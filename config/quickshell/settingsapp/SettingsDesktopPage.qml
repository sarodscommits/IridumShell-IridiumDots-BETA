import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../settings"

// Settings: infinite desktop, parallax and magnet page
Item {
    id: settingsDesktopPage
    anchors.fill: parent
    visible: settingsPopup.activeSection === "infinite desktop"
    ScrollView {
        id: infDesktopScrollView
        anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.left: parent.left
        anchors.leftMargin: 24; anchors.topMargin: 24; anchors.bottomMargin: 24
        width: parent.width - 36
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ColumnLayout {
            width: infDesktopScrollView.availableWidth
            spacing: 14

            DesktopLayoutGroup { id: desktopLayoutGroup }

            SettingsGroup {
                Layout.fillWidth: true
                title: tr("inf_group_magnet")
                icon: ""
                titleSize: 12; bodySpacing: 12
                expanded: globalState.settingsExpanded["inf_group_magnet"] === true
                onToggled: globalState.toggleSettingsGroup("inf_group_magnet")
                accent: pal.primary; textColor: pal.colorOnSurfVar; lineColor: pal.surfaceVar; hoverColor: pal.surfaceVar
                cardColor: globalState.glassMode ? ga(pal.surfaceDeep, 0.7) : pal.surfaceDeep; cardOpenColor: globalState.glassMode ? ga(pal.surfaceElevated, 0.78) : pal.surfaceElevated; innerColor: globalState.glassMode ? ga(pal.surfaceHigh, 0.82) : pal.surfaceHigh; iconContColor: pal.secondaryCont; titleColor: pal.colorOnSurface; subColor: pal.colorOnSurfVar; bodyFont: globalState.fontSecondary
                titleFont: globalState.fontPrimary; fontScale: globalState.fontScale

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Repeater {
                        model: [
                        { prop: "magnetEnabled", label: "magnet_enabled", icon: "", master: true  },
                        { prop: "magnetMove",    label: "magnet_move",    icon: "", master: false },
                        { prop: "magnetResize",  label: "magnet_resize",  icon: "", master: false },
                        { prop: "magnetResnap",  label: "magnet_resnap",  icon: "", master: false },
                        { prop: "magnetAlign",   label: "magnet_align",   icon: "", master: false },
                        { prop: "magnetNoAnim",  label: "magnet_noanim",  icon: "", master: false }
                        ]
                        delegate: ColumnLayout {
                            id: mgToggleRow
                            required property var modelData
                            readonly property bool on: globalState[modelData.prop] === true
                            readonly property bool usable: modelData.master || globalState.magnetEnabled
                            Layout.fillWidth: true
                            spacing: 6
                            opacity: usable ? 1 : 0.45
                            Behavior on opacity { M3NumberAnim {} }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                Text {
                                    text: mgToggleRow.modelData.icon
                                    font.family: "Material Symbols Rounded"; font.pixelSize: 16
                                    color: pal.primary
                                }
                                Text {
                                    text: tr(mgToggleRow.modelData.label)
                                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                                    color: pal.colorOnSurfVar
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                }
                                ESwitch {
                                    checked: mgToggleRow.on
                                    enabled: mgToggleRow.usable
                                    onToggled: setMagnetBool(mgToggleRow.modelData.prop, !mgToggleRow.on)
                                }
                            }
                            Text {
                                visible: mgToggleRow.modelData.master
                                Layout.fillWidth: true
                                text: tr("magnet_note")
                                wrapMode: Text.WordWrap
                                font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale)
                                color: pal.muted
                            }
                        }
                    }

                    Repeater {
                        model: [
                        { prop: "magnetGap",       label: "magnet_gap",        icon: "" },
                        { prop: "magnetSnapDist",  label: "magnet_snap",       icon: "" },
                        { prop: "magnetBreakAway", label: "magnet_break_away", icon: "" },
                        { prop: "magnetBreakInto", label: "magnet_break_into", icon: "" }
                        ]
                        delegate: ColumnLayout {
                            id: mgSliderRow
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 6
                            opacity: globalState.magnetEnabled ? 1 : 0.45
                            Behavior on opacity { M3NumberAnim {} }
                            readonly property real val: globalState[modelData.prop]
                            readonly property real vmin: magnetLimits[modelData.prop][0]
                            readonly property real vmax: magnetLimits[modelData.prop][1]
                            readonly property real span: vmax - vmin

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                Text {
                                    text: mgSliderRow.modelData.icon
                                    font.family: "Material Symbols Rounded"; font.pixelSize: 16
                                    color: pal.primary
                                }
                                Text {
                                    text: tr(mgSliderRow.modelData.label)
                                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                                    color: pal.colorOnSurfVar
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: Math.round(mgSliderRow.val) + " px"
                                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale)
                                    color: pal.muted
                                }
                            }
                            FractionSlider {
                                id: mgTrack
                                Layout.fillWidth: true
                                property real displayPct: (mgSliderRow.val - mgSliderRow.vmin) / mgSliderRow.span
                                value: displayPct
                                trackH: 14
                                handleHOverride: 20
                                height: 22
                                activeColor: pal.toggleOn
                                inactiveColor: globalState.glassMode ? ga(pal.surfaceDeep, 0.6) : pal.surfaceDeep
                                showBubble: false
                                enabled: globalState.magnetEnabled
                                onFracMoved: (frac) => { setMagnetValue(mgSliderRow.modelData.prop, mgSliderRow.vmin + frac * mgSliderRow.span); }
                                onFracReleased: { savePrefs(); syncMagnetFile(); }
                            }
                        }
                    }
                }
            }

            SettingsGroup {
                Layout.fillWidth: true
                title: tr("inf_group_widgets")
                icon: "\ue30d"
                titleSize: 12; bodySpacing: 12
                expanded: globalState.settingsExpanded["inf_group_widgets"] === true
                onToggled: globalState.toggleSettingsGroup("inf_group_widgets")
                accent: pal.primary; textColor: pal.colorOnSurfVar; lineColor: pal.surfaceVar; hoverColor: pal.surfaceVar
                cardColor: globalState.glassMode ? ga(pal.surfaceDeep, 0.7) : pal.surfaceDeep; cardOpenColor: globalState.glassMode ? ga(pal.surfaceElevated, 0.78) : pal.surfaceElevated; innerColor: globalState.glassMode ? ga(pal.surfaceHigh, 0.82) : pal.surfaceHigh; iconContColor: pal.secondaryCont; titleColor: pal.colorOnSurface; subColor: pal.colorOnSurfVar; bodyFont: globalState.fontSecondary
                titleFont: globalState.fontPrimary; fontScale: globalState.fontScale

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Text {
                            text: "\ue30d"
                            font.family: "Material Symbols Rounded"; font.pixelSize: 16
                            color: pal.primary
                        }
                        Text {
                            text: "Widgets de escritorio"
                            font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                            color: pal.colorOnSurfVar
                            Layout.fillWidth: true
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        height: 32
                        radius: 10
                        color: globalState.glassMode ? ga(pal.surfaceDeep, 0.6) : pal.surfaceDeep
                        Text {
                            anchors.centerIn: parent
                            text: "Editar widgets de escritorio"
                            font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                            color: pal.colorOnSurface
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                settingsWindow.closeWin();
                                if (!globalState.desktopEditMode) globalState.toggleDesktopEditMode();
                            }
                        }
                    }
                }
            }
            DesktopParallaxGroup { id: desktopParallaxGroup }
        }
    }
}
