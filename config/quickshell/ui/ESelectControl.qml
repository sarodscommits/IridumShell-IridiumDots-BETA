import QtQuick

// Base for ECheck / ERadio; children go inside the 40px box
Item {
    id: esc
    property string label: ""
    default property alias indicator: escBox.data
    readonly property alias hovered: escMa.containsMouse
    signal activated()
    width: escRow.implicitWidth; height: 40
    implicitWidth: width; implicitHeight: 40
    Row {
        id: escRow; spacing: 8; anchors.verticalCenter: parent.verticalCenter
        Item {
            id: escBox
            width: 40; height: 40
            Rectangle { anchors.fill: parent; radius: 20; color: m3.inkSurface; opacity: escMa.containsMouse ? 0.08 : 0 }
        }
        EText { text: esc.label; role: "bodyMedium"; visible: esc.label !== ""; anchors.verticalCenter: parent.verticalCenter }
    }
    MouseArea { id: escMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: esc.activated() }
}
