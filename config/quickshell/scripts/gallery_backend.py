#!/usr/bin/env python3
# Gallery backend (Gallery.qml), line-delimited JSON over stdin/stdout.

import os
import sys
import json
import time
import shutil
import hashlib
import threading
import subprocess
import urllib.parse
import datetime
from concurrent.futures import ThreadPoolExecutor

HOME = os.path.expanduser("~")
CONFIG_HOME = os.environ.get("XDG_CONFIG_HOME", os.path.join(HOME, ".config"))
CACHE = os.path.join(os.environ.get("XDG_CACHE_HOME", os.path.join(HOME, ".cache")), "qs-gallery")
THUMBS = os.path.join(CACHE, "thumbs")
INFO_CACHE = os.path.join(CACHE, "vinfo.json")
PREFS = os.path.join(CONFIG_HOME, "quickshell", "gallery-prefs.json")
TRASH = os.path.join(os.environ.get("XDG_DATA_HOME", os.path.join(HOME, ".local", "share")), "Trash")

IMAGE_EXT = set("png jpg jpeg gif webp bmp avif tif tiff heic heif jxl".split())
VIDEO_EXT = set("mp4 mkv webm avi mov m4v mpg mpeg 3gp wmv flv ts".split())
SKIP_DIRS = {"node_modules", "__pycache__", "venv", ".venv", "site-packages", "thumbnails", "Trash"}
MIN_IMAGE_BYTES = 3072          # skip tiny icons
MAX_DEPTH = 8

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


def run(cmd, timeout=30):
    try:
        r = subprocess.run(cmd, capture_output=True, timeout=timeout)
        return r.returncode, r.stdout.decode("utf-8", "replace"), r.stderr.decode("utf-8", "replace")
    except Exception as e:  # noqa: BLE001
        return 1, "", str(e)


def ext_of(name):
    i = name.rfind(".")
    return name[i + 1:].lower() if i > 0 else ""


def kind_of(name):
    e = ext_of(name)
    if e in IMAGE_EXT:
        return "image"
    if e in VIDEO_EXT:
        return "video"
    return ""


def unique(dirpath, name):
    p = os.path.join(dirpath, name)
    if not os.path.lexists(p):
        return p
    i = name.rfind(".")
    base, ext = (name[:i], name[i:]) if i > 0 else (name, "")
    n = 2
    while True:
        p = os.path.join(dirpath, "%s (%d)%s" % (base, n, ext))
        if not os.path.lexists(p):
            return p
        n += 1


# ───────────────────────── folders ─────────────────────────
def xdg_dirs():
    res = {}
    try:
        with open(os.path.join(CONFIG_HOME, "user-dirs.dirs")) as fh:
            for line in fh:
                line = line.strip()
                if not line.startswith("XDG_") or "=" not in line:
                    continue
                k, v = line.split("=", 1)
                v = os.path.normpath(os.path.expanduser(v.strip().strip('"').replace("$HOME", HOME)))
                if v != os.path.normpath(HOME):
                    res[k[4:-4].lower()] = v
    except OSError:
        pass
    fallback = {"pictures": ("Pictures", "Imágenes", "Imagenes"), "videos": ("Videos", "Vídeos"),
                "download": ("Downloads", "Descargas"), "desktop": ("Desktop", "Escritorio"),
                "documents": ("Documents", "Documentos")}
    for key, names in fallback.items():
        if key in res and os.path.isdir(res[key]):
            continue
        for n in names:
            p = os.path.join(HOME, n)
            if os.path.isdir(p):
                res[key] = p
                break
    return res


def load_prefs():
    try:
        with open(PREFS) as fh:
            d = json.load(fh)
            return d if isinstance(d, dict) else {}
    except (OSError, ValueError):
        return {}


def save_prefs(d):
    os.makedirs(os.path.dirname(PREFS), exist_ok=True)
    tmp = PREFS + ".tmp"
    with open(tmp, "w") as fh:
        json.dump(d, fh, ensure_ascii=False, indent=1)
    os.replace(tmp, PREFS)


def xdg_user_dir(name, fallback):
    """Like the shell's xdg-user-dir lookup, with a fallback."""
    p = ""
    if have("xdg-user-dir"):
        code, so, _ = run(["xdg-user-dir", name], 3)
        if code == 0:
            p = so.strip()
    if not p or not os.path.isdir(p):
        p = os.path.join(HOME, fallback)
    return p


def special_dirs():
    """Folders the shell uses: screenshots, screen recordings and wallpapers."""
    pics = xdg_user_dir("PICTURES", "Pictures")
    vids = xdg_user_dir("VIDEOS", "Videos")
    cand = {
        "screenshots": [os.path.join(pics, "Screenshots"), os.path.join(HOME, "Screenshots"),
                        os.path.join(HOME, "Pictures", "Screenshots")],
        "recordings": [os.path.join(vids, "Recordings"), os.path.join(HOME, "Recordings"),
                       os.path.join(HOME, "Videos", "Recordings")],
        "wallpapers": [os.path.join(HOME, "Wallpapers")],
    }
    res = {}
    for k, ps in cand.items():
        for p in ps:
            if os.path.isdir(p):
                res[k] = os.path.normpath(p)
                break
    return res


def roots():
    x = xdg_dirs()
    out = []
    for k in ("pictures", "videos", "download", "desktop", "documents"):
        p = x.get(k)
        if p and os.path.isdir(p):
            out.append(p)
    out.extend(special_dirs().values())
    for p in load_prefs().get("extraRoots", []):
        p = os.path.normpath(os.path.expanduser(p))
        if os.path.isdir(p):
            out.append(p)
    # no duplicates and no folders contained in another root
    res = []
    for p in sorted(set(out), key=len):
        rp = os.path.realpath(p)
        if not any(rp == os.path.realpath(r) or rp.startswith(os.path.realpath(r) + "/") for r in res):
            res.append(p)
    return res


# ───────────────────────── scanning ─────────────────────────
def c_scan(rid, a):
    rs = roots()
    seen = set()
    batch, total, last = [], 0, time.time()
    for root in rs:
        stack = [(root, 0)]
        while stack:
            d, depth = stack.pop()
            try:
                it = os.scandir(d)
            except OSError:
                continue
            with it:
                for de in it:
                    name = de.name
                    if name.startswith("."):
                        continue
                    try:
                        if de.is_dir(follow_symlinks=False):
                            if depth < MAX_DEPTH and name not in SKIP_DIRS:
                                stack.append((de.path, depth + 1))
                            continue
                        k = kind_of(name)
                        if not k:
                            continue
                        st = de.stat()
                    except OSError:
                        continue
                    if k == "image" and st.st_size < MIN_IMAGE_BYTES:
                        continue
                    key = (st.st_dev, st.st_ino)
                    if key in seen:
                        continue
                    seen.add(key)
                    batch.append({"p": de.path, "n": name, "k": k, "m": int(st.st_mtime), "s": st.st_size,
                                  "d": d, "a": os.path.basename(d) or d})
                    total += 1
            if batch and (len(batch) >= 400 or time.time() - last > 0.2):
                emit({"event": "scan", "id": rid, "items": batch})
                batch, last = [], time.time()
    if batch:
        emit({"event": "scan", "id": rid, "items": batch})
    x = xdg_dirs()
    return {"count": total, "roots": rs, "pictures": x.get("pictures", ""), "videos": x.get("videos", ""),
            "special": special_dirs(),
            "tools": {k: have(k) for k in ("ffmpeg", "ffprobe", "wl-copy")}}


# ───────────────────────── video thumbnails and info ─────────────────────────
_info_lock = threading.Lock()
_info = None


def info_cache():
    global _info
    if _info is None:
        try:
            with open(INFO_CACHE) as fh:
                _info = json.load(fh)
        except (OSError, ValueError):
            _info = {}
    return _info


def save_info_cache():
    with _info_lock:
        try:
            tmp = INFO_CACHE + ".tmp"
            with open(tmp, "w") as fh:
                json.dump(_info or {}, fh)
            os.replace(tmp, INFO_CACHE)
        except OSError:
            pass


_save_timer = None


def schedule_info_save():
    global _save_timer
    if _save_timer:
        _save_timer.cancel()
    _save_timer = threading.Timer(2.0, save_info_cache)
    _save_timer.daemon = True
    _save_timer.start()


def key_for(p, st):
    return hashlib.sha1(("%s:%s:%s" % (p, st.st_mtime, st.st_size)).encode()).hexdigest()


def probe(p):
    if not have("ffprobe"):
        return {}
    code, so, _ = run(["ffprobe", "-v", "quiet", "-print_format", "json", "-show_format", "-show_streams", p], 20)
    if code != 0:
        return {}
    try:
        d = json.loads(so)
    except ValueError:
        return {}
    res = {"dur": float((d.get("format") or {}).get("duration") or 0)}
    for s in d.get("streams", []):
        if s.get("codec_type") == "video" and "w" not in res:
            w, h = int(s.get("width") or 0), int(s.get("height") or 0)
            rot = 0
            try:
                rot = int((s.get("tags") or {}).get("rotate") or 0)
            except ValueError:
                pass
            for sd in s.get("side_data_list") or []:
                if "rotation" in sd:
                    try:
                        rot = int(sd["rotation"])
                    except (TypeError, ValueError):
                        pass
            if abs(rot) % 180 == 90:
                w, h = h, w
            res["w"], res["h"] = w, h
        if s.get("codec_type") == "audio":
            res["audio"] = True
    return res


def c_vinfo(rid, a):
    p = a["path"]
    st = os.stat(p)
    k = key_for(p, st)
    c = info_cache()
    with _info_lock:
        if k in c:
            return c[k]
    r = probe(p)
    with _info_lock:
        c[k] = r
    schedule_info_save()
    return r


def c_thumb(rid, a):
    p = a["path"]
    st = os.stat(p)
    k = key_for(p, st)
    out = os.path.join(THUMBS, k + ".jpg")
    info = c_vinfo(rid, a)
    if not os.path.exists(out):
        if not have("ffmpeg"):
            raise RuntimeError("ffmpeg is not installed")
        dur = info.get("dur") or 0
        for ss in ([str(min(3.0, dur * 0.3))] if dur else []) + ["0"]:
            run(["ffmpeg", "-nostdin", "-y", "-loglevel", "error", "-ss", ss, "-i", p, "-frames:v", "1",
                 "-vf", "scale=480:-2", "-q:v", "4", out], 40)
            if os.path.exists(out) and os.path.getsize(out) > 0:
                break
    if not os.path.exists(out):
        raise RuntimeError("no thumbnail")
    return {"path": out, "dur": info.get("dur", 0), "w": info.get("w", 0), "h": info.get("h", 0)}


# ───────────────────────── trash (freedesktop) ─────────────────────────
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
    name = os.path.basename(ap)
    base, i = name, 1
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
        name = os.path.basename(orig) or tid
        k = kind_of(name) or kind_of(tid)
        if not k:
            continue
        fp = os.path.join(files, tid)
        try:
            st = os.stat(fp)
        except OSError:
            continue
        if os.path.isdir(fp):
            continue
        try:
            deleted = int(datetime.datetime.fromisoformat(date).timestamp())
        except ValueError:
            deleted = int(st.st_mtime)
        items.append({"p": fp, "n": name, "k": k, "m": int(st.st_mtime), "s": st.st_size,
                      "d": os.path.dirname(orig), "a": os.path.basename(os.path.dirname(orig)),
                      "tid": tid, "orig": orig, "del": deleted})
    items.sort(key=lambda e: -e["del"])
    return {"items": items}


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
    if ids is None:   # empty only the media files from the trash
        ids = [e["tid"] for e in c_trash_list(rid, {})["items"]]
    errors = []
    for tid in ids:
        fp = os.path.join(TRASH, "files", tid)
        try:
            if os.path.lexists(fp):
                if os.path.isdir(fp) and not os.path.islink(fp):
                    shutil.rmtree(fp)
                else:
                    os.unlink(fp)
            ip = os.path.join(TRASH, "info", tid + ".trashinfo")
            if os.path.exists(ip):
                os.unlink(ip)
        except Exception as e:  # noqa: BLE001
            errors.append("%s: %s" % (tid, e))
    return {"errors": errors}


# ───────────────────────── editing ─────────────────────────
def edited_name(src, ext=None):
    d = os.path.dirname(src)
    n = os.path.basename(src)
    i = n.rfind(".")
    base, e = (n[:i], n[i:]) if i > 0 else (n, "")
    if ext:
        e = ext
    return unique(d, "%s (editado)%s" % (base, e))


def c_image_finalize(rid, a):
    """Optionally crops the exported PNG and saves it as a copy or over the original."""
    tmp = a["tmp"]
    src = a["src"]
    replace = bool(a.get("replace"))
    crop = a.get("crop")
    ext = os.path.splitext(src)[1].lower()
    if ext not in (".png", ".jpg", ".jpeg", ".webp", ".bmp"):
        ext = ".png"
    out = src if (replace and os.path.splitext(src)[1].lower() == ext) else edited_name(src, ext)
    work = out + ".qs-tmp" + ext
    vf = []
    if crop:
        x, y, w, h = (max(0, int(round(crop[k]))) for k in ("x", "y", "w", "h"))
        vf.append("crop=%d:%d:%d:%d" % (max(1, w), max(1, h), x, y))
    if not vf and ext == ".png":
        shutil.copyfile(tmp, work)
    else:
        if not have("ffmpeg"):
            raise RuntimeError("ffmpeg is not installed (needed to crop / convert)")
        cmd = ["ffmpeg", "-nostdin", "-y", "-loglevel", "error", "-i", tmp]
        if vf:
            cmd += ["-vf", ",".join(vf)]
        if ext in (".jpg", ".jpeg"):
            cmd += ["-q:v", "2"]
        elif ext == ".webp":
            cmd += ["-quality", "92"]
        cmd += ["-frames:v", "1", "-update", "1", work]
        code, _o, err = run(cmd, 120)
        if code != 0 or not os.path.exists(work):
            raise RuntimeError(err.strip()[:300] or "ffmpeg failed")
    os.replace(work, out)
    try:
        os.unlink(tmp)
    except OSError:
        pass
    return {"path": out}


JOBS = {}


def c_video_edit(rid, a):
    """Trims a video by time and/or crop, re-encoding with x264."""
    if not have("ffmpeg"):
        raise RuntimeError("ffmpeg is not installed")
    src = a["path"]
    start = max(0.0, float(a.get("start") or 0))
    end = float(a.get("end") or 0)
    crop = a.get("crop")
    replace = bool(a.get("replace"))
    info = c_vinfo(rid, {"path": src})
    dur = float(info.get("dur") or 0)
    if end <= 0 or (dur and end > dur):
        end = dur
    length = max(0.05, end - start) if end else 0
    out_final = src if replace else edited_name(src, ".mp4")
    if replace and not src.lower().endswith(".mp4"):
        out_final = edited_name(src, ".mp4")
    out = out_final + ".qs-tmp.mp4"
    cmd = ["ffmpeg", "-nostdin", "-y", "-loglevel", "error", "-progress", "pipe:1", "-nostats"]
    if start > 0:
        cmd += ["-ss", "%.3f" % start]
    cmd += ["-i", src]
    if length:
        cmd += ["-t", "%.3f" % length]
    vf = []
    if crop:
        x, y, w, h = (int(round(float(crop[k]))) for k in ("x", "y", "w", "h"))
        w, h = max(2, w - w % 2), max(2, h - h % 2)
        vf.append("crop=%d:%d:%d:%d" % (w, h, max(0, x), max(0, y)))
    vf.append("format=yuv420p")
    cmd += ["-vf", ",".join(vf), "-c:v", "libx264", "-preset", "veryfast", "-crf", "20",
            "-c:a", "aac", "-b:a", "192k", "-movflags", "+faststart", out]
    j = {"cancel": False}
    JOBS[rid] = j
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    last = 0.0
    try:
        for raw in proc.stdout:
            if j["cancel"]:
                proc.kill()
                break
            line = raw.decode("utf-8", "replace").strip()
            if line.startswith("out_time_us=") or line.startswith("out_time_ms="):
                try:
                    t = int(line.split("=", 1)[1]) / 1e6
                except ValueError:
                    continue
                now = time.time()
                if length and now - last > 0.15:
                    last = now
                    emit({"event": "job", "id": rid, "progress": max(0.0, min(1.0, t / length))})
        proc.wait()
    finally:
        JOBS.pop(rid, None)
    if j["cancel"]:
        try:
            os.unlink(out)
        except OSError:
            pass
        raise RuntimeError("cancelled")
    if proc.returncode != 0 or not os.path.exists(out):
        err = proc.stderr.read().decode("utf-8", "replace").strip()
        try:
            os.unlink(out)
        except OSError:
            pass
        raise RuntimeError(err[-300:] or "ffmpeg failed")
    os.replace(out, out_final)
    if replace and out_final != src:
        try:
            trash_one(src)
        except Exception:  # noqa: BLE001
            pass
    emit({"event": "job", "id": rid, "progress": 1.0})
    return {"path": out_final}


def c_tmp_path(rid, a):
    d = os.path.join(CACHE, "tmp")
    os.makedirs(d, exist_ok=True)
    return {"path": os.path.join(d, "edit-%d-%d.png" % (os.getpid(), int(time.time() * 1000)))}


def c_rename(rid, a):
    src = a["path"]
    name = (a.get("name") or "").strip()
    if not name or "/" in name:
        raise ValueError("invalid name")
    dst = os.path.join(os.path.dirname(src), name)
    if os.path.lexists(dst):
        raise FileExistsError("«%s» already exists" % name)
    os.rename(src, dst)
    return {"path": dst}


def c_props(rid, a):
    p = a["path"]
    st = os.stat(p)
    res = {"path": p, "size": st.st_size, "mtime": int(st.st_mtime)}
    if kind_of(p) == "video":
        res.update(c_vinfo(rid, a))
    return res


def c_clip_image(rid, a):
    p = a["path"]
    if not have("wl-copy"):
        raise RuntimeError("wl-copy is not installed")
    mime = "image/png" if p.lower().endswith(".png") else ("image/jpeg" if p.lower().endswith((".jpg", ".jpeg")) else "")
    if mime:
        with open(p, "rb") as fh:
            subprocess.Popen(["wl-copy", "--type", mime], stdin=fh, stdout=subprocess.DEVNULL,
                             stderr=subprocess.DEVNULL)
    else:
        uri = "file://" + urllib.parse.quote(p) + "\r\n"
        subprocess.Popen(["wl-copy", "--type", "text/uri-list"], stdin=subprocess.PIPE, stdout=subprocess.DEVNULL,
                         stderr=subprocess.DEVNULL).communicate(uri.encode(), timeout=3)
    return {}


def c_prefs_load(rid, a):
    return load_prefs()


def c_prefs_save(rid, a):
    d = load_prefs()
    d.update(a.get("prefs") or {})
    save_prefs(d)
    return {}


# ─── watching: notifies if any media folder changes (directory mtime) ───
WATCH = {}
WATCH_LOCK = threading.Lock()


def c_watch(rid, a):
    with WATCH_LOCK:
        WATCH.clear()
        for d in a.get("dirs") or []:
            try:
                WATCH[d] = os.stat(d).st_mtime_ns
            except OSError:
                pass
        tf = os.path.join(TRASH, "files")
        try:
            WATCH[tf] = os.stat(tf).st_mtime_ns
        except OSError:
            pass
    return {}


def watcher():
    while True:
        time.sleep(2.0)
        with WATCH_LOCK:
            items = list(WATCH.items())
        changed = []
        for d, m in items:
            try:
                nm = os.stat(d).st_mtime_ns
            except OSError:
                nm = -1
            if nm != m:
                with WATCH_LOCK:
                    if d in WATCH:
                        WATCH[d] = nm
                changed.append(d)
        if changed:
            emit({"event": "changed", "dirs": changed,
                  "trash": os.path.join(TRASH, "files") in changed})


CMDS = {
    "scan": c_scan, "thumb": c_thumb, "vinfo": c_vinfo, "trash": c_trash, "trash_list": c_trash_list,
    "trash_restore": c_trash_restore, "trash_purge": c_trash_purge, "image_finalize": c_image_finalize,
    "video_edit": c_video_edit, "tmp_path": c_tmp_path, "rename": c_rename, "props": c_props,
    "clip_image": c_clip_image, "prefs_load": c_prefs_load, "prefs_save": c_prefs_save, "watch": c_watch,
}

POOL = ThreadPoolExecutor(max_workers=4)
THUMB_POOL = ThreadPoolExecutor(max_workers=3)
EDIT_POOL = ThreadPoolExecutor(max_workers=1)


def execute(fn, rid, a):
    try:
        emit({"id": rid, "ok": True, "data": fn(rid, a)})
    except Exception as e:  # noqa: BLE001
        emit({"id": rid, "ok": False, "error": str(e) or e.__class__.__name__})


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
            j = JOBS.get(a.get("job"))
            if j:
                j["cancel"] = True
            emit({"id": rid, "ok": True, "data": {}})
            continue
        fn = CMDS.get(cmd)
        if not fn:
            emit({"id": rid, "ok": False, "error": "comando desconocido: %s" % cmd})
            continue
        pool = THUMB_POOL if cmd in ("thumb", "vinfo") else (EDIT_POOL if cmd in ("video_edit", "image_finalize") else POOL)
        pool.submit(execute, fn, rid, a)
    os._exit(0)


if __name__ == "__main__":
    main()