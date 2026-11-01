import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Volume and brightness sliders of the gaming panel
Rectangle {
    id: gamingSlidersCard
    visible: gamingWindow.modOn("sliders")
    Layout.fillWidth: true
    implicitHeight: gmSliderCol.implicitHeight + 32
    radius: 28
    color: globalState.glassMode ? ga(pal.surfaceDeep, 0.6) : pal.surfaceDeep
    ColumnLayout {
        id: gmSliderCol
        anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 16; anchors.rightMargin: 16
        spacing: 8
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            FadeIcon {
                Layout.preferredWidth: 24
                horizontalAlignment: Text.AlignHCenter
                text: globalState.isMuted ? "" : ""; font.family: "Material Symbols Rounded"; font.pixelSize: 21
                color: globalState.isMuted ? pal.muted : pal.primary
                MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: globalState.toggleMute() }
            }
            PercentSlider {
                id: gmVolTrack
                Layout.fillWidth: true
                opacity: globalState.isMuted ? 0.4 : 1.0
                property real displayPct: globalState.isMuted ? 0 : globalState.rawVolumeValue / 100
                value: displayPct
                trackH: 28
                handleHOverride: 38
                height: 40
                activeColor: globalState.isMuted ? Qt.darker(pal.error, 1.8) : pal.toggleOn
                inactiveColor: globalState.glassMode ? ga(pal.surface, 0.6) : pal.surface
                showBubble: true
                Behavior on opacity { M3NumberAnim {} }
                onPctPressed: { if (globalState.isMuted) globalState.toggleMute(); }
                onPctMoved: (v) => setVolumePercent(v)
            }
            Text {
                Layout.preferredWidth: 38
                horizontalAlignment: Text.AlignRight
                text: globalState.isMuted ? "—" : globalState.rawVolumeValue + "%"
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.DemiBold
                color: pal.colorOnSurfVar
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Text {
                Layout.preferredWidth: 24
                horizontalAlignment: Text.AlignHCenter
                text: ""; font.family: "Material Symbols Rounded"; font.pixelSize: 21; color: pal.primary
            }
            PercentSlider {
                id: gmBrightTrack
                Layout.fillWidth: true
                property real displayPct: globalState.rawBrightness / 100
                value: displayPct
                trackH: 28
                handleHOverride: 38
                height: 40
                activeColor: pal.toggleOn
                inactiveColor: globalState.glassMode ? ga(pal.surface, 0.6) : pal.surface
                showBubble: true
                onPctPressed: { globalState.brightnessAdjusting = true; }
                onPctMoved: (v) => { globalState.setBrightness(v); }
                onPctReleased: { globalState.brightnessAdjusting = false; }
            }
            Text {
                Layout.preferredWidth: 38
                horizontalAlignment: Text.AlignRight
                text: globalState.rawBrightness + "%"
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.DemiBold
                color: pal.colorOnSurfVar
            }
        }
    }
}
