import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Album art of the Control Center media card
Item {
    id: ncMediaArtWrap
    anchors.left: parent.left
    anchors.leftMargin: 10
    anchors.verticalCenter: parent.verticalCenter
    width: Math.min(260, parent.height - 16)
    height: width

    property real rotOffset: 0
    NumberAnimation {
        id: ncMediaArtRotAnim
        target: ncMediaArtWrap
        property: "rotOffset"
        from: 0; to: Math.PI * 2
        duration: 20000
        loops: Animation.Infinite
        paused: !ncMediaCard.live
    }
    Component.onCompleted: ncMediaArtRotAnim.start()

    Rectangle {
        id: ncMediaArtFallback
        anchors.fill: parent
        color: globalState.glassMode ? ga(pal.surface, 0.6) : pal.surface
        visible: ncMediaArtImage.status !== Image.Ready
        layer.enabled: visible
        layer.smooth: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: ncMediaArtMaskFrame
            maskThresholdMin: 0.5
            maskSpreadAtMin: 0.05
        }
    }

    Text {
        anchors.centerIn: parent
        visible: ncMediaArtImage.status !== Image.Ready
        text: "\ue405"
        font.family: "Material Symbols Rounded"
        font.pixelSize: Math.round(ncMediaArtWrap.width * 0.38)
        color: globalState.glassMode ? ga(pal.colorOnSurfVar, 0.7) : pal.colorOnSurfVar
    }

    Image {
        sourceSize: Qt.size(512, 512)
        id: ncMediaArtImage
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        source: globalState.mediaArtUrl
        asynchronous: true
        layer.enabled: true
        layer.smooth: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: ncMediaArtMaskFrame
            maskThresholdMin: 0.5
            maskSpreadAtMin: 0.05
        }
    }

    Item {
        id: ncMediaArtMaskFrame
        anchors.fill: parent
        clip: true
        visible: false
        layer.enabled: true

        Canvas {
            id: ncMediaArtMaskCanvas
            width: ncMediaArtWrap.width * 1.5
            height: ncMediaArtWrap.height * 1.5
            anchors.centerIn: parent
            rotation: -ncMediaArtWrap.rotOffset * 180 / Math.PI
            onWidthChanged: requestPaint()
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                var cx = width / 2, cy = height / 2;
                var gearR = ncMediaArtWrap.width * 0.38;
                var teeth = 12, rBase = gearR * 0.88, amp = gearR * 0.10;
                var asymAmp = gearR * 0.05;
                var cxAdj = cx - asymAmp / 2;
                var steps = 720;
                ctx.beginPath();
                for (var i = 0; i <= steps; i++) {
                    var a = (i / steps) * Math.PI * 2;
                    var c = Math.cos(teeth / 2 * a);
                    var r = rBase + amp * c * c + asymAmp * Math.cos(a);
                    var px = cxAdj + Math.cos(a) * r;
                    var py = cy + Math.sin(a) * r;
                    if (i === 0) ctx.moveTo(px, py); else ctx.lineTo(px, py);
                }
                ctx.closePath();
                ctx.fillStyle = "#FFFFFF";
                ctx.fill();
            }
            Component.onCompleted: requestPaint()
        }
    }

    Canvas {
        readonly property string _palSig: "" + pal.primary
        on_PalSigChanged: requestPaint()
        id: ncMediaArtRing
        anchors.fill: parent
        property real pct: globalState.mediaPosition
        Behavior on pct { M3SpringAnim { token: "spatialSlow"; epsilon: 0.002 } }
        property real rotOffset: ncMediaArtWrap.rotOffset
        property color trackColor: ringTrackColor()
        onTrackColorChanged: requestPaint()
        property real lwK: m3.progressThickness
        onLwKChanged: requestPaint()
        onPctChanged: requestPaint()
        onRotOffsetChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            var cx = width / 2, cy = height / 2;
            var gearR = Math.min(width, height) * 0.42;
            var teeth = 12, rBase = gearR * 0.88, amp = gearR * 0.10;
            var asymAmp = gearR * 0.05;
            var steps = 720;
            var ringOffset = 14;

            var gapAngle = (pct > 0 && pct < 1) ? Math.min(0.45, 10 / Math.max(1, rBase)) : 0;
            var fillStartAngle = -Math.PI / 2;
            var fillEndAngle = fillStartAngle + Math.PI * 2 * Math.min(1, pct);
            var bgStart = pct > 0 ? fillEndAngle + gapAngle : fillStartAngle;
            var bgSweep = pct > 0
            ? (Math.PI * 2 - Math.PI * 2 * Math.min(1, pct)) - gapAngle * 2
            : Math.PI * 2;
            if (bgSweep > 0.001) {
                var bgSteps = Math.max(2, Math.round(steps * (bgSweep / (Math.PI * 2))));
                var rBg = rBase + ringOffset;
                ctx.beginPath();
                for (var i = 0; i <= bgSteps; i++) {
                    var aPosBg = bgStart + (i / bgSteps) * bgSweep;
                    var pxBg = cx + Math.cos(aPosBg) * rBg;
                    var pyBg = cy + Math.sin(aPosBg) * rBg;
                    if (i === 0) ctx.moveTo(pxBg, pyBg); else ctx.lineTo(pxBg, pyBg);
                }
                ctx.strokeStyle = ncMediaArtRing.trackColor.toString();
                ctx.lineWidth = m3.ringLw(7);
                ctx.lineCap = "round";
                ctx.stroke();
            }

            if (pct <= 0) return;

            var upTo = Math.round(steps * Math.min(1, pct));
            ctx.beginPath();
            for (var j = 0; j <= upTo; j++) {
                var aPos = (j / steps) * Math.PI * 2 - Math.PI / 2;
                var aTooth = aPos + rotOffset;
                var c2 = Math.cos(teeth / 2 * aTooth);
                var r2 = rBase + amp * c2 * c2 + asymAmp * Math.cos(aTooth) + ringOffset;
                var px2 = cx + Math.cos(aPos) * r2;
                var py2 = cy + Math.sin(aPos) * r2;
                if (j === 0) ctx.moveTo(px2, py2); else ctx.lineTo(px2, py2);
            }
            ctx.strokeStyle = m3.ringActive.toString();
            ctx.lineWidth = m3.ringLw(7);
            ctx.lineCap = "round";
            ctx.stroke();
        }
        Component.onCompleted: requestPaint()
    }
}
