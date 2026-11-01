import QtQuick
import Quickshell
import Quickshell.Io

// Hyprland events, workspaces, clients and captures
SystemMonitorServices {
    property alias windowIconLookupProcess: windowIconLookupProcess
    property alias wpResumeRetry: wpResumeRetry
    property alias wsCaptureOpenProc: wsCaptureOpenProc

    Process {
        id: wsCaptureProc
        stdout: SplitParser { onRead: (l) => globalState.wsShotLine(l) }
    }

    Process {
        id: wsCaptureOpenProc
        stdout: SplitParser { onRead: (l) => globalState.wsShotLine(l) }
        onRunningChanged: if (!running) globalState.windowSwitcherOpen = true
    }

    Timer {
        id: wsCaptureDebounce
        interval: 1200
        onTriggered: {
            if (globalState.windowSwitcherOpen || globalState.lockScreenActive || wsCaptureProc.running) return;
            globalState.wsRunCapture(wsCaptureProc);
        }
    }

    Timer {
        interval: 10000; running: true; repeat: true
        onTriggered: wsCaptureDebounce.restart()
    }

    Connections {
        target: globalState
        function onActiveWindowAddressChanged() { wsCaptureDebounce.restart() }
        function onActiveWorkspaceChanged()     { wsCaptureDebounce.restart() }
        function onOpenClientsChanged()         { wsCaptureDebounce.restart() }
    }

    Process {
        id: hyprEventProcess
        command: ["bash", "-c",
        "sock=\"${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock\"; " +
        "socat -u UNIX-CONNECT:\"$sock\" STDOUT 2>/dev/null || " +
        "nc -U \"$sock\" 2>/dev/null"
        ]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                var ev = line.split(">>")[0];
                if (ev === "workspace" || ev === "workspacev2" ||
                ev === "destroyworkspace" || ev === "destroyworkspacev2" ||
                ev === "focusedmon" || ev === "moveworkspace") {
                    workspaceProcess.running = true;
                }
                if (ev === "openwindow" || ev === "closewindow" ||
                ev === "movewindow" || ev === "movewindowv2" ||
                ev === "windowtitle" || ev === "windowtitlev2" ||
                ev === "changefloatingmode" || ev === "fullscreen" ||
                ev === "workspace" || ev === "workspacev2") {
                    clientsProcess.running = true;
                }
                if (ev === "activewindow" || ev === "activewindowv2") {
                    activeWindowProcess.running = true;
                }
                if (ev === "fullscreen") {
                    globalState.wpFullscreenActive = line.split(">>")[1] === "1";
                    fullscreenCheckDebounce.restart();
                }
                if (ev === "closewindow" || ev === "openwindow" ||
                ev === "workspace" || ev === "workspacev2" ||
                ev === "focusedmon" || ev === "focusedmonv2" ||
                ev === "movewindow" || ev === "movewindowv2" ||
                ev === "destroyworkspace" || ev === "destroyworkspacev2" ||
                ev === "activewindowv2") {
                    fullscreenCheckDebounce.restart();
                }
            }
        }
        onRunningChanged: {
            if (!running) hyprEventRestartTimer.start();
        }
    }

    Timer { id: hyprEventRestartTimer; interval: 1000; repeat: false; onTriggered: hyprEventProcess.running = true }

    Process {
        id: fullscreenCheckProcess
        command: ["bash", "-c",
        "hyprctl activeworkspace -j 2>/dev/null | grep -o '\"hasfullscreen\": *[a-z]*' | grep -o '[a-z]*$'"]
        running: false
        property bool _again: false
        stdout: SplitParser {
            onRead: (line) => {
                var t = line.trim();
                if (t !== "true" && t !== "false") return;
                var fs = t === "true";
                if (globalState.wpFullscreenActive !== fs) {
                    console.log("[fullscreen] estado corregido:", globalState.wpFullscreenActive, "→", fs);
                    globalState.wpFullscreenActive = fs;
                }
            }
        }
        onRunningChanged: { if (!running && _again) { _again = false; running = true; } }
        function request() { if (running) _again = true; else running = true; }
    }

    Timer {
        id: fullscreenCheckDebounce
        interval: 150; repeat: false
        onTriggered: { fullscreenCheckProcess.request(); fullscreenCheckLate.restart(); }
    }

    Timer {
        id: fullscreenCheckLate
        interval: 600; repeat: false
        onTriggered: fullscreenCheckProcess.request()
    }

    Timer {
        interval: 3000; repeat: true
        running: globalState.wpFullscreenActive
        onTriggered: fullscreenCheckProcess.request()
    }

    Timer {
        id: wpResumeRetry
        interval: 800; repeat: false
        onTriggered: updateWallpaperPauseState()
    }

    Process {
        id: workspaceProcess
        command: ["bash", "-c", "echo \"$(hyprctl activeworkspace -j | jq '.id') $(hyprctl workspaces -j | jq -c '[.[].id] | sort | join(\",\")')\""]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                var parts = line.trim().split(" ");
                if (parts.length >= 2) {
                    var current = parseInt(parts[0]);
                    if (!isNaN(current)) globalState.activeWorkspace = current;
                    var listStr = parts[1].replace(/\"/g, "");
                    if (listStr.length > 0) {
                        var arr = listStr.split(",").map(Number);
                        if (JSON.stringify(arr) !== JSON.stringify(globalState.openWorkspaces))
                        globalState.openWorkspaces = arr;
                    }
                }
            }
        }
    }

    Timer {
        interval: hyprEventProcess.running ? 10000 : 2000
        running: true; repeat: true
        onTriggered: workspaceProcess.running = true
    }

    Process {
        id: clientsProcess
        command: ["hyprctl", "clients", "-j"]
        running: true
        property string _buf: ""
        stdout: SplitParser { onRead: (line) => { clientsProcess._buf += line; } }
        onRunningChanged: {
            if (!running) {
                var raw = clientsProcess._buf.trim();
                clientsProcess._buf = "";
                if (!raw) return;
                try {
                    var data = JSON.parse(raw);
                    var filtered = data
                    .filter((c) => c && c.mapped !== false && c.class && c.class !== "")
                    .map((c) => ({
                        address:   c.address || "",
                        cls:       c.class,
                        title:     c.title || "",
                        workspace: (c.workspace && typeof c.workspace.id === "number") ? c.workspace.id : 0,
                        pid:       typeof c.pid === "number" ? c.pid : -1,
                        x:         (Array.isArray(c.at)   && c.at.length   === 2) ? c.at[0]   : 0,
                        y:         (Array.isArray(c.at)   && c.at.length   === 2) ? c.at[1]   : 0,
                        w:         (Array.isArray(c.size) && c.size.length === 2) ? c.size[0] : 0,
                        h:         (Array.isArray(c.size) && c.size.length === 2) ? c.size[1] : 0,
                        floating:  c.floating === true
                    }))
                    .sort((a, b) => a.address < b.address ? -1 : a.address > b.address ? 1 : 0);
                    if (JSON.stringify(filtered) !== JSON.stringify(globalState.openClients)) {
                        globalState.openClients = filtered;
                    }
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: hyprEventProcess.running ? 12000 : 4000
        running: true; repeat: true
        onTriggered: clientsProcess.running = true
    }

    Process {
        id: activeWindowProcess
        command: ["hyprctl", "activewindow", "-j"]
        running: true
        property string _buf: ""
        stdout: SplitParser { onRead: (line) => { activeWindowProcess._buf += line; } }
        onRunningChanged: {
            if (!running) {
                var raw = activeWindowProcess._buf.trim();
                activeWindowProcess._buf = "";
                if (!raw) return;
                try {
                    var data = JSON.parse(raw);
                    globalState.activeWindowAddress = data.address || "";
                    globalState.noteFocus(data.address || "");
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: hyprEventProcess.running ? 12000 : 4000
        running: true; repeat: true
        onTriggered: activeWindowProcess.running = true
    }

    Process {
        id: windowIconLookupProcess
        command: ["python3", "-c",
        "import sys, os\n" +
        "\n" +
        "def find_icon(name):\n" +
        "    if not name:\n" +
        "        return ''\n" +
        "    if os.path.isabs(name) and os.path.isfile(name):\n" +
        "        return name\n" +
        "    try:\n" +
        "        import gi\n" +
        "        gi.require_version('Gtk', '3.0')\n" +
        "        from gi.repository import Gtk\n" +
        "        theme = Gtk.IconTheme.get_default()\n" +
        "        info = theme.lookup_icon(name, 48, 0)\n" +
        "        if info:\n" +
        "            return info.get_filename() or ''\n" +
        "    except Exception:\n" +
        "        pass\n" +
        "    search_dirs = [\n" +
        "        os.path.expanduser('~/.local/share/icons'),\n" +
        "        '/usr/share/icons',\n" +
        "        '/usr/share/pixmaps',\n" +
        "    ]\n" +
        "    themes = ['hicolor', 'Papirus', 'Adwaita', 'breeze', 'gnome']\n" +
        "    sizes = ['48x48', '32x32', '64x64', '128x128', 'scalable', '24x24', '22x22']\n" +
        "    exts = ['png', 'svg', 'xpm']\n" +
        "    for base in search_dirs:\n" +
        "        for th in themes:\n" +
        "            for size in sizes:\n" +
        "                for ext in exts:\n" +
        "                    p = os.path.join(base, th, size, 'apps', name + '.' + ext)\n" +
        "                    if os.path.isfile(p):\n" +
        "                        return p\n" +
        "        for ext in exts:\n" +
        "            p = os.path.join(base, name + '.' + ext)\n" +
        "            if os.path.isfile(p):\n" +
        "                return p\n" +
        "    return ''\n" +
        "\n" +
        "def steam_appid_from_pid(pid):\n" +
        "    if not pid or pid == '-1':\n" +
        "        return ''\n" +
        "    try:\n" +
        "        with open('/proc/' + pid + '/environ', 'rb') as fh:\n" +
        "            data = fh.read()\n" +
        "        for part in data.split(b'\\x00'):\n" +
        "            if part.startswith(b'SteamAppId='):\n" +
        "                return part.split(b'=', 1)[1].decode('utf-8', 'ignore').strip()\n" +
        "    except Exception:\n" +
        "        pass\n" +
        "    return ''\n" +
        "\n" +
        "def steam_cached_icon(appid):\n" +
        "    if not appid:\n" +
        "        return ''\n" +
        "    bases = [\n" +
        "        os.path.expanduser('~/.local/share/Steam'),\n" +
        "        os.path.expanduser('~/.steam/steam'),\n" +
        "        os.path.expanduser('~/.steam/root'),\n" +
        "        os.path.expanduser('~/.var/app/com.valvesoftware.Steam/data/Steam'),\n" +
        "    ]\n" +
        "    names = [appid + '_icon.jpg', appid + '_icon.png']\n" +
        "    for base in bases:\n" +
        "        for name in names:\n" +
        "            p = os.path.join(base, 'appcache', 'librarycache', name)\n" +
        "            if os.path.isfile(p):\n" +
        "                return p\n" +
        "    return ''\n" +
        "\n" +
        "import re\n" +
        "for line in sys.stdin:\n" +
        "    raw = line.rstrip('\\n')\n" +
        "    if not raw:\n" +
        "        continue\n" +
        "    parts = raw.split('\\t')\n" +
        "    cls = parts[0]\n" +
        "    pid = parts[1] if len(parts) > 1 else ''\n" +
        "    if not cls:\n" +
        "        continue\n" +
        "\n" +
        "    appid = steam_appid_from_pid(pid)\n" +
        "    if appid:\n" +
        "        cached = steam_cached_icon(appid)\n" +
        "        if cached:\n" +
        "            print(cls + '\\t' + cached)\n" +
        "            sys.stdout.flush()\n" +
        "            continue\n" +
        "\n" +
        "    candidates = [cls, cls.lower()]\n" +
        "    if '.' in cls:\n" +
        "        last = cls.split('.')[-1]\n" +
        "        candidates.append(last)\n" +
        "        candidates.append(last.lower())\n" +
        "    sm = re.match(r'^steam_app_(\\d+)$', cls, re.IGNORECASE)\n" +
        "    if sm:\n" +
        "        candidates.append('steam_icon_' + sm.group(1))\n" +
        "    if appid:\n" +
        "        candidates.append('steam_icon_' + appid)\n" +
        "    found = ''\n" +
        "    for cand in candidates:\n" +
        "        found = find_icon(cand)\n" +
        "        if found:\n" +
        "            break\n" +
        "    print(cls + '\\t' + found)\n" +
        "    sys.stdout.flush()\n"
        ]
        running: false
        stdinEnabled: true
        property bool _busy: false
        property var  _pending: []
        stdout: SplitParser {
            onRead: (line) => {
                var idx = line.indexOf("\t");
                if (idx < 0) return;
                var cls = line.substring(0, idx);
                var path = line.substring(idx + 1).trim();
                var cache = Object.assign({}, globalState.windowIconCache);
                cache[cls] = path;
                globalState.windowIconCache = cache;
            }
        }
        onRunningChanged: {
            if (!running) {
                windowIconLookupProcess._busy = false;
                windowIconLookupProcess.stdinEnabled = true;
                if (windowIconLookupProcess._pending.length > 0) {
                    var next = windowIconLookupProcess._pending.shift();
                    windowIconLookupProcess._doLookup(next);
                }
            }
        }
        function _doLookup(classes) {
            if (classes.length === 0) return;
            if (windowIconLookupProcess._busy) {
                windowIconLookupProcess._pending.push(classes);
                return;
            }
            windowIconLookupProcess._busy = true;
            windowIconLookupProcess.running = true;
            windowIconLookupProcess.write(classes.join("\n") + "\n");
            windowIconLookupProcess.stdinEnabled = false;
        }
    }
}
