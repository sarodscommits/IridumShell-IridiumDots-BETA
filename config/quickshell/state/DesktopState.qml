import QtQuick

// Desktop widgets, wallpaper, lockscreen, parallax, canvas and magnet settings
CaptureState {
    readonly property var currentWallpaperEntry: {
        var l = wallpaperList;
        for (var i = 0; i < l.length; i++) if (l[i].path === currentWallpaper) return l[i];
        return null;
    }

    function openWallpaperBrowser() {
        settingsSection = "wallpaper";
        settingsWpBrowse = true;
        settingsOpen = true;
    }

    function toggleWallpaperBrowser() {
        if (settingsOpen && settingsWpBrowse && settingsSection === "wallpaper") settingsOpen = false;
        else openWallpaperBrowser();
    }

    property bool   lockScreenActive: false
    property string lockUsername:     ""
    property int    lastActivityMs:   0
    property int    lockMotiIdx:      0
    property bool wpFullscreenActive: false
    onLockScreenActiveChanged: updateWallpaperPauseState()

    onWpFullscreenActiveChanged: {
        updateWallpaperPauseState();
        if (!wpFullscreenActive) wpResumeRetry.restart();
    }

    property var    wallpaperList: []
    property bool   wallpaperLoaded: false
    property real musicWidgetX: 60
    property real musicWidgetY: 60
    property real weatherWidgetX: 360
    property real weatherWidgetY: 60
    property real clockWidgetXDesktop: 660
    property real clockWidgetYDesktop: 60
    property real calWidgetXDesktop: 960
    property real calWidgetYDesktop: 60
    property real clockDetailWidgetX: 60
    property real clockDetailWidgetY: 320
    property real weatherDetailWidgetX: 360
    property real weatherDetailWidgetY: 320
    property real calDetailWidgetX: 660
    property real calDetailWidgetY: 320
    property real cpuWidgetX: 60
    property real cpuWidgetY: 620
    property real ramWidgetX: 360
    property real ramWidgetY: 620
    property real diskWidgetX: 660
    property real diskWidgetY: 620
    property real sysWidgetX: 1100
    property real sysWidgetY: 55
    property real gpuWidgetX: 1100
    property real gpuWidgetY: 330
    property real chargeWidgetX: 1375
    property real chargeWidgetY: 330
    property real dateWidgetX: 1485
    property real dateWidgetY: 55
    property real bigTimeWidgetX: 1100
    property real bigTimeWidgetY: 605
    property real mediaPillWidgetX: 1375
    property real mediaPillWidgetY: 605
    property real countdownWidgetX: 1375
    property real countdownWidgetY: 770
    property real weatherPillsWidgetX: 1650
    property real weatherPillsWidgetY: 330
    property real lyricsCardWidgetX: 760
    property real lyricsCardWidgetY: 330
    property real lyricsLineWidgetX: 760
    property real lyricsLineWidgetY: 680
    property real lyricsBubbleWidgetX: 1110
    property real lyricsBubbleWidgetY: 330
    property real weatherWidgetScale: 1.0
    property real clockWidgetScaleDesktop: 1.0
    property real calWidgetScaleDesktop: 1.0
    property real cpuWidgetScale: 1.0
    property real ramWidgetScale: 1.0
    property real diskWidgetScale: 1.0
    property real sysWidgetScale: 1.0
    property real gpuWidgetScale: 1.0
    property real chargeWidgetScale: 1.0
    property real dateWidgetScale: 1.0
    property real bigTimeWidgetScale: 1.0
    property real mediaPillWidgetScale: 1.0
    property real countdownWidgetScale: 1.0
    property real weatherPillsWidgetScale: 1.0
    property real lyricsCardWidgetScale: 1.0
    property real lyricsLineWidgetScale: 1.0
    property real lyricsBubbleWidgetScale: 1.0
    property real musicWidgetW: 330
    property real musicWidgetH: 385
    property real clockDetailWidgetW: 275
    property real clockDetailWidgetH: 330
    property real weatherDetailWidgetW: 275
    property real weatherDetailWidgetH: 385
    property real calDetailWidgetW: 275
    property real calDetailWidgetH: 385
    property bool desktopEditMode: false
    property bool desktopEditPrep: false
    property bool   parallaxEnabled:   false
    property real   parallaxZoom:      1.2
    property real   parallaxStrength:  0.15
    property var    parallaxOffsets:   ({})
    property bool   parallaxWidgets:   false
    property real   parallaxWidgetStrength: 0.45
    property bool   canvasInvertPan:   false
    property bool   canvasInertia:        true
    property real   canvasInertiaTime:    1.0
    property real   canvasInertiaMaxDist: 0.6
    property bool   magnetEnabled:     true
    property bool   magnetMove:        true
    property bool   magnetResize:      true
    property bool   magnetResnap:      true
    property bool   magnetAlign:       true
    property bool   magnetNoAnim:      true
    property int    magnetGap:         7
    property int    magnetSnapDist:    16
    property int    magnetBreakAway:   22
    property int    magnetBreakInto:   70
    property bool musicWidgetEnabled:            true
    property bool   desktopCavaEnabled: true
    property string desktopCavaEdge:    "bottom"
    property string desktopCavaStyle:   "bars"
    property int    desktopCavaResolution: 80
    property int    desktopCavaHeight:     212
    property var    desktopCavaBars:    []
    property bool weatherWidgetEnabled:          true
    property bool clockWidgetEnabledDesktop:     true
    property bool calWidgetEnabledDesktop:       true
    property bool clockDetailWidgetEnabled:   false
    property bool weatherDetailWidgetEnabled: false
    property bool calDetailWidgetEnabled:     false
    property bool cpuWidgetEnabled:  false
    property bool ramWidgetEnabled:  false
    property bool diskWidgetEnabled: false
    property bool sysWidgetEnabled: false
    property bool gpuWidgetEnabled: false
    property bool chargeWidgetEnabled: false
    property bool dateWidgetEnabled: false
    property bool bigTimeWidgetEnabled: false
    property bool mediaPillWidgetEnabled: false
    property bool countdownWidgetEnabled: false
    property bool weatherPillsWidgetEnabled: false
    property bool lyricsCardWidgetEnabled: false
    property bool lyricsLineWidgetEnabled: false
    property bool lyricsBubbleWidgetEnabled: false
    property bool clockShowHandsDesktop:   true
    property bool clockShowNumbersDesktop: true
    property bool clockCircleStyleDesktop: false
    property string lockClockStyle:       "gear"
    property bool   lockClockShowHands:   true
    property bool   lockClockShowNumbers: false
    property real   lockClockScale:     1.0
    property real   lockClockFontScale: 1.0
    property string lockClockFontKey:   "primary"

    readonly property string lockClockFont: (lockClockFontKey !== "primary" && fontResolved[lockClockFontKey] && fontResolved[lockClockFontKey].available)
                                            ? fontResolved[lockClockFontKey].family : fontPrimary

    property string lockLayout:         "vertical"
    property real   lockBlurLevel:      1.0
    property bool   lockCavaEnabled:    true
    property string lockCavaEdge:       "bottom"
    property string lockCavaStyle:      "bars"
    property bool weatherShowFeelsLike: false
    property bool weatherShowHumidity:  false
    property bool weatherShowWind:      false
    property bool calShowDayMonth: true
    property bool calShowYear:     false
    property bool musicShowAlbumArt:     true
    property bool musicShowProgressBar: true
    property bool musicCompactMode:      false
    property bool stopwatchRunning:   false
    property real stopwatchElapsedMs: 0
    property var  stopwatchLaps:      []

    function stopwatchStartPause() {
        stopwatchRunning = !stopwatchRunning;
    }

    function stopwatchLap() {
        if (!stopwatchRunning) return;
        var prevTotal = stopwatchLaps.length > 0 ? stopwatchLaps[stopwatchLaps.length - 1].totalMs : 0;
        var lap = { n: stopwatchLaps.length + 1, totalMs: stopwatchElapsedMs, splitMs: stopwatchElapsedMs - prevTotal };
        stopwatchLaps = stopwatchLaps.concat([lap]);
    }

    function stopwatchReset() {
        if (stopwatchRunning) return;
        stopwatchElapsedMs = 0;
        stopwatchLaps = [];
    }

    onDesktopEditModeChanged: if (!desktopEditMode) { shellShadowEditHold = true; shellShadowEditHoldTimer.restart(); }
}
