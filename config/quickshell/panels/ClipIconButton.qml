import QtQuick
import "../ui"

// Clipboard icon button
Item {
    id: cib
    property string glyph: ""
    property bool active: false
    property color iconColor: m3.inkSurfaceVariant
    property color activeColor: m3.primary
    property color hoverColor: m3.alpha(m3.inkSurface, 0.08)
    property real radius: Math.min(width, height) / 2
    property color color: "transparent"
    signal clicked()
    implicitWidth: 30; implicitHeight: 30
    width: 30; height: 30
    Spring { id: cibR; token: "spatialFast"; eps: 0.05; target: cibMa.pressed ? cib.radius * 0.5 : (cib.active ? cib.radius * 0.66 : cib.radius) }
    Spring { id: cibS; token: "effectsFast"; target: cibMa.pressed ? 1.5 : (cibMa.containsMouse ? 1 : 0) }
    Rectangle {
        anchors.fill: parent; radius: cibR.value
        color: cib.active ? m3.alpha(cib.activeColor, 0.16) : cib.color
        Behavior on color { M3ColorAnim { duration: m3.durFast } }
    }
    Rectangle { anchors.fill: parent; radius: cibR.value; color: cib.hoverColor; opacity: Math.max(0, cibS.value) }
    FadeIcon {
        anchors.centerIn: parent
        text: cib.glyph
        font.family: "Material Symbols Rounded"; font.pixelSize: 17
        color: cib.active ? cib.activeColor : cib.iconColor
    }
    MouseArea { id: cibMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: cib.clicked() }
}
