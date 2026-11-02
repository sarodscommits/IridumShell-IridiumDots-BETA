import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"
import "../i18n"
import "../state"

// Shell root base: state, theme, i18n and shared helpers
ShellRoot {
    property alias gcTimer: gcTimer
    property alias globalState: globalState
    property alias i18n: i18n
    property alias m3: m3
    property alias m3shp: m3shp
    property alias pal: pal
    property alias presetRoles: presetRoles

    GlobalState { id: globalState }

    Timer {
        id: deferredStartTimer
        interval: 1200; running: true; repeat: false
        onTriggered: {
            globalState.deferredReady = true;
            usageLoadProcess.running = true;
            calEventsLoader.running = true;
            wallpaperDirWatchProcess.running = true;
            notificationSoundWatchProcess.running = true;
            fetchProcess.running = true;
            deferredLateTimer.start();
        }
    }

    Timer {
        id: settingsKeepAliveTimer
        interval: 10000
        running: globalState.settingsAlive && !globalState.settingsOpen
        onTriggered: globalState.settingsAlive = false
    }

    Timer {
        id: fileExplorerKeepAliveTimer
        interval: 30000
        running: globalState.fileExplorerAlive && !globalState.fileExplorerOpen
        onTriggered: globalState.fileExplorerAlive = false
    }

    Timer {
        id: textEditorKeepAliveTimer
        interval: 30000
        running: globalState.textEditorAlive && !globalState.textEditorOpen && !globalState.textEditorDirty
        onTriggered: globalState.textEditorAlive = false
    }

    Timer {
        id: galleryKeepAliveTimer
        interval: 30000
        running: globalState.galleryAlive && !globalState.galleryOpen
        onTriggered: globalState.galleryAlive = false
    }

    Timer {
        id: musicPlayerKeepAliveTimer
        interval: 30000
        running: globalState.musicPlayerAlive && !globalState.musicPlayerOpen && !globalState.musicPlaying
        onTriggered: globalState.musicPlayerAlive = false
    }

    Timer {
        id: windowSwitcherKeepAliveTimer
        interval: 500
        running: globalState.windowSwitcherAlive && !globalState.windowSwitcherOpen
        onTriggered: globalState.windowSwitcherAlive = false
    }

    Timer {
        id: wallpaperPickerKeepAliveTimer
        interval: 15000
        running: globalState.wallpaperPickerAlive && !globalState.wallpaperPickerOpen
        onTriggered: globalState.wallpaperPickerAlive = false
    }

    Timer {
        id: gcTimer
        interval: 1500; repeat: false
        onTriggered: gc()
    }

    Timer {
        id: islandControlKeepTimer
        interval: 15000; repeat: false
        onTriggered: { if (!globalState.islandControlOpen && typeof islandControlLoader !== "undefined") { islandControlLoader.keep = false; gcTimer.restart(); } }
    }

    Timer {
        id: notchControlKeepTimer
        interval: 15000; repeat: false
        onTriggered: { if (!globalState.notchControlOpen && typeof notchControlLoader !== "undefined") { notchControlLoader.keep = false; gcTimer.restart(); } }
    }

    Connections {
        target: globalState
        function onIslandControlOpenChanged() {
            if (globalState.islandControlOpen) { islandControlKeepTimer.stop(); if (typeof islandControlLoader !== "undefined") islandControlLoader.keep = true; }
            else { islandControlKeepTimer.restart(); globalState.ncEditMode = false; globalState.ncCcSelected = ""; }
        }
        function onNotchControlOpenChanged() {
            if (globalState.notchControlOpen) { notchControlKeepTimer.stop(); if (typeof notchControlLoader !== "undefined") notchControlLoader.keep = true; }
            else { notchControlKeepTimer.restart(); globalState.ncEditMode = false; globalState.ncCcSelected = ""; }
        }
    }

    Connections {
        target: globalState
        function onLockScreenActiveChanged()      { if (!globalState.lockScreenActive) gcTimer.restart(); }
        function onSettingsAliveChanged()         { if (!globalState.settingsAlive) gcTimer.restart(); }
        function onWallpaperPickerAliveChanged()  { if (!globalState.wallpaperPickerAlive) gcTimer.restart(); }
        function onFileExplorerAliveChanged()     { if (!globalState.fileExplorerAlive) gcTimer.restart(); }
        function onTextEditorAliveChanged()       { if (!globalState.textEditorAlive) gcTimer.restart(); }
        function onMusicPlayerAliveChanged()      { if (!globalState.musicPlayerAlive) gcTimer.restart(); }
        function onWindowSwitcherAliveChanged()   { if (!globalState.windowSwitcherAlive) gcTimer.restart(); }
        function onDesktopEditModeChanged()       { if (!globalState.desktopEditMode) gcTimer.restart(); }
    }

    Timer {
        id: deferredLateTimer
        interval: 1800; repeat: false
        onTriggered: globalState.deferredLateReady = true
    }

    Timer {
        id: stopwatchTickTimer
        interval: 100
        repeat: true
        running: globalState.stopwatchRunning
        onTriggered: globalState.stopwatchElapsedMs += 100
    }

    PresetRoles { id: presetRoles; gs: globalState }
    ShellPalette { id: pal; gs: globalState; roles: presetRoles }
    M3Theme { id: m3; gs: globalState; colors: pal }
    M3Shapes { id: m3shp }
    I18n { id: i18n; language: globalState.language }
    function tr(key) { return i18n.tr(key); }
    function weatherText(en) { return i18n.weatherText(en); }
    function localeCode() { return i18n.localeCode(); }
    function weekdayInitials() { return i18n.weekdayInitials(); }

    function setLanguage(code) {
        globalState.language = code;
        savePrefs();
    }

    function motivationText(idx) { return i18n.motivationText(idx); }

    function ga(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    function ringTrackColor() {
        return m3.ringTrack;
    }

    function containerDark(c) {
        return globalState.colorMode === "light" ? c : Qt.darker(c, 1.85);
    }

    function roundedPolygonRadius(angle, vertices, rc) {
        var dir = { x: Math.cos(angle), y: Math.sin(angle) };
        var edges = _polygonEdges(vertices, rc);
        var best = Infinity, n = edges.length;
        for (var i = 0; i < n; i++) {
            var denom = edges[i].n.x * dir.x + edges[i].n.y * dir.y;
            if (denom > 1e-9) {
                var r = edges[i].d / denom;
                if (r > 0 && r < best) best = r;
            }
        }
        for (var j = 0; j < n; j++) best = Math.min(best, _cornerArcHit(angle, dir, edges[(j - 1 + n) % n], edges[j], rc));
        return best;
    }

    function _polygonEdges(vertices, rc) {
        var n = vertices.length, edges = [];
        for (var i = 0; i < n; i++) {
            var v0 = vertices[i], v1 = vertices[(i + 1) % n];
            var ex = v1.x - v0.x, ey = v1.y - v0.y;
            var elen = Math.sqrt(ex * ex + ey * ey);
            ex /= elen; ey /= elen;
            edges.push({ n: { x: ey, y: -ex }, d: ey * v0.x - ex * v0.y - rc });
        }
        return edges;
    }

    function _wrapPi(a) {
        while (a <= -Math.PI) a += 2 * Math.PI;
        while (a >   Math.PI) a -= 2 * Math.PI;
        return a;
    }

    function _cornerArcHit(angle, dir, A, B, rc) {
        var det = A.n.x * B.n.y - A.n.y * B.n.x;
        if (Math.abs(det) < 1e-9) return Infinity;
        var dA2 = A.d - rc, dB2 = B.d - rc;
        var ox = (dA2 * B.n.y - dB2 * A.n.y) / det;
        var oy = (A.n.x * dB2 - B.n.x * dA2) / det;
        var angA = Math.atan2(oy + rc * A.n.y, ox + rc * A.n.x);
        var diffAB = _wrapPi(Math.atan2(oy + rc * B.n.y, ox + rc * B.n.x) - angA);
        var rel = _wrapPi(angle - angA);
        var inWindow = (diffAB >= 0) ? (rel >= -1e-9 && rel <= diffAB + 1e-9)
                                     : (rel <=  1e-9 && rel >= diffAB - 1e-9);
        if (!inWindow) return Infinity;
        var proj = ox * dir.x + oy * dir.y;
        var disc = proj * proj - (ox * ox + oy * oy - rc * rc);
        if (disc < 0) return Infinity;
        var rC = proj + Math.sqrt(disc);
        return rC > 0 ? rC : Infinity;
    }

    function rectVertices(hw, hh) {
        return [
            { x: -hw, y: -hh },
            { x:  hw, y: -hh },
            { x:  hw, y:  hh },
            { x: -hw, y:  hh }
        ];
    }

    function triVertices(R) {
        var out = [];
        for (var k = 0; k < 3; k++) {
            var a = (-Math.PI / 2) + k * (2 * Math.PI / 3);
            out.push({ x: R * Math.cos(a), y: R * Math.sin(a) });
        }
        return out;
    }

    function triVertices4(R, rc) {
        var tri = triVertices(R);
        var eps = (rc !== undefined && rc !== null) ? rc : Math.max(R * 0.01, 0.5);
        return [
            { x: tri[0].x - eps, y: tri[0].y },
            { x: tri[0].x + eps, y: tri[0].y },
            { x: tri[1].x,       y: tri[1].y },
            { x: tri[2].x,       y: tri[2].y }
        ];
    }

    function pentaVertices(R) {
        var out = [];
        for (var k = 0; k < 5; k++) {
            var a = (-Math.PI / 2) + k * (2 * Math.PI / 5);
            out.push({ x: R * Math.cos(a), y: R * Math.sin(a) });
        }
        return out;
    }

    function rectVertices5(hw, hh) {
        return [
            { x: 0,   y: -hh },
            { x: hw,  y: -hh },
            { x: hw,  y:  hh },
            { x: -hw, y:  hh },
            { x: -hw, y: -hh }
        ];
    }

    function distroIconGlyph(osName) {
        var s = (osName || "").toLowerCase();
        if (s.indexOf("arch")      >= 0) return "\uf303";
        if (s.indexOf("manjaro")   >= 0) return "\uf312";
        if (s.indexOf("endeavour") >= 0) return "\uf322";
        if (s.indexOf("ubuntu")    >= 0) return "\uf31b";
        if (s.indexOf("debian")    >= 0) return "\uf306";
        if (s.indexOf("fedora")    >= 0) return "\uf30a";
        if (s.indexOf("mint")      >= 0) return "\uf30e";
        if (s.indexOf("gentoo")    >= 0) return "\uf30d";
        if (s.indexOf("suse")      >= 0) return "\uf314";
        if (s.indexOf("nixos")     >= 0) return "\uf313";
        return "\uf17c";
    }

    readonly property string scriptsDir: "$HOME/.config/quickshell/scripts"

    readonly property string kittyReloadBash: "  for s in $XDG_RUNTIME_DIR/kitty-socket-quickshell*; do\n" +
        "    [ -S \"$s\" ] && kitty @ --to \"unix:$s\" set-colors -a -c \"$HOME/.cache/wal/colors-kitty.conf\" >/dev/null 2>&1\n" +
        "  done\n"
}
