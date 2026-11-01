import QtQuick
import QtQuick.Layouts
import "../ui"

// Collapsible section of the desktop editor
Item {
    id: esRoot
    property string icon: ""
    property string title: ""
    property string summary: ""
    property bool expanded: false
    property color accent: "#D0BCFF"
    property color accentText: "#381E72"
    property color textColor: "#E6E1E5"
    property color subColor: "#CAC4D0"
    property color cardColor: "#2F282C"
    property color hoverColor: "#3A3337"
    property string titleFont: ""
    property string bodyFont: ""
    property real fontScale: 1
    signal toggled()
    default property alias content: esBody.data

    implicitHeight: esCard.height

    Rectangle {
        id: esCard
        width: esRoot.width
        height: esHeader.height + esBodyClip.height
        radius: esRoot.expanded ? 22 : 18
        Behavior on radius { M3SpringAnim { token: "spatialDefault" } }
        color: (!esRoot.expanded && esHeadHov.hovered) ? esRoot.hoverColor : esRoot.cardColor
        Behavior on color { M3ColorAnim {} }
        border.width: 1
        border.color: esRoot.expanded ? Qt.rgba(esRoot.accent.r, esRoot.accent.g, esRoot.accent.b, 0.35) : "transparent"
        Behavior on border.color { M3ColorAnim {} }
        clip: true

        Item {
            id: esHeader
            width: parent.width
            height: 58

            Item {
                id: esIconBg
                x: 12
                anchors.verticalCenter: parent.verticalCenter
                width: 36; height: 36
                Spring { id: esMorph; token: "spatialDefault"; eps: 0.002; target: esRoot.expanded ? 1 : 0 }
                MShape {
                    anchors.fill: parent
                    inset: 1.0
                    from: "Circle"; to: m3.accentShape
                    t: esMorph.value
                    rot: esMorph.value * 40
                    fill: esRoot.expanded ? esRoot.accent : Qt.rgba(esRoot.accent.r, esRoot.accent.g, esRoot.accent.b, 0.16)
                }
                FadeIcon {
                    anchors.centerIn: parent
                    text: esRoot.icon
                    font.family: "Material Symbols Rounded"; font.pixelSize: 19
                    color: esRoot.expanded ? esRoot.accentText : esRoot.accent
                    Behavior on color { M3ColorAnim {} }
                }
            }
            Column {
                anchors.left: esIconBg.right; anchors.leftMargin: 12
                anchors.right: esChevron.left; anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1
                Text {
                    width: parent.width
                    text: esRoot.title
                    font.family: esRoot.titleFont; font.pixelSize: Math.round(14 * esRoot.fontScale); font.weight: Font.DemiBold
                    color: esRoot.textColor
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    visible: text !== ""
                    text: esRoot.summary
                    font.family: esRoot.bodyFont; font.pixelSize: Math.round(11 * esRoot.fontScale)
                    color: esRoot.subColor
                    elide: Text.ElideRight
                }
            }
            Text {
                id: esChevron
                anchors.right: parent.right; anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: ""
                font.family: "Material Symbols Rounded"; font.pixelSize: 20
                color: esRoot.expanded ? esRoot.accent : esRoot.subColor
                rotation: esRoot.expanded ? 180 : 0
                Behavior on rotation { M3SpringAnim { token: "spatialDefault" } }
            }
            HoverHandler { id: esHeadHov }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: esRoot.toggled()
            }
        }

        Item {
            id: esBodyClip
            y: esHeader.height
            width: parent.width
            height: esRoot.expanded ? esBody.implicitHeight + 26 : 0
            Behavior on height { M3SpringAnim { token: "spatialDefault" } }
            clip: true

            Rectangle {
                x: 14; width: parent.width - 28; height: 1
                color: Qt.rgba(esRoot.subColor.r, esRoot.subColor.g, esRoot.subColor.b, 0.15)
            }
            ColumnLayout {
                id: esBody
                x: 14; y: 12
                width: parent.width - 28
                spacing: 10
                enabled: esRoot.expanded
                opacity: esRoot.expanded ? 1 : 0
                Behavior on opacity { M3NumberAnim { duration: esRoot.expanded ? 280 : 120 } }
            }
        }
    }
}
