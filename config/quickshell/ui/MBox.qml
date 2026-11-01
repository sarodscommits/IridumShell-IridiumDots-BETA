import QtQuick

// Library shape fitted to the item's box; optional bottom band (split) and stroke
Canvas {
    id: mbx
    property string from: "Circle"
    property string to: from
    property real t: 1
    property real rot: 0                 // degrees, applied before fitting
    property bool keepAspect: true
    property real pad: 0
    property color fill: m3.primary
    property real split: -1
    property color fill2: "transparent"
    property color stroke: "transparent"
    property real strokeWidth: 2
    implicitWidth: 64
    implicitHeight: 64
    // Repaint on any input change
    readonly property var _paintKey: [from, to, t, rot, keepAspect, fill, fill2, split, stroke, width, height]
    on_PaintKeyChanged: requestPaint()
    function _morphPoints() {
        const A = m3shp.get(from), B = m3shp.get(to), N = A.length
        const ang = rot * Math.PI / 180, cr = Math.cos(ang), sr = Math.sin(ang)
        const P = new Array(N)
        let x0 = 1e9, x1 = -1e9, y0 = 1e9, y1 = -1e9
        for (let i = 0; i < N; i++) {
            const x = A[i][0] + (B[i][0] - A[i][0]) * t, y = A[i][1] + (B[i][1] - A[i][1]) * t
            const X = x * cr - y * sr, Y = -(x * sr + y * cr)
            P[i] = [X, Y]
            if (X < x0) x0 = X; if (X > x1) x1 = X
            if (Y < y0) y0 = Y; if (Y > y1) y1 = Y
        }
        return { P: P, x0: x0, x1: x1, y0: y0, y1: y1 }
    }
    function _tracePath(ctx, m, sw) {
        const w = Math.max(1, width - 2 * pad - sw), h = Math.max(1, height - 2 * pad - sw)
        const bw = Math.max(1e-6, m.x1 - m.x0), bh = Math.max(1e-6, m.y1 - m.y0)
        let kx = w / bw, ky = h / bh
        if (keepAspect) { const k = Math.min(kx, ky); kx = k; ky = k }
        const ox = width / 2 - (m.x0 + bw / 2) * kx, oy = height / 2 - (m.y0 + bh / 2) * ky
        ctx.beginPath()
        for (let i = 0; i < m.P.length; i++) {
            const X = ox + m.P[i][0] * kx, Y = oy + m.P[i][1] * ky
            if (i === 0) ctx.moveTo(X, Y); else ctx.lineTo(X, Y)
        }
        ctx.closePath()
    }
    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        if (width <= 1 || height <= 1) return
        const sw = stroke.a > 0 ? strokeWidth : 0
        _tracePath(ctx, _morphPoints(), sw)
        if (fill.a > 0) { ctx.fillStyle = m3.css(fill); ctx.fill() }
        if (split >= 0 && fill2.a > 0) {
            ctx.save(); ctx.clip()
            ctx.fillStyle = m3.css(fill2)
            ctx.fillRect(0, height * split, width, height)
            ctx.restore()
        }
        if (sw > 0) { ctx.lineWidth = sw; ctx.strokeStyle = m3.css(stroke); ctx.stroke() }
    }
}
