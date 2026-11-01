import QtQuick

// ESlider reporting the pointer as a 0-1 fraction
ESlider {
    id: fs
    property real thumbW: 6
    property bool skipEmpty: false
    signal fracPressed()
    signal fracMoved(real frac)
    signal fracReleased()
    Item { id: thumb; width: fs.thumbW; visible: false }
    function _mx(f) { return f * (width - fs.thumbW) + (fs.thumbW) / 2; }
    function _emit(mx) {
        var u = fs.width - thumb.width;
        if (fs.skipEmpty && u <= 0) return;
        fs.fracMoved(Math.max(0, Math.min(mx - thumb.width / 2, u)) / u);
    }
    onPressedAt: (v) => { fs.fracPressed(); _emit(_mx(v)); }
    onDragged: (v) => { if (pressed) _emit(_mx(v)); }
    onReleasedAt: (v) => { _emit(_mx(v)); fs.fracReleased(); }
}
