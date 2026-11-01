import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Island app search popup
Item {
    id: notchSearchPopup
    property alias notchVSearchHolder: notchVSearchHolder
    readonly property bool isOpen: globalState.notchSearchOpen && !unifiedFrame.islandMode
    readonly property real rowH: unifiedFrame.islandSearchRowH
    readonly property int resultCount: unifiedFrame.islandSearchResultCount
    readonly property real maxDepth: 420
    readonly property real targetDepth: Math.min(maxDepth, Math.max(rowH, resultCount * rowH) + 40)
    property bool clickGuard: false
    readonly property real natW: 440
    readonly property real bulgeW: natW * unifiedFrame.bulgeScale
    readonly property real fieldH: unifiedFrame.barVertical ? unifiedFrame.vSearchFieldH : 0
    readonly property real scaledDepth: (targetDepth + fieldH) * unifiedFrame.bulgeScale
    x: unifiedFrame.barVertical ? unifiedFrame.popupRealX(width) : unifiedFrame.bulgeLeftX
    width: unifiedFrame.barVertical ? unifiedFrame.bulgeDepth : Math.max(0, unifiedFrame.bulgeRightX - unifiedFrame.bulgeLeftX)
    height: unifiedFrame.barVertical ? Math.max(0, unifiedFrame.bulgeRightX - unifiedFrame.bulgeLeftX) : unifiedFrame.bulgeDepth
    opacity: isOpen ? 1 : 0
    Behavior on opacity { M3NumberAnim { duration: notchSearchPopup.isOpen ? 220 : 140 } }
    visible: opacity > 0.01
    enabled: isOpen
    y: unifiedFrame.barVertical ? unifiedFrame.bulgeLeftX
    : (unifiedFrame.barAtBottom ? (frameRoot.height - unifiedFrame.frameBottomH - height) : unifiedFrame.frameTopH)
    z: 1000
    clip: true

    HoverHandler {
        id: notchSearchPopupHover
        onHoveredChanged: unifiedFrame.searchResultsHovered = hovered && notchSearchPopup.isOpen
    }

    // Spring drives open/resize; closing uses the frame's bulge animation
    Spring {
        id: nsDepthSpring
        target: notchSearchPopup.isOpen ? notchSearchPopup.scaledDepth : 0
        stiffness: m3.sk("spatialDefault")
        dampingRatio: 0.92
        eps: 0.3
        onValueChanged: {
            if (!notchSearchPopup.isOpen || value < 0.5) return;
            unifiedFrame.bulgeLive = true;
            unifiedFrame.setBulgeUnder(notchSearchPopup, topBarContent.searchBtn, value);
        }
        onMovingChanged: if (!moving) unifiedFrame.bulgeLive = false
    }
    onIsOpenChanged: {
        if (isOpen) {
            nsDepthSpring.snap(unifiedFrame.bulgeDepth);
            nsDepthSpring.target = Qt.binding(function () { return notchSearchPopup.isOpen ? notchSearchPopup.scaledDepth : 0; });
        } else {
            unifiedFrame.bulgeLive = false;
            unifiedFrame.setBulgeUnder(notchSearchPopup, topBarContent.searchBtn, 0);
        }
    }

    Timer {
        interval: 220
        repeat: true
        running: notchSearchPopup.isOpen
        onTriggered: {
            if (!topBarContent.topBarHover.hovered && !notchSearchPopupHover.hovered && !notchSearchPopup.clickGuard
                && !unifiedFrame.searchCatcherHovered)
            globalState.notchSearchOpen = false;
        }
    }
    Connections {
        target: unifiedFrame
        function onIslandModeChanged() { if (unifiedFrame.islandMode) globalState.notchSearchOpen = false; }
    }

    Item {
        width: notchSearchPopup.natW
        x: unifiedFrame.barVertical ? (unifiedFrame.barAtLeft ? 0 : parent.width - width) : (parent.width - width) / 2
        height: notchSearchPopup.targetDepth + notchSearchPopup.fieldH
        scale: unifiedFrame.bulgeScale
        transformOrigin: unifiedFrame.popupOrigin
        y: unifiedFrame.barVertical ? (parent.height - height) / 2 : (unifiedFrame.barAtBottom ? parent.height - height : 0)
        Item {
            id: notchVSearchHolder
            visible: unifiedFrame.barVertical
            x: 10; y: 6
            width: parent.width - 20
            height: notchSearchPopup.fieldH - 8
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: 10
            anchors.topMargin: 4 + notchSearchPopup.fieldH
            radius: 18
            color: "transparent"
            clip: true

            ListView {
                id: nsSearchResultsList
                anchors.fill: parent
                anchors.margins: 0
                clip: true
                spacing: 0
                model: globalState.searchMode === "files" ? globalState.fileSearchResults : (leftPanelContent.leftLauncherCard ? leftPanelContent.leftLauncherCard.filteredApps : [])
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                property color appTitleColor: pal.textPrimary
                property color appIconColor:  pal.primary

                delegate: SearchResultRow {
                    list: nsSearchResultsList
                    guard: notchSearchPopup
                    onLaunched: globalState.notchSearchOpen = false
                }

                EmptyHint {
                    anchors.centerIn: parent
                    visible: nsSearchResultsList.count === 0
                    text: tr("nothing_here")
                    key: leftPanelContent.leftLauncherCard ? (globalState.searchMode + ":" + leftPanelContent.leftLauncherCard.searchQuery) : ""
                }
            }
        }
    }
}
