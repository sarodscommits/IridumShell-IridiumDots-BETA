import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Media card of the control panel
Rectangle {
    id: cpMediaCard
    Layout.fillWidth: true
    radius: 16
    implicitHeight: 176
    color: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont)
    clip: true

    ColumnLayout {
        z: 3
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        Item {
            id: cpMediaTitleScrollArea
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
                    if (globalState.mediaMenuOpen) cpMediaTitleScrollArea.reset();
                }
                function onMediaTitleChanged() {
                    cpMediaTitleScrollArea.reset();
                }
            }

            Connections {
                target: cavaTimer
                function onTriggered() {
                    var tw = cpMediaTitleText.contentWidth;
                    var cw = cpMediaTitleScrollArea.width;
                    if (cw <= 0 || tw <= 0) return;

                    if (tw <= cw + 4) {
                        cpMediaTitleScrollArea._scrollX = 0;
                        cpMediaTitleScrollArea._pausing = true;
                        cpMediaTitleScrollArea._ticks   = 0;
                        return;
                    }

                    if (cpMediaTitleScrollArea._pausing) {
                        cpMediaTitleScrollArea._ticks++;
                        if (cpMediaTitleScrollArea._ticks >= cpMediaTitleScrollArea._pauseMax)
                        cpMediaTitleScrollArea._pausing = false;
                        return;
                    }

                    cpMediaTitleScrollArea._scrollX -= cpMediaTitleScrollArea._speed;

                    var cycle = tw + cpMediaTitleScrollArea._gap;
                    if (cpMediaTitleScrollArea._scrollX <= -cycle)
                    cpMediaTitleScrollArea._scrollX += cycle;
                }
            }

            Text {
                id: cpMediaTitleText
                text: globalState.mediaTitle !== "" ? globalState.mediaTitle : "Nothing playing"
                font.family: globalState.fontPrimary; font.pixelSize: Math.round(14 * globalState.fontScale); font.weight: Font.DemiBold
                color: pal.colorOnSurface
                x: cpMediaTitleScrollArea._scrollX
                y: (parent.height - height) / 2
            }

            Text {
                text: cpMediaTitleText.text
                font.family: globalState.fontPrimary; font.pixelSize: Math.round(14 * globalState.fontScale); font.weight: Font.DemiBold
                color: pal.colorOnSurface
                visible: cpMediaTitleText.contentWidth > cpMediaTitleScrollArea.width + 4
                x: cpMediaTitleScrollArea._scrollX + cpMediaTitleText.contentWidth + cpMediaTitleScrollArea._gap
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

        RowLayout { BumpCtl { id: mediaBump2 }
            Layout.fillWidth: true
            spacing: 5

            Item { Layout.fillWidth: true }

            Rectangle {
                implicitWidth: 26 + mediaBump2.dw(0, 5); height: 32; radius: width / 2
                color: globalState.glassMode ? ga(pal.surface, 0.6) : pal.surface
                Behavior on color { M3ColorAnim {} }
                Text { anchors.centerIn: parent; text: "\ue045"; font.family: "Material Symbols Rounded"; font.pixelSize: 18; color: pal.colorOnSurfVar }
                HoverHandler { id: cpMediaPrevHov }
                MouseArea { onPressed: mediaBump2.bump(0); anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: audioPlayer.previous() }
            }

            Rectangle {
                implicitWidth: 32 + mediaBump2.dw(1, 5); height: 32; radius: cpMediaBack5Press.pressed ? 9 : width / 2
                Behavior on radius { M3SpringAnim { token: "spatialFast" } }
                color: { var c = cpMediaBack5Hov.hovered ? pal.surfaceVar : pal.surface; return globalState.glassMode ? ga(c, 0.6) : c; }
                Behavior on color { M3ColorAnim {} }
                Text { anchors.centerIn: parent; text: "\ue020"; font.family: "Material Symbols Rounded"; font.pixelSize: 18; color: pal.colorOnSurfVar }
                HoverHandler { id: cpMediaBack5Hov }
                MouseArea { onPressed: mediaBump2.bump(1); id: cpMediaBack5Press; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: audioPlayer.seekBack() }
            }

            Rectangle {
                property bool paused: globalState.mediaStatus !== "Playing"
                property bool active: true
                implicitWidth: 63 + mediaBump2.dw(2, 5); height: 42
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
                HoverHandler { id: cpMediaPlayHov }
                MouseArea { onPressed: mediaBump2.bump(2); anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        globalState.mediaStatus = (globalState.mediaStatus === "Playing") ? "Paused" : "Playing";
                        audioPlayer.playPause();
                    }
                }
            }

            Rectangle {
                implicitWidth: 32 + mediaBump2.dw(3, 5); height: 32; radius: cpMediaFwd5Press.pressed ? 9 : width / 2
                Behavior on radius { M3SpringAnim { token: "spatialFast" } }
                color: { var c = cpMediaFwd5Hov.hovered ? pal.surfaceVar : pal.surface; return globalState.glassMode ? ga(c, 0.6) : c; }
                Behavior on color { M3ColorAnim {} }
                Text { anchors.centerIn: parent; text: "\ue01f"; font.family: "Material Symbols Rounded"; font.pixelSize: 18; color: pal.colorOnSurfVar }
                HoverHandler { id: cpMediaFwd5Hov }
                MouseArea { onPressed: mediaBump2.bump(3); id: cpMediaFwd5Press; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: audioPlayer.seekForward() }
            }

            Rectangle {
                implicitWidth: 26 + mediaBump2.dw(4, 5); height: 32; radius: width / 2
                color: globalState.glassMode ? ga(pal.surface, 0.6) : pal.surface
                Behavior on color { M3ColorAnim {} }
                Text { anchors.centerIn: parent; text: "\ue044"; font.family: "Material Symbols Rounded"; font.pixelSize: 18; color: pal.colorOnSurfVar }
                HoverHandler { id: cpMediaNextHov }
                MouseArea { onPressed: mediaBump2.bump(4); anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: audioPlayer.next() }
            }

            Item { Layout.fillWidth: true }
        }

        Item {
            id: cpMediaPanelProgress
            Layout.fillWidth: true
            height: 22

            EWavyLinear {
                id: cpMediaPanelWave
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
                id: cpMediaPanelDrag
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                function seek(mx) {
                    var p = Math.max(0, Math.min(mx / cpMediaPanelProgress.width, 1));
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
