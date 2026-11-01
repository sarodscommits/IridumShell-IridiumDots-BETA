import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

// Face of the desktop clock widget
Item {
    id: desktopClockFace
    anchors.fill: parent
    readonly property var faceCanvas: clockWidgetFaceCanvas
    Item {
        id: clockWidgetVisual
        anchors.centerIn: parent
        width: parent.width / globalState.clockWidgetScaleDesktop; height: parent.height / globalState.clockWidgetScaleDesktop
        scale: globalState.clockWidgetScaleDesktop

        Canvas {
            readonly property string _palSig: "" + pal.colorOnSurfVar + "|" + pal.colorOnSurface + "|" + pal.primary + "|" + pal.secondaryCont
            on_PalSigChanged: requestPaint()
            id: clockWidgetFaceCanvas
            anchors.centerIn: parent
            width:  clockWidgetVisual.width  * globalState.clockWidgetScaleDesktop
            height: clockWidgetVisual.height * globalState.clockWidgetScaleDesktop
            scale:  1 / globalState.clockWidgetScaleDesktop
            onWidthChanged:  requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                var cx = width / 2, cy = height / 2;
                var circle = globalState.clockCircleStyleDesktop;
                var showHands = globalState.clockShowHandsDesktop;
                var showNums  = globalState.clockShowNumbersDesktop;
                var gearR = Math.min(width, height) / 2 / 1.02;
                var bg = (globalState.glassMode ? ga(containerDark(pal.secondaryCont), currentFrameOpacity()) : containerDark(pal.secondaryCont)).toString();

                ctx.beginPath();
                if (circle) {
                    ctx.arc(cx, cy, gearR * 1.02, 0, Math.PI * 2);
                } else {
                    var teeth = 12, rBase = gearR * 0.88, amp = gearR * 0.14;
                    var steps = 720;
                    for (var i = 0; i <= steps; i++) {
                        var a = (i / steps) * Math.PI * 2;
                        var c = Math.cos(teeth / 2 * a);
                        var r = rBase + amp * c * c;
                        var px = cx + Math.cos(a) * r;
                        var py = cy + Math.sin(a) * r;
                        if (i === 0) ctx.moveTo(px, py); else ctx.lineTo(px, py);
                    }
                }
                ctx.closePath();
                ctx.fillStyle = bg;
                ctx.fill();

                var ch = clockWidgetRootDesktop.ch, cm = clockWidgetRootDesktop.cm, cs = clockWidgetRootDesktop.cs;
                var hourAngle = ((ch + cm / 60) / 12) * Math.PI * 2 - Math.PI / 2;
                var minAngle  = (cm / 60) * Math.PI * 2 - Math.PI / 2;
                var secAngle  = (cs / 60) * Math.PI * 2 - Math.PI / 2;

                if (circle) {
                    var CR = gearR * 1.02;
                    if (showNums) {
                        ctx.globalAlpha = showHands ? 0.35 : 1.0;
                        ctx.fillStyle = pal.colorOnSurface.toString();
                        ctx.font = "bold " + Math.round(CR * 0.48) + "px '" + globalState.fontPrimary + "'";
                        ctx.textAlign = "center";
                        ctx.textBaseline = "middle";
                        var numR = CR * 0.66;
                        var nums = [[12, -Math.PI / 2], [3, 0], [6, Math.PI / 2], [9, Math.PI]];
                        for (var n = 0; n < nums.length; n++) {
                            ctx.fillText("" + nums[n][0],
                            cx + Math.cos(nums[n][1]) * numR,
                            cy + Math.sin(nums[n][1]) * numR + CR * 0.03);
                        }
                        ctx.globalAlpha = 1;
                    }
                    if (showHands) {
                        ctx.lineCap = "round";
                        ctx.beginPath();
                        ctx.moveTo(cx, cy);
                        ctx.lineTo(cx + Math.cos(hourAngle) * CR * 0.52, cy + Math.sin(hourAngle) * CR * 0.52);
                        ctx.strokeStyle = pal.colorOnSurfVar.toString();
                        ctx.lineWidth = CR * 0.15;
                        ctx.stroke();

                        ctx.beginPath();
                        ctx.moveTo(cx, cy);
                        ctx.lineTo(cx + Math.cos(minAngle) * CR * 0.78, cy + Math.sin(minAngle) * CR * 0.78);
                        ctx.strokeStyle = pal.primary.toString();
                        ctx.lineWidth = CR * 0.045;
                        ctx.stroke();

                        ctx.beginPath();
                        ctx.arc(cx + Math.cos(secAngle) * CR * 0.84, cy + Math.sin(secAngle) * CR * 0.84, CR * 0.07, 0, Math.PI * 2);
                        ctx.fillStyle = pal.colorOnSurfVar.toString();
                        ctx.fill();

                        ctx.beginPath();
                        ctx.arc(cx, cy, CR * 0.08, 0, Math.PI * 2);
                        ctx.fillStyle = pal.primary.toString();
                        ctx.fill();
                    }
                    return;
                }

                if (showHands) {
                    var R = gearR;
                    ctx.globalAlpha = showNums ? 0.35 : 1.0;

                    ctx.beginPath();
                    ctx.moveTo(cx, cy);
                    ctx.lineTo(cx + Math.cos(hourAngle) * R * 0.44, cy + Math.sin(hourAngle) * R * 0.44);
                    ctx.strokeStyle = pal.colorOnSurfVar.toString();
                    ctx.lineWidth = R * 0.115;
                    ctx.lineCap = "round";
                    ctx.stroke();

                    ctx.beginPath();
                    ctx.moveTo(cx, cy);
                    ctx.lineTo(cx + Math.cos(minAngle) * R * 0.65, cy + Math.sin(minAngle) * R * 0.65);
                    ctx.strokeStyle = pal.primary.toString();
                    ctx.lineWidth = R * 0.095;
                    ctx.lineCap = "round";
                    ctx.stroke();

                    ctx.beginPath();
                    ctx.arc(cx + Math.cos(secAngle) * R * 0.66, cy + Math.sin(secAngle) * R * 0.66, R * 0.075, 0, Math.PI * 2);
                    ctx.fillStyle = pal.colorOnSurfVar.toString();
                    ctx.fill();

                    ctx.beginPath();
                    ctx.arc(cx, cy, R * 0.06, 0, Math.PI * 2);
                    ctx.fillStyle = pal.primary.toString();
                    ctx.fill();
                    ctx.globalAlpha = 1;
                }
            }
            Connections {
                target: globalState
                function onGlassModeChanged() { clockWidgetFaceCanvas.requestPaint(); }
                function onGlassQuickshellOpacityChanged() { clockWidgetFaceCanvas.requestPaint(); }
                function onGlassQuickshellEnabledChanged() { clockWidgetFaceCanvas.requestPaint(); }
                function onClockShowHandsDesktopChanged() { clockWidgetFaceCanvas.requestPaint(); }
                function onClockShowNumbersDesktopChanged() { clockWidgetFaceCanvas.requestPaint(); }
                function onClockCircleStyleDesktopChanged() { clockWidgetFaceCanvas.requestPaint(); }
            }
            Connections {
                target: pal
                function onSurfaceElevatedChanged() { clockWidgetFaceCanvas.requestPaint(); }
            }
            Component.onCompleted: requestPaint()
        }

        Column {
            anchors.centerIn: parent
            spacing: -6
            visible: globalState.clockShowNumbersDesktop && !globalState.clockCircleStyleDesktop
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: {
                    var h = clockWidgetRootDesktop.ch;
                    if (!globalState.clockFormat24h) { if (h === 0) h = 12; }
                    else { h = clockWidgetRootDesktop.ch24; }
                    return (h < 10 ? "0" + h : "" + h);
                }
                font.family: globalState.fontPrimary; font.pixelSize: Math.round(40 * globalState.fontScale); font.weight: Font.Bold
                color: pal.primary
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: {
                    var m = clockWidgetRootDesktop.cm;
                    return (m < 10 ? "0" + m : "" + m);
                }
                font.family: globalState.fontPrimary; font.pixelSize: Math.round(40 * globalState.fontScale); font.weight: Font.Bold
                color: pal.colorOnSurface
            }
        }
    }
}
