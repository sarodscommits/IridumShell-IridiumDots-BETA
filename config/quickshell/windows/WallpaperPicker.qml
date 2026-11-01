import QtQuick
import "../ui"

// Super+W coverflow wallpaper picker
WindowLoader {
    id: wallpaperPickerLoader
    active: globalState.wallpaperPickerOpen || globalState.wallpaperPickerAlive
    source: Qt.resolvedUrl("WallpaperPickerWindow.qml")
}
