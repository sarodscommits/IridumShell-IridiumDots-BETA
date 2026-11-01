import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../controlcenter"
import "../ui"

// Control Center media card
Rectangle {
    id: ncMediaCard
    readonly property bool live: parent ? !!parent.live : false
    radius: 36
    implicitHeight: 220
    color: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont)
    clip: true
    CcMediaArt { id: ncMediaArtWrap }
    ColumnLayout {
        anchors.left: ncMediaArtWrap.right
        anchors.leftMargin: 14
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10
        Text {
            Layout.fillWidth: true
            text: globalState.mediaTitle !== "" ? globalState.mediaTitle : "Nothing playing"
            font.family: globalState.fontPrimary; font.pixelSize: Math.round(17 * globalState.fontScale); font.weight: Font.DemiBold
            color: pal.colorOnSurface
            elide: Text.ElideRight
        }
        Text {
            Layout.fillWidth: true
            text: globalState.mediaArtist !== "" ? globalState.mediaArtist : " "
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(13 * globalState.fontScale)
            color: pal.colorOnSurfVar
            elide: Text.ElideRight
            opacity: globalState.mediaArtist !== "" ? 1 : 0
        }
        RowLayout { BumpCtl { id: mediaBump0 }
            Layout.fillWidth: true
            spacing: 7
            Item { Layout.fillWidth: true }
            Rectangle {
                implicitWidth: 30 + mediaBump0.dw(0, 5); height: 38; radius: width / 2
                color: globalState.glassMode ? ga(pal.surface, 0.6) : pal.surface
                Behavior on color { M3ColorAnim {} }
                Text { anchors.centerIn: parent; text: "\ue045"; font.family: "Material Symbols Rounded"; font.pixelSize: 21; color: pal.colorOnSurfVar }
                HoverHandler { id: ncMediaPrevHov }
                MouseArea { onPressed: mediaBump0.bump(0); anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: audioPlayer.previous() }
            }
            Rectangle {
                implicitWidth: 38 + mediaBump0.dw(1, 5); height: 38; radius: ncMediaBack5Press.pressed ? 10 : width / 2
                Behavior on radius { M3SpringAnim { token: "spatialFast" } }
                color: { var c = ncMediaBack5Hov.hovered ? pal.surfaceVar : pal.surface; return globalState.glassMode ? ga(c, 0.6) : c; }
                Behavior on color { M3ColorAnim {} }
                Text { anchors.centerIn: parent; text: "\ue020"; font.family: "Material Symbols Rounded"; font.pixelSize: 21; color: pal.colorOnSurfVar }
                HoverHandler { id: ncMediaBack5Hov }
                MouseArea { onPressed: mediaBump0.bump(1); id: ncMediaBack5Press; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: audioPlayer.seekBack() }
            }
            Rectangle {
                property bool paused: globalState.mediaStatus !== "Playing"
                property bool active: true
                implicitWidth: 75 + mediaBump0.dw(2, 5); height: 50
                radius: paused ? height / 2 : 14
                Behavior on radius { M3SpringAnim { token: "spatialDefault" } }
                color: { var c = active ? pal.primary : containerDark(pal.secondaryCont); return (globalState.glassMode && !active) ? ga(c, 0.78) : c; }
                Behavior on color { M3ColorAnim {} }
                FadeIcon { anchors.centerIn: parent; text: globalState.mediaStatus === "Playing" ? "\ue034" : "\ue037"; font.family: "Material Symbols Rounded"; font.pixelSize: 30; color: parent.active ? pal.colorOnPrimary : pal.primary }
                HoverHandler { id: ncMediaPlayHov }
                MouseArea { onPressed: mediaBump0.bump(2); anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { globalState.mediaStatus = (globalState.mediaStatus === "Playing") ? "Paused" : "Playing"; audioPlayer.playPause(); } }
            }
            Rectangle {
                implicitWidth: 38 + mediaBump0.dw(3, 5); height: 38; radius: ncMediaFwd5Press.pressed ? 10 : width / 2
                Behavior on radius { M3SpringAnim { token: "spatialFast" } }
                color: { var c = ncMediaFwd5Hov.hovered ? pal.surfaceVar : pal.surface; return globalState.glassMode ? ga(c, 0.6) : c; }
                Behavior on color { M3ColorAnim {} }
                Text { anchors.centerIn: parent; text: "\ue01f"; font.family: "Material Symbols Rounded"; font.pixelSize: 21; color: pal.colorOnSurfVar }
                HoverHandler { id: ncMediaFwd5Hov }
                MouseArea { onPressed: mediaBump0.bump(3); id: ncMediaFwd5Press; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: audioPlayer.seekForward() }
            }
            Rectangle {
                implicitWidth: 30 + mediaBump0.dw(4, 5); height: 38; radius: width / 2
                color: globalState.glassMode ? ga(pal.surface, 0.6) : pal.surface
                Behavior on color { M3ColorAnim {} }
                Text { anchors.centerIn: parent; text: "\ue044"; font.family: "Material Symbols Rounded"; font.pixelSize: 21; color: pal.colorOnSurfVar }
                HoverHandler { id: ncMediaNextHov }
                MouseArea { onPressed: mediaBump0.bump(4); anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: audioPlayer.next() }
            }
            Item { Layout.fillWidth: true }
        }
        Item {
            id: ncMediaProgress
            Layout.fillWidth: true
            height: 26
            EWavyLinear {
                id: ncMediaWave
                anchors.fill: parent
                value: rightPanelContent.mediaPanel.animPct
                animateValue: false
                active: pal.primary
                track: m3.alpha(m3.inkSurface, 0.14)
                wavy: globalState.mediaStatus === "Playing"
                showHandle: true
                handleH: 22
                thickness: m3.progressThickness; amplitude: 3; wavelength: 30
                running: ncMediaCard.live
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                function seek(mx) { var p = Math.max(0, Math.min(mx / ncMediaProgress.width, 1)); rightPanelContent.mediaPanel.animPct = p; audioPlayer.seekAbsolute(p * globalState.mediaDurSeconds); }
                onPressed: (m) => seek(m.x)
                onPositionChanged: (m) => { if (pressed) seek(m.x) }
                onReleased: (m) => seek(m.x)
            }
        }
        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: {
                function fmt(s) { s = s || 0; return Math.floor(s/60) + ":" + (s%60 < 10 ? "0" : "") + (s%60); }
                return fmt(globalState.mediaPosSeconds) + "  /  " + fmt(globalState.mediaDurSeconds);
            }
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); color: pal.muted
        }
    }
}
