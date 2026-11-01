import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../ui"

// Settings > System: session fetch modules
SystemPrimaryCard {
    icon: ""
    title: tr("sys_session")
    accent: pal.primary

    SystemSecondaryCard { icon: ""; title: tr("sys_user");   value: globalState.fetchUser;   accent: pal.primary }
    SystemSecondaryCard { icon: ""; title: tr("sys_shell");  value: globalState.fetchShell;  accent: "#FFCC80" }
    SystemSecondaryCard { icon: ""; title: tr("sys_de");     value: globalState.fetchDE;     accent: pal.accent }
    SystemSecondaryCard { icon: ""; title: tr("sys_wm");     value: globalState.fetchWM;     accent: pal.tertiary }
    SystemSecondaryCard { icon: ""; title: tr("sys_locale"); value: globalState.fetchLocale; accent: pal.error }
}
