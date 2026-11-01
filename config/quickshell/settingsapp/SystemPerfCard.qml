import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../ui"

// Settings > System: individual CPU / GPU performance levels
SystemPrimaryCard {
    id: spc
    required property var logic
    icon: ""
    title: tr("sys_perf")
    accent: pal.positive

    function stateText(v, busy) {
        if (busy) return tr("gm_perf_applying");
        if (v === "none" || v === "nodev") return tr("sys_unavailable");
        if (v === "err") return tr("sys_error");
        return v === "low" ? tr("perf_low") : v === "high" ? tr("perf_high") : v === "medium" ? tr("perf_medium") : "";
    }
    readonly property var levels: [
        { value: "low",    icon: "", label: tr("perf_low") },
        { value: "medium", icon: "", label: tr("perf_medium") },
        { value: "high",   icon: "", label: tr("perf_high") }
    ]

    SystemSecondaryCard {
        icon: ""
        title: "CPU"
        value: spc.stateText(spc.logic.cpu, spc.logic.cpuBusy)
        sub: tr("sys_perf_cpu_d")
        accent: pal.positive
        SegmentedPill {
            Layout.fillWidth: true
            segHeight: 44
            iconSize: 17
            enabled: spc.logic.cpu !== "none"
            opacity: enabled ? 1 : 0.45
            options: spc.levels
            current: spc.logic.cpu
            onPicked: (v) => spc.logic.setCpu(v)
            trackColor: m3.glassy(m3.surfaceContainerHighest, 0.6)
            selectedColor: pal.primary
            textColor: pal.colorOnSurfVar
            selectedTextColor: pal.colorOnPrimary
            iconColor: pal.primary
        }
    }

    SystemSecondaryCard {
        icon: ""
        title: "GPU"
        value: spc.stateText(spc.logic.gpu, spc.logic.gpuBusy)
        sub: tr("sys_perf_gpu_d")
        accent: "#FFCC80"
        SegmentedPill {
            Layout.fillWidth: true
            segHeight: 44
            iconSize: 17
            enabled: spc.logic.gpu !== "none" && spc.logic.gpu !== "nodev"
            opacity: enabled ? 1 : 0.45
            options: spc.levels
            current: spc.logic.gpu
            onPicked: (v) => spc.logic.setGpu(v)
            trackColor: m3.glassy(m3.surfaceContainerHighest, 0.6)
            selectedColor: pal.primary
            textColor: pal.colorOnSurfVar
            selectedTextColor: pal.colorOnPrimary
            iconColor: pal.primary
        }
    }
}
