import QtQuick
import Quickshell
import ".."
import "../ui"

// Settings > System: refresh button for the fetch modules
PressIconButton {
    width: 36; height: 36
    cornerRadius: 18
    icon: ""
    iconSize: 18
    iconColor: pal.primary
    iconVisible: !fetchProcess.running
    hoverColor: pal.surfaceVar
    idleColor: "transparent"
    onClicked: fetchProcess.running = true
    MorphLoader {
        anchors.centerIn: parent
        size: 18
        fillColor: pal.primary
        visible: running
        running: fetchProcess.running
    }
}
