import QtQuick
import Quickshell
import Quickshell.Io

// Terminal palette and accent sync scripts (pywal / matugen)
PresetPaletteServices {
    function buildAccentSyncSnippet() {
        var light = globalState.colorMode === "light";
        var presetBorder = globalState.paletteSource === "preset";
        var presetCava = globalState.paletteSource === "preset" && globalState.presetApplyKitty;
        var out = "bcol=\"\"; c1=\"\"; c2=\"\"; c3=\"\"; c0=\"\"\n";
        if (presetBorder) out += "bcol=\"" + String(presetRoles.primary).replace("#", "").toLowerCase() + "\"\n";
        if (presetCava) out += _presetCavaVars(light);
        if (!presetBorder || !presetCava) out += _pywalAccentBash(light, presetBorder, presetCava);
        if (!presetCava && globalState.termPaletteMode !== "pywal") out += _termCavaBash();
        return out + "bash \"" + scriptsDir + "/accent_apply.sh\" \"$bcol\" \"$c1\" \"$c2\" \"$c3\" \"$c0\"\n";
    }

    function _presetCavaVars(light) {
        var st = presetKittyStops();
        var pc = light ? [st[1], st[4], st[8], st[13]] : [st[13], st[9], st[4], st[0]];
        return "c1='" + pc[0] + "'; c2='" + pc[1] + "'; c3='" + pc[2] + "'; c0='" + pc[3] + "'\n";
    }

    function _pywalAccentBash(light, presetBorder, presetCava) {
        return "if [ -f \"$HOME/.cache/wal/colors.json\" ]; then\n" +
            "PYOUT=$(python3 \"" + scriptsDir + "/accent_sync.py\" " + (light ? "light" : "dark") + " " + (presetBorder ? "0" : "1") + " " + (presetCava ? "0" : "1") + " 2>/dev/null)\n" +
            (presetBorder ? "" : "  bcol=$(printf '%s\\n' \"$PYOUT\" | sed -n 's/^BORDER //p')\n") +
            (presetCava ? "" :
            "  set -- $(printf '%s\\n' \"$PYOUT\" | sed -n 's/^CAVA //p')\n" +
            "  c1=\"$1\"; c2=\"$2\"; c3=\"$3\"; c0=\"$4\"\n") +
            "fi\n";
    }

    function _termCavaBash() {
        return "if [ -s \"$HOME/.cache/wal/term-cava.txt\" ]; then\n" +
            "  set -- $(cat \"$HOME/.cache/wal/term-cava.txt\")\n" +
            "  [ -n \"$4\" ] && { c1=\"$1\"; c2=\"$2\"; c3=\"$3\"; c0=\"$4\"; }\n" +
            "fi\n";
    }

    function buildPywalTermSnippet() {
        var mode = globalState.colorMode === "light" ? "light" : "dark";
        return "if [ -f \"$HOME/.cache/wal/colors.json\" ] || [ -f \"$HOME/.config/matugen/colors.json\" ]; then\n" +
            "python3 \"" + scriptsDir + "/pywal_term.py\" " + mode + " " + globalState.termPaletteMode + "\n" +
            kittyReloadBash + "fi\n";
    }

    function restorePywalKittyColors() {
        var script =
        "#!/bin/bash\n" +
        "STILL_FILE=\"$HOME/.cache/wallpaper-selector/current-still.txt\"\n" +
        "if [ -f \"$STILL_FILE\" ] && command -v wal >/dev/null 2>&1; then\n" +
        "  STILL=$(cat \"$STILL_FILE\")\n" +
        "  [ -f \"$STILL\" ] && wal -i \"$STILL\" -n -q\n" +
        "fi\n" +
        buildPywalTermSnippet() +
        buildAccentSyncSnippet();
        wpScriptSaver._doSave(script);
    }

    function restoreMatugenColors() {
        var script =
        "#!/bin/bash\n" +
        "STILL_FILE=\"$HOME/.cache/wallpaper-selector/current-still.txt\"\n" +
        "if [ -f \"$STILL_FILE\" ] && command -v matugen >/dev/null 2>&1; then\n" +
        "  STILL=$(cat \"$STILL_FILE\")\n" +
        "  if [ -f \"$STILL\" ]; then\n" +
        "    COL_JSON=\"$HOME/.config/matugen/colors.json\"\n" +
        "    matugen image \"$STILL\" --source-color-index 1 --type scheme-fidelity --fallback-color '#888888' -j hex > \"$COL_JSON\" 2>/dev/null || " +
        "matugen image \"$STILL\" --source-color-index 0 --type scheme-fidelity --fallback-color '#888888' -j hex > \"$COL_JSON\"\n" +
        "    matugen image \"$STILL\" --source-color-index 1 --type scheme-fidelity --fallback-color '#888888' >/dev/null 2>&1 || " +
        "matugen image \"$STILL\" --source-color-index 0 --type scheme-fidelity --fallback-color '#888888' >/dev/null 2>&1\n" +
        "  fi\n" +
        "fi\n";
        wpScriptSaver._doSave(script);
    }
}
