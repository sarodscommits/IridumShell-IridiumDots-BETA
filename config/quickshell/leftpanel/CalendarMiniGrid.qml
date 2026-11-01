import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Month grid of the calendar card
ColumnLayout {
    id: calMiniGridCol
    x: calShapeCanvas.x + 12
    y: calWidgetItem.calExpanded ? (calShapeCanvas.y + 52) : (calShapeCanvas.y + 12)
    Behavior on y { M3SpringAnim { token: "spatialDefault" } }
    width: calShapeCanvas.width - 24
    spacing: 6
    opacity: (calWidgetItem.calPeek || calWidgetItem.calExpanded) ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity {
        M3NumberAnim { duration: (calWidgetItem.calPeek || calWidgetItem.calExpanded) ? 320 : 160 }
    }

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
                calWidgetItem.calMonth -= 1;
                if (calWidgetItem.calMonth < 0) { calWidgetItem.calMonth = 11; calWidgetItem.calYear -= 1; }
                calWidgetItem.selectedDay = -1;
            }
        }
        Item { Layout.fillWidth: true }
        Text {
            text: Qt.locale(localeCode()).standaloneMonthName(calWidgetItem.calMonth, Locale.LongFormat) + " " + calWidgetItem.calYear
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium
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
                calWidgetItem.calMonth += 1;
                if (calWidgetItem.calMonth > 11) { calWidgetItem.calMonth = 0; calWidgetItem.calYear += 1; }
                calWidgetItem.selectedDay = -1;
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
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(9 * globalState.fontScale); font.weight: Font.Medium
                color: pal.textSecondary
            }
        }
    }

    Grid {
        Layout.fillWidth: true
        columns: 7
        columnSpacing: 1; rowSpacing: 2

        Repeater {
            model: calWidgetItem.firstWeekday(calWidgetItem.calYear, calWidgetItem.calMonth)
            Item { width: (calMiniGridCol.width) / 7; height: 20 }
        }

        Repeater {
            id: calDaysRepeater2
            model: calWidgetItem.daysInMonth(calWidgetItem.calYear, calWidgetItem.calMonth)
            property color _text: pal.textPrimary
            property color _dot:  pal.primary
            property color _accent: pal.accent
            Rectangle {
                id: calDayCell2
                width: calMiniGridCol.width / 7; height: 20; radius: 5
                property bool isToday: (modelData + 1) === calWidgetItem.todayDay &&
                calWidgetItem.calMonth === calWidgetItem.todayMonth &&
                calWidgetItem.calYear  === calWidgetItem.todayYear
                property bool isSelected: calWidgetItem.calExpanded && (modelData + 1) === calWidgetItem.selectedDay
                property bool hasEvents: {
                    var k = calWidgetItem.dateKeyFor(calWidgetItem.calYear, calWidgetItem.calMonth, modelData + 1);
                    return !!(globalState.calendarEvents[k] && globalState.calendarEvents[k].length > 0);
                }
                color: isToday ? "transparent"
                : isSelected ? pal.primaryCont
                : (calDayHov2.hovered ? pal.surfaceVar : "transparent")
                Behavior on color { M3ColorAnim {} }
                Spring { id: calDayCell2Spin; target: calDayHov2.hovered ? 45 : 0; token: "spatialDefault"; eps: 0.05 }
                MShape {
                    anchors.centerIn: parent
                    visible: calDayCell2.isToday
                    width: Math.min(parent.width, parent.height + 6); height: width
                    inset: 1.0
                    from: m3.accentShape; to: m3.accentShape
                    rotation: calDayCell2Spin.value
                    fill: calDaysRepeater2._accent
                }
                Text {
                    anchors.centerIn: parent
                    text: modelData + 1
                    font.family: globalState.fontPrimary; font.pixelSize: Math.round(10 * globalState.fontScale)
                    font.weight: parent.isToday ? Font.Bold : Font.Normal
                    color: parent.isToday ? pal.onAccent : calDaysRepeater2._text
                }
                Rectangle {
                    visible: calDayCell2.hasEvents
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 1
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 4; height: 4; radius: 2
                    color: calDayCell2.isToday ? pal.onAccent : calDaysRepeater2._dot
                }
                HoverHandler { id: calDayHov2 }
                MouseArea {
                    anchors.fill: parent
                    enabled: calWidgetItem.calExpanded
                    cursorShape: Qt.PointingHandCursor
                    onClicked: calWidgetItem.selectedDay = modelData + 1
                }
            }
        }
    }
}
