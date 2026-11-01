import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import ".."
import "../ui"

// Shutdown/reboot confirmation window with countdown
PanelWindow {
    id: powerConfirmWin
    screen: {
        var n = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
        var sc = Quickshell.screens;
        for (var i = 0; i < sc.length; i++) if (sc[i].name === n) return sc[i];
        return sc.length ? sc[0] : null;
    }
    WlrLayershell.namespace: "quickshell"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: globalState.powerConfirmAction !== "" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors.top: true; anchors.bottom: true; anchors.left: true; anchors.right: true
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    readonly property bool shown: globalState.powerConfirmAction !== ""
    property string action: "shutdown"
    Component.onCompleted: if (globalState.powerConfirmAction !== "") action = globalState.powerConfirmAction
    Connections {
        target: globalState
        function onPowerConfirmActionChanged() { if (globalState.powerConfirmAction !== "") powerConfirmWin.action = globalState.powerConfirmAction; }
    }
    readonly property bool isRestart: action === "restart"
    readonly property int total: Math.max(1, globalState.powerConfirmSeconds)
    readonly property int remaining: Math.max(0, globalState.powerConfirmRemaining)

    property bool armed: false
    Timer { interval: 34; running: true; onTriggered: powerConfirmWin.armed = true }
    Spring { id: pcProg; target: (powerConfirmWin.shown && powerConfirmWin.armed) ? 1 : 0; token: powerConfirmWin.shown ? "spatialDefault" : "effectsDefault"; eps: 0.002 }
    Spring { id: pcFade; target: (powerConfirmWin.shown && powerConfirmWin.armed) ? 1 : 0; token: "effectsDefault" }

    Item {
        id: pcRoot
        anchors.fill: parent
        focus: true
        Keys.onPressed: (e) => {
            if (!powerConfirmWin.shown) return;
            if (e.key === Qt.Key_Escape) { globalState.cancelPowerConfirm(); e.accepted = true; }
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { globalState.powerDialogChoose(powerConfirmWin.action); e.accepted = true; }
        }

        Rectangle {
            anchors.fill: parent
            visible: powerConfirmWin.shown
            color: "#4D000000"
        }
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onPressed: pcRoot.forceActiveFocus() }

        Rectangle {
            id: pcCard
            anchors.centerIn: parent
            width: Math.min(parent.width - 48, Math.max(380, pcOthersRow.visible ? pcOthersRow.implicitWidth + 48 : 0))
            height: pcCol.implicitHeight + 48
            radius: 32
            color: globalState.glassMode ? ga(pal.surfacePop, 0.9) : pal.surfacePop
            opacity: Math.min(1, pcFade.value)
            scale: 0.9 + 0.1 * pcProg.value
            enabled: powerConfirmWin.shown
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }

            ColumnLayout {
                id: pcCol
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                anchors.margins: 24
                spacing: 14

                Item {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 104; Layout.preferredHeight: 104
                    EWavyCircular {
                        anchors.fill: parent
                        value: powerConfirmWin.remaining / powerConfirmWin.total
                        thickness: 6; amplitude: 1.8; wavelength: 18
                        active: pal.error
                        track: m3.alpha(pal.error, 0.18)
                    }
                    Item {
                        id: pcUrgency
                        anchors.centerIn: parent
                        width: 78; height: 78
                        readonly property var seq: ["Cookie12Sided", "Cookie9Sided", "Cookie7Sided", "Cookie6Sided", "Sunny", "VerySunny", "SoftBurst", "Burst"]
                        readonly property int idx: Math.max(0, Math.min(seq.length - 1,
                        Math.round((1 - powerConfirmWin.remaining / powerConfirmWin.total) * (seq.length - 1))))
                        property string _from: seq[0]
                        property string _to: seq[0]
                        onIdxChanged: { _from = _to; _to = seq[idx]; pcUrgM.snap(0); pcUrgM.target = 1; }
                        Spring { id: pcUrgM; target: 1; token: "spatialDefault"; eps: 0.002 }
                        Spring { id: pcUrgR; target: -(powerConfirmWin.total - powerConfirmWin.remaining) * 24; token: "spatialFast"; eps: 0.05 }
                        MShape {
                            anchors.fill: parent
                            inset: 1.0
                            from: pcUrgency._from; to: pcUrgency._to; t: pcUrgM.value
                            rotation: pcUrgR.value
                            fill: pal.errorCont
                        }
                    }
                    Column {
                        anchors.centerIn: parent
                        spacing: -2
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: powerConfirmWin.remaining
                            font.family: globalState.fontPrimary; font.pixelSize: Math.round(30 * globalState.fontScale); font.weight: Font.Bold
                            color: pal.colorOnErrorCont
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: powerConfirmWin.isRestart ? "" : ""
                            font.family: "Material Symbols Rounded"; font.pixelSize: 16
                            color: pal.error
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: tr(powerConfirmWin.isRestart ? "power_confirm_title_restart" : "power_confirm_title_shutdown")
                    font.family: globalState.fontPrimary; font.pixelSize: Math.round(20 * globalState.fontScale); font.weight: Font.Bold
                    color: pal.colorOnSurface
                    wrapMode: Text.WordWrap
                }
                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: -8
                    horizontalAlignment: Text.AlignHCenter
                    text: tr(powerConfirmWin.isRestart ? "power_confirm_body_restart" : "power_confirm_body_shutdown").arg(powerConfirmWin.remaining)
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale)
                    color: pal.colorOnSurfVar
                    wrapMode: Text.WordWrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    spacing: 8
                    EButton {
                        Layout.fillWidth: true
                        fixedWidth: (pcCol.width - 8) / 2
                        size: "s"
                        variant: "tonal"
                        icon: ""
                        text: tr("power_confirm_cancel")
                        fontFamily: globalState.fontSecondary
                        onClicked: globalState.cancelPowerConfirm()
                    }
                    EButton {
                        Layout.fillWidth: true
                        fixedWidth: (pcCol.width - 8) / 2
                        size: "s"
                        variant: "error"
                        icon: powerConfirmWin.isRestart ? "" : ""
                        text: tr(powerConfirmWin.isRestart ? "power_confirm_now_restart" : "power_confirm_now_shutdown")
                        fontFamily: globalState.fontSecondary
                        onClicked: globalState.powerDialogChoose(powerConfirmWin.action)
                    }
                }

                Text {
                    visible: globalState.powerConfirmShowOthers
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    horizontalAlignment: Text.AlignHCenter
                    text: tr("power_confirm_others")
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale); font.weight: Font.Medium
                    color: pal.muted
                }
                RowLayout {
                    id: pcOthersRow
                    visible: globalState.powerConfirmShowOthers
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4
                    BumpCtl { id: pcBump; px: 6 }
                    Repeater {
                        model: [
                        { icon: "", label: tr("lock"),     key: "lock"     },
                        { icon: "", label: tr("logout"),   key: "logout"   },
                        { icon: "", label: tr("restart"),  key: "restart"  },
                        { icon: "", label: tr("shutdown"), key: "shutdown" }
                        ]
                        EButton {
                            required property var modelData
                            required property int index
                            size: "xs"
                            icon: modelData.icon
                            text: modelData.label
                            fontFamily: globalState.fontSecondary
                            variant: modelData.key === "lock" ? "filled" : (modelData.key === "logout" ? "tonal" : "error")
                            widthOffset: pcBump.dw(index, 4)
                            Layout.preferredWidth: implicitWidth
                            onPressedChanged: if (pressed) pcBump.bump(index)
                            onClicked: globalState.powerDialogChoose(modelData.key)
                        }
                    }
                }
            }
        }
    }
}
