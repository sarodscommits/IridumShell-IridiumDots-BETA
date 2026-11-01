import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.Notifications
import ".."
import "../ui"
import "../widgets"
import "../settings"
import "../panels"
import "FramePath.js" as FramePath
import "../leftpanel"
import "../rightpanel"
import "../ui/SvgPaths.js" as SvgPaths
import "../controlcenter"
import "../bar"

// Unified frame window: bar, side panels, island and bulge popups
PanelWindow {
    id: unifiedFrame
    property alias ccGridComp: topBarContent.ccGridComp
    property alias ccMediaCardComp: topBarContent.ccMediaCardComp
    property alias ccOverviewComp: topBarContent.ccOverviewComp
    property alias ccTrayComp: topBarContent.ccTrayComp
    property alias perfMorphComp: topBarContent.perfMorphComp
    property alias btPromptFocusTimer: btPromptFocusTimer
    property alias cavaTimer: rightPanelContent.cavaTimer
    property alias desktopEmptyContextMenu: desktopEmptyContextMenu
    property alias frameRoot: frameRoot
    property alias islandAutoHideHideTimer: topBarContent.islandAutoHideHideTimer
    property alias islandControlLoader: topBarContent.islandControlLoader
    property alias mediaPanel: rightPanelContent.mediaPanel
    property alias ncSideHitArea: ncSideHitArea
    property alias ncSideHitHover: ncSideHitHover
    property alias topBarHover: topBarContent.topBarHover
    property alias wifiPasswordFocusTimer: wifiPasswordFocusTimer
    WlrLayershell.namespace: "quickshell"
    WlrLayershell.layer: globalState.desktopEditMode ? WlrLayer.Overlay : WlrLayer.Top

    anchors.top:    true
    anchors.bottom: true
    anchors.left:   true
    anchors.right:  true

    color: "transparent"

    property bool startupSettled: false
    Timer {
        interval: 1200
        running: true
        repeat: false
        onTriggered: unifiedFrame.startupSettled = true
    }

    exclusionMode: ExclusionMode.Ignore

    readonly property real zoomK: 1 / Math.max(0.05, globalState.desktopZoom)
    readonly property real contentW: width / zoomK
    readonly property real contentH: height / zoomK
    onZoomKChanged: Qt.callLater(function() { if (unifiedFrame.mask) unifiedFrame.mask.changed() })

    readonly property real topBaseH:  36 + 14 + 4
    readonly property real islandAutoHideSensorH: 2
    readonly property real edgeBaseSize: 0
    readonly property real edgeHoverWidth: 14

    readonly property var islandControlPageH: [420, 700, 420, 400]
    readonly property real notchPanelTargetH: 690
    readonly property real notchPanelLeftX:  barVertical ? frameShape.width * 0.07 : frameShape.width / 6
    readonly property real notchPanelRightX: barVertical ? frameShape.width * 0.93 : frameShape.width * 5 / 6
    readonly property bool rightPanelEnabled: false
    property var wifiPromptFieldRef: null
    property var btPromptFieldRef: null
    readonly property var islandControlPageHv: [680, 760, 560, 640]
    readonly property var islandControlPageWv: [620, 640, 520, 620]
    readonly property real islandControlExtraH: (barVertical ? islandControlPageHv : islandControlPageH)[Math.min(globalState.islandControlPage, islandControlPageH.length - 1)]
    readonly property real islandSearchRowH: 34
    readonly property int searchResultCountRaw: globalState.searchMode === "files"
    ? globalState.fileSearchResults.length
    : (leftPanelContent.leftLauncherCard ? leftPanelContent.leftLauncherCard.filteredApps.length : 0)
    // Sizes the search popup: grows at once, shrinks after a delay so it doesn't flap between keystrokes
    property int islandSearchResultCount: 0
    property bool searchResultsHovered: false
    property Item islandSearchResultsItem: null
    function syncSearchCount(force) {
        var raw = searchResultCountRaw;
        if (force || raw >= islandSearchResultCount) { searchShrinkTimer.stop(); islandSearchResultCount = raw; }
        else searchShrinkTimer.restart();
    }
    onSearchResultCountRawChanged: syncSearchCount(false)
    Timer {
        id: searchShrinkTimer
        interval: 90
        repeat: false
        onTriggered: {
            // Keep a hover area where the bulge was so the search doesn't close mid-typing
            if (unifiedFrame.searchResultsHovered) unifiedFrame.armSearchCatcher();
            unifiedFrame.islandSearchResultCount = unifiedFrame.searchResultCountRaw;
        }
    }
    Connections {
        target: globalState
        function onIslandSearchOpenChanged() {
            if (globalState.islandSearchOpen) unifiedFrame.syncSearchCount(true);
            else { unifiedFrame.searchResultsHovered = false; unifiedFrame.searchCatchOn = false; }
        }
        function onNotchSearchOpenChanged() {
            if (globalState.notchSearchOpen) unifiedFrame.syncSearchCount(true);
            else { unifiedFrame.searchResultsHovered = false; unifiedFrame.searchCatchOn = false; }
        }
    }

    // Invisible hover catcher over the pre-shrink bulge; cleared when the mouse re-enters results or leaves
    property bool searchCatchOn: false
    readonly property bool searchCatcherHovered: searchCatchOn && searchCatcherHover.hovered
    function armSearchCatcher() {
        var it = globalState.notchSearchOpen ? notchSearchPopup
               : globalState.islandSearchOpen ? islandSearchResultsItem : null;
        if (!it || it.width < 1 || it.height < 1) return;
        var r = it.mapToItem(null, 0, 0, it.width, it.height);
        if (searchCatchOn) {
            // keep the union with the area already caught
            var x1 = Math.min(searchCatcher.x, r.x), y1 = Math.min(searchCatcher.y, r.y);
            var x2 = Math.max(searchCatcher.x + searchCatcher.width, r.x + r.width);
            var y2 = Math.max(searchCatcher.y + searchCatcher.height, r.y + r.height);
            r = Qt.rect(x1, y1, x2 - x1, y2 - y1);
        }
        searchCatcher.x = r.x; searchCatcher.y = r.y;
        searchCatcher.width = r.width; searchCatcher.height = r.height;
        searchCatchOn = true;
        searchCatchCheck.restart();
    }
    onSearchResultsHoveredChanged: if (searchResultsHovered) searchCatchOn = false
    Item {
        id: searchCatcher
        visible: unifiedFrame.searchCatchOn
        z: -1
        HoverHandler {
            id: searchCatcherHover
            onHoveredChanged: if (!hovered && !unifiedFrame.searchResultsHovered) unifiedFrame.searchCatchOn = false
        }
    }
    // Drop the catcher if the pointer isn't on it shortly after arming (it would eat clicks)
    Timer {
        id: searchCatchCheck
        interval: 250
        repeat: false
        onTriggered: if (!searchCatcherHover.hovered && !unifiedFrame.searchResultsHovered) unifiedFrame.searchCatchOn = false
    }
    readonly property real islandSearchExtraH: globalState.islandSearchOpen
    ? Math.min(islandControlPageH[2], Math.max(islandSearchRowH, islandSearchResultCount * islandSearchRowH) + 40)
    : 0
    readonly property real vSearchPanelW: 440
    // Spring keeps velocity on retarget so resizing while typing stays smooth
    Spring {
        id: searchExtraSpring
        target: (unifiedFrame.islandMode && globalState.islandSearchOpen) ? unifiedFrame.islandSearchExtraH : 0
        stiffness: m3.sk("spatialDefault")
        dampingRatio: 0.92
        eps: 0.3
    }
    readonly property real searchExtraLive: Math.max(0, searchExtraSpring.value)
    readonly property bool searchDriving: islandMode && !globalState.islandControlOpen
                                          && (globalState.islandSearchOpen || searchExtraSpring.value > 0.5)
    readonly property real vSearchFieldH: 44
    readonly property real notchVContentW: 600
    readonly property bool ncVertical: barVertical || !islandMode
    readonly property bool ncSide: !islandMode && !barVertical
    readonly property bool ccFromEnd: {
        var L = globalState.barLayoutNotch;
        return !!(L && Array.isArray(L.right) && L.right.indexOf("control") !== -1);
    }
    readonly property real ncSideW: notchVContentW + 24
    readonly property bool ncSideLeftOpen:  ncSide && globalState.ncFusedOpen && !ccFromEnd
    readonly property bool ncSideRightOpen: ncSide && globalState.ncFusedOpen && ccFromEnd
    readonly property real vIslandStripLen: topBarContent.vBarStrip.vIslandCol ? topBarContent.vBarStrip.vIslandCol.implicitHeight : islandNotchMinWidth
    property real bulgeReqAlong: 0
    readonly property real vIslandAlongLen: Math.max(vIslandAlongBase,
    bulgeReqAlong > 0 ? bulgeReqAlong + bulgeEdgeMargin * 2 : 0)
    function _vIslandPoles(w) {
        var half = Math.max(islandNotchMinWidth,
        Math.max(vIslandAlongBase, w + bulgeEdgeMargin * 2) + islandNotchPadding * 2) / 2;
        return { l: frameShape.width / 2 - half, r: frameShape.width / 2 + half };
    }
    readonly property real vIslandAlongBase: (unifiedFrame.islandMode && globalState.islandControlOpen)
    ? (topBaseH + islandControlExtraH - 18)
    : (unifiedFrame.islandMode && globalState.islandSearchOpen)
    ? Math.max(vIslandStripLen, searchExtraLive + vSearchFieldH + 12)
    : vIslandStripLen
    readonly property real vTopH: (!unifiedFrame.islandMode && globalState.ncFusedOpen)
    ? notchVContentW + 16
    : (unifiedFrame.islandMode && globalState.islandControlOpen)
    ? islandControlContentWidth + 18
    : (unifiedFrame.islandMode && globalState.islandSearchOpen)
    ? topBaseH + vSearchPanelW + 10
    : topBaseH
    property real topH: barVertical ? vTopH
    : (unifiedFrame.islandMode && globalState.islandControlOpen)
    ? topBaseH + islandControlExtraH
    : unifiedFrame.searchDriving
    ? topBaseH + searchExtraLive
    : topBaseH
    property real bottomH: 0

    readonly property bool barAtBottom: globalState.topBarPosition === "bottom"
    readonly property string barEdge: globalState.topBarPosition
    readonly property bool barVertical: barEdge === "left" || barEdge === "right"
    readonly property bool barAtLeft:  barEdge === "left"
    readonly property bool barAtRight: barEdge === "right"
    readonly property matrix4x4 frameMatrix: barAtLeft
    ? Qt.matrix4x4(0, 1, 0, 0,  1, 0, 0, 0,  0, 0, 1, 0,  0, 0, 0, 1)
    : barAtRight
    ? Qt.matrix4x4(0, -1, 0, frameRoot.width,  1, 0, 0, 0,  0, 0, 1, 0,  0, 0, 0, 1)
    : Qt.matrix4x4(1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, 0, 0, 1)
    function popupRealX(w) {
        return barAtLeft ? frameTopH : (frameRoot.width - frameTopH - w);
    }
    readonly property int popupOrigin: barVertical ? (barAtLeft ? Item.Left : Item.Right)
    : (barAtBottom ? Item.Bottom : Item.Top)
    property real islandAutoHideRevealFactor: globalState.islandHiddenByAutoHide ? 0 : 1
    Behavior on islandAutoHideRevealFactor { M3NumberAnim { duration: 260 } }
    readonly property real frameTopH:       barAtBottom ? bottomH     : (topH * islandAutoHideRevealFactor)
    readonly property real frameBottomH:    barAtBottom ? (topH * islandAutoHideRevealFactor) : bottomH
    readonly property real frameTopBaseH:   (barAtBottom || barVertical) ? edgeBaseSize : topBaseH
    readonly property real frameLeftBaseH:  barAtLeft  ? topBaseH : edgeBaseSize
    readonly property real frameRightBaseH: barAtRight ? topBaseH : edgeBaseSize
    readonly property real frameBottomBaseH: barAtBottom ? topBaseH    : edgeBaseSize
    readonly property bool leftPanelEnabled: false
    property real leftW:   ncSideLeftOpen ? ncSideW
    : (leftPanelEnabled && globalState.calendarMenuOpen) ? (globalState.leftPanelPage === 1 ? (unifiedFrame.contentW / 6) : 280) : unifiedFrame.edgeBaseSize
    property real rightW:  ncSideRightOpen ? ncSideW
    : (globalState.mediaMenuOpen && !unifiedFrame.islandMode && unifiedFrame.rightPanelEnabled) ? (globalState.rightPanelPage === 1 ? (unifiedFrame.contentW / 8) : (unifiedFrame.contentW / 5)) : unifiedFrame.edgeBaseSize
    readonly property real rTop:    barAtBottom ? 0 : globalState.cornerR
    readonly property real rBottom: barAtBottom ? globalState.cornerR : 0

    readonly property bool islandMode: globalState.shellMode === "island"
    readonly property real islandNotchR: 24
    readonly property real islandNotchPadding: 28
    readonly property real islandNotchMinWidth: 240
    readonly property var islandControlPageW: [1160, 640, 693, 1000]
    readonly property real islandControlContentWidth: (barVertical ? islandControlPageWv : islandControlPageW)[Math.min(globalState.islandControlPage, islandControlPageW.length - 1)]
    property real islandNotchHalfWidth: Math.max(
    islandNotchMinWidth,
    unifiedFrame.barVertical ? (vIslandAlongLen + islandNotchPadding * 2)
    : (unifiedFrame.islandMode && globalState.islandControlOpen)
    ? (islandControlContentWidth + islandNotchPadding * 2)
    : ((topBarContent.topBarMainRow ? topBarContent.topBarMainRow.implicitWidth : islandNotchMinWidth) + islandNotchPadding * 2)
    ) / 2
    Behavior on islandNotchHalfWidth {
        enabled: !globalState.desktopZoomBusy && unifiedFrame.startupSettled
                 && !(unifiedFrame.barVertical && unifiedFrame.islandMode && globalState.islandSearchOpen)
        NumberAnimation { duration: 280; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasizedDecelerate }
    }
    property real islandRestHalfWidth: Math.max(islandNotchMinWidth,
    (unifiedFrame.barVertical ? vIslandStripLen : (topBarContent.topBarMainRow ? topBarContent.topBarMainRow.implicitWidth : islandNotchMinWidth)) + islandNotchPadding * 2) / 2
    Behavior on islandRestHalfWidth {
        enabled: !globalState.desktopZoomBusy && unifiedFrame.startupSettled
        NumberAnimation { duration: 280; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasizedDecelerate }
    }
    readonly property real islandNotchLeftX:  frameShape.width / 2 - islandNotchHalfWidth
    readonly property real islandNotchRightX: frameShape.width / 2 + islandNotchHalfWidth
    readonly property bool topEdgeIsHost:    !barAtBottom
    readonly property bool bottomEdgeIsHost:  barAtBottom
    readonly property bool topIslandOn:    islandMode && topEdgeIsHost
    readonly property bool bottomIslandOn: islandMode && bottomEdgeIsHost
    readonly property real topStartY: topIslandOn ? 0 : (frameTopH + topLeftCornerExtend)
    readonly property real topEndY:   topIslandOn ? 0 : (frameTopH + topRightCornerExtend)
    readonly property real topNotchJoinR:   topIslandOn ? Math.min(islandNotchR, frameTopH / 2) : 0
    readonly property real topNotchLeftX:   topIslandOn ? islandNotchLeftX  : (leftW + topLeftOuterR)
    readonly property real topNotchRightX:  topIslandOn ? islandNotchRightX : (frameShape.width - rightW - topRightOuterR)
    readonly property real bottomRightY: bottomIslandOn ? frameShape.height : (frameShape.height - frameBottomH - bottomRightCornerExtend)
    readonly property real bottomLeftY:  bottomIslandOn ? frameShape.height : (frameShape.height - frameBottomH - bottomLeftCornerExtend)
    readonly property real bottomNotchJoinR:  bottomIslandOn ? Math.min(islandNotchR, frameBottomH / 2) : 0
    readonly property real bottomNotchLeftX:  bottomIslandOn ? islandNotchLeftX  : (leftW + bottomLeftOuterR)
    readonly property real bottomNotchRightX: bottomIslandOn ? islandNotchRightX : (frameShape.width - rightW - bottomRightOuterR)
    readonly property real currentHostPoleLeftX:  barAtBottom ? bottomNotchLeftX  : topNotchLeftX
    readonly property real topOuterR: topIslandOn ? 0 : rTop
    readonly property real bottomOuterR: bottomIslandOn ? 0 : rBottom
    readonly property real ncFarRL: ncSide ? Math.min(globalState.cornerR, Math.max(0, leftW  - edgeBaseSize)) : 0
    readonly property real ncFarRR: ncSide ? Math.min(globalState.cornerR, Math.max(0, rightW - edgeBaseSize)) : 0
    readonly property real topLeftOuterR:     topIslandOn    ? 0 : Math.max(rTop,    barAtBottom  ? ncFarRL : 0)
    readonly property real topRightOuterR:    topIslandOn    ? 0 : Math.max(rTop,    barAtBottom  ? ncFarRR : 0)
    readonly property real bottomLeftOuterR:  bottomIslandOn ? 0 : Math.max(rBottom, !barAtBottom ? ncFarRL : 0)
    readonly property real bottomRightOuterR: bottomIslandOn ? 0 : Math.max(rBottom, !barAtBottom ? ncFarRR : 0)
    readonly property real currentHostPoleRightX: barAtBottom ? bottomNotchRightX : topNotchRightX

    property real bulgeLeftX:  0
    property real bulgeRightX: 0
    property bool bulgeFlushLeft:  false
    property bool bulgeFlushRight: false
    property real bulgeFlushLeftAmt:  bulgeFlushLeft  ? 1 : 0
    property real bulgeFlushRightAmt: bulgeFlushRight ? 1 : 0
    property bool bulgeSnap: false
    property var  bulgeOwner: null
    property bool bulgeMorph: false
    Behavior on bulgeFlushLeftAmt  { enabled: !unifiedFrame.bulgeSnap; NumberAnimation { duration: 220; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasizedDecelerate } }
    Behavior on bulgeFlushRightAmt { enabled: !unifiedFrame.bulgeSnap; NumberAnimation { duration: 220; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasizedDecelerate } }
    property real bulgeDepth: 0
    // true while a popup drives bulgeDepth frame by frame with its own spring
    property bool bulgeLive: false
    readonly property real bulgeWidthCalc: bulgeRightX - bulgeLeftX
    readonly property real bulgeJoinR: 18
    readonly property real bulgeEdgeMargin: 16
    readonly property real topBulgeDepth:    (!barAtBottom && bulgeWidthCalc > 0) ? bulgeDepth : 0
    readonly property real bottomBulgeDepth: ( barAtBottom && bulgeWidthCalc > 0) ? bulgeDepth : 0
    readonly property real topLeftJoinR:     Math.min(bulgeJoinR, topBulgeDepth / 2, Math.max(0, bulgeWidthCalc) / 2)    * (1 - bulgeFlushLeftAmt)
    readonly property real topRightJoinR:    Math.min(bulgeJoinR, topBulgeDepth / 2, Math.max(0, bulgeWidthCalc) / 2)    * (1 - bulgeFlushRightAmt)
    readonly property real bottomLeftJoinR:  Math.min(bulgeJoinR, bottomBulgeDepth / 2) * (1 - bulgeFlushLeftAmt)
    readonly property real bottomRightJoinR: Math.min(bulgeJoinR, bottomBulgeDepth / 2) * (1 - bulgeFlushRightAmt)
    readonly property real topLeftCornerExtend:     !barAtBottom ? bulgeDepth * bulgeFlushLeftAmt  : 0
    readonly property real topRightCornerExtend:    !barAtBottom ? bulgeDepth * bulgeFlushRightAmt : 0
    readonly property real bottomLeftCornerExtend:   barAtBottom ? bulgeDepth * bulgeFlushLeftAmt  : 0
    readonly property real bottomRightCornerExtend:  barAtBottom ? bulgeDepth * bulgeFlushRightAmt : 0
    Behavior on bulgeDepth { enabled: !unifiedFrame.bulgeLive; NumberAnimation { duration: 300; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasizedDecelerate } }
    Behavior on bulgeLeftX {
        enabled: unifiedFrame.bulgeMorph
        NumberAnimation { duration: 300; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasizedDecelerate }
    }
    Behavior on bulgeRightX {
        enabled: unifiedFrame.bulgeMorph
        NumberAnimation { duration: 300; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasizedDecelerate }
    }

    function _bulgeSpan(popup, targetDepth) {
        var w = (popup.bulgeW !== undefined) ? popup.bulgeW
        : (popup.natBulgeW !== undefined ? popup.natBulgeW : popup.width);
        if (unifiedFrame.barVertical) { var swapT = w; w = targetDepth; targetDepth = swapT; }
        var leftPole  = unifiedFrame.currentHostPoleLeftX;
        var rightPole = unifiedFrame.currentHostPoleRightX;
        if (unifiedFrame.barVertical && unifiedFrame.islandMode) {
            unifiedFrame.bulgeReqAlong = w;
            var vPoles = unifiedFrame._vIslandPoles(w);
            leftPole = vPoles.l; rightPole = vPoles.r;
        }
        return { w: w, depth: targetDepth, l: leftPole, r: rightPole };
    }
    function _applyBulge(popup, lx, rx, flushL, flushR) {
        var snap = unifiedFrame.bulgeDepth < 0.5;
        unifiedFrame.bulgeOwner = popup;
        unifiedFrame.bulgeMorph = !snap;
        if (snap) unifiedFrame.bulgeSnap = true;
        unifiedFrame.bulgeLeftX = lx;
        unifiedFrame.bulgeRightX = rx;
        unifiedFrame.bulgeFlushLeft = flushL;
        unifiedFrame.bulgeFlushRight = flushR;
        unifiedFrame.bulgeSnap = false;
    }
    function _finishBulge(depth) {
        if (!(depth > 0)) unifiedFrame.bulgeReqAlong = 0;
        unifiedFrame.bulgeDepth = depth;
    }

    function setBulgeFrom(popup, triggerItem, targetDepth, flushSide) {
        if (targetDepth > 0 && triggerItem) {
            var s = _bulgeSpan(popup, targetDepth);
            targetDepth = s.depth;
            var lx, rx;
            if (flushSide === "left") { lx = s.l; rx = s.l + s.w; }
            else if (flushSide === "right") { rx = s.r; lx = s.r - s.w; }
            else {
                var p = triggerItem.mapToItem(frameShape, triggerItem.width / 2, triggerItem.height / 2);
                var halfW = s.w / 2, margin = unifiedFrame.bulgeEdgeMargin;
                var cx = Math.max(s.l + margin + halfW, Math.min(s.r - margin - halfW, p.x));
                lx = cx - halfW; rx = cx + halfW;
            }
            _applyBulge(popup, lx, rx, flushSide === "left", flushSide === "right");
            if (popup.bulgeW === undefined) popup.x = frameShape.mapToItem(triggerItem, lx, 0).x;
        }
        _finishBulge(targetDepth);
    }

    property real previewAnchorX: 0

    function setBulgeCentered(popup, targetDepth) {
        if (targetDepth > 0) {
            var s = _bulgeSpan(popup, targetDepth);
            targetDepth = s.depth;
            var halfW = s.w / 2, margin = unifiedFrame.bulgeEdgeMargin;
            var rawCx = unifiedFrame.previewAnchorX;
            var flushL = rawCx < s.l + margin + halfW;
            var flushR = rawCx > s.r - margin - halfW;
            var lx = flushL ? s.l : flushR ? s.r - s.w : rawCx - halfW;
            var rx = flushL ? s.l + s.w : flushR ? s.r : rawCx + halfW;
            _applyBulge(popup, lx, rx, flushL, flushR);
            if (popup.bulgeW === undefined && unifiedFrame.barVertical && popup.placeVertical !== undefined) popup.placeVertical(lx, rx);
            else if (popup.bulgeW === undefined) popup.x = frameShape.mapToItem(popup.parent, lx, 0).x;
        }
        _finishBulge(targetDepth);
    }

    function setBulgeUnder(popup, triggerItem, targetDepth) {
        if (targetDepth > 0 && triggerItem) {
            var p = triggerItem.mapToItem(frameShape, triggerItem.width / 2, triggerItem.height / 2);
            unifiedFrame.previewAnchorX = p.x;
        }
        setBulgeCentered(popup, targetDepth);
    }

    readonly property real previewBulgeDepth: 300 * bulgeScale
    readonly property real bulgeScale: 1.2

    function shadowPathSvg(rest) {
        var W = frameShape.width, H = frameShape.height;
        if (!(W > 0) || !(H > 0)) return "";
        var eb = edgeBaseSize;
        return FramePath.shadowPath({
            W: W, H: H, bab: barAtBottom, isl: islandMode, cR: globalState.cornerR, eb: eb,
            tH: (rest ? topBaseH : topH) * islandAutoHideRevealFactor, bH: bottomH,
            lW: rest ? eb : leftW, rW: rest ? eb : rightW, depth: rest ? 0 : bulgeDepth,
            bLX: bulgeLeftX, bRX: bulgeRightX, flL: bulgeFlushLeftAmt, flR: bulgeFlushRightAmt,
            half: rest ? islandRestHalfWidth : islandNotchHalfWidth,
            joinR: bulgeJoinR, ncSide: ncSide, notchR: islandNotchR
        });
    }

    Behavior on topH    { enabled: !(unifiedFrame.searchDriving && !unifiedFrame.barVertical); NumberAnimation { duration: 420; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasizedDecelerate } }
    Behavior on bottomH { NumberAnimation { duration: 450; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasizedDecelerate } }
    Behavior on leftW   { NumberAnimation { duration: 450; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasizedDecelerate } }
    Behavior on rightW  { NumberAnimation { id: rightPanelWidthAnim; duration: 480; easing.type: Easing.OutExpo } }

    onRightWChanged: {
        if (globalState.powerMenuOpen) setBulgeUnder(powerMenuPopup, topBarContent.barGroupRight.sessionBtnWrap, powerMenuPopup.natDepth * bulgeScale);
        if (globalState.windowPreviewOpen) setBulgeCentered(topBarContent.openWindowsModule.windowPreviewPopup, topBarContent.openWindowsModule.windowPreviewPopup.computedDepth);
        if (notchMediaPopup.isOpen) setBulgeUnder(notchMediaPopup, topBarContent.islandAudioModule, notchMediaPopup.scaledDepth);
        if (notchSearchPopup.isOpen) setBulgeUnder(notchSearchPopup, topBarContent.searchBtn, notchSearchPopup.scaledDepth);
        if (wsPreviewPopup.isOpen) wsPreviewPopup.reposition();
        if (netBulgePopup.isOpen) netBulgePopup.reposition();
        if (privBulgePopup.isOpen) privBulgePopup.reposition();
        if (battBulgePopup.isOpen) battBulgePopup.reposition();
        if (recBulgePopup.isOpen) recBulgePopup.reposition();
    }
    onLeftWChanged: {
        if (globalState.powerMenuOpen) setBulgeUnder(powerMenuPopup, topBarContent.barGroupRight.sessionBtnWrap, powerMenuPopup.natDepth * bulgeScale);
        if (globalState.windowPreviewOpen) setBulgeCentered(topBarContent.openWindowsModule.windowPreviewPopup, topBarContent.openWindowsModule.windowPreviewPopup.computedDepth);
        if (notchMediaPopup.isOpen) setBulgeUnder(notchMediaPopup, topBarContent.islandAudioModule, notchMediaPopup.scaledDepth);
        if (recBulgePopup.isOpen) recBulgePopup.reposition();
        if (battBulgePopup.isOpen) battBulgePopup.reposition();
    }

    HyprlandFocusGrab {
        id: bottomBarFocusGrab
        windows: [unifiedFrame]
        active: (globalState.calendarMenuOpen && globalState.leftPanelPage === 1)
        || globalState.islandSearchOpen || globalState.notchSearchOpen
        || (globalState.wifiPasswordSsid !== "" && globalState.wifiViewOpen)
        || (globalState.btPromptType !== "" && globalState.btDevicesViewOpen)
        || globalState.calEventInputFocused
        || globalState.clipEditing
        onCleared: {
            globalState.clipEditing = false;
            globalState.islandSearchOpen = false;
            globalState.notchSearchOpen = false;
        }
        onActiveChanged: {
            if (!active && globalState.waitingForGrabRelease) {
                globalState.waitingForGrabRelease = false;
                globalState.selectCaptureTrigger++;
            }
        }
    }

    Timer {
        id: wifiPasswordFocusTimer
        interval: 120; repeat: false
        onTriggered: { var f = unifiedFrame.wifiPromptFieldRef; if (f) { f.forceActiveFocus(); f.focus = true; } }
    }
    Timer {
        id: btPromptFocusTimer
        interval: 120; repeat: false
        onTriggered: { var f = unifiedFrame.btPromptFieldRef; if (f) { f.forceActiveFocus(); f.focus = true; } }
    }

    Item {
        id: frameRoot
        width:  unifiedFrame.contentW
        height: unifiedFrame.contentH
        scale:  unifiedFrame.zoomK
        transformOrigin: Item.TopLeft
        opacity: (globalState.frameEffectivelyHidden || globalState.profileFrameFade) ? 0 : 1
        Behavior on opacity { M3NumberAnim { duration: globalState.profileFrameAnim ? 300 : 220 } }

        FrameShape { id: frameShape }

        TopBar { id: topBarContent }

        Item {
            id: ncSideHitArea
            readonly property bool active: unifiedFrame.ncSide && globalState.ncFusedOpen
            width: !unifiedFrame.ncSide ? 0 : (unifiedFrame.ccFromEnd ? unifiedFrame.rightW : unifiedFrame.leftW)
            height: parent.height
            x: unifiedFrame.ccFromEnd ? parent.width - width : 0
            y: 0
            HoverHandler { id: ncSideHitHover }
        }
        Timer {
            id: ncSideDebugTimer
            interval: 700
            onTriggered: console.log("[ncSide] bar x:", topBarContent.x, "width:", topBarContent.width,
            "| row width:", topBarContent.topBarMainRow.width, "implicit:", topBarContent.topBarMainRow.implicitWidth, "| column x:", topBarContent.topBarColumn.x, "| right group x:", topBarContent.barGroupRight.mapToItem(null, 0, 0).x,
            "| left group x:", topBarContent.barGroupLeft.mapToItem(null, 0, 0).x)
        }
        Connections {
            target: globalState
            function onNotchControlOpenChanged() { if (unifiedFrame.ncSide) ncSideDebugTimer.restart(); }
        }

        Rectangle {
            id: notchDimOverlay
            x: unifiedFrame.barVertical ? (unifiedFrame.barAtLeft ? unifiedFrame.topH : 0) : 0
            width: unifiedFrame.barVertical ? Math.max(0, parent.width - unifiedFrame.topH) : parent.width
            height: unifiedFrame.barVertical ? parent.height : Math.max(0, parent.height - unifiedFrame.topH)
            y: unifiedFrame.barVertical ? 0 : (unifiedFrame.barAtBottom ? 0 : unifiedFrame.topH)
            color: "transparent"
            property bool active: !unifiedFrame.islandMode && globalState.ncFusedOpen
            visible: active
            MouseArea {
                anchors.fill: parent
                enabled: notchDimOverlay.active
                onClicked: globalState.notchControlOpen = false
            }
        }


        LeftPanel { id: leftPanelContent }

        RightPanel { id: rightPanelContent }

        Item {
            id: bottomBarContent
            anchors.left: parent.left; anchors.right: parent.right
            height: unifiedFrame.bottomH
            y: unifiedFrame.barAtBottom ? 0 : (parent.height - height)

            Rectangle {
                id: bottomBarBg
                anchors.fill: parent
                color: "transparent"
            }
        }
        NotchMediaPopup { id: notchMediaPopup }

        PowerMenuPopup { id: powerMenuPopup }

        NotchSearchPopup { id: notchSearchPopup }

        WorkspacePreviewPopup { id: wsPreviewPopup }

        NetworkBulgePopup { id: netBulgePopup }

        RecordingBulgePopup { id: recBulgePopup }

        PrivacyBulgePopup { id: privBulgePopup }

        BatteryBulgePopup { id: battBulgePopup }

        ClipBulgePopup { id: clipBulgePopup }
    }

    DesktopEmptyContextMenu { id: desktopEmptyContextMenu }

    mask: Region {
        item: globalState.frameEffectivelyHidden ? null : topBarContent
        Region { item: desktopEmptyContextMenu.open ? desktopEmptyContextMenu : null }
        Region { item: globalState.frameEffectivelyHidden ? null : bottomBarContent }
        Region { item: globalState.frameEffectivelyHidden ? null : leftPanelContent }
        Region { item: globalState.frameEffectivelyHidden ? null : rightPanelContent }
        Region { item: (globalState.frameEffectivelyHidden || !globalState.powerMenuOpen) ? null : powerMenuPopup }
        Region { item: (globalState.frameEffectivelyHidden || !globalState.windowPreviewOpen) ? null : topBarContent.openWindowsModule.windowPreviewPopup }
        Region { item: (globalState.frameEffectivelyHidden || !notchMediaPopup.isOpen) ? null : notchMediaPopup }
        Region { item: (globalState.frameEffectivelyHidden || !notchSearchPopup.isOpen) ? null : notchSearchPopup }
        Region { item: (globalState.frameEffectivelyHidden || !unifiedFrame.searchCatchOn) ? null : searchCatcher }
        Region { item: (globalState.frameEffectivelyHidden || !wsPreviewPopup.isOpen) ? null : wsPreviewPopup }
        Region { item: (globalState.frameEffectivelyHidden || !netBulgePopup.isOpen) ? null : netBulgePopup }
        Region { item: (globalState.frameEffectivelyHidden || !clipBulgePopup.isOpen) ? null : clipBulgePopup }
        Region { item: (globalState.frameEffectivelyHidden || !privBulgePopup.isOpen) ? null : privBulgePopup }
        Region { item: (globalState.frameEffectivelyHidden || !battBulgePopup.isOpen) ? null : battBulgePopup }
        Region { item: (globalState.frameEffectivelyHidden || !recBulgePopup.isOpen) ? null : recBulgePopup }
        Region { item: (globalState.frameEffectivelyHidden || !globalState.ncFusedOpen) ? null : notchDimOverlay }
        Region { item: (globalState.frameEffectivelyHidden || !ncSideHitArea.active) ? null : ncSideHitArea }
    }
}
