import QtQuick
import "../ui"

// Shutdown / restart confirmation dialog with countdown
WindowLoader {
    id: powerConfirmLoader
    active: globalState.powerConfirmAction !== "" || powerConfirmHold.running
    source: Qt.resolvedUrl("PowerConfirmWindow.qml")
}
