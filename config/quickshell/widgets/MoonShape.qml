import QtQuick
import "../ui"

// Animated moon glyph
Item {
    id: moonShapeRoot
    required property real size
    property color colorCore: "#FFFFFF"
    property color colorMid:  "#DCE6F7"
    property color colorEdge: "#9DB2D8"
    width: size; height: size
    property int ss: 3

    Canvas {
        x: 0; y: 0
        width: moonShapeRoot.width * moonShapeRoot.ss
        height: moonShapeRoot.height * moonShapeRoot.ss
        transformOrigin: Item.TopLeft
        scale: 1 / moonShapeRoot.ss
        smooth: true
        antialiasing: true
        readonly property string sig: "" + moonShapeRoot.colorCore + moonShapeRoot.colorMid + moonShapeRoot.colorEdge
        onSigChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.clearRect(0, 0, width, height);
            var r = Math.min(width, height) / 2;
            var cx = width / 2, cy = height / 2;
            var g = ctx.createRadialGradient(cx - r * 0.45, cy + r * 0.35, r * 0.05, cx - r * 0.2, cy + r * 0.15, r * 1.15);
            g.addColorStop(0.0, moonShapeRoot.colorCore);
            g.addColorStop(0.45, moonShapeRoot.colorMid);
            g.addColorStop(1.0, moonShapeRoot.colorEdge);
            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, Math.PI * 2, false);
            ctx.closePath();
            ctx.fillStyle = g;
            ctx.fill();
            ctx.globalCompositeOperation = "destination-out";
            ctx.beginPath();
            ctx.arc(cx + r * 2 * 0.32, cy - r * 2 * 0.12, r * 1.0, 0, Math.PI * 2, false);
            ctx.closePath();
            ctx.fillStyle = "#000000";
            ctx.fill();
            ctx.globalCompositeOperation = "source-over";
        }
        Component.onCompleted: requestPaint()
    }
}
