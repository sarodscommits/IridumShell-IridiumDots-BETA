import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Settings: sound page
Item {
    id: sdSoundPage
    anchors.fill: parent
    visible: settingsPopup.activeSection === "sound"
    EPage {
        anchors.fill: parent
        anchors.leftMargin: 24; anchors.rightMargin: 12; anchors.bottomMargin: 16

        ESection {
            title: tr("ui_sounds")
            subtitle: tr("ui_sounds_d")
            icon: "\ue050"
            ESettingRow {
                icon: globalState.uiSoundsEnabled ? "\ue050" : "\ue04f"
                label: tr("ui_sounds_enable")
                desc: tr("ui_sounds_enable_d")
                ESwitch {
                    checked: globalState.uiSoundsEnabled
                    onToggled: {
                        globalState.uiSoundsEnabled = !globalState.uiSoundsEnabled;
                        savePrefs();
                        globalState.playUiClick();
                    }
                }
            }
        }

        ESection {
            title: tr("notification_sound")
            subtitle: tr("sd_sound_d")
            icon: "\ue7f4"
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Repeater {
                    id: notifSoundRepeater
                    model: [{ path: "", name: tr("notification_sound_default") }].concat(globalState.notificationSoundList)
                    property color _primary:   pal.primary
                    property color _onSurfVar: pal.colorOnSurfVar
                    property color _hoverBg:   Qt.rgba(pal.primary.r, pal.primary.g, pal.primary.b, 0.12)

                    RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 8

                        property bool isSelected: globalState.notificationSoundPath === modelData.path

                        Rectangle {
                            Layout.fillWidth: true
                            height: 30
                            radius: 8
                            color: notifRowHov.hovered ? notifSoundRepeater._hoverBg
                            : (parent.isSelected ? Qt.rgba(notifSoundRepeater._primary.r, notifSoundRepeater._primary.g, notifSoundRepeater._primary.b, 0.08) : "transparent")
                            Behavior on color { M3ColorAnim { duration: m3.durFast } }

                            HoverHandler { id: notifRowHov }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: setNotificationSoundPath(modelData.path)
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8; anchors.rightMargin: 6
                                spacing: 8

                                Text {
                                    text: "\ue5ca"
                                    font.family: "Material Symbols Rounded"; font.pixelSize: 14
                                    color: notifSoundRepeater._primary
                                    visible: isSelected
                                }

                                Text {
                                    text: modelData.name
                                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale)
                                    font.weight: isSelected ? Font.Medium : Font.Normal
                                    color: notifSoundRepeater._onSurfVar
                                    elide: Text.ElideMiddle
                                    Layout.fillWidth: true
                                    opacity: globalState.glassMode ? 0.88 : 1.0
                                }

                                PressIconButton {
                                    visible: modelData.path !== ""
                                    width: 22
                                    height: 22
                                    cornerRadius: 11
                                    icon: "\ue037"
                                    iconSize: 14
                                    iconColor: notifSoundRepeater._primary
                                    hoverColor: Qt.rgba(notifSoundRepeater._primary.r, notifSoundRepeater._primary.g, notifSoundRepeater._primary.b, 0.18)
                                    idleColor: "transparent"
                                    onClicked: previewNotificationSound(modelData.path)
                                }
                            }
                        }
                    }
                }
            }
            Text {
                visible: globalState.notificationSoundList.length === 0
                Layout.fillWidth: true
                text: tr("notification_sound_empty")
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale)
                color: pal.mutedDeep
                wrapMode: Text.WordWrap
            }
            ESettingRow {
                icon: "\ue050"; label: tr("notification_sound_volume"); desc: Math.round(globalState.notificationSoundVolume) + " %"
                FractionSlider {
                    id: notifVolumeTrack
                    Layout.preferredWidth: 280
                    property real displayPct: globalState.notificationSoundVolume / 100
                    value: displayPct
                    trackH: 14
                    handleHOverride: 20
                    height: 22
                    activeColor: pal.toggleOn
                    inactiveColor: globalState.glassMode ? ga(pal.surfaceDeep, 0.6) : pal.surfaceDeep
                    steps: Math.max(0, (11) - 1)
                    showBubble: true
                    onFracMoved: (frac) => { var raw = frac * 100; var v=Math.round(raw/10)*10; setNotificationSoundVolume(v); }
                }
            }
        }

        ESection {
            title: tr("sd_lang_region")
            subtitle: tr("sd_lang_d")
            icon: "\ue8e2"
            SegmentedPill {
                Layout.fillWidth: true
                columns: 5
                segHeight: 28
                fontSize: Math.round(11 * globalState.fontScale)
                options: i18n.languages.map(function(l) { return { value: l.code, label: l.name }; })
                current: globalState.language
                onPicked: (v) => setLanguage(v)
                trackColor: m3.glassy(m3.surfaceContainerHighest, 0.6)
                selectedColor: pal.primary
                textColor: pal.colorOnSurfVar
                selectedTextColor: pal.colorOnPrimary
                iconColor: pal.primary
            }
            ESettingRow {
                icon: "\ue8b5"; label: tr("clock_format")
                SegmentedPill {
                    Layout.preferredWidth: 120
                    segHeight: 28
                    options: [{ value: false, label: "12h" }, { value: true, label: "24h" }]
                    current: globalState.clockFormat24h
                    onPicked: (v) => setClockFormat24h(v)
                    trackColor: m3.glassy(m3.surfaceContainerHighest, 0.6)
                    selectedColor: pal.primary
                    textColor: pal.colorOnSurfVar
                    selectedTextColor: pal.colorOnPrimary
                    iconColor: pal.primary
                }
            }
        }
    }
}
