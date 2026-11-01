import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Track info and playback controls of the media panel
Rectangle {
    id: mediaControlsCard
    property alias mediaPanelDrag: mediaPanelDrag
    Layout.fillWidth: true
    radius: 16
    color: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont)
    implicitHeight: mediaCtrlCol.implicitHeight + 20

    ColumnLayout {
        id: mediaCtrlCol
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        Item {
            id: mediaTitleScrollArea
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
                    if (globalState.mediaMenuOpen) mediaTitleScrollArea.reset();
                }
                function onMediaTitleChanged() {
                    mediaTitleScrollArea.reset();
                }
            }

            Connections {
                target: cavaTimer
                function onTriggered() {
                    var tw = mediaTitleText.contentWidth;
                    var cw = mediaTitleScrollArea.width;
                    if (cw <= 0 || tw <= 0) return;

                    if (tw <= cw + 4) {
                        mediaTitleScrollArea._scrollX = (cw - tw) / 2;
                        mediaTitleScrollArea._pausing = true;
                        mediaTitleScrollArea._ticks   = 0;
                        return;
                    }

                    if (mediaTitleScrollArea._pausing) {
                        mediaTitleScrollArea._ticks++;
                        if (mediaTitleScrollArea._ticks >= mediaTitleScrollArea._pauseMax)
                        mediaTitleScrollArea._pausing = false;
                        return;
                    }

                    mediaTitleScrollArea._scrollX -= mediaTitleScrollArea._speed;

                    var cycle = tw + mediaTitleScrollArea._gap;
                    if (mediaTitleScrollArea._scrollX <= -cycle)
                    mediaTitleScrollArea._scrollX += cycle;
                }
            }

            Text {
                id: mediaTitleText
                text: globalState.mediaTitle !== "" ? globalState.mediaTitle : "Nothing playing"
                font.family: globalState.fontPrimary; font.pixelSize: Math.round(14 * globalState.fontScale); font.weight: Font.DemiBold
                color: pal.colorOnSurface
                x: mediaTitleScrollArea._scrollX
                y: (parent.height - height) / 2
            }

            Text {
                text: mediaTitleText.text
                font.family: globalState.fontPrimary; font.pixelSize: Math.round(14 * globalState.fontScale); font.weight: Font.DemiBold
                color: pal.colorOnSurface
                visible: mediaTitleText.contentWidth > mediaTitleScrollArea.width + 4
                x: mediaTitleScrollArea._scrollX + mediaTitleText.contentWidth + mediaTitleScrollArea._gap
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
            horizontalAlignment: Text.AlignHCenter
        }

        RowLayout { BumpCtl { id: mediaBump1 }
            Layout.fillWidth: true
            spacing: 5

            Item { Layout.fillWidth: true }

            Rectangle {
                implicitWidth: 26 + mediaBump1.dw(0, 5); height: 32; radius: width / 2
                color: globalState.glassMode ? ga(pal.surface, 0.6) : pal.surface
                Behavior on color { M3ColorAnim {} }
                Text { anchors.centerIn: parent; text: "\ue045"; font.family: "Material Symbols Rounded"; font.pixelSize: 18; color: pal.colorOnSurfVar }
                HoverHandler { id: mediaPrevHov2 }
                MouseArea { onPressed: mediaBump1.bump(0); anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: audioPlayer.previous() }
            }

            Rectangle {
                implicitWidth: 32 + mediaBump1.dw(1, 5); height: 32; radius: mediaBack5Press.pressed ? 9 : width / 2
                Behavior on radius { M3SpringAnim { token: "spatialFast" } }
                color: { var c = mediaBack5Hov.hovered ? pal.surfaceVar : pal.surface; return globalState.glassMode ? ga(c, 0.6) : c; }
                Behavior on color { M3ColorAnim {} }
                Text { anchors.centerIn: parent; text: "\ue020"; font.family: "Material Symbols Rounded"; font.pixelSize: 18; color: pal.colorOnSurfVar }
                HoverHandler { id: mediaBack5Hov }
                MouseArea { onPressed: mediaBump1.bump(1); id: mediaBack5Press; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: audioPlayer.seekBack() }
            }

            Rectangle {
                property bool paused: globalState.mediaStatus !== "Playing"
                property bool active: true
                implicitWidth: 63 + mediaBump1.dw(2, 5); height: 42
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
                HoverHandler { id: mediaPlayHov2 }
                MouseArea { onPressed: mediaBump1.bump(2); anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        globalState.mediaStatus = (globalState.mediaStatus === "Playing") ? "Paused" : "Playing";
                        audioPlayer.playPause();
                    }
                }
            }

            Rectangle {
                implicitWidth: 32 + mediaBump1.dw(3, 5); height: 32; radius: mediaFwd5Press.pressed ? 9 : width / 2
                Behavior on radius { M3SpringAnim { token: "spatialFast" } }
                color: { var c = mediaFwd5Hov.hovered ? pal.surfaceVar : pal.surface; return globalState.glassMode ? ga(c, 0.6) : c; }
                Behavior on color { M3ColorAnim {} }
                Text { anchors.centerIn: parent; text: "\ue01f"; font.family: "Material Symbols Rounded"; font.pixelSize: 18; color: pal.colorOnSurfVar }
                HoverHandler { id: mediaFwd5Hov }
                MouseArea { onPressed: mediaBump1.bump(3); id: mediaFwd5Press; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: audioPlayer.seekForward() }
            }

            Rectangle {
                implicitWidth: 26 + mediaBump1.dw(4, 5); height: 32; radius: width / 2
                color: globalState.glassMode ? ga(pal.surface, 0.6) : pal.surface
                Behavior on color { M3ColorAnim {} }
                Text { anchors.centerIn: parent; text: "\ue044"; font.family: "Material Symbols Rounded"; font.pixelSize: 18; color: pal.colorOnSurfVar }
                HoverHandler { id: mediaNextHov2 }
                MouseArea { onPressed: mediaBump1.bump(4); anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: audioPlayer.next() }
            }

            Item { Layout.fillWidth: true }
        }

        Item {
            id: mediaPanelProgress
            Layout.fillWidth: true
            height: 22

            EWavyLinear {
                id: mediaPanelWave
                anchors.fill: parent
                value: mediaPanel.animPct
                animateValue: false
                active: pal.primary
                track: m3.alpha(m3.inkSurface, 0.14)
                thickness: m3.progressThickness; amplitude: 2.5; wavelength: 24
            }

            MouseArea {
                id: mediaPanelDrag
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                function seek(mx) {
                    var p = Math.max(0, Math.min(mx / mediaPanelProgress.width, 1));
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
