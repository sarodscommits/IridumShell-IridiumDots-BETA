import QtQuick
import Quickshell
import Quickshell.Io

// Wallpaper apply pipeline, import/delete and mpvpaper control
AppearanceServices {
    property alias wpImportProcess: wpImportProcess
    property alias wpScriptSaver: wpScriptSaver
    property alias wpStillReader: wpStillReader

    Process {
        id: wpScriptSaver
        command: ["python3", "-c",
        "import sys, os\n" +
        "d = os.path.expanduser('~/.cache/quickshell')\n" +
        "os.makedirs(d, exist_ok=True)\n" +
        "data = sys.stdin.read()\n" +
        "with open(os.path.join(d, 'wp-apply.sh'), 'w') as f:\n" +
        "    f.write(data)\n"
        ]
        running: false
        stdinEnabled: true
        property bool _busy: false
        property string _pending: ""

        onRunningChanged: {
            if (!running) {
                wpScriptSaver.stdinEnabled = true;
                if (wpRunner.running) {
                    wpRunner.running = false;
                    Qt.callLater(function() { wpRunner.running = true; });
                } else {
                    wpRunner.running = true;
                }
            }
        }

        function _doSave(script) {
            if (wpScriptSaver._busy) {
                wpScriptSaver._pending = script;
                return;
            }
            wpScriptSaver._busy = true;
            wpScriptSaver.running = true;
            wpScriptSaver.write(script);
            wpScriptSaver.stdinEnabled = false;
        }
    }

    Process {
        id: wpRunner
        command: ["bash", "-c", "bash \"$HOME/.cache/quickshell/wp-apply.sh\""]
        running: false
        onRunningChanged: {
            if (!running) {
                var cur = globalState.currentWallpaper;
                var lst = globalState.wallpaperList;
                var rebuilt = [];
                for (var i = 0; i < lst.length; i++) {
                    var wp = lst[i];
                    rebuilt.push({ path: wp.path, name: wp.name, current: wp.path === cur,
                        animated: wp.animated, thumb: wp.thumb });
                }
                globalState.wallpaperList = rebuilt;
                walColorReloadTimer.restart();
                walColorReload2Timer.restart();
                walColorReload3Timer.restart();
                wpStillReader.running = true;
                wpScriptSaver._busy = false;
                if (wpScriptSaver._pending !== "") {
                    var p = wpScriptSaver._pending;
                    wpScriptSaver._pending = "";
                    wpScriptSaver._doSave(p);
                }
            }
        }
    }

    Process {
        id: wpStillReader
        command: ["bash", "-c", "cat \"$HOME/.cache/wallpaper-selector/current-still.txt\" 2>/dev/null"]
        running: false
        stdout: SplitParser {
            onRead: (line) => {
                if (line !== "") globalState.currentWallpaperStill = line;
            }
        }
    }

    readonly property string wpImportScript:
      "MODE=\"$1\"; T=\"$2\"; shift 2\n" +
      "D=\"$HOME/Wallpapers\"; mkdir -p \"$D\"\n" +
      "PAT=\"\"; for e in jpg jpeg png webp mp4 webm mkv; do PAT=\"$PAT *.$e *.${e^^}\"; done; PAT=\"${PAT# }\"\n" +
      "if [ \"$MODE\" = pick ]; then\n" +
      "  echo PICKING\n" +
      "  NL=$'\\n'\n" +
      "  if command -v zenity >/dev/null 2>&1; then\n" +
      "    OUT=$(zenity --file-selection --multiple --separator=\"$NL\" --title=\"$T\" --filename=\"$HOME/\" --file-filter=\"$T | $PAT\" 2>/dev/null) || { echo CANCEL; exit 0; }\n" +
      "  elif command -v kdialog >/dev/null 2>&1; then\n" +
      "    OUT=$(kdialog --title \"$T\" --getopenfilename \"$HOME\" \"$PAT|$T\" --multiple --separate-output 2>/dev/null) || { echo CANCEL; exit 0; }\n" +
      "  elif command -v yad >/dev/null 2>&1; then\n" +
      "    OUT=$(yad --file --multiple --separator=\"$NL\" --title=\"$T\" --file-filter=\"$T | $PAT\" 2>/dev/null) || { echo CANCEL; exit 0; }\n" +
      "  else echo NOPICKER; exit 0; fi\n" +
      "  [ -n \"$OUT\" ] || { echo CANCEL; exit 0; }\n" +
      "  mapfile -t SEL <<< \"$OUT\"\n" +
      "  set -- \"${SEL[@]}\"\n" +
      "fi\n" +
      "echo COPYING\n" +
      "ADD=0; DUP=0; BAD=0\n" +
      "for f in \"$@\"; do\n" +
      "  [ -n \"$f\" ] || continue\n" +
      "  [ -f \"$f\" ] || { BAD=$((BAD+1)); continue; }\n" +
      "  case \"${f,,}\" in *.jpg|*.jpeg|*.png|*.webp|*.mp4|*.webm|*.mkv) ;; *) BAD=$((BAD+1)); continue ;; esac\n" +
      "  DST=\"$D/$(basename \"$f\")\"\n" +
      "  if [ -e \"$DST\" ]; then\n" +
      "    if cmp -s \"$f\" \"$DST\"; then DUP=$((DUP+1)); continue; fi\n" +
      "    B=\"${DST%.*}\"; X=\"${DST##*.}\"; i=2\n" +
      "    while [ -e \"$B-$i.$X\" ]; do i=$((i+1)); done\n" +
      "    DST=\"$B-$i.$X\"\n" +
      "  fi\n" +
      "  if cp -- \"$f\" \"$DST\"; then ADD=$((ADD+1)); else BAD=$((BAD+1)); fi\n" +
      "done\n" +
      "echo \"RESULT $ADD $DUP $BAD\"\n"

    property int wpImportExtraBad: 0

    Process {
        id: wpImportProcess
        running: false
        command: ["true"]
        stdout: SplitParser { onRead: (line) => handleWpImportLine(line) }
        onRunningChanged: {
            if (running) return;
            if (globalState.wpImportState === "picking" || globalState.wpImportState === "copying") globalState.wpImportState = "";
        }
    }

    Timer {
        id: wpImportCloseTimer
        interval: 1800; repeat: false
        onTriggered: if (globalState.wpImportState === "done" && !globalState.wpImportDragHover) globalState.wpImportOpen = false
    }

    function wpImportShow() {
        if (!wpImportProcess.running) { globalState.wpImportState = ""; globalState.wpImportMsg = ""; }
        wpImportCloseTimer.stop();
        globalState.wpImportOpen = true;
    }

    function wpImportStart(mode, paths, extraBad) {
        if (wpImportProcess.running) return;
        wpImportCloseTimer.stop();
        wpImportExtraBad = extraBad || 0;
        globalState.wpImportMsg = "";
        globalState.wpImportState = mode === "pick" ? "picking" : "copying";
        wpImportProcess.command = ["bash", "-c", wpImportScript, "qs-wpimport", mode, tr("wpi_title_add")].concat(paths || []);
        wpImportProcess.running = true;
    }

    function wpImportPick() { wpImportStart("pick", [], 0); }

    Process {
        id: wpDeleteProcess
        running: false
        command: ["true"]
        stdout: SplitParser {
            onRead: (line) => { if (line.trim().indexOf("ERR") === 0) console.warn("[wallpaper] couldn't delete:", line); }
        }
        onRunningChanged: if (!running) wallpaperDirReloadTimer.restart()
    }

    function wpDeleteFile(path) {
        globalState.wpDeleteConfirm = "";
        if (!path || path === globalState.currentWallpaper || wpDeleteProcess.running) return;
        globalState.wallpaperList = globalState.wallpaperList.filter(function(w) { return w.path !== path; });
        wpDeleteProcess.command = ["bash", "-c",
            "F=\"$1\"; N=$(basename \"$F\"); TD=\"$HOME/.cache/wallpaper-selector/thumbs\"; " +
            "[ -f \"$F\" ] || { echo \"ERR missing $F\"; exit 0; }; " +
            "if command -v gio >/dev/null 2>&1 && gio trash -- \"$F\" 2>/dev/null; then echo OK trash; " +
            "elif command -v trash-put >/dev/null 2>&1 && trash-put -- \"$F\" 2>/dev/null; then echo OK trash; " +
            "elif rm -f -- \"$F\"; then echo OK rm; else echo \"ERR rm $F\"; fi; " +
            "rm -f -- \"$TD/$N.png\" \"$TD/$N.thumb.jpg\"",
            "qs-wpdelete", path];
        wpDeleteProcess.running = true;
    }

    function wpImportHandleDrop(drop) {
        globalState.wpImportDragHover = false;
        globalState.wpImportOpen = true;
        var local = [], extra = 0;
        if (drop.hasUrls) {
            for (var i = 0; i < drop.urls.length; i++) {
                var u = drop.urls[i].toString();
                if (u.indexOf("file://") === 0) local.push(decodeURIComponent(u.substring(7)));
                else extra++;
            }
        }
        drop.accept(Qt.CopyAction);
        if (local.length === 0) {
            globalState.wpImportState = "done";
            globalState.wpImportMsgKind = "err";
            globalState.wpImportMsg = tr("wpi_nothing");
            return;
        }
        wpImportStart("copy", local, extra);
    }

    function handleWpImportLine(line) {
        var t = line.trim();
        if (t === "PICKING")      globalState.wpImportState = "picking";
        else if (t === "COPYING") globalState.wpImportState = "copying";
        else if (t === "CANCEL")  globalState.wpImportState = "";
        else if (t === "NOPICKER") {
            Quickshell.execDetached(["bash", "-c", "mkdir -p \"$HOME/Wallpapers\"; xdg-open \"$HOME/Wallpapers\""]);
            globalState.wpImportState = "done";
            globalState.wpImportMsgKind = "warn";
            globalState.wpImportMsg = tr("wpi_nopicker");
        } else if (t.indexOf("RESULT ") === 0) {
            var p = t.split(" ");
            var a = parseInt(p[1]) || 0, d = parseInt(p[2]) || 0, b = (parseInt(p[3]) || 0) + wpImportExtraBad;
            var parts = [];
            if (a > 0) parts.push(tr("wpi_added").replace("%1", a));
            if (d > 0) parts.push(tr("wpi_dup").replace("%1", d));
            if (b > 0) parts.push(tr("wpi_bad").replace("%1", b));
            if (parts.length === 0) parts.push(tr("wpi_nothing"));
            globalState.wpImportMsg = parts.join("  ·  ");
            globalState.wpImportMsgKind = a > 0 ? ((b > 0 || d > 0) ? "warn" : "ok") : "err";
            globalState.wpImportState = "done";
            if (a > 0) {
                wallpaperDirReloadTimer.restart();
                if (b === 0 && d === 0) wpImportCloseTimer.restart();
            }
        }
    }

    function buildMpvLaunchBashSnippet() {
      var fpsFilter = globalState.wallpaperFpsLimit < 60 ? ("fps=" + globalState.wallpaperFpsLimit) : "";
      return (
        "SOCK=\"/tmp/mpvpaper-wallpaper.sock\"\n" +
        "rm -f \"$SOCK\" 2>/dev/null\n" +
        "SCREEN_W=$(hyprctl monitors -j 2>/dev/null | jq '[.[] | select(.disabled==false) | .width] | max // empty')\n" +
        "SCREEN_H=$(hyprctl monitors -j 2>/dev/null | jq '[.[] | select(.disabled==false) | .height] | max // empty')\n" +
        "[ -z \"$SCREEN_W\" ] && SCREEN_W=1920\n" +
        "[ -z \"$SCREEN_H\" ] && SCREEN_H=1080\n" +
        "MPVOPTS=\"no-audio loop-file=inf panscan=1.0 hwdec=auto-safe vd-lavc-threads=2 input-ipc-server=$SOCK\"\n" +
        "VF_PARTS=\"\"\n" +
        "if command -v ffprobe >/dev/null 2>&1; then\n" +
        "  read -r SRC_W SRC_H < <(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 \"$WALLPAPER\" 2>/dev/null | tr 'x' ' ')\n" +
        "  if [ -n \"$SRC_W\" ] && [ -n \"$SRC_H\" ]; then\n" +
        "    NEEDSCALE=0\n" +
        "    [ \"$SRC_W\" -gt \"$SCREEN_W\" ] 2>/dev/null && NEEDSCALE=1\n" +
        "    [ \"$SRC_H\" -gt \"$SCREEN_H\" ] 2>/dev/null && NEEDSCALE=1\n" +
        "    if [ \"$NEEDSCALE\" = \"1\" ]; then\n" +
        "      TGT_W=$SCREEN_W; TGT_H=$(( SRC_H * SCREEN_W / SRC_W ))\n" +
        "      if [ \"$TGT_H\" -gt \"$SCREEN_H\" ]; then TGT_H=$SCREEN_H; TGT_W=$(( SRC_W * SCREEN_H / SRC_H )); fi\n" +
        "      VF_PARTS=\"scale=${TGT_W}:${TGT_H}\"\n" +
        "    fi\n" +
        "  fi\n" +
        "fi\n" +
        (fpsFilter !== "" ? ("VF_PARTS=\"${VF_PARTS:+$VF_PARTS,}" + fpsFilter + "\"\n") : "") +
        "[ -n \"$VF_PARTS\" ] && MPVOPTS=\"$MPVOPTS vf=$VF_PARTS\"\n" +
        "setsid mpvpaper -o \"$MPVOPTS\" '*' \"$WALLPAPER\" >/dev/null 2>&1 &\n" +
        "disown\n"
      );
    }

    function setWallpaperWatchingPaused(paused) {
      if (!isCurrentWallpaperAnimated()) return;
      var val = paused ? "true" : "false";
      var script =
        "SOCK=\"/tmp/mpvpaper-wallpaper.sock\"\n" +
        "[ -S \"$SOCK\" ] && echo '{\"command\":[\"set_property\",\"pause\"," + val + "]}' | socat - \"$SOCK\" >/dev/null 2>&1\n";
      Quickshell.execDetached(["bash", "-c", script]);
    }

    function isCurrentWallpaperAnimated() {
      var cur = globalState.currentWallpaper;
      if (cur === "") return false;
      var ext = cur.split(".").pop().toLowerCase();
      return ext === "mp4" || ext === "webm" || ext === "mkv";
    }

    function setWallpaperFpsLimit(v) {
      v = Math.max(10, Math.min(60, Math.round(v)));
      globalState.wallpaperFpsLimit = v;
      savePrefs();
      if (!isCurrentWallpaperAnimated()) return;
      var fpsFilter = v < 60 ? ("fps=" + v) : "";
      var script =
        "SOCK=\"/tmp/mpvpaper-wallpaper.sock\"\n" +
        "[ -S \"$SOCK\" ] && echo '{\"command\":[\"vf\",\"set\"," + JSON.stringify(fpsFilter) + "]}' | socat - \"$SOCK\" >/dev/null 2>&1\n";
      Quickshell.execDetached(["bash", "-c", script]);
    }

    function updateWallpaperPauseState() {
      setWallpaperWatchingPaused(globalState.lockScreenActive || globalState.wpFullscreenActive);
    }

    function applyWallpaper(path) {
        if (profileStore.editing !== "" && profileStore.editing !== path) profileStore.editing = "";
        switchProfileForWallpaper(path);
        globalState.currentWallpaper = path;
        var mode = globalState.colorMode === "light" ? "light" : "dark";
        var ext = path.split(".").pop().toLowerCase();
        var isVideo = (ext === "mp4" || ext === "webm" || ext === "mkv");
        var presetForKitty = globalState.paletteSource === "preset" && globalState.presetApplyKitty;
        var presetForQuickshell = globalState.paletteSource === "preset" && globalState.presetApplyQuickshell;
        wpScriptSaver._doSave(_wpHeaderBash(path, mode, isVideo) +
            "(\n" + _wpColorBash(presetForKitty, presetForQuickshell) + ") &\n" +
            "COLORPID=$!\n" + _wpVisualBash() +
            "wait \"$COLORPID\" 2>/dev/null\n" +
            "echo \"$NAME\" > \"$CACHEDIR/current.txt\"\n" +
            buildAccentSyncSnippet());
    }

    function _wpHeaderBash(path, mode, isVideo) {
        return "#!/bin/bash\n" +
            "WALLPAPER=" + JSON.stringify(path) + "\n" +
            "MODE=" + JSON.stringify(mode) + "\n" +
            "ANIMATED=" + (isVideo ? "1" : "0") + "\n" +
            "NAME=$(basename \"$WALLPAPER\")\n" +
            "CACHEDIR=\"$HOME/.cache/wallpaper-selector\"\n" +
            "mkdir -p \"$CACHEDIR\"\n" +
            "pkill -f mpvpaper 2>/dev/null\n" +
            "sleep 0.15\n" +
            "if [ \"$ANIMATED\" = \"1\" ]; then\n" +
            "  COLORSRC=\"$CACHEDIR/frame-$NAME.png\"\n" +
            "  if [ ! -f \"$COLORSRC\" ] && command -v ffmpeg >/dev/null 2>&1; then\n" +
            "    ffmpeg -nostdin -y -loglevel error -ss 0 -i \"$WALLPAPER\" -frames:v 1 \"$COLORSRC\" 2>/dev/null\n" +
            "  fi\n" +
            "  [ -f \"$COLORSRC\" ] || COLORSRC=\"$WALLPAPER\"\n" +
            "  STILL=\"$COLORSRC\"\n" +
            "else\n" +
            "  COLORSRC=\"$WALLPAPER\"\n" +
            "  STILL=\"$WALLPAPER\"\n" +
            "fi\n" +
            "echo -n \"$STILL\" > \"$CACHEDIR/current-still.txt\"\n";
    }

    function _wpColorBash(presetForKitty, presetForQuickshell) {
        return "  if command -v wal >/dev/null 2>&1; then\n" +
            "    wal -i \"$COLORSRC\" -n -q" + (presetForKitty ? " -s" : "") + "\n" +
            "  fi\n" +
            (presetForQuickshell ? "" : _wpMatugenBash()) +
            (presetForKitty ? _wpPresetKittyBash() : _wpTermBash(presetForQuickshell));
    }

    function _wpMatugenBash() {
        return "  COL_JSON=\"$HOME/.config/matugen/colors.json\"\n" +
            "  matugen image \"$COLORSRC\" --source-color-index 1 --type scheme-fidelity --fallback-color '#888888' -j hex > \"$COL_JSON\" 2>/dev/null || " +
            "matugen image \"$COLORSRC\" --source-color-index 0 --type scheme-fidelity --fallback-color '#888888' -j hex > \"$COL_JSON\"\n" +
            "  matugen image \"$COLORSRC\" --source-color-index 1 --type scheme-fidelity --fallback-color '#888888' >/dev/null 2>&1 || " +
            "matugen image \"$COLORSRC\" --source-color-index 0 --type scheme-fidelity --fallback-color '#888888' >/dev/null 2>&1\n";
    }

    function _wpTermBash(presetForQuickshell) {
        return ((presetForQuickshell && globalState.termPaletteMode !== "pywal")
            ? "  mkdir -p \"$HOME/.cache/wal\"\n" +
            "  matugen image \"$COLORSRC\" --dry-run --source-color-index 1 --type scheme-fidelity --fallback-color '#888888' -j hex > \"$HOME/.cache/wal/matugen-term.json\" 2>/dev/null || " +
            "matugen image \"$COLORSRC\" --dry-run --source-color-index 0 --type scheme-fidelity --fallback-color '#888888' -j hex > \"$HOME/.cache/wal/matugen-term.json\" 2>/dev/null || rm -f \"$HOME/.cache/wal/matugen-term.json\"\n"
            : "  rm -f \"$HOME/.cache/wal/matugen-term.json\"\n") +
            buildPywalTermSnippet();
    }

    function _wpPresetKittyBash() {
        return "  cat > \"$HOME/.cache/wal/colors-kitty.conf\" << 'IRIDUM_KITTY_EOF'\n" +
            buildPresetKittyConf() +
            "IRIDUM_KITTY_EOF\n" +
            "  cat > \"$HOME/.cache/wal/sequences\" << 'IRIDUM_SEQ_EOF'\n" +
            buildPresetSequences() +
            "IRIDUM_SEQ_EOF\n" +
            kittyReloadBash;
    }

    function _wpVisualBash() {
        return "(\n" +
            "if [ \"$ANIMATED\" = \"1\" ]; then\n" +
            "  VDUR=1.5\n" +
            "  awww img \"$COLORSRC\" --transition-type wipe --transition-angle 45 --transition-duration $VDUR\n" +
            "  sleep $VDUR\n" +
        buildMpvLaunchBashSnippet() +
            "else\n" +
            "  awww img \"$WALLPAPER\" --transition-type wipe --transition-angle 45 --transition-duration 1.5\n" +
            "fi\n" +
            "if [ \"$ANIMATED\" = \"1\" ]; then notify-send Wallpaper \"$NAME (animado)\"; else notify-send Wallpaper \"$NAME\"; fi\n" +
            ") &\n" +
            "disown\n";
    }
}
