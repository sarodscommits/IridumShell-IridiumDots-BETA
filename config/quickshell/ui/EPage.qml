import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

// Scrollable settings page
Flickable {
    id: epg
    default property alias content: epgCol.data
    contentWidth: width
    contentHeight: epgCol.implicitHeight + 40
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    flickDeceleration: 2500
    maximumFlickVelocity: 4000
    ColumnLayout {
        id: epgCol
        x: 0
        y: 4
        width: epg.width - 14
        spacing: 16
    }
    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
}
