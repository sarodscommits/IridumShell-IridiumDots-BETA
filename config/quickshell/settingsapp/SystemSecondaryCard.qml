import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../ui"

// Settings > System: secondary card stacked in a primary card; a fetch module
// (icon, label, value, optional usage bar) with extra controls as default content
Rectangle {
    id: sc
    property string icon: ""
    property string title: ""
    property string value: ""
    property string sub: ""
    property color accent: pal.primary
    property real fraction: -1          // 0..1 shows a usage bar
    default property alias content: scBody.data
    property alias headerExtra: scExtra.data

    Layout.fillWidth: true
    Layout.preferredWidth: 1
    implicitHeight: scCol.implicitHeight + 24
    radius: 20
    color: globalState.glassMode ? ga(pal.surfaceHigh, 0.82) : pal.surfaceHigh
    Behavior on color { M3ColorAnim {} }

    ColumnLayout {
        id: scCol
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        anchors.margins: 12
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Rectangle {
                width: 34; height: 34; radius: 17
                color: ga(sc.accent, 0.16)
                Text {
                    anchors.centerIn: parent
                    text: sc.icon
                    font.family: "Material Symbols Rounded"; font.pixelSize: 17
                    color: sc.accent
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text {
                    Layout.fillWidth: true
                    text: sc.title
                    elide: Text.ElideRight
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(10.5 * globalState.fontScale); font.weight: Font.Medium
                    color: pal.colorOnSurfVar
                }
                Text {
                    Layout.fillWidth: true
                    visible: sc.value !== "" || sc.sub === ""
                    text: sc.value !== "" ? sc.value : "—"
                    elide: Text.ElideRight
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(13 * globalState.fontScale); font.weight: Font.DemiBold
                    color: sc.value !== "" ? pal.colorOnSurface : pal.muted
                }
                Text {
                    Layout.fillWidth: true
                    visible: sc.sub !== ""
                    text: sc.sub
                    elide: Text.ElideRight
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale)
                    color: pal.muted
                }
            }
            Row { id: scExtra; spacing: 6 }
        }

        Rectangle {
            Layout.fillWidth: true
            visible: sc.fraction >= 0
            height: 6; radius: 3
            color: ga(sc.accent, 0.18)
            Rectangle {
                height: parent.height; radius: 3
                width: parent.width * Math.max(0, Math.min(1, sc.fraction))
                color: sc.accent
                Behavior on width { M3NumberAnim {} }
            }
        }

        ColumnLayout {
            id: scBody
            Layout.fillWidth: true
            visible: children.length > 0
            spacing: 12
        }
    }
}
