import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "./windowswitcher"
import "./windowswitcher/LayoutEngine.js" as LayoutEngine

// Window switcher (Super+Tab) entry point; logic lives in ./windowswitcher
PanelWindow {
    id: win
    required property var gs
    required property var colors

    // same namespace as the wallpaper picker to inherit its Hyprland blur rules
    WlrLayershell.namespace: "quickshell"
    WlrLayershell.layer: WlrLayer.Overlay
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    color: "transparent"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    readonly property bool open: gs.windowSwitcherOpen
    function ga(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }
    readonly property real tileRadius: 18
    visible: open || fade > 0.01
    property real fade: open ? 1 : 0
    Behavior on fade { NumberAnimation { duration: open ? 220 : 160; easing.type: Easing.OutCubic } }

    // ── layout parameters ──
    readonly property int  perPageMax: 8
    readonly property real gap: 14
    readonly property real aspMin: 0.45
    readonly property real aspMax: 2.6
    readonly property real pageW: Math.min(width * 0.86, 1500)
    readonly property real pageH: Math.min(height * 0.55, 720)
    readonly property real wsStripH: 128
    readonly property real wsCardH: 104
    readonly property real pageSpacing: 80

    // ── state ──
    property var items: []          // ordered (MRU) snapshot of the workspace's windows
    property var pages: []          // [{ tiles: [{i, c, x, y, w, h, row}] }]
    property var pageOf: []         // window index -> page
    property int selected: 0
    property int currentPage: 0
    property bool wsMode: false     // keyboard focus on the workspaces menu
    property int  wsSel: 0
    readonly property var wsList: gs.openWorkspaces && gs.openWorkspaces.length ? gs.openWorkspaces : [gs.activeWorkspace]
    property bool warm: true        // on open all captures stay live until the "peeked" windows render
    property int shownWs: -1
    property alias warmTimer: warmTimerItem

    readonly property var ops: WindowOps {}
    readonly property var nav: Navigation {}

    function snapshot() { items = ops.sortedForWorkspace(win, gs.activeWorkspace); }
    function relayout() { LayoutEngine.relayout(win); }

    onItemsChanged: relayout()
    onPageWChanged: relayout()
    onPageHChanged: relayout()

    function select(i) { nav.select(win, i); }
    function stepPage(d) { nav.stepPage(win, d); }
    function moveVertical(d) { nav.moveVertical(win, d); }
    function switchWorkspace(id) { nav.switchWorkspace(win, id); }

    function peekAll() { ops.peekAll(win); }
    function finish(chosen, wsTarget) { ops.finish(win, chosen, wsTarget); }
    function activate(i) { ops.activate(win, i); }
    function closeWindow(i) { ops.closeWindow(win, i); }
    function toplevelFor(c) { return ops.toplevelFor(win, c); }
    function runRestore(addrs) { ops.runRestore(win, addrs); }
    function refreshItems() { ops.refreshItems(win); }
    function onWorkspaceChanged() { ops.onWorkspaceChanged(win); }

    Timer { id: wsChangeTimer; interval: 140; onTriggered: win.onWorkspaceChanged() }
    Timer { id: clientsChangeTimer; interval: 220; onTriggered: win.refreshItems() }
    Connections {
        target: win.gs
        function onActiveWorkspaceChanged() { if (win.open) wsChangeTimer.restart(); }
        function onOpenClientsChanged()     { if (win.open) clientsChangeTimer.restart(); }
    }
    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() { if (win.open) wsChangeTimer.restart(); }
    }

    Timer { id: warmTimerItem; interval: 800; onTriggered: win.warm = false }

    function onOpened() {
        shownWs = gs.activeWorkspace;
        warm = true;
        wsMode = false;
        wsSel = Math.max(0, wsList.indexOf(gs.activeWorkspace));
        snapshot();
        // Like Alt+Tab: the previous window (second in focus order) is preselected.
        selected = items.length > 1 ? 1 : 0;
        currentPage = pageOf[selected] || 0;
        peekAll();
        warmTimer.restart();
        keys.forceActiveFocus();
    }
    onOpenChanged: if (open) onOpened()
    Component.onCompleted: if (open) onOpened()

    // ── UI ──
    Item {
        id: keys
        anchors.fill: parent
        focus: true
        opacity: win.fade

        Keys.onEscapePressed: win.finish("")
        Keys.onReturnPressed: win.wsMode ? win.switchWorkspace(win.wsList[win.wsSel]) : win.activate(win.selected)
        Keys.onEnterPressed: win.wsMode ? win.switchWorkspace(win.wsList[win.wsSel]) : win.activate(win.selected)
        Keys.onLeftPressed: win.wsMode ? win.wsSel = (win.wsSel + win.wsList.length - 1) % win.wsList.length : win.select(win.selected - 1)
        Keys.onRightPressed: win.wsMode ? win.wsSel = (win.wsSel + 1) % win.wsList.length : win.select(win.selected + 1)
        Keys.onUpPressed: {
            if (win.wsMode) win.wsMode = false;
            else win.moveVertical(-1);
        }
        Keys.onDownPressed: {
            if (win.wsMode) return;
            var before = win.selected;
            win.moveVertical(1);
            if (win.selected === before) win.wsMode = true;
        }
        Keys.onPressed: (e) => {
            if (e.key === Qt.Key_Tab) { if (win.wsMode) win.wsSel = (win.wsSel + 1) % win.wsList.length; else win.select(win.selected + 1); e.accepted = true; }
            else if (e.key === Qt.Key_Backtab) { win.select(win.selected - 1); e.accepted = true; }
            else if (e.key === Qt.Key_PageDown) { win.stepPage(1); e.accepted = true; }
            else if (e.key === Qt.Key_PageUp) { win.stepPage(-1); e.accepted = true; }
        }

        Rectangle {
            anchors.fill: parent
            color: "#4D000000"
            MouseArea {
                anchors.fill: parent
                onClicked: win.finish("")
                onWheel: (w) => win.stepPage(w.angleDelta.y < 0 ? 1 : -1)
            }
        }

        SwitcherChrome { win: win; pagerItem: pager }

        PagerView { id: pager; win: win }

        WorkspaceStrip { win: win }
    }
}
