import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../settings"

// Widget picker section of the desktop editor menu
EditorSection {
    id: edmSecWidgets
    Layout.fillWidth: true
    icon: ""
    title: tr("desktop_editor_widgets_title")
    summary: {
        var l = desktopEditorPopup.widgetList, n = 0;
        for (var i = 0; i < l.length; i++) if (globalState[l[i].enabledProp]) n++;
        return n + " / " + l.length + " " + tr("desktop_editor_active");
    }
    expanded: desktopEditorPopup.openSection === "widgets"
    onToggled: desktopEditorMainMenu.toggleSection("widgets", edmSecWidgets)
    accent: desktopEditorMainMenu.cOn; accentText: desktopEditorMainMenu.cOnTxt
    textColor: desktopEditorMainMenu.cText; subColor: desktopEditorMainMenu.cSub
    cardColor: desktopEditorMainMenu.cSection; hoverColor: desktopEditorMainMenu.cSectionHov
    titleFont: globalState.fontPrimary; bodyFont: globalState.fontSecondary; fontScale: globalState.fontScale

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        rowSpacing: 6; columnSpacing: 6
        Repeater {
            model: desktopEditorPopup.widgetList
            delegate: EditorChip {
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredWidth: 100
                on: globalState[modelData.enabledProp]
                icon: desktopEditorMainMenu.widgetIcons[modelData.enabledProp] || ""
                label: desktopWidgetMenu.titleFor(modelData.type)
                accent: desktopEditorMainMenu.cOn
                textColor: desktopEditorMainMenu.cText
                offColor: desktopEditorMainMenu.cOff
                fontFamily: globalState.fontSecondary
                fontScale: globalState.fontScale
                onClicked: {
                    var ep = modelData.enabledProp;
                    globalState[ep] = !globalState[ep];
                    if (globalState[ep]) {
                        var L = desktopWidgetLayer, gws = L.gridWidgets;
                        for (var gi = 0; gi < gws.length; gi++) {
                            if (gws[gi].enabledProp !== ep) continue;
                            var it = gws[gi].item, r = L.gridTargetFor(it);
                            var off = it.x + it.width > L.width || it.y + it.height > L.height;
                            if (off || L.overlappingWidgets(r, it).length > 0) {
                                var fc = L.nearestFreeCell(L.gridSpanFor(it), r.col, r.row, it);
                                globalState[gws[gi].xProp] = fc.col * L.gridCell;
                                globalState[gws[gi].yProp] = fc.row * L.gridCell;
                            }
                            break;
                        }
                    }
                    savePrefs();
                }
            }
        }
    }
}
