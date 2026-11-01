// Gallery.qml — photo/video gallery; disk work in scripts/gallery_backend.py
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
    id: gal
    property var gs
    property var colors

    // inst 0 = main window (gs.galleryOpen); inst > 0 = extra window
    property int  inst: 0
    property bool extraOpen: true
    readonly property bool winOpen: inst === 0 ? (gs ? gs.galleryOpen : false) : extraOpen
    function closeWin() {
        if (inst === 0) { if (gs) gs.galleryOpen = false; return; }
        extraOpen = false;
        var g = gs, n = inst;
        if (g && typeof g.closeAppExtra === "function") Qt.callLater(function () { g.closeAppExtra("gallery", n); });
    }

    title: tx("Galería", "Gallery")
    visible: winOpen
    color: "transparent"
    width: 1200
    height: 820
    minimumWidth: 640
    minimumHeight: 460

    onClosing: (close) => { gal.closeWin(); }
    onVisibleChanged: {
        if (!visible) {
            if (gal.winOpen) gal.closeWin();
            viewPlayer.pause();
            vePlayer.pause();
            return;
        }
        if (!scannedOnce && !scanning) rescan();
        Qt.callLater(function () { keyCatcher.forceActiveFocus(); });
    }

    // ───────────────────────── style ─────────────────────────
    readonly property bool   glass: gs ? gs.glassMode : false
    readonly property bool   light: gs ? gs.colorMode === "light" : false
    readonly property real   fs:    gs ? gs.fontScale : 1
    readonly property string fontA: gs ? gs.fontPrimary : "sans-serif"
    readonly property string fontB: gs ? gs.fontSecondary : "sans-serif"
    readonly property bool   h24:   gs ? gs.clockFormat24h : true
    readonly property string lang:  gs ? gs.language : "es"

    readonly property color cPrimary:   colors ? colors.primary         : "#D0BCFF"
    readonly property color cOnPrimary: colors ? colors.colorOnPrimary  : "#381E72"
    readonly property color cPrimCont:  colors ? colors.primaryCont     : "#4F378B"
    readonly property color cSurface:   colors ? colors.surface         : "#1C1B1F"
    readonly property color cSurfElev:  colors ? colors.surfaceElevated : "#2A2535"
    readonly property color cSurfHigh:  colors ? colors.surfaceHigh     : "#332E45"
    readonly property color cSurfDeep:  colors ? colors.surfaceDeep     : "#1E1B26"
    readonly property color cOnSurface: colors ? colors.colorOnSurface  : "#E6E1E5"
    readonly property color cOnSurfVar: colors ? colors.colorOnSurfVar  : "#CAC4D0"
    readonly property color cMuted:     colors ? colors.muted           : "#8E8A93"
    readonly property color cSecCont:   colors ? colors.secondaryCont   : "#4A4458"
    readonly property color cError:     colors ? colors.error           : "#F2B8B5"

    readonly property color bgWindow: glass ? ga(cSurface, 0.6) : cSurface
    readonly property color bgCont:   glass ? ga(cdark(cSecCont), 0.6) : cdark(cSecCont)
    readonly property color bgPop:    glass ? ga(cSurfHigh, 0.97) : cSurfHigh
    readonly property color hovCol:   ga(cOnSurfVar, 0.10)
    readonly property color trackCol: ga(cOnSurfVar, light ? 0.12 : 0.10)
    readonly property color lineCol:  light ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, 0.07)

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

    // ───────────────────────── utilities ─────────────────────────
    function fileUrl(p) { return p ? "file://" + p.split("/").map(encodeURIComponent).join("/") : ""; }
    function fmtSize(b) {
        if (b === undefined || b === null || b < 0) return "—";
        if (b < 1024) return b + " B";
        var u = ["KB", "MB", "GB", "TB"], i = -1;
        do { b /= 1024; i++; } while (b >= 1024 && i < u.length - 1);
        return (b >= 100 ? b.toFixed(0) : b.toFixed(1)) + " " + u[i];
    }
    function fmtDur(sec) {
        if (!sec || sec < 0) return "0:00";
        sec = Math.round(sec);
        var h = Math.floor(sec / 3600), m = Math.floor((sec % 3600) / 60), s = sec % 60;
        return (h > 0 ? h + ":" + (m < 10 ? "0" : "") : "") + m + ":" + (s < 10 ? "0" : "") + s;
    }
    function fmtTime(t) {
        var d = new Date(t * 1000);
        return Qt.formatTime(d, h24 ? "HH:mm" : "h:mm AP");
    }
    function dayKey(t) { var d = new Date(t * 1000); return d.getFullYear() * 10000 + d.getMonth() * 100 + d.getDate(); }
    function dayLabel(t) {
        var d = new Date(t * 1000), now = new Date();
        var sod = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime() / 1000;
        if (t >= sod) return tx("Hoy", "Today");
        if (t >= sod - 86400) return tx("Ayer", "Yesterday");
        var sameYear = d.getFullYear() === now.getFullYear();
        var loc = Qt.locale(lang === "es" ? "es_MX" : "en_US");
        var f = lang === "es" ? (sameYear ? "ddd d 'de' MMMM" : "ddd d 'de' MMMM 'de' yyyy")
                              : (sameYear ? "ddd, MMMM d" : "ddd, MMMM d, yyyy");
        var s = loc.toString(d, f);
        return s.charAt(0).toUpperCase() + s.substring(1);
    }
    function fullDate(t) {
        var loc = Qt.locale(lang === "es" ? "es_MX" : "en_US");
        return loc.toString(new Date(t * 1000), lang === "es" ? "d 'de' MMMM 'de' yyyy" : "MMMM d, yyyy") + " · " + fmtTime(t);
    }
    function dirOf(p) { return p.substring(0, p.lastIndexOf("/")); }

    // ───────────────────────── backend ─────────────────────────
    readonly property string backendPath: {
        var u = Qt.resolvedUrl("scripts/gallery_backend.py").toString();
        return u.indexOf("file://") === 0 ? decodeURIComponent(u.substring(7)) : u;
    }
    property int  _rid: 0
    property bool _ready: false
    property var  _queue: []
    property var  _cbs: ({})
    property var  _evs: ({})

    Process {
        id: backend
        command: ["python3", "-u", gal.backendPath]
        running: true
        stdinEnabled: true
        stdout: SplitParser { onRead: (data) => gal._onLine(data) }
        stderr: SplitParser { onRead: (data) => console.warn("[gallery_backend] " + data) }
        onStarted: {
            gal._ready = true;
            var q = gal._queue;
            gal._queue = [];
            for (var i = 0; i < q.length; i++) backend.write(q[i]);
        }
        onExited: (code, status) => {
            gal._ready = false;
            var cbs = gal._cbs;
            gal._cbs = ({});
            gal._evs = ({});
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
    function _onLine(l) {
        var o;
        try { o = JSON.parse(l); } catch (e) { return; }
        if (o.event !== undefined) {
            if (o.event === "changed") {
                rescanDebounce.restart();
                if (o.trash) loadTrash();
            } else {
                var f = _evs[o.id];
                if (f) f(o);
            }
            return;
        }
        var cb = _cbs[o.id];
        delete _cbs[o.id];
        delete _evs[o.id];
        if (cb) cb(o.ok, o.ok ? o.data : o.error);
        else if (!o.ok && o.error !== "cancelled") toast(o.error, true);
    }

    // ───────────────────────── data ─────────────────────────
    property var  allItems: []          // [{p, n, k, m, s, d, a}] most recent first
    property var  trashItems: []
    property bool scanning: false
    property bool scannedOnce: false
    property var  roots: []
    property var  specialDirs: ({})     // { screenshots, recordings, wallpapers } (the shell's own)
    property var  extraRoots: []
    property bool hasFfmpeg: true
    property string filter: "all"       // all | image | video
    property int  zoom: 1               // 0..3
    property string page: "photos"      // photos | albums
    property var  album: null           // open album (albums page)
    property bool prefsLoaded: false

    readonly property var zoomSizes: [px(110), px(150), px(200), px(270)]

    function rescan() {
        if (scanning) { rescanDebounce.restart(); return; }
        scanning = true;
        var acc = [];
        call("scan", {}, function (ok, d) {
            gal.scanning = false;
            gal.scannedOnce = true;
            if (!ok) { gal.toast(d, true); return; }
            acc.sort(function (a, b) { return b.m - a.m; });
            gal.allItems = acc;
            gal.roots = d.roots || [];
            gal.specialDirs = d.special || ({});
            gal.hasFfmpeg = d.tools ? !!d.tools.ffmpeg : true;
            var dirs = {};
            for (var i = 0; i < acc.length; i++) dirs[acc[i].d] = true;
            gal.call("watch", { dirs: Object.keys(dirs).concat(gal.roots) });
        }, function (ev) {
            if (ev.event === "scan" && ev.items) acc = acc.concat(ev.items);
        });
        loadTrash();
    }
    Timer { id: rescanDebounce; interval: 900; onTriggered: gal.rescan() }
    function loadTrash() {
        call("trash_list", {}, function (ok, d) { if (ok) gal.trashItems = d.items || []; });
    }

    Component.onCompleted: {
        call("prefs_load", {}, function (ok, p) {
            if (ok && p) {
                if (p.filter) gal.filter = p.filter;
                if (p.zoom !== undefined) gal.zoom = Math.max(0, Math.min(3, p.zoom));
                if (p.extraRoots) gal.extraRoots = p.extraRoots;
            }
            gal.prefsLoaded = true;
        });
        if (visible && !scanning && !scannedOnce) rescan();
    }
    function savePrefs() {
        if (!prefsLoaded) return;
        call("prefs_save", { prefs: { filter: filter, zoom: zoom, extraRoots: extraRoots } });
    }
    onFilterChanged: savePrefs()
    onZoomChanged: savePrefs()

    // List shown by the current view (filtered photos or the open album)
    readonly property var currentList: {
        if (page === "albums" && album) return albumItems(album);
        if (page === "albums") return [];
        if (filter === "all") return allItems;
        var f = filter;
        return allItems.filter(function (it) { return it.k === f; });
    }
    function albumItems(al) {
        if (!al) return [];
        if (al.kind === "trash") return trashItems;
        if (al.kind === "videos") return allItems.filter(function (it) { return it.k === "video"; });
        if (al.kind === "images") return allItems.filter(function (it) { return it.k === "image"; });
        if (al.kind === "tree") {
            var pre = al.dir + "/";
            return allItems.filter(function (it) { return it.d === al.dir || it.d.indexOf(pre) === 0; });
        }
        return allItems.filter(function (it) { return it.d === al.dir; });
    }
    readonly property bool inTrash: page === "albums" && album !== null && album.kind === "trash"

    readonly property var albums: {
        var vids = null, imgs = null, nv = 0, ni = 0, dirs = {}, order = [];
        for (var i = 0; i < allItems.length; i++) {
            var it = allItems[i];
            if (it.k === "video") { nv++; if (!vids) vids = it; } else { ni++; if (!imgs) imgs = it; }
            var e = dirs[it.d];
            if (!e) { e = dirs[it.d] = { key: "dir:" + it.d, kind: "dir", dir: it.d, title: it.a, count: 0, cover: it, latest: it.m }; order.push(e); }
            e.count++;
        }
        // duplicate names (two "Screenshots" folders): the parent folder is appended
        var names = {};
        for (var j = 0; j < order.length; j++) names[order[j].title] = (names[order[j].title] || 0) + 1;
        for (var k = 0; k < order.length; k++) {
            if (names[order[k].title] > 1) {
                var par = dirOf(order[k].dir);
                order[k].title = order[k].title + " · " + par.substring(par.lastIndexOf("/") + 1);
            }
        }
        order.sort(function (a, b) { return b.latest - a.latest; });
        var out = [
            { key: "videos", kind: "videos", title: tx("Vídeos", "Videos"), count: nv, cover: vids, icon: "movie" },
            { key: "images", kind: "images", title: tx("Imágenes", "Images"), count: ni, cover: imgs, icon: "image" }
        ];
        // Shell folders pinned on top: Screenshots, Recordings, Wallpapers
        var pins = [
            { k: "screenshots", title: "Screenshots", icon: "screenshot_monitor" },
            { k: "recordings",  title: "Recordings",  icon: "screen_record" },
            { k: "wallpapers",  title: "Wallpapers",  icon: "wallpaper" }
        ];
        for (var q = 0; q < pins.length; q++) {
            var pd = specialDirs[pins[q].k];
            if (!pd) continue;
            // includes subfolders (wallpapers usually come in collections)
            for (var r = 0; r < order.length; r++) if (order[r].dir === pd) { order.splice(r, 1); break; }
            var pc = 0, pcov = null, pre = pd + "/";
            for (var z = 0; z < allItems.length; z++) {
                var iz = allItems[z];
                if (iz.d === pd || iz.d.indexOf(pre) === 0) { pc++; if (!pcov) pcov = iz; }
            }
            out.push({ key: "tree:" + pd, kind: "tree", dir: pd, title: pins[q].title, icon: pins[q].icon,
                       count: pc, cover: pcov, latest: pcov ? pcov.m : 0 });
        }
        out = out.concat(order);
        out.push({ key: "trash", kind: "trash", title: tx("Papelera", "Trash"), count: trashItems.length,
                   cover: trashItems.length ? trashItems[0] : null, icon: "delete" });
        return out;
    }
    function openAlbum(al) { clearSel(); album = al; gridView.positionViewAtBeginning(); }

    // ── video thumbnails (generated by the backend with ffmpeg) ──
    property var thumbs: ({})       // path → { path, dur }
    property var _thumbReq: ({})
    property var _thumbAcc: ({})
    property var _thumbPending: []
    function videoThumb(it) {
        var t = thumbs[it.p];
        if (t) return t;
        // requested outside the binding (call() writes properties and would create a loop)
        if (!_thumbReq[it.p]) {
            _thumbReq[it.p] = true;
            _thumbPending.push(it.p);
            Qt.callLater(gal._requestThumbs);
        }
        return null;
    }
    function _requestThumbs() {
        var l = _thumbPending;
        _thumbPending = [];
        for (var i = 0; i < l.length; i++) {
            (function (p) {
                gal.call("thumb", { path: p }, function (ok, d) {
                    gal._thumbAcc[p] = ok ? d : { path: "", dur: 0 };
                    thumbFlush.restart();
                });
            })(l[i]);
        }
    }
    Timer {
        id: thumbFlush
        interval: 120
        onTriggered: {
            var m = Object.assign({}, gal.thumbs, gal._thumbAcc);
            gal._thumbAcc = ({});
            gal.thumbs = m;
        }
    }

    // ── rows grouped by day for the grid ──
    readonly property int cols: Math.max(2, Math.floor((gridView.width - px(32) + px(3)) / (zoomSizes[zoom] + px(3))))
    readonly property real cell: (gridView.width - px(32) - px(3) * (cols - 1)) / cols
    readonly property var rows: {
        var list = currentList, out = [], key = -1, row = null, n = cols;
        var byDel = inTrash;
        for (var i = 0; i < list.length; i++) {
            var it = list[i];
            var t = byDel ? (it.del || it.m) : it.m;
            var k = dayKey(t);
            if (k !== key) {
                key = k;
                out.push({ h: true, label: dayLabel(t), first: out.length === 0 });
                row = null;
            }
            if (!row || row.items.length >= n) { row = { h: false, items: [] }; out.push(row); }
            row.items.push({ it: it, i: i });
        }
        return out;
    }

    // ── selection ──
    property var selMap: ({})
    property int selCount: 0
    readonly property bool selecting: selCount > 0
    function isSel(p) { return selMap[p] === true; }
    function toggleSel(p) {
        var m = Object.assign({}, selMap);
        if (m[p]) delete m[p]; else m[p] = true;
        selMap = m;
        selCount = Object.keys(m).length;
    }
    function clearSel() { selMap = ({}); selCount = 0; }
    function selectAll() {
        var m = {}, l = currentList;
        for (var i = 0; i < l.length; i++) m[l[i].p] = true;
        selMap = m;
        selCount = l.length;
    }
    function selItems() {
        var out = [], l = currentList;
        for (var i = 0; i < l.length; i++) if (selMap[l[i].p]) out.push(l[i]);
        return out;
    }

    // ── actions ──
    function trashItemsAct(items) {
        if (!items.length) return;
        call("trash", { paths: items.map(function (e) { return e.p; }) }, function (ok, d) {
            if (!ok) { gal.toast(d, true); return; }
            if (d.errors && d.errors.length) gal.toast(d.errors[0], true);
            else gal.toast(items.length === 1 ? tx("Movido a la papelera", "Moved to trash")
                                              : items.length + " " + tx("elementos movidos a la papelera", "items moved to trash"));
            gal.removeLocal(items);
            gal.loadTrash();
        });
    }
    function restoreAct(items) {
        if (!items.length) return;
        call("trash_restore", { ids: items.map(function (e) { return e.tid; }) }, function (ok, d) {
            if (!ok) { gal.toast(d, true); return; }
            gal.toast(tx("Restaurado", "Restored"));
            gal.loadTrash();
            gal.rescan();
        });
    }
    function purgeAct(items) {
        var ids = items ? items.map(function (e) { return e.tid; }) : null;
        confirm(items ? (items.length === 1 ? tx("¿Eliminar definitivamente?", "Delete permanently?")
                                            : tx("¿Eliminar %1 elementos definitivamente?", "Delete %1 items permanently?").arg(items.length))
                      : tx("¿Vaciar la papelera?", "Empty the trash?"),
                tx("No se puede deshacer.", "This can't be undone."),
                tx("Eliminar", "Delete"),
                function () {
                    gal.call("trash_purge", ids ? { ids: ids } : {}, function (ok, d) {
                        if (!ok) { gal.toast(d, true); return; }
                        gal.toast(tx("Eliminado", "Deleted"));
                        if (gal.viewing) gal.closeViewer();
                        gal.loadTrash();
                    });
                });
    }
    function removeLocal(items) {
        var gone = {};
        for (var i = 0; i < items.length; i++) gone[items[i].p] = true;
        allItems = allItems.filter(function (e) { return !gone[e.p]; });
        clearSel();
    }
    function showInFolder(it) {
        var d = it.tid ? dirOf(it.orig || it.p) : it.d;
        if (gs && typeof gs.openFileExplorer === "function") gs.openFileExplorer(d);
        else Quickshell.execDetached(["xdg-open", d]);
    }
    function openExternal(it) { Quickshell.execDetached(["xdg-open", it.p]); }
    function copyImage(it) {
        call("clip_image", { path: it.p }, function (ok, d) {
            gal.toast(ok ? tx("Copiado al portapapeles", "Copied to clipboard") : d, !ok);
        });
    }

    // ───────────────────────── viewer ─────────────────────────
    property var  viewList: []
    property int  viewIndex: -1
    readonly property bool viewing: viewIndex >= 0 && viewIndex < viewList.length
    readonly property var  viewItem: viewing ? viewList[viewIndex] : null
    property bool viewInfo: false
    property bool viewChrome: true
    function openViewer(list, i) {
        viewList = list;
        viewIndex = i;
        resetZoom();
        viewChrome = true;
    }
    function closeViewer() {
        viewPlayer.stop();
        viewIndex = -1;
        viewList = [];
        keyCatcher.forceActiveFocus();
    }
    function viewStep(d) {
        if (!viewing) return;
        var n = viewIndex + d;
        if (n < 0 || n >= viewList.length) return;
        viewIndex = n;
        resetZoom();
    }
    function viewTrashCurrent() {
        if (!viewItem) return;
        var it = viewItem, l = viewList.slice(), i = viewIndex;
        if (it.tid) { purgeAct([it]); return; }
        trashItemsAct([it]);
        l.splice(i, 1);
        viewList = l;
        if (!l.length) { closeViewer(); return; }
        viewIndex = Math.min(i, l.length - 1);
        resetZoom();
    }
    property real vZoom: 1
    property real vPanX: 0
    property real vPanY: 0
    function resetZoom() { vZoom = 1; vPanX = 0; vPanY = 0; }
    onViewItemChanged: {
        viewPlayer.stop();
        if (viewItem && viewItem.k === "video") {
            viewPlayer.source = fileUrl(viewItem.p);
            viewPlayer.play();
        } else viewPlayer.source = "";
    }

    MediaPlayer {
        id: viewPlayer
        videoOutput: viewVideo
        audioOutput: AudioOutput { id: viewAudio; volume: 1.0 }
    }

    // ───────────────────────── image editor ─────────────────────────
    property var  imgEdit: null          // item being edited
    property string ieTool: "crop"       // crop | pen | text
    property int  ieColor: 0
    property int  ieSize: 1
    property real ieRatio: 0             // 0 = free
    property var  ieCrop: ({ x: 0, y: 0, w: 1, h: 1 })   // image pixels
    property var  ieStrokes: []          // [{ c, w, pts }] in image pixels
    property var  ieCur: []
    property bool ieDrawing: false
    property var  ieTexts: []            // [{ x, y, t, c, s }]
    property var  ieHistory: []          // "s" | "t" | { crop }
    property bool ieEditingText: false
    property real ieTextX: 0
    property real ieTextY: 0
    property bool ieBusy: false
    readonly property var inkColors: ["#F44336", "#FF9800", "#FFEB3B", "#4CAF50", "#2196F3", "#9C27B0", "#FFFFFF", "#000000"]
    readonly property var penSizes: [3, 6, 11]
    readonly property var textSizes: [20, 30, 46]

    function openImageEditor(it) {
        viewPlayer.pause();
        ieStrokes = []; ieTexts = []; ieHistory = []; ieCur = [];
        ieEditingText = false; ieDrawing = false; ieBusy = false;
        ieTool = "crop"; ieRatio = 0;
        ieCrop = ({ x: 0, y: 0, w: 1, h: 1 });
        imgEdit = it;
    }
    function closeImageEditor() { imgEdit = null; keyCatcher.forceActiveFocus(); }
    function ieUndo() {
        if (ieEditingText) { ieEditingText = false; return; }
        if (!ieHistory.length) return;
        var h = ieHistory.slice(), k = h.pop();
        ieHistory = h;
        if (k === "s") ieStrokes = ieStrokes.slice(0, -1);
        else if (k === "t") ieTexts = ieTexts.slice(0, -1);
        else if (k && k.crop) ieCrop = k.crop;
    }
    function ieCommitText() {
        if (!ieEditingText) return;
        var t = ieTextInput.text;
        ieEditingText = false;
        if (t.trim() !== "") {
            ieTexts = ieTexts.concat([{ x: ieTextX, y: ieTextY, t: t, c: palette[ieColor], s: textSizes[ieSize] / iePage.k }]);
            ieHistory = ieHistory.concat(["t"]);
        }
        keyCatcher.forceActiveFocus();
    }
    function ieSave(replace) {
        if (ieBusy || !imgEdit) return;
        ieCommitText();
        ieBusy = true;
        var src = imgEdit.p, crop = ieCrop, w = iePage.srcW, h = iePage.srcH;
        var full = crop.x <= 0.5 && crop.y <= 0.5 && Math.abs(crop.w - w) < 1 && Math.abs(crop.h - h) < 1;
        call("tmp_path", {}, function (ok, d) {
            if (!ok) { gal.ieBusy = false; gal.toast(d, true); return; }
            var tmp = d.path;
            iePage.grabToImage(function (res) {
                if (!res.saveToFile(tmp)) { gal.ieBusy = false; gal.toast(tx("No se pudo exportar la imagen", "Couldn't export the image"), true); return; }
                gal.call("image_finalize", { tmp: tmp, src: src, replace: replace, crop: full ? null : crop }, function (ok2, d2) {
                    gal.ieBusy = false;
                    if (!ok2) { gal.toast(d2, true); return; }
                    gal.toast(replace ? tx("Imagen guardada", "Image saved") : tx("Copia guardada", "Copy saved"));
                    gal.closeImageEditor();
                    gal.closeViewer();
                    gal.rescan();
                });
            }, Qt.size(Math.round(w), Math.round(h)));
        });
    }

    // ───────────────────────── video editor ─────────────────────────
    property var  vidEdit: null
    property real veDur: 0
    property real veW: 0
    property real veH: 0
    property real veStart: 0
    property real veEnd: 0
    property bool veCropOn: false
    property real veRatio: 0
    property var  veCrop: ({ x: 0, y: 0, w: 1, h: 1 })
    property bool veBusy: false
    property real veProgress: 0
    property int  veJob: 0
    function openVideoEditor(it) {
        viewPlayer.pause();
        veBusy = false; veProgress = 0; veCropOn = false; veRatio = 0;
        veDur = 0; veW = 0; veH = 0; veStart = 0; veEnd = 0;
        vidEdit = it;
        vePlayer.source = fileUrl(it.p);
        call("vinfo", { path: it.p }, function (ok, d) {
            if (!ok || !gal.vidEdit) return;
            gal.veW = d.w || 0; gal.veH = d.h || 0;
            if (d.dur) { gal.veDur = d.dur; gal.veEnd = d.dur; }
            gal.veCrop = ({ x: 0, y: 0, w: gal.veW, h: gal.veH });
        });
    }
    function closeVideoEditor() {
        if (veBusy && veJob) call("cancel", { job: veJob });
        vePlayer.stop();
        vePlayer.source = "";
        vidEdit = null;
        keyCatcher.forceActiveFocus();
    }
    function veSave(replace) {
        if (veBusy || !vidEdit) return;
        if (!hasFfmpeg) { toast(tx("Instala ffmpeg para editar vídeos", "Install ffmpeg to edit videos"), true); return; }
        vePlayer.pause();
        veBusy = true; veProgress = 0;
        var args = { path: vidEdit.p, start: veStart, end: veEnd, replace: replace };
        if (veCropOn && !(veCrop.x <= 0 && veCrop.y <= 0 && veCrop.w >= veW && veCrop.h >= veH)) args.crop = veCrop;
        veJob = call("video_edit", args, function (ok, d) {
            gal.veBusy = false;
            gal.veJob = 0;
            if (!ok) { if (d !== "cancelled") gal.toast(d, true); return; }
            gal.toast(tx("Vídeo guardado", "Video saved"));
            gal.closeVideoEditor();
            gal.closeViewer();
            gal.rescan();
        }, function (ev) {
            if (ev.event === "job" && ev.progress !== undefined) gal.veProgress = ev.progress;
        });
    }
    MediaPlayer {
        id: vePlayer
        videoOutput: veVideo
        audioOutput: AudioOutput { volume: 1.0 }
        onPositionChanged: {
            if (gal.vidEdit && vePlayer.playbackState === MediaPlayer.PlayingState && gal.veEnd > 0 && vePlayer.position / 1000 >= gal.veEnd) {
                vePlayer.pause();
                vePlayer.setPosition(Math.round(gal.veStart * 1000));
            }
        }
        onDurationChanged: {
            if (gal.vidEdit && vePlayer.duration > 0 && gal.veDur <= 0) { gal.veDur = vePlayer.duration / 1000; gal.veEnd = gal.veDur; }
        }
    }

    // ───────────────────────── notices / dialogs ─────────────────────────
    property string toastText: ""
    property bool   toastErr: false
    function toast(t, err) { toastText = String(t); toastErr = !!err; toastTimer.restart(); }
    Timer { id: toastTimer; interval: 3200; onTriggered: gal.toastText = "" }

    property string dlgTitle: ""
    property string dlgBody: ""
    property string dlgOk: ""
    property var    dlgFn: null
    property bool   dlgOpen: false
    function confirm(t, b, ok, fn) { dlgTitle = t; dlgBody = b; dlgOk = ok; dlgFn = fn; dlgOpen = true; }

    property bool foldersOpen: false
    property bool filterMenu: false
    property bool saveMenu: false

    // ───────────────────────── shortcuts ─────────────────────────
    Shortcut { sequence: "Escape"; onActivated: gal.onEscape() }
    Shortcut { sequences: ["Left"];  enabled: gal.viewing && !gal.imgEdit && !gal.vidEdit; onActivated: gal.viewStep(-1) }
    Shortcut { sequences: ["Right"]; enabled: gal.viewing && !gal.imgEdit && !gal.vidEdit; onActivated: gal.viewStep(1) }
    Shortcut { sequence: "Delete"; enabled: !gal.imgEdit && !gal.vidEdit && !gal.foldersOpen && !gal.dlgOpen && (gal.viewing || gal.selecting); onActivated: { if (gal.viewing) gal.viewTrashCurrent(); else if (gal.inTrash) gal.purgeAct(gal.selItems()); else gal.trashItemsAct(gal.selItems()); } }
    Shortcut { sequence: "E"; enabled: gal.viewing && !gal.imgEdit && !gal.vidEdit && gal.viewItem && !gal.viewItem.tid; onActivated: gal.editCurrent() }
    Shortcut { sequence: "Space"; enabled: !gal.ieEditingText && ((gal.viewing && gal.viewItem && gal.viewItem.k === "video" && !gal.vidEdit) || gal.vidEdit); onActivated: { var pl = gal.vidEdit ? vePlayer : viewPlayer; if (pl.playbackState === MediaPlayer.PlayingState) pl.pause(); else pl.play(); } }
    Shortcut { sequence: "Ctrl+Z"; enabled: gal.imgEdit !== null; onActivated: gal.ieUndo() }
    Shortcut { sequence: "Ctrl+A"; enabled: !gal.viewing && !gal.imgEdit && !gal.vidEdit && !gal.foldersOpen; onActivated: gal.selectAll() }
    Shortcut { sequence: "F5"; onActivated: gal.rescan() }
    Shortcut { sequence: "Ctrl+Q"; onActivated: gal.closeWin() }
    function onEscape() {
        if (dlgOpen) { dlgOpen = false; return; }
        if (saveMenu) { saveMenu = false; return; }
        if (filterMenu) { filterMenu = false; return; }
        if (foldersOpen) { foldersOpen = false; return; }
        if (imgEdit) { if (ieEditingText) ieEditingText = false; else closeImageEditor(); return; }
        if (vidEdit) { closeVideoEditor(); return; }
        if (viewing) { closeViewer(); return; }
        if (selecting) { clearSel(); return; }
        if (page === "albums" && album) { album = null; return; }
    }
    function editCurrent() {
        if (!viewItem || viewItem.tid) return;
        if (viewItem.k === "image") openImageEditor(viewItem);
        else openVideoEditor(viewItem);
    }

    // ══ Components ══
    component Glyph: Text {
        property real size: 18
        font.family: "Material Symbols Rounded"
        font.pixelSize: size
        color: gal.cOnSurfVar
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }
    component IconBtn: Rectangle {
        id: ib
        property string glyph: ""
        property bool active: false
        property bool danger: false
        property bool onDark: false
        property real gsize: 20
        signal clicked()
        implicitWidth: gal.px(38)
        implicitHeight: gal.px(38)
        width: implicitWidth
        height: implicitHeight
        radius: height / 2
        opacity: enabled ? 1 : 0.35
        color: active ? gal.ga(gal.cPrimary, 0.20)
             : (ibHov.hovered ? (onDark ? Qt.rgba(1, 1, 1, 0.14) : (danger ? gal.ga(gal.cError, 0.16) : gal.hovCol)) : "transparent")
        Behavior on color { ColorAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Glyph {
            anchors.centerIn: parent
            text: ib.glyph
            size: ib.gsize
            color: ib.onDark ? "white" : (ib.active ? gal.cPrimary : (ib.danger && ibHov.hovered ? gal.cError : gal.cOnSurfVar))
        }
        HoverHandler { id: ibHov; cursorShape: Qt.PointingHandCursor }
        MouseArea { anchors.fill: parent; onClicked: ib.clicked() }
    }
    component PillBtn: Rectangle {
        id: pb
        property string glyph: ""
        property string label: ""
        property bool primary: false
        property bool danger: false
        signal clicked()
        implicitHeight: gal.px(36)
        implicitWidth: pbRow.width + gal.px(30)
        width: implicitWidth
        height: implicitHeight
        radius: height / 2
        opacity: enabled ? 1 : 0.4
        readonly property color base: danger ? gal.cError : gal.cPrimary
        color: primary ? (pbHov.hovered ? Qt.lighter(base, 1.08) : base)
                       : (pbHov.hovered ? gal.ga(base, 0.22) : gal.ga(base, 0.12))
        Behavior on color { ColorAnimation { duration: 160 } }
        Row {
            id: pbRow
            anchors.centerIn: parent
            spacing: 6
            Glyph {
                visible: pb.glyph !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: pb.glyph
                size: gal.px(18)
                color: pb.primary ? (pb.danger ? Qt.darker(gal.cError, 3) : gal.cOnPrimary) : pb.base
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: pb.label
                font.family: gal.fontB
                font.pixelSize: gal.px(13)
                font.weight: Font.DemiBold
                color: pb.primary ? (pb.danger ? Qt.darker(gal.cError, 3) : gal.cOnPrimary) : pb.base
            }
        }
        HoverHandler { id: pbHov; cursorShape: Qt.PointingHandCursor }
        MouseArea { anchors.fill: parent; onClicked: pb.clicked() }
    }
    // Segmented tabs
    component Seg: Row {
        id: seg
        property var options: []      // [{ value, label, icon }]
        property var current
        signal picked(var value)
        spacing: 3
        Repeater {
            model: seg.options
            delegate: Rectangle {
                id: sgc
                required property var modelData
                required property int index
                readonly property bool sel: seg.current === modelData.value
                readonly property bool first: index === 0
                readonly property bool last: index === seg.options.length - 1
                height: gal.px(36)
                width: sgRow.width + gal.px(30)
                readonly property real rL: sel ? height / 2 : (first ? height / 2 : 6)
                readonly property real rR: sel ? height / 2 : (last ? height / 2 : 6)
                topLeftRadius: rL; bottomLeftRadius: rL; topRightRadius: rR; bottomRightRadius: rR
                color: sel ? gal.cPrimary : (sgHov.hovered ? Qt.lighter(gal.trackCol, 1.6) : gal.trackCol)
                Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Row {
                    id: sgRow
                    anchors.centerIn: parent
                    spacing: 6
                    Glyph { visible: !!sgc.modelData.icon; anchors.verticalCenter: parent.verticalCenter; text: sgc.modelData.icon || ""; size: gal.px(18); color: sgc.sel ? gal.cOnPrimary : gal.cOnSurfVar }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: sgc.modelData.label
                        font.family: gal.fontB; font.pixelSize: gal.px(13)
                        font.weight: sgc.sel ? Font.DemiBold : Font.Medium
                        color: sgc.sel ? gal.cOnPrimary : gal.cOnSurfVar
                    }
                }
                HoverHandler { id: sgHov; cursorShape: Qt.PointingHandCursor }
                MouseArea { anchors.fill: parent; onClicked: if (!sgc.sel) seg.picked(sgc.modelData.value) }
            }
        }
    }
    // Image with rounded corners
    component RoundImg: Item {
        id: ri
        property string source: ""
        property real radius: 14
        property size sourceSize: Qt.size(320, 320)
        Image {
            id: riImg
            anchors.fill: parent
            source: ri.source
            sourceSize: ri.sourceSize
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            autoTransform: true
            smooth: true
            visible: false
        }
        Rectangle { id: riMask; anchors.fill: parent; radius: ri.radius; visible: false; layer.enabled: true }
        MultiEffect {
            anchors.fill: parent
            source: riImg
            maskEnabled: true
            maskSource: riMask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }
    }
    // Color palette + sizes (image editor)
    component ColorDot: Item {
        id: cd
        property color dot: "white"
        property bool sel: false
        signal clicked()
        width: gal.px(30); height: gal.px(36)
        Rectangle {
            anchors.centerIn: parent
            width: cd.sel ? gal.px(26) : gal.px(20); height: width; radius: width / 2
            Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }
            color: cd.dot
            border.width: cd.sel ? 2 : 1
            border.color: cd.sel ? gal.cPrimary : gal.ga(gal.cOnSurface, 0.3)
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: cd.clicked() }
    }

    // Reusable crop box (image and video). rect in media pixels.
    component CropBox: Item {
        id: cb
        property real vx: 0
        property real vy: 0
        property real vw: 1
        property real vh: 1
        property real srcW: 1
        property real srcH: 1
        property var  rect: ({ x: 0, y: 0, w: 1, h: 1 })
        property real ratio: 0
        property bool active: true
        signal edited(var r)
        signal begin()
        readonly property real k: vw / Math.max(1, srcW)
        readonly property real rx: vx + rect.x * k
        readonly property real ry: vy + rect.y * k
        readonly property real rw: rect.w * k
        readonly property real rh: rect.h * k
        readonly property color dimCol: Qt.rgba(0, 0, 0, active ? 0.55 : 0.35)

        function setRect(nx, ny, nw, nh) {
            var minS = 16;
            nw = Math.max(minS, Math.min(srcW, nw));
            nh = Math.max(minS, Math.min(srcH, nh));
            nx = Math.max(0, Math.min(srcW - nw, nx));
            ny = Math.max(0, Math.min(srcH - nh, ny));
            edited({ x: nx, y: ny, w: nw, h: nh });
        }

        // dim outside the crop
        Rectangle { x: cb.vx; y: cb.vy; width: cb.vw; height: cb.ry - cb.vy; color: cb.dimCol }
        Rectangle { x: cb.vx; y: cb.ry + cb.rh; width: cb.vw; height: cb.vy + cb.vh - cb.ry - cb.rh; color: cb.dimCol }
        Rectangle { x: cb.vx; y: cb.ry; width: cb.rx - cb.vx; height: cb.rh; color: cb.dimCol }
        Rectangle { x: cb.rx + cb.rw; y: cb.ry; width: cb.vx + cb.vw - cb.rx - cb.rw; height: cb.rh; color: cb.dimCol }
        Rectangle {
            x: cb.rx; y: cb.ry; width: cb.rw; height: cb.rh
            color: "transparent"
            border.width: 2
            border.color: "white"
            visible: cb.active
            // rule of thirds
            Repeater {
                model: 2
                delegate: Item {
                    required property int index
                    Rectangle { x: (index + 1) * cb.rw / 3; y: 0; width: 1; height: cb.rh; color: Qt.rgba(1, 1, 1, 0.45) }
                    Rectangle { x: 0; y: (index + 1) * cb.rh / 3; width: cb.rw; height: 1; color: Qt.rgba(1, 1, 1, 0.45) }
                }
            }
        }
        // move
        MouseArea {
            x: cb.rx; y: cb.ry; width: cb.rw; height: cb.rh
            enabled: cb.active
            cursorShape: Qt.SizeAllCursor
            property real sx: 0
            property real sy: 0
            property var r0: null
            onPressed: (m) => { cb.begin(); var g = mapToItem(cb, m.x, m.y); sx = g.x; sy = g.y; r0 = cb.rect; }
            onPositionChanged: (m) => {
                if (!pressed || !r0) return;
                var g = mapToItem(cb, m.x, m.y);
                cb.setRect(r0.x + (g.x - sx) / cb.k, r0.y + (g.y - sy) / cb.k, r0.w, r0.h);
            }
        }
        // handles
        Repeater {
            model: ["tl", "tr", "bl", "br", "t", "b", "l", "r"]
            delegate: Item {
                id: hd
                required property string modelData
                readonly property bool edge: modelData.length === 1
                readonly property bool onL: modelData.indexOf("l") >= 0
                readonly property bool onR: modelData.indexOf("r") >= 0
                readonly property bool onT: modelData.indexOf("t") >= 0
                readonly property bool onB: modelData.indexOf("b") >= 0
                visible: cb.active && !(edge && cb.ratio > 0)
                width: gal.px(28); height: gal.px(28)
                x: (onL ? cb.rx : (onR ? cb.rx + cb.rw : cb.rx + cb.rw / 2)) - width / 2
                y: (onT ? cb.ry : (onB ? cb.ry + cb.rh : cb.ry + cb.rh / 2)) - height / 2
                Rectangle {
                    anchors.centerIn: parent
                    width: hd.edge ? ((hd.onT || hd.onB) ? gal.px(26) : gal.px(6)) : gal.px(16)
                    height: hd.edge ? ((hd.onL || hd.onR) ? gal.px(26) : gal.px(6)) : gal.px(16)
                    radius: Math.min(width, height) / 2
                    color: "white"
                    border.width: 1
                    border.color: Qt.rgba(0, 0, 0, 0.3)
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: hd.edge ? ((hd.onL || hd.onR) ? Qt.SizeHorCursor : Qt.SizeVerCursor)
                               : (((hd.onT && hd.onL) || (hd.onB && hd.onR)) ? Qt.SizeFDiagCursor : Qt.SizeBDiagCursor)
                    property real sx: 0
                    property real sy: 0
                    property var r0: null
                    onPressed: (m) => { cb.begin(); var g = mapToItem(cb, m.x, m.y); sx = g.x; sy = g.y; r0 = cb.rect; }
                    onPositionChanged: (m) => {
                        if (!pressed || !r0) return;
                        var g = mapToItem(cb, m.x, m.y);
                        var dx = (g.x - sx) / cb.k, dy = (g.y - sy) / cb.k;
                        var x0 = r0.x, y0 = r0.y, x1 = r0.x + r0.w, y1 = r0.y + r0.h;
                        if (hd.onL) x0 = Math.max(0, Math.min(x1 - 16, x0 + dx));
                        if (hd.onR) x1 = Math.min(cb.srcW, Math.max(x0 + 16, x1 + dx));
                        if (hd.onT) y0 = Math.max(0, Math.min(y1 - 16, y0 + dy));
                        if (hd.onB) y1 = Math.min(cb.srcH, Math.max(y0 + 16, y1 + dy));
                        if (cb.ratio > 0) {
                            var w = x1 - x0, h = w / cb.ratio;
                            if (hd.onT) { y0 = y1 - h; if (y0 < 0) { y0 = 0; h = y1; w = h * cb.ratio; if (hd.onL) x0 = x1 - w; else x1 = x0 + w; } }
                            else { y1 = y0 + h; if (y1 > cb.srcH) { y1 = cb.srcH; h = y1 - y0; w = h * cb.ratio; if (hd.onL) x0 = x1 - w; else x1 = x0 + w; } }
                        }
                        cb.edited({ x: x0, y: y0, w: x1 - x0, h: y1 - y0 });
                    }
                }
            }
        }
    }
    // Largest crop rectangle with a given aspect ratio, centered
    function ratioRect(sw, sh, r) {
        if (r <= 0) return { x: 0, y: 0, w: sw, h: sh };
        var w = sw, h = w / r;
        if (h > sh) { h = sh; w = h * r; }
        return { x: (sw - w) / 2, y: (sh - h) / 2, w: w, h: h };
    }
    readonly property var ratios: [
        { v: 0, label: tx("Libre", "Free") }, { v: 1, label: "1:1" }, { v: 4 / 3, label: "4:3" },
        { v: 16 / 9, label: "16:9" }, { v: 9 / 16, label: "9:16" }
    ]

    // ══ UI ══
    Rectangle {
        id: rootBg
        anchors.fill: parent
        color: gal.bgWindow
        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutCubic } }
        clip: true

        Item { id: keyCatcher; focus: true }

        // ───────────── header ─────────────
        Item {
            id: header
            x: 0; y: 0
            width: parent.width
            height: gal.px(64)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: gal.px(16)
                anchors.rightMargin: gal.px(12)
                spacing: gal.px(10)

                IconBtn {
                    visible: gal.page === "albums" && gal.album !== null
                    glyph: "arrow_back"
                    onClicked: { gal.clearSel(); gal.album = null; }
                }
                Column {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                        width: parent.width
                        text: gal.selecting ? (gal.selCount + " " + tx("seleccionados", "selected"))
                              : (gal.page === "albums" && gal.album ? gal.album.title
                              : (gal.page === "albums" ? tx("Álbumes", "Albums") : tx("Fotos", "Photos")))
                        font.family: gal.fontA; font.pixelSize: gal.px(22); font.weight: Font.Bold
                        color: gal.cOnSurface
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        visible: text !== ""
                        text: gal.scanning ? tx("Buscando fotos y vídeos…", "Looking for photos and videos…")
                              : (gal.page === "photos" || gal.album ? gal.currentList.length + " " + tx("elementos", "items")
                              : (gal.albums.length - 1) + " " + tx("álbumes", "albums"))
                        font.family: gal.fontB; font.pixelSize: gal.px(12)
                        color: gal.cMuted
                        elide: Text.ElideRight
                    }
                }

                // filter (Photos only)
                Rectangle {
                    id: filterBtn
                    visible: gal.page === "photos" && !gal.selecting
                    Layout.preferredHeight: gal.px(36)
                    Layout.preferredWidth: fbRow.width + gal.px(26)
                    radius: height / 2
                    color: fbHov.hovered || gal.filterMenu ? Qt.lighter(gal.trackCol, 1.6) : gal.trackCol
                    Row {
                        id: fbRow
                        anchors.centerIn: parent
                        spacing: 6
                        Glyph { anchors.verticalCenter: parent.verticalCenter; size: gal.px(18); color: gal.cPrimary
                                text: gal.filter === "image" ? "image" : (gal.filter === "video" ? "movie" : "photo_library") }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: gal.filter === "image" ? tx("Imágenes", "Images") : (gal.filter === "video" ? tx("Vídeos", "Videos") : tx("Todo", "All"))
                            font.family: gal.fontB; font.pixelSize: gal.px(13); font.weight: Font.Medium
                            color: gal.cOnSurface
                        }
                        Glyph { anchors.verticalCenter: parent.verticalCenter; size: gal.px(18); text: "expand_more" }
                    }
                    HoverHandler { id: fbHov; cursorShape: Qt.PointingHandCursor }
                    MouseArea { anchors.fill: parent; onClicked: gal.filterMenu = !gal.filterMenu }
                }

                // selection actions
                Row {
                    visible: gal.selecting
                    spacing: 2
                    IconBtn { glyph: "select_all"; onClicked: gal.selectAll() }
                    IconBtn { visible: gal.inTrash; glyph: "restore_from_trash"; onClicked: gal.restoreAct(gal.selItems()) }
                    IconBtn { visible: gal.inTrash; glyph: "delete_forever"; danger: true; onClicked: gal.purgeAct(gal.selItems()) }
                    IconBtn { visible: !gal.inTrash && gal.selCount === 1; glyph: "content_copy"; onClicked: { var s = gal.selItems(); if (s.length) gal.copyImage(s[0]); } }
                    IconBtn { visible: !gal.inTrash; glyph: "delete"; danger: true; onClicked: gal.trashItemsAct(gal.selItems()) }
                    IconBtn { glyph: "close"; onClicked: gal.clearSel() }
                }

                IconBtn {
                    visible: gal.inTrash && !gal.selecting && gal.trashItems.length > 0
                    glyph: "delete_sweep"; danger: true
                    onClicked: gal.purgeAct(null)
                }
                IconBtn { visible: !gal.selecting; glyph: "zoom_out"; enabled: gal.zoom > 0; onClicked: gal.zoom = gal.zoom - 1 }
                IconBtn { visible: !gal.selecting; glyph: "zoom_in"; enabled: gal.zoom < 3; onClicked: gal.zoom = gal.zoom + 1 }
                IconBtn { visible: !gal.selecting; glyph: "refresh"; onClicked: gal.rescan()
                          RotationAnimation on rotation { running: gal.scanning; from: 0; to: 360; duration: 900; loops: Animation.Infinite } }
                IconBtn { visible: !gal.selecting; glyph: "create_new_folder"; onClicked: gal.foldersOpen = true }
            }
        }

        // ───────────── content ─────────────
        Item {
            id: content
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: navBar.top

            // Grid grouped by day (Photos and the open album)
            ListView {
                id: gridView
                anchors.fill: parent
                visible: gal.page === "photos" || gal.album !== null
                clip: true
                model: gal.rows
                boundsBehavior: Flickable.StopAtBounds
                reuseItems: true
                cacheBuffer: gal.px(800)
                bottomMargin: gal.px(16)
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                delegate: Item {
                    id: rowDel
                    required property var modelData
                    required property int index
                    width: gridView.width
                    height: modelData.h ? gal.px(modelData.first ? 40 : 52) : gal.cell + gal.px(3)
                    Text {
                        visible: rowDel.modelData.h
                        x: gal.px(18)
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: gal.px(10)
                        text: rowDel.modelData.h ? rowDel.modelData.label : ""
                        font.family: gal.fontA; font.pixelSize: gal.px(15); font.weight: Font.DemiBold
                        color: gal.cOnSurface
                    }
                    Row {
                        visible: !rowDel.modelData.h
                        x: gal.px(16)
                        spacing: gal.px(3)
                        Repeater {
                            model: rowDel.modelData.h ? [] : rowDel.modelData.items
                            delegate: Item {
                                id: tile
                                required property var modelData
                                readonly property var it: modelData.it
                                readonly property bool isVid: it.k === "video"
                                readonly property var vt: isVid ? gal.videoThumb(it) : null
                                readonly property bool sel: gal.isSel(it.p)
                                width: gal.cell
                                height: gal.cell
                                Rectangle { anchors.fill: parent; color: gal.ga(gal.cOnSurfVar, 0.08) }
                                Image {
                                    id: tileImg
                                    anchors.fill: parent
                                    anchors.margins: tile.sel ? gal.px(10) : 0
                                    Behavior on anchors.margins { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                                    source: tile.isVid ? (tile.vt && tile.vt.path ? gal.fileUrl(tile.vt.path) : "") : gal.fileUrl(tile.it.p)
                                    sourceSize: Qt.size(Math.round(gal.cell * 1.25), Math.round(gal.cell * 1.25))
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    autoTransform: true
                                    smooth: true
                                    opacity: status === Image.Ready ? 1 : 0
                                    Behavior on opacity { NumberAnimation { duration: 180 } }
                                }
                                Glyph {
                                    anchors.centerIn: parent
                                    visible: tileImg.status !== Image.Ready
                                    text: tile.isVid ? "movie" : "image"
                                    size: gal.px(26)
                                    color: gal.ga(gal.cOnSurfVar, 0.4)
                                }
                                // video duration
                                Rectangle {
                                    visible: tile.isVid
                                    anchors.right: parent.right; anchors.top: parent.top
                                    anchors.margins: gal.px(6)
                                    height: gal.px(22); width: vdRow.width + gal.px(12); radius: height / 2
                                    color: Qt.rgba(0, 0, 0, 0.55)
                                    Row {
                                        id: vdRow
                                        anchors.centerIn: parent
                                        spacing: 2
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: tile.vt && tile.vt.dur ? gal.fmtDur(tile.vt.dur) : ""
                                            visible: text !== ""
                                            font.family: gal.fontB; font.pixelSize: gal.px(11); font.weight: Font.DemiBold
                                            color: "white"
                                        }
                                        Glyph { anchors.verticalCenter: parent.verticalCenter; text: "play_arrow"; size: gal.px(15); color: "white" }
                                    }
                                }
                                // selection
                                Rectangle {
                                    visible: gal.selecting
                                    x: gal.px(6); y: gal.px(6)
                                    width: gal.px(22); height: width; radius: width / 2
                                    color: tile.sel ? gal.cPrimary : Qt.rgba(0, 0, 0, 0.3)
                                    border.width: tile.sel ? 0 : 2
                                    border.color: "white"
                                    Glyph { anchors.centerIn: parent; visible: tile.sel; text: "check"; size: gal.px(16); color: gal.cOnPrimary }
                                }
                                Rectangle { anchors.fill: parent; color: "white"; opacity: tileHov.hovered && !gal.selecting ? 0.07 : 0 }
                                HoverHandler { id: tileHov; cursorShape: Qt.PointingHandCursor }
                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    pressAndHoldInterval: 450
                                    onPressAndHold: gal.toggleSel(tile.it.p)
                                    onClicked: (m) => {
                                        if (m.button === Qt.RightButton || (m.modifiers & Qt.ControlModifier) || gal.selecting) { gal.toggleSel(tile.it.p); return; }
                                        gal.openViewer(gal.currentList, tile.modelData.i);
                                    }
                                }
                            }
                        }
                    }
                }
                // Ctrl + wheel: thumbnail size
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    onWheel: (w) => {
                        if (w.modifiers & Qt.ControlModifier) {
                            if (w.angleDelta.y > 0) gal.zoom = Math.min(3, gal.zoom + 1); else if (w.angleDelta.y < 0) gal.zoom = Math.max(0, gal.zoom - 1);
                            w.accepted = true;
                        } else w.accepted = false;
                    }
                }
            }

            // Empty
            Column {
                anchors.centerIn: parent
                visible: gridView.visible && gal.currentList.length === 0 && !gal.scanning
                spacing: gal.px(10)
                Glyph { anchors.horizontalCenter: parent.horizontalCenter; text: gal.inTrash ? "delete" : "photo_library"; size: gal.px(56); color: gal.ga(gal.cOnSurfVar, 0.45) }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: gal.inTrash ? tx("La papelera está vacía", "The trash is empty") : tx("No hay fotos ni vídeos aquí", "No photos or videos here")
                    font.family: gal.fontB; font.pixelSize: gal.px(14)
                    color: gal.cMuted
                }
            }

            // Albums
            GridView {
                id: albumGrid
                anchors.fill: parent
                anchors.leftMargin: gal.px(12)
                anchors.rightMargin: gal.px(12)
                visible: gal.page === "albums" && gal.album === null
                clip: true
                model: gal.albums
                boundsBehavior: Flickable.StopAtBounds
                readonly property int acols: Math.max(2, Math.floor(width / gal.px(190)))
                cellWidth: width / acols
                cellHeight: cellWidth + gal.px(52)
                topMargin: gal.px(6)
                bottomMargin: gal.px(16)
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                delegate: Item {
                    id: alDel
                    required property var modelData
                    width: albumGrid.cellWidth
                    height: albumGrid.cellHeight
                    readonly property var cov: modelData.cover
                    readonly property var cvt: cov && cov.k === "video" ? gal.videoThumb(cov) : null
                    Item {
                        id: alCover
                        x: gal.px(6); y: gal.px(6)
                        width: parent.width - gal.px(12)
                        height: width
                        Rectangle { anchors.fill: parent; radius: gal.px(18); color: gal.ga(gal.cOnSurfVar, 0.08) }
                        RoundImg {
                            anchors.fill: parent
                            radius: gal.px(18)
                            visible: !!alDel.cov
                            sourceSize: Qt.size(Math.round(width * 1.2), Math.round(height * 1.2))
                            source: !alDel.cov ? "" : (alDel.cov.k === "video" ? (alDel.cvt && alDel.cvt.path ? gal.fileUrl(alDel.cvt.path) : "") : gal.fileUrl(alDel.cov.p))
                        }
                        Glyph {
                            anchors.centerIn: parent
                            visible: !alDel.cov
                            text: alDel.modelData.icon || "folder"
                            size: gal.px(44)
                            color: gal.ga(gal.cOnSurfVar, 0.45)
                        }
                        // album type badge
                        Rectangle {
                            visible: !!alDel.modelData.icon && !!alDel.cov
                            anchors.left: parent.left; anchors.bottom: parent.bottom
                            anchors.margins: gal.px(8)
                            width: gal.px(32); height: width; radius: width / 2
                            color: Qt.rgba(0, 0, 0, 0.5)
                            Glyph { anchors.centerIn: parent; text: alDel.modelData.icon || ""; size: gal.px(18); color: "white" }
                        }
                        Rectangle { anchors.fill: parent; radius: gal.px(18); color: "white"; opacity: alHov.hovered ? 0.07 : 0 }
                        HoverHandler { id: alHov; cursorShape: Qt.PointingHandCursor }
                        MouseArea { anchors.fill: parent; onClicked: gal.openAlbum(alDel.modelData) }
                    }
                    Text {
                        anchors.top: alCover.bottom; anchors.topMargin: gal.px(8)
                        x: gal.px(8); width: parent.width - gal.px(16)
                        text: alDel.modelData.title
                        font.family: gal.fontB; font.pixelSize: gal.px(14); font.weight: Font.DemiBold
                        color: gal.cOnSurface
                        elide: Text.ElideRight
                    }
                    Text {
                        anchors.top: alCover.bottom; anchors.topMargin: gal.px(28)
                        x: gal.px(8)
                        text: alDel.modelData.count + " " + (alDel.modelData.count === 1 ? tx("elemento", "item") : tx("elementos", "items"))
                        font.family: gal.fontB; font.pixelSize: gal.px(12)
                        color: gal.cMuted
                    }
                }
            }
        }

        // ───────────── bottom navigation bar (Android style) ─────────────
        Item {
            id: navBar
            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
            height: gal.px(72)
            Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: gal.lineCol }
            Row {
                anchors.centerIn: parent
                spacing: gal.px(40)
                Repeater {
                    model: [
                        { v: "photos", icon: "photo_library", label: tx("Fotos", "Photos") },
                        { v: "albums", icon: "photo_album", label: tx("Álbumes", "Albums") }
                    ]
                    delegate: Item {
                        id: nb
                        required property var modelData
                        readonly property bool sel: gal.page === modelData.v
                        width: gal.px(96); height: gal.px(56)
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: gal.px(4)
                            width: nb.sel ? gal.px(64) : gal.px(36); height: gal.px(32); radius: height / 2
                            Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
                            color: nb.sel ? gal.ga(gal.cPrimary, 0.24) : (nbHov.hovered ? gal.hovCol : "transparent")
                            Glyph { anchors.centerIn: parent; text: nb.modelData.icon; size: gal.px(22); color: nb.sel ? gal.cPrimary : gal.cOnSurfVar }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            text: nb.modelData.label
                            font.family: gal.fontB; font.pixelSize: gal.px(12); font.weight: nb.sel ? Font.DemiBold : Font.Medium
                            color: nb.sel ? gal.cOnSurface : gal.cOnSurfVar
                        }
                        HoverHandler { id: nbHov; cursorShape: Qt.PointingHandCursor }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                gal.clearSel();
                                if (gal.page === nb.modelData.v) { if (nb.modelData.v === "albums") gal.album = null; gridView.positionViewAtBeginning(); return; }
                                gal.page = nb.modelData.v;
                                if (nb.modelData.v === "albums") gal.album = null;
                            }
                        }
                    }
                }
            }
        }

        // ───────────── filter menu ─────────────
        MouseArea { anchors.fill: parent; visible: gal.filterMenu; z: 40; onClicked: gal.filterMenu = false }
        Rectangle {
            visible: gal.filterMenu
            z: 41
            readonly property point anchorPt: filterBtn.mapToItem(rootBg, 0, filterBtn.height + gal.px(6))
            x: Math.min(rootBg.width - width - gal.px(8), anchorPt.x)
            y: anchorPt.y
            width: gal.px(210)
            height: fmCol.height + gal.px(12)
            radius: gal.px(16)
            color: gal.bgPop
            border.width: 1; border.color: gal.lineCol
            Column {
                id: fmCol
                x: gal.px(6); y: gal.px(6)
                width: parent.width - gal.px(12)
                Repeater {
                    model: [
                        { v: "all", icon: "photo_library", label: tx("Imágenes y vídeos", "Photos and videos") },
                        { v: "image", icon: "image", label: tx("Solo imágenes", "Images only") },
                        { v: "video", icon: "movie", label: tx("Solo vídeos", "Videos only") }
                    ]
                    delegate: Rectangle {
                        id: fmi
                        required property var modelData
                        width: fmCol.width; height: gal.px(40); radius: gal.px(10)
                        color: fmiHov.hovered ? gal.hovCol : "transparent"
                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            x: gal.px(10); spacing: gal.px(12)
                            Glyph { anchors.verticalCenter: parent.verticalCenter; text: fmi.modelData.icon; size: gal.px(19); color: gal.filter === fmi.modelData.v ? gal.cPrimary : gal.cOnSurfVar }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: fmi.modelData.label
                                font.family: gal.fontB; font.pixelSize: gal.px(13)
                                font.weight: gal.filter === fmi.modelData.v ? Font.DemiBold : Font.Normal
                                color: gal.filter === fmi.modelData.v ? gal.cPrimary : gal.cOnSurface
                            }
                        }
                        Glyph { anchors.right: parent.right; anchors.rightMargin: gal.px(10); anchors.verticalCenter: parent.verticalCenter
                                visible: gal.filter === fmi.modelData.v; text: "check"; size: gal.px(18); color: gal.cPrimary }
                        HoverHandler { id: fmiHov; cursorShape: Qt.PointingHandCursor }
                        MouseArea { anchors.fill: parent; onClicked: { gal.filter = fmi.modelData.v; gal.filterMenu = false; gridView.positionViewAtBeginning(); } }
                    }
                }
            }
        }

        // ═════════════ viewer ═════════════
        Rectangle {
            id: viewer
            anchors.fill: parent
            visible: gal.viewing
            z: 60
            color: "black"
            focus: false

            readonly property bool isVid: gal.viewItem !== null && gal.viewItem.k === "video"

            // image
            Item {
                id: viewImgBox
                anchors.fill: parent
                visible: !viewer.isVid
                clip: true
                Image {
                    id: viewImg
                    width: parent.width; height: parent.height
                    source: gal.viewItem && !viewer.isVid ? gal.fileUrl(gal.viewItem.p) : ""
                    sourceSize: Qt.size(Math.round(viewImgBox.width * 2), Math.round(viewImgBox.height * 2))
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    autoTransform: true
                    smooth: true
                    mipmap: true
                    transform: [
                        Scale { origin.x: viewImg.width / 2; origin.y: viewImg.height / 2; xScale: gal.vZoom; yScale: gal.vZoom },
                        Translate { x: gal.vPanX; y: gal.vPanY }
                    ]
                }
                Glyph { anchors.centerIn: parent; visible: viewImg.status === Image.Loading; text: "hourglass_empty"; size: 40; color: Qt.rgba(1, 1, 1, 0.5) }
                MouseArea {
                    anchors.fill: parent
                    property real lx: 0
                    property real ly: 0
                    property bool moved: false
                    cursorShape: gal.vZoom > 1 ? (pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor) : Qt.ArrowCursor
                    onPressed: (m) => { lx = m.x; ly = m.y; moved = false; }
                    onPositionChanged: (m) => {
                        if (!pressed || gal.vZoom <= 1) return;
                        gal.vPanX += m.x - lx; gal.vPanY += m.y - ly;
                        lx = m.x; ly = m.y; moved = true;
                    }
                    onClicked: if (!moved) gal.viewChrome = !gal.viewChrome
                    onDoubleClicked: (m) => {
                        if (gal.vZoom > 1) { gal.resetZoom(); return; }
                        gal.vZoom = 2.5;
                        gal.vPanX = (width / 2 - m.x) * 1.5;
                        gal.vPanY = (height / 2 - m.y) * 1.5;
                    }
                    onWheel: (w) => {
                        var f = w.angleDelta.y > 0 ? 1.15 : (w.angleDelta.y < 0 ? 1 / 1.15 : 1);
                        var nz = Math.max(1, Math.min(8, gal.vZoom * f));
                        // zoom toward the cursor
                        var cx = w.x - width / 2 - gal.vPanX, cy = w.y - height / 2 - gal.vPanY;
                        gal.vPanX -= cx * (nz / gal.vZoom - 1);
                        gal.vPanY -= cy * (nz / gal.vZoom - 1);
                        gal.vZoom = nz;
                        if (nz <= 1.001) { gal.vPanX = 0; gal.vPanY = 0; }
                    }
                }
            }

            // video
            VideoOutput {
                id: viewVideo
                anchors.fill: parent
                anchors.bottomMargin: gal.viewChrome ? gal.px(84) : 0
                visible: viewer.isVid
                fillMode: VideoOutput.PreserveAspectFit
                MouseArea {
                    anchors.fill: parent
                    onClicked: { if (viewPlayer.playbackState === MediaPlayer.PlayingState) viewPlayer.pause(); else viewPlayer.play(); }
                    onDoubleClicked: gal.viewChrome = !gal.viewChrome
                }
            }
            Rectangle {
                visible: viewer.isVid && viewPlayer.playbackState !== MediaPlayer.PlayingState
                anchors.centerIn: viewVideo
                width: gal.px(72); height: width; radius: width / 2
                color: Qt.rgba(0, 0, 0, 0.5)
                Glyph { anchors.centerIn: parent; text: "play_arrow"; size: gal.px(44); color: "white" }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: viewPlayer.play() }
            }

            // arrows
            IconBtn {
                visible: gal.viewChrome && gal.viewIndex > 0
                anchors.left: parent.left; anchors.leftMargin: gal.px(14)
                anchors.verticalCenter: parent.verticalCenter
                onDark: true; glyph: "chevron_left"; gsize: 30
                width: gal.px(48); height: width
                color: Qt.rgba(0, 0, 0, 0.4)
                onClicked: gal.viewStep(-1)
            }
            IconBtn {
                visible: gal.viewChrome && gal.viewIndex < gal.viewList.length - 1
                anchors.right: parent.right; anchors.rightMargin: gal.px(14) + (gal.viewInfo ? infoPanel.width : 0)
                anchors.verticalCenter: parent.verticalCenter
                onDark: true; glyph: "chevron_right"; gsize: 30
                width: gal.px(48); height: width
                color: Qt.rgba(0, 0, 0, 0.4)
                onClicked: gal.viewStep(1)
            }

            // top bar
            Rectangle {
                id: viewTop
                visible: gal.viewChrome
                width: parent.width; height: gal.px(64)
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0.65) }
                    GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0) }
                }
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: gal.px(10); anchors.rightMargin: gal.px(10)
                    spacing: gal.px(4)
                    IconBtn { onDark: true; glyph: "arrow_back"; onClicked: gal.closeViewer() }
                    Column {
                        Layout.fillWidth: true
                        Layout.leftMargin: gal.px(6)
                        Text {
                            width: parent.width
                            text: gal.viewItem ? gal.viewItem.n : ""
                            font.family: gal.fontB; font.pixelSize: gal.px(14); font.weight: Font.DemiBold
                            color: "white"; elide: Text.ElideMiddle
                        }
                        Text {
                            width: parent.width
                            text: gal.viewItem ? gal.fullDate(gal.viewItem.tid ? gal.viewItem.del : gal.viewItem.m) + (gal.viewItem.tid ? "  ·  " + tx("en la papelera", "in trash") : "") : ""
                            font.family: gal.fontB; font.pixelSize: gal.px(12)
                            color: Qt.rgba(1, 1, 1, 0.7); elide: Text.ElideRight
                        }
                    }
                    IconBtn { visible: gal.viewItem && !gal.viewItem.tid; onDark: true; glyph: "edit"; onClicked: gal.editCurrent() }
                    IconBtn { visible: gal.viewItem && !gal.viewItem.tid && !viewer.isVid; onDark: true; glyph: "content_copy"; onClicked: gal.copyImage(gal.viewItem) }
                    IconBtn { visible: gal.viewItem && !gal.viewItem.tid; onDark: true; glyph: "open_in_new"; onClicked: gal.openExternal(gal.viewItem) }
                    IconBtn { visible: gal.viewItem && !gal.viewItem.tid; onDark: true; glyph: "folder_open"; onClicked: gal.showInFolder(gal.viewItem) }
                    IconBtn { visible: gal.viewItem && !!gal.viewItem.tid; onDark: true; glyph: "restore_from_trash"; onClicked: { gal.restoreAct([gal.viewItem]); gal.closeViewer(); } }
                    IconBtn { onDark: true; glyph: "info"; active: gal.viewInfo; onClicked: gal.viewInfo = !gal.viewInfo }
                    IconBtn { onDark: true; glyph: gal.viewItem && gal.viewItem.tid ? "delete_forever" : "delete"; onClicked: gal.viewTrashCurrent() }
                }
            }

            // video controls
            Rectangle {
                visible: viewer.isVid && gal.viewChrome
                anchors.bottom: parent.bottom
                width: parent.width; height: gal.px(84)
                color: Qt.rgba(0, 0, 0, 0.6)
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: gal.px(16); anchors.rightMargin: gal.px(16)
                    spacing: gal.px(12)
                    IconBtn {
                        onDark: true; gsize: 28
                        glyph: viewPlayer.playbackState === MediaPlayer.PlayingState ? "pause" : "play_arrow"
                        onClicked: { if (viewPlayer.playbackState === MediaPlayer.PlayingState) viewPlayer.pause(); else viewPlayer.play(); }
                    }
                    Text {
                        text: gal.fmtDur(viewPlayer.position / 1000)
                        font.family: gal.fontB; font.pixelSize: gal.px(12); color: "white"
                    }
                    Slider {
                        id: viewSeek
                        Layout.fillWidth: true
                        from: 0; to: Math.max(1, viewPlayer.duration)
                        value: pressed ? value : viewPlayer.position
                        onMoved: viewPlayer.setPosition(Math.round(value))
                        background: Rectangle {
                            x: viewSeek.leftPadding; y: viewSeek.topPadding + viewSeek.availableHeight / 2 - height / 2
                            width: viewSeek.availableWidth; height: gal.px(4); radius: 2
                            color: Qt.rgba(1, 1, 1, 0.25)
                            Rectangle { width: viewSeek.visualPosition * parent.width; height: parent.height; radius: 2; color: gal.cPrimary }
                        }
                        handle: Rectangle {
                            x: viewSeek.leftPadding + viewSeek.visualPosition * (viewSeek.availableWidth - width)
                            y: viewSeek.topPadding + viewSeek.availableHeight / 2 - height / 2
                            width: gal.px(14); height: width; radius: width / 2
                            color: gal.cPrimary
                        }
                    }
                    Text {
                        text: gal.fmtDur(viewPlayer.duration / 1000)
                        font.family: gal.fontB; font.pixelSize: gal.px(12); color: "white"
                    }
                    IconBtn {
                        onDark: true
                        glyph: viewAudio.muted ? "volume_off" : "volume_up"
                        onClicked: viewAudio.muted = !viewAudio.muted
                    }
                }
            }

            // info panel
            Rectangle {
                id: infoPanel
                visible: gal.viewInfo
                anchors.right: parent.right
                anchors.top: viewTop.bottom
                anchors.bottom: parent.bottom
                anchors.bottomMargin: viewer.isVid && gal.viewChrome ? gal.px(84) : 0
                width: gal.px(300)
                color: gal.bgPop
                property var props: null
                property string forPath: ""
                function load() {
                    if (!gal.viewItem || forPath === gal.viewItem.p) return;
                    forPath = gal.viewItem.p;
                    props = null;
                    var p = forPath;
                    gal.call("props", { path: p }, function (ok, d) { if (ok && infoPanel.forPath === p) infoPanel.props = d; });
                }
                onVisibleChanged: if (visible) load()
                Connections { target: gal; function onViewItemChanged() { if (infoPanel.visible) infoPanel.load(); } }
                Column {
                    x: gal.px(18); y: gal.px(16)
                    width: parent.width - gal.px(36)
                    spacing: gal.px(14)
                    Text { text: tx("Información", "Details"); font.family: gal.fontA; font.pixelSize: gal.px(17); font.weight: Font.Bold; color: gal.cOnSurface }
                    Repeater {
                        model: {
                            var it = gal.viewItem, p = infoPanel.props;
                            if (!it) return [];
                            var rows = [
                                { i: "description", k: tx("Nombre", "Name"), v: it.n },
                                { i: "calendar_today", k: tx("Fecha", "Date"), v: gal.fullDate(it.m) },
                                { i: "folder", k: tx("Carpeta", "Folder"), v: it.tid ? (it.orig || "") : it.d },
                                { i: "save", k: tx("Tamaño", "Size"), v: gal.fmtSize(it.s) }
                            ];
                            if (!viewer.isVid && viewImg.status === Image.Ready)
                                rows.push({ i: "aspect_ratio", k: tx("Dimensiones", "Dimensions"), v: viewImg.implicitWidth + " × " + viewImg.implicitHeight });
                            if (viewer.isVid && p && p.w) rows.push({ i: "aspect_ratio", k: tx("Resolución", "Resolution"), v: p.w + " × " + p.h });
                            if (viewer.isVid && p && p.dur) rows.push({ i: "schedule", k: tx("Duración", "Duration"), v: gal.fmtDur(p.dur) });
                            return rows;
                        }
                        delegate: Row {
                            id: ir
                            required property var modelData
                            spacing: gal.px(12)
                            width: parent.width
                            Glyph { text: ir.modelData.i; size: gal.px(20); color: gal.cPrimary }
                            Column {
                                width: parent.width - gal.px(32)
                                Text { text: ir.modelData.k; font.family: gal.fontB; font.pixelSize: gal.px(11); color: gal.cMuted }
                                Text { width: parent.width; text: ir.modelData.v; wrapMode: Text.WrapAnywhere; font.family: gal.fontB; font.pixelSize: gal.px(13); color: gal.cOnSurface }
                            }
                        }
                    }
                }
            }
        }

        // ═════════════ image editor ═════════════
        Rectangle {
            id: imgEditor
            anchors.fill: parent
            visible: gal.imgEdit !== null
            z: 70
            color: gal.light ? "#202020" : "#0c0c0c"

            // top bar
            RowLayout {
                id: ieTop
                x: gal.px(12); width: parent.width - gal.px(24)
                height: gal.px(64)
                spacing: gal.px(8)
                IconBtn { onDark: true; glyph: "close"; onClicked: gal.closeImageEditor() }
                Text {
                    Layout.fillWidth: true
                    text: tx("Editar imagen", "Edit image")
                    font.family: gal.fontA; font.pixelSize: gal.px(17); font.weight: Font.Bold
                    color: "white"
                }
                IconBtn { onDark: true; glyph: "undo"; enabled: gal.ieHistory.length > 0 || gal.ieEditingText; onClicked: gal.ieUndo() }
                PillBtn {
                    glyph: "save"; label: tx("Guardar", "Save"); primary: true
                    enabled: !gal.ieBusy
                    onClicked: gal.saveMenu = !gal.saveMenu
                }
            }

            // canvas
            Item {
                id: ieArea
                anchors.top: ieTop.bottom
                anchors.bottom: ieTools.top
                anchors.left: parent.left; anchors.right: parent.right
                anchors.margins: gal.px(20)

                Image {
                    id: ieProbe     // only to know the real size (with EXIF orientation applied)
                    visible: false
                    source: gal.imgEdit ? gal.fileUrl(gal.imgEdit.p) : ""
                    autoTransform: true
                    asynchronous: true
                    onStatusChanged: if (status === Image.Ready && gal.imgEdit) gal.ieCrop = ({ x: 0, y: 0, w: implicitWidth, h: implicitHeight })
                }

                // what gets exported (grabToImage at full size)
                Item {
                    id: iePage
                    readonly property real srcW: Math.max(1, ieProbe.implicitWidth)
                    readonly property real srcH: Math.max(1, ieProbe.implicitHeight)
                    readonly property real k: Math.min(ieArea.width / srcW, ieArea.height / srcH)
                    width: srcW * k; height: srcH * k
                    x: (ieArea.width - width) / 2
                    y: (ieArea.height - height) / 2
                    visible: ieProbe.status === Image.Ready
                    clip: true
                    Image {
                        anchors.fill: parent
                        source: ieProbe.source
                        autoTransform: true
                        asynchronous: true
                        smooth: true
                        mipmap: true
                        fillMode: Image.Stretch
                    }
                    Repeater {
                        model: gal.ieStrokes.length
                        delegate: Shape {
                            id: ieSt
                            required property int index
                            readonly property var st: gal.ieStrokes[index]
                            readonly property var spts: st ? st.pts.map(function (p) { return Qt.point(p.x * iePage.k, p.y * iePage.k); }) : []
                            anchors.fill: parent
                            preferredRendererType: Shape.CurveRenderer
                            ShapePath {
                                strokeColor: ieSt.st ? ieSt.st.c : "transparent"
                                strokeWidth: ieSt.st ? ieSt.st.w * iePage.k : 1
                                fillColor: "transparent"
                                capStyle: ShapePath.RoundCap
                                joinStyle: ShapePath.RoundJoin
                                PathPolyline { path: ieSt.spts }
                            }
                        }
                    }
                    Shape {
                        anchors.fill: parent
                        visible: gal.ieDrawing
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            strokeColor: gal.inkColors[gal.ieColor]
                            strokeWidth: gal.penSizes[gal.ieSize]
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap
                            joinStyle: ShapePath.RoundJoin
                            PathPolyline { path: gal.ieCur.map(function (p) { return Qt.point(p.x * iePage.k, p.y * iePage.k); }) }
                        }
                    }
                    Repeater {
                        model: gal.ieTexts.length
                        delegate: Text {
                            required property int index
                            readonly property var tt: gal.ieTexts[index]
                            x: tt ? tt.x * iePage.k : 0
                            y: tt ? tt.y * iePage.k : 0
                            text: tt ? tt.t : ""
                            color: tt ? tt.c : "white"
                            font.family: gal.fontA
                            font.pixelSize: Math.max(4, Math.round((tt ? tt.s : 20) * iePage.k))
                            font.weight: Font.Bold
                            style: Text.Outline
                            styleColor: (tt && tt.c === "#000000") ? Qt.rgba(1, 1, 1, 0.6) : Qt.rgba(0, 0, 0, 0.55)
                        }
                    }
                    TextInput {
                        id: ieTextInput
                        visible: gal.ieEditingText
                        x: gal.ieTextX * iePage.k
                        y: gal.ieTextY * iePage.k
                        width: Math.max(gal.px(60), contentWidth + 4)
                        color: gal.inkColors[gal.ieColor]
                        font.family: gal.fontA
                        font.pixelSize: gal.textSizes[gal.ieSize]
                        font.weight: Font.Bold
                        selectByMouse: true
                        Keys.onReturnPressed: gal.ieCommitText()
                        Keys.onEnterPressed: gal.ieCommitText()
                        Text {
                            visible: ieTextInput.text === ""
                            text: tx("Escribe…", "Type…")
                            color: ieTextInput.color
                            opacity: 0.55
                            font: ieTextInput.font
                        }
                    }
                }

                // draw / place text
                MouseArea {
                    x: iePage.x; y: iePage.y; width: iePage.width; height: iePage.height
                    enabled: gal.ieTool !== "crop"
                    cursorShape: gal.ieTool === "text" ? Qt.IBeamCursor : Qt.CrossCursor
                    onPressed: (m) => {
                        var sx = m.x / iePage.k, sy = m.y / iePage.k;
                        if (gal.ieTool === "text") {
                            gal.ieCommitText();
                            gal.ieTextX = sx; gal.ieTextY = sy - gal.textSizes[gal.ieSize] * 0.6 / iePage.k;
                            ieTextInput.text = "";
                            gal.ieEditingText = true;
                            ieTextInput.forceActiveFocus();
                            return;
                        }
                        gal.ieCommitText();
                        gal.ieCur = [Qt.point(sx, sy), Qt.point(sx + 0.01, sy + 0.01)];
                        gal.ieDrawing = true;
                    }
                    onPositionChanged: (m) => {
                        if (!gal.ieDrawing) return;
                        var sx = m.x / iePage.k, sy = m.y / iePage.k;
                        var p = gal.ieCur, last = p[p.length - 1];
                        if (Math.abs(last.x - sx) + Math.abs(last.y - sy) < 1.5 / iePage.k) return;
                        gal.ieCur = p.concat([Qt.point(sx, sy)]);
                    }
                    onReleased: {
                        if (!gal.ieDrawing) return;
                        gal.ieDrawing = false;
                        gal.ieStrokes = gal.ieStrokes.concat([{ c: gal.inkColors[gal.ieColor], w: gal.penSizes[gal.ieSize] / iePage.k, pts: gal.ieCur }]);
                        gal.ieHistory = gal.ieHistory.concat(["s"]);
                        gal.ieCur = [];
                    }
                }

                // crop (on top of the canvas, not exported)
                CropBox {
                    anchors.fill: parent
                    visible: iePage.visible
                    active: gal.ieTool === "crop"
                    vx: iePage.x; vy: iePage.y; vw: iePage.width; vh: iePage.height
                    srcW: iePage.srcW; srcH: iePage.srcH
                    rect: gal.ieCrop
                    ratio: gal.ieRatio
                    onBegin: gal.ieHistory = gal.ieHistory.concat([{ crop: gal.ieCrop }])
                    onEdited: (r) => gal.ieCrop = r
                }
            }

            // tools
            Column {
                id: ieTools
                anchors.bottom: parent.bottom
                anchors.bottomMargin: gal.px(14)
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: gal.px(10)

                // options for the current tool
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: gal.px(48)
                    width: ieOpts.width + gal.px(16)
                    radius: height / 2
                    color: Qt.rgba(1, 1, 1, 0.08)
                    Row {
                        id: ieOpts
                        anchors.centerIn: parent
                        spacing: gal.px(4)
                        // aspect ratios (crop)
                        Repeater {
                            model: gal.ieTool === "crop" ? gal.ratios : []
                            delegate: Rectangle {
                                id: rb
                                required property var modelData
                                readonly property bool sel: Math.abs(gal.ieRatio - modelData.v) < 0.001
                                height: gal.px(34); width: rbT.implicitWidth + gal.px(24); radius: height / 2
                                color: sel ? gal.cPrimary : (rbHov.hovered ? Qt.rgba(1, 1, 1, 0.12) : "transparent")
                                Text { id: rbT; anchors.centerIn: parent; text: rb.modelData.label; font.family: gal.fontB; font.pixelSize: gal.px(13); font.weight: Font.DemiBold; color: rb.sel ? gal.cOnPrimary : "white" }
                                HoverHandler { id: rbHov; cursorShape: Qt.PointingHandCursor }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        gal.ieHistory = gal.ieHistory.concat([{ crop: gal.ieCrop }]);
                                        gal.ieRatio = rb.modelData.v;
                                        gal.ieCrop = gal.ratioRect(iePage.srcW, iePage.srcH, rb.modelData.v);
                                    }
                                }
                            }
                        }
                        IconBtn {
                            visible: gal.ieTool === "crop"; onDark: true; glyph: "restart_alt"
                            onClicked: { gal.ieHistory = gal.ieHistory.concat([{ crop: gal.ieCrop }]); gal.ieRatio = 0; gal.ieCrop = ({ x: 0, y: 0, w: iePage.srcW, h: iePage.srcH }); }
                        }
                        // colors + sizes (pen / text)
                        Repeater {
                            model: gal.ieTool !== "crop" ? gal.inkColors : []
                            delegate: ColorDot {
                                required property var modelData
                                required property int index
                                dot: modelData
                                sel: gal.ieColor === index
                                onClicked: { gal.ieColor = index; if (gal.ieEditingText) ieTextInput.forceActiveFocus(); }
                            }
                        }
                        Rectangle { visible: gal.ieTool !== "crop"; width: 1; height: gal.px(24); anchors.verticalCenter: parent.verticalCenter; color: Qt.rgba(1, 1, 1, 0.2) }
                        Repeater {
                            model: gal.ieTool !== "crop" ? 3 : 0
                            delegate: Item {
                                required property int index
                                width: gal.px(32); height: gal.px(36)
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: gal.px(30); height: width; radius: width / 2
                                    color: gal.ieSize === index ? gal.ga(gal.cPrimary, 0.3) : "transparent"
                                    Rectangle { anchors.centerIn: parent; width: [6, 10, 15][index]; height: width; radius: width / 2; color: gal.inkColors[gal.ieColor] }
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { gal.ieSize = index; if (gal.ieEditingText) ieTextInput.forceActiveFocus(); } }
                            }
                        }
                    }
                }

                // tools
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: gal.px(8)
                    Repeater {
                        model: [
                            { v: "crop", icon: "crop", label: tx("Recortar", "Crop") },
                            { v: "pen", icon: "draw", label: tx("Lápiz", "Pen") },
                            { v: "text", icon: "title", label: tx("Texto", "Text") }
                        ]
                        delegate: Rectangle {
                            id: tb
                            required property var modelData
                            readonly property bool sel: gal.ieTool === modelData.v
                            height: gal.px(44); width: tbRow.width + gal.px(30); radius: height / 2
                            color: sel ? gal.cPrimary : (tbHov.hovered ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.08))
                            Behavior on color { ColorAnimation { duration: 160 } }
                            Row {
                                id: tbRow
                                anchors.centerIn: parent
                                spacing: gal.px(8)
                                Glyph { anchors.verticalCenter: parent.verticalCenter; text: tb.modelData.icon; size: gal.px(20); color: tb.sel ? gal.cOnPrimary : "white" }
                                Text { anchors.verticalCenter: parent.verticalCenter; text: tb.modelData.label; font.family: gal.fontB; font.pixelSize: gal.px(13); font.weight: Font.DemiBold; color: tb.sel ? gal.cOnPrimary : "white" }
                            }
                            HoverHandler { id: tbHov; cursorShape: Qt.PointingHandCursor }
                            MouseArea { anchors.fill: parent; onClicked: { gal.ieCommitText(); gal.ieTool = tb.modelData.v; } }
                        }
                    }
                }
            }

            // busy
            Rectangle {
                anchors.fill: parent
                visible: gal.ieBusy
                color: Qt.rgba(0, 0, 0, 0.5)
                MouseArea { anchors.fill: parent }
                BusyIndicator { anchors.centerIn: parent; running: gal.ieBusy }
            }
        }

        // ═════════════ video editor ═════════════
        Rectangle {
            id: vidEditor
            anchors.fill: parent
            visible: gal.vidEdit !== null
            z: 70
            color: gal.light ? "#202020" : "#0c0c0c"

            RowLayout {
                id: veTop
                x: gal.px(12); width: parent.width - gal.px(24)
                height: gal.px(64)
                spacing: gal.px(8)
                IconBtn { onDark: true; glyph: "close"; onClicked: gal.closeVideoEditor() }
                Text {
                    Layout.fillWidth: true
                    text: tx("Editar vídeo", "Edit video")
                    font.family: gal.fontA; font.pixelSize: gal.px(17); font.weight: Font.Bold
                    color: "white"
                }
                PillBtn {
                    glyph: "save"; label: tx("Guardar", "Save"); primary: true
                    enabled: !gal.veBusy && gal.veEnd > gal.veStart
                    onClicked: gal.saveMenu = !gal.saveMenu
                }
            }

            Item {
                id: veArea
                anchors.top: veTop.bottom
                anchors.bottom: veBottom.top
                anchors.left: parent.left; anchors.right: parent.right
                anchors.margins: gal.px(20)
                VideoOutput {
                    id: veVideo
                    anchors.fill: parent
                    fillMode: VideoOutput.PreserveAspectFit
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: !gal.veCropOn
                    onClicked: { if (vePlayer.playbackState === MediaPlayer.PlayingState) vePlayer.pause(); else { if (vePlayer.position / 1000 < gal.veStart || vePlayer.position / 1000 >= gal.veEnd - 0.05) vePlayer.setPosition(Math.round(gal.veStart * 1000)); vePlayer.play(); } }
                }
                CropBox {
                    anchors.fill: parent
                    visible: gal.veCropOn && gal.veW > 0 && veVideo.contentRect.width > 0
                    active: true
                    vx: veVideo.contentRect.x; vy: veVideo.contentRect.y
                    vw: veVideo.contentRect.width; vh: veVideo.contentRect.height
                    srcW: gal.veW; srcH: gal.veH
                    rect: gal.veCrop
                    ratio: gal.veRatio
                    onEdited: (r) => gal.veCrop = r
                }
            }

            Column {
                id: veBottom
                anchors.bottom: parent.bottom
                anchors.bottomMargin: gal.px(14)
                x: gal.px(24); width: parent.width - gal.px(48)
                spacing: gal.px(10)

                // timeline with start / end
                Item {
                    id: veTimeline
                    width: parent.width
                    height: gal.px(56)
                    readonly property real tw: width - gal.px(24)
                    function tToX(t) { return gal.px(12) + (gal.veDur > 0 ? t / gal.veDur : 0) * tw; }
                    function xToT(x) { return Math.max(0, Math.min(gal.veDur, (x - gal.px(12)) / tw * gal.veDur)); }
                    Rectangle {
                        x: gal.px(12); y: gal.px(18); width: veTimeline.tw; height: gal.px(20); radius: gal.px(6)
                        color: Qt.rgba(1, 1, 1, 0.12)
                    }
                    Rectangle {
                        x: veTimeline.tToX(gal.veStart); y: gal.px(18)
                        width: Math.max(2, veTimeline.tToX(gal.veEnd) - x); height: gal.px(20)
                        color: gal.ga(gal.cPrimary, 0.35)
                        border.width: 2; border.color: gal.cPrimary
                        radius: gal.px(6)
                    }
                    // playhead
                    Rectangle {
                        x: veTimeline.tToX(vePlayer.position / 1000) - 1; y: gal.px(12)
                        width: 2; height: gal.px(32); color: "white"
                    }
                    MouseArea {   // seek
                        x: gal.px(12); y: gal.px(14); width: veTimeline.tw; height: gal.px(28)
                        onPressed: (m) => vePlayer.setPosition(Math.round(veTimeline.xToT(m.x + gal.px(12)) * 1000))
                        onPositionChanged: (m) => { if (pressed) vePlayer.setPosition(Math.round(veTimeline.xToT(m.x + gal.px(12)) * 1000)); }
                    }
                    Repeater {
                        model: ["start", "end"]
                        delegate: Item {
                            id: vh
                            required property string modelData
                            readonly property bool isStart: modelData === "start"
                            width: gal.px(24); height: gal.px(48)
                            x: veTimeline.tToX(isStart ? gal.veStart : gal.veEnd) - width / 2
                            y: gal.px(4)
                            Rectangle {
                                anchors.centerIn: parent
                                width: gal.px(12); height: gal.px(36); radius: gal.px(6)
                                color: gal.cPrimary
                                Rectangle { anchors.centerIn: parent; width: 2; height: gal.px(14); radius: 1; color: gal.cOnPrimary }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.SizeHorCursor
                                onPositionChanged: (m) => {
                                    if (!pressed) return;
                                    var g = mapToItem(veTimeline, m.x, m.y);
                                    var t = veTimeline.xToT(g.x);
                                    if (vh.isStart) gal.veStart = Math.min(t, gal.veEnd - 0.2);
                                    else gal.veEnd = Math.max(t, gal.veStart + 0.2);
                                    vePlayer.setPosition(Math.round((vh.isStart ? gal.veStart : gal.veEnd) * 1000));
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    width: parent.width
                    spacing: gal.px(10)
                    IconBtn {
                        onDark: true; gsize: 26
                        glyph: vePlayer.playbackState === MediaPlayer.PlayingState ? "pause" : "play_arrow"
                        onClicked: {
                            if (vePlayer.playbackState === MediaPlayer.PlayingState) { vePlayer.pause(); return; }
                            if (vePlayer.position / 1000 < gal.veStart || vePlayer.position / 1000 >= gal.veEnd - 0.05) vePlayer.setPosition(Math.round(gal.veStart * 1000));
                            vePlayer.play();
                        }
                    }
                    Text {
                        text: gal.fmtDur(gal.veStart) + " – " + gal.fmtDur(gal.veEnd) + "   (" + gal.fmtDur(gal.veEnd - gal.veStart) + ")"
                        font.family: gal.fontB; font.pixelSize: gal.px(13); color: "white"
                    }
                    Item { Layout.fillWidth: true }
                    // crop size
                    Rectangle {
                        Layout.preferredHeight: gal.px(40)
                        Layout.preferredWidth: vcRow.width + gal.px(28)
                        radius: height / 2
                        color: gal.veCropOn ? gal.cPrimary : (vcHov.hovered ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.08))
                        Row {
                            id: vcRow
                            anchors.centerIn: parent
                            spacing: gal.px(8)
                            Glyph { anchors.verticalCenter: parent.verticalCenter; text: "crop"; size: gal.px(20); color: gal.veCropOn ? gal.cOnPrimary : "white" }
                            Text { anchors.verticalCenter: parent.verticalCenter; text: tx("Recortar tamaño", "Crop size"); font.family: gal.fontB; font.pixelSize: gal.px(13); font.weight: Font.DemiBold; color: gal.veCropOn ? gal.cOnPrimary : "white" }
                        }
                        HoverHandler { id: vcHov; cursorShape: Qt.PointingHandCursor }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                gal.veCropOn = !gal.veCropOn;
                                if (gal.veCropOn && gal.veW > 0 && gal.veCrop.w <= 1) gal.veCrop = ({ x: 0, y: 0, w: gal.veW, h: gal.veH });
                            }
                        }
                    }
                    Repeater {
                        model: gal.veCropOn ? gal.ratios : []
                        delegate: Rectangle {
                            id: vrb
                            required property var modelData
                            readonly property bool sel: Math.abs(gal.veRatio - modelData.v) < 0.001
                            Layout.preferredHeight: gal.px(34)
                            Layout.preferredWidth: vrbT.implicitWidth + gal.px(22)
                            radius: height / 2
                            color: sel ? gal.ga(gal.cPrimary, 0.35) : (vrbHov.hovered ? Qt.rgba(1, 1, 1, 0.12) : "transparent")
                            Text { id: vrbT; anchors.centerIn: parent; text: vrb.modelData.label; font.family: gal.fontB; font.pixelSize: gal.px(12); font.weight: Font.DemiBold; color: "white" }
                            HoverHandler { id: vrbHov; cursorShape: Qt.PointingHandCursor }
                            MouseArea { anchors.fill: parent; onClicked: { gal.veRatio = vrb.modelData.v; gal.veCrop = gal.ratioRect(gal.veW, gal.veH, vrb.modelData.v); } }
                        }
                    }
                }
            }

            // progress
            Rectangle {
                anchors.fill: parent
                visible: gal.veBusy
                color: Qt.rgba(0, 0, 0, 0.6)
                MouseArea { anchors.fill: parent }
                Column {
                    anchors.centerIn: parent
                    spacing: gal.px(14)
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: tx("Procesando vídeo…", "Processing video…") + "  " + Math.round(gal.veProgress * 100) + "%"; font.family: gal.fontB; font.pixelSize: gal.px(15); color: "white" }
                    Rectangle {
                        width: gal.px(320); height: gal.px(6); radius: 3
                        color: Qt.rgba(1, 1, 1, 0.2)
                        Rectangle { width: parent.width * gal.veProgress; height: parent.height; radius: 3; color: gal.cPrimary }
                    }
                    PillBtn { anchors.horizontalCenter: parent.horizontalCenter; label: tx("Cancelar", "Cancel"); onClicked: { if (gal.veJob) gal.call("cancel", { job: gal.veJob }); } }
                }
            }
        }

        // ───────────── Save menu (editors) ─────────────
        MouseArea { anchors.fill: parent; visible: gal.saveMenu; z: 80; onClicked: gal.saveMenu = false }
        Rectangle {
            visible: gal.saveMenu
            z: 81
            anchors.right: parent.right; anchors.rightMargin: gal.px(14)
            y: gal.px(58)
            width: gal.px(240)
            height: smCol.height + gal.px(12)
            radius: gal.px(16)
            color: gal.bgPop
            border.width: 1; border.color: gal.lineCol
            Column {
                id: smCol
                x: gal.px(6); y: gal.px(6)
                width: parent.width - gal.px(12)
                Repeater {
                    model: [
                        { v: false, icon: "library_add", label: tx("Guardar como copia", "Save as copy") },
                        { v: true, icon: "save", label: tx("Reemplazar original", "Replace original") }
                    ]
                    delegate: Rectangle {
                        id: smi
                        required property var modelData
                        width: smCol.width; height: gal.px(42); radius: gal.px(10)
                        color: smiHov.hovered ? gal.hovCol : "transparent"
                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            x: gal.px(10); spacing: gal.px(12)
                            Glyph { anchors.verticalCenter: parent.verticalCenter; text: smi.modelData.icon; size: gal.px(19); color: gal.cPrimary }
                            Text { anchors.verticalCenter: parent.verticalCenter; text: smi.modelData.label; font.family: gal.fontB; font.pixelSize: gal.px(13); color: gal.cOnSurface }
                        }
                        HoverHandler { id: smiHov; cursorShape: Qt.PointingHandCursor }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                gal.saveMenu = false;
                                if (gal.imgEdit) gal.ieSave(smi.modelData.v);
                                else if (gal.vidEdit) gal.veSave(smi.modelData.v);
                            }
                        }
                    }
                }
            }
        }

        // ───────────── gallery folders ─────────────
        Rectangle {
            anchors.fill: parent
            visible: gal.foldersOpen
            z: 90
            color: Qt.rgba(0, 0, 0, 0.45)
            MouseArea { anchors.fill: parent; onClicked: gal.foldersOpen = false }
            Rectangle {
                anchors.centerIn: parent
                width: Math.min(parent.width - gal.px(40), gal.px(520))
                height: fdCol.height + gal.px(40)
                radius: gal.px(24)
                color: gal.bgPop
                MouseArea { anchors.fill: parent }
                Column {
                    id: fdCol
                    x: gal.px(20); y: gal.px(20)
                    width: parent.width - gal.px(40)
                    spacing: gal.px(12)
                    Text { text: tx("Carpetas de la galería", "Gallery folders"); font.family: gal.fontA; font.pixelSize: gal.px(18); font.weight: Font.Bold; color: gal.cOnSurface }
                    Text {
                        width: parent.width; wrapMode: Text.WordWrap
                        text: tx("Se buscan fotos y vídeos en Imágenes, Vídeos, Descargas, Escritorio y Documentos (con sus subcarpetas). Puedes añadir más:",
                                 "Photos and videos are searched in Pictures, Videos, Downloads, Desktop and Documents (with subfolders). You can add more:")
                        font.family: gal.fontB; font.pixelSize: gal.px(12.5); color: gal.cOnSurfVar
                    }
                    Repeater {
                        model: gal.extraRoots
                        delegate: Rectangle {
                            id: er
                            required property string modelData
                            required property int index
                            width: fdCol.width; height: gal.px(40); radius: gal.px(12)
                            color: gal.trackCol
                            Glyph { x: gal.px(10); anchors.verticalCenter: parent.verticalCenter; text: "folder"; size: gal.px(18); color: gal.cPrimary }
                            Text { x: gal.px(38); width: parent.width - gal.px(86); anchors.verticalCenter: parent.verticalCenter; text: er.modelData; elide: Text.ElideMiddle; font.family: gal.fontB; font.pixelSize: gal.px(13); color: gal.cOnSurface }
                            IconBtn {
                                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                glyph: "close"; danger: true; width: gal.px(32); height: width
                                onClicked: { var l = gal.extraRoots.slice(); l.splice(er.index, 1); gal.extraRoots = l; gal.savePrefs(); gal.rescan(); }
                            }
                        }
                    }
                    Rectangle {
                        width: parent.width; height: gal.px(42); radius: height / 2
                        color: gal.ga(gal.cOnSurfVar, 0.08)
                        border.width: fdInput.activeFocus ? 2 : 0; border.color: gal.cPrimary
                        TextInput {
                            id: fdInput
                            anchors.fill: parent
                            anchors.leftMargin: gal.px(16); anchors.rightMargin: gal.px(16)
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: gal.fontB; font.pixelSize: gal.px(13)
                            color: gal.cOnSurface
                            selectByMouse: true
                            clip: true
                            onAccepted: fdAdd.add()
                            Text { visible: fdInput.text === ""; anchors.verticalCenter: parent.verticalCenter; text: "~/Pictures/Camera"; font: fdInput.font; color: gal.cMuted }
                        }
                    }
                    Row {
                        anchors.right: parent.right
                        spacing: gal.px(8)
                        PillBtn { label: tx("Cerrar", "Close"); onClicked: gal.foldersOpen = false }
                        PillBtn {
                            id: fdAdd
                            glyph: "add"; label: tx("Añadir", "Add"); primary: true
                            enabled: fdInput.text.trim() !== ""
                            function add() {
                                var p = fdInput.text.trim();
                                if (!p) return;
                                if (gal.extraRoots.indexOf(p) < 0) gal.extraRoots = gal.extraRoots.concat([p]);
                                fdInput.text = "";
                                gal.savePrefs();
                                gal.rescan();
                            }
                            onClicked: add()
                        }
                    }
                }
            }
        }

        // ───────────── confirmation ─────────────
        Rectangle {
            anchors.fill: parent
            visible: gal.dlgOpen
            z: 95
            color: Qt.rgba(0, 0, 0, 0.45)
            MouseArea { anchors.fill: parent; onClicked: gal.dlgOpen = false }
            Rectangle {
                anchors.centerIn: parent
                width: Math.min(parent.width - gal.px(40), gal.px(400))
                height: dlgCol.height + gal.px(44)
                radius: gal.px(26)
                color: gal.bgPop
                MouseArea { anchors.fill: parent }
                Column {
                    id: dlgCol
                    x: gal.px(24); y: gal.px(22)
                    width: parent.width - gal.px(48)
                    spacing: gal.px(12)
                    Glyph { anchors.horizontalCenter: parent.horizontalCenter; text: "delete_forever"; size: gal.px(28); color: gal.cError }
                    Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap; text: gal.dlgTitle; font.family: gal.fontA; font.pixelSize: gal.px(18); font.weight: Font.Bold; color: gal.cOnSurface }
                    Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap; text: gal.dlgBody; font.family: gal.fontB; font.pixelSize: gal.px(13); color: gal.cOnSurfVar }
                    Item { width: 1; height: gal.px(4) }
                    Row {
                        anchors.right: parent.right
                        spacing: gal.px(8)
                        PillBtn { label: tx("Cancelar", "Cancel"); onClicked: gal.dlgOpen = false }
                        PillBtn { label: gal.dlgOk; primary: true; danger: true; onClicked: { gal.dlgOpen = false; if (gal.dlgFn) gal.dlgFn(); } }
                    }
                }
            }
        }

        // ───────────── notice ─────────────
        Rectangle {
            visible: gal.toastText !== ""
            z: 99
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: gal.px(92)
            height: gal.px(40)
            width: Math.min(parent.width - gal.px(40), toastT.implicitWidth + gal.px(36))
            radius: height / 2
            color: gal.toastErr ? gal.cError : gal.cOnSurface
            Text {
                id: toastT
                anchors.centerIn: parent
                width: parent.width - gal.px(28)
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: gal.toastText
                font.family: gal.fontB; font.pixelSize: gal.px(13); font.weight: Font.Medium
                color: gal.toastErr ? Qt.darker(gal.cError, 3.2) : gal.cSurface
            }
        }
    }
}
