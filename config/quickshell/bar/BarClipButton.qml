import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Clipboard button of the bar
Item {
    id: clipBtn
    property alias clipBtnHover: clipBtnHover
    Layout.alignment: Qt.AlignCenter
    visible: globalState.barModules.clipboard
    width: 28; height: 28
    EBarSlot { anchors.fill: parent; active: clipBulgePopup.isOpen || globalState.clipDragHover; hovered: clipBtnHover.hovered; activeColor: globalState.clipDragHover ? ga(pal.primary, 0.28) : m3.glassy(m3.secondaryContainer, 0.75) }
    Rectangle {
        anchors.fill: parent
        radius: 9
        color: "transparent"
        border.width: globalState.clipDragHover ? 1.5 : 0
        border.color: pal.primary
    }
    Text {
        anchors.centerIn: parent
        text: ""
        font.family: "Material Symbols Rounded"; font.pixelSize: 15
        color: (globalState.clipHasContent || globalState.clipDragHover) ? pal.primary : pal.muted
        opacity: globalState.glassMode ? 0.88 : 1.0
        scale: globalState.clipDragHover ? 1.25 : 1
        Behavior on scale { M3SpringAnim { token: "spatialFast"; epsilon: 0.002 } }
        Behavior on color { M3ColorAnim {} }
    }
    Rectangle {
        visible: globalState.clipHasContent && !clipBulgePopup.isOpen
        anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 3
        width: 6; height: 6; radius: 3
        color: globalState.clipPinned ? pal.primary : pal.muted
    }
    HoverHandler {
        id: clipBtnHover
        onHoveredChanged: {
            if (globalState.desktopEditMode) return;
            if (hovered) { clipBulgePopup.clipCollapseTimer.stop(); if (!globalState.clipBulgeOpen) globalState.openClipBulge(false); }
            else clipBulgePopup.scheduleCollapse(700);
        }
    }
    MouseArea {
        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
        onClicked: { globalState.clipPinned = !globalState.clipPinned; savePrefs(); }
    }
    DropArea {
        anchors.fill: parent
        anchors.margins: -6
        onEntered: (drag) => {
            if (globalState.clipDraggingOut) { drag.accepted = false; return; }
            drag.accept(Qt.CopyAction); globalState.clipDragHover = true;
        }
        onExited: globalState.clipDragHover = false
        onDropped: (drop) => { if (!globalState.clipDraggingOut) handleClipDrop(drop); }
    }
}
