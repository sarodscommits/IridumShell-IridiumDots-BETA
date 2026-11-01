import QtQuick
import QtQuick.Window
import QtQuick.Effects
import QtQuick.Shapes
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Outer shadow surface for the bar/frame silhouette
PanelWindow {
    id: frameShadowWindow
    WlrLayershell.namespace: "iridium-shadow-frame"
    WlrLayershell.layer: globalState.desktopEditMode ? WlrLayer.Overlay : WlrLayer.Top
    anchors.top:    true
    anchors.bottom: true
    anchors.left:   true
    anchors.right:  true
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}

    readonly property bool barOn:    globalState.shellShadowBarOn
    readonly property bool panelsOn: globalState.shellShadowPanelsOn
    visible: (barOn || panelsOn) && !resetting

    property bool   resetting: false
    property double lastChange: 0
    property double lastSwap: 0
    property double lastReset: 0
    property bool   sawSwap: false
    function reset(reason) {
        if (resetting) return;
        console.warn("[shell-shadows] recreating the bar shadow: " + reason);
        lastReset = Date.now();
        resetting = true;
        fsResetTimer.restart();
    }
    Timer { id: fsResetTimer; interval: 80; repeat: false; onTriggered: frameShadowWindow.resetting = false }
    Timer { interval: 2500; running: true; repeat: false; onTriggered: frameShadowWindow.reset("startup") }
    readonly property bool watchOk: visible && sawSwap && strength > 0.01 && frameRoot.opacity > 0.5
        && !globalState.lockScreenActive && !globalState.wpFullscreenActive
    function noteChange() {
        if (!watchOk || fsStallTimer.running) return;
        lastChange = Date.now();
        fsStallTimer.start();
    }
    Timer {
        id: fsStallTimer
        interval: 700; repeat: false
        onTriggered: {
            var w = frameShadowWindow;
            if (w.watchOk && w.lastSwap < w.lastChange && Date.now() - w.lastReset > 3000)
                w.reset("the window didn't present new frames");
        }
    }
    Connections {
        target: globalState
        function onShellShadowGenChanged() { frameShadowWindow.reset("ipc"); }
    }
    readonly property bool panelOpen: unifiedFrame.bulgeDepth > 0.5
        || unifiedFrame.topH > unifiedFrame.topBaseH + 0.5
        || unifiedFrame.leftW  > unifiedFrame.edgeBaseSize + 0.5
        || unifiedFrame.rightW > unifiedFrame.edgeBaseSize + 0.5
    property real panelAmt: panelOpen ? 1 : 0
    Behavior on panelAmt { M3NumberAnim { duration: 220 } }
    readonly property real strength: barOn ? 1 : (panelsOn ? panelAmt : 0)

    Loader {
      active: !frameShadowWindow.resetting
      sourceComponent: Component {
    Item {
        id: fsRootItem
        readonly property var qwin: Window.window
        Connections {
            target: fsRootItem.qwin
            ignoreUnknownSignals: true
            function onFrameSwapped() { frameShadowWindow.lastSwap = Date.now(); frameShadowWindow.sawSwap = true; }
        }
        width:  unifiedFrame.contentW
        height: unifiedFrame.contentH
        scale:  unifiedFrame.zoomK
        transformOrigin: Item.TopLeft
        opacity: frameRoot.opacity * frameShadowWindow.strength
        visible: opacity > 0.003

        Item {
            id: fsSpace
            width:  unifiedFrame.barVertical ? parent.height : parent.width
            height: unifiedFrame.barVertical ? parent.width  : parent.height
            transform: Matrix4x4 { matrix: unifiedFrame.frameMatrix }

            readonly property bool live: frameShadowWindow.visible && parent.visible
            readonly property string fullPath: live ? unifiedFrame.shadowPathSvg(false) : ""
            onFullPathChanged: frameShadowWindow.noteChange()
            readonly property string castPath: !live ? "" : (frameShadowWindow.panelsOn ? fullPath : unifiedFrame.shadowPathSvg(true))
            readonly property int  thick: globalState.shellShadowRange
            readonly property real dil: Math.round(thick * 0.2)

            Shape {
                id: fsMask
                anchors.fill: parent
                visible: false
                layer.enabled: true
                ShapePath {
                    fillColor: "black"
                    fillRule: ShapePath.OddEvenFill
                    strokeColor: "transparent"
                    PathSvg { path: fsSpace.fullPath }
                }
            }
            Item {
                id: fsCast
                anchors.fill: parent
                visible: false
                layer.enabled: true
                Repeater {
                    model: [[0, 0], [1, 0], [-1, 0], [0, 1], [0, -1], [0.7071, 0.7071], [-0.7071, 0.7071], [0.7071, -0.7071], [-0.7071, -0.7071]]
                    delegate: Shape {
                        required property var modelData
                        x: Math.round(modelData[0] * fsSpace.dil)
                        y: Math.round(modelData[1] * fsSpace.dil)
                        width: fsCast.width
                        height: fsCast.height
                        ShapePath {
                            fillColor: "black"
                            fillRule: ShapePath.OddEvenFill
                            strokeColor: "transparent"
                            PathSvg { path: fsSpace.castPath }
                        }
                    }
                }
            }
            MultiEffect {
                anchors.fill: parent
                visible: fsSpace.live
                source: fsCast
                autoPaddingEnabled: false
                blurEnabled: true
                blur: 1.0
                blurMax: fsSpace.thick
                brightness: -1.0
                maskEnabled: true
                maskInverted: true
                maskSource: fsMask
                maskThresholdMin: 0.5
                opacity: globalState.shellShadowIntensity / 100
            }
        }
    }
      }
    }
}
