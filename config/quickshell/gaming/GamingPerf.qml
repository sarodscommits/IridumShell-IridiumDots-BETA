import QtQuick
import Quickshell
import Quickshell.Io

// Performance profile switching (scripts/gaming_perf.sh)
Item {
    id: gmPerf
    property alias gmPerfProc: gmPerfProc
    property alias gmPerfReadProc: gmPerfReadProc
    property string perfGpuState: ""
    property string _perfPending: ""
    function ppdToProfile(v) { return v === "power-saver" ? "low" : v === "performance" ? "high" : v === "balanced" ? "medium" : ""; }
    function setPerfProfile(prof) {
        if (["low", "medium", "high"].indexOf(prof) < 0) return;
        globalState.perfProfile = prof;
        if (gmPerfProc.running) { _perfPending = prof; return; }
        gmPerfProc.command = ["bash", "-c", "exec bash \"" + scriptsDir + "/gaming_perf.sh\" \"$1\" \"$2\"", "qs-perf", prof, globalState.shadowEnabled ? "1" : "0"];
        globalState.perfApplying = true;
        gmPerfProc.running = true;
    }
    Process {
        id: gmPerfProc
        running: false
        command: ["true"]
        stdout: SplitParser {
            onRead: (line) => {
                var i = line.indexOf(":"); if (i < 0) return;
                var k = line.substring(0, i), v = line.substring(i + 1).trim();
                if (k === "PPD") { var pr = gmPerf.ppdToProfile(v); if (pr !== "") globalState.perfProfile = pr; }
                else if (k === "GPU") gmPerf.perfGpuState = v;
                else if (k === "CPU" && v === "err")
                Quickshell.execDetached(["notify-send", "-a", tr("gm_title"), tr("gm_perf"), tr("gm_perf_cpu_err")]);
            }
        }
        onRunningChanged: {
            if (running) return;
            globalState.perfApplying = false;
            if (gmPerf.perfGpuState === "err")
            Quickshell.execDetached(["notify-send", "-a", tr("gm_title"), tr("gm_perf"), tr("gm_perf_gpu_err")]);
            if (gmPerf._perfPending !== "") {
                var p2 = gmPerf._perfPending; gmPerf._perfPending = "";
                gmPerf.setPerfProfile(p2);
            }
        }
    }
    Process {
        id: gmPerfReadProc
        running: false
        command: ["bash", "-c", "powerprofilesctl get 2>/dev/null"]
        stdout: SplitParser {
            onRead: (line) => { var pr = gmPerf.ppdToProfile(line.trim()); if (pr !== "" && !gmPerfProc.running) globalState.perfProfile = pr; }
        }
    }
}
