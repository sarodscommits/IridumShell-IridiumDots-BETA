import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

// Edge/corner resize handles for desktop widgets in edit mode
Item {
    id: desktopResizeOverlay
    anchors.fill: parent
    z: 999
    visible: active && target !== null

    property bool active: false
    property Item target: null
    property string widgetType: ""

    function open(item, type) {
        target = item;
        widgetType = type;
        active = true;
        globalState.wdDeclutterAll();
    }
    function close() {
        active = false;
        target = null;
        widgetType = "";
        if (!globalState.desktopEditMode) globalState.wdRestoreAll();
    }
    readonly property string scaleProp:  desktopWidgetMenu.scalePropFor(widgetType)
    readonly property string widthProp:  desktopWidgetMenu.widthPropFor(widgetType)
    readonly property string heightProp: desktopWidgetMenu.heightPropFor(widgetType)
    readonly property bool freeResize: widthProp !== ""
    property bool resizingEdge: false

    Rectangle {
        visible: desktopResizeOverlay.target !== null
        x: desktopResizeOverlay.target ? desktopResizeOverlay.target.x - 5 : 0
        y: desktopResizeOverlay.target ? desktopResizeOverlay.target.y - 5 : 0
        width:  desktopResizeOverlay.target ? desktopResizeOverlay.target.width  + 10 : 0
        height: desktopResizeOverlay.target ? desktopResizeOverlay.target.height + 10 : 0
        radius: 18
        color: "transparent"
        border.width: 2
        border.color: pal.primary
    }

    Rectangle {
        id: desktopResizeDoneBtn
        x: desktopResizeOverlay.target ? desktopResizeOverlay.target.x : 0
        y: desktopResizeOverlay.target ? Math.max(8, desktopResizeOverlay.target.y - 40) : 0
        width: 74; height: 30; radius: 15
        color: pal.primary
        Text { anchors.centerIn: parent; text: tr("desktop_editor_done"); color: pal.colorOnPrimary; font.pixelSize: 13 }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: desktopResizeOverlay.close()
        }
    }

    Rectangle {
        id: desktopResizeHandle
        visible: !desktopResizeOverlay.freeResize
        width: 36; height: 36; radius: 11
        color: pal.primary
        border.width: 2
        border.color: "white"
        x: desktopResizeOverlay.target ? desktopResizeOverlay.target.x + desktopResizeOverlay.target.width  - width  / 2 : 0
        y: desktopResizeOverlay.target ? desktopResizeOverlay.target.y + desktopResizeOverlay.target.height - height / 2 : 0

        MouseArea {
            id: desktopResizeHandleArea
            anchors.fill: parent
            cursorShape: Qt.SizeFDiagCursor
            property real startGX: 0
            property real startGY: 0
            property real startW: 0
            property real startH: 0
            property real startScale: 1
            onPressed: (mouse) => {
                var t = desktopResizeOverlay.target;
                if (!t) return;
                var gp = desktopResizeHandleArea.mapToItem(desktopPopupsWindow.contentItem, mouse.x, mouse.y);
                startGX = gp.x;
                startGY = gp.y;
                startW = t.width;
                startH = t.height;
                var prop = desktopResizeOverlay.scaleProp;
                startScale = prop !== "" ? globalState[prop] : 1;
            }
            onPositionChanged: (mouse) => {
                if (!desktopResizeHandleArea.pressed) return;
                var t = desktopResizeOverlay.target;
                if (!t) return;
                var gp = desktopResizeHandleArea.mapToItem(desktopPopupsWindow.contentItem, mouse.x, mouse.y);
                var dx = gp.x - startGX;
                var dy = gp.y - startGY;

                var prop = desktopResizeOverlay.scaleProp;
                if (prop === "") return;
                var delta = (dx + dy) / 2;
                var rawSize = startW + delta;
                var cells = Math.max(1, Math.round(rawSize / desktopWidgetLayer.gridCell));
                var snapped = cells * desktopWidgetLayer.gridCell;
                var dragBaseSize = startW / Math.max(0.05, startScale);
                var newScale = snapped / dragBaseSize;
                globalState[prop] = Math.max(0.5, Math.min(3, newScale));
            }
            onReleased: savePrefs()
        }
    }

    Repeater {
        model: [
        { corner: "br" },
        { corner: "bl" },
        { corner: "tr" },
        { corner: "tl" }
        ]
        Rectangle {
            id: cornerHandle
            required property var modelData
            readonly property bool isRight:  modelData.corner === "br" || modelData.corner === "tr"
            readonly property bool isBottom: modelData.corner === "br" || modelData.corner === "bl"
            visible: desktopResizeOverlay.freeResize
            width: 30; height: 30; radius: 10
            color: pal.primary
            border.width: 2
            border.color: "white"
            readonly property Item t: desktopResizeOverlay.target
            x: t ? (isRight  ? t.x + t.width  - width  / 2 : t.x - width  / 2) : 0
            y: t ? (isBottom ? t.y + t.height - height / 2 : t.y - height / 2) : 0

            MouseArea {
                id: cornerHandleArea
                anchors.fill: parent
                cursorShape: (cornerHandle.modelData.corner === "br" || cornerHandle.modelData.corner === "tl")
                ? Qt.SizeFDiagCursor : Qt.SizeBDiagCursor
                property real startGX: 0
                property real startGY: 0
                property real startW: 0
                property real startH: 0
                property real startX: 0
                property real startY: 0
                onPressed: (mouse) => {
                    var t = desktopResizeOverlay.target;
                    if (!t) return;
                    var gp = cornerHandleArea.mapToItem(desktopPopupsWindow.contentItem, mouse.x, mouse.y);
                    startGX = gp.x; startGY = gp.y;
                    startW = t.width; startH = t.height;
                    startX = t.x; startY = t.y;
                    desktopResizeOverlay.resizingEdge = !(cornerHandle.isRight && cornerHandle.isBottom);
                }
                onPositionChanged: (mouse) => {
                    if (!cornerHandleArea.pressed) return;
                    var t = desktopResizeOverlay.target;
                    if (!t) return;
                    var wProp = desktopResizeOverlay.widthProp;
                    var hProp = desktopResizeOverlay.heightProp;
                    if (wProp === "" || hProp === "") return;
                    var gp = cornerHandleArea.mapToItem(desktopPopupsWindow.contentItem, mouse.x, mouse.y);
                    var dx = gp.x - startGX;
                    var dy = gp.y - startGY;
                    var gc = desktopWidgetLayer.gridCell;

                    var newW, newX;
                    if (cornerHandle.isRight) {
                        newW = Math.max(2, Math.round((startW + dx) / gc)) * gc;
                        newX = startX;
                    } else {
                        newW = Math.max(2, Math.round((startW - dx) / gc)) * gc;
                        newX = (startX + startW) - newW;
                    }
                    var newH, newY;
                    if (cornerHandle.isBottom) {
                        newH = Math.max(2, Math.round((startH + dy) / gc)) * gc;
                        newY = startY;
                    } else {
                        newH = Math.max(2, Math.round((startH - dy) / gc)) * gc;
                        newY = (startY + startH) - newH;
                    }

                    globalState[wProp] = newW;
                    globalState[hProp] = newH;
                    if (!cornerHandle.isRight)  globalState[desktopWidgetMenu.xPropFor(desktopResizeOverlay.widgetType)] = newX;
                    if (!cornerHandle.isBottom) globalState[desktopWidgetMenu.yPropFor(desktopResizeOverlay.widgetType)] = newY;
                }
                onReleased: {
                    desktopResizeOverlay.resizingEdge = false;
                    savePrefs();
                }
            }
        }
    }
}
