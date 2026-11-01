import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../widgets"

// Battery charge desktop widget
ExprDesktopWidget {
    id: chargeWidgetRoot
    wType: "charge"
    enabledProp: "chargeWidgetEnabled"; xProp: "chargeWidgetX"; yProp: "chargeWidgetY"; scaleProp: "chargeWidgetScale"
    baseW: 220; baseH: 220
    face: Component {
        Item {
            id: chgFace
            readonly property real u: width / 220
            readonly property bool has: globalState.hasBattery
            readonly property bool chg: has && globalState.batteryCharging
            readonly property bool low: has && !globalState.batteryPlugged && globalState.batteryPercent <= globalState.battLowThreshold
            readonly property real ringM: 10 * u
            readonly property real ringT: m3.ringLw(18 * u)
            readonly property color ink: chg ? m3.inkPrimaryContainer : m3.inkSurface
            readonly property string status: chg ? tr("batt_charging")
            : !has ? tr("dw_ac")
            : globalState.batteryPlugged ? tr("dw_plugged") : tr("dw_on_battery")
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: desktopWidgetLayer.exprDark
            }
            DwRing {
                anchors.fill: parent
                anchors.margins: chgFace.ringM
                thickness: chgFace.ringT
                value: chgFace.has ? globalState.batteryPercent / 100 : 1
                color: chgFace.low ? m3.error : m3.ringActive
                track: chgFace.low ? m3.alpha(m3.error, 0.16) : m3.ringTrack
            }
            Item {
                id: chgCore
                anchors.centerIn: parent
                width: parent.width - 2 * (chgFace.ringM + chgFace.ringT + 9 * chgFace.u); height: width
                Spring { id: chgM; target: chgFace.chg ? 1 : 0; token: "spatialDefault"; eps: 0.002 }
                property real spin: 0
                FrameAnimation {
                    running: chgFace.chg && chargeWidgetRoot.live
                    onTriggered: chgCore.spin = (chgCore.spin + 18 * Math.min(frameTime, 0.05)) % 360
                }
                MBox {
                    anchors.fill: parent
                    from: "Circle"; to: "Cookie12Sided"; t: chgM.value
                    rotation: chgCore.spin
                    fill: chgFace.chg ? m3.primaryContainer : m3.surfaceContainerHigh
                }
                Column {
                    anchors.centerIn: parent
                    spacing: 0
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: chgFace.has
                        text: globalState.batteryPercent
                        font.family: globalState.fontPrimary; font.pixelSize: Math.max(12, Math.round(52 * chgFace.u)); font.weight: Font.Black
                        color: chgFace.low ? m3.error : chgFace.ink
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: !chgFace.has
                        text: ""
                        font.family: "Material Symbols Rounded"; font.pixelSize: Math.max(12, Math.round(44 * chgFace.u))
                        color: m3.primary
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 2 * chgFace.u
                        Text {
                            visible: chgFace.chg
                            anchors.verticalCenter: parent.verticalCenter
                            text: ""
                            font.family: "Material Symbols Rounded"; font.pixelSize: Math.max(7, Math.round(13 * chgFace.u))
                            color: chgFace.ink
                        }
                        Text {
                            text: chgFace.status
                            font.family: globalState.fontSecondary; font.pixelSize: Math.max(7, Math.round(12 * chgFace.u)); font.weight: Font.DemiBold
                            color: chgFace.ink
                        }
                    }
                }
            }
        }
    }
}
