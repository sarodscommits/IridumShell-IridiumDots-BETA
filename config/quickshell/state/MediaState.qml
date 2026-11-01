import QtQuick

// Media/lyrics, notifications and clipboard
WindowsState {
    property string clipKind:         ""
    property string clipText:         ""
    property string clipImagePath:    ""
    property string clipImageMime:    ""
    property int    clipImageBytes:   0
    property var    clipFiles:        []
    property string clipSig:          ""
    property string clipDismissedSig: ""
    property bool   clipBulgeOpen:    false
    property bool   clipAutoOpened:   false
    property bool   clipEditing:      false
    property bool   clipDragHover:    false
    property bool   clipDraggingOut:  false
    property bool   clipOpenOnNext:   false
    property bool   clipPinned:       true
    property bool   clipClearing:     false
    readonly property bool clipHasContent: clipKind === "text" || clipKind === "image" || clipKind === "files"

    function clipBulgeBusy() {
        return powerMenuOpen || windowPreviewOpen || notchMediaOpen || notchSearchOpen || islandSearchOpen ||
               wsPreviewOpen || netBulgeOpen || islandControlOpen || notchControlOpen ||
               privBulgeOpen || battBulgeOpen || desktopEditMode || lockScreenActive || recBulgeOpen;
    }

    function openClipBulge(auto) {
        if (lockScreenActive || !barModules.clipboard || !clipHasContent) return;
        if (auto && clipBulgeBusy()) return;
        if (!auto) closeOthers("clip");
        clipAutoOpened = auto;
        clipBulgeOpen = true;
    }

    property bool   dndEnabled:      false
    property bool   notifClearing:      false
    property var    notifClearSnapshot: []
    property var    notifExpanded:      ({})

    function dismissNotifications(list) {
        var v = (list || []).slice();
        for (var i = 0; i < v.length; i++) {
            try { if (v[i]) v[i].dismiss(); }
            catch (e) { console.warn("[notifs] couldn't dismiss a notification:", e); }
        }
    }

    function clearAllNotifications() {
        if (notifClearing) return;
        var v = notificationsBackend.trackedNotifications.values.slice();
        if (v.length === 0) return;
        playUiSound("5");
        notifClearSnapshot = v;
        notifClearing = true;
        notifClearTimer.restart();
    }

    function toggleNotifGroup(key) {
        var m = Object.assign({}, notifExpanded);
        m[key] = !m[key];
        notifExpanded = m;
    }

    function groupNotifications(vals) {
        var groups = [], byKey = {};
        for (var i = 0; i < vals.length; i++) {
            var n = vals[i];
            if (!n) continue;
            var name = n.appName || n.desktopEntry || "";
            var key = (name || "?").toLowerCase();
            var g = byKey[key];
            if (!g) { g = { key: key, appName: name, items: [] }; byKey[key] = g; groups.push(g); }
            g.items.push(n);
        }
        return groups;
    }

    property string notificationSoundPath:   ""
    property var    notificationSoundList:   []
    property bool   notificationSoundLoaded: false
    property real   notificationSoundVolume: 100
    property bool   notificationSoundExpanded: false
    property var    clipHistory:    []
    property string mediaTitle:    ""
    property string mediaArtist:   ""
    property string mediaArtUrl:   ""
    property string mediaArtColor: ""
    property string mediaStatus:   "Stopped"
    property real   mediaPosition: 0.0
    property int    mediaPosSeconds: 0
    property int    mediaDurSeconds: 0
    property var    mediaLyrics:        []
    property bool   mediaLyricsSynced:  false
    property string mediaLyricsSource:  ""
    property bool   mediaLyricsLoading: false
    property int    mediaLyricIndex:    -1
    property real   mediaLyricProgress: 0
    property string musicBarView:       "eq"
    property bool   lyricsOnlineFallback: true
    readonly property bool mediaHasLyrics: mediaLyrics.length > 0

    function lyricNow() {
        if (!mediaLyricsSynced || mediaLyricIndex < 0 || mediaLyricIndex >= mediaLyrics.length) return "";
        var t = mediaLyrics[mediaLyricIndex].s;
        return t !== "" ? t : "♪";
    }

    function lyricAt(off) {
        var L = mediaLyrics, i = (mediaLyricsSynced ? mediaLyricIndex : 0) + off;
        if (!mediaLyricsSynced && mediaLyricIndex < 0 && off < 0) return "";
        return i >= 0 && i < L.length ? L[i].s : "";
    }

    property var    cavaBars: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    property real   wavePhase: 0
}
