import QtQuick
import QtQuick.Layouts
import "../ui"

// Control-panel card with an icon and a 0-100 slider
Rectangle {
    id: sc
    property string icon: ""
    property bool muted: false
    property bool iconClickable: false
    property real level: 0
    property color activeColor: pal.toggleOn
    signal iconClicked()
    signal pressed()
    signal moved(int value)
    signal released()
    Layout.fillWidth: true
    radius: 14
    color: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont)
    implicitHeight: row.implicitHeight + 20

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8
        FadeIcon {
            text: sc.icon; font.family: "Material Symbols Rounded"; font.pixelSize: 18; color: sc.muted ? pal.muted : pal.primary
            opacity: sc.muted ? 0.5 : 1.0
            Behavior on color { M3ColorAnim {} }
            Behavior on opacity { M3NumberAnim {} }
            MouseArea { anchors.fill: parent; anchors.margins: -6; enabled: sc.iconClickable; cursorShape: Qt.PointingHandCursor; onClicked: sc.iconClicked() }
        }
        PercentSlider {
            id: track
            Layout.fillWidth: true
            opacity: sc.muted ? 0.4 : 1.0
            property real displayPct: sc.level
            value: displayPct
            trackH: 22
            handleHOverride: 32
            height: 36
            activeColor: sc.activeColor
            inactiveColor: globalState.glassMode ? ga(pal.surfaceDeep, 0.6) : pal.surfaceDeep
            showBubble: true
            onPctPressed: sc.pressed()
            onPctMoved: (v) => sc.moved(v)
            onPctReleased: sc.released()
            Behavior on opacity { M3NumberAnim {} }
        }
    }
}
