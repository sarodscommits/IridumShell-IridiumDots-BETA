import QtQuick
import "../ui"

// Common desktop widget frame: fade/scale-in and edit transform
Item {
    id: dwf
    property bool dwOn: false
    property bool dragging: false
    property bool resizable: false
    visible: dwOn || opacity > 0.01
    opacity: dwOn ? 1 : 0
    scale: dwOn ? 1 : 0.9
    Behavior on opacity { M3NumberAnim { duration: globalState.profileMorphing ? 520 : 300 } }
    Behavior on scale   { NumberAnimation { duration: globalState.profileMorphing ? 620 : 340; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.springCurve } }
    Behavior on x { enabled: !dwf.dragging && !(dwf.resizable && desktopResizeOverlay.resizingEdge); NumberAnimation { duration: globalState.profileMorphing ? 700 : 220; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.springCurve } }
    Behavior on y { enabled: !dwf.dragging && !(dwf.resizable && desktopResizeOverlay.resizingEdge); NumberAnimation { duration: globalState.profileMorphing ? 700 : 220; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.springCurve } }
    Behavior on width  { enabled: globalState.profileMorphing; M3SpringAnim { token: "spatialSlow" } }
    Behavior on height { enabled: globalState.profileMorphing; M3SpringAnim { token: "spatialSlow" } }
    transform: [
        Scale {
            origin.x: 0; origin.y: 0
            xScale: desktopWidgetLayer.animScale
            yScale: desktopWidgetLayer.animScale
        },
        Translate {
            x: (desktopWidgetLayer.widgetBoxX + dwf.x * desktopWidgetLayer.animScale - dwf.x)
            y: (desktopWidgetLayer.widgetBoxY + dwf.y * desktopWidgetLayer.animScale - dwf.y)
        }
    ]
}
