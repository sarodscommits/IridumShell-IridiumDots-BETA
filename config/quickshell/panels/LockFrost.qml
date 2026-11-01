import QtQuick
import QtQuick.Effects
import "../ui"

// Frosted glass panel for the lockscreen
Item {
    id: lf
    property Item target: null
    property Item wallpaper: null
    property Item space: null
    property bool active: true
    readonly property real pad: 72
    readonly property rect r: {
        var t = lf.target, s = lf.space;
        if (!t || !s) return Qt.rect(0, 0, 0, 0);
        var pp = t.parent, gp = pp ? pp.parent : null;
        var dep = t.x + t.y + t.width + t.height + t.scale
                + (pp ? pp.x + pp.y : 0) + (gp ? gp.x + gp.y : 0) + s.width + s.height;
        return t.mapToItem(s, 0, 0, t.width, t.height);
    }
    readonly property rect wr: {
        var w = lf.wallpaper, s = lf.space;
        if (!w || !s) return Qt.rect(0, 0, 0, 0);
        var dep = s.scale + s.x + s.y + w.width + w.height;
        return s.mapToItem(w, lf.r.x - lf.pad, lf.r.y - lf.pad, lf.r.width + 2 * lf.pad, lf.r.height + 2 * lf.pad);
    }
    readonly property real k: (target && target.width > 0) ? r.width / target.width : 1
    readonly property real effOpacity: {
        var t = lf.target;
        if (!t) return 0;
        var pp = t.parent;
        return t.opacity * ((pp && pp !== lf.space) ? pp.opacity : 1);
    }
    x: r.x - pad; y: r.y - pad
    width: r.width + 2 * pad; height: r.height + 2 * pad
    z: target ? ((target.parent === space ? target.z : target.parent.z) - 0.01) : 0
    visible: active && target !== null && target.visible && effOpacity > 0.01 && r.width > 1 && r.height > 1
    opacity: effOpacity

    ShaderEffectSource {
        id: lfSrc
        anchors.fill: parent
        visible: false
        sourceItem: lf.visible ? lf.wallpaper : null
        sourceRect: lf.wr
    }
    ShaderEffectSource {
        id: lfMask
        anchors.fill: parent
        visible: false
        hideSource: false
        sourceItem: lf.visible ? lf.target : null
        sourceRect: Qt.rect(-lf.pad / lf.k, -lf.pad / lf.k,
                            (lf.target ? lf.target.width : 0) + 2 * lf.pad / lf.k,
                            (lf.target ? lf.target.height : 0) + 2 * lf.pad / lf.k)
    }
    MultiEffect {
        anchors.fill: parent
        source: lfSrc
        autoPaddingEnabled: false
        blurEnabled: true
        blur: 1.0
        blurMax: 128
        blurMultiplier: 1.6
        brightness: -0.15
        maskEnabled: true
        maskSource: lfMask
        maskThresholdMin: 0.1
        maskSpreadAtMin: 0.1
    }
}
