import QtQuick

// M3E switch
Item {
    id: esw
    property bool checked: false
    property bool icons: m3.switchIcons
    property real scaleF: 1
    property bool interactive: true
    signal toggled(bool value)
    width: 52 * scaleF; height: 32 * scaleF
    implicitWidth: width; implicitHeight: height
    opacity: enabled ? 1 : 0.38
    Spring { id: eswPos; token: "spatialFast"; eps: 0.002; target: esw.checked ? 1 : 0 }
    Spring { id: eswHs; token: "spatialFast"; eps: 0.05; target: eswMa.pressed ? 28 : ((esw.checked || esw.icons) ? 24 : 16) }
    Item {
        width: 52; height: 32
        scale: esw.scaleF
        transformOrigin: Item.TopLeft
        Rectangle {
            anchors.fill: parent; radius: 16
            color: esw.checked ? m3.primary : m3.glassy(m3.surfaceContainerHighest, 0.7)
            border.width: 2; border.color: esw.checked ? m3.primary : m3.outline
            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }
        }
        Rectangle {
            width: eswHs.value; height: eswHs.value; radius: width / 2
            x: 16 + eswPos.value * 20 - width / 2; y: (32 - height) / 2
            color: esw.checked ? m3.inkPrimary : (eswMa.pressed ? m3.inkSurfaceVariant : m3.outline)
            Rectangle {
                anchors.centerIn: parent; width: 40; height: 40; radius: 20; z: -1
                color: esw.checked ? m3.primary : m3.inkSurface
                opacity: eswMa.pressed ? 0.12 : (eswMa.containsMouse ? 0.08 : 0)
            }
            EIcon {
                anchors.centerIn: parent; visible: esw.icons; size: 16
                name: esw.checked ? "check" : "close"
                color: esw.checked ? m3.inkPrimaryContainer : m3.surfaceContainerHighest
            }
        }
    }
    MouseArea { id: eswMa; anchors.fill: parent; enabled: esw.interactive; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: esw.toggled(!esw.checked) }
}
