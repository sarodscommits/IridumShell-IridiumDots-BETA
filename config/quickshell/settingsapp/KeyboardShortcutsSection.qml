import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../settings"

// Keyboard shortcuts section
ESection {
    id: keyboardShortcutsSection
    title: tr("kb_sc_title")
    subtitle: tr("kb_sc_d")
    icon: "keyboard_command_key"
    headerTrailing: EIconButton {
        variant: "tonal"
        icon: "refresh"
        busy: kbBindsLoading
        onClicked: { kbRefresh(false); globalState.playUiClick(); }
    }

    Flow {
        Layout.fillWidth: true
        spacing: 8
        Repeater {
            model: [
                { i: "keyboard",     t: tr("kb_stat_hypr").arg(kbHyprBinds.length), err: false },
                { i: "open_with",    t: tr("kb_stat_inf").arg(kbInfiniteBinds.length), err: false },
                { i: kbPage.conflictCount ? "warning" : "check_circle", t: tr("kb_stat_conf").arg(kbPage.conflictCount), err: kbPage.conflictCount > 0 }
            ]
            delegate: Rectangle {
                required property var modelData
                height: 32; width: kbStatRow.implicitWidth + 24
                radius: 16
                color: modelData.err ? m3.errorContainer : m3.glassy(m3.surfaceContainerHighest, 0.6)
                Row {
                    id: kbStatRow
                    anchors.centerIn: parent; spacing: 6
                    EIcon { name: modelData.i; size: 18; color: modelData.err ? m3.inkErrorContainer : m3.primary; anchors.verticalCenter: parent.verticalCenter }
                    EText { text: modelData.t; role: "labelLarge"; color: modelData.err ? m3.inkErrorContainer : m3.inkSurfaceVariant; anchors.verticalCenter: parent.verticalCenter }
                }
            }
        }
    }

    EText {
        Layout.fillWidth: true
        visible: kbBindsError !== ""
        role: "bodyMedium"; color: m3.error
        text: tr("kb_read_error").arg(kbBindsError)
        wrapMode: Text.WordWrap
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 52
        radius: 26
        color: m3.glassy(m3.surfaceContainerHighest, 0.6)
        border.width: kbBindSearch.activeFocus ? 2 : 0
        border.color: m3.primary
        EIcon { x: 16; anchors.verticalCenter: parent.verticalCenter; name: "search"; color: m3.inkSurfaceVariant }
        TextInput {
            id: kbBindSearch
            x: 52; width: parent.width - 52 - 52
            anchors.verticalCenter: parent.verticalCenter
            color: m3.inkSurface; font.family: m3.fontBody; font.pixelSize: Math.round(15 * m3.fs)
            selectByMouse: true; clip: true
            selectionColor: m3.primary; selectedTextColor: m3.inkPrimary
            onTextChanged: kbPage.bindQuery = text
            EText {
                anchors.verticalCenter: parent.verticalCenter
                visible: parent.text === ""
                role: "bodyLarge"; color: m3.inkSurfaceVariant
                text: tr("kb_search_sc")
            }
        }
        EIconButton {
            anchors.right: parent.right; anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            visible: kbBindSearch.text !== ""
            icon: "close"
            onClicked: kbBindSearch.text = ""
        }
    }

    Flow {
        Layout.fillWidth: true
        spacing: 8
        EChip {
            text: tr("kb_cat_all")
            selected: kbPage.bindCat === "all"
            onClicked: kbPage.bindCat = "all"
        }
        Repeater {
            model: kbCategoryDefs
            delegate: EChip {
                required property var modelData
                text: modelData.key === "submap" ? tr("kb_cat_submap_short") : tr("kb_cat_" + modelData.key)
                icon: modelData.icon
                filter: false
                selected: kbPage.bindCat === modelData.key
                onClicked: kbPage.bindCat = (kbPage.bindCat === modelData.key ? "all" : modelData.key)
            }
        }
    }

    EText {
        Layout.fillWidth: true
        visible: kbPage.bindGroups.length === 0 && !kbBindsLoading
        horizontalAlignment: Text.AlignHCenter
        role: "bodyLarge"; color: m3.inkSurfaceVariant
        text: tr("kb_no_results")
    }

    Repeater {
        model: kbPage.bindGroups
        delegate: ColumnLayout {
            id: kbGroup
            required property var modelData
            Layout.fillWidth: true
            Layout.topMargin: 6
            spacing: 2
            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 8
                spacing: 10
                EIcon { name: kbGroup.modelData.icon; size: 20; color: m3.primary }
                EText {
                    Layout.fillWidth: true
                    role: "titleMedium"; emph: true
                    text: kbGroup.modelData.title
                    elide: Text.ElideRight
                }
                EText { role: "labelLarge"; color: m3.inkSurfaceVariant; text: kbGroup.modelData.items.length }
            }
            Repeater {
                model: kbGroup.modelData.items
                delegate: Rectangle {
                    id: kbBindRow
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    implicitHeight: Math.max(60, kbBindInfo.implicitHeight + 20)
                    readonly property bool first: index === 0
                    readonly property bool last: index === kbGroup.modelData.items.length - 1
                    readonly property real outerR: m3.corner(20)
                    Spring { id: kbBindH; target: kbBindMa.containsMouse ? 1 : 0; token: "effectsFast" }
                    topLeftRadius: first ? outerR : 4; topRightRadius: first ? outerR : 4
                    bottomLeftRadius: last ? outerR : 4; bottomRightRadius: last ? outerR : 4
                    color: m3.state(modelData.conflict ? m3.alpha(m3.errorContainer, 0.55) : m3.glassy(m3.surfaceContainerHigh, 0.6), m3.inkSurface, 0.05 * kbBindH.value)
                    MouseArea { id: kbBindMa; anchors.fill: parent; hoverEnabled: true }
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 14
                        spacing: 12
                        ColumnLayout {
                            id: kbBindInfo
                            Layout.fillWidth: true
                            spacing: 2
                            EText {
                                Layout.fillWidth: true
                                role: "titleSmall"
                                text: kbBindRow.modelData.label
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2; elide: Text.ElideRight
                            }
                            Row {
                                spacing: 6
                                EText {
                                    role: "bodySmall"; color: m3.inkSurfaceVariant
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: kbBindRow.modelData.src === "infinite" ? "infinite_desktop_core.py"
                                          : tr("kb_src_line").arg(kbBindRow.modelData.line)
                                }
                                Repeater {
                                    model: {
                                        var b = kbBindRow.modelData, t = [];
                                        if (b.conflict) t.push({ t: tr("kb_conflict"), err: true });
                                        if (b.repeat)   t.push({ t: tr("kb_tag_repeat"), err: false });
                                        if (b.hold)     t.push({ t: tr("kb_tag_hold"), err: false });
                                        if (b.coop)     t.push({ t: tr("kb_tag_coop"), err: false });
                                        if (b.id)       t.push({ t: "@kb:" + b.id, err: false, mono: true });
                                        return t;
                                    }
                                    delegate: Rectangle {
                                        required property var modelData
                                        height: 20; width: kbTagT.implicitWidth + 14
                                        radius: 6
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: modelData.err ? m3.error : m3.alpha(m3.secondaryContainer, 0.8)
                                        EText {
                                            id: kbTagT
                                            anchors.centerIn: parent
                                            role: "labelSmall"; emph: !modelData.mono
                                            font.family: modelData.mono ? "monospace" : m3.font
                                            text: modelData.t
                                            color: modelData.err ? m3.inkError : m3.inkSecondaryContainer
                                        }
                                    }
                                }
                            }
                        }
                        KbCombo {
                            Layout.alignment: Qt.AlignVCenter
                            keys: kbBindRow.modelData.caps
                        }
                    }
                }
            }
        }
    }
}
