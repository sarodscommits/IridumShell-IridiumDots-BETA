import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Device row of the Bluetooth page
Rectangle {
    id: btDeviceRow
    required property string mac
    required property string name
    required property bool   paired
    required property bool   connected
    Layout.fillWidth: true
    implicitHeight: 56
    radius: 14
    color: globalState.glassMode ? ga(btColors.cardBg, 0.6) : btColors.cardBg

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        Rectangle {
            width: 36; height: 36; radius: 18
            color: connected ? btColors.primary : btColors.surfaceDeep
            Behavior on color { M3ColorAnim {} }
            Text {
                anchors.centerIn: parent
                text: "\ue1a7"
                font.family: "Material Symbols Rounded"; font.pixelSize: 17
                color: connected ? btColors.colorOnPrimary : btColors.muted
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Text {
                text: name
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(13 * globalState.fontScale); font.weight: Font.Medium
                color: btColors.colorOnSurface
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Text {
                text: connected ? tr("bt_connected") : (paired ? tr("bt_paired") : mac)
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale)
                color: btColors.muted
            }
        }

        Rectangle {
            id: btActionBtn
            property bool isBusy: globalState.btPendingMac === mac
            width: 78; height: 30; radius: 10
            color: connected ? btColors.errorDark : btColors.primary
            opacity: isBusy ? 0.6 : 1.0
            Behavior on opacity { M3NumberAnim {} }
            Text {
                anchors.centerIn: parent
                text: connected ? tr("bt_disconnect") : (btActionBtn.isBusy ? "…" : tr("bt_connect"))
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale); font.weight: Font.Medium
                color: btColors.colorOnPrimary
            }
            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                enabled: !btActionBtn.isBusy
                onClicked: globalState.btConnectOrDisconnect(mac, paired, connected)
            }
        }
    }
}
