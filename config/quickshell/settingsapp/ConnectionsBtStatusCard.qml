import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Bluetooth status card
Rectangle {
    id: connectionsBtStatusCard
    Layout.fillWidth: true
    implicitHeight: connBtStatusRow.implicitHeight + 32
    radius: 16
    color: globalState.glassMode ? ga(pal.surfaceHigh, 0.6) : pal.surfaceHigh

    RowLayout {
        id: connBtStatusRow
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        Text {
            text: "\ue1a7"
            font.family: "Material Symbols Rounded"; font.pixelSize: 20
            color: globalState.netBluetoothEnabled ? pal.primary : pal.muted
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Text {
                text: tr("bluetooth")
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                color: pal.colorOnSurface
                Layout.fillWidth: true
            }
            Text {
                text: globalState.netBluetoothEnabled ? tr("radio_on") : tr("radio_off")
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale)
                color: pal.muted
            }
        }

        ESwitch {
            id: connBtEnableSwitch
            opacity: globalState.btRadioBusy ? 0.5 : 1.0
            checked: globalState.netBluetoothEnabled
            enabled: !globalState.btRadioBusy
            onToggled: globalState.btSetEnabled(!globalState.netBluetoothEnabled)
        }
    }
}
