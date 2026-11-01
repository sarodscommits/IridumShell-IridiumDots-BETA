import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// System-info (fetch) card of the left panel
Item {
    id: fetchWidgetItem
    visible: !calPanel.anyWidgetExpanded || fetchWidgetItem.fetchExpanded
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.preferredHeight: 250

    property bool fetchWidgetHovered: false
    property bool fetchPeek:     false
    property bool fetchExpanded: false

    HoverHandler {
        id: fetchWidgetHover
        onHoveredChanged: fetchWidgetItem.fetchWidgetHovered = hovered
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            clockWidgetItem.clockPeek = false;
            clockWidgetItem.clockExpanded = false;
            weatherCard.weatherPeek = false;
            weatherCard.weatherExpanded = false;
            calWidgetItem.calPeek = false;
            calWidgetItem.calExpanded = false;
            calWidgetItem.selectedDay = -1;
            if (!fetchWidgetItem.fetchPeek && !fetchWidgetItem.fetchExpanded) {
                fetchWidgetItem.fetchPeek = true;
            } else if (fetchWidgetItem.fetchPeek && !fetchWidgetItem.fetchExpanded) {
                fetchWidgetItem.fetchExpanded = true;
            }
        }
    }

    Connections {
        target: globalState
        function onCalendarMenuOpenChanged() {
            if (!globalState.calendarMenuOpen) {
                fetchWidgetItem.fetchExpanded = false;
                fetchWidgetItem.fetchPeek = false;
            }
        }
        function onLeftPanelPageChanged() {
            if (globalState.leftPanelPage !== 0) {
                fetchWidgetItem.fetchExpanded = false;
                fetchWidgetItem.fetchPeek = false;
            }
        }
    }

    MorphShapeCanvas { id: fetchShapeCanvas; host: fetchWidgetItem; peek: fetchWidgetItem.fetchPeek; expanded: fetchWidgetItem.fetchExpanded; shape: "trapezoid" }

    Column {
        id: fetchWidgetIdleCol
        anchors.centerIn: fetchShapeCanvas
        spacing: 4
        opacity: (fetchWidgetItem.fetchPeek || fetchWidgetItem.fetchExpanded) ? 0 : 1
        visible: opacity > 0.01
        Behavior on opacity { M3NumberAnim {} }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: distroIconGlyph(globalState.fetchOS)
            font.family: "Symbols Nerd Font"
            font.pixelSize: 40
            color: pal.primary
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: globalState.fetchUser !== "" ? globalState.fetchUser : "—"
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(15 * globalState.fontScale); font.weight: Font.Medium
            color: pal.colorOnSurfVar
            elide: Text.ElideRight
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: globalState.fetchOS !== "" ? globalState.fetchOS : "—"
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale)
            color: pal.colorOnSurfVar
            elide: Text.ElideRight
        }
    }

    ColumnLayout {
        id: fetchDetailCol
        x: fetchShapeCanvas.x + 12
        y: fetchWidgetItem.fetchExpanded ? (fetchShapeCanvas.y + 52) : (fetchShapeCanvas.y + 12)
        Behavior on y { M3SpringAnim { token: "spatialDefault" } }
        width: fetchShapeCanvas.width - 24
        spacing: 5
        opacity: (fetchWidgetItem.fetchPeek || fetchWidgetItem.fetchExpanded) ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity {
            M3NumberAnim { duration: (fetchWidgetItem.fetchPeek || fetchWidgetItem.fetchExpanded) ? 320 : 160 }
        }

        RowLayout {
            Layout.fillWidth: true; spacing: 6
            Text { text: "\ue322"; font.family: "Material Symbols Rounded"; font.pixelSize: 13; color: pal.primary }
            Text { text: tr("system"); font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale); font.weight: Font.Medium; color: pal.colorOnSurfVar }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: pal.mutedDeep; opacity: 0.5 }

        Repeater {
            id: fetchRepeaterMain
            model: [
            { icon: "\ue00f", label: "OS",      value: globalState.fetchOS,     color: pal.primary },
            { icon: "\ue40d", label: "Kernel",  value: globalState.fetchKernel, color: pal.accent },
            { icon: "\uf8b4", label: "WM",      value: globalState.fetchWM,     color: pal.tertiary },
            { icon: "\ue322", label: "CPU",     value: globalState.fetchCPU,    color: pal.error },
            { icon: "\ue3af", label: "GPU",     value: globalState.fetchGPU,    color: pal.positive },
            { icon: "\ue322", label: "RAM",     value: globalState.fetchRAM,    color: pal.primary },
            { icon: "\ue1db", label: "Disk",    value: globalState.fetchDisk,   color: "#FFCC80" },
            { icon: "\ue425", label: "Uptime",  value: globalState.fetchUptime, color: "#CE93D8" },
            ]
            property color _textSecondary: pal.textSecondary
            property color _textPrimary: pal.textPrimary
            property color _textMuted: pal.textMuted
            RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 6
                Text {
                    text: modelData.icon
                    font.family: "Material Symbols Rounded"; font.pixelSize: 12
                    color: modelData.color; opacity: 0.85
                    Layout.preferredWidth: 16
                }
                Text {
                    text: modelData.label
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(9 * globalState.fontScale); font.weight: Font.Medium
                    color: fetchRepeaterMain._textSecondary
                    Layout.preferredWidth: 38
                }
                Text {
                    Layout.fillWidth: true
                    text: modelData.value !== "" ? modelData.value : "—"
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(9 * globalState.fontScale)
                    color: modelData.value !== "" ? fetchRepeaterMain._textPrimary : fetchRepeaterMain._textMuted
                    elide: Text.ElideRight
                }
            }
        }
    }

    ColumnLayout {
        id: fetchDetailColExtra
        visible: fetchWidgetItem.fetchExpanded
        opacity: fetchWidgetItem.fetchExpanded ? 1 : 0
        Behavior on opacity { M3NumberAnim {} }

        x: fetchDetailCol.x
        y: fetchDetailCol.y + fetchDetailCol.height + 14
        width: fetchDetailCol.width
        spacing: 5

        Rectangle { Layout.fillWidth: true; height: 1; color: pal.mutedDeep; opacity: 0.5 }

        Repeater {
            id: fetchRepeaterExtra
            model: [
            { icon: "\ue30c", label: "Display",  value: globalState.fetchDisplay,  color: pal.tertiary },
            { icon: "\ue264", label: "Font",      value: globalState.fetchFont,     color: pal.accent },
            { icon: "\ue86f", label: "Shell",     value: globalState.fetchShell,    color: pal.primary },
            { icon: "\uf187", label: "Packages",  value: globalState.fetchPackages, color: "#FFCC80" },
            { icon: "\ue894", label: "Locale",    value: globalState.fetchLocale,   color: "#CE93D8" },
            ]
            property color _textSecondary: pal.textSecondary
            property color _textPrimary: pal.textPrimary
            property color _textMuted: pal.textMuted
            RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 6
                Text {
                    text: modelData.icon
                    font.family: "Material Symbols Rounded"; font.pixelSize: 12
                    color: modelData.color; opacity: 0.85
                    Layout.preferredWidth: 16
                }
                Text {
                    text: modelData.label
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(9 * globalState.fontScale); font.weight: Font.Medium
                    color: fetchRepeaterExtra._textSecondary
                    Layout.preferredWidth: 55
                }
                Text {
                    Layout.fillWidth: true
                    text: modelData.value !== "" ? modelData.value : "—"
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(9 * globalState.fontScale)
                    color: modelData.value !== "" ? fetchRepeaterExtra._textPrimary : fetchRepeaterExtra._textMuted
                    elide: Text.ElideRight
                }
            }
        }
    }

    Rectangle {
        id: fetchCloseBtn
        visible: fetchWidgetItem.fetchExpanded
        opacity: fetchWidgetItem.fetchExpanded ? 1 : 0
        Behavior on opacity { M3NumberAnim {} }
        z: 50
        width: 26; height: 26; radius: 13
        x: fetchShapeCanvas.x + fetchShapeCanvas.width - width - 12
        y: fetchShapeCanvas.y + 20
        color: fetchCloseBtnHov.hovered ? pal.primaryCont : "transparent"
        Behavior on color { M3ColorAnim { duration: m3.durFast } }
        Text { anchors.centerIn: parent; text: "\ue5cd"; font.family: "Material Symbols Rounded"; font.pixelSize: 15; color: pal.colorOnSurfVar }
        HoverHandler { id: fetchCloseBtnHov }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                fetchWidgetItem.fetchExpanded = false;
                fetchWidgetItem.fetchPeek = false;
            }
        }
    }
}
