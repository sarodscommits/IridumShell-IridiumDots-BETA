import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Album art, title and visualizer column of the desktop music widget
Item {
    id: musicArtWrap
    visible: globalState.musicShowAlbumArt
    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
    Layout.row: 0
    Layout.column: 0
    Layout.rowSpan: musicWidgetRoot.isWide ? 3 : 1
    width: musicWidgetColumn.artSize; height: musicWidgetColumn.artSize
    Layout.preferredWidth: musicWidgetColumn.artSize
    Layout.preferredHeight: musicWidgetColumn.artSize

    property real rotOffset: 0
    NumberAnimation {
        id: musicArtRotAnim
        target: musicArtWrap
        property: "rotOffset"
        from: 0; to: Math.PI * 2
        duration: 20000
        loops: Animation.Infinite
        paused: globalState.mediaStatus !== "Playing" || !globalState.musicWidgetEnabled || globalState.lockScreenActive
    }
    Component.onCompleted: musicArtRotAnim.start()

    Rectangle {
        id: musicArtFallback
        anchors.fill: parent
        color: globalState.glassMode ? ga(pal.surface, 0.6) : pal.surface
        visible: musicArtImage.status !== Image.Ready
        layer.enabled: visible
        layer.smooth: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: musicArtMaskFrame
            maskThresholdMin: 0.5
            maskSpreadAtMin: 0.05
        }
    }

    Text {
        anchors.centerIn: parent
        visible: musicArtImage.status !== Image.Ready
        text: "\ue405"
        font.family: "Material Symbols Rounded"
        font.pixelSize: Math.max(16, Math.round(musicArtWrap.width * 0.39))
        color: globalState.glassMode ? ga(pal.colorOnSurfVar, 0.7) : pal.colorOnSurfVar
    }

    Image {
        sourceSize: Qt.size(512, 512)
        id: musicArtImage
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        source: globalState.mediaArtUrl
        asynchronous: true
        layer.enabled: true
        layer.smooth: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: musicArtMaskFrame
            maskThresholdMin: 0.5
            maskSpreadAtMin: 0.05
        }
    }

    Item {
        id: musicArtMaskFrame
        anchors.fill: parent
        clip: true
        visible: false
        layer.enabled: true

        Canvas {
            id: musicArtMaskCanvas
            width: musicArtWrap.width * 1.5
            height: musicArtWrap.height * 1.5
            anchors.centerIn: parent
            rotation: -musicArtWrap.rotOffset * 180 / Math.PI
            onWidthChanged: requestPaint()
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                var cx = width / 2, cy = height / 2;
                var gearR = musicArtWrap.width * 0.38;
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
        id: musicProgressRing
        anchors.fill: parent
        property real pct: globalState.mediaPosition
        Behavior on pct { M3SpringAnim { token: "spatialSlow"; epsilon: 0.002 } }
        property real rotOffset: musicArtWrap.rotOffset
        onPctChanged: requestPaint()
        onRotOffsetChanged: requestPaint()
        property color trackColor: ringTrackColor()
        onTrackColorChanged: requestPaint()
        property real lwK: m3.progressThickness
        onLwKChanged: requestPaint()
        onWidthChanged: requestPaint()
        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            var cx = width / 2, cy = height / 2;
            var gearR = Math.min(width, height) * 0.42;
            var teeth = 12, rBase = gearR * 0.88, amp = gearR * 0.10;
            var asymAmp = gearR * 0.05;
            var steps = 720;
            var ringK = Math.min(width, height) / 248;
            var ringOffset = 14 * ringK;

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
                ctx.strokeStyle = musicProgressRing.trackColor.toString();
                ctx.lineWidth = Math.max(1.5, m3.ringLw(7 * ringK));
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
            ctx.lineWidth = Math.max(1.5, m3.ringLw(7 * ringK));
            ctx.lineCap = "round";
            ctx.stroke();
        }
        Component.onCompleted: requestPaint()
    }
}
