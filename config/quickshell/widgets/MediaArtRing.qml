import QtQuick
import QtQuick.Effects
import "../ui"
import "GearRing.js" as GearRing

// Album art clipped to a rotating gear with a progress ring
Item {
    id: marRoot

    property string artUrl: ""
    property real   pct: 0
    property bool   running: true
    required property color ringColor
    required property color fallbackColor
    required property color iconColor

    property real rotOffset: 0
    NumberAnimation {
        id: marRotAnim
        target: marRoot
        property: "rotOffset"
        from: 0; to: Math.PI * 2
        duration: 20000
        loops: Animation.Infinite
    }
    Component.onCompleted: if (running) marRotAnim.start()
    onRunningChanged: {
        if (running) { if (marRotAnim.paused) marRotAnim.resume(); else if (!marRotAnim.running) marRotAnim.start(); }
        else if (marRotAnim.running) marRotAnim.pause();
    }

    Rectangle {
        anchors.fill: parent
        color: marRoot.fallbackColor
        visible: marArtImage.status !== Image.Ready
        layer.enabled: visible
        layer.smooth: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: marMaskFrame
            maskThresholdMin: 0.5
            maskSpreadAtMin: 0.05
        }
    }
    Text {
        anchors.centerIn: parent
        visible: marArtImage.status !== Image.Ready
        text: "\ue405"
        font.family: "Material Symbols Rounded"
        font.pixelSize: Math.round(marRoot.width * 0.36)
        color: marRoot.iconColor
    }
    Image {
        sourceSize: Qt.size(512, 512)
        id: marArtImage
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        source: marRoot.artUrl
        asynchronous: true
        layer.enabled: true
        layer.smooth: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: marMaskFrame
            maskThresholdMin: 0.5
            maskSpreadAtMin: 0.05
        }
    }
    Item {
        id: marMaskFrame
        anchors.fill: parent
        clip: true
        visible: false
        layer.enabled: true
        Canvas {
            id: marMaskCanvas
            width: marRoot.width * 1.5
            height: marRoot.height * 1.5
            anchors.centerIn: parent
            rotation: -marRoot.rotOffset * 180 / Math.PI
            onWidthChanged: requestPaint()
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                var cx = width / 2, cy = height / 2;
                var gearR = marRoot.width * 0.38;
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
        id: marRing
        anchors.fill: parent
        property real pct: marRoot.pct
        Behavior on pct { M3SpringAnim { token: "spatialSlow"; epsilon: 0.002 } }
        property real rotOffset: marRoot.rotOffset
        property color ringColor: m3.ringActive
        property color trackColor: m3.ringTrack
        property real lwK: m3.progressThickness
        onLwKChanged: requestPaint()
        onTrackColorChanged: requestPaint()
        onPctChanged: requestPaint()
        onRotOffsetChanged: requestPaint()
        onRingColorChanged: requestPaint()
        onWidthChanged: requestPaint()
        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            var k = Math.min(width, height) / 248;
            var cx = width / 2, cy = height / 2;
            var gearR = Math.min(width, height) * 0.42;
            var teeth = 12, rBase = gearR * 0.88, amp = gearR * 0.10;
            var asymAmp = gearR * 0.05;
            var steps = 720;
            var ringOffset = 14 * k;
            var lw = Math.max(1.5, m3.ringLw(Math.max(3, 7 * k)));
            var gapAngle = GearRing.gapAngle(pct, rBase);
            var fillStartAngle = -Math.PI / 2;
            var fillEndAngle = fillStartAngle + Math.PI * 2 * Math.min(1, pct);
            var bgStart = pct > 0 ? fillEndAngle + gapAngle : fillStartAngle;
            var bgSweep = pct > 0
            ? (Math.PI * 2 - Math.PI * 2 * Math.min(1, pct)) - gapAngle * 2
            : Math.PI * 2;
            GearRing.trackArc(ctx, cx, cy, rBase + ringOffset, bgStart, bgSweep, steps, trackColor, lw);
            if (pct <= 0) return;
            var rot = rotOffset;
            GearRing.gearStroke(ctx, cx, cy, Math.round(steps * Math.min(1, pct)), steps, function (aPos) {
                var aTooth = aPos + rot;
                var c2 = Math.cos(teeth / 2 * aTooth);
                return rBase + amp * c2 * c2 + asymAmp * Math.cos(aTooth) + ringOffset;
            }, ringColor, lw);
        }
        Component.onCompleted: requestPaint()
    }
}
