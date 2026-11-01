import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import ".."

// Backdrop and corner fillets of the gaming panel
Item {
    id: gmBg
    anchors.fill: parent
    layer.enabled: true
    layer.samples: 4
    visible: !gamingWindow.floatLayout
    opacity: currentFrameOpacity()
    Rectangle {
        x: gamingWindow.margin; y: gmPanel.y
        width: gamingWindow.panelW; height: gmPanel.height
        radius: 32
        color: pal.surface
    }
    Rectangle {
        visible: gmTab.width > 0.5
        x: gamingWindow.margin + gamingWindow.panelW - 32
        y: gmTab.y
        width: gmTab.width + 32; height: gmTab.height
        radius: Math.min(22, height / 2, width / 2)
        color: pal.surface
    }
    Shape {
        id: gmFillets
        anchors.fill: parent
        visible: r > 0.5
        preferredRendererType: Shape.CurveRenderer
        readonly property real r: 16 * gmTab.prog
        readonly property real pr: gamingWindow.margin + gamingWindow.panelW
        readonly property real tt: gmTab.y
        readonly property real tb: gmTab.y + gmTab.height
        readonly property real k: 0.4477
        ShapePath {
            fillColor: pal.surface; strokeColor: "transparent"
            startX: gmFillets.pr - 1; startY: gmFillets.tt - gmFillets.r
            PathLine { x: gmFillets.pr - 1; y: gmFillets.tt + 1 }
            PathLine { x: gmFillets.pr + gmFillets.r; y: gmFillets.tt + 1 }
            PathLine { x: gmFillets.pr + gmFillets.r; y: gmFillets.tt }
            PathCubic {
                control1X: gmFillets.pr + gmFillets.r * gmFillets.k; control1Y: gmFillets.tt
                control2X: gmFillets.pr; control2Y: gmFillets.tt - gmFillets.r * gmFillets.k
                x: gmFillets.pr; y: gmFillets.tt - gmFillets.r
            }
            PathLine { x: gmFillets.pr - 1; y: gmFillets.tt - gmFillets.r }
        }
        ShapePath {
            fillColor: pal.surface; strokeColor: "transparent"
            startX: gmFillets.pr - 1; startY: gmFillets.tb + gmFillets.r
            PathLine { x: gmFillets.pr - 1; y: gmFillets.tb - 1 }
            PathLine { x: gmFillets.pr + gmFillets.r; y: gmFillets.tb - 1 }
            PathLine { x: gmFillets.pr + gmFillets.r; y: gmFillets.tb }
            PathCubic {
                control1X: gmFillets.pr + gmFillets.r * gmFillets.k; control1Y: gmFillets.tb
                control2X: gmFillets.pr; control2Y: gmFillets.tb + gmFillets.r * gmFillets.k
                x: gmFillets.pr; y: gmFillets.tb + gmFillets.r
            }
            PathLine { x: gmFillets.pr - 1; y: gmFillets.tb + gmFillets.r }
        }
    }
}
