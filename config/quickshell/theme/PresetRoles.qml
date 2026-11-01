import QtQuick

// Material roles generated from the selected single-hue preset
QtObject {
    property QtObject gs
    readonly property bool _light: gs.colorMode === "light"
    function _seed() {
      var list = gs.presetPalettes;
      for (var i = 0; i < list.length; i++) {
        if (list[i].key === gs.presetPaletteKey) return list[i];
      }
      return list[0];
    }
    readonly property var _s: _seed()
    function hsl(h, s, l) { return Qt.hsla(((h % 360) + 360) % 360 / 360, Math.max(0, Math.min(1, s)), Math.max(0, Math.min(1, l)), 1); }
    
    property color primary:         hsl(_s.hue, _s.sat,        _light ? 0.42 : 0.78)
    property color colorOnPrimary:  hsl(_s.hue, _s.sat * 0.3,  _light ? 0.99 : 0.14)
    property color primaryCont:     hsl(_s.hue, _s.sat * 0.7,  _light ? 0.90 : 0.32)
    property color surface:         hsl(_s.hue, _s.sat * 0.30, _light ? 0.985: 0.075)
    property color surfaceElevated: hsl(_s.hue, _s.sat * 0.32, _light ? 0.955: 0.120)
    property color surfaceHigh:     hsl(_s.hue, _s.sat * 0.34, _light ? 0.930: 0.160)
    property color surfacePop:      hsl(_s.hue, _s.sat * 0.36, _light ? 0.900: 0.200)
    property color surfaceDeep:     hsl(_s.hue, _s.sat * 0.28, _light ? 0.965: 0.050)
    property color surfaceLowest:   hsl(_s.hue, _s.sat * 0.24, _light ? 1.000: 0.035)
    property color surfaceVar:      hsl(_s.hue, _s.sat * 0.40, _light ? 0.900: 0.260)
    property color colorOnSurface:  hsl(_s.hue, _s.sat * 0.10, _light ? 0.110: 0.940)
    property color colorOnSurfVar:  hsl(_s.hue, _s.sat * 0.18, _light ? 0.300: 0.800)
    property color muted:           hsl(_s.hue, _s.sat * 0.14, _light ? 0.470: 0.600)
    property color mutedDeep:       hsl(_s.hue, _s.sat * 0.20, _light ? 0.800: 0.340)
    property color secondaryCont:   hsl(_s.hue, _s.sat * 0.55, _light ? 0.88 : 0.30)
    property color tertiary:        hsl(_s.hue, _s.sat * 0.70, _light ? 0.45 : 0.78)
    property color accent:          hsl(_s.hue, _s.sat * 0.50, _light ? 0.38 : 0.78)
    property color accentAlt:       hsl(_s.hue, _s.sat * 0.60, _light ? 0.88 : 0.30)
    property color error:           _light ? "#B3261E" : "#F2B8B5"
    property color toggleOn:        primary
    property color positive:        _light ? "#2E7D32" : "#A8D8A8"
    property color darkPrimary:     hsl(_s.hue, _s.sat,        0.78)
    property color darkOnSurface:   hsl(_s.hue, _s.sat * 0.10, 0.940)
    property color colorOnPrimaryCont:   hsl(_s.hue, _s.sat * 0.70, _light ? 0.12 : 0.90)
    property color colorOnSecondary:     hsl(_s.hue, _s.sat * 0.30, _light ? 0.99 : 0.16)
    property color colorOnSecondaryCont: hsl(_s.hue, _s.sat * 0.50, _light ? 0.14 : 0.90)
    property color colorOnTertiary:      hsl(_s.hue, _s.sat * 0.30, _light ? 0.99 : 0.16)
    property color tertiaryCont:    hsl(_s.hue, _s.sat * 0.62, _light ? 0.86 : 0.34)
    property color colorOnTertiaryCont:  hsl(_s.hue, _s.sat * 0.60, _light ? 0.14 : 0.92)
    property color colorOnError:         _light ? "#FFFFFF" : "#601410"
    property color errorCont:       _light ? "#F9DEDC" : "#8C1D18"
    property color colorOnErrorCont:     _light ? "#410E0B" : "#F9DEDC"
    property color inverseSurface:  hsl(_s.hue, _s.sat * 0.10, _light ? 0.19 : 0.90)
    property color inverseOnSurface: hsl(_s.hue, _s.sat * 0.10, _light ? 0.95 : 0.19)
    property color inversePrimary:  hsl(_s.hue, _s.sat, _light ? 0.80 : 0.40)
}
