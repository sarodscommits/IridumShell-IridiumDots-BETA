#!/usr/bin/env python3
"""
switcher_pan.py <address>

Usado por WindowSwitcher.qml al elegir una ventana. Toma la posicion
ORIGINAL de cada ventana flotante del workspace (la guardada por
peek_window.py en /tmp/qs_peek_state.json si estaba peekeada; si no, la
actual), calcula el desplazamiento que lleva la ventana elegida al centro
del monitor y mueve TODAS las ventanas con ese mismo desplazamiento, asi
se conserva la disposicion relativa (como paneo del escritorio infinito).
Despues borra el estado de peek y enfoca la ventana elegida.
"""
import sys, os, subprocess, traceback
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from hypr_ipc import (hyprctl_json, move_window_exact, desktop_lock,
                      _load_peek_state as load_state,
                      _save_peek_state as save_state)

LOG = "/tmp/qs_switcher_pan.log"

def log(m):
    try:
        with open(LOG, "a") as f: f.write(m + "\n")
    except Exception: pass

def main():
    chosen = sys.argv[1]
    with desktop_lock():
        clients = hyprctl_json(["clients"]) or []
        monitors = hyprctl_json(["monitors"]) or []
        target = next((c for c in clients if c.get("address", "").lower() == chosen.lower()), None)
        if not target or not monitors:
            log("sin target/monitores"); return
        ws = target.get("workspace", {}).get("id")
        mon = next((m for m in monitors if m.get("id") == target.get("monitor")), None) \
              or next((m for m in monitors if m.get("focused")), monitors[0])
        state = load_state()

        wins = [c for c in clients
                if c.get("floating") and c.get("workspace", {}).get("id") == ws and c.get("mapped", True)]

        def orig(c):
            s = state.get(c["address"])
            return (s["x"], s["y"]) if s else (c["at"][0], c["at"][1])

        if target.get("floating"):
            ox, oy = orig(target)
            cx = ox + target["size"][0] / 2
            cy = oy + target["size"][1] / 2
            dx = int(mon["x"] + mon["width"] / 2 - cx)
            dy = int(mon["y"] + mon["height"] / 2 - cy)
        else:
            dx = dy = 0
        log(f"chosen={chosen} ws={ws} d=({dx},{dy}) n={len(wins)}")

        for c in wins:
            x, y = orig(c)
            move_window_exact(int(x + dx), int(y + dy), c["address"])
            state.pop(c["address"], None)
        save_state(state)

    subprocess.run(["hyprctl", "eval", f'hl.dsp.window.focus("address:{chosen}")'],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

if __name__ == "__main__":
    try: main()
    except Exception: log(traceback.format_exc())