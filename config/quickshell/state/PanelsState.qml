import QtQuick
import Quickshell

// Menus, bulges, panels, island/notch controls, power confirm and frame visibility
BarLayoutState {
    property bool volumeMenuOpen:   false
    property bool sysMenuOpen:      false
    property bool powerMenuOpen:    false
    property bool   powerConfirmEnabled:    true
    property int    powerConfirmSeconds:    30
    property bool   powerConfirmShowOthers: true
    property string powerConfirmAction:     ""
    property int    powerConfirmRemaining:  0

    readonly property var powerCmds: ({
        logout:   ["hyprctl", "dispatch", "hl.dsp.exit()"],
        restart:  ["systemctl", "reboot"],
        shutdown: ["systemctl", "poweroff"]
    })

    function runPowerAction(key) {
        powerConfirmAction = "";
        powerConfirmRemaining = 0;
        powerConfirmPreview = false;
        if (key === "lock") { lockScreenActive = true; closeAll(); return; }
        var c = powerCmds[key];
        if (c) Quickshell.execDetached(c);
    }

    function requestPowerAction(key) {
        if ((key === "restart" || key === "shutdown") && powerConfirmEnabled) {
            closeAll();
            powerConfirmRemaining = Math.max(1, powerConfirmSeconds);
            powerConfirmAction = key;
            return;
        }
        runPowerAction(key);
    }

    function cancelPowerConfirm() { powerConfirmAction = ""; powerConfirmRemaining = 0; powerConfirmPreview = false; }
    property bool powerConfirmPreview: false

    function previewPowerConfirm() {
        powerConfirmPreview = true;
        powerConfirmRemaining = Math.max(1, powerConfirmSeconds);
        powerConfirmAction = "shutdown";
    }

    function powerDialogChoose(key) {
        if (powerConfirmPreview) { cancelPowerConfirm(); return; }
        runPowerAction(key);
    }

    property bool calendarMenuOpen: false
    property bool mediaMenuOpen:    false
    property bool windowPreviewOpen: false
    property bool notchMediaOpen:   false
    property bool notchSearchOpen:  false
    property bool wsPreviewOpen:    false
    property bool   netBulgeOpen:   false
    property string netBulgeKind:   "wifi"
    property var    privCamDevs:      []
    property var    privMicDevs:      []
    readonly property bool privCamActive: privCamDevs.length > 0
    readonly property bool privMicActive: privMicDevs.length > 0
    readonly property bool privActive:    privCamActive || privMicActive
    property bool   privRevealed:     false
    property bool   privBulgeOpen:    false
    property bool   battBulgeOpen:    false
    property var    privIgnoreApps:   ["quickshell"]
    property int  wsPreviewId:      -1

    onActiveWorkspaceChanged: {
        windowPreviewOpen = false;
    }

    property string windowPreviewAddress: ""
    property string windowPreviewCls: ""
    property bool notifCenterExpanded: false
    property int  rightPanelPage:   0
    property int  cpModulesPage:    0
    property bool islandControlOpen: false
    property int  islandControlPage: 0
    property bool islandSearchOpen: false
    property bool notchControlOpen: false
    property bool ccFloat: true
    readonly property bool ncFusedOpen: notchControlOpen && !ccFloat

    function toggleControlCenter() {
        if (ccFloat) { toggleNotchControl(); return; }
        if (typeof unifiedFrame !== "undefined" && unifiedFrame.islandMode) toggleIslandControl();
        else toggleNotchControl();
    }

    property int  notchControlPage: 0
    property int  leftPanelPage:    0
    property bool mediaPendingClose: false
    property bool sysHovered:       false
    readonly property int cornerR: 14
    property bool brightnessMenuOpen: false
    property bool appLauncherOpen:  false
    property bool frameHidden:     false
    property bool profileMorphing:  false
    property bool profileFrameFade: false
    property bool profileFrameAnim: false
    property bool frameHeldHidden: false
    readonly property bool frameEffectivelyHidden: frameHidden || frameHeldHidden || islandHiddenByAutoHide

    function toggleFrameHidden() {
        frameHidden = !frameHidden;
        closeAll(true);
    }

    function setFrameHeldHidden(v) {
        frameHeldHidden = v;
        if (v) closeAll(true);
    }

    property bool islandAutoHideRevealed: false
    readonly property bool islandAutoHideActive: islandAutoHide && shellMode === "island"

    readonly property bool islandHiddenByAutoHide:
        islandAutoHideActive && !islandAutoHideRevealed &&
        !islandControlOpen && !islandSearchOpen && !(clipBulgeOpen && !clipPinned) && !privBulgeOpen && !battBulgeOpen && !privRevealed && !recBulgeOpen

    function setIslandAutoHide(enabled) {
        if (islandAutoHide === enabled) return;
        islandAutoHide = enabled;
        islandAutoHideRevealed = !enabled;
        islandAutoHideHideTimer.stop();
        savePrefs();
    }

    function islandAutoHideSetHover(hovered) {
        if (!islandAutoHideActive) return;
        if (hovered) {
            islandAutoHideHideTimer.stop();
            islandAutoHideRevealed = true;
        } else {
            islandAutoHideHideTimer.restart();
        }
    }

    onMediaMenuOpenChanged: {
        if (!mediaMenuOpen) {
            if (wifiViewOpen)      closeWifiView();
            if (btDevicesViewOpen) closeBtDevicesView();
        }
    }

    readonly property var _closeAllFlags: ["volumeMenuOpen", "sysMenuOpen", "powerMenuOpen", "calendarMenuOpen", "mediaMenuOpen",
        "brightnessMenuOpen", "windowPreviewOpen", "notchMediaOpen", "notchSearchOpen", "wsPreviewOpen", "netBulgeOpen",
        "clipBulgeOpen", "recBulgeOpen", "privBulgeOpen", "battBulgeOpen", "islandControlOpen", "islandSearchOpen", "notchControlOpen"]

    function closeAll(keepSettings) {
        if (lockScreenActive) return;
        _closeAllFlags.forEach(function (f) { globalState[f] = false; });
        if (!keepSettings) settingsOpen = false;
        if (btDevicesViewOpen) closeBtDevicesView();
        if (wifiViewOpen)      closeWifiView();
    }

    function toggleNotchControl() {
        if (lockScreenActive) return;
        if (notchControlOpen) {
            notchControlOpen = false;
        } else {
            closeAll(true);
            notchControlPage = 0;
            notchControlOpen = true;
        }
    }

    function openNotchControl(page) {
        if (lockScreenActive) return;
        notchControlPage = page;
        if (!notchControlOpen) { closeAll(true); notchControlOpen = true; }
    }

    function toggleIslandControl() {
        if (lockScreenActive) return;
        if (ccFloat) { toggleNotchControl(); return; }
        if (islandControlOpen) {
            islandControlOpen = false;
        } else {
            closeAll();
            islandControlOpen = true;
            islandControlPage = 0;
        }
    }

    function openIslandControlPage(page) {
        if (lockScreenActive) return;
        if (ccFloat) { openNotchControl(page === 1 || page === 3 ? 1 : 0); return; }
        if (islandControlOpen) {
            islandControlPage = page;
        } else {
            closeAll();
            islandControlOpen = true;
            islandControlPage = page;
        }
    }

    function peekWindowInstant(address) {
        if (!address) return;
        peekWindowsInstant([address]);
    }

    function peekWindowsInstant(addresses) {
        if (!addresses || addresses.length === 0) return;
        Quickshell.execDetached(["bash", "-c",
            "exec 9>$XDG_RUNTIME_DIR/qs_peek_noanim.lock; flock 9; " +
            "hyprctl eval 'hl.animation({ leaf = \"windowsMove\", enabled = false })' >/dev/null 2>&1; " +
            "for a in \"$@\"; do /usr/bin/python3 \"$HOME\"/.config/hypr/scripts/peek_window.py peek \"$a\"; done; " +
            "hyprctl eval 'hl.animation({ leaf = \"windowsMove\", enabled = true, speed = 6, spring = \"elasticSmoth\" })' >/dev/null 2>&1",
            "qs-peek"].concat(addresses));
    }

    property var wdPeekedAddresses: []

    function wdDeclutterAll() {
        var ws = activeWorkspace;
        var addrs = [];
        for (var i = 0; i < openClients.length; i++) {
            var c = openClients[i];
            if (c.workspace === ws && c.floating) {
                addrs.push(c.address);
                Quickshell.execDetached(["/usr/bin/python3",
                    Quickshell.env("HOME") + "/.config/hypr/scripts/peek_window.py", "declutter", c.address]);
            }
        }
        wdPeekedAddresses = addrs;
    }

    function wdRestoreAll() {
        for (var i = 0; i < wdPeekedAddresses.length; i++) {
            Quickshell.execDetached(["/usr/bin/python3",
                Quickshell.env("HOME") + "/.config/hypr/scripts/peek_window.py", "restore", wdPeekedAddresses[i]]);
        }
        wdPeekedAddresses = [];
    }

    function toggleDesktopEditMode() {
        if (lockScreenActive) return;
        if (desktopEditMode) {
            desktopEditPrep = false;
            desktopEditMode = false;
            wdRestoreAll();
        } else if (!desktopEditPrep) {
            desktopEditPrep = true;
        }
    }

    function commitDesktopEditEnter() {
        if (!desktopEditPrep) return;
        desktopEditPrep = false;
        if (lockScreenActive) return;
        desktopEditMode = true;
        wdDeclutterAll();
    }

    function closeTopBar() {
        if (lockScreenActive) return;
        volumeMenuOpen     = false;
        sysMenuOpen        = false;
        powerMenuOpen      = false;
        brightnessMenuOpen = false;
        windowPreviewOpen  = false;
        notchMediaOpen     = false;
        wsPreviewOpen      = false;
        netBulgeOpen       = false;
    }

    function closeOthers(except) {
        if (lockScreenActive) return;
        if (except !== "volume")     volumeMenuOpen     = false;
        if (except !== "sys")        sysMenuOpen        = false;
        if (except !== "power")      powerMenuOpen      = false;
        if (except !== "calendar")   calendarMenuOpen   = false;
        if (except !== "brightness") brightnessMenuOpen = false;
        if (except !== "preview")    windowPreviewOpen  = false;
        if (except !== "notchMedia") notchMediaOpen     = false;
        if (except !== "notchSearch") notchSearchOpen   = false;
        if (except !== "wsPreview")  wsPreviewOpen      = false;
        if (except !== "net")        netBulgeOpen       = false;
        if (except !== "clip")       clipBulgeOpen      = false;
        if (except !== "rec")        recBulgeOpen       = false;
        if (except !== "priv")       privBulgeOpen      = false;
        if (except !== "batt")       battBulgeOpen      = false;
    }
}
