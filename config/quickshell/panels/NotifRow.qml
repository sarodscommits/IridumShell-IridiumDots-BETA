import QtQuick
import "../ui"

// One notification line inside a group card
Item {
    property Item card
    id: ngcRow
    required property var modelData
    required property int index
    readonly property bool dotted: card.open
    readonly property int  gapTop: index > 0 ? 8 : 0
    width: parent ? parent.width : 0
    height: ngcRowCol.height + gapTop

    Rectangle {
        visible: ngcRow.dotted
        x: 1
        y: ngcRowCol.y + ngcRowSummary.height / 2 - height / 2
        width: 6; height: 6; radius: 3
        color: card.accentColor
        opacity: ngcRow.dotted ? 1 : 0
        scale: ngcRow.dotted ? 1 : 0.4
        Behavior on opacity { M3NumberAnim {} }
        Behavior on scale { M3SpringAnim { token: "spatialFast"; epsilon: 0.002 } }
    }
    Column {
        id: ngcRowCol
        x: ngcRow.dotted ? 14 : 0
        y: ngcRow.gapTop
        width: parent.width - x
        spacing: 2
        Behavior on x { M3SpringAnim { token: "spatialDefault" } }
        Text {
            id: ngcRowSummary
            width: parent.width
            text: ngcRow.modelData ? (ngcRow.modelData.summary || "") : ""
            font.family: globalState.fontPrimary; font.pixelSize: Math.round(13 * globalState.fontScale); font.weight: Font.DemiBold
            color: card.textColor
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            visible: text !== ""
            text: ngcRow.modelData ? (ngcRow.modelData.body || "") : ""
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale)
            color: card.subColor
            wrapMode: Text.Wrap
            maximumLineCount: card.open ? 3 : 2
            elide: Text.ElideRight
        }
    }
}
