import QtQuick

Item {
    id: pager
    required property var win
    width: win.pageW; height: win.pageH
    x: (parent.width - width) / 2
    y: 56 + (parent.height - 56 - win.wsStripH - 70 - height) / 2

    DragHandler {
        target: null
        xAxis.enabled: true
        yAxis.enabled: false
        onActiveChanged: {
            if (active) return;
            if (translation.x < -90) win.stepPage(1);
            else if (translation.x > 90) win.stepPage(-1);
        }
    }

    Repeater {
        model: win.pages.length
        delegate: Item {
            id: pageItem
            required property int index
            readonly property int rel: index - win.currentPage
            readonly property bool near: Math.abs(rel) <= 1
            readonly property var tiles: win.pages[index] ? win.pages[index].tiles : []
            width: pager.width; height: pager.height
            x: rel * (win.pageW + win.pageSpacing)
            scale: rel === 0 ? 1 : 0.9
            opacity: rel === 0 ? 1 : (near ? 0.0 : 0)
            visible: near
            Behavior on x       { NumberAnimation { duration: 340; easing.type: Easing.OutCubic } }
            Behavior on scale   { NumberAnimation { duration: 340; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

            Repeater {
                model: pageItem.tiles
                delegate: WindowTile { win: pager.win; page: pageItem }
            }
        }
    }
}
