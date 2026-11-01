import QtQuick
import "../ui"

// Frozen-screen screenshot overlay with region selection and annotation
WindowLoader {
    id: shotLoader
    active: globalState.shotPicking
    source: Qt.resolvedUrl("ScreenshotOverlayWindow.qml")
}
