import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."

// Hero card of the gaming panel: rings and FPS strip
Rectangle {
    id: gmHero
    readonly property bool hasFps: !gamingWindow.floatLayout && globalState.gamingMetricKeys.indexOf("fps") >= 0
    visible: !gamingWindow.floatLayout && (gamingWindow.modOn("rings") || hasFps || gmGpuExtra.visible)
    Layout.fillWidth: true
    Layout.topMargin: 8
    implicitHeight: gmHeroCol.implicitHeight
    color: "transparent"

    ColumnLayout {
        id: gmHeroCol
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        spacing: 8

        GamingRings { id: gamingRings }

        RowLayout {
            id: gmGpuExtra
            Layout.alignment: Qt.AlignHCenter
            visible: gamingWindow.modOn("gpuExtra") && globalState.gpuLactOk && (globalState.gpuVramUsedMb >= 0 || globalState.gpuPowerW >= 0)
            spacing: 8
            Repeater {
                model: {
                    var a = [];
                    if (globalState.gpuVramUsedMb >= 0)
                    a.push("VRAM " + (globalState.gpuVramUsedMb / 1024).toFixed(1) + (globalState.gpuVramTotalMb > 0 ? " / " + (globalState.gpuVramTotalMb / 1024).toFixed(0) : "") + " GB");
                    if (globalState.gpuPowerW >= 0) a.push(Math.round(globalState.gpuPowerW) + " W");
                    if (globalState.gpuClockMhz >= 0) a.push(globalState.gpuClockMhz + " MHz");
                    return a;
                }
                Rectangle {
                    required property string modelData
                    implicitWidth: gmGpuChipTxt.implicitWidth + 24
                    implicitHeight: 32
                    radius: 8
                    color: globalState.glassMode ? ga(pal.surfaceHigh, 0.7) : pal.surfaceHigh
                    Text {
                        id: gmGpuChipTxt
                        anchors.centerIn: parent
                        text: parent.modelData
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium
                        color: pal.colorOnSurfVar
                    }
                }
            }
        }

        GamingFpsStrip { id: gmFpsStrip }
    }
}
