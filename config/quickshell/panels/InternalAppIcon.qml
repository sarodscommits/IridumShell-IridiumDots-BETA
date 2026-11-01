import QtQuick
import "../ui"

// Icon of a built-in shell app
Rectangle {
    property string glyph: ""
    property real glyphScale: 0.6
    property color glyphColor: pal.surfaceLowest
    radius: width / 2
    color: pal.primary
    Behavior on color { M3ColorAnim {} }
    Text {
        anchors.centerIn: parent
        text: parent.glyph
        font.family: "Material Symbols Rounded"
        font.pixelSize: Math.max(8, Math.round(parent.width * parent.glyphScale))
        color: parent.glyphColor
    }
}
