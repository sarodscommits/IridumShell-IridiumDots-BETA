import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../settings"

// Cava visualizer section of the desktop editor menu
EditorSection {
    id: edmSecCava
    Layout.fillWidth: true
    icon: ""
    title: tr("desktop_cava")
    summary: !globalState.desktopCavaEnabled ? tr("radio_off")
    : (tr("edge_" + globalState.desktopCavaEdge) + " · " + tr("cava_style_" + globalState.desktopCavaStyle))
    expanded: desktopEditorPopup.openSection === "cava"
    onToggled: desktopEditorMainMenu.toggleSection("cava", edmSecCava)
    accent: desktopEditorMainMenu.cOn; accentText: desktopEditorMainMenu.cOnTxt
    textColor: desktopEditorMainMenu.cText; subColor: desktopEditorMainMenu.cSub
    cardColor: desktopEditorMainMenu.cSection; hoverColor: desktopEditorMainMenu.cSectionHov
    titleFont: globalState.fontPrimary; bodyFont: globalState.fontSecondary; fontScale: globalState.fontScale

    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Text { text: ""; font.family: "Material Symbols Rounded"; font.pixelSize: 15; color: desktopEditorMainMenu.cOn }
        Text { Layout.fillWidth: true; text: tr("radio_on"); font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium; color: desktopEditorMainMenu.cText; elide: Text.ElideRight }
        EditorToggle {
            on: globalState.desktopCavaEnabled
            activeColor: desktopEditorMainMenu.cOn; offColor: desktopEditorMainMenu.cOff
            onClicked: { globalState.desktopCavaEnabled = !globalState.desktopCavaEnabled; savePrefs(); }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 10
        opacity: globalState.desktopCavaEnabled ? 1 : 0.4
        enabled: globalState.desktopCavaEnabled
        Behavior on opacity { M3NumberAnim { duration: m3.durFast } }

        Text { text: tr("cava_edge"); font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium; color: desktopEditorMainMenu.cSub }
        SegmentedPill {
            Layout.fillWidth: true
            fontSize: Math.round(11 * globalState.fontScale)
            options: [{ value: "top", label: tr("edge_top") }, { value: "bottom", label: tr("edge_bottom") },
            { value: "left", label: tr("edge_left") }, { value: "right", label: tr("edge_right") }]
            current: globalState.desktopCavaEdge
            onPicked: (v) => { globalState.desktopCavaEdge = v; savePrefs(); }
            trackColor: desktopEditorMainMenu.cOff
            selectedColor: desktopEditorMainMenu.cOn
            textColor: desktopEditorMainMenu.cText
            selectedTextColor: desktopEditorMainMenu.cOnTxt
        }

        Text { text: tr("cava_style"); font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium; color: desktopEditorMainMenu.cSub }
        SegmentedPill {
            Layout.fillWidth: true
            options: [{ value: "bars", label: tr("cava_style_bars") }, { value: "wave", label: tr("cava_style_wave") }]
            current: globalState.desktopCavaStyle
            onPicked: (v) => { globalState.desktopCavaStyle = v; savePrefs(); }
            trackColor: desktopEditorMainMenu.cOff
            selectedColor: desktopEditorMainMenu.cOn
            textColor: desktopEditorMainMenu.cText
            selectedTextColor: desktopEditorMainMenu.cOnTxt
        }

        Repeater {
            model: [
            { key: "cava_resolution", prop: "desktopCavaResolution", min: 16, max: 160, step: 4,  unit: "" },
            { key: "cava_max_height", prop: "desktopCavaHeight",     min: 60, max: 480, step: 10, unit: " px" }
            ]
            delegate: ColumnLayout {
                id: dcSlider
                required property var modelData
                Layout.fillWidth: true
                spacing: 4
                readonly property real value: globalState[modelData.prop]
                readonly property real frac: (value - modelData.min) / (modelData.max - modelData.min)
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: tr(dcSlider.modelData.key)
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium
                        color: desktopEditorMainMenu.cSub
                        elide: Text.ElideRight
                    }
                    Text {
                        text: Math.round(dcSlider.value) + dcSlider.modelData.unit
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium
                        color: desktopEditorMainMenu.cText
                    }
                }
                FractionSlider {
                    id: dcTrack
                    Layout.fillWidth: true
                    Layout.preferredHeight: 22
                    property real displayPct: dcSlider.frac
                    value: displayPct
                    trackH: 14
                    handleHOverride: 20
                    height: 22
                    activeColor: desktopEditorMainMenu.cOn
                    inactiveColor: desktopEditorMainMenu.cOff
                    steps: Math.max(0, (9) - 1)
                    showBubble: false
                    skipEmpty: true
                    onFracMoved: (f) => { var md = dcSlider.modelData; var v = md.min + Math.round(f * (md.max - md.min) / md.step) * md.step; globalState[md.prop] = Math.max(md.min, Math.min(md.max, v)); }
                    onFracReleased: { savePrefs(); }
                }
            }
        }
    }
}
