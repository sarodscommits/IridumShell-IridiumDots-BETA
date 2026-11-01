import QtQuick
import Quickshell
import Quickshell.Io

// Individual CPU (power-profiles-daemon) / GPU (LACT) levels via scripts/system_perf.sh.
// Levels: low | medium | high, or none / nodev / err.
Item {
    id: pl
    property string cpu: ""
    property string gpu: ""
    property bool cpuBusy: false
    property bool gpuBusy: false
    property string _cpuPending: ""
    property string _gpuPending: ""

    function refresh() { if (!getProc.running) getProc.running = true; }
    function setCpu(v) {
        cpu = v;
        if (cpuProc.running) { _cpuPending = v; return; }
        cpuBusy = true;
        cpuProc.command = ["bash", "-c", "exec bash \"" + scriptsDir + "/system_perf.sh\" cpu \"$1\"", "qs-perf", v];
        cpuProc.running = true;
    }
    function setGpu(v) {
        gpu = v;
        if (gpuProc.running) { _gpuPending = v; return; }
        gpuBusy = true;
        gpuProc.command = ["bash", "-c", "exec bash \"" + scriptsDir + "/system_perf.sh\" gpu \"$1\"", "qs-perf", v];
        gpuProc.running = true;
    }
    function _line(line) {
        var i = line.indexOf(":"); if (i < 0) return;
        var k = line.substring(0, i), v = line.substring(i + 1).trim();
        if (k === "CPU") {
            pl.cpu = v;
            // Keep the combined profile (control center / gaming hub) in sync: it follows the CPU profile
            if (["low", "medium", "high"].indexOf(v) >= 0) globalState.perfProfile = v;
        } else if (k === "GPU") pl.gpu = v;
    }

    // Re-read when the combined profile is applied elsewhere
    Connections {
        target: globalState
        function onPerfApplyingChanged() { if (!globalState.perfApplying) pl.refresh(); }
    }

    Process {
        id: getProc
        command: ["bash", "-c", "exec bash \"" + scriptsDir + "/system_perf.sh\" get"]
        stdout: SplitParser { onRead: (line) => pl._line(line) }
    }
    Process {
        id: cpuProc
        command: ["true"]
        stdout: SplitParser { onRead: (line) => pl._line(line) }
        onRunningChanged: {
            if (running) return;
            pl.cpuBusy = false;
            if (pl._cpuPending !== "") { var v = pl._cpuPending; pl._cpuPending = ""; pl.setCpu(v); }
        }
    }
    Process {
        id: gpuProc
        command: ["true"]
        stdout: SplitParser { onRead: (line) => pl._line(line) }
        onRunningChanged: {
            if (running) return;
            pl.gpuBusy = false;
            if (pl._gpuPending !== "") { var v = pl._gpuPending; pl._gpuPending = ""; pl.setGpu(v); }
        }
    }
}
