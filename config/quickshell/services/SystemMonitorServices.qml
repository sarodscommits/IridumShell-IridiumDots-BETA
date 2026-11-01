import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import ".."

// CPU/RAM/GPU/disk/network sampling, system fetch info and overview history
LauncherServices {
    property alias fetchProcess: fetchProcess
    property alias sysMonHist: sysMonHist

    Process {
        id: sysProcess
        command: ["bash", "-c",
        "read -r u1 n1 s1 i1 w1 x1 y1 z1 < <(awk '/^cpu /{print $2,$3,$4,$5,$6,$7,$8,$9}' /proc/stat); " +
        "sleep 0.3; " +
        "read -r u2 n2 s2 i2 w2 x2 y2 z2 < <(awk '/^cpu /{print $2,$3,$4,$5,$6,$7,$8,$9}' /proc/stat); " +
        "t1=$((u1+n1+s1+i1+w1+x1+y1+z1)); t2=$((u2+n2+s2+i2+w2+x2+y2+z2)); " +
        "dt=$((t2-t1)); di=$((i2-i1)); " +
        "cpu=$(( dt>0 ? (100*(dt-di))/dt : 0 )); " +
        "read mb pct < <(awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{print int((t-a)/1024),int((t-a)/t*100)}' /proc/meminfo); " +
        "echo $cpu $mb $pct"
        ]
        running: false
        stdout: SplitParser {
            onRead: (line) => {
                var parts = line.trim().split(" ");
                if (parts.length === 3) {
                    var cpu = parseInt(parts[0]);
                    var mb  = parseInt(parts[1]);
                    var pct = parseInt(parts[2]);
                    if (!isNaN(cpu)) globalState.cpuPercent = cpu;
                    if (!isNaN(mb))  globalState.ramUsedMb  = mb;
                    if (!isNaN(pct)) globalState.ramPercent = pct;
                }
            }
        }
    }

    Timer {
        interval: (globalState.gamingOpen || globalState.gamingFloating) ? 1000 : 2000; repeat: true; triggeredOnStart: true
        running: globalState.monitorStatsVisible ||
        ((globalState.cpuWidgetEnabled || globalState.ramWidgetEnabled || globalState.sysWidgetEnabled) && !globalState.lockScreenActive)
        onTriggered: if (!sysProcess.running) sysProcess.running = true
    }

    Process {
        id: sysExtraProcess
        command: ["bash", "-c",
        "read -r used total pct < <(df -P / 2>/dev/null | awk 'NR==2{gsub(\"%\",\"\",$5); printf \"%d %d %d\", $3/1024/1024, $2/1024/1024, $5}'); " +
        "[ -n \"$pct\" ] && echo \"DISKPCT:$pct\"; " +
        "[ -n \"$used\" ] && echo \"DISKUSED:${used}G\"; " +
        "[ -n \"$total\" ] && echo \"DISKTOTAL:${total}G\"; " +
        "cputemp=\"\"; " +
        "if command -v sensors >/dev/null 2>&1; then " +
        "  cputemp=$(sensors 2>/dev/null | grep -m1 -E 'Package id 0|Tctl|Tdie|CPU Temperature' | grep -oP '[0-9.]+(?=°C)' | head -1); " +
        "fi; " +
        "if [ -z \"$cputemp\" ]; then " +
        "  for z in /sys/class/thermal/thermal_zone*/; do " +
        "    t=$(cat \"${z}type\" 2>/dev/null); " +
        "    if [ \"$t\" = \"x86_pkg_temp\" ] || [ \"$t\" = \"acpitz\" ] || [ \"$t\" = \"cpu_thermal\" ]; then " +
        "      cputemp=$(awk '{printf \"%d\", $1/1000}' \"${z}temp\" 2>/dev/null); break; " +
        "    fi; " +
        "  done; " +
        "fi; " +
        "[ -n \"$cputemp\" ] && printf 'CPUTEMP:%.0f\\n' \"$cputemp\"; " +
        "if command -v nvidia-smi >/dev/null 2>&1; then " +
        "  IFS=', ' read -r gu gt <<< \"$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1)\"; " +
        "  [ -n \"$gu\" ] && echo \"GPUPCT:$gu\"; " +
        "  [ -n \"$gt\" ] && echo \"GPUTEMP:$gt\"; " +
        "else " +
        "  busy=$(cat /sys/class/drm/card0/device/gpu_busy_percent 2>/dev/null); " +
        "  [ -n \"$busy\" ] && echo \"GPUPCT:$busy\"; " +
        "  gt=$(sensors 2>/dev/null | grep -m1 -iE 'edge|junction' | grep -oP '[0-9.]+(?=°C)' | head -1); " +
        "  [ -n \"$gt\" ] && printf 'GPUTEMP:%.0f\\n' \"$gt\"; " +
        "fi"
        ]
        running: false
        stdout: SplitParser {
            onRead: (line) => {
                var idx = line.indexOf(":");
                if (idx < 0) return;
                var key = line.substring(0, idx);
                var val = line.substring(idx + 1).trim();
                if      (key === "DISKPCT")   { var dp = parseInt(val); if (!isNaN(dp)) globalState.diskPercent = dp; }
                else if (key === "DISKUSED")  globalState.diskUsedStr  = val;
                else if (key === "DISKTOTAL") globalState.diskTotalStr = val;
                else if (key === "CPUTEMP")   { var ct = parseInt(val); if (!isNaN(ct)) globalState.cpuTemp = ct; }
                else if (key === "GPUPCT" && !globalState.gpuLactOk)    { var gp = parseInt(val); if (!isNaN(gp)) globalState.gpuPercent = gp; }
                else if (key === "GPUTEMP" && !globalState.gpuLactOk)   { var gtp = parseInt(val); if (!isNaN(gtp)) globalState.gpuTemp = gtp; }
            }
        }
    }

    Timer {
        interval: (globalState.monitorStatsVisible || ((globalState.gpuWidgetEnabled || globalState.sysWidgetEnabled) && !globalState.gpuLactOk)) ? 3000 : 30000
        repeat: true; triggeredOnStart: true
        running: globalState.monitorStatsVisible || ((globalState.diskWidgetEnabled || globalState.gpuWidgetEnabled || globalState.sysWidgetEnabled) && !globalState.lockScreenActive)
        onTriggered: if (!sysExtraProcess.running) sysExtraProcess.running = true
    }

    Process {
        id: netSpeedProcess
        command: ["bash", "-c",
        "r1=$(awk -F'[: ]+' '/:/{if ($2 !~ /^lo$/) { rx+=$3; tx+=$11 }} END{printf \"%d %d\", rx+0, tx+0}' /proc/net/dev); " +
        "sleep 1; " +
        "r2=$(awk -F'[: ]+' '/:/{if ($2 !~ /^lo$/) { rx+=$3; tx+=$11 }} END{printf \"%d %d\", rx+0, tx+0}' /proc/net/dev); " +
        "awk -v r1=\"$r1\" -v r2=\"$r2\" 'BEGIN{ " +
        "  split(r1, a, \" \"); split(r2, b, \" \"); " +
        "  printf \"NETDOWN:%.1f\\nNETUP:%.1f\\n\", (b[1]-a[1])/1024, (b[2]-a[2])/1024 " +
        "}'"
        ]
        running: false
        stdout: SplitParser {
            onRead: (line) => {
                var idx = line.indexOf(":");
                if (idx < 0) return;
                var key = line.substring(0, idx);
                var val = line.substring(idx + 1).trim();
                if      (key === "NETDOWN") { var nd = parseFloat(val); if (!isNaN(nd)) globalState.netDownKBps = Math.max(0, nd); }
                else if (key === "NETUP")   { var nu = parseFloat(val); if (!isNaN(nu)) globalState.netUpKBps   = Math.max(0, nu); }
            }
        }
    }

    Timer {
        interval: 3000; repeat: true; triggeredOnStart: true
        running: globalState.monitorStatsVisible
        onTriggered: if (!netSpeedProcess.running) netSpeedProcess.running = true
    }

    Process {
        id: fetchProcess
        command: ["bash", "-c",
        "echo \"USER:$(whoami)\"; " +
        "echo \"HOST:$(hostname)\"; " +
        "echo \"OS:$(grep '^PRETTY_NAME' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '\"')\"; " +
        "echo \"KERNEL:$(uname -r)\"; " +
        "echo \"PACKAGES:$(pacman -Qq 2>/dev/null | wc -l) (pacman)\"; " +
        "echo \"SHELL:$(basename \\\"${SHELL:-unknown}\\\")\"; " +
        "echo \"DISPLAY:$(hyprctl monitors 2>/dev/null | grep -oP '\\d+x\\d+@[0-9.]+' | head -1)\"; " +
        "echo \"DE:${XDG_SESSION_DESKTOP:-${XDG_CURRENT_DESKTOP:-N/A}}\"; " +
        "echo \"WM:${XDG_CURRENT_DESKTOP:-Hyprland}\"; " +
        "echo \"FONT:$(fc-match -f '%{family}' sans 2>/dev/null)\"; " +
        "echo \"TERMINAL:$(basename \\\"$(readlink /proc/$PPID/exe 2>/dev/null)\\\" 2>/dev/null)\"; " +
        "echo \"CPU:$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ //;s/(R)//g;s/(TM)//g;s/  */ /g')\"; " +
        "echo \"GPU:$(lspci 2>/dev/null | grep -i 'vga\\|3d\\|display' | head -1 | sed 's/.*: //;s/ (rev .*)//;s/.*\\[//;s/\\].*//')\"; " +
        "awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{printf \"RAM:%d / %d MB\\n\",int((t-a)/1024),int(t/1024)}' /proc/meminfo; " +
        "awk '/SwapTotal/{t=$2}/SwapFree/{f=$2}END{if(t>0)printf \"SWAP:%d / %d MB\\n\",int((t-f)/1024),int(t/1024); else print \"SWAP:None\"}' /proc/meminfo; " +
        "df -h / 2>/dev/null | awk 'NR==2{print \"DISK:\" $3 \" / \" $2}'; " +
        "echo \"LOCALE:${LANG:-C}\"; " +
        "awk '{s=int($1);d=int(s/86400);h=int((s%86400)/3600);m=int((s%3600)/60); if(d>0)printf \"UPTIME:%dd %dh %dm\\n\",d,h,m; else printf \"UPTIME:%dh %dm\\n\",h,m}' /proc/uptime"
        ]
        running: false
        stdout: SplitParser {
            onRead: (line) => {
                var idx = line.indexOf(":");
                if (idx < 0) return;
                var key = line.substring(0, idx);
                var val = line.substring(idx + 1).trim();
                if      (key === "OS")        globalState.fetchOS        = val;
                else if (key === "KERNEL")    globalState.fetchKernel    = val;
                else if (key === "WM")        globalState.fetchWM        = val;
                else if (key === "CPU")       globalState.fetchCPU       = val;
                else if (key === "GPU")       globalState.fetchGPU       = val;
                else if (key === "RAM")       globalState.fetchRAM       = val;
                else if (key === "DISK")      globalState.fetchDisk      = val;
                else if (key === "UPTIME")    globalState.fetchUptime    = val;
                else if (key === "USER")      globalState.fetchUser      = val;
                else if (key === "HOST")      globalState.fetchHost      = val;
                else if (key === "PACKAGES")  globalState.fetchPackages  = val;
                else if (key === "SHELL")     globalState.fetchShell     = val;
                else if (key === "DISPLAY")   globalState.fetchDisplay   = val;
                else if (key === "DE")        globalState.fetchDE        = val;
                else if (key === "FONT")      globalState.fetchFont      = val;
                else if (key === "TERMINAL")  globalState.fetchTerminal  = val;
                else if (key === "SWAP")      globalState.fetchSwap      = val;
                else if (key === "LOCALE")    globalState.fetchLocale    = val;
            }
        }
    }

    Timer {
        interval: 60000; repeat: true; triggeredOnStart: true
        running: globalState.deferredReady && globalState.fetchVisible
        property double _last: 0
        onTriggered: {
            var now = Date.now();
            if (now - _last < 30000 || fetchProcess.running) return;
            _last = now;
            fetchProcess.running = true;
        }
    }

    GpuBackend {
        id: gpuBackend
        active: globalState.deferredReady && (globalState.monitorStatsVisible || globalState.gpuWidgetEnabled || globalState.sysWidgetEnabled) && !globalState.lockScreenActive
        onStatsUpdated: (s) => {
            function num(v) { return (typeof v === "number" && !isNaN(v)) ? v : -1; }
            var t = s.temps || {};
            globalState.gpuLactOk       = true;
            globalState.gpuName         = s.name || "";
            if (typeof s.busy === "number") globalState.gpuPercent = s.busy;
            var edge = num(t.edge);
            if (edge >= 0) globalState.gpuTemp = Math.round(edge);
            globalState.gpuTempJunction = Math.round(num(t.junction));
            globalState.gpuTempMem      = Math.round(num(t.mem));
            globalState.gpuVramUsedMb   = num(s.vram_used);
            globalState.gpuVramTotalMb  = num(s.vram_total);
            globalState.gpuPowerW       = num(s.power);
            globalState.gpuPowerCapW    = num(s.power_cap);
            globalState.gpuClockMhz     = num(s.gpu_clock);
            globalState.gpuVramClockMhz = num(s.vram_clock);
            globalState.gpuFanRpm       = num(s.fan_rpm);
            globalState.gpuFanPercent   = num(s.fan_pct);
        }
        onUnavailable: (reason) => { globalState.gpuLactOk = false; }
    }

    QtObject {
        id: sysMonHist
        readonly property bool active: (globalState.ncVisiblePage === 1 || globalState.icVisiblePage === 1 || globalState.icVisiblePage === 3) && !globalState.lockScreenActive
        readonly property bool gamingPinging: (globalState.gamingOpen || globalState.gamingFloating) && !globalState.lockScreenActive
        readonly property int histLen: 40
        readonly property string pingHost: "1.1.1.1"
        property var cpu:  []
        property var gpu:  []
        property var ram:  []
        property var ping: []
        function push(arr, v) {
            var a = arr.slice();
            a.push(v);
            while (a.length > histLen) a.shift();
            return a;
        }
        onActiveChanged: {
            if (active) {
                cpu = []; gpu = []; ram = []; ping = [];
                if (!gamingPinging) { globalState.gamingPingMs = -1; globalState.gamingPingLost = false; }
            }
        }
    }

    Timer {
        interval: 1000; repeat: true; triggeredOnStart: true
        running: sysMonHist.active
        onTriggered: {
            sysMonHist.cpu  = sysMonHist.push(sysMonHist.cpu,  globalState.cpuPercent);
            sysMonHist.gpu  = sysMonHist.push(sysMonHist.gpu,  Math.max(0, globalState.gpuPercent));
            sysMonHist.ram  = sysMonHist.push(sysMonHist.ram,  globalState.ramPercent);
            sysMonHist.ping = sysMonHist.push(sysMonHist.ping, globalState.gamingPingLost ? -1 : globalState.gamingPingMs);
        }
    }

    Process {
        id: sysMonPingProc
        running: sysMonHist.active && !sysMonHist.gamingPinging
        command: ["ping", "-n", "-O", "-i", "1", "-W", "2", sysMonHist.pingHost]
        stdout: SplitParser {
            onRead: (line) => {
                var m = line.match(/time[=<]([0-9.]+)/);
                if (m) { globalState.gamingPingMs = parseFloat(m[1]); globalState.gamingPingLost = false; }
                else if (line.indexOf("no answer") >= 0) globalState.gamingPingLost = true;
            }
        }
    }
}
