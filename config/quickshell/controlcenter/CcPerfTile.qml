import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Performance profile tile of the Control Center grid
Rectangle {
    id: ncPerfTile
    readonly property string prof: globalState.perfProfile
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
    readonly property bool menuOpen: _host !== null && _host.srcTile === ncPerfTile && _host.isOpen
    readonly property bool morphing: _host !== null && _host.srcTile === ncPerfTile && _host.active
    readonly property bool _hl: menuOpen
    readonly property var opts: [
    { v: "low",    icon: "", name: tr("perf_low"),    desc: tr("perf_low_d") },
    { v: "medium", icon: "", name: tr("perf_medium"), desc: tr("perf_medium_d") },
    { v: "high",   icon: "", name: tr("perf_high"),   desc: tr("perf_high_d") }
    ]
    function optFor(v) { for (var i = 0; i < opts.length; i++) if (opts[i].v === v) return opts[i]; return null; }
    readonly property string menuKind: "perf"
    readonly property string menuTitle: tr("nce_perf")
    readonly property string morphIcon: { var o = optFor(prof); return o ? o.icon : ""; }
    readonly property string morphName: { var o = optFor(prof); return o ? o.name : tr("nce_perf"); }
    function isSel(v) { return prof === v; }
    function choose(v) { gamingWindow.setPerfProfile(v); }
    radius: ncPerfTileMa.pressed ? 12 : ((menuOpen) ? 16 : height / 2)
    Behavior on radius { M3SpringAnim { token: "spatialDefault" } }
    color: { var c = _hl ? pal.primary : containerDark(pal.secondaryCont); return (globalState.glassMode && !_hl) ? ga(c, 0.78) : c; }
    Behavior on color { M3ColorAnim {} }
    opacity: morphing ? 0 : (globalState.perfApplying ? 0.7 : 1.0)
    Rectangle { anchors.fill: parent; radius: parent.radius; color: ((menuOpen) ? pal.colorOnPrimary : pal.colorOnSurface); opacity: ncPerfTileMa.pressed ? 0.12 : (ncPerfHov.hovered ? 0.08 : 0); Behavior on opacity { NumberAnimation { duration: m3.durFast } } }
    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width - 6
        spacing: 2
        opacity: globalState.glassMode ? 0.88 : 1.0
        FadeIcon {
            Layout.alignment: Qt.AlignHCenter
            text: { var o = ncPerfTile.optFor(ncPerfTile.prof); return o ? o.icon : ""; }
            font.family: "Material Symbols Rounded"; font.pixelSize: 24
            color: ncPerfTile._hl ? pal.colorOnPrimary : pal.primary
        }
        Text {
            Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
            text: globalState.perfApplying ? tr("gm_perf_applying")
            : (function () { var o = ncPerfTile.optFor(ncPerfTile.prof); return o ? o.name : tr("nce_perf"); })()
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
            color: ncPerfTile._hl ? pal.colorOnPrimary : pal.colorOnSurface
        }
    }
    HoverHandler { id: ncPerfHov }
    MouseArea { id: ncPerfTileMa;
        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
        enabled: !globalState.ncEditMode
        onClicked: { globalState.playUiClick();
            var h = ncPerfTile.morphHost();
            if (!h) return;
            if (ncPerfTile.menuOpen) { h.close(); return; }
            if (!gmPerfReadProc.running && !gmPerfProc.running) gmPerfReadProc.running = true;
            h.openFor(ncPerfTile);
        }
    }
}
