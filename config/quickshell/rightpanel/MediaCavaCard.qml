import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."

// Cava visualizer card of the media panel
Rectangle {
    id: mediaCavaCard
    property alias cavaCanvas: cavaCanvas
    Layout.fillWidth: true
    Layout.preferredHeight: 140
    radius: 16
    color: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont)
    clip: true

    Canvas {
        readonly property string _palSig: "" + pal.primary + "|" + pal.tertiary
        on_PalSigChanged: requestPaint()
        id: cavaCanvas
        anchors.fill: parent
        anchors.margins: 8
        property var cavaData: globalState.cavaBars
        property color walColorA: pal.primary
        property color walColorB: pal.accent
        property color walColorC: pal.error
        onCavaDataChanged: requestPaint()
        onWalColorAChanged: requestPaint()
        onWalColorBChanged: requestPaint()
        onWalColorCChanged: requestPaint()
        onWidthChanged:    requestPaint()
        onHeightChanged:   requestPaint()
        onPaint: {
            var ctx = getContext("2d");
            if (!ctx) return;
            if (width <= 0 || height <= 0) return;
            ctx.clearRect(0, 0, width, height);
            var N = globalState.cavaBars.length;
            if (N === 0) return;
            var gap  = 2;
            var barW = Math.max(1, (width - (N - 1) * gap) / N);
            var maxH = height;

            for (var i = 0; i < N; i++) {
                var v = globalState.cavaBars[i] || 0;
                var barH = Math.max(2, v * maxH);
                var x = i * (barW + gap);
                var y = maxH - barH;

                var t = v;
                function hexC(c) {
                    var h = c.toString(16);
                    return h.length === 1 ? "0" + h : h;
                }
                function parseC(col) {
                    var s = col.toString().replace("#","");
                    if (s.length === 3) s = s[0]+s[0]+s[1]+s[1]+s[2]+s[2];
                    return [parseInt(s.substr(0,2),16), parseInt(s.substr(2,2),16), parseInt(s.substr(4,2),16)];
                }
                var cA = parseC(cavaCanvas.walColorA);
                var r, g, b;
                r = cA[0]; g = cA[1]; b = cA[2];

                var grad = ctx.createLinearGradient(x, y, x, maxH);
                grad.addColorStop(0, "rgba(" + r + "," + g + "," + b + ",0.90)");
                grad.addColorStop(1, "rgba(" + r + "," + g + "," + b + ",0.10)");
                ctx.fillStyle = grad;

                var cr = Math.min(Math.floor(barW / 2), 3);
                if (cr < 1 || barW < cr * 2) {
                    ctx.fillRect(x, y, barW, barH);
                } else {
                    ctx.beginPath();
                    ctx.moveTo(x + cr, y);
                    ctx.lineTo(x + barW - cr, y);
                    ctx.arc(x + barW - cr, y + cr, cr, -Math.PI/2, 0);
                    ctx.lineTo(x + barW, maxH);
                    ctx.lineTo(x, maxH);
                    ctx.arc(x + cr, y + cr, cr, Math.PI, -Math.PI/2);
                    ctx.closePath();
                    ctx.fill();
                }
            }
        }
    }
}
