import QtQuick

// Spring-driven shape sequence for MShape/MBox; next(spin) advances
Item {
    id: ss
    visible: false
    property var seq: []
    property int idx: 0
    property string token: "spatialDefault"
    property real stiffness: m3.sk(token)
    property real dampingRatio: m3.sz(token)
    property real morphEps: 0.001
    property real rotEps: 0.01
    readonly property string from: seq.length ? seq[(idx + seq.length - 1) % seq.length] : "Circle"
    readonly property string to: seq.length ? seq[idx] : "Circle"
    readonly property real t: ssM.value
    readonly property real rot: ssR.value
    function next(spin) {
        idx = (idx + 1) % seq.length
        ssM.snap(0); ssM.target = 1
        ssR.target += spin
    }
    Spring { id: ssM; target: 1; stiffness: ss.stiffness; dampingRatio: ss.dampingRatio; eps: ss.morphEps }
    Spring { id: ssR; target: 0; stiffness: ss.stiffness; dampingRatio: ss.dampingRatio; eps: ss.rotEps }
}
