import QtQuick

// M3 Expressive roles, motion tokens, shape scale and type scale
QtObject {
    property QtObject gs
    property QtObject colors
    readonly property bool dark: gs.colorMode !== "light"
    readonly property bool expressive: gs.motionScheme !== "standard"
    readonly property bool glass: gs.glassMode

    readonly property color primary:                 colors.primary
    readonly property color inkPrimary:              colors.colorOnPrimary
    readonly property color primaryContainer:        colors.primaryCont
    readonly property color inkPrimaryContainer:     colors.colorOnPrimaryCont
    readonly property color secondary:               colors.accent
    readonly property color inkSecondary:            colors.colorOnSecondary
    readonly property color secondaryContainer:      colors.secondaryCont
    readonly property color inkSecondaryContainer:   colors.colorOnSecondaryCont
    readonly property color tertiary:                colors.tertiary
    readonly property color inkTertiary:             colors.colorOnTertiary
    readonly property color tertiaryContainer:       colors.tertiaryCont
    readonly property color inkTertiaryContainer:    colors.colorOnTertiaryCont
    readonly property color error:                   colors.error
    readonly property color inkError:                colors.colorOnError
    readonly property color errorContainer:          colors.errorCont
    readonly property color inkErrorContainer:       colors.colorOnErrorCont
    readonly property color surface:                 colors.surface
    readonly property color surfaceContainerLowest:  colors.surfaceLowest
    readonly property color surfaceContainerLow:     colors.surfaceDeep
    readonly property color surfaceContainer:        colors.surfaceElevated
    readonly property color surfaceContainerHigh:    colors.surfaceHigh
    readonly property color surfaceContainerHighest: colors.surfacePop
    readonly property color inkSurface:              colors.colorOnSurface
    readonly property color inkSurfaceVariant:       colors.colorOnSurfVar
    readonly property color outline:                 colors.muted
    readonly property color outlineVariant:          colors.mutedDeep
    readonly property color inverseSurface:          colors.inverseSurface
    readonly property color inverseOnSurface:        colors.inverseOnSurface
    readonly property color inversePrimary:          colors.inversePrimary
    readonly property color shadow:                  "#000000"

    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    function mix(a, b, t) { return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t) }
    function css(c) { return "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + "," + c.a.toFixed(3) + ")" }
    function glassy(c, a) { return glass ? Qt.rgba(c.r, c.g, c.b, a === undefined ? 0.6 : a) : c }
    function state(base, ink, amount) { return Qt.tint(base, Qt.rgba(ink.r, ink.g, ink.b, amount)) }

    readonly property var springs: ({
        expressive: {
            spatialFast: [800, 0.6], spatialDefault: [380, 0.8], spatialSlow: [200, 0.8],
            effectsFast: [3800, 1.0], effectsDefault: [1600, 1.0], effectsSlow: [800, 1.0]
        },
        standard: {
            spatialFast: [1400, 0.9], spatialDefault: [700, 0.9], spatialSlow: [300, 0.9],
            effectsFast: [3800, 1.0], effectsDefault: [1600, 1.0], effectsSlow: [800, 1.0]
        }
    })
    readonly property real speed: Math.max(0.5, Math.min(2, gs.m3Speed))
    readonly property real bounce: Math.max(0, Math.min(2, gs.m3Bounce))
    function baseK(tok) { return springs[expressive ? "expressive" : "standard"][tok][0] }
    function baseZ(tok) { return springs[expressive ? "expressive" : "standard"][tok][1] }
    function sk(tok) { return baseK(tok) * speed * speed }
    function sz(tok) { const z = baseZ(tok); return tok.indexOf("spatial") === 0 ? Math.max(0.25, Math.min(1, 1 - (1 - z) * bounce)) : z }
    function qs(tok) { return sk(tok) / 79.4 }
    function qd(tok) { return 2 * sz(tok) * Math.sqrt(sk(tok)) / 75.4 * 0.93 }

    readonly property var emphasized:           [0.05, 0, 0.133333, 0.06, 0.166666, 0.4, 0.208333, 0.82, 0.25, 1, 1, 1]
    readonly property var emphasizedDecelerate: [0.05, 0.7, 0.1, 1, 1, 1]
    readonly property var emphasizedAccelerate: [0.3, 0, 0.8, 0.15, 1, 1]
    readonly property var standardCurve:        [0.2, 0, 0, 1, 1, 1]
    readonly property var standardDecelerate:   [0, 0, 0, 1, 1, 1]
    readonly property var standardAccelerate:   [0.3, 0, 1, 1, 1, 1]
    readonly property var springCurve:          expressive ? [0.1142, 0.0601, 0.1822, 0.7841, 0.4265, 0.9605, 0.5301, 1.0198, 0.515, 1.0248, 1, 1] : [0.05, 0.7, 0.1, 1, 1, 1]
    readonly property var springCurveFast:      expressive ? [0.0951, 0.0493, 0.1505, 1.1892, 0.3692, 1.0923, 0.6571, 0.9642, 0.5233, 0.9919, 1, 1] : [0.05, 0.7, 0.1, 1, 1, 1]
    readonly property int durFast:    Math.round(150 / speed)
    readonly property int durDefault: Math.round(220 / speed)
    readonly property int durSlow:    Math.round(320 / speed)

    readonly property string accentShape: gs.m3AccentShape
    readonly property real cornerScale: Math.max(0.6, Math.min(1.4, gs.m3CornerScale))
    function corner(r) { return Math.round(r * cornerScale) }
    readonly property bool switchIcons: gs.m3SwitchIcons
    readonly property bool wavy: gs.m3Wavy
    readonly property real progressThickness: Math.max(2, Math.min(8, gs.m3ProgressThickness))
    readonly property color ringActive: primary
    // Same as the empty part of the sliders / music progress bars
    readonly property color ringTrack: alpha(inkSurface, 0.14)
    function ringLw(base) { return base * progressThickness / 4 }
    readonly property real sliderScale: Math.max(0.7, Math.min(1.4, gs.m3SliderScale))
    readonly property bool emphasis: gs.m3Emphasis

    readonly property real fs: gs.fontScale
    readonly property string font:     gs.fontPrimary
    readonly property string fontBody: gs.fontSecondary
    readonly property string symbols:  "Material Symbols Rounded"
    readonly property var type: ({
        displayLarge: [57, 64, 400], displayMedium: [45, 52, 400], displaySmall: [36, 44, 400],
        headlineLarge: [32, 40, 400], headlineMedium: [28, 36, 400], headlineSmall: [24, 32, 400],
        titleLarge: [22, 28, 400], titleMedium: [16, 24, 500], titleSmall: [14, 20, 500],
        bodyLarge: [16, 24, 400], bodyMedium: [14, 20, 400], bodySmall: [12, 16, 400],
        labelLarge: [14, 20, 500], labelMedium: [12, 16, 500], labelSmall: [11, 16, 500]
    })
    readonly property var typeRoles: ["displayLarge", "displayMedium", "displaySmall", "headlineLarge", "headlineMedium", "headlineSmall",
        "titleLarge", "titleMedium", "titleSmall", "bodyLarge", "bodyMedium", "bodySmall", "labelLarge", "labelMedium", "labelSmall"]
    function tw(role, emph) {
        const b = type[role][2]
        const auto = emphasis && (role.indexOf("display") === 0 || role.indexOf("headline") === 0 || role.indexOf("title") === 0)
        return (emph || auto) ? (b >= 500 ? 700 : 600) : b
    }
}
