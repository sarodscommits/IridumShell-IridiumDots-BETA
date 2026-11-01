import QtQuick

// Wavy circular progress
Canvas {
    id: ewc
    property real value: 0.6
    property bool wavy: true
    property bool indeterminate: false
    property real thickness: m3.progressThickness
    property real amplitude: 1.6
    property real wavelength: 15
    property color active: m3.primary
    property color track: m3.secondaryContainer
    property real phase: 0
    property real spin: 0
    Spring { id: ewcA; token: "effectsDefault"; target: (ewc.wavy && m3.wavy && (ewc.indeterminate || (ewc.value > 0.03 && ewc.value < 0.97))) ? 1 : 0 }
    Spring { id: ewcV; token: "spatialDefault"; target: ewc.value }
    readonly property real shownV: ewcV.value
    readonly property real ampV: ewcA.value
    NumberAnimation on phase { from: 0; to: Math.PI * 2; duration: 1100; loops: Animation.Infinite; running: ewc.visible && ((ewc.wavy && ewc.ampV > 0.01) || ewc.indeterminate) }
    NumberAnimation on spin { from: 0; to: 1; duration: 2000; loops: Animation.Infinite; running: ewc.visible && ewc.indeterminate }
    implicitWidth: 48; implicitHeight: 48
    // Repaint on any input change
    readonly property var _paintKey: [shownV, ampV, phase, active, track, width]
    on_PaintKeyChanged: requestPaint()
    // [start, end] of the active arc
    function _arcRange() {
        if (!indeterminate) {
            const s = -Math.PI / 2
            return [s, s + 2 * Math.PI * Math.max(0, Math.min(1, shownV))]
        }
        const p = spin
        const len = 0.08 + 0.55 * (0.5 - 0.5 * Math.cos(p * 4 * Math.PI))
        const s = -Math.PI / 2 + p * 2 * Math.PI * 2.0 + Math.sin(p * 4 * Math.PI) * 0.6
        return [s, s + len * 2 * Math.PI]
    }
    function _wavyArc(ctx, cx, cy, R, A, s, e) {
        const waves = Math.max(5, Math.round(2 * Math.PI * R / wavelength))
        const steps = Math.max(10, Math.ceil((e - s) * R / 1.5))
        ctx.strokeStyle = m3.css(active); ctx.beginPath()
        for (let i = 0; i <= steps; i++) {
            const a = s + (e - s) * i / steps
            const r = R + A * Math.sin(waves * a - phase)
            const x = cx + r * Math.cos(a), y = cy + r * Math.sin(a)
            if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y)
        }
        ctx.stroke()
    }
    onPaint: {
        const ctx = getContext("2d"); ctx.reset()
        const cx = width / 2, cy = height / 2
        const R = Math.min(width, height) / 2 - thickness / 2 - amplitude
        if (R <= 1) return
        ctx.lineCap = "round"; ctx.lineWidth = thickness
        const se = _arcRange(), s = se[0], e = se[1]
        if (!indeterminate) {
            const gapA = (thickness + 4) / R
            const ts = e + gapA, te = s + 2 * Math.PI - gapA
            if (te > ts) { ctx.strokeStyle = m3.css(track); ctx.beginPath(); ctx.arc(cx, cy, R, ts, te, false); ctx.stroke() }
        }
        if (e - s > 0.001) _wavyArc(ctx, cx, cy, R, amplitude * ampV, s, e)
    }
}
