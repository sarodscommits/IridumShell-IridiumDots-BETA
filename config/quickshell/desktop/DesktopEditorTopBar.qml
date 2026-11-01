import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."

// Top bar of the desktop editor
Rectangle {
    id: desktopEditorTopBar
    transform: Translate { y: desktopWidgetLayer.editMenuOffset }
    opacity: desktopWidgetLayer.editEnterOpacity
    anchors.bottom: previewBox.top
    anchors.bottomMargin: 10
    anchors.horizontalCenter: previewBox.horizontalCenter
    width: previewBox.width
    height: 40
    radius: 14
    color: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.8) : containerDark(pal.secondaryCont)
    MouseArea { anchors.fill: parent }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 12

        Rectangle {
            visible: profileStore.editing !== ""
            Layout.preferredHeight: 26
            Layout.preferredWidth: Math.min(360, edProfileRow.implicitWidth + 20)
            radius: 13
            color: ga(pal.primary, 0.18)
            Row {
                id: edProfileRow
                anchors.centerIn: parent
                spacing: 6
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\ue40a"
                    font.family: "Material Symbols Rounded"; font.pixelSize: 15
                    color: pal.primary
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, 300)
                    elide: Text.ElideMiddle
                    text: tr("profile_editing") + ": " + profileName(profileStore.editing)
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                    color: pal.colorOnSurface
                }
            }
        }

        Item { Layout.fillWidth: true }
        Text {
            visible: profileStore.editing !== ""
            text: tr("profile_discard")
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(13 * globalState.fontScale); font.weight: Font.Medium
            color: pal.error
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: { profileStore.discardOnExit = true; globalState.toggleDesktopEditMode(); }
            }
        }
        Text {
            text: profileStore.editing !== "" ? tr("profile_save") : tr("desktop_editor_exit")
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(13 * globalState.fontScale); font.weight: Font.Medium
            color: profileStore.editing !== "" ? pal.primary : pal.colorOnSurfVar
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: globalState.toggleDesktopEditMode()
            }
        }
    }
}
