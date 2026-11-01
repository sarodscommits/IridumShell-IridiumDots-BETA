#!/usr/bin/env python3
# Display configuration for Settings > System.
#   display_ctl.py read            -> one JSON line: {"monitors": [...live...], "saved": [...]}
#   display_ctl.py apply '<json>'  -> writes ~/.config/hypr/monitors.lua (+ monitors.json
#                                     sidecar with the UI choices) and applies it live.
# Entry: {output, mode "WxH@R", position, scale, vrr, disabled, mirror, res_auto, rate_auto}
import json, os, subprocess, sys

HYPR = os.path.expanduser("~/.config/hypr")
LUA = os.path.join(HYPR, "monitors.lua")
SIDE = os.path.join(HYPR, "monitors.json")


def live():
    try:
        out = subprocess.run(["hyprctl", "monitors", "all", "-j"], capture_output=True, text=True, timeout=5).stdout
        return json.loads(out or "[]")
    except Exception:
        return []


def saved():
    try:
        with open(SIDE) as f:
            d = json.load(f)
        return d if isinstance(d, list) else []
    except Exception:
        return []


def lstr(s):
    return '"' + str(s).replace("\\", "\\\\").replace('"', '\\"') + '"'


def spec(e):
    """Lua table with only the fields hl.monitor() understands."""
    f = ["output = " + lstr(e["output"])]
    if e.get("disabled"):
        f.append("disabled = true")
    else:
        f.append("mode = " + lstr(e.get("mode") or "preferred"))
        f.append("position = " + lstr(e.get("position") or "auto"))
        sc = e.get("scale", 1)
        f.append("scale = " + (lstr(sc) if isinstance(sc, str) else repr(float(sc)).rstrip("0").rstrip(".")))
        f.append("vrr = " + str(int(e.get("vrr", 0))))
        if e.get("mirror"):
            f.append("mirror = " + lstr(e["mirror"]))
    return "{ " + ", ".join(f) + " }"


def write(entries):
    os.makedirs(HYPR, exist_ok=True)
    lines = [
        "-- Generated automatically by Quickshell (Settings > System > Displays).",
        "-- Don't edit by hand: it's overwritten every time you change the",
        "-- resolution, refresh rate, scale, position or VRR from the shell.",
        "-- hyprland.lua loads it with dofile() at startup (see monitors_ok in",
        "-- hyprland.lua); monitors that aren't listed here are auto-detected.",
        "return {",
    ]
    for e in entries:
        lines.append("    " + spec(e) + ",")
    lines.append("}")
    tmp = LUA + ".tmp"
    with open(tmp, "w") as f:
        f.write("\n".join(lines) + "\n")
    os.replace(tmp, LUA)
    with open(SIDE + ".tmp", "w") as f:
        json.dump(entries, f, indent=2)
    os.replace(SIDE + ".tmp", SIDE)


def apply(entries):
    keep = {e["output"] for e in entries}
    merged = entries + [s for s in saved() if s.get("output") not in keep]
    write(merged)
    ok = True
    # Enabled monitors first so there's never a moment with every output off.
    for e in sorted(entries, key=lambda e: bool(e.get("disabled"))):
        r = subprocess.run(["hyprctl", "eval", "hl.monitor(" + spec(e) + ")"], capture_output=True, text=True, timeout=10)
        if r.returncode != 0 or r.stdout.strip().lower() not in ("", "ok"):
            ok = False
            print("ERRMSG:" + e["output"] + ": " + (r.stdout + r.stderr).strip().replace("\n", " "))
    print("APPLY:" + ("ok" if ok else "err"))


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "read"
    if cmd == "read":
        print(json.dumps({"monitors": live(), "saved": saved()}))
    elif cmd == "apply" and len(sys.argv) > 2:
        try:
            data = json.loads(sys.argv[2])
            apply([e for e in data if isinstance(e, dict) and e.get("output")])
        except Exception as ex:
            print("ERRMSG:" + str(ex))
            print("APPLY:err")
