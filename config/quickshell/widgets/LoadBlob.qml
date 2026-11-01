import QtQuick
import "../ui"

// Load blob whose shape reflects the level (calm → cookie → spinning burst)
Item {
    id: lb
    property int value: 0
    property string label: ""
    property color fill: m3.primaryContainer
    property color ink: m3.inkPrimaryContainer
    property bool live: true
    readonly property string shapeName: value >= 70 ? "SoftBurst" : (value >= 35 ? "Cookie9Sided" : "Circle")
    property string _from: shapeName
    property string _to: shapeName
    onShapeNameChanged: { _from = _to; _to = shapeName; lbM.snap(0); lbM.target = 1; lbR.target += 40; }
    Spring { id: lbM; target: 1; token: "spatialDefault"; eps: 0.002 }
    Spring { id: lbR; target: 0; token: "spatialDefault"; eps: 0.05 }
    property real spin: 0
    FrameAnimation {
        running: lb.live && lb.visible && lb.value >= 70
        onTriggered: lb.spin = (lb.spin + 22 * Math.min(frameTime, 0.05)) % 360
    }
    readonly property real side: Math.min(width, height)
    MBox {
        anchors.centerIn: parent
        width: lb.side; height: lb.side
        from: lb._from; to: lb._to; t: lbM.value
        rotation: lbR.value + lb.spin
        fill: lb.fill
    }
    Column {
        anchors.centerIn: parent
        spacing: -lb.side * 0.03
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: lb.value < 0 ? "—" : lb.value + "%"
            font.family: globalState.fontPrimary; font.pixelSize: Math.max(8, Math.round(lb.side * 0.26)); font.weight: Font.Black
            color: lb.ink
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: lb.label
            font.family: globalState.fontSecondary; font.pixelSize: Math.max(7, Math.round(lb.side * 0.12)); font.weight: Font.DemiBold
            color: lb.ink
            opacity: 0.8
        }
    }
}
