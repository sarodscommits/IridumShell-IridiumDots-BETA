import QtQuick
import "../ui"

// Labeled switch row for the desktop editor
Item {
    id: etRoot
    property bool on: false
    property color activeColor: m3.primary
    property color offColor: m3.surfaceContainerHighest
    signal clicked()
    implicitWidth: 39; implicitHeight: 24
    width: 39; height: 24
    ESwitch {
        anchors.centerIn: parent
        scaleF: 0.75
        checked: etRoot.on
        onToggled: etRoot.clicked()
    }
}
