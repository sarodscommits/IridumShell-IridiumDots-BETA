import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Network status card with the Wi-Fi switch
Rectangle {
    id: connectionsNetStatusCard
Layout.fillWidth: true
implicitHeight: connNetStatusRow.implicitHeight + 40
radius: 32
color: globalState.glassMode ? ga(pal.surfacePop, 0.78) : pal.surfacePop

RowLayout {
    id: connNetStatusRow
    anchors.fill: parent
    anchors.margins: 20
    spacing: 16

    Rectangle {
        Layout.preferredWidth: 48; Layout.preferredHeight: 48
        radius: 24
        color: (globalState.netEthCount > 0 || globalState.netWifi !== "") ? pal.primary : pal.secondaryCont
    FadeIcon {
        anchors.centerIn: parent
        text: {
            var eth  = globalState.netEthCount > 0;
            var wifi = globalState.netWifi !== "";
            return eth ? "\ue1b1" : (wifi ? "\ue1d8" : "\ue1da");
        }
        font.family: "Material Symbols Rounded"; font.pixelSize: 22
        color: (globalState.netEthCount > 0 || globalState.netWifi !== "") ? pal.colorOnPrimary : pal.colorOnSurfVar
    }
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
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(16 * globalState.fontScale); font.weight: Font.DemiBold
            color: pal.colorOnSurface
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
        Text {
            visible: globalState.netWifi !== ""
            text: globalState.netWifi
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale)
            color: pal.colorOnSurfVar
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }

    ESwitch {
        id: connWifiEnableSwitch
        opacity: globalState.wifiRadioBusy ? 0.5 : 1.0
        checked: globalState.netWifiEnabled
        enabled: !globalState.wifiRadioBusy
        onToggled: globalState.wifiSetEnabled(!globalState.netWifiEnabled)
    }
}
            }
