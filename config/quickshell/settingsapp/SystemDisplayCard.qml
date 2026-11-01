import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../ui"

// Settings > System: displays (auto-detect, per-monitor cards, apply + confirm/revert)
SystemPrimaryCard {
    id: sdc
    required property var logic
    property int cols: 5
    icon: ""
    title: tr("sys_displays")
    subtitle: globalState.fetchDisplay
    accent: pal.primary

    headerExtra: [
        EButton {
            size: "xs"; variant: "tonal"
            icon: ""
            text: tr("sys_detect")
            fontFamily: globalState.fontSecondary
            busy: sdc.logic.loading
            enabled: !sdc.logic.confirming && !sdc.logic.applying
            onClicked: sdc.logic.detect()
        },
        EButton {
            size: "xs"; variant: "filled"
            icon: ""
            text: tr("sys_apply")
            fontFamily: globalState.fontSecondary
            busy: sdc.logic.applying
            enabled: sdc.logic.dirty && !sdc.logic.confirming && !sdc.logic.applying
            opacity: enabled ? 1 : 0.5
            onClicked: sdc.logic.apply()
        }
    ]

    // Confirm / auto-revert banner
    Rectangle {
        Layout.fillWidth: true
        visible: sdc.logic.confirming
        implicitHeight: confirmRow.implicitHeight + 24
        radius: 20
        color: pal.primaryCont
        RowLayout {
            id: confirmRow
            anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 12
            spacing: 10
            Text { text: ""; font.family: "Material Symbols Rounded"; font.pixelSize: 20; color: pal.colorOnPrimaryCont }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text {
                    Layout.fillWidth: true; wrapMode: Text.WordWrap
                    text: tr("sys_keep_q")
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(12.5 * globalState.fontScale); font.weight: Font.DemiBold
                    color: pal.colorOnPrimaryCont
                }
                Text {
                    Layout.fillWidth: true; wrapMode: Text.WordWrap
                    text: (sdc.logic.error !== "" ? tr("sys_apply_err") + " · " : "") + tr("sys_revert_in").arg(sdc.logic.countdown)
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(10.5 * globalState.fontScale)
                    color: pal.colorOnPrimaryCont
                    opacity: 0.85
                }
            }
            EButton { size: "xs"; variant: "outlined"; text: tr("sys_revert"); fontFamily: globalState.fontSecondary; onClicked: sdc.logic.revert() }
            EButton { size: "xs"; variant: "filled"; text: tr("sys_keep"); fontFamily: globalState.fontSecondary; onClicked: sdc.logic.keep() }
        }
    }

    Text {
        Layout.fillWidth: true
        visible: sdc.logic.monitors.length === 0 && !sdc.logic.loading
        text: tr("sys_no_monitors")
        horizontalAlignment: Text.AlignHCenter
        font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale)
        color: pal.muted
    }

    SystemDisplayLayout {
        visible: sdc.logic.monitors.length > 1
        logic: sdc.logic
    }

    Repeater {
        model: sdc.logic.monitors
        delegate: SystemMonitorCard {
            required property var modelData
            mon: modelData
            logic: sdc.logic
            cols: sdc.cols
        }
    }
}
