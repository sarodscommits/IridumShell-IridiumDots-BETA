import QtQuick
import Quickshell
import Quickshell.Io

// Camera/microphone usage watcher for the privacy indicator
RecordingServices {
    Process {
        id: privWatchProcess
        property int failures: 0
        readonly property bool wanted: globalState.deferredReady && globalState.barModules.privacy
        running: wanted
        onWantedChanged: { failures = 0; running = wanted; }
        stdinEnabled: true
        command: ["python3", "-u", "-c",
        "import os, sys, json, re, select, subprocess\n" +
        "IGNORE = set()\n" +
        "try:\n" +
        "    IGNORE = set(s.lower() for s in json.loads(sys.argv[1]))\n" +
        "except Exception:\n" +
        "    pass\n" +
        "PW = ('pipewire', 'wireplumber', 'pipewire-pulse')\n" +
        "def run(a):\n" +
        "    try:\n" +
        "        r = subprocess.run(a, capture_output=True, timeout=4)\n" +
        "        return r.stdout if r.returncode == 0 else None\n" +
        "    except Exception:\n" +
        "        return None\n" +
        "def comm(pid):\n" +
        "    try:\n" +
        "        with open('/proc/%d/comm' % pid) as f: return f.read().strip()\n" +
        "    except OSError:\n" +
        "        return ''\n" +
        "def ignored(*names):\n" +
        "    return any(n and n.lower() in IGNORE for n in names)\n" +
        "def scan():\n" +
        "    cam, snd = {}, {}\n" +
        "    for p in os.listdir('/proc'):\n" +
        "        if not p.isdigit(): continue\n" +
        "        d = '/proc/' + p + '/fd'\n" +
        "        try: fds = os.listdir(d)\n" +
        "        except OSError: continue\n" +
        "        for fd in fds:\n" +
        "            try: t = os.readlink(d + '/' + fd)\n" +
        "            except OSError: continue\n" +
        "            if t.startswith('/dev/video'): cam.setdefault(t, set()).add(int(p))\n" +
        "            elif t.startswith('/dev/snd/pcmC') and t.endswith('c'): snd.setdefault(t, set()).add(int(p))\n" +
        "    return cam, snd\n" +
        "def cam_name(dev):\n" +
        "    try:\n" +
        "        with open('/sys/class/video4linux/' + os.path.basename(dev) + '/name') as f: return f.read().strip()\n" +
        "    except OSError:\n" +
        "        return os.path.basename(dev)\n" +
        "def card_name(dev):\n" +
        "    m = re.match(r'/dev/snd/pcmC(\\d+)D', dev)\n" +
        "    if m:\n" +
        "        try:\n" +
        "            for l in open('/proc/asound/cards'):\n" +
        "                mm = re.match(r'\\s*(\\d+)\\s+\\[[^\\]]*\\]:\\s*(.*?)\\s+-\\s+(.*)', l)\n" +
        "                if mm and mm.group(1) == m.group(1): return mm.group(3).strip()\n" +
        "        except OSError:\n" +
        "            pass\n" +
        "    return os.path.basename(dev)\n" +
        "def pw_video_apps():\n" +
        "    raw = run(['pw-dump'])\n" +
        "    out = []\n" +
        "    try:\n" +
        "        for o in json.loads(raw or b'[]'):\n" +
        "            if o.get('type') != 'PipeWire:Interface:Node': continue\n" +
        "            i = o.get('info') or {}\n" +
        "            pr = i.get('props') or {}\n" +
        "            if pr.get('media.class') == 'Stream/Input/Video' and i.get('state') == 'running':\n" +
        "                n = pr.get('application.name') or pr.get('application.process.binary') or pr.get('node.name') or '?'\n" +
        "                if not ignored(n, pr.get('application.process.binary')): out.append(n)\n" +
        "    except Exception:\n" +
        "        pass\n" +
        "    return out\n" +
        "def pactl(what):\n" +
        "    raw = run(['pactl', '-f', 'json', 'list', what])\n" +
        "    if raw is None: return None\n" +
        "    try: return json.loads(raw)\n" +
        "    except Exception: return None\n" +
        "def mic_from_pactl():\n" +
        "    so = pactl('source-outputs')\n" +
        "    if so is None: return None\n" +
        "    used = {}\n" +
        "    for s in so:\n" +
        "        if s.get('corked'): continue\n" +
        "        pr = s.get('properties') or {}\n" +
        "        if 'peak' in (pr.get('media.name') or '').lower(): continue\n" +
        "        app = pr.get('application.name') or pr.get('application.process.binary') or '?'\n" +
        "        if ignored(app, pr.get('application.process.binary')): continue\n" +
        "        used.setdefault(s.get('source'), []).append(app)\n" +
        "    if not used: return []\n" +
        "    res = []\n" +
        "    for src in (pactl('sources') or []):\n" +
        "        idx = src.get('index')\n" +
        "        if idx not in used: continue\n" +
        "        mon = src.get('monitor_of_sink')\n" +
        "        if (mon not in (None, '', 'n/a')) or (src.get('name') or '').endswith('.monitor'): continue\n" +
        "        res.append({'dev': src.get('description') or src.get('name') or '?', 'src': src.get('name') or '',\n" +
        "                    'muted': bool(src.get('mute')), 'apps': sorted(set(used[idx]))})\n" +
        "    return res\n" +
        "def probe():\n" +
        "    have_cam = any(n.startswith('video') for n in os.listdir('/dev'))\n" +
        "    mic = mic_from_pactl()\n" +
        "    cam_out, mic_direct = [], []\n" +
        "    if have_cam or mic is None:\n" +
        "        cam, snd = scan()\n" +
        "        devs = {}\n" +
        "        for dev, pids in cam.items():\n" +
        "            name = cam_name(dev)\n" +
        "            apps = devs.setdefault(name, set())\n" +
        "            for pid in pids:\n" +
        "                c = comm(pid)\n" +
        "                if c in PW: apps.update(pw_video_apps() or ['PipeWire'])\n" +
        "                elif not ignored(c): apps.add(c or str(pid))\n" +
        "        cam_out = [{'dev': k, 'apps': sorted(v)} for k, v in sorted(devs.items()) if v]\n" +
        "        if mic is None:\n" +
        "            cards = {}\n" +
        "            for dev, pids in snd.items():\n" +
        "                apps = set(c for c in (comm(p) for p in pids) if c and not ignored(c))\n" +
        "                if apps: cards.setdefault(card_name(dev), set()).update(apps)\n" +
        "            mic_direct = [{'dev': k, 'src': '', 'muted': False, 'apps': sorted(v)} for k, v in sorted(cards.items())]\n" +
        "    return {'cam': cam_out, 'mic': mic if mic is not None else mic_direct}\n" +
        "last = None\n" +
        "while True:\n" +
        "    try:\n" +
        "        st = json.dumps(probe(), sort_keys=True)\n" +
        "        if st != last:\n" +
        "            last = st\n" +
        "            print(st, flush=True)\n" +
        "    except Exception as e:\n" +
        "        print(json.dumps({'err': str(e)}), file=sys.stderr, flush=True)\n" +
        "    r, _, _ = select.select([sys.stdin], [], [], 2.0)\n" +
        "    if r and not sys.stdin.readline():\n" +
        "        break\n",
        JSON.stringify(globalState.privIgnoreApps)]
        stdout: SplitParser { onRead: (line) => { privWatchProcess.failures = 0; applyPriv(line); } }
        onRunningChanged: {
            if (!running) {
                if (wanted && failures < 5) { failures++; privWatchRestartTimer.start(); }
                else if (!wanted) { globalState.privCamDevs = []; globalState.privMicDevs = []; }
            }
        }
        function refresh() { if (running) write("r\n"); }
    }

    Timer { id: privWatchRestartTimer; interval: 3000; repeat: false; onTriggered: if (privWatchProcess.wanted) privWatchProcess.running = true }
    Timer { id: privRefreshTimer; interval: 250; repeat: false; onTriggered: privWatchProcess.refresh() }
    Timer { id: privRevealTimer; interval: 3500; repeat: false; onTriggered: globalState.privRevealed = false }

    function applyPriv(raw) {
        var d;
        try { d = JSON.parse((raw || "").trim()); } catch (e) { return; }
        if (!d || typeof d !== "object") return;
        var cam = Array.isArray(d.cam) ? d.cam : [];
        var mic = Array.isArray(d.mic) ? d.mic : [];
        var newCam = cam.length > 0 && !globalState.privCamActive;
        var newMic = mic.length > 0 && !globalState.privMicActive;
        globalState.privCamDevs = cam;
        globalState.privMicDevs = mic;
        if (newCam || newMic) {
            globalState.privRevealed = true;
            privRevealTimer.restart();
        }
        if (!globalState.privActive) {
            privRevealTimer.stop();
            globalState.privRevealed = false;
            globalState.privBulgeOpen = false;
        }
    }

    function privToggleMute(src) {
        if (!src) return;
        Quickshell.execDetached(["pactl", "set-source-mute", src, "toggle"]);
        privRefreshTimer.restart();
    }
}
