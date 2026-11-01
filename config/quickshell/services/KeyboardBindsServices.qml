import QtQuick
import Quickshell
import Quickshell.Io

// Keyboard shortcuts from hyprland.lua and the infinite desktop
KeyboardLayoutServices {
    property alias kbBindsProc: kbBindsProc

    readonly property var kbInfiniteBinds: [
        { keys: ["SUPER", "ALT", "mouse:move"], act: "kbinf_pan" },
        { keys: ["SUPER", "ALT"],               act: "kbinf_hold", hold: true },
        { keys: ["SUPER", "mouse:wheel"],       act: "kbinf_zoom" },
        { keys: ["SUPER", "mouse:272"],         act: "kbinf_drag",   coop: true },
        { keys: ["SUPER", "mouse:273"],         act: "kbinf_resize", coop: true }
    ]

    function kbNormKey(k) {
        var u = (k || "").trim();
        var up = u.toUpperCase();
        if (up === "WIN" || up === "META" || up === "MOD4" || up === "LOGO") return "SUPER";
        if (up === "CONTROL") return "CTRL";
        if (up === "ENTER" || up === "RETURN") return "RETURN";
        if (up === "ESC") return "ESCAPE";
        if (u.indexOf("mouse") === 0) return u.toLowerCase();
        return up;
    }

    function kbNormKeys(keys) {
        var order = { SUPER: 0, CTRL: 1, ALT: 2, SHIFT: 3 };
        var mods = [], rest = [];
        for (var i = 0; i < keys.length; i++) {
            var k = kbNormKey(keys[i]);
            if (order[k] !== undefined) mods.push(k); else rest.push(k);
        }
        mods.sort(function (a, b) { return order[a] - order[b]; });
        return mods.concat(rest);
    }

    function kbKeyCap(k) {
        switch (k) {
        case "SUPER":  return { t: "Super", i: "" };
        case "CTRL":   return { t: "Ctrl",  i: "" };
        case "ALT":    return { t: "Alt",   i: "" };
        case "SHIFT":  return { t: "Shift", i: "" };
        case "LEFT":   return { t: "", i: "arrow_back" };
        case "RIGHT":  return { t: "", i: "arrow_forward" };
        case "UP":     return { t: "", i: "arrow_upward" };
        case "DOWN":   return { t: "", i: "arrow_downward" };
        case "SPACE":  return { t: tr("kb_key_space"), i: "" };
        case "TAB":    return { t: "Tab", i: "" };
        case "ESCAPE": return { t: "Esc", i: "" };
        case "RETURN": return { t: "Enter", i: "" };
        case "mouse:272":   return { t: tr("kb_key_lmb"),   i: "mouse" };
        case "mouse:273":   return { t: tr("kb_key_rmb"),   i: "mouse" };
        case "mouse:274":   return { t: tr("kb_key_mmb"),   i: "mouse" };
        case "mouse:move":  return { t: tr("kb_key_move"),  i: "open_with" };
        case "mouse:wheel": return { t: tr("kb_key_wheel"), i: "unfold_more" };
        case "mouse_down":  return { t: tr("kb_key_wheel"), i: "arrow_downward" };
        case "mouse_up":    return { t: tr("kb_key_wheel"), i: "arrow_upward" };
        }
        if (k.length === 1) return { t: k, i: "" };
        return { t: k.charAt(0) + k.slice(1).toLowerCase(), i: "" };
    }

    function kbWsLabel(a) {
        var s = String(a).replace(/["']/g, "");
        if (s === "-1" || s === "e-1" || s === "r-1") return tr("kb_ws_prev");
        if (s === "+1" || s === "e+1" || s === "r+1") return tr("kb_ws_next");
        return s;
    }

    function kbDescribeExec(cmd) {
        var m = /(navigate_windows|move_window_tiled|move_window|resize_window)\.py\s+(left|right|up|down)/.exec(cmd);
        if (m) return tr("kb_x_" + m[1]).arg(tr("kb_dir_" + m[2]));
        if (/floating_tile_toggle\.py/.test(cmd)) return tr("kb_x_floating_tile_toggle");
        var term = /^\s*(kitty|alacritty|foot|wezterm|ghostty)\b/.exec(cmd);
        if (term) return tr("kb_d_terminal").arg(term[1]);
        if (/\bgrim\b/.test(cmd)) return tr("kb_d_screenshot");
        return tr("kb_d_run").arg(cmd);
    }

    function kbDescribe(b) {
        if (b.act) return tr(b.act);
        if (b.id && i18n.has("kbact_" + b.id)) return tr("kbact_" + b.id);
        if (b.desc) return b.desc;
        switch (b.kind) {
        case "global":   return i18n.has("kbg_" + b.arg) ? tr("kbg_" + b.arg) : "Quickshell · " + b.arg;
        case "focus_ws": return tr("kb_d_focus_ws").arg(kbWsLabel(b.arg));
        case "move_ws":  return (b.extra && b.extra.follow === "false" ? tr("kb_d_move_ws_silent") : tr("kb_d_move_ws")).arg(kbWsLabel(b.arg));
        case "close":    return tr("kb_d_close");
        case "float":    return tr("kb_d_float");
        case "drag":     return tr("kb_d_drag");
        case "resize":   return tr("kb_d_resize");
        case "submap":   return b.arg === "reset" ? tr("kb_d_submap_exit") : tr("kb_d_submap").arg(b.arg);
        case "exec":     return kbDescribeExec(b.arg);
        }
        return b.dsp || b.kind;
    }

    function kbCategory(b) {
        if (b.src === "infinite") return "infinite";
        if (b.submap !== "" || b.kind === "submap") return "submap";
        if (b.kind === "focus_ws" || b.kind === "move_ws") return "workspaces";
        if (["close", "float", "drag", "resize"].indexOf(b.kind) >= 0) return "windows";
        if (b.kind === "exec" && /(navigate_windows|move_window_tiled|move_window|resize_window|floating_tile_toggle)\.py/.test(b.arg)) return "windows";
        return "shell";
    }

    readonly property var kbCategoryDefs: [
        { key: "windows",    icon: "web_asset" },
        { key: "workspaces", icon: "view_carousel" },
        { key: "shell",      icon: "apps" },
        { key: "submap",     icon: "layers" },
        { key: "infinite",   icon: "open_with" }
    ]

    function kbCategoryTitle(k) {
        if (k === "submap") {
            var names = [];
            for (var i = 0; i < kbHyprBinds.length; i++) {
                var s = kbHyprBinds[i].submap || (kbHyprBinds[i].kind === "submap" && kbHyprBinds[i].arg !== "reset" ? kbHyprBinds[i].arg : "");
                if (s && names.indexOf(s) < 0) names.push(s);
            }
            return tr("kb_cat_submap").arg(names.join(", "));
        }
        return tr("kb_cat_" + k);
    }

    function kbAllBinds() {
        var all = [], i, b;
        for (i = 0; i < kbHyprBinds.length; i++) {
            b = kbHyprBinds[i];
            all.push({ src: "hypr", keys: kbNormKeys(b.keys), submap: b.submap || "", kind: b.kind, arg: b.arg, extra: b.extra,
                       dsp: b.dsp, id: b.id, desc: b.desc, repeat: b.repeat, mouse: b.mouse, line: b.line, act: "", hold: false, coop: false });
        }
        for (i = 0; i < kbInfiniteBinds.length; i++) {
            b = kbInfiniteBinds[i];
            all.push({ src: "infinite", keys: kbNormKeys(b.keys), submap: "", kind: "infinite", arg: "", extra: {},
                       dsp: "", id: "", desc: "", repeat: false, mouse: b.keys.join(" ").indexOf("mouse") >= 0, line: 0,
                       act: b.act, hold: !!b.hold, coop: !!b.coop });
        }
        var count = {};
        for (i = 0; i < all.length; i++) {
            if (all[i].coop) continue;
            var key = all[i].submap + "|" + all[i].keys.join("+");
            count[key] = (count[key] || 0) + 1;
        }
        for (i = 0; i < all.length; i++) {
            all[i].conflict = !all[i].coop && count[all[i].submap + "|" + all[i].keys.join("+")] > 1;
            all[i].label = kbDescribe(all[i]);
            all[i].cat = kbCategory(all[i]);
            all[i].caps = all[i].keys.map(function (k) {
                var c = kbKeyCap(k);
                return { t: c.t, i: c.i, m: ["SUPER", "CTRL", "ALT", "SHIFT"].indexOf(k) >= 0 };
            });
        }
        return all;
    }

    function kbBuildGroups(all, query, cat) {
        var q = (query || "").trim().toLowerCase();
        var out = [];
        for (var c = 0; c < kbCategoryDefs.length; c++) {
            var def = kbCategoryDefs[c];
            if (cat !== "all" && cat !== def.key) continue;
            var items = [];
            for (var i = 0; i < all.length; i++) {
                var b = all[i];
                if (b.cat !== def.key) continue;
                if (q !== "") {
                    var caps = b.keys.map(function (k) { var kc = kbKeyCap(k); return (kc.t + " " + k).toLowerCase(); }).join(" ");
                    var hay = (b.label + " " + caps + " " + b.keys.join("+") + " " + (b.id || "") + " " + (b.arg || "")).toLowerCase();
                    if (hay.indexOf(q) < 0) continue;
                }
                items.push(b);
            }
            if (items.length) out.push({ key: def.key, icon: def.icon, title: kbCategoryTitle(def.key), items: items });
        }
        return out;
    }

    Process {
        id: kbBindsProc
        running: false
        command: ["python3", "-c", 
            "import json, os, re, sys\n" +
            "path = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser(\"~/.config/hypr/hyprland.lua\")\n" +
            "try:\n" +
            "    src = open(path, encoding=\"utf-8\").read().split(\"\\n\")\n" +
            "except Exception as e:\n" +
            "    print(json.dumps({\"ok\": False, \"error\": str(e), \"binds\": []})); sys.exit(0)\n" +
            "\n" +
            "def split_top(s):\n" +
            "    parts, depth, cur, q, i = [], 0, \"\", None, 0\n" +
            "    while i < len(s):\n" +
            "        c = s[i]\n" +
            "        if q:\n" +
            "            cur += c\n" +
            "            if c == \"\\\\\" and i + 1 < len(s):\n" +
            "                cur += s[i + 1]; i += 2; continue\n" +
            "            if c == q:\n" +
            "                q = None\n" +
            "        elif c in \"\\\"'\":\n" +
            "            q = c; cur += c\n" +
            "        elif c in \"({[\":\n" +
            "            depth += 1; cur += c\n" +
            "        elif c in \")}]\":\n" +
            "            depth -= 1; cur += c\n" +
            "        elif c == \",\" and depth == 0:\n" +
            "            parts.append(cur.strip()); cur = \"\"\n" +
            "        else:\n" +
            "            cur += c\n" +
            "        i += 1\n" +
            "    if cur.strip():\n" +
            "        parts.append(cur.strip())\n" +
            "    return parts\n" +
            "\n" +
            "def call_body(line, start):\n" +
            "    depth, q, i = 0, None, start\n" +
            "    while i < len(line):\n" +
            "        c = line[i]\n" +
            "        if q:\n" +
            "            if c == \"\\\\\":\n" +
            "                i += 2; continue\n" +
            "            if c == q:\n" +
            "                q = None\n" +
            "        elif c in \"\\\"'\":\n" +
            "            q = c\n" +
            "        elif c == \"(\":\n" +
            "            depth += 1\n" +
            "        elif c == \")\":\n" +
            "            depth -= 1\n" +
            "            if depth == 0:\n" +
            "                return line[start + 1:i], line[i + 1:]\n" +
            "        i += 1\n" +
            "    return None, None\n" +
            "\n" +
            "def unq(s):\n" +
            "    s = s.strip()\n" +
            "    if len(s) >= 2 and s[0] == s[-1] and s[0] in \"\\\"'\":\n" +
            "        return s[1:-1]\n" +
            "    return s\n" +
            "\n" +
            "vars_ = {}\n" +
            "for ln in src:\n" +
            "    m = re.match(r'\\s*local\\s+(\\w+)\\s*=\\s*(\"[^\"]*\"|\\'[^\\']*\\')\\s*(--.*)?$', ln)\n" +
            "    if m:\n" +
            "        vars_[m.group(1)] = unq(m.group(2))\n" +
            "\n" +
            "def resolve(expr):\n" +
            "    out = \"\"\n" +
            "    for tok in expr.split(\"..\"):\n" +
            "        tok = tok.strip()\n" +
            "        if tok[:1] in \"\\\"'\":\n" +
            "            out += unq(tok)\n" +
            "        elif tok in vars_:\n" +
            "            out += vars_[tok]\n" +
            "        else:\n" +
            "            return None\n" +
            "    return out\n" +
            "\n" +
            "def table(s):\n" +
            "    d = {}\n" +
            "    s = s.strip()\n" +
            "    if s.startswith(\"{\") and s.endswith(\"}\"):\n" +
            "        for p in split_top(s[1:-1]):\n" +
            "            if \"=\" in p:\n" +
            "                k, v = p.split(\"=\", 1)\n" +
            "                v = v.strip()\n" +
            "                d[k.strip()] = unq(v) if v[:1] in \"\\\"'\" else v\n" +
            "    return d\n" +
            "\n" +
            "def classify(dsp):\n" +
            "    m = re.match(r'hl\\.dsp\\.([\\w.]+)\\s*\\((.*)\\)\\s*$', dsp.strip(), re.S)\n" +
            "    if not m:\n" +
            "        return \"other\", dsp, {}\n" +
            "    fn, args = m.group(1), m.group(2).strip()\n" +
            "    a = split_top(args) if args else []\n" +
            "    first = a[0] if a else \"\"\n" +
            "    t = table(first) if first.startswith(\"{\") else {}\n" +
            "    if fn == \"global\":\n" +
            "        return \"global\", unq(first).split(\":\", 1)[-1], {}\n" +
            "    if fn == \"exec_cmd\":\n" +
            "        return \"exec\", unq(first), {}\n" +
            "    if fn == \"submap\":\n" +
            "        return \"submap\", unq(first), {}\n" +
            "    if fn == \"focus\" and \"workspace\" in t:\n" +
            "        return \"focus_ws\", t[\"workspace\"], {}\n" +
            "    if fn == \"window.move\" and \"workspace\" in t:\n" +
            "        return \"move_ws\", t[\"workspace\"], {\"follow\": t.get(\"follow\", \"true\")}\n" +
            "    if fn == \"window.float\":\n" +
            "        return \"float\", t.get(\"action\", \"toggle\"), {}\n" +
            "    if fn in (\"window.close\", \"window.drag\", \"window.resize\"):\n" +
            "        return fn.split(\".\")[1], \"\", {}\n" +
            "    return fn, args, {}\n" +
            "\n" +
            "binds, submap, line_no = [], \"\", 0\n" +
            "for i, ln in enumerate(src):\n" +
            "    s = ln.strip()\n" +
            "    if s.startswith(\"--\"):\n" +
            "        continue\n" +
            "    m = re.search(r'hl\\.define_submap\\(\\s*(\"[^\"]*\"|\\'[^\\']*\\')', ln)\n" +
            "    if m:\n" +
            "        submap = unq(m.group(1)); continue\n" +
            "    if submap and re.match(r'\\s*end\\s*\\)', ln):\n" +
            "        submap = \"\"; continue\n" +
            "    k = ln.find(\"hl.bind(\")\n" +
            "    if k < 0:\n" +
            "        continue\n" +
            "    body, rest = call_body(ln, k + len(\"hl.bind\"))\n" +
            "    if body is None:\n" +
            "        continue\n" +
            "    args = split_top(body)\n" +
            "    if len(args) < 2:\n" +
            "        continue\n" +
            "    combo = resolve(args[0])\n" +
            "    if combo is None:\n" +
            "        continue\n" +
            "    opts = table(args[2]) if len(args) > 2 else {}\n" +
            "    kind, arg, extra = classify(args[1])\n" +
            "    comment = \"\"\n" +
            "    cm = re.search(r'--\\s*(.*)$', rest or \"\")\n" +
            "    if cm:\n" +
            "        comment = cm.group(1).strip()\n" +
            "    kid = \"\"\n" +
            "    km = re.search(r'@kb:([\\w.-]+)', comment)\n" +
            "    if km:\n" +
            "        kid = km.group(1)\n" +
            "    keys = [p.strip() for p in combo.split(\"+\") if p.strip()]\n" +
            "    binds.append({\n" +
            "        \"line\": i + 1, \"combo\": combo, \"keys\": keys, \"submap\": submap,\n" +
            "        \"kind\": kind, \"arg\": arg, \"extra\": extra, \"dsp\": args[1],\n" +
            "        \"id\": kid, \"desc\": opts.get(\"description\", \"\"),\n" +
            "        \"repeat\": opts.get(\"repeating\") == \"true\", \"mouse\": opts.get(\"mouse\") == \"true\",\n" +
            "        \"locked\": opts.get(\"locked\") == \"true\",\n" +
            "    })\n" +
            "print(json.dumps({\"ok\": True, \"path\": path, \"binds\": binds}, ensure_ascii=False, separators=(\",\", \":\")))\n"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var r = JSON.parse(this.text);
                    kbBindsError = r.ok ? "" : (r.error || "?");
                    kbBindsPath = r.path || "";
                    kbHyprBinds = r.binds || [];
                } catch (e) { kbBindsError = String(e); }
                kbBindsLoading = false;
            }
        }
        onRunningChanged: if (!running) kbBindsLoading = false
    }
}
