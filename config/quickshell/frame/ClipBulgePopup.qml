import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../panels"

// Clipboard bulge popup: copied text, image or files
Item {
    id: clipBulgePopup
    property alias clipCollapseTimer: clipCollapseTimer
    readonly property bool isOpen: globalState.clipBulgeOpen && globalState.clipHasContent
    && globalState.barModules.clipboard && !globalState.frameEffectivelyHidden
    readonly property string kind: globalState.clipKind
    readonly property real natW: 440
    readonly property real bulgeW: natW * unifiedFrame.bulgeScale
    readonly property real headerH: 54
    readonly property real innerW: natW - 28
    readonly property string previewPath: kind === "image" ? globalState.clipImagePath
    : (kind === "files" && globalState.clipFiles.length === 1 && clipIsImage(globalState.clipFiles[0].path))
    ? globalState.clipFiles[0].path : ""
    readonly property real previewH: {
        var w = clipBody.clipPreviewImg.implicitWidth, h = clipBody.clipPreviewImg.implicitHeight;
        if (w <= 0 || h <= 0) return 160;
        return Math.max(90, Math.min(300, innerW * h / w));
    }
    readonly property real bodyH: {
        if (kind === "text") return Math.max(64, Math.min(260, clipBody.clipTextArea.implicitHeight));
        if (previewPath !== "") return previewH + (kind === "files" ? 26 : 0);
        if (kind === "files") return Math.min(5, globalState.clipFiles.length) * 44 + (globalState.clipFiles.length > 5 ? 22 : 0);
        return 60;
    }
    readonly property real natDepth: headerH + bodyH + 16
    function mimeForFiles(paths) {
        var uris = paths.map(function (p) { return fileUrl(p); });
        return { "text/uri-list": uris.join("\r\n") + "\r\n", "text/plain": paths.join("\n") };
    }
    readonly property var dragMime: {
        if (kind === "text") {
            var t = clipBody.clipTextArea.selectedText !== "" ? clipBody.clipTextArea.selectedText : globalState.clipText;
            return { "text/plain": t, "text/plain;charset=utf-8": t };
        }
        if (kind === "image") return mimeForFiles([globalState.clipImagePath]);
        if (kind === "files") return mimeForFiles(globalState.clipFiles.map(function (f) { return f.path; }));
        return ({});
    }
    function dragStateChanged(active) {
        globalState.clipDraggingOut = active;
        if (!active) scheduleCollapse(1500);
    }

    x: unifiedFrame.barVertical ? unifiedFrame.popupRealX(width) : unifiedFrame.bulgeLeftX
    width: unifiedFrame.barVertical ? unifiedFrame.bulgeDepth : Math.max(0, unifiedFrame.bulgeRightX - unifiedFrame.bulgeLeftX)
    height: unifiedFrame.barVertical ? Math.max(0, unifiedFrame.bulgeRightX - unifiedFrame.bulgeLeftX) : unifiedFrame.bulgeDepth
    opacity: isOpen ? 1 : 0
    Behavior on opacity { M3NumberAnim { duration: clipBulgePopup.isOpen ? 220 : 140 } }
    visible: opacity > 0.01
    enabled: isOpen
    y: unifiedFrame.barVertical ? unifiedFrame.bulgeLeftX
    : (unifiedFrame.barAtBottom ? (frameRoot.height - unifiedFrame.frameBottomH - height) : unifiedFrame.frameTopH)
    z: 1000
    clip: true

    function reposition() {
        if (isOpen) unifiedFrame.setBulgeUnder(clipBulgePopup, topBarContent.barGroupRight.clipBtn, natDepth * unifiedFrame.bulgeScale);
    }
    function scheduleCollapse(ms) {
        if (globalState.clipPinned) { clipCollapseTimer.stop(); return; }
        clipCollapseTimer.interval = ms;
        clipCollapseTimer.restart();
    }
    function flushEdit() {
        clipWriteDebounce.stop();
        if (globalState.clipClearing) return;
        var t = clipBody.clipTextArea.text;
        if (t === "" || t === globalState.clipText) return;
        globalState.clipText = t;
        globalState.clipSig = "text|" + t;
        clipCopyProcess.copy([], t);
    }
    onNatDepthChanged: reposition()
    onIsOpenChanged: {
        if (isOpen) {
            reposition();
            scheduleCollapse(globalState.clipAutoOpened ? 4500 : 1200);
        } else {
            clipCollapseTimer.stop();
            if (clipBody.clipTextArea.activeFocus) clipBody.clipTextArea.focus = false;
            if (unifiedFrame.bulgeOwner === clipBulgePopup) unifiedFrame.setBulgeUnder(clipBulgePopup, topBarContent.barGroupRight.clipBtn, 0);
        }
    }

    Timer {
        id: clipCollapseTimer
        repeat: false
        onTriggered: {
            if (globalState.clipPinned) return;
            if (clipPopupHover.hovered || topBarContent.barGroupRight.clipBtn.clipBtnHover.hovered || globalState.clipEditing || globalState.clipDragHover || globalState.clipDraggingOut) return;
            globalState.clipBulgeOpen = false;
        }
    }
    Timer {
        interval: 800; repeat: true
        running: globalState.clipPinned && globalState.clipHasContent && !globalState.clipBulgeOpen
        && globalState.clipSig !== globalState.clipDismissedSig
        onTriggered: globalState.openClipBulge(true)
    }
    Timer { id: clipWriteDebounce; interval: 350; repeat: false; onTriggered: clipBulgePopup.flushEdit() }
    Timer { id: clipResyncTimer;   interval: 300; repeat: false; onTriggered: clipProbeProcess.request() }
    Timer { id: clipFocusTimer;    interval: 120; repeat: false; onTriggered: clipBody.clipTextArea.forceActiveFocus() }

    Connections {
        target: globalState
        function onClipTextChanged() {
            if (!clipBody.clipTextArea.activeFocus && clipBody.clipTextArea.text !== globalState.clipText) clipBody.clipTextArea.text = globalState.clipText;
        }
        function onClipClearingChanged() {
            if (!globalState.clipClearing) return;
            clipWriteDebounce.stop();
            if (clipBody.clipTextArea.activeFocus) clipBody.clipTextArea.focus = false;
            clipBody.clipTextArea.text = "";
        }
        function onClipEditingChanged() {
            if (globalState.clipEditing) return;
            clipBulgePopup.flushEdit();
            if (clipBody.clipTextArea.activeFocus) clipBody.clipTextArea.focus = false;
            clipResyncTimer.restart();
            clipBulgePopup.scheduleCollapse(1500);
        }
        function onClipPinnedChanged() {
            if (globalState.clipPinned) clipCollapseTimer.stop();
            else if (clipBulgePopup.isOpen) clipBulgePopup.scheduleCollapse(1500);
        }
    }

    HoverHandler {
        id: clipPopupHover
        onHoveredChanged: { if (hovered) clipCollapseTimer.stop(); else clipBulgePopup.scheduleCollapse(700); }
    }
    DropArea {
        anchors.fill: parent
        onEntered: (drag) => {
            if (globalState.clipDraggingOut) { drag.accepted = false; return; }
            drag.accept(Qt.CopyAction); globalState.clipDragHover = true;
        }
        onExited: globalState.clipDragHover = false
        onDropped: (drop) => { if (!globalState.clipDraggingOut) handleClipDrop(drop); }
    }

    Item {
        id: clipContent
        width: clipBulgePopup.natW
        x: unifiedFrame.barVertical ? (unifiedFrame.barAtLeft ? 0 : parent.width - width) : (parent.width - width) / 2
        height: clipBulgePopup.natDepth
        scale: unifiedFrame.bulgeScale
        transformOrigin: unifiedFrame.popupOrigin
        y: unifiedFrame.barVertical ? (parent.height - height) / 2 : (unifiedFrame.barAtBottom ? parent.height - height : 0)

        ClipBulgeHeader { id: clipBulgeHeader }

        ClipBulgeBody { id: clipBody }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 6
            radius: 18
            visible: globalState.clipDragHover
            color: ga(pal.primary, 0.16)
            border.width: 2
            border.color: pal.primary
            Text {
                anchors.centerIn: parent
                text: tr("clip_drop")
                font.family: globalState.fontPrimary; font.pixelSize: Math.round(15 * globalState.fontScale); font.weight: Font.Bold
                color: pal.primary
            }
        }
    }
}
