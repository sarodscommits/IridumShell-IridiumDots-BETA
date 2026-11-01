import QtQuick
import Quickshell
import Quickshell.Io

// Gaming overlay telemetry: metric history, ping and MangoHud FPS readers
Item {
    id: gmTelemetry
    property bool active: false
    readonly property int histLen: 40
    property var histCpu:  []
    property var histGpu:  []
    property var histRam:  []
    property var histPing: []
    property var histFps:  []
    function _push(arr, v) {
        var a = arr.slice();
        a.push(v);
        while (a.length > histLen) a.shift();
        return a;
    }
    Timer {
        interval: 1000; repeat: true; triggeredOnStart: true
        running: gmTelemetry.active
        onTriggered: {
            gmTelemetry.histCpu  = gmTelemetry._push(gmTelemetry.histCpu,  globalState.cpuPercent);
            gmTelemetry.histGpu  = gmTelemetry._push(gmTelemetry.histGpu,  Math.max(0, globalState.gpuPercent));
            gmTelemetry.histRam  = gmTelemetry._push(gmTelemetry.histRam,  globalState.ramPercent);
            gmTelemetry.histPing = gmTelemetry._push(gmTelemetry.histPing, globalState.gamingPingLost ? -1 : globalState.gamingPingMs);
            gmTelemetry.histFps  = gmTelemetry._push(gmTelemetry.histFps,  globalState.gamingFpsLive ? globalState.gamingFps : -1);
        }
    }

    readonly property string pingHost: "1.1.1.1"
    Process {
        id: gamingPingProc
        running: false
        command: ["ping", "-n", "-O", "-i", "1", "-W", "2", gmTelemetry.pingHost]
        stdout: SplitParser {
            onRead: (line) => {
                var m = line.match(/time[=<]([0-9.]+)/);
                if (m) { globalState.gamingPingMs = parseFloat(m[1]); globalState.gamingPingLost = false; }
                else if (line.indexOf("no answer") >= 0) globalState.gamingPingLost = true;
            }
        }
        onRunningChanged: if (!running && gmTelemetry.active) gamingPingRestart.restart()
    }
    Timer { id: gamingPingRestart; interval: 3000; repeat: false; onTriggered: if (gmTelemetry.active && !gamingPingProc.running) gamingPingProc.running = true }

    property real fpsLastMs: 0
    Process {
        id: gmFpsProc
        running: false
        command: ["bash", "-c", "exec bash \"" + scriptsDir + "/mangohud_fps.sh\""]
        stdout: SplitParser {
            onRead: (line) => {
                if (line.indexOf("FILE:") === 0) {
                    var n = line.substring(5);
                    var m = n.match(/^(.*)_\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}$/);
                    globalState.gamingFpsGame = m ? m[1] : n;
                    return;
                }
                var c = line.charAt(0);
                if (c < "0" || c > "9") return;
                var parts = line.split(",");
                if (parts.length < 2) return;
                var f = parseFloat(parts[0]), ft = parseFloat(parts[1]);
                if (isNaN(f)) return;
                globalState.gamingFps = f;
                globalState.gamingFrametime = isNaN(ft) ? -1 : ft;
                globalState.gamingFpsLive = true;
                gmTelemetry.fpsLastMs = Date.now();
            }
        }
    }
    Timer {
        interval: 1000; repeat: true
        running: gmTelemetry.active
        onTriggered: if (globalState.gamingFpsLive && Date.now() - gmTelemetry.fpsLastMs > 3000) globalState.gamingFpsLive = false
    }
    function resetHistory() { histCpu = []; histGpu = []; histRam = []; histPing = []; histFps = []; }
    function startProcs() {
        if (!gamingPingProc.running) gamingPingProc.running = true;
        if (!gmFpsProc.running) gmFpsProc.running = true;
    }
    function stopProcs() {
        gamingPingProc.running = false;
        gmFpsProc.running = false;
        gamingPingRestart.stop();
    }
}
