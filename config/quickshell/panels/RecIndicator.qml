import QtQuick
import "../ui"

// Recording indicator whose shape shows the recorder state
Item {
    id: rci
    property real size: 12
    property bool active: true
    property bool running: true
    property color recColor: "#FF4D4D"
    property color pausedColor: pal.muted
    property color idleColor: pal.secondaryCont
    readonly property string st: !active ? "idle"
                               : globalState.recSaving ? "saving"
                               : globalState.recPaused ? "paused" : "rec"
    readonly property string shapeName: st === "saving" ? "Cookie4Sided"
                                      : st === "paused" ? "Square"
                                      : st === "idle"   ? "Circle" : "SoftBurst"
    property string _from: shapeName
    property string _to: shapeName
    onShapeNameChanged: { _from = _to; _to = shapeName; rciM.snap(0); rciM.target = 1; }
    width: size; height: size
    implicitWidth: size; implicitHeight: size
    Spring { id: rciM; target: 1; token: "spatialDefault"; eps: 0.002 }
    readonly property real _spd: st === "saving" ? 300 : (st === "rec" ? 50 : 0)
    property real spin: 0
    FrameAnimation {
        running: rci.running && rci.visible && rci._spd > 0
        onTriggered: rci.spin = (rci.spin + rci._spd * Math.min(frameTime, 0.05)) % 360
    }
    Spring { id: rciRest; target: 0; token: "spatialDefault"; eps: 0.05 }
    readonly property bool _still: st === "paused" || st === "idle"
    on_StillChanged: {
        if (_still) { rciRest.snap(spin > 180 ? spin - 360 : spin); rciRest.target = 0; }
        else spin = ((rciRest.value % 360) + 360) % 360;
    }
    property color col: st === "idle" ? idleColor : (st === "paused" ? pausedColor : recColor)
    Behavior on col { M3ColorAnim {} }
    property real pulse: 1
    SequentialAnimation on pulse {
        running: rci.running && rci.visible && rci.st === "rec"
        loops: Animation.Infinite
        NumberAnimation { to: 0.35; duration: 650; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.standardCurve }
        NumberAnimation { to: 1.0;  duration: 650; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.standardCurve }
    }
    MShape {
        anchors.fill: parent
        inset: 1.0
        from: rci._from; to: rci._to; t: rciM.value
        rotation: rci._still ? rciRest.value : rci.spin
        fill: rci.col
        opacity: rci.st === "rec" ? rci.pulse : 1
    }
}
