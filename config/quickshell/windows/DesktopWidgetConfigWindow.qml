import QtQuick
import "../ui"

// Per-widget configuration window of the desktop editor
WindowLoader {
    active: globalState.desktopEditMode
    source: Qt.resolvedUrl("DesktopWidgetConfigPanel.qml")
}
