import QtQuick
import Quickshell
import Quickshell.Io

// Volume, microphone, brightness and eye-care processes
NotificationServices {
    property alias brightnessApplyProcess: brightnessApplyProcess

    Process {
        id: eyeCareCheckProc
        command: ["sh", "-c", "command -v hyprsunset"]
        running: true
        onExited: (code) => globalState.eyeCareHasSunset = (code === 0)
    }

    Process {
        id: eyeCareSunsetProc
        command: ["sh", "-c", "pkill -x hyprsunset; exec hyprsunset -t " + globalState.eyeCareTemp]
        running: globalState.eyeCare && globalState.eyeCareHasSunset
    }

    Process {
        id: brightnessApplyProcess
        command: ["bash", "-c",
        "read -r V; " +
        "LOG=\"$HOME/.cache/qs-brightness.log\"; " +
        "if command -v brightnessctl >/dev/null 2>&1 && ls /sys/class/backlight/*/brightness >/dev/null 2>&1; then " +
        "  brightnessctl set \"${V}%\" >\"$LOG\" 2>&1 || echo \"[brightnessctl fallo, ver $LOG]\" >&2; " +
        "elif command -v ddcutil >/dev/null 2>&1; then " +
        "  BF=\"$HOME/.cache/qs-ddc-bus\"; BUS=$(cat \"$BF\" 2>/dev/null); " +
        "  if [ \"$BUS\" = \"none\" ]; then exit 0; fi; " +
        "  if [ -z \"$BUS\" ]; then " +
        "    BUS=$(ddcutil detect 2>/dev/null | grep -m1 'I2C bus' | grep -oE '[0-9]+$'); " +
        "    if [ -n \"$BUS\" ]; then echo \"$BUS\" > \"$BF\"; else echo \"none\" > \"$BF\"; fi; " +
        "  fi; " +
        "  [ -n \"$BUS\" ] && ddcutil --sleep-multiplier 0.1 setvcp 10 \"$V\" -b \"$BUS\" --noverify >\"$LOG\" 2>&1; " +
        "else " +
        "  echo \"[neither brightnessctl nor ddcutil available]\" > \"$LOG\"; " +
        "fi"
        ]
        running: false
        stdinEnabled: true
        property bool _busy:   false
        property int  _pending: -1

        function queue(v) {
            if (brightnessApplyProcess._busy) {
                brightnessApplyProcess._pending = v;
                return;
            }
            brightnessApplyProcess._run(v);
        }

        function _run(v) {
            brightnessApplyProcess._busy = true;
            globalState.lastBrightnessSetMs = Date.now();
            brightnessApplyProcess.running = true;
            brightnessApplyProcess.write(v + "\n");
            brightnessApplyProcess.stdinEnabled = false;
            brightnessApplyWatchdog.restart();
        }

        onRunningChanged: {
            if (!running) {
                brightnessApplyProcess._busy = false;
                brightnessApplyProcess.stdinEnabled = true;
                if (brightnessApplyProcess._pending >= 0) {
                    var p = brightnessApplyProcess._pending;
                    brightnessApplyProcess._pending = -1;
                    brightnessApplyProcess._run(p);
                }
            }
        }
    }

    Timer {
        id: brightnessApplyWatchdog
        interval: 15000; repeat: false
        onTriggered: { if (brightnessApplyProcess.running) brightnessApplyProcess.running = false; }
    }

    Process {
        id: hwSinkDetectProcess
        command: ["bash", "-c",
        "NEWHW_NAME=$(pw-link -l 2>/dev/null | grep -B1 '|<- easyeffects_sink:monitor_' | grep ':playback_FL$' | head -1 | sed 's/:playback_FL$//'); " +
        "if [ -n \"$NEWHW_NAME\" ] && command -v jq >/dev/null 2>&1; then " +
        "  NEWHW_ID=$(pw-dump 2>/dev/null | jq -r --arg n \"$NEWHW_NAME\" '.[] | select(.info.props.\"node.name\"==$n and .type==\"PipeWire:Interface:Node\") | .id' | head -1); " +
        "  [ -n \"$NEWHW_ID\" ] && echo \"$NEWHW_ID\" > \"$HOME/.cache/qs-eq-hw-sink\"; " +
        "  [ -n \"$NEWHW_ID\" ] && echo \"$NEWHW_NAME\" > \"$HOME/.cache/qs-eq-hw-sink-name\"; " +
        "fi; true"]
        running: true
        onRunningChanged: if (!running) volumeReadDebounce.restart()
    }

    Timer {
        interval: 30000; running: true; repeat: true
        onTriggered: if (!hwSinkDetectProcess.running) hwSinkDetectProcess.running = true
    }

    Timer {
        id: hwSinkDetectDebounce
        interval: 400; repeat: false
        onTriggered: { if (hwSinkDetectProcess.running) restart(); else hwSinkDetectProcess.running = true; }
    }

    Process {
        id: volumeProcess
        command: ["bash", "-c",
        "HW=$(cat \"$HOME/.cache/qs-eq-hw-sink\" 2>/dev/null); " +
        "[ -z \"$HW\" ] && HW=\"@DEFAULT_AUDIO_SINK@\"; " +
        "wpctl get-volume \"$HW\""]
        running: false
        stdout: SplitParser {
            onRead: (line) => {
                var trimmed = line.trim();
                var muted = trimmed.indexOf("[MUTED]") !== -1;
                var match = trimmed.match(/Volume:\s*([\d.]+)/);
                if (match) {
                    var vol = Math.round(parseFloat(match[1]) * 100);
                    if (!isNaN(vol)) {
                        vol = Math.round(vol / globalState.hwVolumeBoostMultiplier);
                        vol = Math.max(0, Math.min(100, vol));
                        globalState.rawVolumeValue = vol;
                        if (muted) {
                            globalState.isMuted = true;
                            globalState.volumeText = "Mute";
                        } else {
                            globalState.isMuted = false;
                            globalState.volumeText = vol + "%";
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: volumeReadDebounce
        interval: 150; repeat: false
        onTriggered: { if (volumeProcess.running) restart(); else volumeProcess.running = true; }
    }

    Timer {
        interval: audioEventProcess.running ? 15000 : 1000
        running: true; repeat: true
        onTriggered: if (!volumeProcess.running) volumeProcess.running = true
    }

    Process {
        id: audioEventProcess
        property int failures: 0
        command: ["bash", "-c", "command -v pactl >/dev/null 2>&1 && LC_ALL=C exec pactl subscribe"]
        running: globalState.deferredReady
        stdout: SplitParser {
            onRead: (line) => {
                var m = line.match(/^Event '(\w+)' on (sink|source|server)\b(?!-)/);
                if (!m) return;
                audioEventProcess.failures = 0;
                var kind = m[1], fac = m[2];
                if (fac === "sink") {
                    volumeReadDebounce.restart();
                    if (kind === "new" || kind === "remove") hwSinkDetectDebounce.restart();
                } else if (fac === "source") {
                    if (globalState.quickSlidersVisible) micVolumeDebounce.restart();
                } else {
                    hwSinkDetectDebounce.restart();
                    micVolumeDebounce.restart();
                }
            }
        }
        onRunningChanged: {
            if (!running && globalState.deferredReady && failures < 5) {
                failures++;
                audioEventRestartTimer.start();
            }
        }
    }

    Timer { id: audioEventRestartTimer; interval: 3000; repeat: false; onTriggered: audioEventProcess.running = true }

    Process {
        id: micVolumeProcess
        command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SOURCE@"]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                var trimmed = line.trim();
                var match = trimmed.match(/Volume:\s*([\d.]+)/);
                if (match) {
                    var vol = Math.round(parseFloat(match[1]) * 100);
                    if (!isNaN(vol)) globalState.rawMicVolume = vol;
                }
            }
        }
    }

    Timer {
        id: micVolumeDebounce
        interval: 60; repeat: false
        onTriggered: { if (micVolumeProcess.running) restart(); else micVolumeProcess.running = true; }
    }

    Timer {
        interval: audioEventProcess.running ? 30000 : 1000
        running: globalState.quickSlidersVisible
        repeat: true; triggeredOnStart: true
        onTriggered: if (!micVolumeProcess.running) micVolumeProcess.running = true
    }

    Process {
        id: brightnessReadProcess
        command: ["bash", "-c",
        "if command -v brightnessctl >/dev/null 2>&1 && ls /sys/class/backlight/*/brightness >/dev/null 2>&1; then " +
        "  echo \"$(brightnessctl get) $(brightnessctl max)\"; " +
        "elif command -v ddcutil >/dev/null 2>&1; then " +
        "  BF=\"$HOME/.cache/qs-ddc-bus\"; BUS=$(cat \"$BF\" 2>/dev/null); " +
        "  if [ -z \"$BUS\" ]; then BUS=$(ddcutil detect 2>/dev/null | grep -m1 'I2C bus' | grep -oE '[0-9]+$'); [ -n \"$BUS\" ] && echo \"$BUS\" > \"$BF\"; fi; " +
        "  if [ -n \"$BUS\" ]; then " +
        "    OUT=$(ddcutil --sleep-multiplier 0.1 getvcp 10 -b \"$BUS\" 2>/dev/null); " +
        "    CUR=$(echo \"$OUT\" | grep -oE 'current value *= *[0-9]+' | grep -oE '[0-9]+'); " +
        "    MAX=$(echo \"$OUT\" | grep -oE 'max value *= *[0-9]+' | grep -oE '[0-9]+'); " +
        "    [ -n \"$CUR\" ] && [ -n \"$MAX\" ] && echo \"$CUR $MAX\"; " +
        "  fi; " +
        "fi"]
        running: true
        onRunningChanged: { if (running) brightnessReadWatchdog.restart(); }
        stdout: SplitParser {
            onRead: (line) => {
                var parts = line.trim().split(" ");
                if (parts.length === 2) {
                    var cur = parseInt(parts[0]);
                    var max = parseInt(parts[1]);
                    if (!isNaN(cur) && !isNaN(max) && max > 0 &&
                    !brightnessApplyProcess._busy &&
                    (Date.now() - globalState.lastBrightnessSetMs) > 3000)
                    globalState.rawBrightness = Math.round(cur / max * 100);
                }
            }
        }
    }

    Timer {
        id: brightnessReadWatchdog
        interval: 12000; repeat: false
        onTriggered: { if (brightnessReadProcess.running) brightnessReadProcess.running = false; }
    }

    Timer {
        interval: 15000; repeat: true; triggeredOnStart: true
        running: globalState.quickSlidersVisible
        property double _last: 0
        onTriggered: {
            if (_last > 0 && Date.now() - _last < 14000) return;
            if (globalState.brightnessAdjusting) return;
            if (brightnessReadProcess.running) return;
            if (brightnessApplyProcess._busy || brightnessApplyProcess.running) return;
            if (Date.now() - globalState.lastBrightnessSetMs < 5000) return;
            _last = Date.now();
            brightnessReadProcess.running = true;
        }
    }
}
