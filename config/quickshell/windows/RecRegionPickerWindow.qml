import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import ".."

// Region selector for screen recording
PanelWindow {
    id: recRegionWin
    screen: {
        var n = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
        var sc = Quickshell.screens;
        for (var i = 0; i < sc.length; i++) if (sc[i].name === n) return sc[i];
        return sc.length ? sc[0] : null;
    }
    WlrLayershell.namespace: "iridium-recregion"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    anchors.top: true; anchors.bottom: true; anchors.left: true; anchors.right: true
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    Item {
        id: rr
        anchors.fill: parent
        focus: true
        property real x0: 0; property real y0: 0
        property real x1: 0; property real y1: 0
        property bool dragging: false
        property bool has: false
        readonly property real sx: Math.min(x0, x1)
        readonly property real sy: Math.min(y0, y1)
        readonly property real sw: Math.abs(x1 - x0)
        readonly property real sh: Math.abs(y1 - y0)
        readonly property color dim: Qt.rgba(0, 0, 0, 0.45)
        property real fade: 0
        NumberAnimation on fade { from: 0; to: 1; duration: 160; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasizedDecelerate }

        function cancel() {
            globalState.recRegionPicking = false;
            globalState.recStarting = false;
        }
        function confirm() {
            if (sw < 16 || sh < 16) { has = false; return; }
            var ox = recRegionWin.screen ? recRegionWin.screen.x : 0;
            var oy = recRegionWin.screen ? recRegionWin.screen.y : 0;
            var g = Math.round(sw) + "x" + Math.round(sh) + "+" + Math.round(ox + sx) + "+" + Math.round(oy + sy);
            recRegionLaunchDelay.geom = g;
            globalState.recRegionPicking = false;
            recRegionLaunchDelay.restart();
        }
        Keys.onEscapePressed: cancel()
        Component.onCompleted: forceActiveFocus()

        Rectangle { visible: !rr.has; anchors.fill: parent; color: rr.dim; opacity: rr.fade }
        Item {
            visible: rr.has
            anchors.fill: parent
            opacity: rr.fade
            Rectangle { x: 0; y: 0; width: parent.width; height: rr.sy; color: rr.dim }
            Rectangle { x: 0; y: rr.sy + rr.sh; width: parent.width; height: parent.height - rr.sy - rr.sh; color: rr.dim }
            Rectangle { x: 0; y: rr.sy; width: rr.sx; height: rr.sh; color: rr.dim }
            Rectangle { x: rr.sx + rr.sw; y: rr.sy; width: parent.width - rr.sx - rr.sw; height: rr.sh; color: rr.dim }
        }
        Rectangle {
            visible: rr.has
            x: rr.sx - 1; y: rr.sy - 1
            width: rr.sw + 2; height: rr.sh + 2
            color: "transparent"
            radius: 4
            border.width: 2
            border.color: pal.primary
        }
        Rectangle {
            visible: rr.has && rr.sw > 0
            readonly property bool below: rr.sy + rr.sh + height + 10 < rr.height
            x: Math.max(8, Math.min(rr.width - width - 8, rr.sx + rr.sw - width))
            y: below ? rr.sy + rr.sh + 8 : Math.max(8, rr.sy - height - 8)
            width: rrSize.implicitWidth + 20; height: 26; radius: 13
            color: pal.primary
            Text {
                id: rrSize
                anchors.centerIn: parent
                text: Math.round(rr.sw) + " × " + Math.round(rr.sh)
                font.family: globalState.fontPrimary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.DemiBold
                color: pal.colorOnPrimary
            }
        }
        Rectangle {
            visible: !rr.dragging
            anchors.horizontalCenter: parent.horizontalCenter
            y: 40
            width: rrHintRow.implicitWidth + 32; height: 40; radius: 20
            color: globalState.glassMode ? ga(pal.surfaceHigh, 0.92) : pal.surfaceHigh
            opacity: rr.fade
            Row {
                id: rrHintRow
                anchors.centerIn: parent
                spacing: 8
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\ue3c2"
                    font.family: "Material Symbols Rounded"; font.pixelSize: 18
                    color: pal.primary
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: tr("rec_pick_hint")
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                    color: pal.colorOnSurface
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.CrossCursor
            onPressed: (m) => {
                if (m.button === Qt.RightButton) { rr.cancel(); return; }
                rr.x0 = rr.x1 = m.x; rr.y0 = rr.y1 = m.y;
                rr.dragging = true; rr.has = true;
            }
            onPositionChanged: (m) => {
                if (!rr.dragging) return;
                rr.x1 = Math.max(0, Math.min(rr.width, m.x));
                rr.y1 = Math.max(0, Math.min(rr.height, m.y));
            }
            onReleased: (m) => {
                if (m.button !== Qt.LeftButton || !rr.dragging) return;
                rr.dragging = false;
                rr.confirm();
            }
        }
    }
}
