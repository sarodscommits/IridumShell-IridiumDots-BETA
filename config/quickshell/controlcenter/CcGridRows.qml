import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Editable rows of the Control Center grid
ColumnLayout {
    id: ncCcRowsCol
    property alias ncCcRowRep: ncCcRowRep
    anchors.fill: parent
    spacing: ncCcGrid.rowGap

    Repeater {
        id: ncCcRowRep
        model: globalState.ncCcRows
        Item {
            id: ncCcRow
            required property var modelData
            required property int index
            readonly property int rowIndex: index
            readonly property bool hasButton: {
                for (var i = 0; i < modelData.length; i++) if (!globalState.ncCcIsSlider(modelData[i].k)) return true;
                return false;
            }
            readonly property var weights: {
                var o = [];
                for (var i = 0; i < modelData.length; i++) o.push(ncCcGrid.weightFor(rowIndex, i, modelData[i].w));
                return o;
            }
            readonly property real wSum: { var s = 0; for (var i = 0; i < weights.length; i++) s += weights[i]; return s > 0 ? s : 1; }
            readonly property real avail: Math.max(0, width - ncCcGrid.sp * Math.max(0, modelData.length - 1))
            function cx(i) { var s = 0; for (var j = 0; j < i; j++) s += weights[j]; return s / wSum * avail + i * ncCcGrid.sp; }
            function cw(i) { return weights[i] / wSum * avail; }
            function cellsExcept(k) {
                var out = [];
                for (var i = 0; i < ncCcCellRep.count; i++) {
                    var c = ncCcCellRep.itemAt(i);
                    if (c && c.key !== k) out.push({ x: c.x, w: c.width });
                }
                return out;
            }
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: hasButton ? 56 : 40
            implicitHeight: hasButton ? 56 : 40

            Repeater {
                id: ncCcCellRep
                model: ncCcRow.modelData
                Item {
                    id: ncCcCell
                    required property var modelData
                    required property int index
                    readonly property string key: modelData.k
                    readonly property bool dragging: ncCcGrid.dragKey === key
                    x: ncCcBump.val !== 0 ? ncCcRow.cx(index) + ncCcBump.dx(index, ncCcRow.rowIndex) : Math.round(ncCcRow.cx(index))
                    width: ncCcBump.val !== 0 ? Math.max(0, ncCcRow.cw(index) + ncCcBump.dw(index, ncCcRow.modelData.length, ncCcRow.rowIndex)) : Math.round(ncCcRow.cw(index))
                    height: ncCcRow.height

                    Item {
                        anchors.fill: parent
                        z: 2
                        PointHandler {
                            enabled: !globalState.ncEditMode && !globalState.ncCcIsSlider(ncCcCell.key)
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onActiveChanged: if (active) ncCcBump.bump(ncCcCell.index, ncCcRow.rowIndex)
                        }
                    }

                    Loader {
                        anchors.fill: parent
                        property string ctlKey: ncCcCell.key
                        enabled: !globalState.ncEditMode
                        opacity: ncCcCell.dragging ? 0.25 : (globalState.ncEditMode ? 0.75 : 1)
                        Behavior on opacity { M3NumberAnim { duration: m3.durFast } }
                        sourceComponent: ncCcGrid.compFor(ncCcCell.key)
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -3
                        visible: globalState.ncEditMode
                        radius: Math.min(16, height / 2)
                        color: (ncCcEditHov.hovered && ncCcGrid.dragKey === "" && ncCcGrid.resizeRow < 0) ? ga(pal.primary, 0.10) : "transparent"
                        border.width: 1
                        border.color: ga(pal.colorOnSurfVar, ncCcCell.dragging ? 0.2 : 0.45)
                        Behavior on color { M3ColorAnim { duration: m3.durFast } }
                        HoverHandler { id: ncCcEditHov }
                        MouseArea {
                            anchors.fill: parent
                            preventStealing: true
                            cursorShape: ncCcCell.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                            property real sx: 0
                            property real sy: 0
                            onPressed: (m) => { sx = m.x; sy = m.y; }
                            onPositionChanged: (m) => {
                                if (!pressed) return;
                                if (ncCcGrid.dragKey === "") {
                                    if (Math.abs(m.x - sx) + Math.abs(m.y - sy) < 6) return;
                                    var o = mapToItem(ncCcCell, sx, sy);
                                    ncCcGrid.beginDrag(ncCcCell.key, ncCcCell.width, ncCcCell.height, o.x, o.y);
                                }
                                var g = mapToItem(ncCcGrid, m.x, m.y);
                                ncCcGrid.moveDrag(g.x, g.y);
                            }
                            onReleased: ncCcGrid.endDrag(true)
                            onCanceled: ncCcGrid.endDrag(false)
                        }
                        PressIconButton {
                            visible: !ncCcCell.dragging
                            width: 20
                            height: 20
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.topMargin: -6
                            anchors.rightMargin: -6
                            border.width: 2
                            border.color: globalState.glassMode ? ga(pal.surface, currentFrameOpacity()) : pal.surface
                            cornerRadius: 10
                            icon: ""
                            iconSize: 12
                            iconColor: "white"
                            hoverColor: Qt.lighter(pal.error, 1.15)
                            idleColor: pal.error
                            hitMargin: -3
                            onClicked: globalState.ncCcRemove(ncCcCell.key)
                        }
                    }
                }
            }

            Repeater {
                model: globalState.ncEditMode ? Math.max(0, ncCcRow.modelData.length - 1) : 0
                Item {
                    id: ncCcSplit
                    required property int index
                    visible: ncCcGrid.dragKey === ""
                    x: Math.round(ncCcRow.cx(index + 1) - ncCcGrid.sp / 2 - width / 2)
                    width: 16
                    height: ncCcRow.height
                    z: 5
                    readonly property bool active: ncCcGrid.resizeRow === ncCcRow.rowIndex && ncCcGrid.resizeIdx === index
                    Rectangle {
                        anchors.centerIn: parent
                        width: ncCcSplit.active || ncCcSplitHov.hovered ? 5 : 3
                        height: Math.min(parent.height - 8, ncCcSplit.active ? 34 : 24)
                        radius: width / 2
                        color: pal.primary
                        opacity: ncCcSplit.active ? 1 : (ncCcSplitHov.hovered ? 0.9 : 0.45)
                        Behavior on width { M3SpringAnim { token: "spatialFast" } }
                        Behavior on height { M3SpringAnim { token: "spatialFast" } }
                    }
                    HoverHandler { id: ncCcSplitHov; cursorShape: Qt.SizeHorCursor }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.SizeHorCursor
                        preventStealing: true
                        property real sx: 0
                        property real wA: 1
                        property real wB: 1
                        property real pA: 0
                        property real pB: 0
                        onPressed: (m) => {
                            sx = mapToItem(ncCcRow, m.x, 0).x;
                            ncCcGrid.snapXs = ncCcGrid.computeSnaps(ncCcRow.rowIndex);
                            ncCcGrid.snapActive = -1;
                            var i = ncCcSplit.index;
                            wA = ncCcRow.modelData[i].w; wB = ncCcRow.modelData[i + 1].w;
                            pA = ncCcRow.cw(i); pB = ncCcRow.cw(i + 1);
                            ncCcGrid.resizeA = wA; ncCcGrid.resizeB = wB;
                            ncCcGrid.resizeIdx = i; ncCcGrid.resizeRow = ncCcRow.rowIndex;
                        }
                        onPositionChanged: (m) => {
                            if (!pressed || ncCcGrid.resizeRow < 0) return;
                            var i = ncCcSplit.index;
                            var dx = mapToItem(ncCcRow, m.x, 0).x - sx;
                            var tot = pA + pB;
                            var minA = ncCcGrid.minPx(ncCcRow.modelData[i].k);
                            var minB = ncCcGrid.minPx(ncCcRow.modelData[i + 1].k);
                            if (minA + minB > tot) { minA = tot * minA / (minA + minB); minB = tot - minA; }
                            var a = Math.max(minA, Math.min(tot - minB, pA + dx));
                            var base = ncCcRow.cx(i) + ncCcGrid.sp / 2;
                            var bx = base + a, best = -1, bestD = ncCcGrid.snapDist;
                            for (var q = 0; q < ncCcGrid.snapXs.length; q++) {
                                var sxq = ncCcGrid.snapXs[q], d = Math.abs(sxq - bx);
                                var aq = sxq - base;
                                if (d <= bestD && aq >= minA && aq <= tot - minB) { best = sxq; bestD = d; }
                            }
                            if (best >= 0) a = best - base;
                            ncCcGrid.snapActive = best;
                            var wt = wA + wB;
                            ncCcGrid.resizeA = wt * a / tot;
                            ncCcGrid.resizeB = wt - ncCcGrid.resizeA;
                        }
                        function finish(commit) {
                            var r = ncCcGrid.resizeRow, i = ncCcGrid.resizeIdx, a = ncCcGrid.resizeA, b = ncCcGrid.resizeB;
                            ncCcGrid.snapXs = []; ncCcGrid.snapActive = -1;
                            if (r < 0) return;
                            if (!commit) { ncCcGrid.resizeRow = -1; return; }
                            Qt.callLater(function () {
                                globalState.ncCcSetWeights(r, i, a, b);
                                ncCcGrid.resizeRow = -1;
                            });
                        }
                        onReleased: finish(true)
                        onCanceled: finish(false)
                    }
                }
            }
        }
    }
}
