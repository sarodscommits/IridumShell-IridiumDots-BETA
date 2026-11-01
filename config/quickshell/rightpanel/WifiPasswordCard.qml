import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Password prompt of the Wi-Fi page
Rectangle {
    id: wifiPasswordCard
    visible: globalState.wifiPasswordSsid !== ""
    Layout.fillWidth: true
    radius: 16
    implicitHeight: wifiPromptCol.implicitHeight + 20
    color: globalState.glassMode ? ga(containerDark(pal.primaryCont), 0.6) : containerDark(pal.primaryCont)

    ColumnLayout {
        id: wifiPromptCol
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        Text {
            text: tr("wifi_enter_password") + " \"" + globalState.wifiPasswordSsid + "\""
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
            color: pal.colorOnSurface
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        Text {
            visible: globalState.wifiConnectError !== ""
            text: globalState.wifiConnectError
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale)
            color: pal.error
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        Rectangle {
            Layout.fillWidth: true
            height: 34; radius: 10
            color: pal.surfaceDeep
            border.width: 1
            border.color: wifiPromptField.activeFocus ? pal.primary : "transparent"

            TextInput {
                id: wifiPromptField
                Component.onCompleted: unifiedFrame.wifiPromptFieldRef = wifiPromptField
                Component.onDestruction: if (unifiedFrame.wifiPromptFieldRef === wifiPromptField) unifiedFrame.wifiPromptFieldRef = null
                anchors.fill: parent
                anchors.leftMargin: 10; anchors.rightMargin: 36
                verticalAlignment: TextInput.AlignVCenter
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(13 * globalState.fontScale)
                color: pal.colorOnSurface
                echoMode: globalState.wifiPasswordVisible ? TextInput.Normal : TextInput.Password
                text: globalState.wifiPasswordDraft
                onTextChanged: globalState.wifiPasswordDraft = text
                Keys.onReturnPressed: wifiPromptConfirmBtn.doConfirm()
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 4
                width: 26; height: 26; radius: m3Ib21Ma.pressed ? Math.max(4, (8) * 0.5) : (8)
                Behavior on radius { M3SpringAnim { token: "spatialFast" } }
                color: wifiEyeHov.hovered ? pal.primaryCont : "transparent"
                Behavior on color { M3ColorAnim { duration: m3.durFast } }
                FadeIcon {
                    anchors.centerIn: parent
                    text: globalState.wifiPasswordVisible ? "\ue8f4" : "\ue8f5"
                    font.family: "Material Symbols Rounded"; font.pixelSize: 15
                    color: pal.muted
                }
                HoverHandler { id: wifiEyeHov }
                MouseArea { id: m3Ib21Ma;
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: globalState.wifiPasswordVisible = !globalState.wifiPasswordVisible
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                height: 32; radius: 10
                color: pal.surfaceDeep
                Text { anchors.centerIn: parent; text: tr("bt_cancel"); font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); color: pal.colorOnSurface }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: globalState.wifiCancelPassword() }
            }
            Rectangle {
                id: wifiPromptConfirmBtn
                function doConfirm() { globalState.wifiSubmitPassword(); }
                Layout.fillWidth: true
                height: 32; radius: 10
                color: pal.primary
                Text {
                    anchors.centerIn: parent
                    text: tr("bt_send")
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium
                    color: pal.colorOnPrimary
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: wifiPromptConfirmBtn.doConfirm() }
            }
        }
    }
}
