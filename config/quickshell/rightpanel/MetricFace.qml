import QtQuick
import QtQuick.Layouts
import "../ui"
import "../widgets"

// One liquid-gauge metric of the system monitor card
Item {
    id: mf
    property bool active: false
    property real spin: 360
    property real size: 60
    property real percent: 0
    property string label: ""
    property string shapePath: ""
    anchors.fill: parent
    opacity: active ? 1 : 0
    scale: active ? 1 : 0.55
    rotation: active ? 0 : spin
    transformOrigin: Item.Center
    visible: opacity > 0.01
    Behavior on opacity { M3NumberAnim { duration: m3.durSlow } }
    Behavior on scale   { M3SpringAnim { token: "spatialSlow"; epsilon: 0.002 } }
    Behavior on rotation{ M3SpringAnim { token: "spatialSlow" } }

    ShapeGauge {
        anchors.centerIn: parent
        width: mf.size; height: mf.size
        glassEmpty: globalState.glassMode
        waveEffect: true
        wavePhase: globalState.wavePhase
        pct: mf.percent / 100
        shapePath: mf.shapePath
        fillColor: pal.primary
        emptyColor: pal.surfaceDeep
        outlineColor: pal.mutedDeep
    }
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 2
        Text { Layout.alignment: Qt.AlignHCenter; text: mf.label; font.family: globalState.fontPrimary; font.pixelSize: Math.round(22 * globalState.fontScale); font.weight: Font.Medium; color: pal.colorOnSurfVar }
        Text { Layout.alignment: Qt.AlignHCenter; text: mf.percent + "%"; font.family: globalState.fontPrimary; font.pixelSize: Math.round(48 * globalState.fontScale); font.weight: Font.Bold; color: pal.colorOnSurface }
    }
}
