import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../widgets"

// Weather forecast pills desktop widget
ExprDesktopWidget {
    id: weatherPillsWidgetRoot
    wType: "wpills"
    enabledProp: "weatherPillsWidgetEnabled"; xProp: "weatherPillsWidgetX"; yProp: "weatherPillsWidgetY"; scaleProp: "weatherPillsWidgetScale"
    baseW: 275; baseH: 275
    face: Component {
        Item {
            id: wpFace
            readonly property real u: width / 275
            readonly property real pad: 14 * u
            property int nowHour: new Date().getHours()
            Timer { interval: 60000; running: true; repeat: true; onTriggered: wpFace.nowHour = new Date().getHours() }
            readonly property bool isDay: nowHour >= 6 && nowHour < 19
            function glyphFor(desc, day) {
                var d = (desc || "").toLowerCase();
                if (d.indexOf("thunder") >= 0 || d.indexOf("torment") >= 0) return "";
                if (d.indexOf("snow") >= 0 || d.indexOf("niev") >= 0 || d.indexOf("sleet") >= 0 || d.indexOf("ice") >= 0) return "";
                if (d.indexOf("rain") >= 0 || d.indexOf("drizzle") >= 0 || d.indexOf("shower") >= 0 || d.indexOf("lluv") >= 0 || d.indexOf("llovizna") >= 0) return "";
                if (d.indexOf("fog") >= 0 || d.indexOf("niebla") >= 0) return "";
                if (d.indexOf("mist") >= 0 || d.indexOf("haze") >= 0 || d.indexOf("neblina") >= 0 || d.indexOf("bruma") >= 0) return "";
                if (d.indexOf("partly") >= 0 || d.indexOf("parcial") >= 0) return day ? "" : "";
                if (d.indexOf("cloud") >= 0 || d.indexOf("overcast") >= 0 || d.indexOf("nublado") >= 0 || d.indexOf("nubes") >= 0) return "";
                return day ? "" : "";
            }
            function dayLabel(i, dateStr) {
                if (i === 0) return tr("today");
                var d = new Date(dateStr + "T12:00:00");
                if (isNaN(d.getTime())) return "";
                var n = Qt.locale(localeCode()).standaloneDayName(d.getDay(), Locale.ShortFormat);
                return n.length ? n.charAt(0).toUpperCase() + n.slice(1) : n;
            }
            readonly property var days: (globalState.weatherForecast || []).slice(0, 3)

            Rectangle {
                anchors.fill: parent
                radius: 36 * wpFace.u
                color: desktopWidgetLayer.exprDark
            }
            Item {
                id: wpTop
                x: wpFace.pad + 4 * wpFace.u; y: wpFace.pad
                width: parent.width - 2 * x
                height: parent.height * 0.36
                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: wpFace.glyphFor(globalState.weatherDesc, wpFace.isDay)
                    font.family: "Material Symbols Rounded"; font.pixelSize: Math.max(14, Math.round(64 * wpFace.u))
                    color: m3.primary
                }
                Column {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * 0.6
                    spacing: -2 * wpFace.u
                    Text {
                        anchors.right: parent.right
                        text: globalState.weatherTemp !== "" ? globalState.weatherTemp + "°" : "—"
                        font.family: globalState.fontPrimary; font.pixelSize: Math.max(12, Math.round(44 * wpFace.u)); font.weight: Font.Black
                        color: pal.colorOnSurface
                    }
                    Text {
                        anchors.right: parent.right
                        width: parent.width
                        horizontalAlignment: Text.AlignRight
                        text: globalState.weatherDesc !== "" ? weatherText(globalState.weatherDesc) : "—"
                        font.family: globalState.fontSecondary; font.pixelSize: Math.max(7, Math.round(13 * wpFace.u)); font.weight: Font.DemiBold
                        color: pal.colorOnSurfVar
                        elide: Text.ElideRight
                    }
                }
            }
            Row {
                x: wpFace.pad; y: wpTop.y + wpTop.height + 8 * wpFace.u
                width: parent.width - 2 * wpFace.pad
                height: parent.height - y - wpFace.pad
                spacing: 8 * wpFace.u
                Repeater {
                    id: wpRep1
                    model: 3
                    property color c0: m3.primaryContainer
                    property color i0: m3.inkPrimaryContainer
                    property color c1: m3.tertiaryContainer
                    property color i1: m3.inkTertiaryContainer
                    delegate: Rectangle {
                        id: wpPill
                        required property int index
                        readonly property var day: index < wpFace.days.length ? wpFace.days[index] : null
                        width: (parent.width - 2 * parent.spacing) / 3
                        height: parent.height
                        radius: width / 2
                        color: index === 1 ? wpRep1.c1 : wpRep1.c0
                        Column {
                            anchors.centerIn: parent
                            spacing: 6 * wpFace.u
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: wpPill.day ? wpFace.dayLabel(wpPill.index, wpPill.day.date) : "—"
                                font.family: globalState.fontPrimary; font.pixelSize: Math.max(7, Math.round(13 * wpFace.u)); font.weight: Font.Bold
                                color: wpPill.index === 1 ? wpRep1.i1 : wpRep1.i0
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: wpFace.glyphFor(wpPill.day ? wpPill.day.desc : "", true)
                                font.family: "Material Symbols Rounded"; font.pixelSize: Math.max(10, Math.round(28 * wpFace.u))
                                color: wpPill.index === 1 ? wpRep1.i1 : wpRep1.i0
                            }
                            Column {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: -2 * wpFace.u
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: wpPill.day && wpPill.day.max !== "" ? wpPill.day.max + "°" : "—"
                                    font.family: globalState.fontPrimary; font.pixelSize: Math.max(8, Math.round(16 * wpFace.u)); font.weight: Font.Black
                                    color: wpPill.index === 1 ? wpRep1.i1 : wpRep1.i0
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    visible: !!(wpPill.day && wpPill.day.min !== "")
                                    text: wpPill.day ? wpPill.day.min + "°" : ""
                                    font.family: globalState.fontSecondary; font.pixelSize: Math.max(7, Math.round(11 * wpFace.u)); font.weight: Font.DemiBold
                                    color: wpPill.index === 1 ? wpRep1.i1 : wpRep1.i0
                                    opacity: 0.7
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
