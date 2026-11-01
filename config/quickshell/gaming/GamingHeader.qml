import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../panels"

// Header row of the gaming panel
RowLayout {
    id: gamingHeader
    visible: gamingWindow.modOn("status")
    Layout.fillWidth: true
    Layout.preferredHeight: 48
    spacing: 8
    Rectangle {
        width: 36; height: 36; radius: 18
        color: ga(pal.primary, 0.16)
        Text { anchors.centerIn: parent; text: ""; font.family: "Material Symbols Rounded"; font.pixelSize: 20; color: pal.primary }
    }
    Text {
        id: gmClock
        text: Qt.formatTime(new Date(), globalState.clockFormat24h ? "HH:mm" : "h:mm AP")
        font.family: globalState.fontPrimary; font.pixelSize: Math.round(20 * globalState.fontScale); font.weight: Font.Bold
        color: pal.colorOnSurface
        Timer {
            interval: 5000; repeat: true; running: gamingWindow.shown; triggeredOnStart: true
            onTriggered: gmClock.text = Qt.formatTime(new Date(), globalState.clockFormat24h ? "HH:mm" : "h:mm AP")
        }
    }
    Item { Layout.fillWidth: true }
    Rectangle {
        id: gmStatusPill
        readonly property int notifCount: notificationsBackend.trackedNotifications.values.length
        readonly property bool wifiUp: globalState.netWifi !== ""
        readonly property bool ethUp: !wifiUp && globalState.netEthCount > 0
        readonly property bool btConn: globalState.btConnectedNames.length > 0
        implicitWidth: gmStatusRow.implicitWidth + 32
        height: 40; radius: 20
        color: globalState.glassMode ? ga(pal.surfaceHigh, 0.6) : pal.surfaceHigh
        RowLayout {
            id: gmStatusRow
            anchors.centerIn: parent
            spacing: 10
            FadeIcon {
                text: gmStatusPill.ethUp ? "" : (globalState.netWifiEnabled ? "" : "")
                font.family: "Material Symbols Rounded"; font.pixelSize: 18
                color: (gmStatusPill.wifiUp || gmStatusPill.ethUp) ? pal.primary : pal.muted
            }
            FadeIcon {
                text: !globalState.netBluetoothEnabled ? "" : (gmStatusPill.btConn ? "" : "")
                font.family: "Material Symbols Rounded"; font.pixelSize: 18
                color: gmStatusPill.btConn ? pal.primary : (globalState.netBluetoothEnabled ? pal.colorOnSurfVar : pal.muted)
            }
            Item { width: 2; height: 1 }
            RowLayout {
                spacing: 4
                FadeIcon {
                    text: globalState.dndEnabled ? "" : ""
                    font.family: "Material Symbols Rounded"; font.pixelSize: 18
                    color: gmStatusPill.notifCount > 0 ? pal.primary : pal.muted
                }
                Text {
                    text: gmStatusPill.notifCount > 99 ? "99+" : gmStatusPill.notifCount
                    font.family: globalState.fontPrimary; font.pixelSize: Math.round(13 * globalState.fontScale); font.weight: Font.Bold
                    color: gmStatusPill.notifCount > 0 ? pal.colorOnSurface : pal.muted
                }
            }
        }
    }
    Rectangle {
        Layout.preferredWidth: 40; Layout.preferredHeight: 40
        radius: m3Ib36Ma.pressed ? Math.max(4, (gmFloatBtnHov.hovered ? 12 : 20) * 0.5) : (gmFloatBtnHov.hovered ? 12 : 20)
        Behavior on radius { M3SpringAnim { token: "spatialFast" } }
        color: {
            var c = gmFloatBtnHov.hovered ? pal.surfacePop : pal.secondaryCont;
            return globalState.glassMode ? ga(c, 0.7) : c;
        }
        Behavior on color { M3ColorAnim {} }
        Text { anchors.centerIn: parent; text: "\ue8aa"; font.family: "Material Symbols Rounded"; font.pixelSize: 18; color: pal.primary }
        HoverHandler { id: gmFloatBtnHov }
        MouseArea { id: m3Ib36Ma; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: globalState.setGamingFloating(true) }
    }
    ClipIconButton {
        width: 40; height: 40; radius: 20
        glyph: ""
        iconColor: pal.colorOnSurfVar; activeColor: pal.primary; hoverColor: ga(pal.colorOnSurfVar, 0.14)
        onClicked: globalState.toggleGaming()
    }
}
