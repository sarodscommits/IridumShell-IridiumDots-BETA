import QtQuick
import Quickshell
import Quickshell.Io

// Per-wallpaper profiles: snapshots, switching and editing
PrefsServices {
    property alias profileLoader: profileLoader
    property alias profileStore: profileStore

    QtObject {
        id: profileStore
        property bool   loaded: false
        property var    defaultSnap: null
        property var    profiles: ({})
        property string active: ""
        property string editing: ""
        property bool   editExisted: false
        property var    editPreSnap: null
        property bool   discardOnExit: false
        function has(path) { return !!path && Object.prototype.hasOwnProperty.call(profiles, path); }
        function setProfile(path, snap) {
            var p = Object.assign({}, profiles);
            if (snap) p[path] = snap; else delete p[path];
            profiles = p;
        }
        function recordLive(obj) {
            if (!loaded) return;
            var snap = profileSnapshot(obj);
            if (active !== "" && has(active)) setProfile(active, snap);
            else defaultSnap = snap;
            persist();
        }
        function persist() { if (loaded) profileSaveDebounce.restart(); }
    }

    Timer {
        id: profileSaveDebounce
        interval: 400; repeat: false
        onTriggered: profileSaver._doSave(JSON.stringify({
            version: 1,
            active: profileStore.active,
            "default": profileStore.defaultSnap,
            profiles: profileStore.profiles
        }))
    }

    Process {
        id: profileSaver
        command: ["bash", "-c",
        "d=\"$HOME/.config/quickshell\"; mkdir -p \"$d\" && cat > \"$d/wallpaper-profiles.json.tmp\" && mv \"$d/wallpaper-profiles.json.tmp\" \"$d/wallpaper-profiles.json\""
        ]
        running: false
        stdinEnabled: true
        property bool _busy: false
        property string _pending: ""
        onRunningChanged: {
            if (!running) {
                profileSaver._busy = false;
                profileSaver.stdinEnabled = true;
                if (profileSaver._pending !== "") {
                    var p = profileSaver._pending;
                    profileSaver._pending = "";
                    profileSaver._doSave(p);
                }
            }
        }
        function _doSave(json) {
            if (profileSaver._busy) { profileSaver._pending = json; return; }
            profileSaver._busy = true;
            profileSaver.running = true;
            profileSaver.write(json);
            profileSaver.stdinEnabled = false;
        }
    }

    Process {
        id: profileLoader
        command: ["bash", "-c", "f=\"$HOME/.config/quickshell/wallpaper-profiles.json\"; [ -f \"$f\" ] && cat \"$f\"; true"]
        running: false
        property string _buf: ""
        stdout: SplitParser { onRead: (line) => { profileLoader._buf += line; } }
        onRunningChanged: {
            if (running) { profileLoader._buf = ""; return; }
            var raw = profileLoader._buf.trim();
            profileLoader._buf = "";
            try {
                if (raw) {
                    var d = JSON.parse(raw);
                    if (d.profiles && typeof d.profiles === "object") profileStore.profiles = d.profiles;
                    if (d["default"] && typeof d["default"] === "object") profileStore.defaultSnap = d["default"];
                    if (typeof d.active === "string" && profileStore.has(d.active)) profileStore.active = d.active;
                }
            } catch (e) { console.warn("[perfiles] wallpaper-profiles.json ilegible:", e); }
            if (profileStore.active === "" && !profileStore.defaultSnap) profileStore.defaultSnap = profileSnapshot();
            profileStore.loaded = true;
            Qt.callLater(pruneMissingProfiles);
        }
    }

    function stripProfileGlobals(o) {
        if (!o) return o;
        delete o.pinnedApps;
        delete o.notificationSoundPath;
        delete o.notificationSoundVolume;
        delete o.colorMode;
        delete o.eyeCare;
        delete o.ncCcRows;
        delete o.ncDashOrder;
        delete o.ncCcKeysSeen;
        delete o.recFps;
        delete o.recResolution;
        delete o.recRegion;
        delete o.recMic;
        delete o.gamingEscOnOpen;
        delete o.gamingModules;
        delete o.gamingFloating;
        delete o.gamingFloatX;
        delete o.gamingFloatY;
        delete o.gamingFloatOpacity;
        delete o.termPaletteMode;
        delete o.uiSoundsEnabled;
        delete o.powerConfirmEnabled;
        delete o.powerConfirmSeconds;
        delete o.powerConfirmShowOthers;
        delete o.canvasInvertPan;
        delete o.canvasInertia;
        delete o.canvasInertiaTime;
        delete o.canvasInertiaMaxDist;
        for (var mgP in o) {
            if (Object.prototype.hasOwnProperty.call(o, mgP) && mgP.indexOf("magnet") === 0) delete o[mgP];
        }
        for (var k in o) {
            if (Object.prototype.hasOwnProperty.call(o, k) && k.indexOf("lock") === 0) delete o[k];
        }
        return o;
    }

    function profileSnapshot(obj) {
        return stripProfileGlobals(JSON.parse(JSON.stringify(obj || collectPrefs())));
    }

    function profileName(path) {
        return (path || "").split("/").pop().replace(/\.[^.]+$/, "");
    }

    function paletteSig() {
        return [globalState.paletteSource, globalState.presetPaletteKey, globalState.presetApplyKitty,
                globalState.presetApplyQuickshell, globalState.colorMode].join("|");
    }

    function applyProfileSnapshot(snap, viaWallpaper) {
        if (!snap) return;
        globalState.profileMorphing = true;
        profileMorphTimer.restart();
        var prevKitty = currentKittyOpacity();
        var prevPal = paletteSig();
        globalState.closeAll(true);
        applyPrefsData(stripProfileGlobals(JSON.parse(JSON.stringify(snap))));
        appearanceApplyProcess.queue(globalState.borderSize, globalState.shadowEnabled, globalState.shadowRange,
            globalState.shadowIntensity, currentKittyOpacity(), globalState.cornerRounding, globalState.layoutMode,
            globalState.allFloating, currentKittyOpacity() !== prevKitty);
        colorExtraction.reload();
        if (!viaWallpaper && paletteSig() !== prevPal) {
            if (globalState.paletteSource === "preset") {
                if (globalState.presetApplyKitty) applyPresetKittyColors(); else restorePywalKittyColors();
                if (!globalState.presetApplyQuickshell) restoreMatugenColors();
            } else {
                restorePywalKittyColors();
                restoreMatugenColors();
            }
        }
    }

    function switchProfileForWallpaper(path) {
        if (!profileStore.loaded) return;
        var target = profileStore.has(path) ? path : "";
        if (target === profileStore.active) return;
        profileStore.recordLive(collectPrefs());
        profileStore.active = target;
        var snap = target !== "" ? profileStore.profiles[target] : profileStore.defaultSnap;
        if (snap) applyProfileSnapshot(snap, true);
        savePrefs();
    }

    function profileBarSig(o) {
        if (!o) return "";
        return JSON.stringify([o.topBarPosition, o.shellMode, o.barModules, o.barLayoutIsland, o.barLayoutNotch,
                               o.islandAutoHide, o.fontPrimaryKey, o.fontSecondaryKey, o.fontScale]);
    }

    function applyWallpaperSmooth(path) {
        if (profileFadeOutTimer.running) { profileFadeOutTimer.path = path; return; }
        if (profileStore.loaded && !globalState.desktopEditMode && !globalState.frameEffectivelyHidden) {
            var target = profileStore.has(path) ? path : "";
            if (target !== profileStore.active) {
                var snap = target !== "" ? profileStore.profiles[target] : profileStore.defaultSnap;
                if (snap && profileBarSig(snap) !== profileBarSig(collectPrefs())) {
                    globalState.profileFrameAnim = true;
                    globalState.profileFrameFade = true;
                    profileFadeOutTimer.path = path;
                    profileFadeOutTimer.restart();
                    return;
                }
            }
        }
        applyWallpaper(path);
    }

    Timer {
        id: profileFadeOutTimer
        property string path: ""
        interval: 300; repeat: false
        onTriggered: { applyWallpaper(path); profileFadeInTimer.restart(); }
    }

    Timer {
        id: profileFadeInTimer
        interval: 220; repeat: false
        onTriggered: { globalState.profileFrameFade = false; profileFrameAnimTimer.restart(); }
    }

    Timer {
        id: profileFrameAnimTimer
        interval: 520; repeat: false
        onTriggered: globalState.profileFrameAnim = false
    }

    Timer {
        id: profileMorphTimer
        interval: 900; repeat: false
        onTriggered: globalState.profileMorphing = false
    }

    function cycleProfile(dir) {
        if (!profileStore.loaded || globalState.lockScreenActive) return;
        if (globalState.desktopEditMode) return;
        var keys = Object.keys(profileStore.profiles).sort(function(a, b) {
            var na = profileName(a).toLowerCase(), nb = profileName(b).toLowerCase();
            return na < nb ? -1 : (na > nb ? 1 : 0);
        });
        if (keys.length === 0) {
            Quickshell.execDetached(["notify-send", tr("profile_title"), tr("profile_none")]);
            return;
        }
        var i = keys.indexOf(globalState.currentWallpaper);
        var next = i < 0 ? (dir > 0 ? 0 : keys.length - 1)
                         : (i + (dir > 0 ? 1 : -1) + keys.length) % keys.length;
        if (keys[next] === globalState.currentWallpaper) return;
        applyWallpaperSmooth(keys[next]);
    }

    function startWallpaperProfileEdit(path) {
        if (!path || globalState.lockScreenActive || !profileStore.loaded) return;
        if (globalState.desktopEditMode) globalState.toggleDesktopEditMode();
        if (globalState.currentWallpaper !== path) applyWallpaper(path);
        else switchProfileForWallpaper(path);
        profileStore.editExisted = profileStore.has(path);
        profileStore.editPreSnap = profileSnapshot();
        if (!profileStore.editExisted) {
            profileStore.recordLive(collectPrefs());
            profileStore.setProfile(path, profileStore.editPreSnap);
            profileStore.active = path;
            profileStore.persist();
        }
        profileStore.discardOnExit = false;
        profileStore.editing = path;
        globalState.wallpaperPickerOpen = false;
        globalState.toggleDesktopEditMode();
    }

    function finishWallpaperProfileEdit() {
        var path = profileStore.editing;
        if (path === "") return;
        profileStore.editing = "";
        if (profileStore.discardOnExit) {
            profileStore.discardOnExit = false;
            if (profileStore.editExisted) {
                profileStore.setProfile(path, profileStore.editPreSnap);
                if (profileStore.active === path) applyProfileSnapshot(profileStore.editPreSnap, false);
            } else {
                profileStore.setProfile(path, null);
                if (profileStore.active === path) {
                    profileStore.active = "";
                    if (profileStore.defaultSnap) applyProfileSnapshot(profileStore.defaultSnap, false);
                }
            }
            savePrefs();
            Quickshell.execDetached(["notify-send", tr("profile_title"), tr("profile_discarded")]);
        } else {
            savePrefs();
            Quickshell.execDetached(["notify-send", tr("profile_title"), tr("profile_saved") + " " + profileName(path)]);
        }
        profileStore.editPreSnap = null;
        profileStore.persist();
    }

    function deleteWallpaperProfile(path) {
        if (!profileStore.has(path)) return;
        if (profileStore.editing === path) profileStore.editing = "";
        var wasActive = profileStore.active === path;
        profileStore.setProfile(path, null);
        if (wasActive) {
            profileStore.active = "";
            if (profileStore.defaultSnap) applyProfileSnapshot(profileStore.defaultSnap, false);
            savePrefs();
        }
        profileStore.persist();
    }

    function pruneMissingProfiles() {
        if (!profileStore.loaded || !globalState.wallpaperLoaded) return;
        var list = globalState.wallpaperList || [];
        if (list.length === 0) return;
        var present = {};
        for (var i = 0; i < list.length; i++) present[list[i].path] = true;
        var gone = Object.keys(profileStore.profiles).filter(function(k) { return !present[k]; });
        if (gone.length === 0) return;
        for (var j = 0; j < gone.length; j++) {
            console.log("[perfiles] wallpaper eliminado, se borra su perfil:", gone[j]);
            deleteWallpaperProfile(gone[j]);
        }
        Quickshell.execDetached(["notify-send", tr("profile_title"),
            tr("profile_removed") + " " + gone.map(profileName).join(", ")]);
    }
}
