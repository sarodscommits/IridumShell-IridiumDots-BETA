import QtQuick

// M3E loading indicator
Item {
    id: eli
    property bool contained: false
    property real size: 48
    property bool running: true
    property color color: contained ? m3.inkPrimaryContainer : m3.primary
    property color containerColor: m3.primaryContainer
    readonly property alias seq: eliSeq.seq
    property alias idx: eliSeq.idx
    property real spin: 0
    width: size; height: size
    implicitWidth: size; implicitHeight: size
    ShapeSequencer {
        id: eliSeq
        seq: ["SoftBurst", "Cookie9Sided", "Pentagon", "Pill", "Sunny", "Cookie4Sided", "Oval"]
        stiffness: 200; dampingRatio: 0.6
    }
    NumberAnimation on spin { from: 0; to: 360; duration: 4666; loops: Animation.Infinite; running: eli.running && eli.visible }
    Timer {
        interval: 650; repeat: true; running: eli.running && eli.visible
        onTriggered: eliSeq.next(90)
    }
    Rectangle { anchors.fill: parent; radius: width / 2; color: eli.containerColor; visible: eli.contained }
    MShape {
        anchors.centerIn: parent
        width: eli.size * (eli.contained ? 0.72 : 0.84); height: width
        from: eliSeq.from; to: eliSeq.to
        t: eliSeq.t; rot: eli.spin + eliSeq.rot; fill: eli.color; inset: 0.95
    }
}
