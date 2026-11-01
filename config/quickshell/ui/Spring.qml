import QtQuick

// Physical spring (mass 1): F = -k(x - target) - c·v, c = 2ζ√k
Item {
    id: sp
    visible: false
    property real target: 0
    property real value: 0
    property real velocity: 0
    property string token: "spatialDefault"
    property real stiffness: m3.sk(token)
    property real dampingRatio: m3.sz(token)
    property real eps: 0.001
    property bool ready: false
    readonly property bool moving: spFa.running
    Component.onCompleted: { value = target; ready = true }
    onTargetChanged: if (ready) spFa.running = true
    function snap(v) { spFa.running = false; value = v; velocity = 0; target = v }
    FrameAnimation {
        id: spFa
        onTriggered: {
            const dt = Math.min(frameTime, 0.05)
            const n = Math.max(1, Math.ceil(dt / 0.003))
            const h = dt / n
            const k = sp.stiffness, c = 2 * sp.dampingRatio * Math.sqrt(k)
            let x = sp.value, v = sp.velocity
            for (let i = 0; i < n; i++) { const a = -k * (x - sp.target) - c * v; v += a * h; x += v * h }
            if (Math.abs(x - sp.target) < sp.eps && Math.abs(v) < sp.eps * 10) { x = sp.target; v = 0; running = false }
            sp.velocity = v; sp.value = x
        }
    }
}
