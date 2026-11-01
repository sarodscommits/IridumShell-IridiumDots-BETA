import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Accessibility and extra toggles of the control panel
RowLayout {
    id: accessToggleRow
    Layout.fillWidth: true
    spacing: 8

    Repeater {
        id: cpAccessToggleRepeater
        model: [
        { key: "dark", iconOn: "\ue1ad", iconOff: "\ue1ac" },
        { key: "dnd",  iconOn: "\ue7f6", iconOff: "\ue7f4" },
        ]
        property color _primary:       pal.primary
        property color _secondaryCont: pal.secondaryCont
        property color _onSurface:     pal.colorOnSurface
        property color _onPrimary:     pal.colorOnPrimary
        Rectangle {
            required property var modelData
            property bool on: modelData.key === "dark" ? globalState.colorMode === "dark" : globalState.dndEnabled
            property string label: {
                if (modelData.key === "dark") return globalState.colorMode === "light" ? tr("light") : tr("dark");
                return globalState.dndEnabled ? tr("dnd") : tr("dnd_off");
            }
            Layout.fillWidth: true
            height: 64
            radius: on ? 14 : height / 2
            Behavior on radius { M3SpringAnim { token: "spatialDefault" } }
            color: {
                var active = on || accessToggleHov.hovered;
                var c = active ? cpAccessToggleRepeater._primary : containerDark(cpAccessToggleRepeater._secondaryCont);
                return (globalState.glassMode && !active) ? ga(c, 0.78) : c;
            }
            Behavior on color { M3ColorAnim {} }
            property bool _darken: on || accessToggleHov.hovered

            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width - 8
                spacing: 2
                opacity: globalState.glassMode ? 0.88 : 1.0
                FadeIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: on ? modelData.iconOn : modelData.iconOff
                    font.family: "Material Symbols Rounded"; font.pixelSize: 17
                    color: parent.parent._darken ? cpAccessToggleRepeater._onPrimary : cpAccessToggleRepeater._primary
                    Behavior on color { M3ColorAnim {} }
                }
                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: label
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(9 * globalState.fontScale); font.weight: Font.Medium
                    color: parent.parent._darken ? cpAccessToggleRepeater._onPrimary : cpAccessToggleRepeater._onSurface
                    Behavior on color { M3ColorAnim {} }
                }
            }
            HoverHandler { id: accessToggleHov }
            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (modelData.key === "dark") {
                        setColorMode(globalState.colorMode === "light" ? "dark" : "light");
                    }
                    if (modelData.key === "dnd") {
                        globalState.toggleDnd();
                    }
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 64; radius: 32
        color: {
            var c = containerDark(pal.secondaryCont);
            return (globalState.glassMode && true) ? ga(c, 0.78) : c;
        }
        Behavior on color { M3ColorAnim {} }
        Rectangle { anchors.fill: parent; radius: parent.radius; color: pal.colorOnSurface; opacity: m3Tile11Ma.pressed ? 0.12 : (cpTermHov.hovered ? 0.08 : 0); Behavior on opacity { NumberAnimation { duration: m3.durFast } } }
        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width - 8
            spacing: 2
            opacity: globalState.glassMode ? 0.88 : 1.0
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "\ue728"; font.family: "Material Symbols Rounded"; font.pixelSize: 17
                color: pal.primary
                Behavior on color { M3ColorAnim {} }
            }
            Text {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: "terminal"; font.family: globalState.fontSecondary; font.pixelSize: Math.round(9 * globalState.fontScale); font.weight: Font.Medium
                color: pal.colorOnSurface
                Behavior on color { M3ColorAnim {} }
            }
        }
        HoverHandler { id: cpTermHov }
        MouseArea { id: m3Tile11Ma;
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: { globalState.mediaMenuOpen = false; globalState.openTerminal(); }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 64; radius: 32
        color: {
            var c = containerDark(pal.secondaryCont);
            return (globalState.glassMode && true) ? ga(c, 0.78) : c;
        }
        Behavior on color { M3ColorAnim {} }
        Rectangle { anchors.fill: parent; radius: parent.radius; color: pal.colorOnSurface; opacity: m3Tile12Ma.pressed ? 0.12 : (cpSsHov.hovered ? 0.08 : 0); Behavior on opacity { NumberAnimation { duration: m3.durFast } } }
        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width - 8
            spacing: 2
            opacity: globalState.glassMode ? 0.88 : 1.0
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "\ue3b0"; font.family: "Material Symbols Rounded"; font.pixelSize: 17
                color: pal.primary
                Behavior on color { M3ColorAnim {} }
            }
            Text {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: tr("take_screenshot"); font.family: globalState.fontSecondary; font.pixelSize: Math.round(9 * globalState.fontScale); font.weight: Font.Medium
                color: pal.colorOnSurface
                Behavior on color { M3ColorAnim {} }
            }
        }
        HoverHandler { id: cpSsHov }
        MouseArea { id: m3Tile12Ma;
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: {
                globalState.mediaMenuOpen = false;
                if (bottomBarFocusGrab.active) {
                    globalState.waitingForGrabRelease = true;
                } else {
                    globalState.selectCaptureTrigger++;
                }
            }
        }
    }
}
