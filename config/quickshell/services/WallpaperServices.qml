import QtQuick
import Quickshell
import Quickshell.Io

// Wallpaper list, folder watch and terminal color reloads
BackendServices {
    property alias termColorsReloadTimer: termColorsReloadTimer
    property alias walColorReload2Timer: walColorReload2Timer
    property alias walColorReload3Timer: walColorReload3Timer
    property alias walColorReloadTimer: walColorReloadTimer
    property alias wallpaperDirReloadTimer: wallpaperDirReloadTimer
    property alias wallpaperDirWatchProcess: wallpaperDirWatchProcess

    Process {
        id: wallpaperListProcess
        command: ["bash", "-c",
        "WDIR=\"$HOME/Wallpapers\"; [ -d \"$WDIR\" ] || exit 0; " +
        "CURR=\"\"; [ -f \"$HOME/.cache/wallpaper-selector/current.txt\" ] && CURR=$(cat \"$HOME/.cache/wallpaper-selector/current.txt\"); " +
        "THUMBDIR=\"$HOME/.cache/wallpaper-selector/thumbs\"; mkdir -p \"$THUMBDIR\"; " +
        "find \"$WDIR\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' \\) | sort | while read -r f; do " +
        "  name=$(basename \"$f\"); " +
        "  current=0; [ \"$name\" = \"$CURR\" ] && current=1; " +
        "  case \"$name\" in " +
        "    *.mp4|*.MP4|*.webm|*.WEBM|*.mkv|*.MKV) " +
        "      animated=1; " +
        "      thumb=\"$THUMBDIR/$name.png\"; " +
        "      if [ ! -f \"$thumb\" ] && command -v ffmpeg >/dev/null 2>&1; then " +
        "        ffmpeg -nostdin -y -loglevel error -ss 0 -i \"$f\" -frames:v 1 -vf \"scale=480:-1\" \"$thumb\" 2>/dev/null; " +
        "      fi; " +
        "      [ -f \"$thumb\" ] || thumb=\"\"; " +
        "      ;; " +
        "    *) animated=0; " +
        "      thumb=\"$THUMBDIR/$name.thumb.jpg\"; " +
        "      if { [ ! -f \"$thumb\" ] || [ \"$f\" -nt \"$thumb\" ]; } && command -v ffmpeg >/dev/null 2>&1; then " +
        "        ffmpeg -nostdin -y -loglevel error -i \"$f\" -frames:v 1 -vf \"scale='min(1280,iw)':-2\" -q:v 3 \"$thumb\" 2>/dev/null; " +
        "      fi; " +
        "      [ -f \"$thumb\" ] || thumb=\"$f\"; " +
        "      ;; " +
        "  esac; " +
        "  echo \"$f|$name|$current|$animated|$thumb\"; " +
        "done"
        ]
        running: false
        property bool _startupRestoreDone: false
        property var _acc: []
        stdout: SplitParser {
            onRead: (line) => {
                var parts = line.split("|");
                if (parts.length < 5) return;
                wallpaperListProcess._acc.push({
                    path: parts[0], name: parts[1], current: parts[2] === "1",
                    animated: parts[3] === "1", thumb: parts[4]
                });
                if (parts[2] === "1") globalState.currentWallpaper = parts[0];
            }
        }
        onRunningChanged: {
            if (running) { wallpaperListProcess._acc = []; return; }
            if (!running) {
                globalState.wallpaperList = wallpaperListProcess._acc;
                wallpaperListProcess._acc = [];
                globalState.wallpaperLoaded = true;
                Qt.callLater(pruneMissingProfiles);
                wpStillReader.running = true;
                if (!wallpaperListProcess._startupRestoreDone) {
                    wallpaperListProcess._startupRestoreDone = true;
                    var cur = globalState.currentWallpaper;
                    var ext = cur !== "" ? cur.split(".").pop().toLowerCase() : "";
                    if (ext === "mp4" || ext === "webm" || ext === "mkv") {
                        var restoreScript =
                        "#!/bin/bash\n" +
                        "WALLPAPER=" + JSON.stringify(cur) + "\n" +
                        "CACHEDIR=\"$HOME/.cache/wallpaper-selector\"\n" +
                        "mkdir -p \"$CACHEDIR\"\n" +
                        "NAME=$(basename \"$WALLPAPER\")\n" +
                        "pkill -f mpvpaper 2>/dev/null\n" +
                        "STILL=\"$CACHEDIR/frame-$NAME.png\"\n" +
                        "if [ ! -f \"$STILL\" ] && command -v ffmpeg >/dev/null 2>&1; then\n" +
                        "  ffmpeg -nostdin -y -loglevel error -ss 0 -i \"$WALLPAPER\" -frames:v 1 \"$STILL\" 2>/dev/null\n" +
                        "fi\n" +
                        "if [ -f \"$STILL\" ]; then\n" +
                        "  awww img \"$STILL\" --transition-type simple --transition-duration 0.2\n" +
                        "fi\n" +
                        "sleep 0.4\n" +
                        buildMpvLaunchBashSnippet() +
                        "sleep 2\n" +
                        "if ! pgrep -f 'mpvpaper' >/dev/null 2>&1; then\n" +
                        buildMpvLaunchBashSnippet() +
                        "fi\n";
                        wpScriptSaver._doSave(restoreScript);
                    }
                    if (globalState.paletteSource === "preset" && globalState.presetApplyKitty) { applyPresetKittyColors(); }
                }
            }
        }
    }

    Timer {
        id: wallpaperListInitTimer
        interval: 500; running: globalState.deferredLateReady; repeat: false
        onTriggered: {
            globalState.wallpaperList = [];
            globalState.wallpaperLoaded = false;
            wallpaperListProcess.running = true;
        }
    }

    Process {
        id: wallpaperDirWatchProcess
        command: ["bash", "-c",
        "WDIR=\"$HOME/Wallpapers\"; mkdir -p \"$WDIR\"; " +
        "while true; do " +
        "  inotifywait -e create,delete,moved_to,moved_from,close_write -qq \"$WDIR\" 2>/dev/null; " +
        "  echo changed; " +
        "  sleep 0.3; " +
        "done"
        ]
        running: false
        stdout: SplitParser {
            onRead: (line) => {
                if (line.trim() === "changed") wallpaperDirReloadTimer.restart();
            }
        }
        onRunningChanged: {
            if (!running) wallpaperDirWatchRestartTimer.start();
        }
    }

    Timer {
        id: wallpaperDirWatchRestartTimer
        interval: 3000; repeat: false
        onTriggered: wallpaperDirWatchProcess.running = true
    }

    Process {
        id: termColorsProcess
        command: ["bash", "-c", "cat \"$HOME/.cache/wal/colors-kitty.conf\" 2>/dev/null"]
        running: false
        property var _acc: ({})
        stdout: SplitParser {
            onRead: (line) => {
                var m = line.trim().match(/^(background|foreground|color[0-9]+)\s+(#[0-9a-fA-F]{6})/);
                if (m) termColorsProcess._acc[m[1]] = m[2];
            }
        }
        onRunningChanged: {
            if (running) { termColorsProcess._acc = ({}); return; }
            if (termColorsProcess._acc.color0 !== undefined) globalState.termColors = termColorsProcess._acc;
            termColorsProcess._acc = ({});
        }
        function reload() { if (!running) running = true; }
    }

    Timer {
        id: termColorsReloadTimer
        interval: 1500; repeat: false
        property int passes: 0
        function kick() { passes = 0; restart(); }
        onTriggered: {
            termColorsProcess.reload();
            if (++passes < 4) restart();
        }
    }

    Timer {
        interval: 800; running: globalState.deferredLateReady; repeat: false
        onTriggered: termColorsProcess.reload()
    }

    Connections {
        target: globalState
        function onCurrentWallpaperChanged() { termColorsReloadTimer.kick(); }
        function onPaletteSourceChanged()    { termColorsReloadTimer.kick(); }
        function onPresetPaletteKeyChanged() { termColorsReloadTimer.kick(); }
        function onPresetApplyKittyChanged() { termColorsReloadTimer.kick(); }
        function onColorModeChanged()        { termColorsReloadTimer.kick(); }
        function onSettingsOpenChanged()     { if (globalState.settingsOpen) termColorsProcess.reload(); }
    }

    Timer {
        id: wallpaperDirReloadTimer
        interval: 500; repeat: false
        onTriggered: {
            globalState.wallpaperList = [];
            globalState.wallpaperLoaded = false;
            wallpaperListProcess.running = true;
        }
    }

    Timer {
        id: walColorReloadTimer
        interval: 800; repeat: false
        onTriggered: colorExtraction.reload()
    }

    Timer {
        id: walColorReload2Timer
        interval: 2500; repeat: false
        onTriggered: colorExtraction.reload()
    }

    Timer {
        id: walColorReload3Timer
        interval: 5000; repeat: false
        onTriggered: colorExtraction.reload()
    }
}
