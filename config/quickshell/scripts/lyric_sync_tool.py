#!/usr/bin/env python3
# LyricSync helper: `peaks` and `cut`, prints one JSON line.
import json
import os
import shutil
import subprocess
import sys
import tempfile
from array import array


def out(obj):
    sys.stdout.write(json.dumps(obj, ensure_ascii=False, separators=(",", ":")) + "\n")
    sys.stdout.flush()


def fail(msg):
    out({"ok": False, "error": str(msg)})
    sys.exit(0)


def need_ffmpeg():
    if not shutil.which("ffmpeg"):
        fail("ffmpeg is not installed (sudo pacman -S ffmpeg)")


# ───────────────────────── waveform ─────────────────────────
def cmd_peaks(path, rate=100):
    need_ffmpeg()
    rate = max(10, min(400, int(rate)))
    sr = 8000 if rate <= 200 else 16000
    bucket = max(1, sr // rate)
    p = subprocess.run(
        ["ffmpeg", "-v", "error", "-nostdin", "-i", path, "-map", "0:a:0", "-ac", "1", "-ar", str(sr), "-f", "s16le", "-"],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    )
    if p.returncode != 0 and not p.stdout:
        fail((p.stderr.decode("utf-8", "replace").strip().splitlines() or ["ffmpeg failed"])[-1])
    data = p.stdout
    if len(data) % 2:
        data = data[:-1]
    smp = array("h")
    smp.frombytes(data)
    if sys.byteorder != "little":
        smp.byteswap()
    n = len(smp)
    peaks = []
    for i in range(0, n, bucket):
        ch = smp[i:i + bucket]
        hi = max(ch)
        lo = min(ch)
        peaks.append(max(hi, -lo))
    top = max(peaks) if peaks else 0
    if top <= 0:
        top = 1
    # a gentle curve (square root) so the quiet parts are visible too
    norm = [round((v / top) ** 0.75, 3) for v in peaks]
    out({"ok": True, "dur": n / float(sr), "rate": sr / float(bucket), "peaks": norm})


# ───────────────────────── trimming ─────────────────────────
CODECS = {
    "mp3":  ["-c:a", "libmp3lame"],
    "m4a":  ["-c:a", "aac"],
    "mp4":  ["-c:a", "aac"],
    "aac":  ["-c:a", "aac"],
    "flac": ["-c:a", "flac"],
    "ogg":  ["-c:a", "libvorbis", "-q:a", "7"],
    "oga":  ["-c:a", "libvorbis", "-q:a", "7"],
    "opus": ["-c:a", "libopus", "-b:a", "192k"],
    "wav":  ["-c:a", "pcm_s16le"],
    "aif":  ["-c:a", "pcm_s16be"],
    "aiff": ["-c:a", "pcm_s16be"],
}


def probe_bitrate(path):
    try:
        p = subprocess.run(["ffprobe", "-v", "error", "-select_streams", "a:0", "-show_entries",
                            "stream=bit_rate", "-of", "default=nw=1:nk=1", path],
                           stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
        return int(p.stdout.strip().splitlines()[0])
    except Exception:
        return 0


def probe_dur(path):
    try:
        p = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
                            "-of", "default=nw=1:nk=1", path],
                           stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
        return float(p.stdout.strip())
    except Exception:
        return 0.0


def copy_tags(src, dst):
    """Copies the tags from src to dst with mutagen. Returns True if it could."""
    try:
        import mutagen
        from mutagen.id3 import ID3, ID3NoHeaderError
    except Exception:
        return False
    ext = os.path.splitext(src)[1].lower()
    try:
        if ext == ".mp3":
            try:
                tags = ID3(src)
            except ID3NoHeaderError:
                return True
            tags.delall("SYLT")       # binary synced lyrics: would no longer line up
            tags.delall("TLEN")       # stale duration
            tags.save(dst, v2_version=3)
            return True
        s = mutagen.File(src)
        d = mutagen.File(dst)
        if s is None or d is None or s.tags is None:
            return True
        if d.tags is None:
            d.add_tags()
        if ext == ".flac":
            for k, v in s.tags.items():
                d.tags[k] = v
            d.clear_pictures()
            for pic in s.pictures:
                d.add_picture(pic)
        else:
            for k in list(s.tags.keys()):
                try:
                    d.tags[k] = s.tags[k]
                except Exception:
                    pass
        d.save()
        return True
    except Exception as e:
        sys.stderr.write("copy_tags: %s\n" % e)
        return False


def cmd_cut(path, ranges_json, backup="1"):
    need_ffmpeg()
    try:
        ranges = [(float(a), float(b)) for a, b in json.loads(ranges_json)]
    except Exception:
        fail("invalid sections")
    ranges = [(max(0.0, a), b) for a, b in ranges if b - a > 0.01]
    if not ranges:
        fail("no audio left")
    if not os.path.isfile(path):
        fail("the file doesn't exist")
    if not os.access(path, os.W_OK) or not os.access(os.path.dirname(path) or ".", os.W_OK):
        fail("no write permission")

    ext = os.path.splitext(path)[1].lower().lstrip(".")
    fd, tmp = tempfile.mkstemp(prefix=".lyrsync-", suffix="." + ext, dir=os.path.dirname(path) or ".")
    os.close(fd)
    have_mutagen = True
    try:
        import mutagen  # noqa: F401
    except Exception:
        have_mutagen = False

    lossless = len(ranges) == 1
    cmd = ["ffmpeg", "-v", "error", "-nostdin", "-y"]
    if lossless:
        a, b = ranges[0]
        cmd += ["-i", path, "-ss", "%.3f" % a, "-to", "%.3f" % b, "-map", "0:a:0", "-c:a", "copy"]
    else:
        parts = []
        for i, (a, b) in enumerate(ranges):
            parts.append("[0:a:0]atrim=start=%.4f:end=%.4f,asetpts=PTS-STARTPTS[a%d]" % (a, b, i))
        fc = ";".join(parts) + ";" + "".join("[a%d]" % i for i in range(len(ranges))) + \
            "concat=n=%d:v=0:a=1[out]" % len(ranges)
        cmd += ["-i", path, "-filter_complex", fc, "-map", "[out]"]
        codec = CODECS.get(ext)
        if codec is None:
            os.unlink(tmp)
            fail("unsupported format for cutting in the middle: ." + ext)
        cmd += codec
        br = probe_bitrate(path)
        if ext == "mp3":
            cmd += ["-b:a", "%dk" % max(128, min(320, round(br / 1000)))] if br else ["-q:a", "0"]
        elif ext in ("m4a", "mp4", "aac"):
            cmd += ["-b:a", "%dk" % max(128, min(320, round(br / 1000)))] if br else ["-b:a", "256k"]

    if have_mutagen:
        cmd += ["-map_metadata", "-1"]
        if ext == "mp3":
            cmd += ["-write_xing", "1", "-id3v2_version", "0"]
    else:
        # without mutagen: ffmpeg copies what it can (including the cover)
        cmd += ["-map_metadata", "0"]
        if ext in ("mp3", "m4a", "mp4", "flac"):
            cmd += ["-map", "0:v?", "-c:v", "copy", "-disposition:v", "attached_pic"]
        if ext == "mp3":
            cmd += ["-id3v2_version", "3"]
    cmd += [tmp]

    p = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if p.returncode != 0 or not os.path.getsize(tmp):
        try:
            os.unlink(tmp)
        except OSError:
            pass
        fail((p.stderr.decode("utf-8", "replace").strip().splitlines() or ["ffmpeg failed"])[-1])

    if have_mutagen:
        copy_tags(path, tmp)

    bak = ""
    if str(backup) == "1":
        bak = path + ".bak"
        n = 1
        while os.path.exists(bak):
            n += 1
            bak = "%s.bak%d" % (path, n)
        try:
            shutil.copy2(path, bak)
        except Exception as e:
            os.unlink(tmp)
            fail("couldn't create the backup: %s" % e)
    try:
        st = os.stat(path)
        os.chmod(tmp, st.st_mode & 0o7777)
    except OSError:
        pass
    os.replace(tmp, path)
    out({"ok": True, "path": path, "dur": probe_dur(path), "lossless": lossless, "backup": bak})


def main():
    a = sys.argv[1:]
    if not a:
        fail("usage: peaks|cut …")
    try:
        if a[0] == "peaks" and len(a) >= 2:
            cmd_peaks(a[1], a[2] if len(a) > 2 else 100)
        elif a[0] == "cut" and len(a) >= 3:
            cmd_cut(a[1], a[2], a[3] if len(a) > 3 else "1")
        else:
            fail("unknown command")
    except SystemExit:
        raise
    except Exception as e:
        fail(e)


if __name__ == "__main__":
    main()
