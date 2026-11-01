import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../panels"
import "../ui"

// Scrollable icon strip of open windows
Item {
    id: openWindowsClip
    property alias openWindowsRow: openWindowsRow
    anchors.fill: parent
    visible: globalState.barModules.windows
    clip: false

    Grid {
        id: openWindowsRow
        y: unifiedFrame.barVertical ? 0 : (parent.height - height) / 2
        x: unifiedFrame.barVertical ? (parent.width - width) / 2 : 0
        spacing: 12
        rows:    unifiedFrame.barVertical ? -1 : 1
        columns: unifiedFrame.barVertical ? 1 : -1

        Repeater {
            id: openWindowsRepeater
            model: taskbarModel
            property var taskbarModel: buildTaskbarModel()
            function buildTaskbarModel() {
                var ws = globalState.activeWorkspace;
                var real = globalState.openClients.filter(function(c) {
                    return c.workspace === ws;
                });

                var openClsSet = {};
                for (var i = 0; i < globalState.openClients.length; i++) {
                    openClsSet[globalState.openClients[i].cls] = true;
                }

                var ghosts = [];
                for (var j = 0; j < globalState.pinnedApps.length; j++) {
                    var cls = globalState.pinnedApps[j];
                    if (openClsSet[cls]) continue;
                    var entry = globalState.appEntryForCls(cls);
                    ghosts.push({
                        address: "",
                        cls: cls,
                        title: entry ? entry.name : cls,
                        workspace: ws,
                        floating: false,
                        _pinnedGhostExec: entry ? entry.exec : ""
                    });
                }

                return real.concat(ghosts);
            }
            Connections {
                target: globalState
                function onOpenClientsChanged() { openWindowsRepeater.taskbarModel = openWindowsRepeater.buildTaskbarModel(); }
                function onActiveWorkspaceChanged() { openWindowsRepeater.taskbarModel = openWindowsRepeater.buildTaskbarModel(); }
                function onPinnedAppsChanged() { openWindowsRepeater.taskbarModel = openWindowsRepeater.buildTaskbarModel(); }
                function onAppListChanged() { openWindowsRepeater.taskbarModel = openWindowsRepeater.buildTaskbarModel(); }
            }
            property color _primary: pal.primary
            property color _muted:   pal.muted

            delegate: Item {
                id: winSlot
                required property var modelData
                width: 28; height: 28

                readonly property bool isActive: modelData.address !== "" &&
                modelData.address === globalState.activeWindowAddress
                readonly property string _qsApp: globalState.internalAppForClient(modelData.cls, modelData.title)
                readonly property string _icon: _qsApp !== "" ? "" : globalState.windowIconFor(modelData.cls)

                scale: (winSlot.isActive || winSlotHov.hovered) ? 1.35 : 1.0
                Behavior on scale { M3SpringAnim { token: "spatialFast"; epsilon: 0.002 } }
                opacity: winSlot.isActive ? 1.0 : 0.60
                Behavior on opacity { M3NumberAnim { duration: m3.durFast } }
                Behavior on x { M3SpringAnim { token: "spatialFast" } }

                InternalAppIcon {
                    anchors.fill: parent
                    anchors.margins: 1
                    visible: winSlot._qsApp !== ""
                    glyph: globalState.internalAppGlyph(winSlot._qsApp)
                }
                Image {
                    sourceSize: Qt.size(96, 96)
                    anchors.fill: parent
                    visible: winSlot._icon !== ""
                    source: winSlot._icon !== "" ? ("file://" + winSlot._icon) : ""
                    fillMode: Image.PreserveAspectFit
                    smooth: true; mipmap: true; asynchronous: true
                }
                Text {
                    anchors.centerIn: parent
                    visible: winSlot._icon === "" && winSlot._qsApp === ""
                    text: (winSlot.modelData.title || winSlot.modelData.cls || "?").charAt(0).toUpperCase()
                    font.family: globalState.fontPrimary; font.pixelSize: Math.round(13 * globalState.fontScale); font.weight: Font.Bold
                    color: winSlot.isActive ? openWindowsRepeater._primary : openWindowsRepeater._muted
                }

                HoverHandler {
                    id: winSlotHov
                    onHoveredChanged: {
                        if (hovered) {
                            peekRestoreGuard.stop();
                            previewCloseTimer.stop();
                            globalState.closeOthers("preview");
                            globalState.windowPreviewAddress = winSlot.modelData.address;
                            globalState.windowPreviewOpen = true;
                            unifiedFrame.previewAnchorX =
                            winSlot.mapToItem(frameShape, winSlot.width / 2, winSlot.height / 2).x;
                            unifiedFrame.setBulgeCentered(windowPreviewPopup, windowPreviewPopup.computedDepth);

                            if (globalState.peekedWindowAddress !== winSlot.modelData.address) {
                                if (globalState.peekedWindowAddress !== "") {
                                    Quickshell.execDetached(["/usr/bin/python3",
                                    Quickshell.env("HOME") + "/.config/hypr/scripts/peek_window.py", "restore",
                                    globalState.peekedWindowAddress]);
                                }
                                globalState.peekedWindowAddress = winSlot.modelData.address;
                                globalState.peekWindowInstant(winSlot.modelData.address);
                            }
                        } else {
                            previewCloseTimer.restart();
                        }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (winSlot.modelData.address !== "") {
                            if (globalState.peekedWindowAddress === winSlot.modelData.address) {
                                peekRestoreGuard.stop();
                                Quickshell.execDetached(["/usr/bin/python3",
                                Quickshell.env("HOME") + "/.config/hypr/scripts/peek_window.py", "cancel",
                                winSlot.modelData.address]);
                                globalState.peekedWindowAddress = "";
                            }
                            Quickshell.execDetached(["/usr/bin/python3",
                            Quickshell.env("HOME") + "/.config/hypr/scripts/focus_window_from_taskbar.py",
                            winSlot.modelData.address]);
                        }
                    }
                }
            }
        }
    }
}
