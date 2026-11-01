// MusicPlayer.qml — music player; disk work in scripts/music_backend.py
import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes
import QtQuick.Effects
import QtMultimedia
import Quickshell
import Quickshell.Io
import "i18n/apps.js" as AppStrings

Window {
    id: mp
    property var gs
    property var colors

    title: tx("Música", "Music")
    visible: gs ? gs.musicPlayerOpen : true
    color: "transparent"
    width: 1260
    height: 800
    minimumWidth: 880
    minimumHeight: 560

    onClosing: (close) => { if (mp.gs) mp.gs.musicPlayerOpen = false; }
    onVisibleChanged: {
        if (!visible && gs && gs.musicPlayerOpen) gs.musicPlayerOpen = false;
        if (visible) { takeExternal(); Qt.callLater(mp.refocus); }
    }

    // ── style ──
    readonly property bool   glass: gs ? gs.glassMode : false
    readonly property bool   light: gs ? gs.colorMode === "light" : false
    readonly property real   fs:    gs ? gs.fontScale : 1
    readonly property string fontA: gs ? gs.fontPrimary : "sans-serif"
    readonly property string fontB: gs ? gs.fontSecondary : "sans-serif"
    readonly property string lang:  gs ? gs.language : "es"

    readonly property color cPrimary:   colors ? colors.primary         : "#D0BCFF"
    readonly property color cOnPrimary: colors ? colors.colorOnPrimary  : "#381E72"
    readonly property color cPrimCont:  colors ? colors.primaryCont     : "#4F378B"
    readonly property color cSurface:   colors ? colors.surface         : "#1C1B1F"
    readonly property color cSurfElev:  colors ? colors.surfaceElevated : "#2A2535"
    readonly property color cSurfHigh:  colors ? colors.surfaceHigh     : "#332E45"
    readonly property color cSurfPop:   colors ? colors.surfacePop      : "#3D3655"
    readonly property color cSurfVar:   colors ? colors.surfaceVar      : "#49454F"
    readonly property color cOnSurface: colors ? colors.colorOnSurface  : "#E6E1E5"
    readonly property color cOnSurfVar: colors ? colors.colorOnSurfVar  : "#CAC4D0"
    readonly property color cMuted:     colors ? colors.muted           : "#8E8A93"
    readonly property color cMutedDeep: colors ? colors.mutedDeep       : "#49454F"
    readonly property color cSecCont:   colors ? colors.secondaryCont   : "#4A4458"
    readonly property color cTertiary:  colors ? colors.tertiary        : "#EFB8C8"
    readonly property color cAccent:    colors ? colors.accent          : "#CCC2DC"
    readonly property color cError:     colors ? colors.error           : "#F2B8B5"
    readonly property color cPositive:  colors ? colors.positive        : "#A8D8A8"

    readonly property color bgWindow:  glass ? ga(m3Cont, 0.6) : m3Cont
    // full-screen lyrics background: darkest palette color
    function lumOf(c) { if (typeof c === "string") c = Qt.tint(c, "transparent"); return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b; }
    readonly property color cDarkest: {
        var cs = [cSurface, cSurfElev, cSurfHigh, cSurfPop, cSurfVar, cPrimCont, cSecCont, cMutedDeep];
        if (!light) cs = cs.concat([cOnPrimary, cPrimary, cTertiary, cAccent, cMuted]);
        var best = cs[0], bl = lumOf(cs[0]);
        for (var i = 1; i < cs.length; i++) { var l = lumOf(cs[i]); if (l < bl) { bl = l; best = cs[i]; } }
        return best;
    }
    readonly property color bgLyrFull: glass ? ga(cDarkest, 0.82) : cDarkest
    readonly property color bgSide:    "transparent"
    readonly property color bgCont:    glass ? ga(m3Low, 0.7) : m3Low
    readonly property color bgField:   m3Highest
    readonly property color bgPop:     m3High
    readonly property color lineCol:   ga(m3OutlineVar, 0.7)
    readonly property color hovCol:    ga(cOnSurface, 0.08)
    readonly property color selCol:    m3SecCont
    readonly property color trackCol:  m3High

    function ga(c, a) { if (typeof c === "string") c = Qt.tint(c, "transparent"); return Qt.rgba(c.r, c.g, c.b, a); }
    function cdark(c) { return light ? c : Qt.darker(c, 1.85); }
    function px(n) { return Math.round(n * fs); }
    // es at the call site; en is the fallback and lookup key
    function tx(es, en) {
        if (lang === "es") return es;
        var base = en !== undefined ? en : es;
        if (lang === "en") return base;
        var entry = AppStrings.strings[base];
        return (entry && entry[lang]) || base;
    }

    // ── M3 roles from the shell palette ──
    function mixc(a, b, t) { if (typeof a === "string") a = Qt.tint(a, "transparent"); if (typeof b === "string") b = Qt.tint(b, "transparent"); return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t); }
    function css(c) { return "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + "," + c.a.toFixed(3) + ")"; }
    readonly property color m3Lowest:   light ? mixc(cSurface, "#ffffff", 0.7) : Qt.darker(cSurface, 1.3)
    readonly property color m3Low:      mixc(mixc(cSurface, cOnSurface, light ? 0.025 : 0.035), cPrimary, 0.015)
    readonly property color m3Cont:     mixc(mixc(cSurface, cOnSurface, light ? 0.045 : 0.06), cPrimary, 0.02)
    readonly property color m3High:     mixc(mixc(cSurface, cOnSurface, light ? 0.065 : 0.095), cPrimary, 0.02)
    readonly property color m3Highest:  mixc(mixc(cSurface, cOnSurface, light ? 0.09 : 0.135), cPrimary, 0.02)
    readonly property color m3OnPrimCont: light ? mixc(cPrimary, "#000000", 0.6) : mixc(cPrimary, "#ffffff", 0.55)
    readonly property color m3SecCont:  cSecCont
    readonly property color m3OnSecCont: light ? mixc(cOnSurface, cPrimary, 0.25) : mixc(cOnSurface, cPrimary, 0.15)
    readonly property color m3TerCont:  mixc(cSurface, cTertiary, light ? 0.3 : 0.32)
    readonly property color m3OnTerCont: light ? mixc(cTertiary, "#000000", 0.6) : mixc(cTertiary, "#ffffff", 0.55)
    readonly property color m3OnError:  Qt.darker(cError, 3)
    readonly property color m3ErrCont:  mixc(cSurface, cError, light ? 0.25 : 0.3)
    readonly property color m3OnErrCont: light ? mixc(cError, "#000000", 0.55) : mixc(cError, "#ffffff", 0.55)
    readonly property color m3InvSurf:  cOnSurface
    readonly property color m3InvOnSurf: cSurface
    readonly property color m3Outline:  cMuted
    readonly property color m3OutlineVar: mixc(cSurface, cOnSurface, light ? 0.2 : 0.22)
    readonly property color bgPane:     glass ? ga(cSurface, 0.55) : cSurface

    // M3 type scale: [size, line height, base weight]
    readonly property var typeScale: ({
        displayLarge: [57, 64, 400], displayMedium: [45, 52, 400], displaySmall: [36, 44, 400],
        headlineLarge: [32, 40, 400], headlineMedium: [28, 36, 400], headlineSmall: [24, 32, 400],
        titleLarge: [22, 28, 400], titleMedium: [16, 24, 500], titleSmall: [14, 20, 500],
        bodyLarge: [16, 24, 400], bodyMedium: [14, 20, 400], bodySmall: [12, 16, 400],
        labelLarge: [14, 20, 500], labelMedium: [12, 16, 500], labelSmall: [11, 16, 500]
    })
    // "Emphasized": heavier version of each role
    function tw(role, emph) { var b = typeScale[role][2]; return emph ? (b >= 500 ? 700 : 600) : b; }

    // Spring tokens (stiffness, damping) — Expressive motion scheme
    readonly property var springTok: ({
        spatialFast: [800, 0.6], spatialDefault: [380, 0.8], spatialSlow: [200, 0.8],
        effectsFast: [3800, 1.0], effectsDefault: [1600, 1.0], effectsSlow: [800, 1.0]
    })
    function sk(tok) { return springTok[tok][0]; }
    function sz(tok) { return springTok[tok][1]; }

    // Material 3 Expressive shape library (approx.), with point-to-point morphing
    QtObject {
        id: shp
        readonly property int count: 180
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
        // Polygon with rounded corners (radius per vertex)
        function rounded(v, rr) {
            const n = v.length, out = []
            for (let i = 0; i < n; i++) {
                const p = v[(i - 1 + n) % n], c = v[i], q = v[(i + 1) % n]
                let r = Array.isArray(rr) ? rr[i] : rr
                const ax = p[0] - c[0], ay = p[1] - c[1], bx = q[0] - c[0], by = q[1] - c[1]
                const la = Math.hypot(ax, ay), lb = Math.hypot(bx, by)
                if (la < 1e-9 || lb < 1e-9) continue
                const ux = ax / la, uy = ay / la, wx = bx / lb, wy = by / lb
                const ang = Math.acos(Math.max(-1, Math.min(1, ux * wx + uy * wy)))
                if (r <= 0 || ang < 1e-3 || Math.PI - ang < 1e-3) { out.push([c[0], c[1]]); continue }
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
            return out
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
            // Scale by the max radius so any rotation fits the unit circle
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
        function raw(n) {
            const P = Math.PI
            switch (n) {
            case "Circle": return polar(a => 1)
            case "Square": return rounded([[-1, -1], [1, -1], [1, 1], [-1, 1]], 0.32)
            case "Slanted": return rounded([[-1, -1], [0.72, -1], [1, 1], [-0.72, 1]], 0.3)
            case "Arch": return rounded([[-1, -1], [1, -1]].concat(arc(0, 0, 1, 0, P, 16)), [0.3, 0.3].concat(zeros(17)))
            case "Fan": return rounded([[-1, -1]].concat(arc(-1, -1, 2, 0, P / 2, 20)), [0.3, 0.3].concat(zeros(19)).concat([0.3]))
            case "Arrow": return rounded([[0, 1], [-1, -0.95], [0, -0.5], [1, -0.95]], [0.28, 0.28, 0.18, 0.28])
            case "SemiCircle": { const a = arc(0, -0.5, 1, 0, P, 16).slice(1, 16); return rounded([[-1, -0.5], [1, -0.5]].concat(a), [0.22, 0.22].concat(zeros(a.length))) }
            case "Oval": return rotate(param(t => [Math.cos(t), 0.62 * Math.sin(t)]), P / 4)
            case "Pill": return rotate(rounded([[-1, -0.48], [1, -0.48], [1, 0.48], [-1, 0.48]], 0.48), P / 4)
            case "Triangle": return rounded(regular(3, P / 2), 0.3)
            case "Diamond": return rounded([[0, 1], [-0.72, 0], [0, -1], [0.72, 0]], 0.24)
            case "ClamShell": return rounded([[-1, 0], [-0.55, -0.78], [0.55, -0.78], [1, 0], [0.55, 0.78], [-0.55, 0.78]], 0.22)
            case "Pentagon": return rounded(regular(5, P / 2), 0.26)
            case "Gem": return rounded([[-0.45, 1], [-1, 0.25], [-0.5, -1], [0.5, -1], [1, 0.25], [0.45, 1]], 0.24)
            case "Sunny": return rounded(star(8, 0.8), 0.13)
            case "VerySunny": return rounded(star(8, 0.64), 0.1)
            case "Cookie4Sided": return polar(a => 1 + 0.16 * Math.cos(4 * (a - P / 4)))
            case "Cookie6Sided": return polar(a => 1 + 0.11 * Math.cos(6 * (a - P / 2)))
            case "Cookie7Sided": return polar(a => 1 + 0.09 * Math.cos(7 * (a - P / 2)))
            case "Cookie9Sided": return polar(a => 1 + 0.075 * Math.cos(9 * (a - P / 2)))
            case "Cookie12Sided": return polar(a => 1 + 0.055 * Math.cos(12 * (a - P / 2)))
            case "Ghostish": return rounded([[-1, -1], [-0.33, -0.72], [0.33, -1], [1, -0.72]].concat(arc(0, 0, 1, 0, P, 16)), [0.25, 0.18, 0.18, 0.25].concat(zeros(17)))
            case "Clover4Leaf": return polar(a => 0.5 + 0.5 * Math.pow(Math.abs(Math.cos(2 * (a - P / 4))), 0.55))
            case "Clover8Leaf": return polar(a => 0.76 + 0.24 * Math.pow(Math.abs(Math.cos(4 * (a - P / 2))), 0.8))
            case "Burst": return rounded(star(12, 0.74), 0.03)
            case "SoftBurst": return rounded(star(10, 0.74), 0.12)
            case "Boom": return rounded(star(15, 0.56), 0.025)
            case "SoftBoom": return rounded(star(16, 0.62), 0.09)
            case "Flower": return polar(a => 0.6 + 0.4 * Math.pow(Math.abs(Math.cos(4 * (a - P / 2))), 0.38))
            case "Puffy": return polar(a => { const e = 1 / Math.sqrt(Math.pow(Math.cos(a), 2) + Math.pow(Math.sin(a) / 0.78, 2)); return e * (0.9 + 0.1 * Math.abs(Math.cos(5 * a))) })
            case "PuffyDiamond": return polar(a => 0.74 + 0.26 * Math.cos(4 * a))
            case "PixelCircle": return pixels(y => q4(Math.sqrt(Math.max(0, 1 - y * y))))
            case "PixelTriangle": return pixels(y => q4((1 - y) / 2))
            case "Bun": return polar(a => { const se = 1 / Math.pow(Math.pow(Math.abs(Math.cos(a)), 4) + Math.pow(Math.abs(Math.sin(a)) / 0.9, 4), 0.25); return se * (1 - 0.16 * Math.pow(Math.abs(Math.cos(a)), 12)) })
            case "Heart": return param(t => { const s = Math.sin(t); return [16 * s * s * s, 13 * Math.cos(t) - 5 * Math.cos(2 * t) - 2 * Math.cos(3 * t) - Math.cos(4 * t)] })
            }
            return polar(a => 1)
        }
        function build(n) { return orient(resample(normalize(raw(n)), count)) }
        // Traces the a→b interpolation (t may overshoot [0,1])
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

    // ───────────────────────── utilities ─────────────────────────
    function fmtTime(s) {
        s = Math.max(0, Math.floor(s || 0));
        var h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60), x = s % 60;
        return (h > 0 ? h + ":" + (m < 10 ? "0" : "") : "") + m + ":" + (x < 10 ? "0" : "") + x;
    }
    function fmtLong(s) {
        s = Math.round(s || 0);
        var h = Math.floor(s / 3600), m = Math.round((s % 3600) / 60);
        if (h > 0) return h + " h " + m + " min";
        return m + " min";
    }
    function fmtSize(b) {
        if (!b || b < 0) return "—";
        var u = ["B", "KB", "MB", "GB"], i = 0;
        while (b >= 1024 && i < u.length - 1) { b /= 1024; i++; }
        return (b >= 100 || i === 0 ? b.toFixed(0) : b.toFixed(1)) + " " + u[i];
    }
    function nSongs(n, one, many) { return songsLabel(n) + " " + (n === 1 ? one : many); }
    function songsLabel(n) { return n === 1 ? tx("1 canción", "1 song") : n + " " + tx("canciones", "songs"); }
    function fileUrl(p) { return p ? "file://" + p.split("/").map(encodeURIComponent).join("/") : ""; }
    function urlToPath(u) {
        var s = u.toString();
        if (s.indexOf("file://") !== 0) return "";
        s = s.substring(7);
        if (s.charAt(0) !== "/") s = s.substring(s.indexOf("/"));
        try { return decodeURIComponent(s); } catch (e) { return s; }
    }
    function baseName(p) { var s = (p || "").replace(/\/+$/, ""); return s.substring(s.lastIndexOf("/") + 1); }
    function dirName(p) { var s = (p || "").replace(/\/+$/, ""); var i = s.lastIndexOf("/"); return i <= 0 ? "/" : s.substring(0, i); }
    function prettyPath(p) { return home && p && (p === home || p.indexOf(home + "/") === 0) ? "~" + p.substring(home.length) : p; }
    function extOf(p) { var b = baseName(p); var i = b.lastIndexOf("."); return i > 0 ? b.substring(i + 1).toLowerCase() : ""; }
    readonly property var audioExts: ["mp3", "flac", "m4a", "mp4", "aac", "alac", "ogg", "oga", "opus", "wav", "aif", "aiff", "wma", "ape", "wv", "mpc"]
    function isAudio(p) { return audioExts.indexOf(extOf(p)) >= 0; }
    function isImage(p) { return ["jpg", "jpeg", "png", "webp", "bmp"].indexOf(extOf(p)) >= 0; }
    function isPlaylistFile(p) { return ["m3u", "m3u8"].indexOf(extOf(p)) >= 0; }
    function artistOf(t) { return t ? (t.ar || t.aa || tx("Artista desconocido", "Unknown artist")) : ""; }
    function albumArtistOf(t) { return t ? (t.aa || t.ar || tx("Artista desconocido", "Unknown artist")) : ""; }
    function shuffled(a) {
        a = a.slice();
        for (var i = a.length - 1; i > 0; i--) { var j = Math.floor(Math.random() * (i + 1)); var x = a[i]; a[i] = a[j]; a[j] = x; }
        return a;
    }
    function uid() { return Date.now().toString(36) + Math.floor(Math.random() * 1e6).toString(36); }

    // ───────────────────────── backend ─────────────────────────
    readonly property string backendPath: {
        var u = Qt.resolvedUrl("scripts/music_backend.py").toString();
        return u.indexOf("file://") === 0 ? decodeURIComponent(u.substring(7)) : u;
    }
    property int  _rid: 0
    property bool _ready: false
    property var  _queue: []
    property var  _cbs: ({})
    property var  _evs: ({})

    Process {
        id: backend
        command: ["python3", "-u", mp.backendPath]
        running: true
        stdinEnabled: true
        stdout: SplitParser { onRead: (data) => mp._onLine(data) }
        stderr: SplitParser { onRead: (data) => console.warn("[music_backend] " + data) }
        onStarted: {
            mp._ready = true;
            var q = mp._queue;
            mp._queue = [];
            for (var i = 0; i < q.length; i++) backend.write(q[i]);
        }
        onExited: (code, status) => {
            mp._ready = false;
            var cbs = mp._cbs;
            mp._cbs = ({});
            mp._evs = ({});
            for (var k in cbs) { try { cbs[k](false, "backend reiniciado"); } catch (e) {} }
            backendRestart.start();
        }
    }
    Timer { id: backendRestart; interval: 900; onTriggered: { backend.running = true; mp.mprisPush(true); } }

    function call(cmd, args, cb, onEv) {
        var id = ++_rid;
        if (cb) _cbs[id] = cb;
        if (onEv) _evs[id] = onEv;
        var line = JSON.stringify({ id: id, cmd: cmd, args: args || {} }) + "\n";
        if (_ready) backend.write(line); else _queue.push(line);
        return id;
    }
    function _onLine(l) {
        var o;
        try { o = JSON.parse(l); } catch (e) { return; }
        if (o.event !== undefined) {
            if (o.event === "mpris") onMpris(o);
            else { var f = _evs[o.id]; if (f) f(o); }
            return;
        }
        var cb = _cbs[o.id];
        delete _cbs[o.id];
        delete _evs[o.id];
        if (cb) cb(o.ok, o.ok ? o.data : o.error);
        else if (!o.ok) toast(o.error, true);
    }

    // ───────────────────────── notices / tooltips ─────────────────────────
    property string toastText: ""
    property bool   toastErr: false
    function toast(t, err) { toastText = String(t); toastErr = !!err; toastTimer.restart(); }
    Timer { id: toastTimer; interval: 3800; onTriggered: mp.toastText = "" }

    property string tipText: ""
    property var    tipItem: null
    property bool   tipShown: false
    property real   tipX: 0
    property real   tipY: 0
    function showTip(t, item) { tipItem = item; tipText = t; tipShown = false; tipTimer.restart(); }
    function hideTip(item) {
        if (item && item !== tipItem) return;
        tipTimer.stop(); tipShown = false; tipItem = null;
    }
    Timer {
        id: tipTimer
        interval: 550
        onTriggered: {
            if (!mp.tipItem) return;
            var g = mp.tipItem.mapToItem(null, mp.tipItem.width / 2, mp.tipItem.height + 6);
            mp.tipX = g.x; mp.tipY = g.y; mp.tipShown = true;
        }
    }
    readonly property real wheelStep: px(150)

    // ───────────────────────── general state ─────────────────────────
    property string home: ""
    property string musicDir: ""
    property bool   hasMutagen: true
    property string picker: ""
    property bool   hasMpris: false
    property bool   inited: false

    property var    tracks: []           // full library (backend objects)
    property var    tmap: ({})           // path -> track (includes loose tracks opened from outside)
    property int    libRev: 0
    property bool   scanning: false
    property int    scanDone: 0
    property int    scanTotal: 0
    property var    playlists: []        // [{ id, name, desc, cover, tracks: [paths], created }]
    property int    plRev: 0
    property var    libDirs: []
    property var    extraFiles: []

    // preferences
    property real   volume: 0.8
    property bool   muted: false
    property bool   shuffle: false
    property string repeatMode: "off"    // off | all | one
    property string sortKey: "title"     // title | artist | album | dur | added | year
    property bool   sortAsc: true
    property string importMode: "copy"   // copy | add
    property bool   playerOpen: false    // now-playing screen open
    property real   ppProg: playerOpen ? 1 : 0
    Behavior on ppProg { NumberAnimation { duration: 340; easing.type: Easing.InOutCubic } }
    property string panelTab: "queue"    // queue | lyrics | related | info
    property var    recent: []           // last played songs (most recent first)
    property bool   prefsLoaded: false

    function savePrefs() { if (prefsLoaded) prefsTimer.restart(); }
    Timer {
        id: prefsTimer
        interval: 700
        onTriggered: mp.call("prefs_save", { prefs: {
            volume: mp.volume, muted: mp.muted, shuffle: mp.shuffle, repeat: mp.repeatMode,
            sortKey: mp.sortKey, sortAsc: mp.sortAsc, importMode: mp.importMode, dlFormat: mp.dlFormat, dlSynced: mp.dlSynced,
            panelTab: mp.panelTab, recent: mp.recent.slice(0, 60),
            view: ["home", "explore", "songs", "albums", "artists", "playlists"].indexOf(mp.view) >= 0 ? mp.view : "home"
        } })
    }
    onVolumeChanged: { savePrefs(); mprisPush(); }
    onMutedChanged: savePrefs()
    onShuffleChanged: { savePrefs(); mprisPush(); }
    onRepeatModeChanged: { savePrefs(); mprisPush(); }
    onSortKeyChanged: savePrefs()
    onSortAscChanged: savePrefs()
    onImportModeChanged: savePrefs()
    onPanelTabChanged: savePrefs()

    Component.onCompleted: init()
    Component.onDestruction: {
        if (gs && typeof gs.musicPosSec !== "undefined") { gs.musicPosSec = 0; gs.musicDurSec = 0; }
        if (gs && typeof gs.musicPlaying !== "undefined") gs.musicPlaying = false;
        if (gs && typeof gs.musicLyricIndex !== "undefined") {
            gs.musicLyrics = []; gs.musicLyricsSynced = false; gs.musicLyricsPath = ""; gs.musicLyricIndex = -1;
        }
    }

    function init() {
        call("init", {}, function (ok, d) {
            if (!ok) { toast(d, true); return; }
            home = d.home; musicDir = d.musicDir; hasMutagen = d.mutagen; picker = d.picker; hasMpris = d.mpris;
            var p = d.prefs || {};
            volume = p.volume !== undefined ? p.volume : 0.8;
            muted = !!p.muted;
            shuffle = !!p.shuffle;
            repeatMode = p.repeat || "off";
            sortKey = p.sortKey || "title";
            sortAsc = p.sortAsc !== false;
            importMode = p.importMode || "copy";
            dlFormat = p.dlFormat || "mp3";
            dlSynced = p.dlSynced !== false;
            onlineCheck();
            panelTab = ["queue", "lyrics", "related", "info"].indexOf(p.panelTab) >= 0 ? p.panelTab : "queue";
            recent = p.recent || [];
            libDirs = p.libDirs || [];
            extraFiles = p.extraFiles || [];
            if (p.view) { view = p.view; }
            playlists = d.playlists || [];
            ensureLiked();
            plRev++;
            prefsLoaded = true;
            inited = true;
            if (!hasMutagen) toast(tx("Falta python-mutagen: no se podrán leer ni editar etiquetas", "python-mutagen is missing: tags can't be read or edited"), true);
            rescan(false, d.state || {});
        });
    }

    function rescan(force, restore) {
        if (scanning) return;
        scanning = true; scanDone = 0; scanTotal = 0;
        call("scan", { force: !!force }, function (ok, d) {
            scanning = false;
            if (!ok) { toast(d, true); return; }
            setLibrary(d);
            if (restore) restoreState(restore);
            takeExternal();
            if (force) toast(tx("Biblioteca actualizada: ", "Library updated: ") + songsLabel(d.length));
        }, function (ev) { scanDone = ev.done; scanTotal = ev.total; });
    }

    // ───────────────────────── online search and download (spotdl) ─────────────────────────
    property string onlineQ: ""
    property var    onlineRes: []
    property bool   onlineBusy: false
    property string onlineErr: ""
    property bool   onlineAvail: true
    property bool   onlineSearched: false
    property bool   dlSynced: true
    property string dlFormat: "mp3"
    property var    dl: ({})          // id → { state: run|done|err, line, err, path, rid }
    function onlineCheck() { call("online_status", {}, function (ok, d) { if (ok) onlineAvail = !!d.available; }); }
    function onlineSearch(q) {
        q = (q || "").trim();
        if (!q) return;
        onlineQ = q; onlineBusy = true; onlineErr = ""; onlineSearched = true;
        call("online_search", { query: q, limit: 20 }, function (ok, d) {
            onlineBusy = false;
            if (!ok) { onlineErr = String(d); onlineRes = []; return; }
            onlineRes = d;
        });
    }
    function dlSet(id, o) {
        var m = Object.assign({}, dl);
        m[id] = Object.assign({}, m[id] || {}, o);
        dl = m;
    }
    function onlineDownload(it) {
        var cur = dl[it.id];
        if (cur && cur.state === "run") return;
        dlSet(it.id, { state: "run", line: tx("Iniciando…", "Starting…"), err: "", path: "" });
        var rid = call("online_download", { url: it.url, fmt: dlFormat, synced: dlSynced }, function (ok, d) {
            if (!ok) {
                if (String(d) === "cancelled") { dlSet(it.id, { state: "", err: "" }); return; }
                dlSet(it.id, { state: "err", err: String(d) });
                toast(tx("No se pudo descargar: ", "Download failed: ") + it.title + " — " + String(d), true);
                return;
            }
            dlSet(it.id, { state: "done", path: d.paths && d.paths.length ? d.paths[0] : "" });
            if (d.tracks && d.tracks.length) rescan(false);
            toast(d.exists ? tx("Ya estaba en tu biblioteca: ", "Already in your library: ") + it.title
                           : tx("Descargada: ", "Downloaded: ") + it.title);
        }, function (ev) { dlSet(it.id, { line: ev.line }); });
        dlSet(it.id, { rid: rid });
    }
    function onlineCancel(it) { var c = dl[it.id]; if (c && c.rid) call("online_cancel", { target: c.rid }); }
    function artistsText(it) { return (it.artists || []).join(", "); }

    function setLibrary(list) {
        var m = {};
        // keep loose tracks that are in use by the queue
        for (var k in tmap) if (tmap[k] && tmap[k].loose) m[k] = tmap[k];
        for (var i = 0; i < list.length; i++) m[list[i].p] = list[i];
        tracks = list;
        tmap = m;
        libRev++;
    }
    function upsertTracks(list) {
        if (!list || !list.length) return;
        var m = tmap, arr = tracks.slice(), idx = {};
        for (var i = 0; i < arr.length; i++) idx[arr[i].p] = i;
        for (var j = 0; j < list.length; j++) {
            var t = list[j];
            if (idx[t.p] !== undefined) arr[idx[t.p]] = t;
            else if (!(m[t.p] && m[t.p].loose)) { arr.push(t); idx[t.p] = arr.length - 1; }
            else { t = Object.assign({}, t, { loose: true }); }
            m[t.p] = t;
        }
        tracks = arr;
        tmap = m;
        libRev++;
        if (curPath && m[curPath]) loadCurInfo();
    }
    function dropTracks(paths) {
        var s = {};
        paths.forEach(function (p) { s[p] = true; });
        tracks = tracks.filter(function (t) { return !s[t.p]; });
        var m = tmap;
        paths.forEach(function (p) { delete m[p]; });
        tmap = m;
        libRev++;
    }
    function trackOf(p) { var _r = libRev; return tmap[p] || null; }
    function tracksOf(paths) { var _r = libRev; var out = []; for (var i = 0; i < paths.length; i++) { var t = tmap[paths[i]]; if (t) out.push(t); } return out; }

    // ───────────────────────── derived views ─────────────────────────
    property string view: "home"         // current page name
    property var    viewArg: null
    property var    navStack: []
    property string search: ""
    property string searchTab: "all"     // all | songs | albums | artists | playlists
    property string libTab: "playlists"  // last visited library tab
    readonly property bool isLibView: view === "songs" || view === "albums" || view === "artists" || view === "playlists"
    onViewChanged: { clearSel(); savePrefs(); if (isLibView) libTab = view; }
    onViewArgChanged: clearSel()
    onSearchChanged: clearSel()

    function go(v, arg) {
        playerOpen = false;
        if (v === view && arg === viewArg) return;
        navStack = navStack.concat([{ v: view, a: viewArg, s: search }]).slice(-30);
        if (["home", "explore", "songs", "albums", "artists", "playlists"].indexOf(v) >= 0) navStack = [];
        search = "";
        view = v;
        viewArg = arg === undefined ? null : arg;
        Qt.callLater(mp.refocus);
    }
    function openSearch() {
        if (view === "search") return;
        playerOpen = false;
        navStack = navStack.concat([{ v: view, a: viewArg, s: "" }]).slice(-30);
        view = "search";
        viewArg = null;
    }
    function back() {
        playerOpen = false;
        if (!navStack.length) {
            if (view === "album") go("albums");
            else if (view === "artist") go("artists");
            else if (view === "playlist") go("playlists");
            else if (view === "collection") go("explore");
            else if (view !== "home") go("home");
            return;
        }
        var s = navStack[navStack.length - 1];
        navStack = navStack.slice(0, -1);
        view = s.v;
        viewArg = s.a;
        search = s.s || "";
    }
    readonly property bool isDetail: view === "album" || view === "artist" || view === "playlist" || view === "collection"
    readonly property bool canBack: navStack.length > 0 || isDetail || view === "queue" || view === "search"

    function matches(t, q) {
        if (!q) return true;
        var hay = ((t.t || "") + " " + (t.ar || "") + " " + (t.al || "") + " " + (t.aa || "") + " " + (t.g || "")).toLowerCase();
        var parts = q.split(/\s+/);
        for (var i = 0; i < parts.length; i++) if (parts[i] && hay.indexOf(parts[i]) < 0) return false;
        return true;
    }
    function filterTracks(list, q) {
        q = (q || "").trim().toLowerCase();
        if (!q) return list;
        return list.filter(function (t) { return mp.matches(t, q); });
    }
    function cmpStr(a, b) { return (a || "￿").localeCompare(b || "￿", undefined, { numeric: true, sensitivity: "base" }); }
    function albumOrder(a, b) { return (a.dn || 0) - (b.dn || 0) || (a.n || 0) - (b.n || 0) || cmpStr(a.t, b.t); }
    function sortTracks(list, key, asc) {
        var d = asc ? 1 : -1;
        var f;
        if (key === "artist") f = function (a, b) { return d * (cmpStr(mp.artistOf(a), mp.artistOf(b)) || cmpStr(a.al, b.al)) || mp.albumOrder(a, b); };
        else if (key === "album") f = function (a, b) { return d * cmpStr(a.al, b.al) || mp.albumOrder(a, b); };
        else if (key === "dur") f = function (a, b) { return d * ((a.dur || 0) - (b.dur || 0)) || mp.cmpStr(a.t, b.t); };
        else if (key === "added") f = function (a, b) { return d * ((b.add || 0) - (a.add || 0)) || mp.cmpStr(a.t, b.t); };
        else if (key === "year") f = function (a, b) { return d * (mp.cmpStr(b.y, a.y)) || mp.cmpStr(a.al, b.al) || mp.albumOrder(a, b); };
        else f = function (a, b) { return d * cmpStr(a.t, b.t) || mp.cmpStr(mp.artistOf(a), mp.artistOf(b)); };
        return list.slice().sort(f);
    }
    function albumKeyOf(t) { return (albumArtistOf(t).toLowerCase() + "\u0001" + (t.al || "").toLowerCase()); }

    // albums and artists (recomputed only when the library changes)
    readonly property var albumData: {
        var _r = libRev;
        var map = {}, list = [];
        for (var i = 0; i < tracks.length; i++) {
            var t = tracks[i];
            if (!t.al) continue;
            var k = albumKeyOf(t);
            var a = map[k];
            if (!a) { a = map[k] = { key: k, name: t.al, artist: albumArtistOf(t), year: "", art: "", genre: "", tracks: [], dur: 0 }; list.push(a); }
            a.tracks.push(t);
            a.dur += t.dur || 0;
            if (!a.art && t.art) a.art = t.art;
            if (!a.year && t.y) a.year = t.y;
            if (!a.genre && t.g) a.genre = t.g;
        }
        for (var j = 0; j < list.length; j++) list[j].tracks.sort(albumOrder);
        list.sort(function (x, y) { return mp.cmpStr(x.name, y.name) || mp.cmpStr(x.artist, y.artist); });
        return { map: map, list: list };
    }
    readonly property var artistData: {
        var _r = libRev;
        var map = {}, list = [];
        for (var i = 0; i < tracks.length; i++) {
            var t = tracks[i];
            var n = albumArtistOf(t);
            var k = n.toLowerCase();
            var a = map[k];
            if (!a) { a = map[k] = { key: k, name: n, art: "", tracks: [], albums: [], _al: {} }; list.push(a); }
            a.tracks.push(t);
            if (!a.art && t.art) a.art = t.art;
            if (t.al) { var ak = albumKeyOf(t); if (!a._al[ak]) { a._al[ak] = true; a.albums.push(ak); } }
        }
        list.sort(function (x, y) { return mp.cmpStr(x.name, y.name); });
        return { map: map, list: list };
    }
    readonly property var songsView: sortTracks(filterTracks(tracks, search), sortKey, sortAsc)
    readonly property var albumsView: {
        var q = search.trim().toLowerCase();
        if (!q) return albumData.list;
        return albumData.list.filter(function (a) { return (a.name + " " + a.artist + " " + a.genre).toLowerCase().indexOf(q) >= 0; });
    }
    readonly property var artistsView: {
        var q = search.trim().toLowerCase();
        if (!q) return artistData.list;
        return artistData.list.filter(function (a) { return a.name.toLowerCase().indexOf(q) >= 0; });
    }
    readonly property var curAlbum: view === "album" && viewArg ? (albumData.map[viewArg] || null) : null
    readonly property var curArtist: view === "artist" && viewArg ? (artistData.map[viewArg] || null) : null
    readonly property var curPlaylist: { var _p = plRev; return view === "playlist" && viewArg ? playlistById(viewArg) : null; }
    readonly property var curArtistAlbums: {
        if (!curArtist) return [];
        var m = albumData.map;
        return curArtist.albums.map(function (k) { return m[k]; }).filter(Boolean)
            .sort(function (a, b) { return mp.cmpStr(b.year, a.year) || mp.cmpStr(a.name, b.name); });
    }
    readonly property var curItems: {
        var _r = libRev, _p = plRev, _q = queueRev;
        if (view === "songs") return songsView;
        if (view === "album") return curAlbum ? filterTracks(curAlbum.tracks, search) : [];
        if (view === "artist") return curArtist ? filterTracks(sortTracks(curArtist.tracks, "album", true), search) : [];
        if (view === "playlist") return curPlaylist ? filterTracks(tracksOf(curPlaylist.tracks), search) : [];
        if (view === "queue") return tracksOf(queue);
        if (view === "search") return searchSongs;
        if (view === "collection") return collection.tracks;
        return [];
    }
    // filtering breaks index ↔ position in playlists/queue
    readonly property bool ordered: (view === "playlist" || view === "queue") && search.trim() === ""

    // ───────────────────────── pages (Home · Explore · Search) ─────────────────────────
    readonly property bool listMode: ["songs", "album", "artist", "playlist", "queue", "collection"].indexOf(view) >= 0
                                     || (view === "search" && (searchTab === "all" || searchTab === "songs"))
    readonly property bool gridAlbums: view === "albums" || (view === "search" && searchTab === "albums")
    readonly property bool gridArtists: view === "artists" || (view === "search" && searchTab === "artists")
    readonly property bool gridLists: view === "playlists" || (view === "search" && searchTab === "playlists")
    readonly property bool searchBlank: view === "search" && search.trim() === ""
    readonly property bool searchHasOther: view === "search" && searchTab === "all" && (albumsView.length + artistsView.length + playlistsView.length) > 0
    readonly property real cardW: px(172)
    readonly property real cardH: px(244)

    readonly property var searchSongs: {
        var _r = libRev;
        var q = search.trim().toLowerCase();
        if (!q) return [];
        var list = filterTracks(tracks, q);
        var rank = function (t) { var x = (t.t || "").toLowerCase(), i = x.indexOf(q); return i === 0 ? 0 : i > 0 ? 1 : 2; };
        return list.slice().sort(function (a, b) { return rank(a) - rank(b) || mp.cmpStr(a.t, b.t); });
    }
    readonly property var playlistsView: {
        var _p = plRev;
        var q = search.trim().toLowerCase();
        return q ? playlists.filter(function (p) { return p.name.toLowerCase().indexOf(q) >= 0; }) : playlists.slice();
    }

    function artsOf(list) {
        var out = [], seen = {};
        for (var i = 0; i < list.length && out.length < 4; i++) {
            var a = list[i].art;
            if (a && !seen[a]) { seen[a] = true; out.push(a); }
        }
        return out;
    }
    function decadeName(d) { return lang === "es" ? "Años " + (d >= 2000 ? d : String(d).substring(2)) : d + "s"; }
    function greeting() {
        var h = new Date().getHours();
        return h < 6 ? tx("Buenas noches", "Good night") : h < 12 ? tx("Buenos días", "Good morning") : h < 20 ? tx("Buenas tardes", "Good afternoon") : tx("Buenas noches", "Good evening");
    }

    readonly property var genreData: {
        var _r = libRev, map = {}, list = [];
        for (var i = 0; i < tracks.length; i++) {
            var t = tracks[i], g = (t.g || "").trim();
            if (!g) continue;
            var k = g.toLowerCase(), o = map[k];
            if (!o) { o = map[k] = { key: k, name: g, tracks: [] }; list.push(o); }
            o.tracks.push(t);
        }
        list.sort(function (a, b) { return b.tracks.length - a.tracks.length || mp.cmpStr(a.name, b.name); });
        return { map: map, list: list };
    }
    readonly property var decadeData: {
        var _r = libRev, map = {}, list = [];
        for (var i = 0; i < tracks.length; i++) {
            var t = tracks[i];
            var m = /(\d{4})/.exec(t.y || "");
            if (!m) continue;
            var d = Math.floor(parseInt(m[1], 10) / 10) * 10;
            if (d < 1900 || d > 2090) continue;
            var o = map[d];
            if (!o) { o = map[d] = { key: String(d), name: decadeName(d), tracks: [] }; list.push(o); }
            o.tracks.push(t);
        }
        list.sort(function (a, b) { return parseInt(b.key) - parseInt(a.key); });
        return { map: map, list: list };
    }
    // automatic mixes: shuffle, by artist and by genre
    readonly property var mixes: {
        var _r = libRev, out = [];
        var mk = function (name, list) { var l = shuffled(list).slice(0, 60); return { name: name, sub: songsLabel(l.length), tracks: l, arts: artsOf(l) }; };
        if (tracks.length >= 2) out.push(mk(tx("Mix aleatorio", "Shuffle mix"), tracks));
        artistData.list.filter(function (a) { return a.tracks.length >= 3; })
            .sort(function (a, b) { return b.tracks.length - a.tracks.length; }).slice(0, 3)
            .forEach(function (a) { out.push(mk(tx("Mix de ", "Mix of ") + a.name, a.tracks)); });
        genreData.list.filter(function (g) { return g.tracks.length >= 3; }).slice(0, 3)
            .forEach(function (g) { out.push(mk("Mix " + g.name, g.tracks)); });
        return out;
    }
    readonly property var quickPicks: { var _r = libRev; return shuffled(tracks).slice(0, 12); }
    readonly property var recentTracks: {
        var _r = libRev, out = [];
        for (var i = 0; i < recent.length && out.length < 20; i++) { var t = tmap[recent[i]]; if (t && !t.loose) out.push(t); }
        return out;
    }
    readonly property var addedTracks: sortTracks(tracks, "added", true).slice(0, 20)
    readonly property var newAlbums: {
        var _r = libRev;
        var mx = function (a) { var m = 0; for (var i = 0; i < a.tracks.length; i++) m = Math.max(m, a.tracks[i].add || 0); return m; };
        return albumData.list.slice().sort(function (a, b) { return mx(b) - mx(a); }).slice(0, 20);
    }
    readonly property var collection: {
        var _r = libRev, _p = plRev;
        var none = { name: "", tracks: [] };
        if (view !== "collection" || !viewArg) return none;
        var a = String(viewArg);
        if (a === "recent") return { name: tx("Novedades", "New additions"), tracks: sortTracks(tracks, "added", true) };
        if (a.indexOf("genre:") === 0) { var g = genreData.map[a.substring(6)]; return g ? { name: g.name, tracks: sortTracks(g.tracks, "artist", true) } : none; }
        if (a.indexOf("decade:") === 0) { var d = decadeData.map[a.substring(7)]; return d ? { name: d.name, tracks: sortTracks(d.tracks, "year", true) } : none; }
        if (a.indexOf("mix:") === 0) { var m = mixes[parseInt(a.substring(4))]; return m ? { name: m.name, tracks: m.tracks } : none; }
        return none;
    }
    function pushRecent(p) {
        if (!p || !tmap[p] || tmap[p].loose) return;
        var r = recent.filter(function (x) { return x !== p; });
        r.unshift(p);
        recent = r.slice(0, 60);
        savePrefs();
    }
    // related to the song that's playing
    readonly property var curAlbumObj: { var _r = libRev; return cur && cur.al ? (albumData.map[albumKeyOf(cur)] || null) : null; }
    readonly property var curArtistObj: { var _r = libRev; return cur ? (artistData.map[albumArtistOf(cur).toLowerCase()] || null) : null; }
    readonly property var curArtistRest: {
        if (!curArtistObj) return [];
        var k = cur && cur.al ? albumKeyOf(cur) : "";
        return sortTracks(curArtistObj.tracks, "album", true).filter(function (t) { return !k || albumKeyOf(t) !== k; }).slice(0, 15);
    }
    readonly property var curArtistOtherAlbums: {
        if (!curArtistObj) return [];
        var k = cur && cur.al ? albumKeyOf(cur) : "";
        return curArtistObj.albums.filter(function (x) { return x !== k; }).map(function (x) { return albumData.map[x]; }).filter(Boolean);
    }

    // ───────────────────────── selection ─────────────────────────
    property var selIdx: ({})
    property int selRev: 0
    property int selAnchor: -1
    readonly property int selCount: { var _s = selRev; return Object.keys(selIdx).length; }
    function clearSel() { selIdx = ({}); selAnchor = -1; selRev++; }
    function isSel(i) { var _s = selRev; return selIdx[i] === true; }
    function clickSel(i, mods) {
        var m = selIdx;
        if (mods & Qt.ShiftModifier && selAnchor >= 0) {
            if (!(mods & Qt.ControlModifier)) m = {};
            var a = Math.min(selAnchor, i), b = Math.max(selAnchor, i);
            for (var k = a; k <= b; k++) m[k] = true;
        } else if (mods & Qt.ControlModifier) {
            if (m[i]) delete m[i]; else m[i] = true;
            selAnchor = i;
        } else {
            m = {}; m[i] = true; selAnchor = i;
        }
        selIdx = m;
        selRev++;
    }
    function selectAll() { var m = {}; for (var i = 0; i < curItems.length; i++) m[i] = true; selIdx = m; selRev++; }
    function selIndices() { var _s = selRev; return Object.keys(selIdx).map(Number).filter(function (i) { return i < mp.curItems.length; }).sort(function (a, b) { return a - b; }); }
    function selPaths() { var it = curItems; return selIndices().map(function (i) { return it[i].p; }); }
    function targetsFor(i) {
        // if acting on a selected row, the action applies to the whole selection
        if (isSel(i) && selCount > 1) return selPaths();
        return curItems[i] ? [curItems[i].p] : [];
    }

    // ───────────────────────── playback ─────────────────────────
    property var    queue: []            // paths in playback order
    property var    queueOrig: []        // original order (to turn shuffle off)
    property int    qIndex: -1
    property int    queueRev: 0
    property string queueLabel: ""       // where the queue comes from (album, playlist…)
    property real   pendingSeek: -1
    property bool   pendingPlay: false
    property int    errStreak: 0
    readonly property string curPath: qIndex >= 0 && qIndex < queue.length ? queue[qIndex] : ""
    readonly property var    cur: { var _r = libRev; return curPath ? (tmap[curPath] || null) : null; }
    readonly property bool   playing: player.playbackState === MediaPlayer.PlayingState
    // player.duration is stale until the new track loads
    readonly property real   durSec: (player.duration > 0 && curPath !== "" && player.source.toString() === fileUrl(curPath))
                                     ? player.duration / 1000 : (cur ? cur.dur || 0 : 0)
    property real   posSec: 0
    readonly property real   pct: durSec > 0 ? Math.min(1, posSec / durSec) : 0
    readonly property bool   canNext: queue.length > 0 && (qIndex < queue.length - 1 || repeatMode === "all")
    readonly property bool   canPrev: queue.length > 0

    onPlayingChanged: {
        if (gs && typeof gs.musicPlaying !== "undefined") gs.musicPlaying = playing;
        mprisPush();
    }
    onCurPathChanged: { loadCurInfo(); mprisPush(); saveState(); }
    // real position/duration for the shell's sliders (no MPRIS)
    readonly property int _gsPos: Math.floor(posSec)
    readonly property int _gsDur: Math.round(durSec)
    function pushGsPos() {
        if (!gs || typeof gs.musicPosSec === "undefined") return;
        gs.musicDurSec = qIndex >= 0 ? _gsDur : 0;
        gs.musicPosSec = qIndex >= 0 ? _gsPos : 0;
    }
    on_GsPosChanged: pushGsPos()
    on_GsDurChanged: pushGsPos()
    onQIndexChanged: { pushGsPos(); if (qIndex < 0) pushGsLyrics(true); }
    onCanNextChanged: mprisPush()

    MediaPlayer {
        id: player
        audioOutput: AudioOutput {
            id: audioOut
            volume: mp.muted ? 0 : mp.volume * mp.volume
        }
        onPositionChanged: if (!mp.seekDragging) mp.posSec = player.position / 1000
        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.LoadedMedia || mediaStatus === MediaPlayer.BufferedMedia) {
                if (mp.pendingSeek >= 0) { player.position = Math.round(mp.pendingSeek * 1000); mp.pendingSeek = -1; }
                if (mp.pendingPlay) { mp.pendingPlay = false; player.play(); playKick.restart(); }
                mp.errStreak = 0;
            } else if (mediaStatus === MediaPlayer.EndOfMedia) {
                mp.onEnded();
            } else if (mediaStatus === MediaPlayer.InvalidMedia) {
                mp.onBadMedia();
            }
        }
        onErrorOccurred: (err, msg) => { console.warn("[music] " + msg); mp.onBadMedia(msg); }
    }
    function onBadMedia(msg) {
        toast(tx("No se pudo reproducir: ", "Couldn't play: ") + baseName(curPath) + (msg ? " (" + msg + ")" : ""), true);
        errStreak++;
        if (errStreak < Math.min(queue.length, 8) && qIndex < queue.length - 1) badSkip.restart();
        else { pendingPlay = false; player.stop(); }
    }
    Timer { id: playKick; interval: 60; repeat: false; onTriggered: if (player.playbackState !== MediaPlayer.PlayingState && mp.queue.length > 0 && player.mediaStatus !== MediaPlayer.NoMedia && player.mediaStatus !== MediaPlayer.InvalidMedia) player.play() }
    Timer { id: badSkip; interval: 700; onTriggered: mp.next(true) }

    function loadIndex(i, autoplay, seek) {
        if (i < 0 || i >= queue.length) return;
        // set posSec before qIndex so MPRIS gets the right position
        posSec = seek > 0 ? seek : 0;
        qIndex = i;
        if (autoplay) pushRecent(queue[i]);
        pendingSeek = seek > 0 ? seek : -1;
        pendingPlay = !!autoplay;
        var u = fileUrl(queue[i]);
        if (player.source.toString() === u) {
            player.position = seek > 0 ? Math.round(seek * 1000) : 0;
            pendingSeek = -1;
            if (autoplay) { pendingPlay = false; player.play(); }
        } else {
            player.stop();
            player.source = u;
        }
        queueRev++;
    }
    function setQueue(paths, start, label, forceShuffle) {
        if (!paths.length) return;
        start = Math.max(0, Math.min(start || 0, paths.length - 1));
        queueOrig = paths.slice();
        queueLabel = label || "";
        if (forceShuffle !== undefined) shuffle = forceShuffle;
        if (shuffle) {
            var first = paths[start];
            var rest = paths.slice(0, start).concat(paths.slice(start + 1));
            queue = [first].concat(shuffled(rest));
            start = 0;
        } else queue = paths.slice();
        loadIndex(start, true, 0);
    }
    function playPaths(paths, start, label) { setQueue(paths, start, label); }
    function shufflePaths(paths, label) { if (paths.length) setQueue(paths, Math.floor(Math.random() * paths.length), label, true); }
    function playNext(paths) {
        if (!paths.length) return;
        if (qIndex < 0) { playPaths(paths, 0, ""); return; }
        var q = queue.slice();
        Array.prototype.splice.apply(q, [qIndex + 1, 0].concat(paths));
        queue = q;
        queueOrig = queueOrig.concat(paths);
        queueRev++;
        toast(paths.length === 1 ? tx("Sonará a continuación", "Playing next") : songsLabel(paths.length) + tx(" a continuación", " playing next"));
    }
    function addToQueue(paths) {
        if (!paths.length) return;
        if (qIndex < 0) { queue = paths.slice(); queueOrig = paths.slice(); loadIndex(0, false, 0); }
        else { queue = queue.concat(paths); queueOrig = queueOrig.concat(paths); queueRev++; }
        toast(tx("Añadido a la cola: ", "Added to queue: ") + songsLabel(paths.length));
        saveState();
    }
    function removeFromQueue(indices) {
        indices = indices.slice().sort(function (a, b) { return b - a; });
        var q = queue.slice(), cur = qIndex, removedCur = false;
        for (var i = 0; i < indices.length; i++) {
            var k = indices[i];
            if (k < 0 || k >= q.length) continue;
            q.splice(k, 1);
            if (k < cur) cur--;
            else if (k === cur) removedCur = true;
        }
        var keep = {};
        q.forEach(function (p) { keep[p] = true; });
        queueOrig = queueOrig.filter(function (p) { return keep[p]; });
        queue = q;
        if (!q.length) { stopAll(); return; }
        if (removedCur) { qIndex = -1; loadIndex(Math.min(cur, q.length - 1), playing, 0); }
        else { qIndex = cur; queueRev++; }
        clearSel();
        saveState();
    }
    function moveInQueue(from, to) {
        if (from === to || from < 0 || to < 0 || from >= queue.length || to >= queue.length) return;
        var q = queue.slice();
        var x = q.splice(from, 1)[0];
        q.splice(to, 0, x);
        var c = qIndex;
        if (from === c) c = to;
        else if (from < c && to >= c) c--;
        else if (from > c && to <= c) c++;
        queue = q;
        qIndex = c;
        queueRev++;
        saveState();
    }
    function clearQueue() {
        if (qIndex >= 0 && playing) { queue = [curPath]; queueOrig = [curPath]; qIndex = 0; queueRev++; }
        else stopAll();
        saveState();
    }
    function stopAll() {
        player.stop();
        player.source = "";
        queue = []; queueOrig = []; qIndex = -1; queueRev++; posSec = 0;
        saveState();
    }
    function togglePlay() {
        if (qIndex < 0) {
            var list = curItems.length ? curItems : songsView;
            if (list.length) playPaths(list.map(function (t) { return t.p; }), 0, "");
            return;
        }
        if (playing) player.pause();
        else {
            if (player.mediaStatus === MediaPlayer.EndOfMedia) player.position = 0;
            if (player.mediaStatus === MediaPlayer.NoMedia) loadIndex(qIndex, true, posSec);
            else player.play();
        }
    }
    function next(auto) {
        if (!queue.length) return;
        if (qIndex < queue.length - 1) loadIndex(qIndex + 1, true, 0);
        else if (repeatMode === "all") {
            if (shuffle) { var c = queue[qIndex]; queue = shuffled(queue); if (queue[0] === c && queue.length > 1) { queue.push(queue.shift()); } queueRev++; }
            loadIndex(0, true, 0);
        } else if (auto) { player.stop(); posSec = 0; player.position = 0; }
    }
    function prev() {
        if (!queue.length) return;
        if (posSec > 3 || qIndex === 0) { seekTo(0); if (!playing) player.play(); return; }
        loadIndex(qIndex - 1, true, 0);
    }
    function onEnded() {
        if (repeatMode === "one") { player.position = 0; posSec = 0; player.play(); mprisPush(false, true); return; }
        next(true);
    }
    function seekTo(s) {
        s = Math.max(0, Math.min(s, durSec > 0 ? durSec - 0.25 : s));
        player.position = Math.round(s * 1000);
        posSec = s;
        mprisPush(false, true);
    }
    function seekBy(d) { if (qIndex >= 0) seekTo(posSec + d); }
    // reopens the current track (e.g. after the sync editor trims the file)
    function reloadCurrent(seek, play) {
        if (qIndex < 0) return;
        player.stop();
        player.source = "";
        loadIndex(qIndex, !!play, seek > 0 ? seek : 0);
    }
    function toggleShuffle() {
        var on = !shuffle;
        shuffle = on;
        if (qIndex < 0 || queue.length < 2) return;
        var c = queue[qIndex];
        if (on) {
            queueOrig = queue.slice();
            var rest = queue.slice(0, qIndex).concat(queue.slice(qIndex + 1));
            queue = [c].concat(shuffled(rest));
            qIndex = 0;
        } else {
            var base = queueOrig.length ? queueOrig.slice() : queue.slice();
            var seen = {};
            base.forEach(function (p) { seen[p] = true; });
            queue.forEach(function (p) { if (!seen[p]) base.push(p); });
            queue = base;
            qIndex = Math.max(0, base.indexOf(c));
        }
        queueRev++;
        saveState();
    }
    function cycleRepeat() { repeatMode = repeatMode === "off" ? "all" : repeatMode === "all" ? "one" : "off"; }
    function setVolume(v) { volume = Math.max(0, Math.min(1, v)); if (volume > 0) muted = false; }

    // state (queue + position) to restore it when reopening
    function saveState() { if (inited) stateTimer.restart(); }
    Timer {
        id: stateTimer
        interval: 1200
        onTriggered: mp.call("state_save", { state: {
            queue: mp.queue, queueOrig: mp.queueOrig, index: mp.qIndex, pos: mp.posSec, label: mp.queueLabel
        } })
    }
    Timer { interval: 10000; repeat: true; running: mp.playing; onTriggered: mp.saveState() }
    function restoreState(st) {
        if (qIndex >= 0 || !st || !st.queue || !st.queue.length) return;
        var ok = st.queue.filter(function (p) { return !!mp.tmap[p]; });
        if (!ok.length) return;
        var curP = st.queue[st.index] || "";
        queue = ok;
        queueOrig = (st.queueOrig || ok).filter(function (p) { return !!mp.tmap[p]; });
        queueLabel = st.label || "";
        var i = ok.indexOf(curP);
        loadIndex(i >= 0 ? i : 0, false, i >= 0 ? (st.pos || 0) : 0);
    }

    // ───────────────────────── current track info (lyrics, etc.) ─────────────────────────
    property var  curInfo: null          // track_get reply for the current track
    property var  lyr: ({ synced: false, lines: [] })
    property int  lyrIndex: -1
    function loadCurInfo() {
        var p = curPath;
        if (!p) { curInfo = null; lyr = { synced: false, lines: [] }; return; }
        call("track_get", { path: p }, function (ok, d) {
            if (p !== mp.curPath) return;
            if (!ok) { mp.curInfo = null; mp.lyr = { synced: false, lines: [] }; return; }
            mp.curInfo = d;
            mp.lyr = mp.pickLyrics(d);
            if (mp.tmap[p] && mp.tmap[p].loose) {
                var o = mp.tmap[p];
                // new object: if the same one is mutated, bindings on `cur` don't notice
                mp.tmap[p] = Object.assign({}, o, {
                    t: d.tags.title || o.t, ar: d.tags.artist, al: d.tags.album, aa: d.tags.albumartist,
                    art: d.art || d.folderArt || "", dur: d.duration, n: parseInt(d.tags.track) || 0,
                    lyr: !!(d.tags.lyrics || d.lrcText)
                });
                mp.libRev++;
                mp.mprisPush();
            }
        });
    }
    function pickLyrics(d) {
        var a = parseLrc(d.tags ? d.tags.lyrics : "");
        var b = parseLrc(d.lrcText || "");
        if (b.synced && !a.synced) return b;
        if (a.lines.length) return a;
        return b;
    }
    function parseLrc(text) {
        text = (text || "").replace(/\r/g, "");
        if (!text.trim()) return { synced: false, lines: [] };
        var rx = /\[(\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?\]/g;
        var offset = 0;
        var mo = text.match(/\[offset:\s*([+-]?\d+)\s*\]/i);
        if (mo) offset = parseInt(mo[1], 10) / 1000;
        var out = [], plain = [], any = false;
        var rows = text.split("\n");
        for (var i = 0; i < rows.length; i++) {
            var row = rows[i];
            var stamps = [], m;
            rx.lastIndex = 0;
            var last = 0;
            while ((m = rx.exec(row)) !== null) {
                if (m.index !== last) break;
                var frac = m[3] ? parseInt(m[3], 10) / Math.pow(10, m[3].length) : 0;
                stamps.push(parseInt(m[1], 10) * 60 + parseInt(m[2], 10) + frac);
                last = rx.lastIndex;
            }
            if (stamps.length) {
                any = true;
                var txt = row.substring(last).replace(/<\d+:\d+(?:\.\d+)?>/g, "").trim();
                for (var j = 0; j < stamps.length; j++) out.push({ t: Math.max(0, stamps[j] - offset), s: txt });
            } else if (!/^\[[a-z]+:.*\]$/i.test(row.trim())) {
                plain.push({ t: -1, s: row.trim() });
            }
        }
        if (any) {
            out.sort(function (x, y) { return x.t - y.t; });
            return { synced: true, lines: out };
        }
        while (plain.length && !plain[0].s) plain.shift();
        while (plain.length && !plain[plain.length - 1].s) plain.pop();
        return { synced: false, lines: plain };
    }
    function stripLrc(text) {
        return (text || "").split("\n").filter(function (l) { return !/^\s*\[[a-z]+:.*\]\s*$/i.test(l); })
            .map(function (l) { return l.replace(/\[\d{1,3}:\d{1,2}(?:[.:]\d{1,3})?\]/g, "").replace(/<\d+:\d+(?:\.\d+)?>/g, "").trim(); }).join("\n").trim();
    }
    onPosSecChanged: {
        if (!lyr.synced) { if (lyrIndex !== -1) lyrIndex = -1; return; }
        var L = lyr.lines, t = posSec + 0.15, lo = 0, hi = L.length - 1, ans = -1;
        while (lo <= hi) { var mid = (lo + hi) >> 1; if (L[mid].t <= t) { ans = mid; lo = mid + 1; } else hi = mid - 1; }
        if (ans !== lyrIndex) lyrIndex = ans;
    }
    onLyrChanged: lyrIndex = -1

    // ── full-screen lyrics over cava ──
    property bool lyrFull: false
    // the normal UI fades out (keeps glass mode)
    property real uiVis: lyrFull ? 0 : 1
    Behavior on uiVis { NumberAnimation { duration: 340; easing.type: Easing.OutCubic } }
    property var  fsCava: []                 // cava bars (0..1), mono: bass on the left, treble on the right
    function setLyrFull(on) {
        if (on === lyrFull) return;
        lyrFull = on;
        Qt.callLater(mp.refocus);
    }

    // cava is restarted by hand and watched for data
    readonly property bool fsCavaWanted: lyrFull && visible
    property real fsCavaLastTs: 0
    onFsCavaWantedChanged: {
        if (fsCavaWanted) fsCavaStart();
        else { fsCavaRetry.stop(); fsCavaProc.running = false; fsCava = []; }
    }
    function fsCavaStart() {
        fsCavaLastTs = Date.now();
        // if one is still alive (e.g. shutting down), restart when it exits (onExited)
        if (fsCavaProc.running) { fsCavaProc.running = false; return; }
        fsCavaProc.running = true;
    }
    Timer { id: fsCavaRetry; interval: 450; onTriggered: if (mp.fsCavaWanted) mp.fsCavaStart() }
    Timer {
        // watchdog: playing with no cava data for 3 s → restart
        interval: 1500; repeat: true
        running: mp.fsCavaWanted && mp.playing
        onTriggered: {
            if (Date.now() - mp.fsCavaLastTs < 3000) return;
            mp.fsCavaLastTs = Date.now();
            if (fsCavaProc.running) fsCavaProc.running = false; else mp.fsCavaStart();
        }
    }
    Process {
        id: fsCavaProc
        running: false
        command: ["bash", "-c",
            "CONF=\"$HOME/.cache/qs-music-cava.conf\"; " +
            "NAME=$(cat \"$HOME/.cache/qs-eq-hw-sink-name\" 2>/dev/null); " +
            "if [ -n \"$NAME\" ]; then SRC=\"${NAME}.monitor\"; else SRC=\"auto\"; fi; " +
            "cat > \"$CONF\" << EOF\n" +
            "[general]\n" +
            "bars = 32\n" +
            "framerate = 40\n" +
            "autosens = 1\n" +
            "sensitivity = 100\n" +
            "[input]\n" +
            "method = pulse\n" +
            "source = $SRC\n" +
            "[output]\n" +
            "method = raw\n" +
            "raw_target = /dev/stdout\n" +
            "data_format = ascii\n" +
            "ascii_max_range = 100\n" +
            "bar_delimiter = 59\n" +
            "frame_delimiter = 10\n" +
            "channels = mono\n" +
            "mono_option = average\n" +
            "EOF\n" +
            "command -v cava >/dev/null 2>&1 && exec cava -p \"$CONF\""]
        stdout: SplitParser {
            onRead: (line) => {
                var parts = line.split(";");
                var n = parts.length;
                if (n > 0 && parts[n - 1].length === 0) n--;
                if (n < 2) return;
                var out = new Array(n);
                for (var i = 0; i < n; i++) {
                    var raw = parseInt(parts[i], 10);
                    out[i] = isNaN(raw) ? 0 : Math.max(0, Math.min(1, raw / 100));
                }
                mp.fsCava = out;
                mp.fsCavaLastTs = Date.now();
            }
        }
        onExited: (code, status) => {
            mp.fsCava = [];
            if (mp.fsCavaWanted) fsCavaRetry.restart();
        }
    }

    // progress wave phase (only runs while the window is visible and playing)
    property real wavePhase: 0
    NumberAnimation on wavePhase {
        from: 0; to: Math.PI * 2; duration: 1600; loops: Animation.Infinite
        running: mp.visible && mp.playing
    }
    property bool seekDragging: false

    // ───────────────────────── MPRIS ─────────────────────────
    function mprisPush(full, seeked) {
        if (!_ready && !full) return;
        var t = cur;
        call("mpris", {
            status: qIndex < 0 ? "Stopped" : (playing ? "Playing" : "Paused"),
            loop: repeatMode === "one" ? "Track" : repeatMode === "all" ? "Playlist" : "None",
            shuffle: shuffle, volume: volume,
            title: t ? t.t : "", artist: t ? artistOf(t) : "", album: t ? (t.al || "") : "",
            albumartist: t ? (t.aa || "") : "", art: t ? (t.art || "") : "", path: curPath,
            track: t ? (t.n || 0) : 0, len: Math.round(durSec * 1e6), pos: Math.round(posSec * 1e6),
            canNext: canNext, canPrev: canPrev, seeked: !!seeked,
            // lyrics: full text in xesam:asText (LRC if synced) + current line in real time
            lyrics: qIndex >= 0 ? lyrText : "", lyricsSynced: qIndex >= 0 && lyr.synced,
            lyricLine: qIndex >= 0 ? lyrLine : "", lyricIndex: qIndex >= 0 ? lyrIndex : -1
        });
    }
    onDurSecChanged: mprisPush()
    onCurChanged: mprisPush()

    // ── lyrics out (MPRIS + shell) ──
    function fmtLrcTime(t) {
        var cs = Math.max(0, Math.round(t * 100));
        var m = Math.floor(cs / 6000), s = Math.floor(cs / 100) % 60, c = cs % 100;
        return "[" + (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s + "." + (c < 10 ? "0" : "") + c + "]";
    }
    readonly property string lyrText: {
        var L = lyr.lines || [];
        if (!L.length) return "";
        var out = [];
        for (var i = 0; i < L.length; i++) out.push(lyr.synced ? fmtLrcTime(L[i].t) + L[i].s : L[i].s);
        return out.join("\n");
    }
    readonly property string lyrLine: lyr.synced && lyrIndex >= 0 && lyrIndex < lyr.lines.length ? lyr.lines[lyrIndex].s : ""
    onLyrIndexChanged: { mprisPush(); pushGsLyrics(false); }
    onLyrTextChanged: { mprisPush(); pushGsLyrics(true); }
    // direct copy into globalState (no MPRIS lag)
    function pushGsLyrics(all) {
        if (!gs || typeof gs.musicLyricIndex === "undefined") return;
        var has = qIndex >= 0;
        if (all) {
            gs.musicLyricsPath = has ? curPath : "";
            gs.musicLyricsSynced = has && lyr.synced;
            gs.musicLyrics = has ? (lyr.lines || []).map(function (l) { return { t: l.t, s: l.s }; }) : [];
        }
        gs.musicLyricIndex = has ? lyrIndex : -1;
    }
    function onMpris(o) {
        var a = o.action;
        if (a === "PlayPause") togglePlay();
        else if (a === "Play") { if (!playing) togglePlay(); }
        else if (a === "Pause") player.pause();
        else if (a === "Stop") { player.stop(); posSec = 0; }
        else if (a === "Next") next(false);
        else if (a === "Previous") prev();
        else if (a === "Seek") seekBy(o.value);
        else if (a === "SetPosition") seekTo(o.value);
        else if (a === "Loop") repeatMode = o.value === "Track" ? "one" : o.value === "Playlist" ? "all" : "off";
        else if (a === "Shuffle") { if (!!o.value !== shuffle) toggleShuffle(); }
        else if (a === "Volume") setVolume(o.value);
        else if (a === "Raise") { if (gs) { if (typeof gs.openMusicHere === "function") gs.openMusicHere(); else gs.musicPlayerOpen = true; } }
        else if (a === "Quit") { player.stop(); if (gs) gs.musicPlayerOpen = false; }
        else if (a === "Open") openExternal([o.value]);
    }

    // ── opening files from outside ──
    property int _extSeen: 0
    Connections {
        target: mp.gs || null
        ignoreUnknownSignals: true
        function onMusicPlayerReqChanged() { mp.takeExternal(); }
    }
    function takeExternal() {
        if (!gs || !inited || typeof gs.musicPlayerQueue === "undefined") return;
        if (gs.musicPlayerReq === _extSeen) return;
        _extSeen = gs.musicPlayerReq;
        var q = gs.musicPlayerQueue || [];
        gs.musicPlayerQueue = [];
        if (q.length) openExternal(q);
    }
    function openExternal(paths) {
        var pls = paths.filter(isPlaylistFile);
        pls.forEach(function (p) { importM3u(p, true); });
        var rest = paths.filter(function (p) { return !mp.isPlaylistFile(p); });
        if (!rest.length) return;
        // folders are expanded in the backend (audio inside, sorted)
        call("expand", { paths: rest }, function (ok, list) { if (ok) mp._playLoose(list); else mp.toast(list, true); });
    }
    function _playLoose(auds) {
        if (!auds.length) { toast(tx("No hay audio compatible ahí", "No compatible audio there"), true); return; }
        var m = tmap;
        auds.forEach(function (p) {
            if (!m[p]) m[p] = { p: p, t: baseName(p).replace(/\.[^.]+$/, ""), ar: "", al: "", aa: "", n: 0, dn: 0, y: "", g: "", dur: 0, art: "", lyr: false, ext: extOf(p), loose: true };
        });
        tmap = m;
        libRev++;
        playPaths(auds, 0, "");
    }

    // ───────────────────────── playlists ─────────────────────────
    function playlistById(id) { for (var i = 0; i < playlists.length; i++) if (playlists[i].id === id) return playlists[i]; return null; }
    // "Liked songs": built-in playlist, can't be deleted or renamed
    function ensureLiked() {
        if (playlistById("liked")) return;
        playlists = [{ id: "liked", fav: true, name: tx("Me gusta", "Liked songs"), desc: "", cover: "", tracks: [], created: Math.floor(Date.now() / 1000) }].concat(playlists);
        savePlaylists();
    }
    readonly property var likedSet: {
        var _p = plRev, m = {};
        var pl = playlistById("liked");
        if (pl) pl.tracks.forEach(function (p) { m[p] = true; });
        return m;
    }
    function isLiked(p) { return likedSet[p] === true; }
    function likePaths(paths) {
        paths = (paths || []).filter(Boolean);
        if (!paths.length) return;
        ensureLiked();
        var pl = playlistById("liked");
        if (!pl) return;
        var all = paths.every(function (p) { return likedSet[p]; });
        if (all) pl.tracks = pl.tracks.filter(function (p) { return paths.indexOf(p) < 0; });
        else {
            var have = {};
            pl.tracks.forEach(function (p) { have[p] = true; });
            pl.tracks = paths.filter(function (p) { return !have[p]; }).concat(pl.tracks);
        }
        savePlaylists();
        toast(all ? tx("Quitada de «Me gusta»", "Removed from Liked") : tx("Añadida a «Me gusta»", "Added to Liked"));
    }
    function savePlaylists() {
        // fresh copies: that way bindings showing a playlist notice the change
        playlists = playlists.map(function (p) { return Object.assign({}, p, { tracks: p.tracks.slice() }); });
        plRev++;
        call("playlists_save", { playlists: playlists });
    }
    function editPlaylist(id, fn) { var pl = playlistById(id); if (pl) { fn(pl); savePlaylists(); } }
    function createPlaylist(name, paths, cb) {
        var pl = { id: uid(), name: name, desc: "", cover: "", tracks: paths || [], created: Math.floor(Date.now() / 1000) };
        playlists = playlists.concat([pl]);
        savePlaylists();
        if (cb) cb(pl);
        return pl;
    }
    function addToPlaylist(id, paths) {
        var pl = playlistById(id);
        if (!pl) return;
        var have = {}, added = 0;
        pl.tracks.forEach(function (p) { have[p] = true; });
        paths.forEach(function (p) { if (!have[p]) { pl.tracks.push(p); have[p] = true; added++; } });
        savePlaylists();
        toast(added ? nSongs(added, tx("añadida", "added"), tx("añadidas", "added")) + tx(" a «", " to “") + pl.name + tx("»", "”")
                    : tx("Ya estaban en «", "Already in “") + pl.name + tx("»", "”"));
    }
    function removeFromPlaylist(id, indices) {
        var pl = playlistById(id);
        if (!pl) return;
        var s = {};
        indices.forEach(function (i) { s[i] = true; });
        pl.tracks = pl.tracks.filter(function (p, i) { return !s[i]; });
        clearSel();
        savePlaylists();
    }
    function movePlaylistItem(id, from, to) {
        var pl = playlistById(id);
        if (!pl || from === to || to < 0 || to >= pl.tracks.length) return;
        var x = pl.tracks.splice(from, 1)[0];
        pl.tracks.splice(to, 0, x);
        savePlaylists();
        var m = {}; m[to] = true; selIdx = m; selAnchor = to; selRev++;
    }
    function deletePlaylist(id) {
        var pl = playlistById(id);
        if (!pl || pl.fav) return;
        askConfirm(tx("Eliminar lista", "Delete playlist"),
                   tx("¿Eliminar «", "Delete “") + pl.name + tx("»? Las canciones no se borran.", "”? Songs are not deleted."),
                   tx("Eliminar", "Delete"), true, function () {
            mp.playlists = mp.playlists.filter(function (x) { return x.id !== id; });
            mp.savePlaylists();
            if (mp.view === "playlist" && mp.viewArg === id) mp.go("playlists");
        });
    }
    function newPlaylistDlg(paths) {
        askInput(tx("Nueva lista", "New playlist"), tx("Nombre de la lista", "Playlist name"), "", tx("Crear", "Create"), function (n) {
            var pl = mp.createPlaylist(n, paths || []);
            if (paths && paths.length) mp.toast(songsLabel(paths.length) + tx(" en «", " in “") + n + tx("»", "”"));
            else mp.go("playlist", pl.id);
        });
    }
    function renamePlaylistDlg(id) {
        var pl = playlistById(id);
        if (!pl || pl.fav) return;
        askInput(tx("Renombrar lista", "Rename playlist"), "", pl.name, tx("Guardar", "Save"), function (n) { mp.editPlaylist(id, function (x) { x.name = n; }); });
    }
    function descPlaylistDlg(id) {
        var pl = playlistById(id);
        if (!pl) return;
        askInput(tx("Descripción", "Description"), "", pl.desc || "", tx("Guardar", "Save"), function (n) { mp.editPlaylist(id, function (x) { x.desc = n; }); }, true);
    }
    function coverPlaylist(id) {
        var pl = playlistById(id);
        if (!pl) return;
        call("pick", { title: tx("Portada de la lista", "Playlist cover"), kind: "image" }, function (ok, d) {
            if (!ok || d.status !== "ok") { if (ok && d.status === "nopicker") mp.toast(mp.noPickerMsg(), true); return; }
            mp.call("playlist_cover", { file: d.paths[0] }, function (ok2, c) {
                if (!ok2) { mp.toast(c, true); return; }
                mp.editPlaylist(id, function (x) { x.cover = c; });
            });
        });
    }
    function exportPlaylist(id) {
        var pl = playlistById(id);
        if (!pl) return;
        var dest = (libDirs[0] || musicDir || home) + "/" + pl.name.replace(/[\/\\:*?"<>|]/g, "_") + ".m3u";
        call("export_m3u", { dest: dest, paths: pl.tracks }, function (ok, d) {
            if (ok) mp.toast(tx("Exportada a ", "Exported to ") + mp.prettyPath(d)); else mp.toast(d, true);
        });
    }
    function importM3u(path, play) {
        call("read_m3u", { path: path }, function (ok, list) {
            if (!ok) { mp.toast(list, true); return; }
            if (!list.length) { mp.toast(tx("La lista no tiene canciones accesibles", "The playlist has no reachable songs"), true); return; }
            var missing = list.filter(function (p) { return !mp.tmap[p] || mp.tmap[p].loose; });
            var finish = function () {
                var pl = mp.createPlaylist(mp.baseName(path).replace(/\.m3u8?$/i, ""), list);
                mp.toast(tx("Lista importada: ", "Playlist imported: ") + pl.name);
                if (play) mp.playPaths(list, 0, pl.name);
                else mp.go("playlist", pl.id);
            };
            if (!missing.length) { finish(); return; }
            mp.call("import", { paths: missing, mode: "add" }, function (ok2, d) {
                if (ok2) mp.upsertTracks(d.tracks);
                finish();
            });
        });
    }
    // playlist cover: its own, or a mosaic of its songs' covers
    function plArts(pl) {
        var _r = libRev;
        if (!pl) return [];
        if (pl.cover) return [pl.cover];
        var out = [], seen = {};
        for (var i = 0; i < pl.tracks.length && out.length < 4; i++) {
            var t = tmap[pl.tracks[i]];
            if (t && t.art && !seen[t.art]) { seen[t.art] = true; out.push(t.art); }
        }
        return out;
    }
    function plDuration(pl) { var _r = libRev; var s = 0; tracksOf(pl ? pl.tracks : []).forEach(function (t) { s += t.dur || 0; }); return s; }
    function sumDur(list) { var s = 0; for (var i = 0; i < list.length; i++) s += list[i].dur || 0; return s; }

    // ───────────────────────── remove / delete ─────────────────────────
    function removeFromLibrary(paths, toTrash) {
        if (!paths.length) return;
        var n = paths.length;
        var title = toTrash ? tx("Mover a la papelera", "Move to trash") : tx("Quitar de la biblioteca", "Remove from library");
        var txt = toTrash
            ? (n === 1 ? tx("El archivo «", "The file “") + baseName(paths[0]) + tx("» se moverá a la papelera.", "” will be moved to the trash.")
                       : songsLabel(n) + tx(" se moverán a la papelera.", " will be moved to the trash."))
            : (n === 1 ? tx("«", "“") + (trackOf(paths[0]) ? trackOf(paths[0]).t : baseName(paths[0])) + tx("» dejará de aparecer en la biblioteca. El archivo no se borra.", "” will no longer show in the library. The file is kept.")
                       : songsLabel(n) + tx(" dejarán de aparecer en la biblioteca. Los archivos no se borran.", " will no longer show in the library. Files are kept."));
        askConfirm(title, txt, toTrash ? tx("Mover a la papelera", "Move to trash") : tx("Quitar", "Remove"), true, function () {
            mp.call("remove", { paths: paths, trash: !!toTrash }, function (ok, done) {
                if (!ok) { mp.toast(done, true); return; }
                mp.dropTracks(done);
                var s = {};
                done.forEach(function (p) { s[p] = true; });
                var idx = [];
                mp.queue.forEach(function (p, i) { if (s[p]) idx.push(i); });
                if (idx.length) mp.removeFromQueue(idx);
                var plCh = false;
                mp.playlists.forEach(function (pl) { var l = pl.tracks.length; pl.tracks = pl.tracks.filter(function (p) { return !s[p]; }); if (pl.tracks.length !== l) plCh = true; });
                if (plCh) mp.savePlaylists();
                mp.clearSel();
                mp.toast(toTrash ? tx("Movido a la papelera", "Moved to trash") : tx("Quitado de la biblioteca", "Removed from library"));
            });
        });
    }
    function revealInFiles(p) {
        if (gs && typeof gs.openFileExplorer === "function") gs.openFileExplorer(dirName(p));
        else call("open_external", { path: dirName(p) });
    }
    function noPickerMsg() { return tx("No hay selector de archivos: instala zenity, kdialog o yad (o arrastra los archivos a la ventana)", "No file picker found: install zenity, kdialog or yad (or drag files onto the window)"); }

    // ───────────────────────── library folders ─────────────────────────
    function addLibDir() {
        call("pick", { title: tx("Carpeta de música", "Music folder"), kind: "dir" }, function (ok, d) {
            if (!ok || d.status !== "ok") { if (ok && d.status === "nopicker") mp.toast(mp.noPickerMsg(), true); return; }
            var dirs = mp.libDirs.slice();
            if (dirs.indexOf(d.paths[0]) < 0) dirs.push(d.paths[0]);
            mp.setLibDirs(dirs);
        });
    }
    function setLibDirs(dirs) {
        call("lib_dirs", { dirs: dirs }, function (ok, d) {
            if (!ok) { mp.toast(d, true); return; }
            mp.libDirs = d;
            mp.rescan(false);
        });
    }

    // ── import overlay ──
    property bool   impOpen: false
    property bool   impHover: false
    property string impState: ""         // "" | picking | copying | done
    property string impMsg: ""
    property string impKind: ""          // ok | warn | err
    property int    impDone: 0
    property int    impTotal: 0
    property string impCur: ""
    readonly property bool impBusy: impState === "picking" || impState === "copying"
    function impShow() {
        if (!impBusy) { impState = ""; impMsg = ""; }
        impCloseTimer.stop();
        impOpen = true;
    }
    Timer {
        id: impCloseTimer
        interval: 2200
        onTriggered: if (mp.impState === "done" && mp.impKind === "ok" && !mp.impHover) mp.impOpen = false
    }
    function impPick(kind) {
        if (impBusy) return;
        impCloseTimer.stop();
        impMsg = "";
        impState = "picking";
        call("pick", { title: kind === "dir" ? tx("Añadir carpeta de música", "Add music folder") : tx("Añadir música", "Add music"), kind: kind || "audio" }, function (ok, d) {
            if (!ok) { mp.impFinish("err", d); return; }
            if (d.status === "nopicker") { mp.impFinish("err", mp.noPickerMsg()); return; }
            if (d.status !== "ok") { mp.impState = ""; return; }
            mp.impRun(d.paths, 0);
        });
    }
    function impHandleDrop(drop) {
        impHover = false;
        impOpen = true;
        var local = [], extra = 0;
        if (drop.hasUrls) {
            for (var i = 0; i < drop.urls.length; i++) {
                var p = urlToPath(drop.urls[i]);
                if (p) local.push(p); else extra++;
            }
        }
        drop.accept(Qt.CopyAction);
        var pls = local.filter(isPlaylistFile);
        local = local.filter(function (p) { return !mp.isPlaylistFile(p); });
        pls.forEach(function (p) { mp.importM3u(p, false); });
        if (!local.length) {
            if (pls.length) { impOpen = false; return; }
            impFinish("err", tx("No se soltó ningún archivo local", "No local files were dropped"));
            return;
        }
        impRun(local, extra);
    }
    function impRun(paths, extraBad) {
        impState = "copying";
        impDone = 0; impTotal = 0; impCur = "";
        call("import", { paths: paths, mode: importMode }, function (ok, d) {
            if (!ok) { mp.impFinish("err", d); return; }
            mp.upsertTracks(d.tracks);
            var bad = d.bad + (extraBad || 0);
            var parts = [];
            if (d.add) parts.push(mp.importMode === "copy" ? mp.nSongs(d.add, tx("importada", "imported"), tx("importadas", "imported"))
                                                         : mp.nSongs(d.add, tx("añadida", "added"), tx("añadidas", "added")));
            if (d.dup) parts.push(d.dup + tx(" ya estaban en la biblioteca", " already in the library"));
            if (bad) parts.push(bad + tx(" no válidas o ilegibles", " invalid or unreadable"));
            var kind = d.add && !bad ? "ok" : (d.add || d.dup ? "warn" : "err");
            mp.impFinish(kind, parts.length ? parts.join(" · ") : tx("No se encontró audio compatible", "No compatible audio found"));
            if (d.add && mp.view !== "songs") mp.go("songs");
            if (d.add) { mp.sortKey = "added"; mp.sortAsc = true; }
        }, function (ev) { mp.impDone = ev.done; mp.impTotal = ev.total; mp.impCur = ev.cur || ""; });
    }
    function impFinish(kind, msg) {
        impKind = kind; impMsg = msg; impState = "done";
        impCloseTimer.restart();
    }

    // ───────────────────────── simple dialogs ─────────────────────────
    property string dlgKind: ""          // "" | input | confirm | addto | libdirs
    property string dlgTitle: ""
    property string dlgText: ""
    property string dlgValue: ""
    property string dlgOk: ""
    property bool   dlgDanger: false
    property bool   dlgMulti: false
    property var    dlgCb: null
    property var    dlgPaths: []
    function askInput(title, text, value, ok, cb, multi) {
        dlgTitle = title; dlgText = text || ""; dlgValue = value || ""; dlgOk = ok; dlgDanger = false; dlgMulti = !!multi; dlgCb = cb;
        dlgKind = "input";
    }
    function askConfirm(title, text, ok, danger, cb) {
        dlgTitle = title; dlgText = text || ""; dlgOk = ok; dlgDanger = !!danger; dlgCb = cb;
        dlgKind = "confirm";
    }
    function acceptDlg(v) {
        var cb = dlgCb, k = dlgKind;
        if (k === "input") { v = (v || "").trim(); if (!v && !dlgMulti) return; }
        dlgKind = ""; dlgCb = null;
        if (cb) cb(v);
        Qt.callLater(mp.refocus);
    }
    function closeDlg() { dlgKind = ""; dlgCb = null; Qt.callLater(mp.refocus); }
    function addToDlg(paths) { if (!paths.length) return; dlgPaths = paths; dlgTitle = tx("Añadir a una lista", "Add to playlist"); dlgKind = "addto"; }

    // ───────────────────────── context menu ─────────────────────────
    property var  menuItems: []
    readonly property var menuGroups: {
        var g = [[]];
        for (var i = 0; i < menuItems.length; i++) { if (menuItems[i].sep) g.push([]); else g[g.length - 1].push(menuItems[i]); }
        return g.filter(function (x) { return x.length > 0; });
    }
    property real menuX: 0
    property real menuY: 0
    property bool menuOpen: false
    function openMenu(items, x, y) {
        var out = [];
        for (var i = 0; i < items.length; i++) {
            var it = items[i];
            if (!it) continue;
            if (it.sep && (out.length === 0 || out[out.length - 1].sep)) continue;
            out.push(it);
        }
        while (out.length && out[out.length - 1].sep) out.pop();
        menuCol.implicitW = 0;
        menuItems = out;
        menuX = x; menuY = y;
        menuOpen = true;
    }
    function runMenu(it) {
        menuOpen = false;
        if (it && it.fn && !it.disabled) it.fn();
        Qt.callLater(mp.refocus);
    }
    function songMenu(i, x, y) {
        var t = curItems[i];
        if (!t) return;
        if (!isSel(i)) clickSel(i, 0);
        var ps = targetsFor(i);
        var one = ps.length === 1;
        var m = [];
        m.push({ icon: "play_arrow", label: tx("Reproducir", "Play"), key: "Enter", fn: function () { mp.playFromView(i); } });
        m.push({ icon: "queue_play_next", label: tx("Reproducir a continuación", "Play next"), fn: function () { mp.playNext(ps); } });
        m.push({ icon: "add_to_queue", label: tx("Añadir a la cola", "Add to queue"), fn: function () { mp.addToQueue(ps); } });
        m.push({ icon: "playlist_add", label: tx("Añadir a una lista…", "Add to playlist…"), fn: function () { mp.addToDlg(ps); } });
        m.push({ icon: "favorite", label: ps.every(function (p) { return mp.likedSet[p]; }) ? tx("Quitar de «Me gusta»", "Remove from Liked") : tx("Me gusta", "Like"), fn: function () { mp.likePaths(ps); } });
        m.push({ sep: true });
        m.push({ icon: "edit", label: one ? tx("Editar etiquetas…", "Edit tags…") : tx("Editar etiquetas de ", "Edit tags of ") + songsLabel(ps.length) + "…", key: "Ctrl+E", fn: function () { mp.openEditor(ps, "tags"); } });
        if (one) m.push({ icon: "lyrics", label: tx("Editar letra…", "Edit lyrics…"), fn: function () { mp.openEditor(ps, "tags", "lyrics"); } });
        if (one) m.push({ icon: "graphic_eq", label: tx("Sincronizar letra…", "Sync lyrics…"), key: "Ctrl+Y", fn: function () { mp.openLyricSync(ps[0]); } });
        if (!one) m.push({ icon: "library_music", label: tx("Crear álbum con la selección…", "Create album from selection…"), fn: function () { mp.openEditor(ps, "album"); } });
        m.push({ sep: true });
        if (one && t.al && view !== "album") m.push({ icon: "album", label: tx("Ir al álbum", "Go to album"), fn: function () { mp.go("album", mp.albumKeyOf(t)); } });
        if (one && view !== "artist") m.push({ icon: "artist", label: tx("Ir al artista", "Go to artist"), fn: function () { mp.go("artist", mp.albumArtistOf(t).toLowerCase()); } });
        if (one) m.push({ icon: "folder_open", label: tx("Mostrar en Archivos", "Show in Files"), fn: function () { mp.revealInFiles(t.p); } });
        m.push({ sep: true });
        if (view === "playlist" && ordered) m.push({ icon: "arrow_upward", label: tx("Subir", "Move up"), disabled: !one || i === 0, fn: function () { mp.movePlaylistItem(mp.viewArg, i, i - 1); } });
        if (view === "playlist" && ordered) m.push({ icon: "arrow_downward", label: tx("Bajar", "Move down"), disabled: !one || i >= curItems.length - 1, fn: function () { mp.movePlaylistItem(mp.viewArg, i, i + 1); } });
        if (view === "playlist" && ordered) m.push({ icon: "playlist_remove", label: tx("Quitar de la lista", "Remove from playlist"), key: "Supr", fn: function () { mp.removeFromPlaylist(mp.viewArg, mp.isSel(i) ? mp.selIndices() : [i]); } });
        if (view === "queue") {
            m.push({ icon: "arrow_upward", label: tx("Subir", "Move up"), disabled: !one || i === 0, fn: function () { mp.moveInQueue(i, i - 1); var s = {}; s[i - 1] = true; mp.selIdx = s; mp.selRev++; } });
            m.push({ icon: "arrow_downward", label: tx("Bajar", "Move down"), disabled: !one || i >= curItems.length - 1, fn: function () { mp.moveInQueue(i, i + 1); var s = {}; s[i + 1] = true; mp.selIdx = s; mp.selRev++; } });
            m.push({ icon: "remove_circle", label: tx("Quitar de la cola", "Remove from queue"), key: "Supr", fn: function () { mp.removeFromQueue(mp.isSel(i) ? mp.selIndices() : [i]); } });
        }
        m.push({ sep: true });
        if (!t.loose) m.push({ icon: "hide_source", label: tx("Quitar de la biblioteca", "Remove from library"), fn: function () { mp.removeFromLibrary(ps, false); } });
        m.push({ icon: "delete", label: tx("Mover a la papelera", "Move to trash"), danger: true, fn: function () { mp.removeFromLibrary(ps, true); } });
        openMenu(m, x, y);
    }
    // menu for a song outside a numbered list (home, related, player…)
    function trackMenu(t, x, y) {
        if (!t) return;
        var ps = [t.p];
        var m = [];
        m.push({ icon: "play_arrow", label: tx("Reproducir", "Play"), fn: function () { mp.playPaths(ps, 0, ""); } });
        m.push({ icon: "queue_play_next", label: tx("Reproducir a continuación", "Play next"), fn: function () { mp.playNext(ps); } });
        m.push({ icon: "add_to_queue", label: tx("Añadir a la cola", "Add to queue"), fn: function () { mp.addToQueue(ps); } });
        m.push({ icon: "playlist_add", label: tx("Añadir a una lista…", "Add to playlist…"), fn: function () { mp.addToDlg(ps); } });
        m.push({ icon: "favorite", label: isLiked(t.p) ? tx("Quitar de «Me gusta»", "Remove from Liked") : tx("Me gusta", "Like"), fn: function () { mp.likePaths(ps); } });
        m.push({ sep: true });
        m.push({ icon: "edit", label: tx("Editar etiquetas…", "Edit tags…"), fn: function () { mp.openEditor(ps, "tags"); } });
        m.push({ icon: "lyrics", label: tx("Editar letra…", "Edit lyrics…"), fn: function () { mp.openEditor(ps, "tags", "lyrics"); } });
        m.push({ icon: "graphic_eq", label: tx("Sincronizar letra…", "Sync lyrics…"), fn: function () { mp.openLyricSync(ps[0]); } });
        m.push({ sep: true });
        if (t.al && !t.loose) m.push({ icon: "album", label: tx("Ir al álbum", "Go to album"), fn: function () { mp.go("album", mp.albumKeyOf(t)); } });
        if (!t.loose) m.push({ icon: "artist", label: tx("Ir al artista", "Go to artist"), fn: function () { mp.go("artist", mp.albumArtistOf(t).toLowerCase()); } });
        m.push({ icon: "folder_open", label: tx("Mostrar en Archivos", "Show in Files"), fn: function () { mp.revealInFiles(t.p); } });
        openMenu(m, x, y);
    }
    // generic menu for a collection of songs (mixes, genres, decades…)
    function listMenu(name, paths, x, y) {
        openMenu([
            { icon: "play_arrow", label: tx("Reproducir", "Play"), disabled: !paths.length, fn: function () { mp.playPaths(paths, 0, name); } },
            { icon: "shuffle", label: tx("Aleatorio", "Shuffle"), disabled: !paths.length, fn: function () { mp.shufflePaths(paths, name); } },
            { icon: "queue_play_next", label: tx("Reproducir a continuación", "Play next"), disabled: !paths.length, fn: function () { mp.playNext(paths); } },
            { icon: "add_to_queue", label: tx("Añadir a la cola", "Add to queue"), disabled: !paths.length, fn: function () { mp.addToQueue(paths); } },
            { sep: true },
            { icon: "playlist_add", label: tx("Añadir a una lista…", "Add to playlist…"), disabled: !paths.length, fn: function () { mp.addToDlg(paths); } },
            { icon: "library_add", label: tx("Guardar como lista nueva…", "Save as new playlist…"), disabled: !paths.length, fn: function () { mp.newPlaylistDlg(paths); } }
        ], x, y);
    }
    function albumMenu(a, x, y) {
        var ps = a.tracks.map(function (t) { return t.p; });
        openMenu([
            { icon: "play_arrow", label: tx("Reproducir", "Play"), fn: function () { mp.playPaths(ps, 0, a.name); } },
            { icon: "shuffle", label: tx("Aleatorio", "Shuffle"), fn: function () { mp.shufflePaths(ps, a.name); } },
            { icon: "queue_play_next", label: tx("Reproducir a continuación", "Play next"), fn: function () { mp.playNext(ps); } },
            { icon: "add_to_queue", label: tx("Añadir a la cola", "Add to queue"), fn: function () { mp.addToQueue(ps); } },
            { icon: "playlist_add", label: tx("Añadir a una lista…", "Add to playlist…"), fn: function () { mp.addToDlg(ps); } },
            { sep: true },
            { icon: "edit", label: tx("Editar álbum…", "Edit album…"), fn: function () { mp.openEditor(ps, "album"); } },
            { icon: "artist", label: tx("Ir al artista", "Go to artist"), fn: function () { mp.go("artist", a.artist.toLowerCase()); } },
            { icon: "folder_open", label: tx("Mostrar en Archivos", "Show in Files"), fn: function () { mp.revealInFiles(ps[0]); } }
        ], x, y);
    }
    function artistMenu(a, x, y) {
        var ps = sortTracks(a.tracks, "album", true).map(function (t) { return t.p; });
        openMenu([
            { icon: "play_arrow", label: tx("Reproducir", "Play"), fn: function () { mp.playPaths(ps, 0, a.name); } },
            { icon: "shuffle", label: tx("Aleatorio", "Shuffle"), fn: function () { mp.shufflePaths(ps, a.name); } },
            { icon: "add_to_queue", label: tx("Añadir a la cola", "Add to queue"), fn: function () { mp.addToQueue(ps); } },
            { icon: "playlist_add", label: tx("Añadir a una lista…", "Add to playlist…"), fn: function () { mp.addToDlg(ps); } }
        ], x, y);
    }
    function playlistMenu(pl, x, y) {
        openMenu([
            { icon: "play_arrow", label: tx("Reproducir", "Play"), disabled: !pl.tracks.length, fn: function () { mp.playPaths(pl.tracks, 0, pl.name); } },
            { icon: "shuffle", label: tx("Aleatorio", "Shuffle"), disabled: !pl.tracks.length, fn: function () { mp.shufflePaths(pl.tracks, pl.name); } },
            { icon: "add_to_queue", label: tx("Añadir a la cola", "Add to queue"), disabled: !pl.tracks.length, fn: function () { mp.addToQueue(pl.tracks); } },
            { sep: true },
            { icon: "edit", label: tx("Renombrar…", "Rename…"), disabled: !!pl.fav, fn: function () { mp.renamePlaylistDlg(pl.id); } },
            { icon: "notes", label: tx("Descripción…", "Description…"), fn: function () { mp.descPlaylistDlg(pl.id); } },
            { icon: "add_photo_alternate", label: tx("Cambiar portada…", "Change cover…"), fn: function () { mp.coverPlaylist(pl.id); } },
            pl.cover ? { icon: "hide_image", label: tx("Quitar portada", "Remove cover"), fn: function () { mp.editPlaylist(pl.id, function (x) { x.cover = ""; }); } } : null,
            { icon: "ios_share", label: tx("Exportar como M3U", "Export as M3U"), disabled: !pl.tracks.length, fn: function () { mp.exportPlaylist(pl.id); } },
            { sep: true },
            { icon: "delete", label: tx("Eliminar lista", "Delete playlist"), danger: true, disabled: !!pl.fav, fn: function () { mp.deletePlaylist(pl.id); } }
        ], x, y);
    }
    function viewLabel() {
        return view === "album" && curAlbum ? curAlbum.name : view === "artist" && curArtist ? curArtist.name
             : view === "playlist" && curPlaylist ? curPlaylist.name : view === "collection" ? collection.name
             : view === "search" ? tx("Búsqueda: ", "Search: ") + search : "";
    }
    function playFromView(i) {
        var it = curItems;
        if (view === "queue") { loadIndex(i, true, 0); return; }
        var label = viewLabel();
        playPaths(it.map(function (t) { return t.p; }), i, label);
    }
    function playView(shuf) {
        var ps = curItems.map(function (t) { return t.p; });
        var label = viewLabel();
        if (shuf) shufflePaths(ps, label); else playPaths(ps, 0, label);
    }
    function deleteKey() {
        if (!selCount) return;
        if (view === "playlist" && ordered) removeFromPlaylist(viewArg, selIndices());
        else if (view === "queue") removeFromQueue(selIndices());
        else removeFromLibrary(selPaths(), false);
    }

    // ───────────────────────── tag editor ─────────────────────────
    property bool   edOpen: false
    property string edMode: "tags"       // tags | album
    property string edTab: "info"        // info | lyrics
    property var    edPaths: []
    property var    edInfo: null         // track_get of the first (or only) track
    property var    edVals: ({})         // shared initial values ("\u0000" = mixed)
    property bool   edLoading: false
    property bool   edSaving: false
    property string edCoverMode: "keep"  // keep | set | remove
    property string edCoverFile: ""
    property string edCoverShown: ""     // path of the image shown in the editor
    property bool   edNumber: false      // number tracks in the current order
    property string edLyrics: ""
    property bool   edLyricsDirty: false
    property bool   edLrcSidecar: false  // also save as .lrc
    property bool   edFetching: false
    property int    edRev: 0
    readonly property bool edMulti: edPaths.length > 1
    readonly property string mixedVal: "\u0000"
    readonly property var edFields: ["title", "artist", "album", "albumartist", "genre", "year", "track", "tracktotal", "disc", "disctotal", "composer", "comment"]

    function openEditor(paths, mode, tab) {
        paths = (paths || []).filter(function (p) { return !!p; });
        if (!paths.length) return;
        if (!hasMutagen) { toast(tx("Instala python-mutagen para editar etiquetas", "Install python-mutagen to edit tags"), true); return; }
        menuOpen = false;
        edPaths = paths;
        edMode = mode || "tags";
        edTab = tab === "lyrics" && paths.length === 1 ? "lyrics" : "info";
        edInfo = null; edVals = ({}); edCoverMode = "keep"; edCoverFile = ""; edCoverShown = "";
        edNumber = edMode === "album";
        edLyrics = ""; edLyricsDirty = false; edLrcSidecar = false; edSaving = false;
        edLoading = true;
        edOpen = true;
        var infos = [], left = Math.min(paths.length, 200);
        var sample = paths.slice(0, 200);
        sample.forEach(function (p, k) {
            call("track_get", { path: p }, function (ok, d) {
                infos[k] = ok ? d : null;
                if (--left > 0) return;
                mp.edFill(infos.filter(Boolean));
            });
        });
    }
    function edFill(infos) {
        edLoading = false;
        if (!infos.length) { toast(tx("No se pudieron leer las etiquetas", "Couldn't read tags"), true); edOpen = false; return; }
        edInfo = infos[0];
        var v = {};
        edFields.forEach(function (f) {
            var x = infos[0].tags[f] || "";
            for (var i = 1; i < infos.length; i++) if ((infos[i].tags[f] || "") !== x) { x = mp.mixedVal; break; }
            v[f] = x;
        });
        if (edMode === "album") {
            // when creating an album, values are suggested from the selection
            if (v.album === mixedVal || !v.album) v.album = v.album === mixedVal ? "" : v.album;
            if (v.albumartist === mixedVal || !v.albumartist) v.albumartist = v.artist !== mixedVal ? v.artist : "";
            if (v.year === mixedVal) v.year = "";
            if (v.genre === mixedVal) v.genre = "";
        }
        edVals = v;
        var arts = {}, nArt = 0;
        infos.forEach(function (d) { var a = d.embeddedArt ? d.art : ""; if (!arts[a]) { arts[a] = true; nArt++; } });
        edCoverShown = nArt === 1 ? (infos[0].embeddedArt ? infos[0].art : "") : (infos[0].art || "");
        edCoverMixed = nArt > 1;
        edFolderArt = infos[0].folderArt || "";
        edCoverOrig = edCoverShown;
        edCoverMixedOrig = edCoverMixed;
        var L = infos[0].tags.lyrics || "";
        if (!L.trim() && infos[0].lrcText) { L = infos[0].lrcText; edLrcSidecar = true; }
        else edLrcSidecar = !!infos[0].lrc;
        edLyrics = L;
        edLyricsDirty = false;
        edRev++;
    }
    property bool   edCoverMixed: false
    property string edFolderArt: ""
    property string edCoverOrig: ""
    property bool   edCoverMixedOrig: false
    function edResetCover() { edCoverMode = "keep"; edCoverFile = ""; edCoverShown = edCoverOrig; edCoverMixed = edCoverMixedOrig; }
    // stamps the current time on the cursor's line and moves down
    function stampLine(area) {
        var t = area.text, pos = area.cursorPosition;
        var ls = t.lastIndexOf("\n", pos - 1) + 1;
        var le = t.indexOf("\n", pos);
        if (le < 0) le = t.length;
        var line = t.substring(ls, le).replace(/^\s*(\[\d{1,3}:\d{1,2}(?:[.:]\d{1,3})?\])+\s*/, "");
        var s = Math.max(0, posSec - 0.2), m = Math.floor(s / 60), sec = s - m * 60;
        var ss = sec.toFixed(2);
        if (ss.length < 5) ss = "0" + ss;
        var st = "[" + (m < 10 ? "0" : "") + m + ":" + ss + "]";
        area.text = t.substring(0, ls) + st + line + t.substring(le);
        var np = ls + st.length + line.length + 1;
        area.cursorPosition = Math.min(np, area.text.length);
        area.forceActiveFocus();
    }
    function edPickCover() {
        call("pick", { title: tx("Elegir carátula", "Choose cover"), kind: "image" }, function (ok, d) {
            if (!ok || d.status !== "ok") { if (ok && d.status === "nopicker") mp.toast(mp.noPickerMsg(), true); return; }
            mp.edSetCover(d.paths[0]);
        });
    }
    function edSetCover(p) { edCoverMode = "set"; edCoverFile = p; edCoverShown = p; edCoverMixed = false; }
    function edRemoveCover() { edCoverMode = "remove"; edCoverFile = ""; edCoverShown = ""; edCoverMixed = false; }
    function edFetchLyrics() {
        if (!edInfo) return;
        var tg = edInfo.tags;
        var title = edFieldValue("title") || tg.title || (trackOf(edPaths[0]) ? trackOf(edPaths[0]).t : "");
        var artist = edFieldValue("artist") || tg.artist;
        if (!title) { toast(tx("Pon al menos el título para buscar la letra", "Set at least the title to search lyrics"), true); return; }
        edFetching = true;
        call("lyrics_fetch", { title: title, artist: artist, album: edFieldValue("album") || tg.album, duration: edInfo.duration }, function (ok, d) {
            mp.edFetching = false;
            if (!ok) { mp.toast(tx("No se pudo buscar la letra: ", "Lyrics search failed: ") + d, true); return; }
            if (!d.found) { mp.toast(tx("No se encontró letra para esta canción", "No lyrics found for this song"), true); return; }
            mp.edLyrics = d.synced || d.plain;
            mp.edLyricsDirty = true;
            mp.edRev++;
            mp.toast(d.synced ? tx("Letra sincronizada encontrada", "Synced lyrics found") : tx("Letra encontrada (sin sincronizar)", "Lyrics found (not synced)"));
        });
    }
    function edImportLrc() {
        call("pick", { title: tx("Importar letra", "Import lyrics"), kind: "lrc" }, function (ok, d) {
            if (!ok || d.status !== "ok") { if (ok && d.status === "nopicker") mp.toast(mp.noPickerMsg(), true); return; }
            mp.call("read_text", { path: d.paths[0] }, function (ok2, txt) {
                if (!ok2) { mp.toast(txt, true); return; }
                mp.edLyrics = txt; mp.edLyricsDirty = true; mp.edRev++;
            });
        });
    }
    // edFieldValue / edCollect read the dialog fields (defined in the UI)
    property var edFieldItems: ({})
    function edFieldValue(f) { var it = edFieldItems[f]; return it ? it.text.trim() : ""; }
    function edSave() {
        if (edSaving || !edInfo) return;
        var changes = {};
        edFields.forEach(function (f) {
            var it = mp.edFieldItems[f];
            if (!it || !it.visible) return;
            var nv = it.text.trim(), ov = mp.edVals[f];
            if (ov === mp.mixedVal) { if (it.touched) changes[f] = nv; }
            else if (nv !== (ov || "")) changes[f] = nv;
        });
        var per = {};
        if (edMulti && edNumber) {
            edPaths.forEach(function (p, i) { per[p] = { track: String(i + 1), tracktotal: String(mp.edPaths.length) }; });
            delete changes.track; delete changes.tracktotal;
        }
        var lyricsDirty = edLyricsDirty && !edMulti;
        if (lyricsDirty) changes.lyrics = edLyrics;
        var cover = { mode: edCoverMode, file: edCoverFile };
        if (!Object.keys(changes).length && !Object.keys(per).length && edCoverMode === "keep" && !(lyricsDirty)) { edOpen = false; return; }
        edSaving = true;
        var paths = edPaths.slice();
        var afterLrc = function () {
            mp.call("tags_write", { paths: paths, tags: changes, perTrack: per, cover: cover,
                                    lrcSidecar: lyricsDirty && !mp.edLrcSidecar ? "delete" : "" }, function (ok, d) {
                mp.edSaving = false;
                if (!ok) { mp.toast(d, true); return; }
                mp.upsertTracks(d.tracks);
                if (d.errors && d.errors.length) mp.toast(tx("Algunos archivos no se pudieron guardar: ", "Some files couldn't be saved: ") + d.errors.slice(0, 2).join("; "), true);
                else mp.toast(paths.length === 1 ? tx("Etiquetas guardadas", "Tags saved") : mp.nSongs(paths.length, "", tx("actualizadas", "updated")));
                mp.edOpen = false;
                if (mp.edMode === "album" && changes.album) {
                    var t = mp.tmap[paths[0]];
                    if (t && t.al) mp.go("album", mp.albumKeyOf(t));
                }
                Qt.callLater(mp.refocus);
            }, function (ev) {});
        };
        if (lyricsDirty && edLrcSidecar) call("lrc_save", { path: paths[0], text: edLyrics }, function () { afterLrc(); });
        else afterLrc();
    }

    // quick lyrics from the panel: searches LRCLIB and saves them into the file
    property bool npFetching: false
    function quickFetchLyrics() {
        var t = cur, p = curPath;
        if (!t || npFetching) return;
        npFetching = true;
        call("lyrics_fetch", { title: t.t, artist: t.ar || t.aa, album: t.al, duration: durSec }, function (ok, d) {
            if (!ok) { mp.npFetching = false; mp.toast(tx("No se pudo buscar la letra: ", "Lyrics search failed: ") + d, true); return; }
            if (!d.found) { mp.npFetching = false; mp.toast(tx("No se encontró letra para esta canción", "No lyrics found for this song"), true); return; }
            mp.call("tags_write", { paths: [p], tags: { lyrics: d.synced || d.plain } }, function (ok2, r) {
                mp.npFetching = false;
                if (!ok2) {
                    // no write permission: at least show them
                    if (p === mp.curPath) mp.lyr = mp.parseLrc(d.synced || d.plain);
                    mp.toast(tx("Letra encontrada, pero no se pudo guardar: ", "Lyrics found but couldn't be saved: ") + r, true);
                    return;
                }
                mp.upsertTracks(r.tracks);
                mp.toast(d.synced ? tx("Letra sincronizada guardada en el archivo", "Synced lyrics saved to the file") : tx("Letra guardada en el archivo", "Lyrics saved to the file"));
            });
        });
    }

    // ───────────────────────── sync editor (LyricSync.qml) ─────────────────────────
    readonly property bool lsOpen: lyrSync.open
    function openLyricSync(p, text) {
        if (!p) return;
        if (!hasMutagen) { toast(tx("Instala python-mutagen para editar letras", "Install python-mutagen to edit lyrics"), true); return; }
        menuOpen = false;
        if (lyrFull) setLyrFull(false);
        edOpen = false;
        lyrSync.openFor(p, text || "");
    }

    function refocus() { if (keyRoot) keyRoot.forceActiveFocus(); }

    // ══ UI ══
    property bool railCollapsed: false
    readonly property bool sideCompact: width < px(1040) || railCollapsed
    Spring { id: railSpring; token: "spatialDefault"; eps: 0.1; target: mp.sideCompact ? mp.px(96) : mp.px(236) }
    readonly property real sideW: railSpring.value
    readonly property real railE: Math.max(0, Math.min(1, (sideW - px(96)) / px(140)))
    readonly property real topH: px(80)
    readonly property real barH: px(96)

    Shortcut { sequence: "Escape"; enabled: mp.menuOpen || mp.dlgKind !== "" || mp.impOpen || mp.edOpen || mp.lyrFull || mp.playerOpen || mp.lsOpen
        onActivated: {
            if (mp.menuOpen) mp.menuOpen = false;
            else if (mp.lsOpen) { lyrSync.escapeKey(); return; }
            else if (mp.dlgKind !== "") mp.closeDlg();
            else if (mp.edOpen) { if (!mp.edSaving) mp.edOpen = false; }
            else if (mp.impOpen && !mp.impBusy) mp.impOpen = false;
            else if (mp.lyrFull) mp.setLyrFull(false);
            else if (mp.playerOpen) mp.playerOpen = false;
            Qt.callLater(mp.refocus);
        }
    }
    readonly property bool modal: menuOpen || dlgKind !== "" || impOpen || edOpen || lsOpen
    Shortcut { sequence: "Ctrl+F"; enabled: !mp.modal; onActivated: { searchField.input.forceActiveFocus(); searchField.input.selectAll(); } }
    Shortcut { sequence: "Ctrl+I"; enabled: !mp.modal; onActivated: mp.impShow() }
    Shortcut { sequence: "Ctrl+E"; enabled: !mp.modal; onActivated: { var p = mp.selCount ? mp.selPaths() : (mp.curPath ? [mp.curPath] : []); if (p.length) mp.openEditor(p, "tags"); } }
    Shortcut { sequence: "Ctrl+L"; enabled: !mp.modal; onActivated: mp.playerOpen = !mp.playerOpen }
    Shortcut { sequence: "Ctrl+Y"; enabled: !mp.modal; onActivated: { var p = mp.selCount === 1 ? mp.selPaths()[0] : mp.curPath; if (p) mp.openLyricSync(p); } }
    Shortcut { sequence: "Ctrl+S"; enabled: !mp.modal; onActivated: mp.toggleShuffle() }
    Shortcut { sequence: "Ctrl+R"; enabled: !mp.modal; onActivated: mp.cycleRepeat() }
    Shortcut { sequence: "Ctrl+N"; enabled: !mp.modal; onActivated: mp.newPlaylistDlg([]) }
    Shortcut { sequence: "Ctrl+Q"; onActivated: { if (mp.gs) mp.gs.musicPlayerOpen = false; else mp.close(); } }
    Shortcut { sequence: "F5"; enabled: !mp.modal; onActivated: mp.rescan(false) }
    Shortcut { sequence: "F11"; enabled: !mp.modal; onActivated: { if (!mp.lyrFull) mp.panelTab = "lyrics"; mp.setLyrFull(!mp.lyrFull); } }
    Shortcut { sequences: ["Media Play", "Media Pause", "Toggle Media Play/Pause"]; onActivated: mp.togglePlay() }
    Shortcut { sequence: "Media Next"; onActivated: mp.next(false) }
    Shortcut { sequence: "Media Previous"; onActivated: mp.prev() }

    Item {
        id: keyRoot
        anchors.fill: parent
        focus: true
        Keys.onPressed: (e) => {
            if (mp.modal) return;
            var ctrl = e.modifiers & Qt.ControlModifier, alt = e.modifiers & Qt.AltModifier;
            if (e.key === Qt.Key_Space) { mp.togglePlay(); e.accepted = true; }
            else if (e.key === Qt.Key_Right && ctrl) { mp.next(false); e.accepted = true; }
            else if (e.key === Qt.Key_Left && ctrl) { mp.prev(); e.accepted = true; }
            else if (e.key === Qt.Key_Left && alt) { mp.back(); e.accepted = true; }
            else if (e.key === Qt.Key_Backspace) { mp.back(); e.accepted = true; }
            else if (e.key === Qt.Key_Right) { mp.seekBy(5); e.accepted = true; }
            else if (e.key === Qt.Key_Left) { mp.seekBy(-5); e.accepted = true; }
            else if ((e.key === Qt.Key_Up || e.key === Qt.Key_Down) && alt && mp.ordered && mp.selCount === 1) {
                var i = mp.selIndices()[0], j = i + (e.key === Qt.Key_Up ? -1 : 1);
                if (j >= 0 && j < mp.curItems.length) {
                    if (mp.view === "queue") { mp.moveInQueue(i, j); var s = {}; s[j] = true; mp.selIdx = s; mp.selRev++; }
                    else mp.movePlaylistItem(mp.viewArg, i, j);
                }
                e.accepted = true;
            }
            else if (e.key === Qt.Key_Up && !ctrl) { mp.setVolume(mp.volume + 0.05); e.accepted = true; }
            else if (e.key === Qt.Key_Down && !ctrl) { mp.setVolume(mp.volume - 0.05); e.accepted = true; }
            else if (e.key === Qt.Key_M && !ctrl) { mp.muted = !mp.muted; e.accepted = true; }
            else if (e.key === Qt.Key_A && ctrl) { mp.selectAll(); e.accepted = true; }
            else if (e.key === Qt.Key_Delete) { mp.deleteKey(); e.accepted = true; }
            else if ((e.key === Qt.Key_Return || e.key === Qt.Key_Enter) && mp.selCount) { mp.playFromView(mp.selIndices()[0]); e.accepted = true; }
        }

    Rectangle {
        id: rootBg
        anchors.fill: parent
        color: mp.lyrFull ? mp.bgLyrFull : mp.bgWindow
        Behavior on color { ColorAnimation { duration: 340; easing.type: Easing.OutCubic } }
        clip: true

        // ───────────── top bar: rail menu · search · add music ─────────────
        Item {
            id: topBar
            opacity: (1 - mp.ppProg) * mp.uiVis
            visible: mp.ppProg < 0.995 && mp.uiVis > 0.01
            transform: Translate { y: -mp.ppProg * px(90) }
            x: 0; y: 0
            width: parent.width
            height: mp.topH
            z: 20
            IconBtn {
                id: railBtn
                x: (px(96) - width) / 2
                anchors.verticalCenter: parent.verticalCenter
                glyph: mp.sideCompact ? "menu" : "menu_open"
                enabled: mp.width >= px(1040)
                tip: mp.sideCompact ? mp.tx("Expandir", "Expand") : mp.tx("Contraer", "Collapse")
                onClicked: mp.railCollapsed = !mp.railCollapsed
            }
            Row {
                id: logoRow
                x: px(84)
                anchors.verticalCenter: parent.verticalCenter
                spacing: px(10)
                opacity: mp.railE
                visible: opacity > 0.01
                ShapeView {
                    anchors.verticalCenter: parent.verticalCenter
                    width: px(36); height: width
                    from: "Cookie9Sided"; to: "Cookie9Sided"
                    fill: mp.cPrimCont
                    Glyph { anchors.centerIn: parent; text: "library_music"; size: px(20); color: mp.m3OnPrimCont }
                }
                T {
                    anchors.verticalCenter: parent.verticalCenter
                    role: "titleLarge"
                    emph: true
                    text: mp.tx("Música", "Music")
                }
            }
            IconBtn {
                id: backBtn
                x: mp.sideW + px(4)
                anchors.verticalCenter: parent.verticalCenter
                visible: mp.canBack
                variant: "tonal"
                glyph: "arrow_back"
                tip: mp.tx("Volver (Alt+←)", "Back (Alt+←)")
                onClicked: mp.back()
            }
            Item {
                id: searchWrap
                anchors.left: parent.left; anchors.leftMargin: mp.sideW + px(56)
                anchors.right: topRight.left; anchors.rightMargin: px(16)
                anchors.verticalCenter: parent.verticalCenter
                height: px(56)
                Field {
                    id: searchField
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.min(px(720), parent.width)
                    height: px(56)
                    color: mp.m3High
                    glyph: "search"
                    placeholder: mp.tx("Busca canciones, álbumes, artistas y listas", "Search songs, albums, artists and playlists")
                    onEdited: (t) => { if (t.trim() !== "") mp.openSearch(); mp.search = t; }
                    onEscaped: { if (text !== "") { text = ""; mp.search = ""; } else if (mp.view === "search") mp.back(); else mp.refocus(); }
                    onAccepted: mp.refocus()
                    IconBtn {
                        visible: searchField.text !== ""
                        glyph: "close"
                        onClicked: { searchField.text = ""; mp.search = ""; }
                    }
                    Connections { target: mp; function onSearchChanged() { if (searchField.text !== mp.search) searchField.text = mp.search; } }
                }
            }
            Row {
                id: topRight
                anchors.right: parent.right; anchors.rightMargin: px(20)
                anchors.verticalCenter: parent.verticalCenter
                spacing: px(8)
                PillBtn { visible: !mp.sideCompact; glyph: "library_add"; label: mp.tx("Añadir música", "Add music"); primary: true; implicitHeight: px(48); onClicked: mp.impShow() }
                IconBtn { visible: mp.sideCompact; variant: "filled"; implicitWidth: px(48); implicitHeight: px(48); glyph: "library_add"; tip: mp.tx("Añadir música (Ctrl+I)", "Add music (Ctrl+I)"); onClicked: mp.impShow() }
            }
        }

        // ── navigation rail ──
        Item {
            id: sidebar
            opacity: (1 - mp.ppProg) * mp.uiVis
            visible: mp.ppProg < 0.995 && mp.uiVis > 0.01
            transform: Translate { y: -mp.ppProg * px(90) }
            x: 0; y: mp.topH
            width: mp.sideW
            height: parent.height - mp.topH - mp.barH
            clip: true

            Column {
                id: sideTop
                x: px(12); y: px(4)
                width: parent.width - px(24)
                spacing: px(2)
                Item {
                    width: parent.width
                    height: px(76)
                    EFab {
                        x: (parent.width - width) / 2 * (1 - mp.railE) + px(4) * mp.railE
                        y: px(4)
                        glyph: "add"
                        text: mp.tx("Nueva lista", "New playlist")
                        extended: !mp.sideCompact
                        tone: "tertiary"
                        tip: mp.tx("Nueva lista (Ctrl+N)", "New playlist (Ctrl+N)")
                        onClicked: mp.newPlaylistDlg([])
                    }
                }
                NavItem { width: parent.width; compact: mp.sideCompact; glyph: "home"; label: mp.tx("Inicio", "Home"); active: mp.view === "home"; onClicked: mp.go("home") }
                NavItem { width: parent.width; compact: mp.sideCompact; glyph: "explore"; label: mp.tx("Explorar", "Explore"); active: mp.view === "explore" || mp.view === "collection"; onClicked: mp.go("explore") }
                NavItem { width: parent.width; compact: mp.sideCompact; glyph: "library_music"; label: mp.tx("Biblioteca", "Library"); active: mp.isLibView; onClicked: mp.go(mp.libTab) }
                NavItem { width: parent.width; compact: mp.sideCompact; glyph: "cloud_download"; label: mp.tx("En línea", "Online"); active: mp.view === "online"; onClicked: { mp.go("online"); mp.onlineCheck(); Qt.callLater(function () { onlField.input.forceActiveFocus(); }); } }
                Item { width: 1; height: px(12) }
                T {
                    x: px(16)
                    visible: mp.railE > 0.01
                    opacity: mp.railE
                    role: "titleSmall"
                    emph: true
                    text: mp.tx("Tus listas", "Your playlists")
                    color: mp.cOnSurfVar
                    bottomPadding: px(6)
                }
            }

            ListView {
                id: sidePl
                visible: mp.railE > 0.01
                opacity: mp.railE
                anchors.top: sideTop.bottom
                anchors.bottom: sideFoot.top
                x: px(12)
                width: parent.width - px(24)
                clip: true
                spacing: px(2)
                boundsBehavior: Flickable.StopAtBounds
                model: { var _p = mp.plRev; return mp.playlists.slice(); }
                ScrollBar.vertical: ScrollBarX {}
                delegate: Item {
                    id: spd
                    required property var modelData
                    width: sidePl.width
                    height: px(60)
                    readonly property bool act: mp.view === "playlist" && mp.viewArg === modelData.id
                    Spring { id: spdSel; token: "spatialFast"; eps: 0.002; target: spd.act ? 1 : 0 }
                    Spring { id: spdHovS; token: "effectsFast"; target: spdMa.containsMouse ? 1 : 0 }
                    Rectangle { anchors.fill: parent; radius: px(30); color: mp.cOnSurface; opacity: 0.08 * Math.max(0, spdHovS.value) }
                    Rectangle {
                        height: parent.height
                        width: parent.width * Math.max(0, spdSel.value)
                        radius: px(30)
                        color: mp.m3SecCont
                        visible: spdSel.value > 0.01
                    }
                    Mosaic {
                        id: spdArt
                        x: px(10); anchors.verticalCenter: parent.verticalCenter
                        width: px(40); height: width; r: px(12)
                        glyph: spd.modelData.fav ? "favorite" : "queue_music"
                        arts: { var _r = mp.libRev, _p = mp.plRev; return mp.plArts(spd.modelData); }
                    }
                    Column {
                        anchors.left: spdArt.right; anchors.leftMargin: px(12)
                        anchors.right: parent.right; anchors.rightMargin: px(14)
                        anchors.verticalCenter: parent.verticalCenter
                        T {
                            width: parent.width
                            role: "labelLarge"
                            emph: spd.act
                            text: spd.modelData.name
                            color: spd.act ? mp.m3OnSecCont : mp.cOnSurface
                        }
                        T {
                            width: parent.width
                            role: "bodySmall"
                            text: { var _p = mp.plRev; return mp.tx("Lista", "Playlist") + " · " + mp.songsLabel(spd.modelData.tracks.length); }
                            color: spd.act ? mp.m3OnSecCont : mp.cOnSurfVar
                        }
                    }
                    MouseArea {
                        id: spdMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: (m) => {
                            if (m.button === Qt.RightButton) { var g = mapToItem(rootBg, m.x, m.y); mp.playlistMenu(spd.modelData, g.x, g.y); }
                            else mp.go("playlist", spd.modelData.id);
                        }
                        onDoubleClicked: if (spd.modelData.tracks.length) mp.playPaths(spd.modelData.tracks, 0, spd.modelData.name)
                    }
                }
            }

            Item {
                id: sideFoot
                anchors.bottom: parent.bottom
                x: px(12)
                width: parent.width - px(24)
                height: mp.sideCompact ? px(100) : px(64)
                Column {
                    visible: mp.railE > 0.01
                    opacity: mp.railE
                    anchors.left: parent.left; anchors.leftMargin: px(12)
                    anchors.right: footBtns.left; anchors.rightMargin: px(6)
                    anchors.verticalCenter: parent.verticalCenter
                    T {
                        width: parent.width
                        role: "labelLarge"
                        text: mp.scanning ? mp.tx("Buscando música…", "Scanning…") : mp.songsLabel(mp.tracks.length)
                        color: mp.cOnSurface
                    }
                    T {
                        width: parent.width
                        role: "bodySmall"
                        text: mp.scanning ? (mp.scanTotal ? mp.scanDone + " / " + mp.scanTotal : "") : mp.fmtLong(mp.sumDur(mp.tracks))
                        color: mp.cOnSurfVar
                    }
                }
                Row {
                    id: footBtns
                    visible: !mp.sideCompact
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    IconBtn { glyph: "refresh"; tip: mp.tx("Volver a escanear (F5)", "Rescan (F5)"); enabled: !mp.scanning; onClicked: mp.rescan(false) }
                    IconBtn { glyph: "folder_managed"; tip: mp.tx("Carpetas de la biblioteca", "Library folders"); onClicked: mp.dlgKind = "libdirs" }
                }
                Column {
                    visible: mp.sideCompact
                    anchors.centerIn: parent
                    spacing: px(4)
                    IconBtn { anchors.horizontalCenter: parent.horizontalCenter; glyph: "refresh"; tip: mp.tx("Volver a escanear (F5)", "Rescan (F5)"); enabled: !mp.scanning; onClicked: mp.rescan(false) }
                    IconBtn { anchors.horizontalCenter: parent.horizontalCenter; glyph: "folder_managed"; tip: mp.tx("Carpetas de la biblioteca", "Library folders"); onClicked: mp.dlgKind = "libdirs" }
                }
            }
        }

        // ───────────── main area ─────────────
        Item {
            id: mainArea
            opacity: (1 - mp.ppProg) * mp.uiVis
            visible: mp.ppProg < 0.995 && mp.uiVis > 0.01
            transform: Translate { y: -mp.ppProg * px(90) }
            x: mp.sideW
            y: mp.topH
            width: parent.width - mp.sideW - px(12)
            height: parent.height - mp.topH - mp.barH

            Rectangle { anchors.fill: parent; radius: px(32); color: mp.bgPane }

            // page header: «Library» + tabs, or the search filters
            Item {
                id: pageHead
                width: parent.width
                height: mp.isLibView ? px(132) : (mp.view === "search" ? px(64) : 0)
                visible: height > 1
                clip: true
                Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                Column {
                    visible: mp.isLibView
                    x: px(28); y: px(18)
                    spacing: px(2)
                    T { role: "labelLarge"; emph: true; text: (mp.songsLabel(mp.tracks.length) + "  ·  " + mp.fmtLong(mp.sumDur(mp.tracks))).toUpperCase(); color: mp.cPrimary; font.letterSpacing: 1.1 }
                    T { role: "displaySmall"; emph: true; text: mp.tx("Biblioteca", "Library") }
                }
                Row {
                    id: chipRow
                    x: px(28)
                    y: mp.isLibView ? px(90) : px(18)
                    spacing: px(8)
                    Repeater {
                        model: mp.isLibView
                            ? [{ v: "playlists", l: mp.tx("Listas", "Playlists") }, { v: "songs", l: mp.tx("Canciones", "Songs") },
                               { v: "albums", l: mp.tx("Álbumes", "Albums") }, { v: "artists", l: mp.tx("Artistas", "Artists") }]
                            : [{ v: "all", l: mp.tx("Todo", "All") }, { v: "songs", l: mp.tx("Canciones", "Songs") },
                               { v: "albums", l: mp.tx("Álbumes", "Albums") }, { v: "artists", l: mp.tx("Artistas", "Artists") },
                               { v: "playlists", l: mp.tx("Listas", "Playlists") }]
                        delegate: Chip {
                            required property var modelData
                            label: modelData.l
                            active: mp.isLibView ? mp.view === modelData.v : mp.searchTab === modelData.v
                            onClicked: { if (mp.isLibView) mp.go(modelData.v); else mp.searchTab = modelData.v; }
                        }
                    }
                }
                Row {
                    anchors.right: parent.right; anchors.rightMargin: px(20)
                    y: chipRow.y
                    height: px(34)
                    PillBtn {
                        visible: mp.view === "search" && mp.search.trim() !== ""
                        anchors.verticalCenter: parent.verticalCenter
                        glyph: "cloud_download"
                        label: mp.tx("Buscar en línea", "Search online")
                        onClicked: { var q = mp.search; mp.go("online"); onlField.text = q; mp.onlineCheck(); mp.onlineSearch(q); }
                    }
                    IconBtn {
                        visible: mp.view === "songs"
                        anchors.verticalCenter: parent.verticalCenter
                        glyph: "sort"
                        tip: mp.tx("Ordenar", "Sort")
                        onClicked: {
                            var g = mapToItem(rootBg, 0, height + 4);
                            var opt = function (k, l, ic) {
                                return { icon: mp.sortKey === k ? (mp.sortAsc ? "arrow_upward" : "arrow_downward") : ic, label: l,
                                         fn: function () { if (mp.sortKey === k) mp.sortAsc = !mp.sortAsc; else { mp.sortKey = k; mp.sortAsc = true; } } };
                            };
                            mp.openMenu([
                                opt("title", mp.tx("Título", "Title"), "title"),
                                opt("artist", mp.tx("Artista", "Artist"), "artist"),
                                opt("album", mp.tx("Álbum", "Album"), "album"),
                                opt("year", mp.tx("Año", "Year"), "calendar_month"),
                                opt("dur", mp.tx("Duración", "Duration"), "timer"),
                                opt("added", mp.tx("Añadidas recientemente", "Recently added"), "schedule")
                            ], g.x - px(180), g.y);
                        }
                    }
                }
            }

            // multi-selection bar
            Rectangle {
                id: selBar
                anchors.top: pageHead.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(parent.width - px(32), selRow.implicitWidth + px(24))
                height: mp.selCount > 1 ? px(64) : 0
                opacity: mp.selCount > 1 ? 1 : 0
                visible: height > 1
                clip: true
                radius: px(32)
                color: mp.m3High
                z: 5
                Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 160 } }
                Row {
                    id: selRow
                    anchors.centerIn: parent
                    spacing: px(4)
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: mp.selCount + " " + mp.tx("seleccionadas", "selected") + "   "
                        font.family: mp.fontB; font.pixelSize: px(14); font.weight: Font.DemiBold
                        color: mp.cPrimary
                        leftPadding: px(6)
                    }
                    IconBtn { glyph: "play_arrow"; tip: mp.tx("Reproducir selección", "Play selection"); onClicked: mp.playPaths(mp.selPaths(), 0, "") }
                    IconBtn { glyph: "queue_play_next"; tip: mp.tx("Reproducir a continuación", "Play next"); onClicked: mp.playNext(mp.selPaths()) }
                    IconBtn { glyph: "add_to_queue"; tip: mp.tx("Añadir a la cola", "Add to queue"); onClicked: mp.addToQueue(mp.selPaths()) }
                    IconBtn { glyph: "playlist_add"; tip: mp.tx("Añadir a una lista", "Add to playlist"); onClicked: mp.addToDlg(mp.selPaths()) }
                    IconBtn { glyph: "edit"; tip: mp.tx("Editar etiquetas", "Edit tags"); onClicked: mp.openEditor(mp.selPaths(), "tags") }
                    IconBtn { glyph: "library_music"; tip: mp.tx("Crear álbum con la selección", "Create album from selection"); onClicked: mp.openEditor(mp.selPaths(), "album") }
                    IconBtn {
                        glyph: mp.view === "queue" ? "remove_circle" : mp.view === "playlist" ? "playlist_remove" : "hide_source"
                        danger: true
                        tip: mp.view === "queue" ? mp.tx("Quitar de la cola", "Remove from queue") : mp.view === "playlist" ? mp.tx("Quitar de la lista", "Remove from playlist") : mp.tx("Quitar de la biblioteca", "Remove from library")
                        onClicked: mp.deleteKey()
                    }
                    IconBtn { glyph: "close"; tip: mp.tx("Deseleccionar", "Clear selection"); onClicked: mp.clearSel() }
                }
            }

            // content
            Item {
                id: content
                anchors.top: selBar.bottom
                anchors.topMargin: selBar.visible ? px(6) : 0
                anchors.bottom: parent.bottom
                width: parent.width

                // song lists (songs, album, artist, playlist, queue)
                ListView {
                    id: songList
                    anchors.fill: parent
                    visible: mp.listMode && !emptyLib.visible && !mp.searchBlank
                    clip: true
                    model: mp.curItems
                    reuseItems: true
                    cacheBuffer: px(600)
                    boundsBehavior: Flickable.StopAtBounds
                    interactive: false
                    readonly property bool wide: width > px(700)
                    // header height changes per view: scroll to top once laid out
                    function toTop() { positionViewAtBeginning(); toTopTimer.restart(); }
                    Timer { id: toTopTimer; interval: 30; onTriggered: { songList.contentY = songList.originY; songList.positionViewAtBeginning(); } }
                    readonly property bool showAlbumCol: wide && mp.view !== "album"
                    readonly property bool showCover: mp.view !== "album"
                    header: Column {
                        width: songList.width
                        Loader {
                            width: parent.width
                            sourceComponent: mp.view === "album" ? albumHero : mp.view === "artist" ? artistHero
                                           : mp.view === "playlist" ? playlistHero : mp.view === "queue" ? queueHero
                                           : mp.view === "collection" ? collectionHero
                                           : mp.view === "search" ? (mp.searchTab === "all" ? searchHero : searchSongsHero) : songsHero
                        }
                        Item {
                            width: parent.width
                            height: px(34)
                            visible: mp.curItems.length > 0
                            Row {
                                x: px(28); width: parent.width - px(48)
                                height: parent.height
                                Item {
                                    width: px(40); height: parent.height
                                    Text { anchors.centerIn: parent; text: "#"; font.family: mp.fontB; font.pixelSize: px(12); color: mp.cMuted }
                                }
                                Item { width: songList.showCover ? px(60) : px(4); height: 1 }
                                ColHead {
                                    width: parent.width - px(40) - (songList.showCover ? px(60) : px(4)) - (songList.showAlbumCol ? parent.width * 0.28 : 0) - px(152)
                                    label: mp.tx("Título", "Title"); key: "title"
                                }
                                ColHead { visible: songList.showAlbumCol; width: parent.width * 0.28; label: mp.tx("Álbum", "Album"); key: "album" }
                                Item { width: px(44); height: 1 }
                                ColHead { width: px(64); label: mp.tx("Duración", "Time"); key: "dur"; alignRight: true }
                            }
                            Item { width: 1; height: 1 }
                        }
                        Item { width: 1; height: px(4) }
                    }
                    footer: Item {
                        width: songList.width
                        height: mp.curItems.length || mp.searchHasOther ? px(28) : px(220)
                        Column {
                            anchors.centerIn: parent
                            visible: mp.curItems.length === 0 && !mp.searchHasOther
                            spacing: px(8)
                            Glyph {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: mp.search ? "search_off" : mp.view === "queue" ? "queue_music" : "music_off"
                                size: px(42); color: mp.cMutedDeep
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: mp.search ? mp.tx("Sin resultados para «", "No results for “") + mp.search + mp.tx("»", "”")
                                    : mp.view === "queue" ? mp.tx("La cola está vacía", "The queue is empty")
                                    : mp.view === "playlist" ? mp.tx("Esta lista está vacía", "This playlist is empty")
                                    : mp.tx("No hay canciones", "No songs")
                                font.family: mp.fontB; font.pixelSize: px(14); color: mp.cMuted
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                visible: mp.view === "playlist" && !mp.search
                                width: Math.min(px(380), songList.width - px(40))
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                text: mp.tx("Añade canciones con clic derecho → «Añadir a una lista…»", "Add songs with right click → “Add to playlist…”")
                                font.family: mp.fontB; font.pixelSize: px(12); color: mp.cMuted
                            }
                        }
                    }
                    delegate: SongRow {
                        width: songList.width
                        showCover: songList.showCover
                        showAlbum: songList.showAlbumCol
                    }
                    ScrollBar.vertical: ScrollBarX {}
                    Connections {
                        target: mp
                        function onViewChanged() { songList.toTop(); }
                        function onViewArgChanged() { songList.toTop(); }
                    }
                }
                WheelCatcher { flick: songList; visible: songList.visible }

                // album grid
                GridView {
                    id: albumGrid
                    anchors.fill: parent
                    anchors.leftMargin: px(16)
                    anchors.rightMargin: px(8)
                    visible: mp.gridAlbums && !emptyLib.visible && !mp.searchBlank
                    clip: true
                    interactive: false
                    model: mp.albumsView
                    readonly property int cols: Math.max(2, Math.floor(width / px(196)))
                    cellWidth: Math.floor(width / cols)
                    cellHeight: cellWidth + px(76)
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBarX {}
                    footer: Item { width: 1; height: px(24) }
                    delegate: AlbumCard {
                        width: albumGrid.cellWidth
                        height: albumGrid.cellHeight
                        title: modelData.name
                        sub: modelData.artist + (modelData.year ? " · " + modelData.year : "")
                        art: modelData.art
                        onOpen: mp.go("album", modelData.key)
                        onPlay: mp.playPaths(modelData.tracks.map(function (t) { return t.p; }), 0, modelData.name)
                        onMenu: (x, y) => mp.albumMenu(modelData, x, y)
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: mp.albumsView.length === 0
                        width: Math.min(px(420), parent.width - px(40))
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        text: mp.search ? mp.tx("Sin resultados", "No results")
                            : mp.tx("No hay álbumes. Las canciones sin etiqueta de álbum no aparecen aquí: selecciónalas y usa «Crear álbum».", "No albums. Songs without an album tag don't show here: select them and use “Create album”.")
                        font.family: mp.fontB; font.pixelSize: px(14); color: mp.cMuted
                    }
                }
                WheelCatcher { flick: albumGrid; visible: albumGrid.visible }

                // artist grid
                GridView {
                    id: artistGrid
                    anchors.fill: parent
                    anchors.leftMargin: px(16)
                    anchors.rightMargin: px(8)
                    visible: mp.gridArtists && !emptyLib.visible && !mp.searchBlank
                    clip: true
                    interactive: false
                    model: mp.artistsView
                    readonly property int cols: Math.max(2, Math.floor(width / px(180)))
                    cellWidth: Math.floor(width / cols)
                    cellHeight: cellWidth + px(76)
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBarX {}
                    footer: Item { width: 1; height: px(24) }
                    delegate: AlbumCard {
                        width: artistGrid.cellWidth
                        height: artistGrid.cellHeight
                        round: true
                        glyph: "artist"
                        title: modelData.name
                        sub: mp.songsLabel(modelData.tracks.length)
                        art: modelData.art
                        onOpen: mp.go("artist", modelData.key)
                        onPlay: mp.playPaths(mp.sortTracks(modelData.tracks, "album", true).map(function (t) { return t.p; }), 0, modelData.name)
                        onMenu: (x, y) => mp.artistMenu(modelData, x, y)
                    }
                }
                WheelCatcher { flick: artistGrid; visible: artistGrid.visible }

                // playlist grid
                GridView {
                    id: plGrid
                    anchors.fill: parent
                    anchors.leftMargin: px(16)
                    anchors.rightMargin: px(8)
                    visible: mp.gridLists && !mp.searchBlank
                    clip: true
                    interactive: false
                    model: { var _p = mp.plRev; return mp.view === "search" ? mp.playlistsView : [{ _new: true }].concat(mp.playlists); }
                    readonly property int cols: Math.max(2, Math.floor(width / px(196)))
                    cellWidth: Math.floor(width / cols)
                    cellHeight: cellWidth + px(76)
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBarX {}
                    footer: Item { width: 1; height: px(24) }
                    delegate: AlbumCard {
                        width: plGrid.cellWidth
                        height: plGrid.cellHeight
                        isNew: !!modelData._new
                        title: modelData._new ? mp.tx("Nueva lista", "New playlist") : modelData.name
                        sub: { var _p = mp.plRev; return modelData._new ? mp.tx("Crea una colección propia", "Make your own collection") : mp.songsLabel(modelData.tracks.length); }
                        arts: { var _r = mp.libRev, _p = mp.plRev; return modelData._new ? [] : mp.plArts(modelData); }
                        glyph: modelData.fav ? "favorite" : "queue_music"
                        canPlay: !modelData._new && modelData.tracks.length > 0
                        onOpen: { if (modelData._new) mp.newPlaylistDlg([]); else mp.go("playlist", modelData.id); }
                        onPlay: mp.playPaths(modelData.tracks, 0, modelData.name)
                        onMenu: (x, y) => { if (!modelData._new) mp.playlistMenu(modelData, x, y); }
                    }
                }
                WheelCatcher { flick: plGrid; visible: plGrid.visible }

                // search with no text
                Item {
                    anchors.fill: parent
                    visible: mp.searchBlank
                    Column {
                        anchors.centerIn: parent
                        spacing: px(10)
                        Glyph { anchors.horizontalCenter: parent.horizontalCenter; text: "search"; size: px(44); color: mp.cMutedDeep }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: mp.tx("Busca canciones, álbumes, artistas y listas", "Search songs, albums, artists and playlists")
                            font.family: mp.fontB; font.pixelSize: px(14); color: mp.cMuted
                        }
                    }
                }

                // home
                Flickable {
                    id: homeFlick
                    anchors.fill: parent
                    visible: mp.view === "home" && !emptyLib.visible
                    clip: true
                    interactive: false
                    contentWidth: width
                    contentHeight: homeCol.height + px(28)
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBarX {}
                    Column {
                        id: homeCol
                        width: homeFlick.width
                        spacing: px(12)
                        Item { width: 1; height: px(4) }
                        Rectangle {
                            x: px(16)
                            width: parent.width - px(32)
                            height: Math.max(px(240), heroCol.implicitHeight + px(72))
                            radius: px(48)
                            color: mp.cPrimCont
                            clip: true
                            AutoShape {
                                width: px(320); height: width
                                x: parent.width - px(400); y: -px(60)
                                fill: mp.ga(mp.cPrimary, 0.28)
                                interval: 2200
                                spinStep: 60
                                running: homeFlick.visible
                            }
                            AutoShape {
                                width: px(150); height: width
                                x: parent.width - px(520); y: px(130)
                                seq: ["Flower", "Cookie6Sided", "Clover4Leaf", "Sunny", "Pill", "Gem"]
                                fill: mp.cTertiary
                                interval: 1500
                                morphToken: "spatialDefault"
                                running: homeFlick.visible
                            }
                            Column {
                                id: heroCol
                                x: px(36)
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.min(parent.width * 0.6, px(640))
                                spacing: px(12)
                                T {
                                    width: parent.width
                                    role: "labelLarge"; emph: true
                                    text: (mp.songsLabel(mp.tracks.length) + "  ·  " + mp.fmtLong(mp.sumDur(mp.tracks))).toUpperCase()
                                    color: mp.m3OnPrimCont
                                    font.letterSpacing: 1.4
                                }
                                T {
                                    width: parent.width
                                    role: "displayMedium"; emph: true
                                    text: mp.greeting()
                                    color: mp.m3OnPrimCont
                                }
                                Item { width: 1; height: px(4) }
                                Row {
                                    spacing: px(12)
                                    PillBtn { glyph: "shuffle"; label: mp.tx("Aleatorio", "Shuffle"); primary: true; implicitHeight: px(56); onClicked: mp.shufflePaths(mp.tracks.map(function (t) { return t.p; }), "") }
                                    PillBtn { glyph: "play_arrow"; label: mp.tx("Reproducir todo", "Play all"); implicitHeight: px(56); onClicked: mp.playPaths(mp.sortTracks(mp.tracks, mp.sortKey, mp.sortAsc).map(function (t) { return t.p; }), 0, "") }
                                }
                            }
                        }
                        Shelf {
                            title: mp.tx("Volver a escuchar", "Listen again")
                            model: mp.recentTracks
                            delegate: AlbumCard {
                                width: mp.cardW; height: mp.cardH
                                glyph: "music_note"
                                title: modelData.t
                                sub: mp.artistOf(modelData)
                                art: modelData.art
                                onOpen: mp.playPaths(mp.recentTracks.map(function (t) { return t.p; }), index, mp.tx("Volver a escuchar", "Listen again"))
                                onPlay: mp.playPaths(mp.recentTracks.map(function (t) { return t.p; }), index, mp.tx("Volver a escuchar", "Listen again"))
                                onMenu: (x, y) => mp.trackMenu(modelData, x, y)
                            }
                        }
                        Column {
                            width: parent.width
                            visible: mp.quickPicks.length > 0
                            Item {
                                width: parent.width; height: px(52)
                                Text {
                                    x: px(24); anchors.verticalCenter: parent.verticalCenter
                                    text: mp.tx("Selección rápida", "Quick picks")
                                    font.family: mp.fontA; font.pixelSize: px(22); font.weight: Font.DemiBold
                                    color: mp.cOnSurface
                                }
                            }
                            Grid {
                                x: px(16)
                                width: parent.width - px(32)
                                columns: width > px(900) ? 3 : 2
                                columnSpacing: px(8)
                                rowSpacing: 0
                                Repeater {
                                    model: mp.quickPicks
                                    delegate: MiniSong {
                                        required property var modelData
                                        required property int index
                                        width: (parent.width - (parent.columns - 1) * parent.columnSpacing) / parent.columns
                                        tr: modelData
                                        onPlay: mp.playPaths(mp.quickPicks.map(function (t) { return t.p; }), index, mp.tx("Selección rápida", "Quick picks"))
                                        onMenu: (x, y) => mp.trackMenu(modelData, x, y)
                                    }
                                }
                            }
                        }
                        Shelf {
                            title: mp.tx("Álbumes", "Albums")
                            showMore: mp.albumData.list.length > 8
                            onMore: mp.go("albums")
                            model: mp.albumData.list.slice(0, 20)
                            delegate: AlbumCard {
                                width: mp.cardW; height: mp.cardH
                                title: modelData.name
                                sub: modelData.artist + (modelData.year ? " · " + modelData.year : "")
                                art: modelData.art
                                onOpen: mp.go("album", modelData.key)
                                onPlay: mp.playPaths(modelData.tracks.map(function (t) { return t.p; }), 0, modelData.name)
                                onMenu: (x, y) => mp.albumMenu(modelData, x, y)
                            }
                        }
                        Shelf {
                            title: mp.tx("Artistas", "Artists")
                            showMore: mp.artistData.list.length > 8
                            onMore: mp.go("artists")
                            model: mp.artistData.list.slice(0, 20)
                            delegate: AlbumCard {
                                width: mp.cardW; height: mp.cardH
                                round: true
                                glyph: "artist"
                                title: modelData.name
                                sub: mp.songsLabel(modelData.tracks.length)
                                art: modelData.art
                                onOpen: mp.go("artist", modelData.key)
                                onPlay: mp.playPaths(mp.sortTracks(modelData.tracks, "album", true).map(function (t) { return t.p; }), 0, modelData.name)
                                onMenu: (x, y) => mp.artistMenu(modelData, x, y)
                            }
                        }
                        Shelf {
                            title: mp.tx("Tus listas", "Your playlists")
                            showMore: true
                            onMore: mp.go("playlists")
                            model: { var _p = mp.plRev; return mp.playlists.slice(0, 20); }
                            delegate: AlbumCard {
                                width: mp.cardW; height: mp.cardH
                                glyph: modelData.fav ? "favorite" : "queue_music"
                                title: modelData.name
                                sub: { var _p = mp.plRev; return mp.songsLabel(modelData.tracks.length); }
                                arts: { var _r = mp.libRev, _p = mp.plRev; return mp.plArts(modelData); }
                                canPlay: modelData.tracks.length > 0
                                onOpen: mp.go("playlist", modelData.id)
                                onPlay: mp.playPaths(modelData.tracks, 0, modelData.name)
                                onMenu: (x, y) => mp.playlistMenu(modelData, x, y)
                            }
                        }
                        Shelf {
                            title: mp.tx("Añadidas recientemente", "Recently added")
                            showMore: true
                            onMore: mp.go("collection", "recent")
                            model: mp.addedTracks
                            delegate: AlbumCard {
                                width: mp.cardW; height: mp.cardH
                                glyph: "music_note"
                                title: modelData.t
                                sub: mp.artistOf(modelData)
                                art: modelData.art
                                onOpen: mp.playPaths(mp.addedTracks.map(function (t) { return t.p; }), index, mp.tx("Añadidas recientemente", "Recently added"))
                                onPlay: mp.playPaths(mp.addedTracks.map(function (t) { return t.p; }), index, mp.tx("Añadidas recientemente", "Recently added"))
                                onMenu: (x, y) => mp.trackMenu(modelData, x, y)
                            }
                        }
                    }
                }
                WheelCatcher { flick: homeFlick; visible: homeFlick.visible }

                // explore
                Flickable {
                    id: exploreFlick
                    anchors.fill: parent
                    visible: mp.view === "explore" && !emptyLib.visible
                    clip: true
                    interactive: false
                    contentWidth: width
                    contentHeight: exploreCol.height + px(28)
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBarX {}
                    Column {
                        id: exploreCol
                        width: exploreFlick.width
                        spacing: px(12)
                        Item {
                            width: parent.width; height: px(76)
                            Text {
                                x: px(24); anchors.verticalCenter: parent.verticalCenter
                                text: mp.tx("Explorar", "Explore")
                                font.family: mp.fontA; font.pixelSize: px(36); font.weight: Font.DemiBold
                                color: mp.cOnSurface
                            }
                        }
                        Row {
                            x: px(24)
                            width: parent.width - px(48)
                            spacing: px(10)
                            Tile {
                                width: (parent.width - parent.spacing * 2) / 3
                                glyph: "new_releases"; tint: mp.cPrimary; shape: "Sunny"
                                label: mp.tx("Novedades", "New additions"); sub: mp.tx("Lo último que añadiste", "Latest additions")
                                onClicked: mp.go("collection", "recent")
                            }
                            Tile {
                                width: (parent.width - parent.spacing * 2) / 3
                                glyph: "shuffle"; tint: mp.cTertiary; shape: "SoftBurst"
                                label: mp.tx("Aleatorio total", "Shuffle everything"); sub: mp.songsLabel(mp.tracks.length)
                                onClicked: mp.shufflePaths(mp.tracks.map(function (t) { return t.p; }), "")
                            }
                            Tile {
                                width: (parent.width - parent.spacing * 2) / 3
                                glyph: "favorite"; tint: mp.cAccent; shape: "Heart"
                                label: mp.tx("Me gusta", "Liked songs"); sub: { var _p = mp.plRev; var pl = mp.playlistById("liked"); return mp.songsLabel(pl ? pl.tracks.length : 0); }
                                onClicked: mp.go("playlist", "liked")
                            }
                        }
                        Item {
                            width: parent.width; height: px(48)
                            visible: mp.genreData.list.length > 0
                            Text { x: px(24); anchors.verticalCenter: parent.verticalCenter; text: mp.tx("Géneros", "Genres"); font.family: mp.fontA; font.pixelSize: px(22); font.weight: Font.DemiBold; color: mp.cOnSurface }
                        }
                        Flow {
                            x: px(24)
                            width: parent.width - px(48)
                            spacing: px(10)
                            readonly property int cols: width > px(900) ? 4 : 3
                            Repeater {
                                model: mp.genreData.list.slice(0, 24)
                                delegate: Tile {
                                    required property var modelData
                                    required property int index
                                    width: Math.floor((parent.width - (parent.cols - 1) * parent.spacing) / parent.cols)
                                    glyph: "graphic_eq"
                                    shape: ["Cookie9Sided", "Flower", "Clover4Leaf", "Pentagon", "Gem", "Cookie6Sided"][index % 6]
                                    tint: [mp.cPrimary, mp.cTertiary, mp.cAccent, mp.cPositive][index % 4]
                                    label: modelData.name
                                    sub: mp.songsLabel(modelData.tracks.length)
                                    onClicked: mp.go("collection", "genre:" + modelData.key)
                                }
                            }
                        }
                        Item {
                            width: parent.width; height: px(48)
                            visible: mp.decadeData.list.length > 0
                            Text { x: px(24); anchors.verticalCenter: parent.verticalCenter; text: mp.tx("Décadas", "Decades"); font.family: mp.fontA; font.pixelSize: px(22); font.weight: Font.DemiBold; color: mp.cOnSurface }
                        }
                        Flow {
                            x: px(24)
                            width: parent.width - px(48)
                            spacing: px(10)
                            readonly property int cols: width > px(900) ? 4 : 3
                            Repeater {
                                model: mp.decadeData.list
                                delegate: Tile {
                                    required property var modelData
                                    required property int index
                                    width: Math.floor((parent.width - (parent.cols - 1) * parent.spacing) / parent.cols)
                                    glyph: "calendar_month"
                                    shape: ["Arch", "Pill", "Square", "Cookie4Sided"][index % 4]
                                    tint: [mp.cTertiary, mp.cPrimary, mp.cPositive, mp.cAccent][index % 4]
                                    label: modelData.name
                                    sub: mp.songsLabel(modelData.tracks.length)
                                    onClicked: mp.go("collection", "decade:" + modelData.key)
                                }
                            }
                        }
                        Shelf {
                            title: mp.tx("Álbumes nuevos", "New albums")
                            model: mp.newAlbums
                            delegate: AlbumCard {
                                width: mp.cardW; height: mp.cardH
                                title: modelData.name
                                sub: modelData.artist + (modelData.year ? " · " + modelData.year : "")
                                art: modelData.art
                                onOpen: mp.go("album", modelData.key)
                                onPlay: mp.playPaths(modelData.tracks.map(function (t) { return t.p; }), 0, modelData.name)
                                onMenu: (x, y) => mp.albumMenu(modelData, x, y)
                            }
                        }
                        Shelf {
                            title: mp.tx("Mixes", "Mixes")
                            model: mp.mixes
                            delegate: AlbumCard {
                                width: mp.cardW; height: mp.cardH
                                glyph: "auto_awesome"
                                title: modelData.name
                                sub: modelData.sub
                                arts: modelData.arts
                                onOpen: mp.go("collection", "mix:" + index)
                                onPlay: mp.playPaths(modelData.tracks.map(function (t) { return t.p; }), 0, modelData.name)
                                onMenu: (x, y) => mp.listMenu(modelData.name, modelData.tracks.map(function (t) { return t.p; }), x, y)
                            }
                        }
                    }
                }
                WheelCatcher { flick: exploreFlick; visible: exploreFlick.visible }


                // online: search and download with spotdl
                Item {
                    id: onlineView
                    anchors.fill: parent
                    visible: mp.view === "online"
                    Column {
                        id: onlHead
                        x: px(24)
                        width: parent.width - px(48)
                        spacing: px(10)
                        Item { width: 1; height: px(6) }
                        Text {
                            text: mp.tx("En línea", "Online")
                            font.family: mp.fontA; font.pixelSize: px(36); font.weight: Font.DemiBold
                            color: mp.cOnSurface
                        }
                        Text {
                            width: parent.width
                            text: mp.tx("Busca una canción y descárgala a tu biblioteca con spotdl, con la letra sincronizada.", "Search for a song and download it to your library with spotdl, with synced lyrics.")
                            font.family: mp.fontB; font.pixelSize: px(14); color: mp.cMuted
                            wrapMode: Text.WordWrap
                        }
                        Row {
                            spacing: px(10)
                            Field {
                                id: onlField
                                width: Math.min(px(560), onlHead.width - px(120))
                                height: px(56)
                                glyph: "cloud_download"
                                placeholder: mp.tx("Canción, artista o «Artista - Título»", "Song, artist or “Artist - Title”")
                                onAccepted: mp.onlineSearch(text)
                                onEscaped: mp.refocus()
                            }
                            PillBtn { glyph: "search"; label: mp.tx("Buscar", "Search"); primary: true; implicitHeight: px(56); enabled: !mp.onlineBusy; onClicked: mp.onlineSearch(onlField.text) }
                        }
                        Row {
                            spacing: px(10)
                            height: px(36)
                            Text { anchors.verticalCenter: parent.verticalCenter; text: mp.tx("Letra sincronizada", "Synced lyrics"); font.family: mp.fontB; font.pixelSize: px(14); color: mp.cOnSurfVar }
                            Toggle { anchors.verticalCenter: parent.verticalCenter; checked: mp.dlSynced; onToggled: { mp.dlSynced = !mp.dlSynced; mp.savePrefs(); } }
                            Item { width: px(14); height: 1 }
                            Text { anchors.verticalCenter: parent.verticalCenter; text: mp.tx("Formato", "Format"); font.family: mp.fontB; font.pixelSize: px(14); color: mp.cOnSurfVar }
                            Repeater {
                                model: ["mp3", "flac", "m4a", "opus"]
                                Chip { anchors.verticalCenter: parent.verticalCenter; label: modelData; active: mp.dlFormat === modelData; onClicked: { mp.dlFormat = modelData; mp.savePrefs(); } }
                            }
                        }
                    }
                    Column {
                        visible: !mp.onlineAvail || mp.onlineErr !== "" || mp.onlineBusy || (mp.onlineSearched && mp.onlineRes.length === 0)
                        anchors.top: onlHead.bottom; anchors.topMargin: px(40)
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.min(px(460), parent.width - px(48))
                        spacing: px(10)
                        MorphLoader { anchors.horizontalCenter: parent.horizontalCenter; size: px(64); visible: mp.onlineBusy; running: visible }
                        ShapeView {
                            id: onlSpin
                            visible: !mp.onlineBusy
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: px(72); height: width
                            from: "Cookie9Sided"; to: "Cookie9Sided"
                            fill: mp.onlineAvail ? mp.m3SecCont : mp.m3ErrCont
                            Glyph { anchors.centerIn: parent; text: mp.onlineAvail ? "search_off" : "error"; size: px(32); color: mp.onlineAvail ? mp.m3OnSecCont : mp.m3OnErrCont }
                        }
                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            font.family: mp.fontB; font.pixelSize: px(14); color: mp.cOnSurfVar
                            text: mp.onlineBusy ? mp.tx("Buscando…", "Searching…")
                                : !mp.onlineAvail ? mp.tx("No se encontró spotdl. Instálalo con «pip install spotdl» (o pipx) y asegúrate de que esté en el PATH; también necesitas ffmpeg.", "spotdl wasn't found. Install it with “pip install spotdl” (or pipx) and make sure it's in PATH; you also need ffmpeg.")
                                : mp.onlineErr !== "" ? mp.tx("No se pudo buscar: ", "Search failed: ") + mp.onlineErr
                                : mp.tx("Sin resultados para «", "No results for “") + mp.onlineQ + mp.tx("»", "”")
                        }
                    }
                    ListView {
                        id: onlList
                        anchors.top: onlHead.bottom; anchors.topMargin: px(14)
                        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                        anchors.leftMargin: px(14); anchors.rightMargin: px(14)
                        clip: true
                        interactive: false
                        boundsBehavior: Flickable.StopAtBounds
                        model: mp.onlineRes
                        ScrollBar.vertical: ScrollBarX {}
                        spacing: 0
                        delegate: OnlineRow { width: onlList.width; it: modelData; first: index === 0; last: index === onlList.count - 1 }
                    }
                    WheelCatcher { flick: onlList; visible: onlineView.visible }
                }

                // empty library / scanning
                Item {
                    id: emptyLib
                    anchors.fill: parent
                    visible: mp.tracks.length === 0 && ["home", "explore", "songs", "albums", "artists"].indexOf(mp.view) >= 0
                    Column {
                        anchors.centerIn: parent
                        width: Math.min(px(460), parent.width - px(48))
                        spacing: px(14)
                        Item {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: px(104); height: px(104)
                            AutoShape {
                                anchors.fill: parent
                                visible: !mp.scanning && mp.inited
                                fill: mp.cPrimCont
                                seq: ["Cookie9Sided", "Flower", "Sunny", "Clover4Leaf"]
                                interval: 2000
                                Glyph { anchors.centerIn: parent; text: "library_music"; size: px(40); color: mp.m3OnPrimCont }
                            }
                            MorphLoader { anchors.centerIn: parent; size: px(60); fillColor: mp.cPrimary; visible: mp.scanning || !mp.inited; running: visible }
                        }
                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            text: mp.scanning || !mp.inited ? mp.tx("Buscando música…", "Looking for music…") : mp.tx("Tu biblioteca está vacía", "Your library is empty")
                            font.family: mp.fontA; font.pixelSize: px(20); font.weight: Font.DemiBold
                            color: mp.cOnSurface
                        }
                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            text: mp.scanning ? (mp.scanTotal ? mp.scanDone + " / " + mp.scanTotal : "")
                                : mp.tx("Añade canciones desde el explorador o arrastrándolas a esta ventana. También se leen automáticamente las de ", "Add songs from the file picker or by dragging them onto this window. Songs in ")
                                  + mp.libDirs.map(mp.prettyPath).join(", ") + mp.tx(".", " are read automatically.")
                            font.family: mp.fontB; font.pixelSize: px(14)
                            color: mp.cOnSurfVar
                        }
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: px(8)
                            visible: !mp.scanning && mp.inited
                            PillBtn { glyph: "library_add"; label: mp.tx("Añadir música", "Add music"); primary: true; implicitHeight: px(40); onClicked: mp.impShow() }
                            PillBtn { glyph: "create_new_folder"; label: mp.tx("Añadir carpeta", "Add folder"); implicitHeight: px(40); onClicked: mp.addLibDir() }
                        }
                    }
                }
            }
        }

        // ───────────── view headers (they live inside the list and scroll with it) ─────────────
        Component {
            id: songsHero
            Item {
                width: parent ? parent.width : 0
                height: mp.curItems.length ? px(56) : 0
                visible: height > 0
                Row {
                    x: px(24)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: px(8)
                    PillBtn { glyph: "play_arrow"; label: mp.tx("Reproducir", "Play"); primary: true; onClicked: mp.playView(false) }
                    PillBtn { glyph: "shuffle"; label: mp.tx("Aleatorio", "Shuffle"); onClicked: mp.playView(true) }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        leftPadding: px(8)
                        text: mp.songsLabel(mp.curItems.length) + " · " + mp.fmtLong(mp.sumDur(mp.curItems))
                              + (mp.search ? "" : "  ·  " + mp.tx("orden: ", "sort: ") + ({ title: mp.tx("título", "title"), artist: mp.tx("artista", "artist"), album: mp.tx("álbum", "album"), year: mp.tx("año", "year"), dur: mp.tx("duración", "duration"), added: mp.tx("recientes", "recent") })[mp.sortKey])
                        font.family: mp.fontB; font.pixelSize: px(12)
                        color: mp.cMuted
                    }
                }
            }
        }
        Component {
            id: albumHero
            HeroBox {
                kicker: mp.tx("ÁLBUM", "ALBUM")
                title: mp.curAlbum ? mp.curAlbum.name : ""
                linkText: mp.curAlbum ? mp.curAlbum.artist : ""
                onLinkClicked: if (mp.curAlbum) mp.go("artist", mp.curAlbum.artist.toLowerCase())
                meta: mp.curAlbum ? [mp.curAlbum.year, mp.songsLabel(mp.curAlbum.tracks.length), mp.fmtLong(mp.curAlbum.dur), mp.curAlbum.genre].filter(Boolean).join("  ·  ") : ""
                arts: mp.curAlbum && mp.curAlbum.art ? [mp.curAlbum.art] : []
                glyph: "album"
                onPlayClicked: mp.playView(false)
                onShuffleClicked: mp.playView(true)
                editTip: mp.tx("Editar álbum (nombre, artista, año, carátula…)", "Edit album (name, artist, year, cover…)")
                onEditClicked: if (mp.curAlbum) mp.openEditor(mp.curAlbum.tracks.map(function (t) { return t.p; }), "album")
                onMoreClicked: (x, y) => { if (mp.curAlbum) mp.albumMenu(mp.curAlbum, x, y); }
            }
        }
        Component {
            id: artistHero
            Column {
                width: parent ? parent.width : 0
                HeroBox {
                    width: parent.width
                    round: true
                    kicker: mp.tx("ARTISTA", "ARTIST")
                    title: mp.curArtist ? mp.curArtist.name : ""
                    meta: mp.curArtist ? [mp.curArtistAlbums.length ? (mp.curArtistAlbums.length === 1 ? mp.tx("1 álbum", "1 album") : mp.curArtistAlbums.length + mp.tx(" álbumes", " albums")) : "",
                                          mp.songsLabel(mp.curArtist.tracks.length), mp.fmtLong(mp.sumDur(mp.curArtist.tracks))].filter(Boolean).join("  ·  ") : ""
                    arts: mp.curArtist && mp.curArtist.art ? [mp.curArtist.art] : []
                    glyph: "artist"
                    showEdit: false
                    onPlayClicked: mp.playView(false)
                    onShuffleClicked: mp.playView(true)
                    onMoreClicked: (x, y) => { if (mp.curArtist) mp.artistMenu(mp.curArtist, x, y); }
                }
                Text {
                    visible: mp.curArtistAlbums.length > 0
                    x: px(24)
                    topPadding: px(4)
                    bottomPadding: px(6)
                    text: mp.tx("Álbumes", "Albums")
                    font.family: mp.fontA; font.pixelSize: px(22); font.weight: Font.DemiBold
                    color: mp.cOnSurface
                }
                ListView {
                    id: artAlbums
                    visible: mp.curArtistAlbums.length > 0
                    x: px(16)
                    width: parent.width - px(32)
                    height: visible ? px(200) : 0
                    orientation: ListView.Horizontal
                    clip: true
                    spacing: 0
                    boundsBehavior: Flickable.StopAtBounds
                    model: mp.curArtistAlbums
                    delegate: AlbumCard {
                        width: px(158); height: px(200)
                        title: modelData.name
                        sub: modelData.year || mp.songsLabel(modelData.tracks.length)
                        art: modelData.art
                        onOpen: mp.go("album", modelData.key)
                        onPlay: mp.playPaths(modelData.tracks.map(function (t) { return t.p; }), 0, modelData.name)
                        onMenu: (x, y) => mp.albumMenu(modelData, x, y)
                    }
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        onWheel: (w) => {
                            var d = w.angleDelta.y !== 0 ? w.angleDelta.y : w.angleDelta.x;
                            artAlbums.contentX = Math.max(0, Math.min(artAlbums.contentWidth - artAlbums.width, artAlbums.contentX - d));
                        }
                    }
                }
                Text {
                    x: px(24)
                    topPadding: px(10)
                    bottomPadding: px(2)
                    text: mp.tx("Canciones", "Songs")
                    font.family: mp.fontA; font.pixelSize: px(22); font.weight: Font.DemiBold
                    color: mp.cOnSurface
                }
            }
        }
        Component {
            id: playlistHero
            HeroBox {
                kicker: mp.tx("LISTA", "PLAYLIST")
                title: mp.curPlaylist ? mp.curPlaylist.name : ""
                desc: mp.curPlaylist ? (mp.curPlaylist.desc || "") : ""
                meta: { var _p = mp.plRev; return mp.curPlaylist ? mp.songsLabel(mp.curPlaylist.tracks.length) + "  ·  " + mp.fmtLong(mp.plDuration(mp.curPlaylist)) : ""; }
                arts: { var _r = mp.libRev, _p = mp.plRev; return mp.plArts(mp.curPlaylist); }
                glyph: "queue_music"
                canPlay: mp.curItems.length > 0
                editTip: mp.tx("Renombrar", "Rename")
                onPlayClicked: mp.playView(false)
                onShuffleClicked: mp.playView(true)
                onEditClicked: if (mp.curPlaylist) mp.renamePlaylistDlg(mp.curPlaylist.id)
                onArtClicked: if (mp.curPlaylist) mp.coverPlaylist(mp.curPlaylist.id)
                artTip: mp.tx("Cambiar portada", "Change cover")
                onMoreClicked: (x, y) => { if (mp.curPlaylist) mp.playlistMenu(mp.curPlaylist, x, y); }
            }
        }
        Component {
            id: queueHero
            Item {
                width: parent ? parent.width : 0
                height: px(62)
                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: px(24)
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: qhBtns.left
                    anchors.rightMargin: px(12)
                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: mp.queue.length ? (mp.queueLabel ? mp.tx("Reproduciendo desde «", "Playing from “") + mp.queueLabel + mp.tx("»", "”") : mp.tx("Reproduciendo", "Now playing"))
                                              : mp.tx("Nada en cola", "Nothing queued")
                        font.family: mp.fontB; font.pixelSize: px(14); font.weight: Font.Medium
                        color: mp.cOnSurface
                    }
                    Text {
                        visible: mp.queue.length > 0
                        text: mp.songsLabel(mp.queue.length) + "  ·  " + mp.fmtLong(mp.sumDur(mp.curItems))
                              + (mp.shuffle ? "  ·  " + mp.tx("aleatorio", "shuffled") : "")
                        font.family: mp.fontB; font.pixelSize: px(12); color: mp.cMuted
                    }
                }
                Row {
                    id: qhBtns
                    anchors.right: parent.right
                    anchors.rightMargin: px(24)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: px(8)
                    PillBtn {
                        glyph: "playlist_add"; label: mp.tx("Guardar como lista", "Save as playlist")
                        enabled: mp.queue.length > 0
                        onClicked: mp.newPlaylistDlg(mp.queue.slice())
                    }
                    PillBtn {
                        glyph: "clear_all"; label: mp.tx("Vaciar", "Clear"); danger: true
                        enabled: mp.queue.length > 0
                        onClicked: mp.clearQueue()
                    }
                }
            }
        }

        Component {
            id: collectionHero
            HeroBox {
                kicker: mp.tx("COLECCIÓN", "COLLECTION")
                title: mp.collection.name
                meta: mp.songsLabel(mp.curItems.length) + "  ·  " + mp.fmtLong(mp.sumDur(mp.curItems))
                arts: mp.artsOf(mp.curItems)
                glyph: "library_music"
                showEdit: false
                canPlay: mp.curItems.length > 0
                onPlayClicked: mp.playView(false)
                onShuffleClicked: mp.playView(true)
                onMoreClicked: (x, y) => mp.listMenu(mp.collection.name, mp.curItems.map(function (t) { return t.p; }), x, y)
            }
        }
        Component {
            id: searchSongsHero
            Item {
                width: parent ? parent.width : 0
                height: mp.curItems.length ? px(52) : 0
                visible: height > 0
                Text {
                    x: px(24); anchors.verticalCenter: parent.verticalCenter
                    text: mp.songsLabel(mp.curItems.length)
                    font.family: mp.fontA; font.pixelSize: px(22); font.weight: Font.DemiBold
                    color: mp.cOnSurface
                }
            }
        }
        Component {
            id: searchHero
            Column {
                width: parent ? parent.width : 0
                Shelf {
                    title: mp.tx("Álbumes", "Albums")
                    showMore: mp.albumsView.length > 8
                    onMore: mp.searchTab = "albums"
                    model: mp.albumsView.slice(0, 20)
                    delegate: AlbumCard {
                        width: mp.cardW; height: mp.cardH
                        title: modelData.name
                        sub: modelData.artist + (modelData.year ? " · " + modelData.year : "")
                        art: modelData.art
                        onOpen: mp.go("album", modelData.key)
                        onPlay: mp.playPaths(modelData.tracks.map(function (t) { return t.p; }), 0, modelData.name)
                        onMenu: (x, y) => mp.albumMenu(modelData, x, y)
                    }
                }
                Shelf {
                    title: mp.tx("Artistas", "Artists")
                    showMore: mp.artistsView.length > 8
                    onMore: mp.searchTab = "artists"
                    model: mp.artistsView.slice(0, 20)
                    delegate: AlbumCard {
                        width: mp.cardW; height: mp.cardH
                        round: true
                        glyph: "artist"
                        title: modelData.name
                        sub: mp.songsLabel(modelData.tracks.length)
                        art: modelData.art
                        onOpen: mp.go("artist", modelData.key)
                        onPlay: mp.playPaths(mp.sortTracks(modelData.tracks, "album", true).map(function (t) { return t.p; }), 0, modelData.name)
                        onMenu: (x, y) => mp.artistMenu(modelData, x, y)
                    }
                }
                Shelf {
                    title: mp.tx("Listas", "Playlists")
                    showMore: mp.playlistsView.length > 8
                    onMore: mp.searchTab = "playlists"
                    model: mp.playlistsView.slice(0, 20)
                    delegate: AlbumCard {
                        width: mp.cardW; height: mp.cardH
                        glyph: modelData.fav ? "favorite" : "queue_music"
                        title: modelData.name
                        sub: { var _p = mp.plRev; return mp.songsLabel(modelData.tracks.length); }
                        arts: { var _r = mp.libRev, _p = mp.plRev; return mp.plArts(modelData); }
                        canPlay: modelData.tracks.length > 0
                        onOpen: mp.go("playlist", modelData.id)
                        onPlay: mp.playPaths(modelData.tracks, 0, modelData.name)
                        onMenu: (x, y) => mp.playlistMenu(modelData, x, y)
                    }
                }
                Item {
                    width: parent.width
                    height: mp.curItems.length ? px(56) : 0
                    visible: height > 0
                    Text {
                        x: px(24); anchors.verticalCenter: parent.verticalCenter
                        text: mp.tx("Canciones", "Songs")
                        font.family: mp.fontA; font.pixelSize: px(22); font.weight: Font.DemiBold
                        color: mp.cOnSurface
                    }
                }
            }
        }

        // ───────────── now-playing screen (like YouTube Music's «Now playing») ─────────────
        Rectangle {
            id: playerPage
            x: 0
            y: (1 - mp.ppProg) * height
            width: parent.width
            height: parent.height - mp.barH
            z: 40
            visible: y < height - 1 && mp.uiVis > 0.01
            color: "transparent"
            opacity: Math.min(1, mp.ppProg * 2.5) * mp.uiVis
            readonly property real leftW: Math.min(px(560), width * 0.42)
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onWheel: (w) => {} }

            Item {
                id: ppTop
                width: parent.width
                height: mp.topH
                IconBtn {
                    id: ppClose
                    x: px(20)
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: px(40); implicitHeight: px(40); radius: px(20); gsize: px(26)
                    glyph: "keyboard_arrow_down"
                    tip: mp.tx("Cerrar (Ctrl+L)", "Close (Ctrl+L)")
                    onClicked: mp.playerOpen = false
                }
                Column {
                    anchors.centerIn: parent
                    width: parent.width - px(220)
                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: mp.tx("REPRODUCIENDO", "NOW PLAYING")
                        font.family: mp.fontB; font.pixelSize: px(11); font.weight: Font.DemiBold; font.letterSpacing: 0.8
                        color: mp.cMuted
                    }
                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        visible: mp.queueLabel !== ""
                        text: mp.queueLabel
                        elide: Text.ElideRight
                        font.family: mp.fontB; font.pixelSize: px(14); font.weight: Font.Medium
                        color: mp.cOnSurfVar
                    }
                }
                IconBtn {
                    id: ppMore
                    anchors.right: parent.right; anchors.rightMargin: px(20)
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: px(40); implicitHeight: px(40); radius: px(20); gsize: px(22)
                    visible: !!mp.cur
                    glyph: "more_vert"
                    tip: mp.tx("Más opciones", "More options")
                    onClicked: { var g = mapToItem(rootBg, 0, height + 4); mp.trackMenu(mp.cur, g.x - px(200), g.y); }
                }
            }

            // left: large cover with title and actions
            Item {
                id: ppLeft
                x: 0; y: ppTop.height
                width: playerPage.leftW
                height: parent.height - ppTop.height
                Column {
                    anchors.centerIn: parent
                    width: parent.width - px(64)
                    spacing: px(10)
                    ArtGear {
                        id: npArt
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.max(px(160), Math.min(parent.width, px(430), ppLeft.height - px(210)))
                        height: width
                        artPath: mp.cur ? (mp.cur.art || "") : ""
                        pct: mp.pct
                        running: mp.playing && mp.playerOpen
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: parent.width * 0.12
                            cursorShape: mp.cur ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: if (mp.cur && !mp.cur.loose && mp.cur.al) mp.go("album", mp.albumKeyOf(mp.cur))
                            onDoubleClicked: if (mp.curPath) mp.openEditor([mp.curPath], "tags")
                        }
                    }
                    Item { width: 1; height: px(4) }
                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: mp.cur ? mp.cur.t : mp.tx("Nada sonando", "Nothing playing")
                        elide: Text.ElideRight
                        font.family: mp.fontA; font.pixelSize: px(28); font.weight: Font.DemiBold
                        color: mp.cOnSurface
                    }
                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: mp.cur ? mp.artistOf(mp.cur) + (mp.cur.al ? "  ·  " + mp.cur.al : "")
                                     : mp.tx("Elige una canción para empezar", "Pick a song to start")
                        elide: Text.ElideRight
                        font.family: mp.fontB; font.pixelSize: px(14)
                        color: npArtistHov.hovered && mp.cur ? mp.cPrimary : mp.cOnSurfVar
                        HoverHandler { id: npArtistHov; cursorShape: mp.cur ? Qt.PointingHandCursor : Qt.ArrowCursor }
                        TapHandler { onTapped: if (mp.cur && !mp.cur.loose) mp.go("artist", mp.albumArtistOf(mp.cur).toLowerCase()) }
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: px(6)
                        visible: !!mp.cur
                        IconBtn {
                            readonly property bool liked: mp.cur ? mp.isLiked(mp.curPath) : false
                            variant: "tonal"; implicitWidth: px(48); implicitHeight: px(48)
                            glyph: "favorite"
                            glyphColor: liked ? mp.cTertiary : mp.cOnSurfVar
                            tip: liked ? mp.tx("Quitar de «Me gusta»", "Remove from Liked") : mp.tx("Me gusta", "Like")
                            onClicked: mp.likePaths([mp.curPath])
                        }
                        IconBtn { variant: "tonal"; implicitWidth: px(48); implicitHeight: px(48); glyph: "playlist_add"; tip: mp.tx("Añadir a una lista…", "Add to playlist…"); onClicked: mp.addToDlg([mp.curPath]) }
                        IconBtn { variant: "tonal"; implicitWidth: px(48); implicitHeight: px(48); glyph: "edit"; tip: mp.tx("Editar etiquetas (Ctrl+E)", "Edit tags (Ctrl+E)"); onClicked: mp.openEditor([mp.curPath], "tags") }
                        IconBtn { variant: "tonal"; implicitWidth: px(48); implicitHeight: px(48); glyph: "lyrics"; active: mp.panelTab === "lyrics"; tip: mp.tx("Letra", "Lyrics"); onClicked: mp.panelTab = "lyrics" }
                    }
                }
            }

            // right: Up next · Lyrics · Related · Info
            Rectangle {
                id: ppRight
                x: ppLeft.width
                y: ppTop.height
                width: parent.width - ppLeft.width - px(28)
                height: parent.height - ppTop.height - px(16)
                radius: px(32)
                color: mp.bgPane
                clip: true
                TabStrip {
                    id: ppTabs
                    width: parent.width
                    current: mp.panelTab
                    options: [
                        { value: "queue", label: mp.tx("A continuación", "Up next") },
                        { value: "lyrics", label: mp.tx("Letra", "Lyrics") },
                        { value: "related", label: mp.tx("Relacionado", "Related") },
                        { value: "info", label: "Info" }
                    ]
                    onPicked: (v) => mp.panelTab = v
                }
                Item {
                    id: npTab
                    anchors.top: ppTabs.bottom
                    anchors.topMargin: px(6)
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: px(10)
                    x: px(12)
                    width: parent.width - px(24)
                    clip: true

                    // up next
                    Item {
                        anchors.fill: parent
                        visible: mp.panelTab === "queue"
                        Item {
                            id: qHead
                            width: parent.width
                            height: px(46)
                            Text {
                                anchors.left: parent.left; anchors.leftMargin: px(8)
                                anchors.right: qBtns.left; anchors.rightMargin: px(8)
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight
                                text: mp.queue.length ? (mp.queueLabel ? mp.tx("Reproduciendo desde «", "Playing from “") + mp.queueLabel + mp.tx("»", "”") : mp.songsLabel(mp.queue.length)) : mp.tx("Nada en cola", "Nothing queued")
                                font.family: mp.fontB; font.pixelSize: px(14); font.weight: Font.Medium
                                color: mp.cOnSurfVar
                            }
                            Row {
                                id: qBtns
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                IconBtn { glyph: "playlist_add"; tip: mp.tx("Guardar la cola como lista", "Save queue as playlist"); enabled: mp.queue.length > 0; onClicked: mp.newPlaylistDlg(mp.queue.slice()) }
                                IconBtn { glyph: "open_in_full"; tip: mp.tx("Gestionar la cola", "Manage queue"); onClicked: mp.go("queue") }
                                IconBtn { glyph: "clear_all"; tip: mp.tx("Vaciar la cola", "Clear queue"); enabled: mp.queue.length > 0; onClicked: mp.clearQueue() }
                            }
                        }
                        ListView {
                            id: upNext
                            anchors.top: qHead.bottom
                            anchors.bottom: parent.bottom
                            width: parent.width
                            clip: true
                            interactive: false
                            boundsBehavior: Flickable.StopAtBounds
                            model: { var _q = mp.queueRev, _r = mp.libRev; return mp.queue.slice(0, 400); }
                            function focusCur() { if (mp.qIndex >= 0 && count > 0) positionViewAtIndex(Math.max(0, mp.qIndex - 1), ListView.Beginning); }
                            Connections {
                                target: mp
                                function onQIndexChanged() { Qt.callLater(upNext.focusCur); }
                                function onPlayerOpenChanged() { if (mp.playerOpen) Qt.callLater(upNext.focusCur); }
                                function onPanelTabChanged() { if (mp.panelTab === "queue") Qt.callLater(upNext.focusCur); }
                            }
                            Component.onCompleted: Qt.callLater(focusCur)
                            delegate: Rectangle {
                                id: unr
                                required property var modelData
                                required property int index
                                readonly property var tr: mp.trackOf(modelData)
                                readonly property bool isCur: index === mp.qIndex
                                width: upNext.width
                                height: px(58)
                                radius: px(16)
                                color: unr.isCur ? mp.ga(mp.cPrimary, 0.12) : (unrHov.hovered ? mp.hovCol : "transparent")
                                Behavior on color { ColorAnimation { duration: 120 } }
                                Cover {
                                    id: unrArt
                                    x: px(8); anchors.verticalCenter: parent.verticalCenter
                                    width: px(42); height: width; r: px(12)
                                    src: unr.tr ? unr.tr.art : ""
                                    Rectangle {
                                        anchors.fill: parent; radius: parent.r
                                        color: Qt.rgba(0, 0, 0, 0.5)
                                        visible: unr.isCur || unrHov.hovered
                                        EqBars { anchors.centerIn: parent; visible: unr.isCur && !unrHov.hovered; live: mp.playing }
                                        Glyph { anchors.centerIn: parent; visible: unrHov.hovered; text: unr.isCur && mp.playing ? "pause" : "play_arrow"; size: px(22); color: "white" }
                                    }
                                }
                                Column {
                                    anchors.left: unrArt.right; anchors.leftMargin: px(12)
                                    anchors.right: unrDur.left; anchors.rightMargin: px(8)
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text { width: parent.width; text: unr.tr ? unr.tr.t : mp.baseName(unr.modelData); elide: Text.ElideRight; font.family: mp.fontB; font.pixelSize: px(14); font.weight: Font.Medium; color: unr.isCur ? mp.cPrimary : mp.cOnSurface }
                                    Text { width: parent.width; text: unr.tr ? mp.artistOf(unr.tr) : ""; elide: Text.ElideRight; font.family: mp.fontB; font.pixelSize: px(12); color: mp.cMuted }
                                }
                                Text {
                                    id: unrDur
                                    anchors.right: unrBtn.left; anchors.rightMargin: px(2)
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: unr.tr ? mp.fmtTime(unr.tr.dur) : ""
                                    font.family: mp.fontB; font.pixelSize: px(12); color: mp.cMuted
                                }
                                IconBtn {
                                    id: unrBtn
                                    anchors.right: parent.right; anchors.rightMargin: px(6)
                                    anchors.verticalCenter: parent.verticalCenter
                                    implicitWidth: px(28); implicitHeight: px(28); gsize: px(16)
                                    opacity: unrHov.hovered && !unr.isCur ? 1 : 0
                                    enabled: !unr.isCur
                                    glyph: "close"; tip: mp.tx("Quitar de la cola", "Remove from queue")
                                    onClicked: mp.removeFromQueue([unr.index])
                                }
                                HoverHandler { id: unrHov; cursorShape: Qt.PointingHandCursor }
                                MouseArea {
                                    anchors.fill: parent
                                    z: -1
                                    onClicked: { if (unr.isCur) mp.togglePlay(); else mp.loadIndex(unr.index, true, 0); }
                                }
                            }
                            ScrollBar.vertical: ScrollBarX {}
                        }
                        WheelCatcher { flick: upNext }
                        Text {
                            anchors.centerIn: parent
                            visible: upNext.count === 0
                            width: parent.width - px(32)
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            text: mp.tx("La cola está vacía. Reproduce una canción, álbum o lista.", "The queue is empty. Play a song, album or playlist.")
                            font.family: mp.fontB; font.pixelSize: px(14); color: mp.cMuted
                        }
                    }


                    // lyrics
                    Item {
                        anchors.fill: parent
                        visible: mp.panelTab === "lyrics"
                        ListView {
                            id: lyrList
                            anchors.fill: parent
                            visible: mp.lyr.lines.length > 0
                            model: mp.lyr.lines
                            clip: true
                            spacing: px(6)
                            interactive: false
                            boundsBehavior: Flickable.StopAtBounds
                            cacheBuffer: height * 2
                            function follow(instant) {
                                if (!mp.lyr.synced || mp.lyrIndex < 0 || lyrWheel.recent || !visible || height <= 0) return;
                                var it = itemAtIndex(mp.lyrIndex);
                                if (!it) { positionViewAtIndex(mp.lyrIndex, ListView.Contain); it = itemAtIndex(mp.lyrIndex); if (!it) return; }
                                var tgt = it.y + it.height / 2 - height * 0.36;
                                tgt = Math.max(originY, Math.min(originY + Math.max(0, contentHeight - height), tgt));
                                lyrFollow.stop();
                                if (instant || Math.abs(tgt - contentY) > height * 1.5) { contentY = tgt; return; }
                                lyrFollow.from = contentY; lyrFollow.to = tgt; lyrFollow.start();
                            }
                            NumberAnimation { id: lyrFollow; target: lyrList; property: "contentY"; duration: 700; easing.type: Easing.InOutSine }
                            Connections {
                                target: mp
                                function onLyrIndexChanged() { lyrList.follow(false); }
                            }
                            Connections {
                                target: lyrWheel
                                function onRecentChanged() { if (lyrWheel.recent) lyrFollow.stop(); else lyrList.follow(false); }
                            }
                            onVisibleChanged: if (visible) Qt.callLater(function () { lyrList.follow(true); })
                            header: Item { width: 1; height: px(36) }
                            footer: Item { width: 1; height: lyrList.height * 0.5 }
                            delegate: Text {
                                id: lyrLine
                                required property var modelData
                                required property int index
                                readonly property bool isCur: mp.lyr.synced && index === mp.lyrIndex
                                readonly property bool past: mp.lyr.synced && index < mp.lyrIndex
                                x: px(12)
                                width: mp.lyr.synced ? (lyrList.width - px(24)) / 1.3 : lyrList.width - px(24)
                                transformOrigin: Item.Left
                                scale: !mp.lyr.synced ? 1 : (isCur ? 1.3 : 1)
                                opacity: 1
                                Behavior on scale { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
                                text: modelData.s === "" ? (mp.lyr.synced ? "♪" : " ") : modelData.s
                                wrapMode: Text.WordWrap
                                horizontalAlignment: Text.AlignLeft
                                font.family: mp.fontA
                                font.pixelSize: mp.lyr.synced ? px(19) : px(15.5)
                                font.weight: mp.lyr.synced ? Font.Bold : Font.Normal
                                lineHeight: 1.12
                                color: !mp.lyr.synced ? mp.cOnSurfVar : isCur ? mp.cPrimary : past ? mp.ga(mp.cOnSurfVar, 0.45) : mp.ga(mp.cOnSurfVar, 0.75)
                                Behavior on color { ColorAnimation { duration: 450 } }
                                HoverHandler { id: lyrHov; enabled: mp.lyr.synced; cursorShape: Qt.PointingHandCursor }
                                TapHandler { enabled: mp.lyr.synced; onTapped: { mp.seekTo(lyrLine.modelData.t); if (!mp.playing) mp.togglePlay(); } }
                                Rectangle {
                                    z: -1
                                    anchors.fill: parent
                                    anchors.margins: -px(6)
                                    radius: px(10)
                                    color: mp.hovCol
                                    visible: lyrHov.hovered
                                }
                            }
                            ScrollBar.vertical: ScrollBarX {}
                        }
                        WheelCatcher {
                            id: lyrWheel
                            flick: lyrList
                            visible: lyrList.visible
                            property bool recent: false
                            onWheeled: { lyrWheel.recent = true; lyrRecent.restart(); }
                            Timer { id: lyrRecent; interval: 4000; onTriggered: lyrWheel.recent = false }
                        }
                        IconBtn {
                            id: lyrSyncBtn
                            anchors.right: lyrTagBox.left
                            anchors.rightMargin: px(6)
                            anchors.verticalCenter: lyrTagBox.verticalCenter
                            visible: lyrList.visible
                            implicitWidth: px(30); implicitHeight: px(30); radius: px(15); gsize: px(19)
                            glyph: "graphic_eq"
                            tip: mp.tx("Ajustar la sincronización (Ctrl+Y)", "Adjust sync (Ctrl+Y)")
                            onClicked: mp.openLyricSync(mp.curPath)
                        }
                        IconBtn {
                            anchors.right: lyrSyncBtn.left
                            anchors.rightMargin: px(2)
                            anchors.verticalCenter: lyrTagBox.verticalCenter
                            visible: lyrList.visible
                            implicitWidth: px(30); implicitHeight: px(30); radius: px(15); gsize: px(19)
                            glyph: "fullscreen"
                            tip: mp.tx("Pantalla completa (F11)", "Full screen (F11)")
                            onClicked: mp.setLyrFull(true)
                        }
                        Rectangle {
                            id: lyrTagBox
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: px(4)
                            visible: lyrList.visible
                            width: lyrTag.implicitWidth + px(16)
                            height: px(22)
                            radius: px(11)
                            color: mp.ga(mp.lyr.synced ? mp.cPrimary : mp.cOnSurfVar, 0.14)
                            Text {
                                id: lyrTag
                                anchors.centerIn: parent
                                text: mp.lyr.synced ? mp.tx("Sincronizada", "Synced") : mp.tx("Texto", "Plain")
                                font.family: mp.fontB; font.pixelSize: px(9.5); font.weight: Font.DemiBold
                                color: mp.lyr.synced ? mp.cPrimary : mp.cOnSurfVar
                            }
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: if (mp.curPath) mp.openEditor([mp.curPath], "tags", "lyrics") }
                        }
                        Column {
                            anchors.centerIn: parent
                            width: parent.width - px(32)
                            visible: !lyrList.visible
                            spacing: px(10)
                            Glyph { anchors.horizontalCenter: parent.horizontalCenter; text: "lyrics"; size: px(34); color: mp.cMutedDeep }
                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                text: mp.cur ? mp.tx("Esta canción no tiene letra", "This song has no lyrics") : mp.tx("La letra aparecerá aquí", "Lyrics will show here")
                                font.family: mp.fontB; font.pixelSize: px(14); color: mp.cMuted
                            }
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: px(6)
                                visible: !!mp.cur
                                PillBtn {
                                    glyph: mp.npFetching ? "hourglass_top" : "travel_explore"
                                    label: mp.tx("Buscar en línea", "Find online")
                                    enabled: !mp.npFetching && mp.hasMutagen
                                    onClicked: mp.quickFetchLyrics()
                                }
                                PillBtn { glyph: "edit"; label: mp.tx("Escribir", "Write"); onClicked: mp.openEditor([mp.curPath], "tags", "lyrics") }
                            }
                        }
                    }


                    // related
                    Flickable {
                        id: relFlick
                        anchors.fill: parent
                        visible: mp.panelTab === "related"
                        clip: true
                        interactive: false
                        contentHeight: relCol.height + px(12)
                        boundsBehavior: Flickable.StopAtBounds
                        Column {
                            id: relCol
                            width: relFlick.width
                            Item {
                                width: parent.width; height: px(44)
                                visible: !!mp.curAlbumObj && mp.curAlbumObj.tracks.length > 1
                                Text {
                                    x: px(8); anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - px(16)
                                    elide: Text.ElideRight
                                    text: mp.curAlbumObj ? mp.tx("Del álbum «", "From the album “") + mp.curAlbumObj.name + mp.tx("»", "”") : ""
                                    font.family: mp.fontA; font.pixelSize: px(22); font.weight: Font.DemiBold
                                    color: mp.cOnSurface
                                }
                            }
                            Repeater {
                                model: mp.curAlbumObj && mp.curAlbumObj.tracks.length > 1 ? mp.curAlbumObj.tracks : []
                                delegate: MiniSong {
                                    required property var modelData
                                    required property int index
                                    width: relCol.width
                                    tr: modelData
                                    onPlay: mp.playPaths(mp.curAlbumObj.tracks.map(function (t) { return t.p; }), index, mp.curAlbumObj.name)
                                    onMenu: (x, y) => mp.trackMenu(modelData, x, y)
                                }
                            }
                            Item {
                                width: parent.width; height: px(52)
                                visible: mp.curArtistRest.length > 0
                                Text {
                                    x: px(8); anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - px(16)
                                    elide: Text.ElideRight
                                    text: mp.curArtistObj ? mp.tx("Más de ", "More from ") + mp.curArtistObj.name : ""
                                    font.family: mp.fontA; font.pixelSize: px(22); font.weight: Font.DemiBold
                                    color: mp.cOnSurface
                                }
                            }
                            Repeater {
                                model: mp.curArtistRest
                                delegate: MiniSong {
                                    required property var modelData
                                    required property int index
                                    width: relCol.width
                                    tr: modelData
                                    onPlay: mp.playPaths(mp.curArtistRest.map(function (t) { return t.p; }), index, mp.curArtistObj.name)
                                    onMenu: (x, y) => mp.trackMenu(modelData, x, y)
                                }
                            }
                            Shelf {
                                title: mp.tx("Álbumes del artista", "Albums by this artist")
                                pad: px(12)
                                itemH: mp.cardH
                                model: mp.curArtistOtherAlbums
                                delegate: AlbumCard {
                                    width: mp.cardW; height: mp.cardH
                                    title: modelData.name
                                    sub: modelData.year || mp.songsLabel(modelData.tracks.length)
                                    art: modelData.art
                                    onOpen: mp.go("album", modelData.key)
                                    onPlay: mp.playPaths(modelData.tracks.map(function (t) { return t.p; }), 0, modelData.name)
                                    onMenu: (x, y) => mp.albumMenu(modelData, x, y)
                                }
                            }
                            Text {
                                visible: !mp.curAlbumObj && mp.curArtistRest.length === 0
                                width: parent.width
                                topPadding: px(40)
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                text: mp.cur ? mp.tx("No hay más música relacionada en tu biblioteca", "No related music in your library") : mp.tx("Reproduce algo para ver canciones relacionadas", "Play something to see related songs")
                                font.family: mp.fontB; font.pixelSize: px(14); color: mp.cMuted
                            }
                        }
                        ScrollBar.vertical: ScrollBarX {}
                    }
                    WheelCatcher { flick: relFlick; visible: relFlick.visible }


                    // file info
                    Flickable {
                        id: infoFlick
                        anchors.fill: parent
                        visible: mp.panelTab === "info"
                        clip: true
                        interactive: false
                        contentHeight: infoCol.height + px(12)
                        boundsBehavior: Flickable.StopAtBounds
                        Column {
                            id: infoCol
                            x: px(12)
                            width: infoFlick.width - px(24)
                            spacing: px(6)
                            Repeater {
                                model: {
                                    var d = mp.curInfo, t = mp.cur;
                                    if (!d || !t) return [];
                                    var tg = d.tags;
                                    var rows = [
                                        [mp.tx("Título", "Title"), tg.title], [mp.tx("Artista", "Artist"), tg.artist],
                                        [mp.tx("Álbum", "Album"), tg.album], [mp.tx("Artista del álbum", "Album artist"), tg.albumartist],
                                        [mp.tx("Pista", "Track"), tg.track ? tg.track + (tg.tracktotal ? " / " + tg.tracktotal : "") : ""],
                                        [mp.tx("Disco", "Disc"), tg.disc ? tg.disc + (tg.disctotal ? " / " + tg.disctotal : "") : ""],
                                        [mp.tx("Año", "Year"), tg.year], [mp.tx("Género", "Genre"), tg.genre],
                                        [mp.tx("Compositor", "Composer"), tg.composer],
                                        [mp.tx("Formato", "Format"), d.format + (d.bitrate ? "  ·  " + d.bitrate + " kbps" : "")],
                                        [mp.tx("Duración", "Duration"), mp.fmtTime(d.duration)], [mp.tx("Tamaño", "Size"), mp.fmtSize(d.size)],
                                        [mp.tx("Ubicación", "Location"), mp.prettyPath(d.path)]
                                    ];
                                    return rows.filter(function (r) { return !!r[1]; });
                                }
                                delegate: Column {
                                    required property var modelData
                                    width: infoCol.width
                                    Text { text: modelData[0]; font.family: mp.fontB; font.pixelSize: px(11); font.weight: Font.DemiBold; color: mp.cMuted }
                                    Text { width: parent.width; text: modelData[1]; wrapMode: Text.WrapAnywhere; font.family: mp.fontB; font.pixelSize: px(14); color: mp.cOnSurface }
                                }
                            }
                            Item { width: 1; height: px(4) }
                            Flow {
                                width: parent.width
                                spacing: px(6)
                                visible: !!mp.curInfo
                                PillBtn { glyph: "edit"; label: mp.tx("Editar etiquetas", "Edit tags"); onClicked: mp.openEditor([mp.curPath], "tags") }
                                PillBtn { glyph: "folder_open"; label: mp.tx("Mostrar", "Show"); onClicked: mp.revealInFiles(mp.curPath) }
                            }
                            Text {
                                visible: !mp.curInfo
                                width: parent.width
                                topPadding: px(30)
                                horizontalAlignment: Text.AlignHCenter
                                text: mp.tx("Sin canción", "No song")
                                font.family: mp.fontB; font.pixelSize: px(14); color: mp.cMuted
                            }
                        }
                        ScrollBar.vertical: ScrollBarX {}
                    }
                    WheelCatcher { flick: infoFlick; visible: infoFlick.visible }

                }
            }
        }

        // ───────────── fixed player bar (always visible, like in YouTube Music) ─────────────
        Rectangle {
            id: playerBar
            opacity: mp.uiVis
            visible: mp.uiVis > 0.01
            anchors.bottom: parent.bottom
            width: parent.width
            height: mp.barH
            z: 60
            color: "transparent"
            WaveBar {
                id: barWave
                x: px(20)
                y: px(2)
                width: parent.width - px(40)
                height: px(28)
                compact: true
                z: 3
            }
            Controls {
                id: barCtl
                extras: false
                x: px(16)
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: px(12)
            }
            Text {
                id: barTime
                anchors.left: barCtl.right; anchors.leftMargin: px(14)
                anchors.verticalCenter: barCtl.verticalCenter
                width: px(84)
                text: mp.cur ? mp.fmtTime(mp.posSec) + " / " + mp.fmtTime(mp.durSec) : ""
                font.family: mp.fontB; font.pixelSize: px(12)
                color: mp.cMuted
            }
            Item {
                id: barInfo
                anchors.left: barTime.right; anchors.leftMargin: px(10)
                anchors.right: barRight.left; anchors.rightMargin: px(14)
                anchors.verticalCenter: barCtl.verticalCenter
                height: px(56)
                Cover {
                    id: barArt
                    anchors.verticalCenter: parent.verticalCenter
                    width: px(56); height: width; r: px(16)
                    src: mp.cur ? mp.cur.art : ""
                }
                Column {
                    anchors.left: barArt.right; anchors.leftMargin: px(12)
                    anchors.right: barLike.left; anchors.rightMargin: px(6)
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        width: parent.width
                        text: mp.cur ? mp.cur.t : mp.tx("Nada sonando", "Nothing playing")
                        elide: Text.ElideRight
                        font.family: mp.fontA; font.pixelSize: px(16); font.weight: Font.DemiBold
                        color: mp.cOnSurface
                    }
                    Text {
                        width: parent.width
                        text: mp.cur ? mp.artistOf(mp.cur) + (mp.cur.al ? "  ·  " + mp.cur.al : "") : mp.tx("Elige una canción para empezar", "Pick a song to start")
                        elide: Text.ElideRight
                        font.family: mp.fontB; font.pixelSize: px(12)
                        color: mp.cOnSurfVar
                    }
                }
                MouseArea {
                    anchors.left: parent.left; anchors.right: barLike.left
                    height: parent.height
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mp.playerOpen = !mp.playerOpen
                }
                IconBtn {
                    id: barLike
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !!mp.cur
                    readonly property bool liked: mp.cur ? mp.isLiked(mp.curPath) : false
                    glyph: "favorite"
                    glyphColor: liked ? mp.cTertiary : mp.cOnSurfVar
                    tip: liked ? mp.tx("Quitar de «Me gusta»", "Remove from Liked") : mp.tx("Me gusta", "Like")
                    onClicked: mp.likePaths([mp.curPath])
                }
            }
            Row {
                id: barRight
                anchors.right: parent.right; anchors.rightMargin: px(14)
                anchors.verticalCenter: barCtl.verticalCenter
                spacing: px(2)
                VolumeRow {
                    visible: mp.width >= px(1180)
                    width: visible ? px(150) : 0
                    anchors.verticalCenter: parent.verticalCenter
                }
                IconBtn {
                    visible: mp.width < px(1180)
                    anchors.verticalCenter: parent.verticalCenter
                    glyph: mp.muted || mp.volume === 0 ? "volume_off" : mp.volume < 0.4 ? "volume_down" : "volume_up"
                    tip: mp.muted ? mp.tx("Activar sonido (M)", "Unmute (M)") : mp.tx("Silenciar (M)", "Mute (M)")
                    onClicked: mp.muted = !mp.muted
                }
                IconBtn {
                    anchors.verticalCenter: parent.verticalCenter
                    glyph: mp.repeatMode === "one" ? "repeat_one" : "repeat"
                    active: mp.repeatMode !== "off"
                    tip: mp.repeatMode === "off" ? mp.tx("Repetir: no (Ctrl+R)", "Repeat: off (Ctrl+R)")
                       : mp.repeatMode === "all" ? mp.tx("Repetir: todo", "Repeat: all") : mp.tx("Repetir: una", "Repeat: one")
                    onClicked: mp.cycleRepeat()
                }
                IconBtn {
                    anchors.verticalCenter: parent.verticalCenter
                    glyph: "shuffle"
                    active: mp.shuffle
                    tip: mp.tx("Aleatorio (Ctrl+S)", "Shuffle (Ctrl+S)")
                    onClicked: mp.toggleShuffle()
                }
                IconBtn {
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: px(38); implicitHeight: px(38); radius: px(19); gsize: px(24)
                    glyph: mp.playerOpen ? "keyboard_arrow_down" : "keyboard_arrow_up"
                    tip: mp.tx("Pantalla de reproducción (Ctrl+L)", "Now playing (Ctrl+L)")
                    onClicked: mp.playerOpen = !mp.playerOpen
                }
            }
        }

        // ── full-screen lyrics + background cava ──
        Rectangle {
            id: lyrFs
            anchors.fill: parent
            z: 100
            color: "transparent"     // no background of its own: the window's background shows through (glass included)
            opacity: 1 - mp.uiVis
            visible: opacity > 0.01

            // exit button that shows on mouse move and auto-hides
            property bool chrome: true
            function poke() { chrome = true; fsIdle.restart(); }
            Timer { id: fsIdle; interval: 2600; onTriggered: lyrFs.chrome = false }
            Connections {
                target: mp
                function onLyrFullChanged() {
                    if (!mp.lyrFull) return;
                    lyrFs.poke();
                    fsWheel.recent = false;
                    fsCavaCv.smoothVals = [];
                    fsCavaCv.wasSilent = false;
                    fsCavaCv.requestPaint();
                    Qt.callLater(function () { fsLyr.follow(true); });
                }
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.AllButtons
                cursorShape: lyrFs.chrome ? Qt.ArrowCursor : Qt.BlankCursor
                onPositionChanged: lyrFs.poke()
                onPressed: lyrFs.poke()
                onWheel: (w) => {}
            }

            // ── visualizer: blurred overlapping waves with glow ──
            readonly property color activeCol: Qt.lighter(mp.cPrimary, 1.08)
            readonly property real cavaPad: px(220)
            readonly property real cavaMaxH: height / 3
            readonly property int  cavaDs: 8         // the canvas is painted at 1/8 and scaled up (cheap and already smooth)
            Item {
                id: fsCavaSrc
                x: -lyrFs.cavaPad
                y: -lyrFs.cavaPad
                width: lyrFs.width + lyrFs.cavaPad * 2
                height: lyrFs.height + lyrFs.cavaPad * 2
                visible: false
                layer.enabled: true
                layer.smooth: true
                // 1/16 resolution texture: cheap, wide blur
                layer.textureSize: Qt.size(Math.max(1, Math.round(width / 16)), Math.max(1, Math.round(height / 16)))
                Canvas {
                    id: fsCavaCv
                    width: Math.ceil(parent.width / lyrFs.cavaDs)
                    height: Math.ceil(parent.height / lyrFs.cavaDs)
                    scale: lyrFs.cavaDs
                    transformOrigin: Item.TopLeft
                    property var smoothVals: []
                    property bool wasSilent: false
                    property color c1: lyrFs.activeCol
                    onC1Changed: { wasSilent = false; requestPaint(); }
                    onWidthChanged: { wasSilent = false; requestPaint(); }
                    onHeightChanged: { wasSilent = false; requestPaint(); }
                    Timer {
                        interval: 25; repeat: true
                        running: lyrFs.visible && mp.visible
                        onTriggered: fsCavaCv.requestPaint()
                    }
                    onPaint: {
                        var ctx = getContext("2d");
                        if (!ctx || width <= 0 || height <= 0) return;
                        var src = mp.fsCava, M = src.length, sm = smoothVals;
                        if (sm.length !== M) { sm = []; for (var q = 0; q < M; q++) sm.push(0); }
                        var silent = true;
                        for (var q2 = 0; q2 < M; q2++) {
                            var tv = src[q2] || 0;
                            sm[q2] += (tv - sm[q2]) * (tv > sm[q2] ? 0.5 : 0.14);
                            if (sm[q2] > 0.004) silent = false;
                        }
                        smoothVals = sm;
                        if (silent && wasSilent && !mp.playing) return;
                        wasSilent = silent;
                        ctx.clearRect(0, 0, width, height);

                        var ds = lyrFs.cavaDs, W = width, H = height, pad = lyrFs.cavaPad / ds, maxH = lyrFs.cavaMaxH / ds;
                        var baseY = H - pad;
                        var innerW = Math.max(1, W - pad * 2);
                        var now = Date.now() / 1000;
                        function valAt(t) {
                            if (M < 2) return 0;
                            var pos = Math.max(0, Math.min(1, t)) * (M - 1);
                            var lo = Math.floor(pos), hi = Math.min(M - 1, lo + 1), f = pos - lo;
                            return sm[lo] * (1 - f) + sm[hi] * f;
                        }
                        function rgba(c, a) {
                            return "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + "," + a + ")";
                        }
                        // back to front: the tallest one at the back
                        var layers = [
                            { c: c1, m: 1.00, ph: 0.0, sp:  1.25, sh:  0.035, a: 0.70 },
                            { c: c1, m: 0.78, ph: 2.1, sp: -0.95, sh: -0.045, a: 0.72 },
                            { c: c1, m: 0.56, ph: 4.2, sp:  0.75, sh:  0.025, a: 0.78 }
                        ];
                        var P = 48;
                        for (var li = 0; li < layers.length; li++) {
                            var L = layers[li];
                            var drift = L.sh * Math.sin(now * 0.45 + L.ph);
                            var pts = [];
                            for (var k = 0; k <= P; k++) {
                                var xx = k / P * W;
                                var t = (xx - pad) / innerW;
                                var v = valAt(t + drift);
                                var swell = Math.sin(t * Math.PI * 2.2 + now * 0.6 * L.sp + L.ph);
                                var ripple = (0.025 + v * 0.06) * Math.sin(t * Math.PI * 6 + now * 2 * L.sp + L.ph);
                                var lvl = 0.05 + 0.025 * swell + v * 0.92 + ripple;
                                var hgt = Math.max(0, Math.min(1, lvl)) * maxH * L.m;
                                pts.push({ x: xx, y: baseY - hgt });
                            }
                            var grad = ctx.createLinearGradient(0, baseY - maxH * L.m, 0, H);
                            grad.addColorStop(0, rgba(L.c, L.a));
                            grad.addColorStop(0.6, rgba(L.c, L.a * 0.55));
                            grad.addColorStop(1, rgba(L.c, L.a * 0.35));
                            ctx.fillStyle = grad;
                            ctx.beginPath();
                            ctx.moveTo(0, H);
                            ctx.lineTo(pts[0].x, pts[0].y);
                            for (var k2 = 1; k2 < pts.length; k2++) {
                                var mx = (pts[k2 - 1].x + pts[k2].x) / 2, my = (pts[k2 - 1].y + pts[k2].y) / 2;
                                ctx.quadraticCurveTo(pts[k2 - 1].x, pts[k2 - 1].y, mx, my);
                            }
                            ctx.lineTo(W, pts[pts.length - 1].y);
                            ctx.lineTo(W, H);
                            ctx.closePath();
                            ctx.fill();
                        }
                    }
                }
            }
            // 1st blur pass at very low resolution
            MultiEffect {
                id: fsCavaBlur1
                source: fsCavaSrc
                x: fsCavaSrc.x; y: fsCavaSrc.y
                width: fsCavaSrc.width; height: fsCavaSrc.height
                visible: false
                autoPaddingEnabled: false
                blurEnabled: true
                blurMax: 64
                blur: 1.0
                blurMultiplier: 2.0
                layer.enabled: true
                layer.smooth: true
                layer.textureSize: Qt.size(Math.max(1, Math.round(width / 12)), Math.max(1, Math.round(height / 12)))
            }
            // glow: halo of the same color, lighter, tinting the whole background
            MultiEffect {
                source: fsCavaBlur1
                x: fsCavaSrc.x; y: fsCavaSrc.y
                width: fsCavaSrc.width; height: fsCavaSrc.height
                visible: lyrFs.visible
                autoPaddingEnabled: false
                blurEnabled: true
                blurMax: 64
                blur: 1.0
                blurMultiplier: 2.5
                colorization: 1.0
                colorizationColor: lyrFs.activeCol
                brightness: 0.12
                opacity: 0.34
            }
            // body: same wave, blurred but with a bit more shape
            MultiEffect {
                source: fsCavaBlur1
                x: fsCavaSrc.x; y: fsCavaSrc.y
                width: fsCavaSrc.width; height: fsCavaSrc.height
                visible: lyrFs.visible
                autoPaddingEnabled: false
                blurEnabled: true
                blurMax: 64
                blur: 1.0
                blurMultiplier: 1.2
                colorization: 1.0
                colorizationColor: lyrFs.activeCol
                opacity: 0.22
            }

            // ── lyrics ──
            ListView {
                id: fsLyr
                anchors.fill: parent
                visible: mp.lyr.lines.length > 0
                model: lyrFs.visible ? mp.lyr.lines : []
                clip: true
                spacing: px(24)
                interactive: false
                boundsBehavior: Flickable.StopAtBounds
                cacheBuffer: height
                onCountChanged: if (count > 0) Qt.callLater(function () { fsLyr.follow(true); })
                onHeightChanged: Qt.callLater(function () { fsLyr.follow(true); })
                onWidthChanged: Qt.callLater(function () { fsLyr.follow(true); })
                readonly property real lineW: Math.min(width - px(120), px(1500))
                readonly property real curScale: 1.12
                function follow(instant) {
                    if (!mp.lyrFull || !mp.lyr.synced || mp.lyrIndex < 0 || fsWheel.recent || height <= 0) return;
                    var it = itemAtIndex(mp.lyrIndex);
                    if (!it) { positionViewAtIndex(mp.lyrIndex, ListView.Center); it = itemAtIndex(mp.lyrIndex); if (!it) return; }
                    // active paragraph centered in the window
                    var tgt = it.y + it.height / 2 - height / 2;
                    tgt = Math.max(originY, Math.min(originY + Math.max(0, contentHeight - height), tgt));
                    fsFollow.stop();
                    if (instant || Math.abs(tgt - contentY) > height * 1.5) { contentY = tgt; return; }
                    fsFollow.from = contentY; fsFollow.to = tgt; fsFollow.start();
                }
                NumberAnimation { id: fsFollow; target: fsLyr; property: "contentY"; duration: 750; easing.type: Easing.InOutSine }
                Connections {
                    target: mp
                    function onLyrIndexChanged() { fsLyr.follow(false); }
                    function onLyrChanged() { Qt.callLater(function () { fsLyr.positionViewAtBeginning(); fsLyr.follow(true); }); }
                }
                Connections {
                    target: fsWheel
                    function onRecentChanged() { if (fsWheel.recent) fsFollow.stop(); else fsLyr.follow(false); }
                }
                // half-window padding so the first/last lines can center
                header: Item { width: 1; height: fsLyr.height * (mp.lyr.synced ? 0.5 : 0.18) }
                footer: Item { width: 1; height: fsLyr.height * 0.5 }
                delegate: Item {
                    id: fsRow
                    required property var modelData
                    required property int index
                    readonly property bool isCur: mp.lyr.synced && index === mp.lyrIndex
                    readonly property int dist: mp.lyr.synced && mp.lyrIndex >= 0 ? Math.abs(index - mp.lyrIndex) : 0
                    property real glow: isCur ? 1 : 0
                    Behavior on glow { NumberAnimation { duration: 550; easing.type: Easing.OutCubic } }
                    width: fsLyr.width
                    height: fsLine.height
                    // centered container; scale/opacity apply to text + glow
                    Item {
                        id: fsWrap
                        width: fsLine.width
                        height: fsLine.height
                        x: Math.round((fsRow.width - width) / 2)
                        transformOrigin: Item.Center
                        scale: fsRow.isCur ? fsLyr.curScale : 1
                        Behavior on scale { NumberAnimation { duration: 480; easing.type: Easing.OutCubic } }
                        opacity: !mp.lyr.synced ? 0.92 : fsRow.isCur ? 1 : Math.max(0.22, 0.62 - fsRow.dist * 0.08)
                        Behavior on opacity { NumberAnimation { duration: 480 } }
                        // soft glow of the active paragraph: blurred, tinted copy behind the text
                        MultiEffect {
                            source: fsLine
                            anchors.fill: fsLine
                            visible: fsRow.glow > 0.01
                            blurEnabled: true
                            blurMax: 32
                            blur: 0.9
                            colorization: 1.0
                            colorizationColor: mp.cPrimary
                            brightness: 0.1
                            opacity: 0.42 * fsRow.glow
                        }
                        Text {
                            id: fsLine
                            width: Math.round(mp.lyr.synced ? fsLyr.lineW / fsLyr.curScale : fsLyr.lineW)
                            text: fsRow.modelData.s === "" ? (mp.lyr.synced ? "♪" : " ") : fsRow.modelData.s
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                            font.family: mp.fontA
                            font.pixelSize: mp.lyr.synced ? px(56) : px(38)
                            font.weight: mp.lyr.synced ? Font.Bold : Font.DemiBold
                            lineHeight: 1.1
                            color: !mp.lyr.synced ? mp.cOnSurface : fsRow.isCur ? lyrFs.activeCol : mp.cOnSurfVar
                            Behavior on color { ColorAnimation { duration: 480 } }
                            HoverHandler { enabled: mp.lyr.synced; cursorShape: Qt.PointingHandCursor }
                            TapHandler { enabled: mp.lyr.synced; onTapped: { mp.seekTo(fsRow.modelData.t); if (!mp.playing) mp.togglePlay(); fsWheel.recent = false; } }
                        }
                    }
                }
            }
            WheelCatcher {
                id: fsWheel
                flick: fsLyr
                visible: fsLyr.visible
                property bool recent: false
                onWheeled: { fsWheel.recent = true; fsRecent.restart(); lyrFs.poke(); }
                Timer { id: fsRecent; interval: 4000; onTriggered: fsWheel.recent = false }
            }

            // no lyrics
            Column {
                anchors.centerIn: parent
                width: Math.min(parent.width - px(64), px(560))
                visible: !fsLyr.visible
                spacing: px(14)
                Glyph { anchors.horizontalCenter: parent.horizontalCenter; text: "lyrics"; size: px(56); color: mp.cMutedDeep }
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: mp.cur ? mp.tx("Esta canción no tiene letra", "This song has no lyrics") : mp.tx("Nada sonando", "Nothing playing")
                    font.family: mp.fontA; font.pixelSize: px(22); font.weight: Font.DemiBold; color: mp.cMuted
                }
                PillBtn {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: !!mp.cur
                    glyph: mp.npFetching ? "hourglass_top" : "travel_explore"
                    label: mp.tx("Buscar en línea", "Find online")
                    enabled: !mp.npFetching && mp.hasMutagen
                    onClicked: mp.quickFetchLyrics()
                }
            }

            // exit
            Rectangle {
                anchors.top: parent.top; anchors.right: parent.right
                anchors.margins: px(22)
                z: 60
                width: px(46); height: px(46); radius: px(23)
                color: mp.ga(mp.cSurfHigh, 0.55)
                opacity: lyrFs.chrome ? 1 : 0
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: 260 } }
                IconBtn {
                anchors.fill: parent
                implicitWidth: px(46); implicitHeight: px(46); radius: px(23); gsize: px(26)
                glyph: "fullscreen_exit"
                tip: mp.tx("Salir de pantalla completa (Esc)", "Exit full screen (Esc)")
                onClicked: mp.setLyrFull(false)
                }
            }
        }

        // ───────────── overlay: add music (file picker or drag and drop) ─────────────
        Item {
            id: impLayer
            anchors.fill: parent
            z: 150
            readonly property bool shown: mp.impOpen || (mp.impHover && !mp.edOpen)
            readonly property bool hot: mp.impHover
            visible: opacity > 0.01
            opacity: shown ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            Rectangle { anchors.fill: parent; color: "#000000"; opacity: mp.glass ? 0.0 : 0.55 }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.AllButtons
                onClicked: if (!mp.impBusy) mp.impOpen = false
                onWheel: (wheel) => { wheel.accepted = true; }
            }

            Rectangle {
                id: impCard
                anchors.centerIn: parent
                width: Math.min(parent.width - 80, px(580))
                height: impCol.implicitHeight + 64
                radius: 28
                color: mp.m3High
                scale: impLayer.shown ? (impLayer.hot ? 1.03 : 1) : 0.94
                Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
                Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onWheel: (wheel) => { wheel.accepted = true; } }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 12
                    radius: 20
                    color: mp.cPrimary
                    opacity: impLayer.hot ? 0.12 : 0
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                }
                Canvas {
                    anchors.fill: parent
                    anchors.margins: 12
                    property color lineColor: impLayer.hot ? mp.cPrimary : mp.cMuted
                    property bool solid: impLayer.hot
                    onLineColorChanged: requestPaint()
                    onSolidChanged: requestPaint()
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.strokeStyle = lineColor;
                        ctx.lineWidth = solid ? 2.5 : 2;
                        ctx.setLineDash(solid ? [] : [10, 7]);
                        ctx.beginPath();
                        ctx.roundedRect(1, 1, width - 2, height - 2, 20, 20);
                        ctx.stroke();
                    }
                }
                Rectangle {
                    anchors.top: parent.top; anchors.right: parent.right
                    anchors.topMargin: 22; anchors.rightMargin: 22
                    width: 32; height: 32; radius: 16
                    visible: !mp.impBusy
                    color: impCloseHov.hovered ? mp.cSurfVar : "transparent"
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Glyph { anchors.centerIn: parent; text: "close"; size: 18 }
                    HoverHandler { id: impCloseHov; cursorShape: Qt.PointingHandCursor }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: mp.impOpen = false }
                }

                ColumnLayout {
                    id: impCol
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 44; anchors.rightMargin: 44
                    spacing: 14

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 76; Layout.preferredHeight: 76
                        ShapeView {
                            anchors.fill: parent
                            visible: !mp.impBusy
                            from: "Cookie9Sided"; to: "Sunny"
                            t: impLayer.hot ? 1 : 0
                            rot: impLayer.hot ? 30 : 0
                            Behavior on t { NumberAnimation { duration: 420; easing.type: Easing.OutBack } }
                            Behavior on rot { NumberAnimation { duration: 420; easing.type: Easing.OutBack } }
                            fill: impLayer.hot ? mp.cPrimary : mp.cPrimCont
                            Glyph {
                                anchors.centerIn: parent
                                text: impLayer.hot ? "download" : "library_music"
                                size: 38
                                color: impLayer.hot ? mp.cOnPrimary : mp.m3OnPrimCont
                            }
                        }
                        MorphLoader { anchors.centerIn: parent; size: 56; fillColor: mp.cPrimary; visible: mp.impBusy; running: visible }
                    }
                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        text: mp.impState === "picking" ? mp.tx("Elige los archivos en la ventana del selector…", "Pick the files in the file picker…")
                            : mp.impState === "copying" ? (mp.importMode === "copy" ? mp.tx("Importando música…", "Importing music…") : mp.tx("Añadiendo a la biblioteca…", "Adding to library…"))
                            : impLayer.hot ? mp.tx("Suelta para añadir", "Drop to add")
                            : mp.tx("Arrastra aquí tus canciones o carpetas", "Drag your songs or folders here")
                        font.family: mp.fontA
                        font.pixelSize: px(19)
                        font.weight: Font.DemiBold
                        color: mp.cOnSurface
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: mp.impState === "copying" && mp.impTotal > 0
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideMiddle
                        text: mp.impDone + " / " + mp.impTotal + "  ·  " + mp.impCur
                        font.family: mp.fontB; font.pixelSize: px(12); color: mp.cOnSurfVar
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 40; Layout.rightMargin: 40
                        spacing: 10
                        visible: !mp.impBusy && !impLayer.hot
                        Rectangle { Layout.fillWidth: true; height: 1; color: mp.cMutedDeep }
                        Text { text: mp.tx("o", "or"); font.family: mp.fontB; font.pixelSize: px(12); color: mp.cMuted }
                        Rectangle { Layout.fillWidth: true; height: 1; color: mp.cMutedDeep }
                    }
                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: px(8)
                        visible: !impLayer.hot
                        enabled: !mp.impBusy
                        PillBtn { glyph: "folder_open"; label: mp.tx("Buscar en el explorador", "Browse files"); primary: true; implicitHeight: px(48); onClicked: mp.impPick("audio") }
                        PillBtn { glyph: "create_new_folder"; label: mp.tx("Carpeta", "Folder"); implicitHeight: px(48); onClicked: mp.impPick("dir") }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: impMsgRow.implicitHeight + 18
                        radius: 14
                        visible: mp.impState === "done" && mp.impMsg !== "" && !impLayer.hot
                        readonly property color kindColor: mp.impKind === "ok" ? mp.cPositive : mp.impKind === "warn" ? mp.cAccent : mp.cError
                        color: Qt.rgba(kindColor.r, kindColor.g, kindColor.b, 0.14)
                        RowLayout {
                            id: impMsgRow
                            anchors.left: parent.left; anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 14; anchors.rightMargin: 14
                            spacing: 10
                            Glyph { text: mp.impKind === "ok" ? "check_circle" : mp.impKind === "warn" ? "info" : "error"; size: 18; color: parent.parent.kindColor }
                            Text {
                                Layout.fillWidth: true
                                text: mp.impMsg
                                wrapMode: Text.WordWrap
                                font.family: mp.fontB; font.pixelSize: px(14)
                                color: mp.cOnSurface
                            }
                        }
                    }
                    Rectangle { Layout.fillWidth: true; Layout.topMargin: 4; height: 1; color: mp.cMutedDeep; opacity: 0.6 }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Text {
                            text: mp.tx("Al añadir:", "When adding:")
                            font.family: mp.fontB; font.pixelSize: px(12); font.weight: Font.Medium
                            color: mp.cOnSurfVar
                        }
                        Seg {
                            Layout.fillWidth: true
                            segHeight: px(36)
                            enabled: !mp.impBusy
                            current: mp.importMode
                            options: [
                                { value: "copy", label: mp.tx("Copiar a Música", "Copy to Music"), icon: "content_copy" },
                                { value: "add", label: mp.tx("Dejar donde están", "Keep in place"), icon: "link" }
                            ]
                            onPicked: (v) => mp.importMode = v
                        }
                    }

                    Text {
                        text: mp.tx("Formatos compatibles", "Supported formats")
                        font.family: mp.fontB; font.pixelSize: px(12); font.weight: Font.Medium
                        color: mp.cOnSurfVar
                    }
                    Repeater {
                        model: [
                            { icon: "graphic_eq", label: mp.tx("Con pérdida", "Lossy"), exts: ["MP3", "M4A", "AAC", "OGG", "OPUS", "WMA"] },
                            { icon: "high_quality", label: mp.tx("Sin pérdida", "Lossless"), exts: ["FLAC", "WAV", "AIFF", "ALAC", "APE", "WV"] },
                            { icon: "queue_music", label: mp.tx("Listas", "Playlists"), exts: ["M3U", "M3U8"] }
                        ]
                        delegate: RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 8
                            Glyph { text: modelData.icon; size: 16; color: mp.cPrimary; Layout.preferredWidth: 20 }
                            Text {
                                text: modelData.label
                                font.family: mp.fontB; font.pixelSize: px(12)
                                color: mp.cOnSurfVar
                                Layout.preferredWidth: 96
                                elide: Text.ElideRight
                            }
                            Flow {
                                Layout.fillWidth: true
                                spacing: 6
                                Repeater {
                                    model: modelData.exts
                                    delegate: Rectangle {
                                        required property string modelData
                                        width: impChipTxt.implicitWidth + 16
                                        height: 22; radius: 11
                                        color: mp.cSurfVar
                                        Text {
                                            id: impChipTxt
                                            anchors.centerIn: parent
                                            text: modelData
                                            font.family: mp.fontB; font.pixelSize: px(11); font.weight: Font.Medium
                                            color: mp.cOnSurfVar
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        Layout.topMargin: 2
                        text: mp.importMode === "copy"
                              ? mp.tx("Los archivos se copiarán a ", "Files will be copied to ") + mp.prettyPath(mp.libDirs[0] || mp.musicDir) + mp.tx(" (las carpetas mantienen su estructura; los duplicados se omiten).", " (folders keep their structure; duplicates are skipped).")
                              : mp.tx("Se añadirán a la biblioteca sin moverlos de su sitio.", "They'll be added to the library without moving them.")
                        font.family: mp.fontB; font.pixelSize: px(11)
                        color: mp.cMuted
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }

        // ───────────── tag editor ─────────────
        Item {
            id: edLayer
            anchors.fill: parent
            z: 120
            visible: opacity > 0.01
            opacity: mp.edOpen ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            Rectangle { anchors.fill: parent; color: mp.glass ? "transparent" : Qt.rgba(0, 0, 0, mp.light ? 0.25 : 0.5) }
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onWheel: (w) => {}; onClicked: if (!mp.edSaving) mp.edOpen = false }

            Rectangle {
                id: edCard
                anchors.centerIn: parent
                width: Math.min(parent.width - px(48), px(880))
                height: Math.min(parent.height - px(48), px(660))
                radius: 28
                color: mp.bgPop
                border.width: 1
                border.color: mp.lineCol
                scale: mp.edOpen ? 1 : 0.95
                Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutBack } }
                MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onWheel: (w) => {} }

                // header
                Item {
                    id: edHead
                    x: px(22); y: px(18)
                    width: parent.width - px(44)
                    height: px(44)
                    Rectangle {
                        id: edIco
                        anchors.verticalCenter: parent.verticalCenter
                        width: px(40); height: width; radius: width / 2
                        color: mp.ga(mp.cPrimary, 0.18)
                        Glyph { anchors.centerIn: parent; text: mp.edMode === "album" ? "library_music" : "edit"; size: px(20); color: mp.cPrimary }
                    }
                    Column {
                        anchors.left: edIco.right; anchors.leftMargin: px(12)
                        anchors.right: edTabs.left; anchors.rightMargin: px(12)
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: mp.edMode === "album" ? mp.tx("Álbum", "Album") + " · " + mp.songsLabel(mp.edPaths.length)
                                : mp.edMulti ? mp.tx("Editar ", "Edit ") + mp.songsLabel(mp.edPaths.length)
                                : mp.tx("Editar etiquetas", "Edit tags")
                            font.family: mp.fontA; font.pixelSize: px(17); font.weight: Font.DemiBold
                            color: mp.cOnSurface
                        }
                        Text {
                            width: parent.width
                            elide: Text.ElideMiddle
                            text: mp.edMulti ? mp.tx("Solo se cambian los campos que modifiques", "Only the fields you change are written")
                                             : (mp.edPaths.length ? mp.baseName(mp.edPaths[0]) : "")
                            font.family: mp.fontB; font.pixelSize: px(12); color: mp.cMuted
                        }
                    }
                    Seg {
                        id: edTabs
                        anchors.right: edCloseBtn.left; anchors.rightMargin: px(10)
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !mp.edMulti
                        cellW: px(124)
                        current: mp.edTab
                        options: [
                            { value: "info", label: mp.tx("Detalles", "Details"), icon: "sell" },
                            { value: "lyrics", label: mp.tx("Letra", "Lyrics"), icon: "lyrics" }
                        ]
                        onPicked: (v) => mp.edTab = v
                    }
                    IconBtn {
                        id: edCloseBtn
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        glyph: "close"
                        enabled: !mp.edSaving
                        onClicked: mp.edOpen = false
                    }
                }

                // tab: details
                Item {
                    id: edInfoTab
                    anchors.top: edHead.bottom; anchors.topMargin: px(16)
                    anchors.bottom: edFoot.top; anchors.bottomMargin: px(8)
                    x: px(22)
                    width: parent.width - px(44)
                    visible: mp.edTab === "info" || mp.edMulti

                    // cover
                    Column {
                        id: edCoverCol
                        width: Math.min(px(240), parent.width * 0.34)
                        spacing: px(10)
                        Rectangle {
                            id: edCoverBox
                            width: parent.width
                            height: width
                            radius: px(24)
                            color: mp.ga(mp.cPrimary, 0.10)
                            border.width: edCoverDrop.containsDrag ? 2 : 0
                            border.color: mp.cPrimary
                            Cover {
                                anchors.fill: parent
                                r: px(24)
                                res: 512
                                src: mp.edCoverShown
                                glyph: mp.edCoverMixed ? "photo_library" : "image"
                            }
                            Rectangle {
                                anchors.fill: parent
                                radius: px(24)
                                color: Qt.rgba(0, 0, 0, 0.45)
                                opacity: edCoverHov.hovered || edCoverDrop.containsDrag ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                                Column {
                                    anchors.centerIn: parent
                                    spacing: px(6)
                                    Glyph { anchors.horizontalCenter: parent.horizontalCenter; text: edCoverDrop.containsDrag ? "download" : "add_photo_alternate"; size: px(34); color: "white" }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: edCoverDrop.containsDrag ? mp.tx("Suelta la imagen", "Drop the image") : mp.tx("Cambiar carátula", "Change cover")
                                        font.family: mp.fontB; font.pixelSize: px(14); font.weight: Font.DemiBold; color: "white"
                                    }
                                }
                            }
                            Rectangle {
                                visible: mp.edCoverMode !== "keep" || mp.edCoverMixed
                                anchors.left: parent.left; anchors.top: parent.top; anchors.margins: px(10)
                                width: edCoverTag.implicitWidth + px(14); height: px(22); radius: px(11)
                                color: mp.cPrimary
                                Text {
                                    id: edCoverTag
                                    anchors.centerIn: parent
                                    text: mp.edCoverMode === "set" ? mp.tx("Nueva", "New") : mp.edCoverMode === "remove" ? mp.tx("Se quitará", "Will be removed") : mp.tx("Varias", "Mixed")
                                    font.family: mp.fontB; font.pixelSize: px(11); font.weight: Font.DemiBold; color: mp.cOnPrimary
                                }
                            }
                            HoverHandler { id: edCoverHov; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: mp.edPickCover() }
                            DropArea {
                                id: edCoverDrop
                                anchors.fill: parent
                                onEntered: (drag) => {
                                    var ok = false;
                                    if (drag.hasUrls) for (var i = 0; i < drag.urls.length; i++) if (mp.isImage(mp.urlToPath(drag.urls[i]))) ok = true;
                                    drag.accepted = ok;
                                }
                                onDropped: (drop) => {
                                    for (var i = 0; i < drop.urls.length; i++) {
                                        var p = mp.urlToPath(drop.urls[i]);
                                        if (mp.isImage(p)) { mp.edSetCover(p); drop.accept(Qt.CopyAction); return; }
                                    }
                                }
                            }
                        }
                        Flow {
                            width: parent.width
                            spacing: px(6)
                            PillBtn { glyph: "image"; label: mp.tx("Elegir…", "Choose…"); onClicked: mp.edPickCover() }
                            PillBtn {
                                glyph: "hide_image"; label: mp.tx("Quitar", "Remove"); danger: true
                                visible: mp.edCoverShown !== "" || mp.edCoverMixed
                                onClicked: mp.edRemoveCover()
                            }
                            PillBtn {
                                glyph: "folder_special"; label: mp.tx("Usar la de la carpeta", "Use folder image")
                                visible: mp.edFolderArt !== "" && mp.edCoverShown !== mp.edFolderArt
                                onClicked: mp.edSetCover(mp.edFolderArt)
                            }
                            PillBtn {
                                glyph: "undo"; label: mp.tx("Deshacer", "Undo")
                                visible: mp.edCoverMode !== "keep"
                                onClicked: mp.edResetCover()
                            }
                        }
                        Text {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: mp.tx("Arrastra una imagen sobre la carátula o haz clic para elegirla. Se guarda dentro del archivo de audio.", "Drag an image onto the cover or click to pick one. It's stored inside the audio file.")
                            font.family: mp.fontB; font.pixelSize: px(11); color: mp.cMuted
                        }
                    }

                    // fields
                    Flickable {
                        id: edFieldsFlick
                        anchors.left: edCoverCol.right; anchors.leftMargin: px(22)
                        anchors.right: parent.right
                        height: parent.height
                        clip: true
                        interactive: false
                        contentHeight: edGrid.height + px(8)
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: ScrollBarX {}
                        GridLayout {
                            id: edGrid
                            width: edFieldsFlick.width - px(10)
                            columns: 2
                            columnSpacing: px(12)
                            rowSpacing: px(10)
                            EdField { key: "title"; label: mp.tx("Título", "Title"); Layout.columnSpan: 2; Layout.fillWidth: true; visible: !mp.edMulti }
                            EdField { key: "artist"; label: mp.tx("Artista", "Artist"); Layout.columnSpan: 2; Layout.fillWidth: true }
                            EdField { key: "album"; label: mp.tx("Álbum", "Album"); Layout.columnSpan: 2; Layout.fillWidth: true }
                            EdField { key: "albumartist"; label: mp.tx("Artista del álbum", "Album artist"); Layout.fillWidth: true }
                            EdField { key: "genre"; label: mp.tx("Género", "Genre"); Layout.fillWidth: true }
                            EdField { key: "year"; label: mp.tx("Año", "Year"); Layout.fillWidth: true; numeric: true }
                            EdField { key: "composer"; label: mp.tx("Compositor", "Composer"); Layout.fillWidth: true }
                            EdField { key: "track"; label: mp.tx("Nº de pista", "Track no."); Layout.fillWidth: true; numeric: true; visible: !mp.edMulti }
                            EdField { key: "tracktotal"; label: mp.tx("Total de pistas", "Total tracks"); Layout.fillWidth: true; numeric: true; visible: !mp.edMulti }
                            EdField { key: "disc"; label: mp.tx("Disco", "Disc"); Layout.fillWidth: true; numeric: true }
                            EdField { key: "disctotal"; label: mp.tx("Total de discos", "Total discs"); Layout.fillWidth: true; numeric: true }
                            EdField { key: "comment"; label: mp.tx("Comentario", "Comment"); Layout.columnSpan: 2; Layout.fillWidth: true; visible: !mp.edMulti }
                            Rectangle {
                                Layout.columnSpan: 2
                                Layout.fillWidth: true
                                visible: mp.edMulti
                                Layout.preferredHeight: px(52)
                                radius: px(16)
                                color: mp.bgField
                                Text {
                                    anchors.left: parent.left; anchors.leftMargin: px(14)
                                    anchors.right: edNumSw.left; anchors.rightMargin: px(10)
                                    anchors.verticalCenter: parent.verticalCenter
                                    wrapMode: Text.WordWrap
                                    text: mp.tx("Numerar las pistas en el orden actual (1 – ", "Number tracks in the current order (1 – ") + mp.edPaths.length + ")"
                                    font.family: mp.fontB; font.pixelSize: px(14); color: mp.cOnSurface
                                }
                                Toggle { id: edNumSw; anchors.right: parent.right; anchors.rightMargin: px(12); anchors.verticalCenter: parent.verticalCenter; checked: mp.edNumber; onToggled: mp.edNumber = !mp.edNumber }
                            }
                        }
                    }
                    WheelCatcher { flick: edFieldsFlick }
                }

                // tab: lyrics
                Item {
                    id: edLyrTab
                    anchors.top: edHead.bottom; anchors.topMargin: px(16)
                    anchors.bottom: edFoot.top; anchors.bottomMargin: px(8)
                    x: px(22)
                    width: parent.width - px(44)
                    visible: mp.edTab === "lyrics" && !mp.edMulti
                    readonly property bool synced: /\[\d{1,3}:\d{1,2}(?:[.:]\d{1,3})?\]/.test(mp.edLyrics)
                    readonly property bool isPlayingThis: mp.edPaths.length === 1 && mp.edPaths[0] === mp.curPath

                    Flow {
                        id: edLyrTools
                        width: parent.width
                        spacing: px(6)
                        PillBtn {
                            glyph: mp.edFetching ? "hourglass_top" : "travel_explore"
                            label: mp.edFetching ? mp.tx("Buscando…", "Searching…") : mp.tx("Buscar en LRCLIB", "Search LRCLIB")
                            enabled: !mp.edFetching
                            primary: mp.edLyrics.trim() === ""
                            onClicked: mp.edFetchLyrics()
                        }
                        PillBtn { glyph: "upload_file"; label: mp.tx("Importar .lrc/.txt", "Import .lrc/.txt"); onClicked: mp.edImportLrc() }
                        PillBtn {
                            glyph: "graphic_eq"
                            label: mp.tx("Editor de sincronización", "Sync editor")
                            primary: edLyrTab.synced
                            onClicked: mp.openLyricSync(mp.edPaths[0], mp.edLyricsDirty ? mp.edLyrics : "")
                        }
                        PillBtn {
                            glyph: "more_time"
                            label: mp.tx("Marcar tiempo", "Stamp time")
                            enabled: edLyrTab.isPlayingThis
                            onClicked: mp.stampLine(edLyrArea)
                        }
                        PillBtn {
                            glyph: "timer_off"; label: mp.tx("Quitar tiempos", "Strip times")
                            visible: edLyrTab.synced
                            onClicked: { edLyrArea.text = mp.stripLrc(edLyrArea.text); }
                        }
                        PillBtn {
                            glyph: "delete"; label: mp.tx("Borrar", "Clear"); danger: true
                            visible: mp.edLyrics !== ""
                            onClicked: edLyrArea.text = ""
                        }
                    }
                    Rectangle {
                        id: edLyrBox
                        anchors.top: edLyrTools.bottom; anchors.topMargin: px(10)
                        anchors.bottom: edLyrOpts.top; anchors.bottomMargin: px(10)
                        width: parent.width
                        radius: px(18)
                        color: mp.bgField
                        border.width: edLyrArea.activeFocus ? 1 : 0
                        border.color: mp.ga(mp.cPrimary, 0.6)
                        Flickable {
                            id: edLyrFlick
                            anchors.fill: parent
                            anchors.margins: px(4)
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            contentHeight: edLyrArea.implicitHeight
                            ScrollBar.vertical: ScrollBarX {}
                            TextArea.flickable: TextArea {
                                id: edLyrArea
                                property bool loading: false
                                wrapMode: TextEdit.Wrap
                                selectByMouse: true
                                color: mp.cOnSurface
                                selectionColor: mp.ga(mp.cPrimary, 0.45)
                                selectedTextColor: mp.cOnSurface
                                font.family: mp.fontB
                                font.pixelSize: px(14)
                                leftPadding: px(14); rightPadding: px(14); topPadding: px(12); bottomPadding: px(12)
                                placeholderText: mp.tx("Escribe o pega la letra aquí.\nPara letra sincronizada usa el formato LRC:  [01:23.45] texto de la línea", "Type or paste the lyrics here.\nFor synced lyrics use LRC format:  [01:23.45] line text")
                                placeholderTextColor: mp.cMuted
                                background: Item {}
                                onTextChanged: if (!loading) { mp.edLyrics = text; mp.edLyricsDirty = true; }
                                Connections {
                                    target: mp
                                    function onEdRevChanged() { edLyrArea.loading = true; edLyrArea.text = mp.edLyrics; edLyrArea.loading = false; }
                                }
                            }
                        }
                    }
                    Row {
                        id: edLyrOpts
                        anchors.bottom: parent.bottom
                        width: parent.width
                        spacing: px(10)
                        height: px(30)
                        Toggle { anchors.verticalCenter: parent.verticalCenter; checked: mp.edLrcSidecar; onToggled: mp.edLrcSidecar = !mp.edLrcSidecar }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: mp.tx("Guardar también como archivo .lrc junto a la canción", "Also save as a .lrc file next to the song")
                            font.family: mp.fontB; font.pixelSize: px(12); color: mp.cOnSurfVar
                        }
                        Item { width: px(8); height: 1 }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: edLyrTab.synced ? "●  " + mp.tx("Sincronizada (LRC)", "Synced (LRC)") : (mp.edLyrics.trim() ? "○  " + mp.tx("Sin tiempos", "No timestamps") : "")
                            font.family: mp.fontB; font.pixelSize: px(12); font.weight: Font.Medium
                            color: edLyrTab.synced ? mp.cPrimary : mp.cMuted
                        }
                    }
                }

                // footer
                Item {
                    id: edFoot
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: px(18)
                    x: px(22)
                    width: parent.width - px(44)
                    height: px(40)
                    Text {
                        anchors.left: parent.left
                        anchors.right: edBtns.left
                        anchors.rightMargin: px(12)
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                        text: !mp.edInfo ? "" : mp.edMulti ? mp.songsLabel(mp.edPaths.length)
                            : [mp.edInfo.format, mp.edInfo.bitrate ? mp.edInfo.bitrate + " kbps" : "", mp.fmtTime(mp.edInfo.duration), mp.fmtSize(mp.edInfo.size)].filter(Boolean).join("  ·  ")
                              + (mp.edInfo.writable ? "" : "  ·  " + mp.tx("solo lectura", "read-only"))
                        font.family: mp.fontB; font.pixelSize: px(12)
                        color: mp.edInfo && !mp.edInfo.writable ? mp.cError : mp.cMuted
                    }
                    Row {
                        id: edBtns
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: px(8)
                        PillBtn { label: mp.tx("Cancelar", "Cancel"); enabled: !mp.edSaving; onClicked: mp.edOpen = false }
                        PillBtn {
                            glyph: mp.edSaving ? "hourglass_top" : "save"
                            label: mp.edSaving ? mp.tx("Guardando…", "Saving…") : mp.tx("Guardar en el archivo", "Save to file")
                            primary: true
                            enabled: !mp.edSaving && !mp.edLoading
                            onClicked: mp.edSave()
                        }
                    }
                }

                // loading
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: mp.bgPop
                    visible: mp.edLoading
                    MorphLoader { anchors.centerIn: parent; size: px(56); fillColor: mp.cPrimary; running: parent.visible }
                }
            }
            Shortcut { sequence: "Ctrl+Return"; enabled: mp.edOpen; onActivated: mp.edSave() }
        }

        // ───────────── lyrics sync editor (full screen inside the window) ─────────────
        LyricSync {
            id: lyrSync
            mp: mp
            anchors.fill: parent
            z: 125
        }

        // ── dialogs ──
        Item {
            id: dlgLayer
            anchors.fill: parent
            z: 130
            property string k: ""
            Spring { id: dlgO; token: "effectsDefault"; target: mp.dlgKind !== "" ? 1 : 0 }
            Spring { id: dlgS; token: "spatialDefault"; eps: 0.002; target: mp.dlgKind !== "" ? 1 : 0 }
            visible: dlgO.value > 0.01
            Rectangle { anchors.fill: parent; color: "#000000"; opacity: (mp.glass ? 0.2 : 0.38) * Math.max(0, Math.min(1, dlgO.value)) }
            MouseArea { anchors.fill: parent; enabled: mp.dlgKind !== ""; acceptedButtons: Qt.AllButtons; onWheel: (w) => {}; onClicked: mp.closeDlg() }
            Rectangle {
                id: dlgCard
                anchors.centerIn: parent
                width: Math.min(parent.width - 40, px(dlgLayer.k === "libdirs" ? 540 : 460))
                height: dlgCol.height + px(48)
                radius: px(28)
                color: mp.m3High
                scale: 0.82 + 0.18 * dlgS.value
                opacity: Math.min(1, Math.max(0, dlgO.value))
                enabled: mp.dlgKind !== ""
                MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }
                Column {
                    id: dlgCol
                    x: px(24); y: px(24)
                    width: dlgCard.width - px(48)
                    spacing: px(16)
                    ShapeView {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: px(56); height: px(56)
                        from: "Sunny"; to: "Sunny"; rot: 20 * dlgS.value
                        fill: mp.dlgDanger ? mp.m3ErrCont : mp.m3SecCont
                        Glyph {
                            anchors.centerIn: parent
                            text: dlgLayer.k === "addto" ? "playlist_add" : dlgLayer.k === "libdirs" ? "folder_managed"
                                : dlgLayer.k === "confirm" ? (mp.dlgDanger ? "warning" : "help") : "edit"
                            size: px(24)
                            color: mp.dlgDanger ? mp.m3OnErrCont : mp.m3OnSecCont
                        }
                    }
                    T {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        role: "headlineSmall"
                        emph: true
                        wrapMode: Text.WordWrap
                        text: dlgLayer.k === "libdirs" ? mp.tx("Carpetas de la biblioteca", "Library folders") : mp.dlgTitle
                    }
                    T {
                        visible: text !== ""
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        role: "bodyMedium"
                        wrapMode: Text.WordWrap
                        color: mp.cOnSurfVar
                        text: dlgLayer.k === "libdirs" ? mp.tx("La música de estas carpetas (y sus subcarpetas) aparece en la biblioteca. Lo que importes se copia a la primera.", "Music in these folders (and subfolders) shows in the library. Imports are copied into the first one.")
                            : dlgLayer.k === "addto" ? mp.songsLabel(mp.dlgPaths.length) : mp.dlgText
                    }
                    Field {
                        id: dlgField
                        visible: dlgLayer.k === "input"
                        width: parent.width
                        height: px(56)
                        onAccepted: mp.acceptDlg(dlgField.text)
                        onEscaped: mp.closeDlg()
                    }

                    // add to playlist (segmented list)
                    Column {
                        visible: dlgLayer.k === "addto"
                        width: parent.width
                        spacing: px(2)
                        Item {
                            width: parent.width; height: px(60)
                            Spring { id: dlgNewH; token: "effectsFast"; target: dlgNewMa.containsMouse ? 1 : 0 }
                            Rectangle {
                                anchors.fill: parent
                                topLeftRadius: px(20); topRightRadius: px(20); bottomLeftRadius: px(4); bottomRightRadius: px(4)
                                color: mp.m3TerCont
                                Rectangle { anchors.fill: parent; topLeftRadius: parent.topLeftRadius; topRightRadius: parent.topRightRadius; bottomLeftRadius: parent.bottomLeftRadius; bottomRightRadius: parent.bottomRightRadius; color: mp.m3OnTerCont; opacity: 0.08 * Math.max(0, dlgNewH.value) }
                            }
                            ShapeView {
                                id: dlgNewIco
                                x: px(10); anchors.verticalCenter: parent.verticalCenter
                                width: px(40); height: width
                                from: "Cookie9Sided"; to: "Cookie9Sided"; rot: 30 * dlgNewH.value
                                fill: mp.m3OnTerCont
                                Glyph { anchors.centerIn: parent; text: "add"; size: px(22); color: mp.m3TerCont }
                            }
                            T {
                                anchors.left: dlgNewIco.right; anchors.leftMargin: px(14)
                                anchors.verticalCenter: parent.verticalCenter
                                role: "titleMedium"
                                text: mp.tx("Nueva lista…", "New playlist…")
                                color: mp.m3OnTerCont
                            }
                            MouseArea { id: dlgNewMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { var ps = mp.dlgPaths; mp.dlgKind = ""; mp.newPlaylistDlg(ps); } }
                        }
                        Item {
                            width: parent.width
                            height: dlgPlList.height
                            ListView {
                                id: dlgPlList
                                width: parent.width
                                height: Math.min(contentHeight, px(320))
                                clip: true
                                interactive: false
                                spacing: px(2)
                                boundsBehavior: Flickable.StopAtBounds
                                model: { var _p = mp.plRev; return mp.playlists.slice(); }
                                ScrollBar.vertical: ScrollBarX {}
                                delegate: Item {
                                    id: dpl
                                    required property var modelData
                                    required property int index
                                    width: dlgPlList.width; height: px(60)
                                    readonly property real rb: index === dlgPlList.count - 1 ? px(20) : px(4)
                                    Spring { id: dplH; token: "effectsFast"; target: dplMa.containsMouse ? 1 : 0 }
                                    Rectangle {
                                        anchors.fill: parent
                                        topLeftRadius: px(4); topRightRadius: px(4); bottomLeftRadius: dpl.rb; bottomRightRadius: dpl.rb
                                        color: mp.m3Cont
                                        Rectangle { anchors.fill: parent; topLeftRadius: parent.topLeftRadius; topRightRadius: parent.topRightRadius; bottomLeftRadius: parent.bottomLeftRadius; bottomRightRadius: parent.bottomRightRadius; color: mp.cOnSurface; opacity: 0.08 * Math.max(0, dplH.value) }
                                    }
                                    Mosaic {
                                        id: dplArt
                                        x: px(10); anchors.verticalCenter: parent.verticalCenter
                                        width: px(40); height: width; r: px(12)
                                        glyph: dpl.modelData.fav ? "favorite" : "queue_music"
                                        arts: mp.plArts(dpl.modelData)
                                    }
                                    T {
                                        anchors.left: dplArt.right; anchors.leftMargin: px(14)
                                        anchors.right: dplCount.left; anchors.rightMargin: px(8)
                                        anchors.verticalCenter: parent.verticalCenter
                                        role: "bodyLarge"
                                        text: dpl.modelData.name
                                    }
                                    T {
                                        id: dplCount
                                        anchors.right: parent.right; anchors.rightMargin: px(16)
                                        anchors.verticalCenter: parent.verticalCenter
                                        role: "labelLarge"
                                        text: dpl.modelData.tracks.length
                                        color: mp.cOnSurfVar
                                    }
                                    MouseArea { id: dplMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { var ps = mp.dlgPaths; mp.closeDlg(); mp.addToPlaylist(dpl.modelData.id, ps); } }
                                }
                            }
                            WheelCatcher { flick: dlgPlList }
                        }
                    }

                    // library folders (segmented list)
                    Column {
                        visible: dlgLayer.k === "libdirs"
                        width: parent.width
                        spacing: px(2)
                        Repeater {
                            id: ldrRep
                            model: mp.libDirs
                            delegate: Rectangle {
                                id: ldr
                                required property string modelData
                                required property int index
                                readonly property real rt: index === 0 ? px(20) : px(4)
                                readonly property real rb: index === mp.libDirs.length - 1 ? px(20) : px(4)
                                width: parent.width; height: px(56)
                                topLeftRadius: rt; topRightRadius: rt; bottomLeftRadius: rb; bottomRightRadius: rb
                                color: ldr.index === 0 ? mp.m3SecCont : mp.m3Cont
                                Glyph { id: ldrIco; x: px(16); anchors.verticalCenter: parent.verticalCenter; text: ldr.index === 0 ? "folder_special" : "folder"; size: px(22); color: ldr.index === 0 ? mp.m3OnSecCont : mp.cPrimary }
                                Column {
                                    anchors.left: ldrIco.right; anchors.leftMargin: px(14)
                                    anchors.right: ldrDel.left; anchors.rightMargin: px(6)
                                    anchors.verticalCenter: parent.verticalCenter
                                    T { width: parent.width; role: "bodyLarge"; elide: Text.ElideMiddle; text: mp.prettyPath(ldr.modelData); color: ldr.index === 0 ? mp.m3OnSecCont : mp.cOnSurface }
                                    T { visible: ldr.index === 0; role: "labelMedium"; text: mp.tx("Destino de importación", "Import target"); color: mp.m3OnSecCont }
                                }
                                IconBtn {
                                    id: ldrDel
                                    anchors.right: parent.right; anchors.rightMargin: px(8)
                                    anchors.verticalCenter: parent.verticalCenter
                                    glyph: "close"; danger: true
                                    visible: mp.libDirs.length > 1
                                    tip: mp.tx("Quitar carpeta", "Remove folder")
                                    onClicked: mp.setLibDirs(mp.libDirs.filter(function (d, i) { return i !== ldr.index; }))
                                }
                            }
                        }
                        T {
                            visible: mp.extraFiles.length > 0
                            topPadding: px(6)
                            role: "bodySmall"
                            text: mp.extraFiles.length + mp.tx(" archivos añadidos desde otras ubicaciones", " files added from other locations")
                            color: mp.cOnSurfVar
                        }
                    }

                    Item {
                        width: parent.width
                        height: dlgBtns.height
                        Row {
                            visible: dlgLayer.k === "libdirs"
                            spacing: px(8)
                            PillBtn { glyph: "create_new_folder"; label: mp.tx("Añadir carpeta", "Add folder"); onClicked: mp.addLibDir() }
                            PillBtn { glyph: "refresh"; variant: "outlined"; label: mp.tx("Reescanear todo", "Full rescan"); enabled: !mp.scanning; onClicked: { mp.closeDlg(); mp.rescan(true); } }
                        }
                        Row {
                            id: dlgBtns
                            anchors.right: parent.right
                            spacing: px(8)
                            PillBtn { variant: "text"; label: dlgLayer.k === "libdirs" || dlgLayer.k === "addto" ? mp.tx("Cerrar", "Close") : mp.tx("Cancelar", "Cancel"); onClicked: mp.closeDlg() }
                            PillBtn {
                                visible: dlgLayer.k === "input" || dlgLayer.k === "confirm"
                                label: mp.dlgOk
                                primary: true
                                danger: mp.dlgDanger
                                onClicked: mp.acceptDlg(dlgField.text)
                            }
                        }
                    }
                }
            }
            Connections {
                target: mp
                function onDlgKindChanged() {
                    if (mp.dlgKind !== "") dlgLayer.k = mp.dlgKind;
                    if (mp.dlgKind === "input") {
                        dlgField.text = mp.dlgValue;
                        Qt.callLater(function () { dlgField.input.forceActiveFocus(); dlgField.input.selectAll(); });
                    }
                }
            }
            Shortcut { sequences: ["Return", "Enter"]; enabled: mp.dlgKind === "confirm"; onActivated: mp.acceptDlg("") }
        }

        // ── context menu ──
        Item {
            id: menuLayer
            anchors.fill: parent
            z: 140
            Spring { id: mnO; token: "spatialFast"; eps: 0.002; target: mp.menuOpen ? 1 : 0 }
            Spring { id: mnF; token: "effectsFast"; target: mp.menuOpen ? 1 : 0 }
            visible: mnF.value > 0.01
            MouseArea {
                anchors.fill: parent
                enabled: mp.menuOpen
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onPressed: { mp.menuOpen = false; mp.refocus(); }
                onWheel: (w) => { mp.menuOpen = false; }
            }
            Item {
                id: menuBox
                readonly property bool up: mp.menuY + height > rootBg.height - 6
                width: Math.max(px(240), menuCol.implicitW)
                height: menuCol.height
                x: Math.max(6, Math.min(mp.menuX, rootBg.width - width - 6))
                y: !up ? mp.menuY : Math.max(6, mp.menuY - height)
                opacity: Math.min(1, Math.max(0, mnF.value))
                enabled: mp.menuOpen
                transform: Scale {
                    origin.x: 0
                    origin.y: menuBox.up ? menuBox.height : 0
                    xScale: 0.9 + 0.1 * mnO.value
                    yScale: 0.55 + 0.45 * mnO.value
                }
                Rectangle { y: 4; width: parent.width; height: parent.height; radius: px(16); color: mp.ga("#000000", mp.light ? 0.15 : 0.45) }
                Rectangle { anchors.fill: parent; radius: px(16); color: mp.m3Lowest }
                MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }
                Column {
                    id: menuCol
                    width: parent.width
                    spacing: 2
                    property real implicitW: 0
                    Repeater {
                        model: mp.menuGroups
                        delegate: Rectangle {
                            id: mg
                            required property var modelData
                            required property int index
                            readonly property bool first: index === 0
                            readonly property bool last: index === mp.menuGroups.length - 1
                            width: menuCol.width
                            height: mgCol.height + px(8)
                            color: mp.m3High
                            topLeftRadius: first ? px(16) : px(6); topRightRadius: first ? px(16) : px(6)
                            bottomLeftRadius: last ? px(16) : px(6); bottomRightRadius: last ? px(16) : px(6)
                            Column {
                                id: mgCol
                                x: px(4); y: px(4)
                                width: parent.width - px(8)
                                spacing: 2
                                Repeater {
                                    model: mg.modelData
                                    delegate: Item {
                                        id: mi
                                        required property var modelData
                                        width: mgCol.width
                                        height: px(44)
                                        opacity: mi.modelData.disabled ? 0.38 : 1
                                        Component.onCompleted: menuCol.implicitW = Math.max(menuCol.implicitW, miTxt.implicitWidth + miKey.implicitWidth + px(92))
                                        Spring { id: miH; token: "effectsFast"; target: miMa.containsMouse && !mi.modelData.disabled ? 1 : 0 }
                                        Rectangle {
                                            anchors.fill: parent
                                            radius: px(12)
                                            color: mi.modelData.danger ? mp.cError : mp.cOnSurface
                                            opacity: (mi.modelData.danger ? 0.12 : 0.08) * Math.max(0, miH.value)
                                        }
                                        Glyph {
                                            id: miIco
                                            x: px(12)
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: mi.modelData.icon || ""
                                            size: px(20)
                                            color: mi.modelData.danger ? mp.cError : mp.cOnSurfVar
                                        }
                                        T {
                                            id: miTxt
                                            anchors.left: miIco.right; anchors.leftMargin: px(12)
                                            anchors.right: miKey.left; anchors.rightMargin: px(8)
                                            anchors.verticalCenter: parent.verticalCenter
                                            role: "labelLarge"
                                            text: mi.modelData.label || ""
                                            color: mi.modelData.danger ? mp.cError : mp.cOnSurface
                                        }
                                        T {
                                            id: miKey
                                            anchors.right: parent.right; anchors.rightMargin: px(12)
                                            anchors.verticalCenter: parent.verticalCenter
                                            role: "labelMedium"
                                            text: mi.modelData.key || ""
                                            color: mp.cOnSurfVar
                                        }
                                        MouseArea {
                                            id: miMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            enabled: !mi.modelData.disabled
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: mp.runMenu(mi.modelData)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ───────────── snackbar ─────────────
        Rectangle {
            id: toastBox
            z: 160
            property string keep: ""
            Connections { target: mp; function onToastTextChanged() { if (mp.toastText !== "") toastBox.keep = mp.toastText; } }
            Spring { id: tsp; token: "spatialFast"; eps: 0.002; target: mp.toastText !== "" ? 1 : 0 }
            visible: tsp.value > 0.01
            anchors.horizontalCenter: parent.horizontalCenter
            y: rootBg.height - (mp.barH + px(20) + height) * Math.max(0, tsp.value) + (1 - Math.min(1, tsp.value)) * px(20)
            opacity: Math.min(1, Math.max(0, tsp.value))
            width: Math.min(rootBg.width - 80, Math.max(px(300), toastRow.implicitWidth + px(40)))
            height: Math.max(px(52), toastRow.height + px(24))
            radius: px(16)
            color: mp.m3InvSurf
            Row {
                id: toastRow
                x: px(20)
                anchors.verticalCenter: parent.verticalCenter
                spacing: px(12)
                Glyph {
                    anchors.verticalCenter: parent.verticalCenter
                    text: mp.toastErr ? "error" : "check_circle"
                    size: px(20)
                    color: mp.toastErr ? (mp.light ? mp.mixc(mp.cError, "#ffffff", 0.3) : mp.mixc(mp.cError, "#000000", 0.35)) : mp.m3InvOnSurf
                }
                T {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, Math.min(px(560), rootBg.width - 160))
                    role: "bodyMedium"
                    text: toastBox.keep
                    wrapMode: Text.Wrap
                    maximumLineCount: 6
                    color: mp.m3InvOnSurf
                }
            }
            MouseArea { anchors.fill: parent; onClicked: mp.toastText = "" }
        }

        // ───────────── tooltip ─────────────
        Rectangle {
            id: tipBox
            z: 170
            Spring { id: tipS; token: "spatialFast"; eps: 0.002; target: mp.tipShown && mp.tipText !== "" ? 1 : 0 }
            visible: tipS.value > 0.01
            x: Math.max(6, Math.min(rootBg.width - width - 6, mp.tipX - width / 2))
            y: mp.tipY + height > rootBg.height - 6 ? mp.tipY - height - 40 : mp.tipY
            width: tipT.implicitWidth + px(24)
            height: px(32)
            radius: height / 2
            color: mp.m3InvSurf
            scale: Math.max(0, tipS.value)
            opacity: Math.min(1, Math.max(0, tipS.value))
            transformOrigin: Item.Top
            T { id: tipT; anchors.centerIn: parent; role: "labelLarge"; text: mp.tipText; color: mp.m3InvOnSurf }
        }

        // ───────────── drop files anywhere on the window ─────────────
        DropArea {
            anchors.fill: parent
            z: 200
            enabled: !mp.edOpen && !mp.lsOpen
            onEntered: (drag) => {
                if (!drag.hasUrls || mp.impBusy) { drag.accepted = false; return; }
                drag.accept(Qt.CopyAction);
                mp.impHover = true;
            }
            onExited: mp.impHover = false
            onDropped: (drop) => mp.impHandleDrop(drop)
        }
    }
    }

    // ══ Components (M3 Expressive) ══

    component Glyph: Text {
        property real size: 18
        font.family: "Material Symbols Rounded"
        font.pixelSize: size
        color: mp.cOnSurfVar
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }

    component Spring: Item {
        id: sp
        visible: false
        property real target: 0
        property real value: 0
        property real velocity: 0
        property string token: "spatialDefault"
        property real stiffness: mp.sk(token)
        property real dampingRatio: mp.sz(token)
        property real eps: 0.001
        property bool ready: false
        property real initial: NaN
        readonly property bool moving: fa.running
        Component.onCompleted: { value = isNaN(initial) ? target : initial; ready = true; if (value !== target) fa.running = true }
        onTargetChanged: if (ready) fa.running = true
        function snap(v) { fa.running = false; value = v; velocity = 0; target = v }
        FrameAnimation {
            id: fa
            onTriggered: {
                const dt = Math.min(frameTime, 0.05)
                const n = Math.max(1, Math.ceil(dt / 0.003))
                const h = dt / n
                const k = sp.stiffness, c = 2 * sp.dampingRatio * Math.sqrt(k)
                let x = sp.value, v = sp.velocity
                for (let i = 0; i < n; i++) { const a = -k * (x - sp.target) - c * v; v += a * h; x += v * h }
                if (Math.abs(x - sp.target) < sp.eps && Math.abs(v) < sp.eps * 10) { x = sp.target; v = 0; running = false }
                sp.velocity = v; sp.value = x
            }
        }
    }


    component ShapeView: Canvas {
        id: sv
        property string from: "Circle"
        property string to: "Circle"
        property real t: 1
        property real rot: 0
        property real inset: 0.92
        property color fill: mp.cPrimary
        property color fill2: "transparent"
        property color stroke: "transparent"
        implicitWidth: 64
        implicitHeight: 64
        onFromChanged: requestPaint()
        onToChanged: requestPaint()
        onTChanged: requestPaint()
        onRotChanged: requestPaint()
        onFillChanged: requestPaint()
        onFill2Changed: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const s = Math.min(width, height) / 2 * inset
            shp.draw(ctx, from, to, t, width / 2, height / 2, s, rot)
            if (fill2.a > 0) {
                const g = ctx.createLinearGradient(0, 0, width, height)
                g.addColorStop(0, mp.css(fill)); g.addColorStop(1, mp.css(fill2))
                ctx.fillStyle = g
            } else ctx.fillStyle = mp.css(fill)
            ctx.fill()
            if (stroke.a > 0) { ctx.lineWidth = 2; ctx.strokeStyle = mp.css(stroke); ctx.stroke() }
        }
    }

    // Shape that cycles through a sequence on its own
    component AutoShape: ShapeView {
        id: as
        property var seq: ["Cookie9Sided", "Sunny", "Clover4Leaf", "Pentagon", "Flower", "Gem", "Heart", "SoftBurst"]
        property int idx: 0
        property int interval: 1800
        property real spinStep: 45
        property bool running: true
        property string morphToken: "spatialSlow"
        from: seq[(idx + seq.length - 1) % seq.length]
        to: seq[idx]
        t: am.value
        rot: ar.value
        Spring { id: am; target: 1; token: as.morphToken }
        Spring { id: ar; target: 0; token: as.morphToken; eps: 0.01 }
        Timer {
            interval: as.interval; repeat: true; running: as.running && as.visible
            onTriggered: { as.idx = (as.idx + 1) % as.seq.length; am.snap(0); am.target = 1; ar.target += as.spinStep }
        }
    }

    // Text with a role from the M3 type scale
    component T: Text {
        property string role: "bodyMedium"
        property bool emph: false
        readonly property var spec: mp.typeScale[role] || mp.typeScale.bodyMedium
        color: mp.cOnSurface
        font.family: role.indexOf("display") === 0 || role.indexOf("headline") === 0 || role.indexOf("title") === 0 ? mp.fontA : mp.fontB
        font.pixelSize: mp.px(spec[0])
        font.weight: mp.tw(role, emph)
        lineHeightMode: Text.FixedHeight
        lineHeight: mp.px(spec[1])
        wrapMode: Text.NoWrap
        elide: Text.ElideRight
    }

    component ScrollBarX: ScrollBar {
        id: sb
        policy: ScrollBar.AsNeeded
        minimumSize: 0.06
        contentItem: Rectangle {
            implicitWidth: 6
            implicitHeight: 6
            radius: 3
            color: mp.ga(mp.cOnSurfVar, sb.pressed ? 0.55 : (sb.hovered ? 0.42 : 0.26))
            opacity: sb.size < 1 && (sb.active || sb.hovered) ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 220 } }
        }
        background: Item {}
    }

    // Mouse wheel with smooth scrolling (same as in the file explorer)
    component WheelCatcher: MouseArea {
        id: wc
        property var flick: null
        property real goal: 0
        signal wheeled()
        anchors.fill: flick
        acceptedButtons: Qt.NoButton
        z: 50
        function maxY() { return Math.max(flick.originY, flick.originY + flick.contentHeight - flick.height); }
        onWheel: (w) => {
            if (!flick) return;
            wc.wheeled();
            var a = w.angleDelta.y, p = w.pixelDelta.y;
            if (a === 0 && p !== 0) {
                wcAnim.stop();
                flick.contentY = Math.max(flick.originY, Math.min(wc.maxY(), flick.contentY - p * 1.4));
                return;
            }
            var step = a / 120 * mp.wheelStep;
            var base = wcAnim.running ? wc.goal : flick.contentY;
            wc.goal = Math.max(flick.originY, Math.min(wc.maxY(), base - step));
            wcAnim.stop();
            wcAnim.from = flick.contentY;
            wcAnim.to = wc.goal;
            wcAnim.start();
        }
        NumberAnimation { id: wcAnim; target: wc.flick; property: "contentY"; duration: 220; easing.type: Easing.OutCubic }
    }

    // M3 Expressive icon button
    component IconBtn: Item {
        id: ib
        property string glyph: ""
        property string tip: ""
        property bool active: false
        property bool danger: false
        property string variant: "standard"    // standard · filled · tonal · outlined
        property real gsize: mp.px(24)
        property real radius: Math.min(width, height) / 2
        readonly property var cols: {
            if (variant === "filled") return [mp.cPrimary, mp.cOnPrimary, null];
            if (variant === "tonal" || active) return [mp.m3SecCont, mp.m3OnSecCont, null];
            if (variant === "outlined") return ["transparent", mp.cOnSurfVar, mp.m3OutlineVar];
            return ["transparent", (danger && ibMa.containsMouse) ? mp.cError : mp.cOnSurfVar, null];
        }
        property color glyphColor: cols[1]
        signal clicked()
        implicitWidth: mp.px(40)
        implicitHeight: mp.px(40)
        width: implicitWidth
        height: implicitHeight
        opacity: enabled ? 1 : 0.38
        Spring { id: ibP; token: "spatialFast"; eps: 0.002; target: ibMa.pressed ? 1 : 0 }
        Spring { id: ibA; token: "spatialFast"; eps: 0.002; target: ib.active ? 1 : 0 }
        Spring { id: ibS; token: "effectsFast"; target: ibMa.pressed ? 0.12 : (ibMa.containsMouse ? 0.08 : 0) }
        readonly property real sqR: height >= mp.px(52) ? mp.px(16) : mp.px(12)
        readonly property real prR: height >= mp.px(52) ? mp.px(12) : mp.px(8)
        readonly property real baseR: radius + (sqR - radius) * Math.max(0, Math.min(1, ibA.value))
        readonly property real rad: Math.max(0, Math.min(Math.min(width, height) / 2, baseR + (prR - baseR) * ibP.value))
        Rectangle {
            anchors.fill: parent
            radius: ib.rad
            color: ib.cols[0]
            border.width: ib.cols[2] ? 1 : 0
            border.color: ib.cols[2] ? ib.cols[2] : "transparent"
            Behavior on color { ColorAnimation { duration: 160 } }
        }
        Rectangle {
            anchors.fill: parent
            radius: ib.rad
            color: ib.danger && ib.variant === "standard" ? mp.cError : ib.glyphColor
            opacity: Math.max(0, ibS.value)
        }
        Glyph {
            anchors.centerIn: parent
            text: ib.glyph
            size: ib.gsize
            color: ib.glyphColor
            Behavior on color { ColorAnimation { duration: 160 } }
        }
        MouseArea {
            id: ibMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onContainsMouseChanged: { if (containsMouse && ib.tip !== "") mp.showTip(ib.tip, ib); else mp.hideTip(ib); }
            onClicked: { mp.hideTip(ib); ib.clicked(); }
        }
    }

    // M3 Expressive button (XS 32 · S 40 · M 56 · L 96)
    component PillBtn: Item {
        id: pb
        property string glyph: ""
        property string label: ""
        property bool primary: false
        property bool danger: false
        property bool square: false
        property string variant: primary ? "filled" : "tonal"   // filled · tonal · outlined · text · elevated
        signal clicked()
        implicitHeight: mp.px(40)
        readonly property real h: height
        readonly property real padX: h >= mp.px(90) ? mp.px(48) : h >= mp.px(52) ? mp.px(24) : h >= mp.px(38) ? mp.px(16) : mp.px(12)
        readonly property real gS: h >= mp.px(90) ? mp.px(32) : h >= mp.px(52) ? mp.px(24) : mp.px(20)
        readonly property real fS: h >= mp.px(90) ? mp.px(24) : h >= mp.px(52) ? mp.px(16) : mp.px(14)
        implicitWidth: pbRow.implicitWidth + padX * 2
        width: implicitWidth
        height: implicitHeight
        opacity: enabled ? 1 : 0.38
        readonly property real restR: square ? (h >= mp.px(52) ? mp.px(16) : mp.px(12)) : h / 2
        readonly property real pressR: h >= mp.px(52) ? mp.px(12) : mp.px(8)
        Spring { id: pbP; token: "spatialFast"; eps: 0.002; target: pbMa.pressed ? 1 : 0 }
        Spring { id: pbS; token: "effectsFast"; target: pbMa.pressed ? 0.12 : (pbMa.containsMouse ? 0.08 : 0) }
        readonly property real rad: Math.max(0, Math.min(h / 2, restR + (pressR - restR) * pbP.value))
        readonly property var cols: {
            switch (variant) {
            case "filled": return danger ? [mp.cError, mp.m3OnError, null] : [mp.cPrimary, mp.cOnPrimary, null];
            case "outlined": return ["transparent", danger ? mp.cError : mp.cOnSurfVar, mp.m3OutlineVar];
            case "text": return ["transparent", danger ? mp.cError : mp.cPrimary, null];
            case "elevated": return [mp.m3Low, danger ? mp.cError : mp.cPrimary, null];
            default: return danger ? [mp.m3ErrCont, mp.m3OnErrCont, null] : [mp.m3SecCont, mp.m3OnSecCont, null];
            }
        }
        Rectangle {
            visible: pb.variant === "elevated"
            y: 1.5; width: parent.width; height: parent.height; radius: pb.rad
            color: mp.ga("#000000", mp.light ? 0.2 : 0.5)
        }
        Rectangle {
            anchors.fill: parent
            radius: pb.rad
            color: pb.cols[0]
            border.width: pb.cols[2] ? 1 : 0
            border.color: pb.cols[2] ? pb.cols[2] : "transparent"
            Behavior on color { ColorAnimation { duration: 160 } }
        }
        Rectangle { anchors.fill: parent; radius: pb.rad; color: pb.cols[1]; opacity: Math.max(0, pbS.value) }
        Row {
            id: pbRow
            anchors.centerIn: parent
            spacing: pb.h >= mp.px(90) ? mp.px(12) : mp.px(8)
            Glyph {
                visible: pb.glyph !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: pb.glyph
                size: pb.gS
                color: pb.cols[1]
            }
            T {
                visible: pb.label !== ""
                anchors.verticalCenter: parent.verticalCenter
                role: "labelLarge"
                text: pb.label
                font.pixelSize: pb.fS
                lineHeight: pb.fS * 1.3
                elide: Text.ElideNone
                color: pb.cols[1]
            }
        }
        MouseArea { id: pbMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pb.clicked() }
    }

    // Connected button group (single selection): the selected one becomes a full pill
    component Seg: Item {
        id: seg
        property var options: []
        property var current
        property real segHeight: mp.px(40)
        property real cellW: 0
        property real gap: mp.px(2)
        signal picked(var value)
        readonly property int _n: options ? options.length : 0
        implicitWidth: cellW > 0 ? _n * cellW + (_n - 1) * gap : _n * mp.px(104) + (_n - 1) * gap
        implicitHeight: segHeight
        width: implicitWidth
        height: implicitHeight
        opacity: enabled ? 1 : 0.38
        Repeater {
            model: seg._n
            delegate: Item {
                id: sc
                required property int index
                readonly property var opt: seg.options[index] || ({})
                readonly property bool sel: seg.current === opt.value
                readonly property bool first: index === 0
                readonly property bool last: index === seg._n - 1
                readonly property real cw: (seg.width - seg.gap * (seg._n - 1)) / Math.max(1, seg._n)
                x: index * (cw + seg.gap)
                width: cw
                height: seg.segHeight
                Spring { id: scSel; token: "spatialFast"; eps: 0.002; target: sc.sel ? 1 : 0 }
                Spring { id: scP; token: "spatialFast"; eps: 0.002; target: scMa.pressed ? 1 : 0 }
                Spring { id: scS; token: "effectsFast"; target: scMa.pressed ? 0.12 : (scMa.containsMouse ? 0.08 : 0) }
                readonly property real outer: height / 2
                readonly property real inner: seg.segHeight <= mp.px(32) ? mp.px(4) : mp.px(8)
                readonly property real f: Math.max(0, Math.min(1, scSel.value))
                readonly property real rL: Math.max(0, ((first ? outer : inner) + (outer - (first ? outer : inner)) * f) * (1 - 0.35 * scP.value))
                readonly property real rR: Math.max(0, ((last ? outer : inner) + (outer - (last ? outer : inner)) * f) * (1 - 0.35 * scP.value))
                readonly property color fg: sc.sel ? mp.cOnPrimary : mp.cOnSurfVar
                Rectangle {
                    anchors.fill: parent
                    topLeftRadius: sc.rL; bottomLeftRadius: sc.rL
                    topRightRadius: sc.rR; bottomRightRadius: sc.rR
                    color: sc.sel ? mp.cPrimary : mp.m3High
                    Behavior on color { ColorAnimation { duration: 160 } }
                }
                Rectangle {
                    anchors.fill: parent
                    topLeftRadius: sc.rL; bottomLeftRadius: sc.rL
                    topRightRadius: sc.rR; bottomRightRadius: sc.rR
                    color: sc.fg
                    opacity: Math.max(0, scS.value)
                }
                Row {
                    anchors.centerIn: parent
                    spacing: mp.px(6)
                    Glyph {
                        id: scIco
                        visible: (sc.opt.icon || "") !== ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: sc.opt.icon || ""
                        size: seg.segHeight <= mp.px(32) ? mp.px(18) : mp.px(20)
                        color: sc.fg
                    }
                    T {
                        visible: (sc.opt.label || "") !== ""
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, sc.width - mp.px(16) - (scIco.visible ? scIco.width + mp.px(6) : 0))
                        role: "labelLarge"
                        emph: sc.sel
                        text: sc.opt.label || ""
                        color: sc.fg
                    }
                }
                MouseArea {
                    id: scMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onContainsMouseChanged: { if (containsMouse && sc.opt.tip) mp.showTip(sc.opt.tip, sc); else mp.hideTip(sc); }
                    onClicked: if (!sc.sel) seg.picked(sc.opt.value)
                }
            }
        }
    }

    // Pill-shaped text field (M3 search bar)
    component Field: Rectangle {
        id: fld
        property alias text: fin.text
        property alias input: fin
        property string placeholder: ""
        property string glyph: ""
        default property alias extra: fldRight.data
        signal accepted()
        signal escaped()
        signal edited(string t)
        implicitHeight: mp.px(48)
        radius: height / 2
        color: mp.m3Highest
        border.width: fin.activeFocus ? 2 : 0
        border.color: mp.cPrimary
        Spring { id: fldS; token: "effectsFast"; target: fldMa.containsMouse && !fin.activeFocus ? 0.08 : 0 }
        Rectangle { anchors.fill: parent; radius: parent.radius; color: mp.cOnSurface; opacity: Math.max(0, fldS.value) }
        Glyph {
            id: fldIco
            visible: fld.glyph !== ""
            anchors.left: parent.left
            anchors.leftMargin: mp.px(16)
            anchors.verticalCenter: parent.verticalCenter
            text: fld.glyph
            size: mp.px(22)
            color: fin.activeFocus ? mp.cPrimary : mp.cOnSurfVar
        }
        TextInput {
            id: fin
            anchors.left: fldIco.visible ? fldIco.right : parent.left
            anchors.leftMargin: fldIco.visible ? mp.px(12) : mp.px(20)
            anchors.right: fldRight.left
            anchors.rightMargin: mp.px(6)
            anchors.verticalCenter: parent.verticalCenter
            clip: true
            color: mp.cOnSurface
            font.family: mp.fontB
            font.pixelSize: mp.px(16)
            selectByMouse: true
            selectionColor: mp.ga(mp.cPrimary, 0.45)
            selectedTextColor: mp.cOnSurface
            onAccepted: fld.accepted()
            onTextEdited: fld.edited(text)
            Keys.onEscapePressed: (e) => { fld.escaped(); e.accepted = true; }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: fin.text === "" && fin.preeditText === ""
                text: fld.placeholder
                font: fin.font
                color: mp.cOnSurfVar
                elide: Text.ElideRight
                width: fin.width
            }
        }
        Row {
            id: fldRight
            anchors.right: parent.right
            anchors.rightMargin: mp.px(6)
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0
        }
        MouseArea { id: fldMa; anchors.fill: parent; z: -1; hoverEnabled: true; cursorShape: Qt.IBeamCursor; onClicked: fin.forceActiveFocus() }
    }

    // Tag editor field (M3 filled text field)
    component EdField: Rectangle {
        id: ef
        property string key: ""
        property string label: ""
        property bool numeric: false
        property bool touched: false
        property alias text: efIn.text
        Layout.minimumWidth: mp.px(120)
        Layout.preferredWidth: 10
        implicitHeight: mp.px(56)
        color: mp.m3Highest
        topLeftRadius: mp.px(4); topRightRadius: mp.px(4)
        Component.onCompleted: { mp.edFieldItems[key] = ef; load(); }
        function load() {
            var v = mp.edVals[ef.key];
            ef.touched = false;
            efIn.text = v === mp.mixedVal || v === undefined ? "" : v;
        }
        Connections { target: mp; function onEdRevChanged() { ef.load(); } }
        Spring { id: efS; token: "effectsFast"; target: efMa.containsMouse && !efIn.activeFocus ? 0.08 : 0 }
        Rectangle { anchors.fill: parent; topLeftRadius: parent.topLeftRadius; topRightRadius: parent.topRightRadius; color: mp.cOnSurface; opacity: Math.max(0, efS.value) }
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: efIn.activeFocus ? 2 : 1
            color: efIn.activeFocus ? mp.cPrimary : mp.cOnSurfVar
        }
        T {
            x: mp.px(16); y: mp.px(7)
            width: parent.width - mp.px(32)
            role: "bodySmall"
            text: ef.label
            color: efIn.activeFocus ? mp.cPrimary : mp.cOnSurfVar
        }
        MouseArea { id: efMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.IBeamCursor; onClicked: efIn.forceActiveFocus() }
        TextInput {
            id: efIn
            x: mp.px(16); y: mp.px(26)
            width: parent.width - mp.px(16) - (efClr.visible ? mp.px(40) : mp.px(16))
            clip: true
            color: mp.cOnSurface
            font.family: mp.fontB
            font.pixelSize: mp.px(16)
            selectByMouse: true
            selectionColor: mp.ga(mp.cPrimary, 0.45)
            selectedTextColor: mp.cOnSurface
            validator: ef.numeric ? numRx : null
            onTextEdited: ef.touched = true
            onAccepted: mp.edSave()
            Keys.onEscapePressed: (e) => { mp.edOpen = false; e.accepted = true; }
            Text {
                visible: efIn.text === "" && mp.edVals[ef.key] === mp.mixedVal && !ef.touched
                text: mp.tx("Varios valores (no se cambian)", "Multiple values (kept)")
                font: efIn.font
                color: mp.cOnSurfVar
                elide: Text.ElideRight
                width: efIn.width
            }
        }
        IconBtn {
            id: efClr
            anchors.right: parent.right; anchors.rightMargin: mp.px(4)
            anchors.verticalCenter: parent.verticalCenter
            visible: efIn.text !== "" && efIn.activeFocus
            implicitWidth: mp.px(32); implicitHeight: mp.px(32); gsize: mp.px(18)
            glyph: "close"
            onClicked: { efIn.text = ""; ef.touched = true; }
        }
    }
    RegularExpressionValidator { id: numRx; regularExpression: /^[0-9]{0,4}$/ }

    // M3 Expressive switch: the handle grows when on and even more when pressed
    component Toggle: Item {
        id: tg
        property bool checked: false
        property bool icons: true
        signal toggled()
        implicitWidth: mp.px(52)
        implicitHeight: mp.px(32)
        width: implicitWidth
        height: implicitHeight
        Spring { id: tgPos; token: "spatialFast"; eps: 0.002; target: tg.checked ? 1 : 0 }
        Spring { id: tgH; token: "spatialFast"; eps: 0.05; target: tgMa.pressed ? 28 : ((tg.checked || tg.icons) ? 24 : 16) }
        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: tg.checked ? mp.cPrimary : mp.m3Highest
            border.width: 2
            border.color: tg.checked ? mp.cPrimary : mp.m3Outline
            Behavior on color { ColorAnimation { duration: 140 } }
        }
        Rectangle {
            readonly property real d: mp.px(tgH.value)
            width: d; height: d; radius: d / 2
            x: mp.px(16) + tgPos.value * mp.px(20) - d / 2
            y: (tg.height - d) / 2
            color: tg.checked ? mp.cOnPrimary : (tgMa.pressed ? mp.cOnSurfVar : mp.m3Outline)
            Glyph {
                anchors.centerIn: parent
                visible: tg.icons
                text: tg.checked ? "check" : "close"
                size: mp.px(16)
                color: tg.checked ? mp.cPrimary : mp.m3Highest
            }
        }
        MouseArea { id: tgMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: tg.toggled() }
    }

    // FAB (and extended FAB that collapses with a spring)
    component EFab: Item {
        id: fab
        property string glyph: "add"
        property string text: ""
        property bool extended: text !== ""
        property string tone: "primary"        // primary · secondary · tertiary
        property string tip: ""
        signal clicked()
        readonly property var cols: tone === "secondary" ? [mp.m3SecCont, mp.m3OnSecCont]
                                  : tone === "tertiary" ? [mp.m3TerCont, mp.m3OnTerCont]
                                  : [mp.cPrimCont, mp.m3OnPrimCont]
        Spring { id: fabR; token: "spatialFast"; eps: 0.002; target: fabMa.pressed ? 1 : 0 }
        Spring { id: fabE; token: "spatialDefault"; eps: 0.002; target: fab.extended ? 1 : 0 }
        Spring { id: fabS; token: "effectsFast"; target: fabMa.pressed ? 0.12 : (fabMa.containsMouse ? 0.08 : 0) }
        readonly property real ev: Math.max(0, fabE.value)
        readonly property real rad: mp.px(16) - mp.px(4) * fabR.value
        implicitHeight: mp.px(56)
        implicitWidth: fabRow.implicitWidth + 2 * (mp.px(16) * (1 - Math.min(1, ev)) + mp.px(20) * ev)
        width: implicitWidth
        height: implicitHeight
        Rectangle { y: 3; width: parent.width; height: parent.height; radius: fab.rad; color: mp.ga("#000000", mp.light ? 0.18 : 0.45) }
        Rectangle { anchors.fill: parent; radius: fab.rad; color: fab.cols[0]; Behavior on color { ColorAnimation { duration: 160 } } }
        Rectangle { anchors.fill: parent; radius: fab.rad; color: fab.cols[1]; opacity: Math.max(0, fabS.value) }
        Row {
            id: fabRow
            anchors.centerIn: parent
            spacing: mp.px(12) * fab.ev
            Glyph { text: fab.glyph; size: mp.px(24); color: fab.cols[1]; anchors.verticalCenter: parent.verticalCenter }
            Item {
                width: fabLbl.implicitWidth * fab.ev; height: fabLbl.implicitHeight; clip: true
                anchors.verticalCenter: parent.verticalCenter
                T { id: fabLbl; text: fab.text; role: "titleMedium"; color: fab.cols[1]; opacity: fab.ev; elide: Text.ElideNone }
            }
        }
        MouseArea {
            id: fabMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onContainsMouseChanged: { if (containsMouse && fab.tip !== "" && !fab.extended) mp.showTip(fab.tip, fab); else mp.hideTip(fab); }
            onClicked: { mp.hideTip(fab); fab.clicked(); }
        }
    }

    // Navigation rail item with spring pill indicator
    component NavItem: Item {
        id: nv
        property string glyph: ""
        property string label: ""
        property int count: 0
        property bool active: false
        property bool compact: false
        signal clicked()
        readonly property real e: mp.railE
        height: mp.px(66) - mp.px(10) * e
        Spring { id: nvInd; token: "spatialFast"; eps: 0.002; target: nv.active ? 1 : 0 }
        Spring { id: nvH; token: "effectsFast"; target: nvMa.containsMouse ? 1 : 0 }
        // collapsed: icon in a 56×32 pill + label below
        Item {
            anchors.fill: parent
            opacity: 1 - nv.e
            visible: opacity > 0.01
            Rectangle { x: (parent.width - mp.px(56)) / 2; y: mp.px(4); width: mp.px(56); height: mp.px(32); radius: mp.px(16); color: mp.cOnSurface; opacity: 0.08 * nvH.value }
            Rectangle {
                width: mp.px(56) * Math.max(0, nvInd.value); height: mp.px(32); radius: mp.px(16)
                x: (parent.width - width) / 2; y: mp.px(4)
                color: mp.m3SecCont
                visible: nvInd.value > 0.01
            }
            Glyph { x: (parent.width - width) / 2; y: mp.px(8); width: mp.px(24); height: mp.px(24); text: nv.glyph; size: mp.px(24); color: nv.active ? mp.m3OnSecCont : mp.cOnSurfVar }
            T {
                anchors.horizontalCenter: parent.horizontalCenter
                y: mp.px(40)
                width: Math.min(implicitWidth, parent.width - mp.px(4))
                horizontalAlignment: Text.AlignHCenter
                role: "labelMedium"
                emph: nv.active
                text: nv.label
                color: nv.active ? mp.cOnSurface : mp.cOnSurfVar
            }
        }
        // expanded: 56 px pill across the full width
        Item {
            anchors.fill: parent
            opacity: nv.e
            visible: opacity > 0.01
            Rectangle { y: (parent.height - mp.px(56)) / 2; width: parent.width; height: mp.px(56); radius: mp.px(28); color: mp.cOnSurface; opacity: 0.08 * nvH.value }
            Rectangle {
                y: (parent.height - mp.px(56)) / 2
                width: parent.width * Math.max(0, nvInd.value); height: mp.px(56); radius: mp.px(28)
                color: mp.m3SecCont
                visible: nvInd.value > 0.01
            }
            Glyph { id: nvIco; x: mp.px(16); anchors.verticalCenter: parent.verticalCenter; text: nv.glyph; size: mp.px(24); color: nv.active ? mp.m3OnSecCont : mp.cOnSurfVar }
            T {
                anchors.left: nvIco.right; anchors.leftMargin: mp.px(12)
                anchors.right: nvCount.left; anchors.rightMargin: mp.px(6)
                anchors.verticalCenter: parent.verticalCenter
                role: "labelLarge"
                emph: nv.active
                text: nv.label
                color: nv.active ? mp.m3OnSecCont : mp.cOnSurfVar
            }
            T {
                id: nvCount
                anchors.right: parent.right; anchors.rightMargin: mp.px(16)
                anchors.verticalCenter: parent.verticalCenter
                role: "labelMedium"
                text: nv.count > 0 ? nv.count : ""
                color: nv.active ? mp.m3OnSecCont : mp.cOnSurfVar
            }
        }
        MouseArea { id: nvMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: nv.clicked() }
    }

    // Column header (sorts in the Songs view)
    component ColHead: Item {
        id: ch
        property string label: ""
        property string key: ""
        property bool alignRight: false
        readonly property bool sortable: mp.view === "songs"
        readonly property bool on: sortable && mp.sortKey === key
        height: parent ? parent.height : 0
        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: ch.alignRight ? parent.right : undefined
            anchors.rightMargin: ch.alignRight ? mp.px(8) : 0
            spacing: 2
            T {
                role: "labelMedium"
                emph: ch.on
                text: ch.label
                color: ch.on ? mp.cPrimary : (chHov.hovered && ch.sortable ? mp.cOnSurface : mp.cOnSurfVar)
            }
            Glyph { visible: ch.on; text: mp.sortAsc ? "arrow_upward" : "arrow_downward"; size: mp.px(14); color: mp.cPrimary }
        }
        HoverHandler { id: chHov; enabled: ch.sortable; cursorShape: Qt.PointingHandCursor }
        TapHandler {
            enabled: ch.sortable
            onTapped: { if (mp.sortKey === ch.key) mp.sortAsc = !mp.sortAsc; else { mp.sortKey = ch.key; mp.sortAsc = true; } }
        }
    }

    // Song row: segmented list item
    component SongRow: Item {
        id: sr
        required property var modelData
        required property int index
        property bool showCover: true
        property bool showAlbum: true
        readonly property bool isCur: mp.view === "queue" ? index === mp.qIndex : modelData.p === mp.curPath
        readonly property bool sel: mp.isSel(index)
        readonly property bool first: index === 0
        readonly property bool last: index === mp.curItems.length - 1
        height: mp.px(66)
        Spring { id: srSel; token: "spatialFast"; eps: 0.002; target: sr.sel || sr.isCur ? 1 : 0 }
        Spring { id: srHovS; token: "effectsFast"; target: srHov.hovered ? 1 : 0 }
        Rectangle {
            id: srBg
            x: mp.px(16)
            width: parent.width - mp.px(32)
            height: parent.height - mp.px(2)
            readonly property real r: mp.px(4) + mp.px(18) * Math.max(0, Math.min(1, srSel.value))
            topLeftRadius: sr.first ? Math.max(r, mp.px(24)) : r
            topRightRadius: sr.first ? Math.max(r, mp.px(24)) : r
            bottomLeftRadius: sr.last ? Math.max(r, mp.px(24)) : r
            bottomRightRadius: sr.last ? Math.max(r, mp.px(24)) : r
            color: sr.sel ? mp.m3SecCont : (sr.isCur ? mp.mixc(mp.m3Low, mp.cPrimary, 0.12) : mp.m3Low)
            Behavior on color { ColorAnimation { duration: 160 } }
            Rectangle {
                anchors.fill: parent
                topLeftRadius: parent.topLeftRadius; topRightRadius: parent.topRightRadius
                bottomLeftRadius: parent.bottomLeftRadius; bottomRightRadius: parent.bottomRightRadius
                color: mp.cOnSurface
                opacity: 0.08 * Math.max(0, srHovS.value)
            }

            Row {
                x: mp.px(12)
                width: parent.width - mp.px(16)
                height: parent.height
                // number / indicator
                Item {
                    width: mp.px(40)
                    height: parent.height
                    T {
                        anchors.centerIn: parent
                        visible: !srHov.hovered && !sr.isCur
                        role: "labelLarge"
                        text: mp.view === "album" ? (sr.modelData.n || "–") : sr.index + 1
                        color: mp.cOnSurfVar
                    }
                    EqBars { anchors.centerIn: parent; visible: sr.isCur && !srHov.hovered; live: mp.playing }
                    IconBtn {
                        anchors.centerIn: parent
                        visible: srHov.hovered
                        variant: "filled"
                        implicitWidth: mp.px(36); implicitHeight: mp.px(36); gsize: mp.px(22)
                        glyph: sr.isCur && mp.playing ? "pause" : "play_arrow"
                        onClicked: { if (sr.isCur) mp.togglePlay(); else mp.playFromView(sr.index); }
                    }
                }
                Item {
                    width: sr.showCover ? mp.px(60) : mp.px(4)
                    height: parent.height
                    Cover {
                        visible: sr.showCover
                        x: mp.px(4)
                        anchors.verticalCenter: parent.verticalCenter
                        width: mp.px(44); height: width; r: mp.px(12)
                        src: sr.modelData.art || ""
                    }
                }
                Column {
                    width: parent.width - mp.px(40) - (sr.showCover ? mp.px(60) : mp.px(4)) - (sr.showAlbum ? parent.width * 0.28 : 0) - mp.px(152)
                    anchors.verticalCenter: parent.verticalCenter
                    T {
                        width: parent.width
                        role: "bodyLarge"
                        emph: sr.isCur
                        text: sr.modelData.t
                        color: sr.sel ? mp.m3OnSecCont : (sr.isCur ? mp.cPrimary : mp.cOnSurface)
                    }
                    Row {
                        width: parent.width
                        spacing: mp.px(6)
                        Rectangle {
                            visible: !!sr.modelData.lyr
                            anchors.verticalCenter: parent.verticalCenter
                            width: mp.px(18); height: mp.px(16); radius: mp.px(5)
                            color: mp.ga(mp.cOnSurfVar, 0.16)
                            Glyph { anchors.centerIn: parent; text: "lyrics"; size: mp.px(12) }
                        }
                        T {
                            width: parent.width - (sr.modelData.lyr ? mp.px(24) : 0)
                            role: "bodyMedium"
                            text: mp.artistOf(sr.modelData) + (!sr.showAlbum && sr.modelData.al && mp.view !== "album" ? "  ·  " + sr.modelData.al : "")
                            color: mp.cOnSurfVar
                        }
                    }
                }
                T {
                    visible: sr.showAlbum
                    width: parent.width * 0.28
                    anchors.verticalCenter: parent.verticalCenter
                    rightPadding: mp.px(10)
                    role: "bodyMedium"
                    text: sr.modelData.al || ""
                    color: srAlHov.hovered ? mp.cPrimary : mp.cOnSurfVar
                    font.underline: srAlHov.hovered
                    HoverHandler { id: srAlHov; enabled: !!sr.modelData.al; cursorShape: Qt.PointingHandCursor }
                    TapHandler { enabled: !!sr.modelData.al; onTapped: mp.go("album", mp.albumKeyOf(sr.modelData)) }
                }
                Item {
                    width: mp.px(44)
                    height: parent.height
                    IconBtn {
                        anchors.centerIn: parent
                        gsize: mp.px(20)
                        readonly property bool liked: mp.isLiked(sr.modelData.p)
                        opacity: liked || srHov.hovered || sr.sel ? 1 : 0
                        glyph: "favorite"
                        glyphColor: liked ? mp.cTertiary : mp.cOnSurfVar
                        tip: liked ? mp.tx("Quitar de «Me gusta»", "Remove from Liked") : mp.tx("Me gusta", "Like")
                        onClicked: mp.likePaths([sr.modelData.p])
                    }
                }
                T {
                    width: mp.px(64)
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignRight
                    rightPadding: mp.px(8)
                    role: "labelLarge"
                    text: mp.fmtTime(sr.modelData.dur)
                    color: mp.cOnSurfVar
                }
                Item {
                    width: mp.px(44)
                    height: parent.height
                    IconBtn {
                        anchors.centerIn: parent
                        opacity: srHov.hovered || sr.sel ? 1 : 0
                        glyph: "more_vert"
                        tip: mp.tx("Más opciones", "More options")
                        onClicked: { var g = mapToItem(rootBg, 0, height); mp.songMenu(sr.index, g.x - mp.px(200), g.y); }
                    }
                }
            }
            HoverHandler { id: srHov }
            MouseArea {
                anchors.fill: parent
                z: -1
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: (m) => {
                    mp.refocus();
                    if (m.button === Qt.RightButton) { var g = mapToItem(rootBg, m.x, m.y); mp.songMenu(sr.index, g.x, g.y); }
                    else mp.clickSel(sr.index, m.modifiers);
                }
                onDoubleClicked: (m) => { if (m.button === Qt.LeftButton) mp.playFromView(sr.index); }
            }
        }
    }

    // Album / artist / playlist card
    component AlbumCard: Item {
        id: ac
        property string title: ""
        property string sub: ""
        property string art: ""
        property var arts: art ? [art] : []
        property string glyph: "album"
        property bool round: false
        property bool isNew: false
        property bool canPlay: true
        signal open()
        signal play()
        signal menu(real x, real y)
        Spring { id: acH; token: "spatialFast"; eps: 0.002; target: acMa.containsMouse || acPlayMa.containsMouse ? 1 : 0 }
        Spring { id: acP; token: "spatialFast"; eps: 0.0005; target: acMa.pressed ? 1 : 0 }
        Spring { id: acRot; token: "spatialDefault"; eps: 0.01; target: acMa.containsMouse || acPlayMa.containsMouse ? 15 : 0 }
        Item {
            id: acArt
            x: mp.px(8); y: mp.px(8)
            width: parent.width - mp.px(16)
            height: width
            scale: 1 - 0.035 * acP.value
            Mosaic {
                anchors.fill: parent
                visible: !ac.isNew
                r: mp.px(24) + mp.px(12) * Math.max(0, Math.min(1, acH.value))
                shape: ac.round ? "Cookie12Sided" : ""
                shapeRot: acRot.value
                arts: ac.arts
                glyph: ac.glyph
            }
            Rectangle {
                anchors.fill: parent
                visible: ac.isNew
                radius: mp.px(24) + mp.px(12) * Math.max(0, Math.min(1, acH.value))
                color: mp.mixc(mp.m3Low, mp.cPrimary, 0.06 + 0.06 * acH.value)
                border.width: 1
                border.color: mp.m3OutlineVar
                ShapeView {
                    anchors.centerIn: parent
                    width: parent.width * 0.42; height: width
                    from: "Cookie9Sided"; to: "Sunny"; t: Math.max(0, acH.value); rot: acRot.value * 2
                    fill: mp.m3TerCont
                    Glyph { anchors.centerIn: parent; text: "add"; size: parent.width * 0.5; color: mp.m3OnTerCont }
                }
            }
            // play button (shape that goes from circle to rounded square)
            Item {
                id: acPlay
                visible: !ac.isNew && ac.canPlay
                anchors.right: parent.right; anchors.bottom: parent.bottom
                anchors.margins: ac.round ? parent.width * 0.06 : mp.px(12)
                width: mp.px(52); height: width
                Spring { id: acPlayIn; token: "spatialFast"; eps: 0.002; target: acMa.containsMouse || acPlayMa.containsMouse ? 1 : 0 }
                Spring { id: acPlayR; token: "spatialFast"; eps: 0.002; target: acPlayMa.pressed ? 1 : (acPlayMa.containsMouse ? 0.6 : 0) }
                opacity: Math.max(0, Math.min(1, acPlayIn.value))
                scale: 0.6 + 0.4 * acPlayIn.value
                transformOrigin: Item.BottomRight
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2 - (width / 2 - mp.px(14)) * Math.max(0, Math.min(1.2, acPlayR.value))
                    color: mp.cPrimary
                    Glyph { anchors.centerIn: parent; text: "play_arrow"; size: mp.px(28); color: mp.cOnPrimary }
                }
                MouseArea { id: acPlayMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ac.play() }
            }
        }
        Column {
            anchors.top: acArt.bottom; anchors.topMargin: mp.px(10)
            x: mp.px(10)
            width: parent.width - mp.px(20)
            T {
                width: parent.width
                horizontalAlignment: ac.round ? Text.AlignHCenter : Text.AlignLeft
                role: "titleMedium"
                emph: true
                text: ac.title
                color: ac.isNew ? mp.cPrimary : mp.cOnSurface
            }
            T {
                width: parent.width
                horizontalAlignment: ac.round ? Text.AlignHCenter : Text.AlignLeft
                role: "bodyMedium"
                text: ac.sub
                color: mp.cOnSurfVar
            }
        }
        MouseArea {
            id: acMa
            anchors.fill: parent
            z: -1
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: (m) => {
                if (m.button === Qt.RightButton) { var g = mapToItem(rootBg, m.x, m.y); ac.menu(g.x, g.y); }
                else ac.open();
            }
            onDoubleClicked: (m) => { if (m.button === Qt.LeftButton && !ac.isNew && ac.canPlay) ac.play(); }
        }
    }

    // Large album / artist / playlist header
    component HeroBox: Item {
        id: hb
        property string kicker: ""
        property string title: ""
        property string linkText: ""
        property string desc: ""
        property string meta: ""
        property var arts: []
        property string glyph: "album"
        property bool round: false
        property bool showEdit: true
        property bool canPlay: true
        property string editTip: ""
        property string artTip: ""
        signal playClicked()
        signal shuffleClicked()
        signal editClicked()
        signal artClicked()
        signal linkClicked()
        signal moreClicked(real x, real y)
        width: parent ? parent.width : 0
        height: hbBox.height + mp.px(24)
        Rectangle {
            id: hbBox
            x: mp.px(16); y: mp.px(12)
            width: parent.width - mp.px(32)
            height: Math.max(hbArt.height, hbCol.height) + mp.px(48)
            radius: mp.px(32)
            color: mp.m3Low
            Mosaic {
                id: hbArt
                x: mp.px(24); y: mp.px(24)
                width: Math.min(mp.px(216), hb.width * 0.3)
                height: width
                r: mp.px(28)
                shape: hb.round ? "Cookie12Sided" : ""
                arts: hb.arts
                glyph: hb.glyph
                HoverHandler { id: hbArtHov; enabled: hb.artTip !== ""; cursorShape: Qt.PointingHandCursor }
                TapHandler { enabled: hb.artTip !== ""; onTapped: hb.artClicked() }
                Rectangle {
                    anchors.fill: parent
                    radius: parent.r
                    color: Qt.rgba(0, 0, 0, 0.45)
                    visible: hbArtHov.hovered
                    Column {
                        anchors.centerIn: parent
                        Glyph { anchors.horizontalCenter: parent.horizontalCenter; text: "add_photo_alternate"; size: mp.px(32); color: "white" }
                        T { role: "labelLarge"; text: hb.artTip; color: "white" }
                    }
                }
            }
            Column {
                id: hbCol
                anchors.left: hbArt.right; anchors.leftMargin: mp.px(28)
                anchors.right: parent.right; anchors.rightMargin: mp.px(24)
                anchors.bottom: hbArt.bottom
                spacing: mp.px(6)
                T {
                    role: "labelLarge"
                    emph: true
                    text: hb.kicker
                    color: mp.cPrimary
                    font.letterSpacing: 1.2
                }
                T {
                    width: parent.width
                    role: hb.title.length > 28 ? "headlineLarge" : "displaySmall"
                    emph: true
                    text: hb.title
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                }
                T {
                    visible: hb.linkText !== ""
                    role: "titleMedium"
                    text: hb.linkText
                    color: hbLinkHov.hovered ? mp.cPrimary : mp.cOnSurface
                    font.underline: hbLinkHov.hovered
                    HoverHandler { id: hbLinkHov; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: hb.linkClicked() }
                }
                T {
                    visible: hb.desc !== ""
                    width: parent.width
                    role: "bodyMedium"
                    text: hb.desc
                    wrapMode: Text.WordWrap
                    maximumLineCount: 3
                    color: mp.cOnSurfVar
                }
                T {
                    width: parent.width
                    role: "bodyMedium"
                    text: hb.meta
                    color: mp.cOnSurfVar
                }
                Item { width: 1; height: mp.px(8) }
                Row {
                    spacing: mp.px(8)
                    PillBtn { glyph: "play_arrow"; label: mp.tx("Reproducir", "Play"); primary: true; enabled: hb.canPlay; implicitHeight: mp.px(56); onClicked: hb.playClicked() }
                    PillBtn { glyph: "shuffle"; label: mp.tx("Aleatorio", "Shuffle"); enabled: hb.canPlay; implicitHeight: mp.px(56); onClicked: hb.shuffleClicked() }
                    IconBtn { visible: hb.showEdit; anchors.verticalCenter: parent.verticalCenter; variant: "tonal"; implicitWidth: mp.px(56); implicitHeight: mp.px(56); glyph: "edit"; tip: hb.editTip; onClicked: hb.editClicked() }
                    IconBtn {
                        anchors.verticalCenter: parent.verticalCenter
                        variant: "outlined"
                        implicitWidth: mp.px(56); implicitHeight: mp.px(56)
                        glyph: "more_horiz"
                        onClicked: { var g = mapToItem(rootBg, 0, height + 4); hb.moreClicked(g.x, g.y); }
                    }
                }
            }
        }
    }

    // Clipped cover image (or placeholder)
    component Cover: Item {
        id: cv
        property string src: ""
        property real r: 10
        property string shape: ""
        property real shapeRot: 0
        property string glyph: "music_note"
        property int res: 256
        property string url: ""
        Rectangle {
            anchors.fill: parent
            radius: cv.r
            color: mp.cPrimCont
            visible: cvImg.status !== Image.Ready && cv.shape === ""
            Glyph { anchors.centerIn: parent; text: cv.glyph; size: Math.max(12, cv.width * 0.42); color: mp.m3OnPrimCont }
        }
        ShapeView {
            anchors.fill: parent
            visible: cvImg.status !== Image.Ready && cv.shape !== ""
            from: cv.shape; to: cv.shape; rot: cv.shapeRot; inset: 1
            fill: mp.cPrimCont
            Glyph { anchors.centerIn: parent; text: cv.glyph; size: Math.max(12, cv.width * 0.42); color: mp.m3OnPrimCont }
        }
        Image {
            id: cvImg
            anchors.fill: parent
            source: cv.url ? cv.url : (cv.src ? mp.fileUrl(cv.src) : "")
            sourceSize: Qt.size(cv.res, cv.res)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            visible: false
        }
        MultiEffect {
            anchors.fill: parent
            source: cvImg
            visible: cvImg.status === Image.Ready
            maskEnabled: true
            maskSource: cvMask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }
        Item {
            id: cvMask
            anchors.fill: parent
            visible: false
            layer.enabled: true
            layer.smooth: true
            Rectangle { visible: cv.shape === ""; anchors.fill: parent; radius: cv.r; color: "black"; antialiasing: true }
            ShapeView { visible: cv.shape !== ""; anchors.fill: parent; from: cv.shape; to: cv.shape; rot: cv.shapeRot; inset: 1; fill: "black" }
        }
    }

    // A cover or a 2×2 mosaic (playlist covers)
    component Mosaic: Item {
        id: mo
        property var arts: []
        property real r: 12
        property string shape: ""
        property real shapeRot: 0
        property string glyph: "queue_music"
        readonly property int n: arts ? arts.length : 0
        Cover {
            anchors.fill: parent
            visible: mo.n < 4
            r: mo.r
            shape: mo.shape
            shapeRot: mo.shapeRot
            src: mo.n ? mo.arts[0] : ""
            glyph: mo.glyph
            res: mo.width > 120 ? 512 : 256
        }
        Item {
            anchors.fill: parent
            visible: mo.n >= 4
            layer.enabled: visible
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: moMask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
            }
            Grid {
                anchors.fill: parent
                columns: 2
                Repeater {
                    model: mo.n >= 4 ? mo.arts.slice(0, 4) : []
                    delegate: Image {
                        required property var modelData
                        width: mo.width / 2; height: mo.height / 2
                        source: mp.fileUrl(modelData)
                        sourceSize: Qt.size(256, 256)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }
            }
        }
        Item {
            id: moMask
            anchors.fill: parent
            visible: false
            layer.enabled: true
            Rectangle { visible: mo.shape === ""; anchors.fill: parent; radius: mo.r; color: "black"; antialiasing: true }
            ShapeView { visible: mo.shape !== ""; anchors.fill: parent; from: mo.shape; to: mo.shape; rot: mo.shapeRot; inset: 1; fill: "black" }
        }
    }

    // Cover with rotating gear mask and progress ring
    component ArtGear: Item {
        id: ag
        property string artPath: ""
        property real pct: 0
        property bool running: false
        property real rotOffset: 0
        NumberAnimation {
            id: agRot
            target: ag; property: "rotOffset"
            from: 0; to: Math.PI * 2; duration: 20000
            loops: Animation.Infinite
        }
        Component.onCompleted: if (running) agRot.start()
        onRunningChanged: {
            if (running) { if (agRot.paused) agRot.resume(); else if (!agRot.running) agRot.start(); }
            else if (agRot.running) agRot.pause();
        }
        Rectangle {
            anchors.fill: parent
            color: mp.cPrimCont
            visible: agImg.status !== Image.Ready
            layer.enabled: true
            layer.smooth: true
            layer.effect: MultiEffect { maskEnabled: true; maskSource: agMask; maskThresholdMin: 0.5; maskSpreadAtMin: 0.05 }
        }
        Glyph {
            anchors.centerIn: parent
            visible: agImg.status !== Image.Ready
            text: "music_note"
            size: Math.round(ag.width * 0.32)
            color: mp.cPrimary
        }
        Image {
            id: agImg
            anchors.fill: parent
            sourceSize: Qt.size(640, 640)
            fillMode: Image.PreserveAspectCrop
            source: ag.artPath ? mp.fileUrl(ag.artPath) : ""
            asynchronous: true
            layer.enabled: true
            layer.smooth: true
            layer.effect: MultiEffect { maskEnabled: true; maskSource: agMask; maskThresholdMin: 0.5; maskSpreadAtMin: 0.05 }
        }
        Item {
            id: agMask
            anchors.fill: parent
            clip: true
            visible: false
            layer.enabled: true
            Canvas {
                width: ag.width * 1.5
                height: ag.height * 1.5
                anchors.centerIn: parent
                rotation: -ag.rotOffset * 180 / Math.PI
                onWidthChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    var cx = width / 2, cy = height / 2;
                    var gearR = ag.width * 0.38;
                    var teeth = 12, rBase = gearR * 0.88, amp = gearR * 0.10;
                    var asymAmp = gearR * 0.05;
                    var cxAdj = cx - asymAmp / 2;
                    var steps = 720;
                    ctx.beginPath();
                    for (var i = 0; i <= steps; i++) {
                        var a = (i / steps) * Math.PI * 2;
                        var c = Math.cos(teeth / 2 * a);
                        var r = rBase + amp * c * c + asymAmp * Math.cos(a);
                        var x = cxAdj + Math.cos(a) * r, y = cy + Math.sin(a) * r;
                        if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
                    }
                    ctx.closePath();
                    ctx.fillStyle = "#FFFFFF";
                    ctx.fill();
                }
                Component.onCompleted: requestPaint()
            }
        }
        Canvas {
            id: agRing
            anchors.fill: parent
            property real pct: ag.pct
            Behavior on pct { NumberAnimation { duration: 400; easing.type: Easing.Linear } }
            property real rotOffset: ag.rotOffset
            property color ringColor: mp.cPrimary
            property color trackColor: mp.ga(Qt.darker(mp.cPrimary, 2.2), mp.glass ? 0.5 : 1)
            onTrackColorChanged: requestPaint()
            onPctChanged: requestPaint()
            onRotOffsetChanged: requestPaint()
            onRingColorChanged: requestPaint()
            onWidthChanged: requestPaint()
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                var k = Math.min(width, height) / 248;
                var cx = width / 2, cy = height / 2;
                var gearR = Math.min(width, height) * 0.42;
                var teeth = 12, rBase = gearR * 0.88, amp = gearR * 0.10;
                var asymAmp = gearR * 0.05;
                var steps = 720;
                var ringOffset = 14 * k;
                var lw = Math.max(3, 7 * k);
                var gapAngle = (pct > 0 && pct < 1) ? Math.min(0.45, 10 / Math.max(1, rBase)) : 0;
                var fillStartAngle = -Math.PI / 2;
                var fillEndAngle = fillStartAngle + Math.PI * 2 * Math.min(1, pct);
                var bgStart = pct > 0 ? fillEndAngle + gapAngle : fillStartAngle;
                var bgSweep = pct > 0 ? (Math.PI * 2 - Math.PI * 2 * Math.min(1, pct)) - gapAngle * 2 : Math.PI * 2;
                if (bgSweep > 0.001) {
                    var bgSteps = Math.max(2, Math.round(steps * (bgSweep / (Math.PI * 2))));
                    var rBg = rBase + ringOffset;
                    ctx.beginPath();
                    for (var i = 0; i <= bgSteps; i++) {
                        var aB = bgStart + (i / bgSteps) * bgSweep;
                        var xB = cx + Math.cos(aB) * rBg, yB = cy + Math.sin(aB) * rBg;
                        if (i === 0) ctx.moveTo(xB, yB); else ctx.lineTo(xB, yB);
                    }
                    ctx.strokeStyle = trackColor.toString();
                    ctx.lineWidth = lw;
                    ctx.lineCap = "round";
                    ctx.stroke();
                }
                if (pct <= 0) return;
                var upTo = Math.round(steps * Math.min(1, pct));
                ctx.beginPath();
                for (var j = 0; j <= upTo; j++) {
                    var aPos = (j / steps) * Math.PI * 2 - Math.PI / 2;
                    var aTooth = aPos + rotOffset;
                    var c2 = Math.cos(teeth / 2 * aTooth);
                    var r2 = rBase + amp * c2 * c2 + asymAmp * Math.cos(aTooth) + ringOffset;
                    var x2 = cx + Math.cos(aPos) * r2, y2 = cy + Math.sin(aPos) * r2;
                    if (j === 0) ctx.moveTo(x2, y2); else ctx.lineTo(x2, y2);
                }
                ctx.strokeStyle = ringColor.toString();
                ctx.lineWidth = lw;
                ctx.lineCap = "round";
                ctx.stroke();
            }
            Component.onCompleted: requestPaint()
        }
    }

    // M3 Expressive wavy progress with a slider handle
    component WaveBar: Item {
        id: wb
        property bool compact: false
        property real dragPct: -1
        readonly property real shownPct: dragPct >= 0 ? dragPct : mp.pct
        Spring { id: wbAmp; token: "effectsDefault"; target: mp.playing && wb.shownPct > 0.02 && wb.shownPct < 0.98 ? 1 : 0 }
        Spring { id: wbHw; token: "spatialFast"; eps: 0.02; target: wbMa.pressed ? 2 : 4 }
        Spring { id: wbHh; token: "spatialFast"; eps: 0.002; target: wbMa.containsMouse || wbMa.pressed ? 1 : 0 }
        Canvas {
            id: wbCanvas
            anchors.fill: parent
            property real pct: wb.shownPct
            property real phase: mp.wavePhase
            property real amp: wbAmp.value
            property real hw: wbHw.value
            property real hh: wbHh.value
            property color active: mp.cPrimary
            property color track: mp.m3SecCont
            onPctChanged: requestPaint()
            onPhaseChanged: requestPaint()
            onAmpChanged: requestPaint()
            onHwChanged: requestPaint()
            onHhChanged: requestPaint()
            onActiveChanged: requestPaint()
            onTrackChanged: requestPaint()
            onWidthChanged: requestPaint()
            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                var th = mp.px(wb.compact ? 4 : 6);
                var A = mp.px(wb.compact ? 3 : 4) * amp;
                var wl = mp.px(wb.compact ? 40 : 48);
                var cy = height / 2;
                var x0 = th / 2, x1 = width - th / 2, W = x1 - x0;
                var p = Math.max(0, Math.min(1, pct));
                var hx = x0 + W * p;
                var hwPx = mp.px(hw);
                var gap = mp.px(5);
                ctx.lineCap = "round";
                ctx.lineWidth = th;
                // active wave
                var a = x0, b = hx - hwPx / 2 - gap;
                if (b - a > 0.5) {
                    ctx.strokeStyle = mp.css(active);
                    ctx.beginPath();
                    for (var x = a; x <= b; x += 1.5) {
                        var yy = cy + A * Math.sin(2 * Math.PI * x / wl - phase);
                        if (x === a) ctx.moveTo(x, yy); else ctx.lineTo(x, yy);
                    }
                    ctx.lineTo(b, cy + A * Math.sin(2 * Math.PI * b / wl - phase));
                    ctx.stroke();
                }
                // flat track
                var c = hx + hwPx / 2 + gap;
                if (x1 - c > 0.5) {
                    ctx.strokeStyle = mp.css(track);
                    ctx.beginPath(); ctx.moveTo(c, cy); ctx.lineTo(x1, cy); ctx.stroke();
                }
                // end indicator (stop)
                if (p < 0.98) {
                    ctx.fillStyle = mp.css(active);
                    ctx.beginPath(); ctx.arc(x1, cy, th / 2 * 0.75, 0, 2 * Math.PI); ctx.fill();
                }
                // vertical handle (gets thinner while dragging)
                var hH = mp.px(wb.compact ? 18 : 28) + mp.px(6) * hh;
                var R = hwPx / 2;
                ctx.fillStyle = mp.css(active);
                ctx.beginPath();
                ctx.moveTo(hx - R, cy - hH / 2 + R);
                ctx.arc(hx, cy - hH / 2 + R, R, Math.PI, 0, false);
                ctx.lineTo(hx + R, cy + hH / 2 - R);
                ctx.arc(hx, cy + hH / 2 - R, R, 0, Math.PI, false);
                ctx.closePath();
                ctx.fill();
            }
        }
        Rectangle {
            visible: wbMa.containsMouse && mp.durSec > 0
            x: Math.max(0, Math.min(wb.width - width, wbMa.mouseX - width / 2))
            y: -height - mp.px(6)
            width: wbTip.implicitWidth + mp.px(20); height: mp.px(32)
            radius: height / 2
            color: mp.m3InvSurf
            T {
                id: wbTip
                anchors.centerIn: parent
                role: "labelLarge"
                text: mp.fmtTime(Math.max(0, Math.min(1, (wbMa.mouseX - 4) / Math.max(1, wb.width - 8))) * mp.durSec)
                color: mp.m3InvOnSurf
            }
        }
        MouseArea {
            id: wbMa
            anchors.fill: parent
            anchors.topMargin: -4
            anchors.bottomMargin: -4
            hoverEnabled: true
            enabled: mp.qIndex >= 0
            cursorShape: Qt.PointingHandCursor
            preventStealing: true
            function at(mx) { return Math.max(0, Math.min(1, (mx - 4) / Math.max(1, wb.width - 8))); }
            onPressed: (m) => { mp.seekDragging = true; wb.dragPct = at(m.x); }
            onPositionChanged: (m) => { if (pressed) wb.dragPct = at(m.x); }
            onReleased: (m) => {
                var p = at(m.x);
                mp.seekDragging = false;
                wb.dragPct = -1;
                mp.seekTo(p * mp.durSec);
            }
            onCanceled: { mp.seekDragging = false; wb.dragPct = -1; }
            onWheel: (w) => { mp.seekBy(w.angleDelta.y > 0 ? 5 : -5); }
        }
    }

    // Play/pause button that morphs circle ⇄ rounded square
    component PlayMorph: Item {
        id: pm
        property real h: mp.px(56)
        signal clicked()
        Spring { id: pmW; token: "spatialFast"; eps: 0.002; target: mp.playing ? 1 : 0 }
        Spring { id: pmP; token: "spatialFast"; eps: 0.002; target: pmMa.pressed ? 1 : 0 }
        Spring { id: pmS; token: "effectsFast"; target: pmMa.pressed ? 0.12 : (pmMa.containsMouse ? 0.08 : 0) }
        implicitWidth: pm.h * (1 + 0.35 * pmW.value)
        implicitHeight: pm.h
        width: implicitWidth
        height: implicitHeight
        readonly property real rad: {
            var base = pm.h / 2 + (pm.h * 0.32 - pm.h / 2) * pmW.value;
            return Math.max(0, Math.min(pm.h / 2, base + (pm.h * 0.2 - base) * pmP.value));
        }
        Rectangle { anchors.fill: parent; radius: pm.rad; color: mp.cPrimary }
        Rectangle { anchors.fill: parent; radius: pm.rad; color: mp.cOnPrimary; opacity: Math.max(0, pmS.value) }
        Glyph {
            anchors.centerIn: parent
            text: mp.playing ? "pause" : "play_arrow"
            size: pm.h * 0.5
            color: mp.cOnPrimary
        }
        MouseArea { id: pmMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pm.clicked() }
    }

    // Controls: shuffle · previous · play · next · repeat
    component Controls: Row {
        id: ctl
        property bool big: false
        property bool extras: true
        spacing: big ? mp.px(10) : mp.px(8)
        readonly property real bs: big ? mp.px(56) : mp.px(40)
        IconBtn {
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: ctl.bs; implicitHeight: ctl.bs; gsize: mp.px(22)
            visible: ctl.extras
            glyph: "shuffle"
            active: mp.shuffle
            tip: mp.tx("Aleatorio (Ctrl+S)", "Shuffle (Ctrl+S)")
            onClicked: mp.toggleShuffle()
        }
        IconBtn {
            anchors.verticalCenter: parent.verticalCenter
            variant: "tonal"
            implicitWidth: ctl.bs; implicitHeight: ctl.bs; gsize: ctl.big ? mp.px(28) : mp.px(24)
            glyph: "skip_previous"
            enabled: mp.canPrev
            tip: mp.tx("Anterior (Ctrl+←)", "Previous (Ctrl+←)")
            onClicked: mp.prev()
        }
        PlayMorph {
            anchors.verticalCenter: parent.verticalCenter
            h: ctl.big ? mp.px(72) : mp.px(56)
            onClicked: mp.togglePlay()
        }
        IconBtn {
            anchors.verticalCenter: parent.verticalCenter
            variant: "tonal"
            implicitWidth: ctl.bs; implicitHeight: ctl.bs; gsize: ctl.big ? mp.px(28) : mp.px(24)
            glyph: "skip_next"
            enabled: mp.canNext
            tip: mp.tx("Siguiente (Ctrl+→)", "Next (Ctrl+→)")
            onClicked: mp.next(false)
        }
        IconBtn {
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: ctl.bs; implicitHeight: ctl.bs; gsize: mp.px(22)
            visible: ctl.extras
            glyph: mp.repeatMode === "one" ? "repeat_one" : "repeat"
            active: mp.repeatMode !== "off"
            tip: mp.repeatMode === "off" ? mp.tx("Repetir: no (Ctrl+R)", "Repeat: off (Ctrl+R)")
               : mp.repeatMode === "all" ? mp.tx("Repetir: todo", "Repeat: all") : mp.tx("Repetir: una", "Repeat: one")
            onClicked: mp.cycleRepeat()
        }
    }

    // Volume: mute button + expressive slider
    component VolumeRow: Item {
        id: vr
        height: mp.px(44)
        IconBtn {
            id: vrBtn
            anchors.verticalCenter: parent.verticalCenter
            glyph: mp.muted || mp.volume === 0 ? "volume_off" : mp.volume < 0.4 ? "volume_down" : "volume_up"
            tip: mp.muted ? mp.tx("Activar sonido (M)", "Unmute (M)") : mp.tx("Silenciar (M)", "Mute (M)")
            onClicked: mp.muted = !mp.muted
        }
        Item {
            id: vrTrack
            anchors.left: vrBtn.right; anchors.leftMargin: mp.px(8)
            anchors.right: vrPct.left; anchors.rightMargin: mp.px(8)
            anchors.verticalCenter: parent.verticalCenter
            height: mp.px(44)
            readonly property real v: mp.muted ? 0 : mp.volume
            readonly property real trackH: mp.px(16)
            readonly property real gap: mp.px(5)
            readonly property real hx: 2 + v * (width - 4)
            Spring { id: vrHw; token: "spatialFast"; eps: 0.02; target: vrMa.pressed ? 2 : 4 }
            readonly property real hwPx: mp.px(vrHw.value)
            Rectangle {
                x: 0; y: (parent.height - vrTrack.trackH) / 2; height: vrTrack.trackH
                width: Math.max(0, vrTrack.hx - vrTrack.hwPx / 2 - vrTrack.gap)
                visible: width > 0.5
                color: mp.muted ? mp.m3Outline : mp.cPrimary
                topLeftRadius: height / 2; bottomLeftRadius: height / 2
                topRightRadius: Math.min(2, width / 2); bottomRightRadius: Math.min(2, width / 2)
            }
            Rectangle {
                x: vrTrack.hx + vrTrack.hwPx / 2 + vrTrack.gap; y: (parent.height - vrTrack.trackH) / 2; height: vrTrack.trackH
                width: Math.max(0, vrTrack.width - x)
                visible: width > 0.5
                color: mp.m3SecCont
                topRightRadius: height / 2; bottomRightRadius: height / 2
                topLeftRadius: Math.min(2, width / 2); bottomLeftRadius: Math.min(2, width / 2)
            }
            Rectangle {
                width: vrTrack.hwPx; height: mp.px(40); radius: width / 2
                x: vrTrack.hx - width / 2; y: (parent.height - height) / 2
                color: mp.muted ? mp.m3Outline : mp.cPrimary
            }
            MouseArea {
                id: vrMa
                anchors.fill: parent
                preventStealing: true
                cursorShape: Qt.PointingHandCursor
                function set(mx) { mp.setVolume((mx - 2) / Math.max(1, vrTrack.width - 4)); }
                onPressed: (m) => set(m.x)
                onPositionChanged: (m) => { if (pressed) set(m.x); }
                onWheel: (w) => mp.setVolume(mp.volume + (w.angleDelta.y > 0 ? 0.05 : -0.05))
            }
        }
        T {
            id: vrPct
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: mp.px(36)
            horizontalAlignment: Text.AlignRight
            role: "labelMedium"
            text: Math.round((mp.muted ? 0 : mp.volume) * 100) + "%"
            color: mp.cOnSurfVar
        }
    }

    // Filter chip: when selected the check appears and the corners round off
    component Chip: Item {
        id: chp
        property string label: ""
        property bool active: false
        signal clicked()
        implicitHeight: mp.px(32)
        implicitWidth: chpRow.implicitWidth + mp.px(32)
        width: implicitWidth
        height: implicitHeight
        Spring { id: chpSel; token: "spatialFast"; eps: 0.002; target: chp.active ? 1 : 0 }
        Spring { id: chpS; token: "effectsFast"; target: chpMa.pressed ? 0.12 : (chpMa.containsMouse ? 0.08 : 0) }
        readonly property real f: Math.max(0, Math.min(1, chpSel.value))
        Rectangle {
            anchors.fill: parent
            radius: mp.px(8) + mp.px(8) * chp.f
            color: chp.active ? mp.m3SecCont : "transparent"
            border.width: chp.active ? 0 : 1
            border.color: mp.m3OutlineVar
            Behavior on color { ColorAnimation { duration: 140 } }
        }
        Rectangle { anchors.fill: parent; radius: mp.px(8) + mp.px(8) * chp.f; color: mp.cOnSurface; opacity: Math.max(0, chpS.value) }
        Row {
            id: chpRow
            anchors.centerIn: parent
            spacing: mp.px(8) * chp.f
            Item {
                width: mp.px(18) * chp.f; height: mp.px(18); clip: true
                anchors.verticalCenter: parent.verticalCenter
                Glyph { text: "check"; size: mp.px(18); color: mp.m3OnSecCont }
            }
            T {
                anchors.verticalCenter: parent.verticalCenter
                role: "labelLarge"
                text: chp.label
                elide: Text.ElideNone
                color: chp.active ? mp.m3OnSecCont : mp.cOnSurfVar
            }
        }
        MouseArea { id: chpMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: chp.clicked() }
    }

    // Now-playing screen tabs: connected button group
    component TabStrip: Item {
        id: ts
        property var options: []
        property var current
        signal picked(var value)
        height: mp.px(68)
        Seg {
            x: mp.px(16); y: mp.px(16)
            width: ts.width - mp.px(32)
            segHeight: mp.px(40)
            options: ts.options
            current: ts.current
            onPicked: (v) => ts.picked(v)
        }
    }

    // Horizontal shelf with title and arrows (Home, Explore, search…)
    component Shelf: Column {
        id: sh
        property string title: ""
        property string sub: ""
        property alias model: shList.model
        property alias delegate: shList.delegate
        property real itemH: mp.cardH
        property real pad: mp.px(24)
        property bool showMore: false
        signal more()
        width: parent ? parent.width : 0
        visible: shList.count > 0
        function scrollBy(d) {
            shAnim.stop();
            shAnim.from = shList.contentX;
            shAnim.to = Math.max(0, Math.min(shList.contentWidth - shList.width, shList.contentX + d));
            shAnim.start();
        }
        Item {
            width: parent.width
            height: sh.sub !== "" ? mp.px(72) : mp.px(60)
            Column {
                anchors.left: parent.left; anchors.leftMargin: sh.pad
                anchors.right: shBtns.left; anchors.rightMargin: mp.px(12)
                anchors.verticalCenter: parent.verticalCenter
                spacing: mp.px(2)
                T {
                    visible: sh.sub !== ""
                    width: parent.width
                    role: "labelLarge"
                    emph: true
                    text: sh.sub
                    color: mp.cPrimary
                    font.letterSpacing: 1.1
                }
                T {
                    width: parent.width
                    role: "titleLarge"
                    emph: true
                    text: sh.title
                }
            }
            Row {
                id: shBtns
                anchors.right: parent.right; anchors.rightMargin: sh.pad - mp.px(4)
                anchors.verticalCenter: parent.verticalCenter
                spacing: mp.px(4)
                PillBtn { visible: sh.showMore; anchors.verticalCenter: parent.verticalCenter; variant: "text"; implicitHeight: mp.px(40); glyph: "arrow_forward"; label: mp.tx("Ver todo", "See all"); onClicked: sh.more() }
                IconBtn { anchors.verticalCenter: parent.verticalCenter; variant: "tonal"; glyph: "chevron_left"; enabled: shList.contentX > 1; onClicked: sh.scrollBy(-shList.width * 0.8) }
                IconBtn { anchors.verticalCenter: parent.verticalCenter; variant: "tonal"; glyph: "chevron_right"; enabled: shList.contentX < shList.contentWidth - shList.width - 1; onClicked: sh.scrollBy(shList.width * 0.8) }
            }
        }
        ListView {
            id: shList
            x: sh.pad - mp.px(8)
            width: parent.width - (sh.pad - mp.px(8)) * 2
            height: sh.itemH
            orientation: ListView.Horizontal
            clip: true
            spacing: 0
            boundsBehavior: Flickable.StopAtBounds
            NumberAnimation { id: shAnim; target: shList; property: "contentX"; duration: 260; easing.type: Easing.OutCubic }
        }
    }

    // Explore card (genres, decades, shortcuts): expressive shape that morphs on hover
    component Tile: Item {
        id: tl
        property string label: ""
        property string sub: ""
        property string glyph: ""
        property string shape: "Cookie9Sided"
        property color tint: mp.cPrimary
        signal clicked()
        height: mp.px(84)
        Spring { id: tlH; token: "spatialFast"; eps: 0.002; target: tlMa.containsMouse ? 1 : 0 }
        Spring { id: tlP; token: "spatialFast"; eps: 0.0005; target: tlMa.pressed ? 1 : 0 }
        Spring { id: tlRot; token: "spatialDefault"; eps: 0.01; target: tlMa.containsMouse ? 30 : 0 }
        scale: 1 - 0.025 * tlP.value
        Rectangle {
            anchors.fill: parent
            radius: mp.px(24) + mp.px(8) * Math.max(0, Math.min(1, tlH.value))
            color: mp.mixc(mp.m3Low, tl.tint, 0.16 + 0.06 * Math.max(0, tlH.value))
        }
        ShapeView {
            id: tlIc
            visible: tl.glyph !== ""
            x: mp.px(16)
            anchors.verticalCenter: parent.verticalCenter
            width: mp.px(52); height: width
            from: tl.shape; to: "Circle"; t: 0.35 * Math.max(0, tlH.value); rot: tlRot.value
            inset: 0.96
            fill: mp.mixc(mp.m3Low, tl.tint, 0.45)
            Glyph { anchors.centerIn: parent; text: tl.glyph; size: mp.px(24); color: mp.light ? mp.mixc(tl.tint, "#000000", 0.5) : mp.mixc(tl.tint, "#ffffff", 0.6) }
        }
        Column {
            anchors.left: tlIc.visible ? tlIc.right : parent.left
            anchors.leftMargin: tlIc.visible ? mp.px(14) : mp.px(20)
            anchors.right: parent.right; anchors.rightMargin: mp.px(12)
            anchors.verticalCenter: parent.verticalCenter
            T { width: parent.width; role: "titleMedium"; emph: true; text: tl.label }
            T { visible: tl.sub !== ""; width: parent.width; role: "bodyMedium"; text: tl.sub; color: mp.cOnSurfVar }
        }
        MouseArea { id: tlMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: tl.clicked() }
    }

    // Online result row
    component OnlineRow: Item {
        id: orow
        property var it: ({})
        property bool first: false
        property bool last: false
        height: mp.px(74)
        readonly property var st: { var _d = mp.dl; return _d[it.id] || ({}); }
        readonly property bool running: st.state === "run"
        readonly property bool done: st.state === "done"
        readonly property bool failed: st.state === "err"
        Spring { id: orHovS; token: "effectsFast"; target: orHov.hovered ? 1 : 0 }
        Rectangle {
            id: orBg
            x: mp.px(2)
            width: parent.width - mp.px(4)
            height: parent.height - mp.px(2)
            topLeftRadius: orow.first ? mp.px(24) : mp.px(4); topRightRadius: orow.first ? mp.px(24) : mp.px(4)
            bottomLeftRadius: orow.last ? mp.px(24) : mp.px(4); bottomRightRadius: orow.last ? mp.px(24) : mp.px(4)
            color: orow.done ? mp.mixc(mp.m3Low, mp.cPrimary, 0.1) : mp.m3Low
            Rectangle {
                anchors.fill: parent
                topLeftRadius: parent.topLeftRadius; topRightRadius: parent.topRightRadius
                bottomLeftRadius: parent.bottomLeftRadius; bottomRightRadius: parent.bottomRightRadius
                color: mp.cOnSurface
                opacity: 0.08 * Math.max(0, orHovS.value)
            }
        }
        Cover {
            id: orArt
            x: mp.px(14)
            anchors.verticalCenter: orBg.verticalCenter
            width: mp.px(48); height: width; r: mp.px(12)
            url: orow.it.cover || ""
        }
        Column {
            anchors.left: orArt.right; anchors.leftMargin: mp.px(14)
            anchors.right: orDur.left; anchors.rightMargin: mp.px(8)
            anchors.verticalCenter: orBg.verticalCenter
            T { width: parent.width; role: "bodyLarge"; text: orow.it.title || "" }
            T {
                width: parent.width
                role: "bodyMedium"
                color: orow.failed ? mp.cError : (orow.running ? mp.cPrimary : mp.cOnSurfVar)
                text: orow.failed ? orow.st.err : (orow.running ? (orow.st.line || "") : mp.artistsText(orow.it) + (orow.it.album ? "  ·  " + orow.it.album : "") + (orow.it.year ? "  ·  " + orow.it.year : ""))
            }
        }
        T {
            id: orDur
            anchors.right: orBtn.left; anchors.rightMargin: mp.px(12)
            anchors.verticalCenter: orBg.verticalCenter
            role: "labelLarge"
            text: orow.it.dur ? mp.fmtTime(orow.it.dur) : ""
            color: mp.cOnSurfVar
        }
        MorphLoader {
            anchors.centerIn: orBtn
            size: mp.px(48)
            visible: orow.running
            fillColor: mp.ga(mp.cPrimary, 0.35)
        }
        IconBtn {
            id: orBtn
            anchors.right: parent.right; anchors.rightMargin: mp.px(16)
            anchors.verticalCenter: orBg.verticalCenter
            variant: orow.done || orow.running ? "standard" : "tonal"
            implicitWidth: mp.px(48); implicitHeight: mp.px(48); gsize: mp.px(24)
            glyph: orow.running ? "close" : orow.done ? (orow.st.path ? "play_arrow" : "check") : orow.failed ? "refresh" : "download"
            active: orow.done
            tip: orow.running ? mp.tx("Cancelar", "Cancel") : orow.done ? (orow.st.path ? mp.tx("Reproducir", "Play") : mp.tx("En tu biblioteca", "In your library")) : orow.failed ? mp.tx("Reintentar", "Retry") : mp.tx("Descargar", "Download")
            onClicked: {
                if (orow.running) mp.onlineCancel(orow.it);
                else if (orow.done) { if (orow.st.path) mp.playPaths([orow.st.path], 0, orow.it.title); }
                else mp.onlineDownload(orow.it);
            }
        }
        HoverHandler { id: orHov }
        TapHandler { acceptedButtons: Qt.LeftButton; onDoubleTapped: if (!orow.running && !orow.done) mp.onlineDownload(orow.it) }
    }

    // Compact song row (quick picks, related): one click plays
    component MiniSong: Item {
        id: ms
        property var tr: null
        signal play()
        signal menu(real x, real y)
        height: mp.px(64)
        readonly property bool isCur: !!tr && tr.p === mp.curPath
        Spring { id: msHovS; token: "effectsFast"; target: msHov.hovered ? 1 : 0 }
        Spring { id: msSel; token: "spatialFast"; eps: 0.002; target: ms.isCur ? 1 : 0 }
        Rectangle {
            anchors.fill: parent; anchors.margins: 1
            radius: mp.px(12) + mp.px(12) * Math.max(0, Math.min(1, msSel.value))
            color: ms.isCur ? mp.m3SecCont : "transparent"
            Rectangle { anchors.fill: parent; radius: parent.radius; color: mp.cOnSurface; opacity: 0.08 * Math.max(0, msHovS.value) }
        }
        Cover {
            id: msArt
            x: mp.px(8)
            anchors.verticalCenter: parent.verticalCenter
            width: mp.px(48); height: width; r: mp.px(12)
            src: ms.tr ? (ms.tr.art || "") : ""
            Rectangle {
                anchors.fill: parent; radius: parent.r
                color: Qt.rgba(0, 0, 0, 0.5)
                visible: msHov.hovered || ms.isCur
                Glyph { anchors.centerIn: parent; text: ms.isCur && mp.playing ? "pause" : "play_arrow"; size: mp.px(26); color: "white" }
            }
        }
        Column {
            anchors.left: msArt.right; anchors.leftMargin: mp.px(14)
            anchors.right: msDur.left; anchors.rightMargin: mp.px(8)
            anchors.verticalCenter: parent.verticalCenter
            T { width: parent.width; role: "bodyLarge"; emph: ms.isCur; text: ms.tr ? ms.tr.t : ""; color: ms.isCur ? mp.m3OnSecCont : mp.cOnSurface }
            T { width: parent.width; role: "bodyMedium"; text: ms.tr ? mp.artistOf(ms.tr) + (ms.tr.al ? "  ·  " + ms.tr.al : "") : ""; color: mp.cOnSurfVar }
        }
        T {
            id: msDur
            anchors.right: parent.right; anchors.rightMargin: mp.px(16)
            anchors.verticalCenter: parent.verticalCenter
            role: "labelLarge"
            text: ms.tr ? mp.fmtTime(ms.tr.dur) : ""
            color: mp.cOnSurfVar
        }
        HoverHandler { id: msHov; cursorShape: Qt.PointingHandCursor }
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: (m) => {
                if (m.button === Qt.RightButton) { var g = mapToItem(rootBg, m.x, m.y); ms.menu(g.x, g.y); }
                else if (ms.isCur) mp.togglePlay();
                else ms.play();
            }
        }
    }

    // Animated "now playing" bars
    component EqBars: Row {
        id: eq
        property bool live: true
        spacing: 2
        Repeater {
            model: 3
            delegate: Rectangle {
                id: bar
                required property int index
                width: mp.px(3)
                radius: width / 2
                anchors.bottom: parent.bottom
                color: mp.cPrimary
                property real h: 0.35
                height: mp.px(14) * h
                SequentialAnimation on h {
                    running: eq.live && eq.visible
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.0; duration: 260 + bar.index * 90; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.3; duration: 300 + bar.index * 70; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.7; duration: 240 + bar.index * 60; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.35; duration: 280; easing.type: Easing.InOutSine }
                }
            }
        }
        height: mp.px(14)
    }

    // M3 Expressive loading indicator: cycles through 7 shapes while spinning
    component MorphLoader: Item {
        id: ml
        property real size: 48
        property color fillColor: mp.cPrimary
        property bool running: visible
        property bool contained: false
        property color containerColor: mp.cPrimCont
        width: size; height: size
        readonly property var seq: ["SoftBurst", "Cookie9Sided", "Pentagon", "Pill", "Sunny", "Cookie4Sided", "Oval"]
        property int idx: 0
        property real spin: 0
        Spring { id: mlM; target: 1; stiffness: 200; dampingRatio: 0.6 }
        Spring { id: mlR; target: 0; stiffness: 200; dampingRatio: 0.6; eps: 0.01 }
        NumberAnimation on spin { from: 0; to: 360; duration: 4666; loops: Animation.Infinite; running: ml.running && ml.visible }
        Timer {
            interval: 650; repeat: true; running: ml.running && ml.visible
            onTriggered: { ml.idx = (ml.idx + 1) % ml.seq.length; mlM.snap(0); mlM.target = 1; mlR.target += 90; }
        }
        Rectangle { anchors.fill: parent; radius: width / 2; color: ml.containerColor; visible: ml.contained }
        ShapeView {
            anchors.centerIn: parent
            width: ml.size * (ml.contained ? 0.72 : 0.84); height: width
            from: ml.seq[(ml.idx + ml.seq.length - 1) % ml.seq.length]; to: ml.seq[ml.idx]
            t: mlM.value; rot: ml.spin + mlR.value; fill: ml.fillColor; inset: 0.95
        }
    }
}
