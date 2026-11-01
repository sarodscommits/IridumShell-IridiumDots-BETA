import QtQuick
import "../ui"

// Fullscreen region picker for screen recording
WindowLoader {
    id: recRegionLoader
    active: globalState.recRegionPicking
    source: Qt.resolvedUrl("RecRegionPickerWindow.qml")
}
