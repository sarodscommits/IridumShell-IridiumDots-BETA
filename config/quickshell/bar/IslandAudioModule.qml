import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Now-playing module of the island
Rectangle {
    id: islandAudioModule
    visible: globalState.barModules.audio
    implicitWidth: unifiedFrame.barVertical ? 28 : 92; implicitHeight: unifiedFrame.barVertical ? 46 : 28; radius: 14
    Layout.alignment: Qt.AlignCenter
    readonly property var miniCava: {
        if (!unifiedFrame.barVertical) return [0, 0, 0, 0];
        var b = globalState.cavaBars;
        var groups = [[0, 4], [4, 8], [8, 13], [13, 18]];
        var out = [];
        for (var g = 0; g < 4; g++) {
            var m = 0;
            for (var k = groups[g][0]; k < groups[g][1]; k++) m = Math.max(m, b[k] || 0);
            out.push(globalState.mediaStatus === "Playing" ? Math.min(1, m) : 0);
        }
        return out;
    }
    Item {
        visible: unifiedFrame.barVertical
        anchors.fill: parent
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 6
            text: "\ue405"
            font.family: "Material Symbols Rounded"; font.pixelSize: 14
            color: globalState.mediaStatus === "Playing" ? pal.primary : pal.colorOnSurfVar
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height - height - 7
            height: 14
            spacing: 2
            Repeater {
                model: 4
                Rectangle {
                    required property int index
                    width: 3; radius: 1.5
                    height: Math.max(2, 14 * (islandAudioModule.miniCava[index] || 0))
                    y: parent.height - height
                    color: pal.primary
                    opacity: globalState.mediaStatus === "Playing" ? 1 : 0.45
                    Behavior on height { M3SpringAnim { token: "spatialFast" } }
                }
            }
        }
    }
    color: {
        var c = notchMediaPopup.isOpen ? pal.primaryCont : pal.secondaryCont;
        return globalState.glassMode ? ga(c, 0.6) : c;
    }
    Behavior on color { M3ColorAnim {} }
    function openAudio() {
        if (!globalState.notchMediaOpen) {
            globalState.islandControlOpen = false;
            globalState.closeOthers("notchMedia");
            globalState.notchControlOpen = false;
            globalState.notchMediaOpen = true;
        }
    }
    HoverHandler {
        id: islandAudioModuleHov
        onHoveredChanged: if (hovered && !globalState.desktopEditMode) islandAudioModule.openAudio()
    }
    MouseArea {
        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
        onClicked: islandAudioModule.openAudio()
    }

    RowLayout {
        visible: !unifiedFrame.barVertical
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 5

        Text {
            text: "\ue405"
            font.family: "Material Symbols Rounded"; font.pixelSize: 12
            color: pal.colorOnSurfVar
        }

        Item {
            id: islandAudioTitleClip
            Layout.fillWidth: true
            height: 16
            clip: true

            property real  _scrollX:  0
            property bool  _pausing:  true
            property int   _ticks:    0
            property int   _pauseMax: 36
            property real  _speed:    0.6
            readonly property int _gap: 30

            function reset() { _scrollX = 0; _pausing = true; _ticks = 0; }

            Connections {
                target: globalState
                function onMediaTitleChanged() { islandAudioTitleClip.reset(); }
            }

            Timer {
                interval: 33; repeat: true
                running: islandAudioModule.visible
                onTriggered: {
                    var tw = islandAudioTitleText.contentWidth;
                    var cw = islandAudioTitleClip.width;
                    if (cw <= 0 || tw <= 0) return;

                    if (tw <= cw + 2) {
                        islandAudioTitleClip._scrollX = 0;
                        islandAudioTitleClip._pausing  = true;
                        islandAudioTitleClip._ticks    = 0;
                        return;
                    }

                    if (islandAudioTitleClip._pausing) {
                        islandAudioTitleClip._ticks++;
                        if (islandAudioTitleClip._ticks >= islandAudioTitleClip._pauseMax)
                        islandAudioTitleClip._pausing = false;
                        return;
                    }

                    islandAudioTitleClip._scrollX -= islandAudioTitleClip._speed;
                    var cycle = tw + islandAudioTitleClip._gap;
                    if (islandAudioTitleClip._scrollX <= -cycle)
                    islandAudioTitleClip._scrollX += cycle;
                }
            }

            Text {
                id: islandAudioTitleText
                text: globalState.mediaTitle !== "" ? globalState.mediaTitle : "Nothing playing"
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium
                color: pal.colorOnSurfVar
                x: islandAudioTitleClip._scrollX
                y: (parent.height - height) / 2
            }
            Text {
                text: islandAudioTitleText.text
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium
                color: pal.colorOnSurfVar
                visible: islandAudioTitleText.contentWidth > islandAudioTitleClip.width + 2
                x: islandAudioTitleClip._scrollX + islandAudioTitleText.contentWidth + islandAudioTitleClip._gap
                y: (parent.height - height) / 2
            }
        }
    }
}
