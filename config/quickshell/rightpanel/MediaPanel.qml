import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../rightpanel"
import "../ui"
import "EqPreset.js" as EqPreset

// Media page of the right panel: player, equalizer and visualizer
Item {
    id: mediaPanel
    anchors.fill: parent
    anchors.margins: 12
    anchors.topMargin: 24
    opacity: (!globalState.mediaMenuOpen || globalState.rightPanelPage !== 1 || globalState.wifiViewOpen || globalState.btDevicesViewOpen) ? 0 : 1
    visible: (globalState.mediaMenuOpen && globalState.rightPanelPage === 1) || opacity > 0
    enabled: globalState.mediaMenuOpen && globalState.rightPanelPage === 1 && !globalState.wifiViewOpen && !globalState.btDevicesViewOpen
    Behavior on opacity { M3NumberAnim {} }

    property real animPct: 0

    property bool eqDragging: false
    function setEqDragging(active) {
        eqDragging = active;
        if (unifiedFrame.islandMode || !unifiedFrame.rightPanelEnabled) return;
        if (active) {
            mediaCloseTimer.stop();
            globalState.mediaPendingClose = false;
            globalState.mediaMenuOpen = true;
        } else if (!rightPanelHover.hovered) {
            mediaCloseTimer.restart();
        }
    }

    onVisibleChanged: {
        if (visible) {
            animPct = globalState.mediaPosition;
            mediaPanel.openEqAnimation();
        }
    }

    readonly property var eqBandLabels: ["60","150","400","1k","2.4k","6k","12k","16k"]
    readonly property var eqPresets: ({
        "Flat":        [0.50,0.50,0.50,0.50,0.50,0.50,0.50,0.50],
        "Bass+":       [0.88,0.78,0.60,0.48,0.42,0.38,0.36,0.34],
        "Pop":         [0.55,0.62,0.68,0.72,0.64,0.58,0.55,0.52],
        "Rock":        [0.72,0.64,0.44,0.40,0.50,0.62,0.68,0.64],
        "Vocal":       [0.40,0.42,0.56,0.76,0.78,0.66,0.50,0.42],
        "Treble+":     [0.34,0.38,0.42,0.48,0.58,0.70,0.82,0.88],
        "Electronic":  [0.82,0.70,0.42,0.38,0.46,0.60,0.75,0.84]
    })
    property string eqActivePreset: "Flat"

    function eqValToDb(v) {
        return (v - 0.5) * 24.0;
    }

    function applyEqToPipewire(vals) {
        var json = EqPreset.build(vals, function (v) { return eqValToDb(v); });
        Quickshell.execDetached(["bash", "-c", "exec bash \"" + scriptsDir + "/easyeffects_eq.sh\" \"$1\"", "qs-eq", json]);
    }

    function applyEqPreset(name) {
        eqActivePreset = name;
        var vals = eqPresets[name];
        var _rq = mediaPanel._rightEqRep();
        for (var i = 0; _rq && i < _rq.count; i++) {
            var row = _rq.itemAt(i);
            if (row) row.animateTo(vals[i]);
        }
        var _icEq = icEqRep();
        if (_icEq) {
            for (var j = 0; j < _icEq.count; j++) {
                var icRow = _icEq.itemAt(j);
                if (icRow) icRow.animateTo(vals[j]);
            }
        }
        var _ncEq = ncEqRep();
        if (_ncEq) {
            for (var k = 0; k < _ncEq.count; k++) {
                var ncRow = _ncEq.itemAt(k);
                if (ncRow) ncRow.animateTo(vals[k]);
            }
        }
        if (typeof notchMediaPopup.nbEqRepeater !== "undefined" && notchMediaPopup.nbEqRepeater) {
            for (var q = 0; q < notchMediaPopup.nbEqRepeater.count; q++) {
                var nbRow = notchMediaPopup.nbEqRepeater.itemAt(q);
                if (nbRow) nbRow.animateTo(vals[q]);
            }
        }
        applyEqToPipewire(vals);
    }

    property var _pendingEqVals: null
    Timer {
        id: eqApplyDebounce
        interval: 90
        repeat: false
        onTriggered: {
            if (mediaPanel._pendingEqVals) mediaPanel.applyEqToPipewire(mediaPanel._pendingEqVals);
        }
    }
    property var eqCustomVals: null
    function onEqBandDragged(vals) {
        var _rq = mediaPanel._rightEqRep(); if (_rq) mediaPanel._syncEqFromRepeater(_rq);
    }
    function onIslandEqBandDragged(vals) {
        var _r = icEqRep(); if (_r) mediaPanel._syncEqFromRepeater(_r);
    }
    function onNotchEqBandDragged(vals) {
        var _r = ncEqRep(); if (_r) mediaPanel._syncEqFromRepeater(_r);
    }
    function onNotchBulgeEqBandDragged(vals) {
        mediaPanel._syncEqFromRepeater(notchMediaPopup.nbEqRepeater);
    }
    function _syncEqFromRepeater(rep) {
        eqActivePreset = "";
        var currentVals = [];
        for (var i = 0; i < rep.count; i++) {
            var row = rep.itemAt(i);
            currentVals.push(row ? row.displayVal : 0.5);
        }
        eqCustomVals = currentVals;
        _pendingEqVals = currentVals;
        eqApplyDebounce.restart();
    }
    function openEqAnimation() {
        var vals = eqActivePreset ? (eqPresets[eqActivePreset] || eqPresets["Flat"])
        : (eqCustomVals || eqPresets["Flat"]);
        var _rq = mediaPanel._rightEqRep();
        for (var i = 0; _rq && i < _rq.count; i++) {
            var row = _rq.itemAt(i);
            if (row) row.resetAndAnimate(vals[i]);
        }
        var _icEq = icEqRep();
        if (_icEq) {
            for (var j = 0; j < _icEq.count; j++) {
                var icRow = _icEq.itemAt(j);
                if (icRow) icRow.resetAndAnimate(vals[j]);
            }
        }
        var _ncEq = ncEqRep();
        if (_ncEq) {
            for (var k = 0; k < _ncEq.count; k++) {
                var ncRow = _ncEq.itemAt(k);
                if (ncRow) ncRow.resetAndAnimate(vals[k]);
            }
        }
        if (typeof notchMediaPopup.nbEqRepeater !== "undefined" && notchMediaPopup.nbEqRepeater) {
            for (var q = 0; q < notchMediaPopup.nbEqRepeater.count; q++) {
                var nbRow = notchMediaPopup.nbEqRepeater.itemAt(q);
                if (nbRow) nbRow.resetAndAnimate(vals[q]);
            }
        }
    }

    Connections {
        target: globalState
        function onMediaPositionChanged() {
            var _ui = mediaPanelUiLoader.item;
            if (!_ui || !_ui.drag.pressed)
            mediaPanel.animPct = globalState.mediaPosition;
        }
    }

    property real cavaPhase: 0
    property real cavaSeed: 0
    property real cavaLastRealTs: 0

    function repaintCava() {
        var ui = mediaPanelUiLoader.item;
        if (!ui || !mediaPanel.visible) return;
        var c = ui.cava;
        if (c && c.width > 0 && c.height > 0) c.requestPaint();
    }
    function _rightEqRep() { return mediaPanelUiLoader.item ? mediaPanelUiLoader.item.eqRep : null; }

    function noise(x, seed) {
        var i = Math.floor(x);
        var f = x - i;
        f = f * f * (3 - 2 * f);
        var h0 = Math.sin(i * 127.1 + seed * 311.7) * 43758.5453;
        var h1 = Math.sin((i+1) * 127.1 + seed * 311.7) * 43758.5453;
        return (h0 - Math.floor(h0)) * (1 - f) + (h1 - Math.floor(h1)) * f;
    }

    Loader {
        id: mediaPanelUiLoader
        anchors.fill: parent
        active: unifiedFrame.rightPanelEnabled && !unifiedFrame.islandMode
        source: Qt.resolvedUrl("MediaPanelUi.qml")
    }
}
