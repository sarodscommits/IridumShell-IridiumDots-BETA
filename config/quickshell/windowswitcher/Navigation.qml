import QtQuick
import Quickshell

QtObject {
    function select(win, i) {
        if (win.items.length === 0) return;
        win.selected = (i + win.items.length) % win.items.length;
        win.currentPage = win.pageOf[win.selected] || 0;
    }

    function stepPage(win, d) {
        if (win.pages.length < 2) return;
        var p = (win.currentPage + d + win.pages.length) % win.pages.length;
        win.currentPage = p;
        var t = win.pages[p].tiles;
        if (t.length > 0) win.selected = t[0].i;
    }

    function moveVertical(win, d) {
        var pg = win.pages[win.currentPage];
        if (!pg) return;
        var cur = null;
        for (var k = 0; k < pg.tiles.length; k++) if (pg.tiles[k].i === win.selected) cur = pg.tiles[k];
        if (!cur) return;
        var best = null, bd = 1e9;
        for (var q = 0; q < pg.tiles.length; q++) {
            var t = pg.tiles[q];
            if (t.row !== cur.row + d) continue;
            var dx = Math.abs((t.x + t.w / 2) - (cur.x + cur.w / 2));
            if (dx < bd) { bd = dx; best = t; }
        }
        if (best) win.selected = best.i;
    }

    function switchWorkspace(win, id) {
        if (id === win.gs.activeWorkspace) return;
        Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + id + " })"]);
    }
}
