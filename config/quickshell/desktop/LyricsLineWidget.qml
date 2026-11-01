import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../widgets"

// Single-line lyrics desktop widget
ExprDesktopWidget {
    id: lyricsLineWidgetRoot
    wType: "lyrline"
    enabledProp: "lyricsLineWidgetEnabled"; xProp: "lyricsLineWidgetX"; yProp: "lyricsLineWidgetY"; scaleProp: "lyricsLineWidgetScale"
    baseW: 440; baseH: 165
    face: Component {
        Item {
            id: llFace
            readonly property real u: width / 440
            readonly property bool playing: globalState.mediaStatus === "Playing"
            readonly property string now: globalState.lyricNow()
            readonly property string shown: now !== "" ? now
            : (!globalState.mediaHasLyrics ? (globalState.mediaTitle !== "" ? globalState.mediaTitle : tr("no_media_playing"))
            : (!globalState.mediaLyricsSynced ? globalState.mediaTitle : "♪"))
            Item {
                id: llBtn
                width: parent.height; height: parent.height
                Spring { id: llM; target: llFace.playing ? 1 : 0; token: "spatialDefault"; eps: 0.002 }
                Spring { id: llS; target: llBtnMa.pressed ? 0.88 : 1; token: "spatialFast"; eps: 0.002 }
                property real spin: 0
                FrameAnimation {
                    running: llFace.playing && lyricsLineWidgetRoot.live
                    onTriggered: llBtn.spin = (llBtn.spin + 24 * Math.min(frameTime, 0.05)) % 360
                }
                MBox {
                    anchors.fill: parent
                    from: "Circle"; to: "SoftBurst"; t: llM.value
                    rotation: llBtn.spin
                    scale: llS.value
                    fill: m3.tertiaryContainer
                }
                FadeIcon {
                    anchors.centerIn: parent
                    scale: llS.value
                    text: llFace.playing ? "" : ""
                    font.family: "Material Symbols Rounded"; font.pixelSize: Math.max(12, Math.round(46 * llFace.u))
                    color: m3.inkTertiaryContainer
                }
                MouseArea {
                    id: llBtnMa
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { globalState.mediaStatus = llFace.playing ? "Paused" : "Playing"; audioPlayer.playPause(); }
                }
            }
            Rectangle {
                id: llPill
                anchors.left: llBtn.right; anchors.leftMargin: 10 * llFace.u
                anchors.right: parent.right
                height: parent.height
                property real r: llFace.playing ? height / 2 : 30 * llFace.u
                Behavior on r { M3SpringAnim { token: "spatialDefault" } }
                radius: r
                color: m3.primaryContainer
                readonly property real padX: Math.max(22 * llFace.u, radius * 0.55)
                Text {
                    id: llMeta
                    x: llPill.padX; y: 16 * llFace.u
                    width: llPill.width - 2 * llPill.padX
                    text: globalState.mediaArtist !== "" ? globalState.mediaTitle + "  ·  " + globalState.mediaArtist : globalState.mediaTitle
                    visible: globalState.mediaHasLyrics && text !== ""
                    font.family: globalState.fontSecondary; font.pixelSize: Math.max(7, Math.round(11 * llFace.u)); font.weight: Font.Bold
                    font.letterSpacing: 0.4 * llFace.u
                    color: m3.inkPrimaryContainer
                    opacity: 0.7
                    elide: Text.ElideRight
                }
                LyricFlip {
                    id: llNow
                    x: llPill.padX
                    y: llMeta.y + llMeta.height + 2 * llFace.u
                    width: llPill.width - 2 * llPill.padX
                    height: llNext.y - y - 2 * llFace.u
                    text: llFace.shown
                    fontSize: 26 * llFace.u
                    maxLines: 2
                    align: Text.AlignLeft
                    color: m3.inkPrimaryContainer
                }
                Text {
                    id: llNext
                    x: llPill.padX
                    y: llWave.y - height - 4 * llFace.u
                    width: llPill.width - 2 * llPill.padX
                    text: globalState.mediaLyricsSynced ? globalState.lyricAt(1) : (globalState.mediaHasLyrics ? tr("lyrics_unsynced") : "")
                    font.family: globalState.fontPrimary; font.pixelSize: Math.max(7, Math.round(13 * llFace.u)); font.weight: Font.DemiBold
                    color: m3.inkPrimaryContainer
                    opacity: 0.55
                    elide: Text.ElideRight
                }
                EWavyLinear {
                    id: llWave
                    x: llPill.padX
                    width: llPill.width - 2 * llPill.padX
                    height: 14 * llFace.u
                    y: llPill.height - height - 14 * llFace.u
                    value: globalState.mediaLyricsSynced ? globalState.mediaLyricProgress : globalState.mediaPosition
                    active: m3.inkPrimaryContainer
                    track: m3.alpha(m3.inkPrimaryContainer, 0.18)
                    wavy: llFace.playing
                    thickness: m3.progressThickness * Math.max(0.6, llFace.u)
                    amplitude: 2.5 * llFace.u; wavelength: 26 * llFace.u
                    running: lyricsLineWidgetRoot.live
                }
            }
        }
    }
}
