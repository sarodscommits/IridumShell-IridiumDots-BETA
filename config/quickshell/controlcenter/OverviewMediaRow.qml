import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../widgets"

// Media row of the overview dashboard
RowLayout {
    id: ncPage4
    property alias ncEqBandsCol: ncEqBandsCol
    property alias ncEqPresetPill: ncEqPresetPill
    property alias ncEqRepeater: ncEqRepeater
    anchors.fill: ncDashAudioCard
    Component.onCompleted: Qt.callLater(function() { if (ncPage4.visible) rightPanelContent.mediaPanel.openEqAnimation(); })
    anchors.margins: 14
    anchors.topMargin: 58
    spacing: 12
    opacity: ncPage1Group.pageOn ? 1 : 0
    visible: opacity > 0.01 && ncDashLayer.shown("aud")
    Behavior on opacity { M3NumberAnim {} }
    onVisibleChanged: if (visible) rightPanelContent.mediaPanel.openEqAnimation()

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 8
        SegmentedPill {
            id: ncEqPresetPill
            Layout.fillWidth: true
            columns: 4
            segHeight: 20
            gap: 3; rowGap: 4
            innerRadius: 5; selRadius: 7
            selGrowX: 1; selGrowY: 2
            fontFamily: globalState.fontPrimary
            fontSize: Math.round(8 * globalState.fontScale)
            options: Object.keys(rightPanelContent.mediaPanel.eqPresets).map(function(k) { return { value: k, label: k }; })
            current: rightPanelContent.mediaPanel.eqActivePreset
            onPicked: (v) => rightPanelContent.mediaPanel.applyEqPreset(v)
            trackColor: {
                var c = Qt.darker(pal.secondaryCont, 1.4);
                return globalState.glassMode ? ga(c, 0.6) : c;
            }
            selectedColor: globalState.glassMode ? ga(pal.primary, 0.85) : pal.primary
            textColor: pal.textPrimary
            selectedTextColor: pal._light ? "#FFFFFF" : "#000000"
        }
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            ColumnLayout {
                id: ncEqBandsCol
                width: parent.width
                spacing: 0
                Repeater {
                    id: ncEqRepeater
                    model: rightPanelContent.mediaPanel.eqBandLabels
                    property color _wave: pal.primary
                    property color _text: pal.textSecondary
                    property color _thumb: pal.accent
                    property color _thumbBorder: ncDashAudioCard.color
                    EqBandRow {
                        required property string modelData
                        required property int index
                        Layout.fillWidth: true
                        Layout.topMargin: index === 0 ? 2 : 14
                        bandLabel: modelData
                        waveColor: ncEqRepeater._wave
                        textColor: ncEqRepeater._text
                        thumbColor: ncEqRepeater._thumb
                        thumbBorderColor: ncEqRepeater._thumbBorder
                        waveCrossings: 19
                        liveWave: ncPage1Group.live
                        onDragged: (v) => rightPanelContent.mediaPanel._syncEqFromRepeater(ncEqRepeater)
                        onDragActive: (active) => rightPanelContent.mediaPanel.setEqDragging(active)
                    }
                }
            }
        }
    }
}
