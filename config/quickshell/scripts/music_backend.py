#!/usr/bin/env python3
"""Music player backend (MusicPlayer.qml), line-delimited JSON over stdin/stdout."""
import base64
import hashlib
import json
import os
import shutil
import subprocess
import sys
import threading
import time
import traceback
import urllib.error
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor

try:
    import mutagen
    from mutagen import File as MFile
    HAVE_MUTAGEN = True
except Exception:  # pragma: no cover
    mutagen = None
    MFile = None
    HAVE_MUTAGEN = False

# ───────────────────────────── paths ─────────────────────────────
HOME = os.path.expanduser("~")
DATA_DIR = os.path.join(os.environ.get("XDG_DATA_HOME") or os.path.join(HOME, ".local", "share"), "qs-music")
CACHE_DIR = os.path.join(os.environ.get("XDG_CACHE_HOME") or os.path.join(HOME, ".cache"), "qs-music")
COVER_DIR = os.path.join(CACHE_DIR, "covers")
LIB_CACHE = os.path.join(CACHE_DIR, "library.json")
PREFS_FILE = os.path.join(DATA_DIR, "prefs.json")
PLAYLISTS_FILE = os.path.join(DATA_DIR, "playlists.json")
STATE_FILE = os.path.join(DATA_DIR, "state.json")
for _d in (DATA_DIR, CACHE_DIR, COVER_DIR):
    os.makedirs(_d, exist_ok=True)

AUDIO_EXT = {".mp3", ".flac", ".m4a", ".mp4", ".aac", ".alac", ".ogg", ".oga", ".opus",
             ".wav", ".aif", ".aiff", ".wma", ".ape", ".wv", ".mpc"}
IMAGE_EXT = {".jpg", ".jpeg", ".png", ".webp", ".bmp"}
FOLDER_COVERS = ("cover", "folder", "front", "album", "albumart", "albumartsmall")


def music_dir():
    try:
        out = subprocess.run(["xdg-user-dir", "MUSIC"], capture_output=True, text=True, timeout=2).stdout.strip()
        if out and out != HOME:
            return out
    except Exception:
        pass
    for n in ("Music", "Música", "Musica"):
        p = os.path.join(HOME, n)
        if os.path.isdir(p):
            return p
    return os.path.join(HOME, "Music")


# ───────────────────────────── output ─────────────────────────────
_out_lock = threading.Lock()


def emit(obj):
    s = json.dumps(obj, ensure_ascii=False, separators=(",", ":"))
    with _out_lock:
        sys.stdout.write(s + "\n")
        sys.stdout.flush()


def log(*a):
    print("[music_backend]", *a, file=sys.stderr, flush=True)


def read_json(path, default):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return default


def write_json(path, data):
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False)
    os.replace(tmp, path)


# ───────────────────────────── covers ─────────────────────────────
def mime_ext(mime, data=b""):
    m = (mime or "").lower()
    if "png" in m or data[:8] == b"\x89PNG\r\n\x1a\n":
        return ".png"
    if "webp" in m or (data[:4] == b"RIFF" and data[8:12] == b"WEBP"):
        return ".webp"
    return ".jpg"


def sniff_mime(data):
    if data[:8] == b"\x89PNG\r\n\x1a\n":
        return "image/png"
    if data[:4] == b"RIFF" and data[8:12] == b"WEBP":
        return "image/webp"
    return "image/jpeg"


def cache_cover(data, mime=""):
    if not data:
        return ""
    h = hashlib.sha1(data).hexdigest()[:20]
    p = os.path.join(COVER_DIR, h + mime_ext(mime, data))
    if not os.path.exists(p):
        try:
            with open(p + ".tmp", "wb") as f:
                f.write(data)
            os.replace(p + ".tmp", p)
        except Exception:
            return ""
    return p


def folder_cover(path):
    d = os.path.dirname(path)
    try:
        names = os.listdir(d)
    except Exception:
        return ""
    best = ""
    for n in names:
        stem, ext = os.path.splitext(n)
        if ext.lower() in IMAGE_EXT and stem.lower() in FOLDER_COVERS:
            if stem.lower() in ("cover", "folder", "front"):
                return os.path.join(d, n)
            best = best or os.path.join(d, n)
    return best


def read_image(path):
    with open(path, "rb") as f:
        data = f.read()
    if len(data) > 20 * 1024 * 1024:
        raise ValueError("the image is too large")
    return data, sniff_mime(data)


# ───────────────────────────── tags ─────────────────────────────
FIELDS = ("title", "artist", "album", "albumartist", "track", "tracktotal",
          "disc", "disctotal", "year", "genre", "composer", "comment", "lyrics")

VORBIS_MAP = {"title": "title", "artist": "artist", "album": "album", "albumartist": "albumartist",
              "year": "date", "genre": "genre", "composer": "composer", "comment": "comment"}
MP4_MAP = {"title": "\xa9nam", "artist": "\xa9ART", "album": "\xa9alb", "albumartist": "aART",
           "year": "\xa9day", "genre": "\xa9gen", "composer": "\xa9wrt", "comment": "\xa9cmt",
           "lyrics": "\xa9lyr"}
ID3_MAP = {"title": "TIT2", "artist": "TPE1", "album": "TALB", "albumartist": "TPE2",
           "year": "TDRC", "genre": "TCON", "composer": "TCOM"}
ASF_MAP = {"title": "Title", "artist": "Author", "album": "WM/AlbumTitle", "albumartist": "WM/AlbumArtist",
           "year": "WM/Year", "genre": "WM/Genre", "composer": "WM/Composer", "lyrics": "WM/Lyrics",
           "comment": "Description"}


def _s(v):
    if v is None:
        return ""
    if isinstance(v, (list, tuple)):
        out = []
        for x in v:
            x = _s(x)
            if x and x not in out:
                out.append(x)
        return "; ".join(out)
    if hasattr(v, "text") and not isinstance(v, str):
        return _s(v.text)
    if isinstance(v, bytes):
        try:
            return v.decode("utf-8", "replace")
        except Exception:
            return ""
    return str(v).strip()


def split_num(v):
    """'3/12' -> ('3', '12')"""
    s = _s(v)
    if not s:
        return "", ""
    if "/" in s:
        a, b = s.split("/", 1)
        return a.strip(), b.strip()
    return s, ""


def _kind(f):
    n = type(f).__name__
    if n in ("MP3", "TrueAudio", "EasyMP3"):
        return "id3"
    if n in ("WAVE", "AIFF", "DSF"):
        return "id3"
    if n == "FLAC":
        return "flac"
    if n in ("OggVorbis", "OggOpus", "OggFLAC", "OggSpeex", "OggTheora"):
        return "ogg"
    if n in ("MP4", "EasyMP4"):
        return "mp4"
    if n == "ASF":
        return "asf"
    if n in ("APEv2File", "MonkeysAudio", "WavPack", "Musepack", "OptimFROG"):
        return "ape"
    return "other"


def read_tags(path, want_cover=True, want_lyrics=True):
    """Devuelve (tags: dict, cover_bytes, cover_mime, duration)."""
    tags = {k: "" for k in FIELDS}
    cover, cmime, dur = b"", "", 0.0
    if not HAVE_MUTAGEN:
        return tags, cover, cmime, dur
    try:
        f = MFile(path)
    except Exception as e:
        log("couldn't read", path, e)
        f = None
    if f is None:
        return tags, cover, cmime, dur
    try:
        dur = float(getattr(f.info, "length", 0) or 0)
    except Exception:
        dur = 0.0
    kind = _kind(f)
    t = f.tags
    try:
        if kind == "id3" and t is not None:
            for k, fr in ID3_MAP.items():
                if fr in t:
                    tags[k] = _s(t[fr])
            tags["track"], tags["tracktotal"] = split_num(t.get("TRCK"))
            tags["disc"], tags["disctotal"] = split_num(t.get("TPOS"))
            for key in t.keys():
                if key.startswith("COMM") and not tags["comment"]:
                    fr = t[key]
                    if getattr(fr, "desc", "") in ("", "Comment"):
                        tags["comment"] = _s(fr)
                if key.startswith("USLT") and want_lyrics and not tags["lyrics"]:
                    tags["lyrics"] = str(t[key].text or "")
                if key.startswith("SYLT") and want_lyrics and not tags["lyrics"]:
                    try:
                        tags["lyrics"] = "\n".join(
                            "[%02d:%05.2f]%s" % (ms // 60000, (ms % 60000) / 1000.0, txt)
                            for txt, ms in t[key].text)
                    except Exception:
                        pass
            if want_cover:
                pics = [t[k] for k in t.keys() if k.startswith("APIC")]
                pics.sort(key=lambda p: 0 if getattr(p, "type", 0) == 3 else 1)
                if pics:
                    cover, cmime = pics[0].data, pics[0].mime
        elif kind in ("flac", "ogg") and t is not None:
            for k, vk in VORBIS_MAP.items():
                if vk in t:
                    tags[k] = _s(t[vk])
            if not tags["year"] and "year" in t:
                tags["year"] = _s(t["year"])
            tn, tt = split_num(t.get("tracknumber"))
            tags["track"] = tn
            tags["tracktotal"] = _s(t.get("tracktotal")) or _s(t.get("totaltracks")) or tt
            dn, dt = split_num(t.get("discnumber"))
            tags["disc"] = dn
            tags["disctotal"] = _s(t.get("disctotal")) or _s(t.get("totaldiscs")) or dt
            if want_lyrics:
                for lk in ("lyrics", "unsyncedlyrics", "unsynced lyrics", "syncedlyrics"):
                    if lk in t:
                        tags["lyrics"] = "\n".join(t[lk])
                        break
            if want_cover:
                pics = []
                if kind == "flac":
                    pics = list(f.pictures)
                if not pics and "metadata_block_picture" in t:
                    from mutagen.flac import Picture
                    for b64 in t["metadata_block_picture"]:
                        try:
                            pics.append(Picture(base64.b64decode(b64)))
                        except Exception:
                            pass
                if pics:
                    pics.sort(key=lambda p: 0 if p.type == 3 else 1)
                    cover, cmime = pics[0].data, pics[0].mime
                elif "coverart" in t:
                    try:
                        cover = base64.b64decode(t["coverart"][0])
                        cmime = _s(t.get("coverartmime")) or sniff_mime(cover)
                    except Exception:
                        pass
        elif kind == "mp4" and t is not None:
            for k, vk in MP4_MAP.items():
                if vk in t and (k != "lyrics" or want_lyrics):
                    tags[k] = _s(t[vk])
            if "trkn" in t and t["trkn"]:
                a, b = t["trkn"][0]
                tags["track"], tags["tracktotal"] = (str(a) if a else ""), (str(b) if b else "")
            if "disk" in t and t["disk"]:
                a, b = t["disk"][0]
                tags["disc"], tags["disctotal"] = (str(a) if a else ""), (str(b) if b else "")
            if want_cover and "covr" in t and t["covr"]:
                c = t["covr"][0]
                cover = bytes(c)
                cmime = "image/png" if getattr(c, "imageformat", 0) == 14 else "image/jpeg"
        elif kind == "asf" and t is not None:
            for k, vk in ASF_MAP.items():
                if vk in t and (k != "lyrics" or want_lyrics):
                    tags[k] = _s([x.value for x in t[vk]])
            tags["track"], tags["tracktotal"] = split_num(_s([x.value for x in t.get("WM/TrackNumber", [])]))
            tags["disc"], tags["disctotal"] = split_num(_s([x.value for x in t.get("WM/PartOfSet", [])]))
            if want_cover and "WM/Picture" in t:
                try:
                    raw = t["WM/Picture"][0].value
                    # type(1) + size(4) + mime(utf16z) + desc(utf16z) + data
                    i = 5
                    def _z(b, i):
                        while i + 1 < len(b) and b[i:i + 2] != b"\x00\x00":
                            i += 2
                        return i + 2
                    j = _z(raw, i)
                    cmime = raw[i:j - 2].decode("utf-16-le", "ignore")
                    k = _z(raw, j)
                    cover = raw[k:]
                except Exception:
                    pass
        elif kind == "ape" and t is not None:
            amap = {"title": "Title", "artist": "Artist", "album": "Album", "albumartist": "Album Artist",
                    "year": "Year", "genre": "Genre", "composer": "Composer", "comment": "Comment",
                    "lyrics": "Lyrics"}
            for k, vk in amap.items():
                if vk in t:
                    tags[k] = _s(str(t[vk]))
            tags["track"], tags["tracktotal"] = split_num(str(t.get("Track", "")))
            tags["disc"], tags["disctotal"] = split_num(str(t.get("Disc", "")))
            if want_cover and "Cover Art (Front)" in t:
                v = t["Cover Art (Front)"].value
                k = v.find(b"\x00")
                cover = v[k + 1:] if k >= 0 else v
                cmime = sniff_mime(cover)
    except Exception as e:
        log("error reading tags", path, e)
    if want_cover and cover and not cmime:
        cmime = sniff_mime(cover)
    return tags, cover, cmime, dur


def _num(a, b):
    a, b = (a or "").strip(), (b or "").strip()
    if not a:
        return ""
    return a + ("/" + b if b else "")


def _int(v):
    try:
        return int(str(v).split("/")[0].strip())
    except Exception:
        return 0


def write_tags(path, changes, cover_mode="keep", cover_file="", cover_data=None):
    """changes: dict with the fields to change ("" = clear). cover_mode: keep | set | remove."""
    if not HAVE_MUTAGEN:
        raise RuntimeError("python-mutagen is missing (pacman -S python-mutagen)")
    if not os.access(path, os.W_OK):
        raise PermissionError("no write permission: " + os.path.basename(path))
    f = MFile(path)
    if f is None:
        raise ValueError("unsupported format: " + os.path.basename(path))
    kind = _kind(f)
    data, mime = b"", ""
    if cover_mode == "set":
        if cover_data:
            data = cover_data
            mime = sniff_mime(data)
        else:
            data, mime = read_image(cover_file)

    # track/disc numbers: merged with the previous value if only one part changes
    cur, _, _, _ = read_tags(path, want_cover=False, want_lyrics=False)
    def merged(a, b):
        return (changes.get(a, cur.get(a, "")), changes.get(b, cur.get(b, "")))
    touch_track = "track" in changes or "tracktotal" in changes
    touch_disc = "disc" in changes or "disctotal" in changes

    if kind == "id3":
        from mutagen import id3
        if f.tags is None:
            f.add_tags()
        t = f.tags
        for k, fr in ID3_MAP.items():
            if k in changes:
                t.delall(fr)
                if changes[k]:
                    t.add(getattr(id3, fr)(encoding=3, text=[changes[k]]))
        if touch_track:
            t.delall("TRCK")
            v = _num(*merged("track", "tracktotal"))
            if v:
                t.add(id3.TRCK(encoding=3, text=[v]))
        if touch_disc:
            t.delall("TPOS")
            v = _num(*merged("disc", "disctotal"))
            if v:
                t.add(id3.TPOS(encoding=3, text=[v]))
        if "comment" in changes:
            for key in [k for k in t.keys() if k.startswith("COMM")]:
                del t[key]
            if changes["comment"]:
                t.add(id3.COMM(encoding=3, lang="eng", desc="", text=[changes["comment"]]))
        if "lyrics" in changes:
            t.delall("USLT")
            t.delall("SYLT")
            if changes["lyrics"]:
                t.add(id3.USLT(encoding=3, lang="eng", desc="", text=changes["lyrics"]))
        if cover_mode in ("set", "remove"):
            t.delall("APIC")
            if cover_mode == "set":
                t.add(id3.APIC(encoding=3, mime=mime, type=3, desc="Cover", data=data))
        if type(f).__name__ in ("MP3",):
            f.save(v2_version=3 if _prefers_v23(t) else 4)
        else:
            f.save()
    elif kind in ("flac", "ogg"):
        if f.tags is None:
            f.add_tags()
        t = f.tags
        for k, vk in VORBIS_MAP.items():
            if k in changes:
                for alias in ([vk, "year"] if k == "year" else [vk]):
                    if alias in t:
                        del t[alias]
                if changes[k]:
                    t[vk] = [changes[k]]
        if touch_track:
            a, b = merged("track", "tracktotal")
            for x in ("tracknumber", "tracktotal", "totaltracks"):
                if x in t:
                    del t[x]
            if a:
                t["tracknumber"] = [a]
            if b:
                t["tracktotal"] = [b]
        if touch_disc:
            a, b = merged("disc", "disctotal")
            for x in ("discnumber", "disctotal", "totaldiscs"):
                if x in t:
                    del t[x]
            if a:
                t["discnumber"] = [a]
            if b:
                t["disctotal"] = [b]
        if "lyrics" in changes:
            for x in ("lyrics", "unsyncedlyrics", "unsynced lyrics", "syncedlyrics"):
                if x in t:
                    del t[x]
            if changes["lyrics"]:
                t["lyrics"] = [changes["lyrics"]]
        if cover_mode in ("set", "remove"):
            from mutagen.flac import Picture
            for x in ("metadata_block_picture", "coverart", "coverartmime"):
                if x in t:
                    del t[x]
            if kind == "flac":
                f.clear_pictures()
            if cover_mode == "set":
                pic = Picture()
                pic.type = 3
                pic.mime = mime
                pic.desc = "Cover"
                pic.data = data
                pic.width, pic.height, pic.depth = _img_size(data)
                if kind == "flac":
                    f.add_picture(pic)
                else:
                    t["metadata_block_picture"] = [base64.b64encode(pic.write()).decode("ascii")]
        f.save()
    elif kind == "mp4":
        from mutagen.mp4 import MP4Cover
        if f.tags is None:
            f.add_tags()
        t = f.tags
        for k, vk in MP4_MAP.items():
            if k in changes:
                if vk in t:
                    del t[vk]
                if changes[k]:
                    t[vk] = [changes[k]]
        if touch_track:
            a, b = merged("track", "tracktotal")
            if "trkn" in t:
                del t["trkn"]
            if _int(a):
                t["trkn"] = [(_int(a), _int(b))]
        if touch_disc:
            a, b = merged("disc", "disctotal")
            if "disk" in t:
                del t["disk"]
            if _int(a):
                t["disk"] = [(_int(a), _int(b))]
        if cover_mode in ("set", "remove"):
            if "covr" in t:
                del t["covr"]
            if cover_mode == "set":
                fmt = MP4Cover.FORMAT_PNG if mime == "image/png" else MP4Cover.FORMAT_JPEG
                t["covr"] = [MP4Cover(data, imageformat=fmt)]
        f.save()
    elif kind == "asf":
        from mutagen.asf import ASFUnicodeAttribute
        if f.tags is None:
            f.add_tags()
        t = f.tags
        for k, vk in ASF_MAP.items():
            if k in changes:
                if vk in t:
                    del t[vk]
                if changes[k]:
                    t[vk] = [ASFUnicodeAttribute(changes[k])]
        if touch_track:
            a, _b = merged("track", "tracktotal")
            if "WM/TrackNumber" in t:
                del t["WM/TrackNumber"]
            if a:
                t["WM/TrackNumber"] = [ASFUnicodeAttribute(a)]
        if touch_disc:
            v = _num(*merged("disc", "disctotal"))
            if "WM/PartOfSet" in t:
                del t["WM/PartOfSet"]
            if v:
                t["WM/PartOfSet"] = [ASFUnicodeAttribute(v)]
        if cover_mode in ("set", "remove"):
            from mutagen.asf import ASFByteArrayAttribute
            import struct
            if "WM/Picture" in t:
                del t["WM/Picture"]
            if cover_mode == "set":
                raw = struct.pack("<bI", 3, len(data)) + (mime + "\0").encode("utf-16-le") + "\0".encode("utf-16-le") + data
                t["WM/Picture"] = [ASFByteArrayAttribute(raw)]
        f.save()
    elif kind == "ape":
        from mutagen.apev2 import APEValue, BINARY
        if f.tags is None:
            f.add_tags()
        t = f.tags
        amap = {"title": "Title", "artist": "Artist", "album": "Album", "albumartist": "Album Artist",
                "year": "Year", "genre": "Genre", "composer": "Composer", "comment": "Comment", "lyrics": "Lyrics"}
        for k, vk in amap.items():
            if k in changes:
                if vk in t:
                    del t[vk]
                if changes[k]:
                    t[vk] = changes[k]
        if touch_track:
            v = _num(*merged("track", "tracktotal"))
            if "Track" in t:
                del t["Track"]
            if v:
                t["Track"] = v
        if touch_disc:
            v = _num(*merged("disc", "disctotal"))
            if "Disc" in t:
                del t["Disc"]
            if v:
                t["Disc"] = v
        if cover_mode in ("set", "remove"):
            if "Cover Art (Front)" in t:
                del t["Cover Art (Front)"]
            if cover_mode == "set":
                t["Cover Art (Front)"] = APEValue(b"cover" + mime_ext(mime, data).encode() + b"\x00" + data, BINARY)
        f.save()
    else:
        raise ValueError("can't write tags in this format: " + os.path.splitext(path)[1])


def _prefers_v23(t):
    try:
        return t.version[1] == 3
    except Exception:
        return False


def _img_size(data):
    """approximate (width, height, depth) without PIL; 0 if unknown."""
    try:
        import struct
        if data[:8] == b"\x89PNG\r\n\x1a\n":
            w, h = struct.unpack(">II", data[16:24])
            return w, h, 24
        if data[:2] == b"\xff\xd8":
            i = 2
            while i < len(data):
                if data[i] != 0xFF:
                    i += 1
                    continue
                m = data[i + 1]
                if m in (0xC0, 0xC1, 0xC2):
                    h, w = struct.unpack(">HH", data[i + 5:i + 9])
                    return w, h, 24
                ln = struct.unpack(">H", data[i + 2:i + 4])[0]
                i += 2 + ln
    except Exception:
        pass
    return 0, 0, 0


# ───────────────────────────── library ─────────────────────────────
_lib_lock = threading.Lock()
_lib = read_json(LIB_CACHE, {})        # path -> track dict (with "mt" and "sz" for validation)
if not isinstance(_lib, dict):
    _lib = {}
_lib_dirty = False
_scan_lock = threading.Lock()


def sidecar_lrc(path):
    base = os.path.splitext(path)[0]
    for ext in (".lrc", ".LRC"):
        if os.path.isfile(base + ext):
            return base + ext
    return ""


def make_track(path, st=None):
    st = st or os.stat(path)
    tags, cover, cmime, dur = read_tags(path, want_cover=True, want_lyrics=True)
    art = cache_cover(cover, cmime) if cover else ""
    if not art:
        art = folder_cover(path)
    stem = os.path.splitext(os.path.basename(path))[0]
    title = tags["title"] or stem
    artist = tags["artist"]
    if not tags["title"] and not artist and " - " in stem:
        a, b = stem.split(" - ", 1)
        artist, title = a.strip(), b.strip()
    lrc = sidecar_lrc(path)
    return {
        "p": path,
        "t": title,
        "ar": artist,
        "al": tags["album"],
        "aa": tags["albumartist"],
        "n": _int(tags["track"]),
        "dn": _int(tags["disc"]),
        "y": tags["year"][:4] if tags["year"] else "",
        "g": tags["genre"],
        "dur": round(dur, 2),
        "art": art,
        "lyr": bool(tags["lyrics"].strip()) or bool(lrc),
        "ext": os.path.splitext(path)[1][1:].lower(),
        "mt": int(st.st_mtime),
        "sz": st.st_size,
        "add": int(_lib.get(path, {}).get("add") or time.time()),
    }


def save_lib():
    global _lib_dirty
    with _lib_lock:
        data = dict(_lib)
        _lib_dirty = False
    try:
        write_json(LIB_CACHE, data)
    except Exception as e:
        log("couldn't save the cache", e)


def walk_audio(roots):
    seen = set()
    for r in roots:
        r = os.path.expanduser(r)
        if os.path.isfile(r):
            if os.path.splitext(r)[1].lower() in AUDIO_EXT and r not in seen:
                seen.add(r)
                yield r
            continue
        if not os.path.isdir(r):
            continue
        for dp, dns, fns in os.walk(r, followlinks=True):
            dns[:] = [d for d in dns if not d.startswith(".")]
            for n in fns:
                if n.startswith("."):
                    continue
                if os.path.splitext(n)[1].lower() in AUDIO_EXT:
                    p = os.path.join(dp, n)
                    if p not in seen:
                        seen.add(p)
                        yield p


def lib_roots(prefs=None):
    prefs = prefs or load_prefs()
    roots = list(prefs.get("libDirs") or [music_dir()])
    roots += [p for p in (prefs.get("extraFiles") or []) if os.path.exists(p)]
    return roots


def scan(rid, force=False):
    global _lib_dirty
    with _scan_lock:
        prefs = load_prefs()
        excluded = set(prefs.get("excluded") or [])
        paths = [p for p in walk_audio(lib_roots(prefs)) if p not in excluded]
        total = len(paths)
        out = []
        last = 0.0
        changed = False
        for i, p in enumerate(paths):
            try:
                st = os.stat(p)
            except OSError:
                continue
            cached = _lib.get(p)
            if cached and not force and cached.get("mt") == int(st.st_mtime) and cached.get("sz") == st.st_size \
                    and (not cached.get("art") or os.path.exists(cached["art"])):
                tr = cached
                lrc = bool(sidecar_lrc(p))
                if lrc and not tr.get("lyr"):
                    tr = dict(tr, lyr=True)
            else:
                try:
                    tr = make_track(p, st)
                except Exception as e:
                    log("error with", p, e)
                    continue
                changed = True
            with _lib_lock:
                _lib[p] = tr
            out.append(tr)
            now = time.time()
            if now - last > 0.25:
                last = now
                emit({"event": "scan", "id": rid, "done": i + 1, "total": total})
        keep = set(paths)
        with _lib_lock:
            gone = [k for k in _lib if k not in keep]
            for k in gone:
                del _lib[k]
            if gone:
                changed = True
            _lib_dirty = _lib_dirty or changed
        if changed:
            save_lib()
        return out


def refresh_track(path):
    global _lib_dirty
    tr = make_track(path)
    with _lib_lock:
        _lib[path] = tr
        _lib_dirty = True
    return tr


# ───────────────────────────── preferences / playlists ─────────────────────────────
DEFAULT_PREFS = {
    "libDirs": None, "extraFiles": [], "excluded": [], "volume": 0.8, "muted": False,
    "shuffle": False, "repeat": "off", "view": "songs", "sortKey": "title", "sortAsc": True,
    "importMode": "copy", "spotdlPath": "", "dlFormat": "mp3", "dlSynced": True, "sideW": 236, "panelOpen": True, "panelTab": "lyrics",
}


def load_prefs():
    p = dict(DEFAULT_PREFS)
    p.update(read_json(PREFS_FILE, {}) or {})
    if not p.get("libDirs"):
        p["libDirs"] = [music_dir()]
    return p


def save_prefs(new):
    p = load_prefs()
    p.update(new or {})
    write_json(PREFS_FILE, p)
    return p


def load_playlists():
    d = read_json(PLAYLISTS_FILE, [])
    return d if isinstance(d, list) else []


# ───────────────────────────── import ─────────────────────────────
def same_file(a, b):
    try:
        if os.path.getsize(a) != os.path.getsize(b):
            return False
        with open(a, "rb") as fa, open(b, "rb") as fb:
            while True:
                x, y = fa.read(1 << 20), fb.read(1 << 20)
                if x != y:
                    return False
                if not x:
                    return True
    except Exception:
        return False


def do_import(rid, paths, mode):
    prefs = load_prefs()
    dest = (prefs.get("libDirs") or [music_dir()])[0]
    files, bad = [], 0
    for p in paths:
        p = os.path.expanduser(p)
        if os.path.isdir(p):
            files.extend((f, os.path.dirname(os.path.abspath(p))) for f in walk_audio([p]))
        elif os.path.isfile(p) and os.path.splitext(p)[1].lower() in AUDIO_EXT:
            files.append((p, os.path.dirname(os.path.abspath(p))))
        else:
            bad += 1
    add, dup = 0, 0
    newpaths = []
    extra = list(prefs.get("extraFiles") or [])
    excluded = set(prefs.get("excluded") or [])
    roots = [os.path.abspath(os.path.expanduser(r)) for r in prefs.get("libDirs") or []]
    by_size = {}
    with _lib_lock:
        for lp, tr in _lib.items():
            by_size.setdefault(tr.get("sz"), []).append(lp)
    total = len(files)
    for i, (f, base) in enumerate(files):
        emit({"event": "import", "id": rid, "done": i, "total": total, "cur": os.path.basename(f)})
        absf = os.path.abspath(f)
        inside = any(absf == r or absf.startswith(r + os.sep) for r in roots)
        if mode == "add" or inside:
            if absf in excluded:
                excluded.discard(absf)
            if absf in _lib and not inside and absf in extra:
                dup += 1
                continue
            if not inside and absf not in extra:
                extra.append(absf)
            if absf in _lib:
                dup += 1
                continue
            newpaths.append(absf)
            add += 1
            continue
        # already in the library (same content at another path)?
        try:
            fsz = os.path.getsize(absf)
        except OSError:
            bad += 1
            continue
        if any(same_file(absf, lp) for lp in by_size.get(fsz, []) if os.path.exists(lp)):
            dup += 1
            continue
        # copy: keeps the subfolder structure if a folder was dropped
        rel = os.path.relpath(absf, base)
        dst = os.path.join(dest, rel)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        if os.path.exists(dst):
            if same_file(absf, dst):
                dup += 1
                excluded.discard(dst)
                continue
            b, x = os.path.splitext(dst)
            k = 2
            while os.path.exists("%s-%d%s" % (b, k, x)):
                k += 1
            dst = "%s-%d%s" % (b, k, x)
        try:
            shutil.copy2(absf, dst)
            # also copies the .lrc and the folder cover if they exist
            lrc = sidecar_lrc(absf)
            if lrc:
                shutil.copy2(lrc, os.path.splitext(dst)[0] + ".lrc")
            fc = folder_cover(absf)
            if fc and not folder_cover(dst):
                shutil.copy2(fc, os.path.join(os.path.dirname(dst), os.path.basename(fc)))
            newpaths.append(dst)
            by_size.setdefault(fsz, []).append(dst)
            add += 1
        except Exception as e:
            log("couldn't copy", absf, e)
            bad += 1
    save_prefs({"extraFiles": extra, "excluded": sorted(excluded)})
    tracks = []
    for p in newpaths:
        try:
            tracks.append(refresh_track(p))
        except Exception as e:
            log("couldn't read", p, e)
    if tracks:
        save_lib()
    return {"add": add, "dup": dup, "bad": bad, "tracks": tracks, "dest": dest}


PICK_SCRIPT = r'''
T="$1"; KIND="$2"; NL=$'\n'
if [ "$KIND" = image ]; then
  PAT=""; for e in jpg jpeg png webp; do PAT="$PAT *.$e *.${e^^}"; done; PAT="${PAT# }"; MULTI=""
elif [ "$KIND" = lrc ]; then
  PAT="*.lrc *.LRC *.txt *.TXT"; MULTI=""
elif [ "$KIND" = dir ]; then
  PAT=""
else
  PAT=""; for e in mp3 flac m4a mp4 aac ogg oga opus wav aif aiff wma ape wv; do PAT="$PAT *.$e *.${e^^}"; done; PAT="${PAT# }"; MULTI=1
fi
if command -v zenity >/dev/null 2>&1; then
  if [ "$KIND" = dir ]; then
    zenity --file-selection --directory --title="$T" --filename="$HOME/" 2>/dev/null || echo "::CANCEL"
  else
    zenity --file-selection ${MULTI:+--multiple} --separator="$NL" --title="$T" --filename="$HOME/" --file-filter="$T | $PAT" 2>/dev/null || echo "::CANCEL"
  fi
elif command -v kdialog >/dev/null 2>&1; then
  if [ "$KIND" = dir ]; then
    kdialog --title "$T" --getexistingdirectory "$HOME" 2>/dev/null || echo "::CANCEL"
  else
    kdialog --title "$T" --getopenfilename "$HOME" "$PAT|$T" ${MULTI:+--multiple --separate-output} 2>/dev/null || echo "::CANCEL"
  fi
elif command -v yad >/dev/null 2>&1; then
  if [ "$KIND" = dir ]; then
    yad --file --directory --title="$T" 2>/dev/null || echo "::CANCEL"
  else
    yad --file ${MULTI:+--multiple} --separator="$NL" --title="$T" --file-filter="$T | $PAT" 2>/dev/null || echo "::CANCEL"
  fi
else
  echo "::NOPICKER"
fi
'''


def pick(title, kind):
    r = subprocess.run(["bash", "-c", PICK_SCRIPT, "qs-music-pick", title, kind], capture_output=True, text=True)
    out = [l for l in r.stdout.splitlines() if l.strip()]
    if "::NOPICKER" in out:
        return {"status": "nopicker", "paths": []}
    if "::CANCEL" in out or not out:
        return {"status": "cancel", "paths": []}
    return {"status": "ok", "paths": out}


def trash(path):
    for cmd in (["gio", "trash", "--", path], ["trash-put", "--", path]):
        if shutil.which(cmd[0]):
            if subprocess.run(cmd, capture_output=True).returncode == 0:
                return "trash"
    os.remove(path)
    return "rm"


# ───────────────────────────── lyrics (LRCLIB) ─────────────────────────────
def http_json(url):
    req = urllib.request.Request(url, headers={"User-Agent": "qs-music/1.0 (Quickshell music player)"})
    with urllib.request.urlopen(req, timeout=12) as r:
        return json.loads(r.read().decode("utf-8"))


def fetch_lyrics(artist, title, album, duration):
    base = "https://lrclib.net/api/"
    q = {"artist_name": artist or "", "track_name": title or ""}
    if album:
        q["album_name"] = album
    if duration:
        q["duration"] = str(int(round(float(duration))))
    res = None
    try:
        res = http_json(base + "get?" + urllib.parse.urlencode(q))
    except urllib.error.HTTPError as e:
        if e.code != 404:
            raise
    except Exception:
        res = None
    if not res or not (res.get("syncedLyrics") or res.get("plainLyrics")):
        lst = http_json(base + "search?" + urllib.parse.urlencode({"track_name": title or "", "artist_name": artist or ""}))
        if not lst:
            lst = http_json(base + "search?" + urllib.parse.urlencode({"q": ((artist or "") + " " + (title or "")).strip()}))
        best = None
        for it in lst or []:
            if it.get("syncedLyrics") or it.get("plainLyrics"):
                if duration and it.get("duration"):
                    if abs(float(it["duration"]) - float(duration)) > 8:
                        best = best or it
                        continue
                best = it
                break
        res = best
    if not res:
        return {"found": False}
    return {"found": True, "synced": res.get("syncedLyrics") or "", "plain": res.get("plainLyrics") or "",
            "title": res.get("trackName") or "", "artist": res.get("artistName") or ""}


# ───────────────────────────── MPRIS ─────────────────────────────
MPRIS_XML = """
<node>
  <interface name="org.mpris.MediaPlayer2">
    <method name="Raise"/><method name="Quit"/>
    <property name="CanQuit" type="b" access="read"/>
    <property name="CanRaise" type="b" access="read"/>
    <property name="HasTrackList" type="b" access="read"/>
    <property name="Identity" type="s" access="read"/>
    <property name="DesktopEntry" type="s" access="read"/>
    <property name="SupportedUriSchemes" type="as" access="read"/>
    <property name="SupportedMimeTypes" type="as" access="read"/>
  </interface>
  <interface name="org.mpris.MediaPlayer2.Player">
    <method name="Next"/><method name="Previous"/><method name="Pause"/>
    <method name="PlayPause"/><method name="Stop"/><method name="Play"/>
    <method name="Seek"><arg direction="in" name="Offset" type="x"/></method>
    <method name="SetPosition"><arg direction="in" name="TrackId" type="o"/><arg direction="in" name="Position" type="x"/></method>
    <method name="OpenUri"><arg direction="in" name="Uri" type="s"/></method>
    <signal name="Seeked"><arg name="Position" type="x"/></signal>
    <property name="PlaybackStatus" type="s" access="read"/>
    <property name="LoopStatus" type="s" access="readwrite"/>
    <property name="Rate" type="d" access="readwrite"/>
    <property name="Shuffle" type="b" access="readwrite"/>
    <property name="Metadata" type="a{sv}" access="read"/>
    <property name="Volume" type="d" access="readwrite"/>
    <property name="Position" type="x" access="read"/>
    <property name="MinimumRate" type="d" access="read"/>
    <property name="MaximumRate" type="d" access="read"/>
    <property name="CanGoNext" type="b" access="read"/>
    <property name="CanGoPrevious" type="b" access="read"/>
    <property name="CanPlay" type="b" access="read"/>
    <property name="CanPause" type="b" access="read"/>
    <property name="CanSeek" type="b" access="read"/>
    <property name="CanControl" type="b" access="read"/>
  </interface>
</node>
"""


class Mpris:
    def __init__(self):
        self.ok = False
        self.state = {"status": "Stopped", "loop": "None", "shuffle": False, "volume": 1.0,
                      "pos": 0, "pos_t": time.time(), "len": 0, "title": "", "artist": "", "album": "",
                      "albumartist": "", "art": "", "path": "", "track": 0, "canNext": False, "canPrev": False,
                      # lyrics: full text (LRC if synced) + current line in real time
                      "lyrics": "", "lyricsSynced": False, "lyricLine": "", "lyricIndex": -1}
        self.conn = None
        self.GLib = None
        try:
            import gi
            gi.require_version("Gio", "2.0")
            from gi.repository import Gio, GLib
            self.Gio, self.GLib = Gio, GLib
        except Exception as e:
            log("MPRIS disabled (PyGObject missing):", e)
            return
        self.ok = True
        threading.Thread(target=self._run, daemon=True).start()

    def _run(self):
        Gio, GLib = self.Gio, self.GLib
        self.node = Gio.DBusNodeInfo.new_for_xml(MPRIS_XML)
        self.loop = GLib.MainLoop()

        def on_bus(conn, name):
            self.conn = conn
            for iface in self.node.interfaces:
                conn.register_object("/org/mpris/MediaPlayer2", iface, self._call, self._get, self._set)

        def on_lost(conn, name):
            log("MPRIS: couldn't acquire the name", name)

        Gio.bus_own_name(Gio.BusType.SESSION, "org.mpris.MediaPlayer2.qsmusic",
                         Gio.BusNameOwnerFlags.NONE, on_bus, None, on_lost)
        try:
            self.loop.run()
        except Exception as e:
            log("MPRIS loop:", e)

    # estimated position (µs)
    def _pos(self):
        s = self.state
        p = s["pos"]
        if s["status"] == "Playing":
            p += int((time.time() - s["pos_t"]) * 1e6)
        if s["len"]:
            p = min(p, s["len"])
        return max(0, p)

    def _trackid(self):
        h = hashlib.md5(self.state["path"].encode("utf-8")).hexdigest() if self.state["path"] else "none"
        return "/org/qsmusic/track/" + h

    def _meta(self):
        GLib = self.GLib
        s = self.state
        m = {"mpris:trackid": GLib.Variant("o", self._trackid())}
        if s["len"]:
            m["mpris:length"] = GLib.Variant("x", int(s["len"]))
        if s["title"]:
            m["xesam:title"] = GLib.Variant("s", s["title"])
        if s["artist"]:
            m["xesam:artist"] = GLib.Variant("as", [s["artist"]])
        if s["album"]:
            m["xesam:album"] = GLib.Variant("s", s["album"])
        if s["albumartist"]:
            m["xesam:albumArtist"] = GLib.Variant("as", [s["albumartist"]])
        if s["track"]:
            m["xesam:trackNumber"] = GLib.Variant("i", int(s["track"]))
        if s["art"]:
            m["mpris:artUrl"] = GLib.Variant("s", "file://" + urllib.parse.quote(s["art"]))
        if s["path"]:
            m["xesam:url"] = GLib.Variant("s", "file://" + urllib.parse.quote(s["path"]))
        if s["lyrics"]:
            # xesam:asText is the standard MPRIS key for lyrics
            m["xesam:asText"] = GLib.Variant("s", s["lyrics"])
            m["qsmusic:lyricsSynced"] = GLib.Variant("b", bool(s["lyricsSynced"]))
            m["qsmusic:lyricIndex"] = GLib.Variant("i", int(s["lyricIndex"]))
            m["qsmusic:lyricLine"] = GLib.Variant("s", s["lyricLine"])
        return GLib.Variant("a{sv}", m)

    def _prop(self, iface, name):
        GLib, s = self.GLib, self.state
        if iface == "org.mpris.MediaPlayer2":
            return {
                "CanQuit": GLib.Variant("b", True), "CanRaise": GLib.Variant("b", True),
                "HasTrackList": GLib.Variant("b", False), "Identity": GLib.Variant("s", "Music"),
                "DesktopEntry": GLib.Variant("s", "qs-music"),
                "SupportedUriSchemes": GLib.Variant("as", ["file"]),
                "SupportedMimeTypes": GLib.Variant("as", ["audio/mpeg", "audio/flac", "audio/ogg", "audio/mp4", "audio/x-wav"]),
            }.get(name)
        has = bool(s["path"])
        return {
            "PlaybackStatus": GLib.Variant("s", s["status"]), "LoopStatus": GLib.Variant("s", s["loop"]),
            "Rate": GLib.Variant("d", 1.0), "Shuffle": GLib.Variant("b", s["shuffle"]),
            "Metadata": self._meta(), "Volume": GLib.Variant("d", float(s["volume"])),
            "Position": GLib.Variant("x", self._pos()), "MinimumRate": GLib.Variant("d", 1.0),
            "MaximumRate": GLib.Variant("d", 1.0), "CanGoNext": GLib.Variant("b", s["canNext"]),
            "CanGoPrevious": GLib.Variant("b", s["canPrev"]), "CanPlay": GLib.Variant("b", has),
            "CanPause": GLib.Variant("b", has), "CanSeek": GLib.Variant("b", has and s["len"] > 0),
            "CanControl": GLib.Variant("b", True),
        }.get(name)

    def _get(self, conn, sender, path, iface, name):
        return self._prop(iface, name)

    def _set(self, conn, sender, path, iface, name, value):
        v = value.unpack()
        if name == "LoopStatus":
            emit({"event": "mpris", "action": "Loop", "value": v})
        elif name == "Shuffle":
            emit({"event": "mpris", "action": "Shuffle", "value": bool(v)})
        elif name == "Volume":
            emit({"event": "mpris", "action": "Volume", "value": float(v)})
        return True

    def _call(self, conn, sender, path, iface, method, params, invocation):
        args = params.unpack() if params is not None else ()
        if method == "Seek":
            emit({"event": "mpris", "action": "Seek", "value": args[0] / 1e6})
        elif method == "SetPosition":
            if args[0] == self._trackid():
                emit({"event": "mpris", "action": "SetPosition", "value": args[1] / 1e6})
        elif method == "OpenUri":
            u = args[0]
            if u.startswith("file://"):
                emit({"event": "mpris", "action": "Open", "value": urllib.parse.unquote(u[7:])})
        else:
            emit({"event": "mpris", "action": method})
        invocation.return_value(None)

    def update(self, d):
        if not self.ok:
            return
        GLib = self.GLib

        def apply():
            s = self.state
            changed = {}
            seeked = d.pop("seeked", False)
            for k, v in d.items():
                if k == "pos":
                    s["pos"], s["pos_t"] = int(v), time.time()
                    continue
                if k in s and s[k] != v:
                    s[k] = v
                    changed[k] = True
            if "pos" in d and "status" in changed:
                s["pos_t"] = time.time()
            if self.conn is None:
                return False
            props = {}
            if "status" in changed:
                props["PlaybackStatus"] = self._prop("x", "PlaybackStatus")
            if "loop" in changed:
                props["LoopStatus"] = self._prop("x", "LoopStatus")
            if "shuffle" in changed:
                props["Shuffle"] = self._prop("x", "Shuffle")
            if "volume" in changed:
                props["Volume"] = self._prop("x", "Volume")
            if any(k in changed for k in ("title", "artist", "album", "albumartist", "art", "path", "len", "track",
                                           "lyrics", "lyricsSynced", "lyricLine", "lyricIndex")):
                props["Metadata"] = self._meta()
                props["CanPlay"] = self._prop("x", "CanPlay")
                props["CanPause"] = self._prop("x", "CanPause")
                props["CanSeek"] = self._prop("x", "CanSeek")
            if "canNext" in changed:
                props["CanGoNext"] = self._prop("x", "CanGoNext")
            if "canPrev" in changed:
                props["CanGoPrevious"] = self._prop("x", "CanGoPrevious")
            try:
                if props:
                    self.conn.emit_signal(None, "/org/mpris/MediaPlayer2", "org.freedesktop.DBus.Properties",
                                          "PropertiesChanged",
                                          GLib.Variant("(sa{sv}as)", ("org.mpris.MediaPlayer2.Player", props, [])))
                if seeked:
                    self.conn.emit_signal(None, "/org/mpris/MediaPlayer2", "org.mpris.MediaPlayer2.Player",
                                          "Seeked", GLib.Variant("(x)", (self._pos(),)))
            except Exception as e:
                log("MPRIS emit:", e)
            return False

        GLib.idle_add(apply)


MPRIS = None


# ───────────────────────────── commands ─────────────────────────────
def c_init(rid, a):
    prefs = load_prefs()
    pickers = [p for p in ("zenity", "kdialog", "yad") if shutil.which(p)]
    return {"home": HOME, "musicDir": music_dir(), "dataDir": DATA_DIR, "prefs": prefs,
            "playlists": load_playlists(), "state": read_json(STATE_FILE, {}),
            "mutagen": HAVE_MUTAGEN, "picker": pickers[0] if pickers else "",
            "mpris": bool(MPRIS and MPRIS.ok)}


def c_scan(rid, a):
    return scan(rid, bool(a.get("force")))


def c_track_get(rid, a):
    p = a["path"]
    tags, cover, cmime, dur = read_tags(p, want_cover=True, want_lyrics=True)
    art = cache_cover(cover, cmime) if cover else ""
    lrc = sidecar_lrc(p)
    lrc_text = ""
    if lrc:
        try:
            with open(lrc, "r", encoding="utf-8", errors="replace") as f:
                lrc_text = f.read()
        except Exception:
            pass
    st = os.stat(p)
    return {"path": p, "tags": tags, "art": art, "embeddedArt": bool(cover), "folderArt": folder_cover(p),
            "duration": dur, "lrc": lrc, "lrcText": lrc_text, "size": st.st_size,
            "writable": os.access(p, os.W_OK), "format": os.path.splitext(p)[1][1:].upper(),
            "bitrate": _bitrate(p)}


def _bitrate(p):
    if not HAVE_MUTAGEN:
        return 0
    try:
        f = MFile(p)
        return int(getattr(f.info, "bitrate", 0) or 0) // 1000
    except Exception:
        return 0


def c_tags_write(rid, a):
    paths = a.get("paths") or [a["path"]]
    changes = {k: str(v) for k, v in (a.get("tags") or {}).items() if k in FIELDS}
    per = a.get("perTrack") or {}           # path -> {field: value} (e.g. track number)
    cover = a.get("cover") or {}
    mode = cover.get("mode", "keep")
    cdata = None
    if mode == "set":
        cdata, _m = read_image(cover["file"])
    lyrics_lrc = a.get("lrcSidecar")        # "delete" to remove the .lrc when saving embedded lyrics
    out, errors = [], []
    for i, p in enumerate(paths):
        if len(paths) > 1:
            emit({"event": "write", "id": rid, "done": i, "total": len(paths), "cur": os.path.basename(p)})
        try:
            ch = dict(changes)
            ch.update({k: str(v) for k, v in (per.get(p) or {}).items() if k in FIELDS})
            write_tags(p, ch, mode, cover_data=cdata)
            if lyrics_lrc == "delete":
                s = sidecar_lrc(p)
                if s:
                    try:
                        trash(s)
                    except Exception:
                        pass
            out.append(refresh_track(p))
        except Exception as e:
            errors.append(os.path.basename(p) + ": " + str(e))
    save_lib()
    if errors and not out:
        raise RuntimeError("; ".join(errors[:3]))
    return {"tracks": out, "errors": errors}


def c_cover_extract(rid, a):
    """Saves the embedded cover as an image next to the file (cover.jpg)."""
    p = a["path"]
    _t, cover, cmime, _d = read_tags(p, want_cover=True, want_lyrics=False)
    if not cover:
        raise ValueError("it has no cover")
    dst = os.path.join(os.path.dirname(p), "cover" + mime_ext(cmime, cover))
    with open(dst, "wb") as f:
        f.write(cover)
    return dst


def c_import(rid, a):
    return do_import(rid, a.get("paths") or [], a.get("mode") or "copy")


def c_pick(rid, a):
    return pick(a.get("title") or "Music", a.get("kind") or "audio")


def c_read_text(rid, a):
    with open(a["path"], "r", encoding="utf-8", errors="replace") as f:
        return f.read(2 * 1024 * 1024)


def c_lyrics_fetch(rid, a):
    return fetch_lyrics(a.get("artist"), a.get("title"), a.get("album"), a.get("duration"))


def c_lrc_save(rid, a):
    p = os.path.splitext(a["path"])[0] + ".lrc"
    txt = a.get("text") or ""
    if not txt.strip():
        if os.path.exists(p):
            trash(p)
        return ""
    with open(p, "w", encoding="utf-8") as f:
        f.write(txt)
    refresh_track(a["path"])
    return p


def c_remove(rid, a):
    """Removes from the library (without deleting) or sends to the trash (trash=true)."""
    prefs = load_prefs()
    excluded = set(prefs.get("excluded") or [])
    extra = list(prefs.get("extraFiles") or [])
    done = []
    for p in a.get("paths") or []:
        try:
            if a.get("trash"):
                trash(p)
                lrc = sidecar_lrc(p)
                if lrc:
                    trash(lrc)
            else:
                if p in extra:
                    extra.remove(p)
                else:
                    excluded.add(p)
            with _lib_lock:
                _lib.pop(p, None)
            done.append(p)
        except Exception as e:
            log("couldn't remove", p, e)
    save_prefs({"excluded": sorted(excluded), "extraFiles": extra})
    save_lib()
    return done


def c_prefs_save(rid, a):
    save_prefs(a.get("prefs") or {})
    return True


def c_state_save(rid, a):
    write_json(STATE_FILE, a.get("state") or {})
    return True


def c_playlists_save(rid, a):
    write_json(PLAYLISTS_FILE, a.get("playlists") or [])
    return True


def c_playlist_cover(rid, a):
    """Copies an image into the cache to use it as a playlist cover."""
    data, mime = read_image(a["file"])
    return cache_cover(data, mime)


def c_export_m3u(rid, a):
    dst = a["dest"]
    with open(dst, "w", encoding="utf-8") as f:
        f.write("#EXTM3U\n")
        for p in a.get("paths") or []:
            tr = _lib.get(p) or {}
            f.write("#EXTINF:%d,%s - %s\n%s\n" % (int(tr.get("dur") or 0), tr.get("ar", ""), tr.get("t", ""), p))
    return dst


def c_read_m3u(rid, a):
    base = os.path.dirname(a["path"])
    out = []
    with open(a["path"], "r", encoding="utf-8", errors="replace") as f:
        for l in f:
            l = l.strip()
            if not l or l.startswith("#"):
                continue
            if l.startswith("file://"):
                l = urllib.parse.unquote(l[7:])
            p = l if os.path.isabs(l) else os.path.normpath(os.path.join(base, l))
            if os.path.isfile(p):
                out.append(p)
    return out


def c_lib_dirs(rid, a):
    dirs = [os.path.expanduser(d) for d in (a.get("dirs") or []) if d]
    save_prefs({"libDirs": dirs or [music_dir()]})
    return load_prefs()["libDirs"]


def c_expand(rid, a):
    """Paths (files or folders) -> list of audio files, in natural order."""
    import re
    def nat(p):
        return [int(x) if x.isdigit() else x.lower() for x in re.split(r"(\d+)", p)]
    out = []
    for p in a.get("paths") or []:
        p = os.path.expanduser(p)
        if os.path.isdir(p):
            out.extend(sorted(walk_audio([p]), key=nat))
        elif os.path.isfile(p) and os.path.splitext(p)[1].lower() in AUDIO_EXT:
            out.append(p)
    return out


def c_mpris(rid, a):
    if MPRIS:
        MPRIS.update(dict(a))
    return None


def c_open_external(rid, a):
    subprocess.Popen(["xdg-open", a["path"]], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                     start_new_session=True)
    return True


# ── online search and download (spotdl) ──
_SEARCH_PY = r"""
import sys, json
from spotdl.utils.config import DEFAULT_CONFIG
from spotdl.utils.spotify import SpotifyClient
SpotifyClient.init(client_id=DEFAULT_CONFIG["client_id"], client_secret=DEFAULT_CONFIG["client_secret"],
                   user_auth=False, no_cache=True, headless=True)
q, n = sys.argv[1], int(sys.argv[2])
raw = SpotifyClient().search(q, "track", n) if n else SpotifyClient().search(q)
out = []
for t in ((raw or {}).get("tracks") or {}).get("items") or []:
    if not t:
        continue
    al = t.get("album") or {}
    imgs = al.get("images") or []
    out.append({
        "id": t.get("id") or "",
        "title": t.get("name") or "",
        "artists": [a.get("name") or "" for a in (t.get("artists") or [])],
        "album": al.get("name") or "",
        "year": (al.get("release_date") or "")[:4],
        "dur": (t.get("duration_ms") or 0) / 1000.0,
        "cover": (imgs[1] if len(imgs) > 1 else imgs[0])["url"] if imgs else "",
        "url": ((t.get("external_urls") or {}).get("spotify")) or ("https://open.spotify.com/track/" + str(t.get("id"))),
        "explicit": bool(t.get("explicit")),
    })
print("@@RESULT@@" + json.dumps(out))
"""
_dl_jobs = {}
_dl_sem = threading.Semaphore(2)
_ASYNC = object()


def spotdl_bin():
    cands = [load_prefs().get("spotdlPath") or "", shutil.which("spotdl") or "",
             os.path.expanduser("~/.local/bin/spotdl"), os.path.expanduser("~/.local/share/pipx/venvs/spotdl/bin/spotdl")]
    for c in cands:
        if c and os.path.isfile(c) and os.access(c, os.X_OK):
            return c
    return ""


def spotdl_python(binp):
    """Interpreter where spotdl is installed (pipx / venv / system), read from the shebang."""
    try:
        with open(binp, "rb") as f:
            first = f.readline().decode("utf-8", "replace").strip()
        if first.startswith("#!"):
            parts = first[2:].split()
            if parts and "python" in os.path.basename(parts[-1] if parts[0].endswith("env") else parts[0]):
                exe = parts[-1] if parts[0].endswith("env") else parts[0]
                return shutil.which(exe) or exe
    except Exception:
        pass
    return sys.executable


def c_online_status(rid, a):
    b = spotdl_bin()
    return {"available": bool(b), "path": b, "ffmpeg": bool(shutil.which("ffmpeg"))}


def c_online_search(rid, a):
    q = (a.get("query") or "").strip()
    if not q:
        return []
    b = spotdl_bin()
    if not b:
        raise RuntimeError("spotdl is not installed (or set its path in the preferences)")
    py = spotdl_python(b)
    try:
        r = subprocess.run([py, "-c", _SEARCH_PY, q, str(int(a.get("limit") or 15))],
                           capture_output=True, text=True, timeout=45)
    except subprocess.TimeoutExpired:
        raise RuntimeError("the search took too long")
    for line in (r.stdout or "").splitlines()[::-1]:
        if line.startswith("@@RESULT@@"):
            return json.loads(line[10:])
    err = (r.stderr or "").strip().splitlines()
    raise RuntimeError(err[-1] if err else "couldn't search online")


def _audio_snapshot(d):
    out = {}
    for root, _, files in os.walk(d):
        for fn in files:
            if os.path.splitext(fn)[1].lower() in AUDIO_EXT:
                fp = os.path.join(root, fn)
                try:
                    out[fp] = os.stat(fp).st_mtime
                except OSError:
                    pass
    return out


def _run_download(rid, a):
    with _dl_sem:
        try:
            b = spotdl_bin()
            if not b:
                raise RuntimeError("spotdl is not installed")
            prefs = load_prefs()
            dest = (prefs.get("libDirs") or [music_dir()])[0]
            os.makedirs(dest, exist_ok=True)
            fmt = a.get("fmt") if a.get("fmt") in ("mp3", "flac", "ogg", "opus", "m4a", "wav") else "mp3"
            target = a.get("url") or a.get("query") or ""
            cmd = [b, "download", target, "--output", os.path.join(dest, "{artists} - {title}.{output-ext}"),
                   "--format", fmt, "--print-errors", "--simple-tui"]
            if a.get("synced", True):
                cmd += ["--generate-lrc", "--lyrics", "synced", "genius"]
            before = _audio_snapshot(dest)
            t0 = time.time()
            env = dict(os.environ, NO_COLOR="1", TERM="dumb", PYTHONUNBUFFERED="1")
            proc = subprocess.Popen(cmd, cwd=dest, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                    text=True, env=env, bufsize=1)
            _dl_jobs[rid] = proc
            tail = []
            alllines = []
            for line in proc.stdout:
                line = line.strip()
                if not line:
                    continue
                tail = (tail + [line])[-12:]
                alllines.append(line)
                emit({"event": "dl", "id": rid, "line": line[:300]})
            code = proc.wait()
            if code != 0 and rid not in _dl_jobs:
                raise RuntimeError("cancelled")
            after = _audio_snapshot(dest)
            new = [p for p, mt in after.items() if p not in before or mt >= t0 - 1]
            alltxt = "\n".join(alllines).lower()
            if code == 0 and not new and ("already exists" in alltxt or "skipping" in alltxt):
                emit({"id": rid, "ok": True, "data": {"paths": [], "tracks": [], "exists": True}})
                return
            if code != 0 or not new:
                keys = ("error", "exception", "no results", "unable", "failed", "could not", "lookup", "not found", "forbidden", "sign in")
                bad = [l for l in alllines if any(k in l.lower() for k in keys)]
                msg = (bad or tail or ["spotdl failed (code %s)" % code])[-1]
                if code == 0 and not new:
                    msg = "spotdl didn't save any file: " + msg + " (try updating: pip install -U spotdl yt-dlp)"
                raise RuntimeError(msg[:260])
            tracks = []
            for p in new:
                try:
                    tracks.append(refresh_track(p))
                except Exception as e:
                    log("refresh", p, e)
            emit({"id": rid, "ok": True, "data": {"paths": new, "tracks": tracks}})
        except Exception as e:
            emit({"id": rid, "ok": False, "error": str(e) or type(e).__name__})
        finally:
            _dl_jobs.pop(rid, None)


def c_online_download(rid, a):
    threading.Thread(target=_run_download, args=(rid, a), daemon=True).start()
    return _ASYNC


def c_online_cancel(rid, a):
    p = _dl_jobs.pop(a.get("target"), None)
    if p:
        try:
            p.terminate()
        except Exception:
            pass
    return True


COMMANDS = {
    "init": c_init, "scan": c_scan, "track_get": c_track_get, "tags_write": c_tags_write,
    "cover_extract": c_cover_extract, "import": c_import, "pick": c_pick, "read_text": c_read_text,
    "lyrics_fetch": c_lyrics_fetch, "lrc_save": c_lrc_save, "remove": c_remove,
    "prefs_save": c_prefs_save, "state_save": c_state_save, "playlists_save": c_playlists_save,
    "playlist_cover": c_playlist_cover, "export_m3u": c_export_m3u, "read_m3u": c_read_m3u,
    "online_status": c_online_status, "online_search": c_online_search,
    "online_download": c_online_download, "online_cancel": c_online_cancel,
    "lib_dirs": c_lib_dirs, "mpris": c_mpris, "expand": c_expand, "open_external": c_open_external,
}
# quick commands run on the reader thread
INLINE = {"mpris", "prefs_save", "state_save", "playlists_save"}


def handle(req):
    rid = req.get("id")
    cmd = req.get("cmd")
    fn = COMMANDS.get(cmd)
    if fn is None:
        emit({"id": rid, "ok": False, "error": "comando desconocido: %s" % cmd})
        return
    try:
        data = fn(rid, req.get("args") or {})
        if cmd != "mpris" and data is not _ASYNC:
            emit({"id": rid, "ok": True, "data": data})
    except Exception as e:
        log(cmd, "→", "".join(traceback.format_exception_only(type(e), e)).strip())
        emit({"id": rid, "ok": False, "error": str(e) or type(e).__name__})


def main():
    global MPRIS
    if os.environ.get("QS_MUSIC_NO_MPRIS") != "1":
        MPRIS = Mpris()
    pool = ThreadPoolExecutor(max_workers=4)
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            req = json.loads(line)
        except Exception:
            continue
        if req.get("cmd") in INLINE:
            handle(req)
        else:
            pool.submit(handle, req)
    pool.shutdown(wait=False, cancel_futures=True)
    if _lib_dirty:
        save_lib()


if __name__ == "__main__":
    main()
