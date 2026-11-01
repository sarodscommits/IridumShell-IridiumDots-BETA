import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Open windows module of the bar
Item {
    id: openWindowsModule
    property alias windowPreviewPopup: windowPreviewPopup
    visible: globalState.barModules.windows
    Layout.preferredWidth: unifiedFrame.barVertical ? 36 : openWindowsClip.openWindowsRow.implicitWidth
    Layout.preferredHeight: unifiedFrame.barVertical ? openWindowsClip.openWindowsRow.implicitHeight : 36
    Layout.alignment: Qt.AlignCenter
    Behavior on Layout.preferredWidth {
        enabled: !globalState.desktopZoomBusy && unifiedFrame.startupSettled
        M3SpringAnim { token: "spatialFast" }
    }
    Behavior on Layout.preferredHeight {
        enabled: !globalState.desktopZoomBusy && unifiedFrame.startupSettled && unifiedFrame.barVertical
        M3SpringAnim { token: "spatialFast" }
    }
    Behavior on x {
        enabled: !globalState.desktopZoomBusy && unifiedFrame.startupSettled && !globalState.desktopEditMode
        M3SpringAnim { token: "spatialFast" }
    }

    OpenWindowsStrip { id: openWindowsClip }

    Timer {
        id: peekRestoreGuard
        interval: 40
        onTriggered: {
            if (globalState.peekedWindowAddress !== "") {
                Quickshell.execDetached(["/usr/bin/python3",
                Quickshell.env("HOME") + "/.config/hypr/scripts/peek_window.py", "restore",
                globalState.peekedWindowAddress]);
                globalState.peekedWindowAddress = "";
            }
        }
    }

    Timer {
        id: previewCloseTimer
        interval: 120
        repeat: false
        onTriggered: {
            if (!windowPreviewPopup.windowPreviewPopupHover.hovered && !topBarHover.hovered) globalState.windowPreviewOpen = false;
        }
    }

    WindowPreviewPopup { id: windowPreviewPopup }
}
