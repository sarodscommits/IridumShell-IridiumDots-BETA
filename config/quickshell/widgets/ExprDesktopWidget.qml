import QtQuick
import "../ui"

// Base of the expressive desktop widgets
DesktopWidgetFrame {
    id: edw
    property string wType: ""
    property string enabledProp: ""
    property string xProp: ""
    property string yProp: ""
    property string scaleProp: ""
    property real baseW: 220
    property real baseH: 220
    property Component face: null
    readonly property real cell: desktopWidgetLayer.gridCell
    readonly property real sc: scaleProp !== "" ? globalState[scaleProp] : 1
    dwOn: enabledProp !== "" && globalState[enabledProp] === true
    readonly property bool live: visible && dwOn && !globalState.lockScreenActive && !globalState.wpFullscreenActive
    x: xProp !== "" ? globalState[xProp] : 0
    y: yProp !== "" ? globalState[yProp] : 0
    width:  Math.ceil((baseW * sc) / cell) * cell
    height: Math.ceil((baseH * sc) / cell) * cell
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: { if (!globalState.desktopEditMode) desktopWidgetMenu.openFor(edw, edw.wType); }
    }
    Loader {
        anchors.fill: parent
        anchors.margins: desktopWidgetLayer.widgetGap
        active: edw.visible
        sourceComponent: edw.face
    }
}
