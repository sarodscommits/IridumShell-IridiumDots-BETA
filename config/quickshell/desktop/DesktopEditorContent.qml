import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../desktop"

// Desktop editor content: dimmed backdrop, preview, top bar and side menu
Item {
    id: desktopEditorContent
    anchors.fill: parent
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.6 * desktopWidgetLayer.editEnterOpacity
        MouseArea { anchors.fill: parent; onClicked: desktopEditorPopup.selectedType = "" }
    }

    DesktopEditPreview { id: previewBox }

    DesktopEditorTopBar { id: desktopEditorTopBar }

    DesktopEditorMenu { id: desktopEditorMainMenu }
}
