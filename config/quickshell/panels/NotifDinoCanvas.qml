import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Empty-state illustration of the notification lists
Canvas {
    readonly property string _palSig: "" + pal.muted
    on_PalSigChanged: requestPaint()
    id: dino
    Layout.alignment: Qt.AlignHCenter
    AutoShape {
        z: -1
        anchors.centerIn: parent
        width: parent.width * 1.22; height: width
        inset: 1.0
        seq: ["Cookie12Sided", "Flower", "Clover8Leaf", "Puffy", "SoftBurst", "Cookie9Sided"]
        interval: 3400
        spinStep: 30
        fill: ga(pal.primary, 0.07)
        running: parent.parent.visible && (globalState.notchControlOpen || globalState.islandControlOpen)
    }
    property int _cols: 32
    property int _rows: 32
    property int _px: 5
    width: _cols * _px
    height: _rows * _px
    opacity: globalState.glassMode ? 0.88 : 1.0
    property var _grid: [
    "00000000000000000011111111110000",
    "00000000000000000011111111110000",
    "00000000000000001111111111111100",
    "00000000000000001110111111111100",
    "00000000000000001111111111111100",
    "00000000000000001111111111111100",
    "00000000000000001111111111111100",
    "00000000000000001111111111111100",
    "00000000000000001111111000000000",
    "00000000000000001111111000000000",
    "00000000000000001111111111100000",
    "00100000000000011111100000000000",
    "00100000000000011111100000000000",
    "00100000000001111111100000000000",
    "00110000001111111111111100000000",
    "00110000001111111111100100000000",
    "00111100011111111111100000000000",
    "00111111111111111111100000000000",
    "00111111111111111111100000000000",
    "00001111111111111111100000000000",
    "00001111111111111111000000000000",
    "00000111111111111111000000000000",
    "00000011111111111110000000000000",
    "00000011111111111110000000000000",
    "00000000111111111000000000000000",
    "00000000011110011000000000000000",
    "11111100011110011000111111111111",
    "00000000011100001000000000000000",
    "00000000010000001000000000000000",
    "00000110010000001000000000000000",
    "00000000011100001110000000000000",
    "01100000000000000000000000000000"
    ]
    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        ctx.fillStyle = pal.muted;
        for (var r = 0; r < _grid.length; r++) {
            var row = _grid[r];
            for (var c = 0; c < row.length; c++) {
                if (row.charAt(c) === "1") ctx.fillRect(c * _px, r * _px, _px, _px);
            }
        }
    }
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    Component.onCompleted: requestPaint()
    Connections {
        target: pal
        function onMutedChanged() { dino.requestPaint() }
    }
}
