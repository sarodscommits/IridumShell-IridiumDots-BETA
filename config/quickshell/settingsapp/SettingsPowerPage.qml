import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../settings"

// Settings: power page
Item {
    id: settingsPowerPage
    anchors.fill: parent
    visible: settingsPopup.activeSection === "power"

    ScrollView {
        id: powerSettingsScrollView
        anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.left: parent.left
        anchors.leftMargin: 24; anchors.topMargin: 24; anchors.bottomMargin: 24
        width: parent.width - 36
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            width: powerSettingsScrollView.availableWidth
            spacing: 8

            SettingsGroup {
                Layout.fillWidth: true
                title: tr("power_group_confirm")
                icon: ""
                titleSize: 12; bodySpacing: 14
                expanded: globalState.settingsExpanded["power_group_confirm"] !== false
                onToggled: { var m = Object.assign({}, globalState.settingsExpanded); m["power_group_confirm"] = (m["power_group_confirm"] === false); globalState.settingsExpanded = m; }
                accent: pal.primary; textColor: pal.colorOnSurfVar; lineColor: pal.surfaceVar; hoverColor: pal.surfaceVar
                cardColor: globalState.glassMode ? ga(pal.surfaceDeep, 0.7) : pal.surfaceDeep; cardOpenColor: globalState.glassMode ? ga(pal.surfaceElevated, 0.78) : pal.surfaceElevated; innerColor: globalState.glassMode ? ga(pal.surfaceHigh, 0.82) : pal.surfaceHigh; iconContColor: pal.secondaryCont; titleColor: pal.colorOnSurface; subColor: pal.colorOnSurfVar; bodyFont: globalState.fontSecondary
                titleFont: globalState.fontPrimary; fontScale: globalState.fontScale

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Text { text: ""; font.family: "Material Symbols Rounded"; font.pixelSize: 16; color: pal.primary }
                        Text {
                            Layout.fillWidth: true
                            text: tr("power_confirm_enable")
                            font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                            color: pal.colorOnSurfVar
                            wrapMode: Text.WordWrap
                        }
                        ESwitch {
                            checked: globalState.powerConfirmEnabled
                            onToggled: { globalState.powerConfirmEnabled = !globalState.powerConfirmEnabled; savePrefs(); }
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: tr("power_confirm_enable_d")
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale)
                        color: pal.mutedDeep
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    enabled: globalState.powerConfirmEnabled
                    opacity: enabled ? 1 : 0.45
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Text { text: ""; font.family: "Material Symbols Rounded"; font.pixelSize: 16; color: pal.primary }
                        Text {
                            Layout.fillWidth: true
                            text: tr("power_confirm_seconds")
                            font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                            color: pal.colorOnSurfVar
                        }
                        Text {
                            text: globalState.powerConfirmSeconds + " s"
                            font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale)
                            color: pal.muted
                        }
                    }
                    SegmentedPill {
                        Layout.fillWidth: true
                        options: [10, 15, 30, 60, 120].map(function (n) { return { value: n, label: n + " s" }; })
                        current: globalState.powerConfirmSeconds
                        onPicked: (v) => { globalState.powerConfirmSeconds = v; savePrefs(); }
                        trackColor: m3.glassy(m3.surfaceContainerHighest, 0.6)
                        selectedColor: pal.primary
                        textColor: pal.colorOnSurfVar
                        selectedTextColor: pal.colorOnPrimary
                        iconColor: pal.primary
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    enabled: globalState.powerConfirmEnabled
                    opacity: enabled ? 1 : 0.45
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Text { text: ""; font.family: "Material Symbols Rounded"; font.pixelSize: 16; color: pal.primary }
                        Text {
                            Layout.fillWidth: true
                            text: tr("power_confirm_show_others")
                            font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                            color: pal.colorOnSurfVar
                            wrapMode: Text.WordWrap
                        }
                        ESwitch {
                            checked: globalState.powerConfirmShowOthers
                            onToggled: { globalState.powerConfirmShowOthers = !globalState.powerConfirmShowOthers; savePrefs(); }
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: tr("power_confirm_show_others_d")
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale)
                        color: pal.mutedDeep
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    enabled: globalState.powerConfirmEnabled
                    opacity: enabled ? 1 : 0.45
                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: tr("power_confirm_preview_d")
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale)
                        color: pal.mutedDeep
                    }
                    EButton {
                        size: "xs"
                        variant: "tonal"
                        icon: ""
                        text: tr("power_confirm_preview")
                        fontFamily: globalState.fontSecondary
                        onClicked: globalState.previewPowerConfirm()
                    }
                }
            }
        }
    }
}
