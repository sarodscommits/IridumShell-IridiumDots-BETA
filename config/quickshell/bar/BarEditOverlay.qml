import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Drag-and-drop overlay for editing the bar layout
Item {
    id: barEditOverlay
    anchors.fill: parent
    z: 100
    visible: globalState.desktopEditMode

    BarLayoutFlip { id: barLayout }
    readonly property bool vert: unifiedFrame.barVertical
    function alongOf(px, py) { return vert ? py : px; }

    property var rects: []
    property var rowRect: Qt.rect(0, 0, 0, 36)
    function refresh() {
        var out = [];
        var keys = globalState.barModuleKeys;
        for (var i = 0; i < keys.length; i++) {
            var it = barLayout.itemsFor(keys[i])[0];
            if (!it || !it.visible || it.width <= 0) continue;
            var r = it.mapToItem(barEditOverlay, Qt.rect(0, 0, it.width, it.height));
            out.push({ key: keys[i], x: r.x, y: r.y, w: r.width, h: r.height,
                a: vert ? r.y : r.x, al: vert ? r.height : r.width });
        }
        rects = out;
        rowRect = vert ? vBarStrip.mapToItem(barEditOverlay, Qt.rect(0, 0, vBarStrip.width, vBarStrip.height))
        : topBarMainRow.mapToItem(barEditOverlay, Qt.rect(0, 0, topBarMainRow.width, topBarMainRow.height));
        updateZones();
    }
    Timer {
        interval: barEditOverlay.dragKey !== "" ? 40 : 150
        repeat: true
        running: barEditOverlay.visible
        triggeredOnStart: true
        onTriggered: barEditOverlay.refresh()
    }

    function rectAt(mx, my) {
        for (var i = 0; i < rects.length; i++) {
            var r = rects[i];
            if (mx >= r.x - 3 && mx <= r.x + r.w + 3 && my >= r.y - 6 && my <= r.y + r.h + 6) return r;
        }
        return null;
    }
    readonly property real alongLen: vert ? height : width
    property real zoneB1: alongLen / 3
    property real zoneB2: alongLen * 2 / 3
    Behavior on zoneB1 { NumberAnimation { duration: 220; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasizedDecelerate } }
    Behavior on zoneB2 { NumberAnimation { duration: 220; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasizedDecelerate } }
    readonly property real zonePad: 28
    function _groupRect(g) {
        var r = g.mapToItem(barEditOverlay, Qt.rect(0, 0, g.width, g.height));
        if (vert) return { x0: r.y, x1: r.y + r.height, empty: g.height < 1 };
        return { x0: r.x, x1: r.x + r.width, empty: g.width < 1 };
    }
    function updateZones() {
        if (unifiedFrame.islandMode || alongLen <= 0) return;
        var W = alongLen;
        var L = _groupRect(vert ? vBarStrip.barVGroupLeft : barGroupLeft),
        C = _groupRect(vert ? vBarStrip.barVGroupCenter : barGroupCenter),
        R = _groupRect(vert ? vBarStrip.barVGroupRight : barGroupRight);
        var cStart = C.empty ? W / 2 : C.x0, cEnd = C.empty ? W / 2 : C.x1;
        var lEnd = L.empty ? 0 : L.x1, rStart = R.empty ? W : R.x0;
        function boundary(base, leftEdge, rightEdge) {
            var lo = leftEdge + zonePad, hi = rightEdge - zonePad;
            if (lo > hi) return (leftEdge + rightEdge) / 2;
            return Math.max(lo, Math.min(hi, base));
        }
        zoneB1 = boundary(W / 3, lEnd, cStart);
        zoneB2 = boundary(W * 2 / 3, cEnd, rStart);
    }
    function zoneFor(mx) {
        if (unifiedFrame.islandMode) return "island";
        if (mx < zoneB1) return "left";
        if (mx > zoneB2) return "right";
        return "center";
    }
    function listFor(zone) {
        return zone === "island" ? globalState.barLayoutIsland : globalState.barLayoutNotch[zone];
    }

    property string dragKey: ""
    property string hoverKey: ""
    property real grabOffX: 0
    property real grabOffY: 0
    property real dragX: 0
    property real dragY: 0
    property var dragRect: null
    property string dropZone: ""
    property string dropBefore: ""
    property var tentIsland: []
    property var tentNotch: ({ left: [], center: [], right: [] })
    property string _lastZone: ""
    property string _lastBefore: "#"

    function buildTentative() {
        var k = dragKey;
        if (dropZone === "island") {
            var arr = globalState.barLayoutIsland.filter(function (x) { return x !== k; });
            var idx = dropBefore !== "" ? arr.indexOf(dropBefore) : -1;
            if (idx < 0) arr.push(k); else arr.splice(idx, 0, k);
            tentIsland = arr;
            tentNotch = globalState.barLayoutNotch;
        } else {
            var src = globalState.barLayoutNotch;
            var n = {
                left:   src.left.filter(function (x) { return x !== k; }),
                center: src.center.filter(function (x) { return x !== k; }),
                right:  src.right.filter(function (x) { return x !== k; })
            };
            var g = n[dropZone];
            var idx2 = dropBefore !== "" ? g.indexOf(dropBefore) : -1;
            if (idx2 < 0) g.push(k); else g.splice(idx2, 0, k);
            tentNotch = n;
            tentIsland = globalState.barLayoutIsland;
        }
    }

    function computeDrop(mx) {
        var zone = zoneFor(mx);
        var list = listFor(zone);
        var cands = rects.filter(function (r) { return r.key !== dragKey && list.indexOf(r.key) !== -1; });
        cands.sort(function (a, b) { return a.a - b.a; });
        var before = null;
        for (var i = 0; i < cands.length; i++) {
            if (cands[i].a + cands[i].al / 2 > mx) { before = cands[i]; break; }
        }
        dropZone = zone;
        dropBefore = before ? before.key : "";
        if (zone !== _lastZone || dropBefore !== _lastBefore) {
            _lastZone = zone;
            _lastBefore = dropBefore;
            buildTentative();
            barLayout.applyArraysAnimated(tentIsland, tentNotch);
        }
    }
    function commitDrop() {
        if (dragKey === "" || dropZone === "") return;
        buildTentative();
        if (dropZone === "island") globalState.barLayoutIsland = tentIsland;
        else globalState.barLayoutNotch = tentNotch;
        savePrefs();
    }
    function endDrag(commit) {
        if (commit) commitDrop();
        else barLayout.applyBarLayout();
        dragKey = "";
        dropZone = "";
        dragRect = null;
        _lastZone = "";
        _lastBefore = "#";
        barEditGhost.sourceItem = null;
    }

    Repeater {
        id: barEditZoneRepeater
        model: unifiedFrame.islandMode ? [] : ["left", "center", "right"]
        property color _c: pal.primary
        Rectangle {
            required property var modelData
            required property int index
            property real x0: index === 0 ? 0 : (index === 1 ? barEditOverlay.zoneB1 : barEditOverlay.zoneB2)
            property real x1: index === 0 ? barEditOverlay.zoneB1 : (index === 1 ? barEditOverlay.zoneB2 : barEditOverlay.alongLen)
            x: barEditOverlay.vert ? barEditOverlay.rowRect.x - 2 : x0 + 4
            width: barEditOverlay.vert ? barEditOverlay.rowRect.width + 4 : Math.max(0, x1 - x0 - 8)
            y: barEditOverlay.vert ? x0 + 4 : barEditOverlay.rowRect.y - 2
            height: barEditOverlay.vert ? Math.max(0, x1 - x0 - 8) : barEditOverlay.rowRect.height + 4
            radius: 12
            color: ga(barEditZoneRepeater._c, (barEditOverlay.dragKey !== "" && barEditOverlay.dropZone === modelData) ? 0.14 : 0.04)
            border.width: 1
            border.color: ga(barEditZoneRepeater._c, (barEditOverlay.dragKey !== "" && barEditOverlay.dropZone === modelData) ? 0.6 : 0.22)
            Behavior on color { M3ColorAnim { duration: m3.durFast } }
        }
    }

    Repeater {
        id: barEditModuleRepeater
        model: barEditOverlay.rects
        property color _c: pal.primary
        property color _bg: pal.surface
        Rectangle {
            required property var modelData
            x: modelData.x - 3; y: modelData.y - 3
            width: modelData.w + 6; height: modelData.h + 6
            radius: 10
            property bool isDragged: barEditOverlay.dragKey === modelData.key
            property bool isHover: barEditOverlay.hoverKey === modelData.key && barEditOverlay.dragKey === ""
            color: isDragged ? "transparent" : ga(barEditModuleRepeater._c, isHover ? 0.16 : 0.07)
            border.width: 1.5
            border.color: ga(barEditModuleRepeater._c, isHover || isDragged ? 0.9 : 0.5)
        }
    }

    ShaderEffectSource {
        id: barEditGhost
        visible: barEditOverlay.dragKey !== ""
        live: true
        hideSource: barEditOverlay.dragKey !== ""
        width: barEditOverlay.dragRect ? barEditOverlay.dragRect.w : 0
        height: barEditOverlay.dragRect ? barEditOverlay.dragRect.h : 0
        x: barEditOverlay.dragX - barEditOverlay.grabOffX
        y: barEditOverlay.dragY - barEditOverlay.grabOffY
        opacity: 0.9
        scale: 1.08
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: barEditOverlay.dragKey !== "" ? Qt.ClosedHandCursor
        : (barEditOverlay.hoverKey !== "" ? Qt.OpenHandCursor : Qt.ArrowCursor)
        onPressed: (m) => {
            barEditOverlay.refresh();
            var r = barEditOverlay.rectAt(m.x, m.y);
            if (!r) return;
            barEditOverlay.dragRect = r;
            barEditOverlay.grabOffX = m.x - r.x;
            barEditOverlay.grabOffY = m.y - r.y;
            barEditOverlay.dragX = m.x;
            barEditOverlay.dragY = m.y;
            barEditGhost.sourceItem = barLayout.itemsFor(r.key)[0];
            barEditOverlay.dragKey = r.key;
            barEditOverlay.computeDrop(barEditOverlay.alongOf(m.x, m.y));
        }
        onPositionChanged: (m) => {
            if (barEditOverlay.dragKey !== "") {
                barEditOverlay.dragX = m.x;
                barEditOverlay.dragY = m.y;
                barEditOverlay.computeDrop(barEditOverlay.alongOf(m.x, m.y));
            } else {
                var r = barEditOverlay.rectAt(m.x, m.y);
                barEditOverlay.hoverKey = r ? r.key : "";
            }
        }
        onExited: barEditOverlay.hoverKey = ""
        onReleased: (m) => {
            if (barEditOverlay.dragKey === "") return;
            barEditOverlay.computeDrop(barEditOverlay.alongOf(m.x, m.y));
            barEditOverlay.endDrag(true);
        }
        onCanceled: {
            if (barEditOverlay.dragKey !== "") barEditOverlay.endDrag(false);
        }
    }
}
