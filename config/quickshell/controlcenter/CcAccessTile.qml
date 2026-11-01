import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Accessibility tile of the Control Center grid
Rectangle {
    id: ncAccessTile
    readonly property string k: parent && parent.ctlKey ? parent.ctlKey : "dark"
    readonly property bool isDark: k === "dark"
    property bool on: isDark ? globalState.colorMode === "dark" : globalState.dndEnabled
    readonly property string label: isDark ? (globalState.colorMode === "light" ? tr("light") : tr("dark"))
    : (globalState.dndEnabled ? tr("dnd") : tr("dnd_off"))
    readonly property bool _darken: on
    onOnChanged: if (!isDark && !on) ncBellShake.restart()
    radius: ncAccessTileMa.pressed ? 12 : ((on) ? 16 : height / 2)
    Behavior on radius { M3SpringAnim { token: "spatialDefault" } }
    color: {
        var c = _darken ? pal.primary : containerDark(pal.secondaryCont);
        return (globalState.glassMode && !_darken) ? ga(c, 0.78) : c;
    }
    Behavior on color { M3ColorAnim {} }
    Rectangle { anchors.fill: parent; radius: parent.radius; color: ((on) ? pal.colorOnPrimary : pal.colorOnSurface); opacity: ncAccessTileMa.pressed ? 0.12 : (ncAccessHov.hovered ? 0.08 : 0); Behavior on opacity { NumberAnimation { duration: m3.durFast } } }
    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width - 6
        spacing: 2
        opacity: globalState.glassMode ? 0.88 : 1.0
        FadeIcon {
            id: ncAccessIcon
            transform: Rotation {
                id: ncBellRot
                origin.x: ncAccessIcon.width / 2
                origin.y: ncAccessIcon.height * 0.12
            }
            SequentialAnimation {
                id: ncBellShake
                ScriptAction { script: ncBellRot.angle = 0 }
                NumberAnimation { target: ncBellRot; property: "angle"; to:  18; duration: 70;  easing.type: Easing.BezierSpline; easing.bezierCurve: m3.standardDecelerate }
                NumberAnimation { target: ncBellRot; property: "angle"; to: -16; duration: 110; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.standardCurve }
                NumberAnimation { target: ncBellRot; property: "angle"; to:  12; duration: 100; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.standardCurve }
                NumberAnimation { target: ncBellRot; property: "angle"; to:  -8; duration: 90;  easing.type: Easing.BezierSpline; easing.bezierCurve: m3.standardCurve }
                NumberAnimation { target: ncBellRot; property: "angle"; to:   4; duration: 80;  easing.type: Easing.BezierSpline; easing.bezierCurve: m3.standardCurve }
                NumberAnimation { target: ncBellRot; property: "angle"; to:   0; duration: 90;  easing.type: Easing.BezierSpline; easing.bezierCurve: m3.standardDecelerate }
            }
            Layout.alignment: Qt.AlignHCenter; text: ncAccessTile.isDark ? (ncAccessTile.on ? "" : "") : (ncAccessTile.on ? "" : ""); font.family: "Material Symbols Rounded"; font.pixelSize: 24; color: ncAccessTile._darken ? pal.colorOnPrimary : pal.primary }
        Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: ncAccessTile.label; font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium; color: ncAccessTile._darken ? pal.colorOnPrimary : pal.colorOnSurface }
    }
    HoverHandler { id: ncAccessHov }
    MouseArea { id: ncAccessTileMa;
        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
        onClicked: { globalState.playUiClick();
            if (ncAccessTile.isDark) setColorMode(globalState.colorMode === "light" ? "dark" : "light");
            else globalState.toggleDnd();
        }
    }
}
