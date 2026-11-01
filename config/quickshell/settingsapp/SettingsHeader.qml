import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Settings window header (title, search, close)
Item {
    id: settingsHeader
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.leftMargin: 28; anchors.rightMargin: 20; anchors.topMargin: 16
    height: 84
    readonly property var cur: settingsPopup.sections[settingsSidebar.activeIndex] || ({})
    EIconButton {
        id: settingsBackBtn
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        size: "m"; variant: "tonal"
        icon: "\ue5c4"
        visible: settingsPopup.activeSection !== "home"
        onClicked: { settingsPopup.goHome(); globalState.playUiClick(); }
    }
    ColumnLayout {
        anchors.left: settingsBackBtn.visible ? settingsBackBtn.right : parent.left
        anchors.leftMargin: settingsBackBtn.visible ? 16 : 0
        anchors.right: settingsHeaderTools.left
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        EText {
            Layout.fillWidth: true
            role: "labelLarge"; emph: true
            text: (settingsPopup.activeSection === "home"
                   ? "Iridium Shell · " + (settingsHeader.cur.sub || "")
                   : tr("sd_home") + (settingsPopup.groupTitle(settingsHeader.cur.group || "") !== "" ? "  ›  " + settingsPopup.groupTitle(settingsHeader.cur.group) : "")).toUpperCase()
            color: m3.primary
            font.letterSpacing: 1.1
            elide: Text.ElideRight
            MouseArea {
                anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                width: Math.min(parent.width, parent.contentWidth)
                enabled: settingsPopup.activeSection !== "home"
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: settingsPopup.goHome()
            }
        }
        EText {
            Layout.fillWidth: true
            role: "displaySmall"; emph: true
            text: settingsHeader.cur.label || ""
            elide: Text.ElideRight
        }
    }
    Row {
        id: settingsHeaderTools
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12
        ESegmented {
            anchors.verticalCenter: parent.verticalCenter
            size: "s"
            options: [{ icon: "\uea0b", label: tr("motion_expressive"), value: "expressive" }, { icon: "", label: tr("motion_standard"), value: "standard" }]
            current: globalState.motionScheme
            onPicked: (v) => setMotionScheme(v)
        }
        EIconButton {
            anchors.verticalCenter: parent.verticalCenter
            variant: "tonal"
            icon: globalState.colorMode === "light" ? "\ue51c" : "\ue518"
            onClicked: setColorMode(globalState.colorMode === "light" ? "dark" : "light")
        }
        EIconButton {
            anchors.verticalCenter: parent.verticalCenter
            variant: "standard"
            icon: "\ue5cd"
            onClicked: settingsWindow.closeWin()
        }
    }
}
