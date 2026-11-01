import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../panels"

// Edge tab that opens and closes the gaming panel
Item {
    id: gmTab
    readonly property bool wanted: gamingWindow.shown && globalState.recActive && !gamingWindow.floatLayout
    property real prog: wanted ? 1 : 0
    Behavior on prog { NumberAnimation { duration: gmTab.wanted ? 480 : 260; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.springCurve } }
    readonly property real natW: gmTabRow.implicitWidth + 24
    x: gamingWindow.margin + gamingWindow.panelW
    y: gmPanel.y + gmCol.y + (gmActions.visible ? gmActions.y : 0)
    width: Math.min(gamingWindow.tabMaxW - 4, natW) * prog
    height: gmTabRow.implicitHeight + 24
    clip: true

    TextMetrics { id: gmTimeMetrics; font.family: globalState.fontPrimary; font.pixelSize: Math.round(14 * globalState.fontScale); font.weight: Font.DemiBold; text: "00:00:00" }
    TextMetrics { id: gmSavingMetrics; font.family: globalState.fontPrimary; font.pixelSize: Math.round(14 * globalState.fontScale); font.weight: Font.DemiBold; text: tr("rec_saving") }

    Column {
        id: gmTabRow
        x: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
        opacity: Math.max(0, gmTab.prog * 1.4 - 0.4)
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 18; height: 18
            RecIndicator {
                anchors.centerIn: parent
                size: 14
                running: gmTab.wanted
            }
        }
        Text {
            width: Math.ceil(Math.max(gmTimeMetrics.width, gmSavingMetrics.width)) + 6
            horizontalAlignment: Text.AlignHCenter
            text: globalState.recSaving ? tr("rec_saving") : globalState.recFmt(globalState.recElapsedMs)
            font: gmTimeMetrics.font
            color: globalState.recPaused ? pal.colorOnSurfVar : pal.colorOnSurface
        }
        Item { width: 1; height: 4 }
        ClipIconButton {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 40; height: 40; radius: 20
            color: ga(pal.error, 0.18)
            enabled: !globalState.recSaving
            opacity: enabled ? 1 : 0.4
            glyph: ""
            iconColor: pal.error; activeColor: pal.error; hoverColor: ga(pal.error, 0.18)
            onClicked: globalState.recStop()
        }
        ClipIconButton {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 40; height: 40; radius: 20
            enabled: !globalState.recSaving
            opacity: enabled ? 1 : 0.4
            glyph: globalState.recPaused ? "" : ""
            active: globalState.recPaused
            iconColor: pal.colorOnSurfVar; activeColor: pal.primary; hoverColor: ga(pal.colorOnSurfVar, 0.14)
            onClicked: globalState.recTogglePause()
        }
        ClipIconButton {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 40; height: 40; radius: 20
            enabled: !globalState.recSaving && globalState.recMicCtl
            opacity: enabled ? 1 : 0.4
            glyph: globalState.recMicLive ? "" : ""
            active: globalState.recMicLive
            iconColor: pal.colorOnSurfVar; activeColor: pal.primary; hoverColor: ga(pal.colorOnSurfVar, 0.14)
            onClicked: globalState.recToggleMic()
        }
    }
}
