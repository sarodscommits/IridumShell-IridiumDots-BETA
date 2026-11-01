import QtQuick
import Quickshell

// Terminal launch command
QtObject {
    id: terminalLauncher

    function open() {
        Quickshell.execDetached(["kitty"]);
    }
}
