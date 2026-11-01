.pragma library
// Shared cava drawing: bar smoothing, sampling, wave fill and rounded bars

function smooth(src, prev) {
    var M = src.length, sm = prev;
    if (sm.length !== M) { sm = []; for (var q = 0; q < M; q++) sm.push(0); }
    var silent = true;
    for (var i = 0; i < M; i++) {
        var t = src[i] || 0;
        sm[i] += (t - sm[i]) * (t > sm[i] ? 0.55 : 0.18);
        if (sm[i] > 0.004) silent = false;
    }
    return { vals: sm, silent: silent };
}

function valAt(sm, tt) {
    var M = sm.length;
    var pos = Math.max(0, Math.min(1, tt)) * (M - 1);
    var lo = Math.floor(pos), hi = Math.min(M - 1, lo + 1);
    var f = pos - lo;
    return sm[lo] * (1 - f) + sm[hi] * f;
}

function fillCss(col) {
    var s0 = col.toString().replace("#", "");
    if (s0.length === 8) s0 = s0.substr(2);
    return "rgba(" + parseInt(s0.substr(0, 2), 16) + "," + parseInt(s0.substr(2, 2), 16) + "," + parseInt(s0.substr(4, 2), 16) + "," + 1 + ")";
}

function ripple(v, tt, now) {
    return (0.03 + v * 0.06) * Math.sin(tt * Math.PI * 6 + now * 2.1);
}

function fillCurve(ctx, pts, W, H) {
    ctx.beginPath();
    ctx.moveTo(0, H);
    ctx.lineTo(pts[0].x, pts[0].y);
    for (var k = 1; k < pts.length; k++) {
        var mx = (pts[k - 1].x + pts[k].x) / 2, my = (pts[k - 1].y + pts[k].y) / 2;
        ctx.quadraticCurveTo(pts[k - 1].x, pts[k - 1].y, mx, my);
    }
    ctx.lineTo(W, pts[pts.length - 1].y);
    ctx.lineTo(W, H);
    ctx.closePath();
    ctx.fill();
}

function roundedBar(ctx, x, bw, H, bh) {
    var y = H - bh;
    var cr = Math.min(bw / 2, 5);
    ctx.beginPath();
    ctx.moveTo(x, H);
    ctx.lineTo(x, y + cr);
    ctx.arc(x + cr, y + cr, cr, Math.PI, -Math.PI / 2);
    ctx.lineTo(x + bw - cr, y);
    ctx.arc(x + bw - cr, y + cr, cr, -Math.PI / 2, 0);
    ctx.lineTo(x + bw, H);
    ctx.closePath();
    ctx.fill();
}
