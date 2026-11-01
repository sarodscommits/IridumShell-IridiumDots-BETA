.pragma library

// Splits the aspect ratios 'a' into 'r' consecutive rows with similar aspect sums.
function partition(a, r) {
    var total = 0;
    for (var k = 0; k < a.length; k++) total += a[k];
    var rows = [], cur = [], acc = 0, ri = 0;
    for (var i = 0; i < a.length; i++) {
        var remItems = a.length - i, remRows = r - ri;
        cur.push(i); acc += a[i];
        var close = ri < r - 1 && (acc >= total * (ri + 1) / r || remItems - 1 === remRows - 1);
        if (close) { rows.push(cur); cur = []; ri++; }
    }
    if (cur.length) rows.push(cur);
    return rows;
}

// Justified page layout: keeps the row count covering the most area
function layoutPage(win, idxs, W, H) {
    var items = win.items, gap = win.gap, aspMin = win.aspMin, aspMax = win.aspMax;
    var n = idxs.length;
    var a = idxs.map(function (ix) {
        var c = items[ix];
        var r = (c.w > 0 && c.h > 0) ? c.w / c.h : 1.6;
        return Math.max(aspMin, Math.min(aspMax, r));
    });
    var maxRowH = H * 0.75;
    var best = null;
    for (var r = 1; r <= n; r++) {
        var rows = partition(a, r);
        var hs = [], tot = 0, area = 0, sums = [];
        for (var ri = 0; ri < rows.length; ri++) {
            var sum = 0;
            for (var k = 0; k < rows[ri].length; k++) sum += a[rows[ri][k]];
            var h = Math.min(maxRowH, (W - gap * (rows[ri].length - 1)) / sum);
            hs.push(h); sums.push(sum); tot += h;
        }
        tot += gap * (rows.length - 1);
        var s = Math.min(1, H / tot);
        for (var q = 0; q < rows.length; q++) area += sums[q] * hs[q] * hs[q] * s * s;
        if (!best || area > best.area) best = { rows: rows, hs: hs, s: s, area: area, tot: tot * s };
    }
    var tiles = [];
    var y = (H - best.tot) / 2;
    for (var rr = 0; rr < best.rows.length; rr++) {
        var h2 = best.hs[rr] * best.s;
        var rw = gap * (best.rows[rr].length - 1);
        for (var kk = 0; kk < best.rows[rr].length; kk++) rw += a[best.rows[rr][kk]] * h2;
        var x = (W - rw) / 2;
        for (var kk2 = 0; kk2 < best.rows[rr].length; kk2++) {
            var li = best.rows[rr][kk2];
            var w2 = a[li] * h2;
            tiles.push({ i: idxs[li], c: items[idxs[li]], x: x, y: y, w: w2, h: h2, row: rr });
            x += w2 + gap;
        }
        y += h2 + best.s * gap;
    }
    return { tiles: tiles };
}

// Paginates win.items and recomputes the selection
function relayout(win) {
    var n = win.items.length;
    if (n === 0 || win.pageW <= 0) { win.pages = []; win.pageOf = []; return; }
    var pc = Math.ceil(n / win.perPageMax);
    var size = Math.ceil(n / pc);
    var out = [], po = [];
    for (var p = 0; p < pc; p++) {
        var idxs = [];
        for (var i = p * size; i < Math.min(n, (p + 1) * size); i++) { idxs.push(i); po[i] = p; }
        out.push(layoutPage(win, idxs, win.pageW, win.pageH));
    }
    win.pages = out;
    win.pageOf = po;
    if (win.selected >= n) win.selected = n - 1;
    win.currentPage = po[win.selected] || 0;
}
