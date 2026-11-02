import QtQuick
import Quickshell
import Quickshell.Io

// Infinite desktop canvas, magnet, parallax settings and calendar events
WallpaperServices {
    property alias calEventsLoader: calEventsLoader

    function setCanvasInvertPan(on) {
      on = !!on;
      if (globalState.canvasInvertPan !== on) {
        globalState.canvasInvertPan = on;
        savePrefs();
      }
      syncCanvasInvertFile();
    }

    function syncCanvasInvertFile() {
      Quickshell.execDetached(["bash", "-c",
        "printf '%s' \"$1\" > $XDG_RUNTIME_DIR/infinite-desktop-state", "_",
        globalState.canvasInvertPan ? "inverse" : "normal"]);
      syncCanvasInertiaFile();
      syncMagnetFile();
    }

    function syncCanvasInertiaFile() {
      var cfg = JSON.stringify({
        enabled: globalState.canvasInertia,
        friction: Math.round(4.0 / Math.max(0.3, globalState.canvasInertiaTime) * 1000) / 1000,
        maxDist: globalState.canvasInertiaMaxDist
      });
      Quickshell.execDetached(["bash", "-c",
        "printf '%s' \"$1\" > $XDG_RUNTIME_DIR/infinite-desktop-inertia.tmp && mv -f $XDG_RUNTIME_DIR/infinite-desktop-inertia.tmp $XDG_RUNTIME_DIR/infinite-desktop-inertia",
        "_", cfg]);
    }

    function setCanvasInertia(on) {
      on = !!on;
      if (globalState.canvasInertia === on) return;
      globalState.canvasInertia = on;
      savePrefs();
      syncCanvasInertiaFile();
    }

    function setCanvasInertiaValue(prop, v) {
      if (prop === "canvasInertiaTime") v = Math.max(0.3, Math.min(2.0, v));
      else if (prop === "canvasInertiaMaxDist") v = Math.max(0.2, Math.min(1.0, v));
      else return;
      v = Math.round(v * 100) / 100;
      if (globalState[prop] !== v) globalState[prop] = v;
    }

    readonly property var magnetLimits: ({
      magnetGap:       [0, 30],
      magnetSnapDist:  [4, 40],
      magnetBreakAway: [5, 80],
      magnetBreakInto: [20, 150]
    })

    function syncMagnetFile() {
      var cfg = JSON.stringify({
        enabled:   globalState.magnetEnabled,
        move:      globalState.magnetMove,
        resize:    globalState.magnetResize,
        resnap:    globalState.magnetResnap,
        align:     globalState.magnetAlign,
        noAnim:    globalState.magnetNoAnim,
        gap:       globalState.magnetGap,
        snap:      globalState.magnetSnapDist,
        breakAway: globalState.magnetBreakAway,
        breakInto: globalState.magnetBreakInto
      });
      Quickshell.execDetached(["bash", "-c",
        "printf '%s' \"$1\" > $XDG_RUNTIME_DIR/infinite-desktop-magnet.tmp && mv -f $XDG_RUNTIME_DIR/infinite-desktop-magnet.tmp $XDG_RUNTIME_DIR/infinite-desktop-magnet",
        "_", cfg]);
    }

    function setMagnetBool(prop, on) {
      if (["magnetEnabled", "magnetMove", "magnetResize", "magnetResnap", "magnetAlign", "magnetNoAnim"].indexOf(prop) < 0) return;
      on = !!on;
      if (globalState[prop] === on) return;
      globalState[prop] = on;
      savePrefs();
      syncMagnetFile();
    }

    function setMagnetValue(prop, v) {
      var lim = magnetLimits[prop];
      if (!lim) return;
      v = Math.round(Math.max(lim[0], Math.min(lim[1], v)));
      if (globalState[prop] !== v) globalState[prop] = v;
    }

    function setParallaxWidgets(on) {
      if (globalState.parallaxWidgets === !!on) return;
      globalState.parallaxWidgets = !!on;
      savePrefs();
    }

    function setParallaxEnabled(on) {
      if (globalState.parallaxEnabled === !!on) return;
      globalState.parallaxEnabled = !!on;
      savePrefs();
    }

    function setParallaxValue(prop, v) {
      if (prop === "parallaxZoom") v = Math.max(1.1, Math.min(1.5, v));
      else if (prop === "parallaxStrength") v = Math.max(0.05, Math.min(0.4, v));
      else if (prop === "parallaxWidgetStrength") v = Math.max(0.2, Math.min(0.9, v));
      else return;
      v = Math.round(v * 100) / 100;
      if (globalState[prop] !== v) globalState[prop] = v;
    }

    Connections {
        target: globalState
        function onDesktopEditModeChanged() { if (!globalState.desktopEditMode) finishWallpaperProfileEdit(); }
    }

    Process {
        id: calEventsLoader
        command: ["bash", "-c",
        "f=\"$HOME/.config/quickshell/calendar-events.json\"; [ -f \"$f\" ] || exit 0; cat \"$f\""
        ]
        running: false
        property string _buf: ""
        stdout: SplitParser { onRead: (line) => { calEventsLoader._buf += line; } }
        onRunningChanged: {
            if (!running) {
                var raw = calEventsLoader._buf.trim();
                calEventsLoader._buf = "";
                if (!raw) return;
                try {
                    var data = JSON.parse(raw);
                    if (data && typeof data === "object") globalState.calendarEvents = data;
                } catch (e) {}
            }
        }
    }

    Process {
        id: calEventsSaver
        command: ["bash", "-c",
        "mkdir -p \"$HOME/.config/quickshell\" && cat > \"$HOME/.config/quickshell/calendar-events.json\""
        ]
        running: false
        stdinEnabled: true
        property bool _busy: false
        property string _pending: ""
        onRunningChanged: {
            if (!running) {
                calEventsSaver._busy = false;
                calEventsSaver.stdinEnabled = true;
                if (calEventsSaver._pending !== "") {
                    var p = calEventsSaver._pending;
                    calEventsSaver._pending = "";
                    calEventsSaver._doSave(p);
                }
            }
        }
        function _doSave(json) {
            if (calEventsSaver._busy) { calEventsSaver._pending = json; return; }
            calEventsSaver._busy = true;
            calEventsSaver.running = true;
            calEventsSaver.write(json);
            calEventsSaver.stdinEnabled = false;
        }
    }

    function saveCalendarEvents() {
        calEventsSaver._doSave(JSON.stringify(globalState.calendarEvents));
    }

    function addCalendarEvent(dateKey, title, type) {
        if (!title || title.trim() === "") return;
        var evs = Object.assign({}, globalState.calendarEvents);
        var arr = evs[dateKey] ? evs[dateKey].slice() : [];
        arr.push({ title: title.trim(), type: type });
        evs[dateKey] = arr;
        globalState.calendarEvents = evs;
        saveCalendarEvents();
    }

    function removeCalendarEvent(dateKey, index) {
        var evs = Object.assign({}, globalState.calendarEvents);
        if (!evs[dateKey]) return;
        var arr = evs[dateKey].slice();
        arr.splice(index, 1);
        if (arr.length > 0) evs[dateKey] = arr; else delete evs[dateKey];
        globalState.calendarEvents = evs;
        saveCalendarEvents();
    }

    function allCalendarEventsSorted() {
        var out = [];
        var evs = globalState.calendarEvents;
        for (var key in evs) {
            var parts = key.split("-");
            var y = parseInt(parts[0], 10), m = parseInt(parts[1], 10), d = parseInt(parts[2], 10);
            var dateObj = new Date(y, m, d);
            var arr = evs[key];
            for (var i = 0; i < arr.length; i++) {
                out.push({
                    dateKey: key,
                    indexInDay: i,
                    dateLabel: dateObj.toLocaleDateString(Qt.locale(localeCode()), "d MMM"),
                    title: arr[i].title,
                    type: arr[i].type,
                    _sortTime: dateObj.getTime()
                });
            }
        }
        out.sort(function(a, b) { return a._sortTime - b._sortTime; });
        return out;
    }
}
