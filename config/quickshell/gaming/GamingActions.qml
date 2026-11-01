import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Quick action buttons of the gaming panel
Item {
    id: gmActions
    visible: gamingWindow.modOn("actions")
    Layout.fillWidth: true
    implicitHeight: 56

    Row {
        anchors.fill: parent
        spacing: 8

        Rectangle {
            id: gmRecCta
            readonly property bool on: globalState.recBusy
            width: Math.max(0, gmActions.width - 3 * 56 - 3 * 8)
            height: 56
            radius: on ? 16 : (gmRecCtaHov.hovered ? 20 : 28)
            Behavior on radius { M3SpringAnim { token: "spatialDefault" } }
            color: on ? ga(pal.error, 0.2)
            : (gmRecCtaHov.hovered ? Qt.lighter(pal.primary, 1.08) : pal.primary)
            Behavior on color { M3ColorAnim {} }
            RowLayout {
                anchors.centerIn: parent
                width: Math.min(implicitWidth, parent.width - 24)
                spacing: 8
                FadeIcon {
                    text: gmRecCta.on ? "\ue047" : "\ue061"
                    font.family: "Material Symbols Rounded"; font.pixelSize: 22
                    color: gmRecCta.on ? pal.error : pal.colorOnPrimary
                }
                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: globalState.recSaving ? tr("rec_saving")
                    : globalState.recActive ? globalState.recFmt(globalState.recElapsedMs)
                    : tr("gm_record")
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(13 * globalState.fontScale); font.weight: Font.DemiBold
                    font.features: { "tnum": 1 }
                    color: gmRecCta.on ? pal.error : pal.colorOnPrimary
                }
            }
            HoverHandler { id: gmRecCtaHov }
            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: globalState.recToggle("gaming")
            }
        }

        Repeater {
            model: ["shot", "mic", "dnd"]
            delegate: Rectangle {
                id: gmAct
                required property string modelData
                readonly property bool on: modelData === "mic" ? globalState.isMicMuted
                : modelData === "dnd" ? globalState.dndEnabled : false
                width: 56; height: 56
                radius: on ? 16 : (gmActHov.hovered ? 20 : 28)
                Behavior on radius { M3SpringAnim { token: "spatialDefault" } }
                color: {
                    if (on) return pal.primary;
                    var c = gmActHov.hovered ? pal.surfacePop : pal.secondaryCont;
                    return globalState.glassMode ? ga(c, 0.78) : c;
                }
                Behavior on color { M3ColorAnim {} }
                FadeIcon {
                    anchors.centerIn: parent
                    text: gmAct.modelData === "shot" ? "\ue3b0"
                    : gmAct.modelData === "mic"  ? (gmAct.on ? "\ue02b" : "\ue029")
                    : (gmAct.on ? "\ue7f6" : "\ue7f4")
                    font.family: "Material Symbols Rounded"; font.pixelSize: 22
                    color: gmAct.on ? pal.colorOnPrimary : pal.primary
                }
                HoverHandler { id: gmActHov }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (gmAct.modelData === "shot") gamingWindow.capture();
                        else if (gmAct.modelData === "mic") globalState.toggleMicMute();
                        else globalState.toggleDnd();
                    }
                }
            }
        }
    }
}
