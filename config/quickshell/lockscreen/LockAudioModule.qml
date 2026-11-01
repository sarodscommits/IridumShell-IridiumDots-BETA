import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../widgets"

// Media module: album art ring, controls and lyrics
Rectangle {
    id: lockAudioModule
    z: 5
    readonly property real collapsedH: 40
    readonly property real expandedH: 240
    property bool expanded: false
    Timer { id: lockAudioCollapseTimer; interval: 260; onTriggered: lockAudioModule.expanded = false }
    HoverHandler {
        id: lockAudioHov
        onHoveredChanged: {
            if (hovered && !lockContent.editMode) { lockAudioCollapseTimer.stop(); lockAudioModule.expanded = true; }
            else lockAudioCollapseTimer.restart();
        }
    }
    Connections {
        target: globalState
        function onLockScreenActiveChanged() { if (!globalState.lockScreenActive) lockAudioModule.expanded = false; }
    }

    readonly property real collapsedW: Math.min(lockSessionRow.width, Math.max(collapsedH * 2.5, 18 + 18 + 10 + lockAudioTitle.implicitWidth + 18))
    readonly property real expandedW:  Math.min(lockContent.width - 40, lockPwArea.width + 80)
    width:  expanded ? expandedW : collapsedW
    height: expanded ? expandedH : collapsedH
    radius: expanded ? 24 : collapsedH / 2
    x: lockContent.modulesCX - width / 2
    y: lockPwArea.y + lockPwArea.height + lockContent.modGap
    Behavior on width  { M3SpringAnim { token: "spatialFast" } }
    Behavior on height { M3SpringAnim { token: "spatialFast" } }
    Behavior on radius { M3SpringAnim { token: "spatialDefault" } }
    clip: true
    color: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont)
    opacity: lockContent.blurDragging ? 0 : 1
    Behavior on opacity { M3NumberAnim { duration: m3.durFast } }

    MouseArea { anchors.fill: parent; onClicked: hiddenInput.forceActiveFocus() }

    property color cavaColor: pal.primary
    readonly property var cava4: {
        var b = globalState.cavaBars;
        var groups = [[0, 4], [4, 8], [8, 13], [13, 18]];
        var out = [];
        for (var g = 0; g < 4; g++) {
            var m = 0;
            for (var k = groups[g][0]; k < groups[g][1]; k++) m = Math.max(m, b[k] || 0);
            out.push(Math.min(1, m));
        }
        return out;
    }

    RowLayout {
        anchors.left: parent.left; anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 18; anchors.rightMargin: 18
        height: lockAudioModule.collapsedH
        spacing: 10
        opacity: lockAudioModule.expanded ? 0 : 1
        visible: opacity > 0.01
        Behavior on opacity { M3NumberAnim { duration: lockAudioModule.expanded ? 100 : 260 } }

        Row {
            spacing: 2
            Layout.preferredHeight: 16
            Layout.alignment: Qt.AlignVCenter
            height: 16
            Repeater {
                model: 4
                Rectangle {
                    required property int index
                    width: 3
                    radius: width / 2
                    height: Math.max(width, 16 * (0.15 + 0.85 * (lockAudioModule.cava4[index] || 0)))
                    anchors.verticalCenter: parent.verticalCenter
                    color: lockAudioModule.cavaColor
                    opacity: globalState.mediaStatus === "Playing" ? 1 : 0.5
                }
            }
        }
        Text {
            id: lockAudioTitle
            Layout.fillWidth: true
            text: globalState.mediaTitle !== "" ? globalState.mediaTitle : tr("no_media_playing")
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
            color: pal.colorOnSurface
            elide: Text.ElideRight
        }
    }

    LockMediaCard { id: lockMediaCard }
}
