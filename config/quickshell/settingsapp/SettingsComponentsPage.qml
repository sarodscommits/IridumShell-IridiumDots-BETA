import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Settings: components page (switches, sliders, progress)
Item {
    id: sdCompPage
    anchors.fill: parent
    visible: settingsPopup.activeSection === "components"
    property real demo: 0.62
    property int seg: 1
    property bool tA: true
    property bool tB: false
    EPage {
        anchors.fill: parent
        anchors.leftMargin: 24; anchors.rightMargin: 12; anchors.bottomMargin: 16

        ESection {
            title: tr("sd_selection")
            subtitle: tr("sd_selection_d")
            icon: ""
            headerTrailing: EButton { size: "s"; variant: "text"; icon: ""; text: tr("sd_reset"); onClicked: resetM3(["m3SwitchIcons", "m3SliderScale"]) }
            ESettingRow {
                icon: ""; label: tr("sd_switch_icons"); desc: tr("sd_switch_icons_d")
                ESwitch { checked: globalState.m3SwitchIcons; onToggled: (v) => setM3("m3SwitchIcons", v) }
            }
            ESettingRow {
                icon: ""; label: tr("sd_slider_thick"); desc: "×" + m3.sliderScale.toFixed(1)
                ESlider {
                    Layout.preferredWidth: 260
                    height: 36; trackH: 16; handleHOverride: 32
                    steps: 7
                    value: (globalState.m3SliderScale - 0.7) / 0.7
                    bubbleText: "×" + (0.7 + value * 0.7).toFixed(1)
                    onMoved: (v) => { globalState.m3SliderScale = Math.round((0.7 + v * 0.7) * 10) / 10; }
                    onReleased: savePrefs()
                }
            }
            Flow {
                Layout.fillWidth: true
                spacing: 18
                ESwitch { checked: sdCompPage.tA; onToggled: (v) => sdCompPage.tA = v }
                ESwitch { checked: sdCompPage.tB; onToggled: (v) => sdCompPage.tB = v }
                ECheck { checked: sdCompPage.tA; label: "Checkbox"; onToggled: (v) => sdCompPage.tA = v }
                ERadio { checked: sdCompPage.tB; label: "Radio"; onPicked: sdCompPage.tB = !sdCompPage.tB }
                EChip { text: tr("sd_chip"); selected: sdCompPage.tA; onClicked: sdCompPage.tA = !sdCompPage.tA }
            }
            ESlider { Layout.fillWidth: true; trackH: 16; value: sdCompPage.demo; onMoved: (v) => sdCompPage.demo = v }
            ESlider { Layout.fillWidth: true; trackH: 40; icon: ""; value: sdCompPage.demo; onMoved: (v) => sdCompPage.demo = v }
        }

        ESection {
            title: tr("sd_progress")
            subtitle: tr("sd_progress_d")
            headerTrailing: EButton { size: "s"; variant: "text"; icon: ""; text: tr("sd_reset"); onClicked: resetM3(["m3Wavy", "m3ProgressThickness"]) }
            ESettingRow {
                icon: ""; label: tr("sd_wavy"); desc: tr("sd_wavy_d")
                ESwitch { checked: globalState.m3Wavy; onToggled: (v) => setM3("m3Wavy", v) }
            }
            ESettingRow {
                icon: ""; label: tr("sd_thickness"); desc: m3.progressThickness + " px"
                ESlider {
                    Layout.preferredWidth: 260
                    height: 36; trackH: 16; handleHOverride: 32
                    steps: 6
                    value: (globalState.m3ProgressThickness - 2) / 6
                    bubbleText: Math.round(2 + value * 6) + " px"
                    onMoved: (v) => { globalState.m3ProgressThickness = Math.round(2 + v * 6); }
                    onReleased: savePrefs()
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 24
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 14
                    EWavyLinear { Layout.fillWidth: true; value: sdCompPage.demo; running: sdCompPage.visible }
                    EWavyLinear { Layout.fillWidth: true; indeterminate: true; running: sdCompPage.visible }
                    EWavyLinear { Layout.fillWidth: true; value: sdCompPage.demo; showHandle: true; running: sdCompPage.visible }
                }
                EWavyCircular { width: 64; height: 64; value: sdCompPage.demo }
                EWavyCircular { width: 64; height: 64; indeterminate: true }
                ELoading { size: 56 }
            }
        }

        ESection {
            title: tr("sd_buttons")
            subtitle: tr("sd_buttons_d")
            Flow {
                Layout.fillWidth: true
                spacing: 12
                EButton { size: "xs"; text: "XS" }
                EButton { size: "s"; text: "S"; variant: "tonal" }
                EButton { size: "m"; text: "M"; icon: "" }
                EButton { size: "s"; text: tr("sd_toggle"); toggleable: true; checked: sdCompPage.tA; onClicked: sdCompPage.tA = !sdCompPage.tA }
                EButton { size: "s"; text: tr("sd_toggle"); toggleable: true; variant: "tonal"; checked: sdCompPage.tB; onClicked: sdCompPage.tB = !sdCompPage.tB }
                EButton { size: "s"; text: "Outlined"; variant: "outlined" }
                EButton { size: "s"; text: "Elevated"; variant: "elevated" }
            }
            Flow {
                Layout.fillWidth: true
                spacing: 12
                EIconButton { icon: ""; variant: "filled" }
                EIconButton { icon: ""; variant: "tonal" }
                EIconButton { icon: ""; variant: "outlined" }
                EIconButton { icon: ""; variant: "tonal"; widthMode: "wide" }
                EIconButton { icon: ""; toggleable: true; checked: sdCompPage.tA; onClicked: sdCompPage.tA = !sdCompPage.tA }
                ESegmented { size: "s"; options: [["", tr("light")], ["", tr("dark")], ["", "Auto"]]; current: sdCompPage.seg; onPicked: (v) => sdCompPage.seg = v }
                EFab { icon: ""; text: tr("sd_fab"); tone: "tertiary" }
                EFab { icon: "" }
            }
        }
    }
}
