// LyricSync.qml — video-editor-style lyrics sync editor (opened from MusicPlayer)
import QtQuick
import QtQuick.Controls
import QtMultimedia
import Quickshell
import Quickshell.Io

Item {
    id: ls
    property var mp
    property bool open: false

    visible: opacity > 0.01
    opacity: open ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    enabled: open

    // ───────────────────────── style ─────────────────────────
    function px(n) { return mp ? mp.px(n) : n; }
    function tx(es, en) { return mp ? mp.tx(es, en) : es; }
    function ga(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }
    function css(c, a) {
        return "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + "," + (a === undefined ? c.a : a) + ")";
    }
    readonly property color cPri:   mp ? mp.cPrimary : "#D0BCFF"
    readonly property color cOnPri: mp ? mp.cOnPrimary : "#381E72"
    readonly property color cTer:   mp ? mp.cTertiary : "#EFB8C8"
    readonly property color cSurf:  mp ? mp.cSurface : "#1C1B1F"
    readonly property color cText:  mp ? mp.cOnSurface : "#E6E1E5"
    readonly property color cVar:   mp ? mp.cOnSurfVar : "#CAC4D0"
    readonly property color cMuted: mp ? mp.cMuted : "#8E8A93"
    readonly property color cErr:   mp ? mp.cError : "#F2B8B5"
    readonly property color cLine:  mp ? mp.lineCol : Qt.rgba(1, 1, 1, 0.07)
    readonly property color cField: mp ? mp.bgField : Qt.rgba(1, 1, 1, 0.07)
    readonly property color cPop:   mp ? mp.bgPop : "#332E45"
    readonly property bool  light:  mp ? mp.light : false
    readonly property string fA: mp ? mp.fontA : "sans-serif"
    readonly property string fB: mp ? mp.fontB : "sans-serif"

    // ───────────────────────── state ─────────────────────────
    property string path: ""
    property var    info: null
    property real   dur: 0
    property var    peaks: []
    property real   peakRate: 100
    property bool   loading: false
    property bool   waveLoading: false
    property string waveErr: ""
    property var    segs: []             // audio segments [{ s, e, on }] covering [0, dur]
    property var    blocks: []           // [{ id, lines: [{ t, s }], end, fixedEnd }] (original audio times)
    property var    meta: []             // LRC headers that are kept ([ar:], [ti:]…)
    property bool   hasTag: false
    property bool   hasLrc: false
    property string src: "tag"           // tag | lrc: where the lyrics were loaded from
    property string target: "tag"        // tag | lrc | both: where they're saved
    property string note: ""             // notice about the loaded lyrics
    property real   origFirst: -1        // start of the first line on load (to show the offset)
    property int    nextId: 1

    property var    sel: ({})            // block id -> true
    property int    selRev: 0
    property int    focB: -1             // focused line (block id + index)
    property int    focI: -1
    property int    focRev: 0
    property int    selSeg: -1

    property string tool: "select"       // select | razor
    property bool   magnet: true
    property bool   stretchMode: false
    property bool   follow: true
    property bool   backup: true
    property real   rate: 1
    property real   pps: 50              // pixels per second
    property real   scrollX: 0
    property real   viewW: 600
    property real   playT: 0
    property real   snapGuide: -1
    property bool   saving: false
    property bool   shiftHeld: false

    property var    hist: []
    property var    fut: []
    property int    ver: 0
    property int    verSeq: 0
    property int    savedVer: 0
    readonly property bool dirty: ver !== savedVer
    readonly property bool audioCut: { for (var i = 0; i < segs.length; i++) if (!segs[i].on) return true; return false; }
    readonly property real keptDur: { var d = 0; for (var i = 0; i < segs.length; i++) if (segs[i].on) d += segs[i].e - segs[i].s; return d; }
    readonly property int  lineCount: { var n = 0; for (var i = 0; i < blocks.length; i++) n += blocks[i].lines.length; return n; }
    readonly property int  cutLines: {
        var _ = segs, n = 0;
        for (var i = 0; i < blocks.length; i++) for (var k = 0; k < blocks[i].lines.length; k++) if (!segOnAt(blocks[i].lines[k].t)) n++;
        return n;
    }
    readonly property real firstT: blocks.length ? blocks[0].lines[0].t : -1
    readonly property real shownOffset: origFirst >= 0 && firstT >= 0 ? firstT - origFirst : 0

    property bool   wasMainPlaying: false
    property string confirmKind: ""      // "" | close | replace
    property var    confirmFn: null

    readonly property string toolPath: {
        var u = Qt.resolvedUrl("scripts/lyric_sync_tool.py").toString();
        return u.indexOf("file://") === 0 ? decodeURIComponent(u.substring(7)) : u;
    }

    // ───────────────────────── utilities ─────────────────────────
    function clamp(v, a, b) { return Math.max(a, Math.min(b, v)); }
    function clone(o) { return JSON.parse(JSON.stringify(o)); }
    function t2x(t) { return t * pps - scrollX; }
    function x2t(x) { return (x + scrollX) / pps; }
    function bStart(b) { return b.lines[0].t; }
    function bLast(b) { return b.lines[b.lines.length - 1].t; }
    function lineEnd(b, k) { return k + 1 < b.lines.length ? b.lines[k + 1].t : b.end; }
    function idxOf(id) { for (var i = 0; i < blocks.length; i++) if (blocks[i].id === id) return i; return -1; }
    function fmtT(t, cs) {
        var neg = t < 0; t = Math.abs(t);
        var c = Math.round(t * 100), m = Math.floor(c / 6000), s = (c % 6000) / 100;
        var ss = cs === false ? String(Math.floor(s)) : s.toFixed(2);
        if (s < 10) ss = "0" + ss;
        return (neg ? "−" : "") + m + ":" + ss;
    }
    function fmtOff(d) { return (d >= 0 ? "+" : "−") + Math.abs(d).toFixed(2) + " s"; }
    function stamp(t) {
        var c = Math.round(Math.max(0, t) * 100), m = Math.floor(c / 6000), s = (c % 6000) / 100;
        return "[" + (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s.toFixed(2) + "]";
    }
    function median(a) {
        if (!a.length) return 0;
        a = a.slice().sort(function (x, y) { return x - y; });
        return a[Math.floor(a.length / 2)];
    }
    function segOnAt(t) {
        for (var i = 0; i < segs.length; i++) if (t < segs[i].e || i === segs.length - 1) return segs[i].on;
        return true;
    }
    function segIndexAt(t) {
        for (var i = 0; i < segs.length; i++) if (t < segs[i].e) return i;
        return segs.length - 1;
    }
    // original audio time -> time in the trimmed audio
    function mapT(t) {
        var acc = 0;
        for (var i = 0; i < segs.length; i++) {
            var g = segs[i];
            if (t >= g.e && i < segs.length - 1) { if (g.on) acc += g.e - g.s; continue; }
            if (g.on) return { t: acc + Math.min(t, g.e) - g.s, cut: false };
            return { t: acc, cut: true };
        }
        return { t: acc, cut: false };
    }
    function flatLines() {
        var out = [];
        for (var i = 0; i < blocks.length; i++)
            for (var k = 0; k < blocks[i].lines.length; k++)
                out.push({ b: blocks[i].id, bi: i, k: k, t: blocks[i].lines[k].t, s: blocks[i].lines[k].s, e: lineEnd(blocks[i], k) });
        return out;
    }
    readonly property var flat: flatLines()

    // ───────────────────────── open / close ─────────────────────────
    function openFor(p, initialText) {
        if (!p || !mp) return;
        path = p;
        info = null; peaks = []; waveErr = ""; segs = []; blocks = []; meta = []; note = "";
        sel = ({}); selRev++; focB = -1; focI = -1; focRev++; selSeg = -1;
        hist = []; fut = []; ver = 0; verSeq = 0; savedVer = 0;
        tool = "select"; playT = 0; scrollX = 0; confirmKind = ""; saving = false;
        loading = true;
        wasMainPlaying = mp.playing;
        if (mp.playing) mp.togglePlay();
        open = true;
        ls.forceActiveFocus();
        mp.call("track_get", { path: p }, function (ok, d) {
            if (p !== ls.path || !ls.open) return;
            ls.loading = false;
            if (!ok) { mp.toast(tx("No se pudo leer la canción: ", "Couldn't read the song: ") + d, true); ls.close(true); return; }
            ls.info = d;
            ls.dur = d.duration || 0;
            ls.segs = [{ s: 0, e: ls.dur, on: true }];
            ls.hasTag = !!(d.tags && (d.tags.lyrics || "").trim());
            ls.hasLrc = !!(d.lrcText || "").trim();
            ls.target = ls.hasTag && ls.hasLrc ? "both" : ls.hasLrc ? "lrc" : "tag";
            var useLrc = ls.hasLrc && (!ls.hasTag || (mp.parseLrc(d.lrcText).synced && !mp.parseLrc(d.tags.lyrics).synced));
            ls.src = useLrc ? "lrc" : "tag";
            var text = initialText ? initialText : (useLrc ? d.lrcText : (d.tags.lyrics || ""));
            ls.loadText(text, !!initialText);
            player.source = mp.fileUrl(p);
            ls.initialView();
            ls.loadWave();
        });
    }
    function loadWave() {
        var p = path;
        waveLoading = true; waveErr = "";
        runTool(["peaks", p, String(100)], function (ok, r) {
            if (p !== ls.path) return;
            ls.waveLoading = false;
            if (!ok) { ls.waveErr = String(r); return; }
            ls.peakRate = r.rate || 100;
            if (r.dur > 0 && Math.abs(r.dur - ls.dur) > 0.05) {
                ls.dur = r.dur;
                if (ls.segs.length === 1) ls.segs = [{ s: 0, e: ls.dur, on: true }];
                ls.fit();
            }
            ls.peaks = r.peaks || [];
        });
    }
    function requestClose() {
        if (saving) return;
        if (confirmKind !== "") { confirmKind = ""; return; }
        if (dirty) { askConfirm("close", function () { ls.close(true); }); return; }
        close(true);
    }
    function close(force) {
        if (!force && dirty) return requestClose();
        player.stop();
        player.source = "";
        open = false;
        confirmKind = "";
        if (wasMainPlaying && mp && !mp.playing) mp.togglePlay();
        wasMainPlaying = false;
        if (mp) Qt.callLater(mp.refocus);
    }
    function askConfirm(kind, fn) { confirmKind = kind; confirmFn = fn; }

    // ───────────────────────── load lyrics ─────────────────────────
    function loadText(text, markDirty) {
        var r = parseEdit(text || "");
        meta = r.meta;
        var bl;
        if (r.synced) { bl = buildBlocks(r.items, r.multi); note = ""; }
        else if (r.plain.some(function (x) { return x !== ""; })) { bl = buildPlain(r.plain); note = tx("La letra no tenía tiempos: se repartió a lo largo de la canción. Arrastra los bloques o usa T para marcarlos.", "The lyrics had no timestamps: they were spread across the song. Drag the blocks or use T to stamp them."); }
        else { bl = []; note = ""; }
        blocks = normBlocks(bl);
        origFirst = blocks.length ? blocks[0].lines[0].t : -1;
        sel = ({}); selRev++;
        focB = blocks.length ? blocks[0].id : -1; focI = blocks.length ? 0 : -1; focRev++;
        if (markDirty || bl.length && !r.synced) ver = ++verSeq;
    }
    function parseEdit(text) {
        text = text.replace(/\r/g, "");
        var offset = 0;
        var mo = text.match(/\[offset:\s*([+-]?\d+)\s*\]/i);
        if (mo) offset = parseInt(mo[1], 10) / 1000;
        var rx = /\[(\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?\]/g;
        var items = [], meta = [], plain = [], any = false, multi = false;
        var rows = text.split("\n");
        for (var i = 0; i < rows.length; i++) {
            var row = rows[i], stamps = [], m, last = 0;
            rx.lastIndex = 0;
            while ((m = rx.exec(row)) !== null) {
                if (m.index !== last) break;
                var frac = m[3] ? parseInt(m[3], 10) / Math.pow(10, m[3].length) : 0;
                stamps.push(parseInt(m[1], 10) * 60 + parseInt(m[2], 10) + frac);
                last = rx.lastIndex;
            }
            var tr = row.trim();
            if (stamps.length) {
                any = true;
                if (stamps.length > 1) multi = true;
                var txt = row.substring(last).replace(/<\d+:\d+(?:\.\d+)?>/g, "").trim();
                for (var j = 0; j < stamps.length; j++) items.push({ t: Math.max(0, stamps[j] - offset), s: txt });
            } else if (tr === "") {
                items.push({ brk: true });
                plain.push("");
            } else if (/^\[[a-z#]+:.*\]$/i.test(tr)) {
                if (!/^\[(offset|length)\s*:/i.test(tr)) meta.push(tr);
            } else {
                plain.push(tr);
            }
        }
        return { synced: any, items: items, meta: meta, plain: plain, multi: multi };
    }
    function buildBlocks(items, multi) {
        var lines = items.filter(function (x) { return !x.brk; });
        var sorted = true;
        for (var i = 1; i < lines.length; i++) if (lines[i].t < lines[i - 1].t) { sorted = false; break; }
        var ordered = (multi || !sorted) ? lines.slice().sort(function (a, b) { return a.t - b.t; }) : items;
        var gaps = [];
        var txtLines = lines.filter(function (x) { return x.s !== ""; }).sort(function (a, b) { return a.t - b.t; });
        for (i = 1; i < txtLines.length; i++) { var g = txtLines[i].t - txtLines[i - 1].t; if (g > 0.05) gaps.push(g); }
        var med = median(gaps) || 3;
        var typ = clamp(med * 1.1, 1.5, 6);
        var hasBreaks = ordered.some(function (x) { return x.brk || x.s === ""; })
                        && ordered.some(function (x) { return !x.brk && x.s !== ""; });
        var out = [], cur = null;
        function closeB(endT) {
            if (cur && cur.lines.length) { cur.end = endT; cur.fixedEnd = endT !== null; out.push(cur); }
            cur = null;
        }
        for (i = 0; i < ordered.length; i++) {
            var it = ordered[i];
            if (it.brk) { closeB(null); continue; }
            if (it.s === "") {
                if (cur) closeB(it.t);
                else if (out.length && out[out.length - 1].end === null && it.t > bLast(out[out.length - 1])) { out[out.length - 1].end = it.t; out[out.length - 1].fixedEnd = true; }
                continue;
            }
            if (cur && !hasBreaks && it.t - bLast(cur) > Math.max(4.5, med * 2.2)) closeB(null);
            if (!cur) cur = { id: nextId++, lines: [], end: null, fixedEnd: false };
            cur.lines.push({ t: it.t, s: it.s });
        }
        closeB(null);
        for (i = 0; i < out.length; i++) {
            var b = out[i], nx = out[i + 1] ? bStart(out[i + 1]) : Math.max(dur, bLast(b) + typ);
            if (b.end === null || b.end > nx) { b.end = Math.min(nx, bLast(b) + typ); b.fixedEnd = false; }
            if (b.end < bLast(b) + 0.05) b.end = bLast(b) + 0.05;
        }
        if (!hasBreaks) out = splitBig(out);
        return out;
    }
    // no paragraphs in the file: very long blocks are split at the biggest gap
    function splitBig(list) {
        var out = [], again = true;
        while (again) {
            again = false; out = [];
            for (var i = 0; i < list.length; i++) {
                var b = list[i], n = b.lines.length;
                if (n <= 8) { out.push(b); continue; }
                var best = -1, bestScore = -1;
                for (var k = 2; k <= n - 2; k++) {
                    var g = b.lines[k].t - b.lines[k - 1].t;
                    var score = g * (1 - Math.abs(k - n / 2) / n * 0.8);
                    if (score > bestScore) { bestScore = score; best = k; }
                }
                out.push({ id: b.id, lines: b.lines.slice(0, best), end: b.lines[best].t, fixedEnd: false });
                out.push({ id: nextId++, lines: b.lines.slice(best), end: b.end, fixedEnd: b.fixedEnd });
                again = true;
            }
            list = out;
        }
        return out;
    }
    function buildPlain(rows) {
        while (rows.length && !rows[0]) rows.shift();
        while (rows.length && !rows[rows.length - 1]) rows.pop();
        var paras = [[]];
        rows.forEach(function (r) { if (r) paras[paras.length - 1].push(r); else if (paras[paras.length - 1].length) paras.push([]); });
        paras = paras.filter(function (p) { return p.length; });
        var n = 0; paras.forEach(function (p) { n += p.length; });
        var D = dur > 0 ? dur : Math.max(60, n * 3);
        var t0 = D * 0.06, step = (D * 0.92 - t0) / Math.max(1, n), t = t0, out = [];
        paras.forEach(function (p) {
            var b = { id: nextId++, lines: [], end: 0, fixedEnd: false };
            p.forEach(function (s) { b.lines.push({ t: t, s: s }); t += step; });
            b.end = t - step * 0.15;
            out.push(b);
        });
        return out;
    }
    // ── save as LRC (optionally with the trimmed audio's timings) ──
    function buildLrc(mapped) {
        var rows = meta.slice();
        if (rows.length) rows.push("");
        var bs = [], dropped = 0;
        for (var i = 0; i < blocks.length; i++) {
            var b = blocks[i], L = [];
            for (var k = 0; k < b.lines.length; k++) {
                var m = mapped ? mapT(b.lines[k].t) : { t: b.lines[k].t, cut: false };
                if (m.cut) { dropped++; continue; }
                L.push({ t: m.t, s: b.lines[k].s });
            }
            if (!L.length) continue;
            var e = mapped ? mapT(b.end).t : b.end;
            if (e < L[L.length - 1].t + 0.05) e = L[L.length - 1].t + 0.05;
            bs.push({ lines: L, end: e, fixedEnd: b.fixedEnd });
        }
        for (i = 0; i < bs.length; i++) {
            var B = bs[i], nx = bs[i + 1];
            for (k = 0; k < B.lines.length; k++) rows.push(stamp(B.lines[k].t) + B.lines[k].s);
            if (B.fixedEnd && (!nx || nx.lines[0].t - B.end > 0.04)) rows.push(stamp(B.end));
            if (nx) rows.push("");
        }
        return { text: bs.length ? rows.join("\n") + "\n" : "", dropped: dropped };
    }

    // ───────────────────────── history ─────────────────────────
    function stateStr() { return JSON.stringify({ b: blocks, s: segs, v: ver }); }
    function pushUndo(st) {
        var h = hist.slice(); h.push(st);
        if (h.length > 200) h.shift();
        hist = h; fut = [];
    }
    function setState(st) {
        var o = JSON.parse(st);
        blocks = o.b; segs = o.s; ver = o.v;
        fixSel();
        focRev++;
    }
    function undo() {
        if (!hist.length) return;
        var h = hist.slice(), st = h.pop();
        fut = fut.concat([stateStr()]); hist = h;
        setState(st);
    }
    function redo() {
        if (!fut.length) return;
        var f = fut.slice(), st = f.pop();
        hist = hist.concat([stateStr()]); fut = f;
        setState(st);
    }
    // applies a change on copies; fn returns false to cancel it
    function edit(fn) {
        var before = stateStr();
        var nb = clone(blocks), ns = clone(segs);
        if (fn(nb, ns) === false) return false;
        pushUndo(before);
        blocks = normBlocks(nb);
        segs = normSegs(ns);
        ver = ++verSeq;
        fixSel();
        return true;
    }
    function normBlocks(nb) {
        nb = nb.filter(function (b) { return b.lines && b.lines.length; });
        nb.forEach(function (b) { b.lines.sort(function (x, y) { return x.t - y.t; }); });
        nb.sort(function (x, y) { return bStart(x) - bStart(y); });
        for (var i = 0; i < nb.length; i++) {
            var b = nb[i], nx = nb[i + 1];
            if (nx && b.end > bStart(nx)) b.end = bStart(nx);
            if (b.end < bLast(b) + 0.05) b.end = bLast(b) + 0.05;
        }
        return nb;
    }
    function normSegs(ns) {
        var o = [];
        for (var i = 0; i < ns.length; i++) {
            var s = ns[i];
            if (s.e - s.s < 0.02) continue;
            var L = o[o.length - 1];
            if (L && !L.on && !s.on) { L.e = s.e; continue; }
            o.push({ s: s.s, e: s.e, on: s.on });
        }
        if (!o.length) return [{ s: 0, e: dur, on: true }];
        o[0].s = 0;
        for (i = 1; i < o.length; i++) o[i].s = o[i - 1].e;
        o[o.length - 1].e = dur;
        return o;
    }
    function fixSel() {
        var s = {}, any = false;
        for (var k in sel) if (idxOf(Number(k)) >= 0) { s[k] = true; any = true; }
        sel = s; selRev++;
        var bi = idxOf(focB);
        if (bi < 0 || focI >= blocks[bi].lines.length) {
            if (bi >= 0) focI = blocks[bi].lines.length - 1;
            else { focB = -1; focI = -1; }
        }
        if (selSeg >= segs.length) selSeg = -1;
    }

    // ───────────────────────── selection ─────────────────────────
    function isSel(id) { var _ = selRev; return !!sel[id]; }
    function selectOnly(id) { var s = {}; if (id >= 0) s[id] = true; sel = s; selRev++; selSeg = -1; }
    function toggleSel(id) { var s = Object.assign({}, sel); if (s[id]) delete s[id]; else s[id] = true; sel = s; selRev++; selSeg = -1; }
    function selectAll() { var s = {}; blocks.forEach(function (b) { s[b.id] = true; }); sel = s; selRev++; selSeg = -1; }
    function clearSel() { sel = ({}); selRev++; selSeg = -1; }
    function selSet() { var s = {}, any = false; for (var k in sel) { s[k] = true; any = true; } return any ? s : null; }
    function allSet() { var s = {}; blocks.forEach(function (b) { s[b.id] = true; }); return s; }
    function selCount() { var _ = selRev, n = 0; for (var k in sel) n++; return n; }
    function setFocus(id, k) { focB = id; focI = k; focRev++; }
    function focusLine() { var _ = focRev, i = idxOf(focB); return i >= 0 && focI >= 0 && focI < blocks[i].lines.length ? { bi: i, k: focI, b: blocks[i], l: blocks[i].lines[focI] } : null; }
    function stepFocus(d) {
        var F = flat; if (!F.length) return;
        var cur = -1;
        for (var i = 0; i < F.length; i++) if (F[i].b === focB && F[i].k === focI) { cur = i; break; }
        var n = cur < 0 ? (d > 0 ? 0 : F.length - 1) : clamp(cur + d, 0, F.length - 1);
        setFocus(F[n].b, F[n].k);
        selectOnly(F[n].b);
        reveal(F[n].t);
    }
    function reveal(t) {
        var x = t2x(t);
        if (x < px(30) || x > viewW - px(60)) scrollX = clampScroll(t * pps - viewW * 0.3);
    }

    // ───────────────────────── magnet ─────────────────────────
    function snapPoints(excl) {
        var pts = [playT, 0, dur];
        for (var i = 1; i < segs.length; i++) pts.push(segs[i].s);
        for (i = 0; i < blocks.length; i++) {
            if (excl && excl[blocks[i].id]) continue;
            pts.push(bStart(blocks[i]), blocks[i].end);
        }
        return pts;
    }
    // returns the offset to add so that one of `cands` lands on a point
    function snapDelta(cands, pts) {
        snapGuide = -1;
        if (!magnet || shiftHeld) return 0;
        var thr = px(8) / pps, best = thr, d = 0, g = -1;
        for (var i = 0; i < cands.length; i++)
            for (var j = 0; j < pts.length; j++) {
                var dd = pts[j] - cands[i];
                if (Math.abs(dd) < best) { best = Math.abs(dd); d = dd; g = pts[j]; }
            }
        snapGuide = g;
        return d;
    }
    function snapTime(t, excl) { return t + snapDelta([t], snapPoints(excl)); }

    // ───────────────────────── operations on the lyrics ─────────────────────────
    function moveClamp(nb, set, dt) {
        var lo = -Infinity, hi = Infinity;
        for (var i = 0; i < nb.length; i++) {
            var b = nb[i];
            if (!set[b.id]) continue;
            lo = Math.max(lo, -bStart(b));
            if (dur > 0) hi = Math.min(hi, dur - 0.05 - bLast(b));
            var pv = nb[i - 1], nx = nb[i + 1];
            if (pv && !set[pv.id]) lo = Math.max(lo, bLast(pv) + 0.1 - bStart(b));
            if (nx && !set[nx.id]) hi = Math.min(hi, bStart(nx) - 0.1 - bLast(b));
        }
        lo = Math.min(lo, 0); hi = Math.max(hi, 0);
        return clamp(dt, lo, hi);
    }
    function applyMove(nb, set, dt) {
        nb.forEach(function (b) {
            if (!set[b.id]) return;
            b.lines.forEach(function (l) { l.t += dt; });
            b.end += dt;
        });
    }
    function nudge(dt, all) {
        var set = all ? allSet() : (selSet() || allSet());
        if (!blocks.length) return;
        edit(function (nb) {
            var d = moveClamp(nb, set, dt);
            if (Math.abs(d) < 1e-4) return false;
            applyMove(nb, set, d);
        });
    }
    // line k of block bi starts at t; `ripple` shifts everything after
    function setLineTime(id, k, t, ripple) {
        return edit(function (nb) {
            var i = -1;
            for (var q = 0; q < nb.length; q++) if (nb[q].id === id) i = q;
            if (i < 0) return false;
            var b = nb[i], old = b.lines[k].t;
            var lo = k > 0 ? b.lines[k - 1].t + 0.1 : (i > 0 ? bLast(nb[i - 1]) + 0.1 : 0);
            if (ripple) {
                var lastAll = bLast(nb[nb.length - 1]);
                var dt = clamp(t - old, lo - old, Math.max(0, dur > 0 ? dur - 0.05 - lastAll : Infinity));
                if (Math.abs(dt) < 1e-4) return false;
                for (var j = k; j < b.lines.length; j++) b.lines[j].t += dt;
                b.end += dt;
                for (q = i + 1; q < nb.length; q++) { nb[q].lines.forEach(function (l) { l.t += dt; }); nb[q].end += dt; }
                if (k === 0 && i > 0 && nb[i - 1].end > b.lines[0].t) nb[i - 1].end = b.lines[0].t;
            } else {
                var hi = k + 1 < b.lines.length ? b.lines[k + 1].t - 0.1 : (nb[i + 1] ? bStart(nb[i + 1]) - 0.15 : (dur > 0 ? dur - 0.1 : t));
                var nt = clamp(t, lo, Math.max(lo, hi));
                if (Math.abs(nt - old) < 1e-4) return false;
                b.lines[k].t = nt;
                if (k === b.lines.length - 1 && b.end < nt + 0.1) b.end = nt + Math.min(2, (nb[i + 1] ? bStart(nb[i + 1]) : nt + 2) - nt);
                if (k === 0 && i > 0 && nb[i - 1].end > nt) nb[i - 1].end = nt;
            }
        });
    }
    function markHere(ripple) {
        var F = focusLine();
        if (!F) {
            // no chosen line: the one closest to the playhead
            var best = -1, bd = 1e9;
            for (var i = 0; i < flat.length; i++) { var d = Math.abs(flat[i].t - playT); if (d < bd) { bd = d; best = i; } }
            if (best < 0) return;
            setFocus(flat[best].b, flat[best].k);
            F = focusLine();
        }
        var t = Math.max(0, playT - (playing ? 0.12 : 0));
        var id = F.b.id, k = F.k;
        if (setLineTime(id, k, t, ripple)) {
            snapGuide = -1;
            stepFocus(1);
            selectOnly(focB);
        }
    }
    function splitBlock(id, k) {
        return edit(function (nb) {
            for (var i = 0; i < nb.length; i++) if (nb[i].id === id) break;
            var b = nb[i];
            if (!b || k < 1 || k >= b.lines.length) return false;
            var nbk = { id: nextId++, lines: b.lines.slice(k), end: b.end, fixedEnd: b.fixedEnd };
            b.lines = b.lines.slice(0, k);
            b.end = nbk.lines[0].t; b.fixedEnd = false;
            nb.splice(i + 1, 0, nbk);
        });
    }
    function splitAtTime(t) {
        for (var i = 0; i < blocks.length; i++) {
            var b = blocks[i];
            if (t < bStart(b) - 0.05 || t > b.end + 0.05) continue;
            if (b.lines.length < 2) { mp.toast(tx("Ese bloque tiene una sola línea: usa «Partir texto» para dividir la línea", "That block has a single line: use “Split text” to split the line"), true); return; }
            var best = 1, bd = 1e9;
            for (var k = 1; k < b.lines.length; k++) { var d = Math.abs(b.lines[k].t - t); if (d < bd) { bd = d; best = k; } }
            splitBlock(b.id, best);
            return;
        }
        mp.toast(tx("No hay ningún bloque de letra en el cursor", "No lyric block at the playhead"), true);
    }
    function joinBlocks() {
        var ids = [];
        for (var k in sel) ids.push(Number(k));
        var idx = ids.map(idxOf).filter(function (i) { return i >= 0; }).sort(function (a, b) { return a - b; });
        if (!idx.length) { var F = focusLine(); if (F) idx = [F.bi]; }
        if (!idx.length) return;
        var a = idx[0], z = idx.length > 1 ? idx[idx.length - 1] : idx[0] + 1;
        if (z >= blocks.length) { mp.toast(tx("No hay un bloque siguiente con el que unir", "No next block to join with"), true); return; }
        var keepId = blocks[a].id;
        edit(function (nb) {
            var m = nb[a];
            for (var i = a + 1; i <= z; i++) { m.lines = m.lines.concat(nb[i].lines); m.end = nb[i].end; m.fixedEnd = nb[i].fixedEnd; }
            nb.splice(a + 1, z - a);
        });
        selectOnly(keepId);
    }
    function addLineAt(t) {
        var newId = -1, newK = 0;
        var ok = edit(function (nb) {
            for (var i = 0; i < nb.length; i++) {
                var b = nb[i];
                if (t >= bStart(b) - 0.05 && t <= b.end) {
                    for (var k = 0; k < b.lines.length; k++) if (Math.abs(b.lines[k].t - t) < 0.1) return false;
                    b.lines.push({ t: Math.max(t, 0), s: "…" });
                    b.lines.sort(function (x, y) { return x.t - y.t; });
                    newId = b.id;
                    for (k = 0; k < b.lines.length; k++) if (b.lines[k].t === Math.max(t, 0)) newK = k;
                    return;
                }
            }
            var nx = null;
            for (i = 0; i < nb.length; i++) if (bStart(nb[i]) > t) { nx = nb[i]; break; }
            var e = Math.min(nx ? bStart(nx) : (dur > 0 ? dur : t + 3), t + 3);
            if (e - t < 0.15) return false;
            var nbk = { id: nextId++, lines: [{ t: t, s: "…" }], end: e, fixedEnd: false };
            nb.push(nbk);
            newId = nbk.id; newK = 0;
        });
        if (!ok) { mp.toast(tx("Ya hay una línea en ese punto", "There's already a line there"), true); return; }
        selectOnly(newId);
        setFocus(newId, newK);
        Qt.callLater(function () { lineText.input.forceActiveFocus(); lineText.input.selectAll(); });
    }
    function deleteSel() {
        if (selSeg >= 0) { toggleSeg(selSeg); return; }
        var set = selSet();
        if (!set) { deleteFocusLine(); return; }
        edit(function (nb) {
            for (var i = nb.length - 1; i >= 0; i--) if (set[nb[i].id]) nb.splice(i, 1);
        });
        clearSel();
    }
    function deleteFocusLine() {
        var F = focusLine(); if (!F) return;
        var id = F.b.id, k = F.k;
        edit(function (nb) {
            for (var i = 0; i < nb.length; i++) if (nb[i].id === id) {
                nb[i].lines.splice(k, 1);
                if (!nb[i].lines.length) nb.splice(i, 1);
                return;
            }
            return false;
        });
    }
    function splitLineText(pos) {
        var F = focusLine(); if (!F) return;
        var s = F.l.s, a = s.substring(0, pos).trim(), b = s.substring(pos).trim();
        if (!a || !b) { mp.toast(tx("Pon el cursor del texto donde quieras partir la línea", "Put the text cursor where you want to split the line"), true); return; }
        var id = F.b.id, k = F.k;
        var t0 = F.l.t, t1 = lineEnd(F.b, k), mid = t0 + Math.max(0.1, (t1 - t0) / 2);
        if (t1 - t0 < 0.25) { mp.toast(tx("La línea es demasiado corta para partirla", "The line is too short to split"), true); return; }
        edit(function (nb) {
            for (var i = 0; i < nb.length; i++) if (nb[i].id === id) {
                nb[i].lines[k].s = a;
                nb[i].lines.splice(k + 1, 0, { t: mid, s: b });
                return;
            }
            return false;
        });
        setFocus(id, k + 1);
    }
    property string _textUndoKey: ""
    function setLineText(text) {
        var F = focusLine(); if (!F) return;
        var key = F.b.id + ":" + F.k + ":" + focRev;
        if (key !== _textUndoKey) { pushUndo(stateStr()); _textUndoKey = key; }
        var nb = clone(blocks);
        nb[F.bi].lines[F.k].s = text;
        blocks = nb;
        ver = ++verSeq;
    }
    function replaceLyrics(text, label) {
        var go = function () {
            pushUndo(stateStr());
            ls.loadText(text, true);
            ls.ver = ++ls.verSeq;
            mp.toast(label);
        };
        go();
    }

    // ───────────────────────── operations on the audio ─────────────────────────
    function cutAudioAt(t) {
        if (waveErr) { mp.toast(tx("Para cortar el audio hace falta ffmpeg", "Cutting audio needs ffmpeg"), true); return; }
        edit(function (nb, ns) {
            for (var i = 0; i < ns.length; i++) {
                var g = ns[i];
                if (t > g.s + 0.05 && t < g.e - 0.05) {
                    ns.splice(i, 1, { s: g.s, e: t, on: g.on }, { s: t, e: g.e, on: g.on });
                    return;
                }
            }
            return false;
        });
    }
    function toggleSeg(i) {
        if (i < 0 || i >= segs.length) return;
        var on = !segs[i].on;
        if (!on) {
            var others = 0;
            for (var j = 0; j < segs.length; j++) if (j !== i && segs[j].on) others++;
            if (!others) { mp.toast(tx("No puedes quitar todo el audio", "You can't remove all the audio"), true); return; }
        }
        var mid = (segs[i].s + segs[i].e) / 2;
        edit(function (nb, ns) { ns[i].on = on; });
        selSeg = segIndexAt(mid);
    }
    function restoreAudio() {
        edit(function (nb, ns) {
            if (ns.length === 1 && ns[0].on) return false;
            ns.splice(0, ns.length, { s: 0, e: dur, on: true });
        });
        selSeg = -1;
    }

    // ───────────────────────── view ─────────────────────────
    readonly property real minPps: calcMinPps()
    function calcMinPps() { return dur > 0 ? Math.max(0.5, (viewW - px(24)) / dur) : 10; }
    readonly property real maxPps: 900
    function clampScroll(v) { return Math.max(0, Math.min(v, Math.max(0, dur * pps - viewW + px(40)))); }
    property bool autoFit: true          // until zoomed by hand, the whole song fits
    function fit() { autoFit = true; pps = calcMinPps(); scrollX = 0; }
    // on open: ~40 s in view, starting just before the first line
    function initialView() {
        var m = calcMinPps(), want = Math.max(m, viewW / 40);
        if (want <= m * 1.1) { fit(); return; }
        autoFit = false;
        pps = want;
        scrollX = clampScroll(firstT > 2 ? (firstT - 2) * pps : 0);
    }
    function zoomAt(f, x) {
        autoFit = false;
        var t = x2t(x);
        pps = clamp(pps * f, calcMinPps(), maxPps);
        scrollX = clampScroll(t * pps - x);
    }
    onViewWChanged: { var m = calcMinPps(); if (autoFit || pps < m) pps = m; scrollX = clampScroll(scrollX); }
    onDurChanged: if (autoFit) pps = calcMinPps()

    // ───────────────────────── playback ─────────────────────────
    readonly property bool playing: player.playbackState === MediaPlayer.PlayingState
    property real _basePos: 0
    property real _baseStamp: 0
    property bool scrubbing: false
    MediaPlayer {
        id: player
        playbackRate: ls.rate
        audioOutput: AudioOutput { volume: ls.mp ? (ls.mp.muted ? 0 : ls.mp.volume * ls.mp.volume) : 0.8 }
        onPositionChanged: {
            ls._basePos = player.position / 1000;
            ls._baseStamp = Date.now();
            if (!ls.playing && !ls.scrubbing) ls.playT = ls._basePos;
        }
        onMediaStatusChanged: if (mediaStatus === MediaPlayer.EndOfMedia) ls.playT = ls.dur
        onPlaybackStateChanged: { ls._basePos = player.position / 1000; ls._baseStamp = Date.now(); }
    }
    Timer {
        interval: 16; repeat: true
        running: ls.open && ls.playing
        onTriggered: ls.tick()
    }
    function tick() {
        var t = _basePos + (Date.now() - _baseStamp) / 1000 * rate;
        if (dur > 0) t = Math.min(t, dur);
        // skip removed segments
        var i = segIndexAt(t);
        if (segs.length && !segs[i].on) {
            var j = i; while (j < segs.length && !segs[j].on) j++;
            if (j >= segs.length) {
                var le = 0; for (var q = 0; q < segs.length; q++) if (segs[q].on) le = segs[q].e;
                player.pause(); seek(Math.max(0, le - 0.05)); return;
            }
            seek(segs[j].s);
            return;
        }
        playT = t;
        if (follow && !lyrMa.pressed && !audMa.pressed) {
            var x = t2x(t);
            if (x > viewW * 0.92 || x < 0) scrollX = clampScroll(t * pps - viewW * 0.12);
        }
    }
    function seek(t) {
        t = clamp(t, 0, Math.max(0, dur - 0.05));
        player.position = Math.round(t * 1000);
        playT = t; _basePos = t; _baseStamp = Date.now();
    }
    function togglePlay() {
        if (playing) { player.pause(); return; }
        if (playT >= dur - 0.1) seek(0);
        var i = segIndexAt(playT);
        if (segs.length && !segs[i].on) {
            var j = i; while (j < segs.length && !segs[j].on) j++;
            if (j < segs.length) seek(segs[j].s);
        }
        player.play();
    }
    function cycleRate() { rate = rate === 1 ? 0.75 : rate === 0.75 ? 0.5 : 1; }

    // ───────────────────────── save ─────────────────────────
    property var _toolQ: []
    Process {
        id: toolProc
        property var cb: null
        property bool done: true
        stdout: StdioCollector { id: toolOut; onStreamFinished: ls._toolDone(this.text) }
        stderr: StdioCollector { id: toolErr }
        onExited: (code, status) => toolGuard.restart()
    }
    Timer { id: toolGuard; interval: 500; onTriggered: if (!toolProc.done) ls._toolDone("") }
    function runTool(args, cb) {
        var q = _toolQ.slice(); q.push({ args: args, cb: cb }); _toolQ = q;
        if (toolProc.done) _toolNext();
    }
    function _toolNext() {
        if (!_toolQ.length || !toolProc.done) return;
        var q = _toolQ.slice(), j = q.shift(); _toolQ = q;
        toolProc.cb = j.cb; toolProc.done = false;
        toolProc.command = ["python3", toolPath].concat(j.args);
        toolProc.running = true;
    }
    function _toolDone(text) {
        if (toolProc.done) return;
        toolProc.done = true;
        toolGuard.stop();
        var r = null;
        try { var rows = String(text || "").trim().split("\n"); r = JSON.parse(rows[rows.length - 1]); } catch (e) {}
        var cb = toolProc.cb; toolProc.cb = null;
        if (cb) {
            if (r && r.ok) cb(true, r);
            else cb(false, r && r.error ? r.error : ((toolErr.text || "").trim().split("\n").pop() || tx("el ayudante no respondió (¿python3?)", "helper didn't respond (python3?)")));
        }
        Qt.callLater(_toolNext);
    }

    function save() {
        if (saving || !info || loading) return;
        if (info.writable === false) { mp.toast(tx("El archivo es de solo lectura", "The file is read-only"), true); return; }
        var p = path, cutting = audioCut;
        var res = buildLrc(cutting);
        var kept = [];
        segs.forEach(function (g) {
            if (!g.on) return;
            var L = kept[kept.length - 1];
            if (L && Math.abs(L[1] - g.s) < 1e-6) L[1] = g.e; else kept.push([g.s, g.e]);
        });
        var tgt = target;
        var mainCur = p === mp.curPath, mainPos = mp.posSec;
        saving = true;
        var finish = function (okAll, msg) {
            ls.saving = false;
            if (!okAll) { mp.toast(msg, true); return; }
            if (mainCur) {
                if (cutting && typeof mp.reloadCurrent === "function") mp.reloadCurrent(ls.mapT(mainPos).t, false);
                mp.loadCurInfo();
            }
            mp.toast(msg);
            if (cutting) {
                // the audio changed: reload everything from the file
                ls.openFor(p, "");
                ls.wasMainPlaying = false;
            } else {
                ls.savedVer = ls.ver;
                ls.hasTag = tgt !== "lrc" && res.text !== "";
                ls.hasLrc = tgt !== "tag" && res.text !== "";
            }
        };
        var writeLyrics = function () {
            var steps = [];
            if (tgt !== "lrc") steps.push(function (next) {
                mp.call("tags_write", { paths: [p], tags: { lyrics: res.text }, lrcSidecar: tgt === "tag" && ls.hasLrc ? "delete" : "" }, function (ok, d) { if (ok) mp.upsertTracks(d.tracks); next(ok, d); });
            });
            if (tgt === "lrc") steps.push(function (next) {
                // .lrc only: remove the embedded lyrics so they don't shadow the .lrc
                mp.call("tags_write", { paths: [p], tags: ls.hasTag ? { lyrics: "" } : {} }, function (ok, d) { if (ok) mp.upsertTracks(d.tracks); next(true); });
            });
            if (tgt !== "tag") steps.push(function (next) {
                mp.call("lrc_save", { path: p, text: res.text }, function (ok, d) { next(ok, d); });
            });
            var run = function (i) {
                if (i >= steps.length) {
                    var m = tx("Guardado", "Saved");
                    if (cutting) m += " · " + tx("audio recortado", "audio trimmed");
                    if (res.dropped) m += " · " + res.dropped + tx(" líneas quitadas", " lines removed");
                    finish(true, m);
                    return;
                }
                steps[i](function (ok, d) {
                    if (!ok) { finish(false, tx("No se pudo guardar la letra: ", "Couldn't save the lyrics: ") + d); return; }
                    run(i + 1);
                });
            };
            run(0);
        };
        if (cutting) {
            player.stop();
            player.source = "";
            runTool(["cut", p, JSON.stringify(kept), backup ? "1" : "0"], function (ok, r) {
                if (!ok) {
                    ls.saving = false;
                    player.source = mp.fileUrl(p);
                    mp.toast(tx("No se pudo recortar el audio: ", "Couldn't trim the audio: ") + r, true);
                    return;
                }
                writeLyrics();
            });
        } else writeLyrics();
    }
    function importFile() {
        mp.call("pick", { title: tx("Importar letra", "Import lyrics"), kind: "lrc" }, function (ok, d) {
            if (!ok || d.status !== "ok") { if (ok && d.status === "nopicker") mp.toast(mp.noPickerMsg(), true); return; }
            ls.importPath(d.paths[0]);
        });
    }
    function importPath(f) {
        mp.call("read_text", { path: f }, function (ok, txt) {
            if (!ok) { mp.toast(txt, true); return; }
            ls.replaceLyrics(txt, tx("Letra importada: ", "Lyrics imported: ") + mp.baseName(f));
        });
    }
    property bool fetching: false
    function fetchOnline() {
        if (!info || fetching) return;
        var tg = info.tags || {}, t = mp.trackOf(path) || {};
        var title = tg.title || t.t || "";
        if (!title) { mp.toast(tx("La canción no tiene título para buscar la letra", "The song has no title to search with"), true); return; }
        fetching = true;
        mp.call("lyrics_fetch", { title: title, artist: tg.artist || t.ar || "", album: tg.album || "", duration: dur }, function (ok, d) {
            ls.fetching = false;
            if (!ok) { mp.toast(tx("No se pudo buscar la letra: ", "Lyrics search failed: ") + d, true); return; }
            if (!d.found) { mp.toast(tx("No se encontró letra para esta canción", "No lyrics found for this song"), true); return; }
            ls.replaceLyrics(d.synced || d.plain, d.synced ? tx("Letra sincronizada de LRCLIB cargada", "Synced lyrics from LRCLIB loaded") : tx("Letra de LRCLIB cargada (sin tiempos)", "Lyrics from LRCLIB loaded (no timestamps)"));
        });
    }
    function switchSource(s) {
        if (!info || s === src) return;
        var go = function () {
            ls.src = s;
            var text = s === "lrc" ? (ls.info.lrcText || "") : (ls.info.tags.lyrics || "");
            ls.hist = []; ls.fut = [];
            ls.loadText(text, false);
            ls.ver = 0; ls.verSeq = 0; ls.savedVer = 0;
        };
        if (dirty) askConfirm("source", go); else go();
    }

    // ───────────────────────── track interaction ─────────────────────────
    property var dragSt: null
    function hitLyr(x) {
        var tolPx = px(6), t = x2t(x);
        for (var i = 0; i < blocks.length; i++) {
            var b = blocks[i], xs = t2x(bStart(b)), xe = t2x(b.end);
            if (x < xs - tolPx || x > xe + tolPx) continue;
            var nx = blocks[i + 1], pv = blocks[i - 1];
            var nearNext = nx && t2x(bStart(nx)) - xe < px(14);
            var nearPrev = pv && xs - t2x(pv.end) < px(14);
            var wide = xe - xs > px(16);
            if (Math.abs(x - xe) <= tolPx && (!nearNext || x <= xe + 1) && (wide || x > (xs + xe) / 2)) return { kind: "trimR", i: i };
            if (Math.abs(x - xs) <= tolPx && (!nearPrev || x >= xs - 1)) return { kind: "trimL", i: i };
            for (var k = 1; k < b.lines.length; k++) if (Math.abs(x - t2x(b.lines[k].t)) <= px(4)) return { kind: "div", i: i, k: k };
            if (x >= xs && x <= xe) {
                var kk = 0;
                for (k = 0; k < b.lines.length; k++) if (b.lines[k].t <= t) kk = k;
                return { kind: "body", i: i, k: kk };
            }
        }
        return { kind: "none", i: -1 };
    }
    function lyrCursor(h, pressedNow) {
        if (tool === "razor") return Qt.SplitHCursor;
        if (h.kind === "trimL" || h.kind === "trimR" || h.kind === "div") return Qt.SizeHorCursor;
        if (h.kind === "body") return pressedNow ? Qt.ClosedHandCursor : Qt.OpenHandCursor;
        return Qt.ArrowCursor;
    }
    function lyrPress(m, item) {
        ls.forceActiveFocus();
        shiftHeld = !!(m.modifiers & Qt.ShiftModifier);
        var h = hitLyr(m.x), t = x2t(m.x);
        var ctrl = !!(m.modifiers & Qt.ControlModifier), alt = !!(m.modifiers & Qt.AltModifier);
        if (m.button === Qt.RightButton) {
            if (h.i >= 0) { if (!isSel(blocks[h.i].id)) selectOnly(blocks[h.i].id); if (h.k !== undefined) setFocus(blocks[h.i].id, h.k); }
            var g = item.mapToItem(null, m.x, m.y);
            lyrMenu(h, t, g.x, g.y);
            dragSt = null;
            return;
        }
        if (tool === "razor") {
            if (h.i >= 0) splitAtTime(snapTime(t));
            dragSt = null;
            return;
        }
        dragSt = { kind: h.kind, i: h.i, k: h.k, x0: m.x, sx: scrollX, base: clone(blocks), before: stateStr(), moved: false, alt: alt || stretchMode, shift: shiftHeld, all: ctrl };
        if (ctrl && h.i >= 0 && h.kind !== "body") { dragSt.kind = "body"; h.kind = "body"; if (h.k === undefined) h.k = 0; }
        if (h.kind === "body") {
            var b = blocks[h.i];
            if (ctrl) { dragSt.kind = "move"; dragSt.set = allSet(); dragSt.prevSel = Object.assign({}, sel); selectAll(); }
            else if (shiftHeld) { toggleSel(b.id); dragSt.kind = "none"; }
            else { if (!isSel(b.id)) selectOnly(b.id); dragSt.kind = "move"; dragSt.set = selSet(); }
            setFocus(b.id, h.k);
            dragSt.grab = b.id;
        } else if (h.kind === "trimL" || h.kind === "trimR" || h.kind === "div") {
            if (!isSel(blocks[h.i].id)) selectOnly(blocks[h.i].id);
            setFocus(blocks[h.i].id, h.kind === "trimR" ? blocks[h.i].lines.length - 1 : (h.kind === "div" ? h.k : 0));
        } else {
            if (!shiftHeld) clearSel();
            dragSt.kind = "scrub";
            scrubbing = true;
            seek(t);
        }
    }
    function lyrMove(m) {
        var D = dragSt;
        if (!D) return;
        shiftHeld = !!(m.modifiers & Qt.ShiftModifier);
        if (D.kind === "scrub") { seek(x2t(m.x)); edgeScroll(m.x); return; }
        var dx = m.x - D.x0;
        if (!D.moved && Math.abs(dx) < 3) return;
        D.moved = true;
        if (!D.grip) edgeScroll(m.x);
        var dt = D.grip ? dx / pps : (dx + scrollX - D.sx) / pps;
        var nb = clone(D.base), b = nb[D.i];
        if (D.kind === "move") {
            var gb = null;
            for (var q = 0; q < nb.length; q++) if (nb[q].id === D.grab) gb = nb[q];
            var d0 = moveClamp(nb, D.set, dt);
            if (gb) {
                var sd = snapDelta([bStart(gb) + d0, gb.end + d0], snapPoints(D.set));
                if (sd !== 0) d0 = moveClamp(nb, D.set, d0 + sd);
            }
            applyMove(nb, D.set, d0);
            D.dt = d0;
        } else if (D.kind === "trimL") {
            var pv = nb[D.i - 1];
            var lo = pv ? bLast(pv) + 0.1 : 0;
            if (D.alt) {
                var E = b.end, S0 = bStart(b), n = b.lines.length;
                var ns = clamp(S0 + dt, lo, E - 0.12 * n);
                ns += snapDelta([ns], snapPoints(null)); ns = clamp(ns, lo, E - 0.12 * n);
                var kf = (E - ns) / (E - S0);
                b.lines.forEach(function (l) { l.t = E - (E - l.t) * kf; });
            } else {
                var hi = (b.lines.length > 1 ? b.lines[1].t : b.end) - 0.1;
                var nt = clamp(bStart(b) + dt, lo, hi);
                nt += snapDelta([nt], snapPoints(null)); nt = clamp(nt, lo, hi);
                b.lines[0].t = nt;
            }
            if (pv && pv.end > bStart(b)) pv.end = bStart(b);
        } else if (D.kind === "trimR") {
            var nx = nb[D.i + 1];
            var hiR = nx ? bStart(nx) : (dur > 0 ? dur : b.end + 60);
            if (D.alt) {
                var S = bStart(b), E0 = b.end;
                var ne = clamp(E0 + dt, S + (E0 - S) * 0.2, hiR);
                ne += snapDelta([ne], snapPoints(null)); ne = clamp(ne, S + (E0 - S) * 0.2, hiR);
                var kr = (ne - S) / (E0 - S);
                b.lines.forEach(function (l) { l.t = S + (l.t - S) * kr; });
                b.end = ne;
            } else {
                var ne2 = clamp(b.end + dt, bLast(b) + 0.1, hiR);
                ne2 += snapDelta([ne2], snapPoints(null)); ne2 = clamp(ne2, bLast(b) + 0.1, hiR);
                b.end = ne2;
            }
            b.fixedEnd = true;
        } else if (D.kind === "div") {
            var k = D.k;
            var lo2 = b.lines[k - 1].t + 0.1, hi2 = lineEnd(b, k) - 0.1;
            var nt2 = clamp(b.lines[k].t + dt, lo2, hi2);
            nt2 += snapDelta([nt2], snapPoints(null)); nt2 = clamp(nt2, lo2, hi2);
            b.lines[k].t = nt2;
        } else return;
        blocks = normBlocks(nb);
    }
    function lyrRelease() {
        var D = dragSt;
        dragSt = null;
        scrubbing = false;
        snapGuide = -1;
        if (!D) return;
        if (D.prevSel) { sel = D.prevSel; selRev++; fixSel(); }
        if (D.moved && D.kind !== "scrub" && D.kind !== "none") {
            pushUndo(D.before);
            ver = ++verSeq;
        } else if (!D.moved && D.kind === "move" && D.i >= 0) {
            // click without dragging: the playhead jumps to the start of that line
            var F = focusLine();
            if (F) seek(F.l.t);
            if (!D.shift && !D.all && F) selectOnly(F.b.id);
        }
    }
    property real _lastEdge: 0
    function edgeScroll(x) {
        var now = Date.now();
        if (now - _lastEdge < 30) return;
        var z = px(28), v = 0;
        if (x < z) v = -(z - x);
        else if (x > viewW - z) v = x - (viewW - z);
        if (v !== 0) { scrollX = clampScroll(scrollX + v * 0.6); _lastEdge = now; }
    }
    function lyrMenu(h, t, gx, gy) {
        var m = [];
        var b = h.i >= 0 ? blocks[h.i] : null;
        if (b) {
            m.push({ icon: "content_cut", label: tx("Dividir el bloque aquí", "Split block here"), key: "S", disabled: b.lines.length < 2, fn: function () { ls.splitAtTime(t); } });
            m.push({ icon: "join", label: tx("Unir con el siguiente", "Join with next"), key: "J", disabled: h.i >= ls.blocks.length - 1, fn: function () { ls.selectOnly(b.id); ls.joinBlocks(); } });
            m.push({ sep: true });
            m.push({ icon: "my_location", label: tx("Esta línea empieza en el cursor (y lo siguiente)", "This line starts at playhead (and the rest)"), key: "T", fn: function () { ls.markHere(true); } });
            m.push({ icon: "edit", label: tx("Editar texto", "Edit text"), key: "Intro", fn: function () { lineText.input.forceActiveFocus(); } });
            m.push({ icon: "add", label: tx("Insertar línea en el cursor", "Insert line at playhead"), key: "N", fn: function () { ls.addLineAt(ls.playT); } });
            m.push({ sep: true });
            m.push({ icon: "remove", label: tx("Borrar esta línea", "Delete this line"), fn: function () { ls.deleteFocusLine(); } });
            m.push({ icon: "delete", label: tx("Borrar bloque", "Delete block"), key: "Supr", danger: true, fn: function () { ls.selectOnly(b.id); ls.deleteSel(); } });
        } else {
            m.push({ icon: "add", label: tx("Línea nueva aquí", "New line here"), fn: function () { ls.addLineAt(t); } });
        }
        m.push({ sep: true });
        m.push({ icon: "select_all", label: tx("Seleccionar toda la letra", "Select all lyrics"), key: "Ctrl+A", fn: function () { ls.selectAll(); } });
        mp.openMenu(m, gx, gy);
    }

    function hitAud(x) {
        var tol = px(6);
        if (!segs.length) return { kind: "none" };
        for (var j = 1; j < segs.length; j++) if (Math.abs(x - t2x(segs[j].s)) <= tol) return { kind: "bound", j: j };
        if (Math.abs(x - t2x(0)) <= tol && segs[0].on) return { kind: "edgeL" };
        if (Math.abs(x - t2x(dur)) <= tol && segs[segs.length - 1].on) return { kind: "edgeR" };
        var t = x2t(x);
        if (t < 0 || t > dur) return { kind: "none" };
        return { kind: "body", i: segIndexAt(t) };
    }
    function audPress(m, item) {
        ls.forceActiveFocus();
        shiftHeld = !!(m.modifiers & Qt.ShiftModifier);
        var h = hitAud(m.x), t = x2t(m.x);
        if (m.button === Qt.RightButton) {
            var g = item.mapToItem(null, m.x, m.y);
            var i = h.kind === "body" ? h.i : segIndexAt(clamp(t, 0, dur));
            selSeg = i; clearSelKeepSeg();
            audMenu(i, t, g.x, g.y);
            dragSt = null;
            return;
        }
        if (tool === "razor") { cutAudioAt(snapTime(t)); dragSt = null; return; }
        var base = clone(segs);
        var D = { kind: h.kind, x0: m.x, before: stateStr(), moved: false, sx: scrollX };
        if (h.kind === "edgeL") { base.unshift({ s: 0, e: 0, on: false }); D.kind = "bound"; D.j = 1; }
        else if (h.kind === "edgeR") { base.push({ s: dur, e: dur, on: false }); D.kind = "bound"; D.j = base.length - 1; }
        else if (h.kind === "bound") D.j = h.j;
        D.base = base;
        if (h.kind === "body") {
            selSeg = h.i; clearSelKeepSeg();
            D.kind = "scrub"; scrubbing = true; seek(t);
        } else if (h.kind === "none") { D.kind = "scrub"; scrubbing = true; seek(clamp(t, 0, dur)); }
        dragSt = D;
    }
    function clearSelKeepSeg() { var s = selSeg; sel = ({}); selRev++; selSeg = s; }
    function audMove(m) {
        var D = dragSt;
        if (!D) return;
        shiftHeld = !!(m.modifiers & Qt.ShiftModifier);
        if (D.kind === "scrub") { seek(clamp(x2t(m.x), 0, dur)); edgeScroll(m.x); return; }
        if (D.kind !== "bound") return;
        var dx = m.x - D.x0;
        if (!D.moved && Math.abs(dx) < 3) return;
        D.moved = true;
        edgeScroll(m.x);
        var ns = clone(D.base), j = D.j;
        var t = (m.x + scrollX) / pps;
        var lo = ns[j - 1].s + (ns[j - 1].on || j - 1 > 0 ? 0.05 : 0), hi = ns[j].e - (ns[j].on || j < ns.length - 1 ? 0.05 : 0);
        t = clamp(t, lo, hi);
        t += snapDelta([t], snapPoints(null));
        t = clamp(t, lo, hi);
        ns[j - 1].e = t; ns[j].s = t;
        segs = ns;
    }
    function audRelease() {
        var D = dragSt;
        dragSt = null; scrubbing = false; snapGuide = -1;
        if (!D) return;
        if (D.kind === "bound") {
            if (D.moved) { segs = normSegs(segs); pushUndo(D.before); ver = ++verSeq; }
            else segs = normSegs(JSON.parse(D.before).s);
        }
    }
    function audMenu(i, t, gx, gy) {
        var g = segs[i];
        var m = [];
        m.push({ icon: "content_cut", label: tx("Cortar el audio aquí", "Cut audio here"), key: "X", fn: function () { ls.cutAudioAt(t); } });
        if (g) m.push({ icon: g.on ? "remove_circle" : "restore", label: g.on ? tx("Quitar este tramo", "Remove this part") : tx("Recuperar este tramo", "Restore this part"), key: "Supr", danger: g.on, fn: function () { ls.toggleSeg(i); } });
        m.push({ sep: true });
        m.push({ icon: "restart_alt", label: tx("Deshacer todos los recortes del audio", "Undo all audio trims"), disabled: !ls.audioCut && ls.segs.length < 2, fn: function () { ls.restoreAudio(); } });
        mp.openMenu(m, gx, gy);
    }

    // ───────────────────────── keyboard ─────────────────────────
    Keys.onPressed: (e) => {
        if (!ls.open) return;
        var ctrl = e.modifiers & Qt.ControlModifier, sh = e.modifiers & Qt.ShiftModifier, alt = e.modifiers & Qt.AltModifier;
        ls.shiftHeld = !!sh;
        var k = e.key, done = true;
        if (ls.confirmKind !== "") { if (k === Qt.Key_Return || k === Qt.Key_Enter) ls.confirmYes(); else if (k === Qt.Key_Escape) ls.confirmKind = ""; e.accepted = true; return; }
        if (ctrl && k === Qt.Key_Z && !sh) ls.undo();
        else if (ctrl && (k === Qt.Key_Y || (k === Qt.Key_Z && sh))) ls.redo();
        else if (ctrl && k === Qt.Key_S) ls.save();
        else if (ctrl && k === Qt.Key_A) ls.selectAll();
        else if (k === Qt.Key_Space) ls.togglePlay();
        else if ((k === Qt.Key_Left || k === Qt.Key_Right) && alt) ls.nudge((k === Qt.Key_Left ? -1 : 1) * (sh ? 0.5 : 0.05), false);
        else if (k === Qt.Key_Left || k === Qt.Key_Right) { ls.seek(ls.playT + (k === Qt.Key_Left ? -1 : 1) * (sh ? 5 : 1)); ls.reveal(ls.playT); }
        else if (k === Qt.Key_Up) ls.stepFocus(-1);
        else if (k === Qt.Key_Down) ls.stepFocus(1);
        else if (k === Qt.Key_Home) { ls.seek(0); ls.reveal(0); }
        else if (k === Qt.Key_End) { ls.seek(ls.dur); ls.reveal(ls.dur); }
        else if (k === Qt.Key_V && !ctrl) ls.tool = "select";
        else if (k === Qt.Key_C && !ctrl) ls.tool = ls.tool === "razor" ? "select" : "razor";
        else if (k === Qt.Key_S && !ctrl) ls.splitAtTime(ls.playT);
        else if (k === Qt.Key_X && !ctrl) ls.cutAudioAt(ls.playT);
        else if (k === Qt.Key_J && !ctrl) ls.joinBlocks();
        else if (k === Qt.Key_N && !ctrl) ls.addLineAt(ls.playT);
        else if (k === Qt.Key_T && !ctrl) ls.markHere(!sh);
        else if (k === Qt.Key_M && !ctrl) ls.magnet = !ls.magnet;
        else if (k === Qt.Key_Delete || k === Qt.Key_Backspace) { if (sh) ls.deleteFocusLine(); else ls.deleteSel(); }
        else if (k === Qt.Key_Return || k === Qt.Key_Enter) { if (ls.focusLine()) { lineText.input.forceActiveFocus(); lineText.input.selectAll(); } }
        else if (k === Qt.Key_Plus || k === Qt.Key_Equal) ls.zoomAt(1.4, ls.t2x(ls.playT));
        else if (k === Qt.Key_Minus) ls.zoomAt(1 / 1.4, ls.t2x(ls.playT));
        else if (k === Qt.Key_0) ls.fit();
        else if (k === Qt.Key_Escape) ls.escapeKey();
        else done = false;
        e.accepted = done;
    }
    Keys.onReleased: (e) => { ls.shiftHeld = !!(e.modifiers & Qt.ShiftModifier); }
    onHistChanged: if (hist.length) note = ""
    function escapeKey() {
        if (lti.activeFocus) { lti.reload(); ls.forceActiveFocus(); }
        else if (confirmKind !== "") confirmKind = "";
        else if (tool === "razor") tool = "select";
        else if (selCount() || selSeg >= 0) clearSel();
        else requestClose();
    }
    function confirmYes() { var f = confirmFn; confirmKind = ""; confirmFn = null; if (f) f(); }

    // ══ UI ══
    Rectangle {
        anchors.fill: parent
        color: ls.mp && ls.mp.glass ? ls.ga(ls.cSurf, 0.94) : ls.cSurf
    }
    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onWheel: (w) => {}; onPressed: ls.forceActiveFocus() }

    // drop a .lrc / .txt on top to replace the lyrics
    DropArea {
        anchors.fill: parent
        onEntered: (d) => { if (!d.hasUrls) d.accepted = false; }
        onDropped: (d) => {
            for (var i = 0; i < d.urls.length; i++) {
                var f = ls.mp.urlToPath(d.urls[i]);
                if (/\.(lrc|txt)$/i.test(f)) { ls.importPath(f); return; }
            }
            ls.mp.toast(ls.tx("Suelta un archivo .lrc o .txt", "Drop a .lrc or .txt file"), true);
        }
    }

    readonly property real headH: px(64)
    readonly property real toolH: px(48)
    readonly property real rulerH: px(26)
    readonly property real ovH: px(30)
    readonly property real footH: px(62)
    readonly property real hdrW: px(178)
    readonly property real trackH: clamp((height - headH - toolH - rulerH - ovH - footH - px(60) - px(150)) / 2, px(74), px(150))

    // ───────────── header ─────────────
    Item {
        id: head
        x: px(20); width: parent.width - px(40)
        height: ls.headH
        Rectangle {
            id: headIco
            anchors.verticalCenter: parent.verticalCenter
            width: px(40); height: width; radius: width / 2
            color: ls.ga(ls.cPri, 0.18)
            Glyph { anchors.centerIn: parent; text: "graphic_eq"; size: px(21); color: ls.cPri }
        }
        Column {
            anchors.left: headIco.right; anchors.leftMargin: px(12)
            anchors.right: headBtns.left; anchors.rightMargin: px(12)
            anchors.verticalCenter: parent.verticalCenter
            Text {
                width: parent.width; elide: Text.ElideRight
                text: ls.tx("Sincronizar letra", "Sync lyrics") + (ls.dirty ? "  •" : "")
                font.family: ls.fA; font.pixelSize: px(17); font.weight: Font.DemiBold
                color: ls.cText
            }
            Text {
                width: parent.width; elide: Text.ElideRight
                text: {
                    if (!ls.info) return ls.mp ? ls.mp.baseName(ls.path) : "";
                    var tg = ls.info.tags || {};
                    return [tg.title || (ls.mp ? ls.mp.baseName(ls.path) : ""), tg.artist].filter(Boolean).join(" — ");
                }
                font.family: ls.fB; font.pixelSize: px(11.5); color: ls.cMuted
            }
        }
        Row {
            id: headBtns
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: px(6)
            MiniSeg {
                anchors.verticalCenter: parent.verticalCenter
                visible: ls.hasTag && ls.hasLrc
                current: ls.src
                options: [{ value: "tag", label: ls.tx("Integrada", "Embedded"), tip: ls.tx("Editar la letra guardada dentro del archivo", "Edit the lyrics stored inside the file") },
                          { value: "lrc", label: ".lrc", tip: ls.tx("Editar el archivo .lrc de al lado", "Edit the .lrc file next to it") }]
                onPicked: (v) => ls.switchSource(v)
            }
            Pill { anchors.verticalCenter: parent.verticalCenter; glyph: "upload_file"; label: ls.tx("Importar", "Import"); tip: ls.tx("Reemplazar con un .lrc / .txt (también puedes soltarlo aquí)", "Replace with a .lrc / .txt (you can also drop it here)"); onClicked: ls.importFile() }
            Pill { anchors.verticalCenter: parent.verticalCenter; glyph: ls.fetching ? "hourglass_top" : "travel_explore"; label: "LRCLIB"; enabled: !ls.fetching; tip: ls.tx("Buscar otra letra en LRCLIB", "Search other lyrics on LRCLIB"); onClicked: ls.fetchOnline() }
            Item { width: px(6); height: 1 }
            Btn { glyph: "undo"; enabled: ls.hist.length > 0; tip: ls.tx("Deshacer (Ctrl+Z)", "Undo (Ctrl+Z)"); onClicked: ls.undo() }
            Btn { glyph: "redo"; enabled: ls.fut.length > 0; tip: ls.tx("Rehacer (Ctrl+Y)", "Redo (Ctrl+Y)"); onClicked: ls.redo() }
            Btn { glyph: "close"; enabled: !ls.saving; tip: ls.tx("Cerrar (Esc)", "Close (Esc)"); onClicked: ls.requestClose() }
        }
    }

    // ───────────── toolbar ─────────────
    Rectangle {
        id: toolbar
        anchors.top: head.bottom
        x: px(14); width: parent.width - px(28)
        height: ls.toolH
        radius: height / 2
        color: ls.cField
        Row {
            id: tbLeft
            anchors.left: parent.left; anchors.leftMargin: px(6)
            anchors.verticalCenter: parent.verticalCenter
            spacing: px(2)
            Rectangle {
                width: px(38); height: px(38); radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                color: playHov.hovered ? Qt.lighter(ls.cPri, 1.08) : ls.cPri
                Glyph { anchors.centerIn: parent; text: ls.playing ? "pause" : "play_arrow"; size: px(24); color: ls.cOnPri }
                HoverHandler { id: playHov; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: ls.togglePlay() }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: px(8); rightPadding: px(6)
                text: ls.fmtT(ls.playT) + "<font color='" + ls.css(ls.cMuted) + "'> / " + ls.fmtT(ls.audioCut ? ls.keptDur : ls.dur) + "</font>"
                textFormat: Text.StyledText
                font.family: ls.fB; font.pixelSize: px(13); font.weight: Font.DemiBold
                font.features: { "tnum": 1 }
                color: ls.cText
            }
            Btn {
                width: px(40); height: px(34)
                label: ls.rate === 1 ? "1×" : ls.rate === 0.75 ? "¾×" : "½×"
                active: ls.rate !== 1
                tip: ls.tx("Velocidad de reproducción (para sincronizar con calma)", "Playback speed (to sync calmly)")
                onClicked: ls.cycleRate()
            }
            Sep {}
            Btn { glyph: "arrow_selector_tool"; active: ls.tool === "select"; tip: ls.tx("Seleccionar y mover (V)", "Select and move (V)"); onClicked: ls.tool = "select" }
            Btn { glyph: "content_cut"; active: ls.tool === "razor"; tip: ls.tx("Tijera: clic en la letra divide el bloque, en el audio lo corta (C)", "Razor: click lyrics to split a block, audio to cut it (C)"); onClicked: ls.tool = ls.tool === "razor" ? "select" : "razor" }
            Btn { glyph: "align_horizontal_center"; active: ls.magnet; tip: ls.tx("Imán: pegar al cursor y a los bordes (M · Mayús lo desactiva al arrastrar)", "Magnet: snap to playhead and edges (M · hold Shift to disable)"); onClicked: ls.magnet = !ls.magnet }
            Btn { glyph: "width"; active: ls.stretchMode; tip: ls.tx("Estirar: los bordes de un bloque estiran sus tiempos en vez de recortar (o Alt al arrastrar)", "Stretch: block edges scale its timing instead of trimming (or hold Alt)"); onClicked: ls.stretchMode = !ls.stretchMode }
            Sep {}
            Btn { glyph: "vertical_split"; tip: ls.tx("Dividir el bloque en el cursor (S)", "Split block at playhead (S)"); enabled: ls.blocks.length > 0; onClicked: ls.splitAtTime(ls.playT) }
            Btn { glyph: "join"; tip: ls.tx("Unir bloques seleccionados / con el siguiente (J)", "Join selected blocks / with next (J)"); enabled: ls.blocks.length > 1; onClicked: ls.joinBlocks() }
            Btn { glyph: "my_location"; tip: ls.tx("La línea elegida empieza en el cursor y lo que sigue se mueve con ella (T · Mayús+T solo esa línea)", "Selected line starts at playhead, everything after follows (T · Shift+T only that line)"); enabled: ls.blocks.length > 0; onClicked: ls.markHere(true) }
            Btn { glyph: "playlist_add"; tip: ls.tx("Línea nueva en el cursor (N)", "New line at playhead (N)"); onClicked: ls.addLineAt(ls.playT) }
            Btn { glyph: "cut"; tip: ls.tx("Cortar el audio en el cursor (X)", "Cut audio at playhead (X)"); enabled: !ls.waveErr; onClicked: ls.cutAudioAt(ls.playT) }
            Btn { glyph: "delete"; danger: true; tip: ls.tx("Borrar selección / quitar tramo de audio (Supr)", "Delete selection / remove audio part (Del)"); onClicked: ls.deleteSel() }
        }
        Row {
            anchors.right: parent.right; anchors.rightMargin: px(6)
            anchors.verticalCenter: parent.verticalCenter
            spacing: px(2)
            visible: toolbar.width - tbLeft.width > width + px(20)
            Btn { glyph: "zoom_out"; tip: ls.tx("Alejar (−)", "Zoom out (−)"); onClicked: ls.zoomAt(1 / 1.5, ls.viewW / 2) }
            Btn { glyph: "zoom_in"; tip: ls.tx("Acercar (+ · Ctrl+rueda)", "Zoom in (+ · Ctrl+wheel)"); onClicked: ls.zoomAt(1.5, ls.t2x(ls.playT) > 0 && ls.t2x(ls.playT) < ls.viewW ? ls.t2x(ls.playT) : ls.viewW / 2) }
            Btn { glyph: "fit_width"; tip: ls.tx("Ver toda la canción (0)", "Fit whole song (0)"); onClicked: ls.fit() }
            Btn { glyph: "follow_the_signs"; active: ls.follow; tip: ls.tx("Seguir el cursor al reproducir", "Follow playhead while playing"); onClicked: ls.follow = !ls.follow }
        }
    }

    // ───────────── timeline ─────────────
    Rectangle {
        id: tl
        anchors.top: toolbar.bottom; anchors.topMargin: px(10)
        x: px(14); width: parent.width - px(28)
        height: ls.rulerH + ls.trackH * 2 + px(8) + ls.ovH + px(8)
        radius: px(18)
        color: ls.light ? Qt.rgba(0, 0, 0, 0.035) : Qt.rgba(0, 0, 0, 0.2)
        border.width: 1; border.color: ls.cLine
        clip: true

        // track headers (left)
        Item {
            id: hdrs
            x: 0; y: ls.rulerH
            width: ls.hdrW; height: ls.trackH * 2 + px(8)

            // audio
            Item {
                width: parent.width; height: ls.trackH
                Column {
                    x: px(14); width: parent.width - px(22)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: px(3)
                    Row {
                        spacing: px(6)
                        Glyph { text: "graphic_eq"; size: px(17); color: ls.cPri; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: ls.tx("Audio", "Audio"); font.family: ls.fA; font.pixelSize: px(13); font.weight: Font.DemiBold; color: ls.cText; anchors.verticalCenter: parent.verticalCenter }
                    }
                    Text {
                        width: parent.width; elide: Text.ElideRight
                        text: !ls.info ? "" : [ls.info.format, ls.info.bitrate ? ls.info.bitrate + " kbps" : "", ls.fmtT(ls.dur, false)].filter(Boolean).join(" · ")
                        font.family: ls.fB; font.pixelSize: px(10.5); color: ls.cMuted
                    }
                    Text {
                        width: parent.width; elide: Text.ElideRight
                        visible: ls.audioCut
                        text: "✂ " + ls.fmtT(ls.keptDur, false) + "  (−" + (ls.dur - ls.keptDur).toFixed(1) + " s)"
                        font.family: ls.fB; font.pixelSize: px(10.5); font.weight: Font.DemiBold; color: ls.cTer
                    }
                    Pill {
                        visible: ls.audioCut || ls.segs.length > 1
                        small: true; glyph: "restart_alt"; label: ls.tx("Restaurar", "Restore")
                        tip: ls.tx("Deshacer todos los cortes del audio", "Undo all audio cuts")
                        onClicked: ls.restoreAudio()
                    }
                }
            }
            Rectangle { y: ls.trackH + px(3); x: px(10); width: parent.width - px(20); height: 1; color: ls.cLine }
            // lyrics
            Item {
                y: ls.trackH + px(8)
                width: parent.width; height: ls.trackH
                Column {
                    x: px(14); width: parent.width - px(22)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: px(4)
                    Row {
                        spacing: px(6)
                        Glyph { text: "lyrics"; size: px(17); color: ls.cPri; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: ls.tx("Letra", "Lyrics"); font.family: ls.fA; font.pixelSize: px(13); font.weight: Font.DemiBold; color: ls.cText; anchors.verticalCenter: parent.verticalCenter }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: ls.lineCount + " · " + ls.blocks.length + " " + ls.tx("bloq.", "blk.")
                            font.family: ls.fB; font.pixelSize: px(10); color: ls.cMuted
                        }
                    }
                    // handle to drag ALL the lyrics
                    Rectangle {
                        id: grip
                        width: parent.width; height: px(30)
                        radius: height / 2
                        visible: ls.blocks.length > 0
                        color: gripMa.pressed ? ls.cPri : ls.ga(ls.cPri, gripMa.containsMouse ? 0.26 : 0.15)
                        border.width: 1; border.color: ls.ga(ls.cPri, 0.4)
                        Behavior on color { ColorAnimation { duration: 140 } }
                        Row {
                            anchors.centerIn: parent
                            spacing: px(5)
                            Glyph { text: "swap_horiz"; size: px(17); color: gripMa.pressed ? ls.cOnPri : ls.cPri; anchors.verticalCenter: parent.verticalCenter }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: gripMa.pressed || Math.abs(ls.shownOffset) > 0.004 ? ls.fmtOff(ls.shownOffset) : ls.tx("Mover todo", "Move all")
                                font.family: ls.fB; font.pixelSize: px(11.5); font.weight: Font.DemiBold
                                font.features: { "tnum": 1 }
                                color: gripMa.pressed ? ls.cOnPri : ls.cPri
                            }
                        }
                        MouseArea {
                            id: gripMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: pressed ? Qt.ClosedHandCursor : Qt.SizeHorCursor
                            preventStealing: true
                            onContainsMouseChanged: { if (containsMouse) ls.mp.showTip(ls.tx("Arrastra a los lados para mover toda la letra a la vez", "Drag sideways to move all the lyrics at once"), grip); else ls.mp.hideTip(grip); }
                            onPressed: (m) => {
                                ls.forceActiveFocus(); ls.mp.hideTip(grip);
                                var all = ls.allSet();
                                var prev = Object.assign({}, ls.sel);
                                ls.selectAll();
                                ls.dragSt = { kind: "move", set: all, grab: ls.blocks[0].id, i: 0, x0: m.x, base: ls.clone(ls.blocks), before: ls.stateStr(), moved: false, grip: true, all: true, prevSel: prev };
                            }
                            onPositionChanged: (m) => { if (pressed) ls.lyrMove({ x: m.x, modifiers: m.modifiers }); }
                            onReleased: { ls.lyrRelease(); }
                        }
                    }
                    Row {
                        spacing: px(3)
                        visible: ls.blocks.length > 0
                        Repeater {
                            model: [-0.5, -0.1, 0.1, 0.5]
                            delegate: Rectangle {
                                required property var modelData
                                width: (grip.width - px(9)) / 4; height: px(22); radius: px(11)
                                color: nudHov.hovered ? ls.ga(ls.cVar, 0.18) : ls.ga(ls.cVar, 0.09)
                                Text {
                                    anchors.centerIn: parent
                                    text: (modelData > 0 ? "+" : "−") + Math.abs(modelData)
                                    font.family: ls.fB; font.pixelSize: px(10.5); font.weight: Font.DemiBold
                                    color: ls.cVar
                                }
                                HoverHandler { id: nudHov; cursorShape: Qt.PointingHandCursor }
                                TapHandler { onTapped: ls.nudge(modelData, true) }
                            }
                        }
                    }
                }
            }
        }
        Rectangle { x: ls.hdrW - 1; y: 0; width: 1; height: ls.rulerH + ls.trackH * 2 + px(8); color: ls.cLine }

        // tracks area
        Item {
            id: lane
            x: ls.hdrW; y: 0
            width: tl.width - ls.hdrW - px(6)
            height: ls.rulerH + ls.trackH * 2 + px(8)
            clip: true
            onWidthChanged: ls.viewW = width
            Component.onCompleted: ls.viewW = width

            // ── ruler ──
            Canvas {
                id: ruler
                width: parent.width; height: ls.rulerH
                property color c1: ls.cVar
                onC1Changed: requestPaint()
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    if (ls.dur <= 0) return;
                    var steps = [0.1, 0.2, 0.5, 1, 2, 5, 10, 15, 30, 60, 120];
                    var major = steps[steps.length - 1];
                    for (var i = 0; i < steps.length; i++) if (steps[i] * ls.pps >= ls.px(70)) { major = steps[i]; break; }
                    var minor = major / (major === 15 ? 3 : (major === 2 || major === 0.2 || major === 120 ? 4 : 5));
                    var t0 = Math.max(0, Math.floor(ls.x2t(0) / minor) * minor), t1 = Math.min(ls.dur, ls.x2t(width));
                    ctx.font = Math.round(ls.px(10)) + "px sans-serif";
                    for (var t = t0; t <= t1 + 1e-6; t += minor) {
                        var x = Math.round(ls.t2x(t)) + 0.5;
                        var isMaj = Math.abs(t / major - Math.round(t / major)) < 1e-4;
                        ctx.fillStyle = ls.css(c1, isMaj ? 0.55 : 0.22);
                        ctx.fillRect(x, height - (isMaj ? ls.px(9) : ls.px(5)), 1, isMaj ? ls.px(9) : ls.px(5));
                        if (isMaj) {
                            ctx.fillStyle = ls.css(c1, 0.75);
                            var lbl = major < 1 ? ls.fmtT(t).replace(/0$/, "") : ls.fmtT(t, false);
                            ctx.fillText(lbl, x + 3, height - ls.px(12));
                        }
                    }
                }
                Connections { target: ls; function onPpsChanged() { ruler.requestPaint(); } function onScrollXChanged() { ruler.requestPaint(); } function onDurChanged() { ruler.requestPaint(); } }
                onWidthChanged: requestPaint()
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    preventStealing: true
                    onPressed: (m) => { ls.forceActiveFocus(); ls.scrubbing = true; ls.seek(ls.x2t(m.x)); }
                    onPositionChanged: (m) => { if (pressed) { ls.seek(ls.x2t(m.x)); ls.edgeScroll(m.x); } }
                    onReleased: ls.scrubbing = false
                }
            }

            // ── audio track ──
            Item {
                id: audTrack
                y: ls.rulerH
                width: parent.width; height: ls.trackH

                Canvas {
                    id: wave
                    anchors.fill: parent
                    property color cOn: ls.cPri
                    property color cOff: ls.cMuted
                    onCOnChanged: requestPaint()
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        var W = width, H = height, mid = H / 2, amp = H / 2 - ls.px(10);
                        var P = ls.peaks, r = ls.peakRate, S = ls.segs;
                        if (!P.length) {
                            ctx.fillStyle = ls.css(cOn, 0.25);
                            var xa = Math.max(0, ls.t2x(0)), xb = Math.min(W, ls.t2x(ls.dur));
                            ctx.fillRect(xa, mid, Math.max(0, xb - xa), 1);
                            return;
                        }
                        var on = ls.css(cOn, 0.85), off = ls.css(cOff, 0.28);
                        var si = 0, cur = "";
                        for (var x = 0; x < W; x++) {
                            var ta = ls.x2t(x), tb = ls.x2t(x + 1);
                            if (tb < 0) continue;
                            if (ta > ls.dur) break;
                            var i0 = Math.max(0, Math.floor(ta * r)), i1 = Math.max(i0 + 1, Math.ceil(tb * r));
                            if (i0 >= P.length) break;
                            var m = 0;
                            for (var i = i0; i < i1 && i < P.length; i++) if (P[i] > m) m = P[i];
                            while (si < S.length - 1 && ta >= S[si].e) si++;
                            var st = S.length && !S[si].on ? off : on;
                            if (st !== cur) { ctx.fillStyle = st; cur = st; }
                            var h = Math.max(0.6, m * amp);
                            ctx.fillRect(x, mid - h, 1, h * 2);
                        }
                    }
                    Connections {
                        target: ls
                        function onPpsChanged() { wave.requestPaint(); }
                        function onScrollXChanged() { wave.requestPaint(); }
                        function onPeaksChanged() { wave.requestPaint(); }
                        function onSegsChanged() { wave.requestPaint(); }
                        function onDurChanged() { wave.requestPaint(); }
                    }
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                }
                // section frames
                Repeater {
                    model: ls.segs.length
                    delegate: Rectangle {
                        required property int index
                        readonly property var g: ls.segs[index] || ({ s: 0, e: 0, on: true })
                        readonly property bool sel: ls.selSeg === index
                        x: ls.t2x(g.s) + 1; width: Math.max(0, ls.t2x(g.e) - ls.t2x(g.s) - 2)
                        y: ls.px(4); height: parent.height - ls.px(8)
                        visible: x + width > -4 && x < audTrack.width + 4
                        radius: ls.px(10)
                        color: g.on ? (sel ? ls.ga(ls.cPri, 0.14) : ls.ga(ls.cPri, 0.05)) : Qt.rgba(0, 0, 0, ls.light ? 0.08 : 0.2)
                        border.width: sel ? 2 : 1
                        border.color: g.on ? ls.ga(ls.cPri, sel ? 0.9 : 0.35) : ls.ga(ls.cMuted, sel ? 0.8 : 0.35)
                        Row {
                            visible: !parent.g.on && parent.width > ls.px(60)
                            anchors.centerIn: parent
                            spacing: ls.px(4)
                            Glyph { text: "content_cut"; size: ls.px(14); color: ls.cMuted; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: ls.tx("quitado", "removed") + " · " + (parent.parent.g.e - parent.parent.g.s).toFixed(1) + " s"; font.family: ls.fB; font.pixelSize: ls.px(10.5); color: ls.cMuted; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }
                }
                // trim handles at the start and end
                Repeater {
                    model: 2
                    delegate: Rectangle {
                        required property int index
                        readonly property real tt: index === 0 ? 0 : ls.dur
                        readonly property bool show: ls.segs.length > 0 && (index === 0 ? ls.segs[0].on : ls.segs[ls.segs.length - 1].on)
                        visible: show
                        x: ls.t2x(tt) - (index === 0 ? 0 : width)
                        y: ls.px(4); width: ls.px(6); height: parent.height - ls.px(8)
                        radius: ls.px(3)
                        color: ls.ga(ls.cPri, 0.7)
                    }
                }
                Text {
                    anchors.centerIn: parent
                    visible: ls.waveLoading || ls.waveErr !== ""
                    text: ls.waveLoading ? ls.tx("Analizando el audio…", "Analyzing audio…") : "⚠ " + ls.waveErr
                    font.family: ls.fB; font.pixelSize: px(11.5)
                    color: ls.waveErr ? ls.cErr : ls.cMuted
                }
                MouseArea {
                    id: audMa
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    preventStealing: true
                    property int hk: 0
                    cursorShape: {
                        var _ = hk;
                        if (ls.tool === "razor") return Qt.SplitHCursor;
                        var h = ls.hitAud(mouseX);
                        return h.kind === "body" || h.kind === "none" ? Qt.IBeamCursor : Qt.SizeHorCursor;
                    }
                    onPressed: (m) => ls.audPress(m, audMa)
                    onPositionChanged: (m) => { if (pressed) ls.audMove(m); else hk++; }
                    onReleased: ls.audRelease()
                    onWheel: (w) => ls.wheel(w, w.x)
                }
            }
            Rectangle { y: ls.rulerH + ls.trackH + px(3); width: parent.width; height: 1; color: ls.cLine }

            // ── lyrics track ──
            Item {
                id: lyrTrack
                y: ls.rulerH + ls.trackH + px(8)
                width: parent.width; height: ls.trackH

                Repeater {
                    model: ls.blocks.length
                    delegate: Item {
                        id: blk
                        required property int index
                        readonly property var b: ls.blocks[index] || null
                        readonly property real x0: b ? ls.t2x(b.lines[0].t) : 0
                        readonly property real x1: b ? ls.t2x(b.end) : 0
                        readonly property bool sel: b ? ls.isSel(b.id) : false
                        readonly property bool hasFocus: b ? ls.focB === b.id : false
                        visible: !!b && x1 > -10 && x0 < lyrTrack.width + 10
                        x: x0; width: Math.max(3, x1 - x0)
                        y: ls.px(5); height: lyrTrack.height - ls.px(10)
                        Rectangle {
                            anchors.fill: parent
                            radius: ls.px(10)
                            color: blk.sel ? ls.ga(ls.cPri, 0.30) : ls.ga(ls.cPri, 0.14)
                            border.width: blk.sel ? 2 : 1
                            border.color: blk.sel ? ls.cPri : ls.ga(ls.cPri, 0.35)
                            clip: true
                            // lines
                            Repeater {
                                model: blk.b ? blk.b.lines.length : 0
                                delegate: Item {
                                    id: ln
                                    required property int index
                                    readonly property var l: blk.b ? blk.b.lines[index] : null
                                    readonly property real lx: l ? ls.t2x(l.t) - blk.x0 : 0
                                    readonly property real rx: blk.b ? ls.t2x(ls.lineEnd(blk.b, index)) - blk.x0 : 0
                                    readonly property bool foc: blk.hasFocus && ls.focI === index
                                    readonly property bool isNow: !!l && ls.playT >= l.t && ls.playT < (blk.b ? ls.lineEnd(blk.b, index) : 0)
                                    readonly property bool cut: { var _ = ls.segs; return !!l && !ls.segOnAt(l.t); }
                                    x: lx; width: Math.max(1, rx - lx); height: parent.height
                                    visible: rx > -2 && lx < blk.width + 2 && blk.x0 + lx < lyrTrack.width
                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.margins: 2
                                        radius: ls.px(7)
                                        visible: ln.foc || ln.cut
                                        color: ln.cut ? ls.ga(ls.cErr, 0.16) : ls.ga(ls.cPri, 0.28)
                                        border.width: ln.foc ? 1 : 0
                                        border.color: ls.ga(ls.cPri, 0.8)
                                    }
                                    Rectangle {
                                        visible: ln.index > 0
                                        x: 0; y: ls.px(6); width: 2; height: parent.height - ls.px(12)
                                        radius: 1
                                        color: ls.ga(ls.cPri, blk.sel ? 0.75 : 0.45)
                                    }
                                    Text {
                                        x: ls.px(6); y: ls.px(6)
                                        width: parent.width - ls.px(10); height: parent.height - ls.px(12)
                                        visible: width > ls.px(14)
                                        text: ln.l ? ln.l.s : ""
                                        wrapMode: width > ls.px(70) ? Text.WordWrap : Text.NoWrap
                                        maximumLineCount: Math.max(1, Math.floor(height / (font.pixelSize * 1.25)))
                                        elide: Text.ElideRight
                                        font.family: ls.fB; font.pixelSize: ls.px(11)
                                        font.weight: ln.isNow ? Font.Bold : Font.Medium
                                        color: ln.cut ? ls.cErr : ln.isNow ? ls.cText : ls.ga(ls.cText, 0.78)
                                    }
                                }
                            }
                        }
                        // edge handles (visible on the selection)
                        Rectangle { visible: blk.sel; x: 0; y: parent.height / 2 - height / 2; width: ls.px(4); height: Math.min(ls.px(26), parent.height - ls.px(10)); radius: 2; color: ls.cPri }
                        Rectangle { visible: blk.sel; x: parent.width - width; y: parent.height / 2 - height / 2; width: ls.px(4); height: Math.min(ls.px(26), parent.height - ls.px(10)); radius: 2; color: ls.cPri }
                    }
                }
                Column {
                    anchors.centerIn: parent
                    z: 2
                    visible: !ls.loading && ls.blocks.length === 0
                    spacing: px(8)
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: ls.tx("Esta canción no tiene letra", "This song has no lyrics")
                        font.family: ls.fB; font.pixelSize: px(12); color: ls.cMuted
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: px(6)
                        Pill { glyph: "travel_explore"; label: ls.tx("Buscar en LRCLIB", "Search LRCLIB"); primary: true; onClicked: ls.fetchOnline() }
                        Pill { glyph: "upload_file"; label: ls.tx("Importar .lrc", "Import .lrc"); onClicked: ls.importFile() }
                    }
                }
                MouseArea {
                    id: lyrMa
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    preventStealing: true
                    property int hk: 0
                    cursorShape: { var _ = hk + ls.blocks.length; return ls.lyrCursor(ls.hitLyr(mouseX), pressed); }
                    onPressed: (m) => ls.lyrPress(m, lyrMa)
                    onPositionChanged: (m) => { if (pressed) ls.lyrMove(m); else hk++; }
                    onReleased: ls.lyrRelease()
                    onDoubleClicked: (m) => { if (ls.hitLyr(m.x).kind === "body") { lineText.input.forceActiveFocus(); lineText.input.selectAll(); } }
                    onWheel: (w) => ls.wheel(w, w.x)
                }
            }

            // removed sections: shading over the lyrics
            Repeater {
                model: ls.segs.length
                delegate: Rectangle {
                    required property int index
                    readonly property var g: ls.segs[index] || ({ s: 0, e: 0, on: true })
                    visible: !g.on
                    x: ls.t2x(g.s); width: ls.t2x(g.e) - ls.t2x(g.s)
                    y: lyrTrack.y; height: lyrTrack.height
                    color: ls.ga(ls.cSurf, 0.55)
                    border.width: 0
                }
            }

            // magnet guide
            Rectangle {
                visible: ls.snapGuide >= 0
                x: Math.round(ls.t2x(ls.snapGuide)); y: ls.rulerH
                width: 1; height: parent.height - ls.rulerH
                color: ls.cTer
            }
            // playhead
            Item {
                id: playhead
                x: Math.round(ls.t2x(ls.playT)); y: 0
                visible: x > -8 && x < lane.width + 8
                width: 1; height: parent.height
                Rectangle { x: 0; y: ls.px(10); width: 2; height: parent.height - ls.px(10); color: ls.cTer }
                Rectangle {
                    x: -ls.px(6) + 1; y: ls.px(2)
                    width: ls.px(12); height: ls.px(12); radius: ls.px(3)
                    rotation: 45
                    color: ls.cTer
                }
            }
        }

        // ── overview (minimap / scrollbar) ──
        Item {
            id: ovBox
            x: px(10); y: ls.rulerH + ls.trackH * 2 + px(8) + px(4)
            width: tl.width - px(20); height: ls.ovH
            Canvas {
                id: ov
                anchors.fill: parent
                property color c1: ls.cPri
                property color c2: ls.cVar
                onC1Changed: requestPaint()
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    var W = width, H = height, D = ls.dur;
                    if (D <= 0) return;
                    var k = W / D, P = ls.peaks, r = ls.peakRate, S = ls.segs;
                    var wh = H * 0.55, mid = wh / 2 + 1;
                    ctx.fillStyle = ls.css(c2, 0.35);
                    if (P.length) {
                        for (var x = 0; x < W; x++) {
                            var i0 = Math.floor(x / k * r), i1 = Math.max(i0 + 1, Math.floor((x + 1) / k * r)), m = 0;
                            for (var i = i0; i < i1 && i < P.length; i++) if (P[i] > m) m = P[i];
                            var h = Math.max(0.5, m * wh / 2);
                            ctx.fillRect(x, mid - h, 1, h * 2);
                        }
                    }
                    for (i = 0; i < S.length; i++) if (!S[i].on) { ctx.fillStyle = "rgba(0,0,0,0.35)"; ctx.fillRect(S[i].s * k, 0, (S[i].e - S[i].s) * k, H); }
                    ctx.fillStyle = ls.css(c1, 0.7);
                    var B = ls.blocks;
                    for (i = 0; i < B.length; i++) {
                        var bx = B[i].lines[0].t * k, bw = Math.max(1.5, (B[i].end - B[i].lines[0].t) * k - 1);
                        ctx.fillRect(bx, H * 0.66, bw, H * 0.24);
                    }
                    var vx = ls.scrollX / ls.pps * k, vw = Math.min(W, ls.viewW / ls.pps * k);
                    ctx.strokeStyle = ls.css(c1, 0.9);
                    ctx.lineWidth = 1.5;
                    ctx.strokeRect(Math.max(0.75, vx), 0.75, Math.min(vw, W - 1.5), H - 1.5);
                    ctx.fillStyle = ls.css(c1, 0.08);
                    ctx.fillRect(vx, 0, vw, H);
                }
                Connections {
                    target: ls
                    function onPpsChanged() { ov.requestPaint(); }
                    function onScrollXChanged() { ov.requestPaint(); }
                    function onPeaksChanged() { ov.requestPaint(); }
                    function onSegsChanged() { ov.requestPaint(); }
                    function onBlocksChanged() { ov.requestPaint(); }
                    function onViewWChanged() { ov.requestPaint(); }
                }
                onWidthChanged: requestPaint()
            }
            Rectangle {
                x: ls.dur > 0 ? Math.round(ls.playT / ls.dur * ov.width) : 0
                width: 2; height: parent.height
                color: ls.cTer
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                preventStealing: true
                function go(x) { if (ls.dur > 0) ls.scrollX = ls.clampScroll(x / width * ls.dur * ls.pps - ls.viewW / 2); }
                onPressed: (m) => { ls.forceActiveFocus(); go(m.x); }
                onPositionChanged: (m) => { if (pressed) go(m.x); }
                onDoubleClicked: (m) => ls.seek(m.x / width * ls.dur)
                onWheel: (w) => ls.wheel(w, ls.viewW / 2)
            }
        }
        Text {
            anchors.centerIn: parent
            visible: ls.loading
            text: ls.tx("Cargando…", "Loading…")
            font.family: ls.fB; font.pixelSize: px(13); color: ls.cMuted
        }
    }
    function wheel(w, x) {
        var ctrl = w.modifiers & Qt.ControlModifier;
        var dy = w.angleDelta.y, dx = w.angleDelta.x;
        if (ctrl) {
            if (dy !== 0) zoomAt(Math.pow(1.0018, dy), x);
        } else {
            var d = 0;
            if (w.pixelDelta.x !== 0 || w.pixelDelta.y !== 0) d = -(Math.abs(w.pixelDelta.x) > Math.abs(w.pixelDelta.y) ? w.pixelDelta.x : w.pixelDelta.y) * 1.5;
            else d = -(Math.abs(dx) > Math.abs(dy) ? dx : dy) / 120 * px(90);
            scrollX = clampScroll(scrollX + d);
        }
        w.accepted = true;
    }

    // ── tips ──
    Text {
        id: hint
        anchors.top: tl.bottom; anchors.topMargin: px(6)
        x: px(24); width: parent.width - px(48)
        elide: Text.ElideRight
        text: ls.note !== "" ? "ⓘ  " + ls.note
            : ls.tool === "razor" ? ls.tx("Tijera: clic en un bloque de letra lo divide en la línea más cercana · clic en el audio lo corta · Esc vuelve a seleccionar",
                                          "Razor: click a lyric block to split it at the nearest line · click the audio to cut it · Esc to go back")
            : ls.tx("Arrastra un bloque para moverlo · sus bordes lo recortan (Alt estira) · los separadores ajustan cada línea · Ctrl+arrastrar o «Mover todo» mueve toda la letra · T marca la línea en el cursor",
                    "Drag a block to move it · its edges trim it (Alt stretches) · separators adjust each line · Ctrl+drag or “Move all” moves all lyrics · T stamps the line at the playhead")
        font.family: ls.fB; font.pixelSize: px(11)
        color: ls.note !== "" ? ls.cTer : ls.cMuted
    }

    // ───────────── bottom: preview + selected line ─────────────
    Item {
        id: lower
        anchors.top: hint.bottom; anchors.topMargin: px(8)
        anchors.bottom: foot.top; anchors.bottomMargin: px(6)
        x: px(14); width: parent.width - px(28)

        // karaoke-style preview
        Rectangle {
            id: preview
            width: Math.round(parent.width * 0.42) - px(5); height: parent.height
            radius: px(18)
            color: ls.cField
            clip: true
            readonly property int ci: {
                var F = ls.flat, t = ls.playT, a = -1;
                for (var i = 0; i < F.length; i++) { if (F[i].t <= t) a = i; else break; }
                return a;
            }
            readonly property bool gap: ci >= 0 && ls.flat[ci] && ls.playT >= ls.flat[ci].e
            Column {
                anchors.centerIn: parent
                width: parent.width - px(32)
                spacing: px(6)
                Text {
                    width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                    text: preview.ci >= 1 && !preview.gap ? ls.flat[preview.ci - 1].s : (preview.ci >= 0 && preview.gap ? ls.flat[preview.ci].s : "")
                    font.family: ls.fB; font.pixelSize: px(12); color: ls.ga(ls.cVar, 0.5)
                }
                Text {
                    width: parent.width; horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight
                    text: preview.ci >= 0 && !preview.gap ? ls.flat[preview.ci].s : "♪"
                    font.family: ls.fA; font.pixelSize: px(20); font.weight: Font.Bold
                    color: ls.cPri
                }
                Text {
                    width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                    text: preview.ci + 1 < ls.flat.length ? ls.flat[preview.ci + 1].s : ""
                    font.family: ls.fB; font.pixelSize: px(12); color: ls.ga(ls.cVar, 0.7)
                }
            }
            Text {
                x: px(14); y: px(10)
                text: ls.tx("Vista previa", "Preview")
                font.family: ls.fB; font.pixelSize: px(10); font.weight: Font.DemiBold
                color: ls.cMuted
            }
        }

        // line inspector
        Rectangle {
            id: insp
            x: preview.width + px(10); width: parent.width - x; height: parent.height
            radius: px(18)
            color: ls.cField
            readonly property var fl: { var _ = ls.focRev + ls.ver; return ls.focusLine(); }
            Column {
                x: px(14); y: px(10)
                width: parent.width - px(28)
                spacing: px(8)
                visible: !!insp.fl
                Row {
                    width: parent.width
                    spacing: px(6)
                    Text {
                        id: inspTitle
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - px(70)
                        elide: Text.ElideRight
                        text: {
                            var f = insp.fl; if (!f) return "";
                            var n = 0; for (var i = 0; i < f.bi; i++) n += ls.blocks[i].lines.length;
                            return ls.tx("Línea ", "Line ") + (n + f.k + 1) + ls.tx(" de ", " of ") + ls.lineCount + "  ·  " + ls.tx("bloque ", "block ") + (f.bi + 1)
                                   + (!ls.segOnAt(f.l.t) ? "  ·  " + ls.tx("en una parte quitada", "in a removed part") : "");
                        }
                        font.family: ls.fB; font.pixelSize: px(10.5); font.weight: Font.DemiBold
                        color: insp.fl && !ls.segOnAt(insp.fl.l.t) ? ls.cErr : ls.cMuted
                    }
                    Btn { small: true; glyph: "keyboard_arrow_up"; tip: ls.tx("Línea anterior (↑)", "Previous line (↑)"); onClicked: ls.stepFocus(-1) }
                    Btn { small: true; glyph: "keyboard_arrow_down"; tip: ls.tx("Línea siguiente (↓)", "Next line (↓)"); onClicked: ls.stepFocus(1) }
                }
                Rectangle {
                    id: lineText
                    property alias input: lti
                    width: parent.width; height: px(34)
                    radius: height / 2
                    color: ls.ga(ls.cVar, 0.08)
                    border.width: lti.activeFocus ? 1 : 0
                    border.color: ls.ga(ls.cPri, 0.6)
                    TextInput {
                        id: lti
                        anchors.left: parent.left; anchors.leftMargin: px(14)
                        anchors.right: parent.right; anchors.rightMargin: px(14)
                        anchors.verticalCenter: parent.verticalCenter
                        clip: true
                        color: ls.cText
                        font.family: ls.fB; font.pixelSize: px(13)
                        selectByMouse: true
                        selectionColor: ls.ga(ls.cPri, 0.45)
                        selectedTextColor: ls.cText
                        property bool loading: false
                        onTextEdited: if (!loading) ls.setLineText(text)
                        onAccepted: { ls.forceActiveFocus(); }
                        Keys.onEscapePressed: (e) => { ls.forceActiveFocus(); e.accepted = true; }
                        Keys.onUpPressed: (e) => { ls.stepFocus(-1); e.accepted = true; }
                        Keys.onDownPressed: (e) => { ls.stepFocus(1); e.accepted = true; }
                        function reload() { var f = ls.focusLine(); loading = true; text = f ? f.l.s : ""; loading = false; }
                        Connections { target: ls; function onFocRevChanged() { lti.reload(); } function onBlocksChanged() { if (!lti.activeFocus) lti.reload(); } }
                    }
                }
                Item {
                  width: parent.width; height: px(30)
                  Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: px(4)
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: ls.tx("Inicio", "Start")
                        font.family: ls.fB; font.pixelSize: px(11); color: ls.cMuted
                    }
                    Btn { small: true; glyph: "remove"; tip: ls.tx("−50 ms (solo esta línea)", "−50 ms (this line only)"); onClicked: { var f = insp.fl; if (f) ls.setLineTime(f.b.id, f.k, f.l.t - 0.05, false); } }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: px(64); horizontalAlignment: Text.AlignHCenter
                        text: insp.fl ? ls.fmtT(insp.fl.l.t) : ""
                        font.family: ls.fB; font.pixelSize: px(13); font.weight: Font.DemiBold
                        font.features: { "tnum": 1 }
                        color: ls.cText
                    }
                    Btn { small: true; glyph: "add"; tip: ls.tx("+50 ms (solo esta línea)", "+50 ms (this line only)"); onClicked: { var f = insp.fl; if (f) ls.setLineTime(f.b.id, f.k, f.l.t + 0.05, false); } }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        leftPadding: px(6)
                        text: insp.fl ? "· " + (ls.lineEnd(insp.fl.b, insp.fl.k) - insp.fl.l.t).toFixed(2) + " s" : ""
                        font.family: ls.fB; font.pixelSize: px(11); color: ls.cMuted
                    }
                  }
                  Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: px(2)
                    Pill {
                        anchors.verticalCenter: parent.verticalCenter
                        small: true; glyph: "my_location"; label: ls.tx("Marcar (T)", "Stamp (T)"); primary: true
                        tip: ls.tx("Esta línea empieza donde está el cursor y todo lo que sigue se mueve con ella", "This line starts at the playhead and everything after follows")
                        onClicked: ls.markHere(true)
                    }
                    Item { width: px(4); height: 1 }
                    Btn { small: true; glyph: "play_arrow"; tip: ls.tx("Escuchar desde un segundo antes", "Listen from one second before"); onClicked: { if (insp.fl) { ls.seek(Math.max(0, insp.fl.l.t - 1)); if (!ls.playing) ls.togglePlay(); } } }
                    Btn { small: true; glyph: "call_split"; tip: ls.tx("Partir el texto en dos donde está el cursor del texto", "Split the text in two at the text cursor"); onClicked: ls.splitLineText(lti.cursorPosition) }
                    Btn { small: true; glyph: "delete"; danger: true; tip: ls.tx("Borrar esta línea (Mayús+Supr)", "Delete this line (Shift+Del)"); onClicked: ls.deleteFocusLine() }
                  }
                }
            }
            Text {
                anchors.centerIn: parent
                width: parent.width - px(40)
                visible: !insp.fl
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: ls.tx("Haz clic en una línea de la pista de letra para editar su texto y su tiempo",
                            "Click a line in the lyrics track to edit its text and timing")
                font.family: ls.fB; font.pixelSize: px(12); color: ls.cMuted
            }
        }
    }

    // ───────────── footer: where to save + save ─────────────
    Item {
        id: foot
        anchors.bottom: parent.bottom
        x: px(20); width: parent.width - px(40)
        height: ls.footH
        Row {
            id: footLeft
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: px(10)
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: ls.tx("Guardar letra en", "Save lyrics to")
                font.family: ls.fB; font.pixelSize: px(11.5); color: ls.cVar
            }
            MiniSeg {
                anchors.verticalCenter: parent.verticalCenter
                current: ls.target
                options: [
                    { value: "tag", label: ls.tx("Archivo", "File"), tip: ls.tx("Integrada en la canción (etiqueta de letra). Si hay un .lrc al lado, se borra para que no quede desfasado", "Embedded in the song (lyrics tag). A .lrc next to it is deleted so it doesn't stay out of sync") },
                    { value: "lrc", label: ".lrc", tip: ls.tx("Archivo .lrc al lado de la canción (quita la letra integrada para que no lo tape)", ".lrc file next to the song (clears the embedded lyrics so they don't override it)") },
                    { value: "both", label: ls.tx("Ambos", "Both"), tip: ls.tx("Integrada y .lrc", "Embedded and .lrc") }
                ]
                onPicked: (v) => ls.target = v
            }
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: px(6)
                visible: ls.audioCut
                Sw { anchors.verticalCenter: parent.verticalCenter; checked: ls.backup; onToggled: ls.backup = !ls.backup }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: ls.tx("Copia del original (.bak)", "Backup original (.bak)")
                    font.family: ls.fB; font.pixelSize: px(11.5); color: ls.cVar
                }
            }
        }
        Text {
            anchors.left: footLeft.right; anchors.leftMargin: px(14)
            anchors.right: footBtns.left; anchors.rightMargin: px(12)
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            text: ls.cutLines > 0 ? "⚠ " + ls.cutLines + ls.tx(" líneas caen en partes quitadas y se borrarán", " lines fall in removed parts and will be dropped")
                : ls.info && ls.info.writable === false ? ls.tx("Solo lectura", "Read-only")
                : ls.audioCut ? ls.tx("El audio se reescribirá recortado y la letra se ajustará sola", "The audio will be rewritten trimmed and the lyrics will follow")
                : ""
            font.family: ls.fB; font.pixelSize: px(11)
            color: ls.cutLines > 0 || (ls.info && ls.info.writable === false) ? ls.cErr : ls.cMuted
        }
        Row {
            id: footBtns
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: px(8)
            Pill { label: ls.dirty ? ls.tx("Descartar", "Discard") : ls.tx("Cerrar", "Close"); enabled: !ls.saving; onClicked: ls.requestClose() }
            Pill {
                glyph: ls.saving ? "hourglass_top" : "save"
                label: ls.saving ? ls.tx("Guardando…", "Saving…") : ls.tx("Guardar", "Save")
                primary: true
                enabled: !ls.saving && !ls.loading && (ls.dirty || ls.target === "both" && !(ls.hasTag && ls.hasLrc) || ls.target === "lrc" && !ls.hasLrc || ls.target === "tag" && !ls.hasTag && ls.blocks.length > 0)
                tip: "Ctrl+S"
                onClicked: ls.save()
            }
        }
    }

    // ───────────── confirmation ─────────────
    Rectangle {
        anchors.fill: parent
        visible: ls.confirmKind !== ""
        color: Qt.rgba(0, 0, 0, ls.light ? 0.25 : 0.5)
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onWheel: (w) => {}; onClicked: ls.confirmKind = "" }
        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width - px(48), px(420))
            height: cfCol.implicitHeight + px(44)
            radius: 26
            color: ls.cPop
            border.width: 1; border.color: ls.cLine
            MouseArea { anchors.fill: parent }
            Column {
                id: cfCol
                x: px(22); y: px(22); width: parent.width - px(44)
                spacing: px(14)
                Text {
                    width: parent.width; wrapMode: Text.WordWrap
                    text: ls.tx("¿Descartar los cambios?", "Discard changes?")
                    font.family: ls.fA; font.pixelSize: px(16); font.weight: Font.DemiBold; color: ls.cText
                }
                Text {
                    width: parent.width; wrapMode: Text.WordWrap
                    text: ls.confirmKind === "source" ? ls.tx("Al cambiar de fuente se pierde lo que no hayas guardado.", "Switching source loses what you haven't saved.")
                                                      : ls.tx("Hay cambios sin guardar en la letra o en el audio.", "There are unsaved changes to the lyrics or audio.")
                    font.family: ls.fB; font.pixelSize: px(12); color: ls.cVar
                }
                Row {
                    anchors.right: parent.right
                    spacing: px(8)
                    Pill { label: ls.tx("Seguir editando", "Keep editing"); onClicked: { ls.confirmKind = ""; ls.forceActiveFocus(); } }
                    Pill { label: ls.tx("Descartar", "Discard"); primary: true; danger: true; onClicked: ls.confirmYes() }
                }
            }
        }
    }

    // ══ Components ══
    component Glyph: Text {
        property real size: 18
        font.family: "Material Symbols Rounded"
        font.pixelSize: size
        color: ls.cVar
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }
    component Sep: Item {
        width: ls.px(13); height: ls.px(22)
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        Rectangle { anchors.centerIn: parent; width: 1; height: parent.height; color: ls.cLine }
    }
    component Btn: Rectangle {
        id: bt
        property string glyph: ""
        property string label: ""
        property string tip: ""
        property bool active: false
        property bool danger: false
        property bool small: false
        signal clicked()
        width: small ? ls.px(28) : ls.px(34)
        height: width
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        radius: Math.min(ls.px(10), height / 2)
        opacity: enabled ? 1 : 0.35
        color: active ? ls.ga(ls.cPri, 0.2) : (btHov.hovered ? (danger ? ls.ga(ls.cErr, 0.16) : ls.ga(ls.cVar, 0.12)) : "transparent")
        Behavior on color { ColorAnimation { duration: 140 } }
        Glyph {
            anchors.centerIn: parent
            visible: bt.glyph !== ""
            text: bt.glyph
            size: bt.small ? ls.px(17) : ls.px(19)
            color: bt.active ? ls.cPri : (bt.danger && btHov.hovered ? ls.cErr : ls.cVar)
        }
        Text {
            anchors.centerIn: parent
            visible: bt.glyph === ""
            text: bt.label
            font.family: ls.fB; font.pixelSize: ls.px(12); font.weight: Font.DemiBold
            color: bt.active ? ls.cPri : ls.cVar
        }
        HoverHandler {
            id: btHov
            cursorShape: Qt.PointingHandCursor
            onHoveredChanged: { if (!ls.mp) return; if (hovered && bt.tip !== "") ls.mp.showTip(bt.tip, bt); else ls.mp.hideTip(bt); }
        }
        MouseArea { anchors.fill: parent; onClicked: { if (ls.mp) ls.mp.hideTip(bt); bt.clicked(); ls.forceActiveFocus(); } }
    }
    component Pill: Rectangle {
        id: pl
        property string glyph: ""
        property string label: ""
        property string tip: ""
        property bool primary: false
        property bool danger: false
        property bool small: false
        signal clicked()
        height: small ? ls.px(28) : ls.px(32)
        width: plRow.width + (small ? ls.px(22) : ls.px(28))
        radius: height / 2
        opacity: enabled ? 1 : 0.4
        readonly property color base: danger ? ls.cErr : ls.cPri
        color: primary ? (plHov.hovered ? Qt.lighter(base, 1.08) : base) : (plHov.hovered ? ls.ga(base, 0.22) : ls.ga(base, 0.12))
        Behavior on color { ColorAnimation { duration: 140 } }
        scale: plMa.pressed ? 0.96 : 1
        Behavior on scale { NumberAnimation { duration: 110 } }
        Row {
            id: plRow
            anchors.centerIn: parent
            spacing: ls.px(5)
            Glyph {
                visible: pl.glyph !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: pl.glyph
                size: pl.small ? ls.px(15) : ls.px(16)
                color: pl.primary ? (pl.danger ? Qt.darker(ls.cErr, 3) : ls.cOnPri) : pl.base
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: pl.label
                font.family: ls.fB; font.pixelSize: pl.small ? ls.px(11.5) : ls.px(12.5); font.weight: Font.DemiBold
                color: pl.primary ? (pl.danger ? Qt.darker(ls.cErr, 3) : ls.cOnPri) : pl.base
            }
        }
        HoverHandler {
            id: plHov
            cursorShape: Qt.PointingHandCursor
            onHoveredChanged: { if (!ls.mp) return; if (hovered && pl.tip !== "") ls.mp.showTip(pl.tip, pl); else ls.mp.hideTip(pl); }
        }
        MouseArea { id: plMa; anchors.fill: parent; onClicked: { if (ls.mp) ls.mp.hideTip(pl); pl.clicked(); } }
    }
    component MiniSeg: Row {
        id: sg
        property var options: []
        property var current
        signal picked(var value)
        spacing: ls.px(3)
        Repeater {
            model: sg.options.length
            delegate: Rectangle {
                id: sc
                required property int index
                readonly property var opt: sg.options[index] || ({})
                readonly property bool sel: sg.current === opt.value
                width: scT.implicitWidth + ls.px(22); height: ls.px(30)
                topLeftRadius: index === 0 ? height / 2 : ls.px(6)
                bottomLeftRadius: index === 0 ? height / 2 : ls.px(6)
                topRightRadius: index === sg.options.length - 1 ? height / 2 : ls.px(6)
                bottomRightRadius: index === sg.options.length - 1 ? height / 2 : ls.px(6)
                color: sel ? ls.cPri : (scHov.hovered ? ls.ga(ls.cVar, 0.18) : ls.ga(ls.cVar, 0.1))
                Behavior on color { ColorAnimation { duration: 160 } }
                Text {
                    id: scT
                    anchors.centerIn: parent
                    text: sc.opt.label || ""
                    font.family: ls.fB; font.pixelSize: ls.px(11.5); font.weight: sc.sel ? Font.DemiBold : Font.Medium
                    color: sc.sel ? ls.cOnPri : ls.cVar
                }
                HoverHandler {
                    id: scHov
                    cursorShape: Qt.PointingHandCursor
                    onHoveredChanged: { if (!ls.mp) return; if (hovered && sc.opt.tip) ls.mp.showTip(sc.opt.tip, sc); else ls.mp.hideTip(sc); }
                }
                MouseArea { anchors.fill: parent; onClicked: if (!sc.sel) sg.picked(sc.opt.value) }
            }
        }
    }
    component Sw: Rectangle {
        id: sw
        property bool checked: false
        signal toggled()
        width: ls.px(40); height: ls.px(24)
        radius: height / 2
        color: checked ? ls.cPri : ls.ga(ls.cVar, 0.12)
        border.width: checked ? 0 : 2
        border.color: ls.cMuted
        Rectangle {
            readonly property real d: sw.checked ? sw.height - ls.px(8) : sw.height - ls.px(12)
            width: d; height: d; radius: d / 2
            anchors.verticalCenter: parent.verticalCenter
            x: sw.checked ? sw.width - d - ls.px(4) : ls.px(6)
            color: sw.checked ? ls.cOnPri : ls.cMuted
            Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        }
        HoverHandler { cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: sw.toggled() }
    }
}
