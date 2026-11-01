import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import ".."

// Eye care overlay: translucent amber layer that ignores clicks
PanelWindow {
    id: eyeCareOverlay
    WlrLayershell.namespace: "iridium-eyecare"
    WlrLayershell.layer: WlrLayer.Overlay
    anchors.top:    true
    anchors.bottom: true
    anchors.left:   true
    anchors.right:  true
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    color: "transparent"
    mask: Region {}
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(1.0, 0.55, 0.15, 0.16)
        opacity: 0
        NumberAnimation on opacity { from: 0; to: 1; duration: 400; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasizedDecelerate }
    }
}
