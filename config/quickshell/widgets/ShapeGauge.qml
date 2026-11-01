import QtQuick
import QtQuick.Shapes
import "../ui"

// Liquid-fill gauge inside a library shape
Item {
    id: gaugeRoot
    required property string shapePath
    property real pct: 0
    property color fillColor:   "#6750A4"
    property color emptyColor:  "#3A3337"
    property color outlineColor:"#938F99"
    property bool glassEmpty: false
    property bool waveEffect: false
    property real wavePhase: 0
    property real fillMin: 0
    property real fillMax: 100

    Behavior on pct { M3SpringAnim { token: "spatialDefault"; epsilon: 0.002 } }

    Shape {
        id: gaugeBgShape
        x: 0; y: 0; width: 100; height: 100
        transformOrigin: Item.TopLeft
        scale: gaugeRoot.width / 100
        antialiasing: true
        preferredRendererType: Shape.CurveRenderer
        opacity: gaugeRoot.glassEmpty ? 0.5 : 1.0
        Behavior on opacity { M3NumberAnim {} }
        ShapePath {
            strokeWidth: 4
            strokeColor: gaugeRoot.outlineColor
            fillColor: gaugeRoot.emptyColor
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.RoundCap
            PathSvg { path: gaugeRoot.shapePath }
        }
    }

    Canvas {
        id: gaugeLiquidCanvas
        anchors.fill: parent
        antialiasing: true
        property real pct: gaugeRoot.pct
        property real phase: gaugeRoot.wavePhase
        property real insetScale: 0.93
        onPctChanged: requestPaint()
        onPhaseChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()

        function tracePath(ctx, d) {
            var toks = d.match(/[MLQAZ]|-?\d*\.?\d+(?:[eE]-?\d+)?/g) || [];
            var i = 0, cmd = "", cx = 0, cy = 0, sx = 0, sy = 0;
            function n() { return parseFloat(toks[i++]); }
            while (i < toks.length) {
                if (/[MLQAZ]/.test(toks[i])) { cmd = toks[i]; i++; }
                switch (cmd) {
                    case "M":
                    cx = n(); cy = n(); sx = cx; sy = cy;
                    ctx.moveTo(cx, cy);
                    cmd = "L";
                    break;
                    case "L":
                    cx = n(); cy = n();
                    ctx.lineTo(cx, cy);
                    break;
                    case "Q": {
                        var qx = n(), qy = n(), ex = n(), ey = n();
                        ctx.quadraticCurveTo(qx, qy, ex, ey);
                        cx = ex; cy = ey;
                        break;
                    }
                    case "A": {
                        var rx = n(), ry = n(), rot = n(), laf = n(), sf = n(), ex2 = n(), ey2 = n();
                        arcTo2(ctx, cx, cy, rx, ry, rot, laf, sf, ex2, ey2);
                        cx = ex2; cy = ey2;
                        break;
                    }
                    case "Z":
                    ctx.closePath();
                    cx = sx; cy = sy;
                    break;
                    default:
                    i++;
                }
            }
        }

        function arcTo2(ctx, x1, y1, rx, ry, rotDeg, laf, sf, x2, y2) {
            if (rx === 0 || ry === 0) { ctx.lineTo(x2, y2); return; }
            rx = Math.abs(rx); ry = Math.abs(ry);
            var phi = rotDeg * Math.PI / 180;
            var cosPhi = Math.cos(phi), sinPhi = Math.sin(phi);
            var dx2 = (x1 - x2) / 2, dy2 = (y1 - y2) / 2;
            var x1p = cosPhi * dx2 + sinPhi * dy2;
            var y1p = -sinPhi * dx2 + cosPhi * dy2;
            var lambda = (x1p * x1p) / (rx * rx) + (y1p * y1p) / (ry * ry);
            if (lambda > 1) { var sc = Math.sqrt(lambda); rx *= sc; ry *= sc; }
            var sign = (laf !== sf) ? 1 : -1;
            var num = rx * rx * ry * ry - rx * rx * y1p * y1p - ry * ry * x1p * x1p;
            var den = rx * rx * y1p * y1p + ry * ry * x1p * x1p;
            var co = sign * Math.sqrt(Math.max(0, num / den));
            var cxp = co * (rx * y1p) / ry;
            var cyp = -co * (ry * x1p) / rx;
            var acx = cosPhi * cxp - sinPhi * cyp + (x1 + x2) / 2;
            var acy = sinPhi * cxp + cosPhi * cyp + (y1 + y2) / 2;
            function ang(ux, uy, vx, vy) {
                var d = Math.sqrt(ux * ux + uy * uy) * Math.sqrt(vx * vx + vy * vy);
                var a = Math.acos(Math.min(1, Math.max(-1, (ux * vx + uy * vy) / d)));
                return (ux * vy - uy * vx < 0) ? -a : a;
            }
            var startAngle = ang(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry);
            var delta = ang((x1p - cxp) / rx, (y1p - cyp) / ry, (-x1p - cxp) / rx, (-y1p - cyp) / ry);
            if (!sf && delta > 0) delta -= 2 * Math.PI;
            if (sf && delta < 0) delta += 2 * Math.PI;
            var endAngle = startAngle + delta;
            if (rotDeg === 0) {
                ctx.arc(acx, acy, rx, startAngle, endAngle, delta < 0);
            } else {
                var steps = 24;
                for (var k = 0; k <= steps; k++) {
                    var a2 = startAngle + (delta * k / steps);
                    var ex3 = acx + rx * Math.cos(a2) * cosPhi - ry * Math.sin(a2) * sinPhi;
                    var ey3 = acy + rx * Math.cos(a2) * sinPhi + ry * Math.sin(a2) * cosPhi;
                    ctx.lineTo(ex3, ey3);
                }
            }
        }

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            if (width <= 0 || height <= 0 || pct <= 0) return;

            ctx.save();
            var s = width / 100;
            ctx.translate(width / 2, height / 2);
            ctx.scale(s * insetScale, s * insetScale);
            ctx.translate(-50, -50);

            ctx.beginPath();
            tracePath(ctx, gaugeRoot.shapePath);
            ctx.closePath();
            ctx.save();
            ctx.clip();

            var fillTop = gaugeRoot.fillMax - (gaugeRoot.fillMax - gaugeRoot.fillMin) * pct;
            var useWave = gaugeRoot.waveEffect && pct > 0.03 && pct < 0.985;
            var amp = useWave ? 2.2 : 0;
            var freq = 4 * Math.PI / 100;
            var ph = phase;

            ctx.beginPath();
            ctx.moveTo(-15, fillTop + Math.sin(-15 * freq + ph) * amp);
            for (var x = -15; x <= 115; x += 2.5) {
                ctx.lineTo(x, fillTop + Math.sin(x * freq + ph) * amp);
            }
            ctx.lineTo(115, 115);
            ctx.lineTo(-15, 115);
            ctx.closePath();
            ctx.fillStyle = gaugeRoot.fillColor.toString();
            ctx.fill();

            ctx.restore();
            ctx.restore();
        }
    }
}
