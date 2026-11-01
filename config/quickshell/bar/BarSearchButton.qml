import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Search / launcher button of the bar
Rectangle {
    id: searchBtn
    property alias topSearchInputHome: topSearchInputHome
    visible: globalState.barModules.search
    implicitWidth: unifiedFrame.barVertical ? 28 : 170; implicitHeight: 28; radius: 14
    Layout.alignment: Qt.AlignCenter
    color: {
        var c = ((globalState.calendarMenuOpen && globalState.leftPanelPage === 1) || globalState.notchSearchOpen
        || (unifiedFrame.barVertical && globalState.islandSearchOpen)) ? pal.primaryCont : pal.secondaryCont;
        return globalState.glassMode ? ga(c, 0.6) : c;
    }
    Behavior on color { M3ColorAnim {} }
    Behavior on x {
        enabled: !globalState.desktopZoomBusy && unifiedFrame.startupSettled && !globalState.desktopEditMode
        M3SpringAnim { token: "spatialFast" }
    }

    function placeInput() {
        var vert = unifiedFrame.barVertical;
        var holder = !vert ? null : (unifiedFrame.islandMode ? islandVSearchHolder : notchSearchPopup.notchVSearchHolder);
        if (vert && holder) {
            if (vSearchField.parent !== holder) vSearchField.parent = holder;
            if (topSearchInputHome.topSearchInput.parent !== vSearchFieldSlot) topSearchInputHome.topSearchInput.parent = vSearchFieldSlot;
        } else {
            if (topSearchInputHome.topSearchInput.parent !== topSearchInputHome) topSearchInputHome.topSearchInput.parent = topSearchInputHome;
            if (vSearchField.parent !== searchBtn) vSearchField.parent = searchBtn;
        }
    }
    function openVertical() {
        topSearchInputHome.islandSearchCloseTimer.stop();
        if (unifiedFrame.islandMode) {
            globalState.islandControlOpen = false;
            globalState.islandSearchOpen = true;
        } else {
            globalState.closeOthers("notchSearch");
            globalState.notchControlOpen = false;
            globalState.notchSearchOpen = true;
        }
        vSearchFocusTimer.tries = 0;
        vSearchFocusTimer.restart();
    }
    Timer {
        id: vSearchFocusTimer
        interval: 60; repeat: true
        property int tries: 0
        onTriggered: {
            topSearchInputHome.topSearchInput.forceActiveFocus();
            tries++;
            if (topSearchInputHome.topSearchInput.activeFocus || tries > 8) stop();
        }
    }
    Connections {
        target: unifiedFrame
        function onBarVerticalChanged() { searchBtn.placeInput(); }
        function onIslandModeChanged()  { searchBtn.placeInput(); }
    }
    Connections {
        target: globalState
        function onIslandSearchOpenChanged() { searchBtn.dropFocusIfClosed(); }
        function onNotchSearchOpenChanged()  { searchBtn.dropFocusIfClosed(); }
    }
    function dropFocusIfClosed() {
        if (!globalState.islandSearchOpen && !globalState.notchSearchOpen && topSearchInputHome.topSearchInput.activeFocus) {
            vSearchFocusTimer.stop();
            topSearchInputHome.topSearchInput.focus = false;
        }
    }
    Component.onCompleted: Qt.callLater(searchBtn.placeInput)

    Text {
        visible: unifiedFrame.barVertical
        anchors.centerIn: parent
        text: "\ue8b6"
        font.family: "Material Symbols Rounded"; font.pixelSize: 15
        color: (globalState.islandSearchOpen || globalState.notchSearchOpen) ? pal.primary : pal.colorOnSurfVar
    }
    MouseArea {
        visible: unifiedFrame.barVertical
        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
        onClicked: searchBtn.openVertical()
    }

    Rectangle {
        id: vSearchField
        visible: unifiedFrame.barVertical && parent !== searchBtn
        anchors.fill: parent
        radius: 14
        color: globalState.glassMode ? ga(pal.secondaryCont, 0.6) : pal.secondaryCont
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12; anchors.rightMargin: 7
            spacing: 8
            Text {
                text: "\ue8b6"
                font.family: "Material Symbols Rounded"; font.pixelSize: 16
                color: pal.primary
            }
            Item {
                id: vSearchFieldSlot
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
            Rectangle {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                radius: globalState.searchMode === "files" ? 8 : 12
                color: globalState.searchMode === "files" ? pal.primary : containerDark(pal.secondaryCont)
                Behavior on color { M3ColorAnim {} }
                Text {
                    anchors.centerIn: parent
                    text: "\ue2c7"
                    font.family: "Material Symbols Rounded"; font.pixelSize: 14
                    color: globalState.searchMode === "files" ? pal.colorOnPrimary : pal.primary
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        globalState.searchMode = (globalState.searchMode === "files") ? "apps" : "files";
                        if (globalState.searchMode === "files") globalState.runFileSearch(topSearchInputHome.topSearchInput.text);
                        topSearchInputHome.topSearchInput.forceActiveFocus();
                    }
                }
            }
        }
    }

    RowLayout {
        visible: !unifiedFrame.barVertical
        anchors.fill: parent
        anchors.leftMargin: 8; anchors.rightMargin: 4
        spacing: 6

        Text {
            text: "\ue8b6"
            font.family: "Material Symbols Rounded"
            font.pixelSize: 15
            color: (globalState.calendarMenuOpen && globalState.leftPanelPage === 1) ? pal.primary : pal.colorOnSurfVar
            opacity: globalState.glassMode ? 0.88 : 1.0
            Behavior on color { M3ColorAnim {} }
        }

        BarSearchInput { id: topSearchInputHome }

        Rectangle {
            id: searchFilesToggle
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            radius: m3Ib4Ma.pressed ? Math.max(4, (globalState.searchMode === "files" ? 7 : height / 2) * 0.5) : (globalState.searchMode === "files" ? 7 : height / 2)
            Behavior on radius { M3SpringAnim { token: "spatialDefault" } }
            color: {
                var active = globalState.searchMode === "files" || searchFilesToggleHov.hovered;
                var c = active ? pal.primary : containerDark(pal.secondaryCont);
                return (globalState.glassMode && !active) ? ga(c, 0.7) : c;
            }
            Behavior on color { M3ColorAnim {} }
            Text {
                anchors.centerIn: parent
                text: "\ue2c7"
                font.family: "Material Symbols Rounded"; font.pixelSize: 13
                color: (globalState.searchMode === "files" || searchFilesToggleHov.hovered) ? pal.colorOnPrimary : pal.primary
                Behavior on color { M3ColorAnim {} }
            }
            HoverHandler { id: searchFilesToggleHov }
            MouseArea { id: m3Ib4Ma;
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    globalState.searchMode = (globalState.searchMode === "files") ? "apps" : "files";
                    if (globalState.searchMode === "files") globalState.runFileSearch(topSearchInputHome.topSearchInput.text);
                }
            }
        }
    }
}
