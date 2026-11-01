import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../widgets"

// Weather card readings
Column {
    id: weatherContentCol
    anchors.horizontalCenter: weatherPillShape.horizontalCenter
    y: weatherCard.weatherExpanded
    ? (weatherPillShape.y + 52)
    : (weatherPillShape.y + (weatherPillShape.height - height) / 2)
    Behavior on y { M3SpringAnim { token: "spatialSlow" } }
    spacing: 4

    Item {
        id: weatherRow
        anchors.horizontalCenter: parent.horizontalCenter
        readonly property int overlap: 34
        width:  weatherIcon.width + weatherTempText.width - overlap
        height: Math.max(weatherIcon.height, weatherTempText.height) + 24

        Item {
            id: weatherIcon
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 14
            z: 1
            width: 78; height: 66

            property bool isDay: weatherPillClock.nowHour >= 6 && weatherPillClock.nowHour < 19
            property bool isCloudy: {
                var d = globalState.weatherDesc.toLowerCase();
                if (d === "") return false;
                return d.indexOf("clear") < 0 && d.indexOf("sunny") < 0 && d.indexOf("despejado") < 0 && d.indexOf("soleado") < 0;
            }

            SunShape {
                id: sun
                visible: weatherIcon.isDay
                anchors.left: parent.left
                anchors.top: parent.top
                size: 62
            }
            MoonShape {
                id: celestialBody
                visible: !weatherIcon.isDay
                anchors.left: parent.left
                anchors.top: parent.top
                size: 54
            }

            CloudShape {
                visible: weatherIcon.isCloudy
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                width: 66; height: 39
            }
        }

        Text {
            id: weatherTempText
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
        id: weatherDetailCol
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 3
        opacity: (weatherCard.weatherPeek || weatherCard.weatherExpanded) ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity {
            M3NumberAnim { duration: (weatherCard.weatherPeek || weatherCard.weatherExpanded) ? 320 : 180 }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: globalState.weatherCity !== "" ? globalState.weatherCity : "—"
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
            color: pal.colorOnSurfVar
            elide: Text.ElideRight
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: tr("feels_like") + ": " + (globalState.weatherFeel !== "" ? globalState.weatherFeel + "°C" : "—")
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale)
            color: pal.textSecondary
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: tr("humidity") + ": " + (globalState.weatherHumidity !== "" ? globalState.weatherHumidity + "%" : "—")
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale)
            color: pal.textSecondary
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: tr("wind") + ": " + (globalState.weatherWind !== "" ? globalState.weatherWind + " km/h" : "—")
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale)
            color: pal.textSecondary
        }
    }
}
