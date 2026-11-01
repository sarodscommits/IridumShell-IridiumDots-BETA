import QtQuick
import Quickshell
import Quickshell.Io

// WiFi (nmcli) + Bluetooth (bluetoothctl) backend; state lives in globalState
Item {
    id: networkBackend

    property var globalState: null
    property var wifiNetworksModel: null
    property var btPairedModel: null
    property var btAvailableModel: null

    // Process refs for the few UI spots that need them
    property alias btCtlProcRef: btCtlProcess
    property alias wifiScanProcRef: netWifiScanProcess

    // Called from closeBtDevicesView() in shell.qml when the view closes.
    function stopBtScan() { btScanStopTimer.restart(); }

    // PIN/passkey prompt signal
    signal btPromptNeedsFocus()

Process {
id: netProcess
command: ["bash", "-c",
  "eth=$(nmcli -t -f type,state dev 2>/dev/null | awk -F: '$1==\"ethernet\" && $2==\"connected\"{found=1} END{print found+0}'); " +
  "wifi_hw=$(nmcli -t -f wifi radio 2>/dev/null | head -1); " +
  "wifi_ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | awk -F: '/^yes/{print $2}'); " +
  "ip=$(ip route get 1.1.1.1 2>/dev/null | awk '/src/{print $7;exit}'); " +
  "printf '%s\\t%s\\t%s\\t%s' \"$eth\" \"${wifi_hw:-none}\" \"${wifi_ssid:-}\" \"${ip:-}\""
]
running: true
stdout: SplitParser {
onRead: (line) => {
var parts = line.split("\t");
if (parts.length >= 4) {
  globalState.netEthCount    = parseInt(parts[0]) || 0;
  globalState.netWifiEnabled = parts[1].trim() === "enabled";
  globalState.netWifiHw      = parts[1].trim() !== "none";
  globalState.netWifi        = parts[2];
  globalState.netIP          = parts[3];
  globalState.wifiRadioBusy  = false;
  // Real state arrived: drop the optimistic value
  globalState.wifiPendingOn  = -1;
}
    }
  }
}
// Toggles the wifi radio, then re-polls the real state
Process {
id: netWifiRadioProcess
property bool enabling: true
command: ["bash", "-c",
  "nmcli radio wifi " + (netWifiRadioProcess.enabling ? "on" : "off") + " >/dev/null 2>&1; " +
  "printf 'WIFI_RADIO_CODE:%s\\n' \"$?\""
]
running: false
stdout: SplitParser {
onRead: (line) => {
  console.log("[WIFI-RADIO] stdout:", line);
  var m = line.match(/^WIFI_RADIO_CODE:(\d+)$/);
  if (!m) return;
  console.log("[WIFI-RADIO] result code =", m[1], "enabling =", netWifiRadioProcess.enabling);
  netProcess.running = true;
}
}
stderr: SplitParser { onRead: (line) => console.log("[WIFI-RADIO] stderr:", line) }
onExited: (exitCode, exitStatus) => {
    console.log("[WIFI-RADIO] process exited. exitCode =", exitCode, "exitStatus =", exitStatus);
    // onExited always clears the busy flag and re-polls
    globalState.wifiRadioBusy = false;
    netWifiRadioWatchdog.stop();
    netProcess.running = true;
}
}

// Watchdog: kill a hung radio toggle after 8s
Timer {
id: netWifiRadioWatchdog
interval: 8000; repeat: false
onTriggered: { if (netWifiRadioProcess.running) netWifiRadioProcess.running = false; }
}

// ── WiFi: scan (SSID last so ":" doesn't break parsing) ──


Process {
id: netWifiScanProcess
command: ["bash", "-c",
  "nmcli -t -f NAME connection show 2>/dev/null | while IFS= read -r n; do printf 'SAVED:%s\\n' \"$n\"; done; " +
  "nmcli dev wifi rescan >/dev/null 2>&1; sleep 1.5; " +
  "nmcli -t -f SIGNAL,SECURITY,IN-USE,SSID dev wifi list 2>/dev/null | while IFS= read -r n; do printf 'NET:%s\\n' \"$n\"; done"
]
running: false
property var _savedProfiles: ({})

function indexOfSsid(ssid) {
    for (var i = 0; i < wifiNetworksModel.count; i++) {
        if (wifiNetworksModel.get(i).ssid === ssid) return i;
    }
    return -1;
}
function upsert(ssid, strength, secured, inUse, saved) {
    var i = indexOfSsid(ssid);
    if (i === -1) {
        wifiNetworksModel.append({ ssid: ssid, strength: strength, secured: secured, inUse: inUse, saved: saved });
        return;
    }
    var existing = wifiNetworksModel.get(i);
    if (strength > existing.strength) wifiNetworksModel.setProperty(i, "strength", strength);
    wifiNetworksModel.setProperty(i, "secured", secured);
    if (inUse) wifiNetworksModel.setProperty(i, "inUse", true);
    if (saved) wifiNetworksModel.setProperty(i, "saved", true);
}

onRunningChanged: {
    console.log("[WIFI-SCAN] running =", running);
    if (running) {
        wifiNetworksModel.clear();
        _savedProfiles = ({});
        globalState.wifiScanning = true;
    }
}
stdout: SplitParser {
onRead: (line) => {
  console.log("[WIFI-SCAN] stdout raw:", JSON.stringify(line));
  if (line.indexOf("SAVED:") === 0) {
      var name = line.substring(6).trim();
      if (name) netWifiScanProcess._savedProfiles[name] = true;
      return;
  }
  if (line.indexOf("NET:") !== 0) return;
  var netLine = line.substring(4);
  var parts = netLine.split(":");
  if (parts.length < 4) { console.log("[WIFI-SCAN] line dropped, fewer than 4 fields:", parts.length); return; }
  var strength  = parseInt(parts[0]) || 0;
  var secBits = parts[1];
  var inUse   = parts[2].trim() === "*";
  var ssid    = parts.slice(3).join(":").trim();
  if (!ssid) { console.log("[WIFI-SCAN] line dropped, empty SSID"); return; }
  var secured = secBits.trim() !== "" && secBits.trim() !== "--";
  var saved   = netWifiScanProcess._savedProfiles[ssid] === true;
  console.log("[WIFI-SCAN] red parseada:", ssid, "strength=", strength, "secured=", secured, "inUse=", inUse, "saved=", saved);
  netWifiScanProcess.upsert(ssid, strength, secured, inUse, saved);
}
}
stderr: SplitParser { onRead: (line) => console.log("[WIFI-SCAN] stderr:", line) }
onExited: (exitCode, exitStatus) => {
    console.log("[WIFI-SCAN] process exited. exitCode =", exitCode, "exitStatus =", exitStatus, "networks found =", wifiNetworksModel.count);
    globalState.wifiScanning = false;
    // Sort: connected network first, then by descending signal strength.
    var arr = [];
    for (var i = 0; i < wifiNetworksModel.count; i++) {
        var it = wifiNetworksModel.get(i);
        arr.push({ ssid: it.ssid, strength: it.strength, secured: it.secured, inUse: it.inUse, saved: it.saved });
    }
    arr.sort(function(a, b) {
        if (a.inUse !== b.inUse) return a.inUse ? -1 : 1;
        return b.strength - a.strength;
    });
    wifiNetworksModel.clear();
    for (var j = 0; j < arr.length; j++) wifiNetworksModel.append(arr[j]);
}
}

// ── WiFi: connect (asks for a password if needed) ──
Process {
id: netWifiConnectProcess
property string ssid:     ""
property string password: ""
property string _output:  ""
command: ["bash", "-c",
  "out=$(nmcli dev wifi connect " + JSON.stringify(netWifiConnectProcess.ssid) +
  (netWifiConnectProcess.password !== "" ? (" password " + JSON.stringify(netWifiConnectProcess.password)) : "") +
  " 2>&1); ec=$?; printf '%s\\n' \"$out\"; printf 'WIFI_RESULT_CODE:%s\\n' \"$ec\""
]
running: false
onRunningChanged: {
    console.log("[WIFI-CONNECT] running =", running, "ssid =", ssid);
    if (running) _output = "";
}
stdout: SplitParser {
onRead: (line) => {
  console.log("[WIFI-CONNECT] stdout:", line);
  var m = line.match(/^WIFI_RESULT_CODE:(\d+)$/);
  if (!m) { netWifiConnectProcess._output += line + "\n"; return; }
  var code = parseInt(m[1]);
  var out  = netWifiConnectProcess._output;
  var ssid = netWifiConnectProcess.ssid;
  console.log("[WIFI-CONNECT] result code =", code, "for", ssid);
  globalState.wifiConnectingSsid = "";
  if (code === 0) {
      globalState.wifiConnectError = "";
      globalState.wifiScanNetworks();
  } else if (/secrets were required|no key available|802-11-wireless-security|key-mgmt/i.test(out)) {
      globalState.wifiConnectError = globalState.tr("wifi_wrong_password");
      globalState.wifiRequestPassword(ssid);
  } else {
      globalState.wifiConnectError = globalState.tr("wifi_connect_failed");
  }
}
}
stderr: SplitParser { onRead: (line) => console.log("[WIFI-CONNECT] stderr:", line) }
onExited: (exitCode, exitStatus) => {
    console.log("[WIFI-CONNECT] process exited. exitCode =", exitCode, "exitStatus =", exitStatus);
}
}

// ── WiFi: disconnect (falls back to the real interface) ──
Process {
id: netWifiDisconnectProcess
property string ssid: ""
command: ["bash", "-c",
  "nmcli con down id " + JSON.stringify(netWifiDisconnectProcess.ssid) + " >/dev/null 2>&1; ec=$?; " +
  "if [ \"$ec\" != \"0\" ]; then " +
  "dev=$(nmcli -t -f DEVICE,TYPE dev status 2>/dev/null | awk -F: '$2==\"wifi\"{print $1; exit}'); " +
  "if [ -n \"$dev\" ]; then nmcli dev disconnect \"$dev\" >/dev/null 2>&1; ec=$?; fi; " +
  "fi; " +
  "printf 'WIFI_DISCONNECT_CODE:%s\\n' \"$ec\""
]
running: false
stdout: SplitParser {
onRead: (line) => {
  console.log("[WIFI-DISCONNECT] stdout:", line);
  var m = line.match(/^WIFI_DISCONNECT_CODE:(\d+)$/);
  if (!m) return;
  console.log("[WIFI-DISCONNECT] result code =", m[1]);
  globalState.wifiConnectingSsid = "";
  globalState.wifiScanNetworks();
}
}
stderr: SplitParser { onRead: (line) => console.log("[WIFI-DISCONNECT] stderr:", line) }
onExited: (exitCode, exitStatus) => {
    console.log("[WIFI-DISCONNECT] process exited. exitCode =", exitCode, "exitStatus =", exitStatus);
}
}

// ── WiFi: forget network ──
Process {
id: netWifiForgetProcess
property string ssid: ""
command: ["bash", "-c",
  "nmcli con delete id " + JSON.stringify(netWifiForgetProcess.ssid) + " >/dev/null 2>&1; ec=$?; " +
  "printf 'WIFI_FORGET_CODE:%s\\n' \"$ec\""
]
running: false
stdout: SplitParser {
onRead: (line) => {
  console.log("[WIFI-FORGET] stdout:", line);
  var m = line.match(/^WIFI_FORGET_CODE:(\d+)$/);
  if (!m) return;
  console.log("[WIFI-FORGET] result code =", m[1]);
  globalState.wifiConnectingSsid = "";
  globalState.wifiScanNetworks();
}
}
stderr: SplitParser { onRead: (line) => console.log("[WIFI-FORGET] stderr:", line) }
onExited: (exitCode, exitStatus) => {
    console.log("[WIFI-FORGET] process exited. exitCode =", exitCode, "exitStatus =", exitStatus);
}
}

Process {
id: btProcess
command: ["bash", "-c",
  "command -v bluetoothctl >/dev/null 2>&1 || { printf 'none\\tno'; exit 0; }; " +
  "ctl=$(bluetoothctl show 2>/dev/null); " +
  "if [ -z \"$ctl\" ]; then printf 'none\\tno'; exit 0; fi; " +
  "pw=$(printf '%s\\n' \"$ctl\" | awk -F': ' '/Powered:/{print $2}'); " +
  "printf 'hw\\t%s' \"${pw:-no}\""
]
running: true
stdout: SplitParser {
onRead: (line) => {
var parts = line.split("\t");
if (parts.length >= 2) {
  globalState.netBluetoothHw      = parts[0].trim() === "hw";
  globalState.netBluetoothEnabled = parts[1].trim() === "yes";
  globalState.btRadioBusy         = false;
  // Real state arrived: drop the optimistic value
  globalState.btPendingOn         = -1;
}
    }
  }
}
Timer {
interval: 3000; running: true; repeat: true
onTriggered: btProcess.running = true
}

// Toggles bluetooth power, then re-checks the real state
Process {
id: netBluetoothRadioProcess
property bool enabling: true
command: ["bash", "-c",
  "bluetoothctl power " + (netBluetoothRadioProcess.enabling ? "on" : "off") + " >/dev/null 2>&1; " +
  "printf 'BT_RADIO_CODE:%s\\n' \"$?\""
]
running: false
stdout: SplitParser {
onRead: (line) => {
  console.log("[BT-RADIO] stdout:", line);
  var m = line.match(/^BT_RADIO_CODE:(\d+)$/);
  if (!m) return;
  console.log("[BT-RADIO] result code =", m[1], "enabling =", netBluetoothRadioProcess.enabling);
  btProcess.running = true;
  if (netBluetoothRadioProcess.enabling) {
      // Restart the bluetoothctl session when the adapter comes back on
      if (globalState.btDevicesViewOpen) {
          btCtlProcess.running = false;
          btCtlProcess.running = true;
      }
  } else {
      // It was turned off: whatever was in the list is no longer valid.
      btPairedModel.clear();
      btAvailableModel.clear();
  }
}
}
stderr: SplitParser { onRead: (line) => console.log("[BT-RADIO] stderr:", line) }
onExited: (exitCode, exitStatus) => {
    console.log("[BT-RADIO] process exited. exitCode =", exitCode, "exitStatus =", exitStatus);
    // onExited always clears the busy flag
    globalState.btRadioBusy = false;
    netBluetoothRadioWatchdog.stop();
    btProcess.running = true;
}
}

// Watchdog: kill a hung power toggle after 8s
Timer {
id: netBluetoothRadioWatchdog
interval: 8000; repeat: false
onTriggered: { if (netBluetoothRadioProcess.running) netBluetoothRadioProcess.running = false; }
}

// ── Bluetooth: route EasyEffects output to the active sink ──
Process {
id: btAudioRouteProcess
property string mac: ""
command: ["bash", "-c",
  "command -v pw-dump >/dev/null 2>&1 && command -v jq >/dev/null 2>&1 && command -v pw-link >/dev/null 2>&1 || exit 0; " +
  "MAC=" + JSON.stringify(btAudioRouteProcess.mac) + "; " +
  "TARGET_ID=\"\"; TARGET_NAME=\"\"; DUMP=\"\"; " +
  // Wait for bluetooth first; ALSA is only the last resort
  "for i in 1 2 3 4 5 6 7 8; do " +
  "  DUMP=$(pw-dump 2>/dev/null); " +
  "  if [ -n \"$MAC\" ]; then " +
  "    TARGET_ID=$(echo \"$DUMP\" | jq -r --arg a \"$MAC\" '.[] | select(.info.props.\"media.class\"==\"Audio/Sink\" and (.info.props.\"api.bluez5.address\"==$a)) | .id' | head -1); " +
  "  fi; " +
  "  [ -z \"$TARGET_ID\" ] && TARGET_ID=$(echo \"$DUMP\" | jq -r '.[] | select(.info.props.\"media.class\"==\"Audio/Sink\" and (.info.props.\"api.bluez5.address\"!=null)) | .id' | head -1); " +
  "  [ -n \"$TARGET_ID\" ] && break; " +
  // No MAC: try briefly, then fall back to ALSA
  "  [ -z \"$MAC\" ] && [ \"$i\" -ge 2 ] && break; " +
  "  sleep 0.5; " +
  "done; " +
  "if [ -z \"$TARGET_ID\" ]; then " +
  "  DUMP=$(pw-dump 2>/dev/null); " +
  // Pick the ALSA sink with the highest priority.session
  "  TARGET_ID=$(echo \"$DUMP\" | jq -r '[.[] | select(.info.props.\"media.class\"==\"Audio/Sink\" and (.info.props.\"api.alsa.path\"!=null) and .info.props.\"node.name\"!=\"easyeffects_sink\")] | sort_by(-((.info.props.\"priority.session\"|tonumber?) // 0)) | .[0].id // empty'); " +
  "fi; " +
  "if [ -z \"$TARGET_ID\" ]; then echo 'AUDIO_ROUTE:no-sink-found'; exit 0; fi; " +
  "TARGET_NAME=$(echo \"$DUMP\" | jq -r --arg id \"$TARGET_ID\" '.[] | select(.type==\"PipeWire:Interface:Node\" and (.id|tostring)==$id) | .info.props.\"node.name\"' | head -1); " +
  // Source is always easyeffects_sink:monitor_FL/FR
  "SRC_FL=\"easyeffects_sink:monitor_FL\"; SRC_FR=\"easyeffects_sink:monitor_FR\"; " +
  "DST_FL=\"$TARGET_NAME:playback_FL\"; DST_FR=\"$TARGET_NAME:playback_FR\"; " +
  "pw-link -l 2>/dev/null | grep -B1 '|<- easyeffects_sink:monitor_' | grep -v '^--$' | while read -r dstline; do " +
  "  read -r srcline; " +
  "  dst=$(echo \"$dstline\" | sed -E 's/^[[:space:]]+//'); " +
  "  src=$(echo \"$srcline\" | sed -E 's/^[[:space:]]*[0-9]*[[:space:]]*\\|<-[[:space:]]*//'); " +
  "  [ -n \"$dst\" ] && [ -n \"$src\" ] && pw-link -d \"$src\" \"$dst\" 2>/dev/null; " +
  "done; " +
  "echo \"AUDIO_ROUTE:target=$TARGET_ID($TARGET_NAME) dst_fl=$DST_FL dst_fr=$DST_FR src_fl=$SRC_FL src_fr=$SRC_FR\"; " +
  "pw-link \"$SRC_FL\" \"$DST_FL\" 2>&1; " +
  "pw-link \"$SRC_FR\" \"$DST_FR\" 2>&1; " +
  // Keep easyeffects_sink at 100%; the hardware sink is the real volume
  "pactl set-sink-volume easyeffects_sink 100% >/dev/null 2>&1; " +
  "[ -n \"$TARGET_NAME\" ] && pactl set-sink-mute \"$TARGET_NAME\" 0 >/dev/null 2>&1; " +
  // Atomic cache write (temp + mv)
  "[ -n \"$TARGET_ID\" ] && echo \"$TARGET_ID\" > \"$HOME/.cache/qs-eq-hw-sink.tmp\" && mv -f \"$HOME/.cache/qs-eq-hw-sink.tmp\" \"$HOME/.cache/qs-eq-hw-sink\"; " +
  "[ -n \"$TARGET_NAME\" ] && echo \"$TARGET_NAME\" > \"$HOME/.cache/qs-eq-hw-sink-name.tmp\" && mv -f \"$HOME/.cache/qs-eq-hw-sink-name.tmp\" \"$HOME/.cache/qs-eq-hw-sink-name\"; " +
  "pactl set-default-sink easyeffects_sink >/dev/null 2>&1; " +
  "echo 'AUDIO_ROUTE:done'"
]
running: false
stdout: SplitParser { onRead: (line) => console.log("[BT-AUDIO-ROUTE]", line) }
stderr: SplitParser { onRead: (line) => console.log("[BT-AUDIO-ROUTE] stderr:", line) }
onExited: (exitCode, exitStatus) => {
    console.log("[BT-AUDIO-ROUTE] process exited. exitCode =", exitCode, "exitStatus =", exitStatus);
}
}

// ── One-time diagnostics at startup ──
Process {
id: btDiagProcess
command: ["bash", "-c",
  "echo '[BT-DIAG] ---- bluetooth diagnostics ----'; " +
  "echo \"[BT-DIAG] which bluetoothctl: $(command -v bluetoothctl || echo NO_ENCONTRADO)\"; " +
  "echo \"[BT-DIAG] which stdbuf: $(command -v stdbuf || echo NO_ENCONTRADO)\"; " +
  "bluetoothctl --version 2>&1 | sed 's/^/[BT-DIAG] version: /'; " +
  "echo \"[BT-DIAG] systemctl is-active bluetooth: $(systemctl is-active bluetooth 2>&1)\"; " +
  "echo \"[BT-DIAG] usuario en grupo lp/bluetooth? $(groups 2>&1)\"; " +
  "echo '[BT-DIAG] rfkill (soft/hard block is a VERY common cause):'; rfkill list bluetooth 2>&1 | sed 's/^/[BT-DIAG]   /'; " +
  "echo '[BT-DIAG] bluetoothctl list:'; bluetoothctl list 2>&1 | sed 's/^/[BT-DIAG]   /'; " +
  "echo '[BT-DIAG] bluetoothctl show:'; bluetoothctl show 2>&1 | sed 's/^/[BT-DIAG]   /'; " +
  "echo '[BT-DIAG] ---- end of diagnostics ----'"
]
running: true
stdout: SplitParser { onRead: (line) => console.log(line) }
stderr: SplitParser { onRead: (line) => console.log("[BT-DIAG] stderr:", line) }
}

// Create the initial EasyEffects link once after startup
Timer {
interval: 3000
running: true
repeat: false
onTriggered: {
    btAudioRouteProcess.mac = "";
    btAudioRouteProcess.running = false;
    btAudioRouteProcess.running = true;
}
}

// ── Bluetooth: device list (interactive bluetoothctl) ──


Process {
id: btCtlProcess
// stdbuf -oL: force line buffering through the pipe
command: ["stdbuf", "-oL", "bluetoothctl"]
running: false
stdinEnabled: true

property bool _seedingPaired:    false
property bool _seedingConnected: false

function modelForMac(mac) {
    for (var i = 0; i < btPairedModel.count; i++) {
        if (btPairedModel.get(i).mac === mac) return btPairedModel;
    }
    for (var j = 0; j < btAvailableModel.count; j++) {
        if (btAvailableModel.get(j).mac === mac) return btAvailableModel;
    }
    return null;
}
function indexInModel(model, mac) {
    for (var i = 0; i < model.count; i++) {
        if (model.get(i).mac === mac) return i;
    }
    return -1;
}
// pairedHint picks the model (true = saved, false = available)
function upsertDevice(mac, name, pairedHint) {
    var existing = modelForMac(mac);
    if (existing) {
        var idx = indexInModel(existing, mac);
        if (name && name !== mac) existing.setProperty(idx, "name", name);
        return { model: existing, index: idx };
    }
    var target = pairedHint ? btPairedModel : btAvailableModel;
    target.append({ mac: mac, name: (name && name !== mac) ? name : mac, paired: !!pairedHint, connected: false });
    return { model: target, index: target.count - 1 };
}
function removeDevice(mac) {
    var m = modelForMac(mac);
    if (!m) return;
    var idx = indexInModel(m, mac);
    if (idx !== -1) m.remove(idx);
}
// Moves a device between saved and available
function moveToModel(mac, toPaired) {
    var fromModel = modelForMac(mac);
    if (!fromModel) { upsertDevice(mac, "", toPaired); return; }
    var idx = indexInModel(fromModel, mac);
    if (idx === -1) return;
    var toModel = toPaired ? btPairedModel : btAvailableModel;
    if (fromModel === toModel) { fromModel.setProperty(idx, "paired", toPaired); return; }
    var item = fromModel.get(idx);
    var copy = { mac: item.mac, name: item.name, paired: toPaired, connected: item.connected };
    if (indexInModel(toModel, mac) === -1) toModel.append(copy);
    fromModel.remove(idx);
}
function setProp(mac, prop, value) {
    if (prop === "paired") { moveToModel(mac, value); return; }
    var i = upsertDevice(mac, "", false);
    i.model.setProperty(i.index, prop, value);
}
// Only replace the name if the new one is better than the MAC
function setNameIfBetter(mac, candidateName) {
    if (!candidateName || candidateName === mac) return;
    var m = modelForMac(mac);
    if (!m) { upsertDevice(mac, candidateName, false); return; }
    var idx = indexInModel(m, mac);
    var current = m.get(idx).name;
    if (!current || current === mac) m.setProperty(idx, "name", candidateName);
}

function handleLine(rawLine) {
    console.log("[BT] stdout raw:", JSON.stringify(rawLine));
    // Strip ANSI color codes
    var noAnsi = rawLine.replace(/\x1b\[[0-9;]*[a-zA-Z]/g, "");
    // Keep only what follows the last \r (prompt redraw)
    var segments = noAnsi.split("\r");
    var line = segments[segments.length - 1].trim();
    if (line !== rawLine.trim()) console.log("[BT] stdout clean:", JSON.stringify(line));

    // ── Adapter reset: reseed paired/connected devices ──
    if (/^hci\d+ added$/.test(line)) {
        console.log("[BT] adaptador re-detectado (hci added) — resincronizando estado de dispositivos");
        btSeedPairedTimer.restart();
        return;
    }

    // ── Pairing agent prompts ──
    if (line.indexOf("Confirm passkey") !== -1) {
        var pm = line.match(/Confirm passkey (\d+)/);
        globalState.btPromptType = "confirm";
        globalState.btPromptText = pm ? pm[1] : "";
        return;
    }
    if (line.indexOf("Enter PIN code") !== -1) {
        globalState.btPromptType    = "pin";
        globalState.btPromptText    = "";
        globalState.btPasswordDraft = "";
        networkBackend.btPromptNeedsFocus();
        return;
    }
    if (line.indexOf("Enter passkey") !== -1) {
        globalState.btPromptType    = "passkey";
        globalState.btPromptText    = "";
        globalState.btPasswordDraft = "";
        networkBackend.btPromptNeedsFocus();
        return;
    }
    if (line.indexOf("Pairing successful") !== -1) {
        globalState.btPromptType = "";
        var pmac = globalState.btPendingMac;
        if (pmac) {
            setProp(pmac, "paired", true);
            btCtlProcess.write("trust "   + pmac + "\n");
            btCtlProcess.write("connect " + pmac + "\n");
        }
        return;
    }
    if (line.indexOf("Failed to pair") !== -1) {
        globalState.btPromptType = "";
        // AlreadyExists: mark as paired and connect directly
        if (line.indexOf("AlreadyExists") !== -1 && globalState.btPendingMac) {
            var alreadyMac = globalState.btPendingMac;
            console.log("[BT] pair failed with AlreadyExists — it was already paired, resyncing:", alreadyMac);
            setProp(alreadyMac, "paired", true);
            globalState.btPendingMac = "";
            btCtlProcess.write("connect " + alreadyMac + "\n");
        } else {
            globalState.btPendingMac = "";
        }
        return;
    }
    if (line.indexOf("Connection successful") !== -1) {
        globalState.btPendingMac = "";
        return;
    }
    if (line.indexOf("Failed to connect") !== -1) {
        globalState.btPendingMac = "";
        return;
    }

    // ── [NEW]/[CHG]/[DEL] Device MAC ... events (live scan) ──
    var m = line.match(/^\[(NEW|CHG|DEL)\]\s+Device\s+([0-9A-Fa-f:]{17})(?:\s+(.*))?$/);
    if (m) {
        console.log("[BT] matched Device event:", m[1], m[2], m[3] || "");
        var kind = m[1], mac = m[2], rest = (m[3] || "").trim();
        if (kind === "DEL") { removeDevice(mac); return; }
        if (kind === "NEW") { upsertDevice(mac, rest, false); return; }
        // CHG
        if      (rest.indexOf("Paired: yes")    === 0) setProp(mac, "paired", true);
        else if (rest.indexOf("Paired: no")     === 0) setProp(mac, "paired", false);
        else if (rest.indexOf("Connected: yes") === 0) {
            setProp(mac, "connected", true);
            globalState.btPendingMac = "";
            // Audio device connected: route EasyEffects to it
            btAudioRouteProcess.mac = mac;
            btAudioRouteProcess.running = false;
            btAudioRouteProcess.running = true;
        }
        else if (rest.indexOf("Connected: no")  === 0) {
            setProp(mac, "connected", false);
            // Disconnected: fall back to the ALSA sink
            btAudioRouteProcess.mac = "";
            btAudioRouteProcess.running = false;
            btAudioRouteProcess.running = true;
        }
        else if (rest.indexOf("Name: ")         === 0) setNameIfBetter(mac, rest.substring(6));
        else if (rest.indexOf("Alias: ")        === 0) setNameIfBetter(mac, rest.substring(7));
        return;
    }

    // ── "Device MAC Name" seed lines ──
    var m2 = line.match(/^Device\s+([0-9A-Fa-f:]{17})\s*(.*)$/);
    if (m2) {
        var mac2 = m2[1], name2 = (m2[2] || "").trim();
        // Seeded devices go straight to "saved"
        var seedPaired = btCtlProcess._seedingPaired || btCtlProcess._seedingConnected;
        var res = upsertDevice(mac2, name2, seedPaired);
        if (btCtlProcess._seedingPaired)    res.model.setProperty(res.index, "paired", true);
        if (btCtlProcess._seedingConnected) res.model.setProperty(res.index, "connected", true);
    }
}

stdout: SplitParser { onRead: (line) => btCtlProcess.handleLine(line) }
stderr: SplitParser { onRead: (line) => console.log("[BT] stderr:", line) }

onExited: (exitCode, exitStatus) => {
    console.log("[BT] proceso bluetoothctl TERMINÓ. exitCode =", exitCode, "exitStatus =", exitStatus,
                "(if this shows up while the view is still open, bluetoothctl died on its own and that's why no more devices arrive)");
}

onRunningChanged: {
    console.log("[BT] running =", running);
    if (running) {
        btPairedModel.clear();
        btAvailableModel.clear();
        globalState.btPromptType = "";
        globalState.btPendingMac = "";
        console.log("[BT] enviando: agent KeyboardOnly / default-agent / power on");
        write("agent KeyboardOnly\n");
        write("default-agent\n");
        write("power on\n");
        btSeedPairedTimer.restart();
    } else {
        globalState.btScanning = false;
        globalState.btPromptType = "";
        globalState.btPendingMac = "";
        _seedingPaired    = false;
        _seedingConnected = false;
    }
}
}


// Startup chain: paired → connected → live scan
Timer {
id: btSeedPairedTimer
interval: 300; repeat: false
onTriggered: {
    if (!btCtlProcess.running) { console.log("[BT] seedPaired: process not running, aborting"); return; }
    console.log("[BT] enviando: devices Paired");
    btCtlProcess._seedingPaired = true;
    btCtlProcess.write("devices Paired\n");
    btSeedConnectedTimer.restart();
}
}
Timer {
id: btSeedConnectedTimer
interval: 400; repeat: false
onTriggered: {
    if (!btCtlProcess.running) { console.log("[BT] seedConnected: process not running, aborting"); return; }
    console.log("[BT] enviando: devices Connected");
    btCtlProcess._seedingPaired    = false;
    btCtlProcess._seedingConnected = true;
    btCtlProcess.write("devices Connected\n");
    btSeedScanTimer.restart();
}
}
Timer {
id: btSeedScanTimer
interval: 400; repeat: false
onTriggered: {
    if (!btCtlProcess.running) { console.log("[BT] seedScan: process not running, aborting"); return; }
    console.log("[BT] enviando: scan on");
    btCtlProcess._seedingConnected = false;
    btCtlProcess.write("scan on\n");
    globalState.btScanning = true;
}
}
// Let "scan off" go out before killing the process
Timer {
id: btScanStopTimer
interval: 300; repeat: false
onTriggered: { console.log("[BT] deteniendo btCtlProcess (running = false)"); btCtlProcess.running = false; }
}

Timer {
interval: 3000; running: true; repeat: true
onTriggered: netProcess.running = true
}


    // ── Actions (public API) ──
function btSetEnabled(enabled) {
    console.log("[BT] btSetEnabled()", enabled);
    if (globalState.btRadioBusy) { console.log("[BT] btSetEnabled() ignored, a change is already in progress"); return; }
    // Instant feedback until the real confirmation arrives
    globalState.btPendingOn = enabled ? 1 : 0;
    globalState.btRadioBusy = true;
    netBluetoothRadioProcess.running  = false;
    netBluetoothRadioProcess.enabling = enabled;
    netBluetoothRadioProcess.running  = true;
    netBluetoothRadioWatchdog.restart();
}
function btConnectOrDisconnect(mac, isPaired, isConnected) {
    if (isConnected) {
        btCtlProcess.write("disconnect " + mac + "\n");
    } else if (isPaired) {
        globalState.btPendingMac = mac;
        btCtlProcess.write("connect " + mac + "\n");
    } else {
        globalState.btPendingMac = mac;
        btCtlProcess.write("pair " + mac + "\n");
    }
}
function btSubmitPrompt(text) {
    if (globalState.btPromptType === "confirm") {
        btCtlProcess.write("yes\n");
    } else {
        btCtlProcess.write(text + "\n");
    }
    globalState.btPromptType    = "";
    globalState.btPasswordDraft = "";
}
function btCancelPrompt() {
    if (globalState.btPromptType === "confirm") btCtlProcess.write("no\n");
    globalState.btPromptType    = "";
    globalState.btPasswordDraft = "";
}

// Toggles the wifi radio and waits for the real state
function wifiSetEnabled(enabled) {
    console.log("[WIFI] wifiSetEnabled()", enabled);
    // Don't restart a radio change already in progress
    if (globalState.wifiRadioBusy) { console.log("[WIFI] wifiSetEnabled() ignored, a change is already in progress"); return; }
    // Instant feedback until the real confirmation arrives
    globalState.wifiPendingOn = enabled ? 1 : 0;
    globalState.wifiRadioBusy = true;
    netWifiRadioProcess.running  = false;
    netWifiRadioProcess.enabling = enabled;
    netWifiRadioProcess.running  = true;
    netWifiRadioWatchdog.restart();
}
function wifiScanNetworks() {
    console.log("[WIFI] wifiScanNetworks() globalState.netWifiEnabled =", globalState.netWifiEnabled);
    if (!globalState.netWifiEnabled) { console.log("[WIFI] escaneo abortado: globalState.netWifiEnabled es false"); return; }
    globalState.wifiScanning = true;
    netWifiScanProcess.running = false;
    netWifiScanProcess.running = true;
}
function wifiConnect(ssid, password) {
    console.log("[WIFI] wifiConnect()", ssid, "pw?", password !== "");
    globalState.wifiConnectError   = "";
    globalState.wifiConnectingSsid = ssid;
    netWifiConnectProcess.running  = false;
    netWifiConnectProcess.ssid     = ssid;
    netWifiConnectProcess.password = password || "";
    netWifiConnectProcess.running  = true;
    console.log("[WIFI] netWifiConnectProcess.running =", netWifiConnectProcess.running, "command =", JSON.stringify(netWifiConnectProcess.command));
}
function wifiDisconnect(ssid) {
    console.log("[WIFI] wifiDisconnect()", ssid);
    globalState.wifiConnectingSsid = ssid;
    netWifiDisconnectProcess.running = false;
    netWifiDisconnectProcess.ssid    = ssid;
    netWifiDisconnectProcess.running = true;
}
function wifiForgetNetwork(ssid) {
    console.log("[WIFI] wifiForgetNetwork()", ssid);
    globalState.wifiConnectingSsid = ssid;
    netWifiForgetProcess.running = false;
    netWifiForgetProcess.ssid    = ssid;
    netWifiForgetProcess.running = true;
}

}
