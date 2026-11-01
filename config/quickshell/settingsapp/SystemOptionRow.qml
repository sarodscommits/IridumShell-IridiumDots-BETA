import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."

// Settings > System: labelled option inside a secondary card (label row + control below)
ColumnLayout {
    id: orow
    property string icon: ""
    property string label: ""
    property string hint: ""
    property string valueText: ""
    default property alias control: orBody.data
    Layout.fillWidth: true
    spacing: 6

    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Text { text: orow.icon; font.family: "Material Symbols Rounded"; font.pixelSize: 15; color: pal.primary }
        Text {
            Layout.fillWidth: true
            text: orow.label
            elide: Text.ElideRight
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
            color: pal.colorOnSurfVar
        }
        Text {
            visible: text !== ""
            text: orow.valueText
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale)
            color: pal.muted
        }
    }
    ColumnLayout { id: orBody; Layout.fillWidth: true; spacing: 4 }
    Text {
        Layout.fillWidth: true
        visible: orow.hint !== ""
        text: orow.hint
        wrapMode: Text.WordWrap
        font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale)
        color: pal.muted
    }
}
