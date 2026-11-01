import QtQuick
import Quickshell
import Quickshell.Io
import "prefs-rules.js" as PrefsRules

// prefs.json load/save and rule-based validation
DesktopSettingsServices {
    Process {
        id: prefsLoader
        command: ["bash", "-c",
        "f=\"$HOME/.config/quickshell/prefs.json\"; [ -f \"$f\" ] || exit 0; cat \"$f\""
        ]
        running: true
        property string _buf: ""
        stdout: SplitParser { onRead: (line) => { prefsLoader._buf += line; } }
        onRunningChanged: {
            if (!running) {
                var raw = prefsLoader._buf.trim();
                prefsLoader._buf = "";
                profileLoader.running = true;
                Qt.callLater(syncCanvasInvertFile);
                if (!raw) return;
                try {
                    var pd = JSON.parse(raw);
                    applyPrefsData(pd);
                    if (Array.isArray(pd.ncCcRows)) {
                        var seenK = Array.isArray(pd.ncCcKeysSeen) ? pd.ncCcKeysSeen
                        : ["bright", "vol", "mic", "wifi", "bt", "dark", "dnd", "term", "shot"];
                        globalState.ncCcKeys.forEach(function (k) { if (seenK.indexOf(k) === -1) globalState.ncCcAdd(k); });
                    }
                } catch (e) {}
            }
        }
    }

    function applyPrefsData(data) {
        if (!data || typeof data !== "object") return;
        _applyPrefRules(data, PrefsRules.general);
        if (typeof data.islandAutoHide === "boolean") {
            globalState.islandAutoHide = data.islandAutoHide;
            globalState.islandAutoHideRevealed = !data.islandAutoHide;
        }
        globalState.shellMode = (data.shellMode === "notch") ? "notch" : "island";
        _applyPrefRules(data, PrefsRules.appearance);
        _applyLayoutPrefs(data);
        _applyPrefRules(data, PrefsRules.desktop);
        _mergeBoolPrefs(data, "gamingModules");
        _applyPrefRules(data, PrefsRules.session);
        for (var mgK in magnetLimits) {
            if (typeof data[mgK] === "number") globalState[mgK] = Math.round(Math.max(magnetLimits[mgK][0], Math.min(magnetLimits[mgK][1], data[mgK])));
        }
    }

    function _applyPrefRules(data, rules) {
        rules.forEach(function (r) {
            if (r[1] === "iffalse") { if (data[r[0]] === false) globalState[r[2]] = r[3]; return; }
            var v = PrefsRules.value(data[r[0]], r);
            if (v !== undefined) globalState[r[0]] = v;
        });
    }

    function _mergeBoolPrefs(data, key) {
        if (!data[key] || typeof data[key] !== "object") return;
        var merged = Object.assign({}, globalState[key]);
        for (var k in merged) if (typeof data[key][k] === "boolean") merged[k] = data[key][k];
        globalState[key] = merged;
    }

    function _applyLayoutPrefs(data) {
        _mergeBoolPrefs(data, "barModules");
        if (Array.isArray(data.barLayoutIsland)) globalState.barLayoutIsland = data.barLayoutIsland;
        if (data.barLayoutNotch && typeof data.barLayoutNotch === "object") globalState.barLayoutNotch = data.barLayoutNotch;
        globalState.sanitizeBarLayouts();
        if (Array.isArray(data.ncCcRows))    globalState.ncCcRows    = data.ncCcRows;
        if (Array.isArray(data.ncDashOrder)) globalState.ncDashOrder = data.ncDashOrder;
        if (Array.isArray(data.ncCcRows) || Array.isArray(data.ncDashOrder)) globalState.sanitizeNcLayout();
        if (Array.isArray(data.pinnedApps)) globalState.pinnedApps = data.pinnedApps.filter(function (c) { return typeof c === "string"; });
    }

    Process {
        id: prefsSaver
        command: ["bash", "-c",
        "mkdir -p \"$HOME/.config/quickshell\" && cat > \"$HOME/.config/quickshell/prefs.json\""
        ]
        running: false
        stdinEnabled: true
        property bool _busy: false
        property string _pending: ""
        onRunningChanged: {
            if (!running) {
                prefsSaver._busy = false;
                prefsSaver.stdinEnabled = true;
                if (prefsSaver._pending !== "") {
                    var p = prefsSaver._pending;
                    prefsSaver._pending = "";
                    prefsSaver._doSave(p);
                }
            }
        }
        function _doSave(json) {
            if (prefsSaver._busy) { prefsSaver._pending = json; return; }
            prefsSaver._busy = true;
            prefsSaver.running = true;
            prefsSaver.write(json);
            prefsSaver.stdinEnabled = false;
        }
    }

    function collectPrefs() {
        return ({ language: globalState.language, colorMode: globalState.colorMode, motionScheme: globalState.motionScheme, m3Speed: globalState.m3Speed, m3Bounce: globalState.m3Bounce, m3AccentShape: globalState.m3AccentShape, m3CornerScale: globalState.m3CornerScale, m3SwitchIcons: globalState.m3SwitchIcons, m3Wavy: globalState.m3Wavy, m3ProgressThickness: globalState.m3ProgressThickness, m3SliderScale: globalState.m3SliderScale, m3Emphasis: globalState.m3Emphasis, paletteSource: globalState.paletteSource, presetPaletteKey: globalState.presetPaletteKey, presetApplyQuickshell: globalState.presetApplyQuickshell, presetApplyKitty: globalState.presetApplyKitty, termPaletteMode: globalState.termPaletteMode, glassMode: globalState.glassMode, glassQuickshellEnabled: globalState.glassQuickshellEnabled, glassKittyEnabled: globalState.glassKittyEnabled, glassQuickshellOpacity: globalState.glassQuickshellOpacity, topBarPosition: globalState.topBarPosition, islandAutoHide: globalState.islandAutoHide, barModules: globalState.barModules, pinnedApps: globalState.pinnedApps, borderSize: globalState.borderSize, shadowEnabled: globalState.shadowEnabled, shadowRange: globalState.shadowRange, shadowIntensity: globalState.shadowIntensity, shellShadowEnabled: globalState.shellShadowEnabled, shellShadowIsland: globalState.shellShadowIsland, shellShadowNotch: globalState.shellShadowNotch, shellShadowPanels: globalState.shellShadowPanels, shellShadowWidgets: globalState.shellShadowWidgets, shellShadowNotifs: globalState.shellShadowNotifs, shellShadowGaming: globalState.shellShadowGaming, shellShadowLock: globalState.shellShadowLock, shellShadowRange: globalState.shellShadowRange, shellShadowIntensity: globalState.shellShadowIntensity, cornerRounding: globalState.cornerRounding, layoutMode: globalState.layoutMode, allFloating: globalState.allFloating, shellMode: globalState.shellMode, clockFormat24h: globalState.clockFormat24h, notificationSoundPath: globalState.notificationSoundPath, notificationSoundVolume: globalState.notificationSoundVolume, wallpaperFpsLimit: globalState.wallpaperFpsLimit, musicWidgetX: globalState.musicWidgetX, musicWidgetY: globalState.musicWidgetY, weatherWidgetX: globalState.weatherWidgetX, weatherWidgetY: globalState.weatherWidgetY, clockWidgetXDesktop: globalState.clockWidgetXDesktop, clockWidgetYDesktop: globalState.clockWidgetYDesktop, calWidgetXDesktop: globalState.calWidgetXDesktop, calWidgetYDesktop: globalState.calWidgetYDesktop, weatherWidgetScale: globalState.weatherWidgetScale, clockWidgetScaleDesktop: globalState.clockWidgetScaleDesktop, calWidgetScaleDesktop: globalState.calWidgetScaleDesktop, musicWidgetW: globalState.musicWidgetW, musicWidgetH: globalState.musicWidgetH, clockDetailWidgetX: globalState.clockDetailWidgetX, clockDetailWidgetY: globalState.clockDetailWidgetY, weatherDetailWidgetX: globalState.weatherDetailWidgetX, weatherDetailWidgetY: globalState.weatherDetailWidgetY, calDetailWidgetX: globalState.calDetailWidgetX, calDetailWidgetY: globalState.calDetailWidgetY, clockDetailWidgetW: globalState.clockDetailWidgetW, clockDetailWidgetH: globalState.clockDetailWidgetH, weatherDetailWidgetW: globalState.weatherDetailWidgetW, weatherDetailWidgetH: globalState.weatherDetailWidgetH, calDetailWidgetW: globalState.calDetailWidgetW, calDetailWidgetH: globalState.calDetailWidgetH, clockDetailWidgetEnabled: globalState.clockDetailWidgetEnabled, weatherDetailWidgetEnabled: globalState.weatherDetailWidgetEnabled, calDetailWidgetEnabled: globalState.calDetailWidgetEnabled, cpuWidgetX: globalState.cpuWidgetX, cpuWidgetY: globalState.cpuWidgetY, ramWidgetX: globalState.ramWidgetX, ramWidgetY: globalState.ramWidgetY, diskWidgetX: globalState.diskWidgetX, diskWidgetY: globalState.diskWidgetY, cpuWidgetScale: globalState.cpuWidgetScale, ramWidgetScale: globalState.ramWidgetScale, diskWidgetScale: globalState.diskWidgetScale, cpuWidgetEnabled: globalState.cpuWidgetEnabled, ramWidgetEnabled: globalState.ramWidgetEnabled, diskWidgetEnabled: globalState.diskWidgetEnabled, sysWidgetX: globalState.sysWidgetX, sysWidgetY: globalState.sysWidgetY, sysWidgetScale: globalState.sysWidgetScale, sysWidgetEnabled: globalState.sysWidgetEnabled, gpuWidgetX: globalState.gpuWidgetX, gpuWidgetY: globalState.gpuWidgetY, gpuWidgetScale: globalState.gpuWidgetScale, gpuWidgetEnabled: globalState.gpuWidgetEnabled, chargeWidgetX: globalState.chargeWidgetX, chargeWidgetY: globalState.chargeWidgetY, chargeWidgetScale: globalState.chargeWidgetScale, chargeWidgetEnabled: globalState.chargeWidgetEnabled, dateWidgetX: globalState.dateWidgetX, dateWidgetY: globalState.dateWidgetY, dateWidgetScale: globalState.dateWidgetScale, dateWidgetEnabled: globalState.dateWidgetEnabled, bigTimeWidgetX: globalState.bigTimeWidgetX, bigTimeWidgetY: globalState.bigTimeWidgetY, bigTimeWidgetScale: globalState.bigTimeWidgetScale, bigTimeWidgetEnabled: globalState.bigTimeWidgetEnabled, mediaPillWidgetX: globalState.mediaPillWidgetX, mediaPillWidgetY: globalState.mediaPillWidgetY, mediaPillWidgetScale: globalState.mediaPillWidgetScale, mediaPillWidgetEnabled: globalState.mediaPillWidgetEnabled, countdownWidgetX: globalState.countdownWidgetX, countdownWidgetY: globalState.countdownWidgetY, countdownWidgetScale: globalState.countdownWidgetScale, countdownWidgetEnabled: globalState.countdownWidgetEnabled, weatherPillsWidgetX: globalState.weatherPillsWidgetX, weatherPillsWidgetY: globalState.weatherPillsWidgetY, weatherPillsWidgetScale: globalState.weatherPillsWidgetScale, weatherPillsWidgetEnabled: globalState.weatherPillsWidgetEnabled, lyricsCardWidgetX: globalState.lyricsCardWidgetX, lyricsCardWidgetY: globalState.lyricsCardWidgetY, lyricsCardWidgetScale: globalState.lyricsCardWidgetScale, lyricsCardWidgetEnabled: globalState.lyricsCardWidgetEnabled, lyricsLineWidgetX: globalState.lyricsLineWidgetX, lyricsLineWidgetY: globalState.lyricsLineWidgetY, lyricsLineWidgetScale: globalState.lyricsLineWidgetScale, lyricsLineWidgetEnabled: globalState.lyricsLineWidgetEnabled, lyricsBubbleWidgetX: globalState.lyricsBubbleWidgetX, lyricsBubbleWidgetY: globalState.lyricsBubbleWidgetY, lyricsBubbleWidgetScale: globalState.lyricsBubbleWidgetScale, lyricsBubbleWidgetEnabled: globalState.lyricsBubbleWidgetEnabled, musicBarView: globalState.musicBarView, lyricsOnlineFallback: globalState.lyricsOnlineFallback, musicWidgetEnabled: globalState.musicWidgetEnabled, weatherWidgetEnabled: globalState.weatherWidgetEnabled, clockWidgetEnabledDesktop: globalState.clockWidgetEnabledDesktop, calWidgetEnabledDesktop: globalState.calWidgetEnabledDesktop, clockShowHandsDesktop: globalState.clockShowHandsDesktop, clockShowNumbersDesktop: globalState.clockShowNumbersDesktop, clockCircleStyleDesktop: globalState.clockCircleStyleDesktop, weatherShowFeelsLike: globalState.weatherShowFeelsLike, weatherShowHumidity: globalState.weatherShowHumidity, weatherShowWind: globalState.weatherShowWind, calShowDayMonth: globalState.calShowDayMonth, calShowYear: globalState.calShowYear, musicShowAlbumArt: globalState.musicShowAlbumArt, musicShowProgressBar: globalState.musicShowProgressBar, musicCompactMode: globalState.musicCompactMode, barLayoutIsland: globalState.barLayoutIsland, barLayoutNotch: globalState.barLayoutNotch, desktopCavaEnabled: globalState.desktopCavaEnabled, desktopCavaEdge: globalState.desktopCavaEdge, desktopCavaStyle: globalState.desktopCavaStyle, desktopCavaResolution: globalState.desktopCavaResolution, desktopCavaHeight: globalState.desktopCavaHeight, lockClockStyle: globalState.lockClockStyle, lockClockShowHands: globalState.lockClockShowHands, lockClockShowNumbers: globalState.lockClockShowNumbers, lockClockScale: globalState.lockClockScale, lockClockFontScale: globalState.lockClockFontScale, lockClockFontKey: globalState.lockClockFontKey, lockLayout: globalState.lockLayout, lockBlurLevel: globalState.lockBlurLevel, lockCavaEnabled: globalState.lockCavaEnabled, lockCavaEdge: globalState.lockCavaEdge, lockCavaStyle: globalState.lockCavaStyle, fontPrimaryKey: globalState.fontPrimaryKey, fontSecondaryKey: globalState.fontSecondaryKey, fontScale: globalState.fontScale, clipPinned: globalState.clipPinned, ncCcRows: globalState.ncCcRows, ncDashOrder: globalState.ncDashOrder, ncCcKeysSeen: globalState.ncCcKeys, recFps: globalState.recFps, recResolution: globalState.recResolution, recMic: globalState.recMic, recRegion: globalState.recRegion, gamingEscOnOpen: globalState.gamingEscOnOpen, gamingFloating: globalState.gamingFloating, gamingFloatX: globalState.gamingFloatX, gamingFloatY: globalState.gamingFloatY, gamingFloatOpacity: globalState.gamingFloatOpacity, gamingModules: globalState.gamingModules, parallaxEnabled: globalState.parallaxEnabled, parallaxZoom: globalState.parallaxZoom, parallaxStrength: globalState.parallaxStrength, parallaxWidgets: globalState.parallaxWidgets, parallaxWidgetStrength: globalState.parallaxWidgetStrength, canvasInvertPan: globalState.canvasInvertPan, canvasInertia: globalState.canvasInertia, canvasInertiaTime: globalState.canvasInertiaTime, canvasInertiaMaxDist: globalState.canvasInertiaMaxDist, magnetEnabled: globalState.magnetEnabled, magnetMove: globalState.magnetMove, magnetResize: globalState.magnetResize, magnetResnap: globalState.magnetResnap, magnetAlign: globalState.magnetAlign, magnetNoAnim: globalState.magnetNoAnim, magnetGap: globalState.magnetGap, magnetSnapDist: globalState.magnetSnapDist, magnetBreakAway: globalState.magnetBreakAway, magnetBreakInto: globalState.magnetBreakInto, eyeCare: globalState.eyeCare, uiSoundsEnabled: globalState.uiSoundsEnabled, powerConfirmEnabled: globalState.powerConfirmEnabled, powerConfirmSeconds: globalState.powerConfirmSeconds, powerConfirmShowOthers: globalState.powerConfirmShowOthers });
    }

    function savePrefs() {
        var obj = collectPrefs();
        prefsSaver._doSave(JSON.stringify(obj));
        profileStore.recordLive(obj);
    }
}
