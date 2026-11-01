import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Audio visualizer card of the overview dashboard
Rectangle {
    id: ncDashAudioCard
    opacity: ncDashLayer.opacity
    visible: ncDashLayer.visible && ncDashLayer.shown("aud")
    x: ncDashLayer.rAud.x
    y: ncDashLayer.rAud.y
    Behavior on y { enabled: globalState.ncEditMode; M3SpringAnim { token: "spatialDefault" } }
    width: ncDashLayer.rAud.width
    height: ncDashLayer.rAud.height
    radius: 28
    color: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont)
    Canvas {
        id: ncDashCavaCanvas
        anchors.fill: parent
        anchors.leftMargin: 18; anchors.rightMargin: 18
        anchors.topMargin: 18; anchors.bottomMargin: 16
        opacity: 0.28
        property var cavaData: ncPage1Group.live ? globalState.cavaBars : []
        property color walColorA: pal.primary
        onCavaDataChanged: requestPaint()
        onWalColorAChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            var ctx = getContext("2d");
            if (!ctx || width <= 0 || height <= 0) return;
            ctx.clearRect(0, 0, width, height);
            function resample(arr, targetLen) {
                if (arr.length === 0) return [];
                if (arr.length === 1) return new Array(targetLen).fill(arr[0]);
                var out = [];
                for (var k = 0; k < targetLen; k++) {
                    var pos = (k / (targetLen - 1)) * (arr.length - 1);
                    var lo = Math.floor(pos), hi = Math.min(arr.length - 1, lo + 1);
                    var frac = pos - lo;
                    out.push(arr[lo] * (1 - frac) + arr[hi] * frac);
                }
                return out;
            }
            var srcBars = globalState.cavaBars;
            if (srcBars.length === 0) return;
            var bars = resample(srcBars, Math.max(8, srcBars.length + 4));
            var N = bars.length;
            var maxH = height;
            var stepX = width / (N - 1);
            function parseC(col) {
                var s = col.toString().replace("#", "");
                if (s.length === 3) s = s[0]+s[0]+s[1]+s[1]+s[2]+s[2];
                return [parseInt(s.substr(0,2),16), parseInt(s.substr(2,2),16), parseInt(s.substr(4,2),16)];
            }
            var cA = parseC(ncDashCavaCanvas.walColorA);
            var r = cA[0], g = cA[1], b = cA[2];
            var pts = [];
            for (var i = 0; i < N; i++) {
                var v = Math.max(0, Math.min(1, bars[i] || 0));
                pts.push({ x: i * stepX, y: maxH - Math.max(2, v * maxH * 0.92) });
            }
            ctx.beginPath();
            ctx.moveTo(0, maxH);
            ctx.lineTo(pts[0].x, pts[0].y);
            for (var j = 0; j < N - 1; j++) {
                var mx = (pts[j].x + pts[j + 1].x) / 2;
                var my = (pts[j].y + pts[j + 1].y) / 2;
                ctx.quadraticCurveTo(pts[j].x, pts[j].y, mx, my);
            }
            ctx.quadraticCurveTo(pts[N - 1].x, pts[N - 1].y, pts[N - 1].x, pts[N - 1].y);
            ctx.lineTo(width, maxH);
            ctx.closePath();
            var grad = ctx.createLinearGradient(0, 0, 0, maxH);
            grad.addColorStop(0, "rgba(" + r + "," + g + "," + b + ",0.95)");
            grad.addColorStop(1, "rgba(" + r + "," + g + "," + b + ",0.15)");
            ctx.fillStyle = grad;
            ctx.fill();
            ctx.beginPath();
            ctx.moveTo(pts[0].x, pts[0].y);
            for (var q = 0; q < N - 1; q++) {
                var mx2 = (pts[q].x + pts[q + 1].x) / 2;
                var my2 = (pts[q].y + pts[q + 1].y) / 2;
                ctx.quadraticCurveTo(pts[q].x, pts[q].y, mx2, my2);
            }
            ctx.lineTo(pts[N - 1].x, pts[N - 1].y);
            ctx.strokeStyle = "rgba(" + r + "," + g + "," + b + ",1)";
            ctx.lineWidth = 2;
            ctx.stroke();
        }
    }
    RowLayout {
        anchors.left: parent.left; anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14
        spacing: 10
        Rectangle {
            width: 30; height: 30; radius: 15
            color: ga(pal.primary, 0.18)
            Text { anchors.centerIn: parent; text: "\ue01d"; font.family: "Material Symbols Rounded"; font.pixelSize: 17; color: pal.primary }
        }
        Text { Layout.fillWidth: true; text: tr("equalizer"); font.family: globalState.fontPrimary; font.pixelSize: Math.round(15 * globalState.fontScale); font.weight: Font.Bold; color: pal.colorOnSurface; elide: Text.ElideRight }
        Text {
            Layout.maximumWidth: parent.width * 0.5
            text: rightPanelContent.mediaPanel.eqActivePreset
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); color: pal.colorOnSurfVar
            elide: Text.ElideRight
        }
    }
}
