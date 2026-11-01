import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Network speed bulge popup
Item {
    id: netBulgePopup
    property alias netBulgePopupHover: netBulgePopupHover
    readonly property bool isOpen: globalState.netBulgeOpen
    readonly property string kind: globalState.netBulgeKind
    property Item trigger: null
    readonly property real natW: 360
    readonly property real bulgeW: natW * unifiedFrame.bulgeScale
    readonly property real rowH: 44
    property var connectedList: []
    property var otherList: []
    readonly property real listDepth: {
        var d = 14 + 36 + 12;
        if (connectedList.length > 0) d += 20 + connectedList.length * rowH;
        var radioOn = (kind === "wifi") ? globalState.netWifiEnabled : globalState.netBluetoothEnabled;
        d += 20 + (otherList.length > 0 ? otherList.length * rowH : (radioOn ? 84 : 40));
        return d + 12;
    }

    x: unifiedFrame.barVertical ? unifiedFrame.popupRealX(width) : unifiedFrame.bulgeLeftX
    width: unifiedFrame.barVertical ? unifiedFrame.bulgeDepth : Math.max(0, unifiedFrame.bulgeRightX - unifiedFrame.bulgeLeftX)
    height: unifiedFrame.barVertical ? Math.max(0, unifiedFrame.bulgeRightX - unifiedFrame.bulgeLeftX) : unifiedFrame.bulgeDepth
    opacity: isOpen ? 1 : 0
    Behavior on opacity { M3NumberAnim { duration: netBulgePopup.isOpen ? 220 : 140 } }
    visible: opacity > 0.01
    enabled: isOpen
    y: unifiedFrame.barVertical ? unifiedFrame.bulgeLeftX
    : (unifiedFrame.barAtBottom ? (frameRoot.height - unifiedFrame.frameBottomH - height) : unifiedFrame.frameTopH)
    z: 1000
    clip: true

    function refreshLists() {
        var con = [], oth = [];
        if (kind === "wifi") {
            for (var i = 0; i < wifiNetworksModel.count; i++) {
                var n = wifiNetworksModel.get(i);
                var o = { ssid: n.ssid, strength: n.strength, secured: n.secured, inUse: n.inUse, saved: n.saved };
                if (o.inUse) con.push(o); else if (oth.length < 5) oth.push(o);
            }
        } else {
            var seen = {};
            for (var j = 0; j < btPairedModel.count; j++) {
                var p = btPairedModel.get(j);
                if (seen[p.mac]) continue; seen[p.mac] = true;
                var po = { mac: p.mac, name: p.name, paired: p.paired, connected: p.connected };
                if (po.connected) con.push(po); else if (oth.length < 5) oth.push(po);
            }
            for (var k = 0; k < btAvailableModel.count; k++) {
                var a = btAvailableModel.get(k);
                if (seen[a.mac]) continue; seen[a.mac] = true;
                var ao = { mac: a.mac, name: a.name, paired: a.paired, connected: a.connected };
                if (ao.connected) con.push(ao); else if (oth.length < 5) oth.push(ao);
            }
        }
        connectedList = con.slice(0, 2);
        otherList = oth;
    }
    onListDepthChanged: if (isOpen) reposition()

    function reposition() {
        if (trigger) unifiedFrame.setBulgeUnder(netBulgePopup, trigger, listDepth * unifiedFrame.bulgeScale);
    }
    function showFor(k, item) {
        netCloseTimer.stop();
        var switching = !globalState.netBulgeOpen || globalState.netBulgeKind !== k;
        if (!globalState.netBulgeOpen) globalState.closeOthers("net");
        trigger = item;
        globalState.netBulgeKind = k;
        if (switching) startScan(k);
        refreshLists();
        if (globalState.netBulgeOpen) reposition();
        else globalState.netBulgeOpen = true;
    }
    function scheduleClose() { netCloseTimer.restart(); }
    function settingsConnVisible() { return globalState.settingsOpen && globalState.settingsSection === "connections"; }
    function startScan(k) {
        if (k === "wifi") { globalState.wifiConnectError = ""; globalState.wifiScanNetworks(); }
        else networkBackend.btCtlProcRef.running = true;
    }
    function stopScans() {
        if (settingsConnVisible()) return;
        if (!globalState.wifiViewOpen) networkBackend.wifiScanProcRef.running = false;
        if (!globalState.btDevicesViewOpen) {
            if (networkBackend.btCtlProcRef.running) networkBackend.btCtlProcRef.write("scan off\n");
            networkBackend.stopBtScan();
        }
    }
    function openSettings() {
        globalState.netBulgeOpen = false;
        globalState.notchControlOpen = false;
        globalState.settingsOpen = true;
        globalState.settingsSection = "connections";
    }

    onIsOpenChanged: {
        if (isOpen) reposition();
        else { unifiedFrame.setBulgeUnder(netBulgePopup, trigger, 0); stopScans(); }
    }

    HoverHandler {
        id: netBulgePopupHover
        onHoveredChanged: { if (hovered) netCloseTimer.stop(); else netBulgePopup.scheduleClose(); }
    }
    Timer {
        id: netCloseTimer
        interval: 260
        repeat: false
        onTriggered: {
            if (!netBulgePopupHover.hovered && !topBarContent.topBarHover.hovered)
            globalState.netBulgeOpen = false;
        }
    }
    Timer {
        interval: 600
        repeat: true
        running: netBulgePopup.isOpen
        onTriggered: netBulgePopup.refreshLists()
    }
    Connections {
        target: globalState
        function onBtPromptTypeChanged() {
            if (netBulgePopup.isOpen && globalState.btPromptType !== "") netBulgePopup.openSettings();
        }
    }

    Item {
        id: netContent
        width: netBulgePopup.natW
        x: unifiedFrame.barVertical ? (unifiedFrame.barAtLeft ? 0 : parent.width - width) : (parent.width - width) / 2
        height: netBulgePopup.listDepth
        scale: unifiedFrame.bulgeScale
        transformOrigin: unifiedFrame.popupOrigin
        y: unifiedFrame.barVertical ? (parent.height - height) / 2 : (unifiedFrame.barAtBottom ? parent.height - height : 0)

        readonly property bool isWifi: netBulgePopup.kind === "wifi"
        readonly property bool radioOn: isWifi ? globalState.netWifiEnabled : globalState.netBluetoothEnabled
        readonly property bool radioBusy: isWifi ? globalState.wifiRadioBusy : globalState.btRadioBusy

        NetworkBulgeHeader { id: netHeader }

        ColumnLayout {
            x: 12
            y: netHeader.y + netHeader.height + 12
            width: parent.width - 24
            spacing: 0

            Text {
                visible: netBulgePopup.connectedList.length > 0
                Layout.preferredHeight: 20
                Layout.leftMargin: 4
                verticalAlignment: Text.AlignVCenter
                text: tr("bt_connected")
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium
                color: pal.muted
            }
            Repeater {
                id: netConnectedRepeater
                model: netBulgePopup.connectedList
                property color _primary: pal.primary
                property color _onPrimary: pal.colorOnPrimary
                property color _text: pal.colorOnSurface
                property color _muted: pal.muted
                property color _hover: pal.surfaceVar
                property color _card: containerDark(pal.secondaryCont)
                delegate: netRowComponent
            }

            Text {
                Layout.preferredHeight: 20
                Layout.leftMargin: 4
                verticalAlignment: Text.AlignVCenter
                text: netContent.isWifi ? tr("wifi") : tr("bt_available_devices")
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium
                color: pal.muted
            }
            Repeater {
                id: netOtherRepeater
                model: netBulgePopup.otherList
                property color _primary: pal.primary
                property color _onPrimary: pal.colorOnPrimary
                property color _text: pal.colorOnSurface
                property color _muted: pal.muted
                property color _hover: pal.surfaceVar
                property color _card: containerDark(pal.secondaryCont)
                delegate: netRowComponent
            }
            Item {
                visible: netBulgePopup.otherList.length === 0 && netContent.radioOn
                Layout.fillWidth: true
                Layout.preferredHeight: 84
                MorphLoader {
                    anchors.centerIn: parent
                    size: 56
                    fillColor: pal.primary
                    running: parent.visible && netBulgePopup.isOpen
                }
            }
            Text {
                visible: netBulgePopup.otherList.length === 0 && !netContent.radioOn
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: tr("radio_off")
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale)
                color: pal.muted
            }
        }

        Component {
            id: netRowComponent
            NetworkBulgeRow { id: netRow }
        }
    }
}
