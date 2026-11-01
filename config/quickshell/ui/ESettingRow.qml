import QtQuick
import QtQuick.Layouts

// Settings row: icon, label, description, trailing control
RowLayout {
    id: esr
    property string label: ""
    property string desc: ""
    property string icon: ""
    default property alias trailing: esrTrail.data
    Layout.fillWidth: true
    spacing: 14
    Rectangle {
        visible: esr.icon !== ""
        Layout.preferredWidth: 40; Layout.preferredHeight: 40
        radius: 14
        color: m3.glassy(m3.surfaceContainerHighest, 0.6)
        Text { anchors.centerIn: parent; text: esr.icon; font.family: "Material Symbols Rounded"; font.pixelSize: 20; color: m3.primary }
    }
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2
        EText { role: "titleSmall"; text: esr.label; Layout.fillWidth: true; elide: Text.ElideRight }
        EText { role: "bodySmall"; color: m3.inkSurfaceVariant; text: esr.desc; visible: esr.desc !== ""; Layout.fillWidth: true; wrapMode: Text.WordWrap; lineHeightMode: Text.ProportionalHeight; lineHeight: 1.1 }
    }
    RowLayout { id: esrTrail; spacing: 8 }
}
