import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../panels"

// Annotation toolbar of the screenshot overlay
Rectangle {
    id: shotBar
    visible: shot.phase === "edit"
    readonly property real gap: 12
    readonly property bool roomBelow: shot.sy + shot.sh + gap + height + 8 <= shot.height
    readonly property bool roomAbove: shot.sy - gap - height - 8 >= 0
    x: Math.max(8, Math.min(shot.width - width - 8, shot.sx + shot.sw / 2 - width / 2))
    y: roomBelow ? shot.sy + shot.sh + gap
    : (roomAbove ? shot.sy - gap - height : shot.sy + shot.sh - height - gap)
    width: shotBarRow.implicitWidth + 16
    height: 52
    radius: 26
    color: globalState.glassMode ? ga(pal.surfaceHigh, 0.94) : pal.surfaceHigh
    border.width: 1
    border.color: ga(pal.colorOnSurface, 0.08)
    opacity: visible ? 1 : 0
    property real slide: 0
    transform: Translate { y: shotBar.slide }
    onVisibleChanged: if (visible) shotBarIn.restart()
    NumberAnimation { id: shotBarIn; target: shotBar; property: "slide"; from: -10; to: 0; duration: 260; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasizedDecelerate }
    MouseArea { anchors.fill: parent }

    Row {
        id: shotBarRow
        anchors.centerIn: parent
        spacing: 4

        ShotBtn { glyph: ""; active: globalState.shotTool === "pen";  onClicked: { shot.commitText(); globalState.shotTool = "pen"; } }
        ShotBtn { glyph: ""; active: globalState.shotTool === "text"; onClicked: globalState.shotTool = "text" }

        Rectangle { width: 1; height: 24; anchors.verticalCenter: parent.verticalCenter; color: ga(pal.colorOnSurface, 0.15) }

        Repeater {
            model: globalState.shotColors
            delegate: Item {
                required property var modelData
                required property int index
                readonly property bool sel: globalState.shotColorIdx === index
                width: 28; height: 36
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.sel ? 24 : 18; height: width; radius: width / 2
                    Behavior on width { M3SpringAnim { token: "spatialFast" } }
                    color: parent.modelData
                    border.width: parent.sel ? 2 : 1
                    border.color: parent.sel ? pal.primary : ga(pal.colorOnSurface, 0.3)
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: { globalState.shotColorIdx = index; if (shot.editingText) shotTextInput.forceActiveFocus(); }
                }
            }
        }

        Rectangle { width: 1; height: 24; anchors.verticalCenter: parent.verticalCenter; color: ga(pal.colorOnSurface, 0.15) }

        Repeater {
            model: 3
            delegate: Item {
                required property int index
                readonly property bool sel: globalState.shotSizeIdx === index
                width: 30; height: 36
                Rectangle {
                    anchors.centerIn: parent
                    width: 28; height: 28; radius: 14
                    color: parent.sel ? ga(pal.primary, 0.22) : "transparent"
                    Rectangle {
                        anchors.centerIn: parent
                        width: [5, 9, 14][index]; height: width; radius: width / 2
                        color: shot.curColor
                        border.width: 1
                        border.color: ga(pal.colorOnSurface, 0.3)
                    }
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: { globalState.shotSizeIdx = index; if (shot.editingText) shotTextInput.forceActiveFocus(); }
                }
            }
        }

        Rectangle { width: 1; height: 24; anchors.verticalCenter: parent.verticalCenter; color: ga(pal.colorOnSurface, 0.15) }

        ShotBtn { glyph: ""; opacity: shot.history.length || shot.editingText ? 1 : 0.4; onClicked: shot.undo() }
        ShotBtn { glyph: ""; onClicked: shot.reselect() }
        ShotBtn { glyph: ""; onClicked: shot.finish(false) }
        ShotBtn { glyph: ""; accent: true; onClicked: shot.finish(true) }
        ShotBtn { glyph: ""; onClicked: shot.cancel() }
    }
}
