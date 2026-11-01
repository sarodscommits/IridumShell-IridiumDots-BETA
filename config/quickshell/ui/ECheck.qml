import QtQuick

// M3E checkbox
ESelectControl {
    id: ecb
    property bool checked: false
    signal toggled(bool value)
    onActivated: toggled(!checked)
    Spring { id: ecbP; token: "spatialFast"; eps: 0.002; target: ecb.checked ? 1 : 0 }
    Rectangle {
        anchors.centerIn: parent; width: 18; height: 18; radius: 2 + 2 * ecbP.value
        color: ecb.checked ? m3.primary : "transparent"
        border.width: ecb.checked ? 0 : 2; border.color: m3.inkSurfaceVariant
        EIcon { anchors.centerIn: parent; name: "check"; size: 16; color: m3.inkPrimary; scale: Math.max(0, ecbP.value); visible: ecbP.value > 0.01 }
    }
}
