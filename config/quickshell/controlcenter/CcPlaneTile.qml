import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Airplane mode tile of the Control Center grid
Rectangle {
    id: ncPlaneTile
    readonly property bool on: globalState.airplaneMode
    readonly property bool _hl: on
    property bool iconOn: false
    Component.onCompleted: iconOn = on
    onOnChanged: {
        if (on) { ncPlaneFly.restart(); }
        else { ncPlaneFly.stop(); ncPlaneMove.y = 0; iconOn = false; }
    }
    clip: true
    Rectangle { anchors.fill: parent; radius: parent.radius; color: ((on) ? pal.colorOnPrimary : pal.colorOnSurface); opacity: ncPlaneTileMa.pressed ? 0.12 : (ncPlaneHov.hovered ? 0.08 : 0); Behavior on opacity { NumberAnimation { duration: m3.durFast } } }
    SequentialAnimation {
        id: ncPlaneFly
        readonly property real off: ncPlaneTile.height / 2 + 24
        NumberAnimation { target: ncPlaneMove; property: "y"; from: 0; to: -ncPlaneFly.off; duration: 170; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasizedAccelerate }
        ScriptAction { script: { ncPlaneTile.iconOn = true; ncPlaneMove.y = ncPlaneFly.off; } }
        NumberAnimation { target: ncPlaneMove; property: "y"; to: 0; duration: 260; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasizedDecelerate }
    }
    radius: ncPlaneTileMa.pressed ? 12 : ((on) ? 16 : height / 2)
    Behavior on radius { M3SpringAnim { token: "spatialDefault" } }
    color: { var c = _hl ? pal.primary : containerDark(pal.secondaryCont); return (globalState.glassMode && !_hl) ? ga(c, 0.78) : c; }
    Behavior on color { M3ColorAnim {} }
    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width - 6
        spacing: 2
        opacity: globalState.glassMode ? 0.88 : 1.0
        FadeIcon {
            duration: ncPlaneFly.running ? 1 : 220
            transform: Translate { id: ncPlaneMove }
            Layout.alignment: Qt.AlignHCenter; text: ncPlaneTile.iconOn ? "" : ""; font.family: "Material Symbols Rounded"; font.pixelSize: 24; color: ncPlaneTile._hl ? pal.colorOnPrimary : pal.primary }
        Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: tr("nce_plane"); font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium; color: ncPlaneTile._hl ? pal.colorOnPrimary : pal.colorOnSurface }
    }
    HoverHandler { id: ncPlaneHov }
    MouseArea { id: ncPlaneTileMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { globalState.playUiClick(); globalState.setAirplaneMode(!globalState.airplaneMode); } }
}
