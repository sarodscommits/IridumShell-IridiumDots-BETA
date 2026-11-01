import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Disk usage card with liquid fill of the monitor page
Rectangle {
    id: diskCard
    readonly property real pct: Math.max(0, Math.min(100, globalState.diskPercent)) / 100
    readonly property color accentCol: globalState.diskPercent >= 90 ? pal.error : globalState.diskPercent >= 75 ? pal.accent : pal.primary
    property real liquidPct: pct
    Behavior on liquidPct { M3SpringAnim { token: "spatialDefault"; epsilon: 0.002 } }
    readonly property real fillW: Math.max(0, Math.min(width, width * liquidPct))
    Layout.columnSpan: 2
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.preferredHeight: 11
    radius: 22
    color: globalState.glassMode ? ga(pal.surface, 0.5) : pal.surface
    Canvas {
        id: diskLiquid
        anchors.fill: parent
        property real pct: diskCard.liquidPct
        property real phase: monPage.ringsLive ? globalState.wavePhase : 0
        property color col: diskCard.accentCol
        onPctChanged: requestPaint()
        onPhaseChanged: requestPaint()
        onColChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            if (width <= 0 || height <= 0 || pct <= 0) return;
            ctx.save();
            ctx.beginPath();
            ctx.roundedRect(0, 0, width, height, diskCard.radius, diskCard.radius);
            ctx.clip();
            var edge = width * Math.min(1.05, pct);
            var wave = pct > 0.03 && pct < 0.985;
            var amp = wave ? 3 : 0;
            var freq = 4 * Math.PI / Math.max(1, height);
            ctx.beginPath();
            ctx.moveTo(-10, -10);
            for (var y = -10; y <= height + 12; y += 3)
            ctx.lineTo(edge + Math.sin(y * freq + phase) * amp, y);
            ctx.lineTo(-10, height + 12);
            ctx.closePath();
            ctx.fillStyle = Qt.rgba(col.r, col.g, col.b, 1);
            ctx.fill();
            ctx.restore();
        }
    }
    Component {
        id: diskContent
        Item {
            id: dcRoot
            readonly property bool inv: parent && parent.inv === true
            readonly property color ink: inv ? pal.colorOnPrimary : pal.colorOnSurface
            RowLayout {
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                anchors.leftMargin: 12; anchors.rightMargin: 12; anchors.topMargin: 10
                spacing: 10
                Rectangle {
                    visible: diskCard.width >= 200
                    width: 30; height: 30; radius: 15
                    color: dcRoot.inv ? ga(pal.colorOnPrimary, 0.18) : ga(diskCard.accentCol, 0.16)
                    Text { anchors.centerIn: parent; text: ""; font.family: "Material Symbols Rounded"; font.pixelSize: 18; color: dcRoot.inv ? pal.colorOnPrimary : diskCard.accentCol }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: -2
                    Text {
                        Layout.fillWidth: true
                        text: tr("nc_disk")
                        elide: Text.ElideRight
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium
                        color: dcRoot.inv ? ga(pal.colorOnPrimary, 0.8) : pal.colorOnSurfVar
                    }
                    Text {
                        Layout.fillWidth: true
                        text: globalState.diskPercent + "%"
                        elide: Text.ElideRight
                        font.family: globalState.fontPrimary; font.pixelSize: Math.round(22 * globalState.fontScale); font.weight: Font.Bold
                        color: dcRoot.ink
                    }
                }
                Rectangle {
                    visible: globalState.diskUsedStr !== "" && diskCard.width >= 250
                    implicitWidth: chipText.implicitWidth + 16
                    height: 26; radius: 13
                    color: dcRoot.inv ? ga(pal.colorOnPrimary, 0.18) : ga(diskCard.accentCol, 0.14)
                    Text {
                        id: chipText
                        anchors.centerIn: parent
                        text: globalState.diskUsedStr
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.DemiBold
                        color: dcRoot.inv ? pal.colorOnPrimary : diskCard.accentCol
                    }
                }
            }
        }
    }
    Item {
        x: diskCard.fillW
        width: Math.max(0, diskCard.width - x); height: diskCard.height
        clip: true
        Loader {
            x: -parent.x
            width: diskCard.width; height: diskCard.height
            property bool inv: false
            sourceComponent: diskContent
        }
    }
    Item {
        width: diskCard.fillW; height: diskCard.height
        clip: true
        Loader {
            width: diskCard.width; height: diskCard.height
            property bool inv: true
            sourceComponent: diskContent
        }
    }
}
