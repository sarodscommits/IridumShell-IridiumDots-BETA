import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import ".."
import "../rightpanel"
import "../ui"

// Right side panel: control, media, Wi-Fi and Bluetooth pages
Item {
    id: rightPanelContent
    property alias cavaTimer: cavaTimer
    property alias mediaPanel: mediaPanel
    anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.right: parent.right
    anchors.topMargin: unifiedFrame.frameTopH
    anchors.bottomMargin: unifiedFrame.frameBottomH
    width: (unifiedFrame.islandMode || !unifiedFrame.rightPanelEnabled) ? 0 : Math.max(unifiedFrame.rightW, unifiedFrame.edgeHoverWidth)

    property bool animating: false
    onWidthChanged: {
        rightPanelContent.animating = true;
        rightPanelAnimGuard.restart();
    }
    Timer {
        id: rightPanelAnimGuard
        interval: 350
        repeat: false
        onTriggered: rightPanelContent.animating = false
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        clip: true

        HoverHandler {
            id: rightPanelHover
            enabled: !unifiedFrame.islandMode && unifiedFrame.rightPanelEnabled
            onHoveredChanged: {
                if (hovered) {
                    mediaCloseTimer.stop();
                    globalState.mediaPendingClose = false;
                    if (!globalState.mediaMenuOpen) globalState.rightPanelPage = 0;
                    globalState.mediaMenuOpen = true;
                } else if (!mediaPanel.eqDragging) {
                    mediaCloseTimer.restart();
                }
            }
        }
        Timer {
            id: mediaCloseTimer
            interval: 400
            repeat: false
            onTriggered: {
                if (!rightPanelHover.hovered && !mediaPanel.eqDragging) {
                    globalState.mediaMenuOpen = false;
                }
            }
        }

        Timer {
            id: cavaTimer
            interval: 33
            running: globalState.cavaConsumerVisible || mediaPanel.opacity > 0
            repeat: true
            onTriggered: {
                mediaPanel.cavaPhase += 0.12;
                var usingReal = (Date.now() - mediaPanel.cavaLastRealTs) < 500;
                if (usingReal) return;
                var playing = globalState.mediaStatus === "Playing";
                var N = 18;
                var newCurrent = [];
                for (var i = 0; i < N; i++) {
                    var target = 0;
                    if (playing) {
                        var n1 = mediaPanel.noise(i * 0.30 + mediaPanel.cavaPhase * 1.1, 1.0);
                        var n2 = mediaPanel.noise(i * 0.65 + mediaPanel.cavaPhase * 1.7, 2.5);
                        var n3 = mediaPanel.noise(i * 1.1  + mediaPanel.cavaPhase * 0.8, 4.1);
                        var freq_envelope = Math.exp(-Math.pow((i / (N-1) - 0.35) * 2.0, 2));
                        target = (n1 * 0.50 + n2 * 0.35 + n3 * 0.15) * (0.4 + freq_envelope * 0.6);
                        if (Math.random() < 0.06) target = Math.min(1.0, target * 1.8);
                        target = Math.max(0.03, target);
                    }
                    var prev = globalState.cavaBars[i] || 0;
                    var lerp = target > prev ? 0.72 : 0.25;
                    newCurrent.push(prev + (target - prev) * lerp);
                }
                globalState.cavaBars = newCurrent;
                mediaPanel.repaintCava();
            }
        }

        Timer {
            id: waveFlowTimer
            interval: 40
            repeat: true
            running: globalState.waveConsumerVisible || mediaPanel.opacity > 0
            onTriggered: {
                globalState.wavePhase = (globalState.wavePhase + 0.10) % (Math.PI * 2);
            }
        }

        Process {
            id: desktopCavaProcess
            running: globalState.lockScreenActive ? globalState.lockCavaEnabled
            : (globalState.desktopCavaEnabled && !globalState.wpFullscreenActive)
            command: ["bash", "-c",
            "CONF=\"$HOME/.cache/qs-desktop-cava.conf\"; " +
            "NAME=$(cat \"$HOME/.cache/qs-eq-hw-sink-name\" 2>/dev/null); " +
            "if [ -n \"$NAME\" ]; then SRC=\"${NAME}.monitor\"; else SRC=\"auto\"; fi; " +
            "cat > \"$CONF\" << EOF\n" +
            "[general]\n" +
            "bars = 48\n" +
            "framerate = 30\n" +
            "autosens = 1\n" +
            "sensitivity = 100\n" +
            "[input]\n" +
            "method = pulse\n" +
            "source = $SRC\n" +
            "[output]\n" +
            "method = raw\n" +
            "raw_target = /dev/stdout\n" +
            "data_format = ascii\n" +
            "ascii_max_range = 100\n" +
            "bar_delimiter = 59\n" +
            "frame_delimiter = 10\n" +
            "channels = stereo\n" +
            "EOF\n" +
            "command -v cava >/dev/null 2>&1 && exec cava -p \"$CONF\""]
            stdout: SplitParser {
                onRead: (line) => {
                    var parts = line.split(";");
                    var n = parts.length;
                    if (n > 0 && parts[n - 1].length === 0) n--;
                    if (n < 2) return;
                    var out = new Array(n);
                    for (var i = 0; i < n; i++) {
                        var raw = parseInt(parts[i], 10);
                        out[i] = isNaN(raw) ? 0 : Math.max(0, Math.min(1, raw / 100));
                    }
                    globalState.desktopCavaBars = out;

                    if (!cavaTimer.running) return;
                    var half = Math.floor(n / 2);
                    var N = globalState.cavaBars.length;
                    if (half < 1 || N < 1) return;
                    var mono = new Array(N);
                    for (var k = 0; k < N; k++) {
                        var pos = N > 1 ? k * (half - 1) / (N - 1) : 0;
                        var j0 = Math.floor(pos), j1 = Math.min(half - 1, j0 + 1), f = pos - j0;
                        var r = out[half + j0] * (1 - f) + out[half + j1] * f;
                        var l = out[half - 1 - j0] * (1 - f) + out[half - 1 - j1] * f;
                        var target = (l + r) * 0.5;
                        var prev = globalState.cavaBars[k] || 0;
                        var lerp = target > prev ? 0.65 : 0.35;
                        mono[k] = prev + (target - prev) * lerp;
                    }
                    globalState.cavaBars = mono;
                    mediaPanel.cavaLastRealTs = Date.now();
                    mediaPanel.repaintCava();
                }
            }
        }

        Process {
            id: cavaAudioProcess
            running: cavaTimer.running && !desktopCavaProcess.running
            command: ["bash", "-c",
            "CONF=\"$HOME/.cache/qs-media-cava.conf\"; " +
            "NAME=$(cat \"$HOME/.cache/qs-eq-hw-sink-name\" 2>/dev/null); " +
            "if [ -n \"$NAME\" ]; then SRC=\"${NAME}.monitor\"; else SRC=\"auto\"; fi; " +
            "cat > \"$CONF\" << EOF\n" +
            "[general]\n" +
            "bars = 18\n" +
            "framerate = 30\n" +
            "autosens = 1\n" +
            "sensitivity = 100\n" +
            "[input]\n" +
            "method = pulse\n" +
            "source = $SRC\n" +
            "[output]\n" +
            "method = raw\n" +
            "raw_target = /dev/stdout\n" +
            "data_format = ascii\n" +
            "ascii_max_range = 100\n" +
            "bar_delimiter = 59\n" +
            "frame_delimiter = 10\n" +
            "channels = mono\n" +
            "EOF\n" +
            "command -v cava >/dev/null 2>&1 && exec cava -p \"$CONF\""]
            stdout: SplitParser {
                onRead: (line) => {
                    var parts = line.split(";").filter(function(p) { return p.length > 0; });
                    if (parts.length < 2) return;
                    var N = globalState.cavaBars.length;
                    var newCurrent = [];
                    for (var i = 0; i < N; i++) {
                        var raw = parseInt(parts[i], 10);
                        var target = isNaN(raw) ? 0 : Math.max(0, Math.min(1, raw / 100));
                        var prev = globalState.cavaBars[i] || 0;
                        var lerp = target > prev ? 0.65 : 0.35;
                        newCurrent.push(prev + (target - prev) * lerp);
                    }
                    globalState.cavaBars = newCurrent;
                    mediaPanel.cavaLastRealTs = Date.now();
                    mediaPanel.repaintCava();
                }
            }
        }

        MediaPanel { id: mediaPanel }

        Loader {
            id: controlPanelLoader
            anchors.fill: parent
            active: unifiedFrame.rightPanelEnabled && !unifiedFrame.islandMode
            source: Qt.resolvedUrl("ControlPanel.qml")
        }

        Row {
            id: rightPageDotsRow
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 8
            spacing: 6
            z: 10
            opacity: (globalState.mediaMenuOpen && !globalState.wifiViewOpen && !globalState.btDevicesViewOpen) ? 1 : 0
            visible: globalState.mediaMenuOpen && !globalState.wifiViewOpen && !globalState.btDevicesViewOpen
            Behavior on opacity { M3NumberAnim { duration: m3.durFast } }

            property color dotActiveColor:   pal.primary
            property color dotInactiveColor: Qt.rgba(pal.primary.r, pal.primary.g, pal.primary.b, 0.35)

            Repeater {
                model: 2
                Rectangle {
                    required property int index
                    width: globalState.rightPanelPage === index ? 14 : 6
                    height: 6; radius: 3
                    property bool isActive: globalState.rightPanelPage === index
                    color: isActive ? rightPageDotsRow.dotActiveColor : rightPageDotsRow.dotInactiveColor
                    Behavior on width { M3SpringAnim { token: "spatialFast" } }
                    Behavior on color { M3ColorAnim {} }
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: globalState.rightPanelPage = index
                    }
                }
            }
        }

        Loader {
            id: btDevicesPageLoader
            anchors.fill: parent
            z: 20
            active: unifiedFrame.rightPanelEnabled && !unifiedFrame.islandMode
            source: Qt.resolvedUrl("BluetoothPage.qml")
        }

        Loader {
            id: wifiPageLoader
            anchors.fill: parent
            z: 20
            active: unifiedFrame.rightPanelEnabled && !unifiedFrame.islandMode
            source: Qt.resolvedUrl("WifiPage.qml")
        }
    }
}
