import QtQuick

// FractionSlider that reports whole percentages (0-100) on press, drag and release
FractionSlider {
    id: ps
    signal pctPressed()
    signal pctMoved(int value)
    signal pctReleased()
    thumbW: 7
    onFracPressed: ps.pctPressed()
    onFracMoved: (frac) => ps.pctMoved(Math.round(frac * 100))
    onFracReleased: ps.pctReleased()
}
