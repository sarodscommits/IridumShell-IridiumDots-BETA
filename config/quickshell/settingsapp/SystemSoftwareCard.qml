import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../ui"

// Settings > System: operating system fetch modules
SystemPrimaryCard {
    icon: ""
    title: tr("sys_software")
    accent: pal.accent
    headerExtra: SystemFetchRefresh {}

    SystemSecondaryCard { icon: ""; title: tr("sys_distro");   value: globalState.fetchOS;       accent: pal.tertiary }
    SystemSecondaryCard { icon: ""; title: tr("sys_kernel");   value: globalState.fetchKernel;   accent: pal.error }
    SystemSecondaryCard { icon: ""; title: tr("sys_packages"); value: globalState.fetchPackages; accent: pal.positive }
    SystemSecondaryCard { icon: ""; title: tr("sys_uptime");   value: globalState.fetchUptime;   accent: "#CE93D8" }
}
