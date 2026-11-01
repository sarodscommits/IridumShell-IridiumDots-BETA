import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Settings: home page (M3 Expressive overview)
Item {
    id: sdHomePage
    anchors.fill: parent
    visible: settingsPopup.activeSection === "home"
    EPage {
        anchors.fill: parent
        anchors.leftMargin: 24; anchors.rightMargin: 12; anchors.bottomMargin: 16

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Math.max(320, sdHeroCol.implicitHeight + 72)
            radius: m3.corner(48)
            color: m3.primaryContainer
            clip: true
            AutoShape {
                width: 400; height: 400
                x: parent.width - 300; y: -70
                fill: m3.alpha(m3.primary, 0.28)
                interval: 2200
                spinStep: 60
                running: sdHomePage.visible
            }
            AutoShape {
                width: 150; height: 150
                x: parent.width - 390; y: 180
                seq: [m3.accentShape, "Flower", "Cookie6Sided", "Clover4Leaf", "Sunny", "Pill", "Gem"]
                fill: m3.tertiary
                interval: 1500
                morphToken: "spatialDefault"
                running: sdHomePage.visible
            }
            ColumnLayout {
                id: sdHeroCol
                x: 36; y: 32
                width: Math.min(parent.width * 0.58, 560)
                spacing: 12
                EText { role: "labelLarge"; emph: true; text: "IRIDIUM SHELL · MATERIAL 3 EXPRESSIVE"; color: m3.inkPrimaryContainer; font.letterSpacing: 1.4; Layout.fillWidth: true; elide: Text.ElideRight }
                EText { role: "displayMedium"; emph: true; text: tr("sd_home_title"); color: m3.inkPrimaryContainer; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                EText { role: "bodyLarge"; color: m3.inkPrimaryContainer; opacity: 0.85; text: tr("sd_home_body"); Layout.fillWidth: true; wrapMode: Text.WordWrap; lineHeightMode: Text.ProportionalHeight; lineHeight: 1.2 }
                Flow {
                    Layout.fillWidth: true
                    spacing: 12
                    EButton { size: "m"; icon: ""; text: tr("wallpapers"); onClicked: globalState.openWallpaperBrowser() }
                    EButton { size: "m"; variant: "tonal"; icon: ""; text: tr("sd_motion"); onClicked: settingsWindow.setSection("motion") }
                }
            }
        }

        Repeater {
            model: settingsPopup.groupDefs
            delegate: ColumnLayout {
                id: sdHomeGroup
                required property var modelData
                required property int index
                readonly property var items: settingsPopup.sectionsInGroup(modelData.key)
                readonly property bool big: modelData.key === "personal"
                Layout.fillWidth: true
                Layout.topMargin: 8
                spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    spacing: 2
                    EText { role: "titleLarge"; emph: true; text: sdHomeGroup.modelData.title; Layout.fillWidth: true; elide: Text.ElideRight }
                    EText { role: "bodyMedium"; color: m3.inkSurfaceVariant; text: sdHomeGroup.modelData.sub; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                }
                GridLayout {
                    id: sdHomeGroupGrid
                    Layout.fillWidth: true
                    columns: width > 760 ? 3 : 2
                    columnSpacing: 16
                    rowSpacing: 16
                    Repeater {
                        model: sdHomeGroup.items
                        delegate: ECard {
                            id: sdHomeCard
                            required property var modelData
                            required property int index
                            kind: ["elevated", "filled", "outlined"][(index + sdHomeGroup.index) % 3]
                            Layout.fillWidth: true
                            Layout.preferredHeight: sdHomeGroup.big ? 176 : 132
                            onClicked: { settingsWindow.setSection(modelData.id); globalState.playUiClick(); }
                            RowLayout {
                                spacing: 14
                                Item {
                                    Layout.preferredWidth: 48; Layout.preferredHeight: 48
                                    AutoShape {
                                        anchors.fill: parent
                                        seq: [m3.accentShape, "Circle"]
                                        interval: 1400 + sdHomeCard.index * 230
                                        fill: sdHomeCard.index % 2 ? m3.tertiaryContainer : m3.primaryContainer
                                        morphToken: "spatialFast"
                                        running: sdHomePage.visible
                                    }
                                    Text { anchors.centerIn: parent; text: sdHomeCard.modelData.icon; font.family: "Material Symbols Rounded"; font.pixelSize: 22; color: sdHomeCard.index % 2 ? m3.inkTertiaryContainer : m3.inkPrimaryContainer }
                                }
                                EText { role: sdHomeGroup.big ? "headlineSmall" : "titleLarge"; emph: true; text: sdHomeCard.modelData.label; Layout.fillWidth: true; elide: Text.ElideRight }
                                Text { text: "\ue5cc"; font.family: "Material Symbols Rounded"; font.pixelSize: 22; color: m3.inkSurfaceVariant }
                            }
                            EText {
                                Layout.fillWidth: true
                                role: "bodyMedium"; color: m3.inkSurfaceVariant; wrapMode: Text.WordWrap
                                maximumLineCount: 2; elide: Text.ElideRight
                                lineHeightMode: Text.ProportionalHeight; lineHeight: 1.15
                                text: settingsPopup.sectionSummary(sdHomeCard.modelData.id)
                            }
                                Item {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 28
                                visible: sdHomeGroup.big
                                    Row {
                                        visible: sdHomeCard.modelData.id === "color"
                                        spacing: 4
                                        Repeater {
                                            model: 6
                                            Rectangle {
                                                required property int index
                                                width: 28; height: 28; radius: index === 0 ? 14 : 8
                                                color: [m3.primary, m3.secondary, m3.tertiary, m3.primaryContainer, m3.secondaryContainer, m3.tertiaryContainer][index]
                                            }
                                        }
                                    }
                                    Row {
                                        visible: sdHomeCard.modelData.id === "components"
                                        spacing: 12
                                        ESwitch { checked: true; interactive: false; anchors.verticalCenter: parent.verticalCenter; scaleF: 0.8 }
                                        EWavyLinear { width: 120; value: 0.6; anchors.verticalCenter: parent.verticalCenter; running: sdHomePage.visible }
                                    }
                                    EWavyLinear {
                                        visible: sdHomeCard.modelData.id === "motion"
                                        width: parent.width; anchors.verticalCenter: parent.verticalCenter
                                        indeterminate: true; running: sdHomePage.visible && visible
                                    }
                                }
                        }
                    }
                }
            }
        }
    }
}
