import QtQuick
import Quickshell
import Quickshell.Hyprland

QtObject {
    readonly property string scriptsDir: Quickshell.env("HOME") + "/.config/hypr/scripts"

    function sortedForWorkspace(win, ws) {
        var order = win.gs.focusOrder || [];
        var list = win.gs.openClients.filter(function (c) { return c.workspace === ws; });
        list.sort(function (a, b) {
            var ia = order.indexOf(a.address), ib = order.indexOf(b.address);
            if (ia < 0) ia = 9999;
            if (ib < 0) ib = 9999;
            return ia !== ib ? ia - ib : (a.address < b.address ? -1 : 1);
        });
        return list;
    }

    function toplevelFor(win, c) {
        var want = (c.address || "").toLowerCase().replace(/^0x/, "");
        var vals = Hyprland.toplevels.values;
        var fallback = null;
        for (var i = 0; i < vals.length; i++) {
            var t = vals[i];
            var ta = (t.address || "").toLowerCase().replace(/^0x/, "");
            if (want !== "" && ta === want) return t.wayland;
            if (t.wayland && t.wayland.appId === c.cls && fallback === null) fallback = t.wayland;
        }
        return fallback;
    }

    function peekAll(win) {
        var addrs = [];
        for (var i = 0; i < win.items.length; i++) if (win.items[i].floating) addrs.push(win.items[i].address);
        if (addrs.length > 0) win.gs.peekWindowsInstant(addrs);
    }

    function finish(win, chosen, wsTarget) {
        if (wsTarget === undefined) wsTarget = -1;
        var others = [];
        for (var i = 0; i < win.items.length; i++) if (win.items[i].address !== chosen) others.push(win.items[i].address);
        win.gs.windowSwitcherOpen = false;
        Quickshell.execDetached(["bash", "-c",
            "exec 9>$XDG_RUNTIME_DIR/qs_peek_noanim.lock; flock 9; " +
            "hyprctl eval 'hl.animation({ leaf = \"windowsMove\", enabled = false })' >/dev/null 2>&1; " +
            "C=\"$1\"; W=\"$2\"; shift 2; " +
            "if [ -z \"$C\" ]; then for a in \"$@\"; do /usr/bin/python3 " + scriptsDir + "/peek_window.py restore \"$a\"; done; fi; " +
            "if [ -n \"$C\" ]; then " +
            "  /usr/bin/python3 " + scriptsDir + "/switcher_pan.py \"$C\"; " +
            "fi; " +
            "if [ \"$W\" -ge 0 ] 2>/dev/null; then hyprctl dispatch \"hl.dsp.focus({ workspace = $W })\" >/dev/null 2>&1; fi; " +
            "hyprctl eval 'hl.animation({ leaf = \"windowsMove\", enabled = true, speed = 6, spring = \"elasticSmoth\" })' >/dev/null 2>&1",
            "qs-switch", chosen, String(wsTarget)].concat(others));
    }

    function activate(win, i) {
        if (i < 0 || i >= win.items.length) { finish(win, ""); return; }
        finish(win, win.items[i].address);
    }

    function closeWindow(win, i) {
        var c = win.items[i];
        if (!c) return;
        Quickshell.execDetached(["bash", "-c",
            "/usr/bin/python3 " + scriptsDir + "/peek_window.py cancel \"$1\"; " +
            "hyprctl dispatch \"hl.dsp.window.focus(\\\"address:$1\\\")\" && hyprctl dispatch 'hl.dsp.window.close()'",
            "qs-switch-close", c.address]);
        var l = win.items.slice();
        l.splice(i, 1);
        win.items = l;
        if (win.items.length === 0) finish(win, "");
        else win.select(Math.min(win.selected, win.items.length - 1));
    }

    function runRestore(win, addrs) {
        if (!addrs || addrs.length === 0) return;
        Quickshell.execDetached(["bash", "-c",
            "exec 9>$XDG_RUNTIME_DIR/qs_peek_noanim.lock; flock 9; " +
            "hyprctl eval 'hl.animation({ leaf = \"windowsMove\", enabled = false })' >/dev/null 2>&1; " +
            "for a in \"$@\"; do /usr/bin/python3 " + scriptsDir + "/peek_window.py restore \"$a\"; done; " +
            "hyprctl eval 'hl.animation({ leaf = \"windowsMove\", enabled = true, speed = 6, spring = \"elasticSmoth\" })' >/dev/null 2>&1",
            "qs-switch-restore"].concat(addrs));
    }

    function refreshItems(win) {
        if (!win.open) return;
        var nl = sortedForWorkspace(win, win.gs.activeWorkspace);
        var same = nl.length === win.items.length;
        for (var i = 0; same && i < nl.length; i++) if (nl[i].address !== win.items[i].address) same = false;
        if (same) return;
        var keep = win.items[win.selected] ? win.items[win.selected].address : "";
        var oldAddrs = win.items.map(function (c) { return c.address; });
        win.items = nl;
        var ni = -1;
        for (var k = 0; k < nl.length; k++) if (nl[k].address === keep) ni = k;
        win.selected = ni >= 0 ? ni : 0;
        win.currentPage = win.pageOf[win.selected] || 0;
        var fresh = [];
        for (var q = 0; q < nl.length; q++) if (nl[q].floating && oldAddrs.indexOf(nl[q].address) < 0) fresh.push(nl[q].address);
        if (fresh.length) win.gs.peekWindowsInstant(fresh);
        win.warm = true; win.warmTimer.restart();
    }

    function onWorkspaceChanged(win) {
        if (!win.open || win.gs.activeWorkspace === win.shownWs) return;
        runRestore(win, win.items.map(function (c) { return c.address; }));
        win.shownWs = win.gs.activeWorkspace;
        win.wsSel = Math.max(0, win.wsList.indexOf(win.gs.activeWorkspace));
        win.snapshot();
        win.selected = 0;
        win.currentPage = win.pageOf[0] || 0;
        peekAll(win);
        win.warm = true;
        win.warmTimer.restart();
    }
}
