import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../widgets"

// Clock card of the left panel
Item {
    id: clockWidgetItem
    visible: !calPanel.anyWidgetExpanded || clockWidgetItem.clockExpanded
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.preferredHeight: 250

    property bool clockHovered: false

    property bool clockPeek:     false
    property bool clockExpanded: false

    HoverHandler {
        id: clockWidgetHover
        onHoveredChanged: clockWidgetItem.clockHovered = hovered
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            weatherCard.weatherPeek = false;
            weatherCard.weatherExpanded = false;
            calWidgetItem.calPeek = false;
            calWidgetItem.calExpanded = false;
            calWidgetItem.selectedDay = -1;
            fetchWidgetItem.fetchPeek = false;
            fetchWidgetItem.fetchExpanded = false;
            if (!clockWidgetItem.clockPeek && !clockWidgetItem.clockExpanded) {
                clockWidgetItem.clockPeek = true;
            } else if (clockWidgetItem.clockPeek && !clockWidgetItem.clockExpanded) {
                clockWidgetItem.clockExpanded = true;
            }
        }
    }

    Connections {
        target: globalState
        function onCalendarMenuOpenChanged() {
            if (!globalState.calendarMenuOpen) {
                clockWidgetItem.clockExpanded = false;
                clockWidgetItem.clockPeek = false;
            }
        }
        function onLeftPanelPageChanged() {
            if (globalState.leftPanelPage !== 0) {
                clockWidgetItem.clockExpanded = false;
                clockWidgetItem.clockPeek = false;
            }
        }
    }

    AnalogClockCanvas { id: analogClockCanvas }

    Column {
        id: clockDetailCol
        anchors.horizontalCenter: analogClockCanvas.horizontalCenter
        y: clockWidgetItem.clockExpanded
        ? (analogClockCanvas.y + 52)
        : (analogClockCanvas.y + (analogClockCanvas.height - height) / 2)
        Behavior on y { M3SpringAnim { token: "spatialSlow" } }
        spacing: 2
        opacity: (clockWidgetItem.clockPeek || clockWidgetItem.clockExpanded) ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity {
            M3NumberAnim { duration: (clockWidgetItem.clockPeek || clockWidgetItem.clockExpanded) ? 320 : 180 }
        }

        property string timeText: "12:00:00 AM"
        Timer {
            interval: 1000; repeat: true; triggeredOnStart: true
            running: globalState.calendarMenuOpen && globalState.leftPanelPage === 0
            onTriggered: {
                var d = new Date();
                var h = d.getHours();
                var ampm = h >= 12 ? "PM" : "AM";
                h = h % 12;
                if (h === 0) h = 12;
                var m = d.getMinutes();
                var s = d.getSeconds();
                clockDetailCol.timeText =
                (h < 10 ? "0" + h : h) + ":" +
                (m < 10 ? "0" + m : m) + ":" +
                (s < 10 ? "0" + s : s) + " " + ampm;
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: clockDetailCol.timeText
            font.family: globalState.fontPrimary; font.pixelSize: Math.round(36 * globalState.fontScale); font.weight: Font.DemiBold
            color: pal.primary
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: {
                var d = new Date();
                return d.toLocaleDateString(Qt.locale(localeCode()), "ddd d MMM yyyy");
            }
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(17 * globalState.fontScale); font.weight: Font.Medium
            color: pal.colorOnSurfVar
        }
    }

    StopwatchFace {
        id: clockStopwatchFace
        visible: clockWidgetItem.clockExpanded
        opacity: clockWidgetItem.clockExpanded ? 1 : 0
        Behavior on opacity { M3NumberAnim {} }

        anchors.horizontalCenter: analogClockCanvas.horizontalCenter
        y: clockDetailCol.y + clockDetailCol.height + 16
        width: analogClockCanvas.width - 40
        height: Math.max(60, analogClockCanvas.y + analogClockCanvas.height - y - 20)

        colorPrimary:       pal.primary
        colorPrimaryCont:   pal.primaryCont
        colorOnPrimaryCont: pal.colorOnPrimary
        colorOnSurfVar:     pal.colorOnSurfVar
        colorSurface:       pal.surface
        running:    globalState.stopwatchRunning
        elapsedMs:  globalState.stopwatchElapsedMs
        laps:       globalState.stopwatchLaps
        onStartPauseClicked: globalState.stopwatchStartPause()
        onLapClicked:        globalState.stopwatchLap()
        onResetClicked:      globalState.stopwatchReset()
    }

    Rectangle {
        id: clockCloseBtn
        visible: clockWidgetItem.clockExpanded
        opacity: clockWidgetItem.clockExpanded ? 1 : 0
        Behavior on opacity { M3NumberAnim {} }
        z: 50
        width: 26; height: 26; radius: 13
        x: analogClockCanvas.x + analogClockCanvas.width - width - 12
        y: analogClockCanvas.y + 20
        color: clockCloseBtnHov.hovered ? pal.primaryCont : "transparent"
        Behavior on color { M3ColorAnim { duration: m3.durFast } }
        Text { anchors.centerIn: parent; text: "\ue5cd"; font.family: "Material Symbols Rounded"; font.pixelSize: 15; color: pal.colorOnSurfVar }
        HoverHandler { id: clockCloseBtnHov }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                clockWidgetItem.clockExpanded = false;
                clockWidgetItem.clockPeek = false;
            }
        }
    }
}
