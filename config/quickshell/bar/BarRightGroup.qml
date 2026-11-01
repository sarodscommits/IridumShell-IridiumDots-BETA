import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Right-hand group of bar modules
RowLayout {
    id: barGroupRight
    property alias battBtn: battBtn
    property alias btBtn: btBtn
    property alias clipBtn: clipBtn
    property alias gamingBtn: gamingBtn
    property alias notifBtn: notifBtn
    property alias privBtn: privBtn
    property alias sessionBtnWrap: sessionBtnWrap
    property alias wifiBtn: wifiBtn
    visible: !unifiedFrame.islandMode
    spacing: 10
    Behavior on x {
        enabled: !globalState.desktopZoomBusy && unifiedFrame.startupSettled && !globalState.desktopEditMode
        M3SpringAnim { token: "spatialFast" }
    }


    Item {
        id: gamingBtn
        Layout.alignment: Qt.AlignCenter
        visible: globalState.barModules.gaming
        width: 28; height: 28
        EBarSlot { anchors.fill: parent; active: globalState.gamingOpen; hovered: gamingBtnMa.containsMouse; pressed: gamingBtnMa.pressed }
        Text {
            anchors.centerIn: parent
            text: "\uea28"
            font.family: "Material Symbols Rounded"; font.pixelSize: 16
            color: globalState.gamingOpen ? pal.primary : pal.muted
            opacity: globalState.glassMode ? 0.88 : 1.0
            Behavior on color { M3ColorAnim {} }
        }
        MouseArea {
            id: gamingBtnMa
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
            onClicked: globalState.toggleGaming()
        }
    }

    BarNotifButton { id: notifBtn }

    BarPrivacyButton { id: privBtn }

    BarClipButton { id: clipBtn }

    Item {
        id: wifiBtn
        Layout.alignment: Qt.AlignCenter
        visible: globalState.barModules.wifi
        width: 28; height: 28
        EBarSlot { anchors.fill: parent; active: netBulgePopup.isOpen && globalState.netBulgeKind === "wifi"; hovered: wifiBtnHover.hovered }
        FadeIcon {
            anchors.centerIn: parent
            text: globalState.netWifiEnabled ? "\ue1d8" : "\ue1da"
            font.family: "Material Symbols Rounded"; font.pixelSize: 15
            color: globalState.netWifiEnabled ? pal.primary : pal.muted
            opacity: globalState.glassMode ? 0.88 : 1.0
            Behavior on color { M3ColorAnim {} }
        }
        HoverHandler {
            id: wifiBtnHover
            onHoveredChanged: {
                if (hovered) netBulgePopup.showFor("wifi", parent);
                else netBulgePopup.scheduleClose();
            }
        }
        MouseArea {
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: netBulgePopup.openSettings()
        }
    }

    Item {
        id: btBtn
        Layout.alignment: Qt.AlignCenter
        visible: globalState.barModules.bluetooth
        width: 28; height: 28
        EBarSlot { anchors.fill: parent; active: netBulgePopup.isOpen && globalState.netBulgeKind === "bt"; hovered: btBtnHover.hovered }
        Text {
            anchors.centerIn: parent
            text: "\ue1a7"
            font.family: "Material Symbols Rounded"; font.pixelSize: 15
            color: globalState.netBluetoothEnabled ? pal.primary : pal.muted
            opacity: globalState.glassMode ? 0.88 : 1.0
            Behavior on color { M3ColorAnim {} }
        }
        HoverHandler {
            id: btBtnHover
            onHoveredChanged: {
                if (hovered) netBulgePopup.showFor("bt", parent);
                else netBulgePopup.scheduleClose();
            }
        }
        MouseArea {
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: netBulgePopup.openSettings()
        }
    }

    BarBatteryButton { id: battBtn }

    Item {
        id: sessionBtnWrap
        Layout.alignment: Qt.AlignCenter
        visible: globalState.barModules.session
        width: 28; height: 28

        Rectangle {
            id: sessionBtn
            anchors.fill: parent
            radius: globalState.powerMenuOpen ? 9 : 14
            Behavior on radius { M3SpringAnim { token: "spatialFast" } }
            color: {
                var c = globalState.powerMenuOpen ? pal.primary : pal.secondaryCont;
                return (globalState.glassMode && !globalState.powerMenuOpen) ? ga(c, 0.6) : c;
            }
            Behavior on color { M3ColorAnim {} }

            Text {
                anchors.centerIn: parent
                text: "\ue8ac"
                font.family: "Material Symbols Rounded"; font.pixelSize: 16
                color: globalState.powerMenuOpen ? pal.colorOnPrimary : pal.colorOnSurfVar
                opacity: globalState.glassMode ? 0.88 : 1.0
                Behavior on color { M3ColorAnim {} }
            }

            HoverHandler {
                onHoveredChanged: {
                    if (hovered) {
                        globalState.closeOthers("power");
                        globalState.powerMenuOpen = true;
                    }
                }
            }
        }
    }
}
