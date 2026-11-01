import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../panels"

// Calendar detail card of the desktop
CardWidgetFrame {
    id: calDetailWidgetRoot
    key: "calDetail"

    property int cdDay: 1
    property int cdMonth: 0
    property int cdYear: 1970
    property int cdWeekday: 0
    readonly property string todayKey: cdYear + "-" + cdMonth + "-" + cdDay
    readonly property var todayEvents: globalState.calendarEvents[todayKey] || []
    Timer {
        interval: 60000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            var d = new Date();
            calDetailWidgetRoot.cdDay     = d.getDate();
            calDetailWidgetRoot.cdMonth   = d.getMonth();
            calDetailWidgetRoot.cdYear    = d.getFullYear();
            calDetailWidgetRoot.cdWeekday = d.getDay();
        }
    }

    body: Component {
        Item {
            anchors.fill: parent
            GridLayout {
                anchors.fill: parent
                anchors.margins: 16
                columns: calDetailWidgetRoot.isWide ? 2 : 1
                rowSpacing: 6
                columnSpacing: 14

                Text {
                    Layout.fillWidth: !calDetailWidgetRoot.isWide
                    Layout.preferredWidth: calDetailWidgetRoot.isWide ? 90 : -1
                    Layout.row: 0
                    Layout.column: 0
                    Layout.alignment: calDetailWidgetRoot.isWide ? Qt.AlignTop : 0
                    text: Qt.locale(localeCode()).standaloneDayName(calDetailWidgetRoot.cdWeekday, Locale.ShortFormat) + " " +
                    calDetailWidgetRoot.cdDay + " " +
                    Qt.locale(localeCode()).standaloneMonthName(calDetailWidgetRoot.cdMonth, Locale.ShortFormat)
                    font.family: globalState.fontPrimary; font.pixelSize: Math.round(16 * globalState.fontScale); font.weight: Font.Bold
                    color: pal.colorOnSurface
                    elide: Text.ElideRight
                    wrapMode: calDetailWidgetRoot.isWide ? Text.WordWrap : Text.NoWrap
                }

                CalendarEventEditor {
                    colorError: pal.error
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.row: calDetailWidgetRoot.isWide ? 0 : 1
                    Layout.column: calDetailWidgetRoot.isWide ? 1 : 0

                    hasSelection: true
                    selectedDateLabel: Qt.locale(localeCode()).standaloneDayName(calDetailWidgetRoot.cdWeekday, Locale.ShortFormat) + " " +
                    calDetailWidgetRoot.cdDay + " " +
                    Qt.locale(localeCode()).standaloneMonthName(calDetailWidgetRoot.cdMonth, Locale.ShortFormat)
                    eventsForDay: calDetailWidgetRoot.todayEvents
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

                    onAddRequested: (title, type) => addCalendarEvent(calDetailWidgetRoot.todayKey, title, type)
                    onRemoveRequested: (index) => removeCalendarEvent(calDetailWidgetRoot.todayKey, index)
                    onRemoveGlobalRequested: (dateKey, index) => removeCalendarEvent(dateKey, index)
                    onInputFocusChanged: (focused) => globalState.calEventInputFocused = focused
                }
            }
        }
    }
}
