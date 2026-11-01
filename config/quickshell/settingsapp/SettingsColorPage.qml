import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Settings: color page (palettes, roles, containment)
Item {
    id: sdColorPage
    anchors.fill: parent
    visible: settingsPopup.activeSection === "color"
    EPage {
        anchors.fill: parent
        anchors.leftMargin: 24; anchors.rightMargin: 12; anchors.bottomMargin: 16

        ESection {
            title: tr("sd_color_source")
            subtitle: tr("sd_color_source_d")
            icon: ""
            ESettingRow {
                icon: ""; label: tr("color_mode")
                SegmentedPill {
                    Layout.preferredWidth: 220
                    options: [{ value: "light", label: tr("light"), icon: "" }, { value: "dark", label: tr("dark"), icon: "" }]
                    current: globalState.colorMode
                    onPicked: (v) => setColorMode(v)
                    selectedColor: pal.primary; selectedTextColor: pal.colorOnPrimary
                    textColor: pal.colorOnSurfVar; iconColor: pal.primary
                }
            }
            ESettingRow {
                icon: ""; label: tr("palette_source")
                SegmentedPill {
                    Layout.preferredWidth: 300
                    options: [{ value: "matugen", label: tr("palette_source_matugen") }, { value: "preset", label: tr("palette_source_preset") }]
                    current: globalState.paletteSource
                    onPicked: (v) => setPaletteSource(v)
                    selectedColor: pal.primary; selectedTextColor: pal.colorOnPrimary
                    textColor: pal.colorOnSurfVar; iconColor: pal.primary
                }
            }
            Flow {
                Layout.fillWidth: true
                visible: globalState.paletteSource === "preset"
                spacing: 10
                Repeater {
                    model: globalState.presetPalettes
                    delegate: Item {
                        id: sdSw
                        required property var modelData
                        readonly property bool sel: globalState.presetPaletteKey === modelData.key
                        width: 44; height: 44
                        Spring { id: sdSwM; target: sdSw.sel ? 1 : 0; token: "spatialFast"; eps: 0.002 }
                        MShape {
                            anchors.fill: parent
                            from: "Circle"; to: m3.accentShape
                            t: sdSwM.value; rot: 40 * sdSwM.value
                            inset: 0.78 + 0.16 * sdSwM.value
                            fill: Qt.hsla((((sdSw.modelData.hue % 360) + 360) % 360) / 360, sdSw.modelData.sat, 0.55, 1)
                        }
                        Text {
                            anchors.centerIn: parent
                            opacity: Math.max(0, Math.min(1, sdSwM.value))
                            text: ""; font.family: "Material Symbols Rounded"; font.pixelSize: 18
                            color: sdSw.modelData.sat < 0.15 ? "#000000" : "#FFFFFF"
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: setPresetPalette(sdSw.modelData.key) }
                    }
                }
            }
            ESettingRow {
                visible: globalState.paletteSource === "preset"
                icon: "\ue30a"; label: tr("preset_apply_quickshell")
                ESwitch {
                    checked: globalState.presetApplyQuickshell
                    onToggled: setPresetApplyQuickshell(!globalState.presetApplyQuickshell)
                }
            }
            ESettingRow {
                visible: globalState.paletteSource === "preset"
                icon: "\ueb8e"; label: tr("preset_apply_kitty")
                ESwitch {
                    checked: globalState.presetApplyKitty
                    onToggled: setPresetApplyKitty(!globalState.presetApplyKitty)
                }
            }
            ESettingRow {
                readonly property bool presetOwnsKitty: globalState.paletteSource === "preset" && globalState.presetApplyKitty
                enabled: !presetOwnsKitty
                opacity: presetOwnsKitty ? 0.4 : 1.0
                icon: "\ueb8e"; label: tr("term_palette")
                desc: presetOwnsKitty ? tr("term_palette_preset_note") : tr("term_palette_d")
                SegmentedPill {
                    Layout.preferredWidth: 320
                    options: [{ value: "pywal",      label: tr("term_palette_pywal") },
                    { value: "matugen",    label: tr("term_palette_matugen") },
                    { value: "matugen_bg", label: tr("term_palette_bg") }]
                    current: globalState.termPaletteMode
                    onPicked: (v) => setTermPaletteMode(v)
                    selectedColor: pal.primary; selectedTextColor: pal.colorOnPrimary
                    textColor: pal.colorOnSurfVar; iconColor: pal.primary
                }
            }
        }

        ESection {
            title: tr("sd_glass")
            subtitle: tr("sd_glass_d")
            icon: "\ue3b0"
            ESettingRow {
                icon: "\ue3b0"; label: tr("glass_mode")
                ESwitch {
                    checked: globalState.glassMode
                    onToggled: setGlassMode(!globalState.glassMode)
                }
            }
            ESettingRow {
                enabled: globalState.glassMode
                opacity: globalState.glassMode ? 1.0 : 0.4
                icon: "\ue30a"; label: tr("glass_quickshell")
                ESwitch {
                    checked: globalState.glassQuickshellEnabled
                    onToggled: setGlassQuickshellEnabled(!globalState.glassQuickshellEnabled)
                }
            }
            ESettingRow {
                enabled: globalState.glassMode
                opacity: globalState.glassMode ? 1.0 : 0.4
                icon: "\ueb8e"; label: tr("glass_kitty")
                ESwitch {
                    checked: globalState.glassKittyEnabled
                    onToggled: setGlassKittyEnabled(!globalState.glassKittyEnabled)
                }
            }
            ESettingRow {
                opacity: (globalState.glassMode && globalState.glassQuickshellEnabled) ? 1.0 : 0.4
                icon: "\ue91c"; label: tr("glass_opacity"); desc: Math.round(globalState.glassQuickshellOpacity * 100) + " %"
                FractionSlider {
                    id: glassOpacityTrack
                    Layout.preferredWidth: 280
                    enabled: globalState.glassMode && globalState.glassQuickshellEnabled
                    property real displayPct: (globalState.glassQuickshellOpacity - 0.35) / 0.40
                    value: displayPct
                    trackH: 14
                    handleHOverride: 20
                    height: 22
                    activeColor: pal.toggleOn
                    inactiveColor: globalState.glassMode ? ga(pal.surfaceDeep, 0.6) : pal.surfaceDeep
                    steps: Math.max(0, (9) - 1)
                    showBubble: false
                    Behavior on opacity { M3NumberAnim {} }
                    onFracMoved: (frac) => { var raw = frac * 0.40; var v=Math.round(raw/0.05)*0.05; setGlassQuickshellOpacity(0.35 + v); }
                }
            }
        }

        ESection {
            title: tr("sd_tonal")
            subtitle: tr("sd_tonal_d")
            Repeater {
                model: [
                { name: "Primary",   c: "primary",   s: 1.0 },
                { name: "Secondary", c: "secondary", s: 1.0 },
                { name: "Tertiary",  c: "tertiary",  s: 1.0 },
                { name: "Neutral",   c: "primary",   s: 0.12 },
                { name: "Error",     c: "error",     s: 1.0 }
                ]
                delegate: RowLayout {
                    id: sdTone
                    required property var modelData
                    readonly property color seed: m3[modelData.c]
                    readonly property real hue: Math.max(0, seed.hslHue)
                    readonly property real sat: Math.max(0.05, seed.hslSaturation) * modelData.s
                    Layout.fillWidth: true
                    spacing: 12
                    EText { text: sdTone.modelData.name; role: "labelLarge"; Layout.preferredWidth: 90; color: m3.inkSurfaceVariant }
                    Row {
                        id: sdToneRow
                        Layout.fillWidth: true
                        height: 44
                        spacing: 2
                        readonly property var tones: [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 95, 99, 100]
                        Repeater {
                            model: sdToneRow.tones
                            delegate: Rectangle {
                                required property var modelData
                                required property int index
                                width: (sdToneRow.width - 2 * (sdToneRow.tones.length - 1)) / sdToneRow.tones.length
                                height: 44
                                color: Qt.hsla(sdTone.hue, sdTone.sat, modelData / 100, 1)
                                topLeftRadius: index === 0 ? 16 : 4; bottomLeftRadius: index === 0 ? 16 : 4
                                topRightRadius: index === sdToneRow.tones.length - 1 ? 16 : 4; bottomRightRadius: index === sdToneRow.tones.length - 1 ? 16 : 4
                                EText { anchors.centerIn: parent; text: modelData; role: "labelSmall"; color: modelData > 55 ? "#1a1a1a" : "#f2f2f2" }
                            }
                        }
                    }
                }
            }
        }

        ESection {
            title: tr("sd_roles")
            subtitle: tr("sd_roles_d")
            GridLayout {
                Layout.fillWidth: true
                columns: width > 700 ? 4 : 3
                columnSpacing: 10
                rowSpacing: 10
                Repeater {
                    model: [
                    ["primary", "inkPrimary"], ["primaryContainer", "inkPrimaryContainer"], ["secondary", "inkSecondary"], ["secondaryContainer", "inkSecondaryContainer"],
                    ["tertiary", "inkTertiary"], ["tertiaryContainer", "inkTertiaryContainer"], ["error", "inkError"], ["errorContainer", "inkErrorContainer"],
                    ["surfaceContainerLowest", "inkSurface"], ["surfaceContainer", "inkSurface"], ["surfaceContainerHighest", "inkSurfaceVariant"], ["inverseSurface", "inverseOnSurface"]
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 76
                        radius: m3.corner(20)
                        color: m3[modelData[0]]
                        border.width: modelData[0].indexOf("surfaceContainer") === 0 ? 1 : 0
                        border.color: m3.outlineVariant
                        ColumnLayout {
                            x: 14; y: 12; width: parent.width - 28
                            spacing: 2
                            EText { text: modelData[0]; role: "labelLarge"; emph: true; color: m3[modelData[1]]; Layout.fillWidth: true; elide: Text.ElideRight }
                            EText { text: modelData[1].replace("ink", "on"); role: "labelSmall"; color: m3[modelData[1]]; opacity: 0.8; Layout.fillWidth: true; elide: Text.ElideRight }
                        }
                    }
                }
            }
        }

        ESection {
            title: tr("sd_surfaces")
            subtitle: tr("sd_surfaces_d")
            Item {
                Layout.fillWidth: true
                implicitHeight: 220
                Repeater {
                    model: ["surfaceContainerLowest", "surfaceContainerLow", "surfaceContainer", "surfaceContainerHigh", "surfaceContainerHighest"]
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        x: index * 34; y: index * 24
                        width: parent.width - index * 68; height: 220 - index * 40
                        radius: m3.corner(36 - index * 4)
                        color: m3[modelData]
                        border.width: 1; border.color: m3.alpha(m3.outlineVariant, 0.6)
                        EText { x: 16; y: 6; text: modelData; role: "labelMedium"; color: m3.inkSurfaceVariant }
                    }
                }
            }
        }
    }
}
