import QtQuick
import Quickshell
import Quickshell.Io

// Battery polling, low/full warnings and the battery IPC simulator
MediaTrackServices {
    Process {
        id: batteryProcess
        command: ["bash", "-c",
        "BAT=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1); " +
        "if [ -z \"$BAT\" ]; then printf 'none\\t0\\tUnknown\\t0\\t-1'; exit 0; fi; " +
        "CAP=$(cat \"$BAT/capacity\" 2>/dev/null || echo 0); " +
        "ST=$(cat \"$BAT/status\" 2>/dev/null || echo Unknown); " +
        "AC=0; for P in /sys/class/power_supply/*; do " +
        "  T=$(cat \"$P/type\" 2>/dev/null); " +
        "  if [ \"$T\" = Mains ] || [ \"$T\" = USB ]; then [ \"$(cat \"$P/online\" 2>/dev/null)\" = 1 ] && AC=1; fi; " +
        "done; " +
        "NOW=$(cat \"$BAT/energy_now\" 2>/dev/null || cat \"$BAT/charge_now\" 2>/dev/null || echo 0); " +
        "FULL=$(cat \"$BAT/energy_full\" 2>/dev/null || cat \"$BAT/charge_full\" 2>/dev/null || echo 0); " +
        "PW=$(cat \"$BAT/power_now\" 2>/dev/null || cat \"$BAT/current_now\" 2>/dev/null || echo 0); " +
        "PW=${PW#-}; MIN=-1; " +
        "if [ \"$PW\" -gt 0 ] 2>/dev/null; then " +
        "  if [ \"$ST\" = Charging ]; then MIN=$(( (FULL - NOW) * 60 / PW )); " +
        "  elif [ \"$ST\" = Discharging ]; then MIN=$(( NOW * 60 / PW )); fi; " +
        "fi; " +
        "printf 'bat\\t%s\\t%s\\t%s\\t%s' \"$CAP\" \"$ST\" \"$AC\" \"$MIN\""
        ]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                if (globalState.batterySim) return;
                var parts = line.split("\t");
                if (parts.length >= 5) {
                    var st = parts[2].trim();
                    globalState.hasBattery      = parts[0].trim() === "bat";
                    globalState.batteryPercent  = Math.max(0, Math.min(100, parseInt(parts[1]) || 0));
                    globalState.batteryStatus   = st;
                    globalState.batteryCharging = st === "Charging";
                    globalState.batteryPlugged  = parts[3].trim() === "1" || st === "Charging" || st === "Full" || st === "Not charging";
                    var m = parseInt(parts[4]);
                    globalState.batteryMinutes  = (isNaN(m) || m < 0 || m > 6000) ? -1 : m;
                    batteryMonitor.evaluate();
                }
            }
        }
    }

    Timer {
        interval: globalState.hasBattery ? 10000 : 300000
        running: !globalState.batterySim; repeat: true
        onTriggered: batteryProcess.running = true
    }

    Process {
        id: batteryWatchProcess
        running: globalState.hasBattery && !globalState.batterySim
        command: ["bash", "-c", "command -v udevadm >/dev/null 2>&1 || exit 0; exec udevadm monitor --udev --subsystem-match=power_supply"]
        stdout: SplitParser { onRead: (line) => batteryWatchDebounce.restart() }
    }

    Timer {
        id: batteryWatchDebounce
        interval: 400; repeat: false
        onTriggered: if (!globalState.batterySim) batteryProcess.running = true
    }

    QtObject {
        id: batteryMonitor
        readonly property string lowTag: "battery-low"
        function simulate(pct, plugged) {
            var g = globalState;
            var p = Math.max(0, Math.min(100, pct));
            g.batterySim      = true;
            g.battPrimed      = true;
            g.hasBattery      = true;
            g.batteryPercent  = p;
            g.batteryPlugged  = plugged;
            g.batteryCharging = plugged && p < 100;
            g.batteryStatus   = plugged ? (p >= 100 ? "Full" : "Charging") : "Discharging";
            g.batteryMinutes  = plugged ? (p >= 100 ? -1 : Math.round((100 - p) * 1.2)) : p * 4;
            evaluate();
        }
        function evaluate() {
            var g = globalState;
            if (!g.hasBattery) { resetFlags(); return; }
            var full = g.batteryPlugged && (g.batteryStatus === "Full" || g.batteryPercent >= 100);
            if (!g.battPrimed) {
                g.battPrimed = true;
                g.battFullNotified = full;
            }
            if (g.batteryPlugged) onPlugged(full);
            else onUnplugged();
        }
        function resetFlags() {
            var g = globalState;
            if (g.battLowNotified) toastWindow.removeToastByTag(lowTag);
            g.battLowNotified = false;
            g.battFullNotified = false;
            g.battPrimed = false;
        }
        function onPlugged(full) {
            var g = globalState;
            if (g.battLowNotified) {
                toastWindow.removeToastByTag(lowTag);
                g.battLowNotified = false;
            }
            if (full && !g.battFullNotified) {
                g.battFullNotified = true;
                if (!g.dndEnabled)
                toastWindow.pushToastEx({
                    app: tr("batt_title"), summary: tr("batt_full_title"), body: tr("batt_full_body"),
                    icon: "", tag: "battery-full", timeout: 6000
                });
            }
        }
        function onUnplugged() {
            var g = globalState;
            g.battFullNotified = false;
            toastWindow.removeToastByTag("battery-full");
            if (g.batteryPercent <= g.battLowThreshold && !g.battLowNotified) {
                g.battLowNotified = true;
                if (!g.dndEnabled) g.playUiSound("2", g.notificationSoundVolume);
                toastWindow.pushToastEx({
                    app: tr("batt_title"), summary: tr("batt_low_title") + " · " + g.batteryPercent + "%",
                    body: tr("batt_low_body"), icon: "", critical: true, persistent: true, tag: lowTag
                });
            } else if (g.batteryPercent > g.battLowThreshold && g.battLowNotified) {
                toastWindow.removeToastByTag(lowTag);
                g.battLowNotified = false;
            }
        }
    }

    IpcHandler {
        target: "battery"
        function sim(pct: int, plugged: bool): void {
            batteryDemoTimer.stop();
            batteryMonitor.simulate(pct, plugged);
        }
        function demo(): void {
            batteryDemoTimer.phase = 0;
            batteryDemoTimer.level = 20;
            batteryMonitor.simulate(20, false);
            batteryDemoTimer.restart();
        }
        function off(): void {
            batteryDemoTimer.stop();
            globalState.batterySim = false;
            globalState.hasBattery = false;
            batteryMonitor.evaluate();
            batteryProcess.running = true;
        }
        function status(): string {
            var g = globalState;
            return (g.batterySim ? "sim" : "real") + " " + (g.hasBattery ? g.batteryPercent + "% " + g.batteryStatus : "sin bateria");
        }
    }

    Timer {
        id: batteryDemoTimer
        property int phase: 0
        property int level: 20
        interval: 700; repeat: true
        onTriggered: {
            if (phase === 0) {
                level -= 1;
                batteryMonitor.simulate(level, false);
                if (level <= 12) phase = 1;
            } else {
                level = Math.min(100, level + 4);
                batteryMonitor.simulate(level, true);
                if (level >= 100) stop();
            }
        }
    }
}
