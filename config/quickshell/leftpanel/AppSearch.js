.pragma library
// Launcher app search: usage order and fuzzy ranking

function byName(a, b) {
    var na = a.name.toLowerCase(), nb = b.name.toLowerCase();
    return na < nb ? -1 : (na > nb ? 1 : 0);
}

function sortByUsage(list, usage) {
    return list.sort(function (a, b) {
        var ua = usage(a), ub = usage(b);
        if (ub !== ua) return ub - ua;
        return a.name.toLowerCase() < b.name.toLowerCase() ? -1 : 1;
    });
}

function _pushBlock(out, label, glyph, items) {
    if (items.length === 0) return;
    out.push({ isHeader: true, inBlock: true, blockFirst: true, blockLast: false,
        name: label, icon: "", glyph: glyph });
    for (var bi = 0; bi < items.length; bi++) {
        out.push(Object.assign({}, items[bi], {
            inBlock: true, blockFirst: false, segFirst: bi === 0, blockLast: bi === items.length - 1
        }));
    }
}

function blocks(all, systemApps, apps, usage, labels) {
    var used = [];
    for (var i = 0; i < all.length && used.length < 6; i++)
        if (usage(all[i]) > 0) used.push(all[i]);
    var out = [];
    _pushBlock(out, labels[0], "", used);
    _pushBlock(out, labels[1], "", systemApps.slice().sort(byName));
    _pushBlock(out, labels[2], "", apps.slice().sort(byName));
    return out;
}

function levenshtein(a, b) {
    var m = a.length, n = b.length;
    var dp = [];
    for (var i = 0; i <= m; i++) {
        dp[i] = [i];
        for (var j = 1; j <= n; j++) {
            dp[i][j] = i === 0 ? j :
            a[i-1] === b[j-1] ? dp[i-1][j-1] :
            1 + Math.min(dp[i-1][j], dp[i][j-1], dp[i-1][j-1]);
        }
    }
    return dp[m][n];
}

function _typoScore(n, q) {
    var best = 999, wlen = q.length;
    for (var start = 0; start <= n.length - Math.max(1, wlen - 2); start++) {
        var dist = levenshtein(q, n.substr(start, wlen + 2));
        if (dist < best) best = dist;
    }
    var maxDist = q.length <= 4 ? 1 : q.length <= 7 ? 2 : 3;
    return best <= maxDist ? 100 - best * 30 : -1;
}

function fuzzyScore(name, q) {
    var n = name.toLowerCase();
    if (n === q) return 1000;
    if (n.indexOf(q) >= 0) return 500 + (100 - n.indexOf(q));
    var initials = n.split(/[\s\-_]/).map(function (w) { return w.charAt(0); }).join('');
    if (initials.indexOf(q) >= 0) return 300;
    var qi = 0;
    for (var ni = 0; ni < n.length && qi < q.length; ni++)
        if (n[ni] === q[qi]) qi++;
    if (qi === q.length) return 200 - (n.length - q.length);
    return q.length >= 3 ? _typoScore(n, q) : -1;
}

function rank(all, q) {
    var scored = [];
    for (var i = 0; i < all.length; i++) {
        var s = fuzzyScore(all[i].name, q);
        var kws = all[i].keywords || [];
        for (var k = 0; k < kws.length; k++) {
            var ks = fuzzyScore(kws[k], q);
            if (ks > 0 && ks - 50 > s) s = ks - 50;
        }
        if (s > 0) scored.push({ app: all[i], score: s });
    }
    scored.sort(function (a, b) { return b.score - a.score; });
    return scored.map(function (x) { return x.app; });
}
