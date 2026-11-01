import QtQuick

// Vertical menu with segmented groups
Item {
    id: emn
    property bool open: false
    property var groups: []                // [[ [icon, text, trailing?, key?], ... ], ...]
    property string selectedKey: ""
    property real menuWidth: 220
    property real itemH: 40
    property bool fromBottom: false
    signal triggered(var key)
    signal closeRequested()                // owner of `open` handles closing
    width: menuWidth
    height: emnCol.implicitHeight
    implicitWidth: width
    implicitHeight: height
    z: 50
    Spring { id: emnO; token: "spatialFast"; target: emn.open ? 1 : 0; eps: 0.002 }
    Spring { id: emnF; token: "effectsFast"; target: emn.open ? 1 : 0 }
    visible: emnF.value > 0.01
    opacity: Math.min(1, emnF.value)
    transform: Scale { origin.x: 0; origin.y: emn.fromBottom ? emn.height : 0; xScale: 0.9 + 0.1 * emnO.value; yScale: 0.55 + 0.45 * emnO.value }
    Rectangle { y: 4; width: parent.width; height: parent.height; radius: m3.corner(16); color: m3.alpha(m3.shadow, m3.dark ? 0.4 : 0.14) }
    Column {
        id: emnCol
        width: parent.width
        spacing: 2
        Repeater {
            model: emn.groups.length
            delegate: Rectangle {
                id: emnGrp
                required property int index
                property var items: emn.groups[index]
                readonly property bool first: index === 0
                readonly property bool last: index === emn.groups.length - 1
                width: emnCol.width
                height: emnGcol.implicitHeight + 8
                color: m3.surfaceContainer
                topLeftRadius: first ? m3.corner(16) : 6; topRightRadius: first ? m3.corner(16) : 6
                bottomLeftRadius: last ? m3.corner(16) : 6; bottomRightRadius: last ? m3.corner(16) : 6
                Column {
                    id: emnGcol
                    x: 4; y: 4
                    width: parent.width - 8
                    spacing: 2
                    Repeater {
                        model: emnGrp.items
                        delegate: Item {
                            id: emnIt
                            required property var modelData
                            width: emnGcol.width
                            height: emn.itemH
                            readonly property string key: modelData.length > 3 ? modelData[3] : modelData[1]
                            readonly property bool sel: emn.selectedKey !== "" && key === emn.selectedKey
                            Spring { id: emnHv; token: "effectsFast"; target: emnMa.containsMouse ? 1 : 0 }
                            Spring { id: emnSr; token: "spatialFast"; target: emnIt.sel ? 1 : 0; eps: 0.002 }
                            Rectangle { anchors.fill: parent; radius: 12; color: m3.alpha(m3.inkSurface, 0.08 * emnHv.value) }
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width * Math.max(0, emnSr.value); height: parent.height
                                radius: 12 + 10 * (1 - Math.min(1, emnSr.value))
                                color: m3.tertiaryContainer; visible: emnSr.value > 0.01
                            }
                            Row {
                                x: 12; spacing: 12; anchors.verticalCenter: parent.verticalCenter
                                EIcon { name: emnIt.sel ? "check" : emnIt.modelData[0]; size: 20; filled: emnIt.sel; color: emnIt.sel ? m3.inkTertiaryContainer : m3.inkSurfaceVariant; anchors.verticalCenter: parent.verticalCenter }
                                EText { text: emnIt.modelData[1]; role: "labelLarge"; color: emnIt.sel ? m3.inkTertiaryContainer : m3.inkSurface; anchors.verticalCenter: parent.verticalCenter }
                            }
                            EText {
                                anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                                text: emnIt.modelData.length > 2 ? emnIt.modelData[2] : ""; role: "labelMedium"
                                color: emnIt.sel ? m3.inkTertiaryContainer : m3.inkSurfaceVariant
                            }
                            MouseArea {
                                id: emnMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { emn.triggered(emnIt.key); emn.closeRequested() }
                            }
                        }
                    }
                }
            }
        }
    }
}
