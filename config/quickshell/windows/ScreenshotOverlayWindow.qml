import QtQuick
import QtQuick.Shapes
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import ".."
import "../windows"

// Area capture overlay: frozen screen, selection and annotation
PanelWindow {
    id: shotWin
    screen: {
        var n = globalState.shotMonitor;
        var sc = Quickshell.screens;
        for (var i = 0; i < sc.length; i++) if (sc[i].name === n) return sc[i];
        return sc.length ? sc[0] : null;
    }
    WlrLayershell.namespace: "iridium-screenshot"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    anchors.top: true; anchors.bottom: true; anchors.left: true; anchors.right: true
    exclusionMode: ExclusionMode.Ignore
    color: "black"

    Item {
        id: shot
        anchors.fill: parent
        focus: true

        property real x0: 0; property real y0: 0
        property real x1: 0; property real y1: 0
        property bool dragging: false
        property bool has: false
        property string phase: "select"
        readonly property real sx: Math.min(x0, x1)
        readonly property real sy: Math.min(y0, y1)
        readonly property real sw: Math.abs(x1 - x0)
        readonly property real sh: Math.abs(y1 - y0)
        readonly property color dim: Qt.rgba(0, 0, 0, 0.45)
        property real fade: 0
        NumberAnimation on fade { from: 0; to: 1; duration: 160; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasizedDecelerate }

        readonly property var sizes:     [3, 6, 11]
        readonly property var textSizes: [18, 28, 42]
        readonly property color curColor: globalState.shotColors[globalState.shotColorIdx]
        property var strokes: []
        property var curPts: []
        property bool drawing: false
        property var texts: []
        property var history: []
        property bool editingText: false
        property real editX: 0; property real editY: 0
        property bool busy: false

        function cancel() { globalState.shotClose(); }
        function enterEdit() {
            phase = "edit";
            forceActiveFocus();
        }
        function selectAll() {
            x0 = 0; y0 = 0; x1 = width; y1 = height;
            has = true;
            enterEdit();
        }
        function reselect() {
            commitText();
            strokes = []; texts = []; history = []; curPts = [];
            has = false; phase = "select";
            forceActiveFocus();
        }
        function undo() {
            if (editingText) { cancelText(); return; }
            if (!history.length) return;
            var h = history.slice(), k = h.pop();
            history = h;
            if (k === "s") strokes = strokes.slice(0, -1);
            else texts = texts.slice(0, -1);
        }
        function beginText(px, py) {
            commitText();
            editX = px; editY = py;
            shotTextInput.text = "";
            editingText = true;
            shotTextInput.forceActiveFocus();
        }
        function commitText() {
            if (!editingText) return;
            var t = shotTextInput.text;
            editingText = false;
            if (t.trim() !== "") {
                texts = texts.concat([{ x: editX, y: editY, t: t, c: curColor.toString(), s: textSizes[globalState.shotSizeIdx] }]);
                history = history.concat(["t"]);
            }
            shot.forceActiveFocus();
        }
        function cancelText() { editingText = false; shot.forceActiveFocus(); }

        function finish(save) {
            if (busy || phase !== "edit") return;
            commitText();
            busy = true;
            var physW = shotFrozenImg.implicitWidth > 0 ? shotFrozenImg.implicitWidth : width;
            var k = physW / Math.max(1, width);
            var tw = Math.max(1, Math.round(sw * k)), th = Math.max(1, Math.round(sh * k));
            var stamp = Qt.formatDateTime(new Date(), "yyyyMMdd-HHmmss");
            var path = save ? (globalState.shotDir + "/screenshot-" + stamp + ".png")
            : ((globalState.shotFrozen.replace(/[^\/]*$/, "")) + "qs-shot-clip.png");
            shotCanvas.grabToImage(function (res) {
                var ok = res.saveToFile(path);
                if (ok) {
                    Quickshell.execDetached(["bash", "-c",
                    "wl-copy --type image/png < \"$1\" >/dev/null 2>&1 &\n" +
                    "if [ \"$2\" = 1 ]; then notify-send -a qs-shot -i \"$1\" \"$3\" \"$1\"; else notify-send -a qs-shot -i \"$1\" \"$4\"; fi\n",
                    "qs-shot-done", path, save ? "1" : "0", tr("shot_saved"), tr("shot_copied")]);
                }
                globalState.shotClose();
            }, Qt.size(tw, th));
        }

        Keys.onPressed: (e) => {
            if (shot.editingText) return;
            if (e.key === Qt.Key_Escape) { shot.cancel(); e.accepted = true; }
            else if (shot.phase === "select" && (e.key === Qt.Key_Return || e.key === Qt.Key_Enter)) { shot.selectAll(); e.accepted = true; }
            else if (shot.phase === "edit") {
                if ((e.modifiers & Qt.ControlModifier) && e.key === Qt.Key_Z) { shot.undo(); e.accepted = true; }
                else if ((e.modifiers & Qt.ControlModifier) && e.key === Qt.Key_C) { shot.finish(false); e.accepted = true; }
                else if ((e.modifiers & Qt.ControlModifier) && e.key === Qt.Key_S) { shot.finish(true); e.accepted = true; }
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { shot.finish(true); e.accepted = true; }
                else if (e.key === Qt.Key_P) { globalState.shotTool = "pen"; e.accepted = true; }
                else if (e.key === Qt.Key_T) { globalState.shotTool = "text"; e.accepted = true; }
            }
        }
        Component.onCompleted: forceActiveFocus()

        Image {
            id: shotFrozenImg
            anchors.fill: parent
            source: globalState.shotFrozen !== "" ? ("file://" + globalState.shotFrozen + "?" + globalState.shotNonce) : ""
            cache: false
            smooth: true
            fillMode: Image.Stretch
        }

        Rectangle { visible: !shot.has; anchors.fill: parent; color: shot.dim; opacity: shot.fade }
        Item {
            visible: shot.has
            anchors.fill: parent
            Rectangle { x: 0; y: 0; width: parent.width; height: shot.sy; color: shot.dim }
            Rectangle { x: 0; y: shot.sy + shot.sh; width: parent.width; height: parent.height - shot.sy - shot.sh; color: shot.dim }
            Rectangle { x: 0; y: shot.sy; width: shot.sx; height: shot.sh; color: shot.dim }
            Rectangle { x: shot.sx + shot.sw; y: shot.sy; width: parent.width - shot.sx - shot.sw; height: shot.sh; color: shot.dim }
        }

        Item {
            id: shotCanvas
            visible: shot.has
            x: shot.sx; y: shot.sy
            width: Math.max(1, shot.sw); height: Math.max(1, shot.sh)
            clip: true
            Image {
                x: -shot.sx; y: -shot.sy
                width: shot.width; height: shot.height
                source: shotFrozenImg.source
                cache: false
                smooth: true
                fillMode: Image.Stretch
            }
            Repeater {
                model: shot.strokes.length
                delegate: Shape {
                    id: shotStrokeDel
                    required property int index
                    readonly property var st: shot.strokes[index]
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeColor: shotStrokeDel.st ? shotStrokeDel.st.c : "transparent"
                        strokeWidth: shotStrokeDel.st ? shotStrokeDel.st.w : 1
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        joinStyle: ShapePath.RoundJoin
                        PathPolyline { path: shotStrokeDel.st ? shotStrokeDel.st.pts : [] }
                    }
                }
            }
            Shape {
                id: shotCurStroke
                anchors.fill: parent
                visible: shot.drawing
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: shot.curColor
                    strokeWidth: shot.sizes[globalState.shotSizeIdx]
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin
                    PathPolyline { path: shot.curPts }
                }
            }
            Repeater {
                model: shot.texts.length
                delegate: Text {
                    required property int index
                    readonly property var tt: shot.texts[index]
                    x: tt ? tt.x : 0; y: tt ? tt.y : 0
                    text: tt ? tt.t : ""
                    color: tt ? tt.c : "white"
                    font.family: globalState.fontPrimary
                    font.pixelSize: tt ? tt.s : 20
                    font.weight: Font.Bold
                    style: Text.Outline
                    styleColor: (tt && tt.c === "#000000") ? Qt.rgba(1, 1, 1, 0.6) : Qt.rgba(0, 0, 0, 0.55)
                }
            }
            TextInput {
                id: shotTextInput
                visible: shot.editingText
                x: shot.editX; y: shot.editY
                width: Math.max(40, contentWidth + 4)
                color: shot.curColor
                font.family: globalState.fontPrimary
                font.pixelSize: shot.textSizes[globalState.shotSizeIdx]
                font.weight: Font.Bold
                selectByMouse: true
                Keys.onReturnPressed: shot.commitText()
                Keys.onEnterPressed: shot.commitText()
                Keys.onEscapePressed: shot.cancelText()
                Text {
                    visible: shotTextInput.text === ""
                    text: tr("shot_text_ph")
                    color: shotTextInput.color
                    opacity: 0.55
                    font: shotTextInput.font
                }
            }
        }

        Rectangle {
            visible: shot.has
            x: shot.sx - 1; y: shot.sy - 1
            width: shot.sw + 2; height: shot.sh + 2
            color: "transparent"
            radius: 2
            border.width: 2
            border.color: pal.primary
        }
        Rectangle {
            visible: shot.has && shot.phase === "select" && shot.sw > 0
            readonly property bool below: shot.sy + shot.sh + height + 10 < shot.height
            x: Math.max(8, Math.min(shot.width - width - 8, shot.sx + shot.sw - width))
            y: below ? shot.sy + shot.sh + 8 : Math.max(8, shot.sy - height - 8)
            width: shotSizeTxt.implicitWidth + 20; height: 26; radius: 13
            color: pal.primary
            Text {
                id: shotSizeTxt
                anchors.centerIn: parent
                text: Math.round(shot.sw) + " × " + Math.round(shot.sh)
                font.family: globalState.fontPrimary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.DemiBold
                color: pal.colorOnPrimary
            }
        }
        Rectangle {
            visible: shot.phase === "select" && !shot.dragging
            anchors.horizontalCenter: parent.horizontalCenter
            y: 40
            width: shotHintRow.implicitWidth + 32; height: 40; radius: 20
            color: globalState.glassMode ? ga(pal.surfaceHigh, 0.92) : pal.surfaceHigh
            opacity: shot.fade
            Row {
                id: shotHintRow
                anchors.centerIn: parent
                spacing: 8
                Text { anchors.verticalCenter: parent.verticalCenter; text: ""; font.family: "Material Symbols Rounded"; font.pixelSize: 18; color: pal.primary }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: tr("shot_pick_hint")
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                    color: pal.colorOnSurface
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: true
            cursorShape: shot.phase === "select" ? Qt.CrossCursor
            : (inCanvas(mouseX, mouseY) ? (globalState.shotTool === "text" ? Qt.IBeamCursor : Qt.CrossCursor) : Qt.ArrowCursor)
            function inCanvas(px, py) { return px >= shot.sx && py >= shot.sy && px <= shot.sx + shot.sw && py <= shot.sy + shot.sh; }
            onPressed: (m) => {
                if (m.button === Qt.RightButton) { if (shot.phase === "select") shot.cancel(); else shot.undo(); return; }
                if (shot.phase === "select") {
                    shot.x0 = shot.x1 = m.x; shot.y0 = shot.y1 = m.y;
                    shot.dragging = true; shot.has = true;
                    return;
                }
                if (!inCanvas(m.x, m.y)) { shot.commitText(); return; }
                var lx = m.x - shot.sx, ly = m.y - shot.sy;
                if (globalState.shotTool === "text") { shot.beginText(lx, ly - shot.textSizes[globalState.shotSizeIdx] * 0.6); return; }
                shot.commitText();
                shot.curPts = [Qt.point(lx, ly), Qt.point(lx + 0.01, ly + 0.01)];
                shot.drawing = true;
            }
            onPositionChanged: (m) => {
                if (shot.phase === "select") {
                    if (!shot.dragging) return;
                    shot.x1 = Math.max(0, Math.min(shot.width, m.x));
                    shot.y1 = Math.max(0, Math.min(shot.height, m.y));
                    return;
                }
                if (!shot.drawing) return;
                var lx = m.x - shot.sx, ly = m.y - shot.sy;
                var p = shot.curPts, last = p[p.length - 1];
                if (Math.abs(last.x - lx) + Math.abs(last.y - ly) < 1.5) return;
                shot.curPts = p.concat([Qt.point(lx, ly)]);
            }
            onReleased: (m) => {
                if (m.button !== Qt.LeftButton) return;
                if (shot.phase === "select") {
                    if (!shot.dragging) return;
                    shot.dragging = false;
                    if (shot.sw < 6 || shot.sh < 6) shot.selectAll();
                    else shot.enterEdit();
                    return;
                }
                if (!shot.drawing) return;
                shot.drawing = false;
                shot.strokes = shot.strokes.concat([{ c: shot.curColor.toString(), w: shot.sizes[globalState.shotSizeIdx], pts: shot.curPts }]);
                shot.history = shot.history.concat(["s"]);
                shot.curPts = [];
            }
        }

        ScreenshotToolbar {}
    }
}
