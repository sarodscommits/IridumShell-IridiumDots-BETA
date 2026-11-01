import QtQuick

// Icon on a shape that morphs on hover and shrinks on press
Item {
    id: sib
    property string shape: "Circle"
    property string hoverShape: "Cookie9Sided"
    property string glyph: ""
    property color fill: m3.secondaryContainer
    property color ink: m3.inkSecondaryContainer
    property real glyphSize: 22
    signal clicked()
    Spring { id: sibM; target: sibMa.containsMouse ? 1 : 0; token: "spatialFast"; eps: 0.002 }
    Spring { id: sibR; target: sibMa.containsMouse ? 30 : 0; token: "spatialDefault"; eps: 0.05 }
    Spring { id: sibS; target: sibMa.pressed ? 0.88 : 1; token: "spatialFast"; eps: 0.002 }
    MBox {
        anchors.fill: parent
        from: sib.shape; to: sib.hoverShape; t: sibM.value
        rotation: sibR.value
        scale: sibS.value
        fill: sib.fill
    }
    Text {
        anchors.centerIn: parent
        text: sib.glyph
        font.family: "Material Symbols Rounded"; font.pixelSize: sib.glyphSize
        color: sib.ink
        scale: sibS.value
    }
    MouseArea { id: sibMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: sib.clicked() }
}
