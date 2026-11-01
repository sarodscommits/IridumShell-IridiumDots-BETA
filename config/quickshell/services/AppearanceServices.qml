import QtQuick
import Quickshell
import Quickshell.Io

// Appearance setters and Hyprland appearance apply
ProfileServices {
    property alias appearanceApplyProcess: appearanceApplyProcess
    property alias shellShadowEditHoldTimer: shellShadowEditHoldTimer

    Process {
        id: uiClickPrepProc
        running: true
        command: ["bash", "-c",
            "DIR=\"$1\"; [ -d \"$DIR\" ] || exit 0\n" +
            "command -v pw-play >/dev/null 2>&1 && command -v ffmpeg >/dev/null 2>&1 || exit 0\n" +
            "D=\"${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/ui-sounds\"; mkdir -p \"$D\"\n" +
            "for SRC in \"$DIR\"/*.mp3; do\n" +
            "  [ -f \"$SRC\" ] || continue\n" +
            "  N=$(basename \"${SRC%.*}\"); OUT=\"$D/$N.wav\"\n" +
            "  if [ ! -s \"$OUT\" ] || [ \"$SRC\" -nt \"$OUT\" ]; then\n" +
            "    ffmpeg -nostdin -loglevel error -y -i \"$SRC\" -af 'adelay=25:all=1,apad=pad_dur=0.15' -ar 48000 -ac 2 \"$OUT\" || continue\n" +
            "  fi\n" +
            "  echo \"$N=$OUT\"\n" +
            "done\n",
            "qs-uisounds", globalState.uiSoundsDir]
        stdout: SplitParser {
            onRead: (l) => {
                var t = l.trim(), k = t.indexOf("=");
                if (k <= 0) return;
                var m = Object.assign({}, globalState.uiSoundWavs);
                m[t.slice(0, k)] = t.slice(k + 1);
                globalState.uiSoundWavs = m;
            }
        }
    }

    function setTopBarPosition(pos) {
        if (["top", "bottom", "left", "right"].indexOf(pos) < 0) return;
        if (globalState.topBarPosition === pos) return;
        globalState.closeAll(true);
        globalState.topBarPosition = pos;
        savePrefs();
    }

    function setShellMode(mode) {
        if (mode !== "island" && mode !== "notch") return;
        if (globalState.shellMode === mode) return;
        globalState.closeAll(true);
        globalState.shellMode = mode;
        savePrefs();
    }

    function setFont(which, key) {
        if (!globalState.fontResolved[key]) return;
        if (which === "primary") globalState.fontPrimaryKey = key;
        else globalState.fontSecondaryKey = key;
        savePrefs();
    }

    function setFontScale(v) {
        v = Math.max(0.8, Math.min(1.3, Math.round(v * 20) / 20));
        globalState.fontScale = v;
    }

    function setClockFormat24h(enabled) {
        if (globalState.clockFormat24h === enabled) return;
        globalState.clockFormat24h = enabled;
        savePrefs();
    }

    function setBorderSize(v) {
        v = Math.max(0, Math.min(10, Math.round(v)));
        globalState.borderSize = v;
        appearanceApplyDebounce.restart();
    }

    function setShadowEnabled(on) {
        globalState.shadowEnabled = !!on;
        appearanceApplyDebounce.restart();
    }

    function setShadowRange(v) {
        v = Math.max(10, Math.min(60, Math.round(v)));
        globalState.shadowRange = v;
        appearanceApplyDebounce.restart();
    }

    function setShadowIntensity(v) {
        v = Math.max(20, Math.min(100, Math.round(v)));
        globalState.shadowIntensity = v;
        appearanceApplyDebounce.restart();
    }

    function setShellShadowFlag(key, on) {
        if (globalState[key] === !!on) return;
        globalState[key] = !!on;
        savePrefs();
    }

    function setShellShadowRange(v) {
        v = Math.max(10, Math.min(60, Math.round(v)));
        if (globalState.shellShadowRange === v) return;
        globalState.shellShadowRange = v;
        shellShadowSaveDebounce.restart();
    }

    function setShellShadowIntensity(v) {
        v = Math.max(10, Math.min(100, Math.round(v / 5) * 5));
        if (globalState.shellShadowIntensity === v) return;
        globalState.shellShadowIntensity = v;
        shellShadowSaveDebounce.restart();
    }

    Timer { id: shellShadowSaveDebounce; interval: 300; repeat: false; onTriggered: savePrefs() }
    Timer { id: shellShadowEditHoldTimer; interval: 500; repeat: false; onTriggered: globalState.shellShadowEditHold = false }

    function setCornerRounding(v) {
        v = Math.max(0, Math.min(20, Math.round(v / 2) * 2));
        globalState.cornerRounding = v;
        appearanceApplyDebounce.restart();
    }

    function setLayoutMode(mode) {
        if (mode !== "dwindle" && mode !== "master") return;
        if (globalState.layoutMode === mode) return;
        globalState.layoutMode = mode;
        savePrefs();
        appearanceApplyProcess.queue(globalState.borderSize, globalState.shadowEnabled, globalState.shadowRange, globalState.shadowIntensity, currentKittyOpacity(), globalState.cornerRounding, globalState.layoutMode, globalState.allFloating, false);
    }

    function setAllFloating(enabled) {
        enabled = !!enabled;
        if (globalState.allFloating === enabled) return;
        globalState.allFloating = enabled;
        savePrefs();
        appearanceApplyProcess.queue(globalState.borderSize, globalState.shadowEnabled, globalState.shadowRange, globalState.shadowIntensity, currentKittyOpacity(), globalState.cornerRounding, globalState.layoutMode, globalState.allFloating, false);
    }

    function currentKittyOpacity() {
        return (globalState.glassMode && globalState.glassKittyEnabled) ? globalState.kittyGlassOpacity : 1.0;
    }

    function currentFrameOpacity() {
        return (globalState.glassMode && globalState.glassQuickshellEnabled) ? globalState.glassQuickshellOpacity : 1.0;
    }

    function setGlassQuickshellEnabled(enabled) {
        if (globalState.glassQuickshellEnabled === enabled) return;
        globalState.glassQuickshellEnabled = enabled;
        savePrefs();
    }

    function setGlassKittyEnabled(enabled) {
        if (globalState.glassKittyEnabled === enabled) return;
        globalState.glassKittyEnabled = enabled;
        savePrefs();
        appearanceApplyProcess.queue(globalState.borderSize, globalState.shadowEnabled, globalState.shadowRange, globalState.shadowIntensity, currentKittyOpacity(), globalState.cornerRounding, globalState.layoutMode, globalState.allFloating, true);
    }

    function setGlassQuickshellOpacity(v) {
        v = Math.max(0.35, Math.min(0.75, v));
        if (globalState.glassQuickshellOpacity === v) return;
        globalState.glassQuickshellOpacity = v;
        savePrefs();
    }

    Timer {
        id: appearanceApplyDebounce
        interval: 150
        repeat: false
        onTriggered: {
            savePrefs();
            appearanceApplyProcess.queue(globalState.borderSize, globalState.shadowEnabled, globalState.shadowRange, globalState.shadowIntensity, currentKittyOpacity(), globalState.cornerRounding, globalState.layoutMode, globalState.allFloating, false);
        }
    }

    Process {
        id: appearanceApplyProcess
        running: false
        stdinEnabled: true
        property bool   _busy:    false
        property string _pending: ""

        function queue(border, shadowOn, range, intensity, kittyOp, rounding, layout, allFloat, doReload) {
            var payload = border + " " + (shadowOn ? "1" : "0") + " " + range + " " + intensity + " " + kittyOp + " " + rounding + " " + layout + " " + (allFloat ? "1" : "0") + " " + (doReload ? "1" : "0");
            if (appearanceApplyProcess._busy) {
                appearanceApplyProcess._pending = payload;
                return;
            }
            appearanceApplyProcess._run(payload);
        }

        function _run(payload) {
            appearanceApplyProcess._busy = true;
            appearanceApplyProcess.running = true;
            appearanceApplyProcess.write(payload + "\n");
            appearanceApplyProcess.stdinEnabled = false;
        }

        command: ["bash", "-c",
        "read -r BORDER SHADOWON RANGE INTENSITY KITTYOP ROUNDING LAYOUT ALLFLOAT DORELOAD\n" +
        "SHADOWBOOL=$( [ \"$SHADOWON\" = \"1\" ] && echo true || echo false )\n" +
        "ALLFLOATBOOL=$( [ \"$ALLFLOAT\" = \"1\" ] && echo true || echo false )\n" +
        "ALPHA_DEC=$(( INTENSITY * 255 / 100 ))\n" +
        "ALPHA_HEX=$(printf '%02x' \"$ALPHA_DEC\")\n" +
        "SHADOWCOLOR=\"rgba(000000${ALPHA_HEX})\"\n" +
        "hyprctl eval \"hl.config({ general = { border_size = ${BORDER} }, decoration = { rounding = ${ROUNDING}, shadow = { enabled = ${SHADOWBOOL}, range = ${RANGE}, color = '${SHADOWCOLOR}' } } })\" >/dev/null 2>&1\n" +
        "hyprctl keyword general:border_size \"$BORDER\" >/dev/null 2>&1\n" +
        "hyprctl keyword decoration:rounding \"$ROUNDING\" >/dev/null 2>&1\n" +
        "hyprctl keyword decoration:shadow:enabled \"$SHADOWBOOL\" >/dev/null 2>&1\n" +
        "hyprctl keyword decoration:shadow:range \"$RANGE\" >/dev/null 2>&1\n" +
        "hyprctl keyword decoration:shadow:color \"$SHADOWCOLOR\" >/dev/null 2>&1\n" +
        "hyprctl eval \"hl.config({ general = { layout = '${LAYOUT}' } })\" >/dev/null 2>&1\n" +
        "hyprctl keyword general:layout \"$LAYOUT\" >/dev/null 2>&1\n" +
        "hyprctl eval \"hl.window_rule({ name = \\\"todas-flotantes\\\", match = { class = \\\".*\\\" }, float = ${ALLFLOATBOOL} })\" >/dev/null 2>&1\n" +
        "hyprctl eval \"hl.window_rule({ name = \\\"kitty-transparency\\\", match = { class = \\\"kitty\\\" }, opacity = ${KITTYOP} })\" >/dev/null 2>&1\n" +
        "hyprctl keyword windowrulev2 \"opacity ${KITTYOP} override,class:^(kitty)$\" >/dev/null 2>&1\n" +
        "mkdir -p \"$HOME/.config/hypr\"\n" +
        "cat > \"$HOME/.config/hypr/appearance.lua\" <<LUAEOF\n" +
        "-- Generated automatically by Quickshell (Settings > Appearance).\n" +
        "-- Don't edit by hand: it's overwritten every time you change the border\n" +
        "-- size, the shadows, kitty's transparency (via glass mode), the\n" +
        "-- tiling layout (dwindle/master), or whether new windows open\n" +
        "-- floating by default, from the shell. hyprland.lua loads it with\n" +
        "-- dofile() at startup (see\n" +
        "-- appearance_ok/appearance en hyprland.lua).\n" +
        "return {\n" +
        "    border_size         = ${BORDER},\n" +
        "    shadow_enabled      = ${SHADOWBOOL},\n" +
        "    shadow_range        = ${RANGE},\n" +
        "    shadow_intensity    = ${INTENSITY},\n" +
        "    kitty_opacity       = ${KITTYOP},\n" +
        "    rounding            = ${ROUNDING},\n" +
        "    layout              = '${LAYOUT}',\n" +
        "    all_floating        = ${ALLFLOATBOOL},\n" +
        "}\n" +
        "LUAEOF\n" +
        "if [ \"$DORELOAD\" = \"1\" ]; then\n" +
        "  hyprctl reload >/dev/null 2>&1\n" +
        "fi\n"
        ]
        onRunningChanged: {
            if (!running) {
                appearanceApplyProcess._busy = false;
                appearanceApplyProcess.stdinEnabled = true;
                if (appearanceApplyProcess._pending !== "") {
                    var p = appearanceApplyProcess._pending;
                    appearanceApplyProcess._pending = "";
                    appearanceApplyProcess._run(p);
                }
            }
        }
    }

    function setBarModuleVisible(key, enabled) {
        if (!(key in globalState.barModules)) return;
        if (globalState.barModules[key] === enabled) return;
        var bm = Object.assign({}, globalState.barModules);
        bm[key] = enabled;
        globalState.barModules = bm;
        if (!enabled) {
            if (key === "search"  && globalState.islandSearchOpen) globalState.islandSearchOpen = false;
            if (key === "clipboard") globalState.clipBulgeOpen = false;
            if (key === "privacy")   globalState.privBulgeOpen = false;
            if (key === "battery")   globalState.battBulgeOpen = false;
        }
        savePrefs();
    }

    function isClsPinned(cls) {
        if (!cls) return false;
        return globalState.pinnedApps.indexOf(cls) !== -1;
    }

    function toggleClsPinned(cls) {
        if (!cls) return;
        var arr = globalState.pinnedApps.slice();
        var idx = arr.indexOf(cls);
        if (idx === -1) arr.push(cls);
        else arr.splice(idx, 1);
        globalState.pinnedApps = arr;
        savePrefs();
    }
}
