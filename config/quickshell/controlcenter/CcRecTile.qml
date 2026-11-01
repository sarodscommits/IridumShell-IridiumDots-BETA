import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Screen recording tile of the Control Center grid
Rectangle {
    id: ncRecTile
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
    readonly property bool menuOpen: _host !== null && _host.srcTile === ncRecTile && _host.isOpen
    readonly property bool morphing: _host !== null && _host.srcTile === ncRecTile && _host.active
    readonly property bool on: globalState.recBusy
    readonly property bool _hl: on || menuOpen
    readonly property bool _arrow: width >= 84 && !on
    readonly property string menuKind: "rec"
    readonly property string menuTitle: tr("screen_record")
    readonly property string morphIcon: "\ue061"
    readonly property string morphName: tr("nce_rec")
    readonly property var opts: []
    function isSel(v) { return false; }
    function choose(v) {}
    radius: ncRecTileMa.pressed ? 12 : ((on || menuOpen) ? 16 : height / 2)
    Behavior on radius { M3SpringAnim { token: "spatialDefault" } }
    color: { var c = _hl ? pal.primary : containerDark(pal.secondaryCont); return (globalState.glassMode && !_hl) ? ga(c, 0.78) : c; }
    Behavior on color { M3ColorAnim {} }
    opacity: morphing ? 0 : 1
    Rectangle { anchors.fill: parent; radius: parent.radius; color: ((on || menuOpen) ? pal.colorOnPrimary : pal.colorOnSurface); opacity: ncRecTileMa.pressed ? 0.12 : (ncRecHov.hovered ? 0.08 : 0); Behavior on opacity { NumberAnimation { duration: m3.durFast } } }
    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width - (ncRecTile._arrow ? 40 : 6)
        spacing: 2
        opacity: globalState.glassMode ? 0.88 : 1.0
        FadeIcon { Layout.alignment: Qt.AlignHCenter; text: ncRecTile.on ? "\ue047" : "\ue061"; font.family: "Material Symbols Rounded"; font.pixelSize: 24; color: ncRecTile._hl ? pal.colorOnPrimary : pal.primary }
        Text {
            Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
            text: globalState.recSaving ? tr("rec_saving") : (globalState.recActive ? globalState.recFmt(globalState.recElapsedMs) : tr("nce_rec"))
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
            color: ncRecTile._hl ? pal.colorOnPrimary : pal.colorOnSurface
        }
    }
    Text {
        visible: ncRecTile._arrow
        anchors.right: parent.right; anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: "\ue5e1"
        font.family: "Material Symbols Rounded"; font.pixelSize: 13
        color: ncRecTile._hl ? pal.colorOnPrimary : pal.primary
        opacity: globalState.glassMode ? 0.75 : 0.85
        Behavior on color { M3ColorAnim {} }
    }
    HoverHandler { id: ncRecHov }
    MouseArea { id: ncRecTileMa;
        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
        enabled: !globalState.ncEditMode
        onClicked: {
            globalState.playUiClick();
            if (globalState.recBusy) { globalState.recToggle(); return; }
            var h = ncRecTile.morphHost();
            if (!h) { globalState.recToggle(); return; }
            if (ncRecTile.menuOpen) { h.close(); return; }
            h.openFor(ncRecTile);
        }
    }
}
