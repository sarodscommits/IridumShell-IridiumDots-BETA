import QtQuick
import "../ui"

// Animated cloud glyph
Item {
    id: cloudShapeRoot
    width: 66; height: 39
    property color colorBody:  "#FFFFFF"
    property int ss: 3

    Canvas {
        x: 0; y: 0
        width: cloudShapeRoot.width * cloudShapeRoot.ss
        height: cloudShapeRoot.height * cloudShapeRoot.ss
        transformOrigin: Item.TopLeft
        scale: 1 / cloudShapeRoot.ss
        smooth: true
        antialiasing: true
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        function fillPieces(ctx, k, dx, dy) {
            function circ(x, y, d) {
                ctx.beginPath();
                ctx.ellipse(x * k + dx, y * k + dy, d * k, d * k);
                ctx.fill();
            }
            circ(0, 12, 28);
            circ(15, 0, 38);
            ctx.beginPath();
            ctx.roundedRect(0 * k + dx, 20 * k + dy, 66 * k, 19 * k, 9.5 * k, 9.5 * k);
            ctx.fill();
        }
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.clearRect(0, 0, width, height);
            var k = Math.min(width / 66, height / 39);
            var g = ctx.createLinearGradient(0, 0, 0, height);
            g.addColorStop(0.0, Qt.rgba(0.80, 0.84, 0.92, 1));
            g.addColorStop(1.0, Qt.rgba(0.62, 0.68, 0.80, 1));
            ctx.fillStyle = g;
            fillPieces(ctx, k, 0, 0);
            ctx.globalCompositeOperation = "source-atop";
            ctx.shadowColor = cloudShapeRoot.colorBody;
            ctx.shadowBlur = 3 * k;
            ctx.fillStyle = cloudShapeRoot.colorBody;
            fillPieces(ctx, k, 0, -4 * k);
            ctx.shadowBlur = 0;
            ctx.globalCompositeOperation = "source-over";
        }
        Component.onCompleted: requestPaint()
    }
}
