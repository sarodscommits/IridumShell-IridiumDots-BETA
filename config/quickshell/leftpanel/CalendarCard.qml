import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../panels"
import "../ui"

// Calendar card of the left panel
Item {
    id: calWidgetItem
    visible: !calPanel.anyWidgetExpanded || calWidgetItem.calExpanded
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.preferredHeight: 250

    property bool calWidgetHovered: false
    property bool calPeek:     false
    property bool calExpanded: false

    property int selectedDay: -1
    function dateKeyFor(y, m, d) { return y + "-" + m + "-" + d; }
    property string selectedDateKey: selectedDay >= 0 ? dateKeyFor(calYear, calMonth, selectedDay) : ""
    property var selectedDateEvents: selectedDateKey !== "" && globalState.calendarEvents[selectedDateKey]
    ? globalState.calendarEvents[selectedDateKey] : []

    property int calYear:  { var d = new Date(); return d.getFullYear() }
    property int calMonth: { var d = new Date(); return d.getMonth() }
    property int todayDay:   { var d = new Date(); return d.getDate() }
    property int todayMonth: { var d = new Date(); return d.getMonth() }
    property int todayYear:  { var d = new Date(); return d.getFullYear() }
    function daysInMonth(y, m) { return new Date(y, m + 1, 0).getDate() }
    function firstWeekday(y, m) { return new Date(y, m, 1).getDay() }

    HoverHandler {
        id: calWidgetHover
        onHoveredChanged: calWidgetItem.calWidgetHovered = hovered
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            clockWidgetItem.clockPeek = false;
            clockWidgetItem.clockExpanded = false;
            weatherCard.weatherPeek = false;
            weatherCard.weatherExpanded = false;
            fetchWidgetItem.fetchPeek = false;
            fetchWidgetItem.fetchExpanded = false;
            if (!calWidgetItem.calPeek && !calWidgetItem.calExpanded) {
                calWidgetItem.calPeek = true;
            } else if (calWidgetItem.calPeek && !calWidgetItem.calExpanded) {
                calWidgetItem.calExpanded = true;
            }
        }
    }

    Connections {
        target: globalState
        function onCalendarMenuOpenChanged() {
            if (!globalState.calendarMenuOpen) {
                calWidgetItem.calExpanded = false;
                calWidgetItem.calPeek = false;
                calWidgetItem.selectedDay = -1;
            }
        }
        function onLeftPanelPageChanged() {
            if (globalState.leftPanelPage !== 0) {
                calWidgetItem.calExpanded = false;
                calWidgetItem.calPeek = false;
                calWidgetItem.selectedDay = -1;
            }
        }
    }

    MorphShapeCanvas { id: calShapeCanvas; host: calWidgetItem; peek: calWidgetItem.calPeek; expanded: calWidgetItem.calExpanded; shape: "pentagon" }

    Column {
        id: calWidgetIdleCol
        anchors.centerIn: calShapeCanvas
        spacing: 4
        opacity: (calWidgetItem.calPeek || calWidgetItem.calExpanded) ? 0 : 1
        visible: opacity > 0.01
        Behavior on opacity { M3NumberAnim {} }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "\ue935"
            font.family: "Material Symbols Rounded"
            font.pixelSize: 40
            color: pal.primary
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: {
                var d = new Date();
                return d.toLocaleDateString(Qt.locale(localeCode()), "ddd d MMM").toLowerCase();
            }
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(17 * globalState.fontScale); font.weight: Font.Medium
            color: pal.colorOnSurfVar
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: {
                var d = new Date();
                return d.toLocaleDateString(Qt.locale(localeCode()), "yyyy");
            }
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(15 * globalState.fontScale); font.weight: Font.Medium
            color: pal.colorOnSurfVar
        }
    }

    CalendarMiniGrid { id: calMiniGridCol }

    CalendarEventEditor {
        colorError: pal.error
        id: calEventEditor
        visible: calWidgetItem.calExpanded
        opacity: calWidgetItem.calExpanded ? 1 : 0
        Behavior on opacity { M3NumberAnim {} }

        x: calMiniGridCol.x
        y: calMiniGridCol.y + calMiniGridCol.height + 14
        width: calMiniGridCol.width
        height: Math.max(80, calShapeCanvas.y + calShapeCanvas.height - y - 20)

        hasSelection: calWidgetItem.selectedDay >= 0
        selectedDateLabel: calWidgetItem.selectedDay >= 0
        ? new Date(calWidgetItem.calYear, calWidgetItem.calMonth, calWidgetItem.selectedDay).toLocaleDateString(Qt.locale(localeCode()), "d MMMM yyyy")
        : ""
        eventsForDay: calWidgetItem.selectedDateEvents
        allEvents: allCalendarEventsSorted()
        eventTypes: [
        { key: "reminder", label: tr("cal_type_reminder"), icon: "\ue7f4" },
        { key: "holiday",  label: tr("cal_type_holiday"),  icon: "\ue838" },
        { key: "birthday", label: tr("cal_type_birthday"), icon: "\ue87d" },
        { key: "event",    label: tr("cal_type_event"),    icon: "\ue878" }
        ]
        placeholderText:  tr("cal_pick_day")
        inputPlaceholder: tr("cal_add_placeholder")
        emptyListText:    tr("cal_no_reminders")

        colorPrimary:       pal.primary
        colorOnPrimaryCont: pal.colorOnPrimary
        colorOnSurface:     pal.colorOnSurface
        colorOnSurfVar:     pal.colorOnSurfVar
        colorTextSecondary: pal.textSecondary
        colorSurface:       pal.surface

        onAddRequested: (title, type) => addCalendarEvent(calWidgetItem.selectedDateKey, title, type)
        onRemoveRequested: (index) => removeCalendarEvent(calWidgetItem.selectedDateKey, index)
        onRemoveGlobalRequested: (dateKey, index) => removeCalendarEvent(dateKey, index)
        onInputFocusChanged: (focused) => globalState.calEventInputFocused = focused
    }

    Rectangle {
        id: calCloseBtn
        visible: calWidgetItem.calExpanded
        opacity: calWidgetItem.calExpanded ? 1 : 0
        Behavior on opacity { M3NumberAnim {} }
        z: 50
        width: 26; height: 26; radius: 13
        x: calShapeCanvas.x + calShapeCanvas.width - width - 12
        y: calShapeCanvas.y + 20
        color: calCloseBtnHov.hovered ? pal.primaryCont : "transparent"
        Behavior on color { M3ColorAnim { duration: m3.durFast } }
        Text { anchors.centerIn: parent; text: "\ue5cd"; font.family: "Material Symbols Rounded"; font.pixelSize: 15; color: pal.colorOnSurfVar }
        HoverHandler { id: calCloseBtnHov }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                calWidgetItem.calExpanded = false;
                calWidgetItem.calPeek = false;
                calWidgetItem.selectedDay = -1;
            }
        }
    }
}
