import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../settings"

// Bar section of the desktop editor menu
EditorSection {
    id: edmSecBar
    Layout.fillWidth: true
    icon: ""
    title: tr("desktop_editor_bar_settings")
    summary: {
        var n = 0, l = desktopEditorMainMenu.barModuleList;
        for (var i = 0; i < l.length; i++) if (globalState.barModules[l[i].key]) n++;
        return (globalState.shellMode === "island" ? tr("shell_mode_island") : tr("shell_mode_notch")) + " · " +
        tr("edge_" + globalState.topBarPosition) + " · " +
        n + "/" + l.length;
    }
    expanded: desktopEditorPopup.openSection === "bar"
    onToggled: desktopEditorMainMenu.toggleSection("bar", edmSecBar)
    accent: desktopEditorMainMenu.cOn; accentText: desktopEditorMainMenu.cOnTxt
    textColor: desktopEditorMainMenu.cText; subColor: desktopEditorMainMenu.cSub
    cardColor: desktopEditorMainMenu.cSection; hoverColor: desktopEditorMainMenu.cSectionHov
    titleFont: globalState.fontPrimary; bodyFont: globalState.fontSecondary; fontScale: globalState.fontScale

    Text { text: tr("shell_mode"); font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium; color: desktopEditorMainMenu.cSub }
    SegmentedPill {
        Layout.fillWidth: true
        segHeight: 28
        fontSize: Math.round(11 * globalState.fontScale)
        options: [{ value: "island", label: tr("shell_mode_island") }, { value: "notch", label: tr("shell_mode_notch") }]
        current: globalState.shellMode
        onPicked: (v) => setShellMode(v)
        trackColor: desktopEditorMainMenu.cOff
        selectedColor: desktopEditorMainMenu.cOn
        textColor: desktopEditorMainMenu.cText
        selectedTextColor: desktopEditorMainMenu.cOnTxt
    }

    Text { text: tr("bar_position"); font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium; color: desktopEditorMainMenu.cSub }
    SegmentedPill {
        Layout.fillWidth: true
        segHeight: 28
        fontSize: Math.round(11 * globalState.fontScale)
        options: [{ value: "top", label: tr("edge_top") }, { value: "bottom", label: tr("edge_bottom") },
        { value: "left", label: tr("edge_left") }, { value: "right", label: tr("edge_right") }]
        current: globalState.topBarPosition
        onPicked: (v) => setTopBarPosition(v)
        trackColor: desktopEditorMainMenu.cOff
        selectedColor: desktopEditorMainMenu.cOn
        textColor: desktopEditorMainMenu.cText
        selectedTextColor: desktopEditorMainMenu.cOnTxt
    }

    RowLayout {
        Layout.fillWidth: true
        visible: globalState.shellMode === "island"
        spacing: 8
        Text { text: ""; font.family: "Material Symbols Rounded"; font.pixelSize: 15; color: desktopEditorMainMenu.cOn }
        Text { Layout.fillWidth: true; text: tr("island_auto_hide"); font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium; color: desktopEditorMainMenu.cText; elide: Text.ElideRight }
        EditorToggle {
            on: globalState.islandAutoHide
            activeColor: desktopEditorMainMenu.cOn; offColor: desktopEditorMainMenu.cOff
            onClicked: globalState.setIslandAutoHide(!globalState.islandAutoHide)
        }
    }

    Rectangle { Layout.fillWidth: true; Layout.topMargin: 2; height: 1; color: ga(desktopEditorMainMenu.cSub, 0.15) }

    Text { text: tr("bar_modules"); font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium; color: desktopEditorMainMenu.cSub }
    Text {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: globalState.shellMode === "island" ? tr("bar_reorder_hint_island") : tr("bar_reorder_hint_notch")
        font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale)
        color: desktopEditorMainMenu.cMuted
    }
    GridLayout {
        Layout.fillWidth: true
        columns: 2
        rowSpacing: 6; columnSpacing: 6
        Repeater {
            model: desktopEditorMainMenu.barModuleList
            delegate: EditorChip {
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredWidth: 100
                on: globalState.barModules[modelData.key]
                icon: modelData.icon
                label: modelData.label
                accent: desktopEditorMainMenu.cOn
                textColor: desktopEditorMainMenu.cText
                offColor: desktopEditorMainMenu.cOff
                fontFamily: globalState.fontSecondary
                fontScale: globalState.fontScale
                onClicked: setBarModuleVisible(modelData.key, !globalState.barModules[modelData.key])
            }
        }
    }
}
