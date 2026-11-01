import QtQuick
import "../ui"
import "CavaPaint.js" as CavaPaint

// Desktop cava visualizer (bars or wave) on a screen edge
Item {
    id: cavaRoot
    transform: [
        Scale {
            xScale: desktopWidgetLayer.animScale
            yScale: desktopWidgetLayer.animScale
        },
        Translate {
            x: desktopWidgetLayer.animBoxX
            y: desktopWidgetLayer.animBoxY
        }
    ]

    readonly property string edge: globalState.desktopCavaEdge
    readonly property bool horizontal: edge === "bottom" || edge === "top"
    readonly property bool behindBar: edge === unifiedFrame.barEdge
    readonly property real barCover: behindBar && !unifiedFrame.islandMode
                                     ? unifiedFrame.topBaseH * unifiedFrame.islandAutoHideRevealFactor : 0
    readonly property real splitHalf: behindBar && unifiedFrame.islandMode
                                      ? unifiedFrame.islandRestHalfWidth * unifiedFrame.islandAutoHideRevealFactor : 0
    readonly property real baseThickness: globalState.desktopCavaHeight
    readonly property real thickness: baseThickness + barCover
    readonly property real stripX: edge === "right" ? width - thickness : 0
    readonly property real stripY: edge === "bottom" ? height - thickness : 0
    readonly property real stripW: horizontal ? width : thickness
    readonly property real stripH: horizontal ? thickness : height

    Item {
        x: cavaRoot.stripX; y: cavaRoot.stripY
        width: cavaRoot.stripW; height: cavaRoot.stripH
        clip: true

        Canvas {
            id: cavaCanvas
            anchors.centerIn: parent
            width: cavaRoot.horizontal ? parent.width : parent.height
            height: cavaRoot.thickness
            rotation: cavaRoot.edge === "top" ? 180
                    : cavaRoot.edge === "left" ? 90
                    : cavaRoot.edge === "right" ? -90 : 0

            property var cavaData: cavaRoot.visible ? globalState.desktopCavaBars : []
            property var smoothVals: []
            property bool wasSilent: false
            property color col: pal.primary
            property string style: globalState.desktopCavaStyle
            onCavaDataChanged: requestPaint()
            onColChanged: { wasSilent = false; requestPaint(); }
            onStyleChanged: { wasSilent = false; requestPaint(); }
            onWidthChanged: { wasSilent = false; requestPaint(); }
            onRotationChanged: { wasSilent = false; requestPaint(); }
            onHeightChanged: { wasSilent = false; requestPaint(); }
            property real barCover: cavaRoot.barCover
            property real splitHalf: cavaRoot.splitHalf
            onBarCoverChanged: { wasSilent = false; requestPaint(); }
            onSplitHalfChanged: { wasSilent = false; requestPaint(); }
            property int resolution: globalState.desktopCavaResolution
            onResolutionChanged: { wasSilent = false; requestPaint(); }

            Timer {
                interval: 33; repeat: true
                running: cavaRoot.visible && globalState.desktopCavaStyle === "wave" && globalState.mediaStatus === "Playing"
                onTriggered: cavaCanvas.requestPaint()
            }

            function wavePoints(sm, W, H, base, L) {
                var now = Date.now() / 1000;
                var P = Math.max(8, resolution);
                var inner = W / 2 - L;
                var fade = inner * 0.9;
                var pts = [];
                for (var k = 0; k <= P; k++) {
                    var px = k / P * W;
                    var tt, taper = 1;
                    if (px <= L) tt = px / L * 0.5;
                    else if (px >= W - L) tt = 0.5 + (px - (W - L)) / L * 0.5;
                    else tt = 0.5;
                    if (inner > 0.5) {
                        var dist = Math.abs(px - W / 2);
                        var e = Math.max(0, Math.min(1, (dist - inner * 0.9) / (fade + inner * 0.1)));
                        taper = e * e * (3 - 2 * e);
                    }
                    var v = CavaPaint.valAt(sm, tt);
                    var ripple = CavaPaint.ripple(v, tt, now);
                    var hgt = barCover + Math.max(0, Math.min(1, v * 0.92 + ripple + 0.02)) * base * taper;
                    pts.push({ x: px, y: H - hgt });
                }
                return pts;
            }
            function drawWave(ctx, sm, W, H, base, L) {
                CavaPaint.fillCurve(ctx, wavePoints(sm, W, H, base, L), W, H);
            }
            function drawBars(ctx, sm, W, H, base, L) {
                var N = Math.max(8, resolution);
                if (N % 2 === 1) N++;
                var gap = Math.max(1, Math.min(4, W / N * 0.18));
                var Nh = N / 2;
                var R = Math.max(1, L - gap / 2);
                var bw = Math.max(2, (R - (Nh - 1) * gap) / Nh);
                for (var i = 0; i < N; i++) {
                    var vb = CavaPaint.valAt(sm, (i + 0.5) / N);
                    var x = i < Nh ? i * (bw + gap)
                                   : (W - R) + (i - Nh) * (bw + gap);
                    CavaPaint.roundedBar(ctx, x, bw, H, barCover + Math.max(3, Math.min(1, vb) * base * 0.95));
                }
            }
            onPaint: {
                var ctx = getContext("2d");
                if (!ctx || width <= 0 || height <= 0) return;
                var res = CavaPaint.smooth(globalState.desktopCavaBars, smoothVals);
                smoothVals = res.vals;
                var silent = res.silent;
                if (silent && wasSilent) return;
                wasSilent = silent;
                ctx.clearRect(0, 0, width, height);
                var sm = smoothVals;
                if (sm.length === 0) return;
                var H = height, W = width;
                var base = Math.max(1, H - barCover);
                var L = Math.max(1, W / 2 - Math.max(0, Math.min(W / 2 - 1, splitHalf)));
                ctx.fillStyle = CavaPaint.fillCss(col);
                if (style === "wave") drawWave(ctx, sm, W, H, base, L);
                else drawBars(ctx, sm, W, H, base, L);
            }
        }
    }
}
