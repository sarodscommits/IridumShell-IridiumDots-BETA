import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Eye care tile of the Control Center grid
Rectangle {
    id: ncEyeTile
    readonly property bool on: globalState.eyeCare
    onOnChanged: { ncEyeBlink.yScale = 1; ncEyeBlinkAnim.restart(); }
    readonly property bool _hl: on
    radius: ncEyeTileMa.pressed ? 12 : ((on) ? 16 : height / 2)
    Behavior on radius { M3SpringAnim { token: "spatialDefault" } }
    color: { var c = _hl ? pal.primary : containerDark(pal.secondaryCont); return (globalState.glassMode && !_hl) ? ga(c, 0.78) : c; }
    Behavior on color { M3ColorAnim {} }
    Rectangle { anchors.fill: parent; radius: parent.radius; color: ((on) ? pal.colorOnPrimary : pal.colorOnSurface); opacity: ncEyeTileMa.pressed ? 0.12 : (ncEyeHov.hovered ? 0.08 : 0); Behavior on opacity { NumberAnimation { duration: m3.durFast } } }
    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width - 6
        spacing: 2
        opacity: globalState.glassMode ? 0.88 : 1.0
        Text {
            id: ncEyeIcon
            Layout.alignment: Qt.AlignHCenter
            text: "\ue8f4"; font.family: "Material Symbols Rounded"; font.pixelSize: 24
            color: ncEyeTile._hl ? pal.colorOnPrimary : pal.primary
            Behavior on color { M3ColorAnim {} }
            transform: Scale {
                id: ncEyeBlink
                origin.x: ncEyeIcon.width / 2
                origin.y: ncEyeIcon.height / 2
            }
            SequentialAnimation {
                id: ncEyeBlinkAnim
                NumberAnimation { target: ncEyeBlink; property: "yScale"; to: 0; duration: 90;  easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasizedAccelerate }
                NumberAnimation { target: ncEyeBlink; property: "yScale"; to: 1; duration: 140; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.standardDecelerate }
            }
        }
        Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: tr("nce_eye"); font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium; color: ncEyeTile._hl ? pal.colorOnPrimary : pal.colorOnSurface }
    }
    HoverHandler { id: ncEyeHov }
    MouseArea { id: ncEyeTileMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; enabled: !globalState.ncEditMode; onClicked: { globalState.playUiClick(); globalState.setEyeCare(!globalState.eyeCare); } }
}
