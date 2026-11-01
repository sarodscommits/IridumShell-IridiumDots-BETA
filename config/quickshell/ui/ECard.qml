import QtQuick
import QtQuick.Layouts

// M3E card: radius grows on hover, shrinks on press
Rectangle {
    id: ecd
    property string kind: "filled"         // elevated · filled · outlined · low
    property bool interactive: true
    property real baseRadius: m3.corner(24)
    property real pad: 16
    default property alias content: ecdCol.data
    signal clicked()
    Spring { id: ecdL; token: "spatialFast"; target: (ecd.interactive && ecdMa.pressed) ? 0.975 : 1; eps: 0.0005 }
    Spring { id: ecdH; token: "effectsFast"; target: (ecd.interactive && ecdMa.containsMouse) ? 1 : 0 }
    scale: ecdL.value
    radius: baseRadius + 8 * ecdH.value
    color: kind === "elevated" ? m3.glassy(m3.surfaceContainerLow, 0.6) : (kind === "filled" ? m3.glassy(m3.surfaceContainerHighest, 0.6) : (kind === "low" ? m3.glassy(m3.surfaceContainerLow, 0.5) : "transparent"))
    border.width: kind === "outlined" ? 1 : 0
    border.color: m3.outlineVariant
    implicitWidth: 260
    implicitHeight: ecdCol.implicitHeight + pad * 2
    Rectangle {
        visible: ecd.kind === "elevated"
        z: -1; y: 2 + 3 * ecdH.value; width: parent.width; height: parent.height; radius: parent.radius
        color: m3.alpha(m3.shadow, (m3.dark ? 0.45 : 0.14) + 0.1 * ecdH.value)
    }
    Rectangle { anchors.fill: parent; radius: parent.radius; color: m3.inkSurface; opacity: 0.05 * ecdH.value }
    MouseArea { id: ecdMa; anchors.fill: parent; hoverEnabled: ecd.interactive; enabled: ecd.interactive; onClicked: ecd.clicked() }
    ColumnLayout { id: ecdCol; x: ecd.pad; y: ecd.pad; width: ecd.width - ecd.pad * 2; spacing: 10 }
}
