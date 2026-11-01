import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../widgets"

// Analog/digital clock desktop widget
DesktopWidgetFrame {
    id: clockWidgetRootDesktop
    dwOn: globalState.clockWidgetEnabledDesktop
    dragging: clockDragArea.drag.active
    x: globalState.clockWidgetXDesktop
    y: globalState.clockWidgetYDesktop
    width:  Math.ceil((220 * globalState.clockWidgetScaleDesktop) / desktopWidgetLayer.gridCell) * desktopWidgetLayer.gridCell
    height: Math.ceil((220 * globalState.clockWidgetScaleDesktop) / desktopWidgetLayer.gridCell) * desktopWidgetLayer.gridCell

    MouseArea {
        id: clockDragArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
    }
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: { if (!globalState.desktopEditMode) desktopWidgetMenu.openFor(clockWidgetRootDesktop, "clock"); }
    }

    property int ch: 0
    property int ch24: 0
    property int cm: 0
    property int cs: 0
    Timer {
        interval: 1000; repeat: true; triggeredOnStart: true
        running: clockWidgetRootDesktop.visible && !globalState.lockScreenActive && !globalState.wpFullscreenActive
        onTriggered: {
            var d = new Date();
            clockWidgetRootDesktop.ch   = d.getHours() % 12;
            clockWidgetRootDesktop.ch24 = d.getHours();
            clockWidgetRootDesktop.cm   = d.getMinutes();
            clockWidgetRootDesktop.cs   = d.getSeconds();
            if (clockWidgetRootDesktopVis.item) clockWidgetRootDesktopVis.item.faceCanvas.requestPaint();
        }
    }

    Loader {
        id: clockWidgetRootDesktopVis
        anchors.fill: parent
        anchors.margins: desktopWidgetLayer.widgetGap
        active: clockWidgetRootDesktop.visible
        source: Qt.resolvedUrl("DesktopClockFace.qml")
    }
}
