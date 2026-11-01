import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../ui"

// Settings > System: primary grid card; its secondary cards stack vertically
Rectangle {
    id: pc
    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property color accent: pal.primary
    default property alias content: pcBody.data
    property alias headerExtra: pcExtra.data

    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.preferredWidth: 100      // equal columns, independent of the content's implicit width
    Layout.alignment: Qt.AlignTop
    implicitHeight: pcCol.implicitHeight + 36
    radius: 28
    color: globalState.glassMode ? ga(pal.surfaceElevated, 0.7) : pal.surfaceElevated
    Behavior on color { M3ColorAnim {} }

    ColumnLayout {
        id: pcCol
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        anchors.margins: 18
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Rectangle {
                width: 40; height: 40; radius: 14
                color: ga(pc.accent, 0.18)
                Text {
                    anchors.centerIn: parent
                    text: pc.icon
                    font.family: "Material Symbols Rounded"; font.pixelSize: 21
                    color: pc.accent
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text {
                    Layout.fillWidth: true
                    text: pc.title
                    elide: Text.ElideRight
                    font.family: globalState.fontPrimary; font.pixelSize: Math.round(16 * globalState.fontScale); font.weight: Font.DemiBold
                    color: pal.colorOnSurface
                }
                Text {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: pc.subtitle
                    elide: Text.ElideRight
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale)
                    color: pal.muted
                }
            }
            Row { id: pcExtra; spacing: 6 }
        }

        ColumnLayout {
            id: pcBody
            Layout.fillWidth: true
            spacing: 8
        }
    }
}
