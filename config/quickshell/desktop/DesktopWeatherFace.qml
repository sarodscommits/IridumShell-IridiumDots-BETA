import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../widgets"

// Face of the desktop weather widget
Item {
    id: desktopWeatherFace
    anchors.fill: parent
    readonly property var extraInfo: weatherExtraInfo
    Item {
        id: weatherWidgetVisual
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: 244; height: 244
        transformOrigin: Item.Top
        scale: parent.width / 244

        Rectangle {
            id: desktopWeatherPillShape
            anchors.centerIn: parent
            width: 100; height: 70
            radius: height / 2
            antialiasing: true
            rotation: -45
            scale: 122 / (15 * Math.SQRT1_2 + 35)
            color: weatherWidgetRoot.pillFillColor
            Behavior on color { M3ColorAnim {} }
        }

        Item {
            id: weatherWidgetRow
            anchors.centerIn: parent
            rotation: -45
            width: 214; height: 150

            Item {
                id: weatherWidgetIcon
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                rotation: 45
                z: 1
                width: 96; height: 82

                property bool isDay: weatherWidgetClock.nowHour >= 6 && weatherWidgetClock.nowHour < 19
                property bool isCloudy: {
                    var d = globalState.weatherDesc.toLowerCase();
                    if (d === "") return false;
                    return d.indexOf("clear") < 0 && d.indexOf("sunny") < 0 && d.indexOf("despejado") < 0 && d.indexOf("soleado") < 0;
                }

                SunShape {
                    visible: weatherWidgetIcon.isDay
                    anchors.left: parent.left
                    anchors.top: parent.top
                    size: 76
                }
                MoonShape {
                    visible: !weatherWidgetIcon.isDay
                    anchors.left: parent.left
                    anchors.top: parent.top
                    size: 66
                }

                CloudShape {
                    visible: weatherWidgetIcon.isCloudy
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    width: 82; height: 48
                }
            }

            Text {
                id: weatherWidgetTempText
                anchors.right: parent.right
                anchors.rightMargin: -4
                anchors.verticalCenter: parent.verticalCenter
                rotation: 45
                z: 0
                width: 120
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: globalState.weatherTemp !== "" ? globalState.weatherTemp + "°" : "—"
                font.family: globalState.fontPrimary; font.pixelSize: Math.round(54 * globalState.fontScale); font.weight: Font.Black
                color: pal.colorOnSurface
                Behavior on color { M3ColorAnim {} }
            }
        }
    }

    Column {
        id: weatherExtraInfo
        anchors.top: weatherWidgetVisual.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 2
        visible: globalState.weatherShowFeelsLike || globalState.weatherShowHumidity || globalState.weatherShowWind
        Text {
            visible: globalState.weatherShowFeelsLike
            text: tr("feels_like") + ": " + (globalState.weatherFeel !== "" ? globalState.weatherFeel + "°C" : "—")
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale)
            color: pal.colorOnSurface
        }
        Text {
            visible: globalState.weatherShowHumidity
            text: tr("humidity") + ": " + (globalState.weatherHumidity !== "" ? globalState.weatherHumidity + "%" : "—")
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale)
            color: pal.colorOnSurface
        }
        Text {
            visible: globalState.weatherShowWind
            text: tr("wind") + ": " + (globalState.weatherWind !== "" ? globalState.weatherWind + " km/h" : "—")
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale)
            color: pal.colorOnSurface
        }
    }
}
