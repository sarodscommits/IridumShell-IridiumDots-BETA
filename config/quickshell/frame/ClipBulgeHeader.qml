import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../panels"

// Clipboard bulge header: type, pin and actions
RowLayout {
    id: clipBulgeHeader
    x: 14; y: 12
    width: parent.width - 28
    height: clipBulgePopup.headerH - 18
    spacing: 8
    Rectangle {
        Layout.preferredWidth: 32; Layout.preferredHeight: 32
        radius: 16
        color: ga(pal.primary, 0.18)
        FadeIcon {
            anchors.centerIn: parent
            text: clipBulgePopup.kind === "image" ? ""
            : clipBulgePopup.kind === "files"
            ? ((globalState.clipFiles.length === 1 && globalState.clipFiles[0].dir) ? "" : "")
            : ""
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
                var k = clipBulgePopup.kind, f = globalState.clipFiles;
                if (k === "text")  return tr("clip_text");
                if (k === "image") return tr("clip_image");
                if (k === "files") return f.length === 1 ? f[0].name : f.length + " " + tr("clip_files");
                return "";
            }
            font.family: globalState.fontPrimary; font.pixelSize: Math.round(14 * globalState.fontScale); font.weight: Font.Bold
            color: pal.colorOnSurface
            elide: Text.ElideMiddle
        }
        Text {
            Layout.fillWidth: true
            text: {
                var k = clipBulgePopup.kind;
                if (k === "text") {
                    var t = globalState.clipText;
                    return t.length + " " + tr("clip_chars") + " · " + t.split("\n").length + " " + tr("clip_lines")
                    + (globalState.clipEditing ? " · " + tr("clip_editing") : "");
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
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale)
            color: pal.colorOnSurfVar
            elide: Text.ElideMiddle
        }
    }
    Rectangle {
        Layout.preferredWidth: 30; Layout.preferredHeight: 30
        radius: 10
        color: clipGripDrag.dragging ? ga(pal.primary, 0.28) : (clipGripHov.hovered ? ga(pal.colorOnSurfVar, 0.14) : "transparent")
        Behavior on color { M3ColorAnim { duration: m3.durFast } }
        Text {
            anchors.centerIn: parent
            text: "\ue945"
            font.family: "Material Symbols Rounded"; font.pixelSize: 18
            color: clipGripDrag.dragging ? pal.primary : pal.colorOnSurfVar
        }
        HoverHandler { id: clipGripHov }
        ClipDragSource {
            id: clipGripDrag
            anchors.fill: parent
            mime: clipBulgePopup.dragMime
            onDraggingChanged: clipBulgePopup.dragStateChanged(dragging)
        }
    }
    ClipIconButton {
        visible: clipBulgePopup.previewPath !== ""
        glyph: ""
        iconColor: pal.colorOnSurfVar; activeColor: pal.primary; hoverColor: ga(pal.colorOnSurfVar, 0.14)
        onClicked: clipOpen(clipBulgePopup.previewPath)
    }
    ClipIconButton {
        visible: clipBulgePopup.kind === "image"
        glyph: ""
        iconColor: pal.colorOnSurfVar; activeColor: pal.primary; hoverColor: ga(pal.colorOnSurfVar, 0.14)
        onClicked: clipSaveImage()
    }
    ClipIconButton {
        glyph: ""
        active: globalState.clipPinned
        iconColor: pal.colorOnSurfVar; activeColor: pal.primary; hoverColor: ga(pal.colorOnSurfVar, 0.14)
        onClicked: { globalState.clipPinned = !globalState.clipPinned; savePrefs(); }
    }
    ClipIconButton {
        glyph: ""
        iconColor: pal.colorOnSurfVar; activeColor: pal.error; hoverColor: Qt.darker(pal.error, 1.6)
        onClicked: clipClear()
    }
    ClipIconButton {
        glyph: ""
        iconColor: pal.colorOnSurfVar; activeColor: pal.primary; hoverColor: ga(pal.colorOnSurfVar, 0.14)
        onClicked: { globalState.clipDismissedSig = globalState.clipSig; globalState.clipBulgeOpen = false; }
    }
}
