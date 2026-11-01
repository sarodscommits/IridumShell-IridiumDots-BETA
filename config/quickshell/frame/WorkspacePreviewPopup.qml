import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../panels"

// Workspace preview bulge popup
Item {
    id: wsPreviewPopup
    property alias wsPreviewCloseTimer: wsPreviewCloseTimer
    property alias wsPreviewPopupHover: wsPreviewPopupHover
    readonly property bool isOpen: globalState.wsPreviewOpen
    property real anchorX: 0
    readonly property real natW: 380
    readonly property real bulgeW: natW * unifiedFrame.bulgeScale
    readonly property real thumbW: natW - 24
    readonly property real screenW: Math.max(1, frameRoot.width)
    readonly property real screenH: Math.max(1, frameRoot.height)
    readonly property real thumbH: Math.round(thumbW * screenH / screenW)
    readonly property real headerH: 26
    readonly property real fullDepth: 12 + headerH + 8 + thumbH + 14
    readonly property var bbox: {
        var minX = 0, minY = 0, maxX = screenW, maxY = screenH;
        var c = wsClients;
        for (var i = 0; i < c.length; i++) {
            minX = Math.min(minX, c[i].x);
            minY = Math.min(minY, c[i].y);
            maxX = Math.max(maxX, c[i].x + c[i].w);
            maxY = Math.max(maxY, c[i].y + c[i].h);
        }
        var zoomedOut = minX < 0 || minY < 0 || maxX > screenW || maxY > screenH;
        if (zoomedOut) {
            var padX = (maxX - minX) * 0.04, padY = (maxY - minY) * 0.04;
            minX -= padX; maxX += padX; minY -= padY; maxY += padY;
        }
        return { minX: minX, minY: minY, w: maxX - minX, h: maxY - minY, zoomedOut: zoomedOut };
    }
    readonly property real sc: Math.min(thumbW / bbox.w, thumbH / bbox.h)
    readonly property real offX: (thumbW - bbox.w * sc) / 2 - bbox.minX * sc
    readonly property real offY: (thumbH - bbox.h * sc) / 2 - bbox.minY * sc
    readonly property var wsClients: {
        var id = globalState.wsPreviewId;
        var out = [];
        var list = globalState.openClients;
        for (var i = 0; i < list.length; i++) if (list[i].workspace === id) out.push(list[i]);
        out.sort(function (a, b) { return (a.floating ? 1 : 0) - (b.floating ? 1 : 0); });
        return out;
    }

    readonly property int poolSize: 24
    property var _slotState: []
    function _rectFor(c) {
        return { x: offX + c.x * sc + 1, y: offY + c.y * sc + 1,
            w: Math.max(6, c.w * sc - 2), h: Math.max(6, c.h * sc - 2) };
    }
    function _dist(a, b) {
        var dx = (a.x + a.w / 2) - (b.x + b.w / 2), dy = (a.y + a.h / 2) - (b.y + b.h / 2);
        return dx * dx + dy * dy;
    }
    function _dot(r) { return { x: r.x + r.w / 2 - 3, y: r.y + r.h / 2 - 3, w: 6, h: 6 }; }
    function _matchSlots(rects, old) {
        var pairs = [];
        for (var i = 0; i < rects.length; i++)
        for (var j = 0; j < poolSize; j++)
        if (old[j].alive) pairs.push({ i: i, j: j, d: _dist(rects[i], old[j].r) });
        pairs.sort(function (a, b) { return a.d - b.d; });
        var newOf = [], slotOf = [];
        for (var k = 0; k < pairs.length; k++) {
            var p = pairs[k];
            if (slotOf[p.i] !== undefined || newOf[p.j] !== undefined) continue;
            slotOf[p.i] = p.j; newOf[p.j] = p.i;
        }
        return { slotOf: slotOf, newOf: newOf };
    }
    function _nearest(r, list) {
        var best = -1, hit = null;
        for (var k = 0; k < list.length; k++) {
            var d = _dist(r, list[k]);
            if (best < 0 || d < best) { best = d; hit = list[k]; }
        }
        return hit;
    }
    function _enter(slot, client, rect, old, animate) {
        var it = wsPreviewScreen.wsPreviewRepeater.itemAt(slot);
        if (!it) return;
        var alive = old.filter(function (s) { return s.alive; }).map(function (s) { return s.r; });
        var src = _nearest(rect, alive) || _dot(rect);
        it.modelData = client;
        it.snap = true; it.alive = true;
        it.place(src, false);
        it.place(rect, animate);
    }
    function _retire(slot, rects, old, animate) {
        var it = wsPreviewScreen.wsPreviewRepeater.itemAt(slot);
        if (!it) return null;
        var dst = _nearest(old[slot].r, rects) || _dot(old[slot].r);
        if (!animate) it.snap = true;
        it.alive = false;
        it.place(dst, animate);
        return dst;
    }
    function relayout() {
        if (wsPreviewScreen.wsPreviewRepeater.count < poolSize) return;
        var animate = isOpen && opacity > 0.5;
        var clients = wsClients.slice(0, poolSize);
        var rects = clients.map(_rectFor);
        var old = _slotState.length === poolSize ? _slotState : [];
        if (old.length === 0) for (var q = 0; q < poolSize; q++) old.push({ alive: false, r: null });
        var m = _matchSlots(rects, old);
        var free = [], next = [];
        for (var f = 0; f < poolSize; f++) {
            if (!old[f].alive) free.push(f);
            next.push({ alive: false, r: old[f].r });
        }
        for (var i = 0; i < rects.length; i++) {
            var slot = m.slotOf[i];
            if (slot !== undefined) {
                var it = wsPreviewScreen.wsPreviewRepeater.itemAt(slot);
                if (it) { it.modelData = clients[i]; it.alive = true; it.place(rects[i], animate); }
            } else if (free.length > 0) {
                slot = free.shift();
                _enter(slot, clients[i], rects[i], old, animate);
            } else continue;
            next[slot] = { alive: true, r: rects[i] };
        }
        for (var s = 0; s < poolSize; s++) {
            if (!old[s].alive || m.newOf[s] !== undefined) continue;
            var dst = _retire(s, rects, old, animate);
            if (dst) next[s] = { alive: false, r: dst };
        }
        _slotState = next;
    }
    onWsClientsChanged: Qt.callLater(relayout)
    onScChanged: Qt.callLater(relayout)
    onOffXChanged: Qt.callLater(relayout)
    onOffYChanged: Qt.callLater(relayout)
    Component.onCompleted: Qt.callLater(relayout)

    x: unifiedFrame.barVertical ? unifiedFrame.popupRealX(width) : unifiedFrame.bulgeLeftX
    width: unifiedFrame.barVertical ? unifiedFrame.bulgeDepth : Math.max(0, unifiedFrame.bulgeRightX - unifiedFrame.bulgeLeftX)
    height: unifiedFrame.barVertical ? Math.max(0, unifiedFrame.bulgeRightX - unifiedFrame.bulgeLeftX) : unifiedFrame.bulgeDepth
    opacity: isOpen ? 1 : 0
    Behavior on opacity { M3NumberAnim { duration: wsPreviewPopup.isOpen ? 220 : 140 } }
    visible: opacity > 0.01
    enabled: isOpen
    y: unifiedFrame.barVertical ? unifiedFrame.bulgeLeftX
    : (unifiedFrame.barAtBottom ? (frameRoot.height - unifiedFrame.frameBottomH - height) : unifiedFrame.frameTopH)
    z: 1000
    clip: true

    function reposition() {
        unifiedFrame.previewAnchorX = anchorX;
        unifiedFrame.setBulgeCentered(wsPreviewPopup, fullDepth * unifiedFrame.bulgeScale);
    }
    onIsOpenChanged: {
        if (isOpen) { reposition(); relayout(); }
        else unifiedFrame.setBulgeCentered(wsPreviewPopup, 0);
    }

    HoverHandler {
        id: wsPreviewPopupHover
        onHoveredChanged: {
            if (hovered) wsPreviewCloseTimer.stop();
            else if (!topBarContent.wsContainer.wsContainerHover.hovered) wsPreviewCloseTimer.restart();
        }
    }
    Timer {
        id: wsPreviewCloseTimer
        interval: 260
        repeat: false
        onTriggered: { if (!wsPreviewPopupHover.hovered && !topBarContent.topBarHover.hovered) globalState.wsPreviewOpen = false; }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (globalState.wsPreviewId !== globalState.activeWorkspace)
            Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + globalState.wsPreviewId + " })"]);
            globalState.wsPreviewOpen = false;
        }
    }

    Item {
        width: wsPreviewPopup.natW
        x: unifiedFrame.barVertical ? (unifiedFrame.barAtLeft ? 0 : parent.width - width) : (parent.width - width) / 2
        height: wsPreviewPopup.fullDepth
        scale: unifiedFrame.bulgeScale
        transformOrigin: unifiedFrame.popupOrigin
        y: unifiedFrame.barVertical ? (parent.height - height) / 2 : (unifiedFrame.barAtBottom ? parent.height - height : 0)

        RowLayout {
            x: 14; y: 12
            width: parent.width - 28
            height: wsPreviewPopup.headerH
            spacing: 8
            Rectangle {
                width: 24; height: 24; radius: 12
                color: globalState.wsPreviewId === globalState.activeWorkspace ? pal.primary : ga(pal.primary, 0.18)
                Text {
                    anchors.centerIn: parent
                    text: globalState.wsPreviewId
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.bold: true
                    color: globalState.wsPreviewId === globalState.activeWorkspace ? pal.colorOnPrimary : pal.primary
                }
            }
            Text {
                Layout.fillWidth: true
                text: "Workspace " + globalState.wsPreviewId
                font.family: globalState.fontPrimary; font.pixelSize: Math.round(13 * globalState.fontScale); font.weight: Font.Bold
                color: pal.colorOnSurface
                elide: Text.ElideRight
            }
            Text {
                visible: wsPreviewPopup.wsClients.length > 0
                text: "\ue30c"
                font.family: "Material Symbols Rounded"; font.pixelSize: 14
                color: pal.colorOnSurfVar
            }
            Text {
                visible: wsPreviewPopup.wsClients.length > 0
                text: wsPreviewPopup.wsClients.length
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                color: pal.colorOnSurfVar
            }
        }

        WorkspacePreviewScreen { id: wsPreviewScreen }
    }
}
