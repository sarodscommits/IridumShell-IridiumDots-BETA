import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."

// Pairing prompt of the Bluetooth page
Rectangle {
    id: btPairPromptCard
    visible: globalState.btPromptType !== ""
    Layout.fillWidth: true
    radius: 16
    implicitHeight: btPromptCol.implicitHeight + 20
    color: globalState.glassMode ? ga(containerDark(pal.primaryCont), 0.6) : containerDark(pal.primaryCont)

    ColumnLayout {
        id: btPromptCol
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        Text {
            text: globalState.btPromptType === "confirm"
            ? (tr("bt_confirm_code") + ": " + globalState.btPromptText)
            : tr("bt_enter_code")
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
            color: pal.colorOnSurface
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        Rectangle {
            visible: globalState.btPromptType !== "confirm"
            Layout.fillWidth: true
            height: 34; radius: 10
            color: pal.surfaceDeep
            border.width: 1
            border.color: btPromptField.activeFocus ? pal.primary : "transparent"

            TextInput {
                id: btPromptField
                Component.onCompleted: unifiedFrame.btPromptFieldRef = btPromptField
                Component.onDestruction: if (unifiedFrame.btPromptFieldRef === btPromptField) unifiedFrame.btPromptFieldRef = null
                anchors.fill: parent
                anchors.leftMargin: 10; anchors.rightMargin: 10
                verticalAlignment: TextInput.AlignVCenter
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(13 * globalState.fontScale)
                color: pal.colorOnSurface
                echoMode: globalState.btPromptType === "pin" ? TextInput.Password : TextInput.Normal
                text: globalState.btPasswordDraft
                onTextChanged: globalState.btPasswordDraft = text
                Keys.onReturnPressed: btPromptConfirmBtn.doConfirm()
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
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: globalState.btCancelPrompt() }
            }
            Rectangle {
                id: btPromptConfirmBtn
                function doConfirm() {
                    globalState.btSubmitPrompt(globalState.btPromptType === "confirm" ? "yes" : globalState.btPasswordDraft);
                }
                Layout.fillWidth: true
                height: 32; radius: 10
                color: pal.primary
                Text {
                    anchors.centerIn: parent
                    text: globalState.btPromptType === "confirm" ? tr("bt_yes") : tr("bt_send")
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium
                    color: pal.colorOnPrimary
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: btPromptConfirmBtn.doConfirm() }
            }
        }
    }
}
