import QtQuick
import "../ui"

// Thick round-capped progress ring
Canvas {
    id: dwr
    property real value: 0
    property real thickness: 14
    property color color: m3.primary
    property color track: "transparent"
    property real gapDeg: 0
    Behavior on value { M3SpringAnim { token: "spatialSlow"; epsilon: 0.002 } }
    onValueChanged: requestPaint()
    onThicknessChanged: requestPaint()
    onColorChanged: requestPaint()
    onTrackChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const r = Math.min(width, height) / 2 - thickness / 2
        if (r <= 0) return
        const cx = width / 2, cy = height / 2, a0 = -Math.PI / 2
        ctx.lineCap = "round"
        ctx.lineWidth = thickness
        if (track.a > 0) {
            ctx.beginPath(); ctx.arc(cx, cy, r, 0, 2 * Math.PI)
            ctx.strokeStyle = m3.css(track); ctx.stroke()
        }
        const v = Math.max(0, Math.min(1, value))
        if (v > 0.001) {
            ctx.beginPath(); ctx.arc(cx, cy, r, a0, a0 + v * 2 * Math.PI * (v >= 0.999 ? 1 : 0.985))
            ctx.strokeStyle = m3.css(color); ctx.stroke()
        }
    }
}
