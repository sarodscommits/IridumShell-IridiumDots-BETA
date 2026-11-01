import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../widgets"

// Weather card of the left panel
Rectangle {
    id: weatherCard
    visible: !calPanel.anyWidgetExpanded || weatherCard.weatherExpanded
    Layout.fillWidth: true
    Layout.fillHeight: weatherCard.weatherExpanded
    color: "transparent"
    implicitHeight: 230

    property bool weatherPeek:     false
    property bool weatherExpanded: false

    property bool weatherHovered: false

    HoverHandler {
        id: weatherCardHover
        onHoveredChanged: weatherCard.weatherHovered = hovered
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            clockWidgetItem.clockPeek = false;
            clockWidgetItem.clockExpanded = false;
            calWidgetItem.calPeek = false;
            calWidgetItem.calExpanded = false;
            calWidgetItem.selectedDay = -1;
            fetchWidgetItem.fetchPeek = false;
            fetchWidgetItem.fetchExpanded = false;
            if (!weatherCard.weatherPeek && !weatherCard.weatherExpanded) {
                weatherCard.weatherPeek = true;
                globalState.reloadWeather();
            } else if (weatherCard.weatherPeek && !weatherCard.weatherExpanded) {
                weatherCard.weatherExpanded = true;
            }
        }
    }

    Connections {
        target: globalState
        function onCalendarMenuOpenChanged() {
            if (!globalState.calendarMenuOpen) {
                weatherCard.weatherExpanded = false;
                weatherCard.weatherPeek = false;
            }
        }
        function onLeftPanelPageChanged() {
            if (globalState.leftPanelPage !== 0) {
                weatherCard.weatherExpanded = false;
                weatherCard.weatherPeek = false;
            }
        }
    }

    Timer {
        id: weatherPillClock
        property int nowHour: new Date().getHours()
        interval: 60000; running: true; repeat: true
        onTriggered: nowHour = new Date().getHours()
    }

    Rectangle {
        id: weatherPillShape
        width:  (weatherCard.weatherPeek || weatherCard.weatherExpanded) ? weatherCard.width : 178
        height: weatherCard.weatherExpanded ? weatherCard.height : ((weatherCard.weatherPeek || weatherCard.weatherExpanded) ? 224 : 178)
        radius: (weatherCard.weatherPeek || weatherCard.weatherExpanded) ? 28 : 65
        rotation: (weatherCard.weatherPeek || weatherCard.weatherExpanded) ? 360 : 45
        anchors.centerIn: parent
        color: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont)
        Behavior on color    { M3ColorAnim {} }
        Behavior on width    { M3SpringAnim { token: "spatialSlow" } }
        Behavior on height   { M3SpringAnim { token: "spatialSlow" } }
        Behavior on radius   { M3SpringAnim { token: "spatialSlow" } }
        Behavior on rotation { M3SpringAnim { token: "spatialSlow" } }
    }

    WeatherCardContent { id: weatherContentCol }

    ColumnLayout {
        id: weatherStatBarsFrame
        visible: weatherCard.weatherExpanded
        opacity: weatherCard.weatherExpanded ? 1 : 0
        Behavior on opacity { M3NumberAnim {} }

        anchors.horizontalCenter: weatherPillShape.horizontalCenter
        y: weatherContentCol.y + weatherContentCol.height + 14
        width: weatherPillShape.width - 40
        spacing: 8

        WeatherStatBar {
            Layout.fillWidth: true
            colorPrimary:   pal.primary
            colorOnSurfVar: pal.colorOnSurfVar
            trackColor:     globalState.glassMode ? ga(pal.surface, 0.5) : pal.surface
            label: tr("humidity")
            valueText: globalState.weatherHumidity !== "" ? globalState.weatherHumidity + "%" : "—"
            pct: globalState.weatherHumidity !== "" ? parseFloat(globalState.weatherHumidity) / 100 : 0
        }
        WeatherStatBar {
            Layout.fillWidth: true
            colorPrimary:   pal.primary
            colorOnSurfVar: pal.colorOnSurfVar
            trackColor:     globalState.glassMode ? ga(pal.surface, 0.5) : pal.surface
            label: tr("wind")
            valueText: globalState.weatherWind !== "" ? globalState.weatherWind + " km/h" : "—"
            pct: globalState.weatherWind !== "" ? parseFloat(globalState.weatherWind) / 60 : 0
        }
    }

    WeatherForecastRow {
        id: weatherForecastRowFrame
        visible: weatherCard.weatherExpanded
        opacity: weatherCard.weatherExpanded ? 1 : 0
        Behavior on opacity { M3NumberAnim {} }

        anchors.horizontalCenter: weatherPillShape.horizontalCenter
        y: weatherStatBarsFrame.y + weatherStatBarsFrame.height + 16
        width: weatherPillShape.width - 32
        height: Math.max(70, weatherPillShape.y + weatherPillShape.height - y - 20)

        vertical: true
        todayLabel:    tr("today")
        tomorrowLabel: tr("tomorrow")
        weekdayLabels: weekdayInitials()

        colorPrimary:        pal.primary
        colorOnSurfVar:      pal.colorOnSurfVar
        colorTextSecondary:  pal.textSecondary
        cardBg:              globalState.glassMode ? ga(pal.surface, 0.5) : pal.surface
        days: globalState.weatherForecast
    }

    Rectangle {
        id: weatherCloseBtn
        visible: weatherCard.weatherExpanded
        opacity: weatherCard.weatherExpanded ? 1 : 0
        Behavior on opacity { M3NumberAnim {} }
        z: 50
        width: 26; height: 26; radius: 13
        x: weatherPillShape.x + weatherPillShape.width - width - 12
        y: weatherPillShape.y + 20
        color: weatherCloseBtnHov.hovered ? pal.primaryCont : "transparent"
        Behavior on color { M3ColorAnim { duration: m3.durFast } }
        Text { anchors.centerIn: parent; text: "\ue5cd"; font.family: "Material Symbols Rounded"; font.pixelSize: 15; color: pal.colorOnSurfVar }
        HoverHandler { id: weatherCloseBtnHov }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                weatherCard.weatherExpanded = false;
                weatherCard.weatherPeek = false;
            }
        }
    }
}
