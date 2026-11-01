import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Strip shown along a vertical bar edge
Item {
    id: vBarStrip
    property alias barVGroupCenter: barVGroupCenter
    property alias barVGroupIsland: barVGroupIsland
    property alias barVGroupLeft: barVGroupLeft
    property alias barVGroupRight: barVGroupRight
    property alias vIslandCol: vIslandCol
    property alias vNotchTopCol: vNotchTopCol
    property alias vStripHover: vStripHover
    visible: unifiedFrame.barVertical
    readonly property bool panelOpen: (unifiedFrame.islandMode && globalState.islandControlOpen)
    || (!unifiedFrame.islandMode && globalState.ncFusedOpen)
    opacity: panelOpen ? 0 : 1
    enabled: visible && !panelOpen
    Behavior on opacity { M3NumberAnim {} }
    width: unifiedFrame.topBaseH
    x: unifiedFrame.barAtRight ? (parent.width - width) : 0
    y: 0
    height: parent.height
    HoverHandler { id: vStripHover }

    ColumnLayout {
        id: vIslandCol
        visible: unifiedFrame.islandMode
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        spacing: 10
        Behavior on y {
            enabled: !globalState.desktopZoomBusy && unifiedFrame.startupSettled
            M3SpringAnim { token: "spatialDefault" }
        }
        ColumnLayout {
            id: barVGroupIsland
            Layout.alignment: Qt.AlignHCenter
            spacing: 10
        }
    }

    Item {
        id: vNotchArea
        visible: !unifiedFrame.islandMode
        anchors.fill: parent
        anchors.topMargin: globalState.cornerR + 12
        anchors.bottomMargin: globalState.cornerR + 12
        ColumnLayout {
            id: vNotchTopCol
            x: (parent.width - width) / 2
            y: 0
            spacing: 10
            ColumnLayout {
                id: barVGroupLeft
                Layout.alignment: Qt.AlignHCenter
                spacing: 10
            }
        }
        ColumnLayout {
            id: barVGroupCenter
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2
            spacing: 10
        }
        ColumnLayout {
            id: barVGroupRight
            x: (parent.width - width) / 2
            y: parent.height - height
            spacing: 10
        }
    }
}
