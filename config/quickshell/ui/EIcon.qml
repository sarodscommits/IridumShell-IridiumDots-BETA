import QtQuick

// Material Symbols icon (codepoint or ligature name)
Text {
    property string name: ""
    property real size: 24
    property bool filled: false
    color: m3.inkSurface
    font.family: m3.symbols
    font.pixelSize: size
    text: name
    width: size
    height: size
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}
