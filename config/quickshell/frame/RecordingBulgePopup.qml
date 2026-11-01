import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../panels"

// Screen recording bulge popup
Item {
    id: recBulgePopup
    readonly property bool isOpen: globalState.recBulgeOpen && globalState.recActive && globalState.recNotchAllowed && !globalState.frameEffectivelyHidden
    readonly property real natW: recRow.implicitWidth + 28
    readonly property real bulgeW: natW * unifiedFrame.bulgeScale
    readonly property real natDepth: 46

    x: unifiedFrame.barVertical ? unifiedFrame.popupRealX(width) : unifiedFrame.bulgeLeftX
    width: unifiedFrame.barVertical ? unifiedFrame.bulgeDepth : Math.max(0, unifiedFrame.bulgeRightX - unifiedFrame.bulgeLeftX)
    height: unifiedFrame.barVertical ? Math.max(0, unifiedFrame.bulgeRightX - unifiedFrame.bulgeLeftX) : unifiedFrame.bulgeDepth
    opacity: isOpen ? 1 : 0
    Behavior on opacity { M3NumberAnim { duration: recBulgePopup.isOpen ? 220 : 140 } }
    visible: opacity > 0.01
    enabled: isOpen
    y: unifiedFrame.barVertical ? unifiedFrame.bulgeLeftX
    : (unifiedFrame.barAtBottom ? (frameRoot.height - unifiedFrame.frameBottomH - height) : unifiedFrame.frameTopH)
    z: 1000
    clip: true

    function reposition() {
        if (!isOpen) return;
        unifiedFrame.setBulgeFrom(recBulgePopup, frameShape, natDepth * unifiedFrame.bulgeScale, "right");
    }
    function show() {
        if (globalState.lockScreenActive || !globalState.recActive) return;
        if (!globalState.recNotchAllowed) return;
        if (!globalState.recBulgeOpen) { globalState.closeOthers("rec"); globalState.recBulgeOpen = true; }
        else reposition();
    }
    onNatWChanged: reposition()
    onIsOpenChanged: {
        if (isOpen) reposition();
        else if (unifiedFrame.bulgeOwner === recBulgePopup) {
            unifiedFrame.setBulgeFrom(recBulgePopup, frameShape, 0, "right");
        }
    }
    Timer {
        interval: 500; repeat: true
        running: globalState.recActive && !globalState.recBulgeOpen && globalState.recNotchAllowed
        onTriggered: if (!globalState.clipBulgeBusy() && !globalState.clipBulgeOpen) recBulgePopup.show()
    }

    Item {
        width: recBulgePopup.natW
        x: unifiedFrame.barVertical ? (unifiedFrame.barAtLeft ? 0 : parent.width - width) : (parent.width - width) / 2
        height: recBulgePopup.natDepth
        scale: unifiedFrame.bulgeScale
        transformOrigin: unifiedFrame.popupOrigin
        y: unifiedFrame.barVertical ? (parent.height - height) / 2 : (unifiedFrame.barAtBottom ? parent.height - height : 0)

        TextMetrics { id: recTimeMetrics; font.family: globalState.fontPrimary; font.pixelSize: Math.round(14 * globalState.fontScale); font.weight: Font.DemiBold; text: "00:00:00" }
        TextMetrics { id: recSavingMetrics; font.family: globalState.fontPrimary; font.pixelSize: Math.round(14 * globalState.fontScale); font.weight: Font.DemiBold; text: tr("rec_saving") }

        Row {
            id: recRow
            anchors.centerIn: parent
            spacing: 6
            Item {
                width: 18; height: 30
                RecIndicator {
                    id: recDot
                    anchors.centerIn: parent
                    size: 14
                    running: recBulgePopup.isOpen
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.ceil(Math.max(recTimeMetrics.width, recSavingMetrics.width)) + 6
                horizontalAlignment: Text.AlignHCenter
                text: globalState.recSaving ? tr("rec_saving") : globalState.recFmt(globalState.recElapsedMs)
                font: recTimeMetrics.font
                color: globalState.recPaused ? pal.colorOnSurfVar : pal.colorOnSurface
                Behavior on color { M3ColorAnim {} }
            }
            Rectangle { width: 1; height: 18; color: pal.mutedDeep; anchors.verticalCenter: parent.verticalCenter }
            ClipIconButton {
                anchors.verticalCenter: parent.verticalCenter
                enabled: !globalState.recSaving && globalState.recMicCtl
                opacity: enabled ? 1 : 0.4
                glyph: globalState.recMicLive ? "\ue029" : "\ue02b"
                active: globalState.recMicLive
                iconColor: pal.colorOnSurfVar; activeColor: pal.primary; hoverColor: ga(pal.colorOnSurfVar, 0.14)
                onClicked: globalState.recToggleMic()
            }
            ClipIconButton {
                anchors.verticalCenter: parent.verticalCenter
                enabled: !globalState.recSaving
                opacity: enabled ? 1 : 0.4
                glyph: globalState.recPaused ? "\ue037" : "\ue034"
                active: globalState.recPaused
                iconColor: pal.colorOnSurfVar; activeColor: pal.primary; hoverColor: ga(pal.colorOnSurfVar, 0.14)
                onClicked: globalState.recTogglePause()
            }
            ClipIconButton {
                anchors.verticalCenter: parent.verticalCenter
                enabled: !globalState.recSaving
                opacity: enabled ? 1 : 0.4
                glyph: "\ue047"
                iconColor: pal.error; activeColor: pal.error; hoverColor: ga(pal.error, 0.18)
                onClicked: globalState.recStop()
            }
        }
    }
}
