import QtQuick
import Quickshell
import Quickshell.Wayland

// Exclusive-zone strip for one screen edge
Loader {
    id: gap
    property string edge: "top"
    property real edgeBase: 0
    property bool autoHideSensor: false
    readonly property real baseSize: edgeBase * unifiedFrame.zoomK
    readonly property bool want: baseSize > 0 || autoHideSensor
    onWantChanged: active = want
    active: false
    onAutoHideSensorChanged: { active = false; active = want; }
    onBaseSizeChanged: { active = false; active = want; }
    Component.onCompleted: active = want
    sourceComponent: Component {
        PanelWindow {
            readonly property real thickness: (gap.autoHideSensor ? unifiedFrame.islandAutoHideSensorH : gap.edgeBase) * unifiedFrame.zoomK
            WlrLayershell.namespace: "quickshell:gap-" + gap.edge
            color: "transparent"
            anchors.top: gap.edge !== "bottom"
            anchors.bottom: gap.edge !== "top"
            anchors.left: gap.edge !== "right"
            anchors.right: gap.edge !== "left"
            exclusionMode: ExclusionMode.Normal
            implicitWidth: thickness
            implicitHeight: thickness
            exclusiveZone: gap.autoHideSensor ? 0 : gap.edgeBase * unifiedFrame.zoomK
            mask: Region { item: gap.autoHideSensor ? sensorArea : null }

            Item {
                id: sensorArea
                anchors.fill: parent
                HoverHandler {
                    onHoveredChanged: globalState.islandAutoHideSetHover(hovered)
                }
            }
        }
    }
}
