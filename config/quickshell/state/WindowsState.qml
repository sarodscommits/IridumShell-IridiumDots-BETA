import QtQuick
import Quickshell

// Workspaces, clients, window icons and the app list used by the launcher
SystemState {
    property int    activeWorkspace: 1
    property var    openWorkspaces: [1]
    property var    openClients:        []
    property string peekedWindowAddress: ""
    property string activeWindowAddress: ""
    property var    windowIconCache:    ({})
    property var  appList:          []
    property bool appListLoaded:    false
    property bool appListLoading:   false
    property var  appUsage:         ({})
    property string searchMode:       "apps"
    property var  fileSearchResults:  []

    readonly property var _genericLauncherExecs: ["steam", "flatpak", "snap", "lutris",
        "heroic", "bottles", "wine", "wine64", "protontricks", "playonlinux",
        "appimagelauncher", "gamemoderun"]

    function _norm(s) { return (s || "").toLowerCase().replace(/[^a-z0-9]/g, ""); }

    function appEntryForCls(cls) {
        var norm = _norm(cls);
        if (!cls || !norm) return null;
        return _appByField("wmclass", norm) || _appByField("desktopId", norm) || _steamApp(cls) || _appByExecOrName(norm);
    }

    function _appByField(field, norm) {
        for (var i = 0; i < appList.length; i++) {
            if (_norm(appList[i][field]) === norm) return appList[i];
        }
        return null;
    }

    function _steamApp(cls) {
        var steamMatch = cls.match(/^steam_app_(\d+)$/i);
        if (!steamMatch) return null;
        var idRe = new RegExp("rungameid\\/" + steamMatch[1] + "(\\D|$)");
        for (var i = 0; i < appList.length; i++) {
            var app = appList[i];
            if (idRe.test(app.exec || "") || idRe.test(app.desktopId || "")) return app;
        }
        return null;
    }

    function _appByExecOrName(norm) {
        for (var i = 0; i < appList.length; i++) {
            var app = appList[i];
            var execBase = _norm((app.exec || "").split(" ")[0].split("/").pop());
            var nameNorm = _norm(app.name);
            if (_genericLauncherExecs.indexOf(execBase) !== -1) execBase = "";
            if (!execBase && !nameNorm) continue;
            if (_prefixOrSuffixMatch(norm, execBase) || _prefixOrSuffixMatch(norm, nameNorm)) return app;
        }
        return null;
    }

    function windowIconFromAppList(cls) {
        var app = appEntryForCls(cls);
        return app ? (app.icon || "") : "";
    }

    function _prefixOrSuffixMatch(a, b) {
        if (!a || !b) return false;
        if (a === b) return true;
        var shorter = a.length <= b.length ? a : b;
        var longer  = a.length <= b.length ? b : a;
        if (shorter.length < 4) return false;
        return longer.indexOf(shorter) === 0 ||
               longer.indexOf(shorter) === (longer.length - shorter.length);
    }

    function windowIconFor(cls) {
        if (!cls) return "";
        var fromApps = windowIconFromAppList(cls);
        if (fromApps) return fromApps;
        var cached = windowIconCache[cls];
        return cached ? cached : "";
    }

    function requestMissingWindowIcons() {
        var pending = [];
        var seen = {};
        for (var i = 0; i < openClients.length; i++) {
            var cls = openClients[i].cls;
            var pid = openClients[i].pid;
            if (!cls || seen[cls]) continue;
            seen[cls] = true;
            if (windowIconFromAppList(cls)) continue;
            if (Object.prototype.hasOwnProperty.call(windowIconCache, cls)) continue;
            pending.push(cls + "\t" + (pid || -1));
        }
        if (pending.length > 0) windowIconLookupProcess._doLookup(pending);
    }

    onOpenClientsChanged: requestMissingWindowIcons()

    function launchApp(app) {
        if (!app) return;
        recordAppLaunch(appUsageKey(app));
        if (app.internal) { openInternalApp(app.internal); return; }
        Quickshell.execDetached(["bash", "-c", app.exec]);
    }

    function recordAppLaunch(appName) {
        if (!appName || typeof appName !== "string" || appName.trim().length === 0) {
            console.warn("recordAppLaunch: invalid appName, not saving ->", JSON.stringify(appName));
            return;
        }
        appName = appName.trim();
        var u = JSON.parse(JSON.stringify(appUsage));
        u[appName] = (u[appName] || 0) + 1;
        appUsage = u;
        appUsageSaver.saveJson(JSON.stringify(u));
    }

    function runFileSearch(query) {
        fileSearchDebounceTimer.pendingQuery = query;
        fileSearchDebounceTimer.restart();
    }
}
