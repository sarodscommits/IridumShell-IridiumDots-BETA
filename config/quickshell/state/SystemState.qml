import QtQuick

// System metrics, audio, network, battery, weather and brightness
AppearanceState {
    property string volumeText:     "Vol --%"
    property int    rawVolumeValue: 0
    property int    rawMicVolume:   0
    property int    cpuPercent:     0
    property int    ramUsedMb:      0
    property int    ramPercent:     0
    property int    gpuPercent:     -1
    property int    gpuTemp:        -1
    property bool   gpuLactOk:       false
    property string gpuName:         ""
    property int    gpuTempJunction: -1
    property int    gpuTempMem:      -1
    property int    gpuVramUsedMb:   -1
    property int    gpuVramTotalMb:  -1
    property real   gpuPowerW:       -1
    property real   gpuPowerCapW:    -1
    property int    gpuClockMhz:     -1
    property int    gpuVramClockMhz: -1
    property int    gpuFanRpm:       -1
    property int    gpuFanPercent:   -1
    property int    cpuTemp:        -1
    property int    diskPercent:    0
    property string diskUsedStr:    ""
    property string diskTotalStr:   ""
    property real   netDownKBps:    0
    property real   netUpKBps:      0
    property bool   isMuted:        false
    property bool   isMicMuted:     false
    property bool   brightnessAdjusting: false
    property string perfProfile:     ""
    property bool   perfApplying:    false
    property int  rawBrightness:    80
    property string netWifi:        ""
    property int    netEthCount:    0
    property bool   netWifiEnabled: true
    property bool   netWifiHw:      false
    property string netIP:          ""
    property bool   netBluetoothEnabled: false
    property bool   netBluetoothHw:      false
    property bool   wifiRadioBusy:       false
    property bool   btRadioBusy:         false
    property int    wifiPendingOn:       -1
    property int    btPendingOn:         -1
    property var    btConnectedNames:    []
    property bool   wifiViewOpen:       false
    property bool   wifiScanning:       false
    property string wifiConnectingSsid: ""
    property string wifiPasswordSsid:   ""
    property string wifiPasswordDraft:  ""
    property bool   wifiPasswordVisible: false
    property string wifiConnectError:   ""
    property bool   btDevicesViewOpen: false
    property bool   btScanning:        false
    property string btPromptType:      ""
    property string btPromptText:      ""
    property string btPendingMac:      ""
    property string btPasswordDraft:   ""
    property bool   hasBattery:      false
    property int    batteryPercent:  100
    property bool   batteryCharging: false
    property bool   batteryPlugged:  false
    property string batteryStatus:   ""
    property int    batteryMinutes:  -1
    property bool   batterySim:      false
    property int    battLowThreshold: 15
    property bool   battLowNotified:  false
    property bool   battFullNotified: false
    property bool   battPrimed:       false
    property string fetchOS:     ""
    property string fetchKernel: ""
    property string fetchWM:     ""
    property string fetchCPU:    ""
    property string fetchGPU:    ""
    property string fetchRAM:    ""
    property string fetchDisk:   ""
    property string fetchUptime: ""
    property string fetchUser:     ""
    property string fetchHost:     ""
    property string fetchPackages: ""
    property string fetchShell:    ""
    property string fetchDisplay:  ""
    property string fetchDE:       ""
    property string fetchFont:     ""
    property string fetchTerminal: ""
    property string fetchSwap:     ""
    property string fetchLocale:   ""
    property string weatherCity:     ""
    property string weatherTemp:     ""
    property string weatherFeel:     ""
    property string weatherDesc:     ""
    property string weatherHumidity: ""
    property string weatherWind:     ""
    property string weatherMax:      ""
    property string weatherMin:      ""
    property var    weatherForecast: []
    property var calendarEvents: ({})
    property bool calEventInputFocused: false

    function openBtDevicesView() {
        console.log("[BT] openBtDevicesView()");
        mediaMenuOpen     = true;
        rightPanelPage    = 0;
        btDevicesViewOpen = true;
        networkBackend.btCtlProcRef.running = true;
    }

    function closeBtDevicesView() {
        console.log("[BT] closeBtDevicesView()");
        btDevicesViewOpen = false;
        btPromptType      = "";
        btPendingMac      = "";
        btPasswordDraft   = "";
        if (networkBackend.btCtlProcRef.running) networkBackend.btCtlProcRef.write("scan off\n");
        networkBackend.stopBtScan();
    }

    function openWifiView() {
        console.log("[WIFI] openWifiView()");
        mediaMenuOpen    = true;
        rightPanelPage   = 0;
        wifiViewOpen     = true;
        wifiConnectError = "";
        networkBackend.wifiScanNetworks();
    }

    function closeWifiView() {
        console.log("[WIFI] closeWifiView()");
        wifiViewOpen        = false;
        wifiPasswordSsid     = "";
        wifiPasswordDraft    = "";
        wifiConnectError      = "";
        wifiConnectingSsid    = "";
        networkBackend.wifiScanProcRef.running = false;
    }

    function wifiRequestPassword(ssid) {
        wifiPasswordSsid    = ssid;
        wifiPasswordDraft   = "";
        wifiPasswordVisible = false;
        wifiPasswordFocusTimer.restart();
    }

    function wifiSubmitPassword() {
        var ssid = wifiPasswordSsid;
        var pw   = wifiPasswordDraft;
        wifiPasswordSsid    = "";
        wifiPasswordDraft   = "";
        wifiPasswordVisible = false;
        networkBackend.wifiConnect(ssid, pw);
    }

    function wifiCancelPassword() {
        wifiPasswordSsid     = "";
        wifiPasswordDraft    = "";
        wifiPasswordVisible  = false;
        wifiConnectingSsid   = "";
    }

    function wifiScanNetworks()              { networkBackend.wifiScanNetworks(); }
    function wifiSetEnabled(enabled)         { networkBackend.wifiSetEnabled(enabled); }
    function wifiConnect(ssid, password)     { networkBackend.wifiConnect(ssid, password); }
    function wifiDisconnect(ssid)            { networkBackend.wifiDisconnect(ssid); }
    function wifiForgetNetwork(ssid)         { networkBackend.wifiForgetNetwork(ssid); }
    function btSetEnabled(enabled)           { networkBackend.btSetEnabled(enabled); }
    function btConnectOrDisconnect(mac, isPaired, isConnected) { networkBackend.btConnectOrDisconnect(mac, isPaired, isConnected); }
    function btSubmitPrompt(text)            { networkBackend.btSubmitPrompt(text); }
    function btCancelPrompt()                { networkBackend.btCancelPrompt(); }
    function reloadWeather()                 { weatherBackend.reload(); }
    function openTerminal()                  { terminalLauncher.open(); }

    function toggleMute() {
        if (isMuted) {
            audioPlayer.setOutputMuted(false);
            isMuted = false;
            volumeText = rawVolumeValue + "%";
        } else {
            audioPlayer.setOutputMuted(true);
            isMuted = true;
            volumeText = "Mute";
        }
    }

    function toggleMicMute() {
        if (isMicMuted) {
            audioPlayer.setMicMuted(false);
            isMicMuted = false;
        } else {
            audioPlayer.setMicMuted(true);
            isMicMuted = true;
        }
    }

    function toggleDnd() {
        dndEnabled = !dndEnabled;
    }

    property bool   batterySaver:      false
    property int    _saverPrevBright:  -1
    property string _saverPrevProfile: ""

    function setBatterySaver(on) {
        if (on === batterySaver) return;
        if (on) {
            _saverPrevBright  = rawBrightness;
            _saverPrevProfile = (perfProfile !== "" && perfProfile !== "low") ? perfProfile : "medium";
            batterySaver = true;
            gamingWindow.setPerfProfile("low");
            setBrightness(20);
        } else {
            batterySaver = false;
            gamingWindow.setPerfProfile(_saverPrevProfile !== "" ? _saverPrevProfile : "medium");
            if (_saverPrevBright > 20) setBrightness(_saverPrevBright);
            _saverPrevBright = -1;
        }
    }

    onPerfProfileChanged: if (batterySaver && perfProfile !== "" && perfProfile !== "low") batterySaver = false
    property bool   airplaneMode:     false
    property bool   _planePrevWifi:   true
    property bool   _planePrevBt:     false
    property double _planeSinceMs:    0

    function setAirplaneMode(on) {
        if (on === airplaneMode) return;
        _planeSinceMs = Date.now();
        if (on) {
            _planePrevWifi = wifiPendingOn !== -1 ? wifiPendingOn === 1 : netWifiEnabled;
            _planePrevBt   = btPendingOn   !== -1 ? btPendingOn   === 1 : netBluetoothEnabled;
            airplaneMode = true;
            if (netWifiEnabled || wifiPendingOn === 1) wifiSetEnabled(false);
            if (netBluetoothEnabled || btPendingOn === 1) btSetEnabled(false);
        } else {
            airplaneMode = false;
            var w = _planePrevWifi || !_planePrevBt;
            if (w) wifiSetEnabled(true);
            if (_planePrevBt) btSetEnabled(true);
        }
    }

    function _planeCheck() {
        if (airplaneMode && (netWifiEnabled || netBluetoothEnabled) && Date.now() - _planeSinceMs > 4000)
            airplaneMode = false;
    }

    onNetWifiEnabledChanged:      _planeCheck()
    onNetBluetoothEnabledChanged: _planeCheck()
    property bool eyeCare:       false
    property int  eyeCareTemp:   4000
    property bool eyeCareHasSunset: false
    readonly property bool eyeCareOverlay: eyeCare && !eyeCareHasSunset
    property double lastBrightnessSetMs: 0

    function setBrightness(v) {
        v = Math.max(0, Math.min(100, Math.round(v)));
        rawBrightness = v;
        brightnessApplyProcess.queue(v);
    }
}
