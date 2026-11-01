import QtQuick
import Quickshell
import Quickshell.Hyprland

// Screen recording, screenshots and the gaming panel
MediaState {
    property int    recFps:          60
    property bool   recMic:          false
    property string recResolution:   "native"
    property bool   recRegion:       false
    property bool   recRegionPicking: false
    property bool   recStarting:     false
    property bool   recActive:       false
    property bool   recPaused:       false
    property bool   recSaving:       false
    property bool   recBulgeOpen:    false
    property string recBackend:      ""
    property string recBackendAvail: ""
    property string recLastFile:     ""
    property real   recAccumMs:      0
    property real   recSegStartMs:   0
    property real   recNowMs:        0
    property bool   recMicLive:      false
    property bool   recMicCtl:       false
    property string recOrigin:       ""
    property bool   gamingOpen:      false
    property bool   gamingCapturing: false
    property real   gamingPingMs:    -1
    property real   gamingFps:       -1
    property real   gamingFrametime: -1
    property string gamingFpsGame:   ""
    property bool   gamingFpsLive:   false
    property bool   gamingPingLost:  false
    readonly property bool recNotchAllowed: (recOrigin !== "gaming" || gamingFloating) && !gamingOpen
    property bool   gamingEscOnOpen: true

    property var    gamingModules: ({ status: true, rings: true, perf: true, actions: true, sliders: true,
                                      fps: true, cpu: true, gpu: true, ram: true, ping: true, gpuExtra: true })

    readonly property var gamingMetricKeys: ["fps", "cpu", "gpu", "ram", "ping"].filter(function (k) { return gamingModules[k] !== false; })
    function gamingModuleOn(k) { return gamingModules[k] !== false; }
    property bool   gamingEscSent:   false
    property bool   gamingKeyGrab:   false
    property bool   gamingFloating:  false
    property real   gamingFloatX:    0
    property real   gamingFloatY:    0
    property real   gamingFloatOpacity: 1.0

    function setGamingFloating(on) {
        on = !!on;
        if (gamingFloating === on) return;
        if (on) {
            gamingEscTimer.stop();
            gamingGrabTimer.stop();
            gamingCloseEscTimer.stop();
            gamingKeyGrab = false;
            gamingEscSent = false;
            gamingFloating = true;
            gamingOpen = false;
        } else {
            gamingFloating = false;
            if (!gamingOpen) toggleGaming();
        }
        savePrefs();
    }

    function toggleGaming() {
        if (lockScreenActive && !gamingOpen) return;
        if (gamingFloating && !gamingOpen) { gamingFloating = false; savePrefs(); }
        gamingOpen = !gamingOpen;
        if (gamingOpen) {
            recBulgeOpen = false;
            gamingCloseEscTimer.stop();
            gamingEscSent = false;
            gamingKeyGrab = false;
            if (gamingEscOnOpen) gamingEscTimer.restart();
        } else {
            gamingEscTimer.stop();
            gamingGrabTimer.stop();
            gamingKeyGrab = false;
            if (gamingEscSent) gamingCloseEscTimer.restart();
            gamingEscSent = false;
        }
    }

    function gamingSendEsc(tag) {
        Quickshell.execDetached(["bash", "-c",
            "log=/tmp/qs-gaming-esc.log; " +
            "if command -v wtype >/dev/null 2>&1; then wtype -s 40 -P Escape -s 70 -p Escape 2>>\"$log\" && echo \"$(date +%T) " + tag + " wtype ok\" >>\"$log\"; " +
            "elif command -v ydotool >/dev/null 2>&1; then ydotool key --key-delay 70 1:1 1:0 2>>\"$log\" && echo \"$(date +%T) " + tag + " ydotool ok\" >>\"$log\"; " +
            "else hyprctl dispatch sendshortcut ', Escape, activewindow' >>\"$log\" 2>&1; echo \"$(date +%T) " + tag + " hyprctl\" >>\"$log\"; fi"]);
    }

    readonly property bool recBusy: recStarting || recActive || recSaving
    readonly property real recElapsedMs: recAccumMs + ((recActive && !recPaused && recSegStartMs > 0) ? Math.max(0, recNowMs - recSegStartMs) : 0)

    function recFmt(ms) {
        var t = Math.max(0, Math.floor(ms / 1000));
        function p(n) { return (n < 10 ? "0" : "") + n; }
        return p(Math.floor(t / 3600)) + ":" + p(Math.floor(t % 3600 / 60)) + ":" + p(t % 60);
    }

    function recStart(origin) {
        if (recBusy || lockScreenActive) return;
        recOrigin = origin === "gaming" ? "gaming" : "";
        recStarting = true;
        if (recOrigin !== "gaming") closeAll(true);
        recStartDelay.restart();
    }

    function recTogglePause() { if (recActive && !recSaving && recProcess.running) recProcess.write("pause\n"); }

    function recStop() {
        if (recStartDelay.running) { recStartDelay.stop(); recStarting = false; return; }
        if (recRegionPicking) { recRegionPicking = false; recStarting = false; return; }
        if (recProcess.running && !recSaving) recProcess.write("stop\n");
    }

    function recToggle(origin) { if (recBusy) recStop(); else recStart(origin !== undefined ? origin : (gamingOpen ? "gaming" : "")); }

    function recToggleMic() {
        if (recActive && !recSaving && recMicCtl && recProcess.running) recProcess.write("mic " + (recMicLive ? "0" : "1") + "\n");
    }

    property bool   ssPopupVisible:   false
    property bool   ssPopupCountdown: false
    property int    ssPopupSeconds:   5
    property int    ssPopupNonce:     0
    property bool   waitingForGrabRelease: false
    property int    selectCaptureTrigger:  0
    property bool   shotPreparing: false
    property bool   shotPicking:   false
    property string shotFrozen:    ""
    property string shotMonitor:   ""
    property string shotDir:       ""
    property int    shotNonce:     0
    property int    shotColorIdx:  0
    property int    shotSizeIdx:   1
    property string shotTool:      "pen"
    readonly property var shotColors: ["#F44336", "#FF9800", "#FFEB3B", "#4CAF50", "#2196F3", "#9C27B0", "#FFFFFF", "#000000"]

    function shotStart() {
        if (lockScreenActive || shotPicking || shotPreparing) return;
        shotPreparing = true;
        shotMonitor = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
        shotFreezeDelay.restart();
    }

    function shotClose() { shotPicking = false; shotPreparing = false; }

    function showSsPopup(isCountdown) {
        ssPopupCountdown = isCountdown;
        ssPopupSeconds   = isCountdown ? 5 : 0;
        ssPopupVisible   = true;
        ssPopupNonce++;
    }

    function hideSsPopup() {
        ssPopupVisible = false;
    }

    function tickCountdown() {
        ssPopupSeconds -= 1;
        if (ssPopupSeconds <= 0) {
            ssPopupCountdown = false;
        }
    }

    function shotFull() {
        closeControlPanels();
        shotFullDelay.restart();
    }
}
