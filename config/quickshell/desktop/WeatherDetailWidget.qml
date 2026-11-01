import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../widgets"

// Weather detail card of the desktop
CardWidgetFrame {
    id: weatherDetailWidgetRoot
    key: "weatherDetail"

    property real weatherWavePhase: 0
    Timer {
        interval: 40
        repeat: true
        running: globalState.weatherDetailWidgetEnabled && !globalState.lockScreenActive && !globalState.wpFullscreenActive
        onTriggered: weatherDetailWidgetRoot.weatherWavePhase = (weatherDetailWidgetRoot.weatherWavePhase + 0.015) % (Math.PI * 2)
    }

    body: Component {
        Item {
            anchors.fill: parent
            Item {
                id: wdBody
                anchors.fill: parent
                anchors.margins: 18
                readonly property bool wide: weatherDetailWidgetRoot.isWide
                readonly property var stats: [
                { label: tr("feels_like"), value: globalState.weatherFeel !== "" ? globalState.weatherFeel + "°C" : "—",
                    pct: globalState.weatherFeel !== "" ? Math.max(0, Math.min(1, (parseFloat(globalState.weatherFeel) + 10) / 50)) : 0 },
                { label: tr("humidity"), value: globalState.weatherHumidity !== "" ? globalState.weatherHumidity + "%" : "—",
                    pct: globalState.weatherHumidity !== "" ? Math.max(0, Math.min(1, parseFloat(globalState.weatherHumidity) / 100)) : 0 },
                { label: tr("wind"), value: globalState.weatherWind !== "" ? globalState.weatherWind + " km/h" : "—",
                    pct: globalState.weatherWind !== "" ? Math.max(0, Math.min(1, parseFloat(globalState.weatherWind) / 60)) : 0 }
                ]
                readonly property real colGap: 16
                readonly property real leftW: wide ? (width - colGap) / 2 : width

                RowLayout {
                    id: wdHeader
                    x: 0; y: 0
                    width: wdBody.leftW
                    spacing: 10
                    Text {
                        text: globalState.weatherTemp !== "" ? globalState.weatherTemp + "°" : "—"
                        font.family: globalState.fontPrimary; font.pixelSize: Math.round(34 * globalState.fontScale); font.weight: Font.Bold
                        color: pal.primary
                    }
                    Text {
                        Layout.fillWidth: true
                        text: globalState.weatherDesc !== "" ? weatherText(globalState.weatherDesc) : "—"
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(14 * globalState.fontScale)
                        color: pal.colorOnSurfVar
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                }

                Column {
                    id: wdStats
                    x: wdBody.wide ? wdBody.leftW + wdBody.colGap : 0
                    width: wdBody.wide ? wdBody.width - x : wdBody.width
                    y: wdBody.wide ? (wdBody.height - height) / 2 : wdBody.height - height
                    spacing: 10
                    Repeater {
                        id: wdStatRep
                        model: 3
                        property color _lbl: pal.colorOnSurfVar
                        property color _val: pal.colorOnSurface
                        delegate: Column {
                            required property int index
                            readonly property var st: wdBody.stats[index]
                            width: wdStats.width
                            spacing: 3
                            Item {
                                width: parent.width
                                height: wdStatLbl.implicitHeight
                                Text {
                                    id: wdStatLbl
                                    anchors.left: parent.left
                                    width: parent.width - wdStatVal.implicitWidth - 8
                                    text: st.label
                                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                                    color: wdStatRep._lbl
                                    elide: Text.ElideRight
                                }
                                Text {
                                    id: wdStatVal
                                    anchors.right: parent.right
                                    text: st.value
                                    font.family: globalState.fontPrimary; font.pixelSize: Math.round(13 * globalState.fontScale); font.weight: Font.Bold
                                    color: wdStatRep._val
                                }
                            }
                            EWavyLinear {
                                width: parent.width
                                height: implicitHeight
                                value: st.pct
                                showHandle: false
                                amplitude: 2.5; wavelength: 26
                                running: weatherDetailWidgetRoot.visible && !globalState.lockScreenActive && !globalState.wpFullscreenActive
                            }
                        }
                    }
                }

                WeatherForecastRow {
                    id: wdDays
                    x: 0
                    y: wdHeader.height + 10
                    width: wdBody.leftW
                    height: Math.max(60, (wdBody.wide ? wdBody.height : wdStats.y - 10) - y)
                    shapedCards: true
                    todayLabel:    tr("today")
                    tomorrowLabel: tr("tomorrow")
                    weekdayLabels: weekdayInitials()
                    colorPrimary:       pal.primary
                    colorOnSurfVar:     pal.colorOnSurfVar
                    colorTextSecondary: pal.textSecondary
                    cardBg:             globalState.glassMode ? ga(pal.surface, 0.5) : pal.surface
                    days: globalState.weatherForecast
                }
            }
        }
    }
}
