import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../ui"

// Settings > System: Iridium Shell identity card (full width, above the grid)
Rectangle {
    id: systemHeroCard
    Layout.fillWidth: true
    implicitHeight: systemHeroRow.implicitHeight + 48
    radius: 32
    color: globalState.glassMode ? ga(pal.surfacePop, 0.78) : pal.surfacePop

    RowLayout {
        id: systemHeroRow
        anchors.left: parent.left; anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: 24
        spacing: 32

        Rectangle {
            id: iridumLogoSquare
            width: 160; height: 160; radius: 25
            color: globalState.glassMode ? ga(pal.surfaceHigh, 0.6) : pal.surfaceHigh
            border.width: 3.75
            border.color: pal.primary

            Text {
                anchors.top:  parent.top
                anchors.left: parent.left
                anchors.margins: 13
                text: "77"
                font.family: globalState.fontPrimary; font.pixelSize: Math.round(23 * globalState.fontScale); font.weight: Font.Medium
                color: pal.colorOnSurfVar
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 0

                Text {
                    text: "Ir"
                    font.family: globalState.fontPrimary; font.pixelSize: Math.round(65 * globalState.fontScale); font.weight: Font.Bold
                    color: pal.primary
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    text: "Iridum"
                    font.family: globalState.fontPrimary; font.pixelSize: Math.round(20 * globalState.fontScale); font.weight: Font.Medium
                    color: pal.colorOnSurface
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    text: "192.22"
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(15 * globalState.fontScale)
                    color: pal.muted
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 0
            Row {
                spacing: 12
                Text {
                    text: "Iridium"
                    font.family: globalState.fontPrimary; font.pixelSize: Math.round(60 * globalState.fontScale); font.weight: Font.Bold
                    color: pal.primary
                }
                Text {
                    text: "Shell"
                    font.family: globalState.fontPrimary; font.pixelSize: Math.round(60 * globalState.fontScale); font.weight: Font.Bold
                    color: pal.colorOnSurface
                }
            }
            Text {
                text: "1.0"
                font.family: globalState.fontPrimary; font.pixelSize: Math.round(30 * globalState.fontScale); font.weight: Font.Medium
                color: pal.muted
            }
        }

        Item { Layout.fillWidth: true }
    }
}
