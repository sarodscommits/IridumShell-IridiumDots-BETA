import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../widgets"

// Desktop cava layer (below the widgets so Hyprland blur applies)
PanelWindow {
    id: desktopCavaLayer
    WlrLayershell.namespace: "iridium-desktop-cava"
    WlrLayershell.layer: WlrLayer.Bottom
    readonly property string cavaEdge: globalState.desktopCavaEdge
    readonly property real cavaThick: Math.ceil(globalState.desktopCavaHeight + unifiedFrame.topBaseH)
    anchors.top:    cavaEdge !== "bottom"
    anchors.bottom: cavaEdge !== "top"
    anchors.left:   cavaEdge !== "right"
    anchors.right:  cavaEdge !== "left"
    implicitWidth:  cavaThick
    implicitHeight: cavaThick
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    visible: globalState.desktopCavaEnabled
    mask: Region {}

    DesktopCavaVis {
        anchors.fill: parent
        visible: globalState.desktopCavaEnabled && !globalState.desktopEditMode
    }
}
