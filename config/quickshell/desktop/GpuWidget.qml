import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../widgets"

// GPU usage desktop widget
ExprDesktopWidget {
    id: gpuWidgetRoot
    wType: "gpu"
    enabledProp: "gpuWidgetEnabled"; xProp: "gpuWidgetX"; yProp: "gpuWidgetY"; scaleProp: "gpuWidgetScale"
    baseW: 220; baseH: 220
    face: Component {
        Item {
            id: gpuFace
            readonly property real u: width / 220
            readonly property int pct: globalState.gpuPercent
            readonly property int temp: globalState.gpuTemp
            readonly property bool hot: temp >= 80
            readonly property string sub: {
                if (globalState.gpuLactOk && globalState.gpuVramUsedMb >= 0 && globalState.gpuVramTotalMb > 0)
                return "VRAM " + (globalState.gpuVramUsedMb / 1024).toFixed(1) + " / " + Math.round(globalState.gpuVramTotalMb / 1024) + " GB";
                if (globalState.gpuLactOk && globalState.gpuPowerW >= 0) return Math.round(globalState.gpuPowerW) + " W";
                return tr("dw_gpu_used");
            }
            MBox {
                anchors.fill: parent
                from: "Square"; rot: 45
                fill: desktopWidgetLayer.exprDark
                split: 0.64
                fill2: m3.primaryContainer
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.36 - height / 2
                Text {
                    id: gpuBigNum
                    text: gpuFace.pct < 0 ? "—" : gpuFace.pct
                    font.family: globalState.fontPrimary; font.pixelSize: Math.max(12, Math.round(68 * gpuFace.u)); font.weight: Font.Black
                    color: m3.primary
                }
                Text {
                    visible: gpuFace.pct >= 0
                    anchors.baseline: gpuBigNum.baseline
                    text: "%"
                    font.family: globalState.fontPrimary; font.pixelSize: Math.max(8, Math.round(28 * gpuFace.u)); font.weight: Font.Bold
                    color: m3.primary
                    opacity: 0.8
                }
            }
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.64 + 8 * gpuFace.u
                spacing: 0
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: tr("gpu_lbl")
                    font.family: globalState.fontPrimary; font.pixelSize: Math.max(8, Math.round(17 * gpuFace.u)); font.weight: Font.Bold
                    color: m3.inkPrimaryContainer
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: gpuFace.sub
                    font.family: globalState.fontSecondary; font.pixelSize: Math.max(7, Math.round(10 * gpuFace.u)); font.weight: Font.Medium
                    color: m3.inkPrimaryContainer
                    opacity: 0.8
                }
            }
            Item {
                id: gpuBadge
                visible: gpuFace.temp >= 0
                x: parent.width - width; y: 0
                width: 60 * gpuFace.u; height: width
                Spring { id: gpuHotM; target: gpuFace.hot ? 1 : 0; token: "spatialDefault"; eps: 0.002 }
                property real spin: 0
                FrameAnimation {
                    running: gpuFace.hot && gpuWidgetRoot.live
                    onTriggered: gpuBadge.spin = (gpuBadge.spin + 40 * Math.min(frameTime, 0.05)) % 360
                }
                MBox {
                    anchors.fill: parent
                    from: "Circle"; to: "SoftBurst"; t: gpuHotM.value
                    rotation: gpuBadge.spin
                    fill: gpuFace.hot ? m3.errorContainer : m3.tertiaryContainer
                }
                Text {
                    anchors.centerIn: parent
                    text: gpuFace.temp + "°"
                    font.family: globalState.fontPrimary; font.pixelSize: Math.max(8, Math.round(19 * gpuFace.u)); font.weight: Font.Black
                    color: gpuFace.hot ? m3.inkErrorContainer : m3.inkTertiaryContainer
                }
            }
        }
    }
}
