import QtQuick

// Square icon button with corners that tighten on press
Rectangle {
    id: pib
    property real size: 32
    property real cornerRadius: 10
    property string icon: ""
    property int iconSize: 18
    property bool iconVisible: true
    property color iconColor: pal.primary
    property color hoverColor: pal.primaryCont
    property color idleColor: pal.secondaryCont
    property int colorDuration: m3.durDefault
    property bool clickEnabled: true
    property real hitMargin: 0
    readonly property bool hovered: hov.hovered
    signal clicked()
    width: size; height: size
    radius: ma.pressed ? Math.max(4, cornerRadius * 0.5) : cornerRadius
    Behavior on radius { M3SpringAnim { token: "spatialFast" } }
    color: hov.hovered ? hoverColor : idleColor
    Behavior on color { M3ColorAnim { duration: pib.colorDuration } }
    Text {
        anchors.centerIn: parent
        visible: pib.iconVisible
        text: pib.icon
        font.family: "Material Symbols Rounded"; font.pixelSize: pib.iconSize
        color: pib.iconColor
    }
    HoverHandler { id: hov }
    MouseArea {
        id: ma
        anchors.fill: parent; anchors.margins: pib.hitMargin; cursorShape: Qt.PointingHandCursor
        enabled: pib.clickEnabled
        onClicked: pib.clicked()
    }
}
