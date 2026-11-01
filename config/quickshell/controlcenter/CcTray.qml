import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Control Center system tray
ColumnLayout {
    id: ncCcTray
    readonly property var info: ({
        bright: { icon: "", name: tr("nce_bright") },
        vol:    { icon: "", name: tr("nce_vol") },
        mic:    { icon: "", name: tr("nce_mic") },
        wifi:   { icon: "", name: tr("wifi") },
        bt:     { icon: "", name: tr("bluetooth") },
        dark:   { icon: "", name: tr("nce_dark") },
        dnd:    { icon: "", name: tr("dnd") },
        term:   { icon: "", name: "Terminal" },
        shot:   { icon: "", name: tr("take_screenshot") },
        rec:    { icon: "\ue061", name: tr("screen_record") },
        perf:   { icon: "\ue9e4", name: tr("nce_perf") },
        saver:  { icon: "\uefde", name: tr("nce_saver") },
        plane:  { icon: "\ue539", name: tr("nce_plane") },
        eye:    { icon: "\ue8f4", name: tr("nce_eye") }
    })
    spacing: 10

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: ncCcHintRow.implicitHeight + 24
        radius: 24
        color: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont)
        RowLayout {
            id: ncCcHintRow
            anchors.left: parent.left; anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 14; anchors.rightMargin: 14
            spacing: 10
            Rectangle {
                width: 30; height: 30; radius: 15
                color: ga(pal.primary, 0.18)
                Text { anchors.centerIn: parent; text: ""; font.family: "Material Symbols Rounded"; font.pixelSize: 17; color: pal.primary }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    Layout.fillWidth: true
                    text: tr("nce_edit_mode")
                    font.family: globalState.fontPrimary; font.pixelSize: Math.round(14 * globalState.fontScale); font.weight: Font.Bold
                    color: pal.colorOnSurface; elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: tr("nce_hint_cc") + (globalState.ncCcRows.length >= globalState.ncCcMaxRows ? "\n" + tr("nce_max_rows") : "")
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale)
                    color: pal.colorOnSurfVar
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: ncCcAddCol.implicitHeight + 24
        radius: 24
        color: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont)
        ColumnLayout {
            id: ncCcAddCol
            anchors.left: parent.left; anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 14; anchors.rightMargin: 14
            spacing: 8
            Text {
                text: tr("nce_add_ctl")
                font.family: globalState.fontPrimary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Bold
                color: pal.colorOnSurface
            }
            Text {
                visible: globalState.ncCcHidden.length === 0
                text: tr("nce_all_ctl")
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale)
                color: pal.colorOnSurfVar
            }
            Flow {
                Layout.fillWidth: true
                visible: globalState.ncCcHidden.length > 0
                spacing: 6
                Repeater {
                    model: globalState.ncCcHidden
                    Rectangle {
                        id: ncCcAddChip
                        required property string modelData
                        width: ncCcAddRow.implicitWidth + 22
                        height: 32; radius: 16
                        color: ncCcAddHov.hovered ? pal.primary : (globalState.glassMode ? ga(pal.surface, 0.5) : pal.surface)
                        Behavior on color { M3ColorAnim { duration: m3.durFast } }
                        RowLayout {
                            id: ncCcAddRow
                            anchors.centerIn: parent
                            spacing: 5
                            Text { text: ""; font.family: "Material Symbols Rounded"; font.pixelSize: 15; color: ncCcAddHov.hovered ? pal.colorOnPrimary : pal.primary }
                            FadeIcon { text: ncCcTray.info[ncCcAddChip.modelData].icon; font.family: "Material Symbols Rounded"; font.pixelSize: 15; color: ncCcAddHov.hovered ? pal.colorOnPrimary : pal.colorOnSurfVar }
                            Text { text: ncCcTray.info[ncCcAddChip.modelData].name; font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium; color: ncCcAddHov.hovered ? pal.colorOnPrimary : pal.colorOnSurface }
                        }
                        HoverHandler { id: ncCcAddHov }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: globalState.ncCcAdd(ncCcAddChip.modelData) }
                    }
                }
            }
        }
    }
    Item { Layout.fillWidth: true; Layout.fillHeight: true }
}
