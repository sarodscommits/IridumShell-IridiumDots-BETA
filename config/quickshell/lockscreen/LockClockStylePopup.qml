import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Clock style picker popup
Rectangle {
    id: lockClockStylePopup
    z: 30
    property bool shown: false
    property color cPrimary:     pal.primary
    property color cPrimarySoft: Qt.rgba(pal.primary.r, pal.primary.g, pal.primary.b, 0.22)
    property color cOnPrimary:   pal.colorOnPrimary
    property color cSurface:     pal.surface
    property color cSurfaceVar:  pal.surfaceVar
    property color cOnSurface:   pal.colorOnSurface
    property color cOnSurfVar:   pal.colorOnSurfVar
    function openAt(px, py) {
        x = Math.max(0, Math.min(lockContent.width  - width,  px));
        y = Math.max(0, Math.min(lockContent.height - height, py));
        shown = true;
    }
    width: 276
    height: lockClockStyleCol.implicitHeight + 28
    radius: 20
    color: lockEdColors.cPopup
    border.width: 1
    border.color: ga(pal.mutedDeep, 0.4)
    opacity: shown ? 1 : 0
    scale: shown ? 1 : 0.9
    transformOrigin: Item.TopLeft
    visible: opacity > 0.01
    Behavior on opacity { M3NumberAnim {} }
    Behavior on scale   { M3SpringAnim { token: "spatialFast"; epsilon: 0.002 } }

    MouseArea { anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton; onClicked: hiddenInput.forceActiveFocus() }

    Column {
        id: lockClockStyleCol
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        Text {
            text: tr("lock_clock_style")
            font.family: globalState.fontPrimary; font.pixelSize: Math.round(13 * globalState.fontScale); font.weight: Font.DemiBold
            color: pal.colorOnSurface
        }

        SegmentedPill {
            id: lockClockStyleGrid
            readonly property real cellW: (width - gap) / 2
            width: lockClockStyleCol.width
            columns: 2
            stacked: true
            segHeight: 70
            gap: 8; rowGap: 8
            outerRadius: 22; innerRadius: 8; selRadius: 16
            selGrowX: 2; selGrowY: 3
            iconSize: 28
            fontSize: Math.round(11 * globalState.fontScale)
            options: [{ value: "gear",     label: tr("lock_clock_gear"),       icon: "", glyphText: "" },
            { value: "circle",   label: tr("lock_clock_circle"),     icon: "", glyphText: "" },
            { value: "digitalV", label: tr("lock_clock_vertical"),   icon: "",       glyphText: "12\n30", glyphSize: 14 },
            { value: "digitalH", label: tr("lock_clock_horizontal"), icon: "",       glyphText: "12 30" }]
            current: globalState.lockClockStyle
            onPicked: (v) => { globalState.lockClockStyle = v; savePrefs(); hiddenInput.forceActiveFocus(); }
            trackColor: globalState.glassMode ? ga(lockClockStylePopup.cSurface, 0.55) : lockClockStylePopup.cSurface
            hoverColor: lockClockStylePopup.cSurfaceVar
            selectedColor: lockClockStylePopup.cPrimary
            textColor: lockClockStylePopup.cOnSurfVar
            selectedTextColor: lockClockStylePopup.cOnPrimary
            iconColor: lockClockStylePopup.cPrimary
        }

        Row {
            spacing: 8
            opacity: lockBigClockCanvas.analog ? 1 : 0.35
            enabled: lockBigClockCanvas.analog
            Behavior on opacity { M3NumberAnim {} }
            Repeater {
                model: [
                { label: tr("desktop_setting_clock_hands"),   prop: "lockClockShowHands" },
                { label: tr("desktop_setting_clock_numbers"), prop: "lockClockShowNumbers" }
                ]
                Rectangle {
                    required property var modelData
                    readonly property bool on: globalState[modelData.prop]
                    width: lockClockStyleGrid.cellW
                    height: 32
                    radius: 16
                    color: on ? lockClockStylePopup.cPrimarySoft : (globalState.glassMode ? ga(lockClockStylePopup.cSurface, 0.55) : lockClockStylePopup.cSurface)
                    border.width: 1
                    border.color: on ? lockClockStylePopup.cPrimary : "transparent"
                    Behavior on color { M3ColorAnim {} }
                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        FadeIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: parent.parent.on ? "" : ""
                            font.family: "Material Symbols Rounded"; font.pixelSize: 16
                            color: parent.parent.on ? lockClockStylePopup.cPrimary : lockClockStylePopup.cOnSurfVar
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.label
                            font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium
                            color: lockClockStylePopup.cOnSurface
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var other = modelData.prop === "lockClockShowHands" ? "lockClockShowNumbers" : "lockClockShowHands";
                            globalState[modelData.prop] = !globalState[modelData.prop];
                            if (!globalState[modelData.prop] && !globalState[other]) globalState[other] = true;
                            savePrefs();
                            hiddenInput.forceActiveFocus();
                        }
                    }
                }
            }
        }
    }
}
