import QtQuick

// Creates the `source` window only while active
QtObject {
    id: wl
    property url source
    property bool active: false
    property QtObject item: null
    property Component _comp: null
    function _create() {
        if (!active || item || !_comp || _comp.status !== Component.Ready) return;
        item = _comp.createObject(wl);
        if (!item) console.warn("WindowLoader: could not create", source);
    }
    function _onStatus() {
        if (_comp.status === Component.Error) console.warn("WindowLoader:", _comp.errorString());
        else _create();
    }
    function _sync() {
        if (active && !item) {
            if (!_comp) {
                _comp = Qt.createComponent(source, Component.Asynchronous);
                if (_comp.status === Component.Loading) { _comp.statusChanged.connect(_onStatus); return; }
            }
            _onStatus();
        } else if (!active && item) {
            item.destroy();
            item = null;
        }
    }
    onActiveChanged: Qt.callLater(_sync)
    onSourceChanged: { if (item) { item.destroy(); item = null; } _comp = null; Qt.callLater(_sync); }
    Component.onCompleted: Qt.callLater(_sync)
}
