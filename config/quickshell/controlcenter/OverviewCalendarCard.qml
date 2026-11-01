import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../panels"
import "../ui"

// Calendar card of the overview dashboard
Rectangle {
    id: ncCalWidgetItem
    visible: ncDashLayer.shown("cal")
    x: ncDashLayer.rCal.x
    y: ncDashLayer.rCal.y
    Behavior on y { enabled: globalState.ncEditMode; M3SpringAnim { token: "spatialDefault" } }
    width: ncDashLayer.rCal.width
    height: ncDashLayer.rCal.height
    radius: 28
    color: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont)

    readonly property real cellH: 24

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


    ColumnLayout {
        id: ncCalMiniGridCol
        x: 18
        y: 16
        width: parent.width - 36
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 0
            PressIconButton {
                width: 22
                height: 22
                cornerRadius: 6
                icon: "\ue5cb"
                iconSize: 14
                iconColor: pal.colorOnSurface
                hoverColor: pal.surfaceVar
                idleColor: "transparent"
                onClicked: {
                    ncCalWidgetItem.calMonth -= 1;
                    if (ncCalWidgetItem.calMonth < 0) { ncCalWidgetItem.calMonth = 11; ncCalWidgetItem.calYear -= 1; }
                    ncCalWidgetItem.selectedDay = -1;
                }
            }
            Item { Layout.fillWidth: true }
            Text {
                text: Qt.locale(localeCode()).standaloneMonthName(ncCalWidgetItem.calMonth, Locale.LongFormat) + " " + ncCalWidgetItem.calYear
                font.family: globalState.fontPrimary; font.pixelSize: Math.round(15 * globalState.fontScale); font.weight: Font.Bold
                color: pal.colorOnSurface
            }
            Item { Layout.fillWidth: true }
            PressIconButton {
                width: 22
                height: 22
                cornerRadius: 6
                icon: "\ue5cc"
                iconSize: 14
                iconColor: pal.colorOnSurface
                hoverColor: pal.surfaceVar
                idleColor: "transparent"
                onClicked: {
                    ncCalWidgetItem.calMonth += 1;
                    if (ncCalWidgetItem.calMonth > 11) { ncCalWidgetItem.calMonth = 0; ncCalWidgetItem.calYear += 1; }
                    ncCalWidgetItem.selectedDay = -1;
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 0
            Repeater {
                model: weekdayInitials()
                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium
                    color: pal.textSecondary
                }
            }
        }

        Grid {
            Layout.fillWidth: true
            columns: 7
            columnSpacing: 1; rowSpacing: 2

            Repeater {
                model: ncCalWidgetItem.firstWeekday(ncCalWidgetItem.calYear, ncCalWidgetItem.calMonth)
                Item { width: (ncCalMiniGridCol.width) / 7; height: ncCalWidgetItem.cellH }
            }

            Repeater {
                id: ncCalDaysRepeater2
                model: ncCalWidgetItem.daysInMonth(ncCalWidgetItem.calYear, ncCalWidgetItem.calMonth)
                property color _text: pal.textPrimary
                property color _dot:  pal.primary
                property color _accent: pal.accent
                Rectangle {
                    id: ncCalDayCell2
                    width: ncCalMiniGridCol.width / 7; height: ncCalWidgetItem.cellH; radius: 5
                    property bool isToday: (modelData + 1) === ncCalWidgetItem.todayDay &&
                    ncCalWidgetItem.calMonth === ncCalWidgetItem.todayMonth &&
                    ncCalWidgetItem.calYear  === ncCalWidgetItem.todayYear
                    property bool isSelected: (modelData + 1) === ncCalWidgetItem.selectedDay
                    property bool hasEvents: {
                        var k = ncCalWidgetItem.dateKeyFor(ncCalWidgetItem.calYear, ncCalWidgetItem.calMonth, modelData + 1);
                        return !!(globalState.calendarEvents[k] && globalState.calendarEvents[k].length > 0);
                    }
                    color: isToday ? "transparent"
                    : isSelected ? pal.primaryCont
                    : (ncCalDayHov2.hovered ? pal.surfaceVar : "transparent")
                    Behavior on color { M3ColorAnim {} }
                    Spring { id: ncCalDayCell2Spin; target: ncCalDayHov2.hovered ? 45 : 0; token: "spatialDefault"; eps: 0.05 }
                    MShape {
                        anchors.centerIn: parent
                        visible: ncCalDayCell2.isToday
                        width: Math.min(parent.width, parent.height + 6); height: width
                        inset: 1.0
                        from: m3.accentShape; to: m3.accentShape
                        rotation: ncCalDayCell2Spin.value
                        fill: ncCalDaysRepeater2._accent
                    }
                    Text {
                        anchors.centerIn: parent
                        text: modelData + 1
                        font.family: globalState.fontPrimary; font.pixelSize: Math.round(12 * globalState.fontScale)
                        font.weight: parent.isToday ? Font.Bold : Font.Normal
                        color: parent.isToday ? pal.onAccent : ncCalDaysRepeater2._text
                    }
                    Rectangle {
                        visible: ncCalDayCell2.hasEvents
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 1
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 4; height: 4; radius: 2
                        color: ncCalDayCell2.isToday ? pal.onAccent : ncCalDaysRepeater2._dot
                    }
                    HoverHandler { id: ncCalDayHov2 }
                    MouseArea {
                        anchors.fill: parent
                        enabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ncCalWidgetItem.selectedDay = modelData + 1
                    }
                }
            }
        }
    }

    CalendarEventEditor {
        colorError: pal.error
        id: ncCalEventEditor
        x: 14
        y: ncCalMiniGridCol.y + ncCalMiniGridCol.height + 14
        width: parent.width - 28
        height: Math.max(60, parent.height - y - 14)

        hasSelection: ncCalWidgetItem.selectedDay >= 0
        selectedDateLabel: ncCalWidgetItem.selectedDay >= 0
        ? new Date(ncCalWidgetItem.calYear, ncCalWidgetItem.calMonth, ncCalWidgetItem.selectedDay).toLocaleDateString(Qt.locale(localeCode()), "d MMMM yyyy")
        : ""
        eventsForDay: ncCalWidgetItem.selectedDateEvents
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

        onAddRequested: (title, type) => addCalendarEvent(ncCalWidgetItem.selectedDateKey, title, type)
        onRemoveRequested: (index) => removeCalendarEvent(ncCalWidgetItem.selectedDateKey, index)
        onRemoveGlobalRequested: (dateKey, index) => removeCalendarEvent(dateKey, index)
        onInputFocusChanged: (focused) => globalState.calEventInputFocused = focused
    }
}
