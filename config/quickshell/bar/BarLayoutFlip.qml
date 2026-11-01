import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

// Applies the saved bar layout with a FLIP animation
Item {
    id: barLayout
    Item { id: barModuleHolder; visible: false }

    function itemsFor(k) {
        switch (k) {
            case "control":    return [islandControlBtn];
            case "search":     return [searchBtn, searchSeparator];
            case "audio":      return [islandAudioModule];
            case "clock":      return [islandClockModule];
            case "workspaces": return [wsContainer];
            case "windows":    return [openWindowsModule];
            case "gaming":     return [barGroupRight.gamingBtn];
            case "clipboard":  return [barGroupRight.clipBtn];
            case "privacy":    return [barGroupRight.privBtn];
            case "notifications": return [barGroupRight.notifBtn];
            case "wifi":       return [barGroupRight.wifiBtn];
            case "bluetooth":  return [barGroupRight.btBtn];
            case "battery":    return [barGroupRight.battBtn];
            case "session":    return [barGroupRight.sessionBtnWrap];
        }
        return [];
    }
    function _place(list, container) {
        for (var i = 0; i < list.length; i++) {
            var its = itemsFor(list[i]);
            for (var j = 0; j < its.length; j++) its[j].parent = container;
        }
    }
    function applyArrays(islandArr, notchObj) {
        var keys = globalState.barModuleKeys;
        for (var i = 0; i < keys.length; i++) {
            var its = itemsFor(keys[i]);
            for (var j = 0; j < its.length; j++) its[j].parent = barModuleHolder;
        }
        var vert = unifiedFrame.barVertical;
        if (unifiedFrame.islandMode) {
            _place(islandArr, vert ? vBarStrip.barVGroupIsland : barGroupLeft);
        } else {
            _place(notchObj.left,   vert ? vBarStrip.barVGroupLeft   : barGroupLeft);
            _place(notchObj.center, vert ? vBarStrip.barVGroupCenter : barGroupCenter);
            _place(notchObj.right,  vert ? vBarStrip.barVGroupRight  : barGroupRight);
        }
    }
    function applyBarLayout() {
        if (barEditOverlay.visible) applyArraysAnimated(globalState.barLayoutIsland, globalState.barLayoutNotch);
        else applyArrays(globalState.barLayoutIsland, globalState.barLayoutNotch);
        Qt.callLater(barEditOverlay.refresh);
    }

    property var _flipTrs: ({})
    property var _flipList: []
    property real flipP: 0
    onFlipPChanged: {
        for (var i = 0; i < _flipList.length; i++) {
            var f = _flipList[i];
            f.t.x = f.dx * flipP;
            f.t.y = f.dy * flipP;
        }
    }
    NumberAnimation {
        id: barFlipAnim
        target: barLayout
        property: "flipP"
        from: 1; to: 0
        duration: 260
        easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasizedDecelerate
    }
    function _trFor(id, it) {
        var t = _flipTrs[id];
        if (!t) {
            t = Qt.createQmlObject('import QtQuick; Translate {}', barEditOverlay);
            _flipTrs[id] = t;
            it.transform = [t];
        }
        return t;
    }
    function _allItems() {
        var out = [];
        var keys = globalState.barModuleKeys;
        for (var i = 0; i < keys.length; i++) {
            var its = itemsFor(keys[i]);
            for (var j = 0; j < its.length; j++) out.push({ id: keys[i] + ":" + j, it: its[j] });
        }
        return out;
    }
    readonly property bool _canSyncLayout: typeof topBarMainRow.ensurePolished === "function"
    || typeof topBarMainRow.forceLayout === "function"
    function _polishOne(l) {
        if (!l) return;
        if (typeof l.ensurePolished === "function") l.ensurePolished();
        else if (typeof l.forceLayout === "function") l.forceLayout();
    }
    function _forceLayouts() {
        for (var n = 0; n < 2; n++) {
            _polishOne(barGroupLeft);
            _polishOne(barGroupCenter);
            _polishOne(barGroupRight);
            _polishOne(topBarMainRow);
            _polishOne(topBarColumn);
            _polishOne(vBarStrip.barVGroupIsland);
            _polishOne(vBarStrip.barVGroupLeft);
            _polishOne(vBarStrip.barVGroupCenter);
            _polishOne(vBarStrip.barVGroupRight);
            _polishOne(vBarStrip.vIslandCol);
            _polishOne(vBarStrip.vNotchTopCol);
        }
    }
    function _startFlip(all, before) {
        var list = [];
        for (var m = 0; m < all.length; m++) {
            var b = before[all[m].id];
            var it2 = all[m].it;
            if (!b || !it2.visible || it2.width <= 0) continue;
            var a = it2.mapToItem(barEditOverlay, Qt.rect(0, 0, it2.width, it2.height));
            var dx = b.x - a.x, dy = b.y - a.y;
            if (Math.abs(dx) < 0.5 && Math.abs(dy) < 0.5) continue;
            list.push({ t: _trFor(all[m].id, it2), dx: dx, dy: dy });
        }
        _flipList = list;
        flipP = 1;
        if (list.length > 0) barFlipAnim.restart();
    }
    function applyArraysAnimated(islandArr, notchObj) {
        var all = _allItems();
        var before = {};
        for (var i = 0; i < all.length; i++) {
            var it = all[i].it;
            if (!it.visible || it.width <= 0) continue;
            var r = it.mapToItem(barEditOverlay, Qt.rect(0, 0, it.width, it.height));
            before[all[i].id] = r;
        }
        barFlipAnim.stop();
        for (var k in _flipTrs) { _flipTrs[k].x = 0; _flipTrs[k].y = 0; }
        applyArrays(islandArr, notchObj);
        if (_canSyncLayout) {
            _forceLayouts();
            _startFlip(all, before);
        } else {
            Qt.callLater(function () { barLayout._startFlip(all, before); });
        }
    }
    Component.onCompleted: Qt.callLater(applyBarLayout)
    Connections {
        target: globalState
        function onBarLayoutIslandChanged() { barLayout.applyBarLayout(); }
        function onBarLayoutNotchChanged()  { barLayout.applyBarLayout(); }
        function onShellModeChanged()       { barLayout.applyBarLayout(); }
    }
    Connections {
        target: unifiedFrame
        function onBarVerticalChanged() { barLayout.applyBarLayout(); }
    }
}
