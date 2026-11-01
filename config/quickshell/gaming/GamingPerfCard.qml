import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Performance profile selector of the gaming panel
Rectangle {
    id: gmPerfCard
    visible: gamingWindow.modOn("perf")
    Layout.fillWidth: true
    implicitHeight: gmPerfCol.implicitHeight + 32
    radius: 28
    color: globalState.glassMode ? ga(pal.surfaceElevated, 0.6) : pal.surfaceElevated
    ColumnLayout {
        id: gmPerfCol
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        anchors.margins: 16
        spacing: 12
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Item {
                id: gmPerfShape
                width: 32; height: 32
                readonly property string shapeName: globalState.perfProfile === "high" ? "SoftBurst"
                : globalState.perfProfile === "medium" ? "Cookie6Sided" : "Circle"
                property string _from: shapeName
                property string _to: shapeName
                onShapeNameChanged: { _from = _to; _to = shapeName; gmPerfM.snap(0); gmPerfM.target = 1; gmPerfR.target += 60; }
                Spring { id: gmPerfM; target: 1; token: "spatialDefault"; eps: 0.002 }
                Spring { id: gmPerfR; target: 0; token: "spatialDefault"; eps: 0.05 }
                property real busySpin: 0
                NumberAnimation on busySpin { from: 0; to: 360; duration: 1600; loops: Animation.Infinite; running: globalState.perfApplying && gamingWindow.shown }
                Connections {
                    target: globalState
                    function onPerfApplyingChanged() {
                        if (!globalState.perfApplying) { gmPerfR.snap(gmPerfR.value + gmPerfShape.busySpin); gmPerfR.target = Math.ceil(gmPerfR.value / 60) * 60; gmPerfShape.busySpin = 0; }
                    }
                }
                MShape {
                    anchors.fill: parent
                    inset: 1.0
                    from: gmPerfShape._from; to: gmPerfShape._to; t: gmPerfM.value
                    rotation: gmPerfR.value + (globalState.perfApplying ? gmPerfShape.busySpin : 0)
                    fill: globalState.perfProfile === "high" ? pal.primary : pal.secondaryCont
                    Behavior on fill { M3ColorAnim {} }
                }
                Text { anchors.centerIn: parent; text: "\ue9e4"; font.family: "Material Symbols Rounded"; font.pixelSize: 18; color: globalState.perfProfile === "high" ? pal.colorOnPrimary : pal.primary }
            }
            Text {
                Layout.fillWidth: true
                text: tr("gm_perf")
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(13 * globalState.fontScale); font.weight: Font.DemiBold
                color: pal.colorOnSurface
            }
            Text {
                text: globalState.perfApplying ? tr("gm_perf_applying")
                : gmPerf.perfGpuState === "err" ? tr("gm_perf_gpu_err_short")
                : gmPerf.perfGpuState === "none" ? tr("gm_perf_no_lact") : ""
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale)
                color: gmPerf.perfGpuState === "err" ? pal.error : pal.mutedDeep
            }
        }
        SegmentedPill {
            Layout.fillWidth: true
            segHeight: 48
            fontSize: Math.round(12 * globalState.fontScale)
            iconSize: 17
            options: [{ value: "low",    icon: "\uea35", label: "Low" },
            { value: "medium", icon: "\ueaf6", label: "Medium" },
            { value: "high",   icon: "\uea0b", label: "High" }]
            current: globalState.perfProfile
            onPicked: (v) => gamingWindow.setPerfProfile(v)
            trackColor: m3.glassy(m3.surfaceContainerHighest, 0.6)
            selectedColor: pal.primary
            textColor: pal.colorOnSurfVar
            selectedTextColor: pal.colorOnPrimary
            iconColor: pal.primary
        }
    }
}
