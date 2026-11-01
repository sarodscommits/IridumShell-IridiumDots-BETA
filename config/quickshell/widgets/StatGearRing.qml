import QtQuick
import "../ui"
import "GearRing.js" as GearRing

// Gear-clipped metric ring
Item {
    id: sgr
    property real pct: 0
    property string label: ""
    property string valueText: ""
    property bool running: false
    property real phaseOffset: 0
    property real textOffsetY: 0
    required property color ringColor
    required property color trackColor
    required property color labelColor
    required property color valueColor

    property real shownPct: Math.max(0, Math.min(1, pct))
    Behavior on shownPct { M3SpringAnim { token: "spatialSlow"; epsilon: 0.002 } }

    property real rotOffset: 0
    NumberAnimation {
        id: sgrRotAnim
        target: sgr
        property: "rotOffset"
        from: 0; to: Math.PI * 2
        duration: 20000
        loops: Animation.Infinite
    }
    Component.onCompleted: if (running) sgrRotAnim.start()
    onRunningChanged: {
        if (running) { if (sgrRotAnim.paused) sgrRotAnim.resume(); else if (!sgrRotAnim.running) sgrRotAnim.start(); }
        else if (sgrRotAnim.running) sgrRotAnim.pause();
    }

    Canvas {
        id: sgrCanvas
        anchors.fill: parent
        antialiasing: true
        property real pct: sgr.shownPct
        property real rot: sgr.rotOffset + sgr.phaseOffset
        property color ringCol: ("" + sgr.ringColor) === ("" + m3.error) ? m3.error : m3.ringActive
        property color trackCol: m3.ringTrack
        property real lwK: m3.progressThickness
        onLwKChanged: requestPaint()
        onPctChanged: requestPaint()
        onRotChanged: requestPaint()
        onRingColChanged: requestPaint()
        onTrackColChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()
        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            var s = Math.min(width, height);
            if (s <= 0) return;
            var cx = width / 2, cy = height / 2;
            var lw = Math.max(1.5, m3.ringLw(Math.max(4, s * 0.045)));
            var R = s / 2 - lw / 2 - 1;
            var amp = R * 0.09;
            var rBase = R - amp;
            var teeth = 12, steps = 720;
            var p = Math.min(1, pct);
            var gap = GearRing.gapAngle(p, rBase);
            var start = -Math.PI / 2;
            var fillEnd = start + Math.PI * 2 * p;
            var bgStart = p > 0 ? fillEnd + gap : start;
            var bgSweep = p > 0 ? (Math.PI * 2 * (1 - p)) - gap * 2 : Math.PI * 2;
            GearRing.trackArc(ctx, cx, cy, rBase, bgStart, bgSweep, steps, trackCol, lw);
            if (p <= 0) return;
            var r0 = rot;
            GearRing.gearStroke(ctx, cx, cy, Math.max(1, Math.round(steps * p)), steps, function (aPos) {
                var c = Math.cos(teeth / 2 * (aPos + r0));
                return rBase + amp * c * c;
            }, ringCol, lw);
        }
    }

    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: sgr.textOffsetY
        spacing: 0
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: sgr.label
            font.family: globalState.fontSecondary
            font.pixelSize: Math.max(9, Math.round(sgr.width * 0.11 * globalState.fontScale))
            font.weight: Font.Medium
            color: sgr.labelColor
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: sgr.valueText
            font.family: globalState.fontPrimary
            font.pixelSize: Math.max(12, Math.round(sgr.width * 0.22 * globalState.fontScale))
            font.weight: Font.Bold
            color: sgr.valueColor
        }
    }
}
