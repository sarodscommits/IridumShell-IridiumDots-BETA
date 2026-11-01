import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../widgets"

// Compact media pill desktop widget
ExprDesktopWidget {
    id: mediaPillWidgetRoot
    wType: "mediapill"
    enabledProp: "mediaPillWidgetEnabled"; xProp: "mediaPillWidgetX"; yProp: "mediaPillWidgetY"; scaleProp: "mediaPillWidgetScale"
    baseW: 220; baseH: 165
    face: Component {
        Item {
            id: mpFace
            readonly property real u: width / 220
            readonly property bool playing: globalState.mediaStatus === "Playing"
            readonly property bool hasMedia: globalState.mediaTitle !== ""
            Rectangle {
                id: mpPill
                width: parent.width
                height: Math.round(parent.height * 0.54)
                property real r: mpPlayMa.pressed ? 14 * mpFace.u : (mpFace.playing ? height / 2 : 26 * mpFace.u)
                Behavior on r { M3SpringAnim { token: "spatialDefault" } }
                radius: r
                color: m3.primaryContainer
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    x: 20 * mpFace.u
                    spacing: 12 * mpFace.u
                    FadeIcon {
                        id: mpPlayIcon
                        anchors.verticalCenter: parent.verticalCenter
                        text: mpFace.playing ? "" : ""
                        font.family: "Material Symbols Rounded"; font.pixelSize: Math.max(12, Math.round(36 * mpFace.u))
                        color: m3.inkPrimaryContainer
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: mpPill.width - 20 * mpFace.u - mpPlayIcon.width - 12 * mpFace.u - 22 * mpFace.u
                        spacing: 0
                        Text {
                            width: parent.width
                            text: mpFace.hasMedia ? globalState.mediaTitle : tr("no_media_playing")
                            font.family: globalState.fontPrimary; font.pixelSize: Math.max(8, Math.round(15 * mpFace.u)); font.weight: Font.Bold
                            color: m3.inkPrimaryContainer
                            elide: Text.ElideRight
                        }
                        Text {
                            width: parent.width
                            visible: globalState.mediaArtist !== ""
                            text: globalState.mediaArtist
                            font.family: globalState.fontSecondary; font.pixelSize: Math.max(7, Math.round(11 * mpFace.u))
                            color: m3.inkPrimaryContainer
                            opacity: 0.75
                            elide: Text.ElideRight
                        }
                    }
                }
                MouseArea {
                    id: mpPlayMa
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        globalState.mediaStatus = mpFace.playing ? "Paused" : "Playing";
                        audioPlayer.playPause();
                    }
                }
            }
            Row {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 14 * mpFace.u
                ShapeIconButton {
                    width: mpFace.height - mpPill.height - 10 * mpFace.u; height: width
                    shape: "Circle"; hoverShape: "Cookie7Sided"
                    glyph: ""; glyphSize: Math.max(10, Math.round(26 * mpFace.u))
                    fill: m3.secondaryContainer; ink: m3.inkSecondaryContainer
                    onClicked: audioPlayer.previous()
                }
                ShapeIconButton {
                    width: mpFace.height - mpPill.height - 10 * mpFace.u; height: width
                    shape: "Cookie9Sided"; hoverShape: "SoftBurst"
                    glyph: ""; glyphSize: Math.max(10, Math.round(26 * mpFace.u))
                    fill: m3.tertiaryContainer; ink: m3.inkTertiaryContainer
                    onClicked: audioPlayer.next()
                }
            }
        }
    }
}
