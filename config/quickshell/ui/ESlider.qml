import QtQuick

// M3E slider
Item {
    id: esl
    property real value: 0.5               // 0..1
    property int steps: 0                  // 0 = continuous
    property real trackH: 16
    property string icon: ""
    property bool showBubble: true
    property string bubbleText: ""         // empty = percent
    property color activeColor: m3.primary
    property color inactiveColor: m3.glassy(m3.secondaryContainer, 0.7)
    property color handleColor: activeColor
    property real handleHOverride: 0
    // Own critically damped motion, ignores global motion tokens (never bounces)
    property bool dragging: false
    property bool animate: !dragging
    readonly property real motionK: 1100      // value stiffness
    readonly property real motionKFast: 1800  // handle / bubble stiffness
    readonly property alias pressed: eslMa.pressed
    readonly property real handleH: handleHOverride > 0 ? handleHOverride : (trackH <= 24 ? 44 : (trackH <= 40 ? 52 : (trackH <= 56 ? 68 : 108)))
    readonly property real tH: Math.max(4, Math.min(height - 2, trackH * m3.sliderScale))   // effective thickness
    readonly property real outerR: tH <= 24 ? tH / 2 : (tH <= 40 ? 12 : (tH <= 56 ? 16 : 28))
    signal moved(real v)                   // on press and drag
    signal released(real v)
    signal pressedAt(real v)
    signal dragged(real v)
    signal releasedAt(real v)
    signal canceled()
    implicitHeight: handleH
    implicitWidth: 240
    opacity: enabled ? 1 : 0.38
    Spring { id: eslHw; stiffness: esl.motionKFast; dampingRatio: 1; eps: 0.02; target: eslMa.pressed ? 2 : 4 }
    Spring { id: eslBub; stiffness: esl.motionKFast; dampingRatio: 1; eps: 0.002; target: eslMa.pressed && esl.showBubble ? 1 : 0 }
    Spring { id: eslV; stiffness: esl.motionK; dampingRatio: 1; eps: 0.0005; target: esl.value }
    readonly property real shown: esl.animate ? Math.max(0, Math.min(1, eslV.value)) : Math.max(0, Math.min(1, esl.value))
    readonly property real gap: 6
    readonly property real hx: 2 + shown * (width - 4)
    readonly property real ty: (height - tH) / 2
    Rectangle {
        x: 0; y: esl.ty; height: esl.tH
        width: Math.max(0, esl.hx - eslHw.value / 2 - esl.gap)
        visible: width > 0.5
        color: esl.activeColor
        topLeftRadius: Math.min(esl.outerR, height / 2); bottomLeftRadius: Math.min(esl.outerR, height / 2)
        topRightRadius: Math.min(2, width / 2); bottomRightRadius: Math.min(2, width / 2)
        Behavior on color { ColorAnimation { duration: m3.durDefault } }
    }
    Rectangle {
        x: esl.hx + eslHw.value / 2 + esl.gap; y: esl.ty; height: esl.tH
        width: Math.max(0, esl.width - x)
        visible: width > 0.5
        color: esl.inactiveColor
        topRightRadius: Math.min(esl.outerR, height / 2); bottomRightRadius: Math.min(esl.outerR, height / 2)
        topLeftRadius: Math.min(2, width / 2); bottomLeftRadius: Math.min(2, width / 2)
    }
    Repeater {
        model: esl.steps > 0 ? esl.steps + 1 : 1
        delegate: Rectangle {
            required property int index
            readonly property real p: esl.steps > 0 ? index / esl.steps : 1
            readonly property real px: 2 + p * (esl.width - 4)
            width: 4; height: 4; radius: 2
            x: Math.max(esl.tH / 2 - 2, Math.min(esl.width - esl.tH / 2 - 2, px - 2))
            y: esl.height / 2 - 2
            visible: Math.abs(px - esl.hx) > esl.gap + 4
            color: p <= esl.shown ? m3.inkPrimary : esl.activeColor
        }
    }
    EIcon {
        visible: esl.icon !== ""
        name: esl.icon
        size: esl.trackH <= 24 ? 16 : (esl.trackH <= 40 ? 20 : (esl.trackH <= 56 ? 24 : 32))
        readonly property bool inActive: esl.hx - esl.gap > size + 20
        x: inActive ? 10 : esl.hx + eslHw.value / 2 + esl.gap + 10
        anchors.verticalCenter: parent.verticalCenter
        color: inActive ? m3.inkPrimary : m3.inkSecondaryContainer
        filled: true
    }
    Rectangle {
        width: eslHw.value; height: esl.handleH; radius: width / 2
        x: esl.hx - width / 2; y: (esl.height - height) / 2
        color: esl.handleColor
    }
    Rectangle {
        width: Math.max(44, eslBubT.implicitWidth + 20); height: 36; radius: 18
        x: esl.hx - width / 2; y: (esl.height - esl.handleH) / 2 - height - 6
        color: m3.inverseSurface
        scale: Math.max(0, eslBub.value); opacity: Math.min(1, Math.max(0, eslBub.value))
        transformOrigin: Item.Bottom
        visible: eslBub.value > 0.01
        z: 10
        EText { id: eslBubT; anchors.centerIn: parent; role: "labelLarge"; text: esl.bubbleText !== "" ? esl.bubbleText : Math.round(esl.value * (esl.steps > 0 ? esl.steps : 100)); color: m3.inverseOnSurface }
    }
    MouseArea {
        id: eslMa
        anchors.fill: parent
        anchors.topMargin: -6; anchors.bottomMargin: -6
        preventStealing: true
        cursorShape: Qt.PointingHandCursor
        function frac(mx) {
            let v = Math.max(0, Math.min(1, (mx - 2) / (esl.width - 4)))
            if (esl.steps > 0) v = Math.round(v * esl.steps) / esl.steps
            return v
        }
        property real pressX: 0
        onPressed: (m) => { pressX = m.x; esl.dragging = false; const f = frac(m.x); esl.pressedAt(f); esl.moved(f) }
        onPositionChanged: (m) => {
            if (!pressed) return
            // Clicks glide; real drags follow the cursor 1:1
            if (!esl.dragging && Math.abs(m.x - pressX) > 3) { esl.dragging = true }
            const f = frac(m.x); esl.dragged(f); esl.moved(f)
        }
        onReleased: (m) => {
            const f = frac(m.x); esl.releasedAt(f); esl.released(f)
            if (esl.dragging) { eslV.velocity = 0; eslV.value = esl.value; esl.dragging = false }
        }
        onCanceled: { if (esl.dragging) { eslV.velocity = 0; eslV.value = esl.value; esl.dragging = false } esl.canceled() }
        onWheel: (w) => {
            const st = esl.steps > 0 ? 1 / esl.steps : 0.05
            const f = Math.max(0, Math.min(1, esl.value + (w.angleDelta.y > 0 ? st : -st)))
            esl.pressedAt(f); esl.moved(f)
            esl.releasedAt(f); esl.released(f)
        }
    }
}
