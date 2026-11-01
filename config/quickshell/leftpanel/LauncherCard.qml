import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "AppSearch.js" as AppSearch

// App search card of the left panel
Item {
    id: leftLauncherCard
    visible: false
    width: 0; height: 0
    property string searchQuery: ""

    function getFilteredApps() {
        var q = leftLauncherCard.searchQuery.toLowerCase().trim();
        var usage = function (a) { return globalState.appUsageCount(a); };
        var all = AppSearch.sortByUsage(globalState.appList.concat(globalState.internalApps), usage);
        if (q.length === 0)
        return AppSearch.blocks(all, globalState.internalApps, globalState.appList, usage,
        [tr("launcher_most_used"), tr("launcher_system"), tr("launcher_all_apps")]);
        return AppSearch.rank(all, q);
    }

    property var filteredApps: leftLauncherCard.getFilteredApps()
    readonly property bool blockMode: globalState.searchMode !== "files" && searchQuery.trim().length === 0

    onSearchQueryChanged: filteredApps = leftLauncherCard.getFilteredApps()
    Connections {
        target: globalState
        function onAppListChanged() {
            leftLauncherCard.filteredApps = leftLauncherCard.getFilteredApps()
        }
        function onAppListLoadedChanged() {
            leftLauncherCard.filteredApps = leftLauncherCard.getFilteredApps()
        }
        function onAppUsageChanged() {
            leftLauncherCard.filteredApps = leftLauncherCard.getFilteredApps()
        }
        function onInternalAppsChanged() {
            leftLauncherCard.filteredApps = leftLauncherCard.getFilteredApps()
        }
        function onLanguageChanged() {
            leftLauncherCard.filteredApps = leftLauncherCard.getFilteredApps()
        }
    }

    property bool showLoading: globalState.searchMode === "apps" && globalState.appListLoading && globalState.appList.length === 0
    property bool showEmpty: globalState.searchMode === "apps" && !globalState.appListLoading && globalState.appList.length === 0 && !globalState.appListLoaded
    property bool showEmptyFiles: globalState.searchMode === "files" && leftLauncherCard.searchQuery.trim().length >= 2 && globalState.fileSearchResults.length === 0
}
