import QtQuick
import QtQuick.Effects
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import ".."
import "../panels"

// Shadow surface for desktop widgets
PanelWindow {
    id: desktopShadowLayer
    WlrLayershell.namespace: "iridium-shadow-desktop"
    WlrLayershell.layer: globalState.desktopEditMode ? WlrLayer.Overlay : WlrLayer.Bottom
    anchors.top:    true
    anchors.bottom: true
    anchors.left:   true
    anchors.right:  true
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}
    visible: !resetting
    property bool resetting: false
    function reset(reason) {
        if (resetting) return;
        console.warn("[shell-shadows] recreating the widgets shadow: " + reason);
        resetting = true;
        dsResetTimer.restart();
    }
    Timer { id: dsResetTimer; interval: 80; repeat: false; onTriggered: desktopShadowLayer.resetting = false }
    Timer { interval: 2600; running: true; repeat: false; onTriggered: desktopShadowLayer.reset("startup") }
    Connections {
        target: globalState
        function onShellShadowGenChanged() { desktopShadowLayer.reset("ipc"); }
    }

    readonly property bool on: globalState.shellShadowWidgetsOn
    readonly property int  thick: globalState.shellShadowRange
    readonly property bool grabLive: on && !globalState.lockScreenActive && !globalState.wpFullscreenActive

    Loader {
      anchors.fill: parent
      active: !desktopShadowLayer.resetting
      sourceComponent: Component {
    // One caster per widget so dragging moves a rendered shadow instead of re-blurring fullscreen
    Item {
        Repeater {
            model: desktopWidgetLayer.gridWidgets
            delegate: Item {
                id: dwSlot
                required property var modelData
                readonly property Item w: modelData.item
                readonly property bool act: desktopShadowLayer.on && w !== null && w.visible
                                            && globalState[modelData.enabledProp] === true
                x: w ? w.x : 0
                y: w ? w.y : 0
                width:  w ? w.width  : 0
                height: w ? w.height : 0
                scale:   w ? w.scale : 1
                opacity: (w && act) ? w.opacity : 0
                visible: act
                transform: [
                    Scale {
                        origin.x: 0; origin.y: 0
                        xScale: desktopWidgetLayer.animScale
                        yScale: desktopWidgetLayer.animScale
                    },
                    Translate {
                        x: (desktopWidgetLayer.widgetBoxX + dwSlot.x * desktopWidgetLayer.animScale - dwSlot.x)
                        y: (desktopWidgetLayer.widgetBoxY + dwSlot.y * desktopWidgetLayer.animScale - dwSlot.y)
                    }
                ]
                // The caster sits at 0,0 inside the slot, so tell it when the slot moves
                onXChanged: dwCaster.nudge()
                onYChanged: dwCaster.nudge()
                Connections {
                    target: desktopWidgetLayer
                    function onWidgetBoxXChanged() { dwCaster.nudge(); }
                    function onWidgetBoxYChanged() { dwCaster.nudge(); }
                    function onAnimScaleChanged()  { dwCaster.nudge(); }
                }
                ShellShadowCaster {
                    id: dwCaster
                    active: dwSlot.act && desktopShadowLayer.grabLive
                    grabTarget: dwSlot.w
                    regrabInterval: 700
                    // Widget drags lag less than a full frame: a smaller fill avoids a dark strip
                    motionFill: 0.4
                    width: dwSlot.width
                    height: dwSlot.height
                }
            }
        }
    }
      }
    }
}
