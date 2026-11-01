import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Right-click menu on empty desktop space
Item {
    id: desktopEmptyContextMenu
    anchors.fill: parent
    z: 3000
    visible: open || desktopEmptyContextMenuCard.visible

    property bool open: false
    property real clickX: 0
    property real clickY: 0

    function openAt(x, y) {
        clickX = x;
        clickY = y;
        open = true;
    }
    function close() { open = false; }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: (m) => {
            if (m.button === Qt.RightButton && !globalState.lockScreenActive && !globalState.desktopEditMode)
            desktopEmptyContextMenu.openAt(m.x, m.y);
            else
            desktopEmptyContextMenu.close();
        }
    }

    EMenu {
        id: desktopEmptyContextMenuCard
        x: Math.max(8, Math.min(desktopEmptyContextMenu.clickX, unifiedFrame.width - width - 8))
        y: Math.max(8, Math.min(desktopEmptyContextMenu.clickY, unifiedFrame.height - height - 8))
        menuWidth: 240
        open: desktopEmptyContextMenu.open
        groups: [
        [["\ue3c9", tr("desktop_context_enter_editor"), "", "editor"]],
        [["\ue2c7", tr("desktop_context_open_files"), "", "files"],
        ["\ue8b8", tr("desktop_context_open_settings"), "", "settings"],
        ["\ue3f4", tr("desktop_context_change_wallpaper"), "", "wallpaper"]],
        [["\ue897", tr("desktop_context_lock"), "", "lock"]]
        ]
        onCloseRequested: desktopEmptyContextMenu.close()
        onTriggered: (action) => {
            if (action === "editor") {
                if (!globalState.desktopEditMode) globalState.toggleDesktopEditMode();
            } else if (action === "settings") {
                globalState.settingsOpen = true;
            } else if (action === "wallpaper") {
                globalState.wallpaperPickerOpen = true;
            } else if (action === "files") {
                globalState.openFileExplorer("");
            } else if (action === "lock") {
                globalState.runPowerAction("lock");
            }
        }
        MouseArea { anchors.fill: parent; z: -2; acceptedButtons: Qt.LeftButton | Qt.RightButton }
    }
}
