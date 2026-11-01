import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Parallax wallpaper layer that follows the infinite-desktop pan
PanelWindow {
    id: parallaxLayer
    WlrLayershell.namespace: "iridium-parallax"
    WlrLayershell.layer: WlrLayer.Background
    anchors.top:    true
    anchors.bottom: true
    anchors.left:   true
    anchors.right:  true
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}

    readonly property bool active: globalState.parallaxEnabled
                                   && globalState.currentWallpaper !== ""
                                   && !isCurrentWallpaperAnimated()
    visible: active

    readonly property real scrW: screen ? screen.width  : width
    readonly property real scrH: screen ? screen.height : height
    readonly property real zoom: globalState.parallaxZoom
    readonly property real maxX: scrW * (zoom - 1) / 2
    readonly property real maxY: scrH * (zoom - 1) / 2

    property real rawX: 0
    property real rawY: 0
    property real wRawX: 0
    property real wRawY: 0
    property int  curWs: -1
    function storeWs() {
        if (curWs < 0) return;
        var copy = Object.assign({}, globalState.parallaxOffsets);
        copy[String(curWs)] = { x: rawX, y: rawY, wx: wRawX, wy: wRawY };
        globalState.parallaxOffsets = copy;
    }
    function loadWs() {
        curWs = globalState.activeWorkspace;
        var o = globalState.parallaxOffsets[String(curWs)];
        rawX  = o ? o.x : 0;
        rawY  = o ? o.y : 0;
        wRawX = o && typeof o.wx === "number" ? o.wx : 0;
        wRawY = o && typeof o.wy === "number" ? o.wy : 0;
    }
    readonly property bool widgetsActive: globalState.parallaxEnabled && globalState.parallaxWidgets
    Connections {
        target: globalState
        function onActiveWorkspaceChanged() {
            parallaxLayer.storeWs();
            parallaxLayer.loadWs();
            parallaxLayer.startSwitch();
        }
    }

    function clampX(v) { return Math.max(-2 * maxX, Math.min(2 * maxX, v)); }
    function clampY(v) { return Math.max(-2 * maxY, Math.min(2 * maxY, v)); }
    function softX(v) { return maxX > 0 ? maxX * Math.tanh(v / maxX) : 0; }
    function softY(v) { return maxY > 0 ? maxY * Math.tanh(v / maxY) : 0; }

    function addDelta(dx, dy) {
        if (!active && !widgetsActive) return;
        if (curWs !== globalState.activeWorkspace) loadWs();
        if (active) {
            rawX = clampX(rawX + dx * globalState.parallaxStrength);
            rawY = clampY(rawY + dy * globalState.parallaxStrength);
        }
        if (widgetsActive && !globalState.desktopEditMode) {
            wRawX += dx * globalState.parallaxWidgetStrength;
            wRawY += dy * globalState.parallaxWidgetStrength;
        }
    }
    function resetCurrent() {
        rawX = 0; rawY = 0;
        wRawX = 0; wRawY = 0;
        storeWs();
    }

    readonly property real targetX: softX(clampX(rawX))
    readonly property real targetY: softY(clampY(rawY))
    property real offX: 0
    property real offY: 0
    readonly property real wTargetX: widgetsActive ? Math.round(wRawX) : 0
    readonly property real wTargetY: widgetsActive ? Math.round(wRawY) : 0
    property real wOffX: 0
    property real wOffY: 0
    property real vX: 0
    property real vY: 0
    property real wvX: 0
    property real wvY: 0

    readonly property real springW: 24

    readonly property real switchDuration: 0.65
    property bool switching: false
    property real swT: 0
    property real swFromX: 0
    property real swFromY: 0
    property real swFromWX: 0
    property real swFromWY: 0
    function startSwitch() {
        swFromX = offX; swFromY = offY;
        swFromWX = wOffX; swFromWY = wOffY;
        vX = 0; vY = 0; wvX = 0; wvY = 0;
        swT = 0;
        switching = true;
    }
    function easeInOut(t) {
        return t < 0.5 ? 16 * t * t * t * t * t : 1 - Math.pow(-2 * t + 2, 5) / 2;
    }
    function springAxis(x, v, target, dt) {
        var w = springW;
        var a = w * w * (target - x) - 2 * w * v;
        v += a * dt;
        x += v * dt;
        return [x, v];
    }
    function settled(x, v, target) { return Math.abs(target - x) < 0.02 && Math.abs(v) < 0.5; }
    FrameAnimation {
        id: plxFollow
        running: parallaxLayer.switching
                 || (parallaxLayer.active
                  && !(parallaxLayer.settled(parallaxLayer.offX, parallaxLayer.vX, parallaxLayer.targetX)
                       && parallaxLayer.settled(parallaxLayer.offY, parallaxLayer.vY, parallaxLayer.targetY)))
                 || !(parallaxLayer.settled(parallaxLayer.wOffX, parallaxLayer.wvX, parallaxLayer.wTargetX)
                      && parallaxLayer.settled(parallaxLayer.wOffY, parallaxLayer.wvY, parallaxLayer.wTargetY))
        onTriggered: {
            var L = parallaxLayer;
            var dt = Math.min(Math.max(smoothFrameTime > 0 ? smoothFrameTime : frameTime, 0.001), 0.05);
            if (L.switching) {
                L.swT = Math.min(1, L.swT + dt / L.switchDuration);
                var e = L.easeInOut(L.swT);
                if (L.active) {
                    L.offX = L.swFromX + (L.targetX - L.swFromX) * e;
                    L.offY = L.swFromY + (L.targetY - L.swFromY) * e;
                }
                L.wOffX = L.swFromWX + (L.wTargetX - L.swFromWX) * e;
                L.wOffY = L.swFromWY + (L.wTargetY - L.swFromWY) * e;
                if (L.swT >= 1) L.switching = false;
                return;
            }
            var n = Math.max(1, Math.ceil(dt / 0.002)), h = dt / n;
            var ox = L.offX, oy = L.offY, ovx = L.vX, ovy = L.vY;
            var wx = L.wOffX, wy = L.wOffY, wvx = L.wvX, wvy = L.wvY;
            var r;
            for (var i = 0; i < n; i++) {
                if (L.active) {
                    r = L.springAxis(ox, ovx, L.targetX, h); ox = r[0]; ovx = r[1];
                    r = L.springAxis(oy, ovy, L.targetY, h); oy = r[0]; ovy = r[1];
                }
                r = L.springAxis(wx, wvx, L.wTargetX, h); wx = r[0]; wvx = r[1];
                r = L.springAxis(wy, wvy, L.wTargetY, h); wy = r[0]; wvy = r[1];
            }
            if (L.settled(ox, ovx, L.targetX)) { ox = L.targetX; ovx = 0; }
            if (L.settled(oy, ovy, L.targetY)) { oy = L.targetY; ovy = 0; }
            if (L.settled(wx, wvx, L.wTargetX)) { wx = L.wTargetX; wvx = 0; }
            if (L.settled(wy, wvy, L.wTargetY)) { wy = L.wTargetY; wvy = 0; }
            L.vX = ovx; L.vY = ovy; L.wvX = wvx; L.wvY = wvy;
            L.offX = ox; L.offY = oy; L.wOffX = wx; L.wOffY = wy;
        }
    }

    Item {
        id: plxContent
        width:  parallaxLayer.scrW * parallaxLayer.zoom
        height: parallaxLayer.scrH * parallaxLayer.zoom
        x: (parallaxLayer.width  - width)  / 2 + parallaxLayer.offX
        y: (parallaxLayer.height - height) / 2 + parallaxLayer.offY
        Behavior on width  { M3SpringAnim { token: "spatialDefault" } }
        Behavior on height { M3SpringAnim { token: "spatialDefault" } }

        property Image front: plxImgA
        property Image back:  plxImgB
        property string shownSrc: ""

        function load(path) {
            var src = path === "" ? "" : "file://" + path;
            if (shownSrc === src && src !== "") return;
            shownSrc = src;
            snapFrames = 0;
            back.want = true;
            back.opacity = 0;
            back.source = src;
            if (back.status === Image.Ready) imageReady(back);
        }
        function imageReady(img) {
            if (img !== back || !img.want) return;
            img.want = false;
            img.z = 1; front.z = 0;
            plxFade.target = img;
            plxFade.restart();
            var old = front;
            front = back; back = old;
            plxClearTimer.restart();
        }

        Image {
            id: plxImgA
            property bool want: false
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true; cache: false; smooth: true; mipmap: false
            sourceSize.width:  Math.round(parallaxLayer.scrW * Math.max(1, parallaxLayer.zoom))
            sourceSize.height: Math.round(parallaxLayer.scrH * Math.max(1, parallaxLayer.zoom))
            onStatusChanged: if (status === Image.Ready) plxContent.imageReady(plxImgA)
        }
        Image {
            id: plxImgB
            property bool want: false
            anchors.fill: parent
            opacity: 0
            fillMode: Image.PreserveAspectCrop
            asynchronous: true; cache: false; smooth: true; mipmap: false
            sourceSize.width:  Math.round(parallaxLayer.scrW * Math.max(1, parallaxLayer.zoom))
            sourceSize.height: Math.round(parallaxLayer.scrH * Math.max(1, parallaxLayer.zoom))
            onStatusChanged: if (status === Image.Ready) plxContent.imageReady(plxImgB)
        }
        ShaderEffectSource {
            id: plxSnap
            anchors.fill: parent
            z: -1
            live: false
            hideSource: false
            smooth: true
        }
        readonly property var qwin: Window.window
        property int snapFrames: 0
        function releaseFront() {
            var f = plxContent.front;
            if (plxContent.back.want || f.status !== Image.Ready || plxSnap.sourceItem !== f) return;
            f.source = "";
            f.opacity = 0;
        }
        Connections {
            target: plxContent.qwin
            enabled: plxContent.snapFrames > 0
            function onFrameSwapped() {
                plxContent.snapFrames -= 1;
                if (plxContent.snapFrames <= 0) plxContent.releaseFront();
                else plxContent.qwin.update();
            }
        }
        NumberAnimation { id: plxFade; property: "opacity"; from: 0; to: 1; duration: 350; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasizedDecelerate }
        Timer {
            id: plxClearTimer
            interval: 400
            onTriggered: {
                plxContent.back.source = ""; plxContent.back.opacity = 0;
                if (plxContent.front.status === Image.Ready && !plxContent.back.want) {
                    plxSnap.sourceItem = plxContent.front;
                    plxSnap.scheduleUpdate();
                    plxContent.snapFrames = 3;
                    if (plxContent.qwin) plxContent.qwin.update();
                }
            }
        }
        readonly property string sizeKey: Math.round(width) + "x" + Math.round(height)
        onSizeKeyChanged: plxResizeTimer.restart()
        Timer {
            id: plxResizeTimer
            interval: 300
            onTriggered: if (parallaxLayer.active && plxContent.shownSrc !== "") {
                plxContent.shownSrc = "";
                plxContent.load(globalState.currentWallpaper);
            }
        }
    }

    function refresh() {
        if (active) plxContent.load(globalState.currentWallpaper);
        else { plxContent.snapFrames = 0; plxSnap.sourceItem = null; plxContent.shownSrc = ""; plxImgA.source = ""; plxImgB.source = ""; plxImgA.opacity = 0; plxImgB.opacity = 0; plxImgA.want = false; plxImgB.want = false; }
    }
    onActiveChanged: { refresh(); offX = targetX; offY = targetY; vX = 0; vY = 0; }
    Connections {
        target: globalState
        function onCurrentWallpaperChanged() { parallaxLayer.refresh(); }
    }
    Component.onCompleted: { loadWs(); refresh(); offX = targetX; offY = targetY; }
}
