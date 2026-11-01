import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../widgets"

// CPU/GPU usage rings of the gaming panel
RowLayout {
    id: gamingRings
    visible: gamingWindow.modOn("rings")
    Layout.fillWidth: true
    spacing: 12
    Repeater {
        id: gmRingRepeater
        model: ["cpu", "gpu"]
        property color _primary:   pal.primary
        property color _track:     ringTrackColor()
        property color _onSurf:    pal.colorOnSurface
        property color _onSurfVar: pal.colorOnSurfVar
        property color _error:     pal.error
        property color _accent:    pal.accent
        property color _muted:     pal.muted
        property color _surface:   pal.surfacePop
        delegate: ColumnLayout {
            id: gmRingCol
            required property string modelData
            readonly property bool isCpu: modelData === "cpu"
            readonly property int pct: isCpu ? globalState.cpuPercent : globalState.gpuPercent
            readonly property int temp: isCpu ? globalState.cpuTemp : globalState.gpuTemp
            readonly property color tempCol: temp < 0 ? gmRingRepeater._muted
            : temp > 85 ? gmRingRepeater._error : temp > 70 ? gmRingRepeater._accent : gmRingRepeater._primary
            Layout.fillWidth: true
            spacing: 0
            Item { Layout.fillWidth: true; Layout.preferredHeight: 0 }
            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 176; Layout.preferredHeight: 176
                Canvas {
                    id: gmRingSpark
                    anchors.fill: parent
                    property var values: gmRingCol.isCpu ? gmTelemetry.histCpu : gmTelemetry.histGpu
                    property color lineCol: gmRing.ringColor
                    onValuesChanged: requestPaint()
                    onLineColChanged: requestPaint()
                    onWidthChanged: requestPaint()
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        var v = values || [];
                        if (v.length < 2) return;
                        var s = Math.min(width, height);
                        var cx = width / 2, cy = height / 2;
                        var lw = m3.ringLw(Math.max(4, s * 0.045));
                        var rIn = (s / 2 - lw / 2 - 1) * 0.91 - lw * 1.6;
                        ctx.save();
                        ctx.beginPath();
                        ctx.arc(cx, cy, rIn, 0, Math.PI * 2);
                        ctx.clip();
                        var top = cy, bot = cy + rIn;
                        var h = bot - top;
                        var x0 = cx - rIn, w = rIn * 2;
                        var n = gmTelemetry.histLen;
                        var step = w / (n - 1);
                        var xs = x0 + w - (v.length - 1) * step;
                        function yOf(val) { return bot - 2 - Math.max(0, Math.min(1, val / 100)) * (h - 4); }
                        ctx.beginPath();
                        ctx.moveTo(xs, bot);
                        for (var i = 0; i < v.length; i++) ctx.lineTo(xs + i * step, yOf(Math.max(0, v[i])));
                        ctx.lineTo(xs + (v.length - 1) * step, bot);
                        ctx.closePath();
                        var g = ctx.createLinearGradient(0, top, 0, bot);
                        g.addColorStop(0, Qt.rgba(lineCol.r, lineCol.g, lineCol.b, 0.28));
                        g.addColorStop(1, Qt.rgba(lineCol.r, lineCol.g, lineCol.b, 0.03));
                        ctx.fillStyle = g;
                        ctx.fill();
                        ctx.beginPath();
                        for (var j = 0; j < v.length; j++) {
                            var px = xs + j * step, py = yOf(Math.max(0, v[j]));
                            if (j === 0) ctx.moveTo(px, py); else ctx.lineTo(px, py);
                        }
                        ctx.lineWidth = 2;
                        ctx.lineJoin = "round";
                        ctx.strokeStyle = Qt.rgba(lineCol.r, lineCol.g, lineCol.b, 0.6);
                        ctx.stroke();
                        ctx.restore();
                    }
                }
                StatGearRing {
                    id: gmRing
                    anchors.fill: parent
                    pct: Math.max(0, gmRingCol.pct) / 100
                    label: gmRingCol.isCpu ? tr("cpu_lbl") : tr("gpu_lbl")
                    valueText: gmRingCol.pct >= 0 ? gmRingCol.pct + "%" : tr("gm_na")
                    phaseOffset: gmRingCol.isCpu ? 0.0 : 2.4
                    running: gamingWindow.shown && !gamingWindow.animating && !globalState.wpFullscreenActive
                    ringColor: gmRingCol.pct >= 90 ? gmRingRepeater._error : gmRingRepeater._primary
                    trackColor: gmRingRepeater._track
                    labelColor: gmRingRepeater._onSurfVar
                    valueColor: gmRingRepeater._onSurf
                }
                Rectangle {
                    anchors.left: parent.left; anchors.top: parent.top
                    anchors.leftMargin: -6; anchors.topMargin: 2
                    width: gmTempRow.implicitWidth + 22
                    height: 34; radius: 17
                    color: globalState.glassMode ? ga(gmRingRepeater._surface, 0.9) : gmRingRepeater._surface
                    Rectangle {
                        anchors.fill: parent; radius: parent.radius
                        color: ga(gmRingCol.tempCol, 0.18)
                        border.width: 1.5; border.color: ga(gmRingCol.tempCol, 0.45)
                        Behavior on color { M3ColorAnim { duration: m3.durSlow } }
                    }
                    RowLayout {
                        id: gmTempRow
                        anchors.centerIn: parent
                        spacing: 5
                        Text { text: ""; font.family: "Material Symbols Rounded"; font.pixelSize: 18; color: gmRingCol.tempCol }
                        Text {
                            text: gmRingCol.temp >= 0 ? gmRingCol.temp + "°C" : "—°C"
                            font.family: globalState.fontPrimary; font.pixelSize: Math.round(14 * globalState.fontScale); font.weight: Font.Bold
                            color: gmRingRepeater._onSurf
                        }
                    }
                }
            }
        }
    }
}
