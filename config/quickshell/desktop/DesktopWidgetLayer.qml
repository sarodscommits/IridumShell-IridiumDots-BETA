import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../widgets"
import "../panels"
import "WidgetTypes.js" as WT
import "../ui/SvgPaths.js" as SvgPaths

// Desktop widget layer: widgets, grid, edit mode and parallax
PanelWindow {
    id: desktopWidgetLayer
    property alias bigTimeWidgetRoot: bigTimeWidgetRoot
    property alias calDetailWidgetRoot: calDetailWidgetRoot
    property alias calWidgetRootDesktop: calWidgetRootDesktop
    property alias chargeWidgetRoot: chargeWidgetRoot
    property alias clockDetailWidgetRoot: clockDetailWidgetRoot
    property alias clockWidgetRootDesktop: clockWidgetRootDesktop
    property alias countdownWidgetRoot: countdownWidgetRoot
    property alias cpuWidgetRoot: cpuWidgetRoot
    property alias dateWidgetRoot: dateWidgetRoot
    property alias diskWidgetRoot: diskWidgetRoot
    property alias gpuWidgetRoot: gpuWidgetRoot
    property alias lyricsBubbleWidgetRoot: lyricsBubbleWidgetRoot
    property alias lyricsCardWidgetRoot: lyricsCardWidgetRoot
    property alias lyricsLineWidgetRoot: lyricsLineWidgetRoot
    property alias mediaPillWidgetRoot: mediaPillWidgetRoot
    property alias musicWidgetRoot: musicWidgetRoot
    property alias ramWidgetRoot: ramWidgetRoot
    property alias sysWidgetRoot: sysWidgetRoot
    property alias weatherDetailWidgetRoot: weatherDetailWidgetRoot
    property alias weatherPillsWidgetRoot: weatherPillsWidgetRoot
    property alias weatherWidgetRoot: weatherWidgetRoot
    WlrLayershell.namespace: "quickshell:desktop-widgets"
    WlrLayershell.layer: globalState.desktopEditMode ? WlrLayer.Overlay : WlrLayer.Bottom
    anchors.top:    true
    anchors.bottom: true
    anchors.left:   true
    anchors.right:  true
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    readonly property bool editMenuOnRight: unifiedFrame.barAtLeft
    property real editPreviewReservedRight: editMenuOnRight ? 348 : (unifiedFrame.barAtRight ? 40 + unifiedFrame.topBaseH : 40)
    property real editPreviewReservedLeft:  editMenuOnRight ? 40 + unifiedFrame.topBaseH : 348
    Behavior on editPreviewReservedRight { NumberAnimation { duration: 420; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasized } }
    Behavior on editPreviewReservedLeft  { NumberAnimation { duration: 420; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasized } }
    readonly property real editPreviewOuterPad: 40
    readonly property real editPreviewTopBarBlockH: 50
    readonly property real editPreviewMaxW: Math.max(200, width  - editPreviewReservedRight - editPreviewReservedLeft - editPreviewOuterPad)
    readonly property real editPreviewMaxH: Math.max(150, height - editPreviewTopBarBlockH - editPreviewOuterPad * 2)
    readonly property real editPreviewScale: Math.min(editPreviewMaxW / width, editPreviewMaxH / height)
    readonly property real editPreviewBoxW: width  * editPreviewScale
    readonly property real editPreviewBoxH: height * editPreviewScale
    readonly property real editPreviewBoxX: editPreviewReservedLeft + (width - editPreviewBoxW - editPreviewReservedLeft - editPreviewReservedRight) / 2
    readonly property real editPreviewBoxY: (height - editPreviewTopBarBlockH - editPreviewBoxH) / 2 + editPreviewTopBarBlockH
    property real editT: globalState.desktopEditMode ? 1 : 0
    Behavior on editT { NumberAnimation { duration: 460; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasizedDecelerate } }
    readonly property real animScale: 1 + (editPreviewScale - 1) * editT
    readonly property real animBoxX: editPreviewBoxX * editT
    readonly property real animBoxY: (editPreviewBoxY + editEnterOffset) * editT
    readonly property real widgetBoxX: animBoxX + parallaxLayer.wOffX * (1 - editT)
    readonly property real widgetBoxY: animBoxY + parallaxLayer.wOffY * (1 - editT)
    property real editEnterOffset: 0
    property real editEnterOpacity: 1
    readonly property real editMenuSlideFrom: -18
    property real editMenuOffset: 0
    ParallelAnimation {
        id: editEnterAnim
        NumberAnimation { target: desktopWidgetLayer; property: "editEnterOffset"; from: 46; to: 0; duration: 520; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasizedDecelerate }
        NumberAnimation { target: desktopWidgetLayer; property: "editEnterOpacity"; from: 0; to: 1; duration: 320; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasizedDecelerate }
        NumberAnimation { target: desktopWidgetLayer; property: "editMenuOffset"; from: desktopWidgetLayer.editMenuSlideFrom; to: 0; duration: 420; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasizedDecelerate }
    }
    Connections {
        target: globalState
        function onDesktopEditModeChanged() {
            if (globalState.desktopEditMode) editEnterAnim.restart();
            else { editEnterAnim.stop(); desktopWidgetLayer.editEnterOffset = 0; desktopWidgetLayer.editEnterOpacity = 1; desktopWidgetLayer.editMenuOffset = 0; }
        }
    }

    mask: Region { item: !globalState.desktopEditMode ? desktopEmptyClickArea : null }

    readonly property real gridCell: 55
    readonly property real widgetGap: 8

    property real desktopGaugeWavePhase: 0
    Timer {
        interval: 40
        repeat: true
        running: (globalState.cpuWidgetEnabled || globalState.ramWidgetEnabled || globalState.diskWidgetEnabled) && !globalState.lockScreenActive && !globalState.wpFullscreenActive
        onTriggered: desktopWidgetLayer.desktopGaugeWavePhase = (desktopWidgetLayer.desktopGaugeWavePhase + 0.10) % (Math.PI * 2)
    }
    property var gridWidgets: WT.gridOrder.map(function (t) {
        return { item: desktopWidgetLayer[WT.rootName(t)], xProp: WT.prop(t, "X"), yProp: WT.prop(t, "Y"), enabledProp: WT.prop(t, "Enabled") };
    })
    property Item draggingWidget: null
    onDraggingWidgetChanged: {
        if (draggingWidget !== null) globalState.wdDeclutterAll();
        else if (!globalState.desktopEditMode) globalState.wdRestoreAll();
    }

    function gridSpanFor(item) {
        var w = item.width, h = item.height;
        for (var i = 0; i < gridWidgets.length; i++) {
            if (gridWidgets[i].item === item && gridWidgets[i].footprintW) {
                w = gridWidgets[i].footprintW; h = gridWidgets[i].footprintH;
                break;
            }
        }
        return { cols: Math.max(1, Math.ceil(w / gridCell)), rows: Math.max(1, Math.ceil(h / gridCell)) };
    }
    function gridCols() { return Math.max(1, Math.floor(width / gridCell)); }
    function gridRows() { return Math.max(1, Math.floor(height / gridCell)); }
    function rectsOverlap(c1, r1, cols1, rows1, c2, r2, cols2, rows2) {
        return c1 < c2 + cols2 && c1 + cols1 > c2 && r1 < r2 + rows2 && r1 + rows1 > r2;
    }
    function otherGridWidgets(exclude) {
        return gridWidgets.filter(function (gw) {
            return gw.item !== exclude && globalState[gw.enabledProp];
        });
    }
    function currentCellRect(item) {
        var span = gridSpanFor(item);
        return { col: Math.round(item.x / gridCell), row: Math.round(item.y / gridCell), cols: span.cols, rows: span.rows };
    }
    function overlappingWidgets(rect, exclude) {
        var hits = [];
        var others = otherGridWidgets(exclude);
        for (var i = 0; i < others.length; i++) {
            var r = currentCellRect(others[i].item);
            if (rectsOverlap(rect.col, rect.row, rect.cols, rect.rows, r.col, r.row, r.cols, r.rows)) hits.push(others[i]);
        }
        return hits;
    }

    function gridTargetFor(item) {
        var span = gridSpanFor(item);
        var maxCol = Math.max(0, gridCols() - span.cols);
        var maxRow = Math.max(0, gridRows() - span.rows);
        return {
            col: Math.min(maxCol, Math.max(0, Math.round(item.x / gridCell))),
            row: Math.min(maxRow, Math.max(0, Math.round(item.y / gridCell))),
            cols: span.cols, rows: span.rows
        };
    }

    function nearestFreeCell(span, aroundCol, aroundRow, exclude) {
        var maxCol = gridCols() - span.cols, maxRow = gridRows() - span.rows;
        if (maxCol < 0 || maxRow < 0) return { col: 0, row: 0 };
        var others = otherGridWidgets(exclude).map(function (gw) { return currentCellRect(gw.item); });
        var best = null, bestDist = Infinity;
        for (var col = 0; col <= maxCol; col++) {
            for (var row = 0; row <= maxRow; row++) {
                var free = true;
                for (var i = 0; i < others.length; i++) {
                    var r = others[i];
                    if (rectsOverlap(col, row, span.cols, span.rows, r.col, r.row, r.cols, r.rows)) { free = false; break; }
                }
                if (!free) continue;
                var d = Math.hypot(col - aroundCol, row - aroundRow);
                if (d < bestDist) { bestDist = d; best = { col: col, row: row }; }
            }
        }
        return best || { col: Math.min(Math.max(0, aroundCol), maxCol), row: Math.min(Math.max(0, aroundRow), maxRow) };
    }

    function snapDesktopWidget(dragged, origX, origY) {
        var span = gridSpanFor(dragged);
        var maxCol = Math.max(0, gridCols() - span.cols), maxRow = Math.max(0, gridRows() - span.rows);
        var col = Math.min(maxCol, Math.max(0, Math.round(dragged.x / gridCell)));
        var row = Math.min(maxRow, Math.max(0, Math.round(dragged.y / gridCell)));
        var origCol = Math.round(origX / gridCell), origRow = Math.round(origY / gridCell);

        var hits = overlappingWidgets({ col: col, row: row, cols: span.cols, rows: span.rows }, dragged);

        if (hits.length === 0) {
            dragged.x = col * gridCell; dragged.y = row * gridCell;
            return;
        }

        if (hits.length === 1) {
            var other = hits[0];
            var otherSpan = gridSpanFor(other.item);
            var otherMaxCol = Math.max(0, gridCols() - otherSpan.cols), otherMaxRow = Math.max(0, gridRows() - otherSpan.rows);
            var oc = Math.min(otherMaxCol, Math.max(0, origCol)), or_ = Math.min(otherMaxRow, Math.max(0, origRow));
            var otherHits = overlappingWidgets({ col: oc, row: or_, cols: otherSpan.cols, rows: otherSpan.rows }, other.item)
            .filter(function (h) { return h.item !== dragged; });
            if (otherHits.length === 0) {
                other.item.x = oc * gridCell; other.item.y = or_ * gridCell;
                globalState[other.xProp] = other.item.x; globalState[other.yProp] = other.item.y;
                dragged.x = col * gridCell; dragged.y = row * gridCell;
                return;
            }
        }

        var free = nearestFreeCell(span, col, row, dragged);
        dragged.x = free.col * gridCell;
        dragged.y = free.row * gridCell;
    }

    Item {
        id: desktopEmptyClickArea
        anchors.fill: parent
        MouseArea {
            id: desktopEmptyRightClick
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            onPressed: (mouse) => {
                if (globalState.lockScreenActive || globalState.desktopEditMode) return;
                desktopEmptyContextMenu.openAt(mouse.x, mouse.y);
            }
        }
    }

    DesktopCavaVis {
        anchors.fill: parent
        visible: globalState.desktopCavaEnabled && globalState.desktopEditMode
    }

    DesktopSnapPreview { id: desktopSnapPreview }

    DesktopMusicWidget { id: musicWidgetRoot }

    DesktopWeatherWidget { id: weatherWidgetRoot }

    DesktopClockWidget { id: clockWidgetRootDesktop }

    DesktopCalendarWidget { id: calWidgetRootDesktop }

    ClockDetailWidget { id: clockDetailWidgetRoot }

    WeatherDetailWidget { id: weatherDetailWidgetRoot }

    CalendarDetailWidget { id: calDetailWidgetRoot }

    MetricGaugeWidget { id: cpuWidgetRoot; key: "cpu"; percent: globalState.cpuPercent; gw: 80.86; gh: 78.3; gx: 9.57; gy: 8.11
        shapePath: SvgPaths.pentagon }

    MetricGaugeWidget { id: ramWidgetRoot; key: "ram"; percent: globalState.ramPercent; gw: 80; gh: 80; gx: 10; gy: 10
        shapePath: SvgPaths.arch }

    MetricGaugeWidget { id: diskWidgetRoot; key: "disk"; percent: globalState.diskPercent; gw: 76.06; gh: 76.08; gx: 11.98; gy: 11.96
        shapePath: SvgPaths.flower }

    readonly property color exprDark: globalState.glassMode ? ga(containerDark(pal.secondaryCont), currentFrameOpacity()) : containerDark(pal.secondaryCont)

    SysWidget { id: sysWidgetRoot }

    GpuWidget { id: gpuWidgetRoot }

    ChargeWidget { id: chargeWidgetRoot }

    DateWidget { id: dateWidgetRoot }

    BigTimeWidget { id: bigTimeWidgetRoot }

    MediaPillWidget { id: mediaPillWidgetRoot }

    CountdownWidget { id: countdownWidgetRoot }

    WeatherPillsWidget { id: weatherPillsWidgetRoot }

    LyricsCardWidget { id: lyricsCardWidgetRoot }

    LyricsLineWidget { id: lyricsLineWidgetRoot }

    LyricsBubbleWidget { id: lyricsBubbleWidgetRoot }
}
