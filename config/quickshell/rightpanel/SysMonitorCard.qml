import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../widgets"
import "../ui/SvgPaths.js" as SvgPaths

// System monitor card of the control panel
Rectangle {
    id: cpSysMonCard
    Layout.fillWidth:  true
    Layout.fillHeight: true
    radius: 14
    color: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont)
    property string activeMetric: "cpu"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 7

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Text {
                text: "\ue322"; font.family: "Material Symbols Rounded"; font.pixelSize: 15
                color: pal.primary; opacity: globalState.glassMode ? 0.88 : 1.0
            }
            Text {
                text: tr("system"); font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium
                color: pal.colorOnSurfVar; opacity: globalState.glassMode ? 0.88 : 1.0
            }
            Item { Layout.fillWidth: true }
        }

        RowLayout {
            Layout.fillWidth: true; spacing: 6

            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 26; radius: 8
                color: cpSysMonCard.activeMetric === "cpu"
                ? (globalState.glassMode ? ga(pal.primary, 0.30) : containerDark(pal.primaryCont))
                : (globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont))
                RowLayout {
                    anchors.centerIn: parent; spacing: 4
                    Text { text: "\ue322"; font.family: "Material Symbols Rounded"; font.pixelSize: 12; color: pal.primary }
                    Text { text: tr("cpu_lbl"); font.family: globalState.fontSecondary; font.pixelSize: Math.round(9 * globalState.fontScale); font.weight: Font.Medium; color: pal.colorOnSurface }
                }
                MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: cpSysMonCard.activeMetric = "cpu" }
            }

            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 26; radius: 8
                color: cpSysMonCard.activeMetric === "ram"
                ? (globalState.glassMode ? ga(pal.primary, 0.30) : containerDark(pal.primaryCont))
                : (globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont))
                RowLayout {
                    anchors.centerIn: parent; spacing: 4
                    Text { text: "\ue322"; font.family: "Material Symbols Rounded"; font.pixelSize: 12; color: pal.primary }
                    Text { text: tr("ram_lbl"); font.family: globalState.fontSecondary; font.pixelSize: Math.round(9 * globalState.fontScale); font.weight: Font.Medium; color: pal.colorOnSurface }
                }
                MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: cpSysMonCard.activeMetric = "ram" }
            }

            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 26; radius: 8
                color: cpSysMonCard.activeMetric === "disk"
                ? (globalState.glassMode ? ga(pal.primary, 0.30) : containerDark(pal.primaryCont))
                : (globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont))
                RowLayout {
                    anchors.centerIn: parent; spacing: 4
                    Text { text: "\ue1db"; font.family: "Material Symbols Rounded"; font.pixelSize: 12; color: pal.primary }
                    Text { text: tr("disk_lbl"); font.family: globalState.fontSecondary; font.pixelSize: Math.round(9 * globalState.fontScale); font.weight: Font.Medium; color: pal.colorOnSurface }
                }
                MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: cpSysMonCard.activeMetric = "disk" }
            }
        }

        Item {
            id: cpShapeStage
            Layout.fillWidth: true
            Layout.fillHeight: true
            property real shapeSize: Math.max(60, Math.min(width, height) - 10)

            MetricFace {
                id: cpCpuFace
                active: cpSysMonCard.activeMetric === "cpu"
                spin: -360
                size: cpShapeStage.shapeSize
                percent: globalState.cpuPercent
                label: tr("cpu_lbl")
                shapePath: SvgPaths.pentagon
            }

            MetricFace {
                id: cpRamFace
                active: cpSysMonCard.activeMetric === "ram"
                spin: 360
                size: cpShapeStage.shapeSize
                percent: globalState.ramPercent
                label: tr("ram_lbl")
                shapePath: SvgPaths.arch
            }

            MetricFace {
                id: cpDiskFace
                active: cpSysMonCard.activeMetric === "disk"
                spin: 360
                size: cpShapeStage.shapeSize
                percent: globalState.diskPercent
                label: tr("disk_lbl")
                shapePath: SvgPaths.flower
            }
        }

        RowLayout {
            Layout.fillWidth: true; spacing: 8
            visible: globalState.gpuPercent >= 0
            Text { text: tr("gpu_lbl"); font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale); font.weight: Font.Medium; color: pal.colorOnSurfVar; opacity: globalState.glassMode ? 0.88 : 1.0; Layout.preferredWidth: 30 }
            EWavyLinear {
                id: cpGpuWave
                opacity: globalState.glassMode ? 0.88 : 1.0
                Layout.fillWidth: true
                height: 18
                value: Math.max(0, globalState.gpuPercent) / 100
                animateValue: false
                active: globalState.gpuPercent > 80 ? pal.error : globalState.gpuPercent > 50 ? pal.accent : pal.primary
                track: m3.alpha(m3.inkSurface, 0.14)
                thickness: m3.progressThickness; amplitude: 2.5; wavelength: 24
            }
            Text { text: globalState.gpuPercent + "%"; font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale); font.weight: Font.Medium; color: pal.colorOnSurfVar; opacity: globalState.glassMode ? 0.88 : 1.0; Layout.preferredWidth: 30; horizontalAlignment: Text.AlignRight }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: pal.mutedDeep; opacity: 0.5 }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 30; radius: 8
                visible: globalState.cpuTemp >= 0
                color: {
                    var c = containerDark(pal.secondaryCont);
                    return globalState.glassMode ? ga(c, 0.78) : c;
                }
                RowLayout {
                    id: cpTempCpuRow
                    anchors.centerIn: parent
                    spacing: 5
                    opacity: globalState.glassMode ? 0.88 : 1.0
                    Text {
                        text: "\ue1ff"; font.family: "Material Symbols Rounded"; font.pixelSize: 13
                        color: globalState.cpuTemp > 80 ? pal.error : globalState.cpuTemp > 60 ? pal.accent : pal.primary
                    }
                    Text {
                        text: (globalState.cpuTemp >= 0 ? (globalState.cpuTemp + "°C") : "—") + " " + tr("cpu_lbl")
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale); font.weight: Font.Medium; color: pal.colorOnSurface
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 30; radius: 8
                visible: globalState.gpuTemp >= 0
                color: {
                    var c = containerDark(pal.secondaryCont);
                    return globalState.glassMode ? ga(c, 0.78) : c;
                }
                RowLayout {
                    id: cpTempGpuRow
                    anchors.centerIn: parent
                    spacing: 5
                    opacity: globalState.glassMode ? 0.88 : 1.0
                    Text {
                        text: "\ue1ff"; font.family: "Material Symbols Rounded"; font.pixelSize: 13
                        color: globalState.gpuTemp > 80 ? pal.error : globalState.gpuTemp > 60 ? pal.accent : pal.primary
                    }
                    Text {
                        text: (globalState.gpuTemp >= 0 ? (globalState.gpuTemp + "°C") : "—") + " " + tr("gpu_lbl")
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale); font.weight: Font.Medium; color: pal.colorOnSurface
                    }
                }
            }
        }
    }
}
