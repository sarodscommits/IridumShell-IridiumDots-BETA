import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import ".."
import "../rightpanel"
import "../ui"

// Bluetooth page of the right panel
Item {
    id: btDevicesPage
    anchors.fill: parent
    z: 20
    opacity: globalState.btDevicesViewOpen ? 1 : 0
    visible: globalState.btDevicesViewOpen || opacity > 0
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
            title: tr("bluetooth")
            scanning: globalState.btScanning && globalState.btDevicesViewOpen
            onBack: globalState.closeBtDevicesView()
            onRefresh: {
                btPairedModel.clear();
                btAvailableModel.clear();
                networkBackend.btCtlProcRef.write("devices Paired\n");
                networkBackend.btCtlProcRef.write("devices Connected\n");
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: btStatusRow.implicitHeight + 20
            radius: 14
            color: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont)

            RowLayout {
                id: btStatusRow
                anchors.fill: parent
                anchors.margins: 10
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
                    id: btEnableSwitch
                    opacity: globalState.btRadioBusy ? 0.5 : 1.0
                    checked: globalState.netBluetoothEnabled
                    enabled: !globalState.btRadioBusy
                    onToggled: globalState.btSetEnabled(!globalState.netBluetoothEnabled)
                }
            }
        }

        ScrollView {
            id: btDevicesScrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            QtObject {
                id: btColors
                property color primary:        pal.primary
                property color colorOnPrimary: pal.colorOnPrimary
                property color colorOnSurface: pal.colorOnSurface
                property color muted:          pal.muted
                property color surfaceDeep:    pal.surfaceDeep
                property color errorDark:      Qt.darker(pal.error, 1.6)
                property color cardBg:         containerDark(pal.secondaryCont)
            }

            Component {
                id: btDeviceDelegateComponent
                BtDeviceRow { id: btDeviceRow }
            }

            ColumnLayout {
                width: btDevicesScrollView.availableWidth
                spacing: 6

                Text {
                    visible: btPairedModel.count > 0
                    text: tr("bt_saved_devices")
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium
                    color: pal.muted
                    Layout.topMargin: 2
                }
                Repeater {
                    id: btPairedRepeater
                    model: btPairedModel
                    delegate: btDeviceDelegateComponent
                }

                Text {
                    visible: btAvailableModel.count > 0
                    text: tr("bt_available_devices")
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium
                    color: pal.muted
                    Layout.topMargin: btPairedModel.count > 0 ? 10 : 2
                }
                Repeater {
                    id: btAvailableRepeater
                    model: btAvailableModel
                    delegate: btDeviceDelegateComponent
                }

                Text {
                    visible: btPairedModel.count === 0 && btAvailableModel.count === 0
                    Layout.fillWidth: true
                    Layout.topMargin: 20
                    horizontalAlignment: Text.AlignHCenter
                    text: tr("bt_scanning")
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale)
                    color: pal.muted
                }
            }
        }

        BtPairPromptCard { id: btPairPromptCard }
    }
}
