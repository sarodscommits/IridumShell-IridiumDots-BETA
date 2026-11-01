import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../widgets"

// Equalizer card of the media panel
Rectangle {
    id: mediaEqCard
    property alias eqRepeater: eqRepeater
    Layout.fillWidth: true
    Layout.fillHeight: true
    radius: 16
    color: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont)
    implicitHeight: eqCol.implicitHeight + 20

    ColumnLayout {
        id: eqCol
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        Text {
            text: tr("equalizer")
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale); font.weight: Font.Medium
            color: pal.textPrimary
        }

        SegmentedPill {
            Layout.fillWidth: true
            columns: 4
            segHeight: 22
            gap: 3; rowGap: 4
            innerRadius: 5; selRadius: 7
            selGrowX: 1; selGrowY: 2
            fontFamily: globalState.fontPrimary
            fontSize: Math.round(9 * globalState.fontScale)
            options: Object.keys(mediaPanel.eqPresets).map(function(k) { return { value: k, label: k }; })
            current: mediaPanel.eqActivePreset
            onPicked: (v) => mediaPanel.applyEqPreset(v)
            trackColor: {
                var c = Qt.darker(pal.secondaryCont, 1.4);
                return globalState.glassMode ? ga(c, 0.6) : c;
            }
            selectedColor: globalState.glassMode ? ga(pal.primary, 0.85) : pal.primary
            textColor: pal.textPrimary
            selectedTextColor: pal._light ? "#FFFFFF" : "#000000"
        }

        Repeater {
            id: eqRepeater
            model: mediaPanel.eqBandLabels
            property color _wave: pal.primary
            property color _text: pal.textSecondary
            property color _thumb: pal.accent
            property color _thumbBorder: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont)
            EqBandRow {
                required property string modelData
                required property int index
                Layout.fillWidth: true
                Layout.topMargin: index === 0 ? 2 : 18
                bandLabel: modelData
                waveColor: eqRepeater._wave
                textColor: eqRepeater._text
                thumbColor: eqRepeater._thumb
                thumbBorderColor: eqRepeater._thumbBorder
                thumbW: 7
                thumbH: 32
                onDragged: (v) => mediaPanel.onEqBandDragged(v)
                onDragActive: (active) => mediaPanel.setEqDragging(active)
            }
        }
    }
}
