import QtQuick
import "../widgets/CavaPaint.js" as CavaPaint
import Quickshell
import Quickshell.Wayland
import ".."

// Lockscreen cava visualizer
Item {
    id: lockCavaVis
    anchors.fill: parent
    visible: globalState.lockCavaEnabled
    readonly property string edge: globalState.lockCavaEdge
    readonly property bool horizontal: edge === "bottom" || edge === "top"
    readonly property real thickness: 212
    readonly property real stripX: edge === "right" ? width - thickness : 0
    readonly property real stripY: edge === "bottom" ? height - thickness : 0
    readonly property real stripW: horizontal ? width : thickness
    readonly property real stripH: horizontal ? thickness : height

    Item {
        x: lockCavaVis.stripX; y: lockCavaVis.stripY
        width: lockCavaVis.stripW; height: lockCavaVis.stripH
        clip: true
        opacity: 0.85

        Canvas {
            id: lockCavaCanvas
            anchors.centerIn: parent
            width: lockCavaVis.horizontal ? parent.width : parent.height
            height: lockCavaVis.thickness
            rotation: lockCavaVis.edge === "top" ? 180
            : lockCavaVis.edge === "left" ? 90
            : lockCavaVis.edge === "right" ? -90 : 0

            property var cavaData: lockCavaVis.visible ? globalState.desktopCavaBars : []
            property var smoothVals: []
            property bool wasSilent: false
            property color col: pal.primary
            property string style: globalState.lockCavaStyle
            onCavaDataChanged: requestPaint()
            onColChanged: { wasSilent = false; requestPaint(); }
            onStyleChanged: { wasSilent = false; requestPaint(); }
            onWidthChanged: { wasSilent = false; requestPaint(); }
            onRotationChanged: { wasSilent = false; requestPaint(); }

            Timer {
                interval: 33; repeat: true
                running: lockCavaVis.visible && globalState.lockCavaStyle === "wave" && globalState.mediaStatus === "Playing"
                onTriggered: lockCavaCanvas.requestPaint()
            }

            function drawWave(ctx, sm, W, H) {
                var now = Date.now() / 1000;
                var P = Math.max(24, Math.round(W / 14));
                var pts = [];
                for (var k = 0; k <= P; k++) {
                    var tt = k / P;
                    var v = CavaPaint.valAt(sm, tt);
                    var hgt = Math.max(0, Math.min(1, v * 0.92 + CavaPaint.ripple(v, tt, now) + 0.02)) * H;
                    pts.push({ x: tt * W, y: H - hgt });
                }
                CavaPaint.fillCurve(ctx, pts, W, H);
            }
            function drawBars(ctx, sm, W, H) {
                var N = Math.max(16, Math.min(96, Math.round(W / 22)));
                if (N % 2 === 1) N++;
                var gap = 4;
                var bw = Math.max(2, (W - (N - 1) * gap) / N);
                for (var i = 0; i < N; i++) {
                    var vb = CavaPaint.valAt(sm, (i + 0.5) / N);
                    CavaPaint.roundedBar(ctx, i * (bw + gap), bw, H, Math.max(3, Math.min(1, vb) * H * 0.95));
                }
            }
            onPaint: {
                var ctx = getContext("2d");
                if (!ctx || width <= 0 || height <= 0) return;
                var res = CavaPaint.smooth(globalState.desktopCavaBars, smoothVals);
                smoothVals = res.vals;
                if (res.silent && wasSilent) return;
                wasSilent = res.silent;
                ctx.clearRect(0, 0, width, height);
                if (res.vals.length === 0) return;
                ctx.fillStyle = CavaPaint.fillCss(col);
                if (style === "wave") drawWave(ctx, res.vals, width, height);
                else drawBars(ctx, res.vals, width, height);
            }
        }
    }
}
