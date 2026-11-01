import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Interface row of the network bulge popup
Rectangle {
    id: netRow
    required property var modelData
    required property int index
    readonly property int groupCount: active ? netBulgePopup.connectedList.length : netBulgePopup.otherList.length
    readonly property bool first: index === 0
    readonly property bool last: index === groupCount - 1
    readonly property bool isWifi: netContent.isWifi
    readonly property bool active: isWifi ? modelData.inUse === true : modelData.connected === true
    readonly property bool busy: isWifi ? globalState.wifiConnectingSsid === modelData.ssid
    : globalState.btPendingMac === modelData.mac
    Layout.fillWidth: true
    Layout.preferredHeight: netBulgePopup.rowH - 2
    Layout.bottomMargin: last ? 6 : 2
    topLeftRadius: first ? 16 : 4; topRightRadius: first ? 16 : 4
    bottomLeftRadius: last ? 16 : 4; bottomRightRadius: last ? 16 : 4
    color: {
        var c = netRow.active ? m3.secondaryContainer : netConnectedRepeater._card;
        c = netRowHov.hovered ? Qt.tint(c, Qt.rgba(netConnectedRepeater._text.r, netConnectedRepeater._text.g, netConnectedRepeater._text.b, 0.08)) : c;
        return globalState.glassMode ? ga(c, 0.6) : c;
    }
    Behavior on color { M3ColorAnim { duration: m3.durFast } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8; anchors.rightMargin: 10
        spacing: 8
        Rectangle {
            width: 26; height: 26
            radius: netRow.active ? 8 : 13
            Behavior on radius { M3SpringAnim { token: "spatialFast" } }
            color: netRow.active ? netConnectedRepeater._primary : "transparent"
            ELoading { anchors.centerIn: parent; size: 20; visible: netRow.busy; running: netRow.busy; color: netRow.active ? netConnectedRepeater._onPrimary : netConnectedRepeater._primary }
            FadeIcon {
                visible: !netRow.busy
                anchors.centerIn: parent
                text: netRow.isWifi
                ? (netRow.modelData.strength >= 60 ? "\ue1d8" : (netRow.modelData.strength >= 30 ? "\ue1d9" : "\ue1da"))
                : "\ue1a7"
                font.family: "Material Symbols Rounded"; font.pixelSize: 15
                color: netRow.active ? netConnectedRepeater._onPrimary : netConnectedRepeater._muted
            }
        }
        Text {
            Layout.fillWidth: true
            text: netRow.isWifi ? netRow.modelData.ssid : (netRow.modelData.name || netRow.modelData.mac)
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
            color: netConnectedRepeater._text
            elide: Text.ElideRight
        }
        Text {
            visible: netRow.isWifi && netRow.modelData.secured === true
            text: "\ue897"
            font.family: "Material Symbols Rounded"; font.pixelSize: 12
            color: netConnectedRepeater._muted
        }
        Text {
            text: netRow.busy ? "…"
            : netRow.active ? tr("bt_disconnect")
            : (netRow.isWifi ? (netRow.modelData.strength + "%") : tr("bt_connect"))
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale); font.weight: Font.Medium
            color: netRowHov.hovered ? netConnectedRepeater._primary : netConnectedRepeater._muted
        }
    }
    HoverHandler { id: netRowHov }
    MouseArea {
        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
        enabled: !netRow.busy
        onClicked: {
            var m = netRow.modelData;
            if (netRow.isWifi) {
                if (m.inUse) globalState.wifiDisconnect(m.ssid);
                else if (m.secured && !m.saved) {
                    netBulgePopup.openSettings();
                    globalState.wifiRequestPassword(m.ssid);
                } else globalState.wifiConnect(m.ssid, "");
            } else {
                globalState.btConnectOrDisconnect(m.mac, m.paired, m.connected);
            }
        }
    }
}
