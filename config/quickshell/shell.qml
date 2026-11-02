//@ pragma Env QSG_RENDER_LOOP=basic
// Basic render loop: one shared GL context (saves RAM)
import QtQuick
import QtQuick.Window
import QtQuick.Effects
import QtQml.Models
import QtQuick.Shapes
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "backend"
import "ui"
import "theme"
import "i18n"
import "state"
import "services"
import "widgets"
import "settings"
import "panels"
import "windows"
import "lockscreen"
import "settingsapp"
import "frame"
import "gaming"
import "desktop"
import "../windows"

ShellServices {
    readonly property var toastShadowRoot: toastShadowWindow.toastShadowRoot
    readonly property var ccGridComp: unifiedFrame.ccGridComp
    readonly property var ccMediaCardComp: unifiedFrame.ccMediaCardComp
    readonly property var ccOverviewComp: unifiedFrame.ccOverviewComp
    readonly property var ccTrayComp: unifiedFrame.ccTrayComp
    readonly property var perfMorphComp: unifiedFrame.perfMorphComp
    readonly property var btPromptFocusTimer: unifiedFrame.btPromptFocusTimer
    readonly property var cavaTimer: unifiedFrame.cavaTimer
    readonly property var desktopEmptyContextMenu: unifiedFrame.desktopEmptyContextMenu
    readonly property var frameRoot: unifiedFrame.frameRoot
    readonly property var islandAutoHideHideTimer: unifiedFrame.islandAutoHideHideTimer
    readonly property var islandControlLoader: unifiedFrame.islandControlLoader
    readonly property var mediaPanel: unifiedFrame.mediaPanel
    readonly property var ncSideHitArea: unifiedFrame.ncSideHitArea
    readonly property var ncSideHitHover: unifiedFrame.ncSideHitHover
    readonly property var topBarHover: unifiedFrame.topBarHover
    readonly property var wifiPasswordFocusTimer: unifiedFrame.wifiPasswordFocusTimer
    readonly property var gmPerfProc: gamingWindow.gmPerfProc
    readonly property var gmPerfReadProc: gamingWindow.gmPerfReadProc
    readonly property var desktopEditorPopup: desktopPopupsWindow.desktopEditorPopup
    readonly property var desktopResizeOverlay: desktopPopupsWindow.desktopResizeOverlay
    readonly property var desktopWidgetMenu: desktopPopupsWindow.desktopWidgetMenu
    readonly property var ccFloatPanel: ccFloatWindow.ccFloatPanel
    readonly property var notchControlLoader: ccFloatWindow.notchControlLoader
// Frame toggle shortcut disabled (Super+Space now opens the Control Center)

GlobalShortcut {
    id: toggleWallpaperPickerShortcut
    appid: "quickshell"
    name: "toggleWallpaperPicker"
    description: "Show/hide the wallpaper picker"
    onPressed: globalState.wallpaperPickerOpen = !globalState.wallpaperPickerOpen
}

GlobalShortcut {
    id: toggleLayoutModeShortcut
    appid: "quickshell"
    name: "toggleLayoutMode"
    description: "Alternar layout de tiling dwindle/master"
    onPressed: setLayoutMode(globalState.layoutMode === "dwindle" ? "master" : "dwindle")
}

GlobalShortcut {
    id: profileNextShortcut
    appid: "quickshell"
    name: "profileNext"
    description: "Switch to the next wallpaper with a profile"
    onPressed: cycleProfile(1)
}
GlobalShortcut {
    id: profilePrevShortcut
    appid: "quickshell"
    name: "profilePrev"
    description: "Switch to the previous wallpaper with a profile"
    onPressed: cycleProfile(-1)
}
IpcHandler {
    target: "profiles"
    function next(): void { cycleProfile(1) }
    function prev(): void { cycleProfile(-1) }
}

// zoom_canvas.py reports the monitor scale after every zoom step.
IpcHandler {
    target: "zoom"
    // Called before the first scale change of each burst.
    function begin(): void {
        globalState.desktopZoomBusy = true
        zoomSettleTimer.restart()
    }
    function setScale(s: real): void {
        globalState.desktopZoomBusy = true
        globalState.desktopZoom = s > 0 ? s : 1.0
        zoomSettleTimer.restart()
    }
}
Timer {
    id: zoomSettleTimer
    interval: 450
    onTriggered: globalState.desktopZoomBusy = false
}

IpcHandler {
    target: "frame"
    function setHeldHidden(v: bool): void {
        globalState.setFrameHeldHidden(v)
    }
}

GlobalShortcut {
    id: toggleScreenRecordShortcut
    appid: "quickshell"
    name: "toggleScreenRecord"
    description: "Start/stop screen recording"
    onPressed: globalState.recToggle()
}
GlobalShortcut {
    id: pauseScreenRecordShortcut
    appid: "quickshell"
    name: "pauseScreenRecord"
    description: "Pause/resume screen recording"
    onPressed: globalState.recTogglePause()
}
// Floating Control Center
GlobalShortcut {
    appid: "quickshell"
    name: "toggleControlCenter"
    description: "Open/close the floating Control Center"
    onPressed: globalState.toggleControlCenter()
}
IpcHandler {
    target: "controlcenter"
    function toggle(): void { globalState.toggleControlCenter() }
    function open(page: int): void { globalState.openNotchControl(page === 1 ? 1 : 0) }
    function close(): void { globalState.notchControlOpen = false }
}
GlobalShortcut {
    id: toggleGamingShortcut
    appid: "quickshell"
    name: "toggleGamingPanel"
    description: "Open/close the gaming panel"
    onPressed: globalState.toggleGaming()
}
IpcHandler {
    target: "perf"
    function set(profile: string): void { gamingWindow.setPerfProfile(profile) }
}
IpcHandler {
    target: "gaming"
    function toggle(): void { globalState.toggleGaming() }
    function open(): void   { if (!globalState.gamingOpen) globalState.toggleGaming() }
    function close(): void  { if (globalState.gamingOpen) globalState.toggleGaming() }
}
IpcHandler {
    target: "screenrec"
    function toggle(): void { globalState.recToggle() }
    function pause(): void  { globalState.recTogglePause() }
    function stop(): void   { globalState.recStop() }
}
GlobalShortcut {
    appid: "quickshell"
    name: "toggleWindowSwitcher"
    description: "Workspace window switcher (Super+Tab)"
    onPressed: globalState.toggleWindowSwitcher()
}
IpcHandler {
    target: "switcher"
    function toggle(): void { globalState.toggleWindowSwitcher() }
}
WindowLoader {
    active: globalState.windowSwitcherOpen || globalState.windowSwitcherAlive
    source: Qt.resolvedUrl("apps/WindowSwitcherApp.qml")
}

// Built-in area capture
GlobalShortcut {
    appid: "quickshell"
    name: "screenshotArea"
    description: "Screenshot of an area (Quickshell picker and annotation)"
    onPressed: globalState.shotStart()
}
IpcHandler {
    target: "screenshot"
    function area(): void { globalState.shotStart() }
    function full(): void { globalState.shotFull() }
}

GlobalShortcut {
    appid: "quickshell"
    name: "toggleFileExplorer"
    description: "Open/close the file explorer"
    onPressed: globalState.toggleFileExplorer()
}
IpcHandler {
    target: "files"
    function toggle(): void { globalState.toggleFileExplorer() }
    function open(path: string): void { globalState.openFileExplorer(path) }
    function close(): void { globalState.fileExplorerOpen = false }
}
WindowLoader {
    active: globalState.fileExplorerOpen || globalState.fileExplorerAlive
    source: Qt.resolvedUrl("apps/FileExplorerApp.qml")
}
// Extra explorer windows (opened when one already exists).
Instantiator {
    model: globalState.appWinsFiles
    delegate: WindowLoader { required property int winId; active: true; source: Qt.resolvedUrl("apps/FileExplorerApp.qml") }
}

GlobalShortcut {
    appid: "quickshell"
    name: "toggleTextEditor"
    description: "Open/close the text editor"
    onPressed: globalState.toggleTextEditor()
}
IpcHandler {
    target: "editor"
    function toggle(): void { globalState.toggleTextEditor() }
    function open(path: string): void { globalState.openTextEditor(path) }
    function close(): void { globalState.textEditorOpen = false }
}
WindowLoader {
    active: globalState.textEditorOpen || globalState.textEditorAlive
    source: Qt.resolvedUrl("apps/TextEditorApp.qml")
}
// Extra editor windows.
Instantiator {
    model: globalState.appWinsEditor
    delegate: WindowLoader { required property int winId; active: true; source: Qt.resolvedUrl("apps/TextEditorApp.qml") }
}

GlobalShortcut {
    appid: "quickshell"
    name: "toggleGallery"
    description: "Open the gallery (another window if one is already open)"
    onPressed: globalState.toggleGallery()
}
IpcHandler {
    target: "gallery"
    function toggle(): void { globalState.toggleGallery() }
    function open(): void   { globalState.openAppNewWindow("gallery") }
    function close(): void  { globalState.galleryOpen = false }
}
WindowLoader {
    active: globalState.galleryOpen || globalState.galleryAlive
    source: Qt.resolvedUrl("apps/GalleryApp.qml")
}
Instantiator {
    model: globalState.appWinsGallery
    delegate: WindowLoader { required property int winId; active: true; source: Qt.resolvedUrl("apps/GalleryApp.qml") }
}

GlobalShortcut {
    appid: "quickshell"
    name: "toggleMusicPlayer"
    description: "Open/close the music player"
    onPressed: globalState.toggleMusicPlayer()
}
IpcHandler {
    target: "music"
    function toggle(): void { globalState.toggleMusicPlayer() }
    function open(path: string): void { globalState.openMusicPlayer(path ? [path] : []) }
    function close(): void { globalState.musicPlayerOpen = false }
}
WindowLoader {
    active: globalState.musicPlayerOpen || globalState.musicPlayerAlive || globalState.musicPlaying
    source: Qt.resolvedUrl("apps/MusicPlayerApp.qml")
}

IpcHandler {
    target: "shadows"
    // Recreates the shadow surfaces (bar and widgets) if one gets stuck.
    function reload(): void { globalState.shellShadowGen++ }
}

FrameShadowWindow { id: frameShadowWindow }

UnifiedFrame { id: unifiedFrame }

EdgeGap {
    edge: "top"
    edgeBase: unifiedFrame.frameTopBaseH
    autoHideSensor: globalState.islandAutoHideActive && unifiedFrame.topEdgeIsHost && !unifiedFrame.barVertical
}
EdgeGap {
    edge: "bottom"
    edgeBase: unifiedFrame.frameBottomBaseH
    autoHideSensor: globalState.islandAutoHideActive && unifiedFrame.bottomEdgeIsHost
}
EdgeGap {
    edge: "left"
    edgeBase: unifiedFrame.frameLeftBaseH
    autoHideSensor: globalState.islandAutoHideActive && unifiedFrame.barAtLeft
}
EdgeGap {
    edge: "right"
    edgeBase: unifiedFrame.frameRightBaseH
    autoHideSensor: globalState.islandAutoHideActive && unifiedFrame.barAtRight
}

ScreenshotPopupWindow { id: ssPopupWindow }

ToastShadowWindow { id: toastShadowWindow }

ToastWindow { id: toastWindow }

Process {
    id: usernameProcess
    command: ["bash", "-c", "echo $USER"]
    running: true
    stdout: SplitParser {
        onRead: (line) => { var t = line.trim(); if (t) globalState.lockUsername = t; }
    }
}

QtObject {
    id: inactivityState
    property int idleSeconds: 0
    readonly property int lockAfterSeconds: 300
}

Process {
    id: idleCheckProcess
    command: ["bash", "-c",
        "idle_ms=$(xprintidle 2>/dev/null); " +
        "if [ -n \"$idle_ms\" ]; then echo \"$idle_ms\"; else " +
        "  hyprctl cursorpos -j 2>/dev/null | python3 -c 'import sys,json; d=json.load(sys.stdin); print(str(d[\"x\"])+\",\"+str(d[\"y\"]))' 2>/dev/null || echo 'nodata'; " +
        "fi"
    ]
    running: false
    property string _lastCursorPos: ""
    stdout: SplitParser {
        onRead: (line) => {
            var t = line.trim();
            if (!t || t === "nodata") return;
            var ms = parseInt(t);
            if (!isNaN(ms)) {
                inactivityState.idleSeconds = Math.floor(ms / 1000);
            } else {
                if (t !== idleCheckProcess._lastCursorPos) {
                    idleCheckProcess._lastCursorPos = t;
                    inactivityState.idleSeconds = 0;
                } else {
                    inactivityState.idleSeconds += 10;
                }
            }
        }
    }
}

// Shutdown/reboot countdown: runs the pending action when it reaches 0.
Timer {
    id: powerConfirmTimer
    interval: 1000
    repeat: true
    running: globalState.powerConfirmAction !== ""
    onTriggered: {
        if (globalState.powerConfirmRemaining > 1) globalState.powerConfirmRemaining--;
        else globalState.powerDialogChoose(globalState.powerConfirmAction);
    }
}

Timer {
    id: inactivityTimer
    interval: 10000
    repeat: true
    running: !globalState.lockScreenActive
    onTriggered: {
        idleCheckProcess.running = true;
        if (inactivityState.idleSeconds >= inactivityState.lockAfterSeconds) {
            inactivityState.idleSeconds = 0;
            globalState.lockScreenActive = true;
            globalState.closeAll();
        }
    }
}

Timer {
    id: idleEvalTimer
    interval: 500
    repeat: false
    onTriggered: {
        if (!globalState.lockScreenActive &&
            inactivityState.idleSeconds >= inactivityState.lockAfterSeconds) {
            inactivityState.idleSeconds = 0;
            globalState.lockScreenActive = true;
            globalState.closeAll();
        }
    }
}

Timer { id: lockHoldTimer; interval: 360; repeat: false }
Connections {
    target: globalState
    function onLockScreenActiveChanged() { if (!globalState.lockScreenActive) lockHoldTimer.restart(); else lockHoldTimer.stop(); }
}
RecRegionPicker { id: recRegionLoader }

Timer { id: shotFreezeDelay; interval: 260; repeat: false; onTriggered: shotFreezeProc.running = true }
Process {
    id: shotFreezeProc
    running: false
    property string _out: ""
    command: ["bash", "-c",
        "D=$(xdg-user-dir PICTURES 2>/dev/null); [ -d \"$D\" ] || D=\"$HOME/Pictures\"; D=\"$D/Screenshots\"; mkdir -p \"$D\"\n" +
        "F=\"${XDG_RUNTIME_DIR:-/tmp}/qs-shot-freeze.png\"; rm -f \"$F\"\n" +
        "if [ -n \"$1\" ]; then grim -o \"$1\" \"$F\"; else grim \"$F\"; fi\n" +
        "[ -s \"$F\" ] || exit 1\n" +
        "printf '%s\\n%s\\n' \"$F\" \"$D\"\n",
        "qs-shot-freeze", globalState.shotMonitor]
    stdout: SplitParser { onRead: (line) => { shotFreezeProc._out += line + "\n"; } }
    onRunningChanged: {
        if (running) { _out = ""; return; }
        var l = _out.trim().split("\n");
        _out = "";
        if (l.length < 2 || l[0] === "") { globalState.shotPreparing = false; return; }
        globalState.shotFrozen = l[0];
        globalState.shotDir = l[1];
        globalState.shotNonce += 1;
        globalState.shotPreparing = false;
        globalState.shotPicking = true;
    }
}

ScreenshotOverlay { id: shotLoader }

// Eye care: translucent amber overlay
WindowLoader {
id: eyeCareOverlayLoader
active: globalState.eyeCareOverlay
source: Qt.resolvedUrl("windows/EyeCareOverlay.qml")
}
LockScreen { id: lockScreenLoader }

// Settings windows (inst > 0 = extra windows)
Instantiator {
    id: settingsWindowLoader
    active: globalState.settingsOpen || globalState.settingsAlive
    model: [0]
    delegate: settingsWindowComp
}
Instantiator {
    model: globalState.appWinsSettings
    delegate: settingsWindowComp
}
Component {
    id: settingsWindowComp
    WindowLoader { active: true; source: Qt.resolvedUrl("settingsapp/SettingsWindow.qml") }
}

WallpaperPicker { id: wallpaperPickerLoader }

// Wallpaper parallax from $XDG_RUNTIME_DIR/qs-parallax.sock
Process {
id: parallaxRecv
running: globalState.deferredReady && globalState.parallaxEnabled
command: ["python3", "-u", "-c", "import socket, os, sys, select\np = os.path.join(os.environ.get('XDG_RUNTIME_DIR') or '/tmp', 'qs-parallax.sock')\ntry: os.unlink(p)\nexcept OSError: pass\ns = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)\ns.bind(p); s.setblocking(False)\nwhile True:\n    select.select([s], [], [])\n    ax = ay = 0.0\n    while True:\n        try: d = s.recv(64)\n        except (BlockingIOError, InterruptedError): break\n        try:\n            a, b = d.split(); ax += float(a); ay += float(b)\n        except Exception: pass\n    if ax or ay:\n        sys.stdout.write('%.2f %.2f\\n' % (ax, ay)); sys.stdout.flush()\n"]
stdout: SplitParser {
  onRead: (line) => {
    var parts = line.trim().split(" ");
    if (parts.length !== 2) return;
    var dx = parseFloat(parts[0]), dy = parseFloat(parts[1]);
    if (isNaN(dx) || isNaN(dy)) return;
    parallaxLayer.addDelta(dx, dy);
  }
}
}

ParallaxLayer { id: parallaxLayer }

DesktopCavaLayer { id: desktopCavaLayer }

DesktopShadowLayer { id: desktopShadowLayer }

DesktopWidgetLayer { id: desktopWidgetLayer }

DesktopPopupsWindow { id: desktopPopupsWindow }

ControlCenterShadowWindow { id: ccFloatShadowWindow }

ControlCenterFloatWindow { id: ccFloatWindow }

GamingShadowWindow { id: gamingShadowWindow }

GamingWindow { id: gamingWindow }

// Only exists while the desktop edit mode is active.
DesktopWidgetConfigWindow {}
// Shutdown/reboot confirmation dialog
Timer { id: powerConfirmHold; interval: 320 }
Connections {
    target: globalState
    function onPowerConfirmActionChanged() { if (globalState.powerConfirmAction === "") powerConfirmHold.restart(); else powerConfirmHold.stop(); }
}
PowerConfirmDialog { id: powerConfirmLoader }
}