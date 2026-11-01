import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Settings: typography page
Item {
    id: sdTypePage
    anchors.fill: parent
    visible: settingsPopup.activeSection === "type"
    EPage {
        anchors.fill: parent
        anchors.leftMargin: 24; anchors.rightMargin: 12; anchors.bottomMargin: 16

        ESection {
            title: tr("settings_section_fonts")
            subtitle: tr("sd_fonts_d")
            icon: "\ue262"
            ColumnLayout {
                id: fontSettingsBlock
                Layout.fillWidth: true
                spacing: 18

                property color cIcon:      pal.primary
                property color cLabel:     pal.colorOnSurfVar
                property color cMuted:     pal.muted
                property color cActiveTxt: pal.primary
                property color cIdleTxt:   pal.colorOnSurfVar
                property color cActiveBg:  Qt.rgba(pal.primary.r, pal.primary.g, pal.primary.b, 0.18)
                property color cHoverBg:   Qt.rgba(pal.colorOnSurfVar.r, pal.colorOnSurfVar.g, pal.colorOnSurfVar.b, 0.08)
                property color cTrackBg:   globalState.glassMode ? ga(pal.surfaceDeep, 0.6) : pal.surfaceDeep
                property color cSel:       pal.primary
                property color cOnSel:     pal.colorOnPrimary

                Repeater {
                    model: [
                        { which: "primary",   label: tr("font_primary"),   desc: tr("font_primary_desc"),   glyph: "\ue264" },
                        { which: "secondary", label: tr("font_secondary"), desc: tr("font_secondary_desc"), glyph: "\ue262" }
                    ]
                    ColumnLayout {
                        id: fontRoleCol
                        required property var modelData
                        readonly property string which: modelData.which
                        readonly property string currentKey: which === "primary" ? globalState.fontPrimaryKey : globalState.fontSecondaryKey
                        Layout.fillWidth: true
                        spacing: 10
                        ESettingRow {
                            icon: fontRoleCol.modelData.glyph
                            label: fontRoleCol.modelData.label
                            desc: fontRoleCol.modelData.desc
                        }
                        SegmentedPill {
                            Layout.fillWidth: true
                            segHeight: 28
                            fontSize: 13
                            options: globalState.fontCatalog.map(function(f) {
                                var r = globalState.fontResolved[f.key];
                                return { value: f.key, label: f.label, font: r.family, enabled: r.available };
                            })
                            current: fontRoleCol.currentKey
                            onPicked: (v) => setFont(fontRoleCol.which, v)
                            trackColor: fontSettingsBlock.cTrackBg
                            selectedColor: fontSettingsBlock.cSel
                            textColor: fontSettingsBlock.cIdleTxt
                            selectedTextColor: fontSettingsBlock.cOnSel
                        }
                    }
                }
            }
        }

        ESection {
            title: tr("sd_type_settings")
            subtitle: tr("sd_type_settings_d")
            icon: ""
            ESettingRow {
                icon: ""; label: tr("sd_font_scale"); desc: Math.round(globalState.fontScale * 100) + " %"
                ESlider {
                    Layout.preferredWidth: 260
                    height: 36; trackH: 16; handleHOverride: 32
                    steps: 10
                    value: (globalState.fontScale - 0.8) / 0.5
                    bubbleText: Math.round((0.8 + value * 0.5) * 100) + "%"
                    onMoved: (v) => setFontScale(Math.round((0.8 + v * 0.5) * 100) / 100)
                    onReleased: savePrefs()
                }
            }
            ESettingRow {
                icon: ""; label: tr("sd_emphasis"); desc: tr("sd_emphasis_d")
                ESwitch { checked: globalState.m3Emphasis; onToggled: (v) => setM3("m3Emphasis", v) }
            }
        }

        ESection {
            title: tr("sd_type_sample")
            subtitle: tr("sd_type_sample_d")
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 56
                color: m3.glassy(m3.surfaceContainerHighest, 0.6)
                topLeftRadius: 4; topRightRadius: 4
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: sdTypeInput.activeFocus ? 2 : 1; color: sdTypeInput.activeFocus ? m3.primary : m3.inkSurfaceVariant }
                EText { x: 16; y: 7; role: "bodySmall"; text: tr("sd_type_sample"); color: sdTypeInput.activeFocus ? m3.primary : m3.inkSurfaceVariant }
                TextInput {
                    id: sdTypeInput
                    x: 16; y: 26; width: parent.width - 32
                    text: "Iridium Shell — Material 3 Expressive"
                    color: m3.inkSurface; font.family: m3.fontBody; font.pixelSize: Math.round(16 * m3.fs)
                    selectByMouse: true; clip: true
                    selectionColor: m3.primary; selectedTextColor: m3.inkPrimary
                }
            }
            Repeater {
                model: m3.typeRoles
                delegate: RowLayout {
                    id: sdTypeRow
                    required property string modelData
                    Layout.fillWidth: true
                    spacing: 16
                    ColumnLayout {
                        Layout.preferredWidth: 150
                        Layout.alignment: Qt.AlignTop
                        spacing: 0
                        EText { role: "labelLarge"; emph: true; text: sdTypeRow.modelData; color: m3.primary }
                        EText { role: "labelSmall"; color: m3.inkSurfaceVariant; text: Math.round(m3.type[sdTypeRow.modelData][0] * m3.fs) + " / " + Math.round(m3.type[sdTypeRow.modelData][1] * m3.fs) + " · " + m3.tw(sdTypeRow.modelData, false) }
                    }
                    EText {
                        Layout.fillWidth: true
                        role: sdTypeRow.modelData
                        text: sdTypeInput.text
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
