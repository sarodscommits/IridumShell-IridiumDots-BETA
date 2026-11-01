import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Widget column of the left panel
Item {
    id: calPanel
    anchors.fill: parent
    anchors.margins: 10
    anchors.topMargin: 26
    opacity: (globalState.calendarMenuOpen && globalState.leftPanelPage === 0) ? 1 : 0
    visible: (globalState.calendarMenuOpen && globalState.leftPanelPage === 0) || opacity > 0
    Behavior on opacity { M3NumberAnim {} }

    property int calYear:    { var d = new Date(); return d.getFullYear() }
    property int calMonth:   { var d = new Date(); return d.getMonth() }
    property int todayDay:   { var d = new Date(); return d.getDate() }
    property int todayMonth: { var d = new Date(); return d.getMonth() }
    property int todayYear:  { var d = new Date(); return d.getFullYear() }

    function daysInMonth(y, m) { return new Date(y, m + 1, 0).getDate() }
    function firstWeekday(y, m) { return new Date(y, m, 1).getDay() }

    property bool anyWidgetExpanded: clockWidgetItem.clockExpanded || weatherCard.weatherExpanded || calWidgetItem.calExpanded || fetchWidgetItem.fetchExpanded

    ColumnLayout {
        id: calPanelWidgetsColumn
        anchors.fill: parent
        spacing: 6

        ClockCard { id: clockWidgetItem }

        CalendarCard { id: calWidgetItem }

        WeatherCard { id: weatherCard }

        FetchCard { id: fetchWidgetItem }
    }
}
