import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import ".."
import "../panels"

// Shadow surface of the floating Control Center
PanelWindow {
    id: ccFloatShadowWindow
    WlrLayershell.namespace: "iridium-shadow-overlay"
    WlrLayershell.layer: WlrLayer.Overlay
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    exclusionMode: ExclusionMode.Normal
    color: "transparent"
    mask: Region {}
    visible: globalState.shellShadowPanelsOn && ccFloatWindow.visible
    ShellShadowCaster {
        active: globalState.shellShadowPanelsOn
        x: ccFloatPanel.x
        y: ccFloatPanel.y
        width: ccFloatPanel.width
        height: ccFloatPanel.height
        radius: ccFloatPanel.radius
        opacity: ccFloatPanel.opacity
    }
}
