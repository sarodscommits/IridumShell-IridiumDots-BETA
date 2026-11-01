import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Settings: windows page (layout, borders, shadows)
Item {
    id: sdWindowsPage
    anchors.fill: parent
    visible: settingsPopup.activeSection === "windows"
    EPage {
        anchors.fill: parent
        anchors.leftMargin: 24; anchors.rightMargin: 12; anchors.bottomMargin: 16

        ESection {
            title: tr("sd_win_frame")
            subtitle: tr("sd_win_frame_d")
            icon: "\uf088"
            ESettingRow {
                icon: "\ue91a"; label: tr("border_size"); desc: globalState.borderSize + " px"
                FractionSlider {
                    id: borderSizeTrack
                    Layout.preferredWidth: 280
                    property real displayPct: globalState.borderSize / 10
                    value: displayPct
                    trackH: 14
                    handleHOverride: 20
                    height: 22
                    activeColor: pal.toggleOn
                    inactiveColor: globalState.glassMode ? ga(pal.surfaceDeep, 0.6) : pal.surfaceDeep
                    steps: Math.max(0, (11) - 1)
                    showBubble: false
                    onFracMoved: (frac) => { var raw = frac * 10; var v=Math.round(raw); setBorderSize(v); }
                }
            }
            ESettingRow {
                icon: "\ue920"; label: tr("corner_rounding"); desc: globalState.cornerRounding + " px"
                FractionSlider {
                    id: cornerRoundingTrack
                    Layout.preferredWidth: 280
                    property real displayPct: globalState.cornerRounding / 20
                    value: displayPct
                    trackH: 14
                    handleHOverride: 20
                    height: 22
                    activeColor: pal.toggleOn
                    inactiveColor: globalState.glassMode ? ga(pal.surfaceDeep, 0.6) : pal.surfaceDeep
                    steps: Math.max(0, (11) - 1)
                    showBubble: false
                    onFracMoved: (frac) => { var raw = frac * 20; var v=Math.round(raw/2)*2; setCornerRounding(v); }
                }
            }
        }

        ESection {
            title: tr("window_shadows")
            subtitle: tr("sd_win_shadow_d")
            icon: "\ue3f7"
            ESettingRow {
                icon: "\ue3f7"; label: tr("window_shadows")
                ESwitch {
                    checked: globalState.shadowEnabled
                    onToggled: setShadowEnabled(!globalState.shadowEnabled)
                }
            }
            ESettingRow {
                opacity: globalState.shadowEnabled ? 1.0 : 0.4
                icon: "\ue3a5"; label: tr("shadow_thickness"); desc: globalState.shadowRange + " px"
                FractionSlider {
                    id: shadowRangeTrack
                    Layout.preferredWidth: 280
                    enabled: globalState.shadowEnabled
                    property real displayPct: (globalState.shadowRange - 10) / 50
                    property int dotCount: 18
                    value: displayPct
                    trackH: 14
                    handleHOverride: 20
                    height: 22
                    activeColor: pal.toggleOn
                    inactiveColor: globalState.glassMode ? ga(pal.surfaceDeep, 0.6) : pal.surfaceDeep
                    steps: Math.max(0, (18) - 1)
                    showBubble: false
                    Behavior on opacity { M3NumberAnim {} }
                    onFracMoved: (frac) => { var idx=Math.round(frac*(dotCount-1)); var v=Math.round(10 + (idx/(dotCount-1))*50); setShadowRange(v); }
                }
            }
            ESettingRow {
                opacity: globalState.shadowEnabled ? 1.0 : 0.4
                icon: "\ue91c"; label: tr("shadow_intensity"); desc: globalState.shadowIntensity + " %"
                FractionSlider {
                    id: shadowIntensityTrack
                    Layout.preferredWidth: 280
                    enabled: globalState.shadowEnabled
                    property real displayPct: (globalState.shadowIntensity - 20) / 80
                    value: displayPct
                    trackH: 14
                    handleHOverride: 20
                    height: 22
                    activeColor: pal.toggleOn
                    inactiveColor: globalState.glassMode ? ga(pal.surfaceDeep, 0.6) : pal.surfaceDeep
                    steps: Math.max(0, (17) - 1)
                    showBubble: false
                    Behavior on opacity { M3NumberAnim {} }
                    onFracMoved: (frac) => { var raw = frac * 80; var v=Math.round(raw/5)*5; setShadowIntensity(20 + v); }
                }
            }
        }

        ESection {
            title: tr("sd_shell_shadow")
            subtitle: tr("sd_shell_shadow_d")
            icon: "\ue3f7"
            ESettingRow {
                icon: "\ue3f7"; label: tr("ss_enable"); desc: tr("ss_edit_note")
                ESwitch {
                    checked: globalState.shellShadowEnabled
                    onToggled: setShellShadowFlag("shellShadowEnabled", !globalState.shellShadowEnabled)
                }
            }
            ESettingRow {
                opacity: globalState.shellShadowEnabled ? 1.0 : 0.4
                Behavior on opacity { M3NumberAnim {} }
                icon: "\ue30a"; label: tr("ss_island"); desc: globalState.shellMode === "island" ? tr("ss_active_mode") : ""
                ESwitch {
                    enabled: globalState.shellShadowEnabled
                    checked: globalState.shellShadowIsland
                    onToggled: setShellShadowFlag("shellShadowIsland", !globalState.shellShadowIsland)
                }
            }
            ESettingRow {
                opacity: globalState.shellShadowEnabled ? 1.0 : 0.4
                Behavior on opacity { M3NumberAnim {} }
                icon: "\ue30a"; label: tr("ss_notch"); desc: globalState.shellMode === "notch" ? tr("ss_active_mode") : ""
                ESwitch {
                    enabled: globalState.shellShadowEnabled
                    checked: globalState.shellShadowNotch
                    onToggled: setShellShadowFlag("shellShadowNotch", !globalState.shellShadowNotch)
                }
            }
            ESettingRow {
                opacity: globalState.shellShadowEnabled ? 1.0 : 0.4
                Behavior on opacity { M3NumberAnim {} }
                icon: "\ue8b8"; label: tr("ss_panels"); desc: tr("ss_panels_d")
                ESwitch {
                    enabled: globalState.shellShadowEnabled
                    checked: globalState.shellShadowPanels
                    onToggled: setShellShadowFlag("shellShadowPanels", !globalState.shellShadowPanels)
                }
            }
            ESettingRow {
                opacity: globalState.shellShadowEnabled ? 1.0 : 0.4
                Behavior on opacity { M3NumberAnim {} }
                icon: "\ue1bd"; label: tr("ss_widgets")
                ESwitch {
                    enabled: globalState.shellShadowEnabled
                    checked: globalState.shellShadowWidgets
                    onToggled: setShellShadowFlag("shellShadowWidgets", !globalState.shellShadowWidgets)
                }
            }
            ESettingRow {
                opacity: globalState.shellShadowEnabled ? 1.0 : 0.4
                Behavior on opacity { M3NumberAnim {} }
                icon: "\ue7f4"; label: tr("ss_notifs")
                ESwitch {
                    enabled: globalState.shellShadowEnabled
                    checked: globalState.shellShadowNotifs
                    onToggled: setShellShadowFlag("shellShadowNotifs", !globalState.shellShadowNotifs)
                }
            }
            ESettingRow {
                opacity: globalState.shellShadowEnabled ? 1.0 : 0.4
                Behavior on opacity { M3NumberAnim {} }
                icon: "\uea28"; label: tr("ss_gaming")
                ESwitch {
                    enabled: globalState.shellShadowEnabled
                    checked: globalState.shellShadowGaming
                    onToggled: setShellShadowFlag("shellShadowGaming", !globalState.shellShadowGaming)
                }
            }
            ESettingRow {
                opacity: globalState.shellShadowEnabled ? 1.0 : 0.4
                Behavior on opacity { M3NumberAnim {} }
                icon: "\ue897"; label: tr("ss_lock")
                ESwitch {
                    enabled: globalState.shellShadowEnabled
                    checked: globalState.shellShadowLock
                    onToggled: setShellShadowFlag("shellShadowLock", !globalState.shellShadowLock)
                }
            }
            ESettingRow {
                opacity: globalState.shellShadowEnabled ? 1.0 : 0.4
                Behavior on opacity { M3NumberAnim {} }
                icon: "\ue3a5"; label: tr("shadow_thickness"); desc: globalState.shellShadowRange + " px"
                FractionSlider {
                    id: shellShadowRangeTrack
                    Layout.preferredWidth: 280
                    enabled: globalState.shellShadowEnabled
                    value: (globalState.shellShadowRange - 10) / 50
                    trackH: 14
                    handleHOverride: 20
                    height: 22
                    activeColor: pal.toggleOn
                    inactiveColor: globalState.glassMode ? ga(pal.surfaceDeep, 0.6) : pal.surfaceDeep
                    steps: 10
                    showBubble: false
                    onFracMoved: (frac) => { var idx=Math.round(frac*10); setShellShadowRange(10 + idx * 5); }
                }
            }
            ESettingRow {
                opacity: globalState.shellShadowEnabled ? 1.0 : 0.4
                Behavior on opacity { M3NumberAnim {} }
                icon: "\ue91c"; label: tr("shadow_intensity"); desc: globalState.shellShadowIntensity + " %"
                FractionSlider {
                    id: shellShadowIntensityTrack
                    Layout.preferredWidth: 280
                    enabled: globalState.shellShadowEnabled
                    value: (globalState.shellShadowIntensity - 10) / 90
                    trackH: 14
                    handleHOverride: 20
                    height: 22
                    activeColor: pal.toggleOn
                    inactiveColor: globalState.glassMode ? ga(pal.surfaceDeep, 0.6) : pal.surfaceDeep
                    steps: 18
                    showBubble: false
                    onFracMoved: (frac) => { var idx=Math.round(frac*18); setShellShadowIntensity(10 + idx * 5); }
                }
            }
        }
    }
}
