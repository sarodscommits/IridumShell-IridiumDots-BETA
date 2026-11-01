import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../widgets"
import "../ui/SvgPaths.js" as SvgPaths

// Battery bulge popup
Item {
    id: battBulgePopup
    readonly property bool isOpen: globalState.battBulgeOpen
    && globalState.barModules.battery && !globalState.frameEffectivelyHidden
    readonly property real natW: 300
    readonly property real bulgeW: natW * unifiedFrame.bulgeScale
    readonly property real topH: globalState.hasBattery ? 128 : 76
    readonly property real natDepth: topH + battPerfBox.height + 14
    readonly property bool low: !globalState.batteryPlugged && globalState.batteryPercent <= globalState.battLowThreshold
    readonly property color accent: low ? pal.error : pal.primary
    readonly property string statusText: {
        var st = globalState.batteryStatus;
        if (globalState.batteryCharging) return tr("batt_charging");
        if (st === "Full" || (globalState.batteryPlugged && globalState.batteryPercent >= 100)) return tr("batt_full");
        if (globalState.batteryPlugged) return tr("batt_plugged");
        return tr("batt_discharging");
    }
    readonly property string timeText: {
        var m = globalState.batteryMinutes;
        if (m < 0 || (!globalState.batteryCharging && globalState.batteryPlugged)) return "";
        var h = Math.floor(m / 60), mm = m % 60;
        var t = h > 0 ? (h + " h " + (mm < 10 ? "0" : "") + mm + " min") : (mm + " min");
        return t + " " + (globalState.batteryCharging ? tr("batt_to_full") : tr("batt_left"));
    }

    x: unifiedFrame.barVertical ? unifiedFrame.popupRealX(width) : unifiedFrame.bulgeLeftX
    width: unifiedFrame.barVertical ? unifiedFrame.bulgeDepth : Math.max(0, unifiedFrame.bulgeRightX - unifiedFrame.bulgeLeftX)
    height: unifiedFrame.barVertical ? Math.max(0, unifiedFrame.bulgeRightX - unifiedFrame.bulgeLeftX) : unifiedFrame.bulgeDepth
    opacity: isOpen ? 1 : 0
    Behavior on opacity { M3NumberAnim { duration: battBulgePopup.isOpen ? 220 : 140 } }
    visible: opacity > 0.01
    enabled: isOpen
    y: unifiedFrame.barVertical ? unifiedFrame.bulgeLeftX
    : (unifiedFrame.barAtBottom ? (frameRoot.height - unifiedFrame.frameBottomH - height) : unifiedFrame.frameTopH)
    z: 1000
    clip: true

    function reposition() {
        if (isOpen) unifiedFrame.setBulgeUnder(battBulgePopup, topBarContent.barGroupRight.battBtn, natDepth * unifiedFrame.bulgeScale);
    }
    function show() {
        battCloseTimer.stop();
        if (globalState.lockScreenActive) return;
        if (globalState.battBulgeOpen && unifiedFrame.bulgeOwner !== battBulgePopup) globalState.battBulgeOpen = false;
        if (!globalState.battBulgeOpen) {
            globalState.closeOthers("batt"); globalState.battBulgeOpen = true;
            if (!gmPerfReadProc.running && !gmPerfProc.running) gmPerfReadProc.running = true;
        }
        else reposition();
    }
    function scheduleClose() { battCloseTimer.restart(); }
    onIsOpenChanged: {
        if (isOpen) reposition();
        else {
            battCloseTimer.stop();
            if (unifiedFrame.bulgeOwner === battBulgePopup) unifiedFrame.setBulgeUnder(battBulgePopup, topBarContent.barGroupRight.battBtn, 0);
        }
    }
    Connections {
        target: unifiedFrame
        function onBulgeOwnerChanged() {
            if (battBulgePopup.isOpen && unifiedFrame.bulgeOwner !== battBulgePopup)
            globalState.battBulgeOpen = false;
        }
        function onBulgeDepthChanged() {
            if (battBulgePopup.isOpen && unifiedFrame.bulgeOwner === battBulgePopup && unifiedFrame.bulgeDepth < 0.5)
            Qt.callLater(battBulgePopup.reposition);
        }
    }
    Connections {
        target: topBarContent.barGroupRight.battBtn
        function onWidthChanged() { battBulgePopup.reposition(); }
        function onXChanged()     { battBulgePopup.reposition(); }
        function onHeightChanged() { if (unifiedFrame.barVertical) battBulgePopup.reposition(); }
        function onYChanged()      { if (unifiedFrame.barVertical) battBulgePopup.reposition(); }
    }
    Timer {
        id: battCloseTimer
        interval: 320; repeat: false
        onTriggered: { if (!battPopupHover.hovered && !topBarContent.barGroupRight.battBtn.battBtnHover.hovered) globalState.battBulgeOpen = false; }
    }
    HoverHandler {
        id: battPopupHover
        onHoveredChanged: { if (hovered) battCloseTimer.stop(); else battBulgePopup.scheduleClose(); }
    }

    Item {
        id: battContent
        width: battBulgePopup.natW
        x: unifiedFrame.barVertical ? (unifiedFrame.barAtLeft ? 0 : parent.width - width) : (parent.width - width) / 2
        height: battBulgePopup.natDepth
        scale: unifiedFrame.bulgeScale
        transformOrigin: unifiedFrame.popupOrigin
        y: unifiedFrame.barVertical ? (parent.height - height) / 2 : (unifiedFrame.barAtBottom ? parent.height - height : 0)

        RowLayout {
            visible: !globalState.hasBattery
            x: 16; width: battBulgePopup.natW - 32
            y: (battBulgePopup.topH - height) / 2
            spacing: 12
            Item {
                Layout.preferredWidth: 44; Layout.preferredHeight: 44
                Spring { id: battAcSpin; target: battBulgePopup.isOpen ? 0 : -90; token: "spatialDefault"; eps: 0.05 }
                MShape {
                    anchors.fill: parent
                    inset: 1.0
                    from: "SoftBurst"; to: "SoftBurst"
                    rotation: battAcSpin.value
                    fill: ga(pal.primary, 0.18)
                }
                Text {
                    anchors.centerIn: parent
                    text: "\ue63c"
                    font.family: "Material Symbols Rounded"; font.pixelSize: 22
                    color: pal.primary
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text {
                    Layout.fillWidth: true
                    text: tr("batt_ac_title")
                    font.family: globalState.fontPrimary; font.pixelSize: Math.round(14 * globalState.fontScale); font.weight: Font.Bold
                    color: pal.colorOnSurface
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: tr("batt_ac_body")
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale)
                    color: pal.colorOnSurfVar
                    elide: Text.ElideRight
                }
            }
        }
        ShapeGauge {
            id: battGauge
            visible: globalState.hasBattery
            x: 16
            y: (battBulgePopup.topH - height) / 2
            width: 100; height: 100
            shapePath: SvgPaths.battery
            fillMin: 13; fillMax: 96
            pct: globalState.batteryPercent / 100
            glassEmpty: globalState.glassMode
            waveEffect: true
            wavePhase: battBulgePopup.isOpen ? globalState.wavePhase : 0
            fillColor: battBulgePopup.accent
            emptyColor: pal.surfaceDeep
            outlineColor: pal.mutedDeep
            Behavior on fillColor { M3ColorAnim {} }
        }
        Text {
            visible: globalState.hasBattery && (globalState.batteryCharging || globalState.batteryPlugged)
            x: battGauge.x + (battGauge.width - width) / 2
            y: battGauge.y + battGauge.height * 0.545 - height / 2
            text: ""
            font.family: "Material Symbols Rounded"; font.pixelSize: 26
            color: globalState.batteryPercent >= 45 ? pal.colorOnPrimary : pal.colorOnSurface
        }

        ColumnLayout {
            visible: globalState.hasBattery
            x: battGauge.x + battGauge.width + 12
            width: battBulgePopup.natW - x - 18
            y: (battBulgePopup.topH - height) / 2
            spacing: 0
            Text {
                Layout.fillWidth: true
                text: tr("batt_title")
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium
                color: pal.colorOnSurfVar
            }
            Text {
                Layout.fillWidth: true
                text: globalState.batteryPercent + "%"
                font.family: globalState.fontPrimary; font.pixelSize: Math.round(40 * globalState.fontScale); font.weight: Font.Bold
                color: battBulgePopup.low ? pal.error : pal.colorOnSurface
                Behavior on color { M3ColorAnim {} }
            }
            Rectangle {
                Layout.topMargin: 4
                Layout.preferredHeight: 22
                Layout.preferredWidth: battStatusRow.implicitWidth + 18
                radius: 11
                color: ga(battBulgePopup.accent, 0.18)
                RowLayout {
                    id: battStatusRow
                    anchors.centerIn: parent
                    spacing: 4
                    FadeIcon {
                        text: globalState.batteryCharging || globalState.batteryPlugged ? ""
                        : battBulgePopup.low ? "" : ""
                        font.family: "Material Symbols Rounded"; font.pixelSize: 13
                        color: battBulgePopup.accent
                    }
                    Text {
                        text: battBulgePopup.statusText
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale); font.weight: Font.Bold
                        color: battBulgePopup.accent
                    }
                }
            }
            Text {
                Layout.fillWidth: true
                Layout.topMargin: 5
                visible: battBulgePopup.timeText !== ""
                text: battBulgePopup.timeText
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale)
                color: pal.colorOnSurfVar
                elide: Text.ElideRight
            }
        }

        Column {
            id: battPerfBox
            x: 16; y: battBulgePopup.topH
            width: battBulgePopup.natW - 32
            spacing: 6
            Text {
                text: tr("batt_power") + (globalState.perfApplying ? " · " + tr("gm_perf_applying") : "")
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale); font.weight: Font.Medium
                color: pal.colorOnSurfVar
            }
            SegmentedPill {
                width: parent.width
                segHeight: 36
                fontSize: Math.round(11 * globalState.fontScale)
                iconSize: 15
                options: [{ value: "low",    icon: "\uea35", label: "Low" },
                { value: "medium", icon: "\ueaf6", label: "Medium" },
                { value: "high",   icon: "\uea0b", label: "High" }]
                current: globalState.perfProfile
                onPicked: (v) => gamingWindow.setPerfProfile(v)
                trackColor: m3.glassy(m3.surfaceContainerHighest, 0.6)
                selectedColor: pal.primary
                textColor: pal.colorOnSurfVar
                selectedTextColor: pal.colorOnPrimary
                iconColor: pal.primary
            }
        }
    }
}
