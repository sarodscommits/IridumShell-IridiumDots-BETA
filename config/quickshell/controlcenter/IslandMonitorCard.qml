import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../controlcenter"

// System monitor card shown in the island
Rectangle {
    id: imMonCard
    readonly property bool live: parent ? !!parent.live : false
    radius: 28
    color: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont)
    RowLayout {
        anchors.left: parent.left; anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14
        spacing: 10
        Rectangle {
            width: 30; height: 30; radius: 15
            color: ga(pal.primary, 0.18)
            Text { anchors.centerIn: parent; text: "\ue322"; font.family: "Material Symbols Rounded"; font.pixelSize: 17; color: pal.primary }
        }
        Text { Layout.fillWidth: true; text: tr("ic_page_monitor"); font.family: globalState.fontPrimary; font.pixelSize: Math.round(15 * globalState.fontScale); font.weight: Font.Bold; color: pal.colorOnSurface; elide: Text.ElideRight }
        Text {
            Layout.maximumWidth: parent.width * 0.5
            text: globalState.fetchUptime !== "" ? "\ue425 " + globalState.fetchUptime : ""
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); color: pal.colorOnSurfVar
            elide: Text.ElideRight
        }
    }
    MonitorPage {
        id: imPage3
        anchors.fill: parent
        live: imMonCard.live
    }
}
