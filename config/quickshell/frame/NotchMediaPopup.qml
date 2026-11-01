import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../widgets"

// Island media popup
Item {
    id: notchMediaPopup
    property alias nbEqRepeater: nbEqRepeater
    property alias notchMediaPopupHover: notchMediaPopupHover
    readonly property bool isOpen: globalState.notchMediaOpen
    readonly property bool compact: unifiedFrame.islandMode
    readonly property real fullDepth: compact ? (unifiedFrame.barVertical ? 340 : 200)
    : (unifiedFrame.barVertical ? 680 : 330)
    readonly property real natW: compact ? (unifiedFrame.barVertical ? 270 : 450)
    : (unifiedFrame.barVertical ? 330 : 800)
    readonly property real bulgeW: natW * unifiedFrame.bulgeScale
    readonly property real scaledDepth: fullDepth * unifiedFrame.bulgeScale
    x: unifiedFrame.barVertical ? unifiedFrame.popupRealX(width) : unifiedFrame.bulgeLeftX
    width: unifiedFrame.barVertical ? unifiedFrame.bulgeDepth : Math.max(0, unifiedFrame.bulgeRightX - unifiedFrame.bulgeLeftX)
    height: unifiedFrame.barVertical ? Math.max(0, unifiedFrame.bulgeRightX - unifiedFrame.bulgeLeftX) : unifiedFrame.bulgeDepth
    opacity: isOpen ? 1 : 0
    Behavior on opacity { M3NumberAnim { duration: notchMediaPopup.isOpen ? 220 : 140 } }
    visible: opacity > 0.01
    enabled: isOpen
    y: unifiedFrame.barVertical ? unifiedFrame.bulgeLeftX
    : (unifiedFrame.barAtBottom ? (frameRoot.height - unifiedFrame.frameBottomH - height) : unifiedFrame.frameTopH)
    z: 1000
    clip: true

    HoverHandler { id: notchMediaPopupHover }
    Connections {
        target: unifiedFrame
        function onIslandModeChanged() { globalState.notchMediaOpen = false; }
    }

    onIsOpenChanged: {
        if (isOpen) {
            unifiedFrame.setBulgeUnder(notchMediaPopup, topBarContent.islandAudioModule, scaledDepth);
            rightPanelContent.mediaPanel.openEqAnimation();
        } else {
            unifiedFrame.setBulgeCentered(notchMediaPopup, 0);
        }
    }

    Item {
        width: notchMediaPopup.natW
        x: unifiedFrame.barVertical ? (unifiedFrame.barAtLeft ? 0 : parent.width - width) : (parent.width - width) / 2
        height: notchMediaPopup.fullDepth
        scale: unifiedFrame.bulgeScale
        transformOrigin: unifiedFrame.popupOrigin
        y: unifiedFrame.barVertical ? (parent.height - height) / 2 : (unifiedFrame.barAtBottom ? parent.height - height : 0)

        GridLayout {
            anchors.fill: parent
            anchors.leftMargin: 18; anchors.rightMargin: 16
            anchors.topMargin: 18; anchors.bottomMargin: 20
            columns: unifiedFrame.barVertical ? 1 : (notchMediaPopup.compact ? 2 : 3)
            rowSpacing: 14
            columnSpacing: 18

            MediaArtRing {
                Layout.preferredWidth: notchMediaPopup.compact ? (unifiedFrame.barVertical ? 120 : 140) : (unifiedFrame.barVertical ? 190 : 282)
                Layout.preferredHeight: notchMediaPopup.compact ? (unifiedFrame.barVertical ? 120 : 140) : (unifiedFrame.barVertical ? 190 : 282)
                Layout.alignment: unifiedFrame.barVertical ? Qt.AlignHCenter : Qt.AlignVCenter
                artUrl: globalState.mediaArtUrl
                pct: globalState.mediaPosition
                running: notchMediaPopup.isOpen
                ringColor: pal.primary
                fallbackColor: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont)
                iconColor: pal.colorOnSurfVar
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 8
                Text { Layout.fillWidth: true; text: globalState.mediaTitle !== "" ? globalState.mediaTitle : tr("no_media_playing"); font.family: globalState.fontPrimary; font.pixelSize: Math.round(20 * globalState.fontScale); font.weight: Font.Bold; color: pal.colorOnSurface; elide: Text.ElideRight }
                Text { Layout.fillWidth: true; Layout.bottomMargin: 10; text: globalState.mediaArtist; font.family: globalState.fontSecondary; font.pixelSize: Math.round(14 * globalState.fontScale); color: pal.colorOnSurfVar; elide: Text.ElideRight }
                RowLayout { BumpCtl { id: mediaBump3 }
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 6
                    Rectangle {
                        implicitWidth: 30 + mediaBump3.dw(0, 5); height: 40; radius: width / 2; color: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont)
                        Text { anchors.centerIn: parent; text: "\ue045"; font.family: "Material Symbols Rounded"; font.pixelSize: 19; color: pal.colorOnSurfVar }
                        MouseArea { onPressed: mediaBump3.bump(0); anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: audioPlayer.previous() }
                    }
                    Rectangle {
                        implicitWidth: 36 + mediaBump3.dw(1, 5); height: 40; radius: nbMediaBack5Press.pressed ? 10 : width / 2
                        Behavior on radius { M3SpringAnim { token: "spatialFast" } }
                        color: { var c = nbMediaBack5Hov.hovered ? pal.surfaceVar : containerDark(pal.secondaryCont); return globalState.glassMode ? ga(c, 0.6) : c; }
                        Behavior on color { M3ColorAnim {} }
                        Text { anchors.centerIn: parent; text: "\ue020"; font.family: "Material Symbols Rounded"; font.pixelSize: 19; color: pal.colorOnSurfVar }
                        HoverHandler { id: nbMediaBack5Hov }
                        MouseArea { onPressed: mediaBump3.bump(1); id: nbMediaBack5Press; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: audioPlayer.seekBack() }
                    }
                    Rectangle {
                        property bool paused: globalState.mediaStatus !== "Playing"
                        property bool active: true
                        implicitWidth: 64 + mediaBump3.dw(2, 5); height: 42
                        radius: paused ? height / 2 : 12
                        Behavior on radius { M3SpringAnim { token: "spatialDefault" } }
                        color: { var c = active ? pal.primary : containerDark(pal.secondaryCont); return (globalState.glassMode && !active) ? ga(c, 0.78) : c; }
                        Behavior on color { M3ColorAnim {} }
                        FadeIcon { anchors.centerIn: parent; text: globalState.mediaStatus === "Playing" ? "\ue034" : "\ue037"; font.family: "Material Symbols Rounded"; font.pixelSize: 24; color: parent.active ? pal.colorOnPrimary : pal.primary }
                        HoverHandler { id: nbMediaPlayHov }
                        MouseArea { onPressed: mediaBump3.bump(2);
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { globalState.mediaStatus = (globalState.mediaStatus === "Playing") ? "Paused" : "Playing"; audioPlayer.playPause(); }
                        }
                    }
                    Rectangle {
                        implicitWidth: 36 + mediaBump3.dw(3, 5); height: 40; radius: nbMediaFwd5Press.pressed ? 10 : width / 2
                        Behavior on radius { M3SpringAnim { token: "spatialFast" } }
                        color: { var c = nbMediaFwd5Hov.hovered ? pal.surfaceVar : containerDark(pal.secondaryCont); return globalState.glassMode ? ga(c, 0.6) : c; }
                        Behavior on color { M3ColorAnim {} }
                        Text { anchors.centerIn: parent; text: "\ue01f"; font.family: "Material Symbols Rounded"; font.pixelSize: 19; color: pal.colorOnSurfVar }
                        HoverHandler { id: nbMediaFwd5Hov }
                        MouseArea { onPressed: mediaBump3.bump(3); id: nbMediaFwd5Press; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: audioPlayer.seekForward() }
                    }
                    Rectangle {
                        implicitWidth: 30 + mediaBump3.dw(4, 5); height: 40; radius: width / 2; color: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont)
                        Text { anchors.centerIn: parent; text: "\ue044"; font.family: "Material Symbols Rounded"; font.pixelSize: 19; color: pal.colorOnSurfVar }
                        MouseArea { onPressed: mediaBump3.bump(4); anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: audioPlayer.next() }
                    }
                }
                Item {
                    id: nbMediaProgress
                    Layout.fillWidth: true
                    height: 20
                    EWavyLinear {
                        id: nbMediaWave
                        anchors.fill: parent
                        value: rightPanelContent.mediaPanel.animPct
                        animateValue: false
                        active: pal.primary
                        track: m3.alpha(m3.inkSurface, 0.14)
                        wavy: globalState.mediaStatus === "Playing"
                        showHandle: true
                        handleH: 22
                        thickness: m3.progressThickness; amplitude: 3; wavelength: 30
                        running: globalState.notchMediaOpen
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        function seek(mx) { var p = Math.max(0, Math.min(mx / nbMediaProgress.width, 1)); rightPanelContent.mediaPanel.animPct = p; audioPlayer.seekAbsolute(p * globalState.mediaDurSeconds); }
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

            Rectangle {
                id: notchMediaEqCard
                visible: !notchMediaPopup.compact
                Layout.preferredWidth: unifiedFrame.barVertical ? -1 : 220
                Layout.fillWidth: unifiedFrame.barVertical
                Layout.fillHeight: true
                radius: 22
                color: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont)
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8
                    SegmentedPill {
                        id: nbMediaViewSel
                        Layout.fillWidth: true
                        segHeight: 26
                        fontFamily: globalState.fontPrimary
                        fontSize: Math.round(11 * globalState.fontScale)
                        iconSize: 14
                        options: [
                        { value: "eq",     label: tr("equalizer"),    icon: "\ue01d" },
                        { value: "lyrics", label: tr("lyrics_title"), icon: "lyrics" }
                        ]
                        current: globalState.musicBarView
                        onPicked: (v) => { globalState.musicBarView = v; savePrefs(); }
                        trackColor: {
                            var c = Qt.darker(pal.secondaryCont, 1.4);
                            return globalState.glassMode ? ga(c, 0.6) : c;
                        }
                        selectedColor: globalState.glassMode ? ga(pal.primary, 0.85) : pal.primary
                        textColor: pal.textPrimary
                        selectedTextColor: pal._light ? "#FFFFFF" : "#000000"
                    }
                    LyricsScroller {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: globalState.musicBarView === "lyrics"
                        fontSize: Math.round(12 * globalState.fontScale)
                        activeScale: 1.18
                        activeColor: pal.primary
                        textColor: pal.colorOnSurface
                        dimColor: pal.colorOnSurfVar
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: globalState.musicBarView !== "lyrics"
                        spacing: 8
                        SegmentedPill {
                            Layout.fillWidth: true
                            columns: 4
                            segHeight: 20
                            gap: 3; rowGap: 4
                            innerRadius: 5; selRadius: 7
                            selGrowX: 1; selGrowY: 2
                            fontFamily: globalState.fontPrimary
                            fontSize: Math.round(9 * globalState.fontScale)
                            options: Object.keys(rightPanelContent.mediaPanel.eqPresets).map(function(k) { return { value: k, label: k }; })
                            current: rightPanelContent.mediaPanel.eqActivePreset
                            onPicked: (v) => rightPanelContent.mediaPanel.applyEqPreset(v)
                            trackColor: {
                                var c = Qt.darker(pal.secondaryCont, 1.4);
                                return globalState.glassMode ? ga(c, 0.6) : c;
                            }
                            selectedColor: globalState.glassMode ? ga(pal.primary, 0.85) : pal.primary
                            textColor: pal.textPrimary
                            selectedTextColor: pal._light ? "#FFFFFF" : "#000000"
                        }
                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                            ColumnLayout {
                                width: parent.width
                                spacing: 0
                                Repeater {
                                    id: nbEqRepeater
                                    model: rightPanelContent.mediaPanel.eqBandLabels
                                    property color _wave: pal.primary
                                    property color _text: pal.textSecondary
                                    property color _thumb: pal.accent
                                    property color _thumbBorder: notchMediaEqCard.color
                                    EqBandRow {
                                        required property string modelData
                                        required property int index
                                        Layout.fillWidth: true
                                        Layout.topMargin: index === 0 ? 2 : 14
                                        bandLabel: modelData
                                        waveColor: nbEqRepeater._wave
                                        textColor: nbEqRepeater._text
                                        thumbColor: nbEqRepeater._thumb
                                        thumbBorderColor: nbEqRepeater._thumbBorder
                                        waveCrossings: 11
                                        liveWave: globalState.notchMediaOpen
                                        onDragged: (v) => rightPanelContent.mediaPanel.onNotchBulgeEqBandDragged(v)
                                        onDragActive: (active) => rightPanelContent.mediaPanel.setEqDragging(active)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
