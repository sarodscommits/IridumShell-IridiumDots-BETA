import QtQuick

// Wavy linear progress; flattens near 0% and 100%
Canvas {
    id: ewl
    property real value: 0.5
    property bool wavy: true
    property bool indeterminate: false
    property real thickness: m3.progressThickness
    property real amplitude: 3
    property real wavelength: 40
    property color active: m3.primary
    property color track: m3.secondaryContainer
    property real phase: 0
    property real spin: 0
    property bool animateValue: true
    property bool showHandle: false        // wavy slider handle
    property real handleH: 20
    property color handleColor: active
    property bool running: true            // false = frozen wave
    Spring { id: ewlA; token: "effectsDefault"; target: (ewl.wavy && m3.wavy && (ewl.indeterminate || (ewl.value > 0.02 && ewl.value < 0.98))) ? 1 : 0 }
    Spring { id: ewlV; token: "spatialDefault"; target: ewl.value }
    readonly property real shownV: animateValue ? ewlV.value : value
    readonly property real ampV: ewlA.value
    NumberAnimation on phase { from: 0; to: Math.PI * 2; duration: 1000; loops: Animation.Infinite; running: ewl.running && ewl.visible && ((ewl.wavy && ewl.ampV > 0.01) || ewl.indeterminate) }
    NumberAnimation on spin { from: 0; to: 1; duration: 1750; loops: Animation.Infinite; running: ewl.visible && ewl.indeterminate }
    implicitHeight: thickness + amplitude * 2 + 4
    implicitWidth: 240
    // Repaint on any input change
    readonly property var _paintKey: [shownV, ampV, phase, width, active, track, handleColor]
    on_PaintKeyChanged: requestPaint()
    function _wave(ctx, a, b, y, A) {
        if (b - a < 0.5) return
        ctx.strokeStyle = m3.css(active); ctx.beginPath()
        for (let x = a; x <= b; x += 1.5) { const yy = y + A * Math.sin(2 * Math.PI * x / wavelength - phase); if (x === a) ctx.moveTo(x, yy); else ctx.lineTo(x, yy) }
        ctx.lineTo(b, y + A * Math.sin(2 * Math.PI * b / wavelength - phase)); ctx.stroke()
    }
    function _flat(ctx, a, b, y) {
        if (b - a < 0.5) return
        ctx.strokeStyle = m3.css(track); ctx.beginPath(); ctx.moveTo(a, y); ctx.lineTo(b, y); ctx.stroke()
    }
    function _paintIndeterminate(ctx, y, x0, x1, A, gap) {
        const p = spin * 1.6, W = x1 - x0
        const a = x0 + W * Math.max(0, Math.min(1, p - 0.55)), b = x0 + W * Math.max(0, Math.min(1, p))
        _flat(ctx, x0, a - gap, y); _wave(ctx, a, b, y, A); _flat(ctx, b + gap, x1, y)
    }
    function _paintValue(ctx, y, x0, x1, A, gap) {
        const v = Math.max(0, Math.min(1, shownV)), ax = x0 + (x1 - x0) * v
        if (showHandle) {
            const hg = gap + 2
            if (v > 0.001) _wave(ctx, x0, ax - hg, y, A)
            _flat(ctx, ax + hg, x1, y)
            ctx.fillStyle = m3.css(handleColor)
            // Full rounded rect (a partial path left a diagonal artifact)
            const hw = 4, hh = Math.max(hw, Math.min(height, handleH)), hx = ax - hw / 2, hy = y - hh / 2
            ctx.beginPath(); ctx.roundedRect(hx, hy, hw, hh, hw / 2, hw / 2); ctx.fill()
        } else {
            if (v > 0.001) _wave(ctx, x0, ax, y, A)
            _flat(ctx, v > 0.001 ? ax + gap : x0, x1, y)
        }
        if (v < 0.995) { ctx.fillStyle = m3.css(active); ctx.beginPath(); ctx.arc(x1, y, thickness / 2, 0, 2 * Math.PI); ctx.fill() }
    }
    onPaint: {
        const ctx = getContext("2d"); ctx.reset()
        const y = height / 2, x0 = thickness / 2, x1 = width - thickness / 2
        const A = amplitude * ampV, gap = 4 + thickness
        ctx.lineCap = "round"; ctx.lineWidth = thickness
        if (indeterminate) _paintIndeterminate(ctx, y, x0, x1, A, gap)
        else _paintValue(ctx, y, x0, x1, A, gap)
    }
}
