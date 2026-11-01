import QtQuick
import "../ui"

// Spring response plot for the current motion tokens
Canvas {
    id: esp
    property string token: "spatialDefault"
    property color line: m3.primary
    property real span: 0.9
    property real marker: -1
    readonly property real sk: m3.sk(token)
    readonly property real sz: m3.sz(token)
    onSkChanged: requestPaint()
    onSzChanged: requestPaint()
    onLineChanged: requestPaint()
    onMarkerChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    function resp(t) {
        const k = sk, z = sz
        const w = Math.sqrt(k)
        if (z >= 0.999) return 1 - Math.exp(-w * t) * (1 + w * t)
        const wd = w * Math.sqrt(1 - z * z)
        return 1 - Math.exp(-z * w * t) * (Math.cos(wd * t) + z / Math.sqrt(1 - z * z) * Math.sin(wd * t))
    }
    onPaint: {
        const ctx = getContext("2d"); ctx.reset()
        const m = 8, W = width - 2 * m, H = height - 2 * m
        const X = t => m + t / span * W, Y = v => m + H * (1 - v / 1.35)
        ctx.lineWidth = 1; ctx.strokeStyle = m3.css(m3.alpha(m3.inkSurfaceVariant, 0.25))
        ctx.setLineDash([4, 4]); ctx.beginPath(); ctx.moveTo(m, Y(1)); ctx.lineTo(m + W, Y(1)); ctx.stroke()
        ctx.setLineDash([]); ctx.beginPath(); ctx.moveTo(m, Y(0)); ctx.lineTo(m + W, Y(0)); ctx.stroke()
        ctx.lineWidth = 3; ctx.lineCap = "round"; ctx.strokeStyle = m3.css(line); ctx.beginPath()
        for (let i = 0; i <= 120; i++) { const t = span * i / 120; const v = resp(t); if (i === 0) ctx.moveTo(X(t), Y(v)); else ctx.lineTo(X(t), Y(v)) }
        ctx.stroke()
        if (marker >= 0 && marker <= span) { ctx.fillStyle = m3.css(m3.tertiary); ctx.beginPath(); ctx.arc(X(marker), Y(resp(marker)), 6, 0, 2 * Math.PI); ctx.fill() }
    }
}
