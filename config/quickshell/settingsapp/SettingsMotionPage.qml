import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../settings"

// Settings: motion page (springs, speed, bounce)
Item {
    id: sdMotionPage
    anchors.fill: parent
    visible: settingsPopup.activeSection === "motion"
    property real slow: 1
    EPage {
        anchors.fill: parent
        anchors.leftMargin: 24; anchors.rightMargin: 12; anchors.bottomMargin: 16

        ESection {
            title: tr("sd_physics")
            subtitle: tr("sd_physics_d")
            icon: ""
            headerTrailing: EButton { size: "s"; variant: "text"; icon: ""; text: tr("sd_reset"); onClicked: resetM3(["motionScheme", "m3Speed", "m3Bounce"]) }
            ESettingRow {
                icon: ""; label: tr("motion_scheme"); desc: tr("motion_desc")
                SegmentedPill {
                    Layout.preferredWidth: 240
                    options: [{ value: "expressive", label: tr("motion_expressive"), icon: "" }, { value: "standard", label: tr("motion_standard") }]
                    current: globalState.motionScheme
                    onPicked: (v) => setMotionScheme(v)
                    selectedColor: pal.primary; selectedTextColor: pal.colorOnPrimary
                    textColor: pal.colorOnSurfVar; iconColor: pal.primary
                }
            }
            ESettingRow {
                icon: ""; label: tr("sd_speed"); desc: tr("sd_speed_d")
                ESlider {
                    Layout.preferredWidth: 260
                    height: 36; trackH: 16; handleHOverride: 32
                    steps: 6
                    value: (globalState.m3Speed - 0.5) / 1.5
                    bubbleText: "×" + (0.5 + value * 1.5).toFixed(2)
                    onMoved: (v) => { globalState.m3Speed = Math.round((0.5 + v * 1.5) * 100) / 100; }
                    onReleased: savePrefs()
                }
            }
            ESettingRow {
                icon: ""; label: tr("sd_bounce"); desc: tr("sd_bounce_d")
                ESlider {
                    Layout.preferredWidth: 260
                    height: 36; trackH: 16; handleHOverride: 32
                    steps: 8
                    value: globalState.m3Bounce / 2
                    bubbleText: "×" + (value * 2).toFixed(2)
                    onMoved: (v) => { globalState.m3Bounce = Math.round(v * 2 * 100) / 100; }
                    onReleased: savePrefs()
                }
            }
        }

        ESection {
            title: tr("sd_tokens")
            subtitle: tr("sd_tokens_d")
            GridLayout {
                Layout.fillWidth: true
                columns: width > 760 ? 3 : 2
                columnSpacing: 12
                rowSpacing: 12
                Repeater {
                    model: ["spatialFast", "spatialDefault", "spatialSlow", "effectsFast", "effectsDefault", "effectsSlow"]
                    delegate: Rectangle {
                        id: sdTok
                        required property string modelData
                        required property int index
                        readonly property bool spatial: modelData.indexOf("spatial") === 0
                        property bool on: false
                        Layout.fillWidth: true
                        implicitHeight: 210
                        radius: m3.corner(24)
                        color: m3.glassy(m3.surfaceContainer, 0.6)
                        property real clock: -1
                        NumberAnimation on clock { id: sdTokClock; running: false; from: 0; to: 0.9; duration: 900 * sdMotionPage.slow }
                        Spring { id: sdTokS; token: sdTok.modelData; target: sdTok.on ? 1 : 0; stiffness: m3.sk(sdTok.modelData) / (sdMotionPage.slow * sdMotionPage.slow) }
                        ColumnLayout {
                            x: 16; y: 14; width: parent.width - 32
                            spacing: 6
                            RowLayout {
                                Layout.fillWidth: true
                                EText { role: "titleSmall"; emph: true; text: sdTok.modelData; Layout.fillWidth: true; elide: Text.ElideRight }
                                EText { role: "labelMedium"; color: m3.primary; text: "k " + Math.round(m3.sk(sdTok.modelData)) + " · ζ " + m3.sz(sdTok.modelData).toFixed(2) }
                            }
                            ESpringPlot {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 100
                                token: sdTok.modelData
                                line: sdTok.spatial ? m3.primary : m3.secondary
                                marker: sdTok.clock
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 28
                                radius: 14
                                color: m3.glassy(m3.surfaceContainerHighest, 0.6)
                                Rectangle {
                                    width: 28; height: 28; radius: 14
                                    x: Math.max(-6, Math.min(parent.width - 22, sdTokS.value * (parent.width - 28)))
                                    color: sdTok.spatial ? m3.primary : m3.secondary
                                    opacity: sdTok.spatial ? 1 : 0.35 + 0.65 * Math.max(0, Math.min(1, sdTokS.value))
                                }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { sdTok.on = !sdTok.on; sdTokClock.restart(); }
                        }
                    }
                }
            }
        }

        ESection {
            id: sdEaseSec
            title: tr("sd_curves")
            subtitle: tr("sd_curves_d")
            headerTrailing: RowLayout {
                spacing: 8
                EText { role: "labelLarge"; text: tr("sd_slowmo"); color: m3.inkSurfaceVariant }
                ESwitch { checked: sdMotionPage.slow > 1; onToggled: (v) => sdMotionPage.slow = v ? 4 : 1 }
            }
            GridLayout {
                Layout.fillWidth: true
                columns: width > 760 ? 3 : 2
                columnSpacing: 12
                rowSpacing: 12
                Repeater {
                    model: [
                        ["Emphasized", "emphasized", 500],
                        ["Emphasized decelerate", "emphasizedDecelerate", 400],
                        ["Emphasized accelerate", "emphasizedAccelerate", 200],
                        ["Standard", "standardCurve", 300],
                        ["Standard decelerate", "standardDecelerate", 250],
                        ["Spring (bézier)", "springCurve", 420]
                    ]
                    delegate: Rectangle {
                        id: sdEt
                        required property var modelData
                        readonly property var curve: m3[modelData[1]]
                        readonly property int dur: Math.round(modelData[2] / m3.speed)
                        Layout.fillWidth: true
                        implicitHeight: 220
                        radius: m3.corner(24)
                        color: m3.glassy(m3.surfaceContainer, 0.6)
                        property real tm: 0
                        property real pr: 0
                        ParallelAnimation {
                            id: sdEanim
                            NumberAnimation { target: sdEt; property: "tm"; from: 0; to: 1; duration: sdEt.dur * sdMotionPage.slow }
                            NumberAnimation { target: sdEt; property: "pr"; from: 0; to: 1; duration: sdEt.dur * sdMotionPage.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: sdEt.curve }
                        }
                        ColumnLayout {
                            x: 16; y: 14; width: parent.width - 32
                            spacing: 6
                            RowLayout {
                                Layout.fillWidth: true
                                EText { text: sdEt.modelData[0]; role: "titleSmall"; emph: true; Layout.fillWidth: true; elide: Text.ElideRight }
                                EText { text: sdEt.dur + " ms"; role: "labelMedium"; color: m3.primary }
                            }
                            Canvas {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 110
                                readonly property var dep: [sdEt.tm, sdEt.pr, m3.primary, sdEt.curve]
                                onDepChanged: requestPaint()
                                onWidthChanged: requestPaint()
                                onPaint: {
                                    const ctx = getContext("2d"); ctx.reset()
                                    const W = width, H = height, m = 10
                                    const X = x => m + x * (W - 2 * m), Y = y => H - m - y * (H - 2 * m) / 1.15
                                    ctx.strokeStyle = m3.css(m3.alpha(m3.inkSurfaceVariant, 0.25)); ctx.lineWidth = 1
                                    ctx.strokeRect(m, Y(1), W - 2 * m, Y(0) - Y(1))
                                    const c = sdEt.curve
                                    ctx.strokeStyle = m3.css(m3.primary); ctx.lineWidth = 3; ctx.beginPath(); ctx.moveTo(X(0), Y(0))
                                    for (let i = 0; i < c.length; i += 6)
                                        ctx.bezierCurveTo(X(c[i]), Y(c[i + 1]), X(c[i + 2]), Y(c[i + 3]), X(c[i + 4]), Y(c[i + 5]))
                                    ctx.stroke()
                                    ctx.fillStyle = m3.css(m3.tertiary); ctx.beginPath(); ctx.arc(X(sdEt.tm), Y(sdEt.pr), 6, 0, 2 * Math.PI); ctx.fill()
                                }
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 24
                                radius: 12
                                color: m3.glassy(m3.surfaceContainerHighest, 0.6)
                                Rectangle { width: 24 + sdEt.pr * (parent.width - 24); height: 24; radius: 12; color: m3.primary }
                            }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: sdEanim.restart() }
                    }
                }
            }
            EText { text: tr("sd_durations"); role: "titleMedium"; emph: true }
            Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: [["short1", 50], ["short2", 100], ["short3", 150], ["short4", 200], ["medium1", 250], ["medium2", 300], ["medium3", 350], ["medium4", 400],
                        ["long1", 450], ["long2", 500], ["long3", 550], ["long4", 600], ["extraLong1", 700], ["extraLong2", 800], ["extraLong3", 900], ["extraLong4", 1000]]
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: 106; height: 52; radius: 14
                        color: m3.mix(m3.secondaryContainer, m3.primaryContainer, index / 15)
                        Column {
                            anchors.centerIn: parent
                            EText { anchors.horizontalCenter: parent.horizontalCenter; text: modelData[0]; role: "labelMedium"; color: m3.inkSecondaryContainer }
                            EText { anchors.horizontalCenter: parent.horizontalCenter; text: Math.round(modelData[1] / m3.speed) + " ms"; role: "labelSmall"; color: m3.inkSecondaryContainer; opacity: 0.8 }
                        }
                    }
                }
            }
        }

        ESection {
            title: tr("sd_gesture")
            subtitle: tr("sd_gesture_d")
            Rectangle {
                id: sdGest
                Layout.fillWidth: true
                implicitHeight: 240
                radius: m3.corner(24)
                color: m3.glassy(m3.surfaceContainer, 0.6)
                clip: true
                property bool dragging: false
                property real dx: 0
                property real dy: 0
                Spring { id: sdGx; token: "spatialDefault"; eps: 0.05 }
                Spring { id: sdGy; token: "spatialDefault"; eps: 0.05 }
                Rectangle { anchors.centerIn: parent; width: 108; height: 108; radius: 54; color: "transparent"; border.width: 2; border.color: m3.alpha(m3.outline, 0.5) }
                MShape {
                    width: 96; height: 96
                    x: sdGest.width / 2 - 48 + (sdGest.dragging ? sdGest.dx : sdGx.value)
                    y: sdGest.height / 2 - 48 + (sdGest.dragging ? sdGest.dy : sdGy.value)
                    from: m3.accentShape; to: m3.accentShape
                    rot: (sdGest.dragging ? sdGest.dx : sdGx.value) * 0.4
                    fill: m3.primary; fill2: m3.tertiary
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: sdGest.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    preventStealing: true
                    property real ox: 0
                    property real oy: 0
                    property real lx: 0
                    property real ly: 0
                    property real lt: 0
                    property real vx: 0
                    property real vy: 0
                    onPressed: (m) => {
                        sdGest.dx = sdGx.value; sdGest.dy = sdGy.value
                        ox = m.x - sdGest.dx; oy = m.y - sdGest.dy
                        lx = m.x; ly = m.y; lt = Date.now(); vx = 0; vy = 0
                        sdGest.dragging = true
                    }
                    onPositionChanged: (m) => {
                        if (!pressed) return
                        const now = Date.now(), dt = Math.max(1, now - lt) / 1000
                        vx = 0.6 * vx + 0.4 * (m.x - lx) / dt; vy = 0.6 * vy + 0.4 * (m.y - ly) / dt
                        lx = m.x; ly = m.y; lt = now
                        sdGest.dx = m.x - ox; sdGest.dy = m.y - oy
                    }
                    onReleased: {
                        sdGx.snap(sdGest.dx); sdGy.snap(sdGest.dy)
                        sdGx.velocity = vx; sdGy.velocity = vy
                        sdGest.dragging = false
                        sdGx.target = 0; sdGy.target = 0
                    }
                }
                EText { anchors.bottom: parent.bottom; anchors.bottomMargin: 12; anchors.horizontalCenter: parent.horizontalCenter; role: "labelMedium"; color: m3.inkSurfaceVariant; text: tr("sd_gesture_hint") }
            }
        }
    }
}
