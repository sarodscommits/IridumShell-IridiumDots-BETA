import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import ".."
import "../ui"
import "../widgets"
import "../panels"

// Gaming mode overlay window
PanelWindow {
    id: gamingWindow
    readonly property var gmPerfProc: gmPerf.gmPerfProc
    readonly property var gmPerfReadProc: gmPerf.gmPerfReadProc
    WlrLayershell.namespace: floatLayout ? "iridium-gaming-float" : "quickshell"
    property bool surfaceSwap: false
    onFloatLayoutChanged: if (visible) { surfaceSwap = true; gmSurfaceSwapTimer.restart(); }
    Timer { id: gmSurfaceSwapTimer; interval: 60; repeat: false; onTriggered: gamingWindow.surfaceSwap = false }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: (shown && globalState.gamingKeyGrab) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors.left:   true
    anchors.top:    floatLayout
    anchors.right:  floatLayout
    anchors.bottom: floatLayout
    property real dragX: globalState.gamingFloatX
    property real dragY: globalState.gamingFloatY
    property bool dragging: false
    readonly property real floatW: margin * 2 + panelW
    readonly property Item _gr: gmContentLoader.item
    readonly property real _gmPanelH: _gr ? _gr.panelItem.height : 0
    readonly property real floatH: _gmPanelH + 24
    function clampX(v) { return Math.max(0, Math.min(v, width  - floatW)); }
    function clampY(v) { return Math.max(0, Math.min(v, height - floatH)); }
    readonly property real floatX: floatLayout ? clampX(dragX) : 0
    readonly property real floatY: floatLayout ? clampY(dragY) : 0
    exclusionMode: floatLayout ? ExclusionMode.Normal : ExclusionMode.Ignore
    color: "transparent"

    readonly property bool shown: (globalState.gamingOpen || globalState.gamingFloating) && !globalState.lockScreenActive

    property bool floatLayout: false
    property real modeFade: 1
    readonly property var floatHidden: ["status", "rings", "perf", "actions", "sliders", "gpuExtra"]
    function modOn(k) { return !(floatLayout && floatHidden.indexOf(k) >= 0) && globalState.gamingModuleOn(k); }
    SequentialAnimation {
        id: gmModeAnim
        NumberAnimation { target: gamingWindow; property: "modeFade"; to: 0; duration: 140; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasizedAccelerate }
        ScriptAction { script: gamingWindow.floatLayout = globalState.gamingFloating }
        PauseAnimation { duration: 80 }
        NumberAnimation { target: gamingWindow; property: "modeFade"; to: 1; duration: 380; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasizedDecelerate }
    }
    Connections {
        target: globalState
        function onGamingFloatingChanged() {
            if (gamingWindow.prog < 0.05) {
                gmModeAnim.stop();
                gamingWindow.floatLayout = globalState.gamingFloating;
                gamingWindow.modeFade = 1;
            } else {
                gmModeAnim.restart();
            }
        }
    }
    Component.onCompleted: {
        floatLayout = globalState.gamingFloating;
        if (shown) { gmArmTimer.restart(); gmStartProcsTimer.restart(); }
    }
    readonly property real floatAlpha: globalState.gamingFloatOpacity

    Item {
        id: gmKeyCatcher
        focus: true
        Keys.onEscapePressed: (event) => {
            event.accepted = true;
            if (globalState.gamingOpen) globalState.toggleGaming();
        }
        Connections {
            target: globalState
            function onGamingKeyGrabChanged() { if (globalState.gamingKeyGrab) gmKeyCatcher.forceActiveFocus(); }
        }
    }
    property bool armed: false
    Timer { id: gmArmTimer; interval: 34; repeat: false; onTriggered: gamingWindow.armed = true }
    property real prog: (shown && armed) ? 1 : 0
    readonly property bool animating: prog > 0.001 && prog < 0.999
    Behavior on prog { id: gmProgBeh; NumberAnimation { duration: gmProgBeh.targetValue > 0.5 ? 420 : 220; easing.type: Easing.BezierSpline; easing.bezierCurve: gmProgBeh.targetValue > 0.5 ? [0.05, 0.7, 0.1, 1.0, 1, 1] : [0.3, 0.0, 0.8, 0.15, 1, 1] } }
    visible: (shown || prog > 0.005) && !globalState.gamingCapturing && !surfaceSwap

    readonly property real margin: 16
    readonly property real panelW: floatLayout ? 380 : 440
    readonly property real tabMaxW: 200
    implicitWidth: margin + panelW + tabMaxW
    implicitHeight: _gmPanelH + 24

    mask: Region {
        x: (gamingWindow.dragging || !gamingWindow._gr) ? 0 : gamingWindow.floatLayout ? gamingWindow._gr.x + gamingWindow._gr.panelItem.x + gamingWindow._gr.colItem.x + gamingWindow._gr.floatRowItem.x : gamingWindow.margin
        y: (gamingWindow.dragging || !gamingWindow._gr) ? 0 : gamingWindow.floatLayout ? gamingWindow._gr.y + gamingWindow._gr.panelItem.y + gamingWindow._gr.colItem.y + gamingWindow._gr.floatRowItem.y : gamingWindow._gr.panelItem.y
        width:  gamingWindow.dragging ? gamingWindow.width  : !gamingWindow._gr ? 0 : gamingWindow.floatLayout ? gamingWindow._gr.floatRowItem.width  : gamingWindow.panelW
        height: gamingWindow.dragging ? gamingWindow.height : !gamingWindow._gr ? 0 : gamingWindow.floatLayout ? gamingWindow._gr.floatRowItem.height : gamingWindow._gr.panelItem.height
        Region {
            x: gamingWindow.margin + gamingWindow.panelW - 1; y: gamingWindow._gr ? gamingWindow._gr.tabItem.y : 0
            width: (gamingWindow._gr && gamingWindow._gr.tabItem.width > 0.5) ? gamingWindow._gr.tabItem.width + 1 : 0
            height: gamingWindow._gr ? gamingWindow._gr.tabItem.height : 0
        }
    }

    GamingTelemetry { id: gmTelemetry; active: gamingWindow.shown }
    Timer {
        id: gmStartProcsTimer; interval: 480; repeat: false
        onTriggered: {
            if (!gamingWindow.shown) return;
            gmTelemetry.startProcs();
            if (!gmPerf.gmPerfReadProc.running && !gmPerf.gmPerfProc.running) gmPerf.gmPerfReadProc.running = true;
        }
    }
    onShownChanged: {
        if (shown) {
            gmArmTimer.restart();
            globalState.gamingPingMs = -1; globalState.gamingPingLost = false;
            gmTelemetry.resetHistory();
            globalState.gamingFpsLive = false;
            gmStartProcsTimer.restart();
        } else {
            gmArmTimer.stop(); armed = false;
            gmStartProcsTimer.stop();
            gmTelemetry.stopProcs();
            globalState.gamingFpsLive = false;
        }
    }

    Process {
        id: gamingShotProc
        running: false
        command: ["bash", "-c", "exec bash \"" + scriptsDir + "/screenshot_full.sh\" \"$1\" \"$2\"",
        "qs-shot", tr("gm_shot_saved"), tr("gm_title")]
        onRunningChanged: if (!running) globalState.gamingCapturing = false
    }
    Timer { id: gamingShotDelay; interval: 160; repeat: false; onTriggered: gamingShotProc.running = true }
    function capture() {
        if (globalState.gamingCapturing || gamingShotProc.running) return;
        globalState.gamingCapturing = true;
        gamingShotDelay.restart();
    }




    GamingPerf { id: gmPerf }
    function setPerfProfile(prof) { gmPerf.setPerfProfile(prof); }

    function tempColor(t) { return t > 85 ? pal.error : t > 70 ? pal.accent : pal.primary; }
    function pingColor(ms, lost) { return (lost || ms > 120) ? pal.error : ms > 60 ? pal.accent : pal.primary; }

    Timer { id: gmKeepTimer; interval: 10000; repeat: false; onTriggered: if (!gamingWindow.visible) gcTimer.restart() }
    onVisibleChanged: if (!visible) gmKeepTimer.restart()
    Loader {
        id: gmContentLoader
        anchors.fill: parent
        active: gamingWindow.shown || gamingWindow.visible || gmKeepTimer.running
        source: Qt.resolvedUrl("GamingContent.qml")
    }
}
