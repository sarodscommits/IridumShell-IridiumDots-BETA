import QtQuick

// Workspaces menu (below the pager): latest capture of each workspace.
Item {
    id: wsStrip
    required property var win
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 34
    height: win.wsStripH
    width: Math.min(parent.width * 0.9, wsRow.width + 24)

    Rectangle {
        anchors.fill: parent
        radius: 22
        color: win.gs.glassMode ? win.ga(win.colors.surfaceElevated, 0.55) : win.colors.surfaceElevated
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)
    }

    Flickable {
        anchors.fill: parent
        anchors.margins: 12
        contentWidth: wsRow.width
        contentHeight: height
        clip: true
        interactive: contentWidth > width
        boundsBehavior: Flickable.StopAtBounds
        Row {
            id: wsRow
            spacing: 14
            height: parent.height
            Repeater {
                model: win.wsList
                delegate: WorkspaceCard { win: wsStrip.win }
            }
        }
    }
}
