import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Screenshot countdown / confirmation popup
PanelWindow {
    id: ssPopupWindow
    WlrLayershell.namespace: "quickshell:corner"
    anchors.bottom: true
    anchors.right:  true
    implicitWidth:  220
    implicitHeight: 110
    color: "transparent"
    visible: globalState.ssPopupVisible || ssPopupHideGrace.running
    Timer { id: ssPopupHideGrace; interval: 450; repeat: false }

    mask: Region {
        item: globalState.ssPopupVisible ? ssPopupBg : null
    }

    Timer {
        id: ssPopupAutoHide
        interval: 2500; repeat: false
        onTriggered: globalState.ssPopupVisible = false
    }

    Connections {
        target: globalState
        function onSsPopupVisibleChanged() {
            if (!globalState.ssPopupVisible) { ssPopupAutoHide.stop(); ssPopupHideGrace.restart(); }
        }
        function onSsPopupNonceChanged() {
            if (globalState.ssPopupVisible && !globalState.ssPopupCountdown)
            ssPopupAutoHide.restart();
        }
        function onSsPopupCountdownChanged() {
            if (!globalState.ssPopupCountdown && globalState.ssPopupVisible)
            ssPopupAutoHide.restart();
        }
    }

    Rectangle {
        id: ssPopupBg
        anchors.right:  parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 16
        width:  200
        height: 90
        radius: 20
        color: globalState.glassMode ? ga(pal.surface, 0.6) : pal.surface
        border.color: pal.surfacePop; border.width: 1

        property real showY: 0
        property real hideY: 24
        y: globalState.ssPopupVisible ? showY : hideY
        Behavior on y { M3SpringAnim { token: "spatialDefault" } }

        opacity: (globalState.ssPopupVisible ? 1.0 : 0.0) * (globalState.glassMode ? 0.75 : 1.0)
        Behavior on opacity { M3NumberAnim {} }

        scale: globalState.ssPopupVisible ? 1.0 : 0.92
        Behavior on scale { M3SpringAnim { token: "spatialDefault"; epsilon: 0.002 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 14

            Rectangle {
                width: 52; height: 52; radius: 26
                color: globalState.ssPopupCountdown ? Qt.darker(pal.primaryCont, 1.4) : Qt.darker(pal.positive, 2.5)
                Behavior on color { M3ColorAnim {} }

                Text {
                    anchors.centerIn: parent
                    visible: globalState.ssPopupCountdown
                    text: globalState.ssPopupSeconds.toString()
                    font.family: globalState.fontPrimary; font.pixelSize: Math.round(24 * globalState.fontScale); font.weight: Font.Bold
                    color: pal.primary
                    Behavior on text {}
                }

                Text {
                    anchors.centerIn: parent
                    visible: !globalState.ssPopupCountdown
                    text: "\ue876"
                    font.family: "Material Symbols Rounded"; font.pixelSize: 28
                    color: pal.positive
                    opacity: !globalState.ssPopupCountdown ? 1 : 0
                    Behavior on opacity { M3NumberAnim {} }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Text {
                    text: globalState.ssPopupCountdown ? "Capturing in..." : "Screenshot saved"
                    font.family: globalState.fontPrimary; font.pixelSize: Math.round(13 * globalState.fontScale); font.weight: Font.DemiBold
                    color: pal.colorOnSurface
                    Behavior on text {}
                }
                Text {
                    visible: globalState.ssPopupCountdown
                    text: tr("full_screen")
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale)
                    color: pal.muted
                }
                Rectangle {
                    visible: globalState.ssPopupCountdown
                    Layout.fillWidth: true
                    height: 3; radius: 2
                    color: Qt.darker(pal.primaryCont, 1.4)
                    Rectangle {
                        width: parent.width * (globalState.ssPopupSeconds / 5.0)
                        height: parent.height; radius: parent.radius
                        color: pal.primary
                        Behavior on width { M3SpringAnim { token: "spatialDefault" } }
                    }
                }
            }
        }
    }
}
