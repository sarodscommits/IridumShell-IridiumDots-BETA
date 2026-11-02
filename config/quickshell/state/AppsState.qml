import QtQuick
import QtQml.Models
import Quickshell

// Built-in apps and their windows
DesktopState {
    property string settingsSection: "home"
    property var settingsExpanded: ({})

    function toggleSettingsGroup(key) {
        var m = Object.assign({}, settingsExpanded);
        m[key] = !(m[key] === true);
        settingsExpanded = m;
    }

    property bool settingsAlive:        false
    property bool wallpaperPickerAlive: false
    onSettingsOpenChanged:        { if (settingsOpen) settingsAlive = true; else { settingsWpBrowse = false; wpImportOpen = false; wpDeleteConfirm = ""; settingsSection = "home"; } }
    onWallpaperPickerOpenChanged: if (wallpaperPickerOpen) wallpaperPickerAlive = true
    property bool settingsWpBrowse: false
    property bool   wpImportOpen:      false
    property string wpDeleteConfirm:   ""
    property bool   wpImportDragHover: false
    property string wpImportState:     ""
    property string wpImportMsg:       ""
    property string wpImportMsgKind:   ""
    property bool windowSwitcherOpen: false
    property bool windowSwitcherAlive: false
    property bool   fileExplorerOpen:  false
    property bool   fileExplorerAlive: false
    property string fileExplorerPath:  ""
    onFileExplorerOpenChanged: if (fileExplorerOpen) fileExplorerAlive = true

    function toggleFileExplorer() {
        if (lockScreenActive) return;
        openAppNewWindow("files");
    }

    function openFileExplorer(path) {
        if (lockScreenActive) return;
        fileExplorerPath = path || "";
        fileExplorerOpen = true;
    }

    property bool   textEditorOpen:    false
    property bool   textEditorAlive:   false
    property var    textEditorQueue:   []
    property int    textEditorReq:     0
    property bool   textEditorDirty:   false
    property bool   textEditorPicking: false
    onTextEditorOpenChanged: if (textEditorOpen) textEditorAlive = true

    function toggleTextEditor() {
        if (lockScreenActive) return;
        openAppNewWindow("editor");
    }

    function openTextEditor(path) {
        if (lockScreenActive) return;
        if (path) textEditorQueue = textEditorQueue.concat([path]);
        textEditorReq++;
        textEditorOpen = true;
    }

    property bool   galleryOpen:  false
    property bool   galleryAlive: false
    onGalleryOpenChanged: if (galleryOpen) galleryAlive = true

    function toggleGallery() {
        if (lockScreenActive) return;
        openAppNewWindow("gallery");
    }

    property bool   musicPlayerOpen:  false
    property bool   musicPlayerAlive: false
    property bool   musicPlaying:     false
    property int    musicPosSec:      0
    property int    musicDurSec:      0
    property var    musicPlayerQueue: []
    property int    musicPlayerReq:   0
    property var    musicLyrics:       []
    property bool   musicLyricsSynced: false
    property string musicLyricsPath:   ""
    property int    musicLyricIndex:   -1
    onMusicPlayerOpenChanged: if (musicPlayerOpen) musicPlayerAlive = true

    function toggleMusicPlayer() {
        openMusicHere();
    }

    function openMusicPlayer(paths) {
        if (lockScreenActive) return;
        if (paths && paths.length) musicPlayerQueue = musicPlayerQueue.concat(paths);
        musicPlayerReq++;
        if (!bringMusicHere()) musicPlayerOpen = true;
    }

    property var focusOrder: []
    onWindowSwitcherOpenChanged: if (windowSwitcherOpen) windowSwitcherAlive = true

    function noteFocus(addr) {
        if (!addr) return;
        var l = focusOrder.filter(function(a) { return a !== addr; });
        l.unshift(addr);
        focusOrder = l.slice(0, 64);
    }

    function toggleWindowSwitcher() {
        if (windowSwitcherOpen) { windowSwitcherOpen = false; return; }
        if (lockScreenActive || desktopEditMode) return;
        closeAll(true);
        if (wsCaptureOpenProc.running) return;
        wsRunCapture(wsCaptureOpenProc);
    }

    property var wsShots: ({})

    readonly property string wsCaptureScript:
        "mkdir -p $XDG_RUNTIME_DIR/qs_ws; J=$(hyprctl activeworkspace -j) || exit 1; " +
        "WS=$(echo \"$J\" | jq -r .id); MON=$(echo \"$J\" | jq -r .monitor); " +
        "F=$XDG_RUNTIME_DIR/qs_ws/ws-$WS-$1.png; grim -s 0.4 -o \"$MON\" \"$F\" || exit 1; " +
        "for o in $XDG_RUNTIME_DIR/qs_ws/ws-$WS-*.png; do [ \"$o\" != \"$F\" ] && rm -f \"$o\"; done; " +
        "echo \"$WS $F\""

    function wsRunCapture(proc) {
        proc.command = ["bash", "-c", wsCaptureScript, "qs-wscap", String(Date.now())];
        proc.running = true;
    }

    function wsShotLine(line) {
        var i = line.indexOf(" ");
        if (i < 0) return;
        var id = parseInt(line.substring(0, i));
        if (isNaN(id)) return;
        var m = Object.assign({}, wsShots);
        m[id] = "file://" + line.substring(i + 1).trim();
        wsShots = m;
    }

    property bool settingsOpen:     false
    property bool wallpaperPickerOpen: false

    readonly property var internalApps: [
        { internal: "files",    usageKey: "qs:files",    name: tr("app_files"),    glyph: "\ue2c7", exec: "", icon: "",
          keywords: ["files", "archivos", "explorer", "explorador", "carpetas", "folders", "file manager"] },
        { internal: "music",    usageKey: "qs:music",    name: tr("app_music"),    glyph: "\ue405", exec: "", icon: "",
          keywords: ["music", "musica", "música", "player", "reproductor", "audio", "songs", "canciones"] },
        { internal: "editor",   usageKey: "qs:editor",   name: tr("app_editor"),   glyph: "\ue745", exec: "", icon: "",
          keywords: ["text editor", "editor", "texto", "notas", "notes", "code"] },
        { internal: "gallery",  usageKey: "qs:gallery",  name: tr("app_gallery"),  glyph: "\ue413", exec: "", icon: "",
          keywords: ["gallery", "galeria", "galería", "photos", "fotos", "imagenes", "imágenes", "videos", "vídeos", "pictures"] },
        { internal: "settings", usageKey: "qs:settings", name: tr("app_settings"), glyph: "\ue8b8", exec: "", icon: "",
          keywords: ["settings", "ajustes", "configuracion", "configuración", "preferencias", "preferences", "config"] }
    ]

    function appUsageKey(app) { return (app && app.usageKey) ? app.usageKey : (app ? app.name : ""); }
    function appUsageCount(app) { return appUsage[appUsageKey(app)] || 0; }

    function openInternalApp(id) {
        if (lockScreenActive) return;
        if (id === "music") { openMusicHere(); return; }
        openAppNewWindow(id);
    }

    function openInternalAppPrimary(id) {
        if (id === "files")         fileExplorerOpen = true;
        else if (id === "music")    musicPlayerOpen  = true;
        else if (id === "editor")   textEditorOpen   = true;
        else if (id === "settings") settingsOpen     = true;
        else if (id === "gallery")  galleryOpen      = true;
    }

    property ListModel appWinsFiles:    ListModel {}
    property ListModel appWinsEditor:   ListModel {}
    property ListModel appWinsSettings: ListModel {}
    property ListModel appWinsGallery:  ListModel {}
    property int appExtraSeq: 0

    function appWinsModel(id) {
        if (id === "files")    return appWinsFiles;
        if (id === "editor")   return appWinsEditor;
        if (id === "settings") return appWinsSettings;
        if (id === "gallery")  return appWinsGallery;
        return null;
    }

    function appExtraIndex(id, inst) {
        var m = appWinsModel(id);
        if (!m) return -1;
        for (var i = 0; i < m.count; i++) if (m.get(i).winId === inst) return i;
        return -1;
    }

    function appPrimaryOpen(id) {
        if (id === "files")    return fileExplorerOpen;
        if (id === "editor")   return textEditorOpen;
        if (id === "settings") return settingsOpen;
        if (id === "music")    return musicPlayerOpen;
        if (id === "gallery")  return galleryOpen;
        return false;
    }

    function openAppNewWindow(id) {
        if (lockScreenActive) return;
        if (!appPrimaryOpen(id)) { openInternalAppPrimary(id); return; }
        var m = appWinsModel(id);
        if (!m) return;
        appExtraSeq += 1;
        m.append({ winId: appExtraSeq });
    }

    function closeAppExtra(id, inst) {
        var i = appExtraIndex(id, inst);
        if (i >= 0) appWinsModel(id).remove(i);
    }

    function internalAppForClient(cls, title) {
        if (!cls || !/quickshell/i.test(cls)) return "";
        var t = title || "";
        if (t === "Iridum Settings") return "settings";
        if (/(Editor de texto|Text editor)$/.test(t)) return "editor";
        if (t === "Archivos" || t === "Files") return "files";
        if (t === "Música" || t === "Music") return "music";
        if (t === "Galería" || t === "Gallery") return "gallery";
        return "";
    }

    function internalAppGlyph(id) {
        for (var i = 0; i < internalApps.length; i++) if (internalApps[i].internal === id) return internalApps[i].glyph;
        return "";
    }

    function musicClient() {
        for (var i = 0; i < openClients.length; i++)
            if (internalAppForClient(openClients[i].cls, openClients[i].title) === "music") return openClients[i];
        return null;
    }

    function bringMusicHere() {
        if (!musicPlayerOpen) return false;
        var c = musicClient();
        if (!c || c.workspace === activeWorkspace) return false;
        musicPlayerOpen = false;
        musicReopenTimer.restart();
        return true;
    }

    function openMusicHere() {
        if (lockScreenActive) return;
        if (!musicPlayerOpen) { musicPlayerOpen = true; return; }
        if (bringMusicHere()) return;
        var c = musicClient();
        if (c) Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.window.focus(\"address:" + c.address + "\")"]);
    }

    property Timer musicReopenTimer: Timer { interval: 140; onTriggered: globalState.musicPlayerOpen = true }
    property int    textEditorPickTarget: 0
    property int    textEditorPickFor:    0
    property string textEditorPickPath:   ""
    property int    textEditorPickReq:    0

    function openTextEditorPicked(path) {
        var t = textEditorPickTarget;
        textEditorPickTarget = 0;
        if (t > 0 && appExtraIndex("editor", t) >= 0) {
            textEditorPickPath = path;
            textEditorPickFor = t;
            textEditorPickReq += 1;
            return;
        }
        openTextEditor(path);
    }
}
