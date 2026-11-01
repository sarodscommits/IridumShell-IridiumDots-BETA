import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// App list, usage tracking and file search for the launcher
DeviceServices {
    property alias appUsageSaver: appUsageSaver
    property alias fileSearchDebounceTimer: fileSearchDebounceTimer
    property alias usageLoadProcess: usageLoadProcess

    Process {
        id: appListProcess
        command: ["bash", "-c",
        "python3 - <<'PYEOF'\n" +
        "import os, glob, configparser, subprocess\n" +
        "\n" +
        "def find_icon(name):\n" +
        "    if not name:\n" +
        "        return ''\n" +
        "    if os.path.isabs(name) and os.path.isfile(name):\n" +
        "        return name\n" +
        "    # Try the GTK icon theme via python gi\n" +
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
        "    # Manual fallback\n" +
        "    search_dirs = [\n" +
        "        os.path.expanduser('~/.local/share/icons'),\n" +
        "        '/usr/share/icons',\n" +
        "        '/usr/share/pixmaps',\n" +
        "    ]\n" +
        "    themes = ['hicolor', 'Papirus', 'Adwaita', 'breeze', 'gnome']\n" +
        "    sizes = ['48x48', '32x32', '64x64', '128x128', 'scalable', '24x24', '22x22']\n" +
        "    exts = ['png', 'svg', 'xpm']\n" +
        "    for base in search_dirs:\n" +
        "        for theme in themes:\n" +
        "            for size in sizes:\n" +
        "                for ext in exts:\n" +
        "                    p = os.path.join(base, theme, size, 'apps', name + '.' + ext)\n" +
        "                    if os.path.isfile(p):\n" +
        "                        return p\n" +
        "        for ext in exts:\n" +
        "            p = os.path.join(base, name + '.' + ext)\n" +
        "            if os.path.isfile(p):\n" +
        "                return p\n" +
        "    return ''\n" +
        "\n" +
        "seen = set()\n" +
        "dirs = ['/usr/share/applications', os.path.expanduser('~/.local/share/applications')]\n" +
        "apps = []\n" +
        "for d in dirs:\n" +
        "    for f in glob.glob(os.path.join(d, '*.desktop')):\n" +
        "        try:\n" +
        "            cp = configparser.RawConfigParser(strict=False)\n" +
        "            cp.read(f, encoding='utf-8')\n" +
        "            if not cp.has_section('Desktop Entry'):\n" +
        "                continue\n" +
        "            de = cp['Desktop Entry']\n" +
        "            if de.get('nodisplay','').lower() == 'true':\n" +
        "                continue\n" +
        "            if de.get('hidden','').lower() == 'true':\n" +
        "                continue\n" +
        "            if de.get('type','') != 'Application':\n" +
        "                continue\n" +
        "            # OnlyShowIn: skip only if Hyprland is not listed (not empty = show everywhere)\n" +
        "            only = de.get('onlyshowin', '')\n" +
        "            if only:\n" +
        "                envs = [e.strip().lower() for e in only.split(';') if e.strip()]\n" +
        "                if 'hyprland' not in envs and 'none' not in envs:\n" +
        "                    continue\n" +
        "            name = de.get('name', '').strip()\n" +
        "            exec_cmd = de.get('exec', '').strip()\n" +
        "            if not name or not exec_cmd:\n" +
        "                continue\n" +
        "            # Clean up exec: strip %f %u %F %U etc. and stray quotes\n" +
        "            import re\n" +
        "            exec_cmd = re.sub(r' ?%[A-Za-z]', '', exec_cmd).strip()\n" +
        "            icon_name = de.get('icon', '').strip()\n" +
        "            wmclass = de.get('startupwmclass', '').strip()\n" +
        "            desktop_id = os.path.splitext(os.path.basename(f))[0]\n" +
        "            key = name.lower()\n" +
        "            if key in seen:\n" +
        "                continue\n" +
        "            seen.add(key)\n" +
        "            icon_path = find_icon(icon_name)\n" +
        "            apps.append((name, exec_cmd, icon_path, wmclass, desktop_id))\n" +
        "        except Exception:\n" +
        "            continue\n" +
        "apps.sort(key=lambda x: x[0].lower())\n" +
        "for name, exe, icon, wmclass, desktop_id in apps:\n" +
        "    print(f'{name}\\t{exe}\\t{icon}\\t{wmclass}\\t{desktop_id}')\n" +
        "PYEOF"
        ]
        running: false
        property var _acc: []
        stdout: SplitParser {
            onRead: (line) => {
                if (!line || line.trim().length === 0) return;
                var parts = line.split("\t");
                if (parts.length >= 2) {
                    var name = parts[0].trim();
                    var exec_cmd = parts[1].trim();
                    var icon_path = parts.length >= 3 ? parts[2].trim() : "";
                    var wmclass = parts.length >= 4 ? parts[3].trim() : "";
                    var desktopId = parts.length >= 5 ? parts[4].trim() : "";
                    if (name && exec_cmd) {
                        appListProcess._acc.push({name: name, exec: exec_cmd, icon: icon_path, wmclass: wmclass, desktopId: desktopId});
                    }
                }
            }
        }
        onRunningChanged: {
            if (running) { appListProcess._acc = []; return; }
            if (appListProcess._acc.length > 0) {
                globalState.appList = appListProcess._acc;
                appListProcess._acc = [];
            }
            if (!running) {
                if (globalState.appList.length === 0) {
                    console.log("No apps loaded, retrying...");
                    reloadAppListTimer.start();
                } else {
                    globalState.appListLoaded = true;
                    globalState.appListLoading = false;
                    console.log("Apps loaded:", globalState.appList.length);
                }
            }
        }
    }

    Timer {
        id: reloadAppListTimer
        interval: 500
        repeat: false
        onTriggered: {
            if (globalState.appList.length === 0) {
                console.log("Retrying app list load...");
                globalState.appListLoading = true;
                appListProcess.running = true;
            } else {
                globalState.appListLoaded = true;
                globalState.appListLoading = false;
            }
        }
    }

    Timer {
        id: fileSearchDebounceTimer
        property string pendingQuery: ""
        interval: 280
        repeat: false
        onTriggered: {
            var q = fileSearchDebounceTimer.pendingQuery.trim();
            if (q.length < 2) {
                globalState.fileSearchResults = [];
                return;
            }
            fileSearchProcess.running = false;
            fileSearchProcess.query   = q;
            fileSearchProcess.running = true;
        }
    }

    Process {
        id: fileSearchProcess
        property string query: ""
        property var _acc: []
        command: ["bash", "-c",
        "timeout 3 find " + JSON.stringify("$HOME") +
        " -iname " + JSON.stringify("*" + fileSearchProcess.query + "*") +
        " -not -path " + JSON.stringify("*/node_modules/*") +
        " 2>/dev/null | head -60"
        ]
        running: false
        stdout: SplitParser {
            onRead: (line) => {
                var p = line.trim();
                if (!p) return;
                fileSearchProcess._acc.push(p);
            }
        }
        onRunningChanged: {
            if (!running) {
                var results = fileSearchProcess._acc.map(function (p) {
                    var parts = p.split("/");
                    var base  = parts[parts.length - 1] || p;
                    return { name: base, icon: "", exec: "kitty -e yazi " + JSON.stringify(p) };
                });
                globalState.fileSearchResults = results;
                fileSearchProcess._acc = [];
            }
        }
    }

    Timer {
        id: initialLoadTimer
        interval: 100
        running: globalState.deferredLateReady
        repeat: false
        onTriggered: {
            console.log("Starting app list load...");
            globalState.appListLoading = true;
            appListProcess.running = true;
        }
    }

    Timer {
        id: fallbackTimer
        interval: 5000
        running: true
        repeat: false
        onTriggered: {
            if (globalState.appList.length === 0 && !globalState.appListLoaded) {
                console.log("Using fallback app list...");
                globalState.appList = [
                {name: "Firefox", exec: "firefox"},
                {name: "Chromium", exec: "chromium"},
                {name: "Kitty", exec: "kitty"},
                {name: "Alacritty", exec: "alacritty"},
                {name: "VSCode", exec: "code"},
                {name: "Spotify", exec: "spotify"},
                {name: "Discord", exec: "discord"},
                {name: "Telegram", exec: "telegram-desktop"},
                {name: "Nautilus", exec: "nautilus"},
                {name: "Dolphin", exec: "dolphin"},
                {name: "GIMP", exec: "gimp"},
                {name: "Inkscape", exec: "inkscape"},
                {name: "LibreOffice", exec: "libreoffice"},
                {name: "VLC", exec: "vlc"},
                {name: "MPV", exec: "mpv"},
                {name: "htop", exec: "kitty -e htop"},
                {name: "btop", exec: "kitty -e btop"},
                {name: "yazi", exec: "kitty -e yazi"}
                ];
                globalState.appListLoaded = true;
                globalState.appListLoading = false;
            }
        }
    }

    Process {
        id: usageLoadProcess
        command: ["bash", "-c", "cat ~/.config/quickshell/app_usage.json 2>/dev/null || echo '{}'"]
        running: false
        property string _buf: ""
        stdout: SplitParser {
            onRead: (line) => {
                usageLoadProcess._buf += line.trim();
                try {
                    var data = JSON.parse(usageLoadProcess._buf);
                    if (typeof data === "object" && data !== null) {
                        var merged = Object.assign({}, data);
                        var inMem = globalState.appUsage;
                        for (var k in inMem) {
                            merged[k] = Math.max(merged[k] || 0, inMem[k] || 0);
                        }
                        globalState.appUsage = merged;
                    }
                } catch(e) {}
            }
        }
    }

    Process {
        id: appUsageSaver
        command: ["python3", "-c",
        "import sys, os, json\n" +
        "d = os.path.expanduser('~/.config/quickshell')\n" +
        "os.makedirs(d, exist_ok=True)\n" +
        "data = sys.stdin.read()\n" +
        "json.loads(data)\n" +
        "with open(os.path.join(d, 'app_usage.json'), 'w') as f:\n" +
        "    f.write(data)\n"
        ]
        running: false
        stdinEnabled: true
        property string _pending: ""
        property bool _busy: false

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text && this.text.trim().length > 0)
                console.warn("appUsageSaver: error al escribir app_usage.json ->", this.text);
            }
        }

        function saveJson(json) {
            if (appUsageSaver._busy) {
                appUsageSaver._pending = json;
                return;
            }
            appUsageSaver._busy = true;
            appUsageSaver.running = true;
            appUsageSaver.write(json);
            appUsageSaver.stdinEnabled = false;
        }

        onRunningChanged: {
            if (!running) {
                appUsageSaver._busy = false;
                appUsageSaver.stdinEnabled = true;
                if (appUsageSaver._pending !== "") {
                    var p = appUsageSaver._pending;
                    appUsageSaver._pending = "";
                    appUsageSaver.saveJson(p);
                }
            }
        }
    }
}
