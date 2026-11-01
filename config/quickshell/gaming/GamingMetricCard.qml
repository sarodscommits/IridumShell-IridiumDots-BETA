import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Metric card with sparkline of the gaming panel
Rectangle {
    id: gmCard
    required property string modelData
    required property int index
    readonly property string key: modelData
    readonly property bool isPing: key === "ping"
    readonly property bool isFps: key === "fps"
    readonly property bool wideLast: !isFps && index === gmMetricRepeater.count - 1
    && ((gmMetricRepeater.count - (gmMetricRepeater.model.indexOf("fps") >= 0 ? 1 : 0)) % 2 === 1)
    readonly property bool autoScale: isPing || isFps
    Layout.columnSpan: (isFps || wideLast) ? 2 : 1
    readonly property real value: isFps ? (globalState.gamingFpsLive ? globalState.gamingFps : -1)
    : key === "cpu" ? globalState.cpuPercent
    : key === "gpu" ? globalState.gpuPercent
    : key === "ram" ? globalState.ramPercent
    : globalState.gamingPingMs
    readonly property int temp: key === "cpu" ? globalState.cpuTemp : key === "gpu" ? globalState.gpuTemp : -1
    readonly property var hist: key === "cpu" ? gmTelemetry.histCpu
    : key === "gpu" ? gmTelemetry.histGpu
    : key === "ram" ? gmTelemetry.histRam
    : isFps ? gmTelemetry.histFps
    : gmTelemetry.histPing
    readonly property color accentCol: {
        if (isFps) {
            if (value < 0) return gmMetricRepeater._onSurfVar;
            return value < 30 ? gmMetricRepeater._error : value < 55 ? gmMetricRepeater._accent : gmMetricRepeater._primary;
        }
        if (isPing) {
            var ms = globalState.gamingPingMs, lost = globalState.gamingPingLost;
            return (lost || ms > 120) ? gmMetricRepeater._error : ms > 60 ? gmMetricRepeater._accent : gmMetricRepeater._primary;
        }
        return value >= 90 ? gmMetricRepeater._error : value >= 75 ? gmMetricRepeater._accent : gmMetricRepeater._primary;
    }
    Layout.fillWidth: true
    Layout.preferredWidth: 1
    implicitHeight: isFps ? 114 : 104
    radius: 20
    color: gamingWindow.floatLayout ? ga(gmMetricRepeater._card, gamingWindow.floatAlpha)
    : gmMetricRepeater._glass ? ga(gmMetricRepeater._card, 0.6) : gmMetricRepeater._card
    Behavior on color { M3ColorAnim { duration: m3.durFast } }

    RowLayout {
        id: gmCardTop
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        anchors.leftMargin: 16; anchors.rightMargin: 16; anchors.topMargin: 12
        spacing: 12
        Rectangle {
            width: 32; height: 32; radius: 16
            color: ga(gmCard.accentCol, 0.16)
            Behavior on color { M3ColorAnim { duration: m3.durSlow } }
            FadeIcon {
                anchors.centerIn: parent
                text: gmCard.isFps ? "\uf190" : gmCard.key === "cpu" ? "" : gmCard.key === "gpu" ? "" : gmCard.key === "ram" ? "" : ""
                font.family: "Material Symbols Rounded"; font.pixelSize: 18
                color: gmCard.accentCol
                Behavior on color { M3ColorAnim { duration: m3.durSlow } }
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: -2
            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: gmCard.isFps ? ("FPS" + (globalState.gamingFpsGame !== "" ? " · " + globalState.gamingFpsGame : ""))
                : gmCard.key === "cpu" ? tr("cpu_lbl") : gmCard.key === "gpu" ? tr("gpu_lbl") : gmCard.key === "ram" ? tr("gm_ram") : tr("gm_ping")
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium
                color: gmMetricRepeater._onSurfVar
            }
            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: {
                    if (gmCard.isFps)
                    return gmCard.value < 0 ? tr("gm_fps_none") : Math.round(gmCard.value) + " FPS";
                    if (gmCard.isPing) {
                        if (globalState.gamingPingLost) return tr("gm_lost");
                        if (gmCard.value < 0) return "— ms";
                        return (gmCard.value < 10 ? gmCard.value.toFixed(1) : Math.round(gmCard.value)) + " ms";
                    }
                    if (gmCard.value < 0) return tr("gm_na");
                    return Math.round(gmCard.value) + "%";
                }
                font.family: globalState.fontPrimary; font.pixelSize: Math.round((gmCard.isFps && gmCard.value >= 0 ? 24 : 20) * globalState.fontScale); font.weight: Font.Bold
                color: gmMetricRepeater._onSurf
            }
        }
        Rectangle {
            readonly property string txt: {
                if (gmCard.isFps) return gmCard.value >= 0 && globalState.gamingFrametime >= 0 ? globalState.gamingFrametime.toFixed(1) + " ms" : "Shift+F2";
                if (gmCard.key === "ram") return (globalState.ramUsedMb / 1024).toFixed(1) + " GB";
                if (gmCard.isPing) return gmTelemetry.pingHost;
                return gmCard.temp >= 0 ? gmCard.temp + "°C" : "—°C";
            }
            readonly property color col: (gmCard.temp >= 0)
            ? (gmCard.temp > 85 ? gmMetricRepeater._error : gmCard.temp > 70 ? gmMetricRepeater._accent : gmMetricRepeater._primary)
            : gmMetricRepeater._onSurfVar
            implicitWidth: gmChipRow.implicitWidth + 16
            height: 28; radius: 8
            color: ga(col, 0.14)
            RowLayout {
                id: gmChipRow
                anchors.centerIn: parent
                spacing: 4
                Text {
                    visible: false
                    text: ""; font.family: "Material Symbols Rounded"; font.pixelSize: 14
                    color: parent.parent.col
                }
                Text {
                    text: parent.parent.txt
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.DemiBold
                    color: parent.parent.col
                }
            }
        }
    }
    Canvas {
        id: gmSpark
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        anchors.leftMargin: 16; anchors.rightMargin: 16; anchors.bottomMargin: 12
        height: gmCard.isFps ? 40 : 30
        property var values: gmCard.hist
        property color lineCol: gmCard.accentCol
        property color lostCol: gmMetricRepeater._error
        onValuesChanged: requestPaint()
        onLineColChanged: requestPaint()
        onWidthChanged: requestPaint()
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            var v = values || [];
            var n = gmTelemetry.histLen;
            if (v.length < 2) return;
            var maxV = 100;
            if (gmCard.autoScale) {
                maxV = gmCard.isFps ? 60 : 50;
                for (var q = 0; q < v.length; q++) if (v[q] > maxV) maxV = v[q];
                maxV *= 1.15;
            }
            var w = width, h = height;
            var step = w / (n - 1);
            var x0 = w - (v.length - 1) * step;
            function yOf(val) { return h - 1 - Math.max(0, Math.min(1, val / maxV)) * (h - 3); }
            ctx.beginPath();
            ctx.moveTo(x0, h);
            for (var i = 0; i < v.length; i++) ctx.lineTo(x0 + i * step, yOf(Math.max(0, v[i])));
            ctx.lineTo(x0 + (v.length - 1) * step, h);
            ctx.closePath();
            var g = ctx.createLinearGradient(0, 0, 0, h);
            g.addColorStop(0, Qt.rgba(lineCol.r, lineCol.g, lineCol.b, 0.30));
            g.addColorStop(1, Qt.rgba(lineCol.r, lineCol.g, lineCol.b, 0.02));
            ctx.fillStyle = g;
            ctx.fill();
            ctx.beginPath();
            for (var j = 0; j < v.length; j++) {
                var px = x0 + j * step, py = yOf(Math.max(0, v[j]));
                if (j === 0) ctx.moveTo(px, py); else ctx.lineTo(px, py);
            }
            ctx.lineWidth = 2;
            ctx.lineJoin = "round";
            ctx.strokeStyle = lineCol;
            ctx.stroke();
            if (gmCard.isPing) {
                ctx.fillStyle = lostCol;
                for (var l = 0; l < v.length; l++)
                if (v[l] < 0) { ctx.beginPath(); ctx.arc(x0 + l * step, h - 3, 2.2, 0, Math.PI * 2); ctx.fill(); }
            }
        }
    }
}
