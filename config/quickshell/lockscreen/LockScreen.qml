import QtQuick
import "../ui"

// Lockscreen: wallpaper blur, clock, media, notifications and password entry
WindowLoader {
    id: lockScreenLoader
    active: globalState.lockScreenActive || lockHoldTimer.running
    source: Qt.resolvedUrl("LockScreenWindow.qml")
}
