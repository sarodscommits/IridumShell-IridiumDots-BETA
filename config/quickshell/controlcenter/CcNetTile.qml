import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Network tile of the Control Center grid
Rectangle {
    id: ncNetTile
    readonly property string k: parent && parent.ctlKey ? parent.ctlKey : "wifi"
    readonly property bool isWifi: k === "wifi"
    property bool on: isWifi
    ? (globalState.wifiPendingOn !== -1 ? globalState.wifiPendingOn === 1 : globalState.netWifiEnabled)
    : (globalState.btPendingOn !== -1 ? globalState.btPendingOn === 1 : globalState.netBluetoothEnabled)
    property bool busy: isWifi ? globalState.wifiRadioBusy : globalState.btRadioBusy
    readonly property bool _darken: on
    opacity: busy ? 0.55 : 1.0
    Behavior on opacity { M3NumberAnim { duration: m3.durFast } }
    radius: ncNetTileMa.pressed ? 12 : Math.min(18, height / 2)
    Behavior on radius { M3SpringAnim { token: "spatialDefault" } }
    color: {
        var c = _darken ? pal.primary : containerDark(pal.secondaryCont);
        return (globalState.glassMode && !_darken) ? ga(c, 0.78) : c;
    }
    Behavior on color { M3ColorAnim {} }
    readonly property string detail: !on ? ""
    : (isWifi ? globalState.netWifi
    : (globalState.btConnectedNames.length > 0 ? globalState.btConnectedNames[0] : ""))
    readonly property int extra: isWifi ? 0 : Math.max(0, globalState.btConnectedNames.length - 1)
    readonly property string title: isWifi ? tr("wifi") : tr("bluetooth")
    // Same layout in both states: square icon box at the left, label at its right
    readonly property real inset: 6
    readonly property real boxS: Math.max(0, height - inset * 2)
    readonly property real textX: inset + boxS + 12
    readonly property bool showText: width >= textX + 28
    readonly property color fgMain: _darken ? pal.colorOnPrimary : pal.colorOnSurface

    Rectangle { anchors.fill: parent; radius: parent.radius; color: ((on) ? pal.colorOnPrimary : pal.colorOnSurface); opacity: ncNetTileMa.pressed ? 0.12 : (ncNetHov.hovered ? 0.08 : 0); Behavior on opacity { NumberAnimation { duration: m3.durFast } } }
    Rectangle {
        id: ncNetBox
        width: ncNetTile.boxS; height: ncNetTile.boxS
        x: ncNetTile.showText ? ncNetTile.inset : (ncNetTile.width - width) / 2
        y: ncNetTile.inset
        radius: Math.max(4, ncNetTile.radius - ncNetTile.inset + 2)
        color: pal.primary
        FadeIcon {
            id: ncNetIcon
            anchors.centerIn: parent
            text: ncNetTile.isWifi ? (ncNetTile.on ? "" : "") : (ncNetTile.detail !== "" ? "" : "")
            font.family: "Material Symbols Rounded"; font.pixelSize: 24
            color: pal.colorOnPrimary
        }
    }
    Text {
        id: ncNetName
        visible: ncNetTile.showText
        x: ncNetTile.textX
        width: ncNetTile.width - x - 14
        anchors.verticalCenter: parent.verticalCenter
        text: (ncNetTile.detail !== "" ? ncNetTile.detail : ncNetTile.title) + (ncNetTile.extra > 0 ? "  +" + ncNetTile.extra : "")
        elide: Text.ElideRight
        maximumLineCount: 1
        font.family: globalState.fontPrimary; font.pixelSize: Math.round(14 * globalState.fontScale); font.weight: Font.DemiBold
        color: ncNetTile.fgMain
        opacity: globalState.glassMode ? 0.92 : 1.0
        Behavior on color { M3ColorAnim {} }
    }
    HoverHandler { id: ncNetHov }
    MouseArea { id: ncNetTileMa;
        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
        enabled: !ncNetTile.busy
        property int _clicks: 0
        onClicked: { globalState.playUiClick();
            _clicks++;
            if (_clicks === 1) { ncNetClickTimer.restart(); return; }
            _clicks = 0; ncNetClickTimer.stop();
            globalState.closeControlPanels();
            globalState.settingsOpen = true;
            globalState.settingsSection = "connections";
        }
        Timer {
            id: ncNetClickTimer; interval: 280; repeat: false
            onTriggered: {
                parent._clicks = 0;
                if (ncNetTile.isWifi) globalState.wifiSetEnabled(!globalState.netWifiEnabled);
                else globalState.btSetEnabled(!globalState.netBluetoothEnabled);
            }
        }
    }
}
