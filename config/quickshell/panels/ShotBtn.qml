import QtQuick
import "../ui"

// Screenshot annotation toolbar button
Rectangle {
    id: sb
    property string glyph: ""
    property string tip: ""
    property bool active: false
    property bool accent: false
    signal clicked()
    width: 36; height: 36
    radius: sbMa.pressed ? 10 : 18
    Behavior on radius { M3SpringAnim { token: "spatialFast" } }
    color: active || accent ? pal.primary
         : (sbMa.containsMouse ? ga(pal.colorOnSurface, 0.10) : "transparent")
    Behavior on color { ColorAnimation { duration: m3.durFast } }
    Text {
        anchors.centerIn: parent
        text: sb.glyph
        font.family: "Material Symbols Rounded"; font.pixelSize: 20
        color: sb.active || sb.accent ? pal.colorOnPrimary : pal.colorOnSurface
    }
    MouseArea { id: sbMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: sb.clicked() }
}
