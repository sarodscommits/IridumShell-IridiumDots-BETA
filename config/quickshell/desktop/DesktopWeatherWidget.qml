import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../widgets"

// Weather desktop widget
DesktopWidgetFrame {
    id: weatherWidgetRoot
    dwOn: globalState.weatherWidgetEnabled
    dragging: weatherDragArea.drag.active
    x: globalState.weatherWidgetX
    y: globalState.weatherWidgetY
    width: Math.ceil((220 * globalState.weatherWidgetScale) / desktopWidgetLayer.gridCell) * desktopWidgetLayer.gridCell
    height: Math.ceil((220 * globalState.weatherWidgetScale) / desktopWidgetLayer.gridCell) * desktopWidgetLayer.gridCell
    + ((weatherWidgetRootVis.item && weatherWidgetRootVis.item.extraInfo.visible) ? weatherWidgetRootVis.item.extraInfo.implicitHeight + 8 : 0)

    MouseArea {
        id: weatherDragArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
    }
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: { if (!globalState.desktopEditMode) desktopWidgetMenu.openFor(weatherWidgetRoot, "weather"); }
    }

    Timer {
        id: weatherWidgetClock
        property int nowHour: new Date().getHours()
        interval: 60000; running: true; repeat: true
        onTriggered: nowHour = new Date().getHours()
    }

    readonly property color pillFillColor: globalState.glassMode ? ga(containerDark(pal.secondaryCont), currentFrameOpacity()) : containerDark(pal.secondaryCont)

    Loader {
        id: weatherWidgetRootVis
        anchors.fill: parent
        anchors.margins: desktopWidgetLayer.widgetGap
        active: weatherWidgetRoot.visible
        source: Qt.resolvedUrl("DesktopWeatherFace.qml")
    }
}
