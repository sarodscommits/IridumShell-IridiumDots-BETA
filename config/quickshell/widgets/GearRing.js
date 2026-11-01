.pragma library
// Gear-shaped progress ring drawing

function gapAngle(p, rBase) {
    return (p > 0 && p < 1) ? Math.min(0.45, 10 / Math.max(1, rBase)) : 0;
}

function stroke(ctx, color, lw) {
    ctx.strokeStyle = color.toString();
    ctx.lineWidth = lw;
    ctx.lineCap = "round";
    ctx.stroke();
}

function trackArc(ctx, cx, cy, r, start, sweep, steps, color, lw) {
    if (sweep <= 0.001) return;
    var n = Math.max(2, Math.round(steps * (sweep / (Math.PI * 2))));
    ctx.beginPath();
    for (var i = 0; i <= n; i++) {
        var a = start + (i / n) * sweep;
        var x = cx + Math.cos(a) * r, y = cy + Math.sin(a) * r;
        if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
    }
    stroke(ctx, color, lw);
}

function gearStroke(ctx, cx, cy, upTo, steps, radiusAt, color, lw) {
    ctx.beginPath();
    for (var j = 0; j <= upTo; j++) {
        var aPos = (j / steps) * Math.PI * 2 - Math.PI / 2;
        var r = radiusAt(aPos);
        var x = cx + Math.cos(aPos) * r, y = cy + Math.sin(aPos) * r;
        if (j === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
    }
    stroke(ctx, color, lw);
}
