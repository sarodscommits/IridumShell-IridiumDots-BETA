import QtQuick

// Bar module slot: state layer + tonal container while its menu is open
Item {
    id: ebs
    property bool active: false
    property bool hovered: false
    property bool pressed: false
    property color activeColor: m3.glassy(m3.secondaryContainer, 0.75)
    property real restRadius: Math.min(width, height) / 2
    z: -1
    Spring { id: ebsR; token: "spatialFast"; eps: 0.05; target: ebs.pressed ? 6 : (ebs.active ? 9 : ebs.restRadius) }
    Spring { id: ebsA; token: "effectsFast"; target: ebs.active ? 1 : 0 }
    Rectangle { anchors.fill: parent; radius: Math.max(0, ebsR.value); color: ebs.activeColor; opacity: Math.max(0, Math.min(1, ebsA.value)) }
    StateLayer { anchors.fill: parent; radius: Math.max(0, ebsR.value); color: m3.inkSurface; hovered: ebs.hovered; pressed: ebs.pressed }
}
