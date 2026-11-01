import QtQuick

// Library shape morphing from → to (t may overshoot [0,1])
Canvas {
    id: msv
    property string from: "Circle"
    property string to: "Circle"
    property real t: 1
    property real rot: 0
    property real inset: 0.92
    property color fill: m3.primary
    property color fill2: "transparent"
    property color stroke: "transparent"
    property real strokeWidth: 2
    implicitWidth: 64
    implicitHeight: 64
    // Repaint on any input change
    readonly property var _paintKey: [from, to, t, rot, fill, fill2, stroke, width, height]
    on_PaintKeyChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        if (width <= 0 || height <= 0) return
        const s = Math.min(width, height) / 2 * inset
        m3shp.draw(ctx, from, to, t, width / 2, height / 2, s, rot)
        if (fill2.a > 0) {
            const g = ctx.createLinearGradient(0, 0, width, height)
            g.addColorStop(0, m3.css(fill)); g.addColorStop(1, m3.css(fill2))
            ctx.fillStyle = g
        } else ctx.fillStyle = m3.css(fill)
        if (fill.a > 0 || fill2.a > 0) ctx.fill()
        if (stroke.a > 0) { ctx.lineWidth = strokeWidth; ctx.strokeStyle = m3.css(stroke); ctx.stroke() }
    }
}
