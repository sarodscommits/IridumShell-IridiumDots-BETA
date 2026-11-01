.pragma library
// Usage fraction from fetch strings like "5120 / 15890 MB" or "120G / 465G"; -1 if unknown

function _bytes(s) {
    var m = /([\d.]+)\s*([KMGTP]?)/i.exec(s);
    if (!m) return NaN;
    var mult = { "": 1, K: 1, M: 1024, G: 1048576, T: 1073741824, P: 1099511627776 }[m[2].toUpperCase()];
    return parseFloat(m[1]) * mult;
}

function usage(s) {
    if (!s || s.indexOf("/") < 0) return -1;
    var p = s.split("/");
    var a = _bytes(p[0]), b = _bytes(p[1]);
    if (/MB\s*$/.test(s)) { a = parseFloat(p[0]); b = parseFloat(p[1]); }
    return (isNaN(a) || isNaN(b) || b <= 0) ? -1 : a / b;
}
