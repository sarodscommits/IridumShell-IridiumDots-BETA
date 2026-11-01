import QtQuick
import QtQuick.Layouts

// Segmented list row; group ends and selection get larger radii
Rectangle {
    id: eli2
    property bool first: false
    property bool last: false
    property bool selected: false
    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property real rowH: 64
    property real outerR: m3.corner(20)
    default property alias trailing: eliTrail.data
    signal clicked()
    implicitHeight: rowH
    Spring { id: eliS; target: eli2.selected ? 1 : 0; token: "spatialFast"; eps: 0.002 }
    Spring { id: eliH; target: eliMa.containsMouse ? 1 : 0; token: "effectsFast" }
    readonly property real r: 4 + (outerR - 4) * Math.max(0, Math.min(1, eliS.value))
    topLeftRadius: first ? outerR : r; topRightRadius: first ? outerR : r
    bottomLeftRadius: last ? outerR : r; bottomRightRadius: last ? outerR : r
    color: m3.state(selected ? m3.secondaryContainer : m3.glassy(m3.surfaceContainerHigh, 0.6), m3.inkSurface, 0.06 * eliH.value)
    Behavior on color { ColorAnimation { duration: 160 } }
    MouseArea { id: eliMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: eli2.clicked() }
    RowLayout {
        anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12
        spacing: 12
        Rectangle {
            visible: eli2.icon !== ""
            Layout.preferredWidth: 40; Layout.preferredHeight: 40
            radius: eli2.selected ? 14 : 20
            Behavior on radius { M3SpringAnim { token: "spatialFast" } }
            color: eli2.selected ? m3.primary : m3.surfaceContainerHighest
            EIcon { anchors.centerIn: parent; name: eli2.icon; size: 22; color: eli2.selected ? m3.inkPrimary : m3.inkSurfaceVariant; filled: eli2.selected }
        }
        ColumnLayout {
            Layout.fillWidth: true; spacing: 0
            EText { Layout.fillWidth: true; text: eli2.title; role: "titleSmall"; elide: Text.ElideRight; color: eli2.selected ? m3.inkSecondaryContainer : m3.inkSurface }
            EText { Layout.fillWidth: true; visible: text !== ""; text: eli2.subtitle; role: "bodySmall"; elide: Text.ElideRight; color: m3.inkSurfaceVariant }
        }
        RowLayout { id: eliTrail; spacing: 8 }
    }
}
