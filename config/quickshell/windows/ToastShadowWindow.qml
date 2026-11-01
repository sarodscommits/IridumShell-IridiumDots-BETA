import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

// Shadow surface for toasts, outside the blurred namespace
PanelWindow {
    id: toastShadowWindow
    property alias toastShadowRoot: toastShadowRoot
    WlrLayershell.namespace: "iridium-shadow-toasts"
    readonly property real extraW: 80
    anchors.top:    true
    anchors.right:  true
    anchors.bottom: true
    implicitWidth: 320 + extraW
    exclusiveZone: 0
    color: "transparent"
    mask: Region {}
    visible: true
    Item { id: toastShadowRoot; anchors.fill: parent; visible: globalState.shellShadowNotifsOn }
}
