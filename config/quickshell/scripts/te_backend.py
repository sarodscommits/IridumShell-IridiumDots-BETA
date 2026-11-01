#!/usr/bin/env python3
"""Text editor backend (TextEditor.qml), line-delimited JSON over stdin/stdout."""
import json
import os
import stat as st
import sys
import tempfile
import threading

MAX_SIZE = 32 * 1024 * 1024
HOME = os.path.expanduser("~")
CONF_DIR = os.path.join(os.environ.get("XDG_CONFIG_HOME") or os.path.join(HOME, ".config"), "quickshell")
STATE_FILE = os.path.join(CONF_DIR, "text-editor.json")

_out_lock = threading.Lock()
_write_lock = threading.Lock()      # writes happen in order


def emit(obj):
    line = json.dumps(obj, ensure_ascii=False)
    with _out_lock:
        sys.stdout.write(line + "\n")
        sys.stdout.flush()


class Err(Exception):
    pass


def _oserr(e, path):
    msgs = {
        "EACCES": "Permission denied",
        "EPERM": "Operation not permitted",
        "ENOENT": "Doesn't exist",
        "EISDIR": "It's a folder",
        "ENOSPC": "No space left on the disk",
        "EROFS": "Read-only file system",
    }
    import errno
    name = errno.errorcode.get(e.errno or 0, "")
    return Err("%s: %s" % (msgs.get(name, e.strerror or str(e)), path))


# ───────────────────────── reading ─────────────────────────
def _looks_binary(raw):
    head = raw[:8192]
    if b"\x00" in head:
        # UTF-16 with a BOM is text
        if head.startswith((b"\xff\xfe", b"\xfe\xff")):
            return False
        return True
    if not head:
        return False
    ctrl = sum(1 for b in head if b < 32 and b not in (9, 10, 12, 13, 27))
    return ctrl / len(head) > 0.10


def _decode(raw):
    if raw.startswith(b"\xef\xbb\xbf"):
        return raw[3:].decode("utf-8", errors="replace"), "utf-8", True
    if raw.startswith(b"\xff\xfe"):
        return raw[2:].decode("utf-16-le", errors="replace"), "utf-16-le", True
    if raw.startswith(b"\xfe\xff"):
        return raw[2:].decode("utf-16-be", errors="replace"), "utf-16-be", True
    try:
        return raw.decode("utf-8"), "utf-8", False
    except UnicodeDecodeError:
        pass
    for enc in ("cp1252", "latin-1"):
        try:
            return raw.decode(enc), enc, False
        except UnicodeDecodeError:
            continue
    return raw.decode("utf-8", errors="replace"), "utf-8", False


def cmd_read(a):
    path = os.path.abspath(os.path.expanduser(a["path"]))
    try:
        s = os.stat(path)
    except OSError as e:
        raise _oserr(e, path)
    if st.S_ISDIR(s.st_mode):
        raise Err("It's a folder: " + path)
    if s.st_size > MAX_SIZE and not a.get("force"):
        return {"path": path, "tooBig": True, "size": s.st_size}
    try:
        with open(path, "rb") as f:
            raw = f.read()
    except OSError as e:
        raise _oserr(e, path)
    if _looks_binary(raw) and not a.get("force"):
        return {"path": path, "binary": True, "size": s.st_size}
    text, enc, bom = _decode(raw)
    crlf = text.count("\r\n")
    lf = text.count("\n") - crlf
    eol = "\r\n" if crlf > lf else "\n"
    if crlf:
        text = text.replace("\r\n", "\n")
    if "\r" in text:                       # classic Mac
        if eol == "\n" and text.count("\r") > text.count("\n"):
            eol = "\r"
        text = text.replace("\r", "\n")
    tabs = spaces = 0
    for ln in text.split("\n", 4000)[:4000]:
        if ln.startswith("\t"):
            tabs += 1
        elif ln.startswith("  "):
            spaces += 1
    return {
        "path": path,
        "text": text,
        "encoding": enc,
        "bom": bom,
        "eol": eol,
        "mtime": s.st_mtime,
        "size": s.st_size,
        "writable": os.access(path, os.W_OK),
        "useTabs": tabs > spaces,
    }


# ───────────────────────── writing ─────────────────────────
def cmd_write(a):
    with _write_lock:
        return _write(a)


def _write(a):
    path = os.path.abspath(os.path.expanduser(a["path"]))
    text = a.get("text", "")
    enc = a.get("encoding") or "utf-8"
    eol = a.get("eol") or "\n"
    if eol != "\n":
        text = text.replace("\n", eol)
    try:
        data = text.encode(enc)
    except (UnicodeEncodeError, LookupError):
        enc = "utf-8"
        data = text.encode("utf-8")
    if a.get("bom"):
        boms = {"utf-8": b"\xef\xbb\xbf", "utf-16-le": b"\xff\xfe", "utf-16-be": b"\xfe\xff"}
        data = boms.get(enc, b"") + data

    real = os.path.realpath(path)          # write through symlinks
    d = os.path.dirname(real) or "/"
    if a.get("mkdirs"):
        try:
            os.makedirs(d, exist_ok=True)
        except OSError as e:
            raise _oserr(e, d)
    if not os.path.isdir(d):
        raise Err("The folder doesn't exist: " + d)

    mode = None
    owner = None
    try:
        s0 = os.stat(real)
        if st.S_ISDIR(s0.st_mode):
            raise Err("It's a folder: " + real)
        mode = st.S_IMODE(s0.st_mode)
        owner = (s0.st_uid, s0.st_gid)
    except FileNotFoundError:
        pass
    except OSError as e:
        raise _oserr(e, real)

    tmp = None
    try:
        fd, tmp = tempfile.mkstemp(prefix=".~" + os.path.basename(real) + ".", dir=d)
        with os.fdopen(fd, "wb") as f:
            f.write(data)
            f.flush()
            os.fsync(f.fileno())
        if mode is not None:
            os.chmod(tmp, mode)
            if owner and owner[0] != os.getuid():
                try:
                    os.chown(tmp, owner[0], owner[1])
                except OSError:
                    pass
        else:
            um = os.umask(0)
            os.umask(um)
            os.chmod(tmp, 0o666 & ~um)
        os.replace(tmp, real)
        tmp = None
    except PermissionError:
        # folder without write permission but writable file: write in place
        if tmp:
            try:
                os.unlink(tmp)
            except OSError:
                pass
            tmp = None
        try:
            with open(real, "wb") as f:
                f.write(data)
        except OSError as e:
            raise _oserr(e, real)
    except OSError as e:
        raise _oserr(e, real)
    finally:
        if tmp:
            try:
                os.unlink(tmp)
            except OSError:
                pass
    s = os.stat(real)
    return {"path": path, "mtime": s.st_mtime, "size": s.st_size, "encoding": enc}


# ───────────────────────── utilities ─────────────────────────
def cmd_stat(a):
    out = {}
    for p in a.get("paths", []):
        try:
            s = os.stat(p)
            out[p] = {"exists": True, "mtime": s.st_mtime, "size": s.st_size, "dir": st.S_ISDIR(s.st_mode)}
        except OSError:
            out[p] = {"exists": False}
    return out


def cmd_ls(a):
    path = os.path.abspath(os.path.expanduser(a.get("path") or HOME))
    while not os.path.isdir(path) and path != "/":
        path = os.path.dirname(path)
    items = []
    try:
        with os.scandir(path) as it:
            for e in it:
                try:
                    isdir = e.is_dir()
                except OSError:
                    isdir = False
                items.append({"n": e.name, "p": e.path, "d": isdir, "h": e.name.startswith(".")})
    except OSError as e:
        raise _oserr(e, path)
    items.sort(key=lambda x: (not x["d"], x["n"].lower()))
    return {"path": path, "parent": os.path.dirname(path) if path != "/" else "", "items": items,
            "writable": os.access(path, os.W_OK)}


def cmd_state_load(a):
    try:
        with open(STATE_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def cmd_state_save(a):
    os.makedirs(CONF_DIR, exist_ok=True)
    tmp = STATE_FILE + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(a.get("state", {}), f, ensure_ascii=False, indent=1)
    os.replace(tmp, STATE_FILE)
    return True


COMMANDS = {
    "read": cmd_read,
    "write": cmd_write,
    "stat": cmd_stat,
    "ls": cmd_ls,
    "home": lambda a: HOME,
    "state_load": cmd_state_load,
    "state_save": cmd_state_save,
}


def handle(msg):
    rid = msg.get("id")
    fn = COMMANDS.get(msg.get("cmd"))
    if not fn:
        emit({"id": rid, "ok": False, "error": "comando desconocido: %s" % msg.get("cmd")})
        return
    try:
        emit({"id": rid, "ok": True, "data": fn(msg.get("args") or {})})
    except Err as e:
        emit({"id": rid, "ok": False, "error": str(e)})
    except Exception as e:  # noqa: BLE001
        emit({"id": rid, "ok": False, "error": "%s: %s" % (type(e).__name__, e)})


def main():
    pending = []
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            msg = json.loads(line)
        except ValueError:
            continue
        # big reads/writes in threads so the rest isn't blocked
        if msg.get("cmd") in ("read", "write"):
            t = threading.Thread(target=handle, args=(msg,), daemon=True)
            t.start()
            pending.append(t)
            pending[:] = [x for x in pending if x.is_alive()]
        else:
            handle(msg)
    for t in pending:                       # stdin closed: finish pending work
        t.join(timeout=30)


if __name__ == "__main__":
    main()
