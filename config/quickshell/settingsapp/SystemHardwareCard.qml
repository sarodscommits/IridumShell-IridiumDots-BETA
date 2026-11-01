import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../ui"
import "SystemFetch.js" as SF

// Settings > System: hardware fetch modules
SystemPrimaryCard {
    icon: ""
    title: tr("sys_hardware")
    accent: pal.tertiary
    headerExtra: SystemFetchRefresh {}

    SystemSecondaryCard { icon: ""; title: tr("sys_processor"); value: globalState.fetchCPU; accent: pal.positive }
    SystemSecondaryCard { icon: ""; title: tr("sys_graphics");  value: globalState.fetchGPU; accent: "#FFCC80" }
    SystemSecondaryCard { icon: ""; title: tr("sys_memory");    value: globalState.fetchRAM; accent: pal.primary; fraction: SF.usage(globalState.fetchRAM) }
    SystemSecondaryCard { icon: ""; title: tr("sys_swap");      value: globalState.fetchSwap; accent: pal.accent; fraction: SF.usage(globalState.fetchSwap) }
    SystemSecondaryCard { icon: ""; title: tr("sys_storage");   value: globalState.fetchDisk; accent: pal.tertiary; fraction: SF.usage(globalState.fetchDisk) }
}
