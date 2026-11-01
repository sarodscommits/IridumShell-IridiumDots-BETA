import QtQuick
import Quickshell
import Quickshell.Io
import "SystemDisplay.js" as SD

// Display config via scripts/display_ctl.py: per-output drafts applied live and to
// ~/.config/hypr/monitors.lua; auto-reverts unless confirmed within 15 s
Item {
    id: dl
    property var monitors: []      // live `hyprctl monitors all -j`
    property var drafts: ({})      // output -> { res, rate, scale, position, vrr, disabled, mirror }
    property var applied: ({})     // output -> draft that is live right now
    property bool applying: false
    property bool confirming: false
    property int countdown: 0
    property string error: ""
    property var _revertTo: null
    property bool _reverting: false
    property bool _autoAfterRead: false

    readonly property bool loading: readProc.running
    readonly property bool dirty: JSON.stringify(drafts) !== JSON.stringify(applied)
    readonly property int enabledCount: {
        var n = 0;
        for (var i = 0; i < monitors.length; i++) { var d = drafts[monitors[i].name]; if (d && !d.disabled) n++; }
        return n;
    }

    function monitor(name) {
        for (var i = 0; i < monitors.length; i++) if (monitors[i].name === name) return monitors[i];
        return null;
    }
    function draft(name) { return drafts[name] || null; }

    function setField(name, key, value) {
        var d = drafts[name];
        if (!d || d[key] === value) return;
        if (key === "disabled" && value && enabledCount <= 1) return;   // never turn every output off
        var nd = Object.assign({}, d);
        nd[key] = value;
        if (key === "res") {
            var mon = monitor(name);
            var res = value === "auto" ? SD.nativeRes(mon) : value;
            if (nd.rate !== "auto" && SD.ratesFor(mon, res).indexOf(nd.rate) < 0) nd.rate = "auto";
        }
        var all = Object.assign({}, drafts);
        all[name] = nd;
        drafts = all;
    }

    function refresh() { if (!readProc.running) readProc.running = true; }
    function detect() { _autoAfterRead = true; refresh(); }
    function discard() { drafts = JSON.parse(JSON.stringify(applied)); }

    function _entries(src) {
        var out = [];
        for (var i = 0; i < monitors.length; i++) {
            var d = src[monitors[i].name];
            if (d) out.push(SD.entry(monitors[i], d));
        }
        return out;
    }
    function _run(src) {
        applying = true;
        error = "";
        applyProc.command = ["bash", "-c", "exec python3 \"" + scriptsDir + "/display_ctl.py\" apply \"$1\"", "qs-display", JSON.stringify(_entries(src))];
        applyProc.running = true;
    }
    function apply() {
        if (applying || !dirty) return;
        _revertTo = JSON.parse(JSON.stringify(applied));
        _reverting = false;
        _run(drafts);
    }
    function keep() {
        confirming = false;
        countdownTimer.stop();
        refresh();
    }
    function revert() {
        confirming = false;
        countdownTimer.stop();
        if (!_revertTo) return;
        drafts = _revertTo;
        _reverting = true;
        _run(drafts);
    }

    Process {
        id: readProc
        command: ["bash", "-c", "exec python3 \"" + scriptsDir + "/display_ctl.py\" read"]
        stdout: StdioCollector {
            onStreamFinished: {
                var r;
                try { r = JSON.parse(this.text); } catch (e) { return; }
                var mons = (r.monitors || []).slice().sort(function (a, b) { return a.x - b.x || a.y - b.y; });
                var saved = {};
                (r.saved || []).forEach(function (e) { if (e && e.output) saved[e.output] = e; });
                var ds = {};
                for (var i = 0; i < mons.length; i++) {
                    var m = mons[i];
                    var d = saved[m.name] ? SD.draftFromSaved(saved[m.name], m) : SD.draftFromLive(m);
                    ds[m.name] = dl._autoAfterRead ? SD.autoDraft(d) : d;
                }
                dl.monitors = mons;
                if (dl.confirming) return;
                if (dl._autoAfterRead) {
                    dl._autoAfterRead = false;
                    var base = {};
                    for (var j = 0; j < mons.length; j++) {
                        var mm = mons[j];
                        base[mm.name] = saved[mm.name] ? SD.draftFromSaved(saved[mm.name], mm) : SD.draftFromLive(mm);
                    }
                    dl.applied = base;
                } else {
                    dl.applied = JSON.parse(JSON.stringify(ds));
                }
                dl.drafts = ds;
            }
        }
    }

    Process {
        id: applyProc
        command: ["true"]
        property bool _ok: false
        stdout: SplitParser {
            onRead: (line) => {
                if (line === "APPLY:ok") applyProc._ok = true;
                else if (line.indexOf("ERRMSG:") === 0) dl.error = line.substring(7);
            }
        }
        onRunningChanged: {
            if (running) { _ok = false; return; }
            dl.applying = false;
            if (!_ok && dl.error === "") dl.error = "?";
            dl.applied = JSON.parse(JSON.stringify(dl.drafts));
            if (dl._reverting) { dl._reverting = false; dl.refresh(); return; }
            dl.countdown = 15;
            dl.confirming = true;
            countdownTimer.restart();
        }
    }

    Timer {
        id: countdownTimer
        interval: 1000; repeat: true
        onTriggered: {
            dl.countdown--;
            if (dl.countdown <= 0) dl.revert();
        }
    }
}
