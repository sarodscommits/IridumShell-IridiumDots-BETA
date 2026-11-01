import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Power menu popup
Item {
    id: powerMenuPopup
    property alias powerPopupHover: powerPopupHover
    property bool isOpen: globalState.powerMenuOpen
    readonly property real bulgeW: (pwrPopupRow.implicitWidth + 16) * unifiedFrame.bulgeScale
    readonly property real natDepth: unifiedFrame.barVertical ? pwrPopupRow.implicitHeight + 16 : 40
    x: unifiedFrame.barVertical ? unifiedFrame.popupRealX(width) : unifiedFrame.bulgeLeftX
    width: unifiedFrame.barVertical ? unifiedFrame.bulgeDepth : Math.max(0, unifiedFrame.bulgeRightX - unifiedFrame.bulgeLeftX)
    height: unifiedFrame.barVertical ? Math.max(0, unifiedFrame.bulgeRightX - unifiedFrame.bulgeLeftX) : unifiedFrame.bulgeDepth
    opacity: isOpen ? 1 : 0
    Behavior on opacity { M3NumberAnim { duration: powerMenuPopup.isOpen ? 220 : 140 } }
    visible: opacity > 0.01
    enabled: isOpen
    y: unifiedFrame.barVertical ? unifiedFrame.bulgeLeftX
    : (unifiedFrame.barAtBottom ? (frameRoot.height - unifiedFrame.frameBottomH - height) : unifiedFrame.frameTopH)
    z: 1000
    clip: true

    HoverHandler { id: powerPopupHover }

    onIsOpenChanged: unifiedFrame.setBulgeUnder(powerMenuPopup, topBarContent.barGroupRight.sessionBtnWrap, isOpen ? natDepth * unifiedFrame.bulgeScale : 0)

    GridLayout {
        id: pwrPopupRow
        anchors.centerIn: parent
        scale: unifiedFrame.bulgeScale
        columns: unifiedFrame.barVertical ? 1 : 4
        rowSpacing: 4
        columnSpacing: 4
        BumpCtl { id: pwrBump; px: 6 }
        Repeater {
            model: [
            { icon: "\ue897", label: tr("lock"),     key: "lock",     cmd: [] },
            { icon: "\ue9ba", label: tr("logout"),   key: "logout",   cmd: ["hyprctl", "dispatch", "hl.dsp.exit()"] },
            { icon: "\ue8b3", label: tr("restart"),  key: "restart",  cmd: ["systemctl", "reboot"] },
            { icon: "\ue8ac", label: tr("shutdown"), key: "shutdown", cmd: ["systemctl", "poweroff"] },
            ]
            EButton {
                required property var modelData
                required property int index
                size: "xs"
                icon: modelData.icon
                text: modelData.label
                fontFamily: globalState.fontSecondary
                variant: modelData.key === "lock" ? "filled" : (modelData.key === "logout" ? "tonal" : "error")
                widthOffset: unifiedFrame.barVertical ? 0 : pwrBump.dw(index, 4)
                Layout.fillWidth: unifiedFrame.barVertical
                Layout.preferredWidth: implicitWidth
                opacity: globalState.glassMode ? 0.92 : 1.0
                onPressedChanged: if (pressed) pwrBump.bump(index)
                onClicked: globalState.requestPowerAction(modelData.key)
            }
        }
    }
}
