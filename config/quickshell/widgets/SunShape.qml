import QtQuick
import "../ui"

// Animated sun glyph
Item {
    id: sunShapeRoot

    required property real size
    property color colorCore: "#FFF1C2"
    property color colorEdge: "#FFB23D"

    width: sunShapeRoot.size
    height: sunShapeRoot.size

    property int ss: 3

    Canvas {
        id: sunShapeCanvas
        x: 0; y: 0
        width: sunShapeRoot.width * sunShapeRoot.ss
        height: sunShapeRoot.height * sunShapeRoot.ss
        transformOrigin: Item.TopLeft
        scale: 1 / sunShapeRoot.ss
        smooth: true
        antialiasing: true
        property color core: sunShapeRoot.colorCore
        property color edge: sunShapeRoot.colorEdge
        onCoreChanged: requestPaint()
        onEdgeChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            var cx = width / 2, cy = height / 2;
            var gearR = Math.min(width, height) * 0.5;
            var teeth = 12, rBase = gearR * 0.88, amp = gearR * 0.10;
            var asymAmp = gearR * 0.05;
            var cxAdj = cx - asymAmp / 2;
            var steps = 720;
            ctx.beginPath();
            for (var i = 0; i <= steps; i++) {
                var a = (i / steps) * Math.PI * 2;
                var c = Math.cos(teeth / 2 * a);
                var r = rBase + amp * c * c + asymAmp * Math.cos(a);
                var px = cxAdj + Math.cos(a) * r;
                var py = cy + Math.sin(a) * r;
                if (i === 0) ctx.moveTo(px, py); else ctx.lineTo(px, py);
            }
            ctx.closePath();
            var grad = ctx.createRadialGradient(cxAdj, cy, gearR * 0.15, cxAdj, cy, gearR);
            grad.addColorStop(0, core);
            grad.addColorStop(1, edge);
            ctx.fillStyle = grad;
            ctx.fill();
        }
        Component.onCompleted: requestPaint()
    }
}
