import QtQuick

// Material shape library resampled for point-to-point morphing
QtObject {
    readonly property int count: 144
    readonly property var names: ["Circle", "Square", "Slanted", "Arch", "Fan", "Arrow", "SemiCircle", "Oval", "Pill",
        "Triangle", "Diamond", "ClamShell", "Pentagon", "Gem", "Sunny", "VerySunny", "Cookie4Sided", "Cookie6Sided",
        "Cookie7Sided", "Cookie9Sided", "Cookie12Sided", "Ghostish", "Clover4Leaf", "Clover8Leaf", "Burst", "SoftBurst",
        "Boom", "SoftBoom", "Flower", "Puffy", "PuffyDiamond", "PixelCircle", "PixelTriangle", "Bun", "Heart"]
    property var cache: ({})
    function get(n) { let c = cache[n]; if (!c) { c = build(n); cache[n] = c } return c }
    function polar(f) { const p = []; for (let i = 0; i < 540; i++) { const a = i / 540 * 2 * Math.PI; const r = f(a); p.push([r * Math.cos(a), r * Math.sin(a)]) } return p }
    function param(f) { const p = []; for (let i = 0; i < 540; i++) p.push(f(i / 540 * 2 * Math.PI)); return p }
    function regular(n, rot) { const v = []; for (let i = 0; i < n; i++) { const a = rot + i * 2 * Math.PI / n; v.push([Math.cos(a), Math.sin(a)]) } return v }
    function star(n, inner) { const v = []; for (let i = 0; i < 2 * n; i++) { const a = Math.PI / 2 + i * Math.PI / n; const r = (i % 2) ? inner : 1; v.push([r * Math.cos(a), r * Math.sin(a)]) } return v }
    function rotate(p, ang) { const c = Math.cos(ang), s = Math.sin(ang); return p.map(q => [q[0] * c - q[1] * s, q[0] * s + q[1] * c]) }
    function arc(cx, cy, r, a0, a1, n) { const p = []; for (let k = 0; k <= n; k++) { const a = a0 + (a1 - a0) * k / n; p.push([cx + r * Math.cos(a), cy + r * Math.sin(a)]) } return p }
    function zeros(n) { return new Array(n).fill(0) }
    function dedupe(p) {
        const o = []
        for (let i = 0; i < p.length; i++) {
            const q = p[i], l = o.length ? o[o.length - 1] : null
            if (!l || Math.hypot(q[0] - l[0], q[1] - l[1]) > 1e-6) o.push(q)
        }
        if (o.length > 1 && Math.hypot(o[0][0] - o[o.length - 1][0], o[0][1] - o[o.length - 1][1]) < 1e-6) o.pop()
        return o
    }
    function rounded(v, rr) {
        const n = v.length, out = []
        for (let i = 0; i < n; i++)
            _roundCorner(out, v[(i - 1 + n) % n], v[i], v[(i + 1) % n], Array.isArray(rr) ? rr[i] : rr)
        return out
    }
    function _roundCorner(out, p, c, q, r) {
        const ax = p[0] - c[0], ay = p[1] - c[1], bx = q[0] - c[0], by = q[1] - c[1]
        const la = Math.hypot(ax, ay), lb = Math.hypot(bx, by)
        if (la < 1e-9 || lb < 1e-9) return
        const ux = ax / la, uy = ay / la, wx = bx / lb, wy = by / lb
        const ang = Math.acos(Math.max(-1, Math.min(1, ux * wx + uy * wy)))
        if (r <= 0 || ang < 1e-3 || Math.PI - ang < 1e-3) { out.push([c[0], c[1]]); return }
        let t = r / Math.tan(ang / 2)
        const tmax = Math.min(la, lb) * 0.5
        if (t > tmax) { t = tmax; r = t * Math.tan(ang / 2) }
        const s = [c[0] + ux * t, c[1] + uy * t], e = [c[0] + wx * t, c[1] + wy * t]
        let bxx = ux + wx, byy = uy + wy
        const lbis = Math.hypot(bxx, byy); bxx /= lbis; byy /= lbis
        const d = r / Math.sin(ang / 2)
        const cx = c[0] + bxx * d, cy = c[1] + byy * d
        const a0 = Math.atan2(s[1] - cy, s[0] - cx), a1 = Math.atan2(e[1] - cy, e[0] - cx)
        let da = a1 - a0
        while (da > Math.PI) da -= 2 * Math.PI
        while (da < -Math.PI) da += 2 * Math.PI
        for (let k = 0; k <= 14; k++) { const a = a0 + da * k / 14; out.push([cx + r * Math.cos(a), cy + r * Math.sin(a)]) }
    }
    function pixels(widthAt) {
        const rows = 8, h = 2 / rows, right = [], left = []
        for (let j = 0; j < rows; j++) {
            const y0 = -1 + j * h, y1 = y0 + h, w = widthAt((y0 + y1) / 2)
            right.push([w, y0], [w, y1]); left.unshift([-w, y1], [-w, y0])
        }
        return dedupe(right.concat(left))
    }
    function q4(x) { return Math.max(0.25, Math.round(x / 0.25) * 0.25) }
    function resample(p, N) {
        p = dedupe(p)
        const n = p.length, L = [0]
        for (let i = 1; i <= n; i++) { const a = p[i - 1], b = p[i % n]; L.push(L[i - 1] + Math.hypot(b[0] - a[0], b[1] - a[1])) }
        const total = L[n], out = []
        let j = 0
        for (let k = 0; k < N; k++) {
            const tg = total * k / N
            while (j < n - 1 && L[j + 1] < tg) j++
            const seg = L[j + 1] - L[j], t = seg > 0 ? (tg - L[j]) / seg : 0
            const a = p[j], b = p[(j + 1) % n]
            out.push([a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t])
        }
        return out
    }
    function normalize(p) {
        let x0 = 1e9, x1 = -1e9, y0 = 1e9, y1 = -1e9
        for (const q of p) { x0 = Math.min(x0, q[0]); x1 = Math.max(x1, q[0]); y0 = Math.min(y0, q[1]); y1 = Math.max(y1, q[1]) }
        const cx = (x0 + x1) / 2, cy = (y0 + y1) / 2
        let s = 0
        for (const q of p) s = Math.max(s, Math.hypot(q[0] - cx, q[1] - cy))
        return p.map(q => [(q[0] - cx) / s, (q[1] - cy) / s])
    }
    function orient(p) {
        let area = 0
        for (let i = 0; i < p.length; i++) { const a = p[i], b = p[(i + 1) % p.length]; area += a[0] * b[1] - b[0] * a[1] }
        if (area < 0) p = p.slice().reverse()
        let best = 0, bd = 1e9
        for (let i = 0; i < p.length; i++) {
            let d = Math.abs(Math.atan2(p[i][1], p[i][0]) - Math.PI / 2)
            if (d > Math.PI) d = 2 * Math.PI - d
            if (d < bd) { bd = d; best = i }
        }
        return p.slice(best).concat(p.slice(0, best))
    }
    readonly property var _builders: ({
        Circle: () => polar(a => 1),
        Square: () => rounded([[-1, -1], [1, -1], [1, 1], [-1, 1]], 0.32),
        Slanted: () => rounded([[-1, -1], [0.72, -1], [1, 1], [-0.72, 1]], 0.3),
        Arch: () => rounded([[-1, -1], [1, -1]].concat(arc(0, 0, 1, 0, Math.PI, 16)), [0.3, 0.3].concat(zeros(17))),
        Fan: () => rounded([[-1, -1]].concat(arc(-1, -1, 2, 0, Math.PI / 2, 20)), [0.3, 0.3].concat(zeros(19)).concat([0.3])),
        Arrow: () => rounded([[0, 1], [-1, -0.95], [0, -0.5], [1, -0.95]], [0.28, 0.28, 0.18, 0.28]),
        SemiCircle: () => { const a = arc(0, -0.5, 1, 0, Math.PI, 16).slice(1, 16); return rounded([[-1, -0.5], [1, -0.5]].concat(a), [0.22, 0.22].concat(zeros(a.length))) },
        Oval: () => rotate(param(t => [Math.cos(t), 0.62 * Math.sin(t)]), Math.PI / 4),
        Pill: () => rotate(rounded([[-1, -0.48], [1, -0.48], [1, 0.48], [-1, 0.48]], 0.48), Math.PI / 4),
        Triangle: () => rounded(regular(3, Math.PI / 2), 0.3),
        Diamond: () => rounded([[0, 1], [-0.72, 0], [0, -1], [0.72, 0]], 0.24),
        ClamShell: () => rounded([[-1, 0], [-0.55, -0.78], [0.55, -0.78], [1, 0], [0.55, 0.78], [-0.55, 0.78]], 0.22),
        Pentagon: () => rounded(regular(5, Math.PI / 2), 0.26),
        Gem: () => rounded([[-0.45, 1], [-1, 0.25], [-0.5, -1], [0.5, -1], [1, 0.25], [0.45, 1]], 0.24),
        Sunny: () => rounded(star(8, 0.8), 0.13),
        VerySunny: () => rounded(star(8, 0.64), 0.1),
        Cookie4Sided: () => polar(a => 1 + 0.16 * Math.cos(4 * (a - Math.PI / 4))),
        Cookie6Sided: () => polar(a => 1 + 0.11 * Math.cos(6 * (a - Math.PI / 2))),
        Cookie7Sided: () => polar(a => 1 + 0.09 * Math.cos(7 * (a - Math.PI / 2))),
        Cookie9Sided: () => polar(a => 1 + 0.075 * Math.cos(9 * (a - Math.PI / 2))),
        Cookie12Sided: () => polar(a => 1 + 0.055 * Math.cos(12 * (a - Math.PI / 2))),
        Ghostish: () => rounded([[-1, -1], [-0.33, -0.72], [0.33, -1], [1, -0.72]].concat(arc(0, 0, 1, 0, Math.PI, 16)), [0.25, 0.18, 0.18, 0.25].concat(zeros(17))),
        Clover4Leaf: () => polar(a => 0.5 + 0.5 * Math.pow(Math.abs(Math.cos(2 * (a - Math.PI / 4))), 0.55)),
        Clover8Leaf: () => polar(a => 0.76 + 0.24 * Math.pow(Math.abs(Math.cos(4 * (a - Math.PI / 2))), 0.8)),
        Burst: () => rounded(star(12, 0.74), 0.03),
        SoftBurst: () => rounded(star(10, 0.74), 0.12),
        Boom: () => rounded(star(15, 0.56), 0.025),
        SoftBoom: () => rounded(star(16, 0.62), 0.09),
        Flower: () => polar(a => 0.6 + 0.4 * Math.pow(Math.abs(Math.cos(4 * (a - Math.PI / 2))), 0.38)),
        Puffy: () => polar(a => { const e = 1 / Math.sqrt(Math.pow(Math.cos(a), 2) + Math.pow(Math.sin(a) / 0.78, 2)); return e * (0.9 + 0.1 * Math.abs(Math.cos(5 * a))) }),
        PuffyDiamond: () => polar(a => 0.74 + 0.26 * Math.cos(4 * a)),
        PixelCircle: () => pixels(y => q4(Math.sqrt(Math.max(0, 1 - y * y)))),
        PixelTriangle: () => pixels(y => q4((1 - y) / 2)),
        Bun: () => polar(a => { const se = 1 / Math.pow(Math.pow(Math.abs(Math.cos(a)), 4) + Math.pow(Math.abs(Math.sin(a)) / 0.9, 4), 0.25); return se * (1 - 0.16 * Math.pow(Math.abs(Math.cos(a)), 12)) }),
        Heart: () => param(t => { const s = Math.sin(t); return [16 * s * s * s, 13 * Math.cos(t) - 5 * Math.cos(2 * t) - 2 * Math.cos(3 * t) - Math.cos(4 * t)] }),
    })
    function raw(n) { const f = _builders[n]; return f ? f() : polar(a => 1) }
    function build(n) { return orient(resample(normalize(raw(n)), count)) }
    function draw(ctx, a, b, t, cx, cy, s, rotDeg) {
        const A = get(a), B = get(b), N = A.length
        const ang = -rotDeg * Math.PI / 180, cr = Math.cos(ang), sr = Math.sin(ang)
        ctx.beginPath()
        for (let i = 0; i < N; i++) {
            const x = A[i][0] + (B[i][0] - A[i][0]) * t, y = A[i][1] + (B[i][1] - A[i][1]) * t
            const X = cx + s * (x * cr - y * sr), Y = cy - s * (x * sr + y * cr)
            if (i === 0) ctx.moveTo(X, Y); else ctx.lineTo(X, Y)
        }
        ctx.closePath()
    }
}
