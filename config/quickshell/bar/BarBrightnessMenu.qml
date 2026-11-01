import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Brightness slider dropdown of the bar
Item {
    id: brightnessMenu
    property bool isOpen: globalState.brightnessMenuOpen
    Layout.fillWidth: true
    Layout.preferredHeight: isOpen ? 36 : 0
    visible: !unifiedFrame.barVertical
    clip: true
    Behavior on x {
        enabled: !globalState.desktopZoomBusy && unifiedFrame.startupSettled
        M3SpringAnim { token: "spatialFast" }
    }

    Behavior on Layout.preferredHeight { M3SpringAnim { token: "spatialDefault" } }

    property real animBrightPct: 0

    onIsOpenChanged: {
        if (isOpen) {
            animBrightPct = 0;
            brightOpenAnim.to = globalState.rawBrightness / 100;
            brightOpenAnim.start();
        }
    }

    NumberAnimation { id: brightOpenAnim; target: brightnessMenu; property: "animBrightPct"; from: 0; duration: 500; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasizedDecelerate }

    Connections {
        target: globalState
        function onRawBrightnessChanged() { if (brightnessMenu.isOpen) brightnessMenu.animBrightPct = globalState.rawBrightness / 100; }
    }

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

            Text { text: "\ue1ad"; font.family: "Material Symbols Rounded"; font.pixelSize: 16; color: pal.primary; opacity: globalState.glassMode ? 0.88 : 1.0 }

            PercentSlider {
                id: brightTrackContainer
                Layout.fillWidth: true
                opacity: globalState.glassMode ? 0.88 : 1.0
                property real displayPct: brightnessMenu.animBrightPct
                value: displayPct
                trackH: 13
                handleHOverride: 26
                height: 28
                activeColor: pal.toggleOn
                inactiveColor: globalState.glassMode ? ga(pal.surfaceDeep, 0.6) : pal.surfaceDeep
                showBubble: false
                onPctPressed: { globalState.brightnessAdjusting = true; }
                onPctMoved: (v) => { brightnessMenu.animBrightPct = v / 100; globalState.setBrightness(v); }
                onPctReleased: { globalState.brightnessAdjusting = false; }
            }

            Text { text: "\ue1ac"; font.family: "Material Symbols Rounded"; font.pixelSize: 16; color: pal.primary; opacity: globalState.glassMode ? 0.88 : 1.0 }
        }
    }
}
