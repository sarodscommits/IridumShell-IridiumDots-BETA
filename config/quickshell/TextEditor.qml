pragma ComponentBehavior: Bound
// TextEditor.qml — text editor; disk work in scripts/te_backend.py
import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "i18n/apps.js" as AppStrings

Window {
    id: ed
    property var gs
    property var colors

    // inst 0 = main window (saves the session); inst > 0 = extra window
    property int  inst: 0
    property bool extraOpen: true
    readonly property bool winOpen: inst === 0 ? (gs ? gs.textEditorOpen : false) : extraOpen
    function closeWin() {
        if (inst === 0) { if (gs) gs.textEditorOpen = false; return; }
        extraOpen = false;
        var g = gs, n = inst;
        if (g && typeof g.closeAppExtra === "function") Qt.callLater(function () { g.closeAppExtra("editor", n); });
    }

    title: (cur ? (cur.dirty ? "● " : "") + cur.title + " — " : "") + tx("Editor de texto", "Text editor")
    visible: winOpen
    color: "transparent"
    width: 1120
    height: 760
    minimumWidth: 560
    minimumHeight: 360

    onClosing: (close) => { close.accepted = false; ed.requestExit(false); }
    onVisibleChanged: {
        if (!visible && ed.winOpen) ed.closeWin();
        if (visible) {
            exitPending = false;
            takeQueue();
            checkDisk();
            Qt.callLater(ed.refocus);
        }
    }
    onActiveChanged: if (active) checkDisk()

    // ───────────────────────── style ─────────────────────────
    readonly property bool   glass: gs ? gs.glassMode : false
    readonly property bool   light: gs ? gs.colorMode === "light" : false
    readonly property real   fs:    gs ? gs.fontScale : 1
    readonly property string fontA: gs ? gs.fontPrimary : "sans-serif"
    readonly property string fontB: gs ? gs.fontSecondary : "sans-serif"
    readonly property string lang:  gs ? gs.language : "es"
    readonly property string monoFont: gs && gs.fontMono ? gs.fontMono : "monospace"

    readonly property color cPrimary:   colors ? colors.primary         : "#D0BCFF"
    readonly property color cOnPrimary: colors ? colors.colorOnPrimary  : "#381E72"
    readonly property color cPrimCont:  colors ? colors.primaryCont     : "#4F378B"
    readonly property color cSurface:   colors ? colors.surface         : "#1C1B1F"
    readonly property color cSurfElev:  colors ? colors.surfaceElevated : "#2A2535"
    readonly property color cSurfHigh:  colors ? colors.surfaceHigh     : "#332E45"
    readonly property color cSurfPop:   colors ? colors.surfacePop      : "#3D3655"
    readonly property color cSurfDeep:  colors ? colors.surfaceDeep     : "#1E1B26"
    readonly property color cOnSurface: colors ? colors.colorOnSurface  : "#E6E1E5"
    readonly property color cOnSurfVar: colors ? colors.colorOnSurfVar  : "#CAC4D0"
    readonly property color cMuted:     colors ? colors.muted           : "#8E8A93"
    readonly property color cMutedDeep: colors ? colors.mutedDeep       : "#49454F"
    readonly property color cSecCont:   colors ? colors.secondaryCont   : "#4A4458"
    readonly property color cTertiary:  colors ? colors.tertiary        : "#EFB8C8"
    readonly property color cAccent:    colors ? colors.accent          : "#CCC2DC"
    readonly property color cError:     colors ? colors.error           : "#F2B8B5"
    readonly property color cPositive:  colors ? colors.positive        : "#A8D8A8"

    readonly property color bgWindow:  glass ? ga(cSurface, 0.6) : cSurface
    readonly property color bgEditor:  glass ? ga(cdark(cSecCont), 0.6) : cdark(cSecCont)
    readonly property color bgGutter:  light ? Qt.rgba(0, 0, 0, 0.03) : Qt.rgba(0, 0, 0, 0.16)
    readonly property color bgField:   ga(cOnSurfVar, light ? 0.09 : 0.075)
    readonly property color bgPop:     glass ? ga(cSurfHigh, 0.97) : cSurfHigh
    readonly property color lineCol:   light ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, 0.07)
    readonly property color hovCol:    ga(cOnSurfVar, 0.10)
    readonly property color selCol:    ga(cPrimary, 0.20)
    readonly property color trackCol:  ga(cOnSurfVar, light ? 0.12 : 0.10)

    function ga(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }
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

    // code font metrics
    property real zoom: 1.0
    property int  tabSize: 4
    property bool wrap: false
    readonly property real codeSize: Math.max(7, Math.round(13.5 * fs * zoom))
    readonly property real charW: Math.max(1, codeMetrics.advanceWidth / 20)
    readonly property real lineH: Math.max(1, codeFm.height)
    TextMetrics { id: codeMetrics; font.family: ed.monoFont; font.pixelSize: ed.codeSize; text: "MMMMMMMMMMMMMMMMMMMM" }
    FontMetrics { id: codeFm; font.family: ed.monoFont; font.pixelSize: ed.codeSize }
    TextMetrics { id: uiMetrics; font.family: ed.fontB; font.pixelSize: ed.px(12.5); font.weight: Font.Medium }

    // ───────────────────────── utilities ─────────────────────────
    property string home: Quickshell.env("HOME") || "/"
    function baseName(p) {
        if (!p) return "";
        if (p === "/") return "/";
        var s = p.replace(/\/+$/, "");
        return s.substring(s.lastIndexOf("/") + 1);
    }
    function dirName(p) {
        var s = (p || "").replace(/\/+$/, "");
        var i = s.lastIndexOf("/");
        return i <= 0 ? "/" : s.substring(0, i);
    }
    function prettyPath(p) {
        if (home && (p === home || (p || "").indexOf(home + "/") === 0)) return "~" + p.substring(home.length);
        return p;
    }
    function expandPath(t, base) {
        t = (t || "").trim();
        if (t === "") return base;
        if (t === "~") return home;
        if (t.indexOf("~/") === 0) return home + t.substring(1);
        if (t.indexOf("file://") === 0) {
            try { t = decodeURIComponent(t.substring(7)); } catch (e) { t = t.substring(7); }
        }
        if (t.charAt(0) !== "/") t = (base === "/" ? "" : base) + "/" + t;
        // resolves . and ..
        var out = [];
        t.split("/").forEach(function (seg) {
            if (seg === "" || seg === ".") return;
            if (seg === "..") out.pop(); else out.push(seg);
        });
        return "/" + out.join("/") + (t.length > 1 && t.charAt(t.length - 1) === "/" ? "/" : "");
    }
    function fmtSize(b) {
        if (b === undefined || b === null || b < 0) return "—";
        if (b < 1024) return b + " B";
        var u = ["KB", "MB", "GB", "TB"], i = -1;
        do { b /= 1024; i++; } while (b >= 1024 && i < u.length - 1);
        return (b >= 100 ? b.toFixed(0) : b.toFixed(1)) + " " + u[i];
    }
    function fmtNum(n) { return Number(n).toLocaleString(Qt.locale(lang === "es" ? "es_ES" : "en_US"), "f", 0); }
    function escHtml(s) { return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/\t/g, "    ").replace(/ /g, "&nbsp;"); }
    function fileIcon(p) {
        var n = baseName(p).toLowerCase();
        var k = n.lastIndexOf(".");
        var e = k > 0 ? n.substring(k + 1) : "";
        if (["md", "markdown", "txt", "rst", "org", "tex", "log"].indexOf(e) >= 0) return "description";
        if (["json", "yaml", "yml", "toml", "ini", "conf", "cfg", "xml", "csv"].indexOf(e) >= 0) return "data_object";
        if (["sh", "bash", "zsh", "fish"].indexOf(e) >= 0) return "terminal";
        if (["html", "htm", "css", "scss"].indexOf(e) >= 0) return "html";
        if (e !== "") return "code";
        return "draft";
    }
    function copyText(t) { Quickshell.execDetached(["wl-copy", "--", t]); toast(tx("Copiado al portapapeles", "Copied to clipboard")); }
    function openWithSystem(p) { Quickshell.execDetached(["xdg-open", p]); }

    // ───────────────────────── backend ─────────────────────────
    readonly property string backendPath: {
        var u = Qt.resolvedUrl("scripts/te_backend.py").toString();
        return u.indexOf("file://") === 0 ? decodeURIComponent(u.substring(7)) : u;
    }
    property int  _rid: 0
    property bool _ready: false
    property var  _queue: []
    property var  _cbs: ({})

    Process {
        id: backend
        command: ["python3", "-u", ed.backendPath]
        running: true
        stdinEnabled: true
        stdout: SplitParser { onRead: (data) => ed._onLine(data) }
        stderr: SplitParser { onRead: (data) => console.warn("[te_backend] " + data) }
        onStarted: {
            ed._ready = true;
            var q = ed._queue;
            ed._queue = [];
            for (var i = 0; i < q.length; i++) backend.write(q[i]);
        }
        onExited: (code, status) => {
            ed._ready = false;
            var cbs = ed._cbs;
            ed._cbs = ({});
            for (var k in cbs) { try { cbs[k](false, "backend reiniciado"); } catch (e) {} }
            backendRestart.start();
        }
    }
    Timer { id: backendRestart; interval: 900; onTriggered: backend.running = true }

    function call(cmd, args, cb) {
        var id = ++_rid;
        if (cb) _cbs[id] = cb;
        var line = JSON.stringify({ id: id, cmd: cmd, args: args || {} }) + "\n";
        if (_ready) backend.write(line); else _queue.push(line);
        return id;
    }
    function _onLine(l) {
        var o;
        try { o = JSON.parse(l); } catch (e) { return; }
        var cb = _cbs[o.id];
        delete _cbs[o.id];
        if (cb) cb(o.ok, o.ok ? o.data : o.error);
        else if (!o.ok) toast(o.error, true);
    }

    // ───────────────────────── notices / tooltips ─────────────────────────
    property string toastText: ""
    property bool   toastErr: false
    function toast(t, err) { toastText = String(t); toastErr = !!err; toastTimer.restart(); }
    Timer { id: toastTimer; interval: 3600; onTriggered: ed.toastText = "" }

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
            if (!ed.tipItem) return;
            var g = ed.tipItem.mapToItem(null, ed.tipItem.width / 2, ed.tipItem.height + 6);
            ed.tipX = g.x; ed.tipY = g.y; ed.tipShown = true;
        }
    }

    // ───────────────────────── state: tabs ─────────────────────────
    property var docs: []                 // Doc objects, in tab order
    property int curIdx: -1
    readonly property var cur: curIdx >= 0 && curIdx < docs.length ? docs[curIdx] : null
    property var recent: []
    property var closedStack: []          // to reopen closed tabs (Ctrl+Shift+T)
    property int untitledSeq: 0
    property bool stateLoaded: false
    property bool exitPending: false

    onCurChanged: {
        if (cur) Qt.callLater(function () { if (ed.cur) { ed.cur.updateGutter(); tabStrip.positionViewAtIndex(ed.curIdx, ListView.Contain); } });
        if (showSearch) runSearch(false);
        Qt.callLater(ed.refocus);
    }

    Component { id: docComp; Doc {} }

    function newDoc(props) {
        var d = docComp.createObject(docHost, props || {});
        docs = docs.concat([d]);
        return d;
    }
    function newTab() {
        untitledSeq++;
        var d = newDoc({ untitledName: tx("Sin título", "Untitled") + (untitledSeq > 1 ? " " + untitledSeq : "") });
        d.setContent({ text: "", encoding: "utf-8", bom: false, eol: "\n", mtime: 0, writable: true, useTabs: false }, {});
        curIdx = docs.length - 1;
        saveState();
        return d;
    }
    function activate(i) {
        if (i < 0 || i >= docs.length) return;
        curIdx = i;
        Qt.callLater(ed.refocus);
    }
    function cycleTab(dir) {
        if (docs.length < 2) return;
        activate((curIdx + dir + docs.length) % docs.length);
    }
    function findDoc(p) {
        for (var i = 0; i < docs.length; i++) if (docs[i].path === p) return i;
        return -1;
    }
    function moveTab(from, to) {
        to = Math.max(0, Math.min(docs.length - 1, to));
        if (from === to || from < 0 || from >= docs.length) return;
        var c = cur;
        var a = docs.slice();
        var d = a.splice(from, 1)[0];
        a.splice(to, 0, d);
        docs = a;
        curIdx = a.indexOf(c);
        saveState();
    }
    function isBlank(d) { return d && d.untitled && !d.dirty && d.area.length === 0; }

    // opens a path (or focuses the tab if it's already open)
    function openPath(p, opts) {
        opts = opts || {};
        if (!p) return;
        p = expandPath(p, home);
        if (p.length > 1) p = p.replace(/\/+$/, "");
        var i = findDoc(p);
        if (i >= 0) { if (!opts.background) activate(i); if (opts.line) docs[i].gotoLine(opts.line, 1); return; }
        var reuse = !opts.background && isBlank(cur) ? cur : null;
        var d = reuse || newDoc({});
        d.path = p;
        d.loading = true;
        if (!opts.background) curIdx = docs.indexOf(d);
        call("read", { path: p, force: !!opts.force }, function (ok, r) {
            if (ed.docs.indexOf(d) < 0) return;           // closed while loading
            if (!ok) {
                if (String(r).indexOf("No existe") === 0 && !opts.skipMissing) {
                    d.setContent({ text: "", encoding: "utf-8", bom: false, eol: "\n", mtime: 0, writable: true, useTabs: false, path: p }, {});
                    d.isNew = true;
                    ed.toast(ed.tx("Archivo nuevo: se creará al guardar", "New file: it will be created when saved"));
                    return;
                }
                ed.dropDoc(d);
                if (!opts.skipMissing) ed.toast(r, true);
                return;
            }
            if (r.binary || r.tooBig) {
                ed.dropDoc(d);
                if (opts.skipMissing) return;
                ed.askChoice(ed.tx("“%1” no parece un archivo de texto", "“%1” doesn't look like a text file").arg(ed.baseName(p)),
                    r.tooBig ? ed.tx("Es muy grande (%1).", "It's very large (%1).").arg(ed.fmtSize(r.size))
                             : ed.tx("Contiene datos binarios; editarlo podría dañarlo.", "It contains binary data; editing it could damage it."),
                    [ { label: ed.tx("Cancelar", "Cancel") },
                      { label: ed.tx("Abrir igualmente", "Open anyway"), fn: function () { var o = Object.assign({}, opts); o.force = true; ed.openPath(p, o); } },
                      { label: ed.tx("Abrir con el sistema", "Open with system"), primary: true, fn: function () { ed.openWithSystem(p); } } ]);
                return;
            }
            d.setContent(r, opts);
            if (!opts.noRecent) ed.addRecent(r.path);
            ed.saveState();
        });
    }
    function dropDoc(d) {
        var i = docs.indexOf(d);
        if (i < 0) return;
        var c = cur;
        var a = docs.slice();
        a.splice(i, 1);
        docs = a;
        if (c === d) curIdx = a.length ? Math.min(i, a.length - 1) : -1;
        else curIdx = a.indexOf(c);
        d.destroy();
        noteDirty();
    }
    // closes a tab; cb(true) if it was closed
    function closeDoc(d, cb, force) {
        if (!d || docs.indexOf(d) < 0) { if (cb) cb(true); return; }
        if (d.dirty && !force) {
            activate(docs.indexOf(d));
            askChoice(tx("¿Guardar los cambios de “%1”?", "Save changes to “%1”?").arg(d.title),
                tx("Si no los guardas se perderán.", "Your changes will be lost if you don't save them."),
                [ { label: tx("Cancelar", "Cancel"), fn: function () { if (cb) cb(false); } },
                  { label: tx("No guardar", "Don't save"), danger: true, fn: function () { ed.closeDoc(d, cb, true); } },
                  { label: tx("Guardar", "Save"), primary: true, fn: function () {
                        ed.saveDoc(d, function (ok) { if (ok) ed.closeDoc(d, cb, true); else if (cb) cb(false); });
                  } } ]);
            return;
        }
        if (!d.untitled) {
            closedStack = closedStack.filter(function (x) { return x.p !== d.path; }).concat([{ p: d.path, c: d.area.cursorPosition, idx: docs.indexOf(d) }]).slice(-25);
        }
        dropDoc(d);
        saveState();
        if (cb) cb(true);
    }
    function closeMany(list, cb) {
        list = list.slice();
        var step = function () {
            if (!list.length) { if (cb) cb(true); return; }
            ed.closeDoc(list.shift(), function (ok) { if (ok) step(); else if (cb) cb(false); });
        };
        step();
    }
    function reopenClosed() {
        if (!closedStack.length) return;
        var a = closedStack.slice();
        var it = a.pop();
        closedStack = a;
        openPath(it.p, { cursor: it.c });
        var i = findDoc(it.p);
        if (i >= 0 && it.idx !== undefined) moveTab(i, it.idx);
    }

    // external requests (explorer, IPC)
    function takeQueue() {
        if (!gs || !stateLoaded || ed.inst !== 0) return;
        var q = gs.textEditorQueue || [];
        if (!q.length) return;
        gs.textEditorQueue = [];
        for (var i = 0; i < q.length; i++) openPath(q[i], {});
    }
    Connections {
        target: ed.gs
        ignoreUnknownSignals: true
        function onTextEditorReqChanged() {
            if (ed.inst !== 0) return;
            ed.exitPending = false;
            ed.takeQueue();
            if (ed.visible) { ed.raise(); ed.requestActivate(); }
        }
    }

    Connections {
        target: ed.gs
        ignoreUnknownSignals: true
        enabled: ed.inst !== 0
        function onTextEditorPickReqChanged() {
            if (ed.gs.textEditorPickFor !== ed.inst || !ed.gs.textEditorPickPath) return;
            ed.openPath(ed.gs.textEditorPickPath, {});
            if (ed.visible) { ed.raise(); ed.requestActivate(); }
        }
    }

    // ───────────────────────── recents / state ─────────────────────────
    function addRecent(p) {
        if (!p) return;
        recent = [p].concat(recent.filter(function (x) { return x !== p; })).slice(0, 20);
        saveState();
    }
    function clearRecent() { recent = []; saveState(); }
    function stateObj() {
        var sess = [], ci = -1;
        for (var i = 0; i < docs.length; i++) {
            var d = docs[i];
            if (d.untitled || d.isNew) continue;
            if (d === cur) ci = sess.length;
            sess.push({ p: d.path, c: d.area.cursorPosition, y: Math.round(d.flick.contentY) });
        }
        return { recent: recent, wrap: wrap, zoom: zoom, tabSize: tabSize, session: sess, cur: ci };
    }
    function saveState() { if (stateLoaded && ed.inst === 0) stateTimer.restart(); }
    Timer { id: stateTimer; interval: 800; onTriggered: ed.call("state_save", { state: ed.stateObj() }) }
    onWrapChanged: saveState()
    onZoomChanged: saveState()

    Component.onCompleted: {
        call("home", {}, function (ok, h) { if (ok && h) ed.home = h; });
        call("state_load", {}, function (ok, s) {
            if (ok && s) {
                if (s.recent) ed.recent = s.recent;
                if (s.wrap !== undefined) ed.wrap = s.wrap;
                if (s.zoom) ed.zoom = s.zoom;
                if (s.tabSize) ed.tabSize = s.tabSize;
                var sess = ed.inst === 0 ? (s.session || []) : [];   // extra windows start empty
                for (var i = 0; i < sess.length; i++)
                    ed.openPath(sess[i].p, { background: true, noRecent: true, skipMissing: true, cursor: sess[i].c, y: sess[i].y });
                if (ed.docs.length) ed.curIdx = Math.max(0, Math.min(ed.docs.length - 1, s.cur >= 0 ? s.cur : 0));
            }
            ed.stateLoaded = true;
            ed.takeQueue();
        });
    }

    // ───────────────────────── save ─────────────────────────
    function noteDirty() {
        var any = false;
        for (var i = 0; i < docs.length; i++) if (docs[i].dirty) { any = true; break; }
        if (ed.inst === 0 && gs && gs.textEditorDirty !== undefined && gs.textEditorDirty !== any) gs.textEditorDirty = any;
    }
    readonly property int dirtyCount: {
        var n = 0;
        for (var i = 0; i < docs.length; i++) if (docs[i].dirty) n++;
        return n;
    }
    function saveDoc(d, cb) {
        if (!d) { if (cb) cb(false); return; }
        if (d.untitled) { activate(docs.indexOf(d)); openSaveAs(d, cb); return; }
        writeDoc(d, d.path, cb);
    }
    function writeDoc(d, path, cb) {
        var text = d.area.text;
        d.saving = true;
        call("write", { path: path, text: text, encoding: d.encoding, bom: d.bom, eol: d.eol, mkdirs: true }, function (ok, r) {
            d.saving = false;
            if (!ok) {
                ed.toast(r, true);
                if (String(r).indexOf("Permiso") === 0 && ed.docs.indexOf(d) >= 0)
                    ed.askChoice(ed.tx("No se pudo guardar", "Couldn't save"), String(r),
                        [ { label: ed.tx("Cancelar", "Cancel"), fn: function () { if (cb) cb(false); } },
                          { label: ed.tx("Guardar como…", "Save as…"), primary: true, fn: function () { ed.openSaveAs(d, cb); } } ]);
                else if (cb) cb(false);
                return;
            }
            var renamed = d.path !== r.path;
            d.path = r.path;
            d.savedText = text;
            d.encoding = r.encoding;
            d.mtime = r.mtime;
            d.metaDirty = false;
            d.isNew = false;
            d.changedOnDisk = false;
            d.missing = false;
            d.writable = true;
            d.recheck();
            ed.addRecent(r.path);
            ed.toast(ed.tx("Guardado: ", "Saved: ") + ed.baseName(r.path));
            if (renamed && ed.showSearch) ed.runSearch(false);
            if (cb) cb(true);
        });
    }
    function saveAllThen(cb) {
        var list = docs.filter(function (d) { return d.dirty; });
        var step = function () {
            if (!list.length) { if (cb) cb(true); return; }
            ed.saveDoc(list.shift(), function (ok) { if (ok) step(); else if (cb) cb(false); });
        };
        step();
    }
    function saveAll() {
        if (!dirtyCount) { toast(tx("No hay cambios sin guardar", "Nothing to save")); return; }
        saveAllThen(null);
    }
    function reloadDoc(d) {
        if (!d || d.untitled) return;
        var go = function () {
            ed.call("read", { path: d.path, force: true }, function (ok, r) {
                if (!ok) { ed.toast(r, true); return; }
                if (ed.docs.indexOf(d) >= 0) d.setContent(r, { cursor: d.area.cursorPosition, y: d.flick.contentY });
            });
        };
        if (d.dirty) askConfirm(tx("¿Recargar “%1”?", "Reload “%1”?").arg(d.title),
                                tx("Se descartarán los cambios sin guardar.", "Unsaved changes will be discarded."),
                                tx("Recargar", "Reload"), true, go);
        else go();
    }

    // changes made outside the editor
    function checkDisk() {
        var ps = [];
        for (var i = 0; i < docs.length; i++) if (!docs[i].untitled && !docs[i].isNew && !docs[i].loading) ps.push(docs[i].path);
        if (!ps.length) return;
        call("stat", { paths: ps }, function (ok, m) {
            if (!ok) return;
            for (var i = 0; i < ed.docs.length; i++) {
                var d = ed.docs[i], s = m[d.path];
                if (!s || d.saving || d.loading) continue;
                if (!s.exists) { d.missing = true; continue; }
                d.missing = false;
                if (Math.abs(s.mtime - d.mtime) > 0.0005) {
                    if (!d.dirty) {
                        (function (dd) {
                            ed.call("read", { path: dd.path, force: true }, function (ok2, r) {
                                if (ok2 && ed.docs.indexOf(dd) >= 0 && !dd.dirty)
                                    dd.setContent(r, { cursor: dd.area.cursorPosition, y: dd.flick.contentY });
                            });
                        })(d);
                    } else d.changedOnDisk = true;
                    d.mtime = s.mtime;
                }
            }
        });
    }
    Timer { interval: 2500; repeat: true; running: ed.visible && ed.docs.length > 0; onTriggered: ed.checkDisk() }

    // ───────────────────────── open / quit ─────────────────────────
    function openViaExplorer(dir) {
        if (gs && typeof gs.openFileExplorer === "function") {
            if (gs.textEditorPickTarget !== undefined) gs.textEditorPickTarget = ed.inst;
            if (gs.textEditorPicking !== undefined) gs.textEditorPicking = true;
            gs.openFileExplorer(dir || (cur && !cur.untitled ? dirName(cur.path) : (recent.length ? dirName(recent[0]) : "")));
        } else askOpenPath();
    }
    function showInExplorer(p) {
        if (gs && typeof gs.openFileExplorer === "function") gs.openFileExplorer(p ? dirName(p) : "");
    }
    function askOpenPath() {
        askInput(tx("Abrir ruta", "Open path"), cur && !cur.untitled ? prettyPath(dirName(cur.path)) + "/" : "~/",
                 tx("Abrir", "Open"), function (v) { ed.openPath(v, {}); });
    }
    function hideWindow() { ed.closeWin(); }
    function requestExit(save) {
        if (dlgKind !== "") return;
        if (save) { saveAllThen(function (ok) { if (ok) ed.finishExit(); }); return; }
        var n = dirtyCount;
        if (!n) { finishExit(); return; }
        askChoice(n === 1 ? tx("Hay 1 archivo sin guardar", "There is 1 unsaved file")
                          : tx("Hay %1 archivos sin guardar", "There are %1 unsaved files").arg(n),
                  tx("¿Quieres guardarlos antes de salir?", "Do you want to save them before leaving?"),
                  [ { label: tx("Cancelar", "Cancel") },
                    { label: tx("Salir sin guardar", "Quit without saving"), danger: true, fn: function () { ed.finishExit(); } },
                    { label: tx("Guardar todo y salir", "Save all and quit"), primary: true, fn: function () { ed.requestExit(true); } } ]);
    }
    function finishExit() {
        if (ed.inst !== 0) { exitPending = true; hideWindow(); return; }
        stateTimer.stop();
        exitPending = true;
        if (gs && gs.textEditorDirty !== undefined) gs.textEditorDirty = false;
        call("state_save", { state: stateObj() }, function () { if (ed.exitPending) unloadTimer.start(); });
        unloadFallback.start();
        hideWindow();
    }
    // unload once the state is saved to disk
    Timer { id: unloadTimer; interval: 50; onTriggered: if (ed.exitPending && ed.gs && !ed.gs.textEditorOpen) ed.gs.textEditorAlive = false }
    Timer { id: unloadFallback; interval: 2000; onTriggered: unloadTimer.start() }

    // ───────────────────────── search ─────────────────────────
    property bool   showSearch: false
    property bool   replaceMode: false
    property string findText: ""
    property string replaceText: ""
    property bool   findCase: false
    property bool   findWord: false
    property bool   findRegex: false
    property string findError: ""
    property var    results: []
    property int    resultLines: 0
    property bool   focusSearchPending: false
    readonly property int maxMatches: 5000

    function openSearch(replace) {
        if (replace !== undefined) replaceMode = replace;
        if (cur) {
            var a = cur.area;
            var n = a.selectionEnd - a.selectionStart;
            if (n > 0 && n < 300) {
                var t = a.selectedText;
                if (t.indexOf("\n") < 0 && t.indexOf(" ") < 0) { findText = t; findField.text = t; }
            }
        }
        showSearch = true;
        focusSearchPending = true;
        Qt.callLater(ed.refocus);
        runSearch(true);
    }
    function closeSearch() {
        showSearch = false;
        results = [];
        for (var i = 0; i < docs.length; i++) { docs[i].matches = []; docs[i].matchIdx = -1; docs[i].updateGutter(); }
        Qt.callLater(ed.refocus);
    }
    function buildRx(global) {
        if (findText === "") return null;
        var src = findRegex ? findText : findText.replace(/[.*+?^${}()|[\]\\\/]/g, "\\$&");
        if (findWord) src = "\\b(?:" + src + ")\\b";
        try {
            var rx = new RegExp(src, (global ? "g" : "") + "m" + (findCase ? "" : "i"));
            findError = "";
            return rx;
        } catch (e) {
            findError = tx("Expresión regular no válida", "Invalid regular expression");
            return null;
        }
    }
    Timer { id: searchTimer; interval: 110; property bool move: false; onTriggered: { ed.runSearch(move); move = false; } }
    function searchSoon(move) { if (move) searchTimer.move = true; searchTimer.restart(); }
    onFindCaseChanged: searchSoon(true)
    onFindWordChanged: searchSoon(true)
    onFindRegexChanged: searchSoon(true)

    function runSearch(move) {
        var d = cur;
        findError = "";
        if (!d || !showSearch || findText === "") {
            if (d) { d.matches = []; d.matchIdx = -1; d.updateGutter(); }
            results = []; resultLines = 0;
            return;
        }
        var rx = buildRx(true);
        if (!rx) { d.matches = []; d.matchIdx = -1; results = []; resultLines = 0; d.updateGutter(); return; }
        d.sync();
        var t = d.area.text, st = d.starts, ms = [], res = [], m, lines = 0, lastL = -1;
        while ((m = rx.exec(t)) !== null) {
            if (m[0].length === 0) { rx.lastIndex++; continue; }
            var s = m.index, e = s + m[0].length, l = d.lineOf(s);
            ms.push({ s: s, e: e, l: l });
            if (l !== lastL) { lines++; lastL = l; }
            if (ms.length >= maxMatches) break;
        }
        for (var i = 0; i < ms.length; i++) {
            var x = ms[i], ls = st[x.l], le = x.l + 1 < st.length ? st[x.l + 1] - 1 : t.length;
            var col = x.s - ls, he = Math.min(x.e, le);
            var pre = t.substring(Math.max(ls, x.s - 36), x.s);
            if (x.s - 36 > ls) pre = "…" + pre.replace(/^\s+/, "");
            else pre = pre.replace(/^\s+/, "");
            res.push({ l: x.l, c: col, html: escHtml(pre) + "<b><font color=\"" + cPrimary + "\">" + escHtml(t.substring(x.s, he)) + "</font></b>"
                                         + escHtml(t.substring(he, Math.min(le, he + 120))) });
        }
        d.matches = ms;
        results = res;
        resultLines = lines;
        // current match: the first one from the cursor onwards
        var pos = move ? d.area.selectionStart : d.area.cursorPosition, k = -1;
        for (var j = 0; j < ms.length; j++) if (ms[j].s >= pos) { k = j; break; }
        if (k < 0 && ms.length) k = 0;
        d.matchIdx = k;
        if (move && k >= 0) gotoMatch(k, true);
        else d.updateGutter();
    }
    function gotoMatch(i, keepFocus) {
        var d = cur;
        if (!d || !d.matches.length) return;
        i = (i + d.matches.length) % d.matches.length;
        d.matchIdx = i;
        var m = d.matches[i];
        d.area.select(m.s, m.e);
        d.centerOn(m.s, m.e);
        if (resultsList.count > i) resultsList.positionViewAtIndex(i, ListView.Contain);
        d.updateGutter();
        if (!keepFocus) Qt.callLater(function () { if (ed.cur) ed.cur.area.forceActiveFocus(); });
    }
    function findNext(dir) {
        var d = cur;
        if (!d) return;
        if (!showSearch) { openSearch(); return; }
        if (!d.matches.length) return;
        var a = d.area, cm = d.matches[d.matchIdx];
        var onMatch = cm && a.selectionStart === cm.s && a.selectionEnd === cm.e;
        var i;
        if (onMatch) i = d.matchIdx + dir;
        else if (dir > 0) {
            i = 0;
            for (var j = 0; j < d.matches.length; j++) if (d.matches[j].s >= a.selectionEnd) { i = j; break; }
        } else {
            i = d.matches.length - 1;
            for (var k = d.matches.length - 1; k >= 0; k--) if (d.matches[k].e <= a.selectionStart) { i = k; break; }
        }
        gotoMatch(i, true);
    }
    function replaceOne() {
        var d = cur;
        if (!d || !d.matches.length) return;
        var a = d.area, m = d.matches[d.matchIdx];
        if (!m || a.selectionStart !== m.s || a.selectionEnd !== m.e) { findNext(1); return; }
        var orig = a.getText(m.s, m.e);
        var rep = replaceText;
        if (findRegex) { var rx = buildRx(false); if (rx) rep = orig.replace(rx, replaceText); }
        d.replaceRange(m.s, m.e, rep);
        a.cursorPosition = m.s + rep.length;
        runSearch(false);
        if (d.matches.length) {
            var nxt = 0;
            for (var j = 0; j < d.matches.length; j++) if (d.matches[j].s >= m.s + rep.length) { nxt = j; break; }
            gotoMatch(nxt, true);
        }
    }
    function replaceAll() {
        var d = cur;
        if (!d) return;
        var rx = buildRx(true);
        if (!rx) return;
        var a = d.area, t = a.text, n = 0;
        var out = t.replace(rx, function () {
            if (arguments[0].length === 0) return arguments[0];
            n++;
            if (!ed.findRegex) return ed.replaceText;
            var single = ed.buildRx(false);
            return arguments[0].replace(single, ed.replaceText);
        });
        if (!n || out === t) { toast(tx("Sin coincidencias", "No matches")); return; }
        d.replaceAllText(out);
        runSearch(false);
        toast(n === 1 ? tx("1 reemplazo", "1 replacement") : n + tx(" reemplazos", " replacements"));
    }

    // ───────────────────────── dialogs ─────────────────────────
    property string dlgKind: ""          // "" | input | confirm | choice | saveas
    property string dlgTitle: ""
    property string dlgText: ""
    property string dlgValue: ""
    property string dlgOk: ""
    property bool   dlgDanger: false
    property var    dlgCb: null
    property var    dlgButtons: []
    function askInput(title, value, ok, cb) {
        dlgTitle = title; dlgText = ""; dlgValue = value; dlgOk = ok; dlgDanger = false; dlgCb = cb; dlgKind = "input";
    }
    function askConfirm(title, text, ok, danger, cb) {
        dlgTitle = title; dlgText = text; dlgValue = ""; dlgOk = ok; dlgDanger = danger; dlgCb = cb; dlgKind = "confirm";
    }
    function askChoice(title, text, buttons) {
        dlgTitle = title; dlgText = text; dlgButtons = buttons; dlgDanger = false; dlgCb = null; dlgKind = "choice";
    }
    function acceptDlg(v) {
        var cb = dlgCb, kind = dlgKind;
        if (kind === "saveas") { acceptSaveAs(v); return; }
        dlgKind = ""; dlgCb = null;
        if (kind === "input") { v = (v || "").trim(); if (!v) { refocus(); return; } }
        if (cb) cb(v);
        Qt.callLater(ed.refocus);
    }
    function pickChoice(b) {
        dlgKind = "";
        if (b && b.fn) b.fn();
        Qt.callLater(ed.refocus);
    }
    function closeDlg() {
        var kind = dlgKind, cb = dlgCb;
        dlgKind = ""; dlgCb = null;
        if (kind === "choice") {                       // Esc = the unstyled "Cancel" button (the first one)
            var b = dlgButtons.length ? dlgButtons[0] : null;
            if (b && b.fn && !b.primary && !b.danger) b.fn();
        }
        if (kind === "saveas" && saCb) { var c = saCb; saCb = null; c(false); }
        Qt.callLater(ed.refocus);
    }

    // Save as: mini folder browser
    property var    saDoc: null
    property var    saCb: null
    property string saDir: ""
    property var    saItems: []
    property bool   saHidden: false
    function openSaveAs(d, cb) {
        if (!d) return;
        saDoc = d; saCb = cb || null;
        var dir = d.untitled ? (recent.length ? dirName(recent[0]) : home) : dirName(d.path);
        var name = d.untitled ? d.untitledName.replace(/\s+/g, "_").toLowerCase() + ".txt" : baseName(d.path);
        dlgTitle = tx("Guardar como", "Save as");
        dlgText = ""; dlgOk = tx("Guardar", "Save"); dlgDanger = false;
        dlgValue = name;
        dlgKind = "saveas";
        saGo(dir);
    }
    function saGo(p) {
        call("ls", { path: p }, function (ok, r) {
            if (!ok) { ed.toast(r, true); return; }
            ed.saDir = r.path;
            ed.saItems = r.items;
        });
    }
    function acceptSaveAs(v) {
        v = (v || "").trim();
        if (!v) return;
        var full = expandPath(v, saDir);
        if (full.charAt(full.length - 1) === "/") { saGo(full); dlgField.text = ""; return; }
        var d = saDoc, cb = saCb;
        call("stat", { paths: [full] }, function (ok, m) {
            var s = ok ? m[full] : null;
            if (s && s.exists && s.dir) { ed.saGo(full); dlgField.text = ""; return; }
            ed.saCb = null;
            ed.dlgKind = "";
            var go = function () { ed.writeDoc(d, full, cb); };
            if (s && s.exists && full !== d.path)
                ed.askChoice(ed.tx("“%1” ya existe", "“%1” already exists").arg(ed.baseName(full)),
                             ed.tx("¿Quieres reemplazarlo?", "Do you want to replace it?"),
                             [ { label: ed.tx("Cancelar", "Cancel"), fn: function () { if (cb) cb(false); } },
                               { label: ed.tx("Reemplazar", "Replace"), danger: true, primary: true, fn: go } ]);
            else go();
        });
    }
    readonly property var saVisible: saHidden ? saItems : saItems.filter(function (e) { return !e.h; })

    // ───────────────────────── menus ─────────────────────────
    property var  menuItems: []
    property real menuX: 0
    property real menuY: 0
    property real menuW: 0
    property bool menuOpen: false
    property string menuSource: ""
    property var  subItems: []
    property real subX: 0
    property real subAltX: 0
    property real subY: 0
    property real subW: 0
    property bool subOpen: false
    property var  subOwner: null
    function cleanItems(items) {
        var out = [];
        for (var i = 0; i < items.length; i++) {
            var it = items[i];
            if (it.sep && (out.length === 0 || out[out.length - 1].sep)) continue;
            out.push(it);
        }
        while (out.length && out[out.length - 1].sep) out.pop();
        return out;
    }
    function menuWidth(items, minW) {
        var w = 0;
        for (var i = 0; i < items.length; i++) {
            if (items[i].sep) continue;
            uiMetrics.text = items[i].label || "";
            var lw = uiMetrics.advanceWidth;
            uiMetrics.text = items[i].key || "";
            var kw = Math.min(px(190), uiMetrics.advanceWidth * 0.86);
            w = Math.max(w, lw + kw + px(84) + (items[i].sub ? px(18) : 0));
        }
        return Math.max(minW, Math.min(px(520), w));
    }
    function openMenu(items, x, y, src) {
        hideTip();
        menuSource = src || "";
        menuItems = cleanItems(items);
        menuW = menuWidth(menuItems, px(236));
        menuX = x; menuY = y;
        subOpen = false; subOwner = null;
        menuOpen = true;
    }
    function openSub(items, item) {
        var g = item.mapToItem(rootBg, 0, 0);
        subItems = cleanItems(items);
        subW = menuWidth(subItems, px(260));
        subX = g.x + item.width + 2;
        subAltX = g.x - subW - 2;
        subY = g.y - 6;
        subOwner = item;
        subOpen = true;
    }
    function closeMenu() { menuOpen = false; subOpen = false; subOwner = null; menuSource = ""; }
    function runMenu(it) {
        if (!it || it.disabled || it.sub) return;
        closeMenu();
        if (it.fn) it.fn();
        Qt.callLater(ed.refocus);
    }
    function recentItems() {
        var m = [];
        if (!recent.length) m.push({ icon: "history", label: tx("Sin archivos recientes", "No recent files"), disabled: true });
        for (var i = 0; i < Math.min(15, recent.length); i++) {
            (function (p) {
                m.push({ icon: ed.fileIcon(p), label: ed.baseName(p), key: ed.prettyPath(ed.dirName(p)), fn: function () { ed.openPath(p, {}); } });
            })(recent[i]);
        }
        m.push({ sep: true });
        m.push({ icon: "folder_open", label: tx("Explorar en Archivos…", "Browse in Files…"),
                 fn: function () { ed.openViaExplorer(ed.recent.length ? ed.dirName(ed.recent[0]) : ""); } });
        if (recent.length) m.push({ icon: "delete_sweep", label: tx("Limpiar la lista", "Clear list"), fn: function () { ed.clearRecent(); } });
        return m;
    }
    function fileMenu(x, y) {
        var c = cur;
        openMenu([
            { icon: "note_add", label: tx("Nuevo", "New"), key: "Ctrl+N", fn: function () { ed.newTab(); } },
            { icon: "folder_open", label: tx("Abrir…", "Open…"), key: "Ctrl+O", fn: function () { ed.openViaExplorer(""); } },
            { icon: "history", label: tx("Abrir reciente", "Open recent"), sub: recentItems() },
            { icon: "input", label: tx("Abrir ruta…", "Open path…"), fn: function () { ed.askOpenPath(); } },
            { sep: true },
            { icon: "save", label: tx("Guardar", "Save"), key: "Ctrl+S", disabled: !c, fn: function () { ed.saveDoc(ed.cur, null); } },
            { icon: "save_as", label: tx("Guardar como…", "Save as…"), key: "Ctrl+Shift+S", disabled: !c, fn: function () { ed.openSaveAs(ed.cur, null); } },
            { icon: "done_all", label: tx("Guardar todo", "Save all"), key: "Ctrl+Alt+S", disabled: !dirtyCount, fn: function () { ed.saveAll(); } },
            { sep: true },
            { icon: "refresh", label: tx("Recargar desde el disco", "Reload from disk"), disabled: !c || c.untitled || c.isNew, fn: function () { ed.reloadDoc(ed.cur); } },
            { icon: "folder", label: tx("Mostrar en Archivos", "Show in Files"), disabled: !c || c.untitled, fn: function () { ed.showInExplorer(ed.cur.path); } },
            { icon: "tab_close", label: tx("Cerrar pestaña", "Close tab"), key: "Ctrl+W", disabled: !c, fn: function () { ed.closeDoc(ed.cur, null); } },
            { sep: true },
            { icon: "logout", label: tx("Guardar y salir", "Save and exit"), key: "Ctrl+Shift+Q", fn: function () { ed.requestExit(true); } },
            { icon: "close", label: tx("Salir", "Exit"), key: "Ctrl+Q", danger: true, fn: function () { ed.requestExit(false); } }
        ], x, y, "file");
    }
    function tabMenu(d, x, y) {
        var i = docs.indexOf(d);
        openMenu([
            { icon: "add", label: tx("Nueva pestaña", "New tab"), key: "Ctrl+T", fn: function () { ed.newTab(); } },
            { sep: true },
            { icon: "close", label: tx("Cerrar", "Close"), key: "Ctrl+W", fn: function () { ed.closeDoc(d, null); } },
            { icon: "tab_close", label: tx("Cerrar las demás", "Close others"), disabled: docs.length < 2,
              fn: function () { ed.closeMany(ed.docs.filter(function (x) { return x !== d; }), null); } },
            { icon: "tab_close_right", label: tx("Cerrar las de la derecha", "Close tabs to the right"), disabled: i >= docs.length - 1,
              fn: function () { ed.closeMany(ed.docs.slice(ed.docs.indexOf(d) + 1), null); } },
            { sep: true },
            { icon: "content_copy", label: tx("Copiar ruta", "Copy path"), disabled: d.untitled, fn: function () { ed.copyText(d.path); } },
            { icon: "folder", label: tx("Mostrar en Archivos", "Show in Files"), disabled: d.untitled, fn: function () { ed.showInExplorer(d.path); } },
            { icon: "refresh", label: tx("Recargar", "Reload"), disabled: d.untitled || d.isNew, fn: function () { ed.reloadDoc(d); } },
            { sep: true },
            { icon: "undo", label: tx("Reabrir pestaña cerrada", "Reopen closed tab"), key: "Ctrl+Shift+T", disabled: !closedStack.length, fn: function () { ed.reopenClosed(); } }
        ], x, y);
    }
    function editMenu(d, x, y) {
        var a = d.area, has = a.selectionEnd > a.selectionStart;
        openMenu([
            { icon: "content_cut", label: tx("Cortar", "Cut"), key: "Ctrl+X", disabled: !has, fn: function () { a.cut(); } },
            { icon: "content_copy", label: tx("Copiar", "Copy"), key: "Ctrl+C", disabled: !has, fn: function () { a.copy(); } },
            { icon: "content_paste", label: tx("Pegar", "Paste"), key: "Ctrl+V", disabled: !a.canPaste, fn: function () { a.paste(); } },
            { sep: true },
            { icon: "undo", label: tx("Deshacer", "Undo"), key: "Ctrl+Z", disabled: !a.canUndo, fn: function () { d.undo(); } },
            { icon: "redo", label: tx("Rehacer", "Redo"), key: "Ctrl+Shift+Z", disabled: !a.canRedo, fn: function () { d.redo(); } },
            { sep: true },
            { icon: "format_line_spacing", label: tx("Seleccionar línea", "Select line"), key: "Ctrl+L", fn: function () { d.selectLineCmd(); } },
            { icon: "select_all", label: tx("Seleccionar todo", "Select all"), key: "Ctrl+A", fn: function () { a.selectAll(); } },
            { icon: "content_copy", label: tx("Duplicar línea", "Duplicate line"), key: "Ctrl+Shift+D", fn: function () { d.duplicateLines(); } },
            { icon: "backspace", label: tx("Eliminar línea", "Delete line"), key: "Ctrl+Shift+K", danger: true, fn: function () { d.deleteLines(); } },
            { sep: true },
            { icon: "search", label: has ? tx("Buscar la selección", "Find selection") : tx("Buscar", "Find"), key: "Ctrl+F", fn: function () { ed.openSearch(); } },
            { icon: "move_down", label: tx("Ir a la línea…", "Go to line…"), key: "Ctrl+G", fn: function () { ed.askGoto(); } }
        ], x, y);
    }
    function askGoto() {
        if (!cur) return;
        askInput(tx("Ir a la línea", "Go to line") + " (1–" + cur.lineTotal + ")", String(cur.curLine + 1), tx("Ir", "Go"), function (v) {
            var p = v.split(/[:,\s]+/);
            var l = parseInt(p[0], 10), c = parseInt(p[1] || "1", 10);
            if (!isNaN(l) && ed.cur) ed.cur.gotoLine(l, isNaN(c) ? 1 : c);
        });
    }

    function refocus() {
        if (dlgKind !== "" || menuOpen) return;
        if (focusSearchPending && showSearch) {
            focusSearchPending = false;
            findField.input.forceActiveFocus();
            findField.input.selectAll();
            return;
        }
        focusSearchPending = false;
        if (cur) cur.area.forceActiveFocus();
        else welcome.forceActiveFocus();
    }

    // ───────────────────────── window shortcuts ─────────────────────────
    readonly property bool keysOn: dlgKind === "" && !menuOpen
    Shortcut { sequence: "Escape"; enabled: ed.dlgKind !== "" || ed.menuOpen || ed.showSearch
        onActivated: { if (ed.menuOpen) { ed.closeMenu(); ed.refocus(); } else if (ed.dlgKind !== "") ed.closeDlg(); else ed.closeSearch(); } }
    Shortcut { sequences: ["Ctrl+N", "Ctrl+T"]; enabled: ed.keysOn; onActivated: ed.newTab() }
    Shortcut { sequence: "Ctrl+O"; enabled: ed.keysOn; onActivated: ed.openViaExplorer("") }
    Shortcut { sequence: "Ctrl+S"; enabled: ed.keysOn; onActivated: ed.saveDoc(ed.cur, null) }
    Shortcut { sequence: "Ctrl+Shift+S"; enabled: ed.keysOn; onActivated: ed.openSaveAs(ed.cur, null) }
    Shortcut { sequence: "Ctrl+Alt+S"; enabled: ed.keysOn; onActivated: ed.saveAll() }
    Shortcut { sequence: "Ctrl+W"; enabled: ed.keysOn; onActivated: if (ed.cur) ed.closeDoc(ed.cur, null) }
    Shortcut { sequence: "Ctrl+Shift+T"; enabled: ed.keysOn; onActivated: ed.reopenClosed() }
    Shortcut { sequences: ["Ctrl+Tab", "Ctrl+PgDown"]; enabled: ed.keysOn; onActivated: ed.cycleTab(1) }
    Shortcut { sequences: ["Ctrl+Shift+Tab", "Ctrl+Backtab", "Ctrl+PgUp"]; enabled: ed.keysOn; onActivated: ed.cycleTab(-1) }
    Shortcut { sequence: "Ctrl+F"; enabled: ed.keysOn; onActivated: ed.openSearch() }
    Shortcut { sequence: "Ctrl+H"; enabled: ed.keysOn; onActivated: ed.openSearch(true) }
    Shortcut { sequence: "F3"; enabled: ed.keysOn; onActivated: ed.findNext(1) }
    Shortcut { sequence: "Shift+F3"; enabled: ed.keysOn; onActivated: ed.findNext(-1) }
    Shortcut { sequence: "Ctrl+G"; enabled: ed.keysOn; onActivated: ed.askGoto() }
    Shortcut { sequences: ["Ctrl+=", "Ctrl++", "Ctrl+Shift+="]; enabled: ed.keysOn; onActivated: ed.zoom = Math.min(3, Math.round((ed.zoom + 0.1) * 10) / 10) }
    Shortcut { sequence: "Ctrl+-"; enabled: ed.keysOn; onActivated: ed.zoom = Math.max(0.5, Math.round((ed.zoom - 0.1) * 10) / 10) }
    Shortcut { sequence: "Ctrl+0"; enabled: ed.keysOn; onActivated: ed.zoom = 1 }
    Shortcut { sequence: "Alt+Z"; enabled: ed.keysOn; onActivated: ed.wrap = !ed.wrap }
    Shortcut { sequence: "Ctrl+Q"; enabled: ed.keysOn; onActivated: ed.requestExit(false) }
    Shortcut { sequence: "Ctrl+Shift+Q"; enabled: ed.keysOn; onActivated: ed.requestExit(true) }
    Repeater {
        model: 9
        delegate: Item {
            required property int index
            Shortcut {
                sequence: "Ctrl+" + (index + 1)
                enabled: ed.keysOn
                onActivated: ed.activate(index === 8 ? ed.docs.length - 1 : index)
            }
        }
    }

    // ══ UI ══
    Rectangle {
        id: rootBg
        anchors.fill: parent
        color: ed.bgWindow
        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutCubic } }
        clip: true

        // ───────────── top bar ─────────────
        Item {
            id: header
            width: parent.width
            height: ed.px(52)

            Rectangle {
                id: appBadge
                x: 14
                anchors.verticalCenter: parent.verticalCenter
                width: ed.px(34)
                height: width
                radius: width / 2
                color: ed.ga(ed.cPrimary, 0.18)
                Glyph { anchors.centerIn: parent; text: "edit_note"; size: ed.px(20); color: ed.cPrimary }
            }

            Row {
                id: headLeft
                anchors.left: appBadge.right
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                BarBtn {
                    id: fileBtn
                    glyph: "description"
                    label: ed.tx("Archivo", "File")
                    arrow: true
                    active: ed.menuOpen && ed.menuSource === "file"
                    onClicked: {
                        if (ed.menuOpen) { ed.closeMenu(); ed.refocus(); return; }
                        var g = fileBtn.mapToItem(rootBg, 0, fileBtn.height + 6);
                        ed.fileMenu(g.x, g.y);
                    }
                }
                BarBtn {
                    id: searchBtn
                    glyph: "search"
                    label: ed.tx("Buscar", "Search")
                    active: ed.showSearch
                    onClicked: { if (ed.showSearch) ed.closeSearch(); else ed.openSearch(); }
                }
            }

            // path of the current file
            Row {
                anchors.left: headLeft.right
                anchors.leftMargin: 18
                anchors.right: headRight.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                clip: true
                Glyph {
                    visible: !!ed.cur
                    anchors.verticalCenter: parent.verticalCenter
                    text: ed.cur && ed.cur.untitled ? "edit_document" : "folder"
                    size: ed.px(15)
                    color: ed.cMuted
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, parent.width - 30)
                    text: !ed.cur ? "" : ed.cur.untitled ? ed.tx("Documento sin guardar", "Unsaved document") : ed.prettyPath(ed.cur.path)
                    elide: Text.ElideMiddle
                    font.family: ed.fontB
                    font.pixelSize: ed.px(12)
                    color: ed.cMuted
                }
            }

            Row {
                id: headRight
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                IconBtn {
                    anchors.verticalCenter: parent.verticalCenter
                    glyph: "wrap_text"
                    tip: ed.tx("Ajuste de línea (Alt+Z)", "Word wrap (Alt+Z)")
                    active: ed.wrap
                    onClicked: ed.wrap = !ed.wrap
                }
                IconBtn {
                    anchors.verticalCenter: parent.verticalCenter
                    glyph: "folder_open"
                    tip: ed.tx("Abrir en Archivos (Ctrl+O)", "Open from Files (Ctrl+O)")
                    onClicked: ed.openViaExplorer("")
                }
                Item { width: 4; height: 1 }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 36
                    height: 36
                    radius: 10
                    color: closeHov.hovered ? Qt.darker(ed.cError, 1.5) : "transparent"
                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    Glyph {
                        anchors.centerIn: parent
                        text: "close"
                        size: 18
                        color: closeHov.hovered ? ed.cError : ed.cOnSurfVar
                        Behavior on color { ColorAnimation { duration: 220 } }
                    }
                    HoverHandler { id: closeHov; cursorShape: Qt.PointingHandCursor }
                    MouseArea { anchors.fill: parent; onClicked: ed.requestExit(false) }
                }
            }
        }

        // ───────────── tabs (browser style) ─────────────
        Item {
            id: tabBar
            anchors.top: header.bottom
            x: ed.px(10)
            width: parent.width - 2 * x
            height: ed.px(38)

            ListView {
                id: tabStrip
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Math.min(parent.width - addTab.width - 4, contentWidth)
                orientation: ListView.Horizontal
                interactive: false
                clip: true
                spacing: 0
                model: ed.docs
                boundsBehavior: Flickable.StopAtBounds
                readonly property real tabW: Math.max(ed.px(110), Math.min(ed.px(232), (tabBar.width - addTab.width - 8) / Math.max(1, count)))
                WheelHandler {
                    onWheel: (w) => {
                        var dx = (w.angleDelta.y !== 0 ? w.angleDelta.y : w.angleDelta.x) / 120 * ed.px(90);
                        tabStrip.contentX = Math.max(0, Math.min(tabStrip.contentWidth - tabStrip.width, tabStrip.contentX - dx));
                    }
                }
                delegate: Item {
                    id: td
                    required property int index
                    required property var modelData
                    readonly property var doc: modelData
                    readonly property bool cur: index === ed.curIdx
                    readonly property bool nextIsCur: index + 1 === ed.curIdx
                    width: tabStrip.tabW
                    height: tabStrip.height
                    z: cur ? 2 : 1

                    // background: the active tab blends into the editor area
                    Rectangle {
                        anchors.fill: parent
                        anchors.bottomMargin: td.cur ? -1 : 4
                        anchors.topMargin: td.cur ? 0 : 3
                        anchors.leftMargin: td.cur ? 0 : 2
                        anchors.rightMargin: td.cur ? 0 : 2
                        topLeftRadius: 12
                        topRightRadius: 12
                        bottomLeftRadius: td.cur ? 0 : 10
                        bottomRightRadius: td.cur ? 0 : 10
                        color: td.cur ? ed.bgEditor : (tdHov.hovered ? ed.hovCol : "transparent")
                        Behavior on color { ColorAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    }
                    // separator between inactive tabs
                    Rectangle {
                        visible: !td.cur && !td.nextIsCur && td.index < ed.docs.length - 1 && !tdHov.hovered
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: -1
                        width: 1
                        height: parent.height * 0.42
                        color: ed.lineCol
                    }
                    Glyph {
                        id: tdIco
                        x: ed.px(12)
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: td.cur ? 0 : -1
                        text: td.doc.loading ? "hourglass_empty" : td.doc.untitled ? "edit_document" : ed.fileIcon(td.doc.path)
                        size: ed.px(15)
                        color: td.cur ? ed.cPrimary : ed.cMuted
                    }
                    Text {
                        anchors.left: tdIco.right
                        anchors.leftMargin: 7
                        anchors.right: tdClose.left
                        anchors.rightMargin: 4
                        anchors.verticalCenter: tdIco.verticalCenter
                        text: td.doc.title
                        elide: Text.ElideRight
                        font.family: ed.fontB
                        font.pixelSize: ed.px(12.5)
                        font.weight: td.cur ? Font.DemiBold : Font.Medium
                        font.italic: td.doc.isNew || td.doc.missing
                        color: td.cur ? ed.cOnSurface : ed.cOnSurfVar
                    }
                    HoverHandler {
                        id: tdHov
                        onHoveredChanged: {
                            if (hovered) ed.showTip(td.doc.untitled ? td.doc.title : ed.prettyPath(td.doc.path) + (td.doc.dirty ? ed.tx("  ·  sin guardar", "  ·  unsaved") : ""), td);
                            else ed.hideTip(td);
                        }
                    }
                    MouseArea {
                        id: tdMa
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                        property real pressX: 0
                        property bool dragging: false
                        onPressed: (m) => {
                            ed.hideTip(td);
                            pressX = m.x; dragging = false;
                            if (m.button === Qt.LeftButton) ed.activate(td.index);
                        }
                        onPositionChanged: (m) => {
                            if (!(m.buttons & Qt.LeftButton)) return;
                            if (!dragging && Math.abs(m.x - pressX) > 8) dragging = true;
                            if (!dragging) return;
                            var gx = mapToItem(tabStrip.contentItem, m.x, 0).x;
                            var to = Math.floor(gx / tabStrip.tabW);
                            if (to !== td.index) ed.moveTab(td.index, to);
                        }
                        onClicked: (m) => {
                            if (m.button === Qt.MiddleButton) ed.closeDoc(td.doc, null);
                            else if (m.button === Qt.RightButton) { var g = mapToItem(rootBg, m.x, m.y); ed.tabMenu(td.doc, g.x, g.y); }
                        }
                    }
                    // "unsaved" dot that turns into ✕ on hover (like in browsers/editors)
                    Rectangle {
                        id: tdClose
                        anchors.right: parent.right
                        anchors.rightMargin: ed.px(7)
                        anchors.verticalCenter: tdIco.verticalCenter
                        width: ed.px(22)
                        height: width
                        radius: width / 2
                        readonly property bool showX: tdHov.hovered || (td.cur && !td.doc.dirty)
                        color: tdcHov.hovered ? ed.ga(ed.cOnSurfVar, 0.16) : "transparent"
                        Behavior on color { ColorAnimation { duration: 140 } }
                        Rectangle {
                            visible: td.doc.dirty && !tdClose.showX
                            anchors.centerIn: parent
                            width: ed.px(8)
                            height: width
                            radius: width / 2
                            color: td.cur ? ed.cPrimary : ed.cOnSurfVar
                        }
                        Glyph {
                            visible: tdClose.showX
                            anchors.centerIn: parent
                            text: "close"
                            size: ed.px(14)
                            color: tdcHov.hovered ? ed.cOnSurface : ed.cOnSurfVar
                        }
                        HoverHandler { id: tdcHov; cursorShape: Qt.PointingHandCursor }
                        MouseArea { anchors.fill: parent; onClicked: ed.closeDoc(td.doc, null) }
                    }
                }
            }
            IconBtn {
                id: addTab
                anchors.left: tabStrip.right
                anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -1
                width: ed.px(30)
                height: ed.px(30)
                glyph: "add"
                tip: ed.tx("Nueva pestaña (Ctrl+T)", "New tab (Ctrl+T)")
                onClicked: ed.newTab()
            }
            // double click on the empty space = new tab
            MouseArea {
                anchors.left: addTab.right
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                onDoubleClicked: ed.newTab()
            }
        }

        // ───────────── body: editor + search panel ─────────────
        Rectangle {
            id: body
            anchors.top: tabBar.bottom
            anchors.bottom: statusBar.top
            x: ed.px(10)
            width: parent.width - 2 * x
            color: ed.bgEditor
            topLeftRadius: ed.curIdx === 0 ? 0 : 16
            topRightRadius: 16
            bottomLeftRadius: 16
            bottomRightRadius: 16
            clip: true

            Item {
                id: docHost
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: searchPanel.visible ? searchPanel.left : parent.right
            }

            // start screen (no tabs)
            FocusScope {
                id: welcome
                anchors.fill: docHost
                visible: ed.docs.length === 0
                Column {
                    anchors.centerIn: parent
                    spacing: 16
                    width: Math.min(parent.width - 60, ed.px(420))
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: ed.px(64)
                        height: width
                        radius: width / 2
                        color: ed.ga(ed.cPrimary, 0.16)
                        Glyph { anchors.centerIn: parent; text: "edit_note"; size: ed.px(34); color: ed.cPrimary }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: ed.tx("Editor de texto", "Text editor")
                        font.family: ed.fontA
                        font.pixelSize: ed.px(20)
                        font.weight: Font.DemiBold
                        color: ed.cOnSurface
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8
                        PillBtn { glyph: "note_add"; label: ed.tx("Nuevo archivo", "New file"); primary: true; onClicked: ed.newTab() }
                        PillBtn { glyph: "folder_open"; label: ed.tx("Abrir…", "Open…"); onClicked: ed.openViaExplorer("") }
                    }
                    Text {
                        visible: ed.recent.length > 0
                        text: ed.tx("Recientes", "Recent")
                        font.family: ed.fontB
                        font.pixelSize: ed.px(11.5)
                        font.weight: Font.DemiBold
                        color: ed.cMuted
                        topPadding: 6
                    }
                    Column {
                        width: parent.width
                        spacing: 2
                        Repeater {
                            model: ed.recent.slice(0, 8)
                            delegate: Rectangle {
                                id: rr
                                required property var modelData
                                width: parent.width
                                height: ed.px(40)
                                radius: 12
                                color: rrHov.hovered ? ed.hovCol : "transparent"
                                Glyph { id: rrIco; x: 12; anchors.verticalCenter: parent.verticalCenter; text: ed.fileIcon(rr.modelData); size: ed.px(17); color: ed.cPrimary }
                                Column {
                                    anchors.left: rrIco.right
                                    anchors.leftMargin: 10
                                    anchors.right: parent.right
                                    anchors.rightMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text { width: parent.width; text: ed.baseName(rr.modelData); elide: Text.ElideRight; font.family: ed.fontB; font.pixelSize: ed.px(12.5); font.weight: Font.Medium; color: ed.cOnSurface }
                                    Text { width: parent.width; text: ed.prettyPath(ed.dirName(rr.modelData)); elide: Text.ElideMiddle; font.family: ed.fontB; font.pixelSize: ed.px(10.5); color: ed.cMuted }
                                }
                                HoverHandler { id: rrHov; cursorShape: Qt.PointingHandCursor }
                                MouseArea { anchors.fill: parent; onClicked: ed.openPath(rr.modelData, {}) }
                            }
                        }
                    }
                }
            }

            // ───────────── search panel ─────────────
            Rectangle {
                id: searchPanel
                visible: ed.showSearch
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Math.min(ed.px(360), parent.width * 0.45)
                color: ed.bgGutter
                Rectangle { width: 1; height: parent.height; color: ed.lineCol }

                Column {
                    id: spTop
                    x: 12
                    y: 12
                    width: parent.width - 24
                    spacing: 8
                    Item {
                        width: parent.width
                        height: ed.px(28)
                        Glyph { id: spIco; anchors.verticalCenter: parent.verticalCenter; text: "manage_search"; size: ed.px(18); color: ed.cPrimary }
                        Text {
                            anchors.left: spIco.right
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: ed.replaceMode ? ed.tx("Buscar y reemplazar", "Find and replace") : ed.tx("Buscar líneas", "Find lines")
                            font.family: ed.fontA
                            font.pixelSize: ed.px(14)
                            font.weight: Font.DemiBold
                            color: ed.cOnSurface
                        }
                        Row {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            IconBtn {
                                width: ed.px(28); height: ed.px(28); gsize: ed.px(16)
                                glyph: "find_replace"
                                active: ed.replaceMode
                                tip: ed.tx("Reemplazar (Ctrl+H)", "Replace (Ctrl+H)")
                                onClicked: ed.replaceMode = !ed.replaceMode
                            }
                            IconBtn {
                                width: ed.px(28); height: ed.px(28); gsize: ed.px(16)
                                glyph: "close"
                                tip: ed.tx("Cerrar (Esc)", "Close (Esc)")
                                onClicked: ed.closeSearch()
                            }
                        }
                    }
                    Field {
                        id: findField
                        width: parent.width
                        height: ed.px(36)
                        glyph: "search"
                        placeholder: ed.tx("Buscar en el archivo…", "Find in file…")
                        onEdited: (t) => { ed.findText = t; ed.searchSoon(true); }
                        onAccepted: ed.findNext(1)
                        onShiftAccepted: ed.findNext(-1)
                        onEscaped: ed.closeSearch()
                        onDownPressed: if (resultsList.count) { resultsList.currentIndex = Math.max(0, ed.cur ? ed.cur.matchIdx : 0); resultsList.forceActiveFocus(); }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            rightPadding: 8
                            visible: ed.findText !== ""
                            text: ed.findError !== "" ? "!" : !ed.cur || !ed.cur.matches.length ? "0" :
                                  (ed.cur.matchIdx + 1) + "/" + (ed.cur.matches.length >= ed.maxMatches ? ed.maxMatches + "+" : ed.cur.matches.length)
                            font.family: ed.fontB
                            font.pixelSize: ed.px(11)
                            color: ed.findError !== "" || (ed.cur && !ed.cur.matches.length) ? ed.cError : ed.cMuted
                        }
                    }
                    Field {
                        id: replaceField
                        visible: ed.replaceMode
                        width: parent.width
                        height: ed.px(36)
                        glyph: "find_replace"
                        placeholder: ed.findRegex ? ed.tx("Reemplazar ($1, $2…)", "Replace ($1, $2…)") : ed.tx("Reemplazar con…", "Replace with…")
                        onEdited: (t) => ed.replaceText = t
                        onAccepted: ed.replaceOne()
                        onEscaped: ed.closeSearch()
                    }
                    Item {
                        width: parent.width
                        height: ed.px(30)
                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            IconBtn { width: ed.px(30); height: ed.px(30); gsize: ed.px(17); glyph: "match_case"; active: ed.findCase; tip: ed.tx("Distinguir mayúsculas", "Match case"); onClicked: ed.findCase = !ed.findCase }
                            IconBtn { width: ed.px(30); height: ed.px(30); gsize: ed.px(17); glyph: "match_word"; active: ed.findWord; tip: ed.tx("Palabra completa", "Whole word"); onClicked: ed.findWord = !ed.findWord }
                            IconBtn { width: ed.px(30); height: ed.px(30); gsize: ed.px(17); glyph: "regular_expression"; active: ed.findRegex; tip: ed.tx("Expresión regular", "Regular expression"); onClicked: ed.findRegex = !ed.findRegex }
                        }
                        Row {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            IconBtn { width: ed.px(30); height: ed.px(30); gsize: ed.px(18); glyph: "keyboard_arrow_up"; tip: ed.tx("Anterior (Shift+Enter)", "Previous (Shift+Enter)"); enabled: !!ed.cur && ed.cur.matches.length > 0; onClicked: ed.findNext(-1) }
                            IconBtn { width: ed.px(30); height: ed.px(30); gsize: ed.px(18); glyph: "keyboard_arrow_down"; tip: ed.tx("Siguiente (Enter)", "Next (Enter)"); enabled: !!ed.cur && ed.cur.matches.length > 0; onClicked: ed.findNext(1) }
                        }
                    }
                    Row {
                        visible: ed.replaceMode
                        spacing: 6
                        PillBtn { glyph: "find_replace"; label: ed.tx("Reemplazar", "Replace"); enabled: !!ed.cur && ed.cur.matches.length > 0; onClicked: ed.replaceOne() }
                        PillBtn { glyph: "done_all"; label: ed.tx("Reemplazar todo", "Replace all"); primary: true; enabled: !!ed.cur && ed.cur.matches.length > 0; onClicked: ed.replaceAll() }
                    }
                    Text {
                        width: parent.width
                        visible: ed.findText !== ""
                        text: ed.findError !== "" ? ed.findError
                              : !ed.results.length ? ed.tx("Sin coincidencias", "No matches")
                              : (ed.resultLines === 1 ? ed.tx("%1 coincidencias en %2 línea", "%1 matches in %2 line") : ed.tx("%1 coincidencias en %2 líneas", "%1 matches in %2 lines"))
                                      .arg(ed.fmtNum(ed.results.length) + (ed.results.length >= ed.maxMatches ? "+" : "")).arg(ed.fmtNum(ed.resultLines))
                        font.family: ed.fontB
                        font.pixelSize: ed.px(11)
                        color: ed.findError !== "" ? ed.cError : ed.cMuted
                        topPadding: 2
                    }
                }

                ListView {
                    id: resultsList
                    anchors.top: spTop.bottom
                    anchors.topMargin: 8
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 8
                    x: 6
                    width: parent.width - 12
                    clip: true
                    model: ed.results
                    boundsBehavior: Flickable.StopAtBounds
                    interactive: false
                    keyNavigationEnabled: true
                    highlightFollowsCurrentItem: false
                    ScrollBar.vertical: EdScrollBar {}
                    Keys.onReturnPressed: ed.gotoMatch(currentIndex, false)
                    Keys.onEnterPressed: ed.gotoMatch(currentIndex, false)
                    Keys.onEscapePressed: findField.input.forceActiveFocus()
                    Keys.onUpPressed: { if (currentIndex <= 0) findField.input.forceActiveFocus(); else { decrementCurrentIndex(); ed.gotoMatch(currentIndex, true); } }
                    Keys.onDownPressed: { incrementCurrentIndex(); ed.gotoMatch(currentIndex, true); }
                    delegate: Rectangle {
                        id: rd
                        required property int index
                        required property var modelData
                        readonly property bool sel: !!ed.cur && ed.cur.matchIdx === index
                        width: resultsList.width - 8
                        height: ed.px(30)
                        radius: 9
                        color: sel ? ed.selCol : (rdHov.hovered ? ed.hovCol : "transparent")
                        Text {
                            id: rdNum
                            x: 6
                            width: ed.px(46)
                            anchors.verticalCenter: parent.verticalCenter
                            horizontalAlignment: Text.AlignRight
                            text: rd.modelData.l + 1
                            font.family: ed.monoFont
                            font.pixelSize: ed.px(11)
                            color: rd.sel ? ed.cPrimary : ed.cMuted
                        }
                        Text {
                            anchors.left: rdNum.right
                            anchors.leftMargin: 10
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: rd.modelData.html
                            textFormat: Text.StyledText
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            font.family: ed.monoFont
                            font.pixelSize: ed.px(11.5)
                            color: ed.cOnSurfVar
                        }
                        HoverHandler { id: rdHov; cursorShape: Qt.PointingHandCursor }
                        MouseArea { anchors.fill: parent; onClicked: { resultsList.currentIndex = rd.index; ed.gotoMatch(rd.index, false); } }
                    }
                }
                WheelCatcher { flick: resultsList }
            }
        }

        // ───────────── status bar ─────────────
        Item {
            id: statusBar
            anchors.bottom: parent.bottom
            width: parent.width
            height: ed.px(32)
            readonly property var d: ed.cur
            Row {
                x: ed.px(18)
                anchors.verticalCenter: parent.verticalCenter
                spacing: 16
                visible: !!statusBar.d
                StatusText {
                    text: !statusBar.d ? "" : ed.tx("Lín ", "Ln ") + (statusBar.d.curLine + 1) + ", " + ed.tx("Col ", "Col ") + (statusBar.d.curCol + 1)
                    onClicked: ed.askGoto()
                }
                StatusText {
                    visible: !!statusBar.d && statusBar.d.selChars > 0
                    text: !statusBar.d ? "" : ed.fmtNum(statusBar.d.selChars) + ed.tx(" seleccionados", " selected")
                          + (statusBar.d.selHi > statusBar.d.selLo ? " (" + (statusBar.d.selHi - statusBar.d.selLo + 1) + ed.tx(" líneas)", " lines)") : "")
                    color: ed.cPrimary
                }
                StatusText {
                    visible: !!statusBar.d && (statusBar.d.changedOnDisk || statusBar.d.missing || !statusBar.d.writable)
                    text: !statusBar.d ? "" : statusBar.d.missing ? ed.tx("Eliminado del disco", "Deleted from disk")
                        : statusBar.d.changedOnDisk ? ed.tx("Cambiado en el disco", "Changed on disk")
                        : ed.tx("Solo lectura", "Read-only")
                    color: ed.cError
                }
            }
            Row {
                anchors.right: parent.right
                anchors.rightMargin: ed.px(18)
                anchors.verticalCenter: parent.verticalCenter
                spacing: 16
                visible: !!statusBar.d
                StatusText { text: !statusBar.d ? "" : ed.fmtNum(statusBar.d.lineTotal) + (statusBar.d.lineTotal === 1 ? ed.tx(" línea", " line") : ed.tx(" líneas", " lines")) }
                StatusText {
                    text: !statusBar.d ? "" : statusBar.d.useTabs ? ed.tx("Tabulaciones", "Tabs") : ed.tx("Espacios: ", "Spaces: ") + ed.tabSize
                    tip: ed.tx("Clic: alternar tabulaciones / espacios", "Click: toggle tabs / spaces")
                    onClicked: statusBar.d.useTabs = !statusBar.d.useTabs
                }
                StatusText {
                    text: !statusBar.d ? "" : statusBar.d.eol === "\r\n" ? "CRLF" : statusBar.d.eol === "\r" ? "CR" : "LF"
                    tip: ed.tx("Fin de línea (clic para cambiar)", "Line ending (click to change)")
                    onClicked: { var d = statusBar.d; d.eol = d.eol === "\n" ? "\r\n" : "\n"; d.metaDirty = true; d.recheck(); }
                }
                StatusText { text: !statusBar.d ? "" : statusBar.d.encoding.toUpperCase() + (statusBar.d.bom ? " BOM" : "") }
                StatusText {
                    text: Math.round(ed.zoom * 100) + " %"
                    tip: ed.tx("Zoom (Ctrl+rueda) · clic = 100 %", "Zoom (Ctrl+wheel) · click = 100 %")
                    onClicked: ed.zoom = 1
                }
            }
        }

        // ───────────── notice ─────────────
        Rectangle {
            id: toastBox
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: ed.toastText !== "" ? ed.px(44) : -height
            Behavior on anchors.bottomMargin { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
            opacity: ed.toastText !== "" ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            z: 30
            width: Math.min(rootBg.width - 80, toastRow.implicitWidth + 32)
            height: toastRow.height + 20
            radius: height > 52 ? 20 : height / 2
            color: ed.bgPop
            border.width: 1
            border.color: ed.toastErr ? ed.ga(ed.cError, 0.5) : ed.lineCol
            Row {
                id: toastRow
                anchors.centerIn: parent
                spacing: 10
                Glyph {
                    anchors.verticalCenter: parent.verticalCenter
                    text: ed.toastErr ? "error" : "check_circle"
                    size: ed.px(18)
                    color: ed.toastErr ? ed.cError : ed.cPrimary
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, Math.min(ed.px(560), rootBg.width - 140))
                    text: ed.toastText
                    wrapMode: Text.Wrap
                    maximumLineCount: 6
                    elide: Text.ElideRight
                    font.family: ed.fontB
                    font.pixelSize: ed.px(12.5)
                    color: ed.cOnSurface
                }
            }
            MouseArea { anchors.fill: parent; onClicked: ed.toastText = "" }
        }

        // ───────────── tooltip ─────────────
        Rectangle {
            z: 90
            visible: ed.tipShown && ed.tipText !== ""
            x: Math.max(6, Math.min(rootBg.width - width - 6, ed.tipX - width / 2))
            y: ed.tipY + height > rootBg.height - 6 ? ed.tipY - height - 40 : ed.tipY
            width: Math.min(tipT.implicitWidth + 20, rootBg.width - 12)
            height: tipT.implicitHeight + 10
            radius: height / 2
            color: ed.cSurfPop
            Text {
                id: tipT
                anchors.centerIn: parent
                width: Math.min(implicitWidth, rootBg.width - 32)
                elide: Text.ElideMiddle
                text: ed.tipText
                font.family: ed.fontB
                font.pixelSize: ed.px(11.5)
                color: ed.cOnSurface
            }
        }

        // ───────────── menus ─────────────
        Item {
            anchors.fill: parent
            visible: ed.menuOpen
            z: 60
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onPressed: { ed.closeMenu(); ed.refocus(); }
                onWheel: (w) => ed.closeMenu()
            }
            MenuPanel {
                id: menuBox
                items: ed.menuItems
                shown: ed.menuOpen
                level: 0
                width: ed.menuW
                x: Math.max(6, Math.min(ed.menuX, rootBg.width - width - 6))
                y: ed.menuY + height <= rootBg.height - 6 ? ed.menuY : Math.max(6, ed.menuY - height)
            }
            MenuPanel {
                id: subBox
                items: ed.subItems
                shown: ed.subOpen && ed.menuOpen
                level: 1
                width: ed.subW
                x: ed.subX + width <= rootBg.width - 6 ? ed.subX : Math.max(6, ed.subAltX)
                y: Math.max(6, Math.min(ed.subY, rootBg.height - height - 6))
            }
        }

        // ───────────── dialog ─────────────
        Rectangle {
            anchors.fill: parent
            visible: ed.dlgKind !== ""
            z: 80
            color: Qt.rgba(0, 0, 0, ed.light ? 0.22 : 0.42)
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onWheel: (w) => {} }
            Rectangle {
                id: dlgCard
                anchors.centerIn: parent
                width: Math.min(parent.width - 40, ed.px(ed.dlgKind === "saveas" ? 560 : 460))
                height: dlgCol.height + 44
                radius: 28
                color: ed.bgPop
                border.width: 1
                border.color: ed.lineCol
                MouseArea { anchors.fill: parent }
                Column {
                    id: dlgCol
                    x: 22
                    y: 22
                    width: dlgCard.width - 44
                    spacing: 14
                    Row {
                        spacing: 10
                        width: parent.width
                        Rectangle {
                            id: dlgIco
                            width: ed.px(36)
                            height: width
                            radius: width / 2
                            color: ed.ga(ed.dlgDanger ? ed.cError : ed.cPrimary, 0.18)
                            Glyph {
                                anchors.centerIn: parent
                                text: ed.dlgKind === "saveas" ? "save_as" : ed.dlgKind === "choice" ? "help" : ed.dlgKind === "confirm" ? (ed.dlgDanger ? "warning" : "help") : "edit"
                                size: ed.px(19)
                                color: ed.dlgDanger ? ed.cError : ed.cPrimary
                            }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - dlgIco.width - 10
                            text: ed.dlgTitle
                            wrapMode: Text.Wrap
                            font.family: ed.fontA
                            font.pixelSize: ed.px(16)
                            font.weight: Font.DemiBold
                            color: ed.cOnSurface
                        }
                    }
                    Text {
                        visible: ed.dlgText !== ""
                        width: parent.width
                        text: ed.dlgText
                        wrapMode: Text.Wrap
                        font.family: ed.fontB
                        font.pixelSize: ed.px(12.5)
                        color: ed.cOnSurfVar
                    }

                    // "Save as" folder browser
                    Item {
                        visible: ed.dlgKind === "saveas"
                        width: parent.width
                        height: ed.px(34)
                        IconBtn {
                            id: saUp
                            anchors.verticalCenter: parent.verticalCenter
                            glyph: "arrow_upward"
                            tip: ed.tx("Carpeta superior", "Parent folder")
                            enabled: ed.saDir !== "/"
                            onClicked: ed.saGo(ed.dirName(ed.saDir))
                        }
                        IconBtn {
                            id: saHome
                            anchors.left: saUp.right
                            anchors.verticalCenter: parent.verticalCenter
                            glyph: "home"
                            tip: ed.tx("Carpeta personal", "Home")
                            onClicked: ed.saGo(ed.home)
                        }
                        Rectangle {
                            anchors.left: saHome.right
                            anchors.leftMargin: 6
                            anchors.right: saHid.left
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            height: ed.px(30)
                            radius: height / 2
                            color: ed.bgField
                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                verticalAlignment: Text.AlignVCenter
                                text: ed.prettyPath(ed.saDir)
                                elide: Text.ElideLeft
                                font.family: ed.fontB
                                font.pixelSize: ed.px(12)
                                color: ed.cOnSurfVar
                            }
                        }
                        IconBtn {
                            id: saHid
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            glyph: ed.saHidden ? "visibility" : "visibility_off"
                            active: ed.saHidden
                            tip: ed.tx("Mostrar ocultos", "Show hidden")
                            onClicked: ed.saHidden = !ed.saHidden
                        }
                    }
                    Rectangle {
                        visible: ed.dlgKind === "saveas"
                        width: parent.width
                        height: ed.px(230)
                        radius: 16
                        color: ed.ga(ed.cOnSurfVar, 0.05)
                        clip: true
                        ListView {
                            id: saList
                            anchors.fill: parent
                            anchors.margins: 4
                            clip: true
                            interactive: false
                            boundsBehavior: Flickable.StopAtBounds
                            model: ed.saVisible
                            ScrollBar.vertical: EdScrollBar {}
                            delegate: Rectangle {
                                id: sr
                                required property var modelData
                                width: saList.width - 6
                                height: ed.px(30)
                                radius: 10
                                color: srHov.hovered ? ed.hovCol : (!sr.modelData.d && dlgField.text === sr.modelData.n ? ed.selCol : "transparent")
                                opacity: sr.modelData.d ? 1 : 0.85
                                Glyph { id: srIco; x: 10; anchors.verticalCenter: parent.verticalCenter; text: sr.modelData.d ? "folder" : ed.fileIcon(sr.modelData.n); size: ed.px(16); color: sr.modelData.d ? ed.cPrimary : ed.cMuted }
                                Text {
                                    anchors.left: srIco.right
                                    anchors.leftMargin: 10
                                    anchors.right: parent.right
                                    anchors.rightMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: sr.modelData.n
                                    elide: Text.ElideMiddle
                                    font.family: ed.fontB
                                    font.pixelSize: ed.px(12.5)
                                    color: sr.modelData.d ? ed.cOnSurface : ed.cOnSurfVar
                                }
                                HoverHandler { id: srHov; cursorShape: Qt.PointingHandCursor }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (sr.modelData.d) ed.saGo(sr.modelData.p);
                                        else { dlgField.text = sr.modelData.n; dlgField.input.forceActiveFocus(); }
                                    }
                                    onDoubleClicked: if (!sr.modelData.d) ed.acceptDlg(sr.modelData.n)
                                }
                            }
                        }
                        WheelCatcher { flick: saList }
                        Text {
                            anchors.centerIn: parent
                            visible: saList.count === 0
                            text: ed.tx("Carpeta vacía", "Empty folder")
                            font.family: ed.fontB
                            font.pixelSize: ed.px(12)
                            color: ed.cMuted
                        }
                    }

                    Field {
                        id: dlgField
                        visible: ed.dlgKind === "input" || ed.dlgKind === "saveas"
                        width: parent.width
                        height: ed.px(38)
                        glyph: ed.dlgKind === "saveas" ? "draft" : ""
                        placeholder: ed.dlgKind === "saveas" ? ed.tx("Nombre del archivo (o ruta)", "File name (or path)") : ""
                        onAccepted: ed.acceptDlg(dlgField.text)
                        onEscaped: ed.closeDlg()
                    }
                    Item {
                        width: parent.width
                        height: dlgBtns.height
                        Row {
                            id: dlgBtns
                            anchors.right: parent.right
                            spacing: 8
                            PillBtn { visible: ed.dlgKind !== "choice"; label: ed.tx("Cancelar", "Cancel"); onClicked: ed.closeDlg() }
                            PillBtn {
                                visible: ed.dlgKind !== "choice"
                                label: ed.dlgOk
                                primary: true
                                danger: ed.dlgDanger
                                onClicked: ed.acceptDlg(dlgField.text)
                            }
                            Repeater {
                                model: ed.dlgKind === "choice" ? ed.dlgButtons : []
                                delegate: PillBtn {
                                    required property var modelData
                                    label: modelData.label
                                    primary: !!modelData.primary
                                    danger: !!modelData.danger
                                    onClicked: ed.pickChoice(modelData)
                                }
                            }
                        }
                    }
                }
            }
        }
        Connections {
            target: ed
            function onDlgKindChanged() {
                if (ed.dlgKind === "input" || ed.dlgKind === "saveas") {
                    dlgField.text = ed.dlgValue;
                    Qt.callLater(function () {
                        dlgField.input.forceActiveFocus();
                        var v = dlgField.text, k = v.lastIndexOf(".");
                        if (ed.dlgKind === "saveas" && k > 0) dlgField.input.select(0, k);
                        else dlgField.input.selectAll();
                    });
                } else if (ed.dlgKind !== "") Qt.callLater(function () { dlgKeys.forceActiveFocus(); });
            }
        }
        // Enter in confirmations / choices = primary button
        Item {
            id: dlgKeys
            focus: false
            Keys.onReturnPressed: ed.dlgEnter()
            Keys.onEnterPressed: ed.dlgEnter()
        }
    }
    function dlgEnter() {
        if (dlgKind === "confirm") acceptDlg("");
        else if (dlgKind === "choice") {
            for (var i = 0; i < dlgButtons.length; i++) if (dlgButtons[i].primary) { pickChoice(dlgButtons[i]); return; }
        }
    }

    // ══ Document (one tab) ══
    component Doc: Item {
        id: doc
        anchors.fill: parent
        visible: ed.cur === doc

        property string path: ""
        property string untitledName: ""
        readonly property bool untitled: path === ""
        readonly property string title: untitled ? untitledName : ed.baseName(path)
        property bool   dirty: false
        property bool   metaDirty: false
        property bool   loading: false
        property bool   saving: false
        property string savedText: ""
        property string encoding: "utf-8"
        property bool   bom: false
        property string eol: "\n"
        property real   mtime: 0
        property bool   writable: true
        property bool   useTabs: false
        property bool   changedOnDisk: false
        property bool   missing: false
        property bool   isNew: false

        property var  starts: [0]          // start position of each line
        property int  lineTotal: 1
        property int  curLine: 0
        property int  curCol: 0
        property int  selLo: 0
        property int  selHi: 0
        property int  selChars: 0
        property var  gutterRows: []
        property var  hlRows: []
        property var  matches: []
        property int  matchIdx: -1

        readonly property alias area: te
        readonly property alias flick: flick

        onDirtyChanged: ed.noteDirty()
        onVisibleChanged: if (visible) Qt.callLater(doc.updateGutter)

        // ── content ──
        function setContent(d, opts) {
            opts = opts || {};
            loading = true;
            te.text = d.text;
            savedText = d.text;
            encoding = d.encoding || "utf-8";
            bom = !!d.bom;
            eol = d.eol || "\n";
            mtime = d.mtime || 0;
            writable = d.writable !== false;
            useTabs = !!d.useTabs;
            if (d.path) path = d.path;
            metaDirty = false;
            changedOnDisk = false;
            missing = false;
            loading = false;
            reindex();
            te.cursorPosition = opts.cursor >= 0 ? Math.min(opts.cursor, te.length) : 0;
            var y = opts.y;
            Qt.callLater(function () {
                if (y !== undefined && y >= 0) flick.contentY = Math.max(0, Math.min(y, flick.contentHeight - flick.height));
                else if (opts.cursor >= 0) doc.centerOn(te.cursorPosition, te.cursorPosition);
                doc.updateGutter();
            });
        }
        function replaceAllText(t) {
            var pos = te.cursorPosition, y = flick.contentY;
            replaceRange(0, te.length, t);
            te.cursorPosition = Math.min(pos, te.length);
            flick.contentY = Math.max(0, Math.min(y, flick.contentHeight - flick.height));
        }
        function recheck() {
            var t = te.text;
            dirty = metaDirty || t.length !== savedText.length || t !== savedText;
        }
        function reindex() {
            var t = te.text, s = [0], i = -1;
            while ((i = t.indexOf("\n", i + 1)) !== -1) s.push(i + 1);
            starts = s;
            lineTotal = s.length;
            dirty = metaDirty || t.length !== savedText.length || t !== savedText;
            cursorMoved();
            Qt.callLater(doc.updateGutter);
        }
        function sync() { if (idxTimer.running) { idxTimer.stop(); reindex(); } }
        Timer { id: idxTimer; interval: 60; onTriggered: { doc.reindex(); if (ed.showSearch && ed.cur === doc) ed.searchSoon(false); } }
        function onEdited() {
            if (loading) return;
            if (te.length < 400000) { reindex(); if (ed.showSearch && ed.cur === doc) ed.searchSoon(false); }
            else idxTimer.restart();
        }

        // ── lines ──
        function lineOf(pos) {
            var s = starts, lo = 0, hi = s.length - 1;
            while (lo < hi) {
                var mid = (lo + hi + 1) >> 1;
                if (s[mid] <= pos) lo = mid; else hi = mid - 1;
            }
            return lo;
        }
        function lineEnd(i) { return i + 1 < starts.length ? starts[i + 1] - 1 : te.length; }
        function cursorMoved() {
            var p = te.cursorPosition;
            curLine = lineOf(p);
            curCol = p - starts[curLine];
            var a = te.selectionStart, b = te.selectionEnd;
            selChars = b - a;
            selLo = lineOf(a);
            var hi = lineOf(b);
            if (b > a && hi > selLo && b === starts[hi]) hi--;
            selHi = hi;
            blink.restart();
            cursorOn = true;
        }
        function selLines() { sync(); cursorMoved(); return [selLo, selHi]; }
        function selectLines(a, b) {
            sync();
            var lo = Math.min(a, b), hi = Math.max(a, b);
            var s = starts[lo], e = hi + 1 < starts.length ? starts[hi + 1] : te.length;
            if (b >= a) te.select(s, e);
            else { te.cursorPosition = e; te.moveCursorSelection(s, TextEdit.SelectCharacters); }
        }
        function selectLineCmd() {
            var r = selLines();
            var a = te.selectionStart, b = te.selectionEnd;
            var hi = r[1];
            if (b > a && b === starts[Math.min(starts.length - 1, hi + 1)] && hi + 1 < starts.length) hi++;   // repeat = extend
            selectLines(r[0], hi);
        }
        function setSel(s, e, cursorAtStart) {
            s = Math.max(0, Math.min(s, te.length)); e = Math.max(0, Math.min(e, te.length));
            if (cursorAtStart) { te.cursorPosition = e; te.moveCursorSelection(s, TextEdit.SelectCharacters); }
            else te.select(s, e);
        }
        // replace = delete + insert, undone as one step
        property var cmpUndo: []
        property var cmpRedo: []
        function replaceRange(a, b, str) {
            if (a === b) { if (str.length) te.insert(a, str); sync(); return; }
            if (!str.length) { te.remove(a, b); sync(); return; }
            var before = te.length < 4000000 ? te.text : null;
            te.remove(a, b);
            te.insert(a, str);
            if (before !== null) {
                cmpUndo = cmpUndo.concat([{ before: before, after: te.text }]).slice(-40);
                cmpRedo = [];
            }
            sync();
        }
        function undo() {
            var c = cmpUndo.length ? cmpUndo[cmpUndo.length - 1] : null;
            if (c && te.length === c.after.length && te.text === c.after) {
                te.undo(); te.undo();
                cmpUndo = cmpUndo.slice(0, -1);
                cmpRedo = cmpRedo.concat([c]);
            } else te.undo();
        }
        function redo() {
            var c = cmpRedo.length ? cmpRedo[cmpRedo.length - 1] : null;
            if (c && te.length === c.before.length && te.text === c.before) {
                te.redo(); te.redo();
                cmpRedo = cmpRedo.slice(0, -1);
                cmpUndo = cmpUndo.concat([c]);
            } else te.redo();
        }
        function deleteLines() {
            var r = selLines(), lo = r[0], hi = r[1];
            var a = starts[lo], b = hi + 1 < starts.length ? starts[hi + 1] : te.length;
            var target = a;
            if (hi + 1 >= starts.length && lo > 0) { a = starts[lo] - 1; target = starts[lo - 1]; }
            var col = curCol;
            te.remove(a, b);
            sync();
            var l = lineOf(Math.min(target, te.length));
            te.cursorPosition = Math.min(starts[l] + col, lineEnd(l));
        }
        function duplicateLines() {
            var r = selLines(), lo = r[0], hi = r[1];
            var s0 = te.selectionStart, e0 = te.selectionEnd, atStart = te.cursorPosition === s0 && e0 > s0;
            var block = te.getText(starts[lo], lineEnd(hi));
            te.insert(lineEnd(hi), "\n" + block);
            sync();
            setSel(s0 + block.length + 1, e0 + block.length + 1, atStart);
        }
        function moveLines(dir) {
            var r = selLines(), lo = r[0], hi = r[1];
            if (dir > 0 && hi >= starts.length - 1) return;
            if (dir < 0 && lo <= 0) return;
            var s0 = te.selectionStart, e0 = te.selectionEnd, atStart = te.cursorPosition === s0 && e0 > s0;
            var A = te.getText(starts[lo], lineEnd(hi));
            if (dir > 0) {
                var B = te.getText(starts[hi + 1], lineEnd(hi + 1));
                replaceRange(starts[lo], lineEnd(hi + 1), B + "\n" + A);
                setSel(s0 + B.length + 1, e0 + B.length + 1, atStart);
            } else {
                var P = te.getText(starts[lo - 1], lineEnd(lo - 1));
                var a0 = starts[lo - 1];
                replaceRange(a0, lineEnd(hi), A + "\n" + P);
                setSel(s0 - P.length - 1, e0 - P.length - 1, atStart);
            }
        }
        function indentUnit() { return useTabs ? "\t" : Array(ed.tabSize + 1).join(" "); }
        function indentLines(dir) {
            var r = selLines(), lo = r[0], hi = r[1];
            var a = starts[lo], b = lineEnd(hi);
            var lines = te.getText(a, b).split("\n");
            var unit = indentUnit();
            for (var i = 0; i < lines.length; i++) {
                var l = lines[i];
                if (dir > 0) { if (l.length) lines[i] = unit + l; }
                else if (l.charAt(0) === "\t") lines[i] = l.substring(1);
                else { var k = 0; while (k < ed.tabSize && l.charAt(k) === " ") k++; lines[i] = l.substring(k); }
            }
            var out = lines.join("\n");
            if (out === te.getText(a, b)) return;
            replaceRange(a, b, out);
            if (lo === hi && te.selectionStart === te.selectionEnd) return;
            setSel(starts[lo], lineEnd(hi), false);
        }
        function gotoLine(l, c) {
            sync();
            l = Math.max(1, Math.min(l, starts.length)) - 1;
            te.cursorPosition = Math.min(starts[l] + Math.max(0, (c || 1) - 1), lineEnd(l));
            centerOn(te.cursorPosition, te.cursorPosition);
            te.forceActiveFocus();
        }

        // ── keyboard ──
        function handleKey(e) {
            var ctrl = e.modifiers & Qt.ControlModifier, shift = e.modifiers & Qt.ShiftModifier, alt = e.modifiers & Qt.AltModifier;
            if (ctrl && !alt && e.key === Qt.Key_L) { selectLineCmd(); e.accepted = true; return; }
            if (ctrl && shift && e.key === Qt.Key_K) { deleteLines(); e.accepted = true; return; }
            if (ctrl && shift && e.key === Qt.Key_D) { duplicateLines(); e.accepted = true; return; }
            if (ctrl && !alt && e.key === Qt.Key_Z) { if (shift) redo(); else undo(); e.accepted = true; return; }
            if (ctrl && !shift && e.key === Qt.Key_Y) { redo(); e.accepted = true; return; }
            if (ctrl && (e.key === Qt.Key_Tab || e.key === Qt.Key_Backtab)) { ed.cycleTab(e.key === Qt.Key_Backtab || shift ? -1 : 1); e.accepted = true; return; }
            if (alt && !ctrl && (e.key === Qt.Key_Up || e.key === Qt.Key_Down)) {
                if (shift) {                                  // Shift+Alt+↑/↓ = duplicate
                    duplicateLines();
                } else moveLines(e.key === Qt.Key_Down ? 1 : -1);
                e.accepted = true; return;
            }
            if (ctrl || alt) return;
            if (e.key === Qt.Key_Tab) {
                if (selHi > selLo) indentLines(1);
                else {
                    var unit = useTabs ? "\t" : Array(ed.tabSize - (curCol % ed.tabSize) + 1).join(" ");
                    var ts0 = te.selectionStart;
                    replaceRange(ts0, te.selectionEnd, unit);
                    te.cursorPosition = ts0 + unit.length;
                }
                e.accepted = true; return;
            }
            if (e.key === Qt.Key_Backtab) { indentLines(-1); e.accepted = true; return; }
            if ((e.key === Qt.Key_Return || e.key === Qt.Key_Enter) && !shift) {
                // auto-indent: keeps the current line's indentation
                sync();
                var ls = starts[lineOf(te.selectionStart)];
                var before = te.getText(ls, te.selectionStart);
                var ws = before.match(/^[ \t]*/)[0];
                var rs0 = te.selectionStart;
                replaceRange(rs0, te.selectionEnd, "\n" + ws);
                te.cursorPosition = rs0 + 1 + ws.length;
                e.accepted = true; return;
            }
            if (e.key === Qt.Key_Backspace && !useTabs && te.selectionStart === te.selectionEnd && curCol > 0) {
                // "smart" backspace over indentation spaces
                var pre = te.getText(starts[curLine], te.cursorPosition);
                if (/^ +$/.test(pre)) {
                    var n = pre.length % ed.tabSize || ed.tabSize;
                    te.remove(te.cursorPosition - n, te.cursorPosition);
                    e.accepted = true; return;
                }
            }
            if (e.key === Qt.Key_Home && !ed.wrap) {
                // "smart" home: first visible character ⇄ column 0
                sync();
                var l = lineOf(te.cursorPosition), st = starts[l];
                var lead = te.getText(st, lineEnd(l)).match(/^[ \t]*/)[0].length;
                var target = te.cursorPosition === st + lead ? st : st + lead;
                if (shift) te.moveCursorSelection(target, TextEdit.SelectCharacters);
                else te.cursorPosition = target;
                e.accepted = true; return;
            }
        }

        // ── scrolling ──
        function ensureVisible(r) {
            var m = ed.lineH;
            var maxY = Math.max(0, flick.contentHeight - flick.height);
            if (r.y < flick.contentY + m * 0.5) flick.contentY = Math.max(0, r.y - m);
            else if (r.y + r.height > flick.contentY + flick.height - m * 0.5) flick.contentY = Math.min(maxY, r.y + r.height - flick.height + m);
            var maxX = Math.max(0, flick.contentWidth - flick.width);
            if (r.x < flick.contentX + ed.charW) flick.contentX = Math.max(0, r.x - ed.charW * 8);
            else if (r.x + 2 > flick.contentX + flick.width - ed.charW * 2) flick.contentX = Math.min(maxX, r.x - flick.width + ed.charW * 10);
        }
        function centerOn(s, e) {
            var r = te.positionToRectangle(s), r2 = te.positionToRectangle(e);
            var maxY = Math.max(0, flick.contentHeight - flick.height);
            if (r.y < flick.contentY || r2.y + r2.height > flick.contentY + flick.height)
                flick.contentY = Math.max(0, Math.min(maxY, r.y - flick.height / 3));
            var maxX = Math.max(0, flick.contentWidth - flick.width);
            if (r.x < flick.contentX || r2.x > flick.contentX + flick.width - ed.charW * 2)
                flick.contentX = Math.max(0, Math.min(maxX, r.x - flick.width / 3));
        }
        function updateGutter() {
            if (!visible) return;
            var s = starts, n = s.length;
            var top = flick.contentY, bot = top + flick.height;
            var lo = 0, hi = n - 1;
            while (lo < hi) {
                var mid = (lo + hi + 1) >> 1;
                if (te.positionToRectangle(s[mid]).y <= top) lo = mid; else hi = mid - 1;
            }
            var rows = [], i;
            for (i = lo; i < n; i++) {
                var r = te.positionToRectangle(s[i]);
                if (r.y > bot) break;
                rows.push({ n: i + 1, y: r.y - top, h: r.height });
                if (rows.length > 800) break;
            }
            gutterRows = rows;
            // highlight visible matches
            var hl = [];
            if (matches.length) {
                var ps = s[lo], pe = i < n ? s[i] : te.length;
                var a = 0, b = matches.length;
                while (a < b) { var md = (a + b) >> 1; if (matches[md].e < ps) a = md + 1; else b = md; }
                for (var k = a; k < matches.length && matches[k].s <= pe && hl.length < 600; k++) {
                    var m = matches[k];
                    var r1 = te.positionToRectangle(m.s), r2 = te.positionToRectangle(m.e);
                    var w = Math.abs(r2.y - r1.y) < 1 ? Math.max(3, r2.x - r1.x) : Math.max(3, te.width - te.rightPadding - r1.x);
                    hl.push({ x: r1.x, y: r1.y, w: w, h: r1.height, cur: k === matchIdx });
                }
            }
            hlRows = hl;
        }

        property bool cursorOn: true
        Timer { id: blink; interval: 530; repeat: true; running: te.activeFocus && ed.visible; onTriggered: doc.cursorOn = !doc.cursorOn }

        // ── disk notices ──
        Rectangle {
            id: banner
            readonly property bool show: doc.changedOnDisk || doc.missing || (!doc.writable && !doc.untitled)
            visible: show
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: show ? ed.px(40) : 0
            color: ed.ga(doc.writable ? ed.cTertiary : ed.cError, 0.12)
            Glyph {
                id: bnIco
                x: 14
                anchors.verticalCenter: parent.verticalCenter
                text: doc.missing ? "delete" : doc.changedOnDisk ? "sync_problem" : "lock"
                size: ed.px(17)
                color: doc.writable ? ed.cTertiary : ed.cError
            }
            Text {
                anchors.left: bnIco.right
                anchors.leftMargin: 10
                anchors.right: bnBtns.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                text: doc.missing ? ed.tx("El archivo se eliminó o se movió. Guarda para volver a crearlo.", "The file was deleted or moved. Save to recreate it.")
                    : doc.changedOnDisk ? ed.tx("El archivo cambió en el disco y tienes cambios sin guardar.", "The file changed on disk and you have unsaved changes.")
                    : ed.tx("Solo lectura: no tienes permiso para guardar aquí.", "Read-only: you can't save here.")
                font.family: ed.fontB
                font.pixelSize: ed.px(12)
                color: ed.cOnSurface
            }
            Row {
                id: bnBtns
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                PillBtn {
                    visible: doc.changedOnDisk
                    height: ed.px(28)
                    label: ed.tx("Recargar", "Reload")
                    onClicked: ed.reloadDoc(doc)
                }
                PillBtn {
                    visible: doc.changedOnDisk
                    height: ed.px(28)
                    label: ed.tx("Mantener los míos", "Keep mine")
                    onClicked: doc.changedOnDisk = false
                }
                PillBtn {
                    visible: !doc.writable && !doc.changedOnDisk && !doc.missing
                    height: ed.px(28)
                    label: ed.tx("Guardar como…", "Save as…")
                    onClicked: ed.openSaveAs(doc, null)
                }
            }
        }

        // ── line numbers ──
        Rectangle {
            id: gutter
            anchors.left: parent.left
            anchors.top: banner.bottom
            anchors.bottom: parent.bottom
            readonly property int digits: Math.max(3, String(doc.lineTotal).length)
            width: Math.round(ed.charW * digits + ed.px(30))
            color: ed.bgGutter
            clip: true
            Repeater {
                model: doc.gutterRows
                delegate: Item {
                    id: gr
                    required property var modelData
                    readonly property int ln: modelData.n - 1
                    readonly property bool inSel: doc.selChars > 0 && ln >= doc.selLo && ln <= doc.selHi
                    y: modelData.y
                    width: gutter.width
                    height: modelData.h
                    Rectangle {
                        anchors.fill: parent
                        visible: gr.inSel
                        color: ed.ga(ed.cPrimary, 0.14)
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: ed.px(14)
                        height: ed.lineH
                        verticalAlignment: Text.AlignVCenter
                        text: gr.modelData.n
                        font.family: ed.monoFont
                        font.pixelSize: ed.codeSize * 0.9
                        color: gr.ln === doc.curLine ? ed.cOnSurface : (gr.inSel ? ed.cPrimary : ed.ga(ed.cMuted, 0.8))
                        font.weight: gr.ln === doc.curLine ? Font.DemiBold : Font.Normal
                    }
                }
            }
            // click = select line · drag = several · Shift+click = extend
            MouseArea {
                id: gutterMa
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                property int anchorLine: 0
                property real lastY: 0
                function lineAtY(y) {
                    var yy = Math.max(0, Math.min(y, gutter.height - 1)) + flick.contentY;
                    return doc.lineOf(te.positionAt(te.leftPadding, yy));
                }
                onPressed: (m) => {
                    doc.sync();
                    var l = lineAtY(m.y);
                    if (m.modifiers & Qt.ShiftModifier) {
                        var anchorPos = te.cursorPosition === te.selectionEnd ? te.selectionStart : te.selectionEnd;
                        anchorLine = doc.lineOf(anchorPos);
                    } else anchorLine = l;
                    lastY = m.y;
                    doc.selectLines(anchorLine, l);
                    te.forceActiveFocus();
                }
                onPositionChanged: (m) => {
                    if (!pressed) return;
                    lastY = m.y;
                    doc.selectLines(anchorLine, lineAtY(m.y));
                }
                Timer {
                    interval: 30
                    repeat: true
                    running: gutterMa.pressed && (gutterMa.lastY < 0 || gutterMa.lastY > gutter.height)
                    onTriggered: {
                        var dy = gutterMa.lastY < 0 ? gutterMa.lastY : gutterMa.lastY - gutter.height;
                        var maxY = Math.max(0, flick.contentHeight - flick.height);
                        flick.contentY = Math.max(0, Math.min(maxY, flick.contentY + dy * 0.6));
                        doc.selectLines(gutterMa.anchorLine, gutterMa.lineAtY(gutterMa.lastY));
                    }
                }
            }
        }

        // ── text ──
        Flickable {
            id: flick
            anchors.left: gutter.right
            anchors.right: parent.right
            anchors.top: banner.bottom
            anchors.bottom: parent.bottom
            clip: true
            interactive: false
            boundsBehavior: Flickable.StopAtBounds
            contentWidth: te.width
            contentHeight: te.height
            ScrollBar.vertical: EdScrollBar {}
            ScrollBar.horizontal: EdScrollBar {}
            onContentYChanged: Qt.callLater(doc.updateGutter)
            onHeightChanged: Qt.callLater(doc.updateGutter)
            onWidthChanged: Qt.callLater(doc.updateGutter)

            // highlights (below the text)
            Item {
                width: te.width
                height: te.height
                Rectangle {          // current line
                    visible: te.selectionStart === te.selectionEnd
                    y: te.cursorRectangle.y
                    width: parent.width
                    height: te.cursorRectangle.height
                    color: ed.ga(ed.cOnSurfVar, ed.light ? 0.07 : 0.055)
                }
                Repeater {
                    model: doc.hlRows
                    delegate: Rectangle {
                        required property var modelData
                        x: modelData.x - 1
                        y: modelData.y
                        width: modelData.w + 2
                        height: modelData.h
                        radius: 3
                        color: modelData.cur ? ed.ga(ed.cPrimary, 0.42) : ed.ga(ed.cTertiary, 0.22)
                        border.width: modelData.cur ? 1 : 0
                        border.color: ed.cPrimary
                    }
                }
            }

            TextEdit {
                id: te
                width: ed.wrap ? flick.width : Math.max(flick.width, implicitWidth)
                height: Math.max(implicitHeight + flick.height * 0.5, flick.height)
                leftPadding: ed.px(12)
                rightPadding: ed.px(28)
                topPadding: ed.px(6)
                bottomPadding: ed.px(6)
                textFormat: TextEdit.PlainText
                wrapMode: ed.wrap ? TextEdit.WrapAtWordBoundaryOrAnywhere : TextEdit.NoWrap
                font.family: ed.monoFont
                font.pixelSize: ed.codeSize
                color: ed.cOnSurface
                selectionColor: ed.ga(ed.cPrimary, 0.36)
                selectedTextColor: ed.cOnSurface
                selectByMouse: true
                persistentSelection: true
                tabStopDistance: ed.charW * ed.tabSize
                activeFocusOnPress: true
                focus: true
                cursorDelegate: Rectangle {
                    width: Math.max(2, ed.px(2))
                    radius: 1
                    color: ed.cPrimary
                    visible: te.activeFocus && doc.cursorOn
                }
                onTextChanged: doc.onEdited()
                onCursorPositionChanged: doc.cursorMoved()
                onSelectionStartChanged: doc.cursorMoved()
                onSelectionEndChanged: doc.cursorMoved()
                onCursorRectangleChanged: if (activeFocus) doc.ensureVisible(cursorRectangle)
                onContentHeightChanged: Qt.callLater(doc.updateGutter)
                onWidthChanged: Qt.callLater(doc.updateGutter)
                Keys.onPressed: (e) => doc.handleKey(e)

                // context menu (the left button still reaches the TextEdit)
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    cursorShape: Qt.IBeamCursor
                    onPressed: (m) => {
                        var p = te.positionAt(m.x, m.y);
                        if (p < te.selectionStart || p > te.selectionEnd || te.selectionStart === te.selectionEnd) te.cursorPosition = p;
                        te.forceActiveFocus();
                        var g = mapToItem(rootBg, m.x, m.y);
                        ed.editMenu(doc, g.x, g.y);
                    }
                }
            }
        }

        // smooth wheel (vertical, Shift = horizontal, Ctrl = zoom)
        MouseArea {
            id: wheelArea
            anchors.left: gutter.left
            anchors.right: flick.right
            anchors.top: flick.top
            anchors.bottom: flick.bottom
            acceptedButtons: Qt.NoButton
            z: 50
            property real goalY: 0
            property real goalX: 0
            onWheel: (w) => {
                if (w.modifiers & Qt.ControlModifier) {
                    var dz = w.angleDelta.y > 0 ? 0.1 : (w.angleDelta.y < 0 ? -0.1 : 0);
                    ed.zoom = Math.max(0.5, Math.min(3, Math.round((ed.zoom + dz) * 10) / 10));
                    return;
                }
                var ay = w.angleDelta.y, ax = w.angleDelta.x, py = w.pixelDelta.y, pxx = w.pixelDelta.x;
                if (w.modifiers & Qt.ShiftModifier) { ax = ax || ay; ay = 0; pxx = pxx || py; py = 0; }
                var maxY = Math.max(0, flick.contentHeight - flick.height);
                var maxX = Math.max(0, flick.contentWidth - flick.width);
                var touchpad = ay === 0 && ax === 0 && (py !== 0 || pxx !== 0);
                if (touchpad) {
                    yAnim.stop(); xAnim.stop();
                    flick.contentY = Math.max(0, Math.min(maxY, flick.contentY - py * 1.4));
                    flick.contentX = Math.max(0, Math.min(maxX, flick.contentX - pxx * 1.4));
                    return;
                }
                if (ay !== 0) {
                    var by = yAnim.running ? goalY : flick.contentY;
                    goalY = Math.max(0, Math.min(maxY, by - ay / 120 * ed.lineH * 3.5));
                    yAnim.stop(); yAnim.from = flick.contentY; yAnim.to = goalY; yAnim.start();
                }
                if (ax !== 0) {
                    var bx = xAnim.running ? goalX : flick.contentX;
                    goalX = Math.max(0, Math.min(maxX, bx - ax / 120 * ed.charW * 12));
                    xAnim.stop(); xAnim.from = flick.contentX; xAnim.to = goalX; xAnim.start();
                }
            }
            NumberAnimation { id: yAnim; target: flick; property: "contentY"; duration: 200; easing.type: Easing.OutCubic }
            NumberAnimation { id: xAnim; target: flick; property: "contentX"; duration: 200; easing.type: Easing.OutCubic }
        }

        Text {
            anchors.centerIn: parent
            visible: doc.loading
            text: ed.tx("Cargando…", "Loading…")
            font.family: ed.fontB
            font.pixelSize: ed.px(13)
            color: ed.cMuted
        }
    }

    // ══ Components ══
    component Glyph: Text {
        property real size: 18
        font.family: "Material Symbols Rounded"
        font.pixelSize: size
        color: ed.cOnSurfVar
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }

    component EdScrollBar: ScrollBar {
        id: sb
        policy: ScrollBar.AsNeeded
        minimumSize: 0.04
        contentItem: Rectangle {
            implicitWidth: 7
            implicitHeight: 7
            radius: 3.5
            color: ed.ga(ed.cOnSurfVar, sb.pressed ? 0.55 : (sb.hovered ? 0.42 : 0.26))
            opacity: sb.size < 1 && (sb.active || sb.hovered) ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 220 } }
        }
        background: Item {}
    }

    component WheelCatcher: MouseArea {
        id: wc
        property var flick: null
        property real goal: 0
        anchors.fill: flick
        acceptedButtons: Qt.NoButton
        z: 50
        function maxY() { return Math.max(flick.originY, flick.originY + flick.contentHeight - flick.height); }
        onWheel: (w) => {
            if (!flick) return;
            var a = w.angleDelta.y, p = w.pixelDelta.y;
            if (a === 0 && p !== 0) {
                wcAnim.stop();
                flick.contentY = Math.max(flick.originY, Math.min(wc.maxY(), flick.contentY - p * 1.4));
                return;
            }
            var base = wcAnim.running ? wc.goal : flick.contentY;
            wc.goal = Math.max(flick.originY, Math.min(wc.maxY(), base - a / 120 * ed.px(120)));
            wcAnim.stop();
            wcAnim.from = flick.contentY;
            wcAnim.to = wc.goal;
            wcAnim.start();
        }
        NumberAnimation { id: wcAnim; target: wc.flick; property: "contentY"; duration: 220; easing.type: Easing.OutCubic }
    }

    component IconBtn: Rectangle {
        id: ib
        property string glyph: ""
        property string tip: ""
        property bool active: false
        property bool danger: false
        property real gsize: 18
        signal clicked()
        implicitWidth: 32
        implicitHeight: 32
        width: implicitWidth
        height: implicitHeight
        radius: Math.min(10, height / 2)
        opacity: enabled ? 1 : 0.35
        color: active ? ed.ga(ed.cPrimary, 0.18)
             : (ibHov.hovered ? (danger ? ed.ga(ed.cError, 0.16) : ed.hovCol) : "transparent")
        Behavior on color { ColorAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Glyph {
            anchors.centerIn: parent
            text: ib.glyph
            size: ib.gsize
            color: ib.active ? ed.cPrimary : (ib.danger && ibHov.hovered ? ed.cError : ed.cOnSurfVar)
            Behavior on color { ColorAnimation { duration: 160 } }
        }
        HoverHandler {
            id: ibHov
            cursorShape: Qt.PointingHandCursor
            onHoveredChanged: { if (hovered && ib.tip !== "") ed.showTip(ib.tip, ib); else ed.hideTip(ib); }
        }
        MouseArea { anchors.fill: parent; onClicked: { ed.hideTip(ib); ib.clicked(); } }
    }

    // top bar button ("File", "Search")
    component BarBtn: Rectangle {
        id: bb
        property string glyph: ""
        property string label: ""
        property bool arrow: false
        property bool active: false
        signal clicked()
        implicitHeight: ed.px(34)
        implicitWidth: bbRow.width + ed.px(26)
        width: implicitWidth
        height: implicitHeight
        radius: height / 2
        color: active ? ed.ga(ed.cPrimary, 0.20) : (bbHov.hovered ? ed.hovCol : ed.ga(ed.cOnSurfVar, 0.06))
        Behavior on color { ColorAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Row {
            id: bbRow
            anchors.centerIn: parent
            spacing: 6
            Glyph {
                anchors.verticalCenter: parent.verticalCenter
                text: bb.glyph
                size: ed.px(17)
                color: bb.active ? ed.cPrimary : ed.cOnSurfVar
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: bb.label
                font.family: ed.fontB
                font.pixelSize: ed.px(12.5)
                font.weight: Font.DemiBold
                color: bb.active ? ed.cPrimary : ed.cOnSurface
            }
            Glyph {
                visible: bb.arrow
                anchors.verticalCenter: parent.verticalCenter
                text: "expand_more"
                size: ed.px(16)
                color: bb.active ? ed.cPrimary : ed.cMuted
                rotation: bb.active ? 180 : 0
                Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }
        }
        HoverHandler { id: bbHov; cursorShape: Qt.PointingHandCursor }
        MouseArea { anchors.fill: parent; onClicked: bb.clicked() }
    }

    component PillBtn: Rectangle {
        id: pb
        property string glyph: ""
        property string label: ""
        property bool primary: false
        property bool danger: false
        signal clicked()
        implicitHeight: ed.px(32)
        implicitWidth: pbRow.width + ed.px(28)
        width: implicitWidth
        height: implicitHeight
        radius: height / 2
        opacity: enabled ? 1 : 0.4
        readonly property color base: danger ? ed.cError : ed.cPrimary
        color: primary ? (pbHov.hovered ? Qt.lighter(base, 1.08) : base)
                       : (pbHov.hovered ? ed.ga(base, 0.22) : ed.ga(base, 0.12))
        Behavior on color { ColorAnimation { duration: 160 } }
        Row {
            id: pbRow
            anchors.centerIn: parent
            spacing: 6
            Glyph {
                visible: pb.glyph !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: pb.glyph
                size: ed.px(16)
                color: pb.primary ? (pb.danger ? Qt.darker(ed.cError, 3) : ed.cOnPrimary) : pb.base
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: pb.label
                font.family: ed.fontB
                font.pixelSize: ed.px(12.5)
                font.weight: Font.DemiBold
                color: pb.primary ? (pb.danger ? Qt.darker(ed.cError, 3) : ed.cOnPrimary) : pb.base
            }
        }
        HoverHandler { id: pbHov; cursorShape: Qt.PointingHandCursor }
        MouseArea { anchors.fill: parent; onClicked: pb.clicked() }
    }

    component StatusText: Text {
        id: stt
        property string tip: ""
        signal clicked()
        font.family: ed.fontB
        font.pixelSize: ed.px(11.5)
        color: sttHov.hovered ? ed.cOnSurface : ed.cMuted
        HoverHandler {
            id: sttHov
            cursorShape: Qt.PointingHandCursor
            onHoveredChanged: { if (hovered && stt.tip !== "") ed.showTip(stt.tip, stt); else ed.hideTip(stt); }
        }
        MouseArea { anchors.fill: parent; anchors.margins: -4; onClicked: stt.clicked() }
    }

    component Field: Rectangle {
        id: fld
        property alias text: fin.text
        property alias input: fin
        property string placeholder: ""
        property string glyph: ""
        default property alias extra: fldRight.data
        signal accepted()
        signal shiftAccepted()
        signal escaped()
        signal downPressed()
        signal edited(string t)
        implicitHeight: ed.px(32)
        radius: height / 2
        color: ed.bgField
        border.width: fin.activeFocus ? 1 : 0
        border.color: ed.ga(ed.cPrimary, 0.6)
        Glyph {
            id: fldIco
            visible: fld.glyph !== ""
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: fld.glyph
            size: ed.px(17)
            color: fin.activeFocus ? ed.cPrimary : ed.cMuted
        }
        TextInput {
            id: fin
            anchors.left: fldIco.visible ? fldIco.right : parent.left
            anchors.leftMargin: fldIco.visible ? 6 : 14
            anchors.right: fldRight.left
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            clip: true
            color: ed.cOnSurface
            font.family: ed.fontB
            font.pixelSize: ed.px(12.5)
            selectByMouse: true
            selectionColor: ed.ga(ed.cPrimary, 0.45)
            selectedTextColor: ed.cOnSurface
            onAccepted: fld.accepted()
            onTextEdited: fld.edited(text)
            Keys.onPressed: (e) => {
                if ((e.key === Qt.Key_Return || e.key === Qt.Key_Enter) && (e.modifiers & Qt.ShiftModifier)) { fld.shiftAccepted(); e.accepted = true; }
            }
            Keys.onEscapePressed: (e) => { fld.escaped(); e.accepted = true; }
            Keys.onDownPressed: (e) => { fld.downPressed(); e.accepted = true; }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: fin.text === "" && fin.preeditText === ""
                text: fld.placeholder
                font: fin.font
                color: ed.cMuted
                elide: Text.ElideRight
                width: fin.width
            }
        }
        Row {
            id: fldRight
            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0
        }
    }

    // menu panel (level 0 = main, level 1 = submenu)
    component MenuPanel: Rectangle {
        id: mp
        property var items: []
        property bool shown: false
        property int level: 0
        height: mpCol.height + 12
        radius: 18
        color: ed.bgPop
        border.width: 1
        border.color: ed.lineCol
        visible: opacity > 0.01
        scale: shown ? 1 : 0.94
        opacity: shown ? 1 : 0
        transformOrigin: Item.TopLeft
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 120 } }
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }
        Column {
            id: mpCol
            x: 6
            y: 6
            width: mp.width - 12
            Repeater {
                model: mp.items
                delegate: Item {
                    id: mi
                    required property var modelData
                    readonly property bool subShown: ed.subOpen && ed.subOwner === mi
                    width: mpCol.width
                    height: modelData.sep ? 9 : ed.px(33)
                    Rectangle {
                        visible: !!mi.modelData.sep
                        anchors.centerIn: parent
                        width: parent.width - 16
                        height: 1
                        color: ed.lineCol
                    }
                    Rectangle {
                        visible: !mi.modelData.sep
                        anchors.fill: parent
                        radius: 11
                        opacity: mi.modelData.disabled ? 0.4 : 1
                        color: (miHov.hovered || mi.subShown) && !mi.modelData.disabled ? (mi.modelData.danger ? ed.ga(ed.cError, 0.14) : ed.hovCol) : "transparent"
                        Glyph {
                            id: miIco
                            x: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: mi.modelData.icon || ""
                            size: ed.px(17)
                            color: mi.modelData.danger ? ed.cError : ed.cOnSurfVar
                        }
                        Text {
                            id: miTxt
                            anchors.left: miIco.right
                            anchors.leftMargin: 10
                            anchors.right: miKey.left
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: mi.modelData.label || ""
                            elide: Text.ElideRight
                            font.family: ed.fontB
                            font.pixelSize: ed.px(12.5)
                            font.weight: Font.Medium
                            color: mi.modelData.danger ? ed.cError : ed.cOnSurface
                        }
                        Text {
                            id: miKey
                            anchors.right: miArrow.visible ? miArrow.left : parent.right
                            anchors.rightMargin: miArrow.visible ? 2 : 10
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.min(implicitWidth, ed.px(190))
                            elide: Text.ElideMiddle
                            text: mi.modelData.key || ""
                            font.family: ed.fontB
                            font.pixelSize: ed.px(10.5)
                            color: ed.cMuted
                        }
                        Glyph {
                            id: miArrow
                            visible: !!mi.modelData.sub
                            anchors.right: parent.right
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            text: "chevron_right"
                            size: ed.px(17)
                            color: ed.cMuted
                        }
                        HoverHandler {
                            id: miHov
                            enabled: !mi.modelData.disabled
                            cursorShape: Qt.PointingHandCursor
                            onHoveredChanged: {
                                if (!hovered || mp.level !== 0) return;
                                if (mi.modelData.sub) ed.openSub(mi.modelData.sub, mi);
                                else { ed.subOpen = false; ed.subOwner = null; }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: !mi.modelData.disabled
                            onClicked: {
                                if (mi.modelData.sub) ed.openSub(mi.modelData.sub, mi);
                                else ed.runMenu(mi.modelData);
                            }
                        }
                    }
                }
            }
        }
    }
}
