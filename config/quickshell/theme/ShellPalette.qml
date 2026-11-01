import QtQuick
import "../ui"

// Shell color roles: preset, matugen (walLoaded) or built-in M3 baseline
QtObject {
    property QtObject gs
    property QtObject roles
    function pick(preset, mat, light, dark) { return _preset ? preset : (gs.walLoaded ? mat : (_light ? light : dark)) }
    readonly property bool _light: gs.colorMode === "light"
    readonly property bool _preset: gs.paletteSource === "preset" && gs.presetApplyQuickshell

    property color primary: pick(roles.primary, gs.matPrimary, "#6750A4", "#D0BCFF")
    property color colorOnPrimary: pick(roles.colorOnPrimary, gs.matOnPrimary, "#FFFFFF", "#381E72")
    property color primaryCont: pick(roles.primaryCont, gs.matPrimaryContainer, "#EADDFF", "#4F378B")
    property color surface: pick(roles.surface, gs.matSurface, "#FFFBFE", "#1C1B1F")
    property color surfaceElevated: pick(roles.surfaceElevated, gs.matSurfaceContainer, "#F3EDF7", "#2A2535")
    property color surfaceHigh: pick(roles.surfaceHigh, gs.matSurfaceContainerHigh, "#ECE6F0", "#332E45")
    property color surfacePop: pick(roles.surfacePop, gs.matSurfaceContainerHighest, "#E6E0E9", "#3D3655")
    property color surfaceDeep: pick(roles.surfaceDeep, gs.matSurfaceContainerLow, "#F7F2FA", "#1E1B26")
    property color surfaceLowest: pick(roles.surfaceLowest, gs.matSurfaceContainerLowest, "#FFFFFF", "#0F0D13")

    property color surfaceVar: pick(roles.surfaceVar, gs.matSurfaceVariant, "#E7E0EC", "#49454F")
    property color colorOnSurface: pick(roles.colorOnSurface, gs.matOnSurface, "#1D1B20", "#E6E1E5")
    property color colorOnSurfVar: pick(roles.colorOnSurfVar, gs.matOnSurfaceVariant, "#49454F", "#CAC4D0")
    property color muted: pick(roles.muted, gs.matOutline, "#79747E", "#8E8A93")
    property color mutedDeep: pick(roles.mutedDeep, gs.matOutlineVariant, "#CAC4D0", "#49454F")
    property color secondaryCont: pick(roles.secondaryCont, gs.matSecondaryContainer, "#E8DEF8", "#4A4458")
    property color tertiary: pick(roles.tertiary, gs.matTertiary, "#7D5260", "#EFB8C8")
    property color accent: pick(roles.accent, gs.matSecondary, "#625B71", "#CCC2DC")
    property color accentAlt: pick(roles.accentAlt, gs.matPrimaryContainer, "#FFD8E4", "#633B48")
    property color error: pick(roles.error, gs.matError, "#B3261E", "#F2B8B5")
    property color colorOnPrimaryCont: pick(roles.colorOnPrimaryCont, gs.matOnPrimaryContainer, "#21005D", "#EADDFF")
    property color colorOnSecondary: pick(roles.colorOnSecondary, gs.matOnSecondary, "#FFFFFF", "#332D41")
    property color colorOnSecondaryCont: pick(roles.colorOnSecondaryCont, gs.matOnSecondaryContainer, "#1D192B", "#E8DEF8")
    property color colorOnTertiary: pick(roles.colorOnTertiary, gs.matOnTertiary, "#FFFFFF", "#492532")
    property color tertiaryCont: pick(roles.tertiaryCont, gs.matTertiaryContainer, "#FFD8E4", "#633B48")
    property color colorOnTertiaryCont: pick(roles.colorOnTertiaryCont, gs.matOnTertiaryContainer, "#31111D", "#FFD8E4")
    property color colorOnError: pick(roles.colorOnError, gs.matOnError, "#FFFFFF", "#601410")
    property color errorCont: pick(roles.errorCont, gs.matErrorContainer, "#F9DEDC", "#8C1D18")
    property color colorOnErrorCont: pick(roles.colorOnErrorCont, gs.matOnErrorContainer, "#410E0B", "#F9DEDC")
    property color inverseSurface: pick(roles.inverseSurface, gs.matInverseSurface, "#322F35", "#E6E1E5")
    property color inverseOnSurface: pick(roles.inverseOnSurface, gs.matInverseOnSurface, "#F5EFF7", "#313033")
    property color inversePrimary: pick(roles.inversePrimary, gs.matInversePrimary, "#D0BCFF", "#6750A4")
    property color toggleOn: pick(roles.toggleOn, gs.matPrimary, "#6750A4", "#7C4DCC")
    property color positive: pick(roles.positive, gs.matTertiary, "#2E7D32", "#A8D8A8")

    property color deskPrimary: pick(roles.darkPrimary, gs.matDarkPrimary, "#D0BCFF", "#D0BCFF")
    property color deskOnSurface: pick(roles.darkOnSurface, gs.matDarkOnSurface, "#E6E1E5", "#E6E1E5")
    Behavior on deskPrimary   { M3ColorAnim {} }
    Behavior on deskOnSurface { M3ColorAnim {} }

    function _darkest(cands) {
        var best = cands[0], bl = 2;
        for (var i = 0; i < cands.length; i++) {
            var c = cands[i], l = 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b;
            if (l < bl) { bl = l; best = c; }
        }
        return best;
    }
    property color darkestSurface: _darkest([surface, surfaceDeep, surfaceElevated, surfaceHigh, surfacePop, surfaceVar, secondaryCont])
    property color notifBase: _light ? secondaryCont : Qt.darker(secondaryCont, 1.85)
    property color notifCard: _light
        ? Qt.tint(secondaryCont, Qt.rgba(surfaceLowest.r, surfaceLowest.g, surfaceLowest.b, 0.75))
        : darkestSurface
    Behavior on notifCard { M3ColorAnim {} }
    property color onAccent: (0.2126 * accent.r + 0.7152 * accent.g + 0.0722 * accent.b) > 0.55 ? "#000000" : "#FFFFFF"
    property color textPrimary:     colorOnSurface
    property color textSecondary:   colorOnSurfVar
    property color textMuted:       muted

    Behavior on primary        { M3ColorAnim {} }
    Behavior on surface        { M3ColorAnim {} }
    Behavior on surfaceElevated{ M3ColorAnim {} }
    Behavior on surfaceHigh    { M3ColorAnim {} }
    Behavior on surfacePop     { M3ColorAnim {} }
    Behavior on surfaceDeep    { M3ColorAnim {} }
    Behavior on surfaceLowest  { M3ColorAnim {} }
    Behavior on primaryCont    { M3ColorAnim {} }
    Behavior on surfaceVar     { M3ColorAnim {} }
    Behavior on secondaryCont  { M3ColorAnim {} }
    Behavior on tertiary       { M3ColorAnim {} }
    Behavior on accent         { M3ColorAnim {} }
    Behavior on accentAlt      { M3ColorAnim {} }
    Behavior on toggleOn       { M3ColorAnim {} }
    Behavior on positive       { M3ColorAnim {} }
    Behavior on muted          { M3ColorAnim {} }
    Behavior on textPrimary    { M3ColorAnim {} }
    Behavior on textSecondary  { M3ColorAnim {} }
    Behavior on textMuted      { M3ColorAnim {} }

    readonly property int shapeXS: 4
    readonly property int shapeS: 8
    readonly property int shapeM: 12
    readonly property int shapeL: 16
    readonly property int shapeLI: 20
    readonly property int shapeXL: 28
    readonly property int shapeXLI: 32
    readonly property int space1: 4
    readonly property int space2: 8
    readonly property int space3: 12
    readonly property int space4: 16
    readonly property int space5: 20
    readonly property int space6: 24
    readonly property int space8: 32
}
