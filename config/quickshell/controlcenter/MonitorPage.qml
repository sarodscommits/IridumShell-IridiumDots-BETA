import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../widgets"
import "../ui/SvgPaths.js" as SvgPaths

// System monitor page (CPU/GPU, disk, RAM, ping)
ColumnLayout {
    id: monPage
    property bool live: false
    anchors.margins: 14
    anchors.topMargin: 58
    spacing: 12
    readonly property bool hasGpu: globalState.gpuPercent >= 0
    readonly property bool ringsLive: monPage.live && !globalState.wpFullscreenActive

    GridLayout {
        id: monGrid
        Layout.fillWidth: true
        Layout.fillHeight: true
        readonly property bool side: monPage.width > monPage.height * 1.25
        columns: side ? 2 : 1
        columnSpacing: 14; rowSpacing: 12

        RowLayout {
            Layout.fillWidth: !monGrid.side
            Layout.fillHeight: true
            Layout.preferredWidth: monGrid.side ? Math.min(monGrid.height * 2 + 10, monGrid.width * 0.5) : 100
            Layout.preferredHeight: monGrid.side ? 100 : 52
            spacing: 10
            Repeater {
                model: monPage.hasGpu ? ["cpu", "gpu"] : ["cpu"]
                MonitorRing { id: monRingSlot }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: monGrid.side ? 54 : 100
            Layout.preferredHeight: monGrid.side ? 100 : 48
            spacing: 10
            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 2
                columnSpacing: 10; rowSpacing: 10

                MonitorDiskCard { id: diskCard }

                Repeater {
                    model: ["ram", "ping"]
                    MonitorMetricCard { id: metCard }
                }
            }
            Item {
                id: monBattSlot
                visible: globalState.hasBattery
                Layout.fillHeight: true
                Layout.preferredWidth: Math.round(height * 0.6)
                ShapeGauge {
                    id: monBattGauge
                    width: parent.height; height: parent.height
                    x: (parent.width - width) / 2
                    shapePath: SvgPaths.battery
                    fillMin: 13; fillMax: 96
                    pct: globalState.batteryPercent / 100
                    glassEmpty: globalState.glassMode
                    waveEffect: true
                    wavePhase: monPage.ringsLive ? globalState.wavePhase : 0
                    fillColor: (!globalState.batteryPlugged && globalState.batteryPercent <= globalState.battLowThreshold) ? pal.error : pal.primary
                    emptyColor: globalState.glassMode ? ga(pal.surface, 0.5) : pal.surface
                    outlineColor: pal.mutedDeep
                }
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: monBattGauge.height * 0.55 - height / 2
                    spacing: -2
                    readonly property color ink: globalState.batteryPercent >= 58 ? pal.colorOnPrimary : pal.colorOnSurface
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: globalState.batteryPlugged && monBattSlot.height >= 70
                        text: "\uea0b"
                        font.family: "Material Symbols Rounded"; font.pixelSize: 16
                        color: parent.ink
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: globalState.batteryPercent + "%"
                        font.family: globalState.fontPrimary; font.weight: Font.Bold
                        font.pixelSize: Math.max(9, Math.min(Math.round(15 * globalState.fontScale), Math.round(monBattSlot.width * 0.2)))
                        color: parent.ink
                    }
                }
            }
        }
    }

}
