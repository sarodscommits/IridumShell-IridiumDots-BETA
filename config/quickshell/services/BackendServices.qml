import QtQuick
import Quickshell
import Quickshell.Io
import QtQml.Models
import ".."

// Backend instances: weather, terminal, network, color extraction
PrivacyServices {
    id: backendServices
    property alias btAvailableModel: btAvailableModel
    property alias btPairedModel: btPairedModel
    property alias colorExtraction: colorExtraction
    property alias networkBackend: networkBackend
    property alias terminalLauncher: terminalLauncher
    property alias weatherBackend: weatherBackend
    property alias wifiNetworksModel: wifiNetworksModel

    WeatherBackend {
        id: weatherBackend
        onWeatherUpdated: (fields) => {
            if (fields.CITY     !== undefined) globalState.weatherCity     = fields.CITY;
            if (fields.TEMP     !== undefined) globalState.weatherTemp     = fields.TEMP;
            if (fields.FEEL     !== undefined) globalState.weatherFeel     = fields.FEEL;
            if (fields.DESC     !== undefined) globalState.weatherDesc     = fields.DESC;
            if (fields.HUMIDITY !== undefined) globalState.weatherHumidity = fields.HUMIDITY;
            if (fields.WIND     !== undefined) globalState.weatherWind     = fields.WIND;
            if (fields.MAX      !== undefined) globalState.weatherMax      = fields.MAX;
            if (fields.MIN      !== undefined) globalState.weatherMin      = fields.MIN;

            var fc = [];
            for (var i = 0; i < 3; i++) {
                var dateKey = "FDATE" + i;
                if (fields[dateKey] === undefined) continue;
                fc.push({
                    date: fields[dateKey],
                    max:  fields["FMAX"  + i] !== undefined ? fields["FMAX"  + i] : "",
                    min:  fields["FMIN"  + i] !== undefined ? fields["FMIN"  + i] : "",
                    desc: fields["FDESC" + i] !== undefined ? fields["FDESC" + i] : ""
                });
            }
            if (fc.length > 0) globalState.weatherForecast = fc;
        }
    }

    TerminalLauncher {
        id: terminalLauncher
    }

    ListModel { id: wifiNetworksModel }
    ListModel { id: btPairedModel }
    ListModel { id: btAvailableModel }

    NetworkBackend {
        id: networkBackend
        globalState: backendServices.globalState
        wifiNetworksModel: wifiNetworksModel
        btPairedModel: btPairedModel
        btAvailableModel: btAvailableModel
        onBtPromptNeedsFocus: btPromptFocusTimer.restart()
    }

    Process {
        id: btConnectedProbe
        running: false
        property string _buf: ""
        command: ["bash", "-c",
        "command -v bluetoothctl >/dev/null 2>&1 || exit 0\n" +
        "out=$(timeout 3 bluetoothctl devices Connected 2>/dev/null)\n" +
        "if [ $? -eq 0 ] && ! printf '%s' \"$out\" | grep -qiE 'invalid|too many|usage'; then\n" +
        "  printf '%s\\n' \"$out\" | sed -n 's/^Device [0-9A-Fa-f:]\\{17\\} //p'\n" +
        "else\n" +
        "  for mac in $(timeout 3 bluetoothctl devices 2>/dev/null | awk '/^Device/{print $2}'); do\n" +
        "    info=$(timeout 2 bluetoothctl info \"$mac\" 2>/dev/null)\n" +
        "    printf '%s' \"$info\" | grep -q 'Connected: yes' && printf '%s\\n' \"$info\" | sed -n 's/^[[:space:]]*Alias: //p' | head -n1\n" +
        "  done\n" +
        "fi\n"]
        stdout: SplitParser { onRead: (line) => { btConnectedProbe._buf += line + "\n"; } }
        onRunningChanged: {
            if (running) { _buf = ""; return; }
            var names = _buf.split("\n").map(function (l) { return l.trim(); }).filter(function (l) { return l !== ""; });
            _buf = "";
            if (JSON.stringify(names) !== JSON.stringify(globalState.btConnectedNames)) globalState.btConnectedNames = names;
        }
    }

    Timer {
        interval: 4000; repeat: true; triggeredOnStart: true
        running: globalState.notchControlOpen && globalState.notchControlPage === 0 && globalState.netBluetoothEnabled
        && (!globalState.ccFloat || ccFloatWindow.prog > 0.99)
        onTriggered: if (!btConnectedProbe.running) btConnectedProbe.running = true
    }

    Connections {
        target: globalState
        function onNetBluetoothEnabledChanged() {
            if (!globalState.netBluetoothEnabled) globalState.btConnectedNames = [];
            else if (!btConnectedProbe.running) btConnectedProbe.running = true;
        }
    }

    ColorExtraction {
        id: colorExtraction
        onColorsLoaded: (colors) => applyMatugenColors(colors)
    }

    readonly property var matugenRoleMap: [
        ["primary", "matPrimary"],
        ["on_primary", "matOnPrimary"],
        ["primary_container", "matPrimaryContainer"],
        ["secondary", "matSecondary"],
        ["on_secondary", "matOnSecondary"],
        ["secondary_container", "matSecondaryContainer"],
        ["tertiary", "matTertiary"],
        ["on_tertiary", "matOnTertiary"],
        ["tertiary_container", "matTertiaryContainer"],
        ["on_primary_container", "matOnPrimaryContainer"],
        ["on_secondary_container", "matOnSecondaryContainer"],
        ["on_tertiary_container", "matOnTertiaryContainer"],
        ["error_container", "matErrorContainer"],
        ["on_error_container", "matOnErrorContainer"],
        ["error", "matError"],
        ["on_error", "matOnError"],
        ["background", "matBackground"],
        ["on_background", "matOnBackground"],
        ["surface", "matSurface"],
        ["on_surface", "matOnSurface"],
        ["surface_variant", "matSurfaceVariant"],
        ["on_surface_variant", "matOnSurfaceVariant"],
        ["surface_container", "matSurfaceContainer"],
        ["surface_container_lowest", "matSurfaceContainerLowest"],
        ["surface_container_low", "matSurfaceContainerLow"],
        ["surface_container_high", "matSurfaceContainerHigh"],
        ["surface_container_highest", "matSurfaceContainerHighest"],
        ["outline", "matOutline"],
        ["outline_variant", "matOutlineVariant"],
        ["inverse_surface", "matInverseSurface"],
        ["inverse_on_surface", "matInverseOnSurface"],
        ["inverse_primary", "matInversePrimary"]
    ]
    function _matVariantColor(r, order) {
        if (!r) return "";
        for (var i = 0; i < order.length; i++) {
            var variant = r[order[i]];
            if (variant) return (typeof variant.color === "string") ? variant.color : "";
        }
        return "";
    }
    function _setMatColor(colors, role, prop, order) {
        var v = _matVariantColor(colors[role], order);
        if (v) globalState[prop] = v;
    }
    function applyMatugenColors(colors) {
        var mode = globalState.colorMode === "light" ? "light" : "dark";
        _setMatColor(colors, "primary", "matDarkPrimary", ["dark", "default", "light"]);
        _setMatColor(colors, "on_surface", "matDarkOnSurface", ["dark", "default", "light"]);
        matugenRoleMap.forEach(function (r) { _setMatColor(colors, r[0], r[1], [mode, "dark", "light", "default"]); });
        globalState.walLoaded = true;
    }
}
