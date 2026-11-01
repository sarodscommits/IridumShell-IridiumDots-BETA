import QtQuick
import QtQuick.Effects
import "../ui"

// Lockscreen element shadow
Item {
    id: lsh
    property Item target: null
    property Item space: null
    property bool active: true
    readonly property int  thick: globalState.shellShadowRange
    readonly property real pad: thick + 8
    readonly property rect r: {
        var t = lsh.target, s = lsh.space;
        if (!t || !s) return Qt.rect(0, 0, 0, 0);
        var pp = t.parent, gp = pp ? pp.parent : null;
        var dep = t.x + t.y + t.width + t.height + t.scale
                + (pp ? pp.x + pp.y : 0) + (gp ? gp.x + gp.y : 0) + s.width + s.height;
        return t.mapToItem(s, 0, 0, t.width, t.height);
    }
    readonly property real k: (target && target.width > 0) ? r.width / target.width : 1
    readonly property real effOpacity: {
        var t = lsh.target;
        if (!t) return 0;
        var pp = t.parent;
        return t.opacity * ((pp && pp !== lsh.space) ? pp.opacity : 1);
    }
    x: r.x - pad; y: r.y - pad
    width: r.width + 2 * pad; height: r.height + 2 * pad
    z: target ? ((target.parent === space ? target.z : target.parent.z) - 0.02) : 0
    visible: active && target !== null && target.visible && effOpacity > 0.01 && r.width > 1 && r.height > 1
    opacity: effOpacity

    ShaderEffectSource {
        id: lshSil
        anchors.fill: parent
        visible: false
        hideSource: false
        sourceItem: lsh.visible ? lsh.target : null
        sourceRect: Qt.rect(-lsh.pad / lsh.k, -lsh.pad / lsh.k,
                            (lsh.target ? lsh.target.width : 0) + 2 * lsh.pad / lsh.k,
                            (lsh.target ? lsh.target.height : 0) + 2 * lsh.pad / lsh.k)
    }
    Rectangle { id: lshBlack; anchors.fill: parent; color: "black"; visible: false; layer.enabled: true }
    MultiEffect {
        id: lshSolid
        anchors.fill: parent
        visible: false
        layer.enabled: true
        source: lshBlack
        autoPaddingEnabled: false
        maskEnabled: true
        maskSource: lshSil
        maskThresholdMin: 0.2308
        maskSpreadAtMin: 0.3
    }
    MultiEffect {
        anchors.fill: parent
        source: lshSolid
        autoPaddingEnabled: false
        blurEnabled: true
        blur: 1.0
        blurMax: lsh.thick
        brightness: -1.0
        maskEnabled: true
        maskInverted: true
        maskSource: lshSil
        maskThresholdMin: 0.2308
        maskSpreadAtMin: 0.3
        opacity: globalState.shellShadowIntensity / 100
    }
}
