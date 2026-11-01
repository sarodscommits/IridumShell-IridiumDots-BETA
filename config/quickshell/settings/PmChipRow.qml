import QtQuick
import "../ui"

// Performance-mode chip row
Item {
    id: pcr
    property var options: []
    property var current
    signal picked(var v)
    readonly property int n: options ? options.length : 0
    readonly property real gap: 2
    implicitHeight: 40
    height: implicitHeight
    Row {
        spacing: pcr.gap
        Repeater {
            model: pcr.options
            Item {
                id: pcrOpt
                required property var modelData
                required property int index
                readonly property bool sel: pcr.current === modelData.v
                readonly property bool first: index === 0
                readonly property bool last: index === pcr.n - 1
                width: pcr.n > 0 ? (pcr.width - pcr.gap * (pcr.n - 1)) / pcr.n : 0
                height: pcr.height
                Spring { id: pcrIn; token: "spatialFast"; eps: 0.05; target: pcrOpt.sel ? pcrOpt.height / 2 : (pcrMa.pressed ? 4 : 8) }
                Spring { id: pcrSt; token: "effectsFast"; target: pcrMa.pressed ? 0.12 : (pcrMa.containsMouse ? 0.08 : 0) }
                readonly property real rL: pcrOpt.first ? height / 2 : pcrIn.value
                readonly property real rR: pcrOpt.last ? height / 2 : pcrIn.value
                Rectangle {
                    anchors.fill: parent
                    topLeftRadius: pcrOpt.rL; bottomLeftRadius: pcrOpt.rL; topRightRadius: pcrOpt.rR; bottomRightRadius: pcrOpt.rR
                    color: pcrOpt.sel ? m3.primary : m3.glassy(m3.surfaceContainerHighest, 0.6)
                    Behavior on color { M3ColorAnim { duration: m3.durFast } }
                }
                Rectangle {
                    anchors.fill: parent
                    topLeftRadius: pcrOpt.rL; bottomLeftRadius: pcrOpt.rL; topRightRadius: pcrOpt.rR; bottomRightRadius: pcrOpt.rR
                    color: pcrOpt.sel ? m3.inkPrimary : m3.inkSurface
                    opacity: Math.max(0, pcrSt.value)
                }
                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        visible: !!pcrOpt.modelData.icon
                        anchors.verticalCenter: parent.verticalCenter
                        text: pcrOpt.modelData.icon || ""
                        font.family: "Material Symbols Rounded"; font.pixelSize: 18
                        color: pcrOpt.sel ? m3.inkPrimary : m3.primary
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: pcrOpt.modelData.label
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: pcrOpt.sel ? Font.DemiBold : Font.Medium
                        color: pcrOpt.sel ? m3.inkPrimary : m3.inkSurface
                    }
                }
                MouseArea {
                    id: pcrMa
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { if (!pcrOpt.sel) { globalState.playUiClick(); pcr.picked(pcrOpt.modelData.v); } }
                }
            }
        }
    }
}
