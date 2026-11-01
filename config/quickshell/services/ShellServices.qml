import QtQuick
import Quickshell
import Quickshell.Io

// Root of the shell services chain: color mode, palette source and M3 setters
TerminalPaletteServices {
    function icEqRep() { return (typeof islandControlLoader !== "undefined" && islandControlLoader.item) ? islandControlLoader.item.eqRepeater : null; }
    function ncEqRep() { return (typeof notchControlLoader !== "undefined" && notchControlLoader.item) ? notchControlLoader.item.eqRepeater : null; }

    function setGlassMode(enabled) {
        if (globalState.glassMode === enabled) return;
        globalState.glassMode = enabled;
        savePrefs();
        appearanceApplyProcess.queue(globalState.borderSize, globalState.shadowEnabled, globalState.shadowRange, globalState.shadowIntensity, currentKittyOpacity(), globalState.cornerRounding, globalState.layoutMode, globalState.allFloating, true);
    }

    function setPresetApplyQuickshell(enabled) {
        if (globalState.presetApplyQuickshell === enabled) return;
        globalState.presetApplyQuickshell = enabled;
        savePrefs();
        if (globalState.paletteSource === "preset" && !enabled) restoreMatugenColors();
    }

    function setTermPaletteMode(m) {
        if (["pywal", "matugen", "matugen_bg"].indexOf(m) < 0) return;
        if (globalState.termPaletteMode === m) return;
        globalState.termPaletteMode = m;
        savePrefs();
        if (globalState.paletteSource === "preset" && globalState.presetApplyKitty) return;
        wpScriptSaver._doSave("#!/bin/bash\n" + buildPywalTermSnippet() + buildAccentSyncSnippet());
        termColorsReloadTimer.kick();
    }

    function setPresetApplyKitty(enabled) {
        if (globalState.presetApplyKitty === enabled) return;
        globalState.presetApplyKitty = enabled;
        savePrefs();
        if (globalState.paletteSource !== "preset") return;
        if (enabled) applyPresetKittyColors();
        else restorePywalKittyColors();
    }

    function setM3(key, value) {
        if (globalState[key] === value) return;
        globalState[key] = value;
        savePrefs();
    }

    function resetM3(keys) {
        var d = { motionScheme: "expressive", m3Speed: 1.0, m3Bounce: 1.0, m3AccentShape: "Cookie9Sided", m3CornerScale: 1.0,
            m3SwitchIcons: true, m3Wavy: true, m3ProgressThickness: 4, m3SliderScale: 1.0, m3Emphasis: true };
        for (var i = 0; i < keys.length; i++) if (d[keys[i]] !== undefined) globalState[keys[i]] = d[keys[i]];
        savePrefs();
    }

    function setMotionScheme(scheme) {
        if (scheme !== "expressive" && scheme !== "standard") return;
        if (globalState.motionScheme === scheme) return;
        globalState.motionScheme = scheme;
        savePrefs();
    }

    function setPaletteSource(source) {
        if (source !== "matugen" && source !== "preset") return;
        if (globalState.paletteSource === source) return;
        globalState.paletteSource = source;
        savePrefs();
        if (source === "preset") {
            if (globalState.presetApplyKitty) applyPresetKittyColors();
            else restorePywalKittyColors();
        }
        else restorePywalKittyColors();
    }

    function setPresetPalette(key) {
        if (globalState.presetPaletteKey !== key) {
            globalState.presetPaletteKey = key;
            savePrefs();
        }
        if (globalState.paletteSource === "preset") { applyPresetKittyColors(); }
    }

    function setColorMode(mode) {
        if (globalState.colorMode === mode) return;
        globalState.colorMode = mode;
        savePrefs();
        colorExtraction.reload();
        var presetKitty = globalState.paletteSource === "preset" && globalState.presetApplyKitty;
        var script = "#!/bin/bash\n" +
        (presetKitty ? buildPresetKittyApplyBash() : buildPywalTermSnippet()) +
        buildAccentSyncSnippet();
        wpScriptSaver._doSave(script);
    }
}
