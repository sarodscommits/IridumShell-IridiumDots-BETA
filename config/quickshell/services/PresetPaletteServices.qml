import QtQuick
import Quickshell
import Quickshell.Io

// Preset palette exports for kitty, terminal sequences and cava
KeyboardBindsServices {
    function hslToHex(h, s, l) {
        h = ((h % 360) + 360) % 360 / 360;
        s = Math.max(0, Math.min(1, s));
        l = Math.max(0, Math.min(1, l));
        function hue2rgb(p, q, t) {
            if (t < 0) t += 1;
            if (t > 1) t -= 1;
            if (t < 1/6) return p + (q - p) * 6 * t;
            if (t < 1/2) return q;
            if (t < 2/3) return p + (q - p) * (2/3 - t) * 6;
            return p;
        }
        var r, g, b;
        if (s === 0) { r = g = b = l; }
        else {
            var q = l < 0.5 ? l * (1 + s) : l + s - l * s;
            var p = 2 * l - q;
            r = hue2rgb(p, q, h + 1/3);
            g = hue2rgb(p, q, h);
            b = hue2rgb(p, q, h - 1/3);
        }
        function toHex(x) { var v = Math.round(x * 255).toString(16); return v.length === 1 ? "0" + v : v; }
        return "#" + toHex(r) + toHex(g) + toHex(b);
    }

    function presetKittyStops() {
        var seed = presetRoles._seed();
        var sat = Math.min(seed.sat, 0.55);
        var stops = [];
        for (var i = 0; i < 14; i++) {
            var l = 0.08 + (i / 13) * 0.84;
            stops.push(hslToHex(seed.hue, sat, l));
        }
        return stops;
    }

    function buildPresetKittyConf() {
        var stops = presetKittyStops();
        var light = globalState.colorMode === "light";
        var bg = light ? stops[13] : stops[0];
        var fg = light ? stops[0]  : stops[13];
        var lines = [];
        lines.push("background " + bg);
        lines.push("foreground " + fg);
        lines.push("cursor " + fg);
        lines.push("cursor_text_color " + bg);
        lines.push("selection_background " + stops[6]);
        lines.push("selection_foreground " + fg);
        lines.push("color0 "  + stops[0]);
        lines.push("color1 "  + stops[2]);
        lines.push("color2 "  + stops[3]);
        lines.push("color3 "  + stops[4]);
        lines.push("color4 "  + stops[5]);
        lines.push("color5 "  + stops[6]);
        lines.push("color6 "  + stops[7]);
        lines.push("color7 "  + stops[9]);
        lines.push("color8 "  + stops[1]);
        lines.push("color9 "  + stops[3]);
        lines.push("color10 " + stops[4]);
        lines.push("color11 " + stops[5]);
        lines.push("color12 " + stops[6]);
        lines.push("color13 " + stops[7]);
        lines.push("color14 " + stops[8]);
        lines.push("color15 " + stops[13]);
        return lines.join("\n") + "\n";
    }

    function buildPresetSequences() {
        var stops = presetKittyStops();
        var light = globalState.colorMode === "light";
        var bg = light ? stops[13] : stops[0];
        var fg = light ? stops[0]  : stops[13];
        var ESC = "\u001b";
        function osc(code, val) { return ESC + "]" + code + ";" + val + ESC + "\\"; }
        var lines = [];
        lines.push(osc("10", fg));
        lines.push(osc("11", bg));
        lines.push(osc("12", fg));
        var idx = [0,2,3,4,5,6,7,9,1,3,4,5,6,7,8,13];
        for (var i = 0; i < 16; i++) {
            lines.push(osc("4;" + i, stops[idx[i]]));
        }
        return lines.join("") + "\n";
    }

    function buildPresetCavaSed() {
        var stops = presetKittyStops();
        var c1 = stops[13];
        var c2 = stops[9];
        var c3 = stops[4];
        var c0 = stops[0];
        return (
        "if [ -f \"$HOME/.config/cava/config\" ]; then\n" +
        "  sed -i \"s/^gradient = .*/gradient = 1/\" \"$HOME/.config/cava/config\"\n" +
        "  sed -i \"s/^gradient_count = .*/gradient_count = 3/\" \"$HOME/.config/cava/config\"\n" +
        "  sed -i \"s/^gradient_color_1 = .*/gradient_color_1 = '" + c1 + "'/\" \"$HOME/.config/cava/config\"\n" +
        "  sed -i \"s/^gradient_color_2 = .*/gradient_color_2 = '" + c2 + "'/\" \"$HOME/.config/cava/config\"\n" +
        "  sed -i \"s/^gradient_color_3 = .*/gradient_color_3 = '" + c3 + "'/\" \"$HOME/.config/cava/config\"\n" +
        "  sed -i \"s/^background = .*/background = '" + c0 + "'/\" \"$HOME/.config/cava/config\"\n" +
        "  pkill -USR1 cava 2>/dev/null\n" +
        "fi\n"
        );
    }

    function applyPresetCavaColors() {
        wpScriptSaver._doSave("#!/bin/bash\n" + buildAccentSyncSnippet());
    }

    function applyPresetKittyColors() {
        if (globalState.paletteSource !== "preset") return;
        var script = "#!/bin/bash\n" +
        (globalState.presetApplyKitty ? buildPresetKittyApplyBash() : "") +
        buildAccentSyncSnippet();
        wpScriptSaver._doSave(script);
    }

    function buildPresetKittyApplyBash() {
        var conf = buildPresetKittyConf();
        var seq = buildPresetSequences();
        return (
        "LOG=\"$HOME/.cache/wal/kitty-preset-debug.log\"\n" +
        "mkdir -p \"$HOME/.cache/wal\"\n" +
        "{\n" +
        "  echo \"---- $(date) applyPresetKittyColors ----\"\n" +
        "  cat > \"$HOME/.cache/wal/colors-kitty.conf\" << 'IRIDUM_KITTY_EOF'\n" +
        conf +
        "IRIDUM_KITTY_EOF\n" +
        "  cat > \"$HOME/.cache/wal/sequences\" << 'IRIDUM_SEQ_EOF'\n" +
        seq +
        "IRIDUM_SEQ_EOF\n" +
        "  echo \"conf + sequences escritos, primeras lineas de conf:\"\n" +
        "  head -n 3 \"$HOME/.cache/wal/colors-kitty.conf\"\n" +
        "  FOUND=0\n" +
        "  for s in $XDG_RUNTIME_DIR/kitty-socket-quickshell*; do\n" +
        "    if [ -S \"$s\" ]; then\n" +
        "      FOUND=1\n" +
        "      echo \"aplicando a $s\"\n" +
        "      kitty @ --to \"unix:$s\" set-colors -a -c \"$HOME/.cache/wal/colors-kitty.conf\"\n" +
        "      echo \"  exit code: $?\"\n" +
        "    fi\n" +
        "  done\n" +
        "  if [ \"$FOUND\" = \"0\" ]; then\n" +
        "    echo \"NO SOCKET FOUND (pattern $XDG_RUNTIME_DIR/kitty-socket-quickshell*)\"\n" +
        "  fi\n" +
        "} >> \"$LOG\" 2>&1\n"
        );
    }
}
