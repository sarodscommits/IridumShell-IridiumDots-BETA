import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import ".."
import "../frame"
import "../ui"

// Search results under the island search field
Item {
    id: islandSearchResultsRow
    property bool isOpen: unifiedFrame.islandMode && globalState.islandSearchOpen
    property bool clickGuard: false
    Component.onCompleted: unifiedFrame.islandSearchResultsItem = islandSearchResultsRow
    Layout.preferredWidth: unifiedFrame.barVertical ? unifiedFrame.vSearchPanelW : (topBarMainRow ? topBarMainRow.width : 0)
    Layout.alignment: Qt.AlignHCenter
    // Height follows unifiedFrame.topH so results reveal exactly as the island grows
    readonly property bool following: isOpen || !globalState.islandControlOpen
    readonly property real frameP: Math.max(0, Math.min(1, (unifiedFrame.topH - unifiedFrame.topBaseH) / (unifiedFrame.vSearchPanelW + 10)))
    Layout.preferredHeight: !following ? 0
        : unifiedFrame.barVertical ? (unifiedFrame.searchExtraLive + unifiedFrame.vSearchFieldH) * frameP
        : Math.max(0, unifiedFrame.topH - unifiedFrame.topBaseH)
    visible: true
    clip: true
    transform: Scale {
        origin.x: islandSearchResultsRow.width  / 2
        origin.y: islandSearchResultsRow.height / 2
        yScale: unifiedFrame.barAtBottom ? -1 : 1
    }
    HoverHandler {
        id: islandSearchRowHover
        onHoveredChanged: unifiedFrame.searchResultsHovered = hovered && islandSearchResultsRow.isOpen
    }
    Timer {
        id: islandSearchHoverCloseGuard
        interval: 220
        repeat: true
        running: globalState.islandSearchOpen
        onTriggered: {
            if (!islandSearchMainRowHover.hovered && !islandSearchRowHover.hovered
            && !(unifiedFrame.barVertical && vBarStrip.vStripHover.hovered)
            && !islandSearchResultsRow.clickGuard
            && !unifiedFrame.searchCatcherHovered)
            globalState.islandSearchOpen = false;
        }
    }

    Item {
        id: islandVSearchHolder
        visible: unifiedFrame.barVertical && islandSearchResultsRow.height > 1
        x: 6; y: 6
        width: parent.width - 12
        height: unifiedFrame.vSearchFieldH - 8
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 6
        anchors.topMargin: unifiedFrame.barVertical ? unifiedFrame.vSearchFieldH + 2 : 6
        radius: 14
        color: "transparent"
        clip: true

        ListView {
            id: icSearchResultsList
            anchors.fill: parent
            anchors.margins: 0
            clip: true
            spacing: 0
            model: globalState.searchMode === "files" ? globalState.fileSearchResults : (leftPanelContent.leftLauncherCard ? leftPanelContent.leftLauncherCard.filteredApps : [])
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            property color appTitleColor: pal.textPrimary
            property color appIconColor:  pal.primary

            delegate: SearchResultRow {
                list: icSearchResultsList
                guard: islandSearchResultsRow
                blockRadius: 14
                pillHover: true
                roundIcons: true
                hoverColor: m3.alpha(m3.inkSurface, 0.10)
                onLaunched: globalState.islandSearchOpen = false
            }

            EmptyHint {
                anchors.centerIn: parent
                visible: icSearchResultsList.count === 0
                text: tr("nothing_here")
                key: leftPanelContent.leftLauncherCard ? (globalState.searchMode + ":" + leftPanelContent.leftLauncherCard.searchQuery) : ""
            }
        }
    }
}
