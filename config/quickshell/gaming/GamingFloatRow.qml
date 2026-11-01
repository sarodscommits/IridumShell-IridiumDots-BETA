import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Compact floating metrics row of the gaming overlay
Rectangle {
    id: gmFloatRow
    readonly property bool fl: gamingWindow.floatLayout
    visible: fl
    Layout.fillWidth: !fl
    Layout.alignment: Qt.AlignLeft
    Layout.topMargin: fl ? 0 : 2
    implicitWidth: gmFloatInner.implicitWidth + (fl ? 28 : 0)
    implicitHeight: fl ? 36 : 22
    radius: 18
    color: fl ? ga(gamingWindow.dragging ? pal.surfacePop : pal.surfaceHigh,
    gamingWindow.dragging ? Math.max(gamingWindow.floatAlpha, 0.85) : gamingWindow.floatAlpha)
    : "transparent"
    Behavior on color { M3ColorAnim { duration: m3.durFast } }

    MouseArea {
        id: gmFloatDrag
        anchors.fill: parent
        enabled: gmFloatRow.fl
        cursorShape: gamingWindow.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        preventStealing: true
        property point pressScene
        property real startX: 0
        property real startY: 0
        onPressed: (mouse) => {
            pressScene = mapToItem(null, mouse.x, mouse.y);
            startX = gamingWindow.floatX; startY = gamingWindow.floatY;
        }
        onPositionChanged: (mouse) => {
            if (!pressed) return;
            var p = mapToItem(null, mouse.x, mouse.y);
            var dx = p.x - pressScene.x, dy = p.y - pressScene.y;
            if (!gamingWindow.dragging && Math.abs(dx) < 3 && Math.abs(dy) < 3) return;
            if (!gamingWindow.dragging) {
                gamingWindow.dragging = true;
                pressScene = p; startX = gamingWindow.floatX; startY = gamingWindow.floatY;
                return;
            }
            gamingWindow.dragX = gamingWindow.clampX(startX + dx);
            gamingWindow.dragY = gamingWindow.clampY(startY + dy);
        }
        onCanceled: finishDrag()
        onReleased: finishDrag()
        function finishDrag() {
            if (!gamingWindow.dragging) return;
            gamingWindow.dragging = false;
            globalState.gamingFloatX = Math.round(gamingWindow.floatX);
            globalState.gamingFloatY = Math.round(gamingWindow.floatY);
            gamingWindow.dragX = Qt.binding(function () { return globalState.gamingFloatX; });
            gamingWindow.dragY = Qt.binding(function () { return globalState.gamingFloatY; });
            savePrefs();
        }
    }

    RowLayout {
        id: gmFloatInner
        anchors.fill: parent
        anchors.leftMargin: gmFloatRow.fl ? 10 : 2
        anchors.rightMargin: gmFloatRow.fl ? 14 : 2
        spacing: 8
        FadeIcon {
            visible: gmFloatRow.fl
            text: ""
            font.family: "Material Symbols Rounded"; font.pixelSize: 18
            color: pal.colorOnSurfVar
        }
        Text { visible: !gmFloatRow.fl; text: ""; font.family: "Material Symbols Rounded"; font.pixelSize: 16; color: pal.primary }
        Text {
            Layout.fillWidth: !gmFloatRow.fl
            text: tr("gm_float")
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
            color: pal.colorOnSurfVar
        }
        ESwitch {
            checked: globalState.gamingFloating
            scaleF: 0.75
            interactive: gmFloatRow.fl
            onToggled: globalState.setGamingFloating(false)
        }
    }
    MouseArea {
        anchors.fill: parent
        visible: !gmFloatRow.fl
        cursorShape: Qt.PointingHandCursor
        onClicked: globalState.setGamingFloating(true)
    }
}
