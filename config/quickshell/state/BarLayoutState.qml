import QtQuick

// Bar module layouts and the notch control-center / overview editor
AppsState {
    readonly property var barModuleKeys: ["control", "search", "audio", "clock", "workspaces", "windows", "gaming", "clipboard", "privacy", "notifications", "wifi", "bluetooth", "battery", "session"]
    property var barLayoutIsland: ["control", "search", "audio", "clock", "workspaces", "windows", "gaming", "clipboard", "privacy", "notifications", "wifi", "bluetooth", "battery", "session"]

    property var barLayoutNotch: ({
        left:   ["control", "search", "audio", "clock", "workspaces"],
        center: ["windows"],
        right:  ["privacy", "notifications", "gaming", "clipboard", "wifi", "bluetooth", "battery", "session"]
    })

    function _knownUnique(list, keys, seen) {
        return (Array.isArray(list) ? list : []).filter(function (k) {
            if (keys.indexOf(k) === -1 || seen[k]) return false;
            seen[k] = true;
            return true;
        });
    }

    function sanitizeBarLayouts() {
        barLayoutIsland = _sanitizedIslandLayout(barModuleKeys);
        barLayoutNotch = _sanitizedNotchLayout(barModuleKeys);
    }

    function _sanitizedIslandLayout(keys) {
        var seen = {};
        var isl = _knownUnique(barLayoutIsland, keys, seen);
        keys.forEach(function (k) {
            if (seen[k]) return;
            if (k === "control") isl.unshift(k);
            else isl.push(k);
        });
        return isl;
    }

    function _sanitizedNotchLayout(keys) {
        var src = (barLayoutNotch && typeof barLayoutNotch === "object") ? barLayoutNotch : {};
        var seen = {};
        var out = { left: _knownUnique(src.left, keys, seen), center: _knownUnique(src.center, keys, seen), right: _knownUnique(src.right, keys, seen) };
        var defGroup = { windows: "center", gaming: "right", clipboard: "right", privacy: "right", notifications: "right", wifi: "right", bluetooth: "right", battery: "right", session: "right" };
        keys.forEach(function (k) {
            if (seen[k]) return;
            if (k === "control") { out.left.unshift(k); return; }
            out[defGroup[k] || "left"].push(k);
        });
        return out;
    }

    readonly property var  ncCcKeys: ["bright", "vol", "mic", "wifi", "bt", "dark", "dnd", "term", "shot", "rec", "perf", "saver", "plane", "eye"]
    readonly property var  ncCcSliderKeys: ["bright", "vol", "mic"]
    readonly property var  ncDashKeys: ["weather", "cal", "mon", "aud", "clip", "fetch"]
    readonly property int  ncCcMaxRows: 5
    property bool   ncEditMode:   false
    property string ncCcSelected: ""
    property var    ncCcRows:     ncCcDefaultRows()
    property var    ncDashOrder:  ncDashKeys.slice()

    readonly property var ncCcHidden: ncCcKeys.filter(function (k) {
        for (var r = 0; r < ncCcRows.length; r++)
            for (var i = 0; i < ncCcRows[r].length; i++) if (ncCcRows[r][i].k === k) return false;
        return true;
    })

    readonly property var ncDashHidden: ncDashKeys.filter(function (k) { return ncDashOrder.indexOf(k) === -1; })

    function ncCcDefaultRows() {
        return [
            [{ k: "bright", w: 1 }],
            [{ k: "vol", w: 1 }, { k: "mic", w: 1 }],
            [{ k: "wifi", w: 1 }, { k: "bt", w: 1 }],
            [{ k: "dark", w: 1 }, { k: "dnd", w: 1 }, { k: "term", w: 1 }, { k: "shot", w: 1 }, { k: "rec", w: 1 }],
            [{ k: "perf", w: 1 }, { k: "saver", w: 1 }, { k: "plane", w: 1 }, { k: "eye", w: 1 }]
        ];
    }

    function ncCcIsSlider(k) { return ncCcSliderKeys.indexOf(k) !== -1; }
    function ncCcRowSum(row) { var s = 0; for (var i = 0; i < row.length; i++) s += row[i].w; return s; }
    function ncCcClone()     { return ncCcRows.map(function (r) { return r.map(function (it) { return { k: it.k, w: it.w }; }); }); }

    function ncCcFind(rows, k) {
        for (var r = 0; r < rows.length; r++)
            for (var i = 0; i < rows[r].length; i++) if (rows[r][i].k === k) return { r: r, i: i };
        return null;
    }

    function ncCcNormRows(rows) {
        return rows.filter(function (r) { return r.length > 0; }).map(function (r) {
            var avg = ncCcRowSum(r) / r.length || 1;
            return r.map(function (it) { return { k: it.k, w: Math.round(it.w / avg * 1000) / 1000 }; });
        });
    }

    function ncCcCommit(rows) {
        ncCcRows = ncCcNormRows(rows);
        savePrefs();
    }

    function _sanitizedCcRows() {
        var seen = {}, out = [];
        (Array.isArray(ncCcRows) ? ncCcRows : []).forEach(function (row) {
            if (!Array.isArray(row)) return;
            var cur = [];
            row.forEach(function (it) {
                if (!it || ncCcKeys.indexOf(it.k) === -1 || seen[it.k]) return;
                seen[it.k] = true;
                var w = Number(it.w);
                if (!(w > 0)) w = 1;
                cur.push({ k: it.k, w: Math.max(0.05, Math.min(50, w)) });
            });
            if (cur.length) out.push(cur);
        });
        while (out.length > ncCcMaxRows) { var extra = out.pop(); out[out.length - 1] = out[out.length - 1].concat(extra); }
        return out;
    }

    function sanitizeNcLayout() {
        ncCcRows = ncCcNormRows(_sanitizedCcRows());
        ncDashOrder = _knownUnique(ncDashOrder, ncDashKeys, {});
    }

    function ncCcDrop(k, row, index, newRow) {
        var rows = ncCcClone(), p = ncCcFind(rows, k);
        if (!p) return;
        var item = rows[p.r].splice(p.i, 1)[0];
        if (newRow) {
            var after = rows.filter(function (x) { return x.length > 0; }).length + 1;
            if (after > ncCcMaxRows) return;
            item.w = 1;
            rows.splice(Math.max(0, Math.min(rows.length, row)), 0, [item]);
        } else {
            if (row < 0 || row >= rows.length) return;
            var t = rows[row];
            if (row !== p.r) item.w = t.length ? ncCcRowSum(t) / t.length : 1;
            t.splice(Math.max(0, Math.min(t.length, index)), 0, item);
        }
        ncCcCommit(rows);
    }

    function ncCcSetWeights(r, i, a, b) {
        var rows = ncCcClone();
        if (!rows[r] || !rows[r][i] || !rows[r][i + 1]) return;
        rows[r][i].w = Math.max(0.05, a);
        rows[r][i + 1].w = Math.max(0.05, b);
        ncCcCommit(rows);
    }

    function ncCcRemove(k) {
        var rows = ncCcClone(), p = ncCcFind(rows, k);
        if (!p) return;
        rows[p.r].splice(p.i, 1);
        if (ncCcSelected === k) ncCcSelected = "";
        ncCcCommit(rows);
    }

    function ncCcAdd(k) {
        if (ncCcKeys.indexOf(k) === -1 || ncCcFind(ncCcRows, k)) return;
        var rows = ncCcClone();
        var last = rows.length ? rows[rows.length - 1] : null;
        var lastIsButtons = !!last && last.every(function (it) { return !ncCcIsSlider(it.k); });
        if (!ncCcIsSlider(k) && lastIsButtons && last.length < 5) last.push({ k: k, w: ncCcRowSum(last) / last.length });
        else if (rows.length < ncCcMaxRows) rows.push([{ k: k, w: 1 }]);
        else {
            var t = rows[0];
            rows.forEach(function (r) { if (r.length < t.length) t = r; });
            t.push({ k: k, w: ncCcRowSum(t) / t.length });
        }
        ncCcCommit(rows);
    }

    function ncDashMove(k, dir) {
        var o = ncDashOrder.slice(), i = o.indexOf(k), j = i + dir;
        if (i === -1 || j < 0 || j >= o.length) return;
        o[i] = o[j]; o[j] = k;
        ncDashOrder = o; savePrefs();
    }

    function ncDashRemove(k) { ncDashOrder = ncDashOrder.filter(function (x) { return x !== k; }); savePrefs(); }

    function ncDashAdd(k) {
        if (ncDashKeys.indexOf(k) === -1 || ncDashOrder.indexOf(k) !== -1) return;
        ncDashOrder = ncDashOrder.concat([k]); savePrefs();
    }

    function closeControlPanels() { notchControlOpen = false; islandControlOpen = false; }

    function ncResetLayout(page) {
        if (page === 0) { ncCcRows = ncCcDefaultRows(); ncCcSelected = ""; }
        else ncDashOrder = ncDashKeys.slice();
        savePrefs();
    }
}
