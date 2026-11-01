import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Left side panel: widget cards and app launcher pages
Item {
    id: leftPanelContent
    property alias leftLauncherCard: leftLauncherCard
    property alias leftPanelHover: leftPanelHover
    anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.left: parent.left
    anchors.topMargin: unifiedFrame.frameTopH
    anchors.bottomMargin: (globalState.calendarMenuOpen && globalState.leftPanelPage === 1)
    ? unifiedFrame.frameBottomBaseH
    : unifiedFrame.frameBottomH
    width: (unifiedFrame.islandMode || !unifiedFrame.leftPanelEnabled) ? 0 : Math.max(unifiedFrame.leftW, unifiedFrame.edgeHoverWidth)
    visible: width > 0

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        clip: true

        HoverHandler {
            id: leftPanelHover
            onHoveredChanged: {
                if (hovered) {
                    calCloseTimer.stop();
                    if (!globalState.calendarMenuOpen) globalState.leftPanelPage = 0;
                    globalState.calendarMenuOpen = true;
                } else {
                    calCloseTimer.restart();
                }
            }
        }
        Timer {
            id: calCloseTimer
            interval: 300
            repeat: false
            onTriggered: {
                if (!leftPanelHover.hovered && !leftPanelPage2Loader.hoverActive && !leftPanelPage2Loader.listMoving)
                globalState.calendarMenuOpen = false;
            }
        }
        Timer {
            id: calHoverGuard
            interval: 200
            repeat: true
            running: globalState.calendarMenuOpen
            onTriggered: {
                if (!topBarContent.topBarHover.hovered && !leftPanelHover.hovered && !leftPanelPage2Loader.hoverActive &&
                !calCloseTimer.running && !leftPanelPage2Loader.listMoving) {
                    calCloseTimer.start();
                }
            }
        }

        Loader {
            id: calPanelLoader
            anchors.fill: parent
            active: unifiedFrame.leftPanelEnabled && !unifiedFrame.islandMode
            source: Qt.resolvedUrl("LeftPanelCards.qml")
        }
    }

    LauncherCard { id: leftLauncherCard }

    Loader {
        id: leftPanelPage2Loader
        anchors.fill: parent
        anchors.margins: 10
        anchors.topMargin: 26
        active: unifiedFrame.leftPanelEnabled && !unifiedFrame.islandMode
        readonly property bool hoverActive: item ? item.hoverActive : false
        readonly property bool listMoving:  item ? item.listMoving  : false
        source: Qt.resolvedUrl("LauncherPage.qml")
    }

    Row {
        id: leftPageDotsRow
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 8
        spacing: 6
        z: 10
        opacity: globalState.calendarMenuOpen ? 1 : 0
        visible: globalState.calendarMenuOpen
        Behavior on opacity { M3NumberAnim { duration: m3.durFast } }

        property color dotActiveColor:   pal.primary
        property color dotInactiveColor: Qt.rgba(pal.primary.r, pal.primary.g, pal.primary.b, 0.35)

        Repeater {
            model: 2
            Rectangle {
                required property int index
                width: globalState.leftPanelPage === index ? 14 : 6
                height: 6; radius: 3
                property bool isActive: globalState.leftPanelPage === index
                color: isActive ? leftPageDotsRow.dotActiveColor : leftPageDotsRow.dotInactiveColor
                Behavior on width { M3SpringAnim { token: "spatialFast" } }
                Behavior on color { M3ColorAnim {} }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: globalState.leftPanelPage = index
                }
            }
        }
    }
}
