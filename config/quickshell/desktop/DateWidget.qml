import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../widgets"

// Date desktop widget
ExprDesktopWidget {
    id: dateWidgetRoot
    wType: "date"
    enabledProp: "dateWidgetEnabled"; xProp: "dateWidgetX"; yProp: "dateWidgetY"; scaleProp: "dateWidgetScale"
    baseW: 220; baseH: 220
    face: Component {
        Item {
            id: dateFace
            readonly property real u: width / 220
            property var now: new Date()
            Timer { interval: 30000; running: true; repeat: true; onTriggered: dateFace.now = new Date() }
            function cap(s) { return s.length ? s.charAt(0).toUpperCase() + s.slice(1) : s; }
            HoverHandler { id: dateHov }
            Spring { id: dateSpin; target: dateHov.hovered ? 45 : 0; token: "spatialDefault"; eps: 0.05 }
            MBox {
                anchors.fill: parent
                from: "Clover8Leaf"
                rot: dateSpin.value
                fill: m3.primaryContainer
                split: 0.64
                fill2: desktopWidgetLayer.exprDark
                stroke: m3.alpha(m3.inkSurface, 0.35)
                strokeWidth: Math.max(1, 2 * dateFace.u)
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.15
                text: Qt.locale(localeCode()).standaloneDayName(dateFace.now.getDay(), Locale.ShortFormat).toUpperCase()
                font.family: globalState.fontSecondary; font.pixelSize: Math.max(7, Math.round(13 * dateFace.u)); font.weight: Font.Bold
                font.letterSpacing: 1.5 * dateFace.u
                color: m3.inkPrimaryContainer
                opacity: 0.75
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.39 - height / 2
                text: dateFace.now.getDate()
                font.family: globalState.fontPrimary; font.pixelSize: Math.max(14, Math.round(80 * dateFace.u)); font.weight: Font.Black
                color: m3.inkPrimaryContainer
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.79 - height / 2
                text: dateFace.cap(Qt.locale(localeCode()).standaloneMonthName(dateFace.now.getMonth(), Locale.LongFormat))
                font.family: globalState.fontPrimary; font.pixelSize: Math.max(8, Math.round(19 * dateFace.u)); font.weight: Font.Bold
                color: pal.colorOnSurface
            }
        }
    }
}
