import QtQuick

// M3E radio button
ESelectControl {
    id: erb
    property bool checked: false
    signal picked()
    onActivated: picked()
    Spring { id: erbP; token: "spatialFast"; eps: 0.002; target: erb.checked ? 1 : 0 }
    Rectangle { anchors.centerIn: parent; width: 20; height: 20; radius: 10; color: "transparent"; border.width: 2; border.color: erb.checked ? m3.primary : m3.inkSurfaceVariant }
    Rectangle { anchors.centerIn: parent; width: 10 * Math.max(0, erbP.value); height: width; radius: width / 2; color: m3.primary }
}
