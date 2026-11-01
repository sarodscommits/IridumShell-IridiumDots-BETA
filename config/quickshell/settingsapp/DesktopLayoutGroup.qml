import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../settings"

// Canvas layout settings group
SettingsGroup {
    id: desktopLayoutGroup
    Layout.fillWidth: true
    title: tr("inf_group_layout")
    icon: "\ue9b0"
    titleSize: 12; bodySpacing: 12
    expanded: globalState.settingsExpanded["inf_group_layout"] === true
    onToggled: globalState.toggleSettingsGroup("inf_group_layout")
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
                text: "\ue871"
                font.family: "Material Symbols Rounded"; font.pixelSize: 16
                color: pal.primary
            }
            Text {
                text: tr("tiling_layout")
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                color: pal.colorOnSurfVar
                Layout.fillWidth: true
            }
        }
        SegmentedPill {
            Layout.fillWidth: true
            segHeight: 28
            fontSize: Math.round(11 * globalState.fontScale)
            options: [{ value: "dwindle", label: tr("layout_dwindle") }, { value: "master", label: tr("layout_master") }]
            current: globalState.layoutMode
            onPicked: (v) => setLayoutMode(v)
            trackColor: m3.glassy(m3.surfaceContainerHighest, 0.6)
            selectedColor: pal.primary
            textColor: pal.colorOnSurfVar
            selectedTextColor: pal.colorOnPrimary
            iconColor: pal.primary
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        Text {
            text: "\uf72e"
            font.family: "Material Symbols Rounded"; font.pixelSize: 16
            color: pal.primary
        }
        Text {
            text: tr("all_floating")
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
            color: pal.colorOnSurfVar
            Layout.fillWidth: true
        }
        ESwitch {
            checked: globalState.allFloating
            onToggled: setAllFloating(!globalState.allFloating)
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Text {
                text: "\ue8d4"
                font.family: "Material Symbols Rounded"; font.pixelSize: 16
                color: pal.primary
            }
            Text {
                text: tr("canvas_pan_dir")
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                color: pal.colorOnSurfVar
                Layout.fillWidth: true
            }
        }
        SegmentedPill {
            Layout.fillWidth: true
            segHeight: 28
            fontSize: Math.round(11 * globalState.fontScale)
            options: [{ value: false, label: tr("canvas_pan_normal") }, { value: true, label: tr("canvas_pan_inverse") }]
            current: globalState.canvasInvertPan
            onPicked: (v) => setCanvasInvertPan(v)
            trackColor: m3.glassy(m3.surfaceContainerHighest, 0.6)
            selectedColor: pal.primary
            textColor: pal.colorOnSurfVar
            selectedTextColor: pal.colorOnPrimary
            iconColor: pal.primary
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Text {
                text: "\ue9e4"
                font.family: "Material Symbols Rounded"; font.pixelSize: 16
                color: pal.primary
            }
            Text {
                text: tr("canvas_inertia")
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                color: pal.colorOnSurfVar
                Layout.fillWidth: true
            }
            ESwitch {
                checked: globalState.canvasInertia
                onToggled: setCanvasInertia(!globalState.canvasInertia)
            }
        }
        Text {
            Layout.fillWidth: true
            text: tr("canvas_inertia_note")
            wrapMode: Text.WordWrap
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale)
            color: pal.muted
        }
        Repeater {
            model: [
            { prop: "canvasInertiaTime",    label: "canvas_inertia_time", icon: "\ue425", min: 0.3, max: 2.0, step: 0.1,  fmt: "s" },
            { prop: "canvasInertiaMaxDist", label: "canvas_inertia_dist", icon: "\ue915", min: 0.2, max: 1.0, step: 0.05, fmt: "%" }
            ]
            delegate: ColumnLayout {
                id: inrSliderRow
                required property var modelData
                Layout.fillWidth: true
                spacing: 6
                opacity: globalState.canvasInertia ? 1 : 0.45
                Behavior on opacity { M3NumberAnim {} }
                readonly property real val: globalState[modelData.prop]
                readonly property real span: modelData.max - modelData.min

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Text {
                        text: inrSliderRow.modelData.icon
                        font.family: "Material Symbols Rounded"; font.pixelSize: 16
                        color: pal.primary
                    }
                    Text {
                        text: tr(inrSliderRow.modelData.label)
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                        color: pal.colorOnSurfVar
                        Layout.fillWidth: true
                    }
                    Text {
                        text: inrSliderRow.modelData.fmt === "s"
                        ? inrSliderRow.val.toFixed(1) + " s"
                        : Math.round(inrSliderRow.val * 100) + "%"
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale)
                        color: pal.muted
                    }
                }
                FractionSlider {
                    id: inrTrack
                    Layout.fillWidth: true
                    property real displayPct: (inrSliderRow.val - inrSliderRow.modelData.min) / inrSliderRow.span
                    value: displayPct
                    trackH: 14
                    handleHOverride: 20
                    height: 22
                    activeColor: pal.toggleOn
                    inactiveColor: globalState.glassMode ? ga(pal.surfaceDeep, 0.6) : pal.surfaceDeep
                    showBubble: false
                    enabled: globalState.canvasInertia
                    onFracMoved: (frac) => { var raw = inrSliderRow.modelData.min + frac * inrSliderRow.span; var st = inrSliderRow.modelData.step; setCanvasInertiaValue(inrSliderRow.modelData.prop, Math.round(raw / st) * st); }
                    onFracReleased: { savePrefs(); syncCanvasInertiaFile(); }
                }
            }
        }
    }
}
