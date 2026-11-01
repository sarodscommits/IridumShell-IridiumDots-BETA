import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

// Draggable, resizable stand-in for a widget in the desktop editor preview
Item {
    id: editProxy
    required property var modelData
    visible: globalState[desktopWidgetMenu.enabledPropFor(modelData.type)]
    property real dragOffsetX: 0
    property real dragOffsetY: 0
    x: modelData.item.x * desktopWidgetLayer.editPreviewScale + dragOffsetX
    y: modelData.item.y * desktopWidgetLayer.editPreviewScale + dragOffsetY
    width:  modelData.item.width  * desktopWidgetLayer.editPreviewScale
    height: modelData.item.height * desktopWidgetLayer.editPreviewScale

    readonly property string scaleProp:  desktopWidgetMenu.scalePropFor(modelData.type)
    readonly property string widthProp:  desktopWidgetMenu.widthPropFor(modelData.type)
    readonly property string heightProp: desktopWidgetMenu.heightPropFor(modelData.type)
    readonly property bool freeResize: widthProp !== ""
    readonly property bool selected: desktopEditorPopup.selectedType === modelData.type
    onVisibleChanged: if (!visible && selected) desktopEditorPopup.selectedType = ""

    Rectangle {
        anchors.fill: parent
        anchors.margins: -3
        radius: 8
        color: "transparent"
        border.color: pal.primary
        border.width: editProxy.selected ? 3 : 2
        visible: editProxyHover.hovered || editProxyArea.pressed || editProxy.selected
    }

    HoverHandler { id: editProxyHover }
    MouseArea {
        id: editProxyArea
        anchors.fill: parent
        cursorShape: Qt.SizeAllCursor
        property real startGX: 0
        property real startGY: 0
        property real travel: 0
        onPressed: (mouse) => {
            var gp = editProxyArea.mapToItem(previewBox, mouse.x, mouse.y);
            startGX = gp.x; startGY = gp.y;
            travel = 0;
        }
        onPositionChanged: (mouse) => {
            if (!editProxyArea.pressed) return;
            var gp = editProxyArea.mapToItem(previewBox, mouse.x, mouse.y);
            var newOffX = editProxy.dragOffsetX + (gp.x - startGX);
            var newOffY = editProxy.dragOffsetY + (gp.y - startGY);
            var baseX = editProxy.modelData.item.x * desktopWidgetLayer.editPreviewScale;
            var baseY = editProxy.modelData.item.y * desktopWidgetLayer.editPreviewScale;
            newOffX = Math.max(-baseX, Math.min(previewBox.width  - editProxy.width  - baseX, newOffX));
            newOffY = Math.max(-baseY, Math.min(previewBox.height - editProxy.height - baseY, newOffY));
            travel += Math.abs(gp.x - startGX) + Math.abs(gp.y - startGY);
            editProxy.dragOffsetX = newOffX;
            editProxy.dragOffsetY = newOffY;
            startGX = gp.x; startGY = gp.y;
        }
        onReleased: {
            if (travel < 5) {
                editProxy.dragOffsetX = 0;
                editProxy.dragOffsetY = 0;
                var ty = editProxy.modelData.type;
                desktopEditorPopup.selectedType = desktopEditorPopup.selectedType === ty ? "" : ty;
                return;
            }
            var xProp = desktopWidgetMenu.xPropFor(editProxy.modelData.type);
            var yProp = desktopWidgetMenu.yPropFor(editProxy.modelData.type);
            if (xProp !== "" && yProp !== "") {
                var gc = desktopWidgetLayer.gridCell;
                var realX = editProxy.x / desktopWidgetLayer.editPreviewScale;
                var realY = editProxy.y / desktopWidgetLayer.editPreviewScale;
                realX = Math.round(realX / gc) * gc;
                realY = Math.round(realY / gc) * gc;
                globalState[xProp] = realX;
                globalState[yProp] = realY;
                savePrefs();
            }
            editProxy.dragOffsetX = 0;
            editProxy.dragOffsetY = 0;
        }
    }

    Repeater {
        id: editCornerHandleRepeater
        model: ["br", "bl", "tr", "tl"]
        property color handleColor: pal.primary
        delegate: Rectangle {
            id: editCornerHandle
            required property string modelData
            readonly property bool isRight:  modelData === "br" || modelData === "tr"
            readonly property bool isBottom: modelData === "br" || modelData === "bl"
            width: 12; height: 12; radius: 4
            color: editCornerHandleRepeater.handleColor
            border.width: 1
            border.color: "white"
            x: isRight  ? editProxy.width  - width  / 2 : -width  / 2
            y: isBottom ? editProxy.height - height / 2 : -height / 2
            visible: editProxyHover.hovered || editProxyArea.pressed || editCornerArea.pressed || editProxy.selected

            MouseArea {
                id: editCornerArea
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: (editCornerHandle.modelData === "br" || editCornerHandle.modelData === "tl")
                ? Qt.SizeFDiagCursor : Qt.SizeBDiagCursor
                property real startGX: 0
                property real startGY: 0
                property real startRealW: 0
                property real startRealH: 0
                property real startRealX: 0
                property real startRealY: 0
                property real startScale: 1
                onPressed: (mouse) => {
                    var gp = editCornerArea.mapToItem(previewBox, mouse.x, mouse.y);
                    startGX = gp.x; startGY = gp.y;
                    startRealW = editProxy.modelData.item.width;
                    startRealH = editProxy.modelData.item.height;
                    startRealX = editProxy.modelData.item.x;
                    startRealY = editProxy.modelData.item.y;
                    if (!editProxy.freeResize && editProxy.scaleProp !== "")
                    startScale = globalState[editProxy.scaleProp];
                    desktopResizeOverlay.resizingEdge = !(editCornerHandle.isRight && editCornerHandle.isBottom);
                }
                onPositionChanged: (mouse) => {
                    if (!editCornerArea.pressed) return;
                    var gp = editCornerArea.mapToItem(previewBox, mouse.x, mouse.y);
                    var dx = (gp.x - startGX) / desktopWidgetLayer.editPreviewScale;
                    var dy = (gp.y - startGY) / desktopWidgetLayer.editPreviewScale;
                    var gc = desktopWidgetLayer.gridCell;

                    if (editProxy.freeResize) {
                        var wProp = editProxy.widthProp;
                        var hProp = editProxy.heightProp;
                        if (wProp === "" || hProp === "") return;
                        var newW, newX;
                        if (editCornerHandle.isRight) {
                            newW = Math.max(2, Math.round((startRealW + dx) / gc)) * gc;
                            newX = startRealX;
                        } else {
                            newW = Math.max(2, Math.round((startRealW - dx) / gc)) * gc;
                            newX = (startRealX + startRealW) - newW;
                        }
                        var newH, newY;
                        if (editCornerHandle.isBottom) {
                            newH = Math.max(2, Math.round((startRealH + dy) / gc)) * gc;
                            newY = startRealY;
                        } else {
                            newH = Math.max(2, Math.round((startRealH - dy) / gc)) * gc;
                            newY = (startRealY + startRealH) - newH;
                        }
                        globalState[wProp] = newW;
                        globalState[hProp] = newH;
                        if (!editCornerHandle.isRight)  globalState[desktopWidgetMenu.xPropFor(editProxy.modelData.type)] = newX;
                        if (!editCornerHandle.isBottom) globalState[desktopWidgetMenu.yPropFor(editProxy.modelData.type)] = newY;
                    } else {
                        var prop = editProxy.scaleProp;
                        if (prop === "") return;
                        var sx = editCornerHandle.isRight  ? 1 : -1;
                        var sy = editCornerHandle.isBottom ? 1 : -1;
                        var delta = (sx * dx + sy * dy) / 2;
                        var rawSize = startRealW + delta;
                        var cells = Math.max(1, Math.round(rawSize / gc));
                        var snapped = cells * gc;
                        var dragBaseSize = startRealW / Math.max(0.05, startScale);
                        var newScale = Math.max(0.5, Math.min(3, snapped / dragBaseSize));
                        globalState[prop] = newScale;
                        var k = newScale / Math.max(0.05, startScale);
                        var newRW = startRealW * k, newRH = startRealH * k;
                        if (!editCornerHandle.isRight)
                        globalState[desktopWidgetMenu.xPropFor(editProxy.modelData.type)] = Math.max(0, Math.round((startRealX + startRealW - newRW) / gc) * gc);
                        if (!editCornerHandle.isBottom)
                        globalState[desktopWidgetMenu.yPropFor(editProxy.modelData.type)] = Math.max(0, Math.round((startRealY + startRealH - newRH) / gc) * gc);
                    }
                }
                onReleased: { desktopResizeOverlay.resizingEdge = false; savePrefs(); }
                onCanceled: desktopResizeOverlay.resizingEdge = false
            }
        }
    }
}
