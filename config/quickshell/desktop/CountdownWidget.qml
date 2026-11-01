import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../widgets"

// Countdown-to-event desktop widget
ExprDesktopWidget {
    id: countdownWidgetRoot
    wType: "countdown"
    enabledProp: "countdownWidgetEnabled"; xProp: "countdownWidgetX"; yProp: "countdownWidgetY"; scaleProp: "countdownWidgetScale"
    baseW: 275; baseH: 220
    face: Component {
        Item {
            id: cdwFace
            readonly property real u: width / 275
            property real dayStamp: 0
            Timer {
                interval: 60000; running: true; repeat: true; triggeredOnStart: true
                onTriggered: { var d = new Date(); cdwFace.dayStamp = new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime(); }
            }
            readonly property var next: {
                var t0 = dayStamp;
                if (!t0) return null;
                var evs = globalState.calendarEvents, best = null;
                for (var key in evs) {
                    var arr = evs[key];
                    if (!arr || !arr.length) continue;
                    var p = key.split("-");
                    var tm = new Date(parseInt(p[0], 10), parseInt(p[1], 10), parseInt(p[2], 10)).getTime();
                    if (isNaN(tm) || tm < t0) continue;
                    if (!best || tm < best.time) best = { time: tm, title: arr[0].title, type: arr[0].type, more: arr.length - 1 };
                }
                return best;
            }
            readonly property int days: next ? Math.round((next.time - dayStamp) / 86400000) : -1
            readonly property var typeGlyph: ({ reminder: "", holiday: "", birthday: "", event: "" })

            MBox {
                id: cdwDome
                width: parent.width
                height: Math.round(parent.height * 0.56)
                from: "Arch"
                keepAspect: false
                fill: desktopWidgetLayer.exprDark
            }
            Column {
                anchors.horizontalCenter: cdwDome.horizontalCenter
                anchors.verticalCenter: cdwDome.verticalCenter
                anchors.verticalCenterOffset: cdwDome.height * 0.1
                width: cdwDome.width * 0.74
                spacing: 2 * cdwFace.u
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: cdwFace.next ? (cdwFace.typeGlyph[cdwFace.next.type] || "") : ""
                    font.family: "Material Symbols Rounded"; font.pixelSize: Math.max(8, Math.round(18 * cdwFace.u))
                    color: m3.primary
                }
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: cdwFace.next ? cdwFace.next.title + (cdwFace.next.more > 0 ? "  +" + cdwFace.next.more : "") : tr("dw_no_events")
                    font.family: globalState.fontPrimary; font.pixelSize: Math.max(8, Math.round(17 * cdwFace.u)); font.weight: Font.Bold
                    color: pal.colorOnSurface
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
            }
            Row {
                y: cdwDome.height + 8 * cdwFace.u
                width: parent.width
                height: parent.height - y
                spacing: 8 * cdwFace.u
                Item {
                    id: cdwSun
                    width: parent.height; height: parent.height
                    HoverHandler { id: cdwSunHov }
                    Spring { id: cdwSunR; target: (cdwSunHov.hovered ? 45 : 0) + Math.max(0, cdwFace.days) * 9; token: "spatialDefault"; eps: 0.05 }
                    MBox {
                        anchors.fill: parent
                        from: "Sunny"
                        rotation: cdwSunR.value
                        fill: m3.tertiaryContainer
                    }
                    Text {
                        anchors.centerIn: parent
                        text: cdwFace.days < 0 ? "—" : cdwFace.days
                        font.family: globalState.fontPrimary; font.pixelSize: Math.max(10, Math.round((cdwFace.days > 99 ? 24 : 32) * cdwFace.u)); font.weight: Font.Black
                        color: m3.inkTertiaryContainer
                    }
                }
                Rectangle {
                    width: parent.width - parent.height - parent.spacing
                    height: parent.height
                    radius: height / 2
                    color: m3.primaryContainer
                    Text {
                        anchors.centerIn: parent
                        width: parent.width - 24 * cdwFace.u
                        horizontalAlignment: Text.AlignHCenter
                        text: cdwFace.days < 0 ? tr("dw_add_event")
                        : cdwFace.days === 0 ? tr("today")
                        : cdwFace.days === 1 ? tr("dw_tomorrow")
                        : tr("dw_days_to_go")
                        font.family: globalState.fontPrimary; font.pixelSize: Math.max(8, Math.round(17 * cdwFace.u)); font.weight: Font.Bold
                        color: m3.inkPrimaryContainer
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                    }
                }
            }
        }
    }
}
