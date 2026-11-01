import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Settings: bar modules page
Item {
    id: sdBarPage
    anchors.fill: parent
    visible: settingsPopup.activeSection === "bar"
    EPage {
        anchors.fill: parent
        anchors.leftMargin: 24; anchors.rightMargin: 12; anchors.bottomMargin: 16

        ESection {
            title: tr("sd_bar_layout")
            subtitle: tr("sd_bar_layout_d")
            icon: "\ue9b7"
            ESettingRow {
                icon: "\ue30a"; label: tr("shell_mode")
                SegmentedPill {
                    Layout.preferredWidth: 180
                    options: [{ value: "island", label: tr("shell_mode_island") }, { value: "notch", label: tr("shell_mode_notch") }]
                    current: globalState.shellMode
                    onPicked: (v) => setShellMode(v)
                    trackColor: m3.glassy(m3.surfaceContainerHighest, 0.6)
                    selectedColor: pal.primary
                    textColor: pal.colorOnSurfVar
                    selectedTextColor: pal.colorOnPrimary
                    iconColor: pal.primary
                }
            }
            ESettingRow {
                visible: globalState.shellMode === "island"
                icon: "\ue5d1"; label: tr("island_auto_hide"); desc: tr("island_auto_hide_desc")
                ESwitch {
                    checked: globalState.islandAutoHide
                    onToggled: globalState.setIslandAutoHide(!globalState.islandAutoHide)
                }
            }
            ESettingRow {
                icon: "\ue871"; label: tr("bar_position")
                    SegmentedPill {
                        Layout.preferredWidth: 168
                        segHeight: 28
                        options: [{ value: "top",    icon: "\ue316", label: "" },
                                  { value: "bottom", icon: "\ue313", label: "" },
                                  { value: "left",   icon: "\ue314", label: "" },
                                  { value: "right",  icon: "\ue315", label: "" }]
                        current: globalState.topBarPosition
                        onPicked: (v) => setTopBarPosition(v)
                        trackColor: m3.glassy(m3.surfaceContainerHighest, 0.6)
                        selectedColor: pal.primary
                        textColor: pal.colorOnSurfVar
                        selectedTextColor: pal.colorOnPrimary
                        iconColor: pal.primary
                    }
            }
        }

        ESection {
            title: tr("bar_modules")
            subtitle: tr("sd_bar_modules_d")
            icon: "\ue89f"
            GridLayout {
                Layout.fillWidth: true
                columns: width > 620 ? 2 : 1
                columnSpacing: 28
                rowSpacing: 10
                Repeater {
                    id: barModulesRepeater
                    model: [
                        { key: "control",    icon: "\ue89f", label: tr("mod_control") },
                        { key: "search",     icon: "\ue8b6", label: tr("mod_search") },
                        { key: "workspaces", icon: "\ue871", label: tr("mod_workspaces") },
                        { key: "windows",    icon: "\uf1ce", label: tr("mod_windows") },
                        { key: "audio",      icon: "\ue405", label: tr("mod_audio") },
                        { key: "clock",      icon: "\ue8b5", label: tr("mod_clock") },
                        { key: "gaming",     icon: "\uea28", label: tr("mod_gaming") },
                        { key: "clipboard",  icon: "\ue14f", label: tr("mod_clipboard") },
                        { key: "privacy",    icon: "\ue32a", label: tr("mod_privacy") },
                        { key: "notifications", icon: "\ue7f4", label: tr("mod_notifications") },
                        { key: "wifi",       icon: "\ue1d8", label: tr("wifi") },
                        { key: "bluetooth",  icon: "\ue1a7", label: tr("bluetooth") },
                        { key: "battery",    icon: "\ue1a4", label: tr("mod_battery") },
                        { key: "session",    icon: "\ue8ac", label: tr("mod_session") },
                    ]
                    property color _primary:   pal.primary
                    property color _muted:     pal.mutedDeep
                    property color _onSurfVar: pal.colorOnSurfVar
                    property color _toggleOn:  pal.toggleOn

                    RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: modelData.icon
                            font.family: "Material Symbols Rounded"; font.pixelSize: 16
                            color: barModulesRepeater._primary
                        }
                        Text {
                            text: modelData.label
                            font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                            color: barModulesRepeater._onSurfVar
                            Layout.fillWidth: true
                            opacity: globalState.glassMode ? 0.88 : 1.0
                        }
                        ESwitch {
                            checked: globalState.barModules[modelData.key]
                            onToggled: setBarModuleVisible(modelData.key, !globalState.barModules[modelData.key])
                        }
                    }
                }
            }
        }
    }
}
