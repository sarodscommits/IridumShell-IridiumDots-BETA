import QtQuick

// Filter / assist chip
Item {
    id: ech
    property string text: ""
    property string icon: ""
    property bool selected: false
    property bool filter: true
    property real chipH: 32
    signal clicked()
    width: echRow.implicitWidth + 32; height: chipH
    implicitWidth: width; implicitHeight: chipH
    Spring { id: echS; token: "spatialFast"; eps: 0.002; target: ech.selected ? 1 : 0 }
    Spring { id: echH; token: "effectsFast"; target: echMa.containsMouse ? 1 : 0 }
    Rectangle {
        anchors.fill: parent; radius: 8 + (ech.chipH / 2 - 8) * Math.max(0, Math.min(1, echS.value))
        color: ech.selected ? m3.secondaryContainer : "transparent"
        border.width: ech.selected ? 0 : 1; border.color: m3.outlineVariant
    }
    Rectangle { anchors.fill: parent; radius: 8 + (ech.chipH / 2 - 8) * Math.max(0, Math.min(1, echS.value)); color: m3.inkSurface; opacity: 0.08 * echH.value }
    Row {
        id: echRow; anchors.centerIn: parent; spacing: 8 * Math.min(1, Math.max(0, ech.filter ? echS.value : 1))
        Item {
            visible: ech.filter || ech.icon !== ""
            width: ech.filter && ech.icon === "" ? 18 * Math.max(0, echS.value) : 18; height: 18; clip: true
            anchors.verticalCenter: parent.verticalCenter
            EIcon { name: (ech.filter && ech.icon === "") ? "check" : ech.icon; size: 18; color: ech.selected ? m3.inkSecondaryContainer : m3.primary; filled: ech.selected }
        }
        EText { text: ech.text; role: "labelLarge"; color: ech.selected ? m3.inkSecondaryContainer : m3.inkSurfaceVariant; anchors.verticalCenter: parent.verticalCenter }
    }
    MouseArea { id: echMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ech.clicked() }
}
