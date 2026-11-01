import QtQuick
import "../ui"

// Pill segment with a rounded close side
Canvas {
    property color segColor: "transparent"
    property real innerR: 8
    antialiasing: true
    onSegColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        var w = width, h = height;
        if (w <= 0 || h <= 0) return;
        var rl = Math.min(innerR, h / 2, w / 2);
        var R = Math.max(0, Math.min(h / 2, w - rl));
        ctx.beginPath();
        ctx.moveTo(rl, 0);
        ctx.lineTo(w - R, 0);
        ctx.arc(w - R, R, R, -Math.PI / 2, 0, false);
        ctx.lineTo(w, h - R);
        ctx.arc(w - R, h - R, R, 0, Math.PI / 2, false);
        ctx.lineTo(rl, h);
        ctx.arc(rl, h - rl, rl, Math.PI / 2, Math.PI, false);
        ctx.lineTo(0, rl);
        ctx.arc(rl, rl, rl, Math.PI, Math.PI * 1.5, false);
        ctx.closePath();
        ctx.fillStyle = segColor;
        ctx.fill();
    }
}
