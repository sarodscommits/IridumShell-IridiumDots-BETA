import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../ui"

// One fetch module card (caption + rows) inside the overview's system card
Rectangle {
    id: ofg
    property string icon: ""
    property string title: ""
    property color accent: pal.primary
    property var rows: []
    property bool showTitle: true

    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.preferredWidth: 1      // equal widths/heights regardless of content
    Layout.preferredHeight: 1
    radius: 18
    clip: true
    color: ga(pal.colorOnSurface, globalState.glassMode ? 0.05 : 0.06)

    ColumnLayout {
        anchors.left: parent.left; anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 12; anchors.rightMargin: 10
        spacing: 3

        RowLayout {
            visible: ofg.showTitle
            Layout.fillWidth: true
            Layout.bottomMargin: 3
            spacing: 6
            Text { text: ofg.icon; font.family: "Material Symbols Rounded"; font.pixelSize: 14; color: ofg.accent }
            Text {
                Layout.fillWidth: true
                text: ofg.title
                elide: Text.ElideRight
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.DemiBold
                color: pal.colorOnSurface
            }
        }

        Repeater {
            model: ofg.rows
            RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 6
                Text {
                    text: modelData.icon
                    font.family: "Material Symbols Rounded"; font.pixelSize: 13
                    color: modelData.color; opacity: 0.85
                    Layout.preferredWidth: 15
                }
                Text {
                    text: modelData.label
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(10.5 * globalState.fontScale); font.weight: Font.Medium
                    color: pal.textSecondary
                    Layout.preferredWidth: 54
                }
                Text {
                    Layout.fillWidth: true
                    text: modelData.value !== "" ? modelData.value : "—"
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(10.5 * globalState.fontScale)
                    color: modelData.value !== "" ? pal.textPrimary : pal.textMuted
                    elide: Text.ElideRight
                }
            }
        }
    }
}
