import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Big lockscreen clock (gear, circle or digital)
Canvas {
    readonly property string _palSig: "" + pal.colorOnSurfVar + "|" + pal.colorOnSurface + "|" + pal.primary + "|" + pal.secondaryCont
    on_PalSigChanged: requestPaint()
    id: lockBigClockCanvas
    x: lockContent.clockCX - width / 2
    y: lockContent.clockCY - height / 2
    opacity: lockContent.blurDragging ? 0 : 1
    Behavior on opacity { M3NumberAnim { duration: m3.durFast } }
    readonly property real fitH: Math.min(lockContent.height - 40, (lockContent.width - lockPwArea.width - 56) / 1.12 - 40)
    readonly property real fitV: 2 * (lockContent.height / 2 + 32 - lockSessionRow.topGap - lockContent.stackH)
    readonly property real fitSize: fitV + (fitH - fitV) * lockContent.layoutT
    width:  Math.max(150, Math.min(fitSize, Math.min(546, fitSize) * globalState.lockClockScale))
    Behavior on width { M3SpringAnim { token: "spatialFast" } }
    height: width
    onWidthChanged:  requestPaint()
    onHeightChanged: requestPaint()

    readonly property string style: globalState.lockClockStyle
    readonly property bool analog: style === "gear" || style === "circle"
    readonly property bool showHands: globalState.lockClockShowHands
    readonly property bool showNums:  globalState.lockClockShowNumbers
    onStyleChanged:     requestPaint()
    onShowHandsChanged: requestPaint()
    onShowNumsChanged:  requestPaint()
    readonly property string fontSig: globalState.lockClockFont + "@" + globalState.lockClockFontScale
    onFontSigChanged:   requestPaint()

    property int ch: 0
    property int ch24: 0
    property int cm: 0
    property int cs: 0
    readonly property string hourText: {
        var h = globalState.clockFormat24h ? ch24 : (ch === 0 ? 12 : ch);
        return h < 10 ? "0" + h : "" + h;
    }
    readonly property string minText: cm < 10 ? "0" + cm : "" + cm

    function tick() {
        var d = new Date();
        ch = d.getHours() % 12; ch24 = d.getHours(); cm = d.getMinutes(); cs = d.getSeconds();
        if (analog) requestPaint();
    }

    Timer {
        interval: 1000; repeat: true; triggeredOnStart: true
        running: globalState.lockScreenActive
        onTriggered: lockBigClockCanvas.tick()
    }
    Component.onCompleted: tick()

    Connections { target: globalState; function onGlassModeChanged() { lockBigClockCanvas.requestPaint() } }
    Connections { target: pal; function onSurfaceElevatedChanged() { lockBigClockCanvas.requestPaint() } function onDeskOnSurfaceChanged() { lockBigClockCanvas.requestPaint() } }

    function drawFace(ctx, cx, cy, R, circle) {
        ctx.beginPath();
        if (circle) {
            ctx.arc(cx, cy, R, 0, Math.PI * 2);
        } else {
            var teeth = 12, rBase = R * 0.86, amp = R * 0.14;
            var steps = 720;
            for (var i = 0; i <= steps; i++) {
                var a = (i / steps) * Math.PI * 2;
                var c = Math.cos(teeth / 2 * a);
                var r = rBase + amp * c * c;
                var px = cx + Math.cos(a) * r, py = cy + Math.sin(a) * r;
                if (i === 0) ctx.moveTo(px, py); else ctx.lineTo(px, py);
            }
        }
        ctx.closePath();
        ctx.fillStyle = (globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont)).toString();
        ctx.fill();
    }
    function drawNumbers(ctx, cx, cy, R) {
        ctx.globalAlpha = showHands ? 0.35 : 1.0;
        ctx.fillStyle = pal.deskOnSurface.toString();
        ctx.font = "bold " + Math.round(R * 0.48 * globalState.lockClockFontScale) + "px '" + globalState.lockClockFont + "'";
        ctx.textAlign = "center";
        ctx.textBaseline = "middle";
        var numR = R * 0.66;
        var nums = [[12, -Math.PI / 2], [3, 0], [6, Math.PI / 2], [9, Math.PI]];
        for (var n = 0; n < nums.length; n++)
        ctx.fillText("" + nums[n][0], cx + Math.cos(nums[n][1]) * numR, cy + Math.sin(nums[n][1]) * numR + R * 0.03);
        ctx.globalAlpha = 1;
    }
    function drawHands(ctx, cx, cy, S, k) {
        var hourAngle = ((ch + cm / 60) / 12) * Math.PI * 2 - Math.PI / 2;
        var minAngle  = (cm / 60) * Math.PI * 2 - Math.PI / 2;
        var secAngle  = (cs / 60) * Math.PI * 2 - Math.PI / 2;
        ctx.lineCap = "round";
        ctx.beginPath(); ctx.moveTo(cx, cy);
        ctx.lineTo(cx + Math.cos(hourAngle) * S * k[0], cy + Math.sin(hourAngle) * S * k[0]);
        ctx.strokeStyle = pal.colorOnSurfVar.toString(); ctx.lineWidth = S * k[1]; ctx.stroke();

        ctx.beginPath(); ctx.moveTo(cx, cy);
        ctx.lineTo(cx + Math.cos(minAngle) * S * k[2], cy + Math.sin(minAngle) * S * k[2]);
        ctx.strokeStyle = pal.primary.toString(); ctx.lineWidth = S * k[3]; ctx.stroke();

        ctx.beginPath();
        ctx.arc(cx + Math.cos(secAngle) * S * k[4], cy + Math.sin(secAngle) * S * k[4], S * k[5], 0, Math.PI * 2);
        ctx.fillStyle = pal.colorOnSurfVar.toString(); ctx.fill();

        ctx.beginPath(); ctx.arc(cx, cy, S * k[6], 0, Math.PI * 2);
        ctx.fillStyle = pal.primary.toString(); ctx.fill();
    }
    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        if (!analog) return;
        var cx = width / 2, cy = height / 2;
        var R = Math.min(width, height) * 0.48;
        var circle = style === "circle";
        drawFace(ctx, cx, cy, R, circle);
        if (circle) {
            if (showNums) drawNumbers(ctx, cx, cy, R);
            if (showHands) drawHands(ctx, cx, cy, R, [0.52, 0.15, 0.78, 0.045, 0.84, 0.07, 0.08]);
            return;
        }
        if (showHands) {
            ctx.globalAlpha = showNums ? 0.35 : 1.0;
            drawHands(ctx, cx, cy, R * 0.98, [0.44, 0.115, 0.65, 0.095, 0.66, 0.075, 0.06]);
            ctx.globalAlpha = 1;
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: -parent.width * 0.027
        visible: lockBigClockCanvas.style === "gear" && lockBigClockCanvas.showNums
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: lockBigClockCanvas.hourText
            font.family: globalState.lockClockFont; font.pixelSize: Math.round(lockBigClockCanvas.width * 0.18 * globalState.lockClockFontScale); font.weight: Font.Bold
            color: pal.deskPrimary
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: lockBigClockCanvas.minText
            font.family: globalState.lockClockFont; font.pixelSize: Math.round(lockBigClockCanvas.width * 0.18 * globalState.lockClockFontScale); font.weight: Font.Bold
            color: pal.deskOnSurface
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: -parent.width * 0.09
        opacity: lockBigClockCanvas.style === "digitalV" ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity { M3NumberAnim {} }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: lockBigClockCanvas.hourText
            font.family: globalState.lockClockFont; font.pixelSize: Math.round(lockBigClockCanvas.width * 0.42 * globalState.lockClockFontScale); font.weight: Font.Bold
            color: pal.deskPrimary
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: lockBigClockCanvas.minText
            font.family: globalState.lockClockFont; font.pixelSize: Math.round(lockBigClockCanvas.width * 0.42 * globalState.lockClockFontScale); font.weight: Font.Bold
            color: pal.deskOnSurface
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: parent.width * 0.06
        opacity: lockBigClockCanvas.style === "digitalH" ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity { M3NumberAnim {} }
        Text {
            text: lockBigClockCanvas.hourText
            font.family: globalState.lockClockFont; font.pixelSize: Math.round(lockBigClockCanvas.width * 0.36 * globalState.lockClockFontScale); font.weight: Font.Bold
            color: pal.deskPrimary
        }
        Text {
            text: lockBigClockCanvas.minText
            font.family: globalState.lockClockFont; font.pixelSize: Math.round(lockBigClockCanvas.width * 0.36 * globalState.lockClockFontScale); font.weight: Font.Bold
            color: pal.deskOnSurface
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton | Qt.LeftButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                var p = mapToItem(lockContent, mouse.x, mouse.y);
                lockClockStylePopup.openAt(p.x, p.y);
            } else {
                lockClockStylePopup.shown = false;
            }
            lockNotifPill.expanded = false;
            hiddenInput.forceActiveFocus();
        }
    }
}
