import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import ".."
import "../rightpanel"
import "../ui"

// Wi-Fi page of the right panel
Item {
    id: wifiPage
    anchors.fill: parent
    z: 20
    opacity: globalState.wifiViewOpen ? 1 : 0
    visible: globalState.wifiViewOpen || opacity > 0
    Behavior on opacity { M3NumberAnim {} }

    Rectangle {
        anchors.fill: parent
        color: globalState.glassMode ? ga(pal.surface, globalState.wifiBtGlassAlpha) : pal.surface
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        anchors.topMargin: 24
        spacing: 10

        PanelPageHeader {
            title: tr("wifi")
            scanning: globalState.wifiScanning && globalState.wifiViewOpen
            onBack: globalState.closeWifiView()
            onRefresh: globalState.wifiScanNetworks()
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: netStatusRow.implicitHeight + 20
            radius: 14
            color: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont)

            RowLayout {
                id: netStatusRow
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                FadeIcon {
                    text: {
                        var eth  = globalState.netEthCount > 0;
                        var wifi = globalState.netWifi !== "";
                        return eth ? "\ue1b1" : (wifi ? "\ue1d8" : "\ue1da");
                    }
                    font.family: "Material Symbols Rounded"; font.pixelSize: 20
                    color: (globalState.netEthCount > 0 || globalState.netWifi !== "") ? pal.primary : pal.muted
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Text {
                        text: {
                            var eth  = globalState.netEthCount > 0;
                            var wifi = globalState.netWifi !== "";
                            if (eth && wifi)  return tr("net_status_both");
                            if (eth)          return tr("net_status_eth");
                            if (wifi)         return tr("net_status_wifi");
                            return tr("net_status_none");
                        }
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                        color: pal.colorOnSurface
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        visible: globalState.netWifi !== ""
                        text: globalState.netWifi
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale)
                        color: pal.muted
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                ESwitch {
                    id: wifiEnableSwitch
                    opacity: globalState.wifiRadioBusy ? 0.5 : 1.0
                    checked: globalState.netWifiEnabled
                    enabled: !globalState.wifiRadioBusy
                    onToggled: globalState.wifiSetEnabled(!globalState.netWifiEnabled)
                }
            }
        }

        ScrollView {
            id: wifiScrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ColumnLayout {
                id: wifiListColumn
                width: wifiScrollView.availableWidth
                spacing: 6

                Repeater {
                    id: wifiNetworkRepeater
                    model: wifiNetworksModel
                    property color _primary:         pal.primary
                    property color _colorOnPrimary:  pal.colorOnPrimary
                    property color _colorOnSurface:  pal.colorOnSurface
                    property color _muted:           pal.muted
                    property color _surfaceDeep:     pal.surfaceDeep
                    property color _errorDark:       Qt.darker(pal.error, 1.6)
                    property color _cardBg:          containerDark(pal.secondaryCont)
                    delegate: WifiNetworkRow { id: wifiNetworkRow }
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
        }

        WifiPasswordCard { id: wifiPasswordCard }
    }
}
