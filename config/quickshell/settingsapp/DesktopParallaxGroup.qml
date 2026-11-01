import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../settings"

// Parallax settings group
SettingsGroup {
    id: desktopParallaxGroup
    Layout.fillWidth: true
    title: tr("inf_group_parallax")
    icon: "\ue3f4"
    titleSize: 12; bodySpacing: 12
    expanded: globalState.settingsExpanded["inf_group_parallax"] === true
    onToggled: globalState.toggleSettingsGroup("inf_group_parallax")
    accent: pal.primary; textColor: pal.colorOnSurfVar; lineColor: pal.surfaceVar; hoverColor: pal.surfaceVar
    cardColor: globalState.glassMode ? ga(pal.surfaceDeep, 0.7) : pal.surfaceDeep; cardOpenColor: globalState.glassMode ? ga(pal.surfaceElevated, 0.78) : pal.surfaceElevated; innerColor: globalState.glassMode ? ga(pal.surfaceHigh, 0.82) : pal.surfaceHigh; iconContColor: pal.secondaryCont; titleColor: pal.colorOnSurface; subColor: pal.colorOnSurfVar; bodyFont: globalState.fontSecondary
    titleFont: globalState.fontPrimary; fontScale: globalState.fontScale

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Text {
                text: "\ue3f4"
                font.family: "Material Symbols Rounded"; font.pixelSize: 16
                color: pal.primary
            }
            Text {
                text: tr("plx_enable")
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                color: pal.colorOnSurfVar
                Layout.fillWidth: true
            }
            ESwitch {
                checked: globalState.parallaxEnabled
                onToggled: setParallaxEnabled(!globalState.parallaxEnabled)
            }
        }

        Text {
            Layout.fillWidth: true
            text: tr("plx_note")
            wrapMode: Text.WordWrap
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale)
            color: pal.muted
        }

        Repeater {
            model: [
            { prop: "parallaxZoom",     label: "plx_zoom",     icon: "\ue8ff", min: 1.1,  max: 1.5, fmt: "x" },
            { prop: "parallaxStrength", label: "plx_strength", icon: "\ue89f", min: 0.05, max: 0.4, fmt: "%" }
            ]
            delegate: ColumnLayout {
                id: plxSliderRow
                required property var modelData
                Layout.fillWidth: true
                spacing: 6
                opacity: globalState.parallaxEnabled ? 1 : 0.45
                Behavior on opacity { M3NumberAnim {} }
                readonly property real val: globalState[modelData.prop]
                readonly property real span: modelData.max - modelData.min

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Text {
                        text: plxSliderRow.modelData.icon
                        font.family: "Material Symbols Rounded"; font.pixelSize: 16
                        color: pal.primary
                    }
                    Text {
                        text: tr(plxSliderRow.modelData.label)
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                        color: pal.colorOnSurfVar
                        Layout.fillWidth: true
                    }
                    Text {
                        text: plxSliderRow.modelData.fmt === "x"
                        ? plxSliderRow.val.toFixed(2) + "x"
                        : Math.round(plxSliderRow.val * 100) + "%"
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale)
                        color: pal.muted
                    }
                }
                FractionSlider {
                    id: plxTrack
                    Layout.fillWidth: true
                    property real displayPct: (plxSliderRow.val - plxSliderRow.modelData.min) / plxSliderRow.span
                    value: displayPct
                    trackH: 14
                    handleHOverride: 20
                    height: 22
                    activeColor: pal.toggleOn
                    inactiveColor: globalState.glassMode ? ga(pal.surfaceDeep, 0.6) : pal.surfaceDeep
                    showBubble: false
                    onFracMoved: (frac) => { var raw = plxSliderRow.modelData.min + frac * plxSliderRow.span; setParallaxValue(plxSliderRow.modelData.prop, Math.round(raw / 0.05) * 0.05); }
                    onFracReleased: { savePrefs(); }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 10
            opacity: globalState.parallaxEnabled ? 1 : 0.45
            Text {
                text: "\ue30d"
                font.family: "Material Symbols Rounded"; font.pixelSize: 16
                color: pal.primary
            }
            Text {
                text: tr("plx_widgets")
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                color: pal.colorOnSurfVar
                Layout.fillWidth: true
            }
            ESwitch {
                checked: globalState.parallaxWidgets
                enabled: globalState.parallaxEnabled
                onToggled: setParallaxWidgets(!globalState.parallaxWidgets)
            }
        }

        Repeater {
            model: [
            { prop: "parallaxWidgetStrength", label: "plx_widgets_strength", icon: "\ue89f", min: 0.2, max: 0.9, fmt: "%" }
            ]
            delegate: ColumnLayout {
                id: plxWSliderRow
                required property var modelData
                Layout.fillWidth: true
                spacing: 6
                opacity: globalState.parallaxEnabled && globalState.parallaxWidgets ? 1 : 0.45
                Behavior on opacity { M3NumberAnim {} }
                readonly property real val: globalState[modelData.prop]
                readonly property real span: modelData.max - modelData.min

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Text {
                        text: plxWSliderRow.modelData.icon
                        font.family: "Material Symbols Rounded"; font.pixelSize: 16
                        color: pal.primary
                    }
                    Text {
                        text: tr(plxWSliderRow.modelData.label)
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                        color: pal.colorOnSurfVar
                        Layout.fillWidth: true
                    }
                    Text {
                        text: plxWSliderRow.modelData.fmt === "x"
                        ? plxWSliderRow.val.toFixed(2) + "x"
                        : Math.round(plxWSliderRow.val * 100) + "%"
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale)
                        color: pal.muted
                    }
                }
                FractionSlider {
                    id: plxWTrack
                    Layout.fillWidth: true
                    property real displayPct: (plxWSliderRow.val - plxWSliderRow.modelData.min) / plxWSliderRow.span
                    value: displayPct
                    trackH: 14
                    handleHOverride: 20
                    height: 22
                    activeColor: pal.toggleOn
                    inactiveColor: globalState.glassMode ? ga(pal.surfaceDeep, 0.6) : pal.surfaceDeep
                    showBubble: false
                    onFracMoved: (frac) => { var raw = plxWSliderRow.modelData.min + frac * plxWSliderRow.span; setParallaxValue(plxWSliderRow.modelData.prop, Math.round(raw / 0.05) * 0.05); }
                    onFracReleased: { savePrefs(); }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 32
            radius: 10
            color: globalState.glassMode ? ga(pal.surfaceDeep, 0.6) : pal.surfaceDeep
            opacity: globalState.parallaxEnabled ? 1 : 0.45
            Text {
                anchors.centerIn: parent
                text: tr("plx_reset")
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                color: pal.colorOnSurface
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: globalState.parallaxEnabled
                onClicked: parallaxLayer.resetCurrent()
            }
        }
    }
}
