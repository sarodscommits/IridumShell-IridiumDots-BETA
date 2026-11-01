import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../controlcenter"

// Menu that morphs out of a Control Center tile
Item {
    id: pmHost
    readonly property real dimRadius: parent && parent.dimRadius !== undefined ? parent.dimRadius : 24
    property Item srcTile: null
    property bool isOpen: false
    property real p: 0
    readonly property bool active: isOpen || p > 0.001 || pmAnim.running
    readonly property real pc: Math.max(0, Math.min(1, p))
    visible: active

    property real sx: 0; property real sy: 0; property real sw: 0; property real sh: 0
    readonly property real tw: Math.min(width - 40, 320)
    readonly property real th: Math.min(height - 40, pmShape.pmMenuCol.implicitHeight + 16)
    readonly property real tx: (width - tw) / 2
    readonly property real ty: (height - th) / 2

    readonly property string prof: globalState.perfProfile
    readonly property string kind: srcTile && srcTile.menuKind ? srcTile.menuKind : "perf"

    function _grab() {
        if (!srcTile) return;
        var o = srcTile.mapToItem(pmHost, 0, 0);
        sx = o.x; sy = o.y; sw = srcTile.width; sh = srcTile.height;
    }
    function openFor(tile) {
        if (globalState.ncEditMode) return;
        if (srcTile && srcTile !== tile) { pmAnim.stop(); p = 0; }
        srcTile = tile;
        _grab();
        isOpen = true;
        pmAnim.stop();
        pmAnim.to = 1; pmAnim.duration = 460; pmAnim.easing.type = Easing.OutBack; pmAnim.easing.overshoot = 1.15;
        pmAnim.start();
        pmHost.forceActiveFocus();
    }
    function close() {
        if (!isOpen) return;
        _grab();
        isOpen = false;
        pmAnim.stop();
        pmAnim.to = 0; pmAnim.duration = 380; pmAnim.easing.type = Easing.OutBack; pmAnim.easing.overshoot = 0.9;
        pmAnim.start();
    }
    NumberAnimation { id: pmAnim; target: pmHost; property: "p"; duration: 460 }

    function lerp(a, b, t) { return a + (b - a) * t; }
    function mix(a, b, t) { return Qt.rgba(lerp(a.r, b.r, t), lerp(a.g, b.g, t), lerp(a.b, b.b, t), lerp(a.a, b.a, t)); }

    Connections {
        target: globalState
        function onNcEditModeChanged() { pmHost.close(); }
        function onNotchControlOpenChanged() { pmHost.close(); }
        function onIslandControlOpenChanged() { pmHost.close(); }
    }
    Keys.onEscapePressed: pmHost.close()

    Rectangle {
        anchors.fill: parent
        radius: pmHost.dimRadius
        color: "black"
        opacity: 0.45 * pmHost.pc
    }
    MouseArea {
        anchors.fill: parent
        enabled: pmHost.isOpen
        acceptedButtons: Qt.AllButtons
        onClicked: pmHost.close()
        onWheel: (w) => { w.accepted = true; }
    }

    PerfMorphShape { id: pmShape }
}
