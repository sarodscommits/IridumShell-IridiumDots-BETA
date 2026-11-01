import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Available Wi-Fi networks list
ColumnLayout {
    id: connWifiListColumn
    Layout.fillWidth: true
    spacing: 4

    Repeater {
        id: connWifiNetworkRepeater
        model: wifiNetworksModel
        property color _primary:         pal.primary
        property color _colorOnPrimary:  pal.colorOnPrimary
        property color _colorOnSurface:  pal.colorOnSurface
        property color _muted:           pal.muted
        property color _surfaceDeep:     pal.surfaceDeep
        property color _errorDark:       Qt.darker(pal.error, 1.6)
        property color _cardBg:          pal.surfaceHigh
        delegate: Rectangle {
            required property string ssid
            required property int    strength
            required property bool   secured
            required property bool   inUse
            required property bool   saved
            Layout.fillWidth: true
            implicitHeight: 56
            radius: 16
            clip: true
            color: globalState.glassMode ? ga(connWifiNetworkRepeater._cardBg, 0.6) : connWifiNetworkRepeater._cardBg

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Rectangle {
                    width: 36; height: 36; radius: 18
                    color: inUse ? connWifiNetworkRepeater._primary : connWifiNetworkRepeater._surfaceDeep
                    Behavior on color { M3ColorAnim {} }
                    FadeIcon {
                        anchors.centerIn: parent
                        text: strength >= 60 ? "\ue1d8" : (strength >= 30 ? "\ue1d9" : "\ue1da")
                        font.family: "Material Symbols Rounded"; font.pixelSize: 17
                        color: inUse ? connWifiNetworkRepeater._colorOnPrimary : connWifiNetworkRepeater._muted
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
                            color: connWifiNetworkRepeater._colorOnSurface
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            visible: secured
                            text: "\ue897"
                            font.family: "Material Symbols Rounded"; font.pixelSize: 13
                            color: connWifiNetworkRepeater._muted
                        }
                    }
                    Text {
                        text: inUse ? tr("bt_connected") : (strength + "%")
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale)
                        color: connWifiNetworkRepeater._muted
                    }
                }

                PressIconButton {
                    id: connWifiForgetBtn
                    visible: saved
                    property bool isBusy: globalState.wifiConnectingSsid === ssid
                    width: 28
                    height: 28
                    opacity: isBusy ? 0.5 : 1.0
                    Behavior on opacity { M3NumberAnim {} }
                    cornerRadius: 9
                    icon: "\ue872"
                    iconSize: 15
                    iconColor: hovered ? connWifiNetworkRepeater._colorOnPrimary : connWifiNetworkRepeater._muted
                    hoverColor: connWifiNetworkRepeater._errorDark
                    idleColor: connWifiNetworkRepeater._surfaceDeep
                    clickEnabled: !connWifiForgetBtn.isBusy
                    onClicked: globalState.wifiForgetNetwork(ssid)
                }

                Rectangle {
                    id: connWifiActionBtn
                    property bool isBusy: globalState.wifiConnectingSsid === ssid
                    width: 84; height: 30; radius: 10
                    color: inUse ? connWifiNetworkRepeater._errorDark : connWifiNetworkRepeater._primary
                    opacity: isBusy ? 0.6 : 1.0
                    Behavior on opacity { M3NumberAnim {} }
                    Text {
                        anchors.centerIn: parent
                        text: inUse ? tr("bt_disconnect") : (connWifiActionBtn.isBusy ? "…" : tr("bt_connect"))
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale); font.weight: Font.Medium
                        color: connWifiNetworkRepeater._colorOnPrimary
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        enabled: !connWifiActionBtn.isBusy
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
    }

    Text {
        visible: wifiNetworksModel.count === 0
        Layout.fillWidth: true
        Layout.topMargin: 20
        horizontalAlignment: Text.AlignHCenter
        text: tr("wifi_scanning")
        font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale)
        color: pal.muted
    }
}
