import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../settings"

// Settings: keyboard layouts and shortcuts page
Item {
    id: kbPage
    anchors.fill: parent
    visible: settingsPopup.activeSection === "keyboard"

    property string selLayout: ""
    property string selVariant: ""
    property string layoutQuery: ""
    property string bindQuery: ""
    property string bindCat: "all"
    readonly property string shownLayout: selLayout !== "" ? selLayout : kbCurLayout
    readonly property var shownLayoutObj: { kbLayouts; return kbFindLayout(shownLayout); }
    readonly property bool pending: selLayout !== "" && (selLayout !== kbCurLayout || selVariant !== kbCurVariant)
    readonly property var filteredLayouts: {
        var q = layoutQuery.trim().toLowerCase();
        if (q === "") return kbLayouts;
        return kbLayouts.filter(function (L) {
            if (L.n.toLowerCase().indexOf(q) >= 0 || L.d.toLowerCase().indexOf(q) >= 0) return true;
            for (var i = 0; i < L.l.length; i++) if (L.l[i].toLowerCase() === q) return true;
            for (var j = 0; j < L.v.length; j++) if (L.v[j].d.toLowerCase().indexOf(q) >= 0) return true;
            return false;
        });
    }
    readonly property var allBinds: { kbHyprBinds; globalState.language; return kbAllBinds(); }
    readonly property var bindGroups: kbBuildGroups(allBinds, bindQuery, bindCat)
    readonly property int conflictCount: allBinds.filter(function (b) { return b.conflict; }).length

    function resetSelection() { selLayout = ""; selVariant = ""; }
    onVisibleChanged: if (visible) { kbRefresh(true); resetSelection(); }
    Connections {
        target: globalState
        function onSettingsOpenChanged() { if (settingsWindow.winOpen) kbRefresh(false); }
    }
    Component.onCompleted: kbRefresh(false)

    EPage {
        anchors.fill: parent
        anchors.leftMargin: 24; anchors.rightMargin: 12; anchors.bottomMargin: 16

        ESection {
            title: tr("kb_layout_title")
            subtitle: tr("kb_layout_d")
            icon: "keyboard"

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: kbHeroRow.implicitHeight + 40
                radius: m3.corner(28)
                color: kbPage.pending ? m3.tertiaryContainer : m3.primaryContainer
                Behavior on color { ColorAnimation { duration: m3.durDefault } }
                clip: true
                AutoShape {
                    width: 220; height: 220
                    x: parent.width - 150; y: -60
                    fill: m3.alpha(kbPage.pending ? m3.tertiary : m3.primary, 0.22)
                    interval: 2600; spinStep: 40
                    running: kbPage.visible
                }
                RowLayout {
                    id: kbHeroRow
                    x: 20; y: 20
                    width: parent.width - 40
                    spacing: 18
                    Item {
                        Layout.preferredWidth: 84; Layout.preferredHeight: 84
                        Layout.alignment: Qt.AlignTop
                        MShape {
                            anchors.fill: parent; inset: 1.0
                            from: m3.accentShape; to: m3.accentShape
                            fill: kbPage.pending ? m3.tertiary : m3.primary
                        }
                        EText {
                            anchors.centerIn: parent
                            width: parent.width - 16
                            horizontalAlignment: Text.AlignHCenter
                            fontSizeMode: Text.HorizontalFit
                            minimumPixelSize: 12
                            role: "headlineSmall"; emph: true
                            text: (kbPage.shownLayout || "··").toUpperCase()
                            color: kbPage.pending ? m3.inkTertiary : m3.inkPrimary
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        readonly property color ink: kbPage.pending ? m3.inkTertiaryContainer : m3.inkPrimaryContainer
                        EText {
                            role: "labelLarge"; emph: true
                            text: (kbPage.pending ? tr("kb_pending_label") : tr("kb_current")).toUpperCase()
                            color: parent.ink; font.letterSpacing: 1.2
                        }
                        EText {
                            Layout.fillWidth: true
                            role: "headlineSmall"; emph: true
                            text: kbLayoutDesc(kbPage.shownLayout)
                            color: parent.ink
                            wrapMode: Text.WordWrap
                        }
                        EText {
                            Layout.fillWidth: true
                            role: "bodyLarge"
                            text: kbVariantDesc(kbPage.shownLayout, kbPage.selLayout !== "" ? kbPage.selVariant : kbCurVariant)
                            color: parent.ink; opacity: 0.85
                            wrapMode: Text.WordWrap
                        }
                        EText {
                            Layout.fillWidth: true
                            visible: !kbPage.pending && kbActiveKeymap !== ""
                            role: "bodySmall"
                            text: tr("kb_hypr_keymap").arg(kbActiveKeymap)
                            color: parent.ink; opacity: 0.7
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: kbPage.pending
                spacing: 12
                EText {
                    Layout.fillWidth: true
                    role: "bodyMedium"; color: m3.inkSurfaceVariant
                    text: tr("kb_pending_d")
                    wrapMode: Text.WordWrap
                }
                EButton {
                    size: "s"; variant: "text"
                    text: tr("kb_discard")
                    onClicked: kbPage.resetSelection()
                }
                EButton {
                    size: "s"; variant: "filled"
                    icon: "check"
                    text: tr("kb_apply")
                    busy: kbApplying
                    onClicked: {
                        kbApplyLayout(kbPage.selLayout, kbPage.selVariant);
                        kbPage.resetSelection();
                        globalState.playUiClick();
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 52
                radius: 26
                color: m3.glassy(m3.surfaceContainerHighest, 0.6)
                border.width: kbLayoutSearch.activeFocus ? 2 : 0
                border.color: m3.primary
                EIcon { x: 16; anchors.verticalCenter: parent.verticalCenter; name: "search"; color: m3.inkSurfaceVariant }
                TextInput {
                    id: kbLayoutSearch
                    x: 52; width: parent.width - 52 - 52
                    anchors.verticalCenter: parent.verticalCenter
                    color: m3.inkSurface; font.family: m3.fontBody; font.pixelSize: Math.round(15 * m3.fs)
                    selectByMouse: true; clip: true
                    selectionColor: m3.primary; selectedTextColor: m3.inkPrimary
                    onTextChanged: kbPage.layoutQuery = text
                    EText {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: parent.text === ""
                        role: "bodyLarge"; color: m3.inkSurfaceVariant
                        text: tr("kb_search_layout")
                    }
                }
                EIconButton {
                    anchors.right: parent.right; anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    visible: kbLayoutSearch.text !== ""
                    icon: "close"
                    onClicked: kbLayoutSearch.text = ""
                }
            }

            KeyboardLayoutList { id: keyboardLayoutList }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10
                visible: kbPage.shownLayoutObj !== null
                EText {
                    Layout.fillWidth: true
                    role: "titleSmall"; emph: true
                    text: tr("kb_variants").arg(kbPage.shownLayoutObj ? kbPage.shownLayoutObj.d : "")
                    elide: Text.ElideRight
                }
                Flow {
                    Layout.fillWidth: true
                    spacing: 8
                    Repeater {
                        model: kbPage.shownLayoutObj ? [{ n: "", d: "" }].concat(kbPage.shownLayoutObj.v) : []
                        delegate: EChip {
                            required property var modelData
                            readonly property string effVariant: kbPage.selLayout !== "" ? kbPage.selVariant : kbCurVariant
                            text: modelData.n === "" ? tr("kb_variant_default") : kbShortVariant(kbPage.shownLayoutObj.d, modelData.d)
                            selected: modelData.n === effVariant
                            onClicked: {
                                var L = kbPage.shownLayout, V = modelData.n;
                                if (L === kbCurLayout && V === kbCurVariant) kbPage.resetSelection();
                                else { kbPage.selLayout = L; kbPage.selVariant = V; }
                                globalState.playUiClick();
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 56
                color: m3.glassy(m3.surfaceContainerHighest, 0.6)
                topLeftRadius: 4; topRightRadius: 4
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: kbTestInput.activeFocus ? 2 : 1; color: kbTestInput.activeFocus ? m3.primary : m3.inkSurfaceVariant }
                EText { x: 16; y: 7; role: "bodySmall"; text: tr("kb_test"); color: kbTestInput.activeFocus ? m3.primary : m3.inkSurfaceVariant }
                TextInput {
                    id: kbTestInput
                    x: 16; y: 26; width: parent.width - 32
                    color: m3.inkSurface; font.family: m3.fontBody; font.pixelSize: Math.round(16 * m3.fs)
                    selectByMouse: true; clip: true
                    selectionColor: m3.primary; selectedTextColor: m3.inkPrimary
                    EText {
                        visible: parent.text === "" && !parent.activeFocus
                        role: "bodyLarge"; color: m3.inkSurfaceVariant; opacity: 0.7
                        text: tr("kb_test_ph")
                    }
                }
            }
        }

        KeyboardShortcutsSection { id: keyboardShortcutsSection }
    }
}
