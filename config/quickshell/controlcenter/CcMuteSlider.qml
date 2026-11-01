import QtQuick
import QtQuick.Layouts
import "../ui"

// Mute toggle + level slider (volume / mic)
Item {
    id: cms
    property bool muted: false
    property string icon: ""
    property real level: 0
    property color activeColor: pal.toggleOn
    signal toggleMute()
    signal pctMoved(int value)
    RowLayout {
        anchors.fill: parent
        spacing: 6
        EIconButton {
            size: "s"
            variant: "tonal"
            toggleable: true
            checked: cms.muted
            icon: cms.icon
            onClicked: cms.toggleMute()
        }
        PercentSlider {
            Layout.fillWidth: true
            opacity: cms.muted ? 0.4 : 1.0
            property real displayPct: cms.muted ? 0 : cms.level
            value: displayPct
            trackH: 28
            handleHOverride: 38
            height: 40
            activeColor: cms.activeColor
            inactiveColor: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont)
            showBubble: true
            Behavior on opacity { M3NumberAnim {} }
            onPctPressed: { if (cms.muted) cms.toggleMute(); }
            onPctMoved: (v) => cms.pctMoved(v)
        }
    }
}
