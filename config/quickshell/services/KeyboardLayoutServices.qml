import QtQuick
import Quickshell
import Quickshell.Io

// Keyboard layouts (XKB list, current layout, apply)
WallpaperApplyServices {
    property var    kbLayouts: []
    property bool   kbLayoutsLoaded: false
    property bool   kbLayoutsLoading: false
    property string kbCurLayout: ""
    property string kbCurVariant: ""
    property string kbActiveKeymap: ""
    property bool   kbSavedFile: false
    property var    kbHyprBinds: []
    property string kbBindsError: ""
    property string kbBindsPath: ""
    property bool   kbBindsLoading: false
    property bool   kbApplying: false

    function kbRefresh(withLayouts) {
        if (!kbCurrentProc.running) kbCurrentProc.running = true;
        if (!kbBindsProc.running) { kbBindsLoading = true; kbBindsProc.running = true; }
        if (withLayouts && !kbLayoutsLoaded && !kbLayoutsProc.running) { kbLayoutsLoading = true; kbLayoutsProc.running = true; }
    }

    function kbFindLayout(code) {
        for (var i = 0; i < kbLayouts.length; i++) if (kbLayouts[i].n === code) return kbLayouts[i];
        return null;
    }

    function kbShortVariant(layoutDesc, variantDesc) {
        var base = (layoutDesc || "").replace(/\)\s*$/, "");
        var vd = variantDesc || "";
        if (base !== "" && vd.indexOf(base) === 0) {
            var rest = vd.slice(base.length).replace(/^[\s,(]+/, "").replace(/\)\s*$/, "");
            if (rest !== "") return rest;
        }
        return vd;
    }

    function kbVariantDesc(code, variant) {
        if (!variant) return tr("kb_default_variant");
        var L = kbFindLayout(code);
        if (L) for (var i = 0; i < L.v.length; i++) if (L.v[i].n === variant) return kbShortVariant(L.d, L.v[i].d);
        return variant;
    }

    function kbLayoutDesc(code) {
        var L = kbFindLayout(code);
        return L ? L.d : code;
    }

    function kbApplyLayout(layout, variant) {
        var ok = /^[A-Za-z0-9_.+-]+$/;
        if (!ok.test(layout || "")) return;
        if (variant && !ok.test(variant)) return;
        kbApplying = true;
        kbApplyProc.queue(layout, variant || "");
        kbCurLayout = layout;
        kbCurVariant = variant || "";
    }

    Process {
        id: kbLayoutsProc
        running: false
        command: ["python3", "-c", 
            "import json, os, sys\n" +
            "import xml.etree.ElementTree as ET\n" +
            "out = []\n" +
            "src = None\n" +
            "for p in (\"/usr/share/X11/xkb/rules/evdev.xml\", \"/usr/share/X11/xkb/rules/base.xml\"):\n" +
            "    if os.path.exists(p):\n" +
            "        src = p\n" +
            "        break\n" +
            "if src:\n" +
            "    try:\n" +
            "        root = ET.parse(src).getroot()\n" +
            "        for lay in root.iter(\"layout\"):\n" +
            "            ci = lay.find(\"configItem\")\n" +
            "            if ci is None:\n" +
            "                continue\n" +
            "            name = (ci.findtext(\"name\") or \"\").strip()\n" +
            "            if not name:\n" +
            "                continue\n" +
            "            desc = (ci.findtext(\"description\") or name).strip()\n" +
            "            langs = [l.text.strip() for l in ci.iter(\"iso639Id\") if l.text]\n" +
            "            vs = []\n" +
            "            vl = lay.find(\"variantList\")\n" +
            "            if vl is not None:\n" +
            "                for v in vl.findall(\"variant\"):\n" +
            "                    vci = v.find(\"configItem\")\n" +
            "                    if vci is None:\n" +
            "                        continue\n" +
            "                    vn = (vci.findtext(\"name\") or \"\").strip()\n" +
            "                    if vn:\n" +
            "                        vs.append({\"n\": vn, \"d\": (vci.findtext(\"description\") or vn).strip()})\n" +
            "            out.append({\"n\": name, \"d\": desc, \"l\": langs, \"v\": vs})\n" +
            "    except Exception:\n" +
            "        out = []\n" +
            "if not out:\n" +
            "    lst = \"/usr/share/X11/xkb/rules/evdev.lst\"\n" +
            "    try:\n" +
            "        sec = \"\"; idx = {}\n" +
            "        for line in open(lst, encoding=\"utf-8\"):\n" +
            "            line = line.rstrip(\"\\n\")\n" +
            "            if line.startswith(\"!\"):\n" +
            "                sec = line[1:].strip(); continue\n" +
            "            if not line.strip():\n" +
            "                continue\n" +
            "            parts = line.strip().split(None, 1)\n" +
            "            if sec == \"layout\" and len(parts) == 2:\n" +
            "                idx[parts[0]] = {\"n\": parts[0], \"d\": parts[1], \"l\": [], \"v\": []}\n" +
            "                out.append(idx[parts[0]])\n" +
            "            elif sec == \"variant\" and len(parts) == 2 and \":\" in parts[1]:\n" +
            "                lay, d = parts[1].split(\":\", 1)\n" +
            "                if lay.strip() in idx:\n" +
            "                    idx[lay.strip()][\"v\"].append({\"n\": parts[0], \"d\": d.strip()})\n" +
            "    except Exception:\n" +
            "        pass\n" +
            "seen = set(); uniq = []\n" +
            "for o in out:\n" +
            "    if o[\"n\"] in seen:\n" +
            "        continue\n" +
            "    seen.add(o[\"n\"]); uniq.append(o)\n" +
            "uniq.sort(key=lambda o: o[\"d\"].lower())\n" +
            "print(json.dumps(uniq, ensure_ascii=False, separators=(\",\", \":\")))\n"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var arr = JSON.parse(this.text);
                    if (Array.isArray(arr) && arr.length) { kbLayouts = arr; kbLayoutsLoaded = true; }
                } catch (e) { console.warn("kbLayoutsProc: invalid JSON", e); }
                kbLayoutsLoading = false;
            }
        }
        onRunningChanged: if (!running) kbLayoutsLoading = false
    }

    Process {
        id: kbCurrentProc
        running: false
        command: ["python3", "-c", 
            "import json, os, re, subprocess\n" +
            "r = {\"layout\": \"\", \"variant\": \"\", \"keymap\": \"\", \"saved\": False, \"savedLayout\": \"\", \"savedVariant\": \"\"}\n" +
            "try:\n" +
            "    d = json.loads(subprocess.run([\"hyprctl\", \"devices\", \"-j\"], capture_output=True, text=True, timeout=2).stdout)\n" +
            "    ks = d.get(\"keyboards\", [])\n" +
            "    k = next((x for x in ks if x.get(\"main\")), ks[0] if ks else None)\n" +
            "    if k:\n" +
            "        r[\"layout\"] = k.get(\"layout\", \"\") or \"\"\n" +
            "        r[\"variant\"] = k.get(\"variant\", \"\") or \"\"\n" +
            "        r[\"keymap\"] = k.get(\"active_keymap\", \"\") or \"\"\n" +
            "except Exception:\n" +
            "    pass\n" +
            "try:\n" +
            "    t = open(os.path.expanduser(\"~/.config/hypr/keyboard.lua\"), encoding=\"utf-8\").read()\n" +
            "    m = re.search(r'layout\\s*=\\s*[\"\\']([^\"\\']*)', t)\n" +
            "    v = re.search(r'variant\\s*=\\s*[\"\\']([^\"\\']*)', t)\n" +
            "    r[\"saved\"] = True\n" +
            "    r[\"savedLayout\"] = m.group(1) if m else \"\"\n" +
            "    r[\"savedVariant\"] = v.group(1) if v else \"\"\n" +
            "except Exception:\n" +
            "    pass\n" +
            "if not r[\"layout\"]:\n" +
            "    r[\"layout\"] = r[\"savedLayout\"] or \"us\"\n" +
            "    r[\"variant\"] = r[\"savedVariant\"]\n" +
            "print(json.dumps(r, ensure_ascii=False))\n"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var r = JSON.parse(this.text);
                    kbCurLayout = (r.layout || "us").split(",")[0];
                    kbCurVariant = (r.variant || "").split(",")[0];
                    kbActiveKeymap = r.keymap || "";
                    kbSavedFile = !!r.saved;
                } catch (e) { console.warn("kbCurrentProc: invalid JSON", e); }
            }
        }
    }

    Process {
        id: kbApplyProc
        running: false
        stdinEnabled: true
        property bool   _busy: false
        property string _pending: ""
        function queue(layout, variant) {
            var payload = layout + " " + (variant === "" ? "-" : variant);
            if (kbApplyProc._busy) { kbApplyProc._pending = payload; return; }
            kbApplyProc._run(payload);
        }
        function _run(payload) {
            kbApplyProc._busy = true;
            kbApplyProc.running = true;
            kbApplyProc.write(payload + "\n");
            kbApplyProc.stdinEnabled = false;
        }
        command: ["bash", "-c",
          "read -r L V\n" +
          "[ \"$V\" = \"-\" ] && V=\"\"\n" +
          "hyprctl eval \"hl.config({ input = { kb_layout = '${L}', kb_variant = '${V}' } })\" >/dev/null 2>&1\n" +
          "hyprctl keyword input:kb_variant \"\" >/dev/null 2>&1\n" +
          "hyprctl keyword input:kb_layout \"$L\" >/dev/null 2>&1\n" +
          "hyprctl keyword input:kb_variant \"$V\" >/dev/null 2>&1\n" +
          "mkdir -p \"$HOME/.config/hypr\"\n" +
          "cat > \"$HOME/.config/hypr/keyboard.lua\" <<LUAEOF\n" +
          "-- Generated automatically by Quickshell (Settings > Keyboard).\n" +
          "-- Overwritten when another layout is picked from the shell.\n" +
          "-- hyprland.lua loads it with dofile() at startup (see keyboard_ok).\n" +
          "return {\n" +
          "    layout  = '${L}',\n" +
          "    variant = '${V}',\n" +
          "}\n" +
          "LUAEOF\n"
        ]
        onRunningChanged: {
            if (!running) {
                kbApplyProc._busy = false;
                kbApplyProc.stdinEnabled = true;
                if (kbApplyProc._pending !== "") {
                    var p = kbApplyProc._pending;
                    kbApplyProc._pending = "";
                    kbApplyProc._run(p);
                } else {
                    kbApplying = false;
                    kbConfirmTimer.restart();
                }
            }
        }
    }

    Timer { id: kbConfirmTimer; interval: 450; repeat: false; onTriggered: if (!kbCurrentProc.running) kbCurrentProc.running = true }
}
