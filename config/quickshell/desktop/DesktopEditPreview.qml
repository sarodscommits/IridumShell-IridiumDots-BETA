import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "WidgetTypes.js" as WT

// Scaled desktop preview of the desktop editor
Rectangle {
    id: previewBox
    transform: Translate { y: desktopWidgetLayer.editEnterOffset }
    opacity: desktopWidgetLayer.editEnterOpacity
    x: desktopWidgetLayer.editPreviewBoxX
    y: desktopWidgetLayer.editPreviewBoxY
    width:  desktopWidgetLayer.editPreviewBoxW
    height: desktopWidgetLayer.editPreviewBoxH
    radius: 18
    clip: true
    color: "#1a1a1a"
    border.width: 3
    border.color: pal.primary

    Image {
        anchors.fill: parent
        source: {
            if (!globalState.desktopEditMode) return "";
            var s = globalState.currentWallpaperStill !== "" ? globalState.currentWallpaperStill : globalState.currentWallpaper;
            return s !== "" ? "file://" + s : "";
        }
        sourceSize.width: 1280
        fillMode: Image.PreserveAspectCrop
        smooth: true; asynchronous: true; cache: false
    }

    Item {
        id: previewBarZone
        readonly property real sc: desktopWidgetLayer.editPreviewScale
        readonly property string edge: unifiedFrame.barEdge
        readonly property bool vert: edge === "left" || edge === "right"
        readonly property bool island: unifiedFrame.islandMode
        readonly property real th: unifiedFrame.topBaseH * sc
        readonly property real alongFull: vert ? parent.height : parent.width
        readonly property real along: island ? Math.min(alongFull, unifiedFrame.islandNotchHalfWidth * 2 * sc) : alongFull
        x: edge === "left" ? 0 : edge === "right" ? parent.width - th : (parent.width - along) / 2
        y: edge === "top" ? 0 : edge === "bottom" ? parent.height - th : (parent.height - along) / 2
        width:  vert ? th : along
        height: vert ? along : th
        Behavior on x      { M3SpringAnim { token: "spatialSlow" } }
        Behavior on y      { M3SpringAnim { token: "spatialSlow" } }
        Behavior on width  { M3SpringAnim { token: "spatialSlow" } }
        Behavior on height { M3SpringAnim { token: "spatialSlow" } }
        Rectangle {
            anchors.fill: parent
            radius: previewBarZone.island ? previewBarZone.th / 2 : 0
            color: "#000000"
            opacity: 0.42
        }
        Rectangle {
            anchors.fill: parent
            radius: previewBarZone.island ? previewBarZone.th / 2 : 0
            color: "transparent"
            border.width: 1
            border.color: ga(pal.primary, 0.55)
        }
    }

    Repeater {
        model: WT.types.map(function (t) { return { type: t, item: desktopWidgetLayer[WT.rootName(t)] }; })
        delegate: DesktopEditProxy { id: editProxy }
    }
}
