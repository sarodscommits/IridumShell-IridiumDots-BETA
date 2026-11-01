import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Privacy indicator button of the bar
Item {
    id: privBtn
    property alias privBtnHover: privBtnHover
    readonly property color green: "#3DDC84"
    readonly property bool expanded: globalState.privActive && (globalState.privRevealed || privBulgePopup.isOpen)
    readonly property int iconCount: (globalState.privCamActive ? 1 : 0) + (globalState.privMicActive ? 1 : 0)
    readonly property real targetW: globalState.privActive ? (expanded ? iconCount * 20 + 14 : 14)
    : (globalState.desktopEditMode ? 28 : 0)
    property real animW: targetW
    Behavior on animW { NumberAnimation { duration: 420; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasizedDecelerate } }
    visible: globalState.barModules.privacy && (globalState.privActive || globalState.desktopEditMode || animW > 0.5)
    readonly property bool vert: unifiedFrame.barVertical
    implicitWidth: vert ? 28 : animW
    implicitHeight: vert ? animW : 28
    Layout.preferredWidth: vert ? 28 : animW
    Layout.minimumWidth: vert ? 28 : animW
    Layout.maximumWidth: vert ? 28 : animW
    Layout.preferredHeight: vert ? animW : 28
    Layout.minimumHeight: vert ? animW : 28
    Layout.maximumHeight: vert ? animW : 28
    Layout.alignment: Qt.AlignCenter

    Text {
        anchors.centerIn: parent
        text: "\ue32a"
        font.family: "Material Symbols Rounded"; font.pixelSize: 15
        color: pal.muted
        opacity: (!globalState.privActive && globalState.desktopEditMode) ? 0.7 : 0
        Behavior on opacity { M3NumberAnim { duration: m3.durFast } }
    }
    Rectangle {
        id: privPill
        anchors.centerIn: parent
        readonly property real longSide: privBtn.expanded ? privBtn.iconCount * 20 + 8 : 8
        readonly property real shortSide: privBtn.expanded ? 22 : 8
        width: privBtn.vert ? shortSide : longSide
        height: privBtn.vert ? longSide : shortSide
        radius: height / 2
        color: privBtn.green
        opacity: globalState.privActive ? 1 : 0
        scale: globalState.privActive ? 1 : 0.4
        Behavior on width   { M3SpringAnim { token: "spatialSlow" } }
        Behavior on height  { M3SpringAnim { token: "spatialSlow" } }
        Behavior on opacity { M3NumberAnim {} }
        Behavior on scale   { M3SpringAnim { token: "spatialFast"; epsilon: 0.002 } }
        Grid {
            anchors.centerIn: parent
            rows:    privBtn.vert ? -1 : 1
            columns: privBtn.vert ? 1 : -1
            opacity: privBtn.expanded ? 1 : 0
            scale: privBtn.expanded ? 1 : 0.5
            Behavior on opacity { M3NumberAnim { duration: privBtn.expanded ? 260 : 140 } }
            Behavior on scale   { M3SpringAnim { token: "spatialDefault"; epsilon: 0.002 } }
            Text {
                visible: globalState.privCamActive
                width: 20; horizontalAlignment: Text.AlignHCenter
                height: privBtn.vert ? 20 : implicitHeight; verticalAlignment: Text.AlignVCenter
                text: "\ue04b"
                font.family: "Material Symbols Rounded"; font.pixelSize: 15
                color: "#06210F"
            }
            Text {
                visible: globalState.privMicActive
                width: 20; horizontalAlignment: Text.AlignHCenter
                height: privBtn.vert ? 20 : implicitHeight; verticalAlignment: Text.AlignVCenter
                text: "\ue029"
                font.family: "Material Symbols Rounded"; font.pixelSize: 15
                color: "#06210F"
            }
        }
    }
    HoverHandler {
        id: privBtnHover
        onHoveredChanged: {
            if (globalState.desktopEditMode) return;
            if (hovered) privBulgePopup.show();
            else privBulgePopup.scheduleClose();
        }
    }
}
