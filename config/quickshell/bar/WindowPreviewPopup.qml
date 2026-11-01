import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import ".."
import "../panels"
import "../ui"

// Live preview popup of a hovered open window
Item {
    id: windowPreviewPopup
    property alias windowPreviewPopupHover: windowPreviewPopupHover
    property bool isOpen: globalState.windowPreviewOpen
    readonly property var previewClient: {
        for (var i = 0; i < globalState.openClients.length; i++) {
            if (globalState.openClients[i].address === globalState.windowPreviewAddress)
            return globalState.openClients[i];
        }
        return null;
    }
    readonly property var previewToplevel: {
        if (!previewClient) return null;
        var wantAddr = (previewClient.address || "").toLowerCase().replace(/^0x/, "");
        var vals = Hyprland.toplevels.values;
        var fallback = null;
        for (var i = 0; i < vals.length; i++) {
            var t = vals[i];
            var tAddr = (t.address || "").toLowerCase().replace(/^0x/, "");
            if (wantAddr !== "" && tAddr === wantAddr) return t.wayland;
            if (t.wayland && t.wayland.appId === previewClient.cls) {
                if (fallback === null) fallback = t.wayland;
                if (t.title === previewClient.title) fallback = t.wayland;
            }
        }
        return fallback;
    }
    readonly property real natBulgeW: 390 * unifiedFrame.bulgeScale
    property real vAnchorX: 0
    property real vAnchorY: 0
    function placeVertical(lx, rx) {
        var p = frameShape.mapToItem(windowPreviewPopup.parent, lx, unifiedFrame.frameTopH);
        vAnchorX = p.x;
        vAnchorY = p.y;
        windowPreviewPopup.x = Qt.binding(function () {
            return unifiedFrame.barAtLeft ? windowPreviewPopup.vAnchorX
            : windowPreviewPopup.vAnchorX - windowPreviewPopup.width;
        });
    }
    width: unifiedFrame.barVertical ? (isOpen ? unifiedFrame.bulgeDepth : 0) : natBulgeW
    height: unifiedFrame.barVertical
    ? (isOpen ? Math.max(0, unifiedFrame.bulgeRightX - unifiedFrame.bulgeLeftX) : 0)
    : (isOpen ? unifiedFrame.bulgeDepth : 0)
    opacity: isOpen ? 1 : 0
    Behavior on opacity { M3NumberAnim {} }
    Behavior on x {
        enabled: windowPreviewPopup.isOpen && !unifiedFrame.barVertical
        M3SpringAnim { token: "spatialFast" }
    }
    y: unifiedFrame.barVertical ? vAnchorY : (unifiedFrame.barAtBottom ? -height : openWindowsModule.height)
    z: 100
    clip: true

    HoverHandler {
        id: windowPreviewPopupHover
        onHoveredChanged: {
            if (hovered) previewCloseTimer.stop();
            else previewCloseTimer.restart();
        }
    }

    readonly property real thumbAreaWidth: natBulgeW - 20
    readonly property real infoRowAllowance: 62
    property real computedDepth: unifiedFrame.previewBulgeDepth

    function recomputeDepth() {
        var d = windowPreviewPopup.infoRowAllowance;
        if (previewScreencopy.hasContent && previewScreencopy.sourceSize.width > 0 && previewScreencopy.sourceSize.height > 0) {
            var aspect = previewScreencopy.sourceSize.width / previewScreencopy.sourceSize.height;
            var thumbH = thumbAreaWidth / aspect;
            d = Math.max(120 * unifiedFrame.bulgeScale, Math.min(500 * unifiedFrame.bulgeScale, thumbH + infoRowAllowance));
        }
        computedDepth = d;
        if (isOpen) unifiedFrame.setBulgeCentered(windowPreviewPopup, computedDepth);
    }

    onPreviewToplevelChanged: recomputeDepth()
    Connections {
        target: globalState
        function onWindowPreviewOpenChanged() {
            if (!globalState.windowPreviewOpen) peekRestoreGuard.restart();
        }
    }

    Connections {
        target: previewScreencopy
        function onSourceSizeChanged() { windowPreviewPopup.recomputeDepth(); }
        function onHasContentChanged() { windowPreviewPopup.recomputeDepth(); }
    }

    onIsOpenChanged: {
        if (isOpen) {
            recomputeDepth();
        } else {
            unifiedFrame.setBulgeCentered(windowPreviewPopup, 0);
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ScreencopyView {
                id: previewScreencopy
                anchors.fill: parent
                paintCursor: false
                property bool capOn: windowPreviewPopup.isOpen
                captureSource: capOn ? windowPreviewPopup.previewToplevel : null
                Connections {
                    target: windowPreviewPopup
                    function onIsOpenChanged() {
                        if (windowPreviewPopup.isOpen) { previewCapOffTimer.stop(); previewScreencopy.capOn = true; }
                        else { previewScreencopy.live = false; previewCapOffTimer.restart(); }
                    }
                }
                Timer { id: previewCapOffTimer; interval: 250; onTriggered: if (!windowPreviewPopup.isOpen) previewScreencopy.capOn = false }
                visible: hasContent
                live: false

                Timer {
                    id: previewSettleTimer
                    interval: 40
                    onTriggered: previewScreencopy.live = windowPreviewPopup.isOpen && previewScreencopy.captureSource !== null
                }

                onCaptureSourceChanged: {
                    live = false;
                    previewSettleTimer.restart();
                }

                Connections {
                    target: windowPreviewPopup
                    function onIsOpenChanged() {
                        previewScreencopy.live = false;
                        previewSettleTimer.restart();
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            InternalAppIcon {
                readonly property string qsApp: windowPreviewPopup.previewClient
                ? globalState.internalAppForClient(windowPreviewPopup.previewClient.cls, windowPreviewPopup.previewClient.title) : ""
                Layout.preferredWidth: 32; Layout.preferredHeight: 32
                visible: qsApp !== ""
                glyph: globalState.internalAppGlyph(qsApp)
            }
            Image {
                sourceSize: Qt.size(96, 96)
                Layout.preferredWidth: 32; Layout.preferredHeight: 32
                visible: windowPreviewPopup.previewClient &&
                globalState.internalAppForClient(windowPreviewPopup.previewClient.cls, windowPreviewPopup.previewClient.title) === "" &&
                globalState.windowIconFor(windowPreviewPopup.previewClient.cls) !== ""
                source: (windowPreviewPopup.previewClient &&
                globalState.windowIconFor(windowPreviewPopup.previewClient.cls) !== "")
                ? ("file://" + globalState.windowIconFor(windowPreviewPopup.previewClient.cls)) : ""
                fillMode: Image.PreserveAspectFit
                smooth: true; mipmap: true; asynchronous: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text {
                    Layout.fillWidth: true
                    text: windowPreviewPopup.previewClient ? (windowPreviewPopup.previewClient.title || windowPreviewPopup.previewClient.cls) : ""
                    elide: Text.ElideRight
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                    color: pal.colorOnSurfVar
                    opacity: globalState.glassMode ? 0.88 : 1.0
                }
                Text {
                    Layout.fillWidth: true
                    text: windowPreviewPopup.previewClient ? windowPreviewPopup.previewClient.cls : ""
                    elide: Text.ElideRight
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale)
                    color: pal.muted
                    opacity: globalState.glassMode ? 0.88 : 1.0
                }
            }

            PressIconButton {
                id: previewPinBtn
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                readonly property bool pinned: windowPreviewPopup.previewClient &&
                globalState.isClsPinned(windowPreviewPopup.previewClient.cls)
                cornerRadius: 8
                icon: "\uf10d"
                iconSize: 15
                iconColor: previewPinBtn.pinned ? pal.primary : pal.colorOnSurfVar
                hoverColor: pal.surfacePop
                idleColor: "transparent"
                colorDuration: m3.durFast
                onClicked: {
                    if (windowPreviewPopup.previewClient)
                    globalState.toggleClsPinned(windowPreviewPopup.previewClient.cls);
                }
            }

            PressIconButton {
                id: previewCloseBtn
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                cornerRadius: 8
                icon: "\ue5cd"
                iconSize: 15
                iconColor: hovered ? pal.error : pal.colorOnSurfVar
                hoverColor: Qt.darker(pal.error, 1.6)
                idleColor: "transparent"
                colorDuration: m3.durFast
                onClicked: {
                    if (windowPreviewPopup.previewClient) {
                        Quickshell.execDetached(["bash", "-c",
                        "hyprctl dispatch 'hl.dsp.window.focus(\"address:" +
                        windowPreviewPopup.previewClient.address +
                        "\")' && hyprctl dispatch 'hl.dsp.window.close()'"]);
                    }
                    globalState.windowPreviewOpen = false;
                }
            }
        }
    }
}
