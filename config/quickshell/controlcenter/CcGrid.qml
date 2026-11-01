import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../controlcenter"
import "../ui"

// Control Center tile grid: sliders and toggles
Item {
    id: ncCcGrid
    implicitHeight: ncCcRowsCol.implicitHeight
    BumpCtl { id: ncCcBump }
    CcTiles { id: ncTiles }

    readonly property real sp: 8
    readonly property real rowGap: 10
    readonly property var info: ({
        bright: { icon: "", name: tr("nce_bright") },
        vol:    { icon: "", name: tr("nce_vol") },
        mic:    { icon: "", name: tr("nce_mic") },
        wifi:   { icon: "", name: tr("wifi") },
        bt:     { icon: "", name: tr("bluetooth") },
        dark:   { icon: "", name: tr("nce_dark") },
        dnd:    { icon: "", name: tr("dnd") },
        term:   { icon: "", name: "Terminal" },
        shot:   { icon: "", name: tr("take_screenshot") },
        rec:    { icon: "\ue061", name: tr("screen_record") },
        perf:   { icon: "\ue9e4", name: tr("nce_perf") },
        saver:  { icon: "\uefde", name: tr("nce_saver") },
        plane:  { icon: "\ue539", name: tr("nce_plane") },
        eye:    { icon: "\ue8f4", name: tr("nce_eye") }
    })
    function compFor(k) { return ncTiles.compFor(k); }
    function minPx(k) { return globalState.ncCcIsSlider(k) ? 110 : 52; }

    property int  resizeRow: -1
    property int  resizeIdx: -1
    property real resizeA: 1
    property real resizeB: 1
    readonly property real snapDist: 10
    property var  snapXs: []
    property real snapActive: -1
    function computeSnaps(r) {
        var W = width, out = [];
        for (var m = 2; m <= 6; m++) {
            var cwm = (W - (m - 1) * sp) / m;
            for (var k = 1; k < m; k++) out.push(k * cwm + (k - 1) * sp + sp / 2);
        }
        for (var ro = 0; ro < ncCcRowsCol.ncCcRowRep.count; ro++) {
            if (ro === r) continue;
            var it = rowItem(ro);
            if (!it) continue;
            for (var j = 1; j < it.modelData.length; j++) out.push(it.cx(j) - sp / 2);
        }
        out.sort(function (a, b) { return a - b; });
        var dd = [];
        for (var q = 0; q < out.length; q++)
        if (!dd.length || out[q] - dd[dd.length - 1] > 3) dd.push(out[q]);
        return dd;
    }
    function weightFor(r, i, w) {
        if (r === resizeRow) {
            if (i === resizeIdx) return resizeA;
            if (i === resizeIdx + 1) return resizeB;
        }
        return w;
    }

    property string dragKey: ""
    property real dragX: 0
    property real dragY: 0
    property real grabX: 0
    property real grabY: 0
    property real dragW: 0
    property real dragH: 0
    property int  dropRow: -1
    property int  dropIndex: 0
    property bool dropNew: false
    property real indX: 0
    property real indY: 0
    property real indW: 0
    property real indH: 0
    function rowItem(r) { return ncCcRowsCol.ncCcRowRep.itemAt(r); }
    function beginDrag(k, w, h, gx, gy) {
        dragKey = k; dragW = w; dragH = h; grabX = gx; grabY = gy;
    }
    function setNewRowDrop(r) {
        var n = ncCcRowsCol.ncCcRowRep.count;
        dropNew = true; dropRow = r; dropIndex = 0;
        var y;
        if (n === 0) y = 0;
        else if (r < n) y = rowItem(r).y - rowGap / 2;
        else { var last = rowItem(n - 1); y = last.y + last.height + rowGap / 2; }
        indX = 0; indW = width; indH = 4;
        indY = Math.max(0, Math.min(height - indH, y - indH / 2));
    }
    function setIntoRowDrop(r, it, px) {
        var cells = it.cellsExcept(dragKey);
        var idx = 0;
        for (var i = 0; i < cells.length; i++) if (cells[i].x + cells[i].w / 2 < px) idx = i + 1;
        dropNew = false; dropRow = r; dropIndex = idx;
        indY = it.y; indH = it.height; indW = 4;
        var x;
        if (cells.length === 0) x = it.width / 2;
        else if (idx < cells.length) x = cells[idx].x - sp / 2;
        else x = cells[cells.length - 1].x + cells[cells.length - 1].w + sp / 2;
        indX = Math.max(0, Math.min(width - indW, x - indW / 2));
    }
    function moveDrag(px, py) {
        dragX = px; dragY = py;
        var n = ncCcRowsCol.ncCcRowRep.count;
        if (n === 0) { setNewRowDrop(0); return; }
        for (var r = 0; r < n; r++) {
            var it = rowItem(r);
            if (!it) continue;
            var edge = Math.min(14, it.height * 0.28);
            if (py < it.y + edge) {
                if (canNewRow) setNewRowDrop(r); else setIntoRowDrop(r, it, px);
                return;
            }
            if (py <= it.y + it.height - edge) { setIntoRowDrop(r, it, px); return; }
        }
        if (canNewRow) setNewRowDrop(n);
        else setIntoRowDrop(n - 1, rowItem(n - 1), px);
    }
    readonly property bool canNewRow: {
        var rows = globalState.ncCcRows;
        if (rows.length < globalState.ncCcMaxRows) return true;
        var p = dragKey !== "" ? globalState.ncCcFind(rows, dragKey) : null;
        return !!p && rows[p.r].length === 1;
    }
    function endDrag(commit) {
        var k = dragKey, r = dropRow, i = dropIndex, nw = dropNew;
        dragKey = ""; dropRow = -1;
        if (commit && k !== "" && r >= 0) Qt.callLater(function () { globalState.ncCcDrop(k, r, i, nw); });
    }

    Text {
        visible: globalState.ncCcRows.length === 0
        anchors.left: parent.left; anchors.right: parent.right
        height: 56
        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
        text: globalState.ncEditMode ? tr("nce_empty_edit") : tr("nce_empty")
        font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale)
        color: pal.colorOnSurfVar
    }

    CcGridRows { id: ncCcRowsCol }

    Repeater {
        model: ncCcGrid.resizeRow >= 0 ? ncCcGrid.snapXs : []
        Item {
            id: ncCcGuide
            required property real modelData
            readonly property bool hot: Math.abs(ncCcGrid.snapActive - modelData) < 0.5
            x: Math.round(modelData) - 1
            y: 0
            width: 2
            height: ncCcGrid.height
            z: 4
            Rectangle {
                anchors.fill: parent
                visible: ncCcGuide.hot
                radius: 1
                color: pal.primary
            }
            Column {
                visible: !ncCcGuide.hot
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 5
                Repeater {
                    model: Math.max(0, Math.floor(ncCcGuide.height / 7))
                    Rectangle { width: 2; height: 2; radius: 1; color: ga(pal.primary, 0.55) }
                }
            }
        }
    }

    Rectangle {
        visible: ncCcGrid.dragKey !== "" && ncCcGrid.dropRow >= 0
        x: ncCcGrid.indX; y: ncCcGrid.indY
        width: ncCcGrid.indW; height: ncCcGrid.indH
        radius: 2
        color: pal.primary
        z: 8
    }
    Rectangle {
        visible: ncCcGrid.dragKey !== ""
        z: 9
        x: ncCcGrid.dragX - ncCcGrid.grabX
        y: ncCcGrid.dragY - ncCcGrid.grabY
        width: ncCcGrid.dragW
        height: ncCcGrid.dragH
        radius: Math.min(18, height / 2)
        color: globalState.glassMode ? ga(pal.primaryCont, 0.9) : pal.primaryCont
        border.width: 2
        border.color: pal.primary
        opacity: 0.92
        RowLayout {
            anchors.centerIn: parent
            width: Math.min(implicitWidth, parent.width - 12)
            spacing: 6
            FadeIcon {
                text: ncCcGrid.info[ncCcGrid.dragKey] ? ncCcGrid.info[ncCcGrid.dragKey].icon : ""
                font.family: "Material Symbols Rounded"; font.pixelSize: 20; color: pal.primary
            }
            Text {
                Layout.fillWidth: true
                text: ncCcGrid.info[ncCcGrid.dragKey] ? ncCcGrid.info[ncCcGrid.dragKey].name : ""
                elide: Text.ElideRight
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                color: pal.colorOnSurface
            }
        }
    }
}
