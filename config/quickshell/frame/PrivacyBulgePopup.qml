import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../panels"

// Privacy bulge popup: apps using camera, microphone or screen
Item {
    id: privBulgePopup
    readonly property bool isOpen: globalState.privBulgeOpen && globalState.privActive
    && globalState.barModules.privacy && !globalState.frameEffectivelyHidden
    readonly property color green: "#3DDC84"
    readonly property real natW: 340
    readonly property real bulgeW: natW * unifiedFrame.bulgeScale
    readonly property real headerH: 54
    readonly property real rowH: 58
    readonly property var rows: {
        var r = [];
        globalState.privCamDevs.forEach(function (d) { r.push({ kind: "cam", dev: d.dev || "", apps: d.apps || [], src: "", muted: false }); });
        globalState.privMicDevs.forEach(function (d) { r.push({ kind: "mic", dev: d.dev || "", apps: d.apps || [], src: d.src || "", muted: !!d.muted }); });
        return r;
    }
    readonly property real natDepth: headerH + Math.max(1, rows.length) * (rowH + 6) - 6 + 14

    x: unifiedFrame.barVertical ? unifiedFrame.popupRealX(width) : unifiedFrame.bulgeLeftX
    width: unifiedFrame.barVertical ? unifiedFrame.bulgeDepth : Math.max(0, unifiedFrame.bulgeRightX - unifiedFrame.bulgeLeftX)
    height: unifiedFrame.barVertical ? Math.max(0, unifiedFrame.bulgeRightX - unifiedFrame.bulgeLeftX) : unifiedFrame.bulgeDepth
    opacity: isOpen ? 1 : 0
    Behavior on opacity { M3NumberAnim { duration: privBulgePopup.isOpen ? 220 : 140 } }
    visible: opacity > 0.01
    enabled: isOpen
    y: unifiedFrame.barVertical ? unifiedFrame.bulgeLeftX
    : (unifiedFrame.barAtBottom ? (frameRoot.height - unifiedFrame.frameBottomH - height) : unifiedFrame.frameTopH)
    z: 1000
    clip: true

    function reposition() {
        if (isOpen) unifiedFrame.setBulgeUnder(privBulgePopup, topBarContent.barGroupRight.privBtn, natDepth * unifiedFrame.bulgeScale);
    }
    function show() {
        privCloseTimer.stop();
        if (globalState.lockScreenActive || !globalState.privActive) return;
        if (!globalState.privBulgeOpen) { globalState.closeOthers("priv"); globalState.privBulgeOpen = true; }
        else reposition();
    }
    function scheduleClose() { privCloseTimer.restart(); }
    onNatDepthChanged: reposition()
    onIsOpenChanged: {
        if (isOpen) reposition();
        else {
            privCloseTimer.stop();
            if (unifiedFrame.bulgeOwner === privBulgePopup) unifiedFrame.setBulgeUnder(privBulgePopup, topBarContent.barGroupRight.privBtn, 0);
        }
    }
    Connections {
        target: topBarContent.barGroupRight.privBtn
        function onWidthChanged() { privBulgePopup.reposition(); }
        function onXChanged()     { privBulgePopup.reposition(); }
        function onHeightChanged() { if (unifiedFrame.barVertical) privBulgePopup.reposition(); }
        function onYChanged()      { if (unifiedFrame.barVertical) privBulgePopup.reposition(); }
    }
    Timer {
        id: privCloseTimer
        interval: 320; repeat: false
        onTriggered: { if (!privPopupHover.hovered && !topBarContent.barGroupRight.privBtn.privBtnHover.hovered) globalState.privBulgeOpen = false; }
    }
    HoverHandler {
        id: privPopupHover
        onHoveredChanged: { if (hovered) privCloseTimer.stop(); else privBulgePopup.scheduleClose(); }
    }

    Item {
        id: privContent
        width: privBulgePopup.natW
        x: unifiedFrame.barVertical ? (unifiedFrame.barAtLeft ? 0 : parent.width - width) : (parent.width - width) / 2
        height: privBulgePopup.natDepth
        scale: unifiedFrame.bulgeScale
        transformOrigin: unifiedFrame.popupOrigin
        y: unifiedFrame.barVertical ? (parent.height - height) / 2 : (unifiedFrame.barAtBottom ? parent.height - height : 0)

        RowLayout {
            x: 14; y: 12
            width: parent.width - 28
            height: privBulgePopup.headerH - 18
            spacing: 10
            Rectangle {
                Layout.preferredWidth: 32; Layout.preferredHeight: 32
                radius: 16
                color: ga(privBulgePopup.green, 0.2)
                Text {
                    anchors.centerIn: parent
                    text: "\ue32a"
                    font.family: "Material Symbols Rounded"; font.pixelSize: 17
                    color: privBulgePopup.green
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text {
                    Layout.fillWidth: true
                    text: tr("priv_title")
                    font.family: globalState.fontPrimary; font.pixelSize: Math.round(14 * globalState.fontScale); font.weight: Font.Bold
                    color: pal.colorOnSurface
                }
                Text {
                    Layout.fillWidth: true
                    text: globalState.privCamActive && globalState.privMicActive ? tr("priv_both")
                    : globalState.privCamActive ? tr("priv_cam_only") : tr("priv_mic_only")
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale)
                    color: pal.colorOnSurfVar
                    elide: Text.ElideRight
                }
            }
        }

        Column {
            id: privRows
            x: 14; y: privBulgePopup.headerH
            width: privBulgePopup.natW - 28
            spacing: 6
            Repeater {
                model: privBulgePopup.rows
                delegate: Rectangle {
                    id: privRow
                    required property var modelData
                    width: privRows.width
                    height: privBulgePopup.rowH
                    radius: 14
                    color: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont)
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10; anchors.rightMargin: 8
                        spacing: 10
                        Item {
                            id: privRowShape
                            Layout.preferredWidth: 34; Layout.preferredHeight: 34
                            readonly property bool live: !privRow.modelData.muted
                            property color col: live ? privBulgePopup.green : ga(pal.colorOnSurfVar, 0.25)
                            Behavior on col { M3ColorAnim {} }
                            Spring { id: privRowM; target: privRowShape.live ? 1 : 0; token: "spatialDefault"; eps: 0.002 }
                            property real spin: 0
                            FrameAnimation {
                                running: privRowShape.live && privBulgePopup.isOpen
                                onTriggered: privRowShape.spin = (privRowShape.spin + 30 * Math.min(frameTime, 0.05)) % 360
                            }
                            MShape {
                                anchors.fill: parent
                                inset: 1.0
                                from: "Circle"; to: "Cookie9Sided"; t: privRowM.value
                                rotation: privRowShape.spin
                                fill: privRowShape.col
                            }
                            FadeIcon {
                                anchors.centerIn: parent
                                text: privRow.modelData.kind === "cam" ? "\ue04b" : (privRow.modelData.muted ? "\ue02b" : "\ue029")
                                font.family: "Material Symbols Rounded"; font.pixelSize: 18
                                color: privRow.modelData.muted ? pal.colorOnSurface : "#06210F"
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Text {
                                Layout.fillWidth: true
                                text: (privRow.modelData.kind === "cam" ? tr("priv_cam") : tr("priv_mic"))
                                + (privRow.modelData.muted ? " · " + tr("priv_muted") : "")
                                font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale); font.weight: Font.Bold
                                color: privRow.modelData.muted ? pal.muted : privBulgePopup.green
                            }
                            Text {
                                Layout.fillWidth: true
                                text: privRow.modelData.dev
                                font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                                color: pal.colorOnSurface
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                visible: privRow.modelData.apps.length > 0
                                text: tr("priv_used_by") + " " + privRow.modelData.apps.join(", ")
                                font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale)
                                color: pal.colorOnSurfVar
                                elide: Text.ElideRight
                            }
                        }
                        ClipIconButton {
                            visible: privRow.modelData.kind === "mic" && privRow.modelData.src !== ""
                            glyph: privRow.modelData.muted ? "\ue02b" : "\ue029"
                            active: privRow.modelData.muted
                            iconColor: pal.colorOnSurfVar; activeColor: pal.error; hoverColor: ga(pal.colorOnSurfVar, 0.14)
                            onClicked: privToggleMute(privRow.modelData.src)
                        }
                    }
                }
            }
        }
    }
}
