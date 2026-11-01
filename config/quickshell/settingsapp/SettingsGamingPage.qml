import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../settings"

// Settings: gaming hub page
Item {
    id: settingsGamingPage
    anchors.fill: parent
    visible: settingsPopup.activeSection === "gaming hub"

    ScrollView {
        id: ghSettingsScrollView
        anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.left: parent.left
        anchors.leftMargin: 24; anchors.topMargin: 24; anchors.bottomMargin: 24
        width: parent.width - 36
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            width: ghSettingsScrollView.availableWidth
            spacing: 14

            SettingsGroup {
                Layout.fillWidth: true
                title: tr("gh_behavior")
                icon: "\ue429"
                titleSize: 12; bodySpacing: 4
                expanded: globalState.settingsExpanded["gh_behavior"] === true
                onToggled: globalState.toggleSettingsGroup("gh_behavior")
                accent: pal.primary; textColor: pal.colorOnSurfVar; lineColor: pal.surfaceVar; hoverColor: pal.surfaceVar
                cardColor: globalState.glassMode ? ga(pal.surfaceDeep, 0.7) : pal.surfaceDeep; cardOpenColor: globalState.glassMode ? ga(pal.surfaceElevated, 0.78) : pal.surfaceElevated; innerColor: globalState.glassMode ? ga(pal.surfaceHigh, 0.82) : pal.surfaceHigh; iconContColor: pal.secondaryCont; titleColor: pal.colorOnSurface; subColor: pal.colorOnSurfVar; bodyFont: globalState.fontSecondary
                titleFont: globalState.fontPrimary; fontScale: globalState.fontScale

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Text { text: ""; font.family: "Material Symbols Rounded"; font.pixelSize: 16; color: pal.primary }
                    Text {
                        Layout.fillWidth: true
                        text: tr("gh_esc_on_open")
                        wrapMode: Text.WordWrap
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                        color: pal.colorOnSurfVar
                    }
                    ESwitch {
                        checked: globalState.gamingEscOnOpen
                        onToggled: setGamingEscOnOpen(!globalState.gamingEscOnOpen)
                    }
                }
                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: tr("gh_esc_note")
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale)
                    color: pal.mutedDeep
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 12
                    spacing: 6
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Text { text: "\ue891"; font.family: "Material Symbols Rounded"; font.pixelSize: 16; color: pal.primary }
                        Text {
                            Layout.fillWidth: true
                            text: tr("gh_float_opacity")
                            wrapMode: Text.WordWrap
                            font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                            color: pal.colorOnSurfVar
                        }
                        Text {
                            text: Math.round(globalState.gamingFloatOpacity * 100) + "%"
                            font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale)
                            color: pal.muted
                        }
                    }
                    FractionSlider {
                        id: ghFloatOpTrack
                        Layout.fillWidth: true
                        readonly property int dotCount: 19
                        property real displayPct: (globalState.gamingFloatOpacity - 0.1) / 0.9
                        value: displayPct
                        trackH: 14
                        handleHOverride: 20
                        height: 22
                        activeColor: pal.toggleOn
                        inactiveColor: globalState.glassMode ? ga(pal.surfaceDeep, 0.6) : pal.surfaceDeep
                        steps: Math.max(0, (ghFloatOpTrack.dotCount) - 1)
                        showBubble: false
                        onFracMoved: (frac) => { var idx = Math.round(frac * (ghFloatOpTrack.dotCount - 1)); setGamingFloatOpacity(0.1 + idx * 0.05); }
                    }
                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: tr("gh_float_opacity_note")
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale)
                        color: pal.mutedDeep
                    }
                }
            }

            Repeater {
                model: [
                { title: "gh_modules", icon: "\ue871", items: [
                    { k: "status",  icon: "", label: "gh_mod_status"  },
                    { k: "rings",   icon: "", label: "gh_mod_rings"   },
                    { k: "perf",    icon: "", label: "gh_mod_perf"    },
                    { k: "actions", icon: "", label: "gh_mod_actions" },
                    { k: "sliders", icon: "", label: "gh_mod_sliders" } ] },
                { title: "gh_metrics", icon: "\uf20c", items: [
                    { k: "fps",      icon: "", label: "gh_mod_fps"       },
                    { k: "cpu",      icon: "", label: "gh_mod_cpu"       },
                    { k: "gpu",      icon: "", label: "gh_mod_gpu"       },
                    { k: "ram",      icon: "", label: "gh_mod_ram"       },
                    { k: "ping",     icon: "", label: "gh_mod_ping"      },
                    { k: "gpuExtra", icon: "", label: "gh_mod_gpu_extra" } ] }
                ]
                delegate: SettingsGroup {
                    id: ghGroup
                    required property var modelData
                    Layout.fillWidth: true
                    title: tr(ghGroup.modelData.title)
                    icon: ghGroup.modelData.icon
                    titleSize: 12
                    expanded: globalState.settingsExpanded["gh_" + ghGroup.modelData.title] === true
                    onToggled: globalState.toggleSettingsGroup("gh_" + ghGroup.modelData.title)
                    accent: pal.primary; textColor: pal.colorOnSurfVar; lineColor: pal.surfaceVar; hoverColor: pal.surfaceVar
                    cardColor: globalState.glassMode ? ga(pal.surfaceDeep, 0.7) : pal.surfaceDeep; cardOpenColor: globalState.glassMode ? ga(pal.surfaceElevated, 0.78) : pal.surfaceElevated; innerColor: globalState.glassMode ? ga(pal.surfaceHigh, 0.82) : pal.surfaceHigh; iconContColor: pal.secondaryCont; titleColor: pal.colorOnSurface; subColor: pal.colorOnSurfVar; bodyFont: globalState.fontSecondary
                    titleFont: globalState.fontPrimary; fontScale: globalState.fontScale

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: ghItemsCol.implicitHeight + 16
                        radius: 16
                        color: globalState.glassMode ? ga(pal.surfacePop, 0.6) : pal.surfacePop

                        ColumnLayout {
                            id: ghItemsCol
                            anchors.left: parent.left; anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 8
                            spacing: 0

                            Repeater {
                                model: ghGroup.modelData.items
                                delegate: Rectangle {
                                    id: ghRow
                                    required property var modelData
                                    readonly property bool on: globalState.gamingModules[modelData.k] !== false
                                    Layout.fillWidth: true
                                    implicitHeight: 38
                                    radius: 10
                                    color: ghRowHov.hovered ? ga(pal.colorOnSurface, 0.05) : "transparent"

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8; anchors.rightMargin: 8
                                        spacing: 10
                                        Text {
                                            text: ghRow.modelData.icon
                                            font.family: "Material Symbols Rounded"; font.pixelSize: 16
                                            color: ghRow.on ? pal.primary : pal.mutedDeep
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: tr(ghRow.modelData.label)
                                            elide: Text.ElideRight
                                            font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                                            color: ghRow.on ? pal.colorOnSurfVar : pal.muted
                                        }
                                        ESwitch {
                                            checked: ghRow.on
                                            interactive: false
                                        }
                                    }
                                    HoverHandler { id: ghRowHov }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: setGamingModule(ghRow.modelData.k, !ghRow.on)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 8 }
        }
    }
}
