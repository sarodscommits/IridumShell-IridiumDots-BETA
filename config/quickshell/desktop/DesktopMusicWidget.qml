import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../widgets"

// Music player desktop widget
CardWidgetFrame {
    id: musicWidgetRoot
    key: "music"
    readonly property int cardPad: 18
    body: Component {
        Item {
            anchors.fill: parent
            GridLayout {
                id: musicWidgetColumn
                anchors.fill: parent
                anchors.margins: musicWidgetRoot.cardPad
                columns: musicWidgetRoot.isWide ? 2 : 1
                rowSpacing: 12
                columnSpacing: 16
                readonly property real titleH: Math.round(15 * globalState.fontScale) + 6
                readonly property real sliderH: globalState.musicShowProgressBar ? 26 : 0
                readonly property real artSize: {
                    if (!globalState.musicShowAlbumArt) return 0;
                    if (musicWidgetRoot.isWide) return Math.max(40, Math.min(height, width * 0.46));
                    var gaps = rowSpacing * (globalState.musicShowProgressBar ? 3 : 2);
                    return Math.max(40, Math.min(width, height - titleH - sliderH - 50 * ctrlK - gaps));
                }
                readonly property real sideW: musicWidgetRoot.isWide ? Math.max(1, width - artSize - columnSpacing) : width
                readonly property real ctrlK: Math.min(1, sideW / 252)

                MusicArtPanel { id: musicArtWrap }

                Text {
                    Layout.fillWidth: true
                    Layout.row: musicWidgetRoot.isWide ? 0 : 1
                    Layout.column: musicWidgetRoot.isWide ? 1 : 0
                    horizontalAlignment: musicWidgetRoot.isWide ? Text.AlignLeft : Text.AlignHCenter
                    text: globalState.mediaTitle !== "" ? globalState.mediaTitle : tr("no_media_playing")
                    font.family: globalState.fontPrimary; font.pixelSize: Math.round(15 * globalState.fontScale); font.weight: Font.DemiBold
                    color: pal.colorOnSurface
                    elide: Text.ElideRight
                }

                Item {
                    id: musicProgressSlider
                    visible: globalState.musicShowProgressBar
                    Layout.fillWidth: true
                    Layout.row: musicWidgetRoot.isWide ? 1 : 2
                    Layout.column: musicWidgetRoot.isWide ? 1 : 0
                    height: 26

                    property real animPct: globalState.mediaPosition
                    Connections {
                        target: globalState
                        function onMediaPositionChanged() {
                            if (!musicSliderDrag.pressed) musicProgressSlider.animPct = globalState.mediaPosition;
                        }
                    }

                    property real wavePhase: 0
                    Timer {
                        interval: 40; repeat: true
                        running: globalState.mediaStatus === "Playing" && globalState.musicWidgetEnabled && !globalState.lockScreenActive && !globalState.wpFullscreenActive
                        onTriggered: musicProgressSlider.wavePhase = (musicProgressSlider.wavePhase + 0.10) % (Math.PI * 2)
                    }

                    EWavyLinear {
                        id: musicWaveCanvas
                        anchors.fill: parent
                        value: musicProgressSlider.animPct
                        animateValue: false
                        active: pal.primary
                        track: m3.alpha(m3.inkSurface, 0.14)
                        wavy: globalState.musicPlaying || globalState.mediaStatus === "Playing"
                        showHandle: true
                        handleH: 22
                        thickness: m3.progressThickness; amplitude: 3; wavelength: 30
                    }
                    MouseArea {
                        id: musicSliderDrag
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        function seek(mx) {
                            var p = Math.max(0, Math.min(mx / musicProgressSlider.width, 1));
                            musicProgressSlider.animPct = p;
                            audioPlayer.seekAbsolute(p * globalState.mediaDurSeconds);
                        }
                        onPressed: (m) => seek(m.x)
                        onPositionChanged: (m) => { if (pressed) seek(m.x) }
                        onReleased: (m) => seek(m.x)
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50 * musicWidgetColumn.ctrlK
                    Layout.row: musicWidgetRoot.isWide ? 2 : 3
                    Layout.column: musicWidgetRoot.isWide ? 1 : 0
                    RowLayout { BumpCtl { id: mediaBump5 }
                        anchors.centerIn: parent
                        scale: musicWidgetColumn.ctrlK
                        spacing: 7
                        Rectangle {
                            implicitWidth: 30 + mediaBump5.dw(0, 5); height: 38; radius: width / 2
                            color: globalState.glassMode ? ga(pal.surface, 0.6) : pal.surface
                            Behavior on color { M3ColorAnim {} }
                            Text { anchors.centerIn: parent; text: "\ue045"; font.family: "Material Symbols Rounded"; font.pixelSize: 21; color: pal.colorOnSurfVar }
                            HoverHandler { id: musicPrevHov }
                            MouseArea { onPressed: mediaBump5.bump(0); anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: audioPlayer.previous() }
                        }
                        Rectangle {
                            implicitWidth: 38 + mediaBump5.dw(1, 5); height: 38; radius: musicBack5Press.pressed ? 10 : width / 2
                            Behavior on radius { M3SpringAnim { token: "spatialFast" } }
                            color: { var c = musicBack5Hov.hovered ? pal.surfaceVar : pal.surface; return globalState.glassMode ? ga(c, 0.6) : c; }
                            Behavior on color { M3ColorAnim {} }
                            Text { anchors.centerIn: parent; text: "\ue020"; font.family: "Material Symbols Rounded"; font.pixelSize: 21; color: pal.colorOnSurfVar }
                            HoverHandler { id: musicBack5Hov }
                            MouseArea { onPressed: mediaBump5.bump(1); id: musicBack5Press; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: audioPlayer.seekBack() }
                        }
                        Rectangle {
                            property bool paused: globalState.mediaStatus !== "Playing"
                            property bool active: true
                            implicitWidth: 75 + mediaBump5.dw(2, 5); height: 50
                            radius: paused ? height / 2 : 14
                            Behavior on radius { M3SpringAnim { token: "spatialDefault" } }
                            color: { var c = active ? pal.primary : containerDark(pal.secondaryCont); return (globalState.glassMode && !active) ? ga(c, 0.78) : c; }
                            Behavior on color { M3ColorAnim {} }
                            FadeIcon { anchors.centerIn: parent; text: globalState.mediaStatus === "Playing" ? "\ue034" : "\ue037"; font.family: "Material Symbols Rounded"; font.pixelSize: 30; color: parent.active ? pal.colorOnPrimary : pal.primary }
                            HoverHandler { id: musicPlayHov }
                            MouseArea { onPressed: mediaBump5.bump(2); anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { globalState.mediaStatus = (globalState.mediaStatus === "Playing") ? "Paused" : "Playing"; audioPlayer.playPause(); } }
                        }
                        Rectangle {
                            implicitWidth: 38 + mediaBump5.dw(3, 5); height: 38; radius: musicFwd5Press.pressed ? 10 : width / 2
                            Behavior on radius { M3SpringAnim { token: "spatialFast" } }
                            color: { var c = musicFwd5Hov.hovered ? pal.surfaceVar : pal.surface; return globalState.glassMode ? ga(c, 0.6) : c; }
                            Behavior on color { M3ColorAnim {} }
                            Text { anchors.centerIn: parent; text: "\ue01f"; font.family: "Material Symbols Rounded"; font.pixelSize: 21; color: pal.colorOnSurfVar }
                            HoverHandler { id: musicFwd5Hov }
                            MouseArea { onPressed: mediaBump5.bump(3); id: musicFwd5Press; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: audioPlayer.seekForward() }
                        }
                        Rectangle {
                            implicitWidth: 30 + mediaBump5.dw(4, 5); height: 38; radius: width / 2
                            color: globalState.glassMode ? ga(pal.surface, 0.6) : pal.surface
                            Behavior on color { M3ColorAnim {} }
                            Text { anchors.centerIn: parent; text: "\ue044"; font.family: "Material Symbols Rounded"; font.pixelSize: 21; color: pal.colorOnSurfVar }
                            HoverHandler { id: musicNextHov }
                            MouseArea { onPressed: mediaBump5.bump(4); anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: audioPlayer.next() }
                        }
                    }
                }
            }
        }
    }
}
