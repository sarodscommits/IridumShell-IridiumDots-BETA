import QtQuick
import Quickshell
import Quickshell.Io
import ".."

// Screen recording, screenshots and gaming-panel key timers
ClipboardServices {
    property alias gamingCloseEscTimer: gamingCloseEscTimer
    property alias gamingEscTimer: gamingEscTimer
    property alias gamingGrabTimer: gamingGrabTimer
    property alias recDetectProcess: recDetectProcess
    property alias recProcess: recProcess
    property alias recRegionLaunchDelay: recRegionLaunchDelay
    property alias recStartDelay: recStartDelay
    property alias shotFullDelay: shotFullDelay

    Timer { id: shotFullDelay; interval: 350; repeat: false; onTriggered: if (!shotFullProc.running) shotFullProc.running = true }

    Process {
        id: shotFullProc
        command: ["bash", "-c", "exec bash \"" + scriptsDir + "/screenshot_full.sh\" \"$1\" \"$2\"",
            "qs-shot", tr("shot_saved"), tr("take_screenshot")]
    }

    Timer {
        id: gamingEscTimer
        interval: 250; repeat: false
        onTriggered: {
            if (!globalState.gamingOpen || !globalState.gamingEscOnOpen) return;
            globalState.gamingSendEsc("open");
            globalState.gamingEscSent = true;
            gamingGrabTimer.restart();
        }
    }

    Timer {
        id: gamingGrabTimer
        interval: 250; repeat: false
        onTriggered: if (globalState.gamingOpen && globalState.gamingEscOnOpen) globalState.gamingKeyGrab = true
    }

    Timer {
        id: gamingCloseEscTimer
        interval: 220; repeat: false
        onTriggered: if (!globalState.gamingOpen) globalState.gamingSendEsc("close")
    }

    readonly property string recScript:
      "FPS=\"$1\"; RES=\"$2\"; MIC=\"$3\"; GEOM=\"$4\"\n" +
      "DIR=$(xdg-user-dir VIDEOS 2>/dev/null); [ -d \"$DIR\" ] || DIR=\"$HOME/Videos\"\n" +
      "DIR=\"$DIR/Recordings\"; mkdir -p \"$DIR\"\n" +
      "OUT=\"$DIR/recording-$(date +%Y%m%d-%H%M%S).mp4\"\n" +
      "LOG=\"$HOME/.cache/qs-screenrec.log\"; mkdir -p \"$HOME/.cache\"; : > \"$LOG\"\n" +
      "MJ=$(hyprctl monitors -j 2>/dev/null)\n" +
      "mget() { printf '%s' \"$MJ\" | jq -r \"[.[]|select(.focused)][0].$1 // empty\" 2>/dev/null; }\n" +
      "MON=$(mget name); MW=$(mget width); MH=$(mget height)\n" +
      "# region (WxH+X+Y from slurp): even size for the encoder\n" +
      "RW=\"\"; RH=\"\"; RX=\"\"; RY=\"\"\n" +
      "if [ -n \"$GEOM\" ]; then\n" +
      "  RW=${GEOM%%x*}; R=${GEOM#*x}; RH=${R%%+*}; R=${R#*+}; RX=${R%%+*}; RY=${R#*+}\n" +
      "  RW=$(( RW / 2 * 2 )); RH=$(( RH / 2 * 2 )); GEOM=\"${RW}x${RH}+${RX}+${RY}\"; MW=$RW; MH=$RH\n" +
      "fi\n" +
      "TW=\"\"; TH=\"\"\n" +
      "if [ \"$RES\" != \"native\" ] && [ -n \"$MH\" ] && [ \"$RES\" -lt \"$MH\" ] 2>/dev/null; then\n" +
      "  TH=$RES; TW=$(( MW * TH / MH / 2 * 2 ))\n" +
      "fi\n" +
      "if command -v gpu-screen-recorder >/dev/null 2>&1; then MODE=gsr\n" +
      "elif command -v wf-recorder >/dev/null 2>&1; then MODE=wf\n" +
      "else echo \"ERR:nobin\"; exit 1; fi\n" +
      "PID=\"\"; N=0; SEGDIR=\"\"; STOPREQ=0\n" +
      "HASPA=0; command -v pactl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1 && HASPA=1\n" +
      "[ \"$MIC\" = 1 ] || MIC=0\n" +
      "# indices of the \"monitor\" sources (desktop audio): never muted along with the mic\n" +
      "mon_ids() { pactl -f json list sources 2>/dev/null | jq -c '[.[] | select((.name // \"\") | endswith(\".monitor\")) | .index]' 2>/dev/null; }\n" +
      "src_ids() {\n" +
      "  local mons; mons=$(mon_ids); [ -n \"$mons\" ] || mons='[]'\n" +
      "  if [ -n \"$LBMIC\" ]; then\n" +
      "    pactl -f json list source-outputs 2>/dev/null | jq -r --arg m \"$LBMIC\" '.[] | select(((.owner_module // \"\") | tostring) == $m) | .index' 2>/dev/null\n" +
      "  else\n" +
      "    pactl -f json list source-outputs 2>/dev/null | jq -r --arg p \"$PID\" --argjson mons \"$mons\" '.[] | select(((.properties[\"application.process.id\"] // \"\") | tostring) == $p or ((.properties[\"application.process.binary\"] // \"\") | test(\"gpu-screen-recorder|wf-recorder\"))) | select(.source as $s | ($mons | any(.[]; . == $s)) | not) | .index' 2>/dev/null\n" +
      "  fi\n" +
      "}\n" +
      "apply_mic() {\n" +
      "  [ $HASPA = 1 ] || return 0\n" +
      "  local m=$((1-MIC))\n" +
      "  ( for t in $(seq 1 50); do ids=$(src_ids); if [ -n \"$ids\" ]; then for i in $ids; do pactl set-source-output-mute \"$i\" $m >/dev/null 2>&1; done; exit 0; fi; sleep 0.1; done ) &\n" +
      "}\n" +
      "# wf-recorder only accepts one audio source: desktop + mic are mixed into a null sink\n" +
      "MIXMOD=\"\"; LBOUT=\"\"; LBMIC=\"\"\n" +
      "mix_up() {\n" +
      "  [ $HASPA = 1 ] || return 0\n" +
      "  local ds; ds=$(pactl get-default-sink 2>/dev/null); [ -n \"$ds\" ] || return 0\n" +
      "  MIXMOD=$(pactl load-module module-null-sink sink_name=qs_rec_mix sink_properties=device.description=QS-Rec-Mix 2>>\"$LOG\") || { MIXMOD=\"\"; return 0; }\n" +
      "  LBOUT=$(pactl load-module module-loopback source=\"$ds.monitor\" sink=qs_rec_mix latency_msec=30 source_dont_move=true sink_dont_move=true 2>>\"$LOG\")\n" +
      "  LBMIC=$(pactl load-module module-loopback source=@DEFAULT_SOURCE@ sink=qs_rec_mix latency_msec=30 sink_dont_move=true 2>>\"$LOG\")\n" +
      "}\n" +
      "mix_down() {\n" +
      "  for m in $LBMIC $LBOUT $MIXMOD; do pactl unload-module \"$m\" >/dev/null 2>&1; done\n" +
      "  MIXMOD=\"\"; LBOUT=\"\"; LBMIC=\"\"\n" +
      "}\n" +
      "trap 'mix_down' EXIT\n" +
      "trap 'STOPREQ=1' TERM HUP\n" +
      "start_gsr() {\n" +
      "  if [ -n \"$GEOM\" ]; then A=(-w region -region \"$GEOM\" -f \"$FPS\" -o \"$OUT\")\n" +
      "  else A=(-w \"${MON:-screen}\" -f \"$FPS\" -o \"$OUT\"); fi\n" +
      "  [ -n \"$TH\" ] && A+=(-s \"${TW}x${TH}\")\n" +
      "  # desktop audio always; the mic goes on the same track (muted when it's off)\n" +
      "  if [ -n \"$MIXMOD\" ]; then A+=(-a qs_rec_mix.monitor)\n" +
      "  elif [ \"$MIC\" = 1 ]; then A+=(-a \"default_output|default_input\")\n" +
      "  else A+=(-a default_output); fi\n" +
      "  gpu-screen-recorder \"${A[@]}\" </dev/null >>\"$LOG\" 2>&1 &\n" +
      "  PID=$!\n" +
      "}\n" +
      "start_seg() {\n" +
      "  N=$((N+1))\n" +
      "  A=(-y -f \"$SEGDIR/seg$N.mp4\" -r \"$FPS\")\n" +
      "  if [ -n \"$GEOM\" ]; then A+=(-g \"$RX,$RY ${RW}x${RH}\")\n" +
      "  elif [ -n \"$MON\" ]; then A+=(-o \"$MON\"); fi\n" +
      "  [ -n \"$TH\" ] && A+=(-F \"scale=${TW}:${TH}\")\n" +
      "  if [ -n \"$MIXMOD\" ]; then A+=(--audio=qs_rec_mix.monitor)\n" +
      "  elif [ $HASPA = 1 ]; then A+=(--audio=\"$(pactl get-default-sink 2>/dev/null).monitor\")\n" +
      "  elif [ \"$MIC\" = 1 ]; then A+=(-a); fi\n" +
      "  wf-recorder \"${A[@]}\" </dev/null >>\"$LOG\" 2>&1 &\n" +
      "  PID=$!\n" +
      "}\n" +
      "stop_child() {\n" +
      "  if [ -n \"$PID\" ]; then kill -INT \"$PID\" 2>/dev/null; wait \"$PID\" 2>/dev/null; fi\n" +
      "  PID=\"\"\n" +
      "}\n" +
      "mix_up\n" +
      "if [ \"$MODE\" = gsr ]; then start_gsr; else SEGDIR=$(mktemp -d /tmp/qs-rec.XXXXXX); start_seg; fi; apply_mic\n" +
      "sleep 0.6\n" +
      "if ! kill -0 \"$PID\" 2>/dev/null; then echo \"ERR:start\"; rm -rf \"$SEGDIR\" 2>/dev/null; exit 1; fi\n" +
      "echo \"MODE:$MODE\"\n" +
      "echo \"STATE:recording\"\n" +
      "echo \"MICCTL:$HASPA\"\n" +
      "echo \"MIC:$MIC\"\n" +
      "PAUSED=0\n" +
      "while true; do\n" +
      "  [ $STOPREQ -eq 1 ] && break\n" +
      "  read -r -t 1 CMD; RC=$?\n" +
      "  [ $STOPREQ -eq 1 ] && break\n" +
      "  if [ $RC -gt 128 ]; then\n" +
      "    if [ $PAUSED -eq 0 ] && ! kill -0 \"$PID\" 2>/dev/null; then PID=\"\"; break; fi\n" +
      "    continue\n" +
      "  fi\n" +
      "  [ $RC -ne 0 ] && CMD=stop\n" +
      "  case \"$CMD\" in\n" +
      "    pause)\n" +
      "      if [ \"$MODE\" = gsr ]; then kill -USR2 \"$PID\" 2>/dev/null\n" +
      "      elif [ $PAUSED -eq 0 ]; then stop_child\n" +
      "      else start_seg; apply_mic; fi\n" +
      "      if [ $PAUSED -eq 0 ]; then PAUSED=1; echo \"STATE:paused\"; else PAUSED=0; echo \"STATE:resumed\"; fi ;;\n" +
      "    mic*) MIC=${CMD#mic}; MIC=${MIC// /}; [ \"$MIC\" = 1 ] || MIC=0; apply_mic; echo \"MIC:$MIC\" ;;\n" +
      "    stop) break ;;\n" +
      "  esac\n" +
      "done\n" +
      "echo \"STATE:saving\"\n" +
      "stop_child\n" +
      "mix_down\n" +
      "if [ \"$MODE\" = wf ]; then\n" +
      "  LIST=\"$SEGDIR/list.txt\"; : > \"$LIST\"; C=0; LAST=\"\"\n" +
      "  for i in $(seq 1 $N); do\n" +
      "    F=\"$SEGDIR/seg$i.mp4\"\n" +
      "    if [ -s \"$F\" ]; then echo \"file '$F'\" >> \"$LIST\"; C=$((C+1)); LAST=\"$F\"; fi\n" +
      "  done\n" +
      "  if [ $C -eq 1 ]; then mv \"$LAST\" \"$OUT\"\n" +
      "  elif [ $C -gt 1 ]; then ffmpeg -nostdin -y -loglevel error -f concat -safe 0 -i \"$LIST\" -c copy \"$OUT\" >>\"$LOG\" 2>&1; fi\n" +
      "  rm -rf \"$SEGDIR\"\n" +
      "fi\n" +
      "if [ -s \"$OUT\" ]; then echo \"SAVED:$OUT\"; else echo \"ERR:empty\"; fi\n"

    Timer {
        id: recStartDelay
        interval: 450; repeat: false
        onTriggered: {
            if (globalState.recRegion) globalState.recRegionPicking = true;
            else recLaunch("");
        }
    }

    function recLaunch(geom) {
      recProcess.command = ["bash", "-c", recScript, "qs-rec", String(globalState.recFps), globalState.recResolution, globalState.recMic ? "1" : "0", geom || ""];
      recProcess.stdinEnabled = true;
      recProcess.running = true;
    }

    Timer {
        id: recRegionLaunchDelay
        property string geom: ""
        interval: 180; repeat: false
        onTriggered: { if (globalState.recStarting) recLaunch(geom); }
    }

    Process {
        id: recProcess
        running: false
        stdinEnabled: true
        command: ["true"]
        stdout: SplitParser { onRead: (line) => handleRecLine(line) }
        onRunningChanged: {
            if (running) return;
            globalState.recStarting   = false;
            globalState.recActive     = false;
            globalState.recPaused     = false;
            globalState.recSaving     = false;
            globalState.recBulgeOpen  = false;
            globalState.recMicLive    = false;
            globalState.recMicCtl     = false;
            globalState.recOrigin     = "";
            globalState.recAccumMs    = 0;
            globalState.recSegStartMs = 0;
        }
    }

    function handleRecLine(line) {
        var i = line.indexOf(":");
        if (i < 0) return;
        var k = line.substring(0, i), v = line.substring(i + 1).trim();
        if (k === "MODE") globalState.recBackend = v;
        else if (k === "MIC") globalState.recMicLive = v === "1";
        else if (k === "MICCTL") globalState.recMicCtl = v === "1";
        else if (k === "STATE") _recStateChanged(v, Date.now());
        else if (k === "SAVED") _recSaved(v);
        else if (k === "ERR") _recError(v);
    }

    function _recStateChanged(v, now) {
        var g = globalState;
        if (v === "recording") {
            g.recStarting = false; g.recActive = true; g.recPaused = false;
            g.recAccumMs = 0; g.recSegStartMs = now; g.recNowMs = now;
            if (g.recNotchAllowed) { g.closeOthers("rec"); g.recBulgeOpen = true; }
        } else if (v === "paused") {
            g.recAccumMs += now - g.recSegStartMs;
            g.recPaused = true;
        } else if (v === "resumed") {
            g.recSegStartMs = now; g.recNowMs = now; g.recPaused = false;
        } else if (v === "saving") {
            if (!g.recPaused && g.recSegStartMs > 0) g.recAccumMs += now - g.recSegStartMs;
            g.recSegStartMs = 0;
            g.recSaving = true;
        }
    }

    function _recSaved(v) {
        globalState.recLastFile = v;
        Quickshell.execDetached(["notify-send", "-a", tr("screen_record"), "-i", "video-x-generic", tr("rec_saved"), v]);
    }

    function _recError(v) {
        var msg = v === "nobin" ? tr("rec_err_nobin") : v === "empty" ? tr("rec_err_empty") : tr("rec_err_start");
        console.warn("[screenrec] error:", v, "(log en ~/.cache/qs-screenrec.log)");
        Quickshell.execDetached(["notify-send", "-a", tr("screen_record"), "-u", "critical", tr("screen_record"), msg]);
    }

    Process {
        id: recDetectProcess
        running: false
        command: ["bash", "-c", "if command -v gpu-screen-recorder >/dev/null 2>&1; then echo gsr; elif command -v wf-recorder >/dev/null 2>&1; then echo wf; else echo none; fi"]
        stdout: SplitParser { onRead: (line) => { var t = line.trim(); if (t) globalState.recBackendAvail = t; } }
    }

    ScreenshotBackend {
        id: screenshotBackend
    }

    Connections {
        target: globalState
        function onSelectCaptureTriggerChanged() { globalState.shotStart(); }
    }

    function setRecFps(v) {
      if (globalState.recFps === v) return;
      globalState.recFps = v;
      savePrefs();
    }

    function setRecResolution(v) {
      if (globalState.recResolution === v) return;
      globalState.recResolution = v;
      savePrefs();
    }

    function setRecRegion(on) {
      if (globalState.recRegion === !!on) return;
      globalState.recRegion = !!on;
      savePrefs();
    }

    function setRecMic(on) {
      if (globalState.recMic === !!on) return;
      globalState.recMic = !!on;
      savePrefs();
    }

    function setGamingFloatOpacity(v) {
      v = Math.round(Math.max(0.1, Math.min(1, v)) * 100) / 100;
      if (globalState.gamingFloatOpacity === v) return;
      globalState.gamingFloatOpacity = v;
      savePrefs();
    }

    function setGamingEscOnOpen(on) {
      if (globalState.gamingEscOnOpen === !!on) return;
      globalState.gamingEscOnOpen = !!on;
      savePrefs();
    }

    function setGamingModule(k, on) {
      var o = Object.assign({}, globalState.gamingModules);
      if (o[k] === !!on) return;
      o[k] = !!on;
      globalState.gamingModules = o;
      savePrefs();
    }

    function openRecFolder() {
      Quickshell.execDetached(["bash", "-c",
        "d=$(xdg-user-dir VIDEOS 2>/dev/null); [ -d \"$d\" ] || d=\"$HOME/Videos\"; mkdir -p \"$d/Recordings\"; xdg-open \"$d/Recordings\""]);
    }
}
