import QtQuick
import QtQuick.Layouts
import "../ui"

// Equalizer band row with wavy sliders
Item {
    id: eqRow
    required property string bandLabel
    property real displayVal: 0
    property color waveColor: "#D0BCFF"
    property color textColor: "#FFFFFF"
    property color thumbColor: "#CCC2DC"
    property color thumbBorderColor: "#00000000"
    property real thumbW: 6
    property real thumbH: 26
    signal dragged(real v)
    signal dragActive(bool active)

    implicitHeight: 18
    property int waveCrossings: 7
    property bool liveWave: true

    function animateTo(v) {
        bandAnim.stop();
        bandAnim.from = eqRow.displayVal;
        bandAnim.to   = Math.max(0, Math.min(1, v));
        bandAnim.start();
    }
    function resetAndAnimate(v) {
        bandAnim.stop();
        eqRow.displayVal = 0;
        bandAnim.from = 0;
        bandAnim.to   = Math.max(0, Math.min(1, v));
        bandAnim.start();
    }
    function setInstant(v) {
        bandAnim.stop();
        eqRow.displayVal = Math.max(0, Math.min(1, v));
    }

    NumberAnimation { id: bandAnim; target: eqRow; property: "displayVal"; duration: 480; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.springCurveFast }

    RowLayout {
        anchors.fill: parent
        spacing: 8

        Text {
            text: eqRow.bandLabel
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(9 * globalState.fontScale); font.weight: Font.Medium
            color: eqRow.textColor
            Layout.preferredWidth: 26
        }

        Item {
            id: eqBandSlot
            Layout.fillWidth: true
            Layout.preferredHeight: 18

            EWavyLinear {
                id: eqBandWave
                anchors.left: parent.left; anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 26
                value: eqRow.displayVal
                animateValue: false
                active: eqRow.waveColor
                track: m3.alpha(m3.inkSurface, 0.14)
                wavy: true
                showHandle: true
                handleH: 22
                thickness: m3.progressThickness; amplitude: 3; wavelength: 30
                running: eqRow.liveWave
            }

            MouseArea {
                id: eqBandDrag
                anchors.fill: eqBandWave
                cursorShape: Qt.PointingHandCursor
                function dragTo(mx) {
                    var p = Math.max(0, Math.min(1, mx / width));
                    eqRow.setInstant(p);
                    eqRow.dragged(p);
                }
                onPressed:         (m) => { eqRow.dragActive(true); dragTo(m.x) }
                onPositionChanged: (m) => { if (pressed) dragTo(m.x) }
                onReleased:        (m) => { dragTo(m.x); eqRow.dragActive(false) }
            }
        }

        Text {
            text: Math.round(eqRow.displayVal * 100) + "%"
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(9 * globalState.fontScale); font.weight: Font.Medium
            color: eqRow.textColor
            Layout.preferredWidth: 28
            horizontalAlignment: Text.AlignRight
        }
    }
}
