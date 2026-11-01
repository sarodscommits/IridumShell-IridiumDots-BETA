import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../panels"

// Clipboard bulge body: text, image or file list
Item {
    id: clipBody
    property alias clipPreviewImg: clipPreviewImg
    property alias clipTextArea: clipTextArea
    x: 14; y: clipBulgePopup.headerH
    width: clipBulgePopup.innerW
    height: clipBulgePopup.bodyH

    ScrollView {
        id: clipTextScroll
        anchors.fill: parent
        visible: clipBulgePopup.kind === "text"
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        background: Rectangle {
            radius: 14
            color: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont)
            border.width: clipTextArea.activeFocus ? 1.5 : 0
            border.color: pal.primary
        }
        TextArea {
            id: clipTextArea
            background: null
            wrapMode: TextEdit.Wrap
            textFormat: TextEdit.PlainText
            selectByMouse: true
            persistentSelection: true
            leftPadding: 12; rightPadding: 12; topPadding: 10; bottomPadding: 10
            font.family: globalState.fontSecondary
            font.pixelSize: Math.round(13 * globalState.fontScale)
            color: pal.colorOnSurface
            selectionColor: pal.primary
            selectedTextColor: pal.colorOnPrimary
            Component.onCompleted: text = globalState.clipText
            onActiveFocusChanged: {
                globalState.clipEditing = activeFocus;
                if (activeFocus) clipFocusTimer.restart();
            }
            onTextChanged: if (activeFocus) clipWriteDebounce.restart()
            Keys.onEscapePressed: clipTextArea.focus = false
        }
    }

    Rectangle {
        visible: clipBulgePopup.previewPath !== ""
        width: parent.width
        height: clipBulgePopup.previewH
        radius: 14
        color: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont)
        Image {
            id: clipPreviewImg
            anchors.fill: parent
            anchors.margins: 6
            source: clipBulgePopup.previewPath !== "" ? fileUrl(clipBulgePopup.previewPath) : ""
            fillMode: Image.PreserveAspectFit
            sourceSize.width: 900
            asynchronous: true; cache: false; smooth: true; mipmap: true
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onDoubleClicked: clipOpen(clipBulgePopup.previewPath)
        }
        ClipDragSource {
            anchors.fill: parent
            mime: clipBulgePopup.mimeForFiles([clipBulgePopup.previewPath])
            onDraggingChanged: clipBulgePopup.dragStateChanged(dragging)
        }
    }
    Text {
        visible: clipBulgePopup.previewPath !== "" && clipBulgePopup.kind === "files"
        y: clipBulgePopup.previewH + 6
        width: parent.width
        text: globalState.clipFiles.length > 0
        ? globalState.clipFiles[0].name + "  ·  " + fmtBytes(globalState.clipFiles[0].size) : ""
        font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale)
        color: pal.colorOnSurfVar
        elide: Text.ElideMiddle
    }

    Column {
        visible: clipBulgePopup.kind === "files" && clipBulgePopup.previewPath === ""
        width: parent.width
        spacing: 4
        Repeater {
            model: globalState.clipFiles.slice(0, 5)
            delegate: Rectangle {
                id: clipFileRow
                required property var modelData
                width: clipBody.width
                height: 40
                radius: 12
                color: clipFileHov.hovered ? pal.surfaceVar
                : (globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont))
                Behavior on color { M3ColorAnim { duration: m3.durFast } }
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8; anchors.rightMargin: 12
                    spacing: 10
                    Item {
                        Layout.preferredWidth: 28; Layout.preferredHeight: 28
                        readonly property bool isImg: clipIsImage(clipFileRow.modelData.path)
                        Image {
                            anchors.fill: parent
                            visible: parent.isImg
                            source: parent.isImg ? fileUrl(clipFileRow.modelData.path) : ""
                            sourceSize: Qt.size(64, 64)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                        FadeIcon {
                            anchors.centerIn: parent
                            visible: !parent.isImg
                            text: clipFileRow.modelData.dir ? "" : ""
                            font.family: "Material Symbols Rounded"; font.pixelSize: 18
                            color: pal.primary
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: clipFileRow.modelData.name
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                        color: pal.colorOnSurface
                        elide: Text.ElideMiddle
                    }
                    Text {
                        text: clipFileRow.modelData.dir ? "" : fmtBytes(clipFileRow.modelData.size)
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale)
                        color: pal.muted
                    }
                }
                HoverHandler { id: clipFileHov }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: clipOpen(clipFileRow.modelData.path)
                }
                ClipDragSource {
                    anchors.fill: parent
                    mime: clipBulgePopup.mimeForFiles([clipFileRow.modelData.path])
                    onDraggingChanged: clipBulgePopup.dragStateChanged(dragging)
                }
            }
        }
        Text {
            visible: globalState.clipFiles.length > 5
            text: "+" + (globalState.clipFiles.length - 5) + " " + tr("clip_more")
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale)
            color: pal.muted
        }
    }
}
