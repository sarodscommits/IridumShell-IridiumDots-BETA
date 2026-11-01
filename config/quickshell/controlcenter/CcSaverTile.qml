import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Battery saver tile of the Control Center grid
Rectangle {
    id: ncSaverTile
    readonly property bool on: globalState.batterySaver
    readonly property bool _hl: on
    radius: ncSaverTileMa.pressed ? 12 : ((on) ? 16 : height / 2)
    Behavior on radius { M3SpringAnim { token: "spatialDefault" } }
    color: { var c = _hl ? pal.primary : containerDark(pal.secondaryCont); return (globalState.glassMode && !_hl) ? ga(c, 0.78) : c; }
    Behavior on color { M3ColorAnim {} }
    Rectangle { anchors.fill: parent; radius: parent.radius; color: ((on) ? pal.colorOnPrimary : pal.colorOnSurface); opacity: ncSaverTileMa.pressed ? 0.12 : (ncSaverHov.hovered ? 0.08 : 0); Behavior on opacity { NumberAnimation { duration: m3.durFast } } }
    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width - 6
        spacing: 2
        opacity: globalState.glassMode ? 0.88 : 1.0
        Text { Layout.alignment: Qt.AlignHCenter; text: ""; font.family: "Material Symbols Rounded"; font.pixelSize: 24; color: ncSaverTile._hl ? pal.colorOnPrimary : pal.primary }
        Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: tr("nce_saver"); font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium; color: ncSaverTile._hl ? pal.colorOnPrimary : pal.colorOnSurface }
    }
    HoverHandler { id: ncSaverHov }
    MouseArea { id: ncSaverTileMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { globalState.playUiClick(); globalState.setBatterySaver(!globalState.batterySaver); } }
}
