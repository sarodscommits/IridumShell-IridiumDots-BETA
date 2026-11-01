import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../widgets"

// System overview desktop widget
ExprDesktopWidget {
    id: sysWidgetRoot
    wType: "sys"
    enabledProp: "sysWidgetEnabled"; xProp: "sysWidgetX"; yProp: "sysWidgetY"; scaleProp: "sysWidgetScale"
    baseW: 330; baseH: 220
    face: Component {
        Item {
            id: sysFace
            readonly property real u: width / 330
            readonly property real gap: 10 * u
            readonly property real diskUsed: parseFloat(globalState.diskUsedStr) || 0
            readonly property real diskTotal: parseFloat(globalState.diskTotalStr) || 0
            function gb(v) { return v >= 1000 ? (v / 1024).toFixed(1) + " TB" : Math.round(v) + " GB"; }

            Rectangle {
                id: sysDiskPill
                width: parent.width
                height: Math.round(parent.height * 0.36)
                radius: height / 2
                color: desktopWidgetLayer.exprDark
                Column {
                    anchors.left: parent.left; anchors.leftMargin: parent.height * 0.42
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        text: tr("dw_used")
                        font.family: globalState.fontSecondary; font.pixelSize: Math.max(7, Math.round(11 * sysFace.u))
                        color: pal.colorOnSurfVar
                    }
                    Text {
                        text: sysFace.diskTotal > 0 ? sysFace.gb(sysFace.diskUsed) : "—"
                        font.family: globalState.fontPrimary; font.pixelSize: Math.max(8, Math.round(17 * sysFace.u)); font.weight: Font.Bold
                        color: pal.colorOnSurface
                    }
                }
                Column {
                    anchors.right: parent.right; anchors.rightMargin: parent.height * 0.42
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        anchors.right: parent.right
                        text: tr("dw_free")
                        font.family: globalState.fontSecondary; font.pixelSize: Math.max(7, Math.round(11 * sysFace.u))
                        color: pal.colorOnSurfVar
                    }
                    Text {
                        anchors.right: parent.right
                        text: sysFace.diskTotal > 0 ? sysFace.gb(Math.max(0, sysFace.diskTotal - sysFace.diskUsed)) : "—"
                        font.family: globalState.fontPrimary; font.pixelSize: Math.max(8, Math.round(17 * sysFace.u)); font.weight: Font.Bold
                        color: pal.colorOnSurface
                    }
                }
                Item {
                    anchors.centerIn: parent
                    width: parent.height - 8 * sysFace.u; height: width
                    DwRing {
                        anchors.fill: parent
                        thickness: Math.max(1.5, m3.ringLw(4 * sysFace.u))
                        value: globalState.diskPercent / 100
                        color: globalState.diskPercent >= 90 ? m3.error : m3.ringActive
                        track: m3.ringTrack
                    }
                    MBox {
                        anchors.fill: parent
                        anchors.margins: 7 * sysFace.u
                        from: "Cookie9Sided"
                        rotation: globalState.diskPercent * 1.8
                        fill: m3.primaryContainer
                    }
                    Text {
                        anchors.centerIn: parent
                        text: ""
                        font.family: "Material Symbols Rounded"; font.pixelSize: Math.max(10, Math.round(parent.width * 0.34))
                        color: m3.inkPrimaryContainer
                    }
                }
            }

            Row {
                y: sysDiskPill.height + sysFace.gap
                width: parent.width
                height: parent.height - y
                spacing: sysFace.gap
                LoadBlob {
                    width: (parent.width - 2 * sysFace.gap) / 3; height: parent.height
                    value: globalState.cpuPercent; label: tr("cpu_lbl")
                    fill: m3.primaryContainer; ink: m3.inkPrimaryContainer
                    live: sysWidgetRoot.live
                }
                LoadBlob {
                    width: (parent.width - 2 * sysFace.gap) / 3; height: parent.height
                    value: globalState.gpuPercent; label: tr("gpu_lbl")
                    fill: m3.tertiaryContainer; ink: m3.inkTertiaryContainer
                    live: sysWidgetRoot.live
                }
                LoadBlob {
                    width: (parent.width - 2 * sysFace.gap) / 3; height: parent.height
                    value: globalState.ramPercent; label: tr("ram_lbl")
                    fill: m3.secondaryContainer; ink: m3.inkSecondaryContainer
                    live: sysWidgetRoot.live
                }
            }
        }
    }
}
