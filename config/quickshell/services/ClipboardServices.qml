import QtQuick
import Quickshell
import Quickshell.Io

// Clipboard watch, probe, copy/clear and image handling
BatteryServices {
    property alias clipCopyProcess: clipCopyProcess
    property alias clipProbeProcess: clipProbeProcess

    Process {
        id: clipWatchProcess
        property int failures: 0
        running: globalState.deferredReady
        command: ["bash", "-c", "command -v wl-paste >/dev/null 2>&1 || exit 1; exec wl-paste --watch echo x"]
        stdout: SplitParser { onRead: (line) => { clipWatchProcess.failures = 0; clipProbeDebounce.restart(); } }
        onRunningChanged: {
            if (!running && globalState.deferredReady && failures < 5) { failures++; clipWatchRestartTimer.start(); }
        }
    }

    Timer { id: clipWatchRestartTimer; interval: 3000; repeat: false; onTriggered: clipWatchProcess.running = true }
    Timer { id: clipProbeDebounce; interval: 120; repeat: false; onTriggered: clipProbeProcess.request() }

    Timer {
        interval: clipWatchProcess.running ? 20000 : 2000
        running: globalState.deferredReady; repeat: true
        onTriggered: clipProbeProcess.request()
    }

    Process {
        id: clipProbeProcess
        property bool _again: false
        property bool primed: false
        running: false
        command: ["python3", "-c",
        "import subprocess, json, os, sys, hashlib, urllib.parse\n" +
        "def run(a):\n" +
        "    try:\n" +
        "        r = subprocess.run(a, capture_output=True, timeout=4)\n" +
        "        return r.stdout if r.returncode == 0 else None\n" +
        "    except Exception:\n" +
        "        return None\n" +
        "def out(d):\n" +
        "    print(json.dumps(d)); sys.exit(0)\n" +
        "raw = run(['wl-paste', '--list-types'])\n" +
        "if not raw: out({'kind': 'none'})\n" +
        "types = [t.strip() for t in raw.decode('utf-8', 'ignore').splitlines() if t.strip()]\n" +
        "if 'x-kde-passwordManagerHint' in types: out({'kind': 'secret'})\n" +
        "cache = os.path.expanduser('~/.cache/qs-clipboard')\n" +
        "os.makedirs(cache, exist_ok=True)\n" +
        "if 'text/uri-list' in types:\n" +
        "    files = []\n" +
        "    for l in (run(['wl-paste', '-n', '-t', 'text/uri-list']) or b'').decode('utf-8', 'ignore').splitlines():\n" +
        "        l = l.strip()\n" +
        "        if not l.startswith('file://'): continue\n" +
        "        p = urllib.parse.unquote(urllib.parse.urlparse(l).path)\n" +
        "        isf = os.path.isfile(p)\n" +
        "        files.append({'path': p, 'name': os.path.basename(p.rstrip('/')) or p, 'dir': os.path.isdir(p), 'size': os.path.getsize(p) if isf else -1})\n" +
        "    if files: out({'kind': 'files', 'files': files})\n" +
        "img = next((t for t in types if t.startswith('image/')), None)\n" +
        "if img:\n" +
        "    data = run(['wl-paste', '-t', img])\n" +
        "    if data:\n" +
        "        ext = img.split('/')[1].split('+')[0].split(';')[0] or 'png'\n" +
        "        path = os.path.join(cache, 'clip-' + hashlib.sha1(data).hexdigest()[:12] + '.' + ext)\n" +
        "        if not os.path.exists(path):\n" +
        "            with open(path, 'wb') as f: f.write(data)\n" +
        "            old = sorted((os.path.join(cache, n) for n in os.listdir(cache) if n.startswith('clip-')), key=os.path.getmtime)\n" +
        "            for o in old[:-8]:\n" +
        "                try: os.remove(o)\n" +
        "                except OSError: pass\n" +
        "        out({'kind': 'image', 'path': path, 'mime': img, 'bytes': len(data)})\n" +
        "if any(t.startswith('text/') or t in ('UTF8_STRING', 'STRING', 'TEXT') for t in types):\n" +
        "    txt = run(['wl-paste', '-n', '-t', 'text']) or run(['wl-paste', '-n'])\n" +
        "    if txt is not None: out({'kind': 'text', 'text': txt.decode('utf-8', 'replace')[:200000]})\n" +
        "out({'kind': 'none'})\n"
        ]
        stdout: StdioCollector { onStreamFinished: applyClip(this.text) }
        onRunningChanged: { if (!running && _again) { _again = false; running = true; } }
        function request() { if (running) _again = true; else running = true; }
    }

    Process {
        id: clipCopyProcess
        running: false
        stdinEnabled: true
        property bool _busy: false
        property var  _pending: null
        command: ["bash", "-c", "exec wl-copy \"$@\" >/dev/null 2>&1", "qs-wlcopy"]
        function copy(args, data) {
            if (_busy) { _pending = { args: args, data: data }; return; }
            _busy = true;
            command = ["bash", "-c", "exec wl-copy \"$@\" >/dev/null 2>&1", "qs-wlcopy"].concat(args);
            running = true;
            write(data);
            stdinEnabled = false;
        }
        onRunningChanged: {
            if (!running) {
                _busy = false;
                stdinEnabled = true;
                if (globalState.clipClearing) _pending = null;
                if (_pending) { var p = _pending; _pending = null; copy(p.args, p.data); }
            }
        }
    }

    function applyClip(raw) {
        var d;
        try { d = JSON.parse((raw || "").trim()); } catch (e) { return; }
        if (!d || !d.kind) return;
        if (globalState.clipClearing) return;
        if (d.kind === "text" && (d.text || "") === "") d = { kind: "none" };
        if (globalState.clipEditing && d.kind === "text") return;
        var sig = d.kind;
        if (d.kind === "text") sig += "|" + d.text;
        else if (d.kind === "image") sig += "|" + d.path;
        else if (d.kind === "files") sig += "|" + d.files.map(function (f) { return f.path; }).join("\n");
        var first = !clipProbeProcess.primed;
        clipProbeProcess.primed = true;
        if (sig === globalState.clipSig) return;
        globalState.clipSig = sig;
        if (d.kind !== "text" && d.kind !== "image" && d.kind !== "files") {
            globalState.clipKind = d.kind === "secret" ? "secret" : "";
            globalState.clipText = ""; globalState.clipImagePath = ""; globalState.clipFiles = [];
            globalState.clipBulgeOpen = false;
            globalState.clipOpenOnNext = false;
            return;
        }
        globalState.clipText       = d.kind === "text"  ? d.text  : "";
        globalState.clipImagePath  = d.kind === "image" ? d.path  : "";
        globalState.clipImageMime  = d.kind === "image" ? d.mime  : "";
        globalState.clipImageBytes = d.kind === "image" ? d.bytes : 0;
        globalState.clipFiles      = d.kind === "files" ? d.files : [];
        globalState.clipKind       = d.kind;
        if (first) return;
        var manual = globalState.clipOpenOnNext;
        globalState.clipOpenOnNext = false;
        globalState.openClipBulge(!manual);
    }

    function handleClipDrop(drop) {
        globalState.clipDragHover = false;
        var local = [], remote = [];
        if (drop.hasUrls) {
            for (var i = 0; i < drop.urls.length; i++) {
                var u = drop.urls[i].toString();
                if (u.indexOf("file://") === 0) local.push(u); else remote.push(u);
            }
        }
        if (local.length > 0) {
            clipCopyProcess.copy(["--type", "text/uri-list"], local.join("\r\n") + "\r\n");
        } else if (remote.length === 1 && /^https?:\/\/.+\.(png|jpe?g|gif|webp|bmp|avif)(\?.*)?$/i.test(remote[0])) {
            Quickshell.execDetached(["bash", "-c",
                "d=\"$HOME/.cache/qs-clipboard\"; mkdir -p \"$d\"; f=\"$d/drop-$(date +%s%N)\"; " +
                "curl -sL --max-time 15 \"$1\" -o \"$f\" && wl-copy < \"$f\"", "qs-clipdrop", remote[0]]);
        } else if (drop.hasText && drop.text !== "") {
            clipCopyProcess.copy([], drop.text);
        } else if (remote.length > 0) {
            clipCopyProcess.copy([], remote.join("\n"));
        } else return;
        globalState.clipOpenOnNext = true;
        if (globalState.clipHasContent) globalState.openClipBulge(false);
        drop.accept(Qt.CopyAction);
    }

    function clipIsImage(p) { return /\.(png|jpe?g|gif|webp|bmp|svg|avif|tiff?)$/i.test(p || ""); }
    function fileUrl(p) { return "file://" + encodeURI(p).replace(/#/g, "%23").replace(/\?/g, "%3F"); }

    function fmtBytes(b) {
        if (b === undefined || b < 0) return "";
        if (b < 1024) return b + " B";
        if (b < 1048576) return (b / 1024).toFixed(1) + " KB";
        return (b / 1048576).toFixed(1) + " MB";
    }

    function clipOpen(p) { if (p) Quickshell.execDetached(["xdg-open", p]); }

    function clipClear() {
        if (clipClearProcess.running) return;
        globalState.clipClearing = true;
        clipCopyProcess._pending = null;
        globalState.clipEditing = false;
        globalState.clipBulgeOpen  = false;
        globalState.clipOpenOnNext = false;
        globalState.clipText = ""; globalState.clipImagePath = ""; globalState.clipImageMime = "";
        globalState.clipImageBytes = 0; globalState.clipFiles = [];
        globalState.clipKind = "";
        globalState.clipSig  = "none";
        clipClearProcess.running = true;
        clipClearGuard.restart();
    }

    Process {
        id: clipClearProcess
        running: false
        command: ["bash", "-c",
        "wl-copy --clear >/dev/null 2>&1\n" +
        "for i in 1 2 3 4 5 6; do\n" +
        "  sleep 0.15\n" +
        "  t=$(timeout 1 wl-paste --list-types 2>/dev/null)\n" +
        "  [ -z \"$t\" ] && exit 0\n" +
        "  if [ $i -ge 3 ]; then printf '' | timeout 2 wl-copy --type text/plain >/dev/null 2>&1\n" +
        "  else wl-copy --clear >/dev/null 2>&1; fi\n" +
        "done\n" +
        "exit 0\n"]
        onRunningChanged: {
            if (!running) {
                clipClearGuard.stop();
                globalState.clipClearing = false;
                clipProbeProcess.request();
            }
        }
    }

    Timer {
        id: clipClearGuard
        interval: 5000; repeat: false
        onTriggered: {
            clipClearProcess.running = false;
            globalState.clipClearing = false;
            clipProbeProcess.request();
        }
    }

    function clipSaveImage() {
        if (!globalState.clipImagePath) return;
        Quickshell.execDetached(["bash", "-c",
            "dir=$(xdg-user-dir PICTURES 2>/dev/null); [ -d \"$dir\" ] || dir=\"$HOME/Pictures\"; mkdir -p \"$dir\"; " +
            "f=\"$dir/clipboard-$(date +%Y%m%d-%H%M%S).${1##*.}\"; cp \"$1\" \"$f\" && notify-send 'Clipboard' \"Saved to $f\"",
            "qs-clipsave", globalState.clipImagePath]);
    }
}
