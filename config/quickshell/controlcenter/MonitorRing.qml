import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../widgets"

// CPU / GPU ring with history of the monitor page
Item {
    id: monRingSlot
    required property string modelData
    readonly property bool isCpu: modelData === "cpu"
    readonly property int pct: isCpu ? globalState.cpuPercent : globalState.gpuPercent
    readonly property int temp: isCpu ? globalState.cpuTemp : globalState.gpuTemp
    readonly property color tempCol: temp < 0 ? pal.muted : temp > 85 ? pal.error : temp > 70 ? pal.accent : pal.primary
    Layout.fillWidth: true
    Layout.fillHeight: true
    Item {
        id: monRingBox
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height)
        height: width
        Canvas {
            anchors.fill: parent
            property var values: monRingSlot.isCpu ? sysMonHist.cpu : sysMonHist.gpu
            property color lineCol: monRing.ringColor
            onValuesChanged: requestPaint()
            onLineColChanged: requestPaint()
            onWidthChanged: requestPaint()
            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                var v = values || [];
                if (v.length < 2 || width <= 0) return;
                var sz = Math.min(width, height);
                var cx = width / 2, cy = height / 2;
                var lw = m3.ringLw(Math.max(4, sz * 0.045));
                var rIn = (sz / 2 - lw / 2 - 1) * 0.91 - lw * 1.6;
                ctx.save();
                ctx.beginPath();
                ctx.arc(cx, cy, rIn, 0, Math.PI * 2);
                ctx.clip();
                var top = cy, bot = cy + rIn, h = bot - top;
                var x0 = cx - rIn, w = rIn * 2;
                var step = w / (sysMonHist.histLen - 1);
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
            id: monRing
            anchors.fill: parent
            pct: Math.max(0, monRingSlot.pct) / 100
            label: monRingSlot.isCpu ? tr("cpu_lbl") : tr("gpu_lbl")
            valueText: monRingSlot.pct >= 0 ? monRingSlot.pct + "%" : tr("gm_na")
            phaseOffset: monRingSlot.isCpu ? 0.0 : 2.4
            running: monPage.ringsLive
            ringColor: monRingSlot.pct >= 90 ? pal.error : m3.ringActive
            trackColor: ringTrackColor()
            labelColor: pal.colorOnSurfVar
            valueColor: pal.colorOnSurface
        }
        Rectangle {
            anchors.left: parent.left; anchors.top: parent.top
            anchors.leftMargin: -4; anchors.topMargin: 0
            width: monTempRow.implicitWidth + 18
            height: 28; radius: 14
            color: globalState.glassMode ? ga(pal.surface, 0.9) : pal.surface
            Rectangle {
                anchors.fill: parent; radius: parent.radius
                color: ga(monRingSlot.tempCol, 0.18)
                border.width: 1.5; border.color: ga(monRingSlot.tempCol, 0.45)
                Behavior on color { M3ColorAnim { duration: m3.durSlow } }
            }
            RowLayout {
                id: monTempRow
                anchors.centerIn: parent
                spacing: 4
                Text { text: ""; font.family: "Material Symbols Rounded"; font.pixelSize: 15; color: monRingSlot.tempCol }
                Text {
                    text: monRingSlot.temp >= 0 ? monRingSlot.temp + "°C" : "—°C"
                    font.family: globalState.fontPrimary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Bold
                    color: pal.colorOnSurface
                }
            }
        }
    }
}
