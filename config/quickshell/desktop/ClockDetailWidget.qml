import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../widgets"

// Clock detail card of the desktop
CardWidgetFrame {
    id: clockDetailWidgetRoot
    key: "clockDetail"

    property int ch: 0
    property int ch24: 0
    property int cm: 0
    Timer {
        interval: 1000; repeat: true; triggeredOnStart: true
        running: clockDetailWidgetRoot.visible && !globalState.lockScreenActive && !globalState.wpFullscreenActive
        onTriggered: {
            var d = new Date();
            clockDetailWidgetRoot.ch   = d.getHours() % 12;
            clockDetailWidgetRoot.ch24 = d.getHours();
            clockDetailWidgetRoot.cm   = d.getMinutes();
        }
    }

    body: Component {
        Item {
            anchors.fill: parent
            GridLayout {
                anchors.fill: parent
                anchors.margins: 20
                columns: clockDetailWidgetRoot.isWide ? 2 : 1
                rowSpacing: 10
                columnSpacing: 16

                Text {
                    Layout.alignment: clockDetailWidgetRoot.isWide ? (Qt.AlignHCenter | Qt.AlignVCenter) : Qt.AlignHCenter
                    Layout.row: 0
                    Layout.column: 0
                    text: {
                        var h = clockDetailWidgetRoot.ch;
                        if (!globalState.clockFormat24h) { if (h === 0) h = 12; }
                        else { h = clockDetailWidgetRoot.ch24; }
                        var hh = h < 10 ? "0" + h : "" + h;
                        var mm = clockDetailWidgetRoot.cm < 10 ? "0" + clockDetailWidgetRoot.cm : "" + clockDetailWidgetRoot.cm;
                        return hh + ":" + mm;
                    }
                    font.family: globalState.fontPrimary; font.pixelSize: Math.round(30 * globalState.fontScale); font.weight: Font.Bold
                    color: pal.primary
                }

                StopwatchFace {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.row: clockDetailWidgetRoot.isWide ? 0 : 1
                    Layout.column: clockDetailWidgetRoot.isWide ? 1 : 0
                    colorPrimary:       pal.primary
                    colorPrimaryCont:   pal.primaryCont
                    colorOnPrimaryCont: pal.colorOnPrimary
                    colorOnSurfVar:     pal.colorOnSurfVar
                    colorSurface:       pal.surface
                    running:   globalState.stopwatchRunning
                    elapsedMs: globalState.stopwatchElapsedMs
                    laps:      globalState.stopwatchLaps
                    onStartPauseClicked: globalState.stopwatchStartPause()
                    onLapClicked:        globalState.stopwatchLap()
                    onResetClicked:      globalState.stopwatchReset()
                }
            }
        }
    }
}
