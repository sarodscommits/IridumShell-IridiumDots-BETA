import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../panels"

// Floating Control Center / Overview window
PanelWindow {
    id: ccFloatWindow
    property alias ccFloatPanel: ccFloatPanel
    property alias notchControlLoader: notchControlLoader
    WlrLayershell.namespace: "quickshell"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    exclusionMode: ExclusionMode.Normal
    color: "transparent"

    readonly property bool shown: globalState.ccFloat && globalState.notchControlOpen && !globalState.lockScreenActive
    property bool armed: false
    readonly property bool contentReady: notchControlLoader.status === Loader.Ready || notchControlLoader.status === Loader.Error
    readonly property bool ccOpen: shown && armed && contentReady
    onShownChanged: {
        if (shown) ccArmTimer.restart();
        else { ccArmTimer.stop(); armed = false; }
    }
    Timer { id: ccArmTimer; interval: 34; repeat: false; onTriggered: ccFloatWindow.armed = true }
    Spring { id: ccProgSpring; target: ccFloatWindow.ccOpen ? 1 : 0; token: ccFloatWindow.ccOpen ? "spatialDefault" : "effectsDefault"; eps: 0.002 }
    readonly property real prog: ccProgSpring.value
    readonly property bool animating: ccProgSpring.moving
    visible: globalState.ccFloat && (shown || prog > 0.005)

    readonly property real margin: 12
    readonly property real panelW: Math.min(unifiedFrame.notchVContentW + 32, width - margin * 2)

    mask: Region { item: ccFloatWindow.shown ? ccFloatCatcher : null }

    MouseArea {
        id: ccFloatCatcher
        anchors.fill: parent
        enabled: ccFloatWindow.shown
        acceptedButtons: Qt.AllButtons
        onClicked: { if (!globalState.ncEditMode) globalState.notchControlOpen = false; }
    }

    Item {
        id: ccFloatKeys
        focus: true
        Keys.onEscapePressed: (event) => {
            event.accepted = true;
            if (globalState.ncEditMode) { globalState.ncEditMode = false; globalState.ncCcSelected = ""; }
            else globalState.notchControlOpen = false;
        }
        Connections {
            target: ccFloatWindow
            function onShownChanged() { if (ccFloatWindow.shown) ccFloatKeys.forceActiveFocus(); }
        }
    }

    Rectangle {
        id: ccFloatPanel
        width: ccFloatWindow.panelW
        height: parent.height - ccFloatWindow.margin * 2
        y: ccFloatWindow.margin
        x: parent.width - ccFloatWindow.margin - width + (1 - ccFloatWindow.prog) * (width + ccFloatWindow.margin + 24)
        opacity: Math.min(1, ccFloatWindow.prog * 1.6)
        radius: 32
        color: globalState.glassMode ? ga(pal.surface, currentFrameOpacity()) : pal.surface
        clip: true

        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onWheel: (w) => { w.accepted = false; } }

        Item {
            anchors.fill: parent
            anchors.margins: 4
            Loader {
                id: notchControlLoader
                anchors.fill: parent
                asynchronous: true
                property bool keep: false
                active: globalState.notchControlOpen || keep
                source: Qt.resolvedUrl("ControlCenterContent.qml")
            }
        }
    }
}
