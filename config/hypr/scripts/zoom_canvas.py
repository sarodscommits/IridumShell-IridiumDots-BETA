#!/usr/bin/env python3
"""
zoom_canvas.py  (v3 — zoom por ESCALA DE MONITOR, pasos finos)
Zoom real del escritorio infinito, sin plugins ni Quickshell.

COMO FUNCIONA
-------------
Cambiar la escala del monitor es zoom de render real de Hyprland: escala 0.5
en 1920x1080 = escritorio logico de 3840x2160, todo a la mitad e interactivo.

Las coordenadas LOGICAS de las ventanas no cambian al cambiar la escala, asi
que se panea todo el canvas para anclar el zoom al cursor:

    P  = posicion FISICA del cursor dentro del monitor
    Δ  = P * (1/s_nuevo - 1/s_viejo)       (en coords logicas)

Por cada paso, en UN solo batch de hyprctl:
    escala nueva -> paneo de ventanas -> cursor al mismo punto fisico
    -> tamano del cursor = base / escala (para que no se vea afectado)

NIVELES
-------
Una escala es valida si:
  - es multiplo de 1/120 (el protocolo de escala fraccional de Wayland solo
    transmite escalas en pasos de 1/120), y
  - ancho/s y alto/s son enteros (Hyprland exige tamano logico entero).
Se calculan todas las que cumplen entre ZOOM_MIN y ZOOM_MAX. Para 1920x1080
son 26 (0.25, 0.267, 0.3, 0.333, 0.375, 0.4, 0.417, 0.5 ... 2, 2.4, 2.5).

RITMO
-----
Como mucho un cambio de escala cada MIN_INTERVAL. Scroll lento = un nivel
por click (pasos finos); scroll rapido = los clicks acumulados en ese
intervalo se aplican en un solo salto (misma velocidad, carga acotada).
La animacion windowsMove se apaga una vez por rafaga y se restaura al final.

BARRAS (Quickshell)
-------------------
Tras cada paso se llama `qs ipc call zoom setScale <escala>` para que el
shell contra-escale sus barras (ver el snippet QML que acompana este script).
Si Quickshell no tiene ese IpcHandler, la llamada falla en silencio.

USO
---
- Desde infinite_desktop_core.py (Super + rueda):  CanvasZoom().add_steps(n)
- CLI:  python3 zoom_canvas.py [--debug] in | out | reset | get | levels | +N | -N

LIMITACIONES CONOCIDAS
----------------------
- Pensado para UN monitor (HDMI-A-1 en 0x0).
- Las capas que no sean tu barra contra-escalada (notificaciones de Hyprland,
  waybar, etc.) siguen escalando con el zoom.
- hl.monitor() se llama solo con output/mode/position/scale. Si tu monitor
  tiene mas campos (vrr, bitdepth, transform...), agregalos en monitor_lua().
- Recargar la config devuelve la escala a la de hyprland.lua sin des-panear
  las ventanas: usa "reset" antes de recargar.
- Si algun dia windowsMove queda apagada, ver el comando de rescate en
  hypr_ipc.py.
"""
import os
import sys
import time
import threading
import subprocess

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from hypr_ipc import (hyprctl_json, move_window_exact_lua, desktop_lock,
                      set_windows_move_animation)

ZOOM_MIN = 0.25
ZOOM_MAX = 2.5

STEPS_PER_CLICK = 1     # niveles por click de rueda
MIN_INTERVAL = 0.12     # s minimo entre cambios de escala. Cada cambio
                        # reconfigura el monitor y obliga a TODAS las apps a
                        # redibujarse; mas seguido que esto satura Hyprland
                        # (congelamientos) y las apps nunca terminan de
                        # ponerse nitidas. Los clicks que llegan mientras
                        # tanto se juntan en un solo salto mas grande.

WARP_CURSOR = True      # mantener el cursor en el mismo punto FISICO
CURSOR_COMPENSATE = True
# Tema y tamano base del cursor. Si quedan en None se leen de las variables
# de entorno (HYPRCURSOR_* / XCURSOR_*). Si tu cursor no se ve igual que
# siempre a escala 1, ponlos aqui a mano.
CURSOR_THEME = None
CURSOR_SIZE = None

NO_ANIM = True          # apaga windowsMove durante la rafaga de zoom
NOTIFY_QS = True        # avisa a Quickshell la escala (contra-zoom de barras)
VERIFY_TIMEOUT = 0.5    # s maximo esperando que Hyprland reporte la escala
DEBUG = False

_bad_levels = set()     # escalas que Hyprland rechazo en esta sesion


def _focused_monitor():
    mons = hyprctl_json(["monitors"]) or []
    return next((m for m in mons if m.get("focused")), mons[0] if mons else None)


def valid_levels(m):
    """Todas las escalas k/120 entre ZOOM_MIN y ZOOM_MAX que dan tamano
    logico entero. Aritmetica entera exacta: w/(k/120) = w*120/k."""
    w, h = m["width"], m["height"]
    out = []
    for k in range(round(ZOOM_MIN * 120), round(ZOOM_MAX * 120) + 1):
        if (w * 120) % k == 0 and (h * 120) % k == 0:
            s = k / 120
            if s not in _bad_levels:
                out.append(s)
    return out


def _fmt(v):
    return f"{v:.10g}"      # 120.0 -> "120", 1/3 -> "0.3333333333"


def monitor_lua(m, scale):
    mode = f'{m["width"]}x{m["height"]}@{_fmt(m["refreshRate"])}'
    pos = f'{m["x"]}x{m["y"]}'
    return (f'hl.monitor({{ output = "{m["name"]}", mode = "{mode}", '
            f'position = "{pos}", scale = {_fmt(scale)} }})')


def move_cursor_lua(x, y):
    return f'hl.dsp.cursor.move({{ x = {int(round(x))}, y = {int(round(y))} }})'


def _cursor_theme_size():
    theme = (CURSOR_THEME or os.environ.get("HYPRCURSOR_THEME")
             or os.environ.get("XCURSOR_THEME"))
    size = CURSOR_SIZE
    if size is None:
        for var in ("HYPRCURSOR_SIZE", "XCURSOR_SIZE"):
            try:
                size = int(os.environ[var])
                break
            except (KeyError, ValueError):
                pass
    return theme, (size or 24)


def _cursor_cmd(scale):
    """`setcursor <tema> <tamano>` para que el cursor se vea igual que a
    escala 1. None si no se conoce el tema (entonces no se toca)."""
    if not CURSOR_COMPENSATE:
        return None
    theme, size = _cursor_theme_size()
    if not theme:
        return None
    return f"setcursor {theme} {max(1, round(size / scale))}"


def _hyprctl_batch(cmds, timeout=5):
    if not cmds:
        return None
    r = subprocess.run(["hyprctl", "--batch", " ; ".join(cmds)],
                       capture_output=True, text=True, timeout=timeout)
    if DEBUG:
        print("[zoom] hyprctl:", r.stdout.strip(), r.stderr.strip(), flush=True)
    return r


def _is_pannable(c, mon_id):
    return (c.get("floating")
            and c.get("monitor") == mon_id
            and not c.get("fullscreen")
            and not c.get("pinned")
            and c.get("mapped", True))


def _wait_for_scale(name, target):
    deadline = time.monotonic() + VERIFY_TIMEOUT
    while True:
        mons = hyprctl_json(["monitors"]) or []
        mon = next((x for x in mons if x.get("name") == name), None)
        if mon and abs(float(mon.get("scale", 0)) - target) < 1e-3:
            return True
        if time.monotonic() >= deadline:
            return False
        time.sleep(0.01)


def _notify_qs(scale):
    if not NOTIFY_QS:
        return
    try:
        subprocess.Popen(["qs", "ipc", "call", "zoom", "setScale", _fmt(scale)],
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass


def get_zoom():
    m = _focused_monitor()
    return float(m.get("scale", 1.0)) if m else 1.0


def _notify_qs_begin():
    """Avisa a Quickshell que empieza una rafaga de zoom, ANTES del primer
    cambio de escala (sincrono, una vez por rafaga): el frame apaga sus
    animaciones de posicion para que nada rebote mientras cambia el tamano."""
    if not NOTIFY_QS:
        return
    try:
        subprocess.run(["qs", "ipc", "call", "zoom", "begin"],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=1.0)
    except Exception:
        pass


def anim_off():
    _notify_qs_begin()
    if NO_ANIM:
        _hyprctl_batch(['eval hl.animation({ leaf = "windowsMove", enabled = false })'])


def anim_on():
    if NO_ANIM:
        time.sleep(0.03)
        set_windows_move_animation(True)


def zoom_step(steps=0, target=None, anchor_physical=None):
    """Mueve `steps` niveles (o al nivel mas cercano a `target`) en un solo
    salto. Devuelve la escala resultante. NO toca la animacion: quien llama
    debe envolverlo con anim_off()/anim_on() (apply_zoom lo hace)."""
    with desktop_lock():
        m = _focused_monitor()
        if not m:
            return None
        s_old = float(m.get("scale", 1.0))
        levels = valid_levels(m)
        if not levels:
            return s_old

        if target is not None:
            s_new = min(levels, key=lambda s: abs(s - target))
        else:
            i = min(range(len(levels)), key=lambda j: abs(levels[j] - s_old))
            i = max(0, min(len(levels) - 1, i + steps))
            s_new = levels[i]

        if abs(s_new - s_old) < 1e-6:
            return s_old

        mx, my = m["x"], m["y"]
        if anchor_physical is None:
            cur = hyprctl_json(["cursorpos"]) or {"x": mx, "y": my}
            px = (cur["x"] - mx) * s_old
            py = (cur["y"] - my) * s_old
        else:
            px, py = anchor_physical

        dx = px * (1.0 / s_new - 1.0 / s_old)
        dy = py * (1.0 / s_new - 1.0 / s_old)

        clients = [c for c in (hyprctl_json(["clients"]) or [])
                   if _is_pannable(c, m["id"])]
        moves = [move_window_exact_lua(c["at"][0] + dx, c["at"][1] + dy, c["address"])
                 for c in clients]

        cmds = [f"eval {monitor_lua(m, s_new)}"]
        cmds += [f"dispatch {e}" for e in moves]
        if WARP_CURSOR:
            cmds.append(f"dispatch {move_cursor_lua(mx + px / s_new, my + py / s_new)}")
        cur_cmd = _cursor_cmd(s_new)
        if cur_cmd:
            cmds.append(cur_cmd)
        _hyprctl_batch(cmds)

        if not _wait_for_scale(m["name"], s_new):
            # Hyprland la rechazo: deshacer y no volver a intentarla.
            _bad_levels.add(s_new)
            undo = [f"dispatch {move_window_exact_lua(c['at'][0], c['at'][1], c['address'])}"
                    for c in clients]
            if WARP_CURSOR:
                undo.append(f"dispatch {move_cursor_lua(mx + px / s_old, my + py / s_old)}")
            cur_cmd = _cursor_cmd(s_old)
            if cur_cmd:
                undo.append(cur_cmd)
            _hyprctl_batch(undo)
            print(f"[zoom] Hyprland rechazo la escala {_fmt(s_new)}; "
                  f"se descarta en esta sesion", flush=True)
            return s_old

        _notify_qs(s_new)
        return s_new


def apply_zoom(steps=0, target=None, anchor_physical=None):
    """Para la CLI: un salto completo con la animacion apagada."""
    anim_off()
    try:
        return zoom_step(steps, target, anchor_physical)
    finally:
        anim_on()


class CanvasZoom:
    def __init__(self):
        self._pending = 0
        self._cv = threading.Condition()
        threading.Thread(target=self._worker, daemon=True).start()

    def add_steps(self, clicks):
        with self._cv:
            self._pending += clicks * STEPS_PER_CLICK
            self._cv.notify()

    def _take(self):
        with self._cv:
            n, self._pending = self._pending, 0
            return n

    def _worker(self):
        while True:
            with self._cv:
                while self._pending == 0:
                    self._cv.wait()
            anim_off()
            last = 0.0
            try:
                while True:
                    # Respetar el intervalo minimo; mientras tanto se siguen
                    # acumulando clicks (o se cancelan si giras al reves).
                    wait = MIN_INTERVAL - (time.monotonic() - last)
                    if wait > 0:
                        time.sleep(wait)
                    n = self._take()
                    if n == 0:
                        break
                    before = get_zoom()
                    try:
                        after = zoom_step(steps=n)
                    except Exception as e:
                        print(f"[zoom] error: {e}", flush=True)
                        break
                    last = time.monotonic()
                    if after is None or abs(after - before) < 1e-6:
                        self._take()       # tope del rango: descartar el resto
                        break
            finally:
                anim_on()


if __name__ == "__main__":
    if "--debug" in sys.argv:
        DEBUG = True
        sys.argv.remove("--debug")
    arg = sys.argv[1] if len(sys.argv) > 1 else "get"
    if arg == "in":
        z = apply_zoom(steps=1)
    elif arg == "out":
        z = apply_zoom(steps=-1)
    elif arg == "reset":
        m = _focused_monitor()
        center = (m["width"] / 2, m["height"] / 2) if m else None
        z = apply_zoom(target=1.0, anchor_physical=center)
        _notify_qs(z or 1.0)
    elif arg == "get":
        z = get_zoom()
    elif arg == "levels":
        m = _focused_monitor()
        print(" ".join(f"{s:.4g}" for s in valid_levels(m)))
        sys.exit(0)
    else:
        try:
            z = apply_zoom(steps=int(arg))
        except ValueError:
            print("uso: zoom_canvas.py [--debug] in | out | reset | get | levels | <+N/-N>")
            sys.exit(1)
    print(_fmt(z) if z is not None else "?")