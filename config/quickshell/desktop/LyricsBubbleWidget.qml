import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../widgets"

// Lyrics speech-bubble desktop widget
ExprDesktopWidget {
    id: lyricsBubbleWidgetRoot
    wType: "lyrbubble"
    enabledProp: "lyricsBubbleWidgetEnabled"; xProp: "lyricsBubbleWidgetX"; yProp: "lyricsBubbleWidgetY"; scaleProp: "lyricsBubbleWidgetScale"
    baseW: 220; baseH: 220
    face: Component {
        Item {
            id: lbFace
            readonly property real u: width / 220
            readonly property bool playing: globalState.mediaStatus === "Playing"
            readonly property var seq: ["Cookie12Sided", "SoftBurst", "Flower", "Cookie9Sided", "Clover8Leaf", "Puffy", "Sunny", "Cookie7Sided"]
            property int idx: 0
            readonly property int line: globalState.mediaLyricIndex
            onLineChanged: { idx = (idx + 1) % seq.length; lbM.snap(0); lbM.target = 1; lbR.target += 40; }
            Spring { id: lbM; target: 1; token: "spatialDefault"; eps: 0.002 }
            Spring { id: lbR; target: 0; token: "spatialSlow"; eps: 0.05 }
            readonly property string now: globalState.lyricNow()
            DwRing {
                anchors.fill: parent
                value: globalState.mediaPosition
                thickness: Math.max(2, m3.progressThickness * 1.4 * lbFace.u)
                color: pal.primary
                track: m3.alpha(m3.inkSurface, 0.14)
            }
            MBox {
                id: lbShape
                anchors.centerIn: parent
                width: parent.width - 2 * (m3.progressThickness * 1.4 * lbFace.u + 8 * lbFace.u)
                height: width
                from: lbFace.seq[(lbFace.idx + lbFace.seq.length - 1) % lbFace.seq.length]
                to: lbFace.seq[lbFace.idx]
                t: lbM.value
                rotation: lbR.value
                fill: globalState.mediaLyricsSynced ? m3.tertiaryContainer : desktopWidgetLayer.exprDark
            }
            LyricFlip {
                anchors.centerIn: parent
                width: lbShape.width * 0.68
                height: lbShape.height * 0.6
                text: lbFace.now !== "" ? lbFace.now
                : (globalState.mediaTitle !== "" ? globalState.mediaTitle : tr("no_media_playing"))
                fontSize: (lbFace.now !== "" ? 22 : 17) * lbFace.u
                maxLines: 4
                color: globalState.mediaLyricsSynced ? m3.inkTertiaryContainer : pal.colorOnSurface
            }
            MouseArea {
                anchors.fill: lbShape
                cursorShape: Qt.PointingHandCursor
                onClicked: { globalState.mediaStatus = lbFace.playing ? "Paused" : "Playing"; audioPlayer.playPause(); }
            }
        }
    }
}
