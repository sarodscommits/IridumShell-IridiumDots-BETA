import QtQuick
import Quickshell

// Theme, fonts, bar/shell appearance, shadows, matugen colors and UI sounds
QtObject {
    property var termColors: ({})
    property string fontPrimaryKey:   "google"
    property string fontSecondaryKey: "google"
    property real   fontScale: 1.0

    readonly property var fontCatalog: [
        { key: "google",  label: "Google Sans",       pkg: "ttf-google-sans",       exact: ["Google Sans", "Google Sans Text", "Google Sans Flex"], match: /^google\s*sans/i },
        { key: "dmsans",  label: "DM Sans",           pkg: "ttf-dm-sans",           exact: ["DM Sans"],                                           match: /^dm\s*sans/i },
        { key: "jakarta", label: "Plus Jakarta Sans", pkg: "ttf-plus-jakarta-sans", exact: ["Plus Jakarta Sans"],                                 match: /plus\s*jakarta/i },
        { key: "nothing", label: "Nothing",           pkg: "ttf-nothing-font-git",  exact: ["NType82", "NType 82", "Ndot 57", "Ndot57", "Ndot 55", "Nothing Font (5x7)"], match: /nothing|ndot|ntype/i }
    ]

    readonly property var fontResolved: {
        var fams = Qt.fontFamilies();
        var out = {};
        for (var i = 0; i < fontCatalog.length; i++) {
            var f = fontCatalog[i], fam = "";
            for (var e = 0; e < f.exact.length && !fam; e++)
                if (fams.indexOf(f.exact[e]) >= 0) fam = f.exact[e];
            for (var j = 0; j < fams.length && !fam; j++)
                if (f.match.test(fams[j])) fam = fams[j];
            out[f.key] = { family: fam !== "" ? fam : f.exact[0], available: fam !== "" };
        }
        return out;
    }

    readonly property string fontPrimary:   (fontResolved[fontPrimaryKey]   || fontResolved.google).family
    readonly property string fontSecondary: (fontResolved[fontSecondaryKey] || fontResolved.google).family
    property string matPrimary:                "#D0BCFF"
    property string matOnPrimary:              "#381E72"
    property string matPrimaryContainer:       "#4F378B"
    property string matSecondary:              "#CCC2DC"
    property string matOnSecondary:            "#332D41"
    property string matSecondaryContainer:     "#4A4458"
    property string matTertiary:               "#EFB8C8"
    property string matOnTertiary:             "#492532"
    property string matTertiaryContainer:      "#633B48"
    property string matError:                  "#F2B8B5"
    property string matOnError:                "#601410"
    property string matBackground:             "#1C1B1F"
    property string matOnBackground:           "#E6E1E5"
    property string matSurface:                "#1C1B1F"
    property string matOnSurface:              "#E6E1E5"
    property string matDarkPrimary:            "#D0BCFF"
    property string matDarkOnSurface:          "#E6E1E5"
    property string matSurfaceVariant:         "#49454F"
    property string matOnSurfaceVariant:       "#CAC4D0"
    property string matSurfaceContainer:       "#241E22"
    property string matSurfaceContainerLowest: "#0F0D13"
    property string matSurfaceContainerLow:    "#201A1E"
    property string matSurfaceContainerHigh:   "#2F282C"
    property string matSurfaceContainerHighest:"#3A3337"
    property string matOutline:                "#938F99"
    property string matOutlineVariant:         "#49454F"
    property string matInverseSurface:         "#E6E1E5"
    property string matInverseOnSurface:       "#313033"
    property string matInversePrimary:         "#6750A4"
    property string matOnPrimaryContainer:     "#EADDFF"
    property string matOnSecondaryContainer:   "#E8DEF8"
    property string matOnTertiaryContainer:    "#FFD8E4"
    property string matErrorContainer:         "#8C1D18"
    property string matOnErrorContainer:       "#F9DEDC"
    property bool   walLoaded:                 false
    property string currentWallpaper: ""
    property string currentWallpaperStill: ""
    property int wallpaperFpsLimit: 60
    property string colorMode:       "dark"
    property string motionScheme: "expressive"
    property real   m3Speed: 1.0
    property real   m3Bounce: 1.0
    property string m3AccentShape: "Cookie9Sided"
    property real   m3CornerScale: 1.0
    property bool   m3SwitchIcons: true
    property bool   m3Wavy: true
    property real   m3ProgressThickness: 4
    property real   m3SliderScale: 1.0
    property bool   m3Emphasis: true
    property string paletteSource:   "matugen"
    property string presetPaletteKey: "sunset_orange"
    property bool presetApplyQuickshell: true
    property bool presetApplyKitty: true
    property string termPaletteMode: "pywal"

    property var presetPalettes: [
      { key: "mono_white",     name: "Blanco (monocroma)", hue: 0,   sat: 0.00 },
      { key: "sunset_orange",  name: "Naranja atardecer",  hue: 22,  sat: 0.85 },
      { key: "golden_yellow",  name: "Amarillo dorado",    hue: 45,  sat: 0.75 },
      { key: "olive_green",    name: "Verde oliva",        hue: 65,  sat: 0.45 },
      { key: "lime_green",     name: "Verde lima",         hue: 90,  sat: 0.65 },
      { key: "moss_green",     name: "Verde musgo",        hue: 112, sat: 0.40 },
      { key: "emerald_green",  name: "Verde esmeralda",    hue: 150, sat: 0.55 },
      { key: "turquoise_blue", name: "Azul turquesa",      hue: 186, sat: 0.65 },
      { key: "ocean_blue",     name: "Ocean blue",         hue: 210, sat: 0.60 },
      { key: "graphite_gray",  name: "Gris grafito",       hue: 220, sat: 0.08 },
      { key: "royal_violet",   name: "Violeta real",       hue: 265, sat: 0.55 },
      { key: "orchid_purple",  name: "Orchid purple",      hue: 290, sat: 0.55 },
      { key: "bubblegum_pink", name: "Rosa chicle",        hue: 330, sat: 0.65 },
      { key: "crimson_red",    name: "Crimson red",        hue: 355, sat: 0.70 }
    ]

    property bool   glassMode:       false
    property real   kittyGlassOpacity: 0.65
    property bool   glassQuickshellEnabled: true
    property bool   glassKittyEnabled:      true
    property real   glassQuickshellOpacity: 0.35
    property string topBarPosition:  "top"
    readonly property bool barVertical: topBarPosition === "left" || topBarPosition === "right"
    property bool islandAutoHide: false
    property string shellMode: "island"
    property bool clockFormat24h: false
    property int    borderSize:      0
    property bool   shadowEnabled:   true
    property int    shadowRange:     30
    property int    shadowIntensity: 80
    property bool   shellShadowEnabled:   true
    property bool   shellShadowIsland:    true
    property bool   shellShadowNotch:     true
    property bool   shellShadowPanels:    true
    property bool   shellShadowWidgets:   true
    property bool   shellShadowNotifs:    true
    property bool   shellShadowGaming:    true
    property bool   shellShadowLock:      true
    property int    shellShadowRange:     28
    property int    shellShadowIntensity: 55
    property bool shellShadowEditHold: false
    readonly property bool shellShadowSuspended: desktopEditMode || desktopEditPrep || shellShadowEditHold
    readonly property bool shellShadowActive:    shellShadowEnabled && !shellShadowSuspended
    readonly property bool shellShadowBarOn:     shellShadowActive && (shellMode === "island" ? shellShadowIsland : shellShadowNotch)
    readonly property bool shellShadowPanelsOn:  shellShadowActive && shellShadowPanels
    readonly property bool shellShadowWidgetsOn: shellShadowActive && shellShadowWidgets
    readonly property bool shellShadowNotifsOn:  shellShadowActive && shellShadowNotifs
    readonly property bool shellShadowGamingOn:  shellShadowActive && shellShadowGaming
    readonly property bool shellShadowLockOn:    shellShadowActive && shellShadowLock
    property int  shellShadowGen: 0

    readonly property var shellShadowSatOffsets: [[0, 0], [0, 0], [0, 0], [0, 0], [0, 0],
        [0.5, 0], [-0.5, 0], [0, 0.5], [0, -0.5], [0.3536, 0.3536], [-0.3536, 0.3536], [0.3536, -0.3536], [-0.3536, -0.3536],
        [0.5, 0], [-0.5, 0], [0, 0.5], [0, -0.5], [0.3536, 0.3536], [-0.3536, 0.3536], [0.3536, -0.3536], [-0.3536, -0.3536],
        [1, 0], [-1, 0], [0, 1], [0, -1], [0.7071, 0.7071], [-0.7071, 0.7071], [0.7071, -0.7071], [-0.7071, -0.7071],
        [1, 0], [-1, 0], [0, 1], [0, -1], [0.7071, 0.7071], [-0.7071, 0.7071], [0.7071, -0.7071], [-0.7071, -0.7071],
        [1, 0], [-1, 0], [0, 1], [0, -1], [0.7071, 0.7071], [-0.7071, 0.7071], [0.7071, -0.7071], [-0.7071, -0.7071]]

    property int    cornerRounding:  20
    property string layoutMode:      "dwindle"
    property bool   allFloating:     true

    property var barModules: ({
        control:    true,
        search:     true,
        workspaces: true,
        windows:    true,
        audio:      true,
        clock:      true,
        gaming:     true,
        clipboard:  true,
        privacy:    true,
        notifications: true,
        wifi:       true,
        bluetooth:  true,
        battery:    true,
        session:    true
    })

    property var pinnedApps: []
    property real   wifiBtGlassAlpha: 0
    property real   hwVolumeBoostMultiplier: 1.5
    property string language:        "en"
    readonly property string uiSoundsDir: Quickshell.env("HOME") + "/.config/quickshell/ui-sounds"
    readonly property string uiClickSound: uiSoundsDir + "/1.mp3"
    property var uiSoundWavs: ({})
    property bool uiSoundsEnabled: true

    function playUiSound(name, vol) {
        if (!uiSoundsEnabled && name !== "2") return;
        var v = (vol === undefined ? 100 : Math.max(0, Math.min(100, vol)));
        var wav = uiSoundWavs[name];
        if (wav) Quickshell.execDetached(["pw-play", "--media-role=Event", "--volume=" + (v / 100).toFixed(2), wav]);
        else Quickshell.execDetached(["mpv", "--no-video", "--really-quiet", "--audio-display=no", "--volume=" + Math.round(v), uiSoundsDir + "/" + name + ".mp3"]);
    }

    function playUiClick() { playUiSound("1"); }

    function setEyeCare(on) {
        if (on === eyeCare) return;
        eyeCare = on;
        savePrefs();
    }
}
