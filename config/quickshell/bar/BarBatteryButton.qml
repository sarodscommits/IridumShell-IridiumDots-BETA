import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Battery button of the bar
Item {
    id: battBtn
    property alias battBtnHover: battBtnHover
    visible: globalState.barModules.battery
    Layout.alignment: Qt.AlignCenter
    implicitWidth: unifiedFrame.barVertical ? 28 : battRow.implicitWidth + (globalState.hasBattery ? 16 : 12)
    implicitHeight: unifiedFrame.barVertical ? battRow.implicitHeight + 6 : 28
    EBarSlot { anchors.fill: parent; active: battBulgePopup.isOpen; hovered: battBtnHover.hovered; restRadius: 14 }

    GridLayout {
        id: battRow
        anchors.centerIn: parent
        columns: unifiedFrame.barVertical ? 1 : 2
        rowSpacing: 0
        columnSpacing: 4
        opacity: globalState.glassMode ? 0.88 : 1.0
        FadeIcon {
            text: !globalState.hasBattery
            ? "\ue63c"
            : (globalState.batteryCharging || globalState.batteryPlugged)
            ? "\ue1a3"
            : globalState.batteryPercent <= globalState.battLowThreshold
            ? "\ue19c"
            : "\ue1a4"
            font.family: "Material Symbols Rounded"; font.pixelSize: 15
            color: !globalState.hasBattery ? pal.primary
            : (globalState.batteryCharging || globalState.batteryPlugged) ? pal.primary
            : globalState.batteryPercent <= globalState.battLowThreshold ? pal.error
            : pal.colorOnSurfVar
        }
        Text {
            visible: globalState.hasBattery
            Layout.alignment: Qt.AlignHCenter
            text: unifiedFrame.barVertical ? ("" + globalState.batteryPercent) : (globalState.batteryPercent + "%")
            font.family: globalState.fontSecondary; font.pixelSize: Math.round((unifiedFrame.barVertical ? 10 : 12) * globalState.fontScale); font.weight: Font.Medium
            color: pal.colorOnSurfVar
        }
    }
    HoverHandler {
        id: battBtnHover
        onHoveredChanged: {
            if (globalState.desktopEditMode) return;
            if (hovered) battBulgePopup.show();
            else battBulgePopup.scheduleClose();
        }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: if (!globalState.desktopEditMode) battBulgePopup.show()
    }
}
