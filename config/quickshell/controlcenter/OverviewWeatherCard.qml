import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../widgets"

// Weather card of the overview dashboard
Rectangle {
    id: ncWeatherCard
    visible: ncDashLayer.shown("weather")
    x: ncDashLayer.rWeather.x
    y: ncDashLayer.rWeather.y
    Behavior on y { enabled: globalState.ncEditMode; M3SpringAnim { token: "spatialDefault" } }
    width: ncDashLayer.rWeather.width
    height: ncDashLayer.rWeather.height
    radius: 28
    color: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont)
    Behavior on color { M3ColorAnim {} }


    Timer {
        id: ncWeatherPillClock
        property int nowHour: new Date().getHours()
        interval: 60000; running: true; repeat: true
        onTriggered: nowHour = new Date().getHours()
    }

    Item { id: ncWeatherPillShape; anchors.fill: parent; property color color: ncWeatherCard.color }

    Column {
        id: ncWeatherContentCol
        anchors.verticalCenter: parent.verticalCenter
        x: 26
        spacing: 6

        Item {
            id: ncWeatherRow
            anchors.horizontalCenter: parent.horizontalCenter
            readonly property int overlap: 34
            width:  ncWeatherIcon.width + ncWeatherTempText.width - overlap
            height: Math.max(ncWeatherIcon.height, ncWeatherTempText.height) + 24

            Item {
                id: ncWeatherIcon
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 14
                z: 1
                width: 78; height: 66

                property bool isDay: ncWeatherPillClock.nowHour >= 6 && ncWeatherPillClock.nowHour < 19
                property bool isCloudy: {
                    var d = globalState.weatherDesc.toLowerCase();
                    if (d === "") return false;
                    return d.indexOf("clear") < 0 && d.indexOf("sunny") < 0 && d.indexOf("despejado") < 0 && d.indexOf("soleado") < 0;
                }

                SunShape {
                    id: ncSun
                    visible: ncWeatherIcon.isDay
                    anchors.left: parent.left
                    anchors.top: parent.top
                    size: 62
                }
                MoonShape {
                    id: ncCelestialBody
                    visible: !ncWeatherIcon.isDay
                    anchors.left: parent.left
                    anchors.top: parent.top
                    size: 54
                }

                CloudShape {
                    visible: ncWeatherIcon.isCloudy
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    width: 66; height: 39
                }
            }

            Text {
                id: ncWeatherTempText
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -14
                z: 0
                width: 120
                horizontalAlignment: Text.AlignHCenter
                text: globalState.weatherTemp !== "" ? globalState.weatherTemp + "°" : "—"
                font.family: globalState.fontPrimary; font.pixelSize: Math.round(62 * globalState.fontScale); font.weight: Font.Light
                color: pal.colorOnSurface
                Behavior on color { M3ColorAnim {} }
            }
        }

        Column {
            id: ncWeatherDetailCol
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 3
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: globalState.weatherCity !== "" ? globalState.weatherCity : "—"
                font.family: globalState.fontPrimary; font.pixelSize: Math.round(15 * globalState.fontScale); font.weight: Font.DemiBold
                color: pal.colorOnSurface
                elide: Text.ElideRight
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: globalState.weatherDesc !== ""
                text: weatherText(globalState.weatherDesc)
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale)
                color: pal.colorOnSurfVar
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: tr("feels_like") + ": " + (globalState.weatherFeel !== "" ? globalState.weatherFeel + "°C" : "—")
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale)
                color: pal.textSecondary
            }
        }
    }

    WeatherForecastRow {
        id: ncWeatherForecastRow
        x: ncWeatherContentCol.x + ncWeatherContentCol.width + 28
        y: 20
        width: Math.max(120, parent.width - x - 20)
        height: Math.max(60, parent.height - y - ncWeatherStatBars.height - 20 - 16)

        todayLabel:    tr("today")
        tomorrowLabel: tr("tomorrow")
        weekdayLabels: weekdayInitials()

        colorPrimary:        pal.primary
        colorOnSurfVar:      pal.colorOnSurfVar
        colorTextSecondary:  pal.textSecondary
        cardBg:              globalState.glassMode ? ga(pal.surface, 0.5) : pal.surface
        days: globalState.weatherForecast
    }

    RowLayout {
        id: ncWeatherStatBars
        x: ncWeatherForecastRow.x
        width: ncWeatherForecastRow.width
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 20
        spacing: 16

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
}
