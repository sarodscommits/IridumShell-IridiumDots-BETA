import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Header of the network bulge popup
RowLayout {
    id: netHeader
    x: 14; y: 14
    width: parent.width - 28
    height: 36
    spacing: 10
    Rectangle {
        width: 32; height: 32; radius: 16
        color: netContent.radioOn ? pal.primary : ga(pal.primary, 0.18)
        Behavior on color { M3ColorAnim {} }
        FadeIcon {
            anchors.centerIn: parent
            text: netContent.isWifi ? (globalState.netWifiEnabled ? "\ue1d8" : "\ue1da") : "\ue1a7"
            font.family: "Material Symbols Rounded"; font.pixelSize: 17
            color: netContent.radioOn ? pal.colorOnPrimary : pal.primary
        }
    }
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        Text {
            Layout.fillWidth: true
            text: netContent.isWifi ? tr("wifi") : tr("bluetooth")
            font.family: globalState.fontPrimary; font.pixelSize: Math.round(14 * globalState.fontScale); font.weight: Font.Bold
            color: pal.colorOnSurface
            elide: Text.ElideRight
        }
        Text {
            Layout.fillWidth: true
            text: !netContent.radioOn ? tr("radio_off")
            : (netBulgePopup.connectedList.length > 0
            ? (netContent.isWifi ? netBulgePopup.connectedList[0].ssid : netBulgePopup.connectedList[0].name)
            : tr("radio_on"))
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale)
            color: pal.colorOnSurfVar
            elide: Text.ElideRight
        }
    }
    ESwitch {
        opacity: netContent.radioBusy ? 0.5 : 1.0
        checked: netContent.radioOn
        enabled: !netContent.radioBusy
        onToggled: {
            if (netContent.isWifi) globalState.wifiSetEnabled(!globalState.netWifiEnabled);
            else globalState.btSetEnabled(!globalState.netBluetoothEnabled);
        }
    }
}
