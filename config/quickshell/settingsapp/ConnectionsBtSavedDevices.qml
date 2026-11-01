import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."

// Saved Bluetooth devices list
ColumnLayout {
    id: connectionsBtSavedDevices
    Layout.fillWidth: true
    spacing: 6

    Text {
        visible: btPairedModel.count > 0
        text: tr("bt_saved_devices")
        font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium
        color: pal.muted
        Layout.topMargin: 2
    }
    Repeater {
        id: connBtPairedRepeater
        model: btPairedModel
        delegate: connBtDeviceDelegateComponent
    }

    Text {
        visible: btAvailableModel.count > 0
        text: tr("bt_available_devices")
        font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium
        color: pal.muted
        Layout.topMargin: btPairedModel.count > 0 ? 10 : 2
    }
    Repeater {
        id: connBtAvailableRepeater
        model: btAvailableModel
        delegate: connBtDeviceDelegateComponent
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
