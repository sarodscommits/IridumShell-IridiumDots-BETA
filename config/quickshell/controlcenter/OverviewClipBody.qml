import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import ".."
import "../panels"
import "../ui"

// Clipboard preview body of the overview dashboard
Item {
    id: ncClipBody
    property alias ncClipText: ncClipText
    anchors.left: parent.left; anchors.right: parent.right
    anchors.top: ncClipHeader.bottom; anchors.bottom: parent.bottom
    anchors.leftMargin: 14; anchors.rightMargin: 14
    anchors.topMargin: 12; anchors.bottomMargin: 14

    Column {
        anchors.centerIn: parent
        visible: !globalState.clipHasContent
        spacing: 6
        FadeIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            text: globalState.clipKind === "secret" ? "" : ""
            font.family: "Material Symbols Rounded"; font.pixelSize: 36
            color: pal.muted
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: globalState.clipKind === "secret" ? "••••••••" : tr("clip_drop")
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale)
            color: pal.muted
        }
    }

    ScrollView {
        anchors.fill: parent
        visible: ncDashClipCard.kind === "text"
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        background: Rectangle {
            radius: 16
            color: globalState.glassMode ? ga(pal.surface, 0.5) : pal.surface
            border.width: ncClipText.activeFocus ? 1.5 : 0
            border.color: pal.primary
        }
        TextArea {
            id: ncClipText
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
                if (!activeFocus) ncDashClipCard.flushEdit();
            }
            onTextChanged: if (activeFocus) ncClipWriteDebounce.restart()
            Keys.onEscapePressed: ncClipText.focus = false
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: ncDashClipCard.previewPath !== ""
        radius: 16
        color: globalState.glassMode ? ga(pal.surface, 0.5) : pal.surface
        Image {
            anchors.fill: parent
            anchors.margins: 6
            source: (ncDashClipCard.previewPath !== "" && ncDashClipCard.visible) ? fileUrl(ncDashClipCard.previewPath) : ""
            fillMode: Image.PreserveAspectFit
            sourceSize.width: 900
            asynchronous: true; cache: false; smooth: true; mipmap: true
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onDoubleClicked: clipOpen(ncDashClipCard.previewPath)
        }
        ClipDragSource {
            anchors.fill: parent
            mime: clipBulgePopup.mimeForFiles([ncDashClipCard.previewPath])
            onDraggingChanged: globalState.clipDraggingOut = dragging
        }
    }

    ListView {
        anchors.fill: parent
        visible: ncDashClipCard.kind === "files" && ncDashClipCard.previewPath === ""
        clip: true
        spacing: 4
        model: visible ? globalState.clipFiles : []
        delegate: Rectangle {
            id: ncClipFileRow
            required property var modelData
            width: ListView.view.width
            height: 40
            radius: 12
            color: ncClipFileHov.hovered ? pal.surfaceVar
            : (globalState.glassMode ? ga(pal.surface, 0.5) : pal.surface)
            Behavior on color { M3ColorAnim { duration: m3.durFast } }
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8; anchors.rightMargin: 12
                spacing: 10
                Item {
                    Layout.preferredWidth: 28; Layout.preferredHeight: 28
                    readonly property bool isImg: clipIsImage(ncClipFileRow.modelData.path)
                    Image {
                        anchors.fill: parent
                        visible: parent.isImg
                        source: parent.isImg ? fileUrl(ncClipFileRow.modelData.path) : ""
                        sourceSize: Qt.size(64, 64)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                    FadeIcon {
                        anchors.centerIn: parent
                        visible: !parent.isImg
                        text: ncClipFileRow.modelData.dir ? "" : ""
                        font.family: "Material Symbols Rounded"; font.pixelSize: 18
                        color: pal.primary
                    }
                }
                Text {
                    Layout.fillWidth: true
                    text: ncClipFileRow.modelData.name
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                    color: pal.colorOnSurface
                    elide: Text.ElideMiddle
                }
                Text {
                    text: ncClipFileRow.modelData.dir ? "" : fmtBytes(ncClipFileRow.modelData.size)
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale)
                    color: pal.muted
                }
            }
            HoverHandler { id: ncClipFileHov }
            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: clipOpen(ncClipFileRow.modelData.path)
            }
            ClipDragSource {
                anchors.fill: parent
                mime: clipBulgePopup.mimeForFiles([ncClipFileRow.modelData.path])
                onDraggingChanged: globalState.clipDraggingOut = dragging
            }
        }
    }
}
