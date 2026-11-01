import QtQuick
import "ButtonColors.js" as ButtonColors

// M3E button: sizes, round/square, toggle, connected groups
Item {
    id: eb
    property string text: ""
    property string icon: ""
    property string variant: "filled"      // filled · tonal · outlined · elevated · text · error · tertiary
    property string size: "s"              // xxs · xs · s · m · l · xl
    property bool square: false
    property bool toggleable: false
    property bool checked: false
    property real widthOffset: 0
    property real fixedWidth: -1
    property real iconRotation: 0
    property bool connectedLeft: false
    property bool connectedRight: false
    property real innerRadius: 8
    property string fontFamily: m3.font
    property bool busy: false
    readonly property alias pressed: ebMa.pressed
    readonly property alias hovered: ebMa.containsMouse
    signal clicked()
    signal rightClicked()
    // [height, padding, icon, font, square radius, pressed radius]
    readonly property var spec: ({
        xxs: [26, 10, 16, 11, 8, 6], xs: [32, 12, 18, 12, 12, 8], s: [40, 16, 20, 14, 12, 8], m: [56, 24, 24, 16, 16, 12],
        l: [96, 48, 32, 24, 28, 16], xl: [136, 64, 40, 32, 28, 16]
    })[size]
    readonly property real h: spec[0]
    readonly property bool connected: connectedLeft || connectedRight
    readonly property bool sq: connected ? false : (toggleable && checked ? !square : square)
    readonly property real restR: sq ? spec[4] : h / 2
    Spring { id: ebRs; token: "spatialFast"; eps: 0.05; target: (ebMa.pressed && !eb.connected) ? eb.spec[5] : eb.restR }
    Spring { id: ebIrs; token: "spatialFast"; eps: 0.05; target: eb.checked ? eb.h / 2 : (ebMa.pressed ? Math.max(2, eb.innerRadius / 2) : eb.innerRadius) }
    Spring { id: ebWs; token: "spatialFast"; eps: 0.05; target: eb.widthOffset }
    implicitHeight: h
    implicitWidth: Math.max(0, (fixedWidth > 0 ? fixedWidth : Math.max(h, ebRow.implicitWidth + spec[1] * 2)) + ebWs.value)
    opacity: enabled ? 1 : 0.38
    readonly property var cols: ButtonColors.colors(m3, variant, toggleable, checked, "transparent", "filled")
    readonly property real lr: Math.max(0, Math.min(height / 2, connectedLeft ? ebIrs.value : ebRs.value))
    readonly property real rr: Math.max(0, Math.min(height / 2, connectedRight ? ebIrs.value : ebRs.value))
    Rectangle {
        visible: eb.variant === "elevated"
        y: 1.5; width: parent.width; height: parent.height
        topLeftRadius: eb.lr; bottomLeftRadius: eb.lr; topRightRadius: eb.rr; bottomRightRadius: eb.rr
        color: m3.alpha(m3.shadow, m3.dark ? 0.55 : 0.2)
    }
    Rectangle {
        anchors.fill: parent
        topLeftRadius: eb.lr; bottomLeftRadius: eb.lr; topRightRadius: eb.rr; bottomRightRadius: eb.rr
        color: eb.cols[0]
        border.width: eb.cols[2] ? (eb.size === "l" ? 2 : eb.size === "xl" ? 3 : 1) : 0
        border.color: eb.cols[2] ? eb.cols[2] : "transparent"
        Behavior on color { M3ColorAnim { duration: m3.durFast } }
    }
    StateLayer {
        anchors.fill: parent
        topLeftRadius: eb.lr; bottomLeftRadius: eb.lr; topRightRadius: eb.rr; bottomRightRadius: eb.rr
        color: eb.cols[1]
        hovered: ebMa.containsMouse; pressed: ebMa.pressed
    }
    Row {
        id: ebRow
        anchors.centerIn: parent
        spacing: (eb.size === "xs" || eb.size === "xxs") ? 4 : (eb.size === "l" ? 12 : (eb.size === "xl" ? 16 : 8))
        ELoading { visible: eb.busy; size: eb.spec[2]; color: eb.cols[1]; running: eb.busy; anchors.verticalCenter: parent.verticalCenter }
        EIcon { name: eb.icon; visible: eb.icon !== "" && !eb.busy; size: eb.spec[2]; color: eb.cols[1]; filled: eb.checked; rotation: eb.iconRotation; anchors.verticalCenter: parent.verticalCenter }
        Text {
            text: eb.text; visible: eb.text !== ""
            font.family: eb.fontFamily
            font.pixelSize: Math.round(eb.spec[3] * m3.fs)
            font.weight: Font.Medium
            color: eb.cols[1]
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    MouseArea {
        id: ebMa
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (m) => { if (m.button === Qt.RightButton) eb.rightClicked(); else eb.clicked() }
    }
}
