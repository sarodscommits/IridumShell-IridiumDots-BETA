import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Notification button of the bar
Item {
    id: notifBtn
    readonly property int count: notificationsBackend.trackedNotifications.values.length
    readonly property bool vert: unifiedFrame.barVertical
    readonly property bool panelOpen: (unifiedFrame.islandMode && !globalState.ccFloat)
    ? (globalState.islandControlOpen && globalState.islandControlPage === 2)
    : (globalState.notchControlOpen && globalState.notchControlPage === 0)
    visible: globalState.barModules.notifications && (count > 0 || globalState.desktopEditMode)
    Layout.alignment: Qt.AlignCenter
    implicitWidth: vert ? 28 : notifBtnGrid.implicitWidth + 16
    implicitHeight: vert ? Math.max(28, notifBtnGrid.implicitHeight + 8) : 28

    EBarSlot { anchors.fill: parent; active: notifBtn.panelOpen; hovered: notifBtnHov.hovered; restRadius: 14 }
    GridLayout {
        id: notifBtnGrid
        anchors.centerIn: parent
        columns: notifBtn.vert ? 1 : 2
        rowSpacing: 0
        columnSpacing: 4
        FadeIcon {
            Layout.alignment: Qt.AlignHCenter
            text: globalState.dndEnabled ? "" : ""
            font.family: "Material Symbols Rounded"; font.pixelSize: 15
            color: notifBtn.count > 0 ? pal.primary : pal.muted
            opacity: globalState.glassMode ? 0.88 : 1.0
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            visible: notifBtn.count > 0
            text: notifBtn.count > 99 ? "99+" : notifBtn.count
            font.family: globalState.fontSecondary
            font.pixelSize: Math.round((notifBtn.vert ? 10 : 12) * globalState.fontScale)
            font.weight: Font.DemiBold
            color: pal.colorOnSurface
        }
    }
    HoverHandler { id: notifBtnHov }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (globalState.desktopEditMode) return;
            if (unifiedFrame.islandMode) globalState.openIslandControlPage(2);
            else globalState.openNotchControl(0);
        }
    }
}
