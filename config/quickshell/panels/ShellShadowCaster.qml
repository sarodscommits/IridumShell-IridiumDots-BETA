import QtQuick
import QtQuick.Effects
import "../ui"

// Outer shell shadow for a silhouette, drawn on the shadow surfaces
Item {
    id: ssc
    property Item grabTarget: null
    property real radius: 0
    property int  regrabInterval: 0
    property bool active: true
    readonly property bool useGrab: grabTarget !== null
    readonly property int  thick: globalState.shellShadowRange
    readonly property real dil: Math.round(thick * 0.2)
    readonly property real pad: thick + dil + 4
    property url  grabUrl: ""
    property var  _grab: null
    // Motion fill: the shadow lags ~1 frame, so shrink the hole on the trailing side
    // by the last frame's displacement to avoid a gap (0 at rest)
    property real motionX: 0
    property real motionY: 0
    property real maxMotion: 64
    // Fraction of last frame's displacement used as fill (1 = full frame of lag)
    property real motionFill: 1.0
    property real _lx: 0
    property real _ly: 0
    property int  _still: 0
    function nudge() {
        if (ssMotion.running || !ssc.active) return;
        var p = ssc.mapToItem(null, 0, 0);
        _lx = p.x; _ly = p.y; _still = 0;
        ssMotion.running = true;
    }
    onXChanged: nudge()
    onYChanged: nudge()
    FrameAnimation {
        id: ssMotion
        onTriggered: {
            var p0 = ssc.mapToItem(null, 0, 0), p1 = ssc.mapToItem(null, 1, 1);
            var kx = Math.max(0.05, Math.abs(p1.x - p0.x)), ky = Math.max(0.05, Math.abs(p1.y - p0.y));
            var dx = (p0.x - ssc._lx) / kx, dy = (p0.y - ssc._ly) / ky;
            ssc._lx = p0.x; ssc._ly = p0.y;
            if (Math.abs(dx) < 0.05) dx = 0;
            if (Math.abs(dy) < 0.05) dy = 0;
            var mx = dx * ssc.motionFill, my = dy * ssc.motionFill;
            ssc.motionX = Math.max(-ssc.maxMotion, Math.min(ssc.maxMotion, mx));
            ssc.motionY = Math.max(-ssc.maxMotion, Math.min(ssc.maxMotion, my));
            if (dx === 0 && dy === 0) {
                if (++ssc._still >= 3) { running = false; ssc.motionX = 0; ssc.motionY = 0; }
            } else ssc._still = 0;
        }
    }
    // Hole edges (local coords): 1px inset at rest, plus the motion fill on the trailing side
    readonly property real holeL: 1 + Math.max(0, Math.floor(motionX))
    readonly property real holeR: width - 1 - Math.max(0, Math.floor(-motionX))
    readonly property real holeT: 1 + Math.max(0, Math.floor(motionY))
    readonly property real holeB: height - 1 - Math.max(0, Math.floor(-motionY))
    readonly property bool shown: active && opacity > 0.003 && width > 1 && height > 1
                                  && (!useGrab || grabUrl.toString() !== "")
    function regrab() {
        var t = ssc.grabTarget;
        if (!t || !ssc.active || !t.visible || t.width < 1 || t.height < 1) return;
        t.grabToImage(function(r) { ssc._grab = r; ssc.grabUrl = r.url; });
    }
    onGrabTargetChanged: { grabUrl = ""; _grab = null; ssGrabDebounce.restart(); }
    onActiveChanged: if (active) ssGrabDebounce.restart()
    onWidthChanged:  if (useGrab) ssGrabDebounce.restart()
    onHeightChanged: if (useGrab) ssGrabDebounce.restart()
    Component.onCompleted: if (useGrab) ssGrabDebounce.restart()
    Connections {
        target: ssc.grabTarget
        ignoreUnknownSignals: true
        function onVisibleChanged() { if (ssc.grabTarget && ssc.grabTarget.visible) ssGrabDebounce.restart(); }
    }
    Timer { id: ssGrabDebounce; interval: 80; repeat: false; onTriggered: ssc.regrab() }
    Timer {
        interval: Math.max(200, ssc.regrabInterval)
        repeat: true
        running: ssc.useGrab && ssc.regrabInterval > 0 && ssc.active && ssc.opacity > 0.003
                 && !globalState.lockScreenActive && !globalState.wpFullscreenActive
        onTriggered: ssc.regrab()
    }

    Item {
        id: sscSrc
        x: -ssc.pad; y: -ssc.pad
        width: ssc.width + ssc.pad * 2; height: ssc.height + ssc.pad * 2
        visible: false
        layer.enabled: true
        Rectangle {
            opacity: ssc.useGrab ? 0 : 1
            x: ssc.pad - ssc.dil; y: ssc.pad - ssc.dil
            width: ssc.width + ssc.dil * 2; height: ssc.height + ssc.dil * 2
            radius: ssc.radius > 0 ? ssc.radius + ssc.dil : 0
            color: "black"
        }
        Repeater {
            model: ssc.useGrab ? globalState.shellShadowSatOffsets : []
            delegate: Image {
                required property var modelData
                x: ssc.pad + Math.round(modelData[0] * ssc.dil)
                y: ssc.pad + Math.round(modelData[1] * ssc.dil)
                width: ssc.width; height: ssc.height
                source: ssc.grabUrl
                cache: true; smooth: true
            }
        }
    }
    Item {
        id: sscMask
        x: -ssc.pad; y: -ssc.pad
        width: sscSrc.width; height: sscSrc.height
        visible: false
        layer.enabled: true
        Rectangle {
            opacity: ssc.useGrab ? 0 : 1
            x: ssc.pad + ssc.holeL; y: ssc.pad + ssc.holeT
            width: Math.max(0, ssc.holeR - ssc.holeL); height: Math.max(0, ssc.holeB - ssc.holeT)
            radius: Math.max(0, Math.min(ssc.radius - 1, width / 2, height / 2))
            color: "black"
        }
        Image {
            opacity: ssc.useGrab ? 1 : 0
            x: ssc.pad + ssc.holeL; y: ssc.pad + ssc.holeT
            width: Math.max(0, ssc.holeR - ssc.holeL); height: Math.max(0, ssc.holeB - ssc.holeT)
            source: ssc.useGrab ? ssc.grabUrl : ""
            cache: true; smooth: true
        }
    }
    MultiEffect {
        x: -ssc.pad; y: -ssc.pad
        width: sscSrc.width; height: sscSrc.height
        visible: ssc.shown
        source: sscSrc
        autoPaddingEnabled: false
        blurEnabled: true
        blur: 1.0
        blurMax: ssc.thick
        brightness: -1.0
        maskEnabled: true
        maskInverted: true
        maskSource: sscMask
        maskThresholdMin: 0.2308
        maskSpreadAtMin: 0.3
        opacity: globalState.shellShadowIntensity / 100
    }
}
