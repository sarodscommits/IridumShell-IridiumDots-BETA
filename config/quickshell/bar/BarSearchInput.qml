import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."

// Search text input of the bar search button
Item {
    id: topSearchInputHome
    property alias islandSearchCloseTimer: islandSearchCloseTimer
    property alias topSearchInput: topSearchInput
    Layout.fillWidth: true
    Layout.fillHeight: true
    TextInput {
        id: topSearchInput
        anchors.fill: parent
        TapHandler {
            onTapped: {
                if (!globalState.islandSearchOpen && !globalState.notchSearchOpen)
                searchBtn.openVertical();
            }
        }
        verticalAlignment: TextInput.AlignVCenter
        font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
        color: pal.colorOnSurface
        selectionColor: pal.toggleOn
        clip: true
        onTextChanged: {
            leftPanelContent.leftLauncherCard.searchQuery = text;
            if (globalState.searchMode === "files") globalState.runFileSearch(text);
        }
        onActiveFocusChanged: {
            if (activeFocus) {
                if (unifiedFrame.islandMode) {
                    islandSearchCloseTimer.stop();
                    globalState.islandControlOpen = false;
                    globalState.islandSearchOpen = true;
                } else {
                    islandSearchCloseTimer.stop();
                    globalState.closeOthers("notchSearch");
                    globalState.notchControlOpen = false;
                    globalState.notchSearchOpen = true;
                }
            } else {
                islandSearchCloseTimer.restart();
            }
        }
        Timer {
            id: islandSearchCloseTimer
            interval: 250
            repeat: false
            onTriggered: { globalState.islandSearchOpen = false; globalState.notchSearchOpen = false; }
        }
        Keys.onEscapePressed: {
            topSearchInput.text = "";
            leftPanelContent.leftLauncherCard.searchQuery = "";
            globalState.calendarMenuOpen = false;
            globalState.islandSearchOpen = false;
            globalState.notchSearchOpen = false;
        }
        Keys.onReturnPressed: {
            if (globalState.searchMode === "files") {
                var files = globalState.fileSearchResults;
                if (files.length > 0) {
                    Quickshell.execDetached(["bash", "-c", files[0].exec]);
                    topSearchInput.text = "";
                    leftPanelContent.leftLauncherCard.searchQuery = "";
                    globalState.calendarMenuOpen = false;
                    globalState.islandSearchOpen = false;
                    globalState.notchSearchOpen = false;
                }
            } else {
                var apps = leftPanelContent.leftLauncherCard.filteredApps;
                var firstApp = null;
                for (var ai = 0; ai < apps.length; ai++) {
                    if (!apps[ai].isHeader) { firstApp = apps[ai]; break; }
                }
                if (firstApp) {
                    globalState.launchApp(firstApp);
                    topSearchInput.text = "";
                    leftPanelContent.leftLauncherCard.searchQuery = "";
                    globalState.calendarMenuOpen = false;
                    globalState.islandSearchOpen = false;
                    globalState.notchSearchOpen = false;
                }
            }
        }
        Text {
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            text: topSearchInput.text.length === 0
            ? (globalState.searchMode === "files" ? tr("search_files")
            : tr("search_apps"))
            : ""
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale)
            color: pal.muted
        }
    }
}
