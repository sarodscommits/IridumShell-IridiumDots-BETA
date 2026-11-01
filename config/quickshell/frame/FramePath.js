.pragma library
// Frame shadow silhouette as an SVG path

function _geometry(p) {
    var g = { W: p.W, H: p.H, lW: p.lW, rW: p.rW, bLX: p.bLX, bRX: p.bRX };
    var fTop = p.bab ? p.bH : p.tH, fBot = p.bab ? p.tH : p.bH;
    var rT = p.bab ? 0 : p.cR, rB = p.bab ? p.cR : 0;
    var tIsl = p.isl && !p.bab, bIsl = p.isl && p.bab;
    var bw = p.bRX - p.bLX;
    g.fTop = fTop; g.fBot = fBot;
    g.tBD = (!p.bab && bw > 0) ? p.depth : 0;
    g.bBD = ( p.bab && bw > 0) ? p.depth : 0;
    g.tLJ = Math.min(p.joinR, g.tBD / 2, Math.max(0, bw) / 2) * (1 - p.flL);
    g.tRJ = Math.min(p.joinR, g.tBD / 2, Math.max(0, bw) / 2) * (1 - p.flR);
    g.bLJ = Math.min(p.joinR, g.bBD / 2) * (1 - p.flL);
    g.bRJ = Math.min(p.joinR, g.bBD / 2) * (1 - p.flR);
    g.tLCE = !p.bab ? p.depth * p.flL : 0; g.tRCE = !p.bab ? p.depth * p.flR : 0;
    g.bLCE =  p.bab ? p.depth * p.flL : 0; g.bRCE =  p.bab ? p.depth * p.flR : 0;
    var farL = p.ncSide ? Math.min(p.cR, Math.max(0, p.lW - p.eb)) : 0;
    var farR = p.ncSide ? Math.min(p.cR, Math.max(0, p.rW - p.eb)) : 0;
    g.tLOR = tIsl ? 0 : Math.max(rT, p.bab ? farL : 0);
    g.tROR = tIsl ? 0 : Math.max(rT, p.bab ? farR : 0);
    g.bLOR = bIsl ? 0 : Math.max(rB, !p.bab ? farL : 0);
    g.bROR = bIsl ? 0 : Math.max(rB, !p.bab ? farR : 0);
    var iLX = p.W / 2 - p.half, iRX = p.W / 2 + p.half;
    g.tSY = tIsl ? 0 : (fTop + g.tLCE);
    g.tEY = tIsl ? 0 : (fTop + g.tRCE);
    g.tNJ = tIsl ? Math.min(p.notchR, fTop / 2) : 0;
    g.tNLX = tIsl ? iLX : (p.lW + g.tLOR);
    g.tNRX = tIsl ? iRX : (p.W - p.rW - g.tROR);
    g.bRY = bIsl ? p.H : (p.H - fBot - g.bRCE);
    g.bLY = bIsl ? p.H : (p.H - fBot - g.bLCE);
    g.bNJ = bIsl ? Math.min(p.notchR, fBot / 2) : 0;
    g.bNLX = bIsl ? iLX : (p.lW + g.bLOR);
    g.bNRX = bIsl ? iRX : (p.W - p.rW - g.bROR);
    return g;
}

function _pen() {
    var out = [];
    function n(v) { return (isFinite(v) ? v : 0).toFixed(2); }
    var P = { out: out };
    P.M = function (x, y) { out.push("M" + n(x) + " " + n(y)); };
    P.L = function (x, y) { out.push("L" + n(x) + " " + n(y)); };
    P.Q = function (cx, cy, x, y) { out.push("Q" + n(cx) + " " + n(cy) + " " + n(x) + " " + n(y)); };
    P.A = function (r, x, y) {
        if (r > 0.01) out.push("A" + n(r) + " " + n(r) + " 0 0 1 " + n(x) + " " + n(y));
        else P.L(x, y);
    };
    return P;
}

function _topEdge(g, P) {
    var t = g.fTop;
    P.M(g.lW + g.tLOR, g.tSY);
    P.L(g.tNLX - g.tNJ, g.tSY);
    P.Q(g.tNLX, g.tSY, g.tNLX, g.tSY + g.tNJ);
    P.L(g.tNLX, t + g.tLCE - g.tNJ);
    P.Q(g.tNLX, t + g.tLCE, g.tNLX + g.tNJ, t + g.tLCE);
    P.L(g.bLX - g.tLJ, t + g.tLCE);
    P.Q(g.bLX, t + g.tLCE, g.bLX, t + g.tLCE + g.tLJ);
    P.L(g.bLX, t + g.tBD - g.tLJ);
    P.Q(g.bLX, t + g.tBD, g.bLX + g.tLJ, t + g.tBD);
    P.L(g.bRX - g.tRJ, t + g.tBD);
    P.Q(g.bRX, t + g.tBD, g.bRX, t + g.tBD - g.tRJ);
    P.L(g.bRX, t + g.tRCE + g.tRJ);
    P.Q(g.bRX, t + g.tRCE, g.bRX + g.tRJ, t + g.tRCE);
    P.L(g.tNRX - g.tNJ, t + g.tRCE);
    P.Q(g.tNRX, t + g.tRCE, g.tNRX, t + g.tRCE - g.tNJ);
    P.L(g.tNRX, g.tEY + g.tNJ);
    P.Q(g.tNRX, g.tEY, g.tNRX + g.tNJ, g.tEY);
    P.L(g.W - g.rW - g.tROR, g.tEY);
    P.A(g.tROR, g.W - g.rW, g.tEY + g.tROR);
    P.L(g.W - g.rW, g.bRY - g.bROR);
    P.A(g.bROR, g.W - g.rW - g.bROR, g.bRY);
}

function _bottomEdge(g, P) {
    var b = g.H - g.fBot;
    P.L(g.bNRX + g.bNJ, g.bRY);
    P.Q(g.bNRX, g.bRY, g.bNRX, g.bRY - g.bNJ);
    P.L(g.bNRX, b - g.bRCE + g.bNJ);
    P.Q(g.bNRX, b - g.bRCE, g.bNRX - g.bNJ, b - g.bRCE);
    P.L(g.bRX + g.bRJ, b - g.bRCE);
    P.Q(g.bRX, b - g.bRCE, g.bRX, b - g.bRCE - g.bRJ);
    P.L(g.bRX, b - g.bBD + g.bRJ);
    P.Q(g.bRX, b - g.bBD, g.bRX - g.bRJ, b - g.bBD);
    P.L(g.bLX + g.bLJ, b - g.bBD);
    P.Q(g.bLX, b - g.bBD, g.bLX, b - g.bBD + g.bLJ);
    P.L(g.bLX, b - g.bLCE - g.bLJ);
    P.Q(g.bLX, b - g.bLCE, g.bLX - g.bLJ, b - g.bLCE);
    P.L(g.bNLX + g.bNJ, b - g.bLCE);
    P.Q(g.bNLX, b - g.bLCE, g.bNLX, b - g.bLCE + g.bNJ);
    P.L(g.bNLX, g.bLY - g.bNJ);
    P.Q(g.bNLX, g.bLY, g.bNLX - g.bNJ, g.bLY);
    P.L(g.lW + g.bLOR, g.bLY);
    P.A(g.bLOR, g.lW, g.bLY - g.bLOR);
    P.L(g.lW, g.tSY + g.tLOR);
    P.A(g.tLOR, g.lW + g.tLOR, g.tSY);
}

function shadowPath(p) {
    var g = _geometry(p), P = _pen();
    P.M(0, 0); P.L(p.W, 0); P.L(p.W, p.H); P.L(0, p.H); P.out.push("Z");
    _topEdge(g, P);
    _bottomEdge(g, P);
    P.out.push("Z");
    return P.out.join(" ");
}
