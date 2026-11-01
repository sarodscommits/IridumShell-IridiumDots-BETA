.pragma library
// Pure helpers for Settings > System > Displays (no QML scope access).

// 20 predefined resolutions, largest first
var presets = [
    "7680x4320", "5120x2880", "5120x1440", "3840x2160", "3840x1600",
    "3440x1440", "2880x1800", "2560x1600", "2560x1440", "2560x1080",
    "2048x1152", "1920x1200", "1920x1080", "1680x1050", "1600x900",
    "1440x900", "1366x768", "1280x1024", "1280x800", "1280x720"
];

function rateStr(r) { return Number(r).toFixed(2); }

// "1920x1080@119.88Hz" -> [{ res: "1920x1080", rate: "119.88" }]
function modes(mon) {
    var out = [], seen = {};
    var list = (mon && mon.availableModes) || [];
    for (var i = 0; i < list.length; i++) {
        var m = /^(\d+x\d+)@([\d.]+)/.exec(list[i]);
        if (!m) continue;
        var k = m[1] + "@" + rateStr(m[2]);
        if (seen[k]) continue;
        seen[k] = true;
        out.push({ res: m[1], rate: rateStr(m[2]) });
    }
    return out;
}

function area(res) { var p = res.split("x"); return (+p[0]) * (+p[1]); }

function supportedRes(mon) {
    var ms = modes(mon), out = [];
    for (var i = 0; i < ms.length; i++) if (out.indexOf(ms[i].res) < 0) out.push(ms[i].res);
    return out;
}

// Native = the monitor's preferred (first listed) mode; falls back to the largest
function nativeRes(mon) {
    var ms = modes(mon);
    if (ms.length) return ms[0].res;
    return mon ? mon.width + "x" + mon.height : "1920x1080";
}

// Refresh rates available for a resolution, highest first
function ratesFor(mon, res) {
    var ms = modes(mon), out = [];
    for (var i = 0; i < ms.length; i++) if (ms[i].res === res && out.indexOf(ms[i].rate) < 0) out.push(ms[i].rate);
    out.sort(function (a, b) { return (+b) - (+a); });
    return out;
}

function closestRate(rates, r) {
    if (!rates.length) return rateStr(r);
    var best = rates[0];
    for (var i = 1; i < rates.length; i++) if (Math.abs(rates[i] - r) < Math.abs(best - r)) best = rates[i];
    return best;
}

function draftFromLive(mon) {
    var res = mon.width + "x" + mon.height;
    return {
        res: res,
        rate: closestRate(ratesFor(mon, res), mon.refreshRate),
        scale: Math.round(mon.scale * 100) / 100,
        position: mon.x + "x" + mon.y,
        vrr: mon.vrr ? 1 : 0,
        disabled: !!mon.disabled,
        mirror: ""
    };
}

function draftFromSaved(e, mon) {
    var m = /^(\d+x\d+)@([\d.]+)/.exec(e.mode || "");
    var d = draftFromLive(mon);
    if (m) { d.res = m[1]; d.rate = rateStr(m[2]); }
    if (e.res_auto) d.res = "auto";
    if (e.rate_auto) d.rate = "auto";
    if (e.scale !== undefined) d.scale = e.scale;
    if (e.position) d.position = e.position;
    if (e.vrr !== undefined) d.vrr = e.vrr;
    d.disabled = !!e.disabled;
    d.mirror = e.mirror || "";
    return d;
}

function autoDraft(d) {
    var n = Object.assign({}, d);
    n.res = "auto"; n.rate = "auto"; n.scale = "auto"; n.position = "auto"; n.mirror = "";
    return n;
}

// Concrete "WxH@R" for a draft (auto picks native resolution / highest rate)
function resolveMode(mon, d) {
    var res = d.res === "auto" ? nativeRes(mon) : d.res;
    var rates = ratesFor(mon, res);
    var rate = (d.rate === "auto" || rates.indexOf(d.rate) < 0) ? (rates.length ? rates[0] : "60.00") : d.rate;
    return res + "@" + rate;
}

function entry(mon, d) {
    return {
        output: mon.name,
        mode: resolveMode(mon, d),
        position: d.position || "auto",
        scale: d.scale === undefined ? 1 : d.scale,
        vrr: d.vrr || 0,
        disabled: !!d.disabled,
        mirror: d.mirror || "",
        res_auto: d.res === "auto",
        rate_auto: d.rate === "auto"
    };
}

function resLabel(res) { return res.replace("x", "×"); }
function rateLabel(r) { var n = +r; return (Math.abs(n - Math.round(n)) < 0.005 ? Math.round(n) : n.toFixed(2)) + " Hz"; }
