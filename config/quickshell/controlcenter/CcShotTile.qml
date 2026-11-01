import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Screenshot tile of the Control Center grid
Rectangle {
    id: ncShotTile
    property var _host: null
    function morphHost() {
        if (_host) return _host;
        for (var p = parent; p; p = p.parent) {
            var ch = p.children;
            for (var i = 0; i < ch.length; i++)
            if (ch[i] && ch[i].isPerfMorphHost === true && ch[i].item) { _host = ch[i].item; return _host; }
        }
        return null;
    }
    readonly property bool menuOpen: _host !== null && _host.srcTile === ncShotTile && _host.isOpen
    readonly property bool morphing: _host !== null && _host.srcTile === ncShotTile && _host.active
    readonly property bool _hl: menuOpen
    readonly property bool _arrow: width >= 84
    readonly property string menuKind: "shot"
    readonly property string menuTitle: tr("take_screenshot")
    readonly property string morphIcon: ""
    readonly property string morphName: tr("take_screenshot")
    readonly property var opts: [
    { v: "full", icon: "\ue5d0", name: tr("shot_full"), desc: tr("shot_full_d") },
    { v: "area", icon: "\ue3c2", name: tr("shot_area"), desc: tr("shot_area_d") }
    ]
    function isSel(v) { return false; }
    function choose(v) {
        if (v === "full") { globalState.shotFull(); return; }
        globalState.closeControlPanels();
        if (bottomBarFocusGrab.active) { globalState.waitingForGrabRelease = true; }
        else { globalState.selectCaptureTrigger++; }
    }
    radius: ncShotTileMa.pressed ? 12 : ((menuOpen) ? 16 : height / 2)
    Behavior on radius { M3SpringAnim { token: "spatialDefault" } }
    color: { var c = _hl ? pal.primary : containerDark(pal.secondaryCont); return (globalState.glassMode && !_hl) ? ga(c, 0.78) : c; }
    Behavior on color { M3ColorAnim {} }
    opacity: morphing ? 0 : 1
    Rectangle { anchors.fill: parent; radius: parent.radius; color: ((menuOpen) ? pal.colorOnPrimary : pal.colorOnSurface); opacity: ncShotTileMa.pressed ? 0.12 : (ncSsHov.hovered ? 0.08 : 0); Behavior on opacity { NumberAnimation { duration: m3.durFast } } }
    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width - (ncShotTile._arrow ? 40 : 6)
        spacing: 2
        opacity: globalState.glassMode ? 0.88 : 1.0
        Text { Layout.alignment: Qt.AlignHCenter; text: ncShotTile.morphIcon; font.family: "Material Symbols Rounded"; font.pixelSize: 24; color: ncShotTile._hl ? pal.colorOnPrimary : pal.primary }
        Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: tr("take_screenshot"); font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium; color: ncShotTile._hl ? pal.colorOnPrimary : pal.colorOnSurface }
    }
    Text {
        visible: ncShotTile._arrow
        anchors.right: parent.right; anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: "\ue5e1"
        font.family: "Material Symbols Rounded"; font.pixelSize: 13
        color: ncShotTile._hl ? pal.colorOnPrimary : pal.primary
        opacity: globalState.glassMode ? 0.75 : 0.85
        Behavior on color { M3ColorAnim {} }
    }
    HoverHandler { id: ncSsHov }
    MouseArea { id: ncShotTileMa;
        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
        enabled: !globalState.ncEditMode
        onClicked: {
            globalState.playUiClick();
            var h = ncShotTile.morphHost();
            if (!h) { ncShotTile.choose("area"); return; }
            if (ncShotTile.menuOpen) { h.close(); return; }
            h.openFor(ncShotTile);
        }
    }
}
