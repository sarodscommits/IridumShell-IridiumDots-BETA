import QtQuick
import "../ui"

// Key combination made of keycaps
Row {
    id: kcb
    property var keys: []
    property bool hold: false
    spacing: 4
    Repeater {
        model: kcb.keys
        delegate: Row {
            required property var modelData
            required property int index
            spacing: 4
            EText {
                visible: index > 0
                text: "+"
                role: "labelMedium"
                color: m3.inkSurfaceVariant
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -1
            }
            KbKeycap {
                label: modelData.t
                icon: modelData.i
                accent: !!modelData.m
            }
        }
    }
}
