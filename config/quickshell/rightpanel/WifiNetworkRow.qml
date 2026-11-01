import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Network row of the Wi-Fi page
Rectangle {
    id: wifiNetworkRow
    required property string ssid
    required property int    strength
    required property bool   secured
    required property bool   inUse
    required property bool   saved
    Layout.fillWidth: true
    implicitHeight: 56
    radius: 14
    clip: true
    color: globalState.glassMode ? ga(wifiNetworkRepeater._cardBg, 0.6) : wifiNetworkRepeater._cardBg

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        Rectangle {
            width: 36; height: 36; radius: 18
            color: inUse ? wifiNetworkRepeater._primary : wifiNetworkRepeater._surfaceDeep
            Behavior on color { M3ColorAnim {} }
            FadeIcon {
                anchors.centerIn: parent
                text: strength >= 60 ? "\ue1d8" : (strength >= 30 ? "\ue1d9" : "\ue1da")
                font.family: "Material Symbols Rounded"; font.pixelSize: 17
                color: inUse ? wifiNetworkRepeater._colorOnPrimary : wifiNetworkRepeater._muted
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            RowLayout {
                Layout.fillWidth: true
                spacing: 4
                Text {
                    text: ssid
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(13 * globalState.fontScale); font.weight: Font.Medium
                    color: wifiNetworkRepeater._colorOnSurface
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    visible: secured
                    text: "\ue897"
                    font.family: "Material Symbols Rounded"; font.pixelSize: 13
                    color: wifiNetworkRepeater._muted
                }
            }
            Text {
                text: inUse ? tr("bt_connected") : (strength + "%")
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale)
                color: wifiNetworkRepeater._muted
            }
        }

        PressIconButton {
            id: wifiForgetBtn
            visible: saved
            property bool isBusy: globalState.wifiConnectingSsid === ssid
            width: 28
            height: 28
            opacity: isBusy ? 0.5 : 1.0
            Behavior on opacity { M3NumberAnim {} }
            cornerRadius: 9
            icon: "\ue872"
            iconSize: 15
            iconColor: hovered ? wifiNetworkRepeater._colorOnPrimary : wifiNetworkRepeater._muted
            hoverColor: wifiNetworkRepeater._errorDark
            idleColor: wifiNetworkRepeater._surfaceDeep
            clickEnabled: !wifiForgetBtn.isBusy
            onClicked: globalState.wifiForgetNetwork(ssid)
        }

        Rectangle {
            id: wifiActionBtn
            property bool isBusy: globalState.wifiConnectingSsid === ssid
            width: 84; height: 30; radius: 10
            color: inUse ? wifiNetworkRepeater._errorDark : wifiNetworkRepeater._primary
            opacity: isBusy ? 0.6 : 1.0
            Behavior on opacity { M3NumberAnim {} }
            Text {
                anchors.centerIn: parent
                text: inUse ? tr("bt_disconnect") : (wifiActionBtn.isBusy ? "…" : tr("bt_connect"))
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale); font.weight: Font.Medium
                color: wifiNetworkRepeater._colorOnPrimary
            }
            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                enabled: !wifiActionBtn.isBusy
                onClicked: {
                    if (inUse) {
                        globalState.wifiDisconnect(ssid);
                    } else if (secured && !saved) {
                        globalState.wifiRequestPassword(ssid);
                    } else {
                        globalState.wifiConnect(ssid, "");
                    }
                }
            }
        }
    }
}
