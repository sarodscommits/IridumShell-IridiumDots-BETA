import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../controlcenter"
import "../ui"

// Weather, calendar and info cards of the overview dashboard
Item {
    id: ncPage1
    property alias ncCalWidgetItem: ncCalWidgetItem
    anchors.fill: parent
    opacity: ncPage1Group.pageOn ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity { M3NumberAnim {} }

    OverviewWeatherCard { id: ncWeatherCard }

    OverviewCalendarCard { id: ncCalWidgetItem }

    OverviewFetchCard { id: ncFetchWidgetItem }
}
