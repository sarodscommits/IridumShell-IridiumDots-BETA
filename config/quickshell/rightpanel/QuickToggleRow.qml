import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Quick toggles (Wi-Fi, Bluetooth, ...) of the control panel
RowLayout {
    id: quickToggleRow
    Layout.fillWidth: true
    spacing: 8

    Repeater {
        id: toggleRepeater
        model: [
        { key: "wifi",      iconOn: "\ue1d8", iconOff: "\ue1da" },
        { key: "bluetooth", iconOn: "\ue1a7", iconOff: "\ue1a7" },
        ]
        property color _primary:       pal.primary
        property color _primaryCont:   pal.primaryCont
        property color _secondaryCont: pal.secondaryCont
        property color _onSurface:     pal.colorOnSurface
        property color _onPrimary:     pal.colorOnPrimary
        Rectangle {
            required property var modelData
            property bool on: {
                if (modelData.key === "wifi") return globalState.wifiPendingOn !== -1 ? globalState.wifiPendingOn === 1 : globalState.netWifiEnabled;
                return globalState.btPendingOn !== -1 ? globalState.btPendingOn === 1 : globalState.netBluetoothEnabled;
            }
            property string label: modelData.key === "wifi" ? tr("wifi") : tr("bluetooth")
            property bool busy: modelData.key === "wifi" ? globalState.wifiRadioBusy : globalState.btRadioBusy
            Layout.fillWidth: true
            height: 64
            opacity: busy ? 0.55 : 1.0
            Behavior on opacity { M3NumberAnim { duration: m3.durFast } }
            radius: on ? 14 : height / 2
            Behavior on radius { M3SpringAnim { token: "spatialDefault" } }
            color: {
                var active = on || toggleHov.hovered;
                var c = active ? toggleRepeater._primary : containerDark(toggleRepeater._secondaryCont);
                return (globalState.glassMode && !active) ? ga(c, 0.78) : c;
            }
            Behavior on color { M3ColorAnim {} }

            property bool _darken: on || toggleHov.hovered

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 3
                opacity: globalState.glassMode ? 0.88 : 1.0
                FadeIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: on ? modelData.iconOn : modelData.iconOff
                    font.family: "Material Symbols Rounded"; font.pixelSize: 20
                    color: parent.parent._darken ? toggleRepeater._onPrimary : toggleRepeater._primary
                    Behavior on color { M3ColorAnim {} }
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: label
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale); font.weight: Font.Medium
                    color: parent.parent._darken ? toggleRepeater._onPrimary : toggleRepeater._onSurface
                    Behavior on color { M3ColorAnim {} }
                }
            }
            HoverHandler { id: toggleHov }
            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                enabled: !busy
                property int _btClicks:   0
                property int _wifiClicks: 0
                onClicked: {
                    if (modelData.key === "bluetooth") {
                        _btClicks++;
                        if (_btClicks === 1) {
                            btClickTimer.restart();
                        } else {
                            _btClicks = 0;
                            btClickTimer.stop();
                            globalState.openBtDevicesView();
                        }
                        return;
                    }
                    if (modelData.key === "wifi") {
                        _wifiClicks++;
                        if (_wifiClicks === 1) {
                            wifiClickTimer.restart();
                        } else {
                            _wifiClicks = 0;
                            wifiClickTimer.stop();
                            globalState.openWifiView();
                        }
                        return;
                    }
                }
                Timer {
                    id: btClickTimer
                    interval: 280; repeat: false
                    onTriggered: {
                        parent._btClicks = 0;
                        globalState.btSetEnabled(!globalState.netBluetoothEnabled);
                    }
                }
                Timer {
                    id: wifiClickTimer
                    interval: 280; repeat: false
                    onTriggered: {
                        parent._wifiClicks = 0;
                        globalState.wifiSetEnabled(!globalState.netWifiEnabled);
                    }
                }
            }
        }
    }
}
