import QtQuick
import QtQuick.Layouts
import "../ui"

// Selectable chip for the desktop editor
Item {
    id: ecRoot
    property bool on: false
    property string icon: ""
    property string label: ""
    property color accent: m3.primary
    property color textColor: m3.inkSurface
    property color offColor: "transparent"
    property string fontFamily: ""
    property real fontScale: 1
    signal clicked()
    implicitHeight: 36
    Spring { id: ecSel; token: "spatialFast"; eps: 0.002; target: ecRoot.on ? 1 : 0 }
    Spring { id: ecSt; token: "effectsFast"; target: ecMa.pressed ? 0.12 : (ecMa.containsMouse ? 0.08 : 0) }
    readonly property real _r: 8 + (height / 2 - 8) * Math.max(0, Math.min(1, ecSel.value))
    Rectangle {
        anchors.fill: parent; radius: ecRoot._r
        color: ecRoot.on ? m3.secondaryContainer : ecRoot.offColor
        border.width: ecRoot.on ? 0 : 1
        border.color: m3.outlineVariant
        Behavior on color { M3ColorAnim { duration: m3.durFast } }
    }
    Rectangle { anchors.fill: parent; radius: ecRoot._r; color: m3.inkSurface; opacity: Math.max(0, ecSt.value) }
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10; anchors.rightMargin: 10
        spacing: 6
        Item {
            Layout.preferredWidth: 16; Layout.preferredHeight: 16
            FadeIcon {
                anchors.centerIn: parent
                text: ecRoot.icon
                font.family: "Material Symbols Rounded"; font.pixelSize: 16
                color: ecRoot.on ? m3.inkSecondaryContainer : m3.primary
            }
        }
        Text {
            Layout.fillWidth: true
            text: ecRoot.label
            font.family: ecRoot.fontFamily; font.pixelSize: Math.round(11 * ecRoot.fontScale); font.weight: Font.Medium
            color: ecRoot.on ? m3.inkSecondaryContainer : m3.inkSurfaceVariant
            elide: Text.ElideRight
        }
    }
    MouseArea { id: ecMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ecRoot.clicked() }
}
