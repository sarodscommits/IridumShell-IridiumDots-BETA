import QtQuick

// Shape that cycles through a sequence on its own
MShape {
    id: aus
    property alias seq: ausSeq.seq
    property alias idx: ausSeq.idx
    property int interval: 1800
    property real spinStep: 45
    property bool running: true
    property string morphToken: "spatialSlow"
    from: ausSeq.from
    to: ausSeq.to
    t: ausSeq.t
    rot: ausSeq.rot
    ShapeSequencer {
        id: ausSeq
        seq: ["Cookie9Sided", "Sunny", "Clover4Leaf", "Pentagon", "Flower", "Gem", "SoftBurst"]
        token: aus.morphToken
    }
    Timer {
        interval: aus.interval; repeat: true; running: aus.running && aus.visible
        onTriggered: ausSeq.next(aus.spinStep)
    }
}
