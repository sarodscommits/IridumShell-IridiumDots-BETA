import QtQuick
import "../ui"

// Current lyric line with a flip transition
Item {
    id: lfl
    property string text: ""
    property color color: pal.colorOnSurface
    property string fontFamily: globalState.fontPrimary
    property real fontSize: 20
    property int weight: Font.Black
    property int align: Text.AlignHCenter
    property int maxLines: 3
    property bool fit: true
    property int _slot: 0
    property string _a: ""
    property string _b: ""
    Component.onCompleted: _a = text
    clip: true
    onTextChanged: {
        if (_slot === 0) { _b = text; _slot = 1; } else { _a = text; _slot = 0; }
        lflSp.snap(0); lflSp.target = 1;
    }
    Spring { id: lflSp; target: 1; token: "spatialDefault"; eps: 0.002 }
    Repeater {
        model: 2
        Text {
            required property int index
            readonly property bool front: index === lfl._slot
            width: lfl.width
            height: lfl.height
            y: front ? (1 - lflSp.value) * lfl.height * 0.45 : -lflSp.value * lfl.height * 0.45
            opacity: front ? Math.min(1, lflSp.value * 1.4) : Math.max(0, 1 - lflSp.value * 1.6)
            text: index === 0 ? lfl._a : lfl._b
            horizontalAlignment: lfl.align
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
            maximumLineCount: lfl.maxLines
            elide: Text.ElideRight
            fontSizeMode: lfl.fit ? Text.Fit : Text.FixedSize
            minimumPixelSize: Math.max(7, Math.round(lfl.fontSize * 0.45))
            font.family: lfl.fontFamily
            font.pixelSize: Math.max(7, Math.round(lfl.fontSize))
            font.weight: lfl.weight
            color: lfl.color
        }
    }
}
