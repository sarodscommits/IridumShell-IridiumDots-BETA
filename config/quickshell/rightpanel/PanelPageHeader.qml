import QtQuick
import QtQuick.Layouts
import "../ui"

// Right-panel sub-page header: back, title, refresh
RowLayout {
    id: pph
    property string title: ""
    property bool scanning: false
    signal back()
    signal refresh()
    Layout.fillWidth: true
    spacing: 8

    PressIconButton {
        size: 32; cornerRadius: 10
        icon: ""; iconSize: 18
        onClicked: pph.back()
    }

    Text {
        text: pph.title
        font.family: globalState.fontPrimary; font.pixelSize: Math.round(14 * globalState.fontScale); font.weight: Font.DemiBold
        color: pal.colorOnSurface
        Layout.fillWidth: true
    }

    PressIconButton {
        size: 38; cornerRadius: 12
        icon: ""; iconSize: 20
        iconVisible: !pph.scanning
        onClicked: pph.refresh()
        MorphLoader {
            anchors.centerIn: parent
            size: 22
            fillColor: pal.primary
            visible: running
            running: pph.scanning
        }
    }
}
