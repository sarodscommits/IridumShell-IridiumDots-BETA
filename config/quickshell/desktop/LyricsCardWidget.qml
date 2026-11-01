import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../widgets"

// Lyrics card desktop widget
ExprDesktopWidget {
    id: lyricsCardWidgetRoot
    wType: "lyrcard"
    enabledProp: "lyricsCardWidgetEnabled"; xProp: "lyricsCardWidgetX"; yProp: "lyricsCardWidgetY"; scaleProp: "lyricsCardWidgetScale"
    baseW: 330; baseH: 330
    face: Component {
        Rectangle {
            id: lcFace
            readonly property real u: width / 330
            readonly property bool playing: globalState.mediaStatus === "Playing"
            radius: 36 * u
            color: desktopWidgetLayer.exprDark
            Item {
                id: lcHead
                x: 16 * lcFace.u; y: 16 * lcFace.u
                width: parent.width - 32 * lcFace.u
                height: 64 * lcFace.u
                ShapeArt {
                    id: lcArt
                    width: parent.height; height: parent.height
                    shape: "Cookie9Sided"
                    spinning: lcFace.playing && lyricsCardWidgetRoot.live
                    fallbackColor: m3.primaryContainer
                    iconColor: m3.inkPrimaryContainer
                }
                Column {
                    anchors.left: lcArt.right; anchors.leftMargin: 12 * lcFace.u
                    anchors.right: lcSrc.left; anchors.rightMargin: 8 * lcFace.u
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0
                    Text {
                        width: parent.width
                        text: globalState.mediaTitle !== "" ? globalState.mediaTitle : tr("no_media_playing")
                        font.family: globalState.fontPrimary; font.pixelSize: Math.max(8, Math.round(17 * lcFace.u)); font.weight: Font.Black
                        color: pal.colorOnSurface
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        visible: globalState.mediaArtist !== ""
                        text: globalState.mediaArtist
                        font.family: globalState.fontSecondary; font.pixelSize: Math.max(7, Math.round(12 * lcFace.u)); font.weight: Font.DemiBold
                        color: pal.colorOnSurfVar
                        elide: Text.ElideRight
                    }
                }
                Rectangle {
                    id: lcSrc
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: globalState.mediaHasLyrics
                    width: visible ? lcSrcTxt.implicitWidth + 16 * lcFace.u : 0
                    height: 24 * lcFace.u
                    radius: height / 2
                    color: globalState.mediaLyricsSynced ? m3.primaryContainer : m3.secondaryContainer
                    Text {
                        id: lcSrcTxt
                        anchors.centerIn: parent
                        text: "lyrics"
                        font.family: "Material Symbols Rounded"; font.pixelSize: Math.max(8, Math.round(15 * lcFace.u))
                        color: globalState.mediaLyricsSynced ? m3.inkPrimaryContainer : m3.inkSecondaryContainer
                    }
                }
            }
            LyricsScroller {
                x: 20 * lcFace.u
                y: lcHead.y + lcHead.height + 8 * lcFace.u
                width: parent.width - 40 * lcFace.u
                height: lcProg.y - y - 8 * lcFace.u
                fontSize: 16 * lcFace.u
                activeScale: 1.22
                activeColor: m3.primary
                textColor: pal.colorOnSurface
                dimColor: pal.colorOnSurfVar
                centerAt: 0.4
            }
            EWavyLinear {
                id: lcProg
                x: 20 * lcFace.u
                width: parent.width - 40 * lcFace.u
                height: 16 * lcFace.u
                y: parent.height - height - 16 * lcFace.u
                value: globalState.mediaPosition
                active: pal.primary
                track: m3.alpha(m3.inkSurface, 0.14)
                wavy: lcFace.playing
                thickness: m3.progressThickness * Math.max(0.6, lcFace.u)
                amplitude: 3 * lcFace.u; wavelength: 30 * lcFace.u
                running: lyricsCardWidgetRoot.live
            }
        }
    }
}
