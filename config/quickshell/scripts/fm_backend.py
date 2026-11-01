#!/usr/bin/env python3
# File explorer backend (FileExplorer.qml), line-delimited JSON over stdin/stdout.

import os
import sys
import json
import stat
import shutil
import threading
import time
import fnmatch
import subprocess
import hashlib
import pwd
import grp
import zipfile
import tarfile
import urllib.parse
import datetime
from concurrent.futures import ThreadPoolExecutor

HOME = os.path.expanduser("~")
CONFIG_HOME = os.environ.get("XDG_CONFIG_HOME", os.path.join(HOME, ".config"))
CACHE = os.path.join(os.environ.get("XDG_CACHE_HOME", os.path.join(HOME, ".cache")), "qs-fm")
THUMBS = os.path.join(CACHE, "thumbs")
PREFS = os.path.join(CONFIG_HOME, "quickshell", "fm-prefs.json")
TRASH = os.path.join(os.environ.get("XDG_DATA_HOME", os.path.join(HOME, ".local", "share")), "Trash")

_out = threading.Lock()


def emit(o):
    line = json.dumps(o, ensure_ascii=False, separators=(",", ":"), default=str)
    with _out:
        try:
            sys.stdout.write(line + "\n")
            sys.stdout.flush()
        except BrokenPipeError:
            os._exit(0)


def have(b):
    return shutil.which(b) is not None


def run(cmd, timeout=20, inp=None):
    try:
        r = subprocess.run(cmd, capture_output=True, timeout=timeout, input=inp)
        return r.returncode, r.stdout.decode("utf-8", "replace"), r.stderr.decode("utf-8", "replace")
    except Exception as e:  # noqa: BLE001
        return 1, "", str(e)


# ───────────────────────── classification ─────────────────────────
EXT = {
    "image": "png jpg jpeg gif webp bmp svg avif tif tiff heic heif ico jxl",
    "video": "mp4 mkv webm avi mov flv wmv m4v mpg mpeg ts 3gp",
    "audio": "mp3 flac ogg oga wav m4a aac opus wma aiff",
    "archive": "zip tar gz tgz xz txz bz2 tbz2 tbz zst 7z rar iso lz lzma cab deb rpm",
    "pdf": "pdf",
    "doc": "doc docx odt rtf txt md epub xls xlsx ods ppt pptx odp csv tex log",
    "code": "py js ts jsx tsx qml c cc cpp h hpp rs go java kt sh bash zsh fish lua json toml yaml yml "
            "html htm css scss xml conf ini cfg rb php sql vim nix mk cmake desktop service",
}
EXTMAP = {}
for _cat, _exts in EXT.items():
    for _e in _exts.split():
        EXTMAP[_e] = _cat

ARCHIVE_SUFFIXES = (".tar.gz", ".tar.xz", ".tar.bz2", ".tar.zst", ".tar.lz", ".tar")


def ext_of(name):
    low = name.lower()
    for s in ARCHIVE_SUFFIXES:
        if low.endswith(s) and len(low) > len(s):
            return s[1:]
    i = low.rfind(".")
    return low[i + 1:] if i > 0 else ""


def category(name, is_dir, mode):
    if is_dir:
        return "dir"
    e = ext_of(name)
    if e.startswith("tar"):
        return "archive"
    c = EXTMAP.get(e)
    if c:
        return c
    if mode & 0o111:
        return "exec"
    return "file"


def count_children(path):
    try:
        n = 0
        with os.scandir(path) as it:
            for _ in it:
                n += 1
                if n >= 9999:
                    break
        return n
    except OSError:
        return -1


def entry(path, name=None, count=False):
    name = name or os.path.basename(path.rstrip("/")) or path
    try:
        lst = os.lstat(path)
    except OSError:
        return None
    link = stat.S_ISLNK(lst.st_mode)
    st = lst
    broken = False
    if link:
        try:
            st = os.stat(path)
        except OSError:
            broken = True
    d = stat.S_ISDIR(st.st_mode)
    e = {
        "n": name,
        "p": path,
        "d": d,
        "l": link,
        "b": broken,
        "s": 0 if d else st.st_size,
        "m": int(st.st_mtime),
        "perm": stat.filemode(st.st_mode)[1:],
        "h": name.startswith("."),
        "c": category(name, d, st.st_mode),
        "e": "" if d else ext_of(name),
    }
    if d and count:
        e["k"] = count_children(path)
    return e


def fs_usage(path):
    try:
        v = os.statvfs(path)
        return v.f_bavail * v.f_frsize, v.f_blocks * v.f_frsize
    except OSError:
        return -1, -1


def unique(dirpath, name):
    p = os.path.join(dirpath, name)
    if not os.path.lexists(p):
        return p
    e = ext_of(name)
    if e and not name.startswith(".") and name.lower().endswith("." + e):
        base, ext = name[: -(len(e) + 1)], "." + name[-len(e):]
    else:
        base, ext = name, ""
    i = 2
    while True:
        p = os.path.join(dirpath, "%s (%d)%s" % (base, i, ext))
        if not os.path.lexists(p):
            return p
        i += 1


# ───────────────────────── cancellable jobs ─────────────────────────
class Cancelled(Exception):
    pass


class Job:
    def __init__(self, rid, kind, label):
        self.rid, self.kind, self.label = rid, kind, label
        self.cancel = False
        self.done = 0
        self.total = 0
        self.cur = ""
        self._last = 0.0

    def check(self):
        if self.cancel:
            raise Cancelled()

    def progress(self, add=0, cur=None, force=False):
        self.done += add
        if cur is not None:
            self.cur = cur
        now = time.time()
        if force or now - self._last > 0.12:
            self._last = now
            emit({"event": "job", "id": self.rid, "kind": self.kind, "label": self.label,
                  "done": self.done, "total": self.total, "cur": self.cur})


JOBS = {}
CANCEL = set()


def job(rid, kind, label):
    j = Job(rid, kind, label)
    JOBS[rid] = j
    j.progress(force=True)
    return j


def tree_size(paths, j=None):
    total = 0
    for p in paths:
        try:
            if os.path.islink(p):
                continue
            if os.path.isdir(p):
                for root, _dirs, files in os.walk(p):
                    if j:
                        j.check()
                    for f in files:
                        try:
                            total += os.lstat(os.path.join(root, f)).st_size
                        except OSError:
                            pass
            else:
                total += os.path.getsize(p)
        except OSError:
            pass
    return total


def copy_file(src, dst, j):
    with open(src, "rb") as fi, open(dst, "wb") as fo:
        while True:
            j.check()
            b = fi.read(1 << 20)
            if not b:
                break
            fo.write(b)
            j.progress(len(b), os.path.basename(src))
    try:
        shutil.copystat(src, dst)
    except OSError:
        pass


def copy_any(src, dst, j):
    j.check()
    if os.path.islink(src):
        os.symlink(os.readlink(src), dst)
    elif os.path.isdir(src):
        os.mkdir(dst)
        with os.scandir(src) as it:
            for de in it:
                copy_any(de.path, os.path.join(dst, de.name), j)
        try:
            shutil.copystat(src, dst)
        except OSError:
            pass
    else:
        copy_file(src, dst, j)


def remove_any(p):
    if os.path.islink(p) or not os.path.isdir(p):
        os.unlink(p)
    else:
        shutil.rmtree(p)


def inside(child, parent):
    child = os.path.realpath(child)
    parent = os.path.realpath(parent)
    return child == parent or child.startswith(parent.rstrip("/") + "/")


# ───────────────────────── commands ─────────────────────────
def c_list(rid, a):
    path = os.path.abspath(os.path.expanduser(a.get("path") or HOME))
    dirs_only = a.get("dirsOnly", False)
    items = []
    with os.scandir(path) as it:
        des = list(it)
    ndirs = 0
    for de in des:
        try:
            if de.is_dir():
                ndirs += 1
        except OSError:
            pass
    count = ndirs <= 400 and not dirs_only
    for de in des:
        if dirs_only:
            try:
                if not de.is_dir():
                    continue
            except OSError:
                continue
        e = entry(de.path, de.name, count)
        if e:
            if dirs_only:
                e["sub"] = has_subdirs(de.path)
            items.append(e)
    free, total = fs_usage(path)
    return {"path": path, "items": items, "free": free, "total": total,
            "writable": os.access(path, os.W_OK)}


def has_subdirs(path):
    try:
        with os.scandir(path) as it:
            for de in it:
                try:
                    if de.is_dir() and not de.name.startswith("."):
                        return True
                except OSError:
                    pass
    except OSError:
        pass
    return False


def xdg_dirs():
    res = {}
    f = os.path.join(CONFIG_HOME, "user-dirs.dirs")
    try:
        with open(f) as fh:
            for line in fh:
                line = line.strip()
                if not line.startswith("XDG_") or "=" not in line:
                    continue
                k, v = line.split("=", 1)
                v = v.strip().strip('"').replace("$HOME", HOME)
                v = os.path.normpath(os.path.expanduser(v))
                if v != os.path.normpath(HOME):
                    res[k[4:-4].lower()] = v
    except OSError:
        pass
    # unset XDG dirs (pointing at $HOME): fall back to common names
    fallback = {"desktop": ("Desktop", "Escritorio"), "documents": ("Documents", "Documentos"),
                "download": ("Downloads", "Descargas"), "pictures": ("Pictures", "Imágenes", "Imagenes"),
                "music": ("Music", "Música", "Musica"), "videos": ("Videos", "Vídeos")}
    for key, names in fallback.items():
        if key in res and os.path.isdir(res[key]):
            continue
        for n in names:
            p = os.path.join(HOME, n)
            if os.path.isdir(p):
                res[key] = p
                break
    return res


def gtk_bookmarks():
    out = []
    for f in (os.path.join(CONFIG_HOME, "gtk-3.0", "bookmarks"), os.path.join(CONFIG_HOME, "gtk-4.0", "bookmarks")):
        try:
            with open(f) as fh:
                for line in fh:
                    line = line.strip()
                    if not line.startswith("file://"):
                        continue
                    parts = line.split(" ", 1)
                    p = urllib.parse.unquote(urllib.parse.urlparse(parts[0]).path)
                    label = parts[1] if len(parts) > 1 else os.path.basename(p.rstrip("/"))
                    if os.path.isdir(p) and p not in [b["p"] for b in out]:
                        out.append({"n": label, "p": p})
        except OSError:
            pass
    return out


def devices():
    out = []
    code, so, _ = run(["lsblk", "-J", "-b", "-o", "PATH,LABEL,MOUNTPOINT,FSTYPE,SIZE,TYPE,RM,HOTPLUG,MODEL"], 6)
    if code == 0:
        try:
            data = json.loads(so)
        except ValueError:
            data = {}

        def walk(nodes, model=""):
            for n in nodes or []:
                m = n.get("model") or model
                fst = n.get("fstype")
                mp = n.get("mountpoint")
                if fst and fst not in ("swap", "crypto_LUKS", "LVM2_member") and n.get("type") != "loop":
                    if mp and (mp.startswith("/boot") or mp.startswith("/efi") or mp == "[SWAP]"):
                        pass
                    elif not (fst == "vfat" and not mp and not (n.get("rm") or n.get("hotplug"))):
                        label = n.get("label") or (("Sistema" if mp == "/" else os.path.basename(mp)) if mp else "") \
                            or (m.strip() if m else "") or os.path.basename(n.get("path", ""))
                        e = {"n": label, "dev": n.get("path"), "p": mp or "", "fs": fst,
                             "size": int(n.get("size") or 0), "rm": bool(n.get("rm") or n.get("hotplug"))}
                        if mp:
                            free, total = fs_usage(mp)
                            e["free"], e["total"] = free, total
                        out.append(e)
                walk(n.get("children"), m)
        walk(data.get("blockdevices"))
    if not out:
        try:
            with open("/proc/self/mounts") as fh:
                for line in fh:
                    dev, mp = line.split()[:2]
                    if not dev.startswith("/dev/") or mp.startswith("/boot") or mp.startswith("/efi"):
                        continue
                    mp = mp.replace("\\040", " ")
                    free, total = fs_usage(mp)
                    out.append({"n": "Sistema" if mp == "/" else os.path.basename(mp), "dev": dev, "p": mp,
                                "free": free, "total": total, "rm": mp.startswith("/run/media")})
        except OSError:
            pass
    seen, uniq = set(), []
    for e in out:
        key = e.get("p") or e.get("dev")
        if key in seen:
            continue
        seen.add(key)
        uniq.append(e)
    uniq.sort(key=lambda e: (e.get("p") != "/", e.get("rm", False), e.get("n", "").lower()))
    return uniq


def c_places(rid, a):
    x = xdg_dirs()
    places = [{"n": os.path.basename(HOME), "p": HOME, "icon": "home"}]
    for key, icon in (("desktop", "desktop_windows"), ("documents", "description"), ("download", "download"),
                      ("pictures", "image"), ("music", "music_note"), ("videos", "movie")):
        p = x.get(key)
        if p and os.path.isdir(p) and p != HOME:
            places.append({"n": os.path.basename(p.rstrip("/")) or p, "p": p, "icon": icon})
    tcount = 0
    try:
        tcount = len(os.listdir(os.path.join(TRASH, "files")))
    except OSError:
        pass
    return {"home": HOME, "places": places, "bookmarks": gtk_bookmarks(), "devices": devices(),
            "trashCount": tcount, "tools": {k: have(k) for k in
                                            ("7z", "bsdtar", "ffprobe", "ffmpeg", "exiftool", "pdftoppm",
                                             "wl-copy", "udisksctl", "gio", "file")}}


def c_mkdir(rid, a):
    p = unique(a["dir"], a.get("name") or "Nueva carpeta") if not a.get("exact") else os.path.join(a["dir"], a["name"])
    os.mkdir(p)
    return {"path": p}


def c_touch(rid, a):
    p = unique(a["dir"], a.get("name") or "Nuevo archivo.txt")
    with open(p, "x"):
        pass
    return {"path": p}


def c_rename(rid, a):
    src = a["path"]
    name = a["name"].strip()
    if not name or "/" in name:
        raise ValueError("invalid name")
    dst = os.path.join(os.path.dirname(src), name)
    if os.path.lexists(dst) and os.path.realpath(dst) != os.path.realpath(src):
        raise FileExistsError("«%s» already exists" % name)
    os.rename(src, dst)
    return {"path": dst}


def c_copy(rid, a, move=False):
    srcs = [s for s in a["paths"] if os.path.lexists(s)]
    dest = a["dest"]
    j = job(rid, "move" if move else "copy", os.path.basename(dest.rstrip("/")) or dest)
    errors, created = [], []
    try:
        dev_dest = os.stat(dest).st_dev
    except OSError as e:
        raise ValueError("invalid destination: %s" % e)
    # size of only what actually needs copying
    to_copy = []
    for s in srcs:
        if move:
            try:
                if os.lstat(s).st_dev == dev_dest:
                    continue
            except OSError:
                continue
        to_copy.append(s)
    j.total = tree_size(to_copy, j)
    for s in srcs:
        j.check()
        name = os.path.basename(s.rstrip("/"))
        if os.path.isdir(s) and not os.path.islink(s) and inside(dest, s):
            errors.append("%s: can't copy a folder into itself" % name)
            continue
        if move and os.path.dirname(os.path.abspath(s)) == os.path.abspath(dest):
            continue
        dst = unique(dest, name)
        try:
            if move:
                try:
                    os.rename(s, dst)
                    created.append(dst)
                    j.progress(cur=name)
                    continue
                except OSError as e:
                    if e.errno != 18:  # EXDEV: different file system
                        raise
            copy_any(s, dst, j)
            created.append(dst)
            if move:
                remove_any(s)
        except Cancelled:
            if os.path.lexists(dst) and dst not in created:
                try:
                    remove_any(dst)
                except OSError:
                    pass
            raise
        except Exception as e:  # noqa: BLE001
            errors.append("%s: %s" % (name, e))
    j.progress(force=True)
    return {"created": created, "errors": errors}


def c_move(rid, a):
    return c_copy(rid, a, move=True)


def c_delete(rid, a):
    j = job(rid, "delete", "")
    j.total = len(a["paths"])
    errors = []
    for p in a["paths"]:
        j.check()
        try:
            remove_any(p)
        except Exception as e:  # noqa: BLE001
            errors.append("%s: %s" % (os.path.basename(p), e))
        j.progress(1, os.path.basename(p))
    return {"errors": errors}


# ─── trash (freedesktop spec, in ~/.local/share/Trash) ───
def trash_one(p):
    files = os.path.join(TRASH, "files")
    info = os.path.join(TRASH, "info")
    os.makedirs(files, exist_ok=True)
    os.makedirs(info, exist_ok=True)
    ap = os.path.abspath(p)
    same_dev = os.lstat(ap).st_dev == os.stat(files).st_dev
    if not same_dev and have("gio"):
        code, _o, err = run(["gio", "trash", "--", ap], 60)
        if code != 0:
            raise OSError(err.strip() or "gio trash failed")
        return
    name = os.path.basename(ap.rstrip("/"))
    base = name
    i = 1
    while True:
        try:
            fd = os.open(os.path.join(info, base + ".trashinfo"), os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
            break
        except FileExistsError:
            i += 1
            base = "%s.%d" % (name, i)
    with os.fdopen(fd, "w") as fh:
        fh.write("[Trash Info]\nPath=%s\nDeletionDate=%s\n" % (
            urllib.parse.quote(ap), datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S")))
    try:
        if same_dev:
            os.rename(ap, os.path.join(files, base))
        else:
            shutil.move(ap, os.path.join(files, base))
    except Exception:
        os.unlink(os.path.join(info, base + ".trashinfo"))
        raise


def c_trash(rid, a):
    errors = []
    for p in a["paths"]:
        try:
            trash_one(p)
        except Exception as e:  # noqa: BLE001
            errors.append("%s: %s" % (os.path.basename(p), e))
    return {"errors": errors}


def c_trash_list(rid, a):
    info = os.path.join(TRASH, "info")
    files = os.path.join(TRASH, "files")
    items = []
    try:
        names = os.listdir(info)
    except OSError:
        names = []
    for f in names:
        if not f.endswith(".trashinfo"):
            continue
        tid = f[:-10]
        orig, date = "", ""
        try:
            with open(os.path.join(info, f)) as fh:
                for line in fh:
                    if line.startswith("Path="):
                        orig = urllib.parse.unquote(line[5:].strip())
                    elif line.startswith("DeletionDate="):
                        date = line[13:].strip()
        except OSError:
            continue
        e = entry(os.path.join(files, tid), os.path.basename(orig) or tid)
        if not e:
            continue
        e["tid"] = tid
        e["orig"] = orig
        try:
            e["del"] = int(datetime.datetime.fromisoformat(date).timestamp())
        except ValueError:
            e["del"] = e["m"]
        items.append(e)
    free, total = fs_usage(TRASH if os.path.isdir(TRASH) else HOME)
    return {"path": "trash://", "items": items, "free": free, "total": total, "writable": False}


def c_trash_restore(rid, a):
    errors, restored = [], []
    for tid in a["ids"]:
        ip = os.path.join(TRASH, "info", tid + ".trashinfo")
        fp = os.path.join(TRASH, "files", tid)
        try:
            orig = ""
            with open(ip) as fh:
                for line in fh:
                    if line.startswith("Path="):
                        orig = urllib.parse.unquote(line[5:].strip())
            if not orig:
                raise ValueError("unknown original path")
            os.makedirs(os.path.dirname(orig), exist_ok=True)
            dst = unique(os.path.dirname(orig), os.path.basename(orig))
            shutil.move(fp, dst)
            os.unlink(ip)
            restored.append(dst)
        except Exception as e:  # noqa: BLE001
            errors.append("%s: %s" % (tid, e))
    return {"restored": restored, "errors": errors}


def c_trash_purge(rid, a):
    ids = a.get("ids")
    if ids is None:
        try:
            ids = [f[:-10] for f in os.listdir(os.path.join(TRASH, "info")) if f.endswith(".trashinfo")]
        except OSError:
            ids = []
        # leftovers without .trashinfo
        try:
            for f in os.listdir(os.path.join(TRASH, "files")):
                if f not in ids:
                    ids.append(f)
        except OSError:
            pass
    j = job(rid, "delete", "")
    j.total = len(ids)
    errors = []
    for tid in ids:
        j.check()
        fp = os.path.join(TRASH, "files", tid)
        try:
            if os.path.lexists(fp):
                remove_any(fp)
            ip = os.path.join(TRASH, "info", tid + ".trashinfo")
            if os.path.exists(ip):
                os.unlink(ip)
        except Exception as e:  # noqa: BLE001
            errors.append("%s: %s" % (tid, e))
        j.progress(1, tid)
    return {"errors": errors}


# ─── compression ───
def c_compress(rid, a):
    paths = a["paths"]
    fmt = a.get("format", "zip")
    dest = a.get("dest") or os.path.dirname(paths[0])
    name = a.get("name") or (os.path.basename(paths[0].rstrip("/")) if len(paths) == 1 else "Archivo")
    ext = {"zip": ".zip", "tar.gz": ".tar.gz", "tar.xz": ".tar.xz", "tar.bz2": ".tar.bz2", "7z": ".7z"}.get(fmt, ".zip")
    if name.lower().endswith(ext):
        name = name[: -len(ext)]
    out = unique(dest, name + ext)
    j = job(rid, "compress", os.path.basename(out))
    j.total = tree_size(paths, j)
    try:
        if fmt == "zip":
            with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as zf:
                for p in paths:
                    base = os.path.dirname(os.path.abspath(p))
                    if os.path.isdir(p) and not os.path.islink(p):
                        for root, dirs, files in os.walk(p):
                            j.check()
                            rel = os.path.relpath(root, base)
                            if not files and not dirs:
                                zf.writestr(rel + "/", "")
                            for f in files:
                                fp = os.path.join(root, f)
                                j.check()
                                try:
                                    zf.write(fp, os.path.join(rel, f))
                                    j.progress(os.lstat(fp).st_size, f)
                                except OSError:
                                    pass
                    else:
                        zf.write(p, os.path.basename(p))
                        j.progress(os.lstat(p).st_size, os.path.basename(p))
        elif fmt.startswith("tar"):
            mode = {"tar.gz": "w:gz", "tar.xz": "w:xz", "tar.bz2": "w:bz2"}.get(fmt, "w:gz")

            def filt(ti):
                j.check()
                if ti.isfile():
                    j.progress(ti.size, os.path.basename(ti.name))
                return ti
            with tarfile.open(out, mode) as tf:
                for p in paths:
                    tf.add(p, arcname=os.path.basename(p.rstrip("/")), filter=filt)
        elif fmt == "7z":
            done = False
            try:
                import py7zr  # type: ignore
                with py7zr.SevenZipFile(out, "w") as z:
                    for p in paths:
                        j.check()
                        z.writeall(p, os.path.basename(p.rstrip("/")))
                        j.progress(tree_size([p]), os.path.basename(p))
                done = True
            except ImportError:
                pass
            if not done:
                cwd = os.path.dirname(os.path.abspath(paths[0]))
                names = [os.path.relpath(os.path.abspath(p), cwd) for p in paths]
                if have("7z"):
                    cmd = ["7z", "a", "-y", out, "--"] + names
                elif have("bsdtar"):
                    cmd = ["bsdtar", "--format", "7zip", "-cf", out, "--"] + names
                else:
                    raise RuntimeError("for 7z install p7zip, libarchive (bsdtar) or python-py7zr")
                proc = subprocess.Popen(cmd, cwd=cwd, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
                while proc.poll() is None:
                    if j.cancel:
                        proc.kill()
                        raise Cancelled()
                    time.sleep(0.2)
                    try:
                        j.done = os.path.getsize(out)
                    except OSError:
                        pass
                    j.progress()
                if proc.returncode != 0:
                    raise RuntimeError(proc.stderr.read().decode("utf-8", "replace").strip()[:300])
        else:
            raise ValueError("unsupported format: %s" % fmt)
    except BaseException:
        try:
            os.unlink(out)
        except OSError:
            pass
        raise
    j.progress(force=True)
    return {"path": out}


def _has_py7zr():
    try:
        import py7zr  # type: ignore  # noqa: F401
        return True
    except Exception:
        return False


def safe_target(target, member):
    dest = os.path.realpath(os.path.join(target, member))
    return dest == os.path.realpath(target) or dest.startswith(os.path.realpath(target) + os.sep)


def archive_stem(name):
    low = name.lower()
    for s in (".tar.gz", ".tar.xz", ".tar.bz2", ".tar.zst", ".tar.lz", ".tgz", ".txz", ".tbz2",
              ".zip", ".7z", ".rar", ".tar", ".gz", ".xz", ".bz2", ".zst", ".iso"):
        if low.endswith(s) and len(low) > len(s):
            return name[: -len(s)]
    return name


def c_extract(rid, a):
    path = a["path"]
    dest = a.get("dest") or os.path.dirname(path)
    name = os.path.basename(path)
    low = name.lower()
    if a.get("mode", "folder") == "folder":
        target = unique(dest, archive_stem(name))
        os.makedirs(target)
    else:
        target = dest
    j = job(rid, "extract", name)
    try:
        if low.endswith(".zip") and zipfile.is_zipfile(path):
            with zipfile.ZipFile(path) as zf:
                infos = zf.infolist()
                j.total = sum(i.file_size for i in infos)
                for i in infos:
                    j.check()
                    if not safe_target(target, i.filename):
                        continue
                    zf.extract(i, target)
                    j.progress(i.file_size, os.path.basename(i.filename.rstrip("/")))
        elif tarfile.is_tarfile(path) and not low.endswith(".zst"):
            with tarfile.open(path, "r:*") as tf:
                members = tf.getmembers()
                j.total = sum(m.size for m in members)
                for m in members:
                    j.check()
                    if not safe_target(target, m.name):
                        continue
                    if hasattr(tarfile, "data_filter"):
                        tf.extract(m, target, filter="data")
                    else:
                        tf.extract(m, target)
                    j.progress(m.size, os.path.basename(m.name))
        elif low.endswith(".7z") and not have("7z") and not have("bsdtar") and _has_py7zr():
            import py7zr  # type: ignore
            with py7zr.SevenZipFile(path, "r") as z:
                names = [n for n in z.getnames() if safe_target(target, n)]
                j.total = len(names)
                z.extract(path=target, targets=names)
                j.progress(len(names))
        else:
            if have("7z"):
                cmd = ["7z", "x", "-y", "-o" + target, path]
            elif have("bsdtar"):
                cmd = ["bsdtar", "-xf", path, "-C", target]
            elif low.endswith(".rar") and have("unrar"):
                cmd = ["unrar", "x", "-o+", path, target + "/"]
            else:
                raise RuntimeError("unsupported format without 7z/bsdtar")
            proc = subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
            while proc.poll() is None:
                if j.cancel:
                    proc.kill()
                    raise Cancelled()
                time.sleep(0.2)
                j.progress()
            if proc.returncode != 0:
                raise RuntimeError(proc.stderr.read().decode("utf-8", "replace").strip()[:300])
    except BaseException:
        if a.get("mode", "folder") == "folder":
            shutil.rmtree(target, ignore_errors=True)
        raise
    j.progress(force=True)
    return {"path": target}


# ─── search ───
SKIP_DIRS = {".git", "node_modules", "__pycache__", ".cache", ".venv", "venv", ".npm", ".cargo"}
SKIP_ROOT = {"/proc", "/sys", "/dev", "/run", "/tmp", "/var/lib/docker"}


def c_search(rid, a):
    root = os.path.abspath(os.path.expanduser(a.get("root") or HOME))
    q = (a.get("query") or "").strip()
    hidden = a.get("hidden", False)
    limit = int(a.get("limit", 4000))
    ql = q.lower()
    wild = any(ch in q for ch in "*?[")
    toks = ql.split()
    if not toks:
        return {"count": 0, "truncated": False}

    def match(n):
        nl = n.lower()
        if wild:
            return fnmatch.fnmatch(nl, ql)
        return all(t in nl for t in toks)

    stack = [root]
    batch, found, last, scanned = [], 0, time.time(), 0
    truncated = False
    while stack:
        if rid in CANCEL:
            break
        d = stack.pop()
        try:
            it = os.scandir(d)
        except OSError:
            continue
        with it:
            for de in it:
                name = de.name
                if not hidden and name.startswith("."):
                    continue
                scanned += 1
                try:
                    isdir = de.is_dir(follow_symlinks=False)
                except OSError:
                    isdir = False
                if match(name):
                    e = entry(de.path, name)
                    if e:
                        batch.append(e)
                        found += 1
                if isdir and name not in SKIP_DIRS and de.path not in SKIP_ROOT:
                    stack.append(de.path)
        if batch and (len(batch) >= 150 or time.time() - last > 0.15):
            emit({"event": "search", "id": rid, "items": batch, "scanned": scanned})
            batch, last = [], time.time()
        if found >= limit:
            truncated = True
            break
    if batch:
        emit({"event": "search", "id": rid, "items": batch, "scanned": scanned})
    CANCEL.discard(rid)
    return {"count": found, "truncated": truncated, "scanned": scanned}


# ─── properties ───
def c_props(rid, a):
    p = a["path"]
    lst = os.lstat(p)
    link = stat.S_ISLNK(lst.st_mode)
    try:
        st = os.stat(p)
    except OSError:
        st = lst
    btime = 0
    code, so, _ = run(["stat", "-c", "%W", p], 3)
    if code == 0:
        try:
            btime = int(so.strip())
        except ValueError:
            btime = 0
    mime = ""
    if have("file"):
        code, so, _ = run(["file", "-b", "-L", "--mime-type", p], 5)
        if code == 0:
            mime = so.strip()
    try:
        owner = pwd.getpwuid(st.st_uid).pw_name
    except KeyError:
        owner = str(st.st_uid)
    try:
        group = grp.getgrgid(st.st_gid).gr_name
    except KeyError:
        group = str(st.st_gid)
    d = stat.S_ISDIR(st.st_mode)
    name = os.path.basename(p.rstrip("/")) or p
    return {
        "path": p, "name": name, "dir": d, "link": link, "target": os.readlink(p) if link else "",
        "size": 0 if d else st.st_size, "mode": st.st_mode & 0o7777, "perm": stat.filemode(st.st_mode),
        "owner": owner, "group": group, "uid": st.st_uid, "gid": st.st_gid, "mine": st.st_uid == os.getuid(),
        "mtime": int(st.st_mtime), "atime": int(st.st_atime), "ctime": int(st.st_ctime), "btime": btime,
        "mime": mime, "cat": category(name, d, st.st_mode), "inode": st.st_ino,
        "readable": os.access(p, os.R_OK), "writable": os.access(p, os.W_OK),
    }


def c_du(rid, a):
    paths = a.get("paths") or [a["path"]]
    size = files = dirs = 0
    last = time.time()
    for p in paths:
        if os.path.isdir(p) and not os.path.islink(p):
            for root, ds, fs in os.walk(p):
                if rid in CANCEL:
                    CANCEL.discard(rid)
                    return {"size": size, "files": files, "dirs": dirs, "partial": True}
                dirs += len(ds)
                for f in fs:
                    try:
                        size += os.lstat(os.path.join(root, f)).st_size
                    except OSError:
                        pass
                files += len(fs)
                if time.time() - last > 0.25:
                    last = time.time()
                    emit({"event": "du", "id": rid, "size": size, "files": files, "dirs": dirs})
        else:
            try:
                size += os.lstat(p).st_size
                files += 1
            except OSError:
                pass
    return {"size": size, "files": files, "dirs": dirs, "partial": False}


EXIF_KEYS = ["ImageSize", "Megapixels", "Make", "Model", "LensModel", "ExposureTime", "FNumber", "ISO",
             "FocalLength", "Flash", "DateTimeOriginal", "CreateDate", "GPSPosition", "Software",
             "ColorSpace", "BitDepth", "ColorType", "Orientation", "Artist", "Copyright"]
EXIF_SKIP = {"SourceFile", "ExifToolVersion", "FileName", "Directory", "FileSize", "FileModifyDate",
             "FileAccessDate", "FileInodeChangeDate", "FilePermissions", "FileTypeExtension", "ThumbnailImage"}


def fmt_dur(sec):
    try:
        sec = float(sec)
    except (TypeError, ValueError):
        return ""
    h, r = divmod(int(sec), 3600)
    m, s = divmod(r, 60)
    return "%d:%02d:%02d" % (h, m, s) if h else "%d:%02d" % (m, s)


def c_meta(rid, a):
    p = a["path"]
    name = os.path.basename(p)
    try:
        st = os.stat(p)
    except OSError:
        return {"pairs": []}
    cat = category(name, stat.S_ISDIR(st.st_mode), st.st_mode)
    pairs = []
    if cat in ("video", "audio") and have("ffprobe"):
        code, so, _ = run(["ffprobe", "-v", "quiet", "-print_format", "json", "-show_format", "-show_streams", p], 15)
        if code == 0:
            try:
                d = json.loads(so)
            except ValueError:
                d = {}
            f = d.get("format", {})
            if f.get("format_long_name"):
                pairs.append(["Container", f["format_long_name"]])
            if f.get("duration"):
                pairs.append(["Duration", fmt_dur(f["duration"])])
            if f.get("bit_rate"):
                pairs.append(["Bitrate", "%d kb/s" % (int(f["bit_rate"]) // 1000)])
            for s in d.get("streams", []):
                t = s.get("codec_type")
                codec = s.get("codec_long_name") or s.get("codec_name") or "?"
                if t == "video":
                    fr = s.get("avg_frame_rate") or s.get("r_frame_rate") or "0/1"
                    try:
                        num, den = fr.split("/")
                        fps = float(num) / float(den) if float(den) else 0
                    except ValueError:
                        fps = 0
                    pairs.append(["Video", "%s · %sx%s%s" % (codec, s.get("width"), s.get("height"),
                                                             (" · %.3g fps" % fps) if fps else "")])
                    if s.get("pix_fmt"):
                        pairs.append(["Pixels", s["pix_fmt"]])
                elif t == "audio":
                    pairs.append(["Audio", "%s · %s Hz · %s ch" % (codec, s.get("sample_rate", "?"),
                                                                         s.get("channels", "?"))])
                elif t == "subtitle":
                    pairs.append(["Subtitles", "%s (%s)" % (codec, (s.get("tags") or {}).get("language", "?"))])
            for k, v in (f.get("tags") or {}).items():
                if k.lower() in ("title", "artist", "album", "date", "genre", "album_artist", "track", "encoder"):
                    pairs.append([k.capitalize(), str(v)])
    elif cat == "image":
        if have("exiftool"):
            code, so, _ = run(["exiftool", "-j", p], 15)
            if code == 0:
                try:
                    d = (json.loads(so) or [{}])[0]
                except (ValueError, IndexError):
                    d = {}
                for k in EXIF_KEYS:
                    if k in d:
                        pairs.append([k, str(d[k])])
                for k, v in d.items():
                    if len(pairs) >= 40:
                        break
                    if k in EXIF_SKIP or k in EXIF_KEYS or isinstance(v, (dict, list)):
                        continue
                    sv = str(v)
                    if len(sv) > 80 or sv.startswith("(Binary"):
                        continue
                    pairs.append([k, sv])
        if not pairs:
            try:
                from PIL import Image, ExifTags  # type: ignore
                with Image.open(p) as im:
                    pairs.append(["Size", "%dx%d" % im.size])
                    pairs.append(["Format", "%s · %s" % (im.format, im.mode)])
                    ex = im.getexif()
                    for k, v in ex.items():
                        tag = ExifTags.TAGS.get(k, str(k))
                        sv = str(v)
                        if len(sv) < 80:
                            pairs.append([tag, sv])
            except Exception:  # noqa: BLE001
                pass
    elif cat == "pdf" and have("pdfinfo"):
        code, so, _ = run(["pdfinfo", p], 10)
        if code == 0:
            for line in so.splitlines():
                if ":" in line:
                    k, v = line.split(":", 1)
                    if v.strip():
                        pairs.append([k.strip(), v.strip()])
    elif cat == "archive":
        try:
            if zipfile.is_zipfile(p):
                with zipfile.ZipFile(p) as zf:
                    il = zf.infolist()
                    pairs.append(["Entries", str(len(il))])
                    pairs.append(["Uncompressed", str(sum(i.file_size for i in il))])
            elif tarfile.is_tarfile(p):
                with tarfile.open(p, "r:*") as tf:
                    ms = tf.getmembers()
                    pairs.append(["Entries", str(len(ms))])
                    pairs.append(["Uncompressed", str(sum(m.size for m in ms))])
        except Exception:  # noqa: BLE001
            pass
    return {"pairs": pairs[:48]}


def c_chmod(rid, a):
    p = a["path"]
    mode = int(a["mode"]) & 0o7777
    os.chmod(p, mode)
    errors = 0
    if a.get("recursive") and os.path.isdir(p) and not os.path.islink(p):
        for root, dirs, files in os.walk(p):
            for d in dirs:
                try:
                    os.chmod(os.path.join(root, d), mode)
                except OSError:
                    errors += 1
            for f in files:
                fp = os.path.join(root, f)
                try:
                    if os.path.islink(fp):
                        continue
                    orig = os.lstat(fp).st_mode
                    # files only keep the execute bit if they already had it
                    os.chmod(fp, mode if orig & 0o111 else mode & ~0o111)
                except OSError:
                    errors += 1
    return {"errors": errors}


def c_thumb(rid, a):
    p = a["path"]
    st = os.stat(p)
    key = hashlib.sha1(("%s:%s:%s" % (p, st.st_mtime, st.st_size)).encode()).hexdigest()
    out = os.path.join(THUMBS, key + ".jpg")
    if os.path.exists(out):
        return {"path": out}
    cat = category(os.path.basename(p), False, st.st_mode)
    if cat == "video" and have("ffmpeg"):
        for ss in ("3", "0"):
            run(["ffmpeg", "-nostdin", "-y", "-loglevel", "error", "-ss", ss, "-i", p, "-frames:v", "1",
                 "-vf", "scale=384:-2", out], 30)
            if os.path.exists(out) and os.path.getsize(out) > 0:
                break
    elif cat == "pdf" and have("pdftoppm"):
        run(["pdftoppm", "-jpeg", "-f", "1", "-l", "1", "-scale-to", "384", "-singlefile", p, out[:-4]], 30)
    if not os.path.exists(out):
        raise RuntimeError("no thumbnail")
    return {"path": out}


def c_peek(rid, a):
    p = a["path"]
    with open(p, "rb") as fh:
        b = fh.read(6000)
    if b"\0" in b:
        return {"text": "", "binary": True}
    t = b.decode("utf-8", "replace")
    return {"text": "\n".join(t.splitlines()[:150]), "binary": False}


def c_clip_set(rid, a):
    if not have("wl-copy"):
        return {}
    uris = "".join("file://" + urllib.parse.quote(p) + "\r\n" for p in a["paths"])
    try:
        subprocess.Popen(["wl-copy", "--type", "text/uri-list"], stdin=subprocess.PIPE,
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).communicate(uris.encode(), timeout=3)
    except Exception:  # noqa: BLE001
        pass
    return {}


def c_clip_get(rid, a):
    if not have("wl-paste"):
        return {"paths": []}
    code, so, _ = run(["wl-paste", "--list-types"], 3)
    if code != 0 or "text/uri-list" not in so:
        return {"paths": []}
    code, so, _ = run(["wl-paste", "-n", "-t", "text/uri-list"], 3)
    paths = []
    for line in so.splitlines():
        line = line.strip()
        if line.startswith("file://"):
            pp = urllib.parse.unquote(urllib.parse.urlparse(line).path)
            if os.path.lexists(pp):
                paths.append(pp)
    return {"paths": paths}


def c_mount(rid, a):
    if not have("udisksctl"):
        raise RuntimeError("udisksctl is not installed")
    code, so, err = run(["udisksctl", "mount", "-b", a["dev"], "--no-user-interaction"], 30)
    if code != 0:
        raise RuntimeError((err or so).strip()[:300])
    mp = so.strip().split(" at ", 1)[-1].rstrip(".") if " at " in so else ""
    return {"path": mp}


def c_unmount(rid, a):
    if not have("udisksctl"):
        raise RuntimeError("udisksctl is not installed")
    code, so, err = run(["udisksctl", "unmount", "-b", a["dev"], "--no-user-interaction"], 30)
    if code != 0:
        raise RuntimeError((err or so).strip()[:300])
    if a.get("eject"):
        run(["udisksctl", "power-off", "-b", a["dev"], "--no-user-interaction"], 30)
    return {}


def c_prefs_load(rid, a):
    try:
        with open(PREFS) as fh:
            return json.load(fh)
    except (OSError, ValueError):
        return {}


def c_prefs_save(rid, a):
    os.makedirs(os.path.dirname(PREFS), exist_ok=True)
    tmp = PREFS + ".tmp"
    with open(tmp, "w") as fh:
        json.dump(a.get("prefs") or {}, fh, ensure_ascii=False, indent=1)
    os.replace(tmp, PREFS)
    return {}


# ─── watching open folders ───
WATCH = {}
WATCH_LOCK = threading.Lock()


def mtime_ns(p):
    try:
        return os.stat(p).st_mtime_ns
    except OSError:
        return -1


def c_watch(rid, a):
    paths = [p for p in (a.get("paths") or []) if p and not p.startswith("trash://")]
    if any(p.startswith("trash://") for p in (a.get("paths") or [])):
        paths.append(os.path.join(TRASH, "files"))
    with WATCH_LOCK:
        old = dict(WATCH)
        WATCH.clear()
        for p in paths:
            WATCH[p] = old.get(p, mtime_ns(p))
    return {}


def watcher():
    while True:
        time.sleep(1.2)
        with WATCH_LOCK:
            items = list(WATCH.items())
        for p, m in items:
            nm = mtime_ns(p)
            if nm != m:
                with WATCH_LOCK:
                    if p in WATCH:
                        WATCH[p] = nm
                emit({"event": "changed", "path": "trash://" if p == os.path.join(TRASH, "files") else p})


CMDS = {
    "list": c_list, "places": c_places, "mkdir": c_mkdir, "touch": c_touch, "rename": c_rename,
    "copy": c_copy, "move": c_move, "delete": c_delete, "trash": c_trash, "trash_list": c_trash_list,
    "trash_restore": c_trash_restore, "trash_purge": c_trash_purge, "compress": c_compress,
    "extract": c_extract, "search": c_search, "props": c_props, "du": c_du, "meta": c_meta,
    "chmod": c_chmod, "thumb": c_thumb, "peek": c_peek, "clip_set": c_clip_set, "clip_get": c_clip_get,
    "mount": c_mount, "unmount": c_unmount, "prefs_load": c_prefs_load, "prefs_save": c_prefs_save,
    "watch": c_watch,
}

POOL = ThreadPoolExecutor(max_workers=6)
THUMB_POOL = ThreadPoolExecutor(max_workers=2)


def execute(fn, rid, a):
    try:
        data = fn(rid, a)
        emit({"id": rid, "ok": True, "data": data})
    except Cancelled:
        emit({"id": rid, "ok": False, "error": "cancelled"})
    except Exception as e:  # noqa: BLE001
        emit({"id": rid, "ok": False, "error": str(e) or e.__class__.__name__})
    finally:
        JOBS.pop(rid, None)


def main():
    os.makedirs(THUMBS, exist_ok=True)
    threading.Thread(target=watcher, daemon=True).start()
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            req = json.loads(line)
        except ValueError:
            continue
        rid = req.get("id")
        cmd = req.get("cmd")
        a = req.get("args") or {}
        if cmd == "cancel":
            target = a.get("job")
            j = JOBS.get(target)
            if j:
                j.cancel = True
            CANCEL.add(target)
            emit({"id": rid, "ok": True, "data": {}})
            continue
        fn = CMDS.get(cmd)
        if not fn:
            emit({"id": rid, "ok": False, "error": "comando desconocido: %s" % cmd})
            continue
        (THUMB_POOL if cmd in ("thumb", "meta") else POOL).submit(execute, fn, rid, a)
    os._exit(0)


if __name__ == "__main__":
    main()
