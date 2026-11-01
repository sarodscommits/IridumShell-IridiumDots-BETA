import QtQuick
import "../ui"

// App name, count badge and expand arrow of a notification group
Item {
    property Item card
    width: parent ? parent.width : 0
    height: ngcApp.implicitHeight
    Text {
        id: ngcApp
        width: parent.width - (card.grouped ? ngcBadge.width + ngcArrow.width + 10 : 0)
        text: card.appName || " "
        font.family: globalState.fontSecondary; font.pixelSize: Math.round(9 * globalState.fontScale); font.weight: Font.Medium
        color: card.mutedColor
        elide: Text.ElideRight
    }
    Rectangle {
        id: ngcBadge
        visible: card.grouped
        anchors.right: ngcArrow.left
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        height: 16; radius: 8
        width: Math.max(16, ngcBadgeTxt.implicitWidth + 10)
        color: Qt.rgba(card.accentColor.r, card.accentColor.g, card.accentColor.b, 0.22)
        Text {
            id: ngcBadgeTxt
            anchors.centerIn: parent
            text: card.count
            font.family: globalState.fontPrimary; font.pixelSize: Math.round(9 * globalState.fontScale); font.weight: Font.Bold
            color: card.accentColor
        }
    }
    Rectangle {
        id: ngcArrow
        visible: card.grouped
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 22; height: 22; radius: m3Ib1Ma.pressed ? Math.max(4, (11) * 0.5) : (11)
        Behavior on radius { M3SpringAnim { token: "spatialFast" } }
        color: ngcArrowHov.hovered ? Qt.rgba(card.accentColor.r, card.accentColor.g, card.accentColor.b, 0.18) : "transparent"
        Behavior on color { M3ColorAnim { duration: m3.durFast } }
        Text {
            anchors.centerIn: parent
            text: ""
            font.family: "Material Symbols Rounded"; font.pixelSize: 18
            color: ngcArrowHov.hovered || card.open ? card.accentColor : card.mutedColor
            rotation: card.open ? 180 : 0
            Behavior on rotation { M3SpringAnim { token: "spatialDefault" } }
        }
        HoverHandler { id: ngcArrowHov }
        MouseArea { id: m3Ib1Ma;
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: card.toggleExpand()
        }
    }
}
