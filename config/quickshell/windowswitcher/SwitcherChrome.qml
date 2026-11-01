import QtQuick

Item {
    id: chrome
    required property var win
    required property var pagerItem
    anchors.fill: parent

    Text {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 28
        text: "Workspace " + win.gs.activeWorkspace + (win.items.length > 0
              ? "   " + (win.selected + 1) + " / " + win.items.length : "")
        font.family: win.gs.fontSecondary; font.pixelSize: Math.round(15 * win.gs.fontScale); font.weight: Font.Medium
        font.capitalization: Font.Capitalize
        color: "#FFFFFF"; opacity: 0.85
    }

    Text {
        anchors.centerIn: parent
        visible: win.items.length === 0
        text: ""
        horizontalAlignment: Text.AlignHCenter
        font.family: "Material Symbols Rounded"; font.pixelSize: 40
        color: "#FFFFFF"; opacity: 0.5
    }

    Rectangle {
        anchors.top: parent.top; anchors.right: parent.right
        anchors.margins: 18
        width: 40; height: 40; radius: 12
        color: closeAllHov.hovered ? Qt.rgba(1, 0, 0, 0.35) : Qt.rgba(1, 1, 1, 0.08)
        Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Text {
            anchors.centerIn: parent
            text: ""
            font.family: "Material Symbols Rounded"; font.pixelSize: 20
            color: "#FFFFFF"
        }
        HoverHandler { id: closeAllHov }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: win.finish("")
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: chrome.pagerItem.bottom
        anchors.topMargin: 26
        spacing: 8
        visible: win.pages.length > 1
        Repeater {
            model: win.pages.length
            Rectangle {
                required property int index
                readonly property bool active: index === win.currentPage
                width: active ? 20 : 8; height: 8; radius: 4
                color: active ? win.colors.primary : Qt.rgba(1, 1, 1, 0.35)
                Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                Behavior on color { ColorAnimation { duration: 200 } }
                MouseArea {
                    anchors.fill: parent; anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { win.currentPage = parent.index; var t = win.pages[parent.index].tiles; if (t.length) win.selected = t[0].i; }
                }
            }
        }
    }
}
