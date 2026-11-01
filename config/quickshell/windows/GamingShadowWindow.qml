import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import ".."
import "../panels"

// Shadow surface for the gaming panel
PanelWindow {
    id: gamingShadowWindow
    WlrLayershell.namespace: "iridium-shadow-gaming"
    WlrLayershell.layer: WlrLayer.Overlay
    readonly property bool fl: gamingWindow.floatLayout
    readonly property real extra: fl ? 0 : 80
    anchors.left:   true
    anchors.top:    fl
    anchors.right:  fl
    anchors.bottom: fl
    exclusionMode: fl ? ExclusionMode.Normal : ExclusionMode.Ignore
    implicitWidth:  gamingWindow.implicitWidth + extra
    implicitHeight: gamingWindow.implicitHeight + extra * 2
    color: "transparent"
    mask: Region {}
    visible: globalState.shellShadowGamingOn && gamingWindow.visible

    readonly property Item gr: gamingWindow._gr
    readonly property Item tgt: !gr ? null : (fl ? gr.panelItem : gr.bgItem)
    ShellShadowCaster {
        active: globalState.shellShadowGamingOn && gamingShadowWindow.tgt !== null
        grabTarget: gamingShadowWindow.tgt
        regrabInterval: 700
        x: gamingShadowWindow.tgt ? gamingShadowWindow.gr.x + gamingShadowWindow.tgt.x : 0
        y: gamingShadowWindow.tgt ? gamingShadowWindow.gr.y + gamingShadowWindow.tgt.y + gamingShadowWindow.extra : 0
        width:  gamingShadowWindow.tgt ? gamingShadowWindow.tgt.width  : 0
        height: gamingShadowWindow.tgt ? gamingShadowWindow.tgt.height : 0
        opacity: gamingShadowWindow.gr ? gamingShadowWindow.gr.opacity : 0
    }
}
