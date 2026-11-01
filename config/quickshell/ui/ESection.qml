import QtQuick
import QtQuick.Layouts

Rectangle {
    id: esec
    default property alias content: esecInner.data
    property string title: ""
    property string subtitle: ""
    property string icon: ""
    property alias headerTrailing: esecTrail.data
    Layout.fillWidth: true
    radius: m3.corner(28)
    color: m3.glassy(m3.surfaceContainerLow, 0.6)
    implicitHeight: esecCol.implicitHeight + 48
    ColumnLayout {
        id: esecCol
        x: 24; y: 24
        width: esec.width - 48
        spacing: 18
        RowLayout {
            Layout.fillWidth: true
            spacing: 14
            visible: esec.title !== ""
            Item {
                visible: esec.icon !== ""
                Layout.preferredWidth: 44; Layout.preferredHeight: 44
                Layout.alignment: Qt.AlignTop
                MShape { anchors.fill: parent; inset: 1.0; from: m3.accentShape; to: m3.accentShape; fill: m3.secondaryContainer }
                Text { anchors.centerIn: parent; text: esec.icon; font.family: "Material Symbols Rounded"; font.pixelSize: 22; color: m3.inkSecondaryContainer }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                EText { role: "titleLarge"; emph: true; text: esec.title; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                EText { role: "bodyMedium"; color: m3.inkSurfaceVariant; text: esec.subtitle; visible: esec.subtitle !== ""; Layout.fillWidth: true; wrapMode: Text.WordWrap; lineHeightMode: Text.ProportionalHeight; lineHeight: 1.15 }
            }
            RowLayout { id: esecTrail; spacing: 8; Layout.alignment: Qt.AlignTop }
        }
        ColumnLayout { id: esecInner; Layout.fillWidth: true; spacing: 16 }
    }
}
