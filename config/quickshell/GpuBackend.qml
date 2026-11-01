import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    // Only polls while stats are visible
    property bool   active: false
    property int    intervalMs: 1500
    property string socketPath: "/run/lactd.sock"
    // Empty = auto (dedicated GPU first), else a list_devices id
    property string deviceId: ""

    readonly property bool available: _ok
    property bool   _ok: false
    property string lastError: ""

    signal statsUpdated(var s)
    signal unavailable(string reason)

    readonly property string _script:
        "import socket, json, sys, time\n" +
        "SOCK, WANT, IV = sys.argv[1], sys.argv[2], max(0.3, float(sys.argv[3]))\n" +
        "def req(cmd, args=None):\n" +
        "    p = {'command': cmd}\n" +
        "    if args is not None: p['args'] = args\n" +
        "    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)\n" +
        "    s.settimeout(3)\n" +
        "    try:\n" +
        "        s.connect(SOCK)\n" +
        "        s.sendall((json.dumps(p) + '\\n').encode())\n" +
        "        buf = b''\n" +
        "        obj = None\n" +
        "        dec = json.JSONDecoder()\n" +
        "        while obj is None:\n" +
        "            chunk = s.recv(262144)\n" +
        "            if not chunk: raise ConnectionError('lactd closed the connection without replying')\n" +
        "            buf += chunk\n" +
        "            try:\n" +
        "                obj, _ = dec.raw_decode(buf.decode('utf-8').strip())\n" +
        "            except ValueError:\n" +
        "                obj = None\n" +
        "    finally:\n" +
        "        s.close()\n" +
        "    if obj.get('status') != 'ok': raise RuntimeError(str(obj.get('data')))\n" +
        "    return obj.get('data')\n" +
        "def pick():\n" +
        "    devs = req('list_devices') or []\n" +
        "    if not devs: raise RuntimeError('LACT found no GPU')\n" +
        "    for d in devs:\n" +
        "        if WANT and d.get('id') == WANT: return d\n" +
        "    for d in devs:\n" +
        "        if d.get('device_type', 'Dedicated') == 'Dedicated': return d\n" +
        "    return devs[0]\n" +
        "def temp(v):\n" +
        "    if isinstance(v, dict):\n" +
        "        if 'current' in v: return v.get('current')\n" +
        "        if isinstance(v.get('value'), dict): return v['value'].get('current')\n" +
        "    return None\n" +
        "def mib(b): return round(b / 1048576) if isinstance(b, (int, float)) else None\n" +
        "dev = None\n" +
        "last_err = None\n" +
        "while True:\n" +
        "    try:\n" +
        "        if dev is None: dev = pick()\n" +
        "        st = req('device_stats', {'id': dev['id']}) or {}\n" +
        "        temps = {k: temp(v) for k, v in (st.get('temps') or {}).items()}\n" +
        "        vram = st.get('vram') or {}\n" +
        "        pw = st.get('power') or {}\n" +
        "        ck = st.get('clockspeed') or {}\n" +
        "        fan = st.get('fan') or {}\n" +
        "        pwm = fan.get('pwm_current')\n" +
        "        out = {\n" +
        "            'ok': True, 'id': dev['id'], 'name': dev.get('name') or dev['id'],\n" +
        "            'busy': st.get('busy_percent'),\n" +
        "            'temps': temps,\n" +
        "            'vram_used': mib(vram.get('used')), 'vram_total': mib(vram.get('total')),\n" +
        "            'power': pw.get('average') if pw.get('average') is not None else pw.get('current'),\n" +
        "            'power_cap': pw.get('cap_current'),\n" +
        "            'gpu_clock': ck.get('gpu_clockspeed'), 'vram_clock': ck.get('vram_clockspeed'),\n" +
        "            'fan_rpm': fan.get('speed_current'),\n" +
        "            'fan_pct': round(pwm / 255 * 100) if isinstance(pwm, (int, float)) else None,\n" +
        "            'perf_level': st.get('performance_level'),\n" +
        "        }\n" +
        "        print(json.dumps(out), flush=True)\n" +
        "        last_err = None\n" +
        "    except Exception as e:\n" +
        "        dev = None\n" +
        "        msg = str(e) or e.__class__.__name__\n" +
        "        if msg != last_err:\n" +
        "            print(json.dumps({'ok': False, 'err': msg}), flush=True)\n" +
        "            last_err = msg\n" +
        "    time.sleep(IV)\n"

    Process {
        id: proc
        property int failures: 0
        running: root.active
        command: ["python3", "-u", "-c", root._script, root.socketPath, root.deviceId, String(root.intervalMs / 1000)]
        stdout: SplitParser {
            onRead: (line) => {
                var d;
                try { d = JSON.parse(line.trim()); } catch (e) { return; }
                if (!d) return;
                proc.failures = 0;
                if (d.ok) {
                    root._ok = true;
                    root.lastError = "";
                    root.statsUpdated(d);
                } else {
                    root._ok = false;
                    root.lastError = d.err || "";
                    console.warn("[gpu/LACT] sin datos:", root.lastError);
                    root.unavailable(root.lastError);
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: { if (this.text && this.text.trim() !== "") console.warn("[gpu/LACT]", this.text.trim()); }
        }
        onRunningChanged: {
            if (!running && root.active && failures < 5) { failures++; restartTimer.start(); }
            if (!running && !root.active) failures = 0;
        }
    }
    Timer { id: restartTimer; interval: 3000; repeat: false; onTriggered: if (root.active) proc.running = true }
}
