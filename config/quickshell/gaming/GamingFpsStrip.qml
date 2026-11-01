import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// FPS and frametime strip of the gaming panel
Rectangle {
    id: gmFpsStrip
    visible: gmHero.hasFps
    Layout.fillWidth: true
    implicitHeight: 112
    radius: 20
    color: globalState.glassMode ? ga(pal.surfaceHigh, 0.7) : pal.surfaceHigh
    readonly property real value: globalState.gamingFpsLive ? globalState.gamingFps : -1
    readonly property color accentCol: value < 0 ? pal.colorOnSurfVar
    : value < 30 ? pal.error : value < 55 ? pal.accent : pal.primary

    RowLayout {
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        anchors.leftMargin: 16; anchors.rightMargin: 16; anchors.topMargin: 12
        spacing: 12
        Rectangle {
            width: 32; height: 32; radius: 16
            color: ga(gmFpsStrip.accentCol, 0.16)
            Behavior on color { M3ColorAnim { duration: m3.durSlow } }
            Text { anchors.centerIn: parent; text: "\uf190"; font.family: "Material Symbols Rounded"; font.pixelSize: 18; color: gmFpsStrip.accentCol }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: -2
            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: "FPS" + (globalState.gamingFpsGame !== "" ? " · " + globalState.gamingFpsGame : "")
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium
                color: pal.colorOnSurfVar
            }
            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: gmFpsStrip.value < 0 ? tr("gm_fps_none") : Math.round(gmFpsStrip.value) + " FPS"
                font.family: globalState.fontPrimary; font.pixelSize: Math.round((gmFpsStrip.value >= 0 ? 28 : 18) * globalState.fontScale); font.weight: Font.Bold
                color: pal.colorOnSurface
            }
        }
        Rectangle {
            readonly property string txt: gmFpsStrip.value >= 0 && globalState.gamingFrametime >= 0 ? globalState.gamingFrametime.toFixed(1) + " ms" : "Shift+F2"
            implicitWidth: gmFpsChipTxt.implicitWidth + 24
            height: 32; radius: 8
            color: ga(gmFpsStrip.accentCol, 0.14)
            Text {
                id: gmFpsChipTxt
                anchors.centerIn: parent
                text: parent.txt
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.DemiBold
                color: gmFpsStrip.accentCol
            }
        }
    }
    Canvas {
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        anchors.leftMargin: 16; anchors.rightMargin: 16; anchors.bottomMargin: 12
        height: 36
        property var values: gmFpsStrip.visible ? gmTelemetry.histFps : []
        property color lineCol: gmFpsStrip.accentCol
        onValuesChanged: requestPaint()
        onLineColChanged: requestPaint()
        onWidthChanged: requestPaint()
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            var v = values || [];
            var n = gmTelemetry.histLen;
            if (v.length < 2) return;
            var maxV = 60;
            for (var q = 0; q < v.length; q++) if (v[q] > maxV) maxV = v[q];
            maxV *= 1.15;
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
        }
    }
}
