import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../rightpanel"
import "../ui"

// Swipeable control panel pages: media, monitor, notifications
Item {
    id: cpModulesSwitcher
    Layout.fillWidth: true
    Layout.fillHeight: true

    ColumnLayout {
        id: cpModulesPage0
        anchors.fill: parent
        spacing: 10
        opacity: globalState.cpModulesPage === 0 ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity { M3NumberAnim {} }

        ControlMediaCard { id: cpMediaCard }

        SysMonitorCard { id: cpSysMonCard }
    }

    ControlNotifCard { id: cpNotifCard }
}
