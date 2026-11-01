import QtQuick

// SegmentedPill cell
Item {
    id: segCell
    required property int index
    required property Item pill
    readonly property var opt: pill.options[index] || ({})
    readonly property int row: Math.floor(index / pill._cols)
    readonly property int col: index % pill._cols
    readonly property int inRow: row === pill._rows - 1 ? pill._n - row * pill._cols : pill._cols
    readonly property bool first: col === 0
    readonly property bool last: col === inRow - 1
    readonly property bool sel: pill.current === opt.value
    readonly property bool usable: opt.enabled !== false
    readonly property real cw: (pill.width - pill.gap * (inRow - 1)) / Math.max(1, inRow)
    x: col * (cw + pill.gap) + pill.bump.dx(col, row)
    y: pill.selGrowY + row * (pill.segHeight + pill.rowGap)
    width: Math.max(0, cw + pill.bump.dw(col, inRow, row))
    height: pill.segHeight
    z: sel ? 2 : 1
    opacity: usable ? 1 : 0.38

    // Inner radius: small at rest, full pill when selected, smaller while pressed
    readonly property real fullR: Math.min(pill._oR, height / 2)
    Spring {
        id: segInR
        token: "spatialFast"; eps: 0.05
        target: segCell.sel ? segCell.fullR : (segMa.pressed ? Math.max(2, pill.innerRadius / 2) : pill.innerRadius)
    }
    Spring { id: segOutR; token: "spatialFast"; eps: 0.05; target: segCell.fullR }
    readonly property real rL: Math.max(0, Math.min(height / 2, segCell.first ? segOutR.value : segInR.value))
    readonly property real rR: Math.max(0, Math.min(height / 2, segCell.last ? segOutR.value : segInR.value))
    readonly property color ink: segCell.sel ? pill.selectedTextColor : pill.textColor

    Rectangle {
        id: segBg
        anchors.fill: parent
        topLeftRadius: segCell.rL; bottomLeftRadius: segCell.rL
        topRightRadius: segCell.rR; bottomRightRadius: segCell.rR
        color: segCell.sel ? pill.selectedColor : pill.trackColor
        Behavior on color { M3ColorAnim { duration: m3.durFast } }
    }
    StateLayer {
        anchors.fill: parent
        topLeftRadius: segCell.rL; bottomLeftRadius: segCell.rL
        topRightRadius: segCell.rR; bottomRightRadius: segCell.rR
        color: segCell.ink
        hovered: segMa.containsMouse && segCell.usable; pressed: segMa.pressed
    }

    Row {
        visible: !pill.stacked
        anchors.centerIn: parent
        spacing: 6
        Item {
            visible: (segCell.opt.icon || "") !== ""
            width: segIcon.implicitWidth; height: segIcon.implicitHeight
            anchors.verticalCenter: parent.verticalCenter
            SegGlyph { id: segIcon; pill: segCell.pill; selected: segCell.sel; text: segCell.opt.icon || "" }
        }
        SegLabel {
            pill: segCell.pill; opt: segCell.opt; selected: segCell.sel
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, segCell.width - 14 - (segIcon.parent.visible ? segIcon.width + 6 : 0))
            visible: text !== ""
        }
    }

    Column {
        visible: pill.stacked
        anchors.centerIn: parent
        spacing: 4
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 40
            height: pill.iconSize + 8
            SegGlyph {
                pill: segCell.pill; selected: segCell.sel
                anchors.centerIn: parent
                visible: text !== ""
                text: segCell.opt.icon || ""
            }
            SegGlyph {
                pill: segCell.pill; selected: segCell.sel
                anchors.centerIn: parent
                visible: text !== ""
                text: segCell.opt.glyphText || ""
                horizontalAlignment: Text.AlignHCenter
                lineHeight: 0.8
                font.family: globalState.fontPrimary
                font.pixelSize: segCell.opt.glyphSize || 16
                font.weight: Font.Bold
            }
        }
        SegLabel {
            pill: segCell.pill; opt: segCell.opt; selected: segCell.sel
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(implicitWidth, segCell.width - 12)
        }
    }

    MouseArea {
        id: segMa
        anchors.fill: parent
        enabled: segCell.usable
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: pill.bump.bump(segCell.col, segCell.row)
        onClicked: if (!segCell.sel)
            pill.picked(segCell.opt.value)
    }

    component SegGlyph: Text {
        property Item pill
        property bool selected: false
        font.family: "Material Symbols Rounded"
        font.pixelSize: pill.iconSize
        color: selected ? pill.selectedTextColor : pill.iconColor
        Behavior on color { M3ColorAnim { duration: m3.durFast } }
    }
    component SegLabel: Text {
        property Item pill
        property var opt: ({})
        property bool selected: false
        text: opt.label || ""
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        font.family: opt.font || pill.fontFamily
        font.pixelSize: pill.fontSize
        font.weight: selected ? Font.DemiBold : Font.Medium
        color: selected ? pill.selectedTextColor : pill.textColor
        Behavior on color { M3ColorAnim { duration: m3.durFast } }
    }
}
