import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Workspace indicator of the bar
Item {
    id: wsContainer
    property alias wsContainerHover: wsContainerHover
    visible: globalState.barModules.workspaces
    implicitHeight: unifiedFrame.barVertical ? wsRow2.implicitHeight : dotHeight
    implicitWidth: wsRow2.implicitWidth
    Layout.alignment: Qt.AlignCenter
    Behavior on x {
        enabled: !globalState.desktopZoomBusy && unifiedFrame.startupSettled && !globalState.desktopEditMode
        M3SpringAnim { token: "spatialFast" }
    }

    readonly property int inactiveSize: 16
    readonly property int activeWidth:  34
    readonly property int dotHeight:    16
    readonly property int dotRadius:    8

    property var displayWorkspaces: computeDisplayWorkspaces()
    function computeDisplayWorkspaces() {
        var s = globalState.openWorkspaces.slice();
        for (var i = 1; i <= 5; i++) { if (s.indexOf(i) === -1) s.push(i); }
        s.sort(function(a, b) { return a - b; });
        return s;
    }
    Connections {
        target: globalState
        function onOpenWorkspacesChanged() {
            wsContainer.displayWorkspaces = wsContainer.computeDisplayWorkspaces();
        }
    }

    HoverHandler {
        id: wsContainerHover
        margin: 4
        onHoveredChanged: {
            if (hovered) wsPreviewPopup.wsPreviewCloseTimer.stop();
            else if (globalState.wsPreviewOpen) wsPreviewPopup.wsPreviewCloseTimer.restart();
        }
    }

    Grid {
        id: wsRow2
        spacing: 6
        rows:    unifiedFrame.barVertical ? -1 : 1
        columns: unifiedFrame.barVertical ? 1 : -1
        Repeater {
            id: wsRepeater
            model: wsContainer.displayWorkspaces

            property color _dotActive:   pal.primary
            property color _dotInactive: Qt.rgba(pal.primary.r, pal.primary.g, pal.primary.b, 0.35)
            property color _onDotActive: pal.colorOnPrimary

            delegate: Item {
                id: wsSlot
                required property var modelData
                readonly property real longSide: wsSlot.isActive ? wsContainer.activeWidth : wsContainer.inactiveSize
                width:  unifiedFrame.barVertical ? wsContainer.dotHeight : longSide
                height: unifiedFrame.barVertical ? longSide : wsContainer.dotHeight

                readonly property bool isActive: modelData === globalState.activeWorkspace
                Behavior on width { M3SpringAnim { token: "spatialFast" } }
                Behavior on height { M3SpringAnim { token: "spatialFast" } }
                Behavior on x { M3SpringAnim { token: "spatialFast" } }

                Rectangle {
                    anchors.fill: parent
                    radius: wsContainer.dotRadius
                    color: wsSlot.isActive ? wsRepeater._dotActive : wsRepeater._dotInactive
                    Behavior on color { M3ColorAnim {} }

                    Text {
                        anchors.centerIn: parent
                        visible: wsSlot.isActive
                        text: wsSlot.modelData
                        font.family: globalState.fontSecondary
                        font.bold: true
                        font.pixelSize: Math.round(12 * globalState.fontScale)
                        color: wsRepeater._onDotActive
                        opacity: wsSlot.isActive ? 1.0 : 0.0
                        Behavior on opacity { M3NumberAnim { duration: m3.durFast } }
                    }
                }

                HoverHandler {
                    margin: 3
                    onHoveredChanged: {
                        if (hovered) {
                            wsPreviewPopup.wsPreviewCloseTimer.stop();
                            var p = wsSlot.mapToItem(frameShape, wsSlot.width / 2, wsSlot.height / 2);
                            if (!globalState.wsPreviewOpen) globalState.closeOthers("wsPreview");
                            wsPreviewPopup.anchorX = p.x;
                            globalState.wsPreviewId = wsSlot.modelData;
                            if (globalState.wsPreviewOpen) wsPreviewPopup.reposition();
                            else globalState.wsPreviewOpen = true;
                        } else if (!wsContainerHover.hovered) {
                            wsPreviewPopup.wsPreviewCloseTimer.restart();
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -3
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!wsSlot.isActive)
                        Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + wsSlot.modelData + " })"])
                    }
                }
            }
        }
    }
}
