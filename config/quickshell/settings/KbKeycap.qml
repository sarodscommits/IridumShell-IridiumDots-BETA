import QtQuick
import "../ui"

// Physical-looking keycap for the keyboard settings
Item {
    id: kkc
    property string label: ""
    property string icon: ""
    property bool accent: false
    property real capH: 30
    implicitWidth: Math.max(capH, kkcRow.implicitWidth + 18)
    implicitHeight: capH + 3
    width: implicitWidth
    height: implicitHeight
    Rectangle {
        y: 3; width: parent.width; height: kkc.capH
        radius: m3.corner(10)
        color: kkc.accent ? m3.alpha(m3.secondary, 0.55) : m3.alpha(m3.outlineVariant, 0.75)
    }
    Rectangle {
        width: parent.width; height: kkc.capH
        radius: m3.corner(10)
        color: kkc.accent ? m3.secondaryContainer : m3.glassy(m3.surfaceContainerHighest, 0.92)
        border.width: 1
        border.color: m3.alpha(m3.outlineVariant, 0.5)
        Row {
            id: kkcRow
            anchors.centerIn: parent
            spacing: 4
            EIcon {
                visible: kkc.icon !== ""
                name: kkc.icon; size: 16
                color: kkc.accent ? m3.inkSecondaryContainer : m3.inkSurfaceVariant
                anchors.verticalCenter: parent.verticalCenter
            }
            EText {
                visible: kkc.label !== ""
                text: kkc.label
                role: "labelLarge"; emph: true
                color: kkc.accent ? m3.inkSecondaryContainer : m3.inkSurface
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
