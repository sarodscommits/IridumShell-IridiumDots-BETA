import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Session buttons (lock, logout, restart, shutdown)
Row {
    id: lockSessionRow
    property alias lockNotifSlot: lockNotifSlot
    property alias lockPowerBar: lockPowerBar
    readonly property real topGap: 24
    width: Math.round(lockPwArea.width * 0.82)
    height: 40
    x: lockContent.modulesCX - width / 2
    y: lockContent.modulesCY - lockContent.stackH / 2
    opacity: lockContent.blurDragging ? 0 : 1
    Behavior on opacity { M3NumberAnim { duration: m3.durFast } }
    spacing: gap
    readonly property int gap: 2
    readonly property real innerRadius: 4

    Rectangle {
        id: lockPowerBar
        width:  (lockSessionRow.width - lockSessionRow.gap) * 2 / 3
        height: lockSessionRow.height
        topLeftRadius:     height / 2
        bottomLeftRadius:  height / 2
        topRightRadius:    lockSessionRow.innerRadius
        bottomRightRadius: lockSessionRow.innerRadius
        color: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont)

        RowLayout {
            id: lockPowerRow
            anchors.centerIn: parent
            spacing: 4
            BumpCtl { id: lockPwrBump; px: 6 }
            Repeater {
                model: [
                { icon: "", label: tr("logout"),   key: "logout",   cmd: ["hyprctl", "dispatch", "hl.dsp.exit()"] },
                { icon: "", label: tr("restart"),  key: "restart",  cmd: ["systemctl", "reboot"] },
                { icon: "", label: tr("shutdown"), key: "shutdown", cmd: ["systemctl", "poweroff"] },
                ]
                EButton {
                    required property var modelData
                    required property int index
                    size: "xxs"
                    icon: modelData.icon
                    text: modelData.label
                    fontFamily: globalState.fontSecondary
                    variant: modelData.key === "logout" ? "tonal" : "error"
                    widthOffset: lockPwrBump.dw(index, 3)
                    Layout.preferredWidth: implicitWidth
                    onPressedChanged: if (pressed) lockPwrBump.bump(index)
                    onClicked: globalState.requestPowerAction(modelData.key)
                }
            }
        }
    }

    Item {
        id: lockNotifSlot
        width:  lockSessionRow.width - lockPowerBar.width - lockSessionRow.gap
        height: lockSessionRow.height
    }
}
