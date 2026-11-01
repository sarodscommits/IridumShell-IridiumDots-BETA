import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../widgets"

// Month calendar desktop widget
DesktopWidgetFrame {
    id: calWidgetRootDesktop
    dwOn: globalState.calWidgetEnabledDesktop
    dragging: calDragArea.drag.active
    x: globalState.calWidgetXDesktop
    y: globalState.calWidgetYDesktop
    width:  Math.ceil((220 * globalState.calWidgetScaleDesktop) / desktopWidgetLayer.gridCell) * desktopWidgetLayer.gridCell
    height: Math.ceil((220 * globalState.calWidgetScaleDesktop) / desktopWidgetLayer.gridCell) * desktopWidgetLayer.gridCell

    MouseArea {
        id: calDragArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
    }
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: { if (!globalState.desktopEditMode) desktopWidgetMenu.openFor(calWidgetRootDesktop, "calendar"); }
    }

    property int cdDay: 1
    property int cdMonth: 0
    property int cdYear: 1970
    property int cdWeekday: 0
    Timer {
        interval: 60000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            var d = new Date();
            calWidgetRootDesktop.cdDay     = d.getDate();
            calWidgetRootDesktop.cdMonth   = d.getMonth();
            calWidgetRootDesktop.cdYear    = d.getFullYear();
            calWidgetRootDesktop.cdWeekday = d.getDay();
            if (calWidgetRootDesktopVis.item) calWidgetRootDesktopVis.item.faceCanvas.requestPaint();
        }
    }

    Loader {
        id: calWidgetRootDesktopVis
        anchors.fill: parent
        anchors.margins: desktopWidgetLayer.widgetGap
        active: calWidgetRootDesktop.visible
        source: Qt.resolvedUrl("DesktopCalendarFace.qml")
    }
}
