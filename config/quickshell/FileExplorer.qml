// FileExplorer.qml — file explorer; disk work in scripts/fm_backend.py
import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "i18n/apps.js" as AppStrings

Window {
    id: fm
    property var gs
    property var colors

    // inst 0 = main window; inst > 0 = extra window
    property int  inst: 0
    property bool extraOpen: true
    readonly property bool winOpen: inst === 0 ? (gs ? gs.fileExplorerOpen : false) : extraOpen
    function closeWin() {
        if (inst === 0) { if (gs) gs.fileExplorerOpen = false; return; }
        extraOpen = false;
        var g = gs, n = inst;
        if (g && typeof g.closeAppExtra === "function") Qt.callLater(function () { g.closeAppExtra("files", n); });
    }

    title: tx("Archivos", "Files")
    visible: winOpen
    color: "transparent"
    width: 1280
    height: 800
    minimumWidth: 760
    minimumHeight: 480

    onClosing: (close) => { fm.closeWin(); }
    onVisibleChanged: {
        if (!visible && fm.winOpen) fm.closeWin();
        if (!visible && fm.inst === 0 && gs && gs.textEditorPicking) gs.textEditorPicking = false;
        if (visible && fm.inst === 0 && gs && gs.textEditorPicking)
            Qt.callLater(function () { fm.toast(fm.tx("Elige un archivo para abrirlo en el editor", "Pick a file to open it in the editor")); });
        if (visible) {
            refreshPlaces();
            takeExternalPath();
            Qt.callLater(fm.refocus);
        }
    }

    // ── style ──
    readonly property bool   glass: gs ? gs.glassMode : false
    readonly property bool   light: gs ? gs.colorMode === "light" : false
    readonly property real   fs:    gs ? gs.fontScale : 1
    readonly property string fontA: gs ? gs.fontPrimary : "sans-serif"
    readonly property string fontB: gs ? gs.fontSecondary : "sans-serif"
    readonly property bool   h24:   gs ? gs.clockFormat24h : true
    readonly property string lang:  gs ? gs.language : "es"
    readonly property string mono:  "monospace"

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
    readonly property color bgSide:    light ? Qt.rgba(0, 0, 0, 0.035) : Qt.rgba(0, 0, 0, 0.18)
    readonly property color bgCont:    glass ? ga(cdark(cSecCont), 0.6) : cdark(cSecCont)
    readonly property color bgField:   ga(cOnSurfVar, light ? 0.09 : 0.075)
    readonly property color bgPop:     glass ? ga(cSurfHigh, 0.97) : cSurfHigh
    readonly property color lineCol:   light ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, 0.07)
    readonly property color hovCol:    ga(cOnSurfVar, 0.10)
    readonly property color selCol:    ga(cPrimary, 0.20)
    readonly property color selStrong: ga(cPrimary, 0.34)
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
    // metadata labels come from fm_backend.py in English; translate the known ones
    function metaLabel(en) {
        if (lang === "en") return en;
        var entry = AppStrings.metaLabels[en];
        return (entry && entry[lang]) || en;
    }

    // ───────────────────────── utilities ─────────────────────────
    function fmtSize(b) {
        if (b === undefined || b === null || b < 0) return "—";
        if (b < 1024) return b + " B";
        var u = ["KB", "MB", "GB", "TB", "PB"], i = -1;
        do { b /= 1024; i++; } while (b >= 1024 && i < u.length - 1);
        return (b >= 100 ? b.toFixed(0) : b.toFixed(1)) + " " + u[i];
    }
    function fmtDate(t, full) {
        if (!t) return "—";
        var d = new Date(t * 1000), now = new Date();
        var tf = h24 ? (full ? "HH:mm:ss" : "HH:mm") : (full ? "h:mm:ss AP" : "h:mm AP");
        var sod = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime() / 1000;
        if (!full) {
            if (t >= sod) return tx("Hoy", "Today") + " " + Qt.formatTime(d, tf);
            if (t >= sod - 86400) return tx("Ayer", "Yesterday") + " " + Qt.formatTime(d, tf);
        }
        return Qt.formatDateTime(d, (lang === "es" ? "dd/MM/yyyy " : "yyyy-MM-dd ") + tf);
    }
    function countLabel(n) { return n === 1 ? tx("1 elemento", "1 item") : n + " " + tx("elementos", "items"); }
    function baseName(p) {
        if (!p) return "";
        if (p === "/") return "/";
        if (p === "trash://") return tx("Papelera", "Trash");
        var s = p.replace(/\/+$/, "");
        return s.substring(s.lastIndexOf("/") + 1);
    }
    function dirName(p) {
        var s = p.replace(/\/+$/, "");
        var i = s.lastIndexOf("/");
        return i <= 0 ? "/" : s.substring(0, i);
    }
    function stemLen(n, isDir) {
        if (isDir) return n.length;
        var low = n.toLowerCase();
        var multi = [".tar.gz", ".tar.xz", ".tar.bz2", ".tar.zst"];
        for (var i = 0; i < multi.length; i++)
            if (low.length > multi[i].length && low.endsWith(multi[i])) return n.length - multi[i].length;
        var k = n.lastIndexOf(".");
        return k > 0 ? k : n.length;
    }
    function prettyPath(p) {
        if (p === "trash://") return tx("Papelera", "Trash");
        if (home && (p === home || p.indexOf(home + "/") === 0)) return "~" + p.substring(home.length);
        return p;
    }
    function expandPath(t, base) {
        t = (t || "").trim();
        if (t === "") return base;
        if (t === "~") return home;
        if (t.indexOf("~/") === 0) return home + t.substring(1);
        if (t.indexOf("file://") === 0) return urlToPath(t);
        if (t.charAt(0) !== "/" && t !== "trash://") return (base === "/" ? "" : base) + "/" + t;
        return t;
    }
    function fileUrl(p) { return "file://" + p.split("/").map(encodeURIComponent).join("/"); }
    function urlToPath(u) {
        var s = u.toString();
        if (s.indexOf("file://") !== 0) return "";
        s = s.substring(7);
        if (s.charAt(0) !== "/") s = s.substring(s.indexOf("/"));
        try { return decodeURIComponent(s); } catch (e) { return s; }
    }
    function mimeFor(paths) {
        return { "text/uri-list": paths.map(fileUrl).join("\r\n") + "\r\n", "text/plain": paths.join("\n") };
    }
    function globRx(g) {
        var s = "^";
        for (var i = 0; i < g.length; i++) {
            var c = g.charAt(i);
            if (c === "*") s += ".*";
            else if (c === "?") s += ".";
            else if (c === "[") {
                var j = g.indexOf("]", i + 1);
                if (j < 0) { s += "\\["; continue; }
                s += "[" + g.substring(i + 1, j).replace(/\\/g, "\\\\") + "]";
                i = j;
            } else s += c.replace(/[.+^${}()|\\\]\/]/g, "\\$&");
        }
        try { return new RegExp(s + "$"); } catch (e) { return null; }
    }
    function _nk(e) {
        if (e._nk === undefined) e._nk = e.n.toLowerCase().match(/(\d+|\D+)/g) || [];
        return e._nk;
    }
    function natCmp(x, y) {
        var a = _nk(x), b = _nk(y);
        var n = Math.min(a.length, b.length);
        for (var i = 0; i < n; i++) {
            var p = a[i], q = b[i];
            if (p === q) continue;
            var pd = p.charCodeAt(0) >= 48 && p.charCodeAt(0) <= 57;
            var qd = q.charCodeAt(0) >= 48 && q.charCodeAt(0) <= 57;
            if (pd && qd) { var d = parseInt(p, 10) - parseInt(q, 10); if (d !== 0) return d; }
            return p.localeCompare(q);
        }
        return a.length - b.length;
    }
    function sorter(trash) {
        var k = sortKey, asc = sortAsc ? 1 : -1, ff = foldersFirst;
        return function (x, y) {
            if (ff && x.d !== y.d) return x.d ? -1 : 1;
            var r = 0;
            if (k === "size") r = (x.d && y.d) ? ((x.k || 0) - (y.k || 0)) : (x.s - y.s);
            else if (k === "mtime") r = trash ? ((x.del || x.m) - (y.del || y.m)) : (x.m - y.m);
            else if (k === "type") r = (x.e || "").localeCompare(y.e || "") || x.c.localeCompare(y.c);
            if (r === 0) r = natCmp(x, y);
            return r * asc;
        };
    }
    function nameSorter(x, y) { return natCmp(x, y); }
    function visibleOnly(list) {
        if (showHidden) return list;
        return list.filter(function (e) { return !e.h; });
    }

    function catIcon(e) {
        if (!e) return "draft";
        if (e.b) return "link_off";
        if (e.d) return placeIcons[e.p] || (e.l ? "folder_special" : "folder");
        switch (e.c) {
        case "image": return "image";
        case "video": return "movie";
        case "audio": return "music_note";
        case "archive": return "folder_zip";
        case "pdf": return "picture_as_pdf";
        case "doc": return "description";
        case "code": return "code";
        case "exec": return "terminal";
        }
        return "draft";
    }
    function catColor(c) {
        switch (c) {
        case "dir": return cPrimary;
        case "image": return cTertiary;
        case "video": return cAccent;
        case "audio": return cPositive;
        case "archive": return Qt.tint(cPrimary, ga(cTertiary, 0.55));
        case "pdf": return cError;
        case "code": return cAccent;
        case "exec": return cPositive;
        }
        return cOnSurfVar;
    }
    function catName(c) {
        switch (c) {
        case "dir": return tx("Carpeta", "Folder");
        case "image": return tx("Imagen", "Image");
        case "video": return tx("Vídeo", "Video");
        case "audio": return tx("Audio", "Audio");
        case "archive": return tx("Comprimido", "Archive");
        case "pdf": return "PDF";
        case "doc": return tx("Documento", "Document");
        case "code": return tx("Código", "Source");
        case "exec": return tx("Ejecutable", "Executable");
        }
        return tx("Archivo", "File");
    }
    function typeLabel(e) {
        if (e.d) return e.l ? tx("Enlace a carpeta", "Folder link") : tx("Carpeta", "Folder");
        var b = catName(e.c);
        if (e.c === "pdf" || !e.e) return b;
        return b + " " + e.e.toUpperCase();
    }
    function subLabel(e) {
        if (e.d) return e.k === undefined ? tx("Carpeta", "Folder") : (e.k < 0 ? "—" : countLabel(e.k));
        return fmtSize(e.s);
    }
    function isImage(e) { return !!e && !e.d && e.c === "image" && ["heic", "heif", "jxl", "tif", "tiff"].indexOf(e.e) < 0 && e.s < 80000000; }
    function wantsThumb(e) { return e && !e.d && ((e.c === "video" && tools.ffmpeg) || (e.c === "pdf" && tools.pdftoppm)); }

    // video/pdf thumbnails (generated by the backend and cached on disk)
    property var thumbs: ({})
    property var _thumbPending: ({})
    function thumbFor(e) {
        if (!wantsThumb(e)) return "";
        var key = e.p + ":" + e.m;
        var t = thumbs[key];
        if (t !== undefined) return t;
        if (!_thumbPending[key]) {
            _thumbPending[key] = true;
            var p = e.p;
            // deferred: calling the backend from a binding would make it depend on _rid (loop)
            Qt.callLater(function () {
                fm.call("thumb", { path: p }, function (ok, d) {
                    var m = Object.assign({}, fm.thumbs);
                    m[key] = ok ? "file://" + d.path : "";
                    fm.thumbs = m;
                });
            });
        }
        return "";
    }

    // ───────────────────────── backend ─────────────────────────
    readonly property string backendPath: {
        var u = Qt.resolvedUrl("scripts/fm_backend.py").toString();
        return u.indexOf("file://") === 0 ? decodeURIComponent(u.substring(7)) : u;
    }
    property int  _rid: 0
    property bool _ready: false
    property var  _queue: []
    property var  _cbs: ({})
    property var  _evs: ({})
    signal dirChanged(string path)

    Process {
        id: backend
        command: ["python3", "-u", fm.backendPath]
        running: true
        stdinEnabled: true
        stdout: SplitParser { onRead: (data) => fm._onLine(data) }
        stderr: SplitParser { onRead: (data) => console.warn("[fm_backend] " + data) }
        onStarted: {
            fm._ready = true;
            var q = fm._queue;
            fm._queue = [];
            for (var i = 0; i < q.length; i++) backend.write(q[i]);
        }
        onExited: (code, status) => {
            fm._ready = false;
            var cbs = fm._cbs;
            fm._cbs = ({});
            fm._evs = ({});
            jobsModel.clear();
            for (var k in cbs) { try { cbs[k](false, "backend reiniciado"); } catch (e) {} }
            backendRestart.start();
        }
    }
    Timer { id: backendRestart; interval: 900; onTriggered: backend.running = true }

    function call(cmd, args, cb, onEv) {
        var id = ++_rid;
        if (cb) _cbs[id] = cb;
        if (onEv) _evs[id] = onEv;
        var line = JSON.stringify({ id: id, cmd: cmd, args: args || {} }) + "\n";
        if (_ready) backend.write(line); else _queue.push(line);
        return id;
    }
    function cancel(id) { if (id > 0) call("cancel", { job: id }); }
    function _onLine(l) {
        var o;
        try { o = JSON.parse(l); } catch (e) { return; }
        if (o.event !== undefined) {
            if (o.event === "job") _jobEvent(o);
            else if (o.event === "changed") { dirChanged(o.path); if (o.path === "trash://") refreshPlaces(); }
            else { var f = _evs[o.id]; if (f) f(o); }
            return;
        }
        var cb = _cbs[o.id];
        delete _cbs[o.id];
        delete _evs[o.id];
        _jobDone(o.id);
        if (cb) cb(o.ok, o.ok ? o.data : o.error);
        else if (!o.ok && o.error !== "cancelled") toast(o.error, true);
    }

    // ───────────────────────── running jobs ─────────────────────────
    ListModel { id: jobsModel }
    function _jobIndex(id) {
        for (var i = 0; i < jobsModel.count; i++) if (jobsModel.get(i).jid === id) return i;
        return -1;
    }
    function _jobEvent(o) {
        var row = { jid: o.id, kind: o.kind || "", label: o.label || "", done: o.done || 0, total: o.total || 0, cur: o.cur || "" };
        var i = _jobIndex(o.id);
        if (i < 0) jobsModel.append(row); else jobsModel.set(i, row);
    }
    function _jobDone(id) { var i = _jobIndex(id); if (i >= 0) jobsModel.remove(i); }
    function jobVerb(k) {
        var m = { copy: tx("Copiando", "Copying"), move: tx("Moviendo", "Moving"), "delete": tx("Eliminando", "Deleting"),
                  compress: tx("Comprimiendo", "Compressing"), extract: tx("Extrayendo", "Extracting") };
        return m[k] || k;
    }

    // ───────────────────────── notices ─────────────────────────
    property string toastText: ""
    property bool   toastErr: false
    function toast(t, err) { toastText = String(t); toastErr = !!err; toastTimer.restart(); }
    Timer { id: toastTimer; interval: 3800; onTriggered: fm.toastText = "" }

    // ───────────────────────── preferences ─────────────────────────
    property string layoutMode: "board"     // board | miller
    property string defaultView: "grid"     // grid | list | compact
    property bool   showHidden: false
    property bool   foldersFirst: true
    property string sortKey: "name"         // name | size | mtime | type
    property bool   sortAsc: true
    property bool   showDetails: false
    property real   sideW: 232
    property var    favorites: []
    property bool   prefsLoaded: false

    function savePrefs() { if (prefsLoaded) prefsTimer.restart(); }
    Timer {
        id: prefsTimer
        interval: 700
        onTriggered: fm.call("prefs_save", { prefs: {
            layoutMode: fm.layoutMode, defaultView: fm.defaultView, showHidden: fm.showHidden,
            foldersFirst: fm.foldersFirst, sortKey: fm.sortKey, sortAsc: fm.sortAsc,
            showDetails: fm.showDetails, sideW: fm.sideW, favorites: fm.favorites } })
    }
    onLayoutModeChanged: { savePrefs(); updateWatch(); }
    onDefaultViewChanged: savePrefs()
    onShowHiddenChanged: savePrefs()
    onFoldersFirstChanged: savePrefs()
    onSortKeyChanged: savePrefs()
    onSortAscChanged: savePrefs()
    onShowDetailsChanged: savePrefs()
    onSideWChanged: savePrefs()
    onFavoritesChanged: savePrefs()

    // ───────────────────────── places / devices ─────────────────────────
    property string home: ""
    property var places: []
    property var devices: []
    property var bookmarks: []
    property int trashCount: 0
    property var tools: ({})
    property var placeIcons: ({})
    function refreshPlaces() {
        call("places", {}, function (ok, d) {
            if (!ok) return;
            var first = fm.home === "";
            fm.home = d.home;
            fm.places = d.places;
            fm.devices = d.devices;
            fm.bookmarks = d.bookmarks || [];
            fm.trashCount = d.trashCount;
            fm.tools = d.tools || {};
            var m = {};
            for (var i = 0; i < d.places.length; i++) m[d.places[i].p] = d.places[i].icon;
            fm.placeIcons = m;
            if (first) treeInit();
        });
    }
    Timer { interval: 5000; repeat: true; running: fm.visible; onTriggered: fm.refreshPlaces() }

    function isFavorite(p) {
        for (var i = 0; i < favorites.length; i++) if (favorites[i].p === p) return true;
        return false;
    }
    function addFavorite(p) {
        if (!p || p === "trash://" || isFavorite(p)) return;
        favorites = favorites.concat([{ n: baseName(p), p: p }]);
        toast(tx("Añadido a favoritos: ", "Added to favorites: ") + baseName(p));
    }
    function removeFavorite(p) { favorites = favorites.filter(function (f) { return f.p !== p; }); }

    // ───────────────────────── folder tree (flattened list) ─────────────────────────
    ListModel { id: treeModel }
    function treeInit() {
        if (treeModel.count || !home) return;
        treeModel.append({ p: home, n: tx("Carpeta personal", "Home"), depth: 0, open: false, sub: true, icon: "home" });
        treeModel.append({ p: "/", n: tx("Sistema de archivos", "File system"), depth: 0, open: false, sub: true, icon: "hard_drive" });
    }
    function treeToggle(i) {
        var it = treeModel.get(i);
        var d = it.depth, p = it.p;
        if (it.open) {
            var j = i + 1;
            while (j < treeModel.count && treeModel.get(j).depth > d) j++;
            if (j > i + 1) treeModel.remove(i + 1, j - i - 1);
            treeModel.setProperty(i, "open", false);
            return;
        }
        treeModel.setProperty(i, "open", true);
        call("list", { path: p, dirsOnly: true }, function (ok, data) {
            var idx = -1;
            for (var k = 0; k < treeModel.count; k++) {
                var t = treeModel.get(k);
                if (t.p === p && t.depth === d) { idx = k; break; }
            }
            if (idx < 0 || !treeModel.get(idx).open) return;
            if (!ok) { treeModel.setProperty(idx, "open", false); fm.toast(data, true); return; }
            var ds = fm.visibleOnly(data.items).sort(fm.nameSorter).slice(0, 400);
            if (!ds.length) treeModel.setProperty(idx, "sub", false);
            for (var q = 0; q < ds.length; q++)
                treeModel.insert(idx + 1 + q, { p: ds[q].p, n: ds[q].n, depth: d + 1, open: false, sub: !!ds[q].sub,
                                                icon: fm.placeIcons[ds[q].p] || "folder" });
        });
    }

    // ───────────────────────── tabs ─────────────────────────
    ListModel { id: tabsModel }
    property int curTab: 0
    property int _uid: 0
    property var curPage: null
    readonly property var activePane: curPage ? curPage.activePane : null
    property var pendingSel: null      // { dir, paths } → select when that folder reloads

    function openTab(path, focus) {
        tabsModel.append({ uid: ++_uid, startPath: path || "", title: "…", icon: "folder" });
        if (focus !== false) curTab = tabsModel.count - 1;
    }
    function closeTab(i) {
        if (i < 0 || i >= tabsModel.count) return;
        if (tabsModel.count <= 1) { fm.closeWin(); return; }
        if (i < curTab || (i === curTab && i === tabsModel.count - 1)) curTab = curTab - 1;
        tabsModel.remove(i);
        updateWatch();
        Qt.callLater(fm.refocus);
    }
    function cycleTab(d) {
        if (tabsModel.count < 2) return;
        curTab = (curTab + d + tabsModel.count) % tabsModel.count;
        Qt.callLater(fm.refocus);
    }
    function navigate(p) { if (activePane) activePane.go(p); }
    function refocus() { if (activePane) activePane.focusKeys(); }

    // path requested from outside (IPC / shortcut with a path)
    function takeExternalPath() {
        if (!gs || gs.fileExplorerPath === undefined || fm.inst !== 0) return;
        var p = gs.fileExplorerPath;
        if (!p) return;
        gs.fileExplorerPath = "";
        if (tabsModel.count === 0) openTab(p);
        else openTab(p);
    }
    Connections {
        target: fm.gs
        ignoreUnknownSignals: true
        function onFileExplorerPathChanged() { if (fm.visible) fm.takeExternalPath(); }
        function onTextEditorPickingChanged() {
            if (fm.visible && fm.inst === 0 && fm.gs.textEditorPicking) fm.toast(fm.tx("Elige un archivo para abrirlo en el editor", "Pick a file to open it in the editor"));
        }
    }

    // watching the visible folders (the backend notifies with "changed")
    Timer {
        id: watchTimer
        interval: 300
        onTriggered: {
            var s = {};
            for (var i = 0; i < tabRep.count; i++) {
                var pg = tabRep.itemAt(i);
                if (pg) pg.collectPaths(s);
            }
            fm.call("watch", { paths: Object.keys(s) });
        }
    }
    function updateWatch() { watchTimer.restart(); }

    // ───────────────────────── clipboard ─────────────────────────
    property var  clipPaths: []
    property bool clipCut: false
    function setClip(paths, cut) {
        if (!paths.length) return;
        clipPaths = paths.slice();
        clipCut = cut;
        call("clip_set", { paths: paths });
        toast((cut ? tx("Cortado: ", "Cut: ") : tx("Copiado: ", "Copied: ")) + (paths.length === 1 ? baseName(paths[0]) : countLabel(paths.length)));
    }
    function paste(dest) {
        if (!dest || dest === "trash://") return;
        call("clip_get", {}, function (ok, d) {
            var sys = ok && d.paths ? d.paths : [];
            var same = sys.length === fm.clipPaths.length && sys.every(function (p) { return fm.clipPaths.indexOf(p) >= 0; });
            var useInternal = same || sys.length === 0;
            var src = useInternal ? fm.clipPaths : sys;
            var cut = useInternal && fm.clipCut;
            if (!src.length) { fm.toast(tx("El portapapeles está vacío", "Clipboard is empty")); return; }
            fm.transfer(src, dest, cut);
            if (cut) { fm.clipPaths = []; fm.clipCut = false; }
        });
    }

    // ───────────────────────── operations ─────────────────────────
    function inside(child, parent) { return child === parent || child.indexOf(parent === "/" ? "/" : parent + "/") === 0; }
    function touchedDirs(paths, dest) {
        var s = {};
        if (dest) s[dest] = 1;
        for (var i = 0; i < paths.length; i++) s[dirName(paths[i])] = 1;
        for (var k in s) dirChanged(k);
    }
    function transfer(paths, dest, move) {
        paths = paths.filter(function (p) { return p && !fm.inside(dest, p) && !(move && fm.dirName(p) === dest); });
        if (!paths.length) return;
        call(move ? "move" : "copy", { paths: paths, dest: dest }, function (ok, d) {
            if (!ok) { if (d !== "cancelled") fm.toast(d, true); }
            else {
                if (d.errors && d.errors.length) fm.toast(d.errors.join("\n"), true);
                if (d.created && d.created.length) fm.pendingSel = { dir: dest, paths: d.created };
            }
            fm.touchedDirs(move ? paths : [], dest);
        });
    }
    function trashPaths(paths) {
        if (!paths.length) return;
        call("trash", { paths: paths }, function (ok, d) {
            if (!ok) fm.toast(d, true);
            else if (d.errors && d.errors.length) fm.toast(d.errors.join("\n"), true);
            else fm.toast(tx("Movido a la papelera: ", "Moved to trash: ") + (paths.length === 1 ? fm.baseName(paths[0]) : fm.countLabel(paths.length)));
            fm.touchedDirs(paths, "");
            fm.dirChanged("trash://");
            fm.refreshPlaces();
        });
    }
    function deletePaths(paths) {
        if (!paths.length) return;
        askConfirm(tx("¿Eliminar definitivamente?", "Delete permanently?"),
                   (paths.length === 1 ? "«" + baseName(paths[0]) + "»" : countLabel(paths.length)) +
                   tx(" se borrará sin pasar por la papelera. No se puede deshacer.", " will be removed without going to the trash. This cannot be undone."),
                   tx("Eliminar", "Delete"), true, function () {
            fm.call("delete", { paths: paths }, function (ok, d) {
                if (!ok) { if (d !== "cancelled") fm.toast(d, true); }
                else if (d.errors && d.errors.length) fm.toast(d.errors.join("\n"), true);
                fm.touchedDirs(paths, "");
            });
        });
    }
    function restoreTrash(entries) {
        var ids = entries.map(function (e) { return e.tid; }).filter(function (t) { return !!t; });
        if (!ids.length) return;
        call("trash_restore", { ids: ids }, function (ok, d) {
            if (!ok) fm.toast(d, true);
            else {
                if (d.errors && d.errors.length) fm.toast(d.errors.join("\n"), true);
                else fm.toast(tx("Restaurado: ", "Restored: ") + fm.countLabel(d.restored.length));
                fm.touchedDirs(d.restored, "");
            }
            fm.dirChanged("trash://");
            fm.refreshPlaces();
        });
    }
    function purgeTrash(entries) {
        var all = entries === null;
        var ids = all ? null : entries.map(function (e) { return e.tid; });
        askConfirm(all ? tx("¿Vaciar la papelera?", "Empty the trash?") : tx("¿Eliminar definitivamente?", "Delete permanently?"),
                   all ? tx("Todos los elementos de la papelera se borrarán para siempre.", "Everything in the trash will be removed forever.")
                       : fm.countLabel(ids.length) + tx(" se borrarán para siempre.", " will be removed forever."),
                   all ? tx("Vaciar", "Empty") : tx("Eliminar", "Delete"), true, function () {
            fm.call("trash_purge", all ? {} : { ids: ids }, function (ok, d) {
                if (!ok && d !== "cancelled") fm.toast(d, true);
                fm.dirChanged("trash://");
                fm.refreshPlaces();
            });
        });
    }
    function newFolder(dir) {
        if (!dir || dir === "trash://") return;
        askInput(tx("Nueva carpeta", "New folder"), tx("Nueva carpeta", "New folder"), tx("Crear", "Create"), function (v) {
            fm.call("mkdir", { dir: dir, name: v }, function (ok, d) {
                if (!ok) { fm.toast(d, true); return; }
                fm.pendingSel = { dir: dir, paths: [d.path] };
                fm.dirChanged(dir);
            });
        });
    }
    function newFile(dir) {
        if (!dir || dir === "trash://") return;
        askInput(tx("Nuevo archivo", "New file"), tx("Nuevo archivo.txt", "New file.txt"), tx("Crear", "Create"), function (v) {
            fm.call("touch", { dir: dir, name: v }, function (ok, d) {
                if (!ok) { fm.toast(d, true); return; }
                fm.pendingSel = { dir: dir, paths: [d.path] };
                fm.dirChanged(dir);
            });
        }, stemLen(tx("Nuevo archivo.txt", "New file.txt"), false));
    }
    function renamePath(e) {
        if (!e) return;
        askInput(tx("Renombrar", "Rename"), e.n, tx("Renombrar", "Rename"), function (v) {
            if (v === e.n) return;
            fm.call("rename", { path: e.p, name: v }, function (ok, d) {
                if (!ok) { fm.toast(d, true); return; }
                var dir = fm.dirName(e.p);
                fm.pendingSel = { dir: dir, paths: [d.path] };
                fm.dirChanged(dir);
            });
        }, stemLen(e.n, e.d));
    }
    function compressDlg(paths, dest) {
        if (!paths.length) return;
        var nm = paths.length === 1 ? baseName(paths[0]) : tx("Archivo", "Archive");
        if (paths.length === 1) nm = nm.substring(0, stemLen(nm, false)) || nm;
        dlgFormat = "zip";
        askInput(tx("Comprimir", "Compress"), nm, tx("Comprimir", "Compress"), function (v) {
            fm.call("compress", { paths: paths, format: fm.dlgFormatUsed, name: v, dest: dest }, function (ok, d) {
                if (!ok) { if (d !== "cancelled") fm.toast(d, true); return; }
                fm.pendingSel = { dir: dest, paths: [d.path] };
                fm.dirChanged(dest);
            });
        });
        dlgKind = "compress";
    }
    function extract(e, mode) {
        var dest = dirName(e.p);
        call("extract", { path: e.p, dest: dest, mode: mode }, function (ok, d) {
            if (!ok) { if (d !== "cancelled") fm.toast(d, true); return; }
            fm.pendingSel = { dir: dest, paths: [d.path] };
            fm.dirChanged(dest);
            fm.toast(tx("Extraído en ", "Extracted to ") + fm.prettyPath(d.path));
        });
    }
    // Text files → shell editor; everything else → system app
    readonly property var textExts: [
        "txt", "text", "md", "markdown", "rst", "org", "adoc", "tex", "log", "nfo", "csv", "tsv",
        "json", "jsonc", "json5", "yaml", "yml", "toml", "ini", "cfg", "conf", "config", "env", "properties",
        "xml", "html", "htm", "xhtml", "svg", "css", "scss", "sass", "less",
        "js", "mjs", "cjs", "jsx", "ts", "tsx", "vue", "svelte", "qml", "qmldir",
        "py", "pyw", "pyi", "rb", "pl", "pm", "php", "lua", "r", "jl", "dart", "go", "rs", "zig", "nim",
        "c", "h", "cc", "cpp", "cxx", "hpp", "hh", "hxx", "m", "mm", "cs", "java", "kt", "kts", "scala", "swift", "gradle",
        "sh", "bash", "zsh", "fish", "ksh", "csh", "ps1", "bat", "cmd", "nix", "cmake", "mk", "make", "ninja",
        "sql", "graphql", "gql", "proto", "diff", "patch", "desktop", "service", "timer", "socket", "rules",
        "srt", "vtt", "sub", "ass", "lrc", "gitignore", "gitattributes", "gitmodules", "editorconfig",
        "lock", "sum", "mod", "list", "rc", "hypr", "kdl", "ron", "el", "vim", "vimrc", "hs", "ml", "ex", "exs", "erl", "clj"]
    readonly property var textNames: ["makefile", "dockerfile", "containerfile", "readme", "license", "licence", "copying",
        "authors", "changelog", "todo", "pkgbuild", "cmakelists.txt", "justfile", "procfile", "vagrantfile", "gemfile", "rakefile"]
    function isTextFile(p, e) {
        var n = baseName(p).toLowerCase();
        if (textNames.indexOf(n) >= 0) return true;
        if (n.charAt(0) === "." && n.indexOf(".", 1) < 0) return true;          // .bashrc, .zshrc, .env…
        var k = n.lastIndexOf(".");
        var ext = k > 0 ? n.substring(k + 1) : "";
        if (ext && textExts.indexOf(ext) >= 0) return true;
        if (e && e.c === "code") return true;
        // small, no extension: the editor checks for binary itself
        if (e && !ext && (e.c === "file" || e.c === "doc") && (e.s === undefined || e.s < 4000000)) return true;
        return false;
    }
    function hasEditor() { return !!gs && typeof gs.openTextEditor === "function"; }
    function hasMusic() { return !!gs && typeof gs.openMusicPlayer === "function"; }
    function isAudioFile(p) { return /\.(mp3|flac|m4a|aac|alac|ogg|oga|opus|wav|aiff?|wma|ape|wv|m3u8?)$/i.test(p); }
    function openInEditor(p) { if (hasEditor()) gs.openTextEditor(p); else openWithSystem(p); }
    function openWithSystem(p) { Quickshell.execDetached(["xdg-open", p]); }
    function openFile(p, e) {
        if (hasEditor() && gs.textEditorPicking) {            // "Open…" from the editor
            gs.textEditorPicking = false;
            if (typeof gs.openTextEditorPicked === "function") gs.openTextEditorPicked(p); else gs.openTextEditor(p);
            fm.closeWin();
            return;
        }
        if (hasMusic() && isAudioFile(p)) { gs.openMusicPlayer([p]); return; }
        if (hasEditor() && isTextFile(p, e)) gs.openTextEditor(p);
        else openWithSystem(p);
    }
    function openTerminal(dir) { Quickshell.execDetached(["sh", "-c", "cd \"$1\" && exec \"${TERMINAL:-kitty}\"", "sh", dir]); }
    function copyText(t) { Quickshell.execDetached(["wl-copy", "--", t]); toast(tx("Copiado al portapapeles", "Copied to clipboard")); }
    function mountDev(dv, thenGo) {
        call("mount", { dev: dv.dev }, function (ok, d) {
            if (!ok) { fm.toast(d, true); return; }
            fm.refreshPlaces();
            if (thenGo && d.path) fm.navigate(d.path);
        });
    }
    function unmountDev(dv, eject) {
        call("unmount", { dev: dv.dev, eject: eject }, function (ok, d) {
            if (!ok) { fm.toast(d, true); return; }
            fm.toast((eject ? tx("Expulsado: ", "Ejected: ") : tx("Desmontado: ", "Unmounted: ")) + dv.n);
            fm.refreshPlaces();
        });
    }

    // dropping files (from this explorer or other apps) onto a folder
    function handleDrop(d, dest, item) {
        if (!d.hasUrls) return;
        var ps = [];
        for (var i = 0; i < d.urls.length; i++) {
            var p = urlToPath(d.urls[i]);
            if (p && !inside(dest, p)) ps.push(p);
        }
        d.accept(Qt.CopyAction);
        if (!ps.length) return;
        if (dest === "trash://") { trashPaths(ps); return; }
        var g = item.mapToItem(null, d.x, d.y);
        var allHere = ps.every(function (p) { return fm.dirName(p) === dest; });
        if (allHere) return;
        Qt.callLater(function () {
            fm.openMenu([
                { icon: "drive_file_move", label: tx("Mover aquí", "Move here"), fn: function () { fm.transfer(ps, dest, true); } },
                { icon: "content_copy", label: tx("Copiar aquí", "Copy here"), fn: function () { fm.transfer(ps, dest, false); } },
                { sep: true },
                { icon: "close", label: tx("Cancelar", "Cancel"), fn: function () {} }
            ], g.x, g.y);
        });
    }

    // ───────────────────────── dialogs ─────────────────────────
    property string dlgKind: ""        // "" | input | confirm | compress
    property string dlgTitle: ""
    property string dlgText: ""
    property string dlgValue: ""
    property string dlgOk: ""
    property bool   dlgDanger: false
    property int    dlgSelEnd: -1
    property var    dlgCb: null
    property string dlgFormat: "zip"
    property string dlgFormatUsed: "zip"
    function askInput(title, value, ok, cb, selEnd) {
        dlgTitle = title; dlgText = ""; dlgValue = value; dlgOk = ok; dlgDanger = false;
        dlgSelEnd = selEnd === undefined ? -1 : selEnd; dlgCb = cb; dlgKind = "input";
    }
    function askConfirm(title, text, ok, danger, cb) {
        dlgTitle = title; dlgText = text; dlgValue = ""; dlgOk = ok; dlgDanger = danger; dlgCb = cb; dlgKind = "confirm";
    }
    function acceptDlg(v) {
        var cb = dlgCb;
        var kind = dlgKind;
        dlgFormatUsed = dlgFormat;
        dlgKind = ""; dlgCb = null;
        if (kind !== "confirm") {
            v = (v || "").trim();
            if (!v) { refocus(); return; }
        }
        if (cb) cb(v);
        Qt.callLater(fm.refocus);
    }
    function closeDlg() { dlgKind = ""; dlgCb = null; Qt.callLater(fm.refocus); }

    // ───────────────────────── context menu ─────────────────────────
    property var  menuItems: []
    property real menuX: 0
    property real menuY: 0
    property bool menuOpen: false
    function openMenu(items, x, y) {
        // drop duplicate separators / those at the ends
        var out = [];
        for (var i = 0; i < items.length; i++) {
            var it = items[i];
            if (it.sep && (out.length === 0 || out[out.length - 1].sep)) continue;
            out.push(it);
        }
        while (out.length && out[out.length - 1].sep) out.pop();
        menuItems = out;
        menuX = x; menuY = y;
        menuOpen = true;
    }
    function runMenu(it) {
        menuOpen = false;
        if (it && it.fn && !it.disabled) it.fn();
        Qt.callLater(fm.refocus);
    }

    function entryMenu(pane, x, y) {
        var ts = pane.targets();
        if (!ts.length) { bgMenu(pane, x, y); return; }
        var one = ts.length === 1 ? ts[0] : null;
        var ps = ts.map(function (e) { return e.p; });
        var m = [];
        if (pane.isTrash) {
            m.push({ icon: "restore_from_trash", label: tx("Restaurar", "Restore"), fn: function () { fm.restoreTrash(ts); } });
            m.push({ sep: true });
            m.push({ icon: "delete_forever", label: tx("Eliminar definitivamente", "Delete permanently"), key: "Supr", danger: true, fn: function () { fm.purgeTrash(ts); } });
            openMenu(m, x, y);
            return;
        }
        var other = pane.host.dual ? pane.host.otherOf(pane) : null;
        if (one) m.push({ icon: one.d ? "folder_open" : "open_in_new", label: tx("Abrir", "Open"), key: "Enter", fn: function () { pane.openEntry(one); } });
        if (one && !one.d && fm.hasEditor()) {
            if (fm.isTextFile(one.p, one)) m.push({ icon: "open_in_new", label: tx("Abrir con la aplicación del sistema", "Open with system app"), fn: function () { fm.openWithSystem(one.p); } });
            else m.push({ icon: "edit_note", label: tx("Abrir en el editor de texto", "Open in text editor"), fn: function () { fm.openInEditor(one.p); } });
        }
        if (fm.hasMusic()) {
            var afiles = ts.filter(function (e) { return e.d || fm.isAudioFile(e.p); }).map(function (e) { return e.p; });
            if (afiles.length) m.push({ icon: "library_music", label: tx("Reproducir en Música", "Play in Music"), fn: function () { fm.gs.openMusicPlayer(afiles); } });
        }
        if (!one && fm.hasEditor()) {
            var tfiles = ts.filter(function (e) { return !e.d; });
            if (tfiles.length) m.push({ icon: "edit_note", label: tx("Abrir en el editor de texto", "Open in text editor"), fn: function () { tfiles.slice(0, 30).forEach(function (e) { fm.openInEditor(e.p); }); } });
        }
        if (one && one.d) {
            m.push({ icon: "tab", label: tx("Abrir en pestaña nueva", "Open in new tab"), fn: function () { fm.openTab(one.p); } });
            if (other) m.push({ icon: "vertical_split", label: tx("Abrir en el otro panel", "Open in other pane"), fn: function () { other.go(one.p); } });
            m.push({ icon: "terminal", label: tx("Abrir terminal aquí", "Open terminal here"), fn: function () { fm.openTerminal(one.p); } });
        }
        if (pane.deepActive && one) m.push({ icon: "folder_open", label: tx("Abrir ubicación", "Open location"), fn: function () { pane.go(fm.dirName(one.p), { focus: one.p }); } });
        m.push({ sep: true });
        m.push({ icon: "content_cut", label: tx("Cortar", "Cut"), key: "Ctrl+X", fn: function () { fm.setClip(ps, true); } });
        m.push({ icon: "content_copy", label: tx("Copiar", "Copy"), key: "Ctrl+C", fn: function () { fm.setClip(ps, false); } });
        if (one && one.d) m.push({ icon: "content_paste", label: tx("Pegar dentro", "Paste into"), fn: function () { fm.paste(one.p); } });
        m.push({ icon: "file_copy", label: tx("Duplicar", "Duplicate"), fn: function () { fm.transfer(ps, pane.deepActive ? fm.dirName(ps[0]) : pane.path, false); } });
        if (other && !other.isTrash) {
            m.push({ icon: "arrow_split", label: tx("Copiar al otro panel", "Copy to other pane"), key: "F5", fn: function () { fm.transfer(ps, other.path, false); } });
            m.push({ icon: "drive_file_move", label: tx("Mover al otro panel", "Move to other pane"), key: "F6", fn: function () { fm.transfer(ps, other.path, true); } });
        }
        m.push({ sep: true });
        if (one) m.push({ icon: "edit", label: tx("Renombrar", "Rename"), key: "F2", fn: function () { fm.renamePath(one); } });
        m.push({ icon: "folder_zip", label: tx("Comprimir…", "Compress…"), fn: function () { fm.compressDlg(ps, pane.deepActive ? fm.dirName(ps[0]) : pane.path); } });
        if (one && one.c === "archive") {
            m.push({ icon: "unarchive", label: tx("Extraer aquí", "Extract here"), fn: function () { fm.extract(one, "here"); } });
            m.push({ icon: "drive_folder_upload", label: tx("Extraer en carpeta", "Extract to folder"), fn: function () { fm.extract(one, "folder"); } });
        }
        m.push({ sep: true });
        if (one && one.d) {
            if (fm.isFavorite(one.p)) m.push({ icon: "star", label: tx("Quitar de favoritos", "Remove from favorites"), fn: function () { fm.removeFavorite(one.p); } });
            else m.push({ icon: "star", label: tx("Añadir a favoritos", "Add to favorites"), fn: function () { fm.addFavorite(one.p); } });
        }
        m.push({ icon: "link", label: tx("Copiar ruta", "Copy path"), key: "Ctrl+Shift+C", fn: function () { fm.copyText(ps.join("\n")); } });
        m.push({ icon: "info", label: tx("Propiedades", "Properties"), key: "Alt+Enter", fn: function () { fm.showDetails = true; } });
        m.push({ sep: true });
        m.push({ icon: "delete", label: tx("Mover a la papelera", "Move to trash"), key: "Supr", danger: true, fn: function () { fm.trashPaths(ps); } });
        m.push({ icon: "delete_forever", label: tx("Eliminar definitivamente", "Delete permanently"), key: "Shift+Supr", danger: true, fn: function () { fm.deletePaths(ps); } });
        openMenu(m, x, y);
    }
    function bgMenu(pane, x, y) {
        var m = [];
        if (pane.isTrash) {
            m.push({ icon: "restore_from_trash", label: tx("Restaurar todo", "Restore all"), disabled: pane.raw.length === 0, fn: function () { fm.restoreTrash(pane.raw); } });
            m.push({ icon: "delete_forever", label: tx("Vaciar papelera", "Empty trash"), danger: true, disabled: pane.raw.length === 0, fn: function () { fm.purgeTrash(null); } });
            openMenu(m, x, y);
            return;
        }
        var dir = pane.path;
        m.push({ icon: "create_new_folder", label: tx("Nueva carpeta", "New folder"), key: "Ctrl+Shift+N", disabled: !pane.writable, fn: function () { fm.newFolder(dir); } });
        m.push({ icon: "note_add", label: tx("Nuevo archivo", "New file"), key: "Ctrl+Alt+N", disabled: !pane.writable, fn: function () { fm.newFile(dir); } });
        m.push({ icon: "content_paste", label: tx("Pegar", "Paste"), key: "Ctrl+V", disabled: !pane.writable, fn: function () { fm.paste(dir); } });
        m.push({ sep: true });
        m.push({ icon: "select_all", label: tx("Seleccionar todo", "Select all"), key: "Ctrl+A", fn: function () { pane.selectAll(); } });
        m.push({ icon: fm.showHidden ? "visibility_off" : "visibility", label: fm.showHidden ? tx("Ocultar archivos ocultos", "Hide hidden files") : tx("Mostrar archivos ocultos", "Show hidden files"), key: "Ctrl+H", fn: function () { fm.showHidden = !fm.showHidden; } });
        m.push({ sep: true });
        m.push({ icon: "terminal", label: tx("Abrir terminal aquí", "Open terminal here"), fn: function () { fm.openTerminal(dir); } });
        if (!fm.isFavorite(dir)) m.push({ icon: "star", label: tx("Añadir a favoritos", "Add to favorites"), fn: function () { fm.addFavorite(dir); } });
        m.push({ icon: "link", label: tx("Copiar ruta", "Copy path"), fn: function () { fm.copyText(dir); } });
        m.push({ icon: "info", label: tx("Propiedades de la carpeta", "Folder properties"), fn: function () { pane.clearSel(); fm.showDetails = true; } });
        openMenu(m, x, y);
    }
    function sortMenu(x, y) {
        function opt(k, icon, label) {
            return { icon: fm.sortKey === k ? "radio_button_checked" : "radio_button_unchecked", label: label,
                     fn: function () { if (fm.sortKey === k) fm.sortAsc = !fm.sortAsc; else { fm.sortKey = k; fm.sortAsc = k === "name" || k === "type"; } } };
        }
        openMenu([
            opt("name", "", tx("Nombre", "Name")),
            opt("size", "", tx("Tamaño", "Size")),
            opt("mtime", "", tx("Fecha de modificación", "Modified")),
            opt("type", "", tx("Tipo", "Type")),
            { sep: true },
            { icon: fm.sortAsc ? "arrow_upward" : "arrow_downward", label: fm.sortAsc ? tx("Ascendente", "Ascending") : tx("Descendente", "Descending"), fn: function () { fm.sortAsc = !fm.sortAsc; } },
            { icon: fm.foldersFirst ? "check_box" : "check_box_outline_blank", label: tx("Carpetas primero", "Folders first"), fn: function () { fm.foldersFirst = !fm.foldersFirst; } }
        ], x, y);
    }

    // ───────────────────────── startup ─────────────────────────
    Component.onCompleted: {
        call("prefs_load", {}, function (ok, p) {
            if (ok && p) {
                if (p.layoutMode) fm.layoutMode = p.layoutMode;
                if (p.defaultView) fm.defaultView = p.defaultView;
                if (p.showHidden !== undefined) fm.showHidden = p.showHidden;
                if (p.foldersFirst !== undefined) fm.foldersFirst = p.foldersFirst;
                if (p.sortKey) fm.sortKey = p.sortKey;
                if (p.sortAsc !== undefined) fm.sortAsc = p.sortAsc;
                if (p.showDetails !== undefined) fm.showDetails = p.showDetails;
                if (p.sideW) fm.sideW = p.sideW;
                if (p.favorites) fm.favorites = p.favorites;
            }
            fm.call("places", {}, function (ok2, d) {
                if (ok2 && (!p || !p.favorites)) fm.favorites = (d.bookmarks || []).map(function (b) { return { n: b.n, p: b.p }; });
                fm.prefsLoaded = true;
            });
            if (tabsModel.count === 0) {
                var start = fm.inst === 0 && fm.gs && fm.gs.fileExplorerPath ? fm.gs.fileExplorerPath : "";
                if (fm.inst === 0 && fm.gs && fm.gs.fileExplorerPath) fm.gs.fileExplorerPath = "";
                fm.openTab(start);
            }
        });
        refreshPlaces();
    }

    // ───────────────────────── window shortcuts ─────────────────────────
    Shortcut { sequence: "Escape"; enabled: fm.dlgKind !== "" || fm.menuOpen; onActivated: { if (fm.menuOpen) { fm.menuOpen = false; fm.refocus(); } else fm.closeDlg(); } }
    Shortcut { sequence: "Ctrl+T"; enabled: fm.dlgKind === ""; onActivated: fm.openTab(fm.activePane && !fm.activePane.isTrash ? fm.activePane.path : "") }
    Shortcut { sequence: "Ctrl+W"; enabled: fm.dlgKind === ""; onActivated: fm.closeTab(fm.curTab) }
    Shortcut { sequences: ["Ctrl+Tab", "Ctrl+PgDown"]; enabled: fm.dlgKind === ""; onActivated: fm.cycleTab(1) }
    Shortcut { sequences: ["Ctrl+Shift+Tab", "Ctrl+Backtab", "Ctrl+PgUp"]; enabled: fm.dlgKind === ""; onActivated: fm.cycleTab(-1) }
    Shortcut { sequence: "F3"; enabled: fm.dlgKind === ""; onActivated: if (fm.curPage) fm.curPage.dual = !fm.curPage.dual }
    Shortcut { sequence: "Ctrl+M"; enabled: fm.dlgKind === ""; onActivated: fm.layoutMode = fm.layoutMode === "board" ? "miller" : "board" }
    Shortcut { sequence: "Ctrl+I"; enabled: fm.dlgKind === ""; onActivated: fm.showDetails = !fm.showDetails }
    Shortcut { sequence: "Ctrl+H"; enabled: fm.dlgKind === ""; onActivated: fm.showHidden = !fm.showHidden }
    Shortcut { sequence: "Ctrl+L"; enabled: fm.dlgKind === ""; onActivated: if (fm.activePane) fm.activePane.editPath() }
    Shortcut { sequence: "Ctrl+F"; enabled: fm.dlgKind === ""; onActivated: if (fm.activePane) fm.activePane.focusSearch() }
    Shortcut { sequence: "Ctrl+R"; enabled: fm.dlgKind === ""; onActivated: if (fm.activePane) fm.activePane.reload() }
    Shortcut { sequence: "Ctrl+1"; enabled: fm.dlgKind === ""; onActivated: if (fm.activePane) fm.activePane.setView("grid") }
    Shortcut { sequence: "Ctrl+2"; enabled: fm.dlgKind === ""; onActivated: if (fm.activePane) fm.activePane.setView("list") }
    Shortcut { sequence: "Ctrl+3"; enabled: fm.dlgKind === ""; onActivated: if (fm.activePane) fm.activePane.setView("compact") }
    Shortcut { sequence: "Ctrl+Q"; onActivated: fm.closeWin() }

    // ───────────────────────── scrolling / tooltips ─────────────────────────
    function wheelScroll(f, w) {
        if (!f) return;
        var dy = w.angleDelta.y !== 0 ? w.angleDelta.y / 120 * wheelStep : w.pixelDelta.y;
        scrollBy(f, -dy);
    }
    readonly property real wheelStep: px(150)   // pixels per wheel click
    function scrollBy(f, dy) {
        var maxY = Math.max(f.originY, f.originY + f.contentHeight - f.height);
        f.contentY = Math.max(f.originY, Math.min(maxY, f.contentY + dy));
    }
    property string tipText: ""
    property var    tipItem: null
    property bool   tipShown: false
    property real   tipX: 0
    property real   tipY: 0
    function showTip(t, item) {
        tipItem = item;
        tipText = t;
        tipShown = false;
        tipTimer.restart();
    }
    function hideTip(item) {
        if (item && item !== tipItem) return;
        tipTimer.stop();
        tipShown = false;
        tipItem = null;
    }
    Timer {
        id: tipTimer
        interval: 550
        onTriggered: {
            if (!fm.tipItem) return;
            var g = fm.tipItem.mapToItem(null, fm.tipItem.width / 2, fm.tipItem.height + 6);
            fm.tipX = g.x;
            fm.tipY = g.y;
            fm.tipShown = true;
        }
    }

    // sidebar menus
    function placeMenu(p, x, y, fav) {
        var m = [
            { icon: "folder_open", label: tx("Abrir", "Open"), fn: function () { fm.navigate(p); } },
            { icon: "tab", label: tx("Abrir en pestaña nueva", "Open in new tab"), fn: function () { fm.openTab(p); } }
        ];
        if (curPage && curPage.dual) m.push({ icon: "vertical_split", label: tx("Abrir en el otro panel", "Open in other pane"), fn: function () { fm.curPage.otherOf(fm.activePane).go(p); } });
        m.push({ icon: "terminal", label: tx("Abrir terminal aquí", "Open terminal here"), fn: function () { fm.openTerminal(p); } });
        m.push({ sep: true });
        m.push({ icon: "content_paste", label: tx("Pegar aquí", "Paste here"), fn: function () { fm.paste(p); } });
        m.push({ icon: "link", label: tx("Copiar ruta", "Copy path"), fn: function () { fm.copyText(p); } });
        m.push({ sep: true });
        if (fav || isFavorite(p)) m.push({ icon: "star", label: tx("Quitar de favoritos", "Remove from favorites"), danger: true, fn: function () { fm.removeFavorite(p); } });
        else m.push({ icon: "star", label: tx("Añadir a favoritos", "Add to favorites"), fn: function () { fm.addFavorite(p); } });
        openMenu(m, x, y);
    }
    function devMenu(dv, x, y) {
        var m = [];
        if (dv.p) {
            m.push({ icon: "folder_open", label: tx("Abrir", "Open"), fn: function () { fm.navigate(dv.p); } });
            m.push({ icon: "tab", label: tx("Abrir en pestaña nueva", "Open in new tab"), fn: function () { fm.openTab(dv.p); } });
            if (dv.p !== "/") {
                m.push({ sep: true });
                m.push({ icon: "eject", label: tx("Desmontar", "Unmount"), fn: function () { fm.unmountDev(dv, false); } });
                if (dv.rm) m.push({ icon: "usb_off", label: tx("Expulsar con seguridad", "Safely eject"), fn: function () { fm.unmountDev(dv, true); } });
            }
        } else {
            m.push({ icon: "power", label: tx("Montar", "Mount"), fn: function () { fm.mountDev(dv, false); } });
            m.push({ icon: "folder_open", label: tx("Montar y abrir", "Mount and open"), fn: function () { fm.mountDev(dv, true); } });
        }
        m.push({ sep: true });
        m.push({ icon: "info", label: dv.dev + (dv.fs ? "  ·  " + dv.fs : ""), disabled: true });
        openMenu(m, x, y);
    }

    // ══ UI ══
    Rectangle {
        id: rootBg
        anchors.fill: parent
        color: fm.bgWindow
        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutCubic } }
        clip: true

        // ───────────── header: tabs + modes ─────────────
        Item {
            id: header
            x: 0
            y: 0
            width: parent.width
            height: fm.px(54)

            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: fm.lineCol }

            Rectangle {
                id: appBadge
                x: 14
                anchors.verticalCenter: parent.verticalCenter
                width: fm.px(34)
                height: width
                radius: width / 2
                color: fm.ga(fm.cPrimary, 0.18)
                Glyph { anchors.centerIn: parent; text: "folder_open"; size: fm.px(19); color: fm.cPrimary }
            }

            ListView {
                id: tabStrip
                anchors.left: appBadge.right
                anchors.leftMargin: 10
                anchors.right: headRight.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                height: fm.px(36)
                orientation: ListView.Horizontal
                spacing: 4
                interactive: false
                clip: true
                model: tabsModel
                readonly property real tabW: Math.max(fm.px(108), Math.min(fm.px(220), (width - fm.px(44) - spacing * count) / Math.max(1, count)))
                delegate: Rectangle {
                    id: td
                    required property int index
                    required property string title
                    required property string icon
                    readonly property bool cur: index === fm.curTab
                    width: tabStrip.tabW
                    height: tabStrip.height
                    radius: height / 2
                    color: tdDrop.containsDrag ? fm.selStrong
                         : td.cur ? fm.ga(fm.cPrimary, 0.18)
                         : (tdHov.hovered ? fm.hovCol : fm.ga(fm.cOnSurfVar, 0.05))
                    Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    Glyph {
                        id: tdIco
                        x: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: td.icon
                        size: fm.px(16)
                        color: td.cur ? fm.cPrimary : fm.cOnSurfVar
                    }
                    Text {
                        anchors.left: tdIco.right
                        anchors.leftMargin: 8
                        anchors.right: tdClose.left
                        anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        text: td.title
                        elide: Text.ElideRight
                        font.family: fm.fontB
                        font.pixelSize: fm.px(12.5)
                        font.weight: td.cur ? Font.DemiBold : Font.Medium
                        color: td.cur ? fm.cOnSurface : fm.cOnSurfVar
                    }
                    HoverHandler { id: tdHov }
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        onClicked: (m) => {
                            if (m.button === Qt.MiddleButton) fm.closeTab(td.index);
                            else { fm.curTab = td.index; Qt.callLater(fm.refocus); }
                        }
                    }
                    IconBtn {
                        id: tdClose
                        anchors.right: parent.right
                        anchors.rightMargin: 5
                        anchors.verticalCenter: parent.verticalCenter
                        width: fm.px(24)
                        height: fm.px(24)
                        gsize: fm.px(14)
                        glyph: "close"
                        opacity: tabsModel.count > 1 && (td.cur || tdHov.hovered) ? 1 : 0
                        enabled: tabsModel.count > 1
                        onClicked: fm.closeTab(td.index)
                    }
                    DropArea {
                        id: tdDrop
                        anchors.fill: parent
                        onEntered: (d) => { if (!d.hasUrls) { d.accepted = false; return; } tdSwitch.restart(); }
                        onExited: tdSwitch.stop()
                        onDropped: (d) => {
                            tdSwitch.stop();
                            var pg = tabRep.itemAt(td.index);
                            if (pg) fm.handleDrop(d, pg.activePane.isTrash ? "trash://" : pg.activePane.path, tdDrop);
                        }
                    }
                    Timer { id: tdSwitch; interval: 650; onTriggered: fm.curTab = td.index }
                }
                footer: Item {
                    width: fm.px(44)
                    height: tabStrip.height
                    IconBtn {
                        anchors.centerIn: parent
                        glyph: "add"
                        tip: fm.tx("Nueva pestaña (Ctrl+T)", "New tab (Ctrl+T)")
                        onClicked: fm.openTab(fm.activePane && !fm.activePane.isTrash ? fm.activePane.path : "")
                    }
                }
            }

            Row {
                id: headRight
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                Seg {
                    anchors.verticalCenter: parent.verticalCenter
                    cellW: fm.px(42)
                    current: fm.layoutMode
                    options: [
                        { value: "board", icon: "dashboard", tip: fm.tx("Tablero: filas y columnas", "Board: rows and columns") },
                        { value: "miller", icon: "view_column", tip: fm.tx("Vertical tipo yazi (Ctrl+M)", "Yazi-style columns (Ctrl+M)") }
                    ]
                    onPicked: (v) => { fm.layoutMode = v; Qt.callLater(fm.refocus); }
                }
                Item { width: 6; height: 1 }
                IconBtn {
                    anchors.verticalCenter: parent.verticalCenter
                    glyph: "vertical_split"
                    tip: fm.tx("Doble panel (F3)", "Dual pane (F3)")
                    active: !!fm.curPage && fm.curPage.dual
                    onClicked: if (fm.curPage) fm.curPage.dual = !fm.curPage.dual
                }
                IconBtn {
                    anchors.verticalCenter: parent.verticalCenter
                    glyph: "info"
                    tip: fm.tx("Propiedades (Ctrl+I)", "Properties (Ctrl+I)")
                    active: fm.showDetails
                    onClicked: fm.showDetails = !fm.showDetails
                }
                Item { width: 4; height: 1 }
                Rectangle {
                    id: closeBtn
                    anchors.verticalCenter: parent.verticalCenter
                    width: 36
                    height: 36
                    radius: 10
                    color: closeHov.hovered ? Qt.darker(fm.cError, 1.5) : "transparent"
                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    Glyph {
                        anchors.centerIn: parent
                        text: "close"
                        size: 18
                        color: closeHov.hovered ? fm.cError : fm.cOnSurfVar
                        Behavior on color { ColorAnimation { duration: 220 } }
                    }
                    HoverHandler { id: closeHov; cursorShape: Qt.PointingHandCursor }
                    MouseArea { anchors.fill: parent; onClicked: fm.closeWin() }
                }
            }
        }

        // ───────────── body ─────────────
        Item {
            id: body
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            // ── sidebar ──
            Rectangle {
                id: sidebar
                width: fm.sideW
                height: parent.height
                color: fm.bgSide
                Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: fm.lineCol }

                Flickable {
                    id: sideFlick
                    anchors.fill: parent
                    anchors.topMargin: 6
                    anchors.bottomMargin: 6
                    anchors.rightMargin: 1
                    interactive: false
                    clip: true
                    contentHeight: sideCol.height
                    ScrollBar.vertical: FmScrollBar {}
                    Column {
                        id: sideCol
                        width: sideFlick.width

                        SideHeader { label: fm.tx("Lugares", "Places") }
                        Repeater {
                            model: fm.places
                            delegate: SideRow {
                                required property var modelData
                                glyph: modelData.icon
                                label: modelData.p === fm.home ? fm.tx("Carpeta personal", "Home") : modelData.n
                                path: modelData.p
                                active: !!fm.activePane && fm.activePane.path === modelData.p
                                onClicked: fm.navigate(modelData.p)
                                onMiddleClicked: fm.openTab(modelData.p, false)
                                onRightClicked: (x, y) => fm.placeMenu(modelData.p, x, y, false)
                            }
                        }
                        SideRow {
                            glyph: "delete"
                            label: fm.tx("Papelera", "Trash")
                            path: "trash://"
                            badge: fm.trashCount > 0 ? String(fm.trashCount) : ""
                            active: !!fm.activePane && fm.activePane.isTrash
                            onClicked: fm.navigate("trash://")
                            onMiddleClicked: fm.openTab("trash://", false)
                            onRightClicked: (x, y) => fm.openMenu([
                                { icon: "delete", label: fm.tx("Abrir papelera", "Open trash"), fn: function () { fm.navigate("trash://"); } },
                                { sep: true },
                                { icon: "delete_forever", label: fm.tx("Vaciar papelera", "Empty trash"), danger: true, disabled: fm.trashCount === 0, fn: function () { fm.purgeTrash(null); } }
                            ], x, y)
                        }

                        Item {
                            width: sideCol.width
                            height: favHead.height
                            SideHeader {
                                id: favHead
                                label: fm.tx("Favoritos", "Favorites")
                                IconBtn {
                                    width: fm.px(24); height: fm.px(24); gsize: fm.px(16)
                                    glyph: "add"
                                    tip: fm.tx("Añadir la carpeta actual", "Add current folder")
                                    enabled: !!fm.activePane && !fm.activePane.isTrash && !fm.isFavorite(fm.activePane.path)
                                    onClicked: fm.addFavorite(fm.activePane.path)
                                }
                            }
                            DropArea {
                                id: favDrop
                                anchors.fill: parent
                                onEntered: (d) => { if (!d.hasUrls) d.accepted = false; }
                                onDropped: (d) => {
                                    for (var i = 0; i < d.urls.length; i++) { var p = fm.urlToPath(d.urls[i]); if (p) fm.addFavorite(p); }
                                    d.accept(Qt.CopyAction);
                                }
                            }
                            Rectangle {
                                anchors.fill: parent
                                anchors.leftMargin: 6
                                anchors.rightMargin: 6
                                radius: 10
                                color: favDrop.containsDrag ? fm.selStrong : "transparent"
                            }
                        }
                        Repeater {
                            model: fm.favorites
                            delegate: SideRow {
                                required property var modelData
                                glyph: fm.placeIcons[modelData.p] || "star"
                                glyphColor: fm.cTertiary
                                label: modelData.n
                                path: modelData.p
                                active: !!fm.activePane && fm.activePane.path === modelData.p
                                onClicked: fm.navigate(modelData.p)
                                onMiddleClicked: fm.openTab(modelData.p, false)
                                onRightClicked: (x, y) => fm.placeMenu(modelData.p, x, y, true)
                            }
                        }
                        Text {
                            visible: fm.favorites.length === 0
                            x: 18
                            width: sideCol.width - 30
                            topPadding: 2
                            bottomPadding: 6
                            text: fm.tx("Arrastra carpetas aquí o pulsa +", "Drop folders here or press +")
                            wrapMode: Text.Wrap
                            font.family: fm.fontB
                            font.pixelSize: fm.px(11)
                            color: fm.cMuted
                        }

                        SideHeader { label: fm.tx("Dispositivos", "Devices"); visible: fm.devices.length > 0 }
                        Repeater {
                            model: fm.devices
                            delegate: SideRow {
                                id: devRow
                                required property var modelData
                                glyph: modelData.rm ? "usb" : (modelData.p === "/" ? "hard_drive" : "storage")
                                label: modelData.n
                                path: modelData.p || ""
                                usage: (modelData.p && modelData.total > 0) ? 1 - modelData.free / modelData.total : -1
                                badge: modelData.p ? "" : fm.fmtSize(modelData.size || 0)
                                glyphColor: modelData.p ? fm.cOnSurfVar : fm.cMuted
                                active: !!modelData.p && !!fm.activePane && fm.activePane.path === modelData.p
                                onClicked: { if (modelData.p) fm.navigate(modelData.p); else fm.mountDev(modelData, true); }
                                onMiddleClicked: if (modelData.p) fm.openTab(modelData.p, false)
                                onRightClicked: (x, y) => fm.devMenu(modelData, x, y)
                                IconBtn {
                                    visible: !!devRow.modelData.p && devRow.modelData.p !== "/" && devRow.modelData.rm
                                    width: fm.px(24); height: fm.px(24); gsize: fm.px(15)
                                    glyph: "eject"
                                    tip: fm.tx("Expulsar", "Eject")
                                    onClicked: fm.unmountDev(devRow.modelData, true)
                                }
                            }
                        }

                        SideHeader { label: fm.tx("Carpetas", "Folders") }
                        Repeater {
                            model: treeModel
                            delegate: SideRow {
                                required property int index
                                required property string p
                                required property string n
                                required property int depth
                                required property bool open
                                required property bool sub
                                required property string icon
                                glyph: icon
                                label: n
                                path: p
                                indent: depth * fm.px(13)
                                chevron: sub ? (open ? 1 : 0) : -1
                                active: !!fm.activePane && fm.activePane.path === p
                                onClicked: fm.navigate(p)
                                onToggled: fm.treeToggle(index)
                                onMiddleClicked: fm.openTab(p, false)
                                onRightClicked: (x, y) => fm.placeMenu(p, x, y, false)
                            }
                        }
                        Item { width: 1; height: 12 }
                    }
                }
                WheelCatcher { flick: sideFlick }
            }
            MouseArea {
                x: fm.sideW - 4
                width: 8
                height: parent.height
                hoverEnabled: true
                cursorShape: Qt.SplitHCursor
                onPositionChanged: (m) => { if (pressed) fm.sideW = Math.max(170, Math.min(420, mapToItem(body, m.x, 0).x)); }
            }

            // ── tabs ──
            Item {
                id: mainArea
                x: fm.sideW
                y: 0
                width: body.width - x - (details.visible ? details.width : 0)
                height: body.height
                Repeater {
                    id: tabRep
                    model: tabsModel
                    onItemAdded: fm.updateWatch()
                    delegate: TabPage {
                        required property int index
                        required property var model
                        tabIndex: index
                        startPath: model.startPath
                        x: 8
                        y: 8
                        width: mainArea.width - 16
                        height: mainArea.height - 16
                        visible: index === fm.curTab
                    }
                }
            }

            // ── properties panel ──
            Rectangle {
                id: details
                visible: fm.showDetails
                anchors.right: parent.right
                width: fm.px(324)
                height: parent.height
                color: fm.bgSide
                Rectangle { width: 1; height: parent.height; color: fm.lineCol }

                property var pane: fm.activePane
                readonly property bool multi: !!pane && pane.selCount > 1
                readonly property var entry: pane ? pane.detailEntry : null
                readonly property string target: !pane ? "" : (multi ? "" : (entry ? entry.p : (pane.isTrash ? "" : pane.path)))
                property var props: null
                property var meta: []
                property real duSize: -1
                property int duFiles: 0
                property int duDirs: 0
                property bool duBusy: false
                property int duId: -1
                property int editMode: 0
                property bool recursive: false
                property bool applying: false
                property int tok: 0
                readonly property var heroEntry: entry ? entry : (props ? { n: props.name, p: props.path, d: props.dir, c: props.cat, l: props.link, b: false, s: props.size, m: props.mtime, e: "", h: false } : null)
                readonly property int curMode: props ? (props.mode & 511) : 0

                onTargetChanged: loadTimer.restart()
                onMultiChanged: loadTimer.restart()
                onVisibleChanged: if (visible) loadTimer.restart()
                Connections {
                    target: details.pane
                    ignoreUnknownSignals: true
                    function onSelVerChanged() { if (details.multi) loadTimer.restart(); }
                }
                Connections {
                    target: fm
                    function onDirChanged(p) {
                        if (details.visible && details.target !== "" && !details.duBusy && (p === details.target || p === fm.dirName(details.target)))
                            loadTimer.restart();
                    }
                }
                Timer { id: loadTimer; interval: 170; onTriggered: details.load() }

                function load() {
                    if (!visible) return;
                    var t = ++tok;
                    if (duBusy && duId > 0) fm.cancel(duId);
                    duBusy = false; duSize = -1; duFiles = 0; duDirs = 0;
                    meta = [];
                    if (multi) { props = null; startDu(pane.targetPaths(), t); return; }
                    if (!target) { props = null; return; }
                    var p = target;
                    fm.call("props", { path: p }, function (ok, d) {
                        if (t !== details.tok) return;
                        if (!ok) { details.props = null; return; }
                        details.props = d;
                        details.editMode = d.mode & 511;
                        details.recursive = false;
                        if (d.dir) details.startDu([p], t);
                        else fm.call("meta", { path: p }, function (ok2, m) { if (t === details.tok) details.meta = ok2 ? m.pairs : []; });
                    });
                }
                function startDu(ps, t) {
                    if (!ps.length) return;
                    duBusy = true;
                    duSize = 0;
                    var id = -1;
                    id = fm.call("du", { paths: ps }, function (ok, d) {
                        if (t !== details.tok) return;
                        details.duBusy = false;
                        if (ok) { details.duSize = d.size; details.duFiles = d.files; details.duDirs = d.dirs; }
                    }, function (ev) {
                        if (t !== details.tok) return;
                        details.duSize = ev.size; details.duFiles = ev.files; details.duDirs = ev.dirs;
                    });
                    duId = id;
                }
                function applyPerm() {
                    if (!props) return;
                    var p = props.path;
                    var t = tok;
                    applying = true;
                    fm.call("chmod", { path: p, mode: (props.mode & 3584) | editMode, recursive: recursive && props.dir }, function (ok, d) {
                        details.applying = false;
                        if (!ok) { fm.toast(d, true); return; }
                        fm.toast(fm.tx("Permisos actualizados", "Permissions updated") + (d.errors ? "  ·  " + d.errors + fm.tx(" sin cambiar", " unchanged") : ""));
                        fm.dirChanged(fm.dirName(p));
                        if (t === details.tok) details.load();
                    });
                }
                function bit(b) { return (editMode & b) !== 0; }
                function flip(b) { editMode = editMode ^ b; }
                function symbolic(m) {
                    var s = "", c = "rwxrwxrwx";
                    for (var i = 0; i < 9; i++) s += (m & (256 >> i)) ? c.charAt(i) : "-";
                    return s;
                }
                readonly property var genRows: {
                    var r = [];
                    function tx(a, b) { return fm.tx(a, b); }
                    if (multi) {
                        r.push({ k: tx("Elementos", "Items"), v: String(pane.selCount) });
                        r.push({ k: tx("Tamaño total", "Total size"), v: (duSize < 0 ? "…" : fm.fmtSize(duSize)) + (duBusy ? "  …" : "") });
                        r.push({ k: tx("Contenido", "Contents"), v: duFiles + tx(" archivos, ", " files, ") + duDirs + tx(" carpetas", " folders") });
                        return r;
                    }
                    var p = props;
                    if (!p) return r;
                    r.push({ k: tx("Ruta", "Path"), v: p.path });
                    if (p.link) r.push({ k: tx("Enlace a", "Link to"), v: p.target });
                    if (p.dir) {
                        r.push({ k: tx("Tamaño", "Size"), v: (duSize < 0 ? "…" : fm.fmtSize(duSize)) + (duBusy ? fm.tx("  calculando…", "  measuring…") : "") });
                        r.push({ k: tx("Contenido", "Contents"), v: duFiles + tx(" archivos, ", " files, ") + duDirs + tx(" carpetas", " folders") });
                    } else {
                        r.push({ k: tx("Tamaño", "Size"), v: fm.fmtSize(p.size) + (p.size >= 1024 ? "  (" + Number(p.size).toLocaleString(Qt.locale(), "f", 0) + " B)" : "") });
                    }
                    if (p.mime) r.push({ k: "MIME", v: p.mime });
                    if (entry && entry.orig) {
                        r.push({ k: tx("Ubicación original", "Original location"), v: entry.orig });
                        r.push({ k: tx("Eliminado", "Deleted"), v: fm.fmtDate(entry.del, true) });
                    }
                    r.push({ k: tx("Creado", "Created"), v: p.btime > 0 ? fm.fmtDate(p.btime, true) : tx("No disponible", "Not available") });
                    r.push({ k: tx("Modificado", "Modified"), v: fm.fmtDate(p.mtime, true) });
                    r.push({ k: tx("Último acceso", "Accessed"), v: fm.fmtDate(p.atime, true) });
                    r.push({ k: tx("Cambio de atributos", "Changed"), v: fm.fmtDate(p.ctime, true) });
                    r.push({ k: tx("Propietario", "Owner"), v: p.owner + " : " + p.group });
                    r.push({ k: tx("Acceso", "Access"), v: (p.readable ? tx("lectura", "read") : "") + (p.writable ? (p.readable ? " · " : "") + tx("escritura", "write") : "") || tx("ninguno", "none") });
                    r.push({ k: "Inodo", v: String(p.inode), mono: true });
                    return r;
                }

                Flickable {
                    id: detFlick
                    anchors.fill: parent
                    anchors.margins: 12
                    anchors.leftMargin: 13
                    interactive: false
                    clip: true
                    contentHeight: detCol.height
                    ScrollBar.vertical: FmScrollBar {}
                    Column {
                        id: detCol
                        width: detFlick.width
                        spacing: 10

                        Item {
                            width: parent.width
                            height: fm.px(32)
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: fm.tx("Propiedades", "Properties")
                                font.family: fm.fontA
                                font.pixelSize: fm.px(14)
                                font.weight: Font.DemiBold
                                color: fm.cOnSurface
                            }
                            IconBtn {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                glyph: "close"
                                onClicked: fm.showDetails = false
                            }
                        }

                        Text {
                            visible: !details.multi && !details.props
                            width: parent.width
                            topPadding: 30
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                            text: details.pane && details.pane.isTrash ? fm.tx("Selecciona un elemento de la papelera", "Select an item in the trash")
                                                                       : fm.tx("Sin selección", "Nothing selected")
                            font.family: fm.fontB
                            font.pixelSize: fm.px(12)
                            color: fm.cMuted
                        }

                        Rectangle {
                            visible: details.multi || !!details.props
                            width: parent.width
                            height: fm.px(178)
                            radius: 20
                            color: fm.bgCont
                            clip: true
                            Image {
                                id: heroImg
                                anchors.fill: parent
                                anchors.margins: 10
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                smooth: true
                                mipmap: true
                                sourceSize: Qt.size(900, 900)
                                source: (details.multi || !details.heroEntry || !details.visible) ? ""
                                      : (fm.isImage(details.heroEntry) ? fm.fileUrl(details.heroEntry.p) : fm.thumbFor(details.heroEntry))
                                visible: status === Image.Ready
                            }
                            FileIcon {
                                anchors.centerIn: parent
                                visible: !heroImg.visible && !details.multi
                                entry: details.heroEntry
                                thumb: false
                                size: fm.px(96)
                            }
                            Glyph {
                                anchors.centerIn: parent
                                visible: details.multi
                                text: "library_add_check"
                                size: fm.px(56)
                                color: fm.cPrimary
                            }
                        }

                        Column {
                            visible: details.multi || !!details.props
                            width: parent.width
                            spacing: 2
                            Text {
                                width: parent.width
                                text: details.multi ? details.pane.selCount + fm.tx(" elementos seleccionados", " items selected") : (details.props ? details.props.name : "")
                                wrapMode: Text.WrapAnywhere
                                font.family: fm.fontA
                                font.pixelSize: fm.px(15)
                                font.weight: Font.DemiBold
                                color: fm.cOnSurface
                            }
                            Text {
                                visible: !details.multi && !!details.heroEntry
                                width: parent.width
                                text: details.heroEntry ? fm.typeLabel(details.heroEntry) : ""
                                elide: Text.ElideRight
                                font.family: fm.fontB
                                font.pixelSize: fm.px(11.5)
                                color: fm.cOnSurfVar
                            }
                        }

                        DCard {
                            visible: details.multi || !!details.props
                            title: fm.tx("General", "General")
                            glyph: "info"
                            Repeater {
                                model: details.genRows
                                delegate: KV {
                                    required property var modelData
                                    k: modelData.k
                                    v: modelData.v
                                    monoVal: !!modelData.mono
                                }
                            }
                        }

                        DCard {
                            visible: !details.multi && !!details.props
                            title: fm.tx("Permisos", "Permissions")
                            glyph: "lock"
                            Row {
                                spacing: 6
                                Item { width: fm.px(82); height: fm.px(18) }
                                Repeater {
                                    model: [fm.tx("Leer", "Read"), fm.tx("Escribir", "Write"), fm.tx("Ejecutar", "Execute")]
                                    delegate: Text {
                                        required property var modelData
                                        width: fm.px(44)
                                        horizontalAlignment: Text.AlignHCenter
                                        text: modelData
                                        font.family: fm.fontB
                                        font.pixelSize: fm.px(10)
                                        font.weight: Font.DemiBold
                                        color: fm.cMuted
                                    }
                                }
                            }
                            Repeater {
                                model: [
                                    { label: fm.tx("Propietario", "Owner"), r: 256, w: 128, x: 64 },
                                    { label: fm.tx("Grupo", "Group"), r: 32, w: 16, x: 8 },
                                    { label: fm.tx("Otros", "Others"), r: 4, w: 2, x: 1 }
                                ]
                                delegate: Row {
                                    required property var modelData
                                    spacing: 6
                                    readonly property bool canEdit: !!details.props && details.props.mine
                                    Text {
                                        width: fm.px(82)
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.label
                                        elide: Text.ElideRight
                                        font.family: fm.fontB
                                        font.pixelSize: fm.px(11.5)
                                        color: fm.cOnSurface
                                    }
                                    PermBox { on: details.bit(modelData.r) && details.editMode >= 0; editable: parent.canEdit; onToggled: details.flip(modelData.r) }
                                    PermBox { on: details.bit(modelData.w) && details.editMode >= 0; editable: parent.canEdit; onToggled: details.flip(modelData.w) }
                                    PermBox { on: details.bit(modelData.x) && details.editMode >= 0; editable: parent.canEdit; onToggled: details.flip(modelData.x) }
                                }
                            }
                            Text {
                                topPadding: 4
                                text: (details.props ? (details.props.dir ? "d" : "-") : "") + details.symbolic(details.editMode)
                                      + "    " + ("000" + details.editMode.toString(8)).slice(-3)
                                      + (details.editMode !== details.curMode ? fm.tx("   (sin aplicar)", "   (not applied)") : "")
                                font.family: fm.mono
                                font.pixelSize: fm.px(11.5)
                                color: details.editMode !== details.curMode ? fm.cPrimary : fm.cOnSurfVar
                            }
                            Row {
                                visible: !!details.props && details.props.dir && details.props.mine
                                spacing: 8
                                PermBox {
                                    width: fm.px(34); height: fm.px(24)
                                    on: details.recursive
                                    onToggled: details.recursive = !details.recursive
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: fm.tx("Aplicar también al contenido", "Apply to contents too")
                                    font.family: fm.fontB
                                    font.pixelSize: fm.px(11.5)
                                    color: fm.cOnSurfVar
                                }
                            }
                            Text {
                                visible: !!details.props && !details.props.mine
                                width: parent.width
                                wrapMode: Text.Wrap
                                text: fm.tx("Solo el propietario (", "Only the owner (") + (details.props ? details.props.owner : "") + fm.tx(") puede cambiar los permisos.", ") can change permissions.")
                                font.family: fm.fontB
                                font.pixelSize: fm.px(11)
                                color: fm.cMuted
                            }
                            Row {
                                visible: !!details.props && details.props.mine
                                spacing: 6
                                topPadding: 2
                                PillBtn {
                                    glyph: "check"
                                    label: details.applying ? fm.tx("Aplicando…", "Applying…") : fm.tx("Aplicar", "Apply")
                                    primary: true
                                    enabled: !details.applying && (details.editMode !== details.curMode || details.recursive)
                                    onClicked: details.applyPerm()
                                }
                                PillBtn {
                                    glyph: "undo"
                                    label: fm.tx("Restablecer", "Reset")
                                    enabled: details.editMode !== details.curMode
                                    onClicked: details.editMode = details.curMode
                                }
                            }
                        }

                        DCard {
                            visible: details.meta.length > 0 && !details.multi
                            title: fm.tx("Metadatos", "Metadata")
                            glyph: "tune"
                            Repeater {
                                model: details.meta
                                delegate: KV {
                                    required property var modelData
                                    k: fm.metaLabel(String(modelData[0]))
                                    v: String(modelData[1])
                                }
                            }
                        }

                        DCard {
                            id: storeCard
                            visible: !!details.pane && details.pane.total > 0
                            title: fm.tx("Almacenamiento", "Storage")
                            glyph: "hard_drive"
                            readonly property real used: details.pane && details.pane.total > 0 ? 1 - details.pane.free / details.pane.total : 0
                            Text {
                                width: parent.width
                                wrapMode: Text.Wrap
                                text: details.pane ? fm.fmtSize(details.pane.free) + fm.tx(" libres de ", " free of ") + fm.fmtSize(details.pane.total)
                                                     + "  ·  " + Math.round(storeCard.used * 100) + fm.tx("% usado", "% used") : ""
                                font.family: fm.fontB
                                font.pixelSize: fm.px(11.5)
                                color: fm.cOnSurfVar
                            }
                            Rectangle {
                                width: parent.width
                                height: 6
                                radius: 3
                                color: fm.trackCol
                                Rectangle {
                                    width: parent.width * Math.max(0, Math.min(1, storeCard.used))
                                    height: parent.height
                                    radius: 3
                                    color: storeCard.used > 0.9 ? fm.cError : fm.cPrimary
                                }
                            }
                        }
                        Item { width: 1; height: 8 }
                    }
                }
                WheelCatcher { flick: detFlick }
            }
        }

        // ───────────── running jobs ─────────────
        Column {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 18 + (details.visible ? details.width : 0)
            anchors.bottomMargin: 18
            spacing: 8
            z: 20
            Repeater {
                model: jobsModel
                delegate: Rectangle {
                    id: jc
                    required property int jid
                    required property string kind
                    required property string label
                    required property real done
                    required property real total
                    required property string cur
                    property bool ready: false
                    Timer { interval: 450; running: true; onTriggered: jc.ready = true }
                    visible: ready
                    width: fm.px(310)
                    height: visible ? jcCol.height + 24 : 0
                    radius: 20
                    color: fm.bgPop
                    border.width: 1
                    border.color: fm.lineCol
                    Glyph {
                        id: jcIco
                        x: 14
                        y: 14
                        text: jc.kind === "copy" ? "content_copy" : jc.kind === "move" ? "drive_file_move"
                            : jc.kind === "delete" ? "delete_forever" : jc.kind === "compress" ? "folder_zip" : "unarchive"
                        size: fm.px(20)
                        color: fm.cPrimary
                    }
                    Column {
                        id: jcCol
                        x: jcIco.x + jcIco.width + 10
                        y: 12
                        width: jc.width - x - 46
                        spacing: 4
                        Text {
                            width: parent.width
                            text: fm.jobVerb(jc.kind) + (jc.label ? "  ·  " + jc.label : "")
                            elide: Text.ElideMiddle
                            font.family: fm.fontB
                            font.pixelSize: fm.px(12.5)
                            font.weight: Font.DemiBold
                            color: fm.cOnSurface
                        }
                        Text {
                            width: parent.width
                            visible: jc.cur !== ""
                            text: jc.cur
                            elide: Text.ElideMiddle
                            font.family: fm.fontB
                            font.pixelSize: fm.px(11)
                            color: fm.cMuted
                        }
                        Rectangle {
                            width: parent.width
                            height: 5
                            radius: 3
                            color: fm.trackCol
                            clip: true
                            Rectangle {
                                id: jcBar
                                readonly property bool det: jc.total > 0
                                height: parent.height
                                radius: 3
                                color: fm.cPrimary
                                width: det ? parent.width * Math.min(1, jc.done / jc.total) : parent.width * 0.3
                                Behavior on width { enabled: jcBar.det; NumberAnimation { duration: 200 } }
                                SequentialAnimation on x {
                                    running: !jcBar.det && jc.visible
                                    loops: Animation.Infinite
                                    NumberAnimation { from: -jcBar.width; to: jcBar.parent.width; duration: 1100; easing.type: Easing.InOutQuad }
                                }
                            }
                        }
                        Text {
                            text: jc.total > 0 ? (jc.kind === "delete" ? Math.round(jc.done) + " / " + Math.round(jc.total)
                                                 : fm.fmtSize(jc.done) + " / " + fm.fmtSize(jc.total)) + "  ·  " + Math.round(100 * jc.done / jc.total) + "%"
                                               : fm.tx("Preparando…", "Preparing…")
                            font.family: fm.fontB
                            font.pixelSize: fm.px(10.5)
                            color: fm.cOnSurfVar
                        }
                    }
                    IconBtn {
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        y: 8
                        glyph: "close"
                        danger: true
                        tip: fm.tx("Cancelar", "Cancel")
                        onClicked: fm.cancel(jc.jid)
                    }
                }
            }
        }

        // ───────────── notice ─────────────
        Rectangle {
            id: toastBox
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: fm.toastText !== "" ? 22 : -height
            Behavior on anchors.bottomMargin { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
            opacity: fm.toastText !== "" ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            z: 30
            width: Math.min(rootBg.width - 80, toastRow.implicitWidth + 32)
            height: toastRow.height + 20
            radius: height > 52 ? 20 : height / 2
            color: fm.bgPop
            border.width: 1
            border.color: fm.toastErr ? fm.ga(fm.cError, 0.5) : fm.lineCol
            Row {
                id: toastRow
                anchors.centerIn: parent
                spacing: 10
                Glyph {
                    anchors.verticalCenter: parent.verticalCenter
                    text: fm.toastErr ? "error" : "check_circle"
                    size: fm.px(18)
                    color: fm.toastErr ? fm.cError : fm.cPrimary
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, Math.min(fm.px(560), rootBg.width - 140))
                    text: fm.toastText
                    wrapMode: Text.Wrap
                    maximumLineCount: 6
                    elide: Text.ElideRight
                    font.family: fm.fontB
                    font.pixelSize: fm.px(12.5)
                    color: fm.cOnSurface
                }
            }
            MouseArea { anchors.fill: parent; onClicked: fm.toastText = "" }
        }

        // ───────────── tooltip ─────────────
        Rectangle {
            z: 90
            visible: fm.tipShown && fm.tipText !== ""
            x: Math.max(6, Math.min(rootBg.width - width - 6, fm.tipX - width / 2))
            y: fm.tipY + height > rootBg.height - 6 ? fm.tipY - height - 40 : fm.tipY
            width: tipT.implicitWidth + 20
            height: tipT.implicitHeight + 10
            radius: height / 2
            color: fm.cSurfPop
            Text {
                id: tipT
                anchors.centerIn: parent
                text: fm.tipText
                font.family: fm.fontB
                font.pixelSize: fm.px(11.5)
                color: fm.cOnSurface
            }
        }

        // ───────────── context menu ─────────────
        Item {
            anchors.fill: parent
            visible: fm.menuOpen
            z: 60
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onPressed: { fm.menuOpen = false; fm.refocus(); }
                onWheel: (w) => { fm.menuOpen = false; }
            }
            Rectangle {
                id: menuBox
                width: Math.max(fm.px(230), menuCol.implicitW + 24)
                height: menuCol.height + 12
                x: Math.max(6, Math.min(fm.menuX, rootBg.width - width - 6))
                y: fm.menuY + height <= rootBg.height - 6 ? fm.menuY : Math.max(6, fm.menuY - height)
                radius: 18
                color: fm.bgPop
                border.width: 1
                border.color: fm.lineCol
                scale: fm.menuOpen ? 1 : 0.94
                opacity: fm.menuOpen ? 1 : 0
                transformOrigin: Item.TopLeft
                Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 120 } }
                MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }
                Column {
                    id: menuCol
                    x: 6
                    y: 6
                    width: menuBox.width - 12
                    property real implicitW: 0
                    Repeater {
                        model: fm.menuItems
                        delegate: Item {
                            id: mi
                            required property var modelData
                            width: menuCol.width
                            height: modelData.sep ? 9 : fm.px(33)
                            Component.onCompleted: if (!modelData.sep) menuCol.implicitW = Math.max(menuCol.implicitW, miTxt.implicitWidth + miKey.implicitWidth + fm.px(80))
                            Rectangle {
                                visible: !!mi.modelData.sep
                                anchors.centerIn: parent
                                width: parent.width - 16
                                height: 1
                                color: fm.lineCol
                            }
                            Rectangle {
                                visible: !mi.modelData.sep
                                anchors.fill: parent
                                radius: 11
                                opacity: mi.modelData.disabled ? 0.4 : 1
                                color: miHov.hovered && !mi.modelData.disabled ? (mi.modelData.danger ? fm.ga(fm.cError, 0.14) : fm.hovCol) : "transparent"
                                Glyph {
                                    id: miIco
                                    x: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: mi.modelData.icon || ""
                                    size: fm.px(17)
                                    color: mi.modelData.danger ? fm.cError : fm.cOnSurfVar
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
                                    font.family: fm.fontB
                                    font.pixelSize: fm.px(12.5)
                                    font.weight: Font.Medium
                                    color: mi.modelData.danger ? fm.cError : fm.cOnSurface
                                }
                                Text {
                                    id: miKey
                                    anchors.right: parent.right
                                    anchors.rightMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: mi.modelData.key || ""
                                    font.family: fm.fontB
                                    font.pixelSize: fm.px(10.5)
                                    color: fm.cMuted
                                }
                                HoverHandler { id: miHov; enabled: !mi.modelData.disabled; cursorShape: Qt.PointingHandCursor }
                                MouseArea {
                                    anchors.fill: parent
                                    enabled: !mi.modelData.disabled
                                    onClicked: fm.runMenu(mi.modelData)
                                }
                            }
                        }
                    }
                }
            }
        }
        Connections {
            target: fm
            function onMenuItemsChanged() { menuCol.implicitW = 0; }
        }

        // ───────────── dialog ─────────────
        Rectangle {
            anchors.fill: parent
            visible: fm.dlgKind !== ""
            z: 80
            color: Qt.rgba(0, 0, 0, fm.light ? 0.22 : 0.42)
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onWheel: (w) => {} }
            Rectangle {
                id: dlgCard
                anchors.centerIn: parent
                width: Math.min(parent.width - 40, fm.px(440))
                height: dlgCol.height + 44
                radius: 28
                color: fm.bgPop
                border.width: 1
                border.color: fm.lineCol
                MouseArea { anchors.fill: parent }
                Column {
                    id: dlgCol
                    x: 22
                    y: 22
                    width: dlgCard.width - 44
                    spacing: 14
                    Row {
                        spacing: 10
                        Rectangle {
                            width: fm.px(36)
                            height: width
                            radius: width / 2
                            color: fm.ga(fm.dlgDanger ? fm.cError : fm.cPrimary, 0.18)
                            Glyph {
                                anchors.centerIn: parent
                                text: fm.dlgKind === "compress" ? "folder_zip" : fm.dlgKind === "confirm" ? (fm.dlgDanger ? "warning" : "help") : "edit"
                                size: fm.px(19)
                                color: fm.dlgDanger ? fm.cError : fm.cPrimary
                            }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: fm.dlgTitle
                            font.family: fm.fontA
                            font.pixelSize: fm.px(16)
                            font.weight: Font.DemiBold
                            color: fm.cOnSurface
                        }
                    }
                    Text {
                        visible: fm.dlgText !== ""
                        width: parent.width
                        text: fm.dlgText
                        wrapMode: Text.Wrap
                        font.family: fm.fontB
                        font.pixelSize: fm.px(12.5)
                        color: fm.cOnSurfVar
                    }
                    Field {
                        id: dlgField
                        visible: fm.dlgKind === "input" || fm.dlgKind === "compress"
                        width: parent.width
                        height: fm.px(38)
                        onAccepted: fm.acceptDlg(dlgField.text)
                        onEscaped: fm.closeDlg()
                    }
                    Seg {
                        visible: fm.dlgKind === "compress"
                        width: parent.width
                        current: fm.dlgFormat
                        options: [
                            { value: "zip", label: "ZIP", icon: "folder_zip" },
                            { value: "tar.gz", label: "TAR.GZ", icon: "inventory_2" },
                            { value: "7z", label: "7Z", icon: "compress" }
                        ]
                        onPicked: (v) => fm.dlgFormat = v
                    }
                    Item {
                        width: parent.width
                        height: dlgBtns.height
                        Row {
                            id: dlgBtns
                            anchors.right: parent.right
                            spacing: 8
                            PillBtn { label: fm.tx("Cancelar", "Cancel"); onClicked: fm.closeDlg() }
                            PillBtn {
                                label: fm.dlgOk
                                primary: true
                                danger: fm.dlgDanger
                                onClicked: fm.acceptDlg(dlgField.text)
                            }
                        }
                    }
                }
            }
        }
        Connections {
            target: fm
            function onDlgKindChanged() {
                if (fm.dlgKind === "input" || fm.dlgKind === "compress") {
                    dlgField.text = fm.dlgValue;
                    Qt.callLater(function () {
                        dlgField.input.forceActiveFocus();
                        if (fm.dlgSelEnd >= 0) dlgField.input.select(0, fm.dlgSelEnd);
                        else dlgField.input.selectAll();
                    });
                }
            }
        }
        Shortcut {
            sequences: ["Return", "Enter"]
            enabled: fm.dlgKind === "confirm"
            onActivated: fm.acceptDlg("")
        }
    }

    // ══ Components ══

    component Glyph: Text {
        property real size: 18
        font.family: "Material Symbols Rounded"
        font.pixelSize: size
        color: fm.cOnSurfVar
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }

    component FmScrollBar: ScrollBar {
        id: sb
        policy: ScrollBar.AsNeeded
        minimumSize: 0.06
        contentItem: Rectangle {
            implicitWidth: 6
            implicitHeight: 6
            radius: 3
            color: fm.ga(fm.cOnSurfVar, sb.pressed ? 0.55 : (sb.hovered ? 0.42 : 0.26))
            opacity: sb.size < 1 && (sb.active || sb.hovered) ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 220 } }
        }
        background: Item {}
    }

    // Smooth mouse wheel (angleDelta, pixelDelta only as fallback)
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
            var touchpad = a === 0 && p !== 0;
            if (touchpad) {
                wcAnim.stop();
                flick.contentY = Math.max(flick.originY, Math.min(wc.maxY(), flick.contentY - p * 1.4));
                return;
            }
            var step = a / 120 * fm.wheelStep;
            var base = wcAnim.running ? wc.goal : flick.contentY;
            wc.goal = Math.max(flick.originY, Math.min(wc.maxY(), base - step));
            wcAnim.stop();
            wcAnim.from = flick.contentY;
            wcAnim.to = wc.goal;
            wcAnim.start();
        }
        NumberAnimation {
            id: wcAnim
            target: wc.flick
            property: "contentY"
            duration: 220
            easing.type: Easing.OutCubic
        }
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
        color: active ? fm.ga(fm.cPrimary, 0.18)
             : (ibHov.hovered ? (danger ? fm.ga(fm.cError, 0.16) : fm.hovCol) : "transparent")
        Behavior on color { ColorAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Glyph {
            anchors.centerIn: parent
            text: ib.glyph
            size: ib.gsize
            color: ib.active ? fm.cPrimary : (ib.danger && ibHov.hovered ? fm.cError : fm.cOnSurfVar)
            Behavior on color { ColorAnimation { duration: 160 } }
        }
        HoverHandler {
            id: ibHov
            cursorShape: Qt.PointingHandCursor
            onHoveredChanged: { if (hovered && ib.tip !== "") fm.showTip(ib.tip, ib); else fm.hideTip(ib); }
        }
        MouseArea {
            anchors.fill: parent
            onClicked: { fm.hideTip(ib); ib.clicked(); }
        }
    }

    // Pill-shaped text button
    component PillBtn: Rectangle {
        id: pb
        property string glyph: ""
        property string label: ""
        property bool primary: false
        property bool danger: false
        signal clicked()
        implicitHeight: fm.px(32)
        implicitWidth: pbRow.width + fm.px(28)
        width: implicitWidth
        height: implicitHeight
        radius: height / 2
        opacity: enabled ? 1 : 0.4
        readonly property color base: danger ? fm.cError : fm.cPrimary
        color: primary ? (pbHov.hovered ? Qt.lighter(base, 1.08) : base)
                       : (pbHov.hovered ? fm.ga(base, 0.22) : fm.ga(base, 0.12))
        Behavior on color { ColorAnimation { duration: 160 } }
        Row {
            id: pbRow
            anchors.centerIn: parent
            spacing: 6
            Glyph {
                visible: pb.glyph !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: pb.glyph
                size: fm.px(16)
                color: pb.primary ? (pb.danger ? Qt.darker(fm.cError, 3) : fm.cOnPrimary) : pb.base
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: pb.label
                font.family: fm.fontB
                font.pixelSize: fm.px(12.5)
                font.weight: Font.DemiBold
                color: pb.primary ? (pb.danger ? Qt.darker(fm.cError, 3) : fm.cOnPrimary) : pb.base
            }
        }
        HoverHandler { id: pbHov; cursorShape: Qt.PointingHandCursor }
        MouseArea { anchors.fill: parent; onClicked: pb.clicked() }
    }

    // Segmented selector (same behavior as the shell's SegmentedPill)
    component Seg: Item {
        id: seg
        property var options: []          // [{ value, label, icon, tip }]
        property var current
        property real segHeight: fm.px(30)
        property real cellW: 0             // 0 = split the available width
        property real gap: 3
        property real selGrowY: 2
        property real selGrowX: 1.5
        signal picked(var value)
        readonly property int _n: options ? options.length : 0
        implicitWidth: cellW > 0 ? _n * cellW + (_n - 1) * gap : _n * fm.px(72)
        implicitHeight: segHeight + 2 * selGrowY
        width: implicitWidth
        height: implicitHeight

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
                y: seg.selGrowY
                width: cw
                height: seg.segHeight
                z: sel ? 2 : 1
                Rectangle {
                    property real grow: sc.sel ? 1 : 0
                    Behavior on grow { NumberAnimation { duration: 280; easing.type: Easing.OutBack } }
                    x: -seg.selGrowX * grow
                    y: -seg.selGrowY * grow
                    width: sc.width + 2 * seg.selGrowX * grow
                    height: sc.height + 2 * seg.selGrowY * grow
                    readonly property real oR: seg.segHeight / 2
                    readonly property real rL: sc.sel ? 10 : (sc.first ? oR : 6)
                    readonly property real rR: sc.sel ? 10 : (sc.last ? oR : 6)
                    topLeftRadius: rL; bottomLeftRadius: rL
                    topRightRadius: rR; bottomRightRadius: rR
                    color: sc.sel ? fm.cPrimary : (scHov.hovered ? Qt.lighter(fm.trackCol, 1.6) : fm.trackCol)
                    Behavior on topLeftRadius { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    Behavior on bottomLeftRadius { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    Behavior on topRightRadius { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    Behavior on bottomRightRadius { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
                }
                Row {
                    anchors.centerIn: parent
                    spacing: 5
                    Glyph {
                        id: scIco
                        visible: (sc.opt.icon || "") !== ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: sc.opt.icon || ""
                        size: fm.px(16)
                        color: sc.sel ? fm.cOnPrimary : fm.cOnSurfVar
                    }
                    Text {
                        visible: (sc.opt.label || "") !== ""
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, sc.width - 12 - (scIco.visible ? scIco.width + 5 : 0))
                        text: sc.opt.label || ""
                        elide: Text.ElideRight
                        font.family: fm.fontB
                        font.pixelSize: fm.px(11.5)
                        font.weight: sc.sel ? Font.DemiBold : Font.Medium
                        color: sc.sel ? fm.cOnPrimary : fm.cOnSurfVar
                    }
                }
                HoverHandler {
                    id: scHov
                    cursorShape: Qt.PointingHandCursor
                    onHoveredChanged: { if (hovered && sc.opt.tip) fm.showTip(sc.opt.tip, sc); else fm.hideTip(sc); }
                }
                MouseArea { anchors.fill: parent; onClicked: if (!sc.sel) seg.picked(sc.opt.value) }
            }
        }
    }

    // Pill-shaped text field
    component Field: Rectangle {
        id: fld
        property alias text: fin.text
        property alias input: fin
        property string placeholder: ""
        property string glyph: ""
        default property alias extra: fldRight.data
        signal accepted()
        signal escaped()
        signal downPressed()
        signal edited(string t)
        implicitHeight: fm.px(32)
        radius: height / 2
        color: fm.bgField
        border.width: fin.activeFocus ? 1 : 0
        border.color: fm.ga(fm.cPrimary, 0.6)
        Glyph {
            id: fldIco
            visible: fld.glyph !== ""
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: fld.glyph
            size: fm.px(17)
            color: fin.activeFocus ? fm.cPrimary : fm.cMuted
        }
        TextInput {
            id: fin
            anchors.left: fldIco.visible ? fldIco.right : parent.left
            anchors.leftMargin: fldIco.visible ? 6 : 14
            anchors.right: fldRight.left
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            clip: true
            color: fm.cOnSurface
            font.family: fm.fontB
            font.pixelSize: fm.px(12.5)
            selectByMouse: true
            selectionColor: fm.ga(fm.cPrimary, 0.45)
            selectedTextColor: fm.cOnSurface
            onAccepted: fld.accepted()
            onTextEdited: fld.edited(text)
            Keys.onEscapePressed: (e) => { fld.escaped(); e.accepted = true; }
            Keys.onDownPressed: (e) => { fld.downPressed(); e.accepted = true; }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: fin.text === "" && fin.preeditText === ""
                text: fld.placeholder
                font: fin.font
                color: fm.cMuted
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

    // Icon / thumbnail of a file
    component FileIcon: Item {
        id: fi
        property var entry: null
        property real size: 48
        property bool thumb: true
        property bool tile: true
        readonly property string src: (!thumb || !entry) ? "" : (fm.isImage(entry) ? fm.fileUrl(entry.p) : fm.thumbFor(entry))
        readonly property color tint: fm.catColor(entry ? entry.c : "file")
        width: size
        height: size
        Rectangle {
            anchors.fill: parent
            visible: fi.tile
            radius: Math.round(fi.size * 0.27)
            color: fm.ga(fi.tint, fiImg.status === Image.Ready ? 0.07 : 0.15)
        }
        Glyph {
            anchors.centerIn: parent
            visible: fiImg.status !== Image.Ready
            text: fm.catIcon(fi.entry)
            size: Math.round(fi.size * (fi.tile ? 0.56 : 0.92))
            color: fi.tint
        }
        Image {
            id: fiImg
            anchors.fill: parent
            anchors.margins: fi.tile ? Math.max(2, fi.size * 0.05) : 0
            source: fi.src
            asynchronous: true
            cache: true
            smooth: true
            mipmap: true
            fillMode: Image.PreserveAspectFit
            sourceSize: Qt.size(Math.ceil(fi.size * 2), Math.ceil(fi.size * 2))
            visible: status === Image.Ready
        }
        Glyph {
            visible: !!fi.entry && fi.entry.l
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: -2
            text: "link"
            size: Math.max(10, Math.round(fi.size * 0.3))
            color: fm.cOnSurface
            style: Text.Outline
            styleColor: fm.cSurface
        }
    }

    // Shared mouse input: selection, menu, double click, drag and drop
    component EntryInput: Item {
        id: ei
        property var owner: null
        property var entry: null
        property int index: -1
        readonly property bool hovered: eiHov.hovered
        readonly property bool dropHover: eiDrop.containsDrag
        anchors.fill: parent

        // "automatic" drag: the system carries the text/uri-list to any target
        Drag.dragType: Drag.Automatic
        Drag.supportedActions: Qt.CopyAction | Qt.MoveAction
        Drag.proposedAction: Qt.MoveAction
        Drag.onDragFinished: (action) => eiMa.endDrag()

        HoverHandler { id: eiHov }
        MouseArea {
            id: eiMa
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            property bool deferSelect: false
            property bool dragStarted: false
            property point pressPos: Qt.point(0, 0)
            function endDrag() {
                if (!dragStarted) return;
                dragStarted = false;
                ei.Drag.active = false;
                if (ei.owner) ei.owner.dragging = false;
            }
            onPressed: (m) => {
                var pn = ei.owner;
                pn.activate();
                pressPos = Qt.point(m.x, m.y);
                dragStarted = false;
                var ctrl = (m.modifiers & Qt.ControlModifier) !== 0;
                var shift = (m.modifiers & Qt.ShiftModifier) !== 0;
                if (m.button === Qt.MiddleButton) {
                    if (ei.entry.d && !pn.isTrash) fm.openTab(ei.entry.p, false);
                    return;
                }
                if (m.button === Qt.RightButton) {
                    if (!pn.isSel(ei.entry.p)) {
                        if (pn.miller) { pn.clearSel(); pn.cur = ei.index; } else pn.selectOnly(ei.index);
                    }
                    var g = eiMa.mapToItem(null, m.x, m.y);
                    fm.entryMenu(pn, g.x, g.y);
                    return;
                }
                deferSelect = false;
                if (ctrl) pn.toggleSel(ei.index);
                else if (shift) { if (pn.anchor < 0) pn.anchor = pn.cur; pn.rangeSel(ei.index, false); }
                else if (pn.isSel(ei.entry.p) && pn.selCount > 1) deferSelect = true;
                else if (pn.miller) { if (pn.selCount) pn.clearSel(); pn.cur = ei.index; pn.anchor = ei.index; }
                else pn.selectOnly(ei.index);
            }
            onPositionChanged: (m) => {
                if (!pressed || dragStarted || !(m.buttons & Qt.LeftButton) || !ei.owner || ei.owner.isTrash) return;
                if (Math.abs(m.x - pressPos.x) + Math.abs(m.y - pressPos.y) < 10) return;
                dragStarted = true;
                deferSelect = false;
                var ps = ei.owner.isSel(ei.entry.p) ? ei.owner.targetPaths() : [ei.entry.p];
                ei.Drag.mimeData = fm.mimeFor(ps);
                ei.owner.dragging = true;
                ei.Drag.active = true;
            }
            onReleased: (m) => {
                if (dragStarted) { endDrag(); return; }
                if (deferSelect) {
                    if (ei.owner.miller) { ei.owner.clearSel(); ei.owner.cur = ei.index; } else ei.owner.selectOnly(ei.index);
                }
                deferSelect = false;
            }
            onCanceled: endDrag()
            onDoubleClicked: (m) => { if (m.button === Qt.LeftButton) ei.owner.openEntry(ei.entry); }
        }
        DropArea {
            id: eiDrop
            anchors.fill: parent
            enabled: !!ei.entry && !!ei.owner && ei.entry.d && !ei.owner.isTrash
            onEntered: (d) => { if (!d.hasUrls || (ei.owner.isSel(ei.entry.p) && ei.owner.dragging)) d.accepted = false; }
            onDropped: (d) => fm.handleDrop(d, ei.entry.p, eiDrop)
        }
    }

    // Empty area of the views: rubber-band selection, background menu and deselect
    component BandArea: MouseArea {
        id: ba
        property var owner: null
        property var view: null
        property int mode: 0            // 0 = grid, 1 = list
        property real rowH: 30
        property point p0: Qt.point(0, 0)
        property bool banding: false
        property var base: ({})
        // reparent to contentItem so selection uses content coordinates
        parent: view ? view.contentItem : null
        z: -1
        x: 0
        y: 0
        width: view ? view.width : 0
        height: view ? Math.max(view.height, view.contentHeight) : 0
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        preventStealing: true
        onPressed: (m) => {
            owner.activate();
            if (m.button === Qt.RightButton) {
                owner.clearSel();
                var g = ba.mapToItem(null, m.x, m.y);
                fm.bgMenu(pane, g.x, g.y);
                return;
            }
            var ctrl = (m.modifiers & Qt.ControlModifier) !== 0;
            base = ctrl ? Object.assign({}, owner.selMap) : ({});
            if (!ctrl) owner.clearSel();
            p0 = Qt.point(m.x, m.y);
            band.x = m.x; band.y = m.y; band.width = 0; band.height = 0;
            banding = true;
        }
        onPositionChanged: (m) => {
            if (!banding) return;
            var x1 = Math.min(p0.x, m.x), x2 = Math.max(p0.x, m.x);
            var y1 = Math.max(0, Math.min(p0.y, m.y)), y2 = Math.max(p0.y, m.y);
            band.x = x1; band.y = y1; band.width = x2 - x1; band.height = y2 - y1;
            var sel = Object.assign({}, base);
            var its = owner.items, n = its.length, i, r;
            if (mode === 0) {
                var cw = view.cellWidth, ch = view.cellHeight;
                var cols = Math.max(1, Math.floor(view.width / cw));
                var r0 = Math.floor(y1 / ch), r1 = Math.floor(y2 / ch);
                for (r = r0; r <= r1; r++)
                    for (var c = 0; c < cols; c++) {
                        i = r * cols + c;
                        if (i >= n) break;
                        if (c * cw + cw < x1 || c * cw > x2) continue;
                        sel[its[i].p] = true;
                    }
            } else {
                var a0 = Math.floor(y1 / rowH), a1 = Math.min(n - 1, Math.floor(y2 / rowH));
                for (i = Math.max(0, a0); i <= a1; i++) sel[its[i].p] = true;
            }
            owner.setSel(sel);
            // auto-scroll only when the pointer leaves the view
            var vy = m.y - view.contentY;
            if (vy > view.height) fm.scrollBy(view, Math.min(40, (vy - view.height) / 2 + 6));
            else if (vy < 0) fm.scrollBy(view, -Math.min(40, -vy / 2 + 6));
        }
        onReleased: banding = false
        onCanceled: banding = false
        Rectangle {
            id: band
            visible: ba.banding && (width > 3 || height > 3)
            radius: 6
            color: fm.ga(fm.cPrimary, 0.14)
            border.width: 1
            border.color: fm.ga(fm.cPrimary, 0.55)
        }
    }

    // Sortable column header (list view)
    component HeadCell: Item {
        id: hc
        property string label: ""
        property string key: ""
        property int align: Text.AlignLeft
        height: parent ? parent.height : 28
        clip: true
        readonly property bool on: key !== "" && fm.sortKey === key
        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: hc.align === Text.AlignLeft ? parent.left : undefined
            anchors.right: hc.align === Text.AlignRight ? parent.right : undefined
            anchors.leftMargin: 8
            anchors.rightMargin: 10
            spacing: 2
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: hc.label
                font.family: fm.fontB
                font.pixelSize: fm.px(11)
                font.weight: hc.on ? Font.Bold : Font.DemiBold
                color: hc.on ? fm.cPrimary : fm.cMuted
            }
            Glyph {
                visible: hc.on
                anchors.verticalCenter: parent.verticalCenter
                text: fm.sortAsc ? "arrow_upward" : "arrow_downward"
                size: fm.px(13)
                color: fm.cPrimary
            }
        }
        HoverHandler { id: hcHov; enabled: hc.key !== ""; cursorShape: Qt.PointingHandCursor }
        MouseArea {
            anchors.fill: parent
            enabled: hc.key !== ""
            onClicked: { if (fm.sortKey === hc.key) fm.sortAsc = !fm.sortAsc; else { fm.sortKey = hc.key; fm.sortAsc = hc.key === "name" || hc.key === "type"; } }
        }
    }

    // Row in the columns view (yazi style)
    component MRow: Item {
        id: mr
        property var entry: null
        property bool isCur: false
        property bool sel: false
        property bool focused: true
        property bool clickable: false
        property bool dropHover: false
        property bool cut: false
        signal clicked()
        height: fm.px(30)
        opacity: cut ? 0.5 : 1
        readonly property bool strong: isCur && focused
        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: 2
            anchors.rightMargin: 2
            anchors.topMargin: 1
            anchors.bottomMargin: 1
            radius: 9
            color: mr.dropHover ? fm.selStrong
                 : mr.isCur ? (mr.focused ? fm.cPrimary : fm.ga(fm.cPrimary, 0.28))
                 : mr.sel ? fm.selCol
                 : (mrHov.hovered ? fm.hovCol : "transparent")
            Behavior on color { ColorAnimation { duration: 110 } }
        }
        Rectangle {
            visible: mr.sel
            x: 5
            anchors.verticalCenter: parent.verticalCenter
            width: 3
            height: parent.height - 12
            radius: 2
            color: mr.strong ? fm.cOnPrimary : fm.cPrimary
        }
        Glyph {
            id: mrIco
            x: 14
            anchors.verticalCenter: parent.verticalCenter
            text: fm.catIcon(mr.entry)
            size: fm.px(17)
            color: mr.strong ? fm.cOnPrimary : fm.catColor(mr.entry ? mr.entry.c : "file")
        }
        Text {
            x: mrIco.x + mrIco.width + 8
            anchors.verticalCenter: parent.verticalCenter
            width: mrSub.x - x - 8
            text: mr.entry ? mr.entry.n : ""
            elide: Text.ElideRight
            font.family: fm.fontB
            font.pixelSize: fm.px(12.5)
            font.weight: mr.isCur ? Font.DemiBold : Font.Medium
            color: mr.strong ? fm.cOnPrimary : ((mr.entry && mr.entry.h) ? fm.cMuted : fm.cOnSurface)
        }
        Text {
            id: mrSub
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: !mr.entry ? "" : (mr.entry.d ? (mr.entry.k === undefined || mr.entry.k < 0 ? "" : String(mr.entry.k)) : fm.fmtSize(mr.entry.s))
            font.family: fm.fontB
            font.pixelSize: fm.px(10.5)
            color: mr.strong ? fm.ga(fm.cOnPrimary, 0.8) : fm.cMuted
        }
        HoverHandler { id: mrHov; cursorShape: mr.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor }
        MouseArea { anchors.fill: parent; enabled: mr.clickable; onClicked: mr.clicked() }
    }

    // Sidebar row
    component SideRow: Item {
        id: sr
        property string glyph: "folder"
        property string label: ""
        property string path: ""
        property bool active: false
        property string badge: ""
        property real indent: 0
        property int chevron: -1           // -1 none, 0 closed, 1 open
        property real usage: -1            // 0..1 → usage bar (devices)
        property bool droppable: true
        property color glyphColor: fm.cOnSurfVar
        default property alias extra: srRight.data
        signal clicked()
        signal rightClicked(real gx, real gy)
        signal middleClicked()
        signal toggled()
        width: parent ? parent.width : 200
        height: usage >= 0 ? fm.px(42) : fm.px(33)
        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            anchors.topMargin: 1
            anchors.bottomMargin: 1
            radius: 11
            color: srDrop.containsDrag ? fm.selStrong
                 : sr.active ? fm.ga(fm.cPrimary, 0.18)
                 : (srHov.hovered ? fm.hovCol : "transparent")
            Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }
        Rectangle {
            visible: sr.active
            x: 0
            anchors.verticalCenter: parent.verticalCenter
            width: 3
            height: parent.height - 14
            radius: 2
            color: fm.cPrimary
        }
        Glyph {
            id: srIco
            x: (sr.chevron >= 0 ? 30 : 16) + sr.indent
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: sr.usage >= 0 ? -5 : 0
            text: sr.glyph
            size: fm.px(18)
            color: sr.active ? fm.cPrimary : sr.glyphColor
        }
        Text {
            id: srTxt
            x: srIco.x + srIco.width + 10
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: sr.usage >= 0 ? -5 : 0
            width: Math.max(10, srRight.x - x - 6)
            text: sr.label
            elide: Text.ElideRight
            font.family: fm.fontB
            font.pixelSize: fm.px(12.5)
            font.weight: sr.active ? Font.DemiBold : Font.Medium
            color: sr.active ? fm.cPrimary : fm.cOnSurface
        }
        Rectangle {
            visible: sr.usage >= 0
            x: srTxt.x
            y: srTxt.y + srTxt.height + 4
            width: srTxt.width
            height: 4
            radius: 2
            color: fm.trackCol
            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, sr.usage))
                height: parent.height
                radius: 2
                color: sr.usage > 0.9 ? fm.cError : fm.cPrimary
            }
        }
        HoverHandler { id: srHov; cursorShape: Qt.PointingHandCursor }
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: (m) => {
                if (m.button === Qt.RightButton) { var g = mapToItem(null, m.x, m.y); sr.rightClicked(g.x, g.y); }
                else if (m.button === Qt.MiddleButton) sr.middleClicked();
                else sr.clicked();
            }
        }
        DropArea {
            id: srDrop
            anchors.fill: parent
            enabled: sr.droppable && sr.path !== ""
            onEntered: (d) => { if (!d.hasUrls) d.accepted = false; }
            onDropped: (d) => fm.handleDrop(d, sr.path, srDrop)
        }
        Item {
            visible: sr.chevron >= 0
            x: 8 + sr.indent
            width: 22
            height: parent.height
            Glyph {
                anchors.centerIn: parent
                text: "chevron_right"
                size: fm.px(17)
                color: chevHov.hovered ? fm.cOnSurface : fm.cMuted
                rotation: sr.chevron === 1 ? 90 : 0
                Behavior on rotation { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            }
            HoverHandler { id: chevHov; cursorShape: Qt.PointingHandCursor }
            MouseArea { anchors.fill: parent; onClicked: sr.toggled() }
        }
        Row {
            id: srRight
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Text {
                visible: sr.badge !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: sr.badge
                font.family: fm.fontB
                font.pixelSize: fm.px(10.5)
                font.weight: Font.DemiBold
                color: fm.cMuted
            }
        }
    }

    component SideHeader: Item {
        id: sh
        property string label: ""
        default property alias extra: shRight.data
        width: parent ? parent.width : 200
        height: fm.px(30)
        Text {
            x: 18
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 5
            text: sh.label
            font.family: fm.fontB
            font.pixelSize: fm.px(10.5)
            font.weight: Font.Bold
            font.capitalization: Font.AllUppercase
            font.letterSpacing: 0.8
            color: fm.cMuted
        }
        Row {
            id: shRight
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 1
        }
    }

    // Properties panel card
    component DCard: Rectangle {
        id: dc
        property string title: ""
        property string glyph: ""
        default property alias body: dcCol.data
        width: parent ? parent.width : 280
        height: dcCol.height + fm.px(24)
        radius: 18
        color: fm.bgCont
        Column {
            id: dcCol
            x: fm.px(14)
            y: fm.px(12)
            width: dc.width - fm.px(28)
            spacing: 6
            Row {
                spacing: 6
                Glyph { text: dc.glyph; size: fm.px(16); color: fm.cPrimary; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    text: dc.title
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: fm.fontA
                    font.pixelSize: fm.px(13)
                    font.weight: Font.DemiBold
                    color: fm.cOnSurface
                }
            }
        }
    }

    component KV: Item {
        id: kv
        property string k: ""
        property string v: ""
        property bool monoVal: false
        width: parent ? parent.width : 260
        height: Math.max(kvK.height, kvV.height) + 2
        Text {
            id: kvK
            width: Math.round(kv.width * 0.36)
            text: kv.k
            wrapMode: Text.Wrap
            font.family: fm.fontB
            font.pixelSize: fm.px(11)
            color: fm.cMuted
        }
        TextEdit {
            id: kvV
            x: kvK.width + 8
            width: kv.width - x
            text: kv.v
            readOnly: true
            selectByMouse: true
            wrapMode: TextEdit.WrapAnywhere
            font.family: kv.monoVal ? fm.mono : fm.fontB
            font.pixelSize: fm.px(11.5)
            color: fm.cOnSurface
            selectionColor: fm.ga(fm.cPrimary, 0.45)
            selectedTextColor: fm.cOnSurface
        }
    }

    component PermBox: Rectangle {
        id: pbx
        property bool on: false
        property bool editable: true
        signal toggled()
        width: fm.px(44)
        height: fm.px(28)
        radius: 9
        color: on ? fm.cPrimary : (pbxHov.hovered && editable ? Qt.lighter(fm.trackCol, 1.7) : fm.trackCol)
        opacity: editable ? 1 : 0.6
        Behavior on color { ColorAnimation { duration: 160 } }
        Glyph {
            anchors.centerIn: parent
            text: pbx.on ? "check" : "remove"
            size: fm.px(16)
            color: pbx.on ? fm.cOnPrimary : fm.cMuted
        }
        HoverHandler { id: pbxHov; enabled: pbx.editable; cursorShape: Qt.PointingHandCursor }
        MouseArea { anchors.fill: parent; enabled: pbx.editable; onClicked: pbx.toggled() }
    }

    // ══ File pane ══
    component Pane: FocusScope {
        id: pane
        property var host: null
        property int paneIdx: 0
        readonly property bool active: host ? host.activeIdx === paneIdx : true
        readonly property bool miller: fm.layoutMode === "miller"
        readonly property bool narrow: width < fm.px(640)
        clip: true
        readonly property bool keysFocused: keyCatcher.activeFocus

        property string path: ""
        readonly property bool isTrash: path === "trash://"
        readonly property string parentPath: (path === "" || path === "/" || isTrash) ? "" : fm.dirName(path)
        property var hist: []
        property int histIdx: -1
        property var raw: []
        property var items: []
        property int baseCount: 0
        property bool loading: false
        property real free: -1
        property real total: -1
        property bool writable: true
        property string view: fm.defaultView
        property bool dragging: false

        // selection
        property var selMap: ({})
        property int selCount: 0
        property real selSize: 0
        property int selVer: 0
        property int cur: -1
        property int anchor: -1
        property string focusAfter: ""
        property var _selAfter: []
        property int _tok: 0
        property string _lastPath: ""
        readonly property var curItem: (cur >= 0 && cur < items.length) ? items[cur] : null
        readonly property var detailEntry: {
            selVer;
            if (selCount > 1) return null;
            if (selCount === 1) {
                for (var i = 0; i < items.length; i++) if (selMap[items[i].p]) return items[i];
                return null;
            }
            return miller ? curItem : null;
        }

        // filters and search
        property string query: ""
        property bool deep: false
        property bool filtersOpen: false
        property string fType: "all"
        property string fDate: "any"
        property string fSize: "any"
        readonly property bool filterActive: fType !== "all" || fDate !== "any" || fSize !== "any"
        property var found: []
        property bool searching: false
        property int scanned: 0
        property int searchId: -1
        property bool truncated: false
        readonly property bool deepActive: deep && query.trim().length > 0 && !isTrash

        // vertical view
        property var parentItems: []
        property var prevItems: []
        property string prevPath: ""
        property string peekText: ""
        property bool prevLoading: false

        onRawChanged: requeue()
        onFoundChanged: requeue()
        onQueryChanged: { requeue(); if (deep) searchTimer.restart(); }
        onDeepChanged: { if (deep) searchTimer.restart(); else stopSearch(); requeue(); }
        onFTypeChanged: requeue()
        onFDateChanged: requeue()
        onFSizeChanged: requeue()
        onCurItemChanged: schedulePreview()
        onMillerChanged: { if (miller && cur < 0 && items.length) cur = 0; loadParent(); schedulePreview(); Qt.callLater(function () { pane.ensureVisible(pane.cur); }); }
        onPathChanged: fm.updateWatch()

        Connections {
            target: fm
            function onShowHiddenChanged() { pane.requeue(); pane.loadParent(); pane.schedulePreview(); }
            function onSortKeyChanged() { pane.requeue(); }
            function onSortAscChanged() { pane.requeue(); }
            function onFoldersFirstChanged() { pane.requeue(); }
            function onDirChanged(p) {
                if (p === pane.path) pane.reload();
                else if (pane.miller && p === pane.parentPath) pane.loadParent();
                else if (pane.miller && p === pane.prevPath) pane.schedulePreview();
            }
        }

        // ── navigation ──
        function activate() { if (host) host.activeIdx = paneIdx; focusKeys(); }
        function focusKeys() { keyCatcher.forceActiveFocus(); }
        function editPath() { activate(); crumbBox.startEdit(); }
        function focusSearch() { activate(); searchField.input.forceActiveFocus(); searchField.input.selectAll(); }
        function setView(v) { view = v; fm.defaultView = v; }
        function collectPaths(s) {
            if (isTrash) s["trash://"] = 1;
            else if (path) s[path] = 1;
            if (miller && parentPath) s[parentPath] = 1;
        }

        function go(p, opts) {
            opts = opts || {};
            if (p === undefined || p === null) return;
            var tok = ++_tok;
            loading = true;
            var cb = function (ok, d) {
                if (tok !== pane._tok) return;
                pane.loading = false;
                if (!ok) {
                    fm.toast(d, true);
                    if (pane.path === "" && p !== "") pane.go("");
                    return;
                }
                var changed = d.path !== pane.path;
                if (changed) {
                    if (!opts.noHist) {
                        var h = pane.hist.slice(0, pane.histIdx + 1);
                        h.push(d.path);
                        if (h.length > 80) h = h.slice(h.length - 80);
                        pane.hist = h;
                        pane.histIdx = h.length - 1;
                    }
                    pane.selMap = ({}); pane.selCount = 0; pane.selSize = 0; pane.selVer++;
                    pane.cur = -1; pane.anchor = -1;
                    if (!opts.keepQuery) { pane.query = ""; pane.deep = false; }
                    pane.stopSearch();
                }
                if (fm.pendingSel && fm.pendingSel.dir === d.path) {
                    pane._selAfter = fm.pendingSel.paths;
                    pane.focusAfter = fm.pendingSel.paths[0];
                    fm.pendingSel = null;
                } else if (opts.focus) pane.focusAfter = opts.focus;
                pane.free = d.free;
                pane.total = d.total;
                pane.writable = d.writable;
                pane.path = d.path;
                pane.raw = d.items;
                if (changed) pane.loadParent();
            };
            if (p === "trash://") fm.call("trash_list", {}, cb);
            else fm.call("list", { path: p }, cb);
        }
        function reload() { if (path !== "") go(path, { noHist: true, keepQuery: true }); }
        function back() {
            if (histIdx <= 0) return;
            var from = path;
            histIdx--;
            go(hist[histIdx], { noHist: true, focus: from });
        }
        function forward() {
            if (histIdx >= hist.length - 1) return;
            histIdx++;
            go(hist[histIdx], { noHist: true });
        }
        function up() { if (parentPath) go(parentPath, { focus: path }); }
        function openEntry(e) {
            if (!e) return;
            if (isTrash) { fm.showDetails = true; return; }
            if (e.d) go(e.p);
            else fm.openFile(e.p, e);
        }
        function openTargets() {
            var ts = targets();
            if (!ts.length && curItem) ts = [curItem];
            if (!ts.length) return;
            if (ts.length === 1) { openEntry(ts[0]); return; }
            if (isTrash) return;
            var files = ts.filter(function (e) { return !e.d; });
            if (files.length) files.slice(0, 12).forEach(function (e) { fm.openFile(e.p, e); });
            else ts.slice(0, 8).forEach(function (e) { fm.openTab(e.p, false); });
        }

        // ── filtering and sorting ──
        function requeue() { Qt.callLater(pane.compute); }
        function activeFlick() { return miller ? mlist : (view === "list" ? list : grid); }
        function compute() {
            var src = deepActive ? found : raw;
            var q = deepActive ? "" : query.trim().toLowerCase();
            var rx = (q && /[*?\[]/.test(q)) ? fm.globRx(q) : null;
            var now = Date.now() / 1000, dl = 0;
            if (fDate !== "any") {
                var d0 = new Date(); d0.setHours(0, 0, 0, 0);
                dl = fDate === "today" ? d0.getTime() / 1000 : fDate === "week" ? now - 7 * 86400
                   : fDate === "month" ? now - 30 * 86400 : now - 365 * 86400;
            }
            var MB = 1048576, smin = 0, smax = -1;
            if (fSize === "tiny") smax = MB;
            else if (fSize === "mid") { smin = MB; smax = 100 * MB; }
            else if (fSize === "big") { smin = 100 * MB; smax = 1024 * MB; }
            else if (fSize === "huge") smin = 1024 * MB;
            var out = [], bc = 0;
            for (var i = 0; i < src.length; i++) {
                var e = src[i];
                if (!fm.showHidden && e.h) continue;
                bc++;
                if (q) {
                    var nl = e.n.toLowerCase();
                    if (rx ? !rx.test(nl) : nl.indexOf(q) < 0) continue;
                }
                if (fType !== "all") {
                    if (fType === "dir" ? !e.d : (fType === "doc" ? (e.c !== "doc" && e.c !== "pdf") : e.c !== fType)) continue;
                }
                if (dl && (isTrash ? (e.del || e.m) : e.m) < dl) continue;
                if (fSize !== "any") {
                    if (e.d) continue;
                    if (e.s < smin || (smax >= 0 && e.s >= smax)) continue;
                }
                out.push(e);
            }
            out.sort(fm.sorter(isTrash));

            var samePath = _lastPath === path;
            _lastPath = path;
            var f = activeFlick();
            var y0 = f ? f.contentY : 0;
            var keep = curItem ? curItem.p : "";
            var target = focusAfter || (samePath ? keep : "");
            focusAfter = "";

            baseCount = bc;
            items = out;

            var ni = -1;
            if (target) for (var j = 0; j < out.length; j++) if (out[j].p === target) { ni = j; break; }
            if (ni < 0) ni = (samePath && out.length) ? Math.min(Math.max(cur, 0), out.length - 1) : (out.length && miller ? 0 : -1);

            var m = {};
            if (_selAfter.length) {
                for (j = 0; j < _selAfter.length; j++) m[_selAfter[j]] = true;
                _selAfter = [];
            } else if (samePath) m = selMap;
            setSel(m);
            cur = ni;
            if (ni >= 0 && anchor < 0) anchor = ni;

            if (samePath && target === keep) {
                Qt.callLater(function () {
                    var ff = pane.activeFlick();
                    if (!ff) return;
                    var maxY = Math.max(ff.originY, ff.originY + ff.contentHeight - ff.height);
                    ff.contentY = Math.max(ff.originY, Math.min(maxY, y0));
                });
            } else {
                Qt.callLater(function () {
                    var ff = pane.activeFlick();
                    if (ff) ff.contentY = ff.originY;
                    pane.ensureVisible(pane.cur);
                });
            }
        }
        function resetFilters() { fType = "all"; fDate = "any"; fSize = "any"; }

        // ── subfolder search ──
        Timer { id: searchTimer; interval: 280; onTriggered: pane.startSearch() }
        function startSearch() {
            stopSearch();
            var q = query.trim();
            if (!deep || !q || isTrash) return;
            found = [];
            scanned = 0;
            truncated = false;
            searching = true;
            var acc = [];
            var myId = -1;
            myId = fm.call("search", { root: path, query: q, hidden: fm.showHidden, limit: 5000 }, function (ok, d) {
                if (pane.searchId !== myId) return;
                pane.searching = false;
                if (ok) { pane.truncated = d.truncated; if (d.scanned) pane.scanned = d.scanned; }
            }, function (ev) {
                if (pane.searchId !== myId) return;
                acc = acc.concat(ev.items);
                pane.found = acc;
                pane.scanned = ev.scanned;
            });
            searchId = myId;
        }
        function stopSearch() {
            if (searching && searchId > 0) fm.cancel(searchId);
            searching = false;
            searchId = -1;
            if (found.length) found = [];
        }

        // ── selection ──
        function isSel(p) { return selMap[p] === true; }
        function setSel(m) {
            var c = 0, sz = 0, clean = {};
            for (var i = 0; i < items.length; i++) {
                var e = items[i];
                if (m[e.p]) { clean[e.p] = true; c++; if (!e.d) sz += e.s; }
            }
            selMap = clean;
            selCount = c;
            selSize = sz;
            selVer++;
        }
        function selectOnly(i) {
            var m = {};
            if (i >= 0 && i < items.length) m[items[i].p] = true;
            setSel(m);
            cur = i;
            anchor = i;
        }
        function toggleSel(i) {
            if (i < 0 || i >= items.length) return;
            var m = Object.assign({}, selMap);
            var p = items[i].p;
            if (m[p]) delete m[p]; else m[p] = true;
            setSel(m);
            cur = i;
            anchor = i;
        }
        function rangeSel(i, additive) {
            if (i < 0 || i >= items.length) return;
            var a = anchor < 0 ? i : Math.min(anchor, items.length - 1);
            var m = additive ? Object.assign({}, selMap) : {};
            for (var k = Math.min(a, i); k <= Math.max(a, i); k++) m[items[k].p] = true;
            setSel(m);
            cur = i;
        }
        function selectAll() {
            var m = {};
            for (var i = 0; i < items.length; i++) m[items[i].p] = true;
            setSel(m);
        }
        function clearSel() { if (selCount) setSel({}); }
        function targets() {
            if (selCount) {
                var r = [];
                for (var i = 0; i < items.length; i++) if (selMap[items[i].p]) r.push(items[i]);
                return r;
            }
            return (miller && curItem) ? [curItem] : [];
        }
        function targetPaths() { return targets().map(function (e) { return e.p; }); }

        // ── keyboard ──
        property string typeBuf: ""
        Timer { id: typeTimer; interval: 900; onTriggered: pane.typeBuf = "" }
        function ensureVisible(i) {
            if (i < 0) return;
            var f = activeFlick();
            if (f && i < f.count) f.positionViewAtIndex(i, ListView.Contain);
        }
        function moveTo(t, shift) {
            if (!items.length) return;
            t = Math.max(0, Math.min(items.length - 1, t));
            if (shift) { if (anchor < 0) anchor = cur < 0 ? t : cur; rangeSel(t, false); }
            else if (miller) cur = t;
            else selectOnly(t);
            ensureVisible(t);
        }
        function moveBy(d, shift) {
            var n = items.length;
            if (!n) return;
            var base = cur < 0 ? (d > 0 ? -1 : n) : cur;
            moveTo(base + d, shift);
        }
        function pageStep() {
            var f = activeFlick();
            var rowH = miller ? fm.px(30) : (view === "list" ? listBox.rowH : grid.cellHeight);
            var rows = Math.max(1, Math.floor(f.height / rowH) - 1);
            return rows * ((!miller && view !== "list") ? grid.cols : 1);
        }
        function typeAhead(ch) {
            typeBuf += ch.toLowerCase();
            typeTimer.restart();
            var n = items.length;
            if (!n) return;
            var start = typeBuf.length === 1 ? cur + 1 : Math.max(cur, 0);
            for (var i = 0; i < n; i++) {
                var j = (start + i) % n;
                if (items[j].n.toLowerCase().indexOf(typeBuf) === 0) { moveTo(j, false); return; }
            }
        }
        function handleKey(ev) {
            var mods = ev.modifiers;
            var ctrl = (mods & Qt.ControlModifier) !== 0;
            var shift = (mods & Qt.ShiftModifier) !== 0;
            var alt = (mods & Qt.AltModifier) !== 0;
            var k = ev.key;
            var cols = (!miller && view !== "list") ? grid.cols : 1;
            var other = host && host.dual ? host.otherOf(pane) : null;
            var done = true;
            if (alt && k === Qt.Key_Left) back();
            else if (alt && k === Qt.Key_Right) forward();
            else if (alt && k === Qt.Key_Up) up();
            else if (alt && (k === Qt.Key_Return || k === Qt.Key_Enter)) fm.showDetails = true;
            else if (ctrl && shift && k === Qt.Key_N) fm.newFolder(path);
            else if (ctrl && alt && k === Qt.Key_N) fm.newFile(path);
            else if (ctrl && shift && k === Qt.Key_C) { var tp = targetPaths(); fm.copyText(tp.length ? tp.join("\n") : path); }
            else if (ctrl && k === Qt.Key_A) selectAll();
            else if (ctrl && k === Qt.Key_C) { if (!isTrash) fm.setClip(targetPaths(), false); }
            else if (ctrl && k === Qt.Key_X) { if (!isTrash) fm.setClip(targetPaths(), true); }
            else if (ctrl && k === Qt.Key_V) fm.paste(path);
            else if (k === Qt.Key_F2) { var t1 = targets(); if (t1.length === 1 && !isTrash) fm.renamePath(t1[0]); }
            else if (k === Qt.Key_Delete) {
                var ts = targets();
                if (ts.length) {
                    if (isTrash) fm.purgeTrash(ts);
                    else if (shift) fm.deletePaths(ts.map(function (e) { return e.p; }));
                    else fm.trashPaths(ts.map(function (e) { return e.p; }));
                }
            }
            else if (k === Qt.Key_F5 && other) { if (!other.isTrash && !isTrash) fm.transfer(targetPaths(), other.path, false); }
            else if (k === Qt.Key_F6 && other) { if (!other.isTrash && !isTrash) fm.transfer(targetPaths(), other.path, true); }
            else if (k === Qt.Key_F5) reload();
            else if (k === Qt.Key_Return || k === Qt.Key_Enter) openTargets();
            else if (k === Qt.Key_Backspace) up();
            else if (k === Qt.Key_Escape) {
                if (query !== "") query = "";
                else if (selCount) clearSel();
                else if (filterActive) resetFilters();
                else if (deep) deep = false;
                else done = false;
            }
            else if (k === Qt.Key_Up || (miller && !ctrl && k === Qt.Key_K)) moveBy(-cols, shift);
            else if (k === Qt.Key_Down || (miller && !ctrl && k === Qt.Key_J)) moveBy(cols, shift);
            else if (miller && (k === Qt.Key_Left || (!ctrl && k === Qt.Key_H))) up();
            else if (miller && (k === Qt.Key_Right || (!ctrl && k === Qt.Key_L))) {
                var ce = curItem;
                if (ce) { if (ce.d) go(ce.p); else if (!isTrash) fm.openFile(ce.p, ce); }
            }
            else if (!miller && k === Qt.Key_Left) { if (cols > 1) moveBy(-1, shift); }
            else if (!miller && k === Qt.Key_Right) { if (cols > 1) moveBy(1, shift); }
            else if (k === Qt.Key_Home || (miller && !ctrl && !shift && k === Qt.Key_G)) moveTo(0, shift);
            else if (k === Qt.Key_End || (miller && !ctrl && shift && k === Qt.Key_G)) moveTo(items.length - 1, shift && k === Qt.Key_End);
            else if (k === Qt.Key_PageUp) moveBy(-pageStep(), shift);
            else if (k === Qt.Key_PageDown) moveBy(pageStep(), shift);
            else if (k === Qt.Key_Space && !ctrl) { if (cur >= 0) { toggleSel(cur); if (miller) moveBy(1, false); } }
            else if (k === Qt.Key_Slash) focusSearch();
            else if (!ctrl && !alt && !miller && ev.text.length === 1 && ev.text > " ") typeAhead(ev.text);
            else done = false;
            ev.accepted = done;
        }

        // ── vertical view: parent folder and preview ──
        function loadParent() {
            if (!miller || !parentPath) { if (parentItems.length) parentItems = []; return; }
            var pp = parentPath;
            fm.call("list", { path: pp }, function (ok, d) {
                if (!ok || pane.parentPath !== pp) return;
                pane.parentItems = fm.visibleOnly(d.items).sort(fm.sorter(false));
                Qt.callLater(function () {
                    for (var i = 0; i < pane.parentItems.length; i++)
                        if (pane.parentItems[i].p === pane.path) { plist.positionViewAtIndex(i, ListView.Center); break; }
                });
            });
        }
        Timer { id: prevTimer; interval: 110; onTriggered: pane.loadPreview() }
        function schedulePreview() { if (miller) prevTimer.restart(); }
        function loadPreview() {
            var e = curItem;
            peekText = "";
            prevPath = e ? e.p : "";
            if (!e || isTrash) { prevItems = []; return; }
            if (e.d) {
                prevLoading = true;
                var pp = e.p;
                fm.call("list", { path: pp }, function (ok, d) {
                    if (pane.prevPath !== pp) return;
                    pane.prevLoading = false;
                    pane.prevItems = ok ? fm.visibleOnly(d.items).sort(fm.sorter(false)) : [];
                });
            } else {
                prevItems = [];
                if (["image", "video", "audio", "archive", "pdf"].indexOf(e.c) < 0 && e.s > 0 && e.s < 8000000) {
                    var fp = e.p;
                    fm.call("peek", { path: fp }, function (ok, d) {
                        if (pane.prevPath !== fp) return;
                        pane.peekText = ok && !d.binary ? d.text : "";
                    });
                }
            }
        }

        // ── crumbs ──
        readonly property var crumbs: {
            if (isTrash) return [{ n: fm.tx("Papelera", "Trash"), p: "trash://", icon: "delete" }];
            if (!path) return [];
            var r = [], base = "", rest = path;
            if (fm.home && (path === fm.home || path.indexOf(fm.home + "/") === 0)) {
                r.push({ n: fm.baseName(fm.home), p: fm.home, icon: "home" });
                base = fm.home;
                rest = path.substring(fm.home.length);
            } else r.push({ n: "", p: "/", icon: "hard_drive" });
            var parts = rest.split("/").filter(function (s) { return s.length > 0; });
            for (var i = 0; i < parts.length; i++) {
                base = base + "/" + parts[i];
                r.push({ n: parts[i], p: base, icon: "" });
            }
            return r;
        }

        readonly property string statusLeft: {
            selVer;
            var n = items.length;
            var s = fm.countLabel(n);
            if (!deepActive && n !== baseCount) s += fm.tx(" de ", " of ") + baseCount;
            if (selCount) s += "  ·  " + selCount + fm.tx(" seleccionados", " selected") + (selSize > 0 ? " (" + fm.fmtSize(selSize) + ")" : "");
            return s;
        }
        readonly property string statusRight: {
            if (deepActive) {
                if (searching) return fm.tx("Buscando… ", "Searching… ") + found.length + fm.tx(" encontrados · ", " found · ") + scanned + fm.tx(" revisados", " scanned");
                return found.length + fm.tx(" resultados", " results") + (truncated ? fm.tx(" (límite alcanzado)", " (limit reached)") : "") + " · " + scanned + fm.tx(" revisados", " scanned");
            }
            if (total > 0) return fm.fmtSize(free) + fm.tx(" libres de ", " free of ") + fm.fmtSize(total);
            return "";
        }

        // ─────────────── interface ───────────────
        Item {
            id: keyCatcher
            focus: true
            width: 0
            height: 0
            Keys.onPressed: (ev) => pane.handleKey(ev)
        }

        Rectangle {
            anchors.fill: parent
            radius: 18
            color: pane.host && pane.host.dual && pane.active ? fm.ga(fm.cPrimary, 0.025) : "transparent"
            border.width: pane.host && pane.host.dual ? 1 : 0
            border.color: pane.active ? fm.ga(fm.cPrimary, 0.42) : fm.lineCol
            Behavior on border.color { ColorAnimation { duration: 200 } }
        }
        // click anywhere in the pane → activate it
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onPressed: (m) => { pane.activate(); m.accepted = false; }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6

            // ── toolbar ──
            RowLayout {
                Layout.fillWidth: true
                spacing: 2
                IconBtn { glyph: "arrow_back"; tip: fm.tx("Atrás (Alt+←)", "Back (Alt+←)"); enabled: pane.histIdx > 0; onClicked: { pane.activate(); pane.back(); } }
                IconBtn { visible: !pane.narrow; glyph: "arrow_forward"; tip: fm.tx("Adelante (Alt+→)", "Forward (Alt+→)"); enabled: pane.histIdx < pane.hist.length - 1; onClicked: { pane.activate(); pane.forward(); } }
                IconBtn { glyph: "arrow_upward"; tip: fm.tx("Subir (Alt+↑)", "Up (Alt+↑)"); enabled: pane.parentPath !== ""; onClicked: { pane.activate(); pane.up(); } }
                IconBtn { visible: !pane.narrow; glyph: "refresh"; tip: fm.tx("Recargar (Ctrl+R)", "Reload (Ctrl+R)"); onClicked: { pane.activate(); pane.reload(); } }
                Item { width: 4; height: 1 }

                // breadcrumbs / editable path
                Rectangle {
                    id: crumbBox
                    Layout.fillWidth: true
                    Layout.minimumWidth: fm.px(56)
                    Layout.preferredHeight: fm.px(32)
                    radius: height / 2
                    color: fm.bgField
                    border.width: pathIn.activeFocus ? 1 : 0
                    border.color: fm.ga(fm.cPrimary, 0.6)
                    property bool editing: false
                    function startEdit() {
                        editing = true;
                        pathIn.text = pane.isTrash ? "trash://" : pane.path;
                        pathIn.forceActiveFocus();
                        pathIn.selectAll();
                    }
                    MouseArea {
                        anchors.fill: parent
                        visible: !crumbBox.editing
                        cursorShape: Qt.IBeamCursor
                        onClicked: pane.editPath()
                    }
                    ListView {
                        id: crumbList
                        visible: !crumbBox.editing
                        anchors.fill: parent
                        anchors.leftMargin: 4
                        anchors.rightMargin: 4
                        orientation: ListView.Horizontal
                        interactive: false
                        clip: true
                        model: pane.crumbs
                        onCountChanged: Qt.callLater(function () { crumbList.positionViewAtEnd(); })
                        onWidthChanged: Qt.callLater(function () { crumbList.positionViewAtEnd(); })
                        delegate: Item {
                            id: cd
                            required property var modelData
                            required property int index
                            readonly property bool last: index === crumbList.count - 1
                            height: crumbList.height
                            width: cdRow.width
                            Row {
                                id: cdRow
                                anchors.verticalCenter: parent.verticalCenter
                                Glyph {
                                    visible: cd.index > 0
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "chevron_right"
                                    size: fm.px(16)
                                    color: fm.cMuted
                                }
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: fm.px(24)
                                    radius: height / 2
                                    width: cdIn.width + fm.px(16)
                                    color: cdDrop.containsDrag ? fm.selStrong : (cdHov.hovered ? fm.hovCol : "transparent")
                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Row {
                                        id: cdIn
                                        anchors.centerIn: parent
                                        spacing: 4
                                        Glyph {
                                            visible: cd.modelData.icon !== ""
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: cd.modelData.icon
                                            size: fm.px(15)
                                            color: cd.last ? fm.cPrimary : fm.cOnSurfVar
                                        }
                                        Text {
                                            visible: cd.modelData.n !== ""
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: cd.modelData.n
                                            font.family: fm.fontB
                                            font.pixelSize: fm.px(12.5)
                                            font.weight: cd.last ? Font.DemiBold : Font.Medium
                                            color: cd.last ? fm.cOnSurface : fm.cOnSurfVar
                                        }
                                    }
                                    HoverHandler { id: cdHov; cursorShape: Qt.PointingHandCursor }
                                    MouseArea { anchors.fill: parent; onClicked: { pane.activate(); pane.go(cd.modelData.p); } }
                                    DropArea {
                                        id: cdDrop
                                        anchors.fill: parent
                                        enabled: !pane.isTrash
                                        onEntered: (d) => { if (!d.hasUrls) d.accepted = false; }
                                        onDropped: (d) => fm.handleDrop(d, cd.modelData.p, cdDrop)
                                    }
                                }
                            }
                        }
                    }
                    TextInput {
                        id: pathIn
                        visible: crumbBox.editing
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        verticalAlignment: TextInput.AlignVCenter
                        clip: true
                        color: fm.cOnSurface
                        font.family: fm.fontB
                        font.pixelSize: fm.px(12.5)
                        selectByMouse: true
                        selectionColor: fm.ga(fm.cPrimary, 0.45)
                        selectedTextColor: fm.cOnSurface
                        onAccepted: {
                            crumbBox.editing = false;
                            pane.go(fm.expandPath(text, pane.isTrash ? fm.home : pane.path));
                            pane.focusKeys();
                        }
                        Keys.onEscapePressed: (e) => { crumbBox.editing = false; pane.focusKeys(); e.accepted = true; }
                        onActiveFocusChanged: if (!activeFocus) crumbBox.editing = false
                    }
                }
                Item { width: 4; height: 1 }

                Field {
                    id: searchField
                    Layout.preferredWidth: pane.narrow ? Math.max(fm.px(96), pane.width * 0.3) : Math.max(fm.px(150), Math.min(fm.px(270), pane.width * 0.27))
                    glyph: pane.deep ? "travel_explore" : "search"
                    placeholder: pane.deep ? fm.tx("Buscar en subcarpetas…", "Search subfolders…") : fm.tx("Filtrar  (*.png, foto?)", "Filter  (*.png, photo?)")
                    text: pane.query
                    onEdited: (t) => pane.query = t
                    onAccepted: { if (pane.query.trim() !== "" && !pane.deep) pane.deep = true; else if (pane.deep) pane.startSearch(); }
                    onEscaped: { if (pane.query !== "") pane.query = ""; else { pane.deep = false; pane.focusKeys(); } }
                    onDownPressed: pane.focusKeys()
                    IconBtn {
                        visible: pane.query !== ""
                        width: fm.px(24); height: fm.px(24); gsize: fm.px(15)
                        glyph: "close"
                        onClicked: { pane.query = ""; pane.focusKeys(); }
                    }
                    IconBtn {
                        width: fm.px(24); height: fm.px(24); gsize: fm.px(15)
                        glyph: "account_tree"
                        active: pane.deep
                        enabled: !pane.isTrash
                        tip: fm.tx("Buscar también en subcarpetas (Enter)", "Also search subfolders (Enter)")
                        onClicked: pane.deep = !pane.deep
                    }
                }
                Item { width: 2; height: 1 }
                Seg {
                    visible: !pane.miller && !pane.narrow
                    cellW: fm.px(34)
                    current: pane.view
                    options: [
                        { value: "grid", icon: "grid_view", tip: fm.tx("Iconos grandes (Ctrl+1)", "Large icons (Ctrl+1)") },
                        { value: "list", icon: "view_list", tip: fm.tx("Lista detallada (Ctrl+2)", "Detailed list (Ctrl+2)") },
                        { value: "compact", icon: "view_module", tip: fm.tx("Cuadrícula compacta (Ctrl+3)", "Compact grid (Ctrl+3)") }
                    ]
                    onPicked: (v) => { pane.setView(v); pane.focusKeys(); }
                }
                IconBtn {
                    id: sortBtn
                    glyph: "sort"
                    tip: fm.tx("Ordenar", "Sort")
                    onClicked: { var g = sortBtn.mapToItem(null, 0, sortBtn.height + 4); fm.sortMenu(g.x, g.y); }
                }
                IconBtn {
                    glyph: "filter_alt"
                    tip: fm.tx("Filtros avanzados", "Advanced filters")
                    active: pane.filtersOpen || pane.filterActive
                    onClicked: pane.filtersOpen = !pane.filtersOpen
                }
                IconBtn {
                    visible: pane.width > fm.px(440)
                    glyph: fm.showHidden ? "visibility" : "visibility_off"
                    tip: fm.tx("Archivos ocultos (Ctrl+H)", "Hidden files (Ctrl+H)")
                    active: fm.showHidden
                    onClicked: fm.showHidden = !fm.showHidden
                }
            }

            // ── advanced filters ──
            Rectangle {
                Layout.fillWidth: true
                visible: pane.filtersOpen
                Layout.preferredHeight: filterFlow.height + 16
                radius: 18
                color: fm.bgCont
                Flow {
                    id: filterFlow
                    x: 12
                    y: 8
                    width: parent.width - 24
                    spacing: 12
                    Row {
                        spacing: 8
                        Text { anchors.verticalCenter: parent.verticalCenter; text: fm.tx("Tipo", "Type"); font.family: fm.fontB; font.pixelSize: fm.px(11); font.weight: Font.DemiBold; color: fm.cMuted }
                        Seg {
                            cellW: fm.px(36)
                            current: pane.fType
                            options: [
                                { value: "all", icon: "apps", tip: fm.tx("Todo", "All") },
                                { value: "dir", icon: "folder", tip: fm.tx("Carpetas", "Folders") },
                                { value: "image", icon: "image", tip: fm.tx("Imágenes", "Images") },
                                { value: "video", icon: "movie", tip: fm.tx("Vídeos", "Videos") },
                                { value: "audio", icon: "music_note", tip: "Audio" },
                                { value: "doc", icon: "description", tip: fm.tx("Documentos", "Documents") },
                                { value: "archive", icon: "folder_zip", tip: fm.tx("Comprimidos", "Archives") },
                                { value: "code", icon: "code", tip: fm.tx("Código", "Code") }
                            ]
                            onPicked: (v) => pane.fType = v
                        }
                    }
                    Row {
                        spacing: 8
                        Text { anchors.verticalCenter: parent.verticalCenter; text: fm.tx("Modificado", "Modified"); font.family: fm.fontB; font.pixelSize: fm.px(11); font.weight: Font.DemiBold; color: fm.cMuted }
                        Seg {
                            cellW: fm.px(62)
                            current: pane.fDate
                            options: [
                                { value: "any", label: fm.tx("Siempre", "Any") },
                                { value: "today", label: fm.tx("Hoy", "Today") },
                                { value: "week", label: fm.tx("7 días", "7 days") },
                                { value: "month", label: fm.tx("30 días", "30 days") },
                                { value: "year", label: fm.tx("1 año", "1 year") }
                            ]
                            onPicked: (v) => pane.fDate = v
                        }
                    }
                    Row {
                        spacing: 8
                        Text { anchors.verticalCenter: parent.verticalCenter; text: fm.tx("Tamaño", "Size"); font.family: fm.fontB; font.pixelSize: fm.px(11); font.weight: Font.DemiBold; color: fm.cMuted }
                        Seg {
                            cellW: fm.px(64)
                            current: pane.fSize
                            options: [
                                { value: "any", label: fm.tx("Todos", "Any") },
                                { value: "tiny", label: "< 1 MB" },
                                { value: "mid", label: "1–100 MB" },
                                { value: "big", label: "0.1–1 GB" },
                                { value: "huge", label: "> 1 GB" }
                            ]
                            onPicked: (v) => pane.fSize = v
                        }
                    }
                    PillBtn {
                        visible: pane.filterActive
                        glyph: "filter_alt_off"
                        label: fm.tx("Quitar filtros", "Clear filters")
                        onClicked: pane.resetFilters()
                    }
                }
            }

            // ── trash bar ──
            Rectangle {
                Layout.fillWidth: true
                visible: pane.isTrash
                Layout.preferredHeight: fm.px(46)
                radius: 18
                color: fm.bgCont
                Row {
                    x: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    Glyph { anchors.verticalCenter: parent.verticalCenter; text: "delete"; size: fm.px(20); color: fm.cPrimary }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: fm.tx("Papelera", "Trash") + "  ·  " + fm.countLabel(pane.raw.length)
                        font.family: fm.fontA
                        font.pixelSize: fm.px(13)
                        font.weight: Font.DemiBold
                        color: fm.cOnSurface
                    }
                }
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    PillBtn {
                        glyph: "restore_from_trash"
                        label: pane.selCount ? fm.tx("Restaurar selección", "Restore selection") : fm.tx("Restaurar todo", "Restore all")
                        enabled: pane.raw.length > 0
                        onClicked: fm.restoreTrash(pane.selCount ? pane.targets() : pane.raw)
                    }
                    PillBtn {
                        glyph: "delete_forever"
                        label: fm.tx("Vaciar papelera", "Empty trash")
                        danger: true
                        primary: true
                        enabled: pane.raw.length > 0
                        onClicked: fm.purgeTrash(null)
                    }
                }
            }

            // ── content ──
            Item {
                id: content
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                // drop on the background → current folder
                DropArea {
                    id: bgDrop
                    anchors.fill: parent
                    enabled: !pane.isTrash && !pane.deepActive && pane.path !== ""
                    onEntered: (d) => { if (!d.hasUrls || pane.dragging) d.accepted = false; }
                    onDropped: (d) => fm.handleDrop(d, pane.path, bgDrop)
                }
                Rectangle {
                    anchors.fill: parent
                    radius: 16
                    color: "transparent"
                    border.width: bgDrop.containsDrag ? 2 : 0
                    border.color: fm.ga(fm.cPrimary, 0.6)
                }

                // ───── board: large icons / compact grid ─────
                GridView {
                    id: grid
                    anchors.fill: parent
                    visible: !pane.miller && pane.view !== "list"
                    interactive: false
                    clip: true
                    cacheBuffer: 600
                    readonly property bool compact: pane.view === "compact"
                    readonly property real baseW: compact ? fm.px(232) : fm.px(116)
                    readonly property int cols: Math.max(1, Math.floor(width / baseW))
                    cellWidth: Math.floor(width / cols)
                    cellHeight: compact ? fm.px(48) : fm.px(130)
                    model: visible ? pane.items : null
                    ScrollBar.vertical: FmScrollBar {}
                    delegate: Item {
                        id: gd
                        required property var modelData
                        required property int index
                        width: grid.cellWidth
                        height: grid.cellHeight
                        readonly property bool sel: pane.selVer >= 0 && pane.selMap[modelData.p] === true
                        readonly property bool isCur: pane.cur === index
                        readonly property bool cutMark: fm.clipCut && fm.clipPaths.indexOf(modelData.p) >= 0
                        opacity: cutMark ? 0.45 : (modelData.h ? 0.7 : 1)
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 3
                            radius: 14
                            color: gdIn.dropHover ? fm.selStrong : gd.sel ? fm.selCol : (gdIn.hovered ? fm.hovCol : (gdHov.hovered ? fm.ga(fm.cOnSurfVar, 0.05) : "transparent"))
                            border.width: gd.isCur && pane.keysFocused && pane.active ? 1 : 0
                            border.color: fm.ga(fm.cPrimary, 0.6)
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }
                        HoverHandler { id: gdHov }
                        Column {
                            id: gdCol
                            visible: !grid.compact
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: fm.px(10)
                            spacing: fm.px(7)
                            FileIcon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                entry: gd.modelData
                                size: fm.px(64)
                                thumb: !grid.compact
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: Math.min(implicitWidth, gd.width - 14)
                                text: gd.modelData.n
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                font.family: fm.fontB
                                font.pixelSize: fm.px(12)
                                font.weight: gd.sel ? Font.DemiBold : Font.Medium
                                color: gd.sel ? fm.cOnSurface : fm.cOnSurfVar
                            }
                        }
                        Item {
                            visible: grid.compact
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 10
                            FileIcon {
                                id: gdcIco
                                anchors.verticalCenter: parent.verticalCenter
                                entry: gd.modelData
                                size: fm.px(30)
                                thumb: grid.compact
                            }
                            Column {
                                anchors.left: gdcIco.right
                                anchors.leftMargin: 10
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1
                                Text {
                                    id: gdcName
                                    width: parent.width
                                    text: gd.modelData.n
                                    elide: Text.ElideMiddle
                                    font.family: fm.fontB
                                    font.pixelSize: fm.px(12)
                                    font.weight: gd.sel ? Font.DemiBold : Font.Medium
                                    color: fm.cOnSurface
                                }
                                Text {
                                    id: gdcSub
                                    width: parent.width
                                    text: fm.subLabel(gd.modelData)
                                    elide: Text.ElideRight
                                    font.family: fm.fontB
                                    font.pixelSize: fm.px(10.5)
                                    color: fm.cMuted
                                }
                            }
                        }
                        // only icon and name take the mouse; the rest starts a rubber band
                        EntryInput {
                            id: gdIn
                            owner: pane
                            entry: gd.modelData
                            index: gd.index
                            anchors.fill: undefined
                            x: grid.compact ? 6 : gdCol.x - 6
                            y: grid.compact ? 4 : gdCol.y - 6
                            width: grid.compact ? Math.min(gd.width - 12, fm.px(30) + 34 + Math.max(gdcName.implicitWidth, gdcSub.implicitWidth))
                                                : gdCol.width + 12
                            height: grid.compact ? gd.height - 8 : gdCol.height + 12
                        }
                    }
                    BandArea { view: grid; owner: pane; mode: 0 }
                }
                WheelCatcher { flick: grid; enabled: grid.visible }

                // ───── board: detailed list ─────
                Item {
                    id: listBox
                    anchors.fill: parent
                    visible: !pane.miller && pane.view === "list"
                    readonly property bool showLoc: pane.isTrash || pane.deepActive
                    readonly property real wSize: fm.px(86)
                    readonly property real wDate: fm.px(152)
                    readonly property real wType: width > fm.px(720) ? fm.px(132) : 0
                    readonly property real wPerm: (width > fm.px(960) && !pane.isTrash) ? fm.px(92) : 0
                    readonly property real wLoc: showLoc ? Math.max(fm.px(140), width * 0.26) : 0
                    readonly property real wName: width - 18 - wLoc - wSize - wDate - wType - wPerm
                    readonly property real rowH: fm.px(34)
                    Row {
                        id: listHead
                        x: 8
                        width: parent.width - 8
                        height: fm.px(28)
                        HeadCell { width: listBox.wName; label: fm.tx("Nombre", "Name"); key: "name" }
                        HeadCell { width: listBox.wLoc; visible: listBox.showLoc; label: pane.isTrash ? fm.tx("Ubicación original", "Original location") : fm.tx("Carpeta", "Folder") }
                        HeadCell { width: listBox.wSize; label: fm.tx("Tamaño", "Size"); key: "size"; align: Text.AlignRight }
                        HeadCell { width: listBox.wDate; label: pane.isTrash ? fm.tx("Eliminado", "Deleted") : fm.tx("Modificado", "Modified"); key: "mtime" }
                        HeadCell { width: listBox.wType; visible: listBox.wType > 0; label: fm.tx("Tipo", "Type"); key: "type" }
                        HeadCell { width: listBox.wPerm; visible: listBox.wPerm > 0; label: fm.tx("Permisos", "Permissions") }
                    }
                    Rectangle { y: listHead.height; width: parent.width; height: 1; color: fm.lineCol }
                    ListView {
                        id: list
                        anchors.fill: parent
                        anchors.topMargin: listHead.height + 3
                        interactive: false
                        clip: true
                        cacheBuffer: 600
                        model: listBox.visible ? pane.items : null
                        ScrollBar.vertical: FmScrollBar {}
                        delegate: Item {
                            id: ld
                            required property var modelData
                            required property int index
                            width: list.width
                            height: listBox.rowH
                            readonly property bool sel: pane.selVer >= 0 && pane.selMap[modelData.p] === true
                            readonly property bool isCur: pane.cur === index
                            readonly property bool cutMark: fm.clipCut && fm.clipPaths.indexOf(modelData.p) >= 0
                            opacity: cutMark ? 0.45 : (modelData.h ? 0.7 : 1)
                            Rectangle {
                                anchors.fill: parent
                                anchors.topMargin: 1
                                anchors.bottomMargin: 1
                                radius: 10
                                color: ldIn.dropHover ? fm.selStrong : ld.sel ? fm.selCol
                                     : ((ldIn.hovered || ldHov.hovered) ? fm.hovCol : (ld.index % 2 ? fm.ga(fm.cOnSurfVar, 0.025) : "transparent"))
                                border.width: ld.isCur && pane.keysFocused && pane.active ? 1 : 0
                                border.color: fm.ga(fm.cPrimary, 0.6)
                            }
                            Row {
                                x: 8
                                height: parent.height
                                Item {
                                    width: listBox.wName
                                    height: parent.height
                                    FileIcon {
                                        id: ldIco
                                        x: 6
                                        anchors.verticalCenter: parent.verticalCenter
                                        entry: ld.modelData
                                        size: fm.px(22)
                                        tile: false
                                    }
                                    Text {
                                        id: ldName
                                        anchors.left: ldIco.right
                                        anchors.leftMargin: 10
                                        anchors.right: parent.right
                                        anchors.rightMargin: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: ld.modelData.n
                                        elide: Text.ElideMiddle
                                        font.family: fm.fontB
                                        font.pixelSize: fm.px(12.5)
                                        font.weight: ld.sel ? Font.DemiBold : Font.Medium
                                        color: fm.cOnSurface
                                    }
                                }
                                Text {
                                    visible: listBox.showLoc
                                    width: listBox.wLoc
                                    anchors.verticalCenter: parent.verticalCenter
                                    leftPadding: 8
                                    rightPadding: 8
                                    text: fm.prettyPath(pane.isTrash ? fm.dirName(ld.modelData.orig || "/") : fm.dirName(ld.modelData.p))
                                    elide: Text.ElideMiddle
                                    font.family: fm.fontB
                                    font.pixelSize: fm.px(11.5)
                                    color: fm.cMuted
                                }
                                Text {
                                    width: listBox.wSize
                                    anchors.verticalCenter: parent.verticalCenter
                                    horizontalAlignment: Text.AlignRight
                                    rightPadding: 10
                                    text: fm.subLabel(ld.modelData)
                                    font.family: fm.fontB
                                    font.pixelSize: fm.px(11.5)
                                    color: fm.cOnSurfVar
                                }
                                Text {
                                    width: listBox.wDate
                                    anchors.verticalCenter: parent.verticalCenter
                                    leftPadding: 8
                                    text: fm.fmtDate(pane.isTrash ? (ld.modelData.del || ld.modelData.m) : ld.modelData.m)
                                    elide: Text.ElideRight
                                    font.family: fm.fontB
                                    font.pixelSize: fm.px(11.5)
                                    color: fm.cOnSurfVar
                                }
                                Text {
                                    visible: listBox.wType > 0
                                    width: listBox.wType
                                    anchors.verticalCenter: parent.verticalCenter
                                    leftPadding: 8
                                    text: fm.typeLabel(ld.modelData)
                                    elide: Text.ElideRight
                                    font.family: fm.fontB
                                    font.pixelSize: fm.px(11.5)
                                    color: fm.cMuted
                                }
                                Text {
                                    visible: listBox.wPerm > 0
                                    width: listBox.wPerm
                                    anchors.verticalCenter: parent.verticalCenter
                                    leftPadding: 8
                                    text: (ld.modelData.d ? "d" : (ld.modelData.l ? "l" : "-")) + ld.modelData.perm
                                    font.family: fm.mono
                                    font.pixelSize: fm.px(11)
                                    color: fm.cMuted
                                }
                            }
                            HoverHandler { id: ldHov }
                            EntryInput {
                                id: ldIn
                                owner: pane
                                entry: ld.modelData
                                index: ld.index
                                anchors.fill: undefined
                                x: 8
                                y: 0
                                height: ld.height
                                width: Math.min(listBox.wName, 16 + ldIco.width + ldName.implicitWidth + 18)
                            }
                        }
                        BandArea { view: list; owner: pane; mode: 1; rowH: listBox.rowH }
                    }
                    WheelCatcher { flick: list; enabled: listBox.visible }
                }

                // ───── vertical (yazi style): parent · current · preview ─────
                Item {
                    id: millerBox
                    anchors.fill: parent
                    visible: pane.miller
                    readonly property real w1: width < fm.px(600) ? 0 : Math.round(width * 0.22)
                    readonly property real w2: w1 === 0 ? Math.round(width * 0.5) : Math.round(width * 0.40)

                    Rectangle {
                        id: mcol1
                        visible: millerBox.w1 > 0
                        width: Math.max(0, millerBox.w1 - 6)
                        height: parent.height
                        radius: 16
                        color: fm.ga(fm.cOnSurfVar, 0.03)
                        ListView {
                            id: plist
                            anchors.fill: parent
                            anchors.margins: 4
                            interactive: false
                            clip: true
                            model: millerBox.visible ? pane.parentItems : null
                            ScrollBar.vertical: FmScrollBar {}
                            delegate: MRow {
                                required property var modelData
                                width: plist.width
                                entry: modelData
                                isCur: modelData.p === pane.path
                                focused: false
                                clickable: true
                                onClicked: { pane.activate(); if (modelData.d) pane.go(modelData.p); else pane.go(pane.parentPath, { focus: modelData.p }); }
                            }
                        }
                        WheelCatcher { flick: plist }
                        Glyph {
                            anchors.centerIn: parent
                            visible: pane.parentPath === ""
                            text: pane.isTrash ? "delete" : "hard_drive"
                            size: fm.px(40)
                            color: fm.ga(fm.cOnSurfVar, 0.25)
                        }
                    }

                    Rectangle {
                        id: mcol2
                        x: millerBox.w1
                        width: millerBox.w2 - 6
                        height: parent.height
                        radius: 16
                        color: fm.ga(fm.cOnSurfVar, pane.active ? 0.06 : 0.04)
                        border.width: pane.keysFocused ? 1 : 0
                        border.color: fm.ga(fm.cPrimary, 0.25)
                        ListView {
                            id: mlist
                            anchors.fill: parent
                            anchors.margins: 4
                            interactive: false
                            clip: true
                            cacheBuffer: 400
                            model: millerBox.visible ? pane.items : null
                            ScrollBar.vertical: FmScrollBar {}
                            delegate: Item {
                                id: md
                                required property var modelData
                                required property int index
                                width: mlist.width
                                height: fm.px(30)
                                MRow {
                                    anchors.fill: parent
                                    entry: md.modelData
                                    isCur: pane.cur === md.index
                                    sel: pane.selVer >= 0 && pane.selMap[md.modelData.p] === true
                                    focused: pane.keysFocused
                                    dropHover: mdIn.dropHover
                                    cut: fm.clipCut && fm.clipPaths.indexOf(md.modelData.p) >= 0
                                }
                                EntryInput { id: mdIn; owner: pane; entry: md.modelData; index: md.index }
                            }
                            BandArea { view: mlist; owner: pane; mode: 1; rowH: fm.px(30) }
                        }
                        WheelCatcher { flick: mlist }
                    }

                    Rectangle {
                        id: mcol3
                        x: millerBox.w1 + millerBox.w2
                        width: millerBox.width - x
                        height: parent.height
                        radius: 16
                        color: fm.ga(fm.cOnSurfVar, 0.03)
                        clip: true
                        readonly property var e: pane.curItem
                        readonly property bool isDir: !!e && e.d
                        readonly property bool img: fm.isImage(e)
                        readonly property string th: (e && !img && !isDir) ? fm.thumbFor(e) : ""

                        ListView {
                            id: prevList
                            anchors.fill: parent
                            anchors.margins: 4
                            visible: mcol3.isDir
                            interactive: false
                            clip: true
                            model: visible ? pane.prevItems : null
                            ScrollBar.vertical: FmScrollBar {}
                            delegate: MRow {
                                required property var modelData
                                width: prevList.width
                                entry: modelData
                                focused: false
                                clickable: true
                                onClicked: { pane.activate(); pane.go(mcol3.e.p, { focus: modelData.p }); }
                            }
                        }
                        WheelCatcher { flick: prevList; enabled: prevList.visible }
                        Text {
                            anchors.centerIn: parent
                            visible: mcol3.isDir && !pane.prevLoading && pane.prevItems.length === 0
                            text: fm.tx("Carpeta vacía", "Empty folder")
                            font.family: fm.fontB
                            font.pixelSize: fm.px(12)
                            color: fm.cMuted
                        }

                        Item {
                            id: pv
                            visible: !!mcol3.e && !mcol3.isDir
                            anchors.fill: parent
                            anchors.margins: 12
                            readonly property real topH: height - pvInfo.height - 12
                            Image {
                                id: pvImg
                                width: parent.width
                                height: pv.topH
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                smooth: true
                                mipmap: true
                                source: !pv.visible ? "" : (mcol3.img ? fm.fileUrl(mcol3.e.p) : mcol3.th)
                                sourceSize: Qt.size(1200, 1200)
                                visible: status === Image.Ready
                            }
                            Flickable {
                                id: pvText
                                width: parent.width
                                height: pv.topH
                                visible: pane.peekText !== "" && !pvImg.visible
                                interactive: false
                                clip: true
                                contentHeight: pvT.height
                                Text {
                                    id: pvT
                                    width: pvText.width
                                    text: pane.peekText
                                    textFormat: Text.PlainText
                                    wrapMode: Text.WrapAnywhere
                                    font.family: fm.mono
                                    font.pixelSize: fm.px(11)
                                    color: fm.cOnSurfVar
                                }
                            }
                            WheelCatcher { flick: pvText; enabled: pvText.visible }
                            FileIcon {
                                x: (parent.width - width) / 2
                                y: Math.max(0, (pv.topH - height) / 2)
                                visible: !pvImg.visible && !pvText.visible
                                entry: mcol3.e
                                size: fm.px(104)
                                thumb: false
                            }
                            Column {
                                id: pvInfo
                                anchors.bottom: parent.bottom
                                width: parent.width
                                spacing: 3
                                Text {
                                    width: parent.width
                                    text: mcol3.e ? mcol3.e.n : ""
                                    wrapMode: Text.WrapAnywhere
                                    maximumLineCount: 3
                                    elide: Text.ElideRight
                                    font.family: fm.fontA
                                    font.pixelSize: fm.px(13.5)
                                    font.weight: Font.DemiBold
                                    color: fm.cOnSurface
                                }
                                Text {
                                    width: parent.width
                                    text: !mcol3.e ? "" : fm.typeLabel(mcol3.e) + "  ·  " + fm.fmtSize(mcol3.e.s)
                                    elide: Text.ElideRight
                                    font.family: fm.fontB
                                    font.pixelSize: fm.px(11.5)
                                    color: fm.cOnSurfVar
                                }
                                Text {
                                    width: parent.width
                                    text: !mcol3.e ? "" : (pane.isTrash ? fm.tx("Eliminado ", "Deleted ") + fm.fmtDate(mcol3.e.del) + "  ·  " + fm.prettyPath(mcol3.e.orig || "")
                                                                         : fm.tx("Modificado ", "Modified ") + fm.fmtDate(mcol3.e.m))
                                    elide: Text.ElideMiddle
                                    font.family: fm.fontB
                                    font.pixelSize: fm.px(11.5)
                                    color: fm.cMuted
                                }
                                Text {
                                    bottomPadding: 2
                                    text: mcol3.e ? "-" + mcol3.e.perm : ""
                                    font.family: fm.mono
                                    font.pixelSize: fm.px(11)
                                    color: fm.cMuted
                                }
                            }
                        }
                    }
                }

                // ───── empty / loading states ─────
                Column {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: pane.miller ? (millerBox.w1 + millerBox.w2 / 2) - content.width / 2 : 0
                    spacing: 8
                    visible: !pane.loading && pane.items.length === 0 && pane.path !== ""
                    Glyph {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: pane.deepActive ? (pane.searching ? "travel_explore" : "search_off")
                            : (pane.query !== "" || pane.filterActive) ? "filter_alt_off"
                            : pane.isTrash ? "delete" : "folder_open"
                        size: fm.px(46)
                        color: fm.ga(fm.cOnSurfVar, 0.32)
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: pane.deepActive ? (pane.searching ? fm.tx("Buscando…", "Searching…") : fm.tx("Sin resultados", "No results"))
                            : (pane.query !== "" || pane.filterActive) ? fm.tx("Nada coincide con el filtro", "Nothing matches the filter")
                            : pane.isTrash ? fm.tx("La papelera está vacía", "Trash is empty") : fm.tx("Carpeta vacía", "Empty folder")
                        font.family: fm.fontB
                        font.pixelSize: fm.px(13)
                        color: fm.cMuted
                    }
                }
                Glyph {
                    id: spinner
                    anchors.centerIn: parent
                    visible: pane.loading && loadingShow.ready
                    text: "progress_activity"
                    size: fm.px(34)
                    color: fm.cPrimary
                    RotationAnimator on rotation { from: 0; to: 360; duration: 900; loops: Animation.Infinite; running: spinner.visible }
                }
                Timer {
                    id: loadingShow
                    property bool ready: false
                    interval: 260
                    running: pane.loading
                    onRunningChanged: if (running) ready = false
                    onTriggered: ready = true
                }
            }

            // ── status bar ──
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: fm.px(20)
                spacing: 8
                Text {
                    Layout.fillWidth: true
                    text: pane.statusLeft
                    elide: Text.ElideRight
                    font.family: fm.fontB
                    font.pixelSize: fm.px(11)
                    color: fm.cMuted
                }
                Text {
                    text: pane.statusRight
                    elide: Text.ElideLeft
                    Layout.maximumWidth: pane.width * 0.6
                    font.family: fm.fontB
                    font.pixelSize: fm.px(11)
                    color: pane.searching ? fm.cPrimary : fm.cMuted
                }
                IconBtn {
                    visible: pane.searching
                    width: fm.px(20); height: fm.px(20); gsize: fm.px(14)
                    glyph: "stop_circle"
                    tip: fm.tx("Detener búsqueda", "Stop search")
                    onClicked: pane.stopSearch()
                }
            }
        }
    }

    // ══ Tab: one or two panes ══
    component TabPage: Item {
        id: page
        property int tabIndex: 0
        property string startPath: ""
        property bool dual: false
        property int activeIdx: 0
        property real split: 0.5
        readonly property bool isCur: tabIndex === fm.curTab
        readonly property var activePane: (dual && activeIdx === 1) ? paneB : paneA
        readonly property string tabTitle: activePane.isTrash ? fm.tx("Papelera", "Trash")
                                         : (activePane.deepActive ? "“" + activePane.query.trim() + "”"
                                         : (activePane.path === "" ? "…" : fm.baseName(activePane.path)))
        readonly property string tabIcon: activePane.isTrash ? "delete" : (activePane.deepActive ? "search" : (fm.placeIcons[activePane.path] || "folder"))
        function syncTab() {
            if (tabIndex >= 0 && tabIndex < tabsModel.count) {
                tabsModel.setProperty(tabIndex, "title", tabTitle);
                tabsModel.setProperty(tabIndex, "icon", tabIcon);
            }
        }
        onTabTitleChanged: syncTab()
        onTabIconChanged: syncTab()
        onTabIndexChanged: syncTab()
        onIsCurChanged: if (isCur) { fm.curPage = page; Qt.callLater(fm.refocus); }
        function otherOf(p) { return p === paneA ? paneB : paneA; }
        function collectPaths(s) { paneA.collectPaths(s); if (dual) paneB.collectPaths(s); }
        onDualChanged: {
            if (dual) {
                if (paneB.path === "") paneB.go(paneA.isTrash ? "" : paneA.path);
                activeIdx = 1;
                Qt.callLater(paneB.focusKeys);
            } else {
                activeIdx = 0;
                Qt.callLater(paneA.focusKeys);
            }
            fm.updateWatch();
        }
        Component.onCompleted: {
            paneA.go(startPath);
            if (isCur) { fm.curPage = page; Qt.callLater(fm.refocus); }
        }

        Pane {
            id: paneA
            host: page
            paneIdx: 0
            x: 0
            y: 0
            height: page.height
            width: page.dual ? Math.round((page.width - 10) * page.split) : page.width
        }
        Item {
            visible: page.dual
            x: paneA.width
            width: 10
            height: page.height
            Rectangle {
                anchors.centerIn: parent
                width: 4
                height: fm.px(44)
                radius: 2
                color: splitMa.containsMouse || splitMa.pressed ? fm.ga(fm.cPrimary, 0.6) : fm.ga(fm.cOnSurfVar, 0.16)
                Behavior on color { ColorAnimation { duration: 160 } }
            }
            MouseArea {
                id: splitMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.SplitHCursor
                onPositionChanged: (m) => {
                    if (!pressed) return;
                    var gx = mapToItem(page, m.x, 0).x;
                    page.split = Math.max(0.22, Math.min(0.78, gx / page.width));
                }
                onDoubleClicked: page.split = 0.5
            }
        }
        Pane {
            id: paneB
            host: page
            paneIdx: 1
            visible: page.dual
            x: paneA.width + 10
            y: 0
            height: page.height
            width: page.width - x
        }
    }
}
