import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../settings"

// Settings: Wi-Fi and Bluetooth manager
Item {
    id: settingsConnectionsPage
    anchors.fill: parent
    visible: settingsPopup.activeSection === "connections"

    onVisibleChanged: {
        if (visible) {
            globalState.wifiConnectError = "";
            globalState.wifiScanNetworks();
            networkBackend.btCtlProcRef.running = true;
        } else {
            globalState.wifiPasswordSsid   = "";
            globalState.wifiPasswordDraft  = "";
            globalState.wifiConnectingSsid = "";
            if (!globalState.wifiViewOpen) networkBackend.wifiScanProcRef.running = false;
            if (!globalState.btDevicesViewOpen) {
                if (networkBackend.btCtlProcRef.running) networkBackend.btCtlProcRef.write("scan off\n");
                networkBackend.stopBtScan();
            }
        }
    }

    Connections {
        target: globalState
        function onWifiPasswordSsidChanged() {
            if (globalState.wifiPasswordSsid !== "" && settingsWindow.winOpen) connPromptFocusTimer.restart();
        }
        function onBtPromptTypeChanged() {
            if (globalState.btPromptType !== "" && settingsWindow.winOpen) connPromptFocusTimer.restart();
        }
    }
    Timer {
        id: connPromptFocusTimer
        interval: 80; repeat: false
        onTriggered: {
            settingsWindow.requestActivate();
            if (globalState.wifiPasswordSsid !== "") {
                connWifiPromptField.forceActiveFocus();
            } else if (globalState.btPromptType !== "" && globalState.btPromptType !== "confirm") {
                connBtPromptField.forceActiveFocus();
            }
        }
    }

    ScrollView {
        id: connectionsScrollView
        anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.left: parent.left
        anchors.leftMargin: 24; anchors.topMargin: 24; anchors.bottomMargin: 24
        width: parent.width - 36
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            width: connectionsScrollView.availableWidth
            spacing: 8

            ConnectionsNetStatusCard { id: connectionsNetStatusCard }


            SettingsGroup {
                Layout.fillWidth: true
                title: tr("wifi")
                icon: "\ue63e"
                titleSize: 12; bodySpacing: 10; innerBlock: false
                expanded: globalState.settingsExpanded["conn_wifi"] === true
                onToggled: globalState.toggleSettingsGroup("conn_wifi")
                accent: pal.primary; textColor: pal.colorOnSurfVar; lineColor: pal.surfaceVar; hoverColor: pal.surfaceVar
                cardColor: globalState.glassMode ? ga(pal.surfaceDeep, 0.7) : pal.surfaceDeep; cardOpenColor: globalState.glassMode ? ga(pal.surfaceElevated, 0.78) : pal.surfaceElevated; innerColor: globalState.glassMode ? ga(pal.surfaceHigh, 0.82) : pal.surfaceHigh; iconContColor: pal.secondaryCont; titleColor: pal.colorOnSurface; subColor: pal.colorOnSurfVar; bodyFont: globalState.fontSecondary
                titleFont: globalState.fontPrimary; fontScale: globalState.fontScale

                headerTrailing: PressIconButton {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    cornerRadius: 9
                    icon: "\ue5d5"
                    iconSize: 18
                    iconColor: pal.primary
                    iconVisible: !(globalState.wifiScanning)
                    hoverColor: pal.surfaceVar
                    idleColor: "transparent"
                    onClicked: globalState.wifiScanNetworks()
                    MorphLoader {
                        anchors.centerIn: parent
                        size: 20
                        fillColor: pal.primary
                        visible: running
                        running: globalState.wifiScanning
                    }
                }

                ConnectionsWifiList { id: connWifiListColumn }

                Rectangle {
                    visible: globalState.wifiPasswordSsid !== ""
                    Layout.fillWidth: true
                    radius: 16
                    implicitHeight: connWifiPromptCol.implicitHeight + 20
                    color: globalState.glassMode ? ga(containerDark(pal.primaryCont), 0.6) : containerDark(pal.primaryCont)

                    ColumnLayout {
                        id: connWifiPromptCol
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        Text {
                            text: tr("wifi_enter_password") + " \"" + globalState.wifiPasswordSsid + "\""
                            font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                            color: pal.colorOnSurface
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Text {
                            visible: globalState.wifiConnectError !== ""
                            text: globalState.wifiConnectError
                            font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale)
                            color: pal.error
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 34; radius: 10
                            color: pal.surfaceDeep
                            border.width: 1
                            border.color: connWifiPromptField.activeFocus ? pal.primary : "transparent"

                            TextInput {
                                id: connWifiPromptField
                                anchors.fill: parent
                                anchors.leftMargin: 10; anchors.rightMargin: 36
                                verticalAlignment: TextInput.AlignVCenter
                                font.family: globalState.fontSecondary; font.pixelSize: Math.round(13 * globalState.fontScale)
                                color: pal.colorOnSurface
                                echoMode: globalState.wifiPasswordVisible ? TextInput.Normal : TextInput.Password
                                text: globalState.wifiPasswordDraft
                                onTextChanged: globalState.wifiPasswordDraft = text
                                Keys.onReturnPressed: connWifiPromptConfirmBtn.doConfirm()
                            }

                            Rectangle {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.rightMargin: 4
                                width: 26; height: 26; radius: m3Ib29Ma.pressed ? Math.max(4, (8) * 0.5) : (8); Behavior on radius { M3SpringAnim { token: "spatialFast" } }
                                color: connWifiEyeHov.hovered ? pal.primaryCont : "transparent"
                                Behavior on color { M3ColorAnim { duration: m3.durFast } }
                                FadeIcon {
                                    anchors.centerIn: parent
                                    text: globalState.wifiPasswordVisible ? "\ue8f4" : "\ue8f5"
                                    font.family: "Material Symbols Rounded"; font.pixelSize: 15
                                    color: pal.muted
                                }
                                HoverHandler { id: connWifiEyeHov }
                                MouseArea { id: m3Ib29Ma;
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: globalState.wifiPasswordVisible = !globalState.wifiPasswordVisible
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                Layout.fillWidth: true
                                height: 32; radius: 10
                                color: pal.surfaceDeep
                                Text { anchors.centerIn: parent; text: tr("bt_cancel"); font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); color: pal.colorOnSurface }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: globalState.wifiCancelPassword() }
                            }
                            Rectangle {
                                id: connWifiPromptConfirmBtn
                                function doConfirm() { globalState.wifiSubmitPassword(); }
                                Layout.fillWidth: true
                                height: 32; radius: 10
                                color: pal.primary
                                Text {
                                    anchors.centerIn: parent
                                    text: tr("bt_send")
                                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium
                                    color: pal.colorOnPrimary
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: connWifiPromptConfirmBtn.doConfirm() }
                            }
                        }
                    }
                }
            }

            SettingsGroup {
                Layout.fillWidth: true
                title: tr("bluetooth")
                icon: "\ue1a7"
                titleSize: 12; bodySpacing: 10; innerBlock: false
                expanded: globalState.settingsExpanded["conn_bt"] === true
                onToggled: globalState.toggleSettingsGroup("conn_bt")
                accent: pal.primary; textColor: pal.colorOnSurfVar; lineColor: pal.surfaceVar; hoverColor: pal.surfaceVar
                cardColor: globalState.glassMode ? ga(pal.surfaceDeep, 0.7) : pal.surfaceDeep; cardOpenColor: globalState.glassMode ? ga(pal.surfaceElevated, 0.78) : pal.surfaceElevated; innerColor: globalState.glassMode ? ga(pal.surfaceHigh, 0.82) : pal.surfaceHigh; iconContColor: pal.secondaryCont; titleColor: pal.colorOnSurface; subColor: pal.colorOnSurfVar; bodyFont: globalState.fontSecondary
                titleFont: globalState.fontPrimary; fontScale: globalState.fontScale

                headerTrailing: PressIconButton {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    cornerRadius: 9
                    icon: "\ue5d5"
                    iconSize: 18
                    iconColor: pal.primary
                    iconVisible: !(globalState.btScanning)
                    hoverColor: pal.surfaceVar
                    idleColor: "transparent"
                    onClicked: {
                        btPairedModel.clear();
                        btAvailableModel.clear();
                        networkBackend.btCtlProcRef.write("devices Paired\n");
                        networkBackend.btCtlProcRef.write("devices Connected\n");
                    }
                    MorphLoader {
                        anchors.centerIn: parent
                        size: 20
                        fillColor: pal.primary
                        visible: running
                        running: globalState.btScanning
                    }
                }

                ConnectionsBtStatusCard { id: connectionsBtStatusCard }

                QtObject {
                    id: connBtColors
                    property color primary:        pal.primary
                    property color colorOnPrimary: pal.colorOnPrimary
                    property color colorOnSurface: pal.colorOnSurface
                    property color muted:          pal.muted
                    property color surfaceDeep:    pal.surfaceDeep
                    property color errorDark:      Qt.darker(pal.error, 1.6)
                    property color cardBg:         pal.surfaceHigh
                }

                Component {
                    id: connBtDeviceDelegateComponent
                    ConnectionsBtDeviceRow { id: connectionsBtDeviceRow }
                }

                ConnectionsBtSavedDevices { id: connectionsBtSavedDevices }

                Rectangle {
                    visible: globalState.btPromptType !== ""
                    Layout.fillWidth: true
                    radius: 16
                    implicitHeight: connBtPromptCol.implicitHeight + 20
                    color: globalState.glassMode ? ga(containerDark(pal.primaryCont), 0.6) : containerDark(pal.primaryCont)

                    ColumnLayout {
                        id: connBtPromptCol
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        Text {
                            text: globalState.btPromptType === "confirm"
                            ? (tr("bt_confirm_code") + ": " + globalState.btPromptText)
                            : tr("bt_enter_code")
                            font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                            color: pal.colorOnSurface
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            visible: globalState.btPromptType !== "confirm"
                            Layout.fillWidth: true
                            height: 34; radius: 10
                            color: pal.surfaceDeep
                            border.width: 1
                            border.color: connBtPromptField.activeFocus ? pal.primary : "transparent"

                            TextInput {
                                id: connBtPromptField
                                anchors.fill: parent
                                anchors.leftMargin: 10; anchors.rightMargin: 10
                                verticalAlignment: TextInput.AlignVCenter
                                font.family: globalState.fontSecondary; font.pixelSize: Math.round(13 * globalState.fontScale)
                                color: pal.colorOnSurface
                                echoMode: globalState.btPromptType === "pin" ? TextInput.Password : TextInput.Normal
                                text: globalState.btPasswordDraft
                                onTextChanged: globalState.btPasswordDraft = text
                                Keys.onReturnPressed: connBtPromptConfirmBtn.doConfirm()
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                Layout.fillWidth: true
                                height: 32; radius: 10
                                color: pal.surfaceDeep
                                Text { anchors.centerIn: parent; text: tr("bt_cancel"); font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); color: pal.colorOnSurface }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: globalState.btCancelPrompt() }
                            }
                            Rectangle {
                                id: connBtPromptConfirmBtn
                                function doConfirm() {
                                    globalState.btSubmitPrompt(globalState.btPromptType === "confirm" ? "yes" : globalState.btPasswordDraft);
                                }
                                Layout.fillWidth: true
                                height: 32; radius: 10
                                color: pal.primary
                                Text {
                                    anchors.centerIn: parent
                                    text: globalState.btPromptType === "confirm" ? tr("bt_yes") : tr("bt_send")
                                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium
                                    color: pal.colorOnPrimary
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: connBtPromptConfirmBtn.doConfirm() }
                            }
                        }
                    }
                }
            }
        }
    }
}
