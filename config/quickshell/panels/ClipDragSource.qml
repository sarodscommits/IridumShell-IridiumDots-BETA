import QtQuick
import "../ui"

// Drag source exporting clipboard content
Item {
    id: cds
    property var mime: ({})
    property int hoverCursor: Qt.OpenHandCursor
    readonly property bool dragging: cdsDrag.active
    Drag.dragType: Drag.Automatic
    Drag.supportedActions: Qt.CopyAction
    Drag.proposedAction: Qt.CopyAction
    Drag.mimeData: cds.mime
    Drag.active: cdsDrag.active
    DragHandler {
        id: cdsDrag
        target: null
        dragThreshold: 8
        cursorShape: Qt.ClosedHandCursor
    }
    HoverHandler { cursorShape: cds.hoverCursor }
}
