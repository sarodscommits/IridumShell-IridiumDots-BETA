import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../widgets"

// Expanded media card: title, artist, progress and controls
Item {
    id: lockMediaCard
    anchors.fill: parent
    opacity: lockAudioModule.expanded ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity { M3NumberAnim { duration: lockAudioModule.expanded ? 280 : 120 } }

    MediaArtRing {
        id: lockMediaArt
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        width: lockAudioModule.expandedH - 16; height: width
        artUrl: globalState.mediaArtUrl
        pct: globalState.mediaPosition
        running: globalState.lockScreenActive && lockAudioModule.expanded
        ringColor: pal.primary
        fallbackColor: globalState.glassMode ? ga(pal.surface, 0.6) : pal.surface
        iconColor: pal.colorOnSurfVar
    }

    ColumnLayout {
        z: 3
        anchors.left: lockMediaArt.right
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 10; anchors.rightMargin: 16
        spacing: 6

        Item {
            id: lockMediaTitleScrollArea
            Layout.fillWidth: true
            height: 20
            clip: true

            property real  _scrollX:  0
            property bool  _pausing:  true
            property int   _ticks:    0
            property int   _pauseMax: 36
            property real  _speed:    1.0
            readonly property int _gap: 48

            function reset() {
                _scrollX = 0;
                _pausing = true;
                _ticks   = 0;
            }

            Connections {
                target: globalState
                function onMediaMenuOpenChanged() {
                    if (globalState.mediaMenuOpen) lockMediaTitleScrollArea.reset();
                }
                function onMediaTitleChanged() {
                    lockMediaTitleScrollArea.reset();
                }
                function onLockScreenActiveChanged() {
                    if (globalState.lockScreenActive) lockMediaTitleScrollArea.reset();
                }
            }

            Connections {
                target: cavaTimer
                function onTriggered() {
                    var tw = lockMediaTitleText.contentWidth;
                    var cw = lockMediaTitleScrollArea.width;
                    if (cw <= 0 || tw <= 0) return;

                    if (tw <= cw + 4) {
                        lockMediaTitleScrollArea._scrollX = 0;
                        lockMediaTitleScrollArea._pausing = true;
                        lockMediaTitleScrollArea._ticks   = 0;
                        return;
                    }

                    if (lockMediaTitleScrollArea._pausing) {
                        lockMediaTitleScrollArea._ticks++;
                        if (lockMediaTitleScrollArea._ticks >= lockMediaTitleScrollArea._pauseMax)
                        lockMediaTitleScrollArea._pausing = false;
                        return;
                    }

                    lockMediaTitleScrollArea._scrollX -= lockMediaTitleScrollArea._speed;

                    var cycle = tw + lockMediaTitleScrollArea._gap;
                    if (lockMediaTitleScrollArea._scrollX <= -cycle)
                    lockMediaTitleScrollArea._scrollX += cycle;
                }
            }

            Text {
                id: lockMediaTitleText
                text: globalState.mediaTitle !== "" ? globalState.mediaTitle : "Nothing playing"
                font.family: globalState.fontPrimary; font.pixelSize: Math.round(14 * globalState.fontScale); font.weight: Font.DemiBold
                color: pal.colorOnSurface
                x: lockMediaTitleScrollArea._scrollX
                y: (parent.height - height) / 2
            }

            Text {
                text: lockMediaTitleText.text
                font.family: globalState.fontPrimary; font.pixelSize: Math.round(14 * globalState.fontScale); font.weight: Font.DemiBold
                color: pal.colorOnSurface
                visible: lockMediaTitleText.contentWidth > lockMediaTitleScrollArea.width + 4
                x: lockMediaTitleScrollArea._scrollX + lockMediaTitleText.contentWidth + lockMediaTitleScrollArea._gap
                y: (parent.height - height) / 2
            }
        }

        Text {
            Layout.fillWidth: true
            text: globalState.mediaArtist !== "" ? globalState.mediaArtist : " "
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale)
            color: pal.colorOnSurfVar
            elide: Text.ElideRight
            opacity: globalState.mediaArtist !== "" ? 1 : 0
            Behavior on opacity { M3NumberAnim { duration: m3.durFast } }
        }

        RowLayout { BumpCtl { id: mediaBump4 }
            Layout.fillWidth: true
            spacing: 5

            Item { Layout.fillWidth: true }

            Rectangle {
                implicitWidth: 26 + mediaBump4.dw(0, 5); height: 32; radius: width / 2
                color: globalState.glassMode ? ga(pal.surface, 0.6) : pal.surface
                Behavior on color { M3ColorAnim {} }
                Text { anchors.centerIn: parent; text: "\ue045"; font.family: "Material Symbols Rounded"; font.pixelSize: 18; color: pal.colorOnSurfVar }
                HoverHandler { id: lockMediaPrevHov }
                MouseArea { onPressed: mediaBump4.bump(0); anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: audioPlayer.previous() }
            }

            Rectangle {
                implicitWidth: 32 + mediaBump4.dw(1, 5); height: 32; radius: lockMediaBack5Press.pressed ? 9 : width / 2
                Behavior on radius { M3SpringAnim { token: "spatialFast" } }
                color: { var c = lockMediaBack5Hov.hovered ? pal.surfaceVar : pal.surface; return globalState.glassMode ? ga(c, 0.6) : c; }
                Behavior on color { M3ColorAnim {} }
                Text { anchors.centerIn: parent; text: "\ue020"; font.family: "Material Symbols Rounded"; font.pixelSize: 18; color: pal.colorOnSurfVar }
                HoverHandler { id: lockMediaBack5Hov }
                MouseArea { onPressed: mediaBump4.bump(1); id: lockMediaBack5Press; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: audioPlayer.seekBack() }
            }

            Rectangle {
                property bool paused: globalState.mediaStatus !== "Playing"
                property bool active: true
                implicitWidth: 63 + mediaBump4.dw(2, 5); height: 42
                radius: paused ? height / 2 : 12
                Behavior on radius { M3SpringAnim { token: "spatialDefault" } }
                color: {
                    var c = active ? pal.primary : containerDark(pal.secondaryCont);
                    return (globalState.glassMode && !active) ? ga(c, 0.78) : c;
                }
                Behavior on color { M3ColorAnim {} }
                FadeIcon { anchors.centerIn: parent
                    text: globalState.mediaStatus === "Playing" ? "\ue034" : "\ue037"
                    font.family: "Material Symbols Rounded"; font.pixelSize: 26; color: parent.active ? pal.colorOnPrimary : pal.primary }
                HoverHandler { id: lockMediaPlayHov }
                MouseArea { onPressed: mediaBump4.bump(2); anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        globalState.mediaStatus = (globalState.mediaStatus === "Playing") ? "Paused" : "Playing";
                        audioPlayer.playPause();
                    }
                }
            }

            Rectangle {
                implicitWidth: 32 + mediaBump4.dw(3, 5); height: 32; radius: lockMediaFwd5Press.pressed ? 9 : width / 2
                Behavior on radius { M3SpringAnim { token: "spatialFast" } }
                color: { var c = lockMediaFwd5Hov.hovered ? pal.surfaceVar : pal.surface; return globalState.glassMode ? ga(c, 0.6) : c; }
                Behavior on color { M3ColorAnim {} }
                Text { anchors.centerIn: parent; text: "\ue01f"; font.family: "Material Symbols Rounded"; font.pixelSize: 18; color: pal.colorOnSurfVar }
                HoverHandler { id: lockMediaFwd5Hov }
                MouseArea { onPressed: mediaBump4.bump(3); id: lockMediaFwd5Press; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: audioPlayer.seekForward() }
            }

            Rectangle {
                implicitWidth: 26 + mediaBump4.dw(4, 5); height: 32; radius: width / 2
                color: globalState.glassMode ? ga(pal.surface, 0.6) : pal.surface
                Behavior on color { M3ColorAnim {} }
                Text { anchors.centerIn: parent; text: "\ue044"; font.family: "Material Symbols Rounded"; font.pixelSize: 18; color: pal.colorOnSurfVar }
                HoverHandler { id: lockMediaNextHov }
                MouseArea { onPressed: mediaBump4.bump(4); anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: audioPlayer.next() }
            }

            Item { Layout.fillWidth: true }
        }

        Item {
            id: lockMediaProgress
            Layout.fillWidth: true
            height: 22

            EWavyLinear {
                id: lockMediaWave
                anchors.fill: parent
                value: mediaPanel.animPct
                animateValue: false
                active: pal.primary
                track: m3.alpha(m3.inkSurface, 0.14)
                wavy: globalState.mediaStatus === "Playing"
                showHandle: true
                handleH: 22
                thickness: m3.progressThickness; amplitude: 3; wavelength: 30
            }

            MouseArea {
                id: lockMediaProgressDrag
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                function seek(mx) {
                    var p = Math.max(0, Math.min(mx / lockMediaProgress.width, 1));
                    mediaPanel.animPct = p;
                    audioPlayer.seekAbsolute(p * globalState.mediaDurSeconds);
                }
                onPressed:         (m) => seek(m.x)
                onPositionChanged: (m) => { if (pressed) seek(m.x) }
                onReleased:        (m) => seek(m.x)
            }
        }

        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: {
                function fmt(s) {
                    s = s || 0;
                    return Math.floor(s/60) + ":" + (s%60 < 10 ? "0" : "") + (s%60);
                }
                return fmt(globalState.mediaPosSeconds) + "  /  " + fmt(globalState.mediaDurSeconds);
            }
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale); color: pal.muted
        }
    }
}
