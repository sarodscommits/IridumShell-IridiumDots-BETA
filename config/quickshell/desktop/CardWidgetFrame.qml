import QtQuick
import "../ui"
import "../widgets"

// Resizable desktop card with a lazily loaded body
DesktopWidgetFrame {
    id: dtf
    property string key: ""
    property Component body: null
    readonly property bool isWide: width > height * 1.15
    dwOn: globalState[key + "WidgetEnabled"]
    dragging: dragArea.drag.active
    resizable: true
    x: globalState[key + "WidgetX"]
    y: globalState[key + "WidgetY"]
    width:  globalState[key + "WidgetW"]
    height: globalState[key + "WidgetH"]
    clip: true

    MouseArea {
        id: dragArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
    }
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: { if (!globalState.desktopEditMode) desktopWidgetMenu.openFor(dtf, dtf.key); }
    }
    Rectangle {
        anchors.fill: parent
        anchors.margins: desktopWidgetLayer.widgetGap
        visible: dtf.visible
        radius: 32
        color: globalState.glassMode ? ga(containerDark(pal.secondaryCont), currentFrameOpacity()) : containerDark(pal.secondaryCont)
    }
    Loader {
        anchors.fill: parent
        anchors.margins: desktopWidgetLayer.widgetGap
        active: dtf.visible
        sourceComponent: dtf.body
    }
}
