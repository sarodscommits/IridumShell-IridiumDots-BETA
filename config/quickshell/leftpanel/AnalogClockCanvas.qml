import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Analog clock face of the clock card
Canvas {
    readonly property string _palSig: "" + pal.colorOnSurfVar + "|" + pal.primary + "|" + pal.secondaryCont
    on_PalSigChanged: requestPaint()
    id: analogClockCanvas
    anchors.centerIn: parent

    width:  (clockWidgetItem.clockPeek || clockWidgetItem.clockExpanded) ? clockWidgetItem.width : 240
    height: clockWidgetItem.clockExpanded ? clockWidgetItem.height : ((clockWidgetItem.clockPeek || clockWidgetItem.clockExpanded) ? 224 : 240)
    rotation: (clockWidgetItem.clockPeek || clockWidgetItem.clockExpanded) ? 360 : 0
    Behavior on width    { M3SpringAnim { token: "spatialSlow" } }
    Behavior on height   { M3SpringAnim { token: "spatialSlow" } }
    Behavior on rotation { M3SpringAnim { token: "spatialSlow" } }

    property real shapeT: (clockWidgetItem.clockPeek || clockWidgetItem.clockExpanded) ? 1 : 0
    Behavior on shapeT { M3SpringAnim { token: "spatialSlow"; epsilon: 0.002 } }
    onShapeTChanged: requestPaint()
    onWidthChanged:  requestPaint()
    onHeightChanged: requestPaint()

    property int ch: 0
    property int cm: 0
    property int cs: 0

    Timer {
        interval: 1000; repeat: true; triggeredOnStart: true
        running: globalState.calendarMenuOpen && globalState.leftPanelPage === 0
        onTriggered: {
            var d = new Date();
            analogClockCanvas.ch = d.getHours() % 12;
            analogClockCanvas.cm = d.getMinutes();
            analogClockCanvas.cs = d.getSeconds();
            analogClockCanvas.requestPaint();
        }
    }

    Component.onCompleted: {
        var d = new Date();
        ch = d.getHours() % 12;
        cm = d.getMinutes();
        cs = d.getSeconds();
        requestPaint();
    }

    Connections {
        target: globalState
        function onGlassModeChanged() { analogClockCanvas.requestPaint() }
    }

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);

        var cx = width / 2;
        var cy = height / 2;
        var t  = shapeT;

        var gearR = Math.min(width, height) * 0.42;
        var teeth = 12;
        var rBase = gearR * 0.88;
        var amp   = gearR * 0.14;

        var cornerRc = 32;
        var halfW = width  * 0.5 + cornerRc;
        var halfH = height * 0.5 + cornerRc;

        var steps = 720;
        ctx.beginPath();
        for (var i = 0; i <= steps; i++) {
            var a  = (i / steps) * Math.PI * 2;
            var ca = Math.cos(a), sa = Math.sin(a);

            var c     = Math.cos(teeth / 2 * a);
            var rGear = rBase + amp * c * c;
            var rRect = roundedPolygonRadius(a, rectVertices(halfW, halfH), cornerRc);

            var r  = rGear * (1 - t) + rRect * t;
            var px = cx + ca * r;
            var py = cy + sa * r;
            if (i === 0) ctx.moveTo(px, py); else ctx.lineTo(px, py);
        }
        ctx.closePath();
        var shapeColor = globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont);
        ctx.fillStyle = shapeColor;
        ctx.fill();

        if (t < 0.98) {
            var R = gearR;
            ctx.globalAlpha = 1 - t;

            var hourAngle = ((ch + cm / 60) / 12) * Math.PI * 2 - Math.PI / 2;
            ctx.beginPath();
            ctx.moveTo(cx, cy);
            ctx.lineTo(cx + Math.cos(hourAngle) * R * 0.44, cy + Math.sin(hourAngle) * R * 0.44);
            ctx.strokeStyle = pal.colorOnSurfVar;
            ctx.lineWidth   = R * 0.115;
            ctx.lineCap     = "round";
            ctx.stroke();

            var minAngle = (cm / 60) * Math.PI * 2 - Math.PI / 2;
            ctx.beginPath();
            ctx.moveTo(cx, cy);
            ctx.lineTo(cx + Math.cos(minAngle) * R * 0.65, cy + Math.sin(minAngle) * R * 0.65);
            ctx.strokeStyle = pal.primary;
            ctx.lineWidth   = R * 0.095;
            ctx.lineCap     = "round";
            ctx.stroke();

            var secAngle = (cs / 60) * Math.PI * 2 - Math.PI / 2;
            ctx.beginPath();
            ctx.arc(cx + Math.cos(secAngle) * R * 0.66, cy + Math.sin(secAngle) * R * 0.66, R * 0.075, 0, Math.PI * 2);
            ctx.fillStyle = pal.colorOnSurfVar;
            ctx.fill();

            ctx.beginPath();
            ctx.arc(cx, cy, R * 0.06, 0, Math.PI * 2);
            ctx.fillStyle = pal.primary;
            ctx.fill();

            ctx.globalAlpha = 1;
        }
    }
}
