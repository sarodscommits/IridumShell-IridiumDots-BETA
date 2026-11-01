import QtQuick

// Press bump: pressed cell grows, neighbors shrink
QtObject {
    id: bc
    property int idx: -1
    property int group: 0
    property real px: 10
    // t: linear 0→1; val: damped oscillation
    property real t: 1
    readonly property real val: (t <= 0 || t >= 1) ? 0 : 1.9 * Math.exp(-4.5 * t) * Math.sin(9.4 * t)
    function bump(i, grp) { idx = i; group = (grp === undefined) ? 0 : grp; _anim.stop(); t = 0; _anim.start(); }
    function dw(i, n, grp) {
        if (idx < 0 || val === 0 || (grp !== undefined && grp !== group)) return 0;
        var g = px * val;
        if (i === idx) return g * ((i > 0) ? 1 : 0) + g * ((i < n - 1) ? 1 : 0);
        if (i === idx - 1 || i === idx + 1) return -g;
        return 0;
    }
    function dx(i, grp) {
        if (idx < 0 || val === 0 || (grp !== undefined && grp !== group)) return 0;
        var g = px * val;
        if (i === idx) return i > 0 ? -g : 0;
        if (i === idx + 1) return g;
        return 0;
    }
    property NumberAnimation _anim: NumberAnimation { target: bc; property: "t"; from: 0; to: 1; duration: 720; easing.type: Easing.Linear }
}
