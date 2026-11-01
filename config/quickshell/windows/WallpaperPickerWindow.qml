import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import ".."
import "../ui"
import "../windows"

// Wallpaper picker window
PanelWindow {
    id: wallpaperPickerWindow
    WlrLayershell.namespace: "quickshell"
    anchors.top:    true
    anchors.bottom: true
    anchors.left:   true
    anchors.right:  true
    visible: globalState.wallpaperPickerOpen
    color:   "transparent"
    focusable: true
    exclusionMode: ExclusionMode.Ignore

    Rectangle {
        anchors.fill: parent
        color: "#4D000000"
        visible: globalState.wallpaperPickerOpen

        MouseArea {
            anchors.fill: parent
            onClicked: globalState.wallpaperPickerOpen = false
            onWheel: (wheel) => {
                if (wpPickerRoot.itemCount < 2) return;
                wpPickerRoot.step(wheel.angleDelta.y < 0 ? 1 : -1);
            }
        }
    }

    property bool grabReady: false
    onVisibleChanged: {
        if (visible) wpGrabDelay.restart();
        else { wpGrabDelay.stop(); grabReady = false; }
    }
    Timer { id: wpGrabDelay; interval: 60; onTriggered: { wallpaperPickerWindow.grabReady = wallpaperPickerWindow.visible; if (wallpaperPickerWindow.visible) wpPickerRoot.forceActiveFocus(); } }

    HyprlandFocusGrab {
        id: wpPickerFocusGrab
        windows: [wallpaperPickerWindow]
        active:  globalState.wallpaperPickerOpen && wallpaperPickerWindow.grabReady
        onActiveChanged: {
            if (!active) globalState.wallpaperPickerOpen = false
        }
    }

    function openInit() {
        var list = globalState.wallpaperList;
        var tgt = 0;
        for (var i = 0; i < list.length; i++) {
            if (list[i].path === globalState.currentWallpaper) { tgt = i; break; }
        }
        wpPickerRoot.currentIndex = tgt;
        wpPickerRoot.forceActiveFocus();
    }
    Connections {
        target: globalState
        function onWallpaperPickerOpenChanged() { if (globalState.wallpaperPickerOpen) wallpaperPickerWindow.openInit(); }
        function onWallpaperListChanged() { if (globalState.wallpaperPickerOpen && wpPickerRoot.currentIndex >= globalState.wallpaperList.length) wallpaperPickerWindow.openInit(); }
    }
    Component.onCompleted: if (globalState.wallpaperPickerOpen) { openInit(); wpGrabDelay.restart(); }

    Item {
        id: wpPickerRoot
        anchors.fill: parent

        property int itemCount: globalState.wallpaperList.length
        property int currentIndex: 0
        readonly property int maxStackDepth: 4
        readonly property real cardW: Math.min(wallpaperPickerWindow.width * 0.68, 1120)
        readonly property real cardH: cardW * 9 / 16

        function wrap(i, n) { return n === 0 ? 0 : ((i % n) + n) % n; }
        function step(d) {
            if (itemCount < 2) return;
            currentIndex = wrap(currentIndex + d, itemCount);
        }
        function relIndex(i) {
            if (itemCount === 0) return 0;
            var raw = i - currentIndex;
            var half = itemCount / 2;
            while (raw > half)  raw -= itemCount;
            while (raw < -half) raw += itemCount;
            return raw;
        }

        function stackScale(depth) {
            return Math.max(0.6, 0.86 - depth * 0.06);
        }
        function stackTargetX(depth) {
            var overlapFrac = 0.5;
            var neighborLeft = (wallpaperPickerWindow.width - cardW) / 2;
            var w = cardW;
            for (var d = 1; d <= depth; d++) {
                w = cardW * stackScale(d);
                var rightEdge = neighborLeft + overlapFrac * w;
                neighborLeft = rightEdge - w;
            }
            var centerX = neighborLeft + w / 2;
            return centerX - cardW / 2;
        }

        Keys.onEscapePressed: globalState.wallpaperPickerOpen = false
        Keys.onLeftPressed:   wpPickerRoot.step(-1)
        Keys.onRightPressed:  wpPickerRoot.step(1)
        Keys.onReturnPressed: {
            var list = globalState.wallpaperList;
            var it = list[wpPickerRoot.currentIndex];
            if (it) {
                applyWallpaperSmooth(it.path);
                globalState.wallpaperPickerOpen = false;
            }
        }

        MorphLoader {
            anchors.centerIn: parent
            size: 72
            fillColor: pal.primary
            visible: !globalState.wallpaperLoaded
            running: visible && globalState.wallpaperPickerOpen
        }
        Column {
            anchors.centerIn: parent
            visible: globalState.wallpaperLoaded && globalState.wallpaperList.length === 0
            spacing: 14
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 96; height: 96
                AutoShape { anchors.fill: parent; fill: m3.primaryContainer; running: parent.visible; interval: 2000 }
                Text { anchors.centerIn: parent; text: "\ue894"; font.family: "Material Symbols Rounded"; font.pixelSize: 36; color: m3.inkPrimaryContainer }
            }
            EText { anchors.horizontalCenter: parent.horizontalCenter; text: tr("wp_none"); role: "titleMedium"; emph: true; color: "#FFFFFF" }
        }

        Column {
            anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 22
            spacing: 0
            EText {
                anchors.horizontalCenter: parent.horizontalCenter
                role: "labelLarge"; emph: true
                text: ("Iridium Shell" + (wpPickerRoot.itemCount > 0 ? "  ·  " + (wpPickerRoot.currentIndex + 1) + " / " + wpPickerRoot.itemCount : "")).toUpperCase()
                font.letterSpacing: 1.2
                color: m3.inversePrimary
            }
            EText {
                anchors.horizontalCenter: parent.horizontalCenter
                role: "headlineMedium"; emph: true
                text: tr("wallpapers")
                color: "#FFFFFF"
            }
        }

        Column {
            id: wpProfileActions
            readonly property var centerWp: globalState.wallpaperList[wpPickerRoot.currentIndex]
            readonly property bool hasProfile: centerWp ? profileStore.has(centerWp.path) : false
            visible: wpPickerRoot.itemCount > 0 && globalState.wallpaperPickerAlive && centerWp !== undefined
            z: 2000
            anchors.horizontalCenter: parent.horizontalCenter
            y: (wallpaperPickerWindow.height + wpPickerRoot.cardH) / 2 + 22
            spacing: 8

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 14

                EFab {
                    id: wpProfileEditBtn
                    anchors.verticalCenter: parent.verticalCenter
                    size: "medium"
                    icon: "\ue3c9"
                    onClicked: if (wpProfileActions.centerWp) startWallpaperProfileEdit(wpProfileActions.centerWp.path)
                }

                Rectangle {
                    visible: wpProfileActions.hasProfile
                    anchors.verticalCenter: parent.verticalCenter
                    width: 42; height: 42; radius: m3Ib33Ma.pressed ? Math.max(4, (21) * 0.5) : (21)
                    Behavior on radius { M3SpringAnim { token: "spatialFast" } }
                    color: wpProfileDelHov.hovered ? Qt.rgba(1,0,0,0.35) : Qt.rgba(1,1,1,0.10)
                    Behavior on color { M3ColorAnim {} }
                    Text {
                        anchors.centerIn: parent
                        text: "\ue872"
                        font.family: "Material Symbols Rounded"; font.pixelSize: 19
                        color: "#FFFFFF"
                    }
                    HoverHandler { id: wpProfileDelHov }
                    MouseArea { id: m3Ib33Ma;
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (wpProfileActions.centerWp) deleteWallpaperProfile(wpProfileActions.centerWp.path)
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: wpProfileDelHov.hovered ? tr("profile_delete")
                : (wpProfileActions.hasProfile ? tr("profile_edit") : tr("profile_create"))
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                color: "#FFFFFF"; opacity: 0.8
            }
        }

        PressIconButton {
            id: wpPickerCloseBtn
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 18
            width: 40
            height: 40
            cornerRadius: 12
            icon: "\ue5cd"
            iconSize: 20
            iconColor: "#FFFFFF"
            hoverColor: Qt.rgba(1,0,0,0.35)
            idleColor: Qt.rgba(1,1,1,0.08)
            onClicked: globalState.wallpaperPickerOpen = false
        }

        WallpaperPickerCards {}
    }
}
