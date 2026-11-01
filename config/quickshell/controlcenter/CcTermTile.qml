import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Terminal tile of the Control Center grid
Rectangle {
    id: ccTermTile
    radius: m3Tile3Ma.pressed ? 12 : height / 2
    color: { var c = containerDark(pal.secondaryCont); return (globalState.glassMode && true) ? ga(c, 0.78) : c; }
    Behavior on color { M3ColorAnim {} }
    Rectangle { anchors.fill: parent; radius: parent.radius; color: pal.colorOnSurface; opacity: m3Tile3Ma.pressed ? 0.12 : (ncTermHov.hovered ? 0.08 : 0); Behavior on opacity { NumberAnimation { duration: m3.durFast } } }
    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width - 6
        spacing: 2
        opacity: globalState.glassMode ? 0.88 : 1.0
        Text { Layout.alignment: Qt.AlignHCenter; text: ""; font.family: "Material Symbols Rounded"; font.pixelSize: 24; color: pal.primary }
        Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: "terminal"; font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium; color: pal.colorOnSurface }
    }
    HoverHandler { id: ncTermHov }
    MouseArea { id: m3Tile3Ma; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { globalState.playUiClick(); globalState.closeControlPanels(); globalState.openTerminal(); } }
}
