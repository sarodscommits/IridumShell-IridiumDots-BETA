import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../controlcenter"
import "../panels"
import "../ui"

// Clipboard card of the overview dashboard
Rectangle {
    id: ncDashClipCard
    property alias ncClipBody: ncClipBody
    opacity: ncDashLayer.opacity
    visible: ncDashLayer.visible && ncDashLayer.shown("clip")
    x: ncDashLayer.rClip.x
    y: ncDashLayer.rClip.y
    Behavior on y { enabled: globalState.ncEditMode; M3SpringAnim { token: "spatialDefault" } }
    width: ncDashLayer.rClip.width
    height: ncDashLayer.rClip.height
    radius: 28
    clip: true
    color: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont)
    border.width: globalState.clipDragHover ? 2 : 0
    border.color: pal.primary

    readonly property string kind: globalState.clipKind
    readonly property string previewPath: clipBulgePopup.previewPath
    readonly property var dragMime: {
        if (kind === "text") {
            var t = ncClipBody.ncClipText.selectedText !== "" ? ncClipBody.ncClipText.selectedText : globalState.clipText;
            return { "text/plain": t, "text/plain;charset=utf-8": t };
        }
        if (kind === "image") return clipBulgePopup.mimeForFiles([globalState.clipImagePath]);
        if (kind === "files") return clipBulgePopup.mimeForFiles(globalState.clipFiles.map(function (f) { return f.path; }));
        return ({});
    }
    function flushEdit() {
        ncClipWriteDebounce.stop();
        if (globalState.clipClearing) return;
        var t = ncClipBody.ncClipText.text;
        if (t === "" || t === globalState.clipText) return;
        globalState.clipText = t;
        globalState.clipSig = "text|" + t;
        clipCopyProcess.copy([], t);
    }
    Timer { id: ncClipWriteDebounce; interval: 350; repeat: false; onTriggered: ncDashClipCard.flushEdit() }
    Connections {
        target: globalState
        function onClipTextChanged() {
            if (!ncClipBody.ncClipText.activeFocus && ncClipBody.ncClipText.text !== globalState.clipText) ncClipBody.ncClipText.text = globalState.clipText;
        }
        function onClipClearingChanged() {
            if (!globalState.clipClearing) return;
            ncClipWriteDebounce.stop();
            if (ncClipBody.ncClipText.activeFocus) ncClipBody.ncClipText.focus = false;
            ncClipBody.ncClipText.text = "";
        }
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

    RowLayout {
        id: ncClipHeader
        anchors.left: parent.left; anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14
        spacing: 8
        Rectangle {
            width: 30; height: 30; radius: 15
            color: ga(pal.primary, 0.18)
            FadeIcon {
                anchors.centerIn: parent
                text: ncDashClipCard.kind === "image" ? ""
                : ncDashClipCard.kind === "files"
                ? ((globalState.clipFiles.length === 1 && globalState.clipFiles[0].dir) ? "" : "")
                : ""
                font.family: "Material Symbols Rounded"; font.pixelSize: 17
                color: pal.primary
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Text {
                Layout.fillWidth: true
                text: {
                    var k = ncDashClipCard.kind, f = globalState.clipFiles;
                    if (k === "text")  return tr("clip_text");
                    if (k === "image") return tr("clip_image");
                    if (k === "files") return f.length === 1 ? f[0].name : f.length + " " + tr("clip_files");
                    return tr("mod_clipboard");
                }
                font.family: globalState.fontPrimary; font.pixelSize: Math.round(15 * globalState.fontScale); font.weight: Font.Bold
                color: pal.colorOnSurface
                elide: Text.ElideMiddle
            }
            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: {
                    var k = ncDashClipCard.kind;
                    if (k === "text") {
                        var t = globalState.clipText;
                        return t.length + " " + tr("clip_chars") + " · " + t.split("\n").length + " " + tr("clip_lines")
                        + (ncClipBody.ncClipText.activeFocus ? " · " + tr("clip_editing") : "");
                    }
                    if (k === "image") return (globalState.clipImageMime.split("/")[1] || "").toUpperCase() + " · " + fmtBytes(globalState.clipImageBytes);
                    if (k === "files") {
                        var f = globalState.clipFiles;
                        if (f.length === 1) return f[0].path.substring(0, f[0].path.lastIndexOf("/")) || "/";
                        var tot = 0;
                        for (var i = 0; i < f.length; i++) if (f[i].size > 0) tot += f[i].size;
                        return fmtBytes(tot);
                    }
                    return "";
                }
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale)
                color: pal.colorOnSurfVar
                elide: Text.ElideMiddle
            }
        }
        Rectangle {
            visible: globalState.clipHasContent
            Layout.preferredWidth: 30; Layout.preferredHeight: 30
            radius: 10
            color: ncClipGrip.dragging ? ga(pal.primary, 0.28) : (ncClipGripHov.hovered ? ga(pal.colorOnSurfVar, 0.14) : "transparent")
            Behavior on color { M3ColorAnim { duration: m3.durFast } }
            Text {
                anchors.centerIn: parent
                text: ""
                font.family: "Material Symbols Rounded"; font.pixelSize: 18
                color: ncClipGrip.dragging ? pal.primary : pal.colorOnSurfVar
            }
            HoverHandler { id: ncClipGripHov }
            ClipDragSource {
                id: ncClipGrip
                anchors.fill: parent
                mime: ncDashClipCard.dragMime
                onDraggingChanged: globalState.clipDraggingOut = dragging
            }
        }
        ClipIconButton {
            visible: ncDashClipCard.previewPath !== ""
            glyph: ""
            iconColor: pal.colorOnSurfVar; activeColor: pal.primary; hoverColor: ga(pal.colorOnSurfVar, 0.14)
            onClicked: clipOpen(ncDashClipCard.previewPath)
        }
        ClipIconButton {
            visible: ncDashClipCard.kind === "image"
            glyph: ""
            iconColor: pal.colorOnSurfVar; activeColor: pal.primary; hoverColor: ga(pal.colorOnSurfVar, 0.14)
            onClicked: clipSaveImage()
        }
        ClipIconButton {
            visible: globalState.clipHasContent
            glyph: ""
            iconColor: pal.colorOnSurfVar; activeColor: pal.error; hoverColor: Qt.darker(pal.error, 1.6)
            onClicked: clipClear()
        }
    }

    OverviewClipBody { id: ncClipBody }
}
