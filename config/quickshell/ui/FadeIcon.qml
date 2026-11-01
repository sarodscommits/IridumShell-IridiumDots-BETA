import QtQuick

Item {
    id: fi
    property string text: ""
    property color color: "black"
    property alias font: fiA.font
    property int horizontalAlignment: Text.AlignLeft
    property int verticalAlignment: Text.AlignTop
    property int duration: 220
    property bool _aFront: true
    property bool _ready: false
    implicitWidth: Math.max(fiA.implicitWidth, fiB.implicitWidth)
    implicitHeight: Math.max(fiA.implicitHeight, fiB.implicitHeight)
    onTextChanged: {
        if (!_ready) { fiA.text = text; return; }
        var front = _aFront ? fiA : fiB, back = _aFront ? fiB : fiA;
        if (front.text === text) return;
        back.text = text; back.opacity = 1; front.opacity = 0; _aFront = !_aFront;
    }
    Component.onCompleted: { fiA.text = text; _ready = true; }
    Text {
        id: fiA
        anchors.fill: parent
        color: fi.color
        horizontalAlignment: fi.horizontalAlignment; verticalAlignment: fi.verticalAlignment
        opacity: 1
        Behavior on opacity { M3NumberAnim { duration: fi.duration } }
    }
    Text {
        id: fiB
        anchors.fill: parent
        font: fiA.font
        color: fi.color
        horizontalAlignment: fi.horizontalAlignment; verticalAlignment: fi.verticalAlignment
        opacity: 0
        Behavior on opacity { M3NumberAnim { duration: fi.duration } }
    }
}
