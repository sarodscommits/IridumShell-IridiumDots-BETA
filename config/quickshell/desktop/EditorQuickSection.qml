import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../settings"

// Quick-settings section of the desktop editor menu
EditorSection {
    id: edmSecQuick
    Layout.fillWidth: true
    icon: ""
    title: tr("quick_settings")
    summary: (globalState.paletteSource === "preset" ? tr("palette_source_preset") : tr("palette_source_matugen")) +
    (globalState.glassMode ? " · " + tr("glass_mode") : "") + " · " +
    (globalState.fontResolved[globalState.fontPrimaryKey] ? globalState.fontResolved[globalState.fontPrimaryKey].family : "")
    expanded: desktopEditorPopup.openSection === "quick"
    onToggled: desktopEditorMainMenu.toggleSection("quick", edmSecQuick)
    accent: desktopEditorMainMenu.cOn; accentText: desktopEditorMainMenu.cOnTxt
    textColor: desktopEditorMainMenu.cText; subColor: desktopEditorMainMenu.cSub
    cardColor: desktopEditorMainMenu.cSection; hoverColor: desktopEditorMainMenu.cSectionHov
    titleFont: globalState.fontPrimary; bodyFont: globalState.fontSecondary; fontScale: globalState.fontScale

    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Text { text: ""; font.family: "Material Symbols Rounded"; font.pixelSize: 15; color: desktopEditorMainMenu.cOn }
        Text { Layout.fillWidth: true; text: tr("glass_mode"); font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium; color: desktopEditorMainMenu.cText; elide: Text.ElideRight }
        EditorToggle {
            on: globalState.glassMode
            activeColor: desktopEditorMainMenu.cOn; offColor: desktopEditorMainMenu.cOff
            onClicked: setGlassMode(!globalState.glassMode)
        }
    }
    ColumnLayout {
        id: edmGlassOpRow
        Layout.fillWidth: true
        spacing: 4
        readonly property bool live: globalState.glassMode && globalState.glassQuickshellEnabled
        enabled: live
        opacity: live ? 1 : 0.4
        Behavior on opacity { M3NumberAnim { duration: m3.durFast } }
        RowLayout {
            Layout.fillWidth: true
            Text { Layout.fillWidth: true; text: tr("glass_opacity"); font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium; color: desktopEditorMainMenu.cSub; elide: Text.ElideRight }
            Text { text: Math.round(globalState.glassQuickshellOpacity * 100) + " %"; font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium; color: desktopEditorMainMenu.cText }
        }
        ESlider {
            id: edmGlassOpTrack
            Layout.fillWidth: true
            Layout.preferredHeight: 22
            value: (globalState.glassQuickshellOpacity - 0.35) / 0.40
            trackH: 14
            handleHOverride: 20
            height: 22
            activeColor: desktopEditorMainMenu.cOn
            inactiveColor: desktopEditorMainMenu.cOff
            steps: 8
            showBubble: false
            function setF(f) { setGlassQuickshellOpacity(0.35 + Math.round(f * 0.40 / 0.05) * 0.05); }
            onPressedAt: (v) => setF(v)
            onDragged: (v) => { if (pressed) setF(v); }
            onReleasedAt: (v) => setF(v)
        }
    }

    Rectangle { Layout.fillWidth: true; Layout.topMargin: 2; height: 1; color: ga(desktopEditorMainMenu.cSub, 0.15) }

    Text { text: tr("palette_source"); font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium; color: desktopEditorMainMenu.cSub }
    SegmentedPill {
        Layout.fillWidth: true
        fontSize: Math.round(11 * globalState.fontScale)
        options: [{ value: "matugen", label: tr("settings_section_wallpaper") }, { value: "preset", label: tr("palette_source_preset") }]
        current: globalState.paletteSource
        onPicked: (v) => setPaletteSource(v)
        trackColor: desktopEditorMainMenu.cOff
        selectedColor: desktopEditorMainMenu.cOn
        textColor: desktopEditorMainMenu.cText
        selectedTextColor: desktopEditorMainMenu.cOnTxt
    }
    ColumnLayout {
        Layout.fillWidth: true
        visible: globalState.paletteSource === "preset"
        spacing: 10
        Flow {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: globalState.presetPalettes
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool sel: globalState.presetPaletteKey === modelData.key
                    width: 26; height: 26; radius: 13
                    color: Qt.hsla((((modelData.hue % 360) + 360) % 360) / 360, modelData.sat, 0.55, 1)
                    border.width: sel ? 2 : 1
                    border.color: sel ? desktopEditorMainMenu.cOn : ga(desktopEditorMainMenu.cText, 0.25)
                    Text {
                        visible: parent.sel
                        anchors.centerIn: parent
                        text: ""
                        font.family: "Material Symbols Rounded"; font.pixelSize: 14
                        color: modelData.sat < 0.15 ? "#000000" : "#FFFFFF"
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: setPresetPalette(modelData.key) }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text { text: "\ue30a"; font.family: "Material Symbols Rounded"; font.pixelSize: 15; color: desktopEditorMainMenu.cOn }
            Text { Layout.fillWidth: true; text: tr("preset_apply_quickshell"); font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium; color: desktopEditorMainMenu.cText; elide: Text.ElideRight }
            EditorToggle {
                on: globalState.presetApplyQuickshell
                activeColor: desktopEditorMainMenu.cOn; offColor: desktopEditorMainMenu.cOff
                onClicked: setPresetApplyQuickshell(!globalState.presetApplyQuickshell)
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text { text: "\ueb8e"; font.family: "Material Symbols Rounded"; font.pixelSize: 15; color: desktopEditorMainMenu.cOn }
            Text { Layout.fillWidth: true; text: tr("preset_apply_kitty"); font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium; color: desktopEditorMainMenu.cText; elide: Text.ElideRight }
            EditorToggle {
                on: globalState.presetApplyKitty
                activeColor: desktopEditorMainMenu.cOn; offColor: desktopEditorMainMenu.cOff
                onClicked: setPresetApplyKitty(!globalState.presetApplyKitty)
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            readonly property bool presetOwnsKitty: globalState.presetApplyKitty
            enabled: !presetOwnsKitty
            opacity: presetOwnsKitty ? 0.4 : 1
            Behavior on opacity { M3NumberAnim { duration: m3.durFast } }
            Text { text: tr("term_palette"); font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium; color: desktopEditorMainMenu.cSub }
            SegmentedPill {
                Layout.fillWidth: true
                segHeight: 26
                fontSize: Math.round(11 * globalState.fontScale)
                options: [{ value: "pywal",      label: tr("term_palette_pywal") },
                { value: "matugen",    label: tr("term_palette_matugen") },
                { value: "matugen_bg", label: tr("term_palette_bg") }]
                current: globalState.termPaletteMode
                onPicked: (v) => setTermPaletteMode(v)
                trackColor: desktopEditorMainMenu.cOff
                selectedColor: desktopEditorMainMenu.cOn
                textColor: desktopEditorMainMenu.cText
                selectedTextColor: desktopEditorMainMenu.cOnTxt
            }
            Text {
                Layout.fillWidth: true
                visible: parent.presetOwnsKitty
                wrapMode: Text.WordWrap
                text: tr("term_palette_preset_note")
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale)
                color: desktopEditorMainMenu.cMuted
            }
        }
    }

    Rectangle { Layout.fillWidth: true; Layout.topMargin: 2; height: 1; color: ga(desktopEditorMainMenu.cSub, 0.15) }

    Repeater {
        model: [
        { which: "primary",   label: tr("font_primary") },
        { which: "secondary", label: tr("font_secondary") }
        ]
        delegate: ColumnLayout {
            id: edmFontCol
            required property var modelData
            Layout.fillWidth: true
            spacing: 6
            Text { text: edmFontCol.modelData.label; font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium; color: desktopEditorMainMenu.cSub }
            SegmentedPill {
                Layout.fillWidth: true
                columns: 2
                segHeight: 28
                fontSize: Math.round(12 * globalState.fontScale)
                options: globalState.fontCatalog.map(function(f) {
                    var r = globalState.fontResolved[f.key];
                    return { value: f.key, label: f.label, font: r.family, enabled: r.available };
                })
                current: edmFontCol.modelData.which === "primary" ? globalState.fontPrimaryKey : globalState.fontSecondaryKey
                onPicked: (v) => setFont(edmFontCol.modelData.which, v)
                trackColor: desktopEditorMainMenu.cOff
                selectedColor: desktopEditorMainMenu.cOn
                textColor: desktopEditorMainMenu.cText
                selectedTextColor: desktopEditorMainMenu.cOnTxt
            }
        }
    }
}
