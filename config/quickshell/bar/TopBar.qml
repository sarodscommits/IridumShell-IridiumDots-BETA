import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../controlcenter"
import "../ui"

// Top bar / island content of the frame
Item {
    id: topBarContent
    property alias barGroupLeft: barGroupLeft
    property alias barGroupRight: barGroupRight
    property alias ccGridComp: ccGridComp
    property alias ccMediaCardComp: ccMediaCardComp
    property alias ccOverviewComp: ccOverviewComp
    property alias ccTrayComp: ccTrayComp
    property alias islandAudioModule: islandAudioModule
    property alias islandAutoHideHideTimer: islandAutoHideHideTimer
    property alias islandControlLoader: islandControlLoader
    property alias openWindowsModule: openWindowsModule
    property alias perfMorphComp: perfMorphComp
    property alias searchBtn: searchBtn
    property alias topBarColumn: topBarColumn
    property alias topBarHover: topBarHover
    property alias topBarMainRow: topBarMainRow
    property alias vBarStrip: vBarStrip
    property alias wsContainer: wsContainer
    readonly property real ncShiftL: unifiedFrame.ncSide ? Math.max(0, unifiedFrame.leftW  - unifiedFrame.edgeBaseSize) : 0
    readonly property real ncShiftR: unifiedFrame.ncSide ? Math.max(0, unifiedFrame.rightW - unifiedFrame.edgeBaseSize) : 0
    width:  unifiedFrame.barVertical ? unifiedFrame.topH : (parent.width - ncShiftL - ncShiftR)
    height: unifiedFrame.barVertical ? parent.height : unifiedFrame.topH
    property real autoHideSlideY: globalState.islandHiddenByAutoHide
    ? (unifiedFrame.barVertical ? (unifiedFrame.barAtRight ? width : -width)
    : (unifiedFrame.barAtBottom ? height : -height))
    : 0
    Behavior on autoHideSlideY { M3NumberAnim { duration: 260 } }
    x: unifiedFrame.barVertical ? ((unifiedFrame.barAtRight ? (parent.width - width) : 0) + autoHideSlideY) : ncShiftL
    y: unifiedFrame.barVertical ? 0 : ((unifiedFrame.barAtBottom ? (parent.height - height) : 0) + autoHideSlideY)

    Rectangle {
        id: topBarBg
        anchors.fill: parent
        color: "transparent"
        HoverHandler {
            id: topBarHover
            onHoveredChanged: {
                if (!hovered) topBarCloseTimer.restart();
            }
        }
        MouseArea {
            id: topBarRightClick
            anchors.fill: parent
            z: -1
            acceptedButtons: Qt.RightButton
            onPressed: (mouse) => {
                if (globalState.lockScreenActive || globalState.desktopEditMode) return;
                var p = topBarRightClick.mapToItem(null, mouse.x, mouse.y);
                desktopEmptyContextMenu.openAt(p.x, p.y);
            }
        }
        Item {
            id: islandPillHoverArea
            x: unifiedFrame.barVertical ? 0 : unifiedFrame.islandNotchLeftX
            width: unifiedFrame.barVertical ? parent.width : (unifiedFrame.islandNotchRightX - unifiedFrame.islandNotchLeftX)
            y: unifiedFrame.barVertical ? unifiedFrame.islandNotchLeftX : 0
            height: unifiedFrame.barVertical ? (unifiedFrame.islandNotchRightX - unifiedFrame.islandNotchLeftX) : parent.height
            HoverHandler {
                onHoveredChanged: globalState.islandAutoHideSetHover(hovered)
            }
        }
        Timer {
            id: topBarCloseTimer
            interval: 300
            repeat: false
            onTriggered: {
                if (!leftPanelContent.leftPanelHover.hovered && !powerMenuPopup.powerPopupHover.hovered && !openWindowsModule.windowPreviewPopup.windowPreviewPopupHover.hovered &&
                !notchMediaPopup.notchMediaPopupHover.hovered && !wsPreviewPopup.wsPreviewPopupHover.hovered && !netBulgePopup.netBulgePopupHover.hovered &&
                !rightPanelContent.mediaPanel.eqDragging)
                globalState.closeTopBar()
            }
        }
        Timer {
            id: islandAutoHideHideTimer
            interval: 450
            repeat: false
            onTriggered: globalState.islandAutoHideRevealed = false
        }
        Timer {
            id: topBarHoverGuard
            interval: 200
            repeat: true
            running: globalState.volumeMenuOpen ||
            globalState.powerMenuOpen || globalState.brightnessMenuOpen ||
            globalState.windowPreviewOpen || globalState.notchMediaOpen || globalState.wsPreviewOpen ||
            globalState.netBulgeOpen
            onTriggered: {
                if (!topBarHover.hovered && !leftPanelContent.leftPanelHover.hovered && !topBarCloseTimer.running &&
                !powerMenuPopup.powerPopupHover.hovered && !openWindowsModule.windowPreviewPopup.windowPreviewPopupHover.hovered &&
                !notchMediaPopup.notchMediaPopupHover.hovered && !wsPreviewPopup.wsPreviewPopupHover.hovered && !netBulgePopup.netBulgePopupHover.hovered &&
                !rightPanelContent.mediaPanel.eqDragging)
                globalState.closeTopBar()
            }
        }

        BarEditOverlay { id: barEditOverlay }

        ColumnLayout {
            id: topBarColumn
            width: parent.width - 32
            x: (unifiedFrame.ncSide && unifiedFrame.ccFromEnd)
            ? Math.min(16, parent.width - 16 - topBarMainRow.width)
            : 16
            anchors.top:    parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin:    unifiedFrame.barAtBottom ? 10 : 8
            anchors.bottomMargin: unifiedFrame.barAtBottom ? 8  : 10
            spacing: 0
            transform: Scale {
                origin.x: topBarColumn.width  / 2
                origin.y: topBarColumn.height / 2
                yScale: unifiedFrame.barAtBottom ? -1 : 1
            }

            RowLayout {
                id: topBarMainRow
                visible: !unifiedFrame.barVertical
                Layout.fillWidth:      !unifiedFrame.islandMode
                Layout.alignment:      unifiedFrame.islandMode ? Qt.AlignHCenter : Qt.AlignLeft
                Layout.preferredHeight: 36
                spacing: 12
                opacity: (unifiedFrame.islandMode && globalState.islandControlOpen) ? 0 : 1
                enabled: !(unifiedFrame.islandMode && globalState.islandControlOpen)
                Behavior on opacity { M3NumberAnim {} }
                transform: Scale {
                    origin.x: topBarMainRow.width  / 2
                    origin.y: topBarMainRow.height / 2
                    yScale: unifiedFrame.barAtBottom ? -1 : 1
                }
                HoverHandler { id: islandSearchMainRowHover }
                Behavior on x {
                    enabled: !globalState.desktopZoomBusy && unifiedFrame.startupSettled
                    M3SpringAnim { token: "spatialFast" }
                }

                Rectangle {
                    id: islandControlBtn
                    visible: globalState.barModules.control
                    Layout.alignment: Qt.AlignCenter
                    property bool panelOpen: (unifiedFrame.islandMode && !globalState.ccFloat) ? globalState.islandControlOpen : globalState.notchControlOpen
                    width: 28; height: 28
                    implicitWidth: 28; implicitHeight: 28
                    radius: islandControlBtnMa.pressed ? 6 : (islandControlBtn.panelOpen ? 9 : 14)
                    Behavior on radius { M3SpringAnim { token: "spatialFast" } }
                    color: {
                        var c = islandControlBtn.panelOpen ? pal.primary : pal.secondaryCont;
                        return (globalState.glassMode && !islandControlBtn.panelOpen) ? ga(c, 0.6) : c;
                    }
                    Behavior on color { M3ColorAnim {} }
                    Text {
                        anchors.centerIn: parent
                        text: "\ue89f"
                        font.family: "Material Symbols Rounded"; font.pixelSize: 15
                        color: islandControlBtn.panelOpen ? pal.colorOnPrimary : pal.colorOnSurfVar
                    }
                    Rectangle { anchors.fill: parent; radius: parent.radius; color: islandControlBtn.panelOpen ? pal.colorOnPrimary : pal.colorOnSurface; opacity: islandControlBtnMa.pressed ? 0.12 : (islandControlBtnHov.hovered ? 0.08 : 0) }
                    function openPanel() {
                        if (unifiedFrame.islandMode) { if (!globalState.islandControlOpen) globalState.toggleIslandControl(); }
                        else if (!globalState.notchControlOpen) globalState.toggleNotchControl();
                    }
                    HoverHandler {
                        id: islandControlBtnHov
                        onHoveredChanged: if (hovered && !globalState.desktopEditMode && !globalState.ccFloat) islandControlBtn.openPanel()
                    }
                    MouseArea {
                        id: islandControlBtnMa
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (globalState.ccFloat) globalState.toggleNotchControl(); else islandControlBtn.openPanel(); }
                    }
                }

                RowLayout {
                    id: barGroupLeft
                    spacing: 10
                    Layout.preferredHeight: 36
                }
                Item {
                    id: notchCenterArea
                    visible: !unifiedFrame.islandMode
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    RowLayout {
                        id: barGroupCenter
                        spacing: 10
                        width: implicitWidth
                        height: parent.height
                        x: (topBarMainRow.width - width) / 2 - notchCenterArea.x
                    }
                }

                BarSearchButton { id: searchBtn }

                Rectangle {
                    id: searchSeparator
                    visible: globalState.barModules.search
                    implicitWidth: unifiedFrame.barVertical ? 16 : 1; implicitHeight: unifiedFrame.barVertical ? 1 : 16; color: pal.surfaceVar; opacity: 0.6
                    Layout.alignment: Qt.AlignCenter
                    Behavior on x {
                        enabled: !globalState.desktopZoomBusy && unifiedFrame.startupSettled && !globalState.desktopEditMode
                        M3SpringAnim { token: "spatialFast" }
                    }
                }

                IslandAudioModule { id: islandAudioModule }

                IslandClockModule { id: islandClockModule }

                WorkspacesModule { id: wsContainer }

                OpenWindowsModule { id: openWindowsModule }

                BarRightGroup { id: barGroupRight }
            }

            IslandSearchResults { id: islandSearchResultsRow }

            BarVolumeMenu { id: volumeMenu }

            BarBrightnessMenu { id: brightnessMenu }
        }

        VerticalBarStrip { id: vBarStrip }

        ColumnLayout {
            id: vSideColumn
            visible: unifiedFrame.barVertical
            spacing: 0
            x: unifiedFrame.barAtRight ? (parent.width - unifiedFrame.topBaseH - width) : unifiedFrame.topBaseH
            y: (parent.height - height) / 2
            function placePanels() {
                if (unifiedFrame.barVertical) {
                    if (islandSearchResultsRow.parent !== vSideColumn) islandSearchResultsRow.parent = vSideColumn;
                } else if (islandSearchResultsRow.parent !== topBarColumn) {
                    islandSearchResultsRow.parent = topBarColumn;
                    volumeMenu.parent = topBarColumn;
                    brightnessMenu.parent = topBarColumn;
                }
            }
            Connections {
                target: unifiedFrame
                function onBarVerticalChanged() { vSideColumn.placePanels(); }
            }
            Component.onCompleted: Qt.callLater(vSideColumn.placePanels)
        }

        Component {
            id: perfMorphComp
            PerfMorphMenu { id: pmHost }
        }

        Component {
            id: ccGridComp
            Loader {
                source: Qt.resolvedUrl("../controlcenter/CcGrid.qml")
            }
        }

        Component {
            id: ccTrayComp
            Loader {
                source: Qt.resolvedUrl("../controlcenter/CcTray.qml")
            }
        }

        Component {
            id: ccMediaCardComp
            Loader {
                source: Qt.resolvedUrl("../controlcenter/CcMediaCard.qml")
                readonly property bool live: parent ? !!parent.live : false
            }
        }

        Component {
            id: ccOverviewComp
            Loader {
                source: Qt.resolvedUrl("../controlcenter/OverviewPage.qml")
                readonly property bool vert: parent ? !!parent.vert : true
                readonly property bool pageOn: parent ? !!parent.pageOn : false
                readonly property bool open: parent ? !!parent.open : false
                readonly property var eqRep: item ? item.eqRep : null
            }
        }

        Component {
            id: ccMonitorComp
            Loader {
                source: Qt.resolvedUrl("../controlcenter/IslandMonitorCard.qml")
                readonly property bool live: parent ? !!parent.live : false
            }
        }

        Loader {
            id: islandControlLoader
            anchors.fill: parent
            asynchronous: true
            property bool keep: false
            active: unifiedFrame.islandMode && (globalState.islandControlOpen || keep)
            source: Qt.resolvedUrl("../controlcenter/IslandControlPanel.qml")
        }
    }
}
