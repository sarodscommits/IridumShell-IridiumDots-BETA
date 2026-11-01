import QtQuick

Item {
    // ELoading with a required color
    id: mlRoot
    property real size: 48
    required property color fillColor
    property bool running: visible
    width: size; height: size
    ELoading {
        anchors.centerIn: parent
        size: mlRoot.size
        color: mlRoot.fillColor
        running: mlRoot.running
    }
}
