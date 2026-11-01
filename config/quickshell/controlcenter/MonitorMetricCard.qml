import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// RAM / ping card with sparkline of the monitor page
Rectangle {
    id: metCard
    required property string modelData
    readonly property bool isPing: modelData === "ping"
    readonly property real value: isPing ? globalState.gamingPingMs : globalState.ramPercent
    readonly property color accentCol: isPing
    ? ((globalState.gamingPingLost || value > 120) ? pal.error : value > 60 ? pal.accent : pal.primary)
    : (value >= 90 ? pal.error : value >= 75 ? pal.accent : pal.primary)
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.preferredWidth: 1
    Layout.preferredHeight: 10
    radius: 22
    color: globalState.glassMode ? ga(pal.surface, 0.5) : pal.surface
    clip: true
    RowLayout {
        id: metTop
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        anchors.leftMargin: 12; anchors.rightMargin: 12; anchors.topMargin: 10
        spacing: 8
        Rectangle {
            visible: metCard.width >= 150
            width: 28; height: 28; radius: 14
            color: ga(metCard.accentCol, 0.16)
            FadeIcon {
                anchors.centerIn: parent
                text: metCard.isPing ? "" : ""
                font.family: "Material Symbols Rounded"; font.pixelSize: 17
                color: metCard.accentCol
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: -2
            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: metCard.isPing ? tr("gm_ping") + " · " + sysMonHist.pingHost
                : tr("gm_ram") + " · " + (globalState.ramUsedMb / 1024).toFixed(1) + " GB"
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium
                color: pal.colorOnSurfVar
            }
            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: {
                    if (metCard.isPing) {
                        if (globalState.gamingPingLost) return tr("gm_lost");
                        if (metCard.value < 0) return "— ms";
                        return (metCard.value < 10 ? metCard.value.toFixed(1) : Math.round(metCard.value)) + " ms";
                    }
                    return Math.round(metCard.value) + "%";
                }
                font.family: globalState.fontPrimary; font.pixelSize: Math.round(18 * globalState.fontScale); font.weight: Font.Bold
                color: pal.colorOnSurface
            }
        }
    }
    Canvas {
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        anchors.leftMargin: 12; anchors.rightMargin: 12; anchors.bottomMargin: 10
        height: Math.max(0, Math.min(30, parent.height - metTop.height - 26))
        visible: height > 8
        property var values: metCard.isPing ? sysMonHist.ping : sysMonHist.ram
        property color lineCol: metCard.accentCol
        property color lostCol: pal.error
        onValuesChanged: requestPaint()
        onLineColChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            var v = values || [];
            if (v.length < 2 || height <= 0) return;
            var maxV = 100;
            if (metCard.isPing) {
                maxV = 50;
                for (var q = 0; q < v.length; q++) if (v[q] > maxV) maxV = v[q];
                maxV *= 1.15;
            }
            var w = width, h = height;
            var step = w / (sysMonHist.histLen - 1);
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
            if (metCard.isPing) {
                ctx.fillStyle = lostCol;
                for (var l = 0; l < v.length; l++)
                if (v[l] < 0) { ctx.beginPath(); ctx.arc(x0 + l * step, h - 3, 2.2, 0, Math.PI * 2); ctx.fill(); }
            }
        }
    }
}
