import QtQuick

// Empty state; the shape morphs to the next one whenever `key` changes
Row {
    id: ehi
    property string text: ""
    property string key: ""
    property color shapeColor: m3.alpha(pal.primary, 0.32)
    property color textColor: pal.muted
    property real shapeSize: 18
    property int fontSize: 12
    spacing: 8
    onKeyChanged: ehiSeq.next(50)
    ShapeSequencer {
        id: ehiSeq
        seq: ["Cookie9Sided", "Flower", "Clover4Leaf", "SoftBurst", "Pentagon", "Puffy", "Gem", "Cookie6Sided"]
        morphEps: 0.002; rotEps: 0.05
    }
    MShape {
        anchors.verticalCenter: parent.verticalCenter
        width: ehi.shapeSize; height: ehi.shapeSize
        inset: 1.0
        from: ehiSeq.from; to: ehiSeq.to
        t: ehiSeq.t
        rotation: ehiSeq.rot
        fill: ehi.shapeColor
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: ehi.text
        font.family: globalState.fontSecondary; font.pixelSize: Math.round(ehi.fontSize * globalState.fontScale)
        color: ehi.textColor
    }
}
