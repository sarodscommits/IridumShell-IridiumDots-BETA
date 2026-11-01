import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Settings navigation rail
Item {
    id: settingsSidebar
    Spring { id: setRailW; target: settingsPopup.railExpanded ? 236 : 96; token: "spatialDefault"; eps: 0.1 }
    width: setRailW.value
    height: parent.height
    readonly property real e: Math.max(0, Math.min(1, (setRailW.value - 96) / 140))
    readonly property int activeIndex: {
        for (var i = 0; i < settingsPopup.sections.length; i++) {
            if (settingsPopup.sections[i].id === settingsPopup.activeSection) return i;
        }
        return 0;
    }
    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: setRailCol.implicitHeight + 40
        boundsBehavior: Flickable.StopAtBounds
        clip: true
    Column {
        id: setRailCol
        y: 20
        width: parent.width
        spacing: 2
        Item {
            width: parent.width; height: 52
            EIconButton {
                x: 28
                anchors.verticalCenter: parent.verticalCenter
                icon: settingsPopup.railExpanded ? "\ue5cb" : "\ue5cc"
                onClicked: settingsPopup.railExpanded = !settingsPopup.railExpanded
            }
        }
        Repeater {
            model: settingsPopup.sections
            delegate: Item {
                id: railItem
                required property var modelData
                required property int index
                width: settingsSidebar.width
                readonly property string groupLbl: railItem.modelData.gap ? settingsPopup.groupTitle(railItem.modelData.group || "") : ""
                readonly property real gapH: railItem.modelData.gap ? (13 + (groupLbl !== "" ? 22 * settingsSidebar.e : 0)) : 0
                height: 48 + 8 * settingsSidebar.e + gapH
                readonly property bool sel: settingsSidebar.activeIndex === index
                Spring { id: railInd; target: railItem.sel ? 1 : 0; token: "spatialFast"; eps: 0.002 }
                Spring { id: railHov; target: railMa.containsMouse ? 1 : 0; token: "effectsFast" }
                Rectangle {
                    visible: railItem.gapH > 0
                    opacity: railItem.groupLbl !== "" ? 1 - settingsSidebar.e : 1
                    x: (parent.width - 40) / 2; y: 4; width: 40; height: 1
                    color: m3.outlineVariant
                }
                EText {
                    visible: railItem.groupLbl !== "" && settingsSidebar.e > 0.01
                    opacity: settingsSidebar.e
                    x: 32; y: 10; width: parent.width - 48
                    text: railItem.groupLbl.toUpperCase()
                    role: "labelSmall"; emph: true
                    color: m3.primary
                    font.letterSpacing: 1.0
                    elide: Text.ElideRight
                }
                Item {
                    anchors.fill: parent
                    anchors.topMargin: railItem.gapH
                    opacity: 1 - settingsSidebar.e
                    visible: opacity > 0.01
                    Rectangle { x: (parent.width - 56) / 2; y: (parent.height - 32) / 2; width: 56; height: 32; radius: 16; color: m3.inkSurface; opacity: 0.08 * railHov.value }
                    Rectangle {
                        width: 56 * Math.max(0, railInd.value); height: 32; radius: 16
                        x: (parent.width - width) / 2; y: (parent.height - 32) / 2
                        color: m3.secondaryContainer; visible: railInd.value > 0.01
                    }
                    EIcon { x: (parent.width - 24) / 2; y: (parent.height - 24) / 2; name: railItem.modelData.icon; filled: railItem.sel; color: railItem.sel ? m3.inkSecondaryContainer : m3.inkSurfaceVariant }
                }
                Item {
                    anchors.fill: parent
                    anchors.topMargin: railItem.gapH
                    opacity: settingsSidebar.e
                    visible: opacity > 0.01
                    Rectangle { x: 16; y: (parent.height - 56) / 2; width: parent.width - 32; height: 56; radius: 28; color: m3.inkSurface; opacity: 0.08 * railHov.value }
                    Rectangle {
                        x: 16; y: (parent.height - 56) / 2
                        width: (parent.width - 32) * Math.max(0, railInd.value); height: 56; radius: 28
                        color: m3.secondaryContainer; visible: railInd.value > 0.01
                    }
                    Row {
                        x: 32; spacing: 12; anchors.verticalCenter: parent.verticalCenter
                        EIcon { name: railItem.modelData.icon; filled: railItem.sel; color: railItem.sel ? m3.inkSecondaryContainer : m3.inkSurfaceVariant }
                        EText { text: railItem.modelData.label; role: "labelLarge"; emph: railItem.sel; color: railItem.sel ? m3.inkSecondaryContainer : m3.inkSurfaceVariant; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
                MouseArea {
                    id: railMa
                    anchors.fill: parent; anchors.topMargin: railItem.gapH; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { settingsWindow.setSection(railItem.modelData.id); globalState.playUiClick(); }
                }
            }
        }
    }
    }
}
