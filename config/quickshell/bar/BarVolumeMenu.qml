import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Volume slider dropdown of the bar
Item {
    id: volumeMenu
    property bool isOpen: globalState.volumeMenuOpen
    Layout.fillWidth: true
    Layout.preferredHeight: isOpen ? 36 : 0
    visible: !unifiedFrame.barVertical
    clip: true
    Behavior on x {
        enabled: !globalState.desktopZoomBusy && unifiedFrame.startupSettled
        M3SpringAnim { token: "spatialFast" }
    }
    transform: Scale {
        origin.x: volumeMenu.width  / 2
        origin.y: volumeMenu.height / 2
        yScale: unifiedFrame.barAtBottom ? -1 : 1
    }

    Behavior on Layout.preferredHeight { M3SpringAnim { token: "spatialDefault" } }

    property real animVolPct: 0

    onIsOpenChanged: {
        if (isOpen) {
            animVolPct = 0;
            volOpenAnim.to = globalState.isMuted ? 0 : globalState.rawVolumeValue / 100;
            volOpenAnim.start();
        }
    }

    NumberAnimation { id: volOpenAnim; target: volumeMenu; property: "animVolPct"; from: 0; duration: 500; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasizedDecelerate }

    Rectangle {
        anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.right: parent.right
        anchors.topMargin: 2; anchors.bottomMargin: 2
        width: Math.min(parent.width / 3, 320)
        radius: 12
        color: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12; anchors.rightMargin: 12
            spacing: 8

            FadeIcon {
                text: globalState.isMuted ? "\ue04f" : "\ue04d"; font.family: "Material Symbols Rounded"; font.pixelSize: 16; color: pal.primary; opacity: globalState.glassMode ? 0.88 : 1.0
                MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: globalState.toggleMute() }
            }

            PercentSlider {
                id: volTrackContainer
                Layout.fillWidth: true
                opacity: (globalState.glassMode ? 0.88 : 1.0) * (globalState.isMuted ? 0.4 : 1.0)
                property real displayPct: volumeMenu.animVolPct
                value: displayPct
                trackH: 13
                handleHOverride: 26
                height: 28
                activeColor: globalState.isMuted ? Qt.darker(pal.error, 1.8) : pal.toggleOn
                inactiveColor: globalState.glassMode ? ga(pal.surfaceDeep, 0.6) : pal.surfaceDeep
                showBubble: false
                Behavior on opacity { M3NumberAnim {} }
                Connections {
                    target: globalState
                    function onIsMutedChanged() {
                        volOpenAnim.to = globalState.isMuted ? 0 : globalState.rawVolumeValue / 100;
                        volOpenAnim.restart();
                    }
                }
                onPctPressed: { if (globalState.isMuted) globalState.toggleMute(); }
                onPctMoved: (v) => { globalState.rawVolumeValue = v; globalState.volumeText = v + "%"; volumeMenu.animVolPct = v / 100; audioPlayer.setOutputVolume(v * globalState.hwVolumeBoostMultiplier); }
            }

            FadeIcon {
                text: globalState.isMuted ? "\ue04f" : "\ue050"; font.family: "Material Symbols Rounded"; font.pixelSize: 16; color: pal.primary; opacity: globalState.glassMode ? 0.88 : 1.0
                MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: globalState.toggleMute() }
            }
        }
    }
}
