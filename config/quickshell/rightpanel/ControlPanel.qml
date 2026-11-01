import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../rightpanel"
import "../ui"

// Control page of the right panel: sliders, toggles and module cards
Item {
    id: controlPanel
    anchors.fill: parent
    anchors.margins: 12
    anchors.topMargin: 24
    opacity: (!globalState.mediaMenuOpen || globalState.rightPanelPage !== 0 || globalState.wifiViewOpen || globalState.btDevicesViewOpen) ? 0 : 1
    visible: (globalState.mediaMenuOpen && globalState.rightPanelPage === 0) || opacity > 0
    enabled: globalState.mediaMenuOpen && globalState.rightPanelPage === 0 && !globalState.wifiViewOpen && !globalState.btDevicesViewOpen
    Behavior on opacity { M3NumberAnim {} }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            id: cpTopRow
            Layout.fillWidth: true
            spacing: 8

            Item { Layout.fillWidth: true }

            Rectangle {
                width: 32; height: 32; radius: 10
                color: {
                    var c = globalState.settingsOpen ? pal.primaryCont : pal.secondaryCont;
                    return globalState.glassMode ? ga(c, 0.78) : c;
                }
                Behavior on color { M3ColorAnim {} }
                Text {
                    anchors.centerIn: parent
                    text: "\ue8b8"
                    font.family: "Material Symbols Rounded"; font.pixelSize: 17
                    color: globalState.settingsOpen ? pal.primary : pal.colorOnSurfVar
                }
                HoverHandler { id: cpSettingsHov }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        globalState.mediaMenuOpen = false;
                        globalState.settingsOpen = !globalState.settingsOpen;
                    }
                }
            }
        }

        SliderCard {
            id: cpBrightCard
            icon: "\ue1ad"
            level: globalState.rawBrightness / 100
            onPressed: globalState.brightnessAdjusting = true
            onMoved: (v) => globalState.setBrightness(v)
            onReleased: globalState.brightnessAdjusting = false
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            SliderCard {
                id: cpVolCard
                icon: globalState.isMuted ? "\ue04f" : "\ue050"
                muted: globalState.isMuted
                iconClickable: true
                level: globalState.isMuted ? 0 : globalState.rawVolumeValue / 100
                activeColor: globalState.isMuted ? Qt.darker(pal.error, 1.8) : pal.toggleOn
                onIconClicked: globalState.toggleMute()
                onPressed: if (globalState.isMuted) globalState.toggleMute()
                onMoved: (v) => setVolumePercent(v)
            }

            SliderCard {
                id: cpMicCard
                icon: globalState.isMicMuted ? "\ue02b" : "\ue029"
                muted: globalState.isMicMuted
                iconClickable: true
                level: globalState.isMicMuted ? 0 : globalState.rawMicVolume / 100
                onIconClicked: globalState.toggleMicMute()
                onPressed: if (globalState.isMicMuted) globalState.toggleMicMute()
                onMoved: (v) => setMicPercent(v)
            }
        }

        QuickToggleRow { id: quickToggleRow }

        AccessToggleRow { id: accessToggleRow }

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 6

            Repeater {
                id: cpModulesDotsRepeater
                model: 2
                property color _dotActive:   pal.primary
                property color _dotInactive: Qt.rgba(pal.primary.r, pal.primary.g, pal.primary.b, 0.35)
                Rectangle {
                    required property int index
                    width: globalState.cpModulesPage === index ? 14 : 6
                    height: 6; radius: 3
                    color: globalState.cpModulesPage === index ? cpModulesDotsRepeater._dotActive : cpModulesDotsRepeater._dotInactive
                    Behavior on width { M3SpringAnim { token: "spatialFast" } }
                    Behavior on color { M3ColorAnim {} }
                    MouseArea {
                        anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor
                        onClicked: globalState.cpModulesPage = index
                    }
                }
            }
        }

        ControlModules { id: cpModulesSwitcher }
    }
}
