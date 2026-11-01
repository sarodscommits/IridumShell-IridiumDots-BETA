#!/usr/bin/env python3
"""
window_magnet.py
Imán entre ventanas flotantes para Hyprland (config Lua, >= 0.55).

CÓMO FUNCIONA
-------------
El arrastre lo sigue haciendo Hyprland (bind Super + clic -> movewindow).
Este script NO toma el control del mouse, solo corrige la posición.

Hyprland calcula la posición del arrastre como
    posición_inicial_ventana + (cursor - cursor_inicial)
así que la posición "que quiere el usuario" siempre es cursor - offset_de_agarre,
aunque nosotros hayamos movido la ventana.

UNIR vs SEPARAR
---------------
Para cada borde vecino se mide una distancia con signo:
    s > 0  -> queda hueco mayor que GAP (afuera)
    s = 0  -> justo pegada con GAP
    s < 0  -> metiéndose encima de la otra ventana

  * UNIR: solo se pega si la ventana se está ACERCANDO a ese borde
    (s disminuye) y entra en la zona de SNAP_DIST, o si lo cruza de golpe.
    Moverse en paralelo o alejándose nunca dispara el imán.

  * Mientras está pegada:
      - empujar hacia la otra ventana  -> resiste hasta BREAK_INTO px
      - tirar para separarla           -> se suelta a los BREAK_AWAY px
    (separar cuesta poco, atravesar cuesta mucho)

  * SEPARAR: al soltarse, ese borde queda "desarmado" y no vuelve a atraer
    hasta que la ventana se aleje REARM_DIST px. Tampoco atraen los bordes
    con los que la ventana ya estaba pegada al empezar el arrastre, así que
    agarrar una ventana pegada para separarla no la retiene.

  * Alineación (arriba/abajo o izq/der con la vecina) solo funciona mientras
    está pegada a esa vecina en el otro eje.

SALTOS / "TELETRANSPORTE"
-------------------------
Cada corrección pasa por hl.dsp.window.move, que anima con windowsMove,
mientras Hyprland mueve la ventana al instante con el cursor. Esa pelea
se ve como saltos. Para evitarlo, durante el arrastre se intenta poner
la propiedad no_anim SOLO en la ventana arrastrada (set_prop) y se
quita al soltar. No toca la config global de animaciones. Si tu versión
de Hyprland no acepta esa propiedad, se avisa una vez por consola y el
imán sigue funcionando igual (con algo de salto).

USO
---
    from window_magnet import WindowMagnet, ResizeMagnet
    WindowMagnet(lambda: super_pressed and btn_left and not alt_pressed
                 and not ctrl_pressed and not canvas_active()).start()
    ResizeMagnet(lambda: super_pressed and btn_right and not btn_left
                 and not alt_pressed and not ctrl_pressed
                 and not canvas_active()).start()

ResizeMagnet (al final del archivo) hace lo mismo al redimensionar con
Super + clic derecho: imanta los bordes que se están estirando.
"""
import os
import json
import socket
import subprocess
import threading
import time

from hypr_ipc import move_window_exact_lua, resize_window_exact_lua

# ── Ajustes ──────────────────────────────────────────────────────────────
GAP = 7                     # px visibles entre ventanas pegadas
GAP_INCLUDES_BORDER = True  # suma 2 x border_size para que el hueco VISIBLE sea GAP

SNAP_DIST = 16      # px: zona en la que se pega (solo si se está acercando)
BREAK_AWAY = 22     # px: cuánto hay que tirar hacia afuera para separarla
BREAK_INTO = 70     # px: cuánto hay que empujar hacia la otra para atravesarla
REARM_DIST = 40     # px: distancia para que un borde soltado vuelva a atraer

ALIGN = True        # alinear bordes con la vecina a la que está pegada
ALIGN_SNAP = 10
ALIGN_BREAK = 28
ALIGN_REARM = 30

# True: al separar, el imán vuelve a intentar pegarla (también si ya estaban
# pegadas al empezar). False: un borde soltado no atrae hasta alejarse REARM_DIST.
RESNAP_ON_SEPARATE = True

NO_ANIM_WHILE_DRAG = True   # no_anim solo en la ventana arrastrada (ver arriba)

# ── Configuración desde Quickshell ───────────────────────────────────────
# Ajustes > Infinite desktop > Imán de ventanas escribe aquí un JSON. Se relee
# (si cambió) al empezar cada arrastre/redimensionado, así que los cambios
# aplican al instante sin reiniciar el daemon. Sin archivo: valores de arriba.
CONFIG_PATH = "/tmp/infinite-desktop-magnet"
MOVE_ENABLED = True
RESIZE_ENABLED = True
_cfg_mtime = None

# clave JSON -> (variables que actualiza, tipo, mínimo, máximo)
_CFG_KEYS = {
    "move":      (("MOVE_ENABLED",), bool, None, None),
    "resize":    (("RESIZE_ENABLED",), bool, None, None),
    "gap":       (("GAP",), int, 0, 40),
    "snap":      (("SNAP_DIST", "R_SNAP_DIST"), int, 2, 60),
    "breakAway": (("BREAK_AWAY", "R_BREAK_AWAY"), int, 2, 150),
    "breakInto": (("BREAK_INTO", "R_BREAK_INTO"), int, 5, 300),
    "resnap":    (("RESNAP_ON_SEPARATE",), bool, None, None),
    "align":     (("ALIGN", "R_ALIGN"), bool, None, None),
    "noAnim":    (("NO_ANIM_WHILE_DRAG",), bool, None, None),
}


def reload_config():
    """Aplica /tmp/infinite-desktop-magnet si cambió desde la última lectura."""
    global _cfg_mtime
    try:
        mt = os.stat(CONFIG_PATH).st_mtime
    except OSError:
        return
    if mt == _cfg_mtime:
        return
    try:
        with open(CONFIG_PATH) as f:
            d = json.load(f)
    except (OSError, ValueError):
        return
    _cfg_mtime = mt
    g = globals()
    if d.get("enabled") is False:
        g["MOVE_ENABLED"] = g["RESIZE_ENABLED"] = False
        d = {k: v for k, v in d.items() if k not in ("move", "resize")}
    for key, (names, typ, lo, hi) in _CFG_KEYS.items():
        v = d.get(key)
        if typ is bool:
            if not isinstance(v, bool):
                continue
        else:
            if isinstance(v, bool) or not isinstance(v, (int, float)):
                continue
            v = int(min(hi, max(lo, round(v))))
        for n in names:
            g[n] = v
    if d.get("enabled") is True:
        g["MOVE_ENABLED"] = d.get("move", True) is not False
        g["RESIZE_ENABLED"] = d.get("resize", True) is not False
    log("config", {n: g[n] for ns, *_ in _CFG_KEYS.values() for n in ns})


POLL = 0.003            # s entre lecturas del cursor durante el arrastre
REFRESH_OTHERS = 0.15   # s entre relecturas de las demás ventanas
BEGIN_TRIES = 20        # ticks para encontrar la ventana arrastrada
DEBUG = False


def log(*a):
    if DEBUG:
        print("[magnet]", *a, flush=True)


# ── IPC directo por el socket de Hyprland ──────────────────────────────────
class HyprSocket:
    def __init__(self):
        rt = os.environ.get("XDG_RUNTIME_DIR") or f"/run/user/{os.getuid()}"
        sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "")
        self.path = f"{rt}/hypr/{sig}/.socket.sock"

    def request(self, msg):
        try:
            s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            s.settimeout(0.25)
            s.connect(self.path)
            s.sendall(msg.encode())
            chunks = []
            while True:
                c = s.recv(65536)
                if not c:
                    break
                chunks.append(c)
            s.close()
            return b"".join(chunks).decode(errors="replace")
        except OSError:
            if msg.startswith("dispatch "):
                args = ["dispatch", msg[len("dispatch "):]]
            elif msg.startswith("j/"):
                args = msg[2:].split(" ", 1) + ["-j"]
            else:
                args = msg.split(" ", 1)
            try:
                r = subprocess.run(["hyprctl"] + args, capture_output=True, text=True, timeout=0.5)
                return r.stdout
            except Exception:
                return ""

    def j(self, cmd):
        out = self.request("j/" + cmd).strip()
        if not out or out[0] not in "[{":
            return None
        try:
            return json.loads(out)
        except ValueError:
            return None

    def dispatch(self, expr):
        return self.request("dispatch " + expr)

    def dispatch_many(self, exprs):
        """Varias órdenes en UNA petición: Hyprland las aplica en el mismo evento."""
        if len(exprs) == 1:
            return self.dispatch(exprs[0])
        out = self.request("[[BATCH]]" + ";".join("dispatch " + e for e in exprs))
        if not out:
            for e in exprs:
                self.dispatch(e)
        return out


def _rect(at, size):
    return {"l": at[0], "t": at[1], "r": at[0] + size[0], "b": at[1] + size[1]}


# ── no_anim por ventana ───────────────────────────────────────────────────
# Formas de valor que se prueban en orden; se recuerda la primera aceptada.
_NOANIM_VALUES = [("true", "false"), ("1", "0"), ('"on"', '"off"')]


class NoAnim:
    def __init__(self, ipc):
        self.ipc = ipc
        self.variant = None     # índice que funcionó
        self.broken = False
        self.on_addr = None

    def _set(self, addr, value):
        expr = (f'hl.dsp.window.set_prop({{ prop = "no_anim", value = {value}, '
                f'window = "address:{addr}" }})')
        out = (self.ipc.dispatch(expr) or "").strip().lower()
        return out == "ok" or out.startswith("ok")

    def enable(self, addr):
        if self.broken or not NO_ANIM_WHILE_DRAG:
            return
        tries = [self.variant] if self.variant is not None else range(len(_NOANIM_VALUES))
        for i in tries:
            if self._set(addr, _NOANIM_VALUES[i][0]):
                self.variant = i
                self.on_addr = addr
                log("no_anim activo con", _NOANIM_VALUES[i][0])
                return
        self.broken = True
        print("[magnet] Hyprland no aceptó set_prop no_anim; el imán sigue "
              "funcionando pero con animación (puede verse algún salto).", flush=True)

    def disable(self):
        if self.on_addr and self.variant is not None:
            self._set(self.on_addr, _NOANIM_VALUES[self.variant][1])
        self.on_addr = None


class WindowMagnet:
    def __init__(self, is_dragging):
        self.is_dragging = is_dragging
        self.ipc = HyprSocket()
        self.noanim = NoAnim(self.ipc)
        self._reset()

    def start(self):
        threading.Thread(target=self._run, daemon=True).start()
        return self

    def _disarm(self, key):
        if not RESNAP_ON_SEPARATE:
            self.disarmed.add(key)

    # ── estado ──
    def _reset(self):
        self.active = False
        self.gave_up = False
        self.tries = 0
        self.addr = None
        self.ws = None
        self.w = self.h = 0
        self.grab = (0, 0)
        self.gap = GAP
        self.others = []
        self.others_t = 0.0
        self.snap = {"x": None, "y": None}   # candidato pegado por eje
        self.prev_s = {}                     # key -> distancia con signo del tick anterior
        self.disarmed = set()                # keys que no atraen hasta alejarse
        self.last_intended = None
        self.last_target = None

    def _run(self):
        while True:
            try:
                if self.is_dragging():
                    if not self.active and not self.gave_up:
                        self._begin()
                    if self.active:
                        self._tick()
                    time.sleep(POLL)
                else:
                    if self.active or self.gave_up:
                        self._end()
                    time.sleep(0.016)
            except Exception as e:
                log("error:", e)
                time.sleep(0.05)

    # ── inicio del arrastre ──
    def _begin(self):
        if self.tries == 0:
            reload_config()
            if not MOVE_ENABLED:
                self.gave_up = True
                return
        self.tries += 1
        if self.tries > BEGIN_TRIES:
            self.gave_up = True
            return
        cur = self.ipc.j("cursorpos")
        aw = self.ipc.j("activewindow")
        if not cur or not aw or not aw.get("address"):
            return
        if not aw.get("floating") or aw.get("fullscreen"):
            self.gave_up = True
            return
        r = _rect(aw["at"], aw["size"])
        m = 12
        if not (r["l"] - m <= cur["x"] <= r["r"] + m and r["t"] - m <= cur["y"] <= r["b"] + m):
            return

        border = 0
        if GAP_INCLUDES_BORDER:
            opt = self.ipc.j("getoption general:border_size")
            if isinstance(opt, dict) and isinstance(opt.get("int"), int):
                border = max(0, opt["int"])
        self.gap = GAP + 2 * border

        self.addr = aw["address"]
        self.ws = (aw.get("workspace") or {}).get("id")
        self.w, self.h = aw["size"]
        self.grab = (cur["x"] - aw["at"][0], cur["y"] - aw["at"][1])
        self._refresh_others()

        # Bordes con los que ya estaba pegada: no la retienen al separarla.
        x0, y0 = aw["at"]
        for axis, val in (("x", x0), ("y", y0)):
            for c in self._gap_cands(axis, x0, y0):
                s = (val - c["pos"]) * c["out"]
                if abs(s) <= SNAP_DIST:
                    self._disarm(c["key"])
                self.prev_s[c["key"]] = s
            for c in self._align_cands(axis, None):
                if abs(val - c["pos"]) <= ALIGN_SNAP:
                    self._disarm(c["key"])

        self.noanim.enable(self.addr)
        self.active = True
        log("drag", self.addr, "gap", self.gap, "desarmados", self.disarmed)

    def _refresh_others(self):
        self.others_t = time.monotonic()
        out = []
        for c in self.ipc.j("clients") or []:
            if c.get("address") == self.addr:
                continue
            if not c.get("floating") or not c.get("mapped", True) or c.get("hidden"):
                continue
            if (c.get("workspace") or {}).get("id") != self.ws:
                continue
            rr = _rect(c["at"], c["size"])
            rr["addr"] = c["address"]
            out.append(rr)
        self.others = out

    # ── candidatos ──
    def _gap_cands(self, axis, ix, iy):
        """Bordes donde pegarse con GAP. 'out' = sentido hacia afuera de la vecina."""
        w, h, g, S = self.w, self.h, self.gap, SNAP_DIST
        res = []
        for o in self.others:
            a = o["addr"]
            if axis == "x":
                if iy < o["b"] + S and iy + h > o["t"] - S:      # comparten franja vertical
                    res.append({"pos": o["l"] - g - w, "out": -1, "key": (a, "L"), "o": a})
                    res.append({"pos": o["r"] + g,     "out": +1, "key": (a, "R"), "o": a})
            else:
                if ix < o["r"] + S and ix + w > o["l"] - S:      # comparten franja horizontal
                    res.append({"pos": o["t"] - g - h, "out": -1, "key": (a, "T"), "o": a})
                    res.append({"pos": o["b"] + g,     "out": +1, "key": (a, "B"), "o": a})
        return res

    def _align_cands(self, axis, only_addr):
        w, h = self.w, self.h
        res = []
        for o in self.others:
            if only_addr is not None and o["addr"] != only_addr:
                continue
            a = o["addr"]
            if axis == "x":
                res.append({"pos": o["l"],     "key": (a, "aL")})
                res.append({"pos": o["r"] - w, "key": (a, "aR")})
            else:
                res.append({"pos": o["t"],     "key": (a, "aT")})
                res.append({"pos": o["b"] - h, "key": (a, "aB")})
        return res

    # ── eje con imán de hueco (unir / separar) ──
    def _gap_axis(self, axis, value, cands):
        prev = self.prev_s
        new_prev = {}
        snap = self.snap[axis]
        result = None

        for c in cands:
            s = (value - c["pos"]) * c["out"]
            new_prev[c["key"]] = s
            if c["key"] in self.disarmed and abs(s) > REARM_DIST:
                self.disarmed.discard(c["key"])

        # ¿sigue pegada?
        if snap is not None and snap.get("kind") == "gap":
            cur = next((c for c in cands if c["key"] == snap["key"]), None)
            if cur is not None:
                s = new_prev[cur["key"]]
                if -BREAK_INTO <= s <= BREAK_AWAY:
                    result = dict(cur, kind="gap")
                else:
                    self._disarm(cur["key"])          # separada: no re-atrae
                    log(axis, "suelta", cur["key"], "s=", s)
            # si cur es None se deslizó fuera del borde: se suelta sin desarmar

        # ¿se pega a algo nuevo? solo acercándose
        if result is None:
            best, bd = None, None
            for c in cands:
                k = c["key"]
                if k in self.disarmed or k not in prev:
                    continue
                s, ps = new_prev[k], prev[k]
                approaching = RESNAP_ON_SEPARATE or s < ps
                in_zone = -SNAP_DIST <= s <= SNAP_DIST
                crossed = ps > 0 and s <= 0 and s >= -BREAK_INTO
                if approaching and (in_zone or crossed):
                    d = abs(s)
                    if bd is None or d < bd:
                        best, bd = c, d
            if best is not None:
                result = dict(best, kind="gap")
                log(axis, "pega", best["key"])

        # actualizar distancias de este eje (sin borrar las del otro eje)
        for k in [k for k in prev if k[1] in (("L", "R") if axis == "x" else ("T", "B"))]:
            if k not in new_prev:
                del prev[k]
        prev.update(new_prev)
        return result

    # ── eje con alineación (solo junto a la vecina pegada en el otro eje) ──
    def _align_axis(self, axis, value, neighbor):
        snap = self.snap[axis]
        cands = self._align_cands(axis, neighbor) if (ALIGN and neighbor) else []

        for c in self._align_cands(axis, None):
            if c["key"] in self.disarmed and abs(value - c["pos"]) > ALIGN_REARM:
                self.disarmed.discard(c["key"])

        if snap is not None and snap.get("kind") == "align":
            cur = next((c for c in cands if c["key"] == snap["key"]), None)
            if cur is not None:
                if abs(value - cur["pos"]) <= ALIGN_BREAK:
                    return dict(cur, kind="align")
                self._disarm(cur["key"])
        best, bd = None, None
        for c in cands:
            if c["key"] in self.disarmed:
                continue
            d = abs(value - c["pos"])
            if d <= ALIGN_SNAP and (bd is None or d < bd):
                best, bd = c, d
        return dict(best, kind="align") if best else None

    # ── cada tick del arrastre ──
    def _tick(self):
        cur = self.ipc.j("cursorpos")
        if not cur:
            return
        ix = int(round(cur["x"] - self.grab[0]))
        iy = int(round(cur["y"] - self.grab[1]))

        if time.monotonic() - self.others_t > REFRESH_OTHERS:
            self._refresh_others()

        was_snapped = self.snap["x"] is not None or self.snap["y"] is not None

        gx = self._gap_axis("x", ix, self._gap_cands("x", ix, iy))
        gy = self._gap_axis("y", iy, self._gap_cands("y", ix, iy))

        # Alineación en el eje que no está pegado por hueco, solo con la
        # vecina a la que sí está pegada en el otro eje.
        sx = gx if gx else self._align_axis("x", ix, gy["o"] if gy else None)
        sy = gy if gy else self._align_axis("y", iy, gx["o"] if gx else None)
        self.snap["x"], self.snap["y"] = sx, sy

        fx = sx["pos"] if sx else ix
        fy = sy["pos"] if sy else iy
        snapped = sx is not None or sy is not None
        target = (int(fx), int(fy))

        if snapped:
            if (ix, iy) != self.last_intended or target != self.last_target:
                self.ipc.dispatch(move_window_exact_lua(target[0], target[1], self.addr))
            self.last_target = target
        else:
            if was_snapped:
                self.ipc.dispatch(move_window_exact_lua(ix, iy, self.addr))
            self.last_target = None
        self.last_intended = (ix, iy)

    # ── fin del arrastre ──
    def _end(self):
        if self.active and self.last_target is not None:
            t, addr = self.last_target, self.addr
            time.sleep(0.03)
            self.ipc.dispatch(move_window_exact_lua(t[0], t[1], addr))
            log("drop pegada en", t)
        self.noanim.disable()
        self._reset()


# ══════════════════════════════════════════════════════════════════════════
# IMÁN AL REDIMENSIONAR (Super + clic derecho -> resizewindow)
# ══════════════════════════════════════════════════════════════════════════
# Misma idea que al mover: Hyprland redimensiona desde el rectángulo inicial
# + (cursor - cursor_inicial), según la esquina agarrada, así que el tamaño
# "que quiere el usuario" siempre se puede calcular. Solo se imantan los
# bordes que se están moviendo:
#   * borde contra borde de otra ventana, con GAP           (unir/separar)
#   * borde alineado con el mismo borde de la vecina de al lado (alinear)
# Unir solo al acercarse, separar con poca tolerancia, y un borde soltado
# no vuelve a atraer hasta alejarse REARM_DIST, igual que al mover.

R_SNAP_DIST = 16
R_BREAK_AWAY = 22
R_BREAK_INTO = 70
R_REARM_DIST = 40
R_ALIGN = True
R_ALIGN_SNAP = 10
R_ALIGN_BREAK = 28
R_ALIGN_REARM = 30
R_MIN_SIZE = 40          # px mínimos que nunca se pasan al corregir
R_ADJ_TOL = 3            # px para considerar que dos ventanas están lado a lado


class ResizeMagnet:
    def __init__(self, is_resizing):
        self.is_resizing = is_resizing
        self.ipc = HyprSocket()
        self.noanim = NoAnim(self.ipc)
        self._reset()

    def start(self):
        threading.Thread(target=self._run, daemon=True).start()
        return self

    def _disarm(self, key):
        if not RESNAP_ON_SEPARATE:
            self.disarmed.add(key)

    def _reset(self):
        self.active = False
        self.gave_up = False
        self.tries = 0
        self.addr = None
        self.ws = None
        self.r0 = None            # rectángulo al empezar
        self.c0 = (0, 0)          # cursor al empezar
        self.ex = self.ey = None  # bordes que se mueven: "l"/"r" y "t"/"b"
        self.gap = GAP
        self.others = []
        self.others_t = 0.0
        self.snap = {"x": None, "y": None}
        self.prev_s = {}
        self.disarmed = set()
        self.last_cursor = None
        self.last_rect = None

    def _run(self):
        while True:
            try:
                if self.is_resizing():
                    if not self.active and not self.gave_up:
                        self._begin()
                    if self.active:
                        self._tick()
                    time.sleep(POLL)
                else:
                    if self.active or self.gave_up:
                        self._end()
                    time.sleep(0.016)
            except Exception as e:
                log("resize error:", e)
                time.sleep(0.05)

    # ── inicio ──
    def _begin(self):
        if self.tries == 0:
            reload_config()
            if not RESIZE_ENABLED:
                self.gave_up = True
                return
        self.tries += 1
        if self.tries > BEGIN_TRIES:
            self.gave_up = True
            return
        cur = self.ipc.j("cursorpos")
        aw = self.ipc.j("activewindow")
        if not cur or not aw or not aw.get("address"):
            return
        if not aw.get("floating") or aw.get("fullscreen"):
            self.gave_up = True
            return
        r = _rect(aw["at"], aw["size"])
        m = 12
        if not (r["l"] - m <= cur["x"] <= r["r"] + m and r["t"] - m <= cur["y"] <= r["b"] + m):
            return

        border = 0
        if GAP_INCLUDES_BORDER:
            opt = self.ipc.j("getoption general:border_size")
            if isinstance(opt, dict) and isinstance(opt.get("int"), int):
                border = max(0, opt["int"])
        self.gap = GAP + 2 * border

        # Esquina que agarra Hyprland: general:resize_corner
        # 0 = la más cercana al cursor, 1 = arriba-izq, 2 = arriba-der,
        # 3 = abajo-der, 4 = abajo-izq.
        corner = 0
        opt = self.ipc.j("getoption general:resize_corner")
        if isinstance(opt, dict) and isinstance(opt.get("int"), int):
            corner = opt["int"]
        if corner == 1:
            self.ex, self.ey = "l", "t"
        elif corner == 2:
            self.ex, self.ey = "r", "t"
        elif corner == 3:
            self.ex, self.ey = "r", "b"
        elif corner == 4:
            self.ex, self.ey = "l", "b"
        else:
            cx = (r["l"] + r["r"]) / 2
            cy = (r["t"] + r["b"]) / 2
            self.ex = "l" if cur["x"] < cx else "r"
            self.ey = "t" if cur["y"] < cy else "b"

        self.addr = aw["address"]
        self.ws = (aw.get("workspace") or {}).get("id")
        self.r0 = dict(r)
        self.c0 = (cur["x"], cur["y"])
        self._refresh_others()

        # Bordes que ya estaban pegados/alineados: no retienen al separar.
        for axis, edge in (("x", self.ex), ("y", self.ey)):
            val = r[edge]
            for c in self._gap_cands(edge, r):
                sd = (val - c["pos"]) * c["out"]
                self.prev_s[c["key"]] = sd
                if abs(sd) <= R_SNAP_DIST:
                    self._disarm(c["key"])
            for c in self._align_cands(edge, None):
                if abs(val - c["pos"]) <= R_ALIGN_SNAP:
                    self._disarm(c["key"])

        self.noanim.enable(self.addr)
        self.active = True
        log("resize", self.addr, "esquina", self.ex, self.ey, "desarmados", self.disarmed)

    def _refresh_others(self):
        self.others_t = time.monotonic()
        out = []
        for c in self.ipc.j("clients") or []:
            if c.get("address") == self.addr:
                continue
            if not c.get("floating") or not c.get("mapped", True) or c.get("hidden"):
                continue
            if (c.get("workspace") or {}).get("id") != self.ws:
                continue
            rr = _rect(c["at"], c["size"])
            rr["addr"] = c["address"]
            out.append(rr)
        self.others = out

    # ── rectángulo que quiere el usuario ──
    def _intended(self, cur):
        dx = cur["x"] - self.c0[0]
        dy = cur["y"] - self.c0[1]
        r = dict(self.r0)
        if self.ex == "r":
            r["r"] = max(r["l"] + R_MIN_SIZE, self.r0["r"] + dx)
        else:
            r["l"] = min(r["r"] - R_MIN_SIZE, self.r0["l"] + dx)
        if self.ey == "b":
            r["b"] = max(r["t"] + R_MIN_SIZE, self.r0["b"] + dy)
        else:
            r["t"] = min(r["b"] - R_MIN_SIZE, self.r0["t"] + dy)
        return {k: int(round(v)) for k, v in r.items()}

    # ── candidatos para un borde que se mueve ──
    def _gap_cands(self, edge, r):
        """edge: 'l','r','t','b'. 'out' = sentido en que el hueco crece."""
        g, S = self.gap, R_SNAP_DIST
        res = []
        for o in self.others:
            a = o["addr"]
            if edge in ("l", "r"):
                if not (r["t"] < o["b"] + S and r["b"] > o["t"] - S):
                    continue
                if edge == "r" and r["l"] < o["l"]:
                    res.append({"pos": o["l"] - g, "out": -1, "key": (a, "rL"), "o": a})
                if edge == "l" and r["r"] > o["r"]:
                    res.append({"pos": o["r"] + g, "out": +1, "key": (a, "lR"), "o": a})
            else:
                if not (r["l"] < o["r"] + S and r["r"] > o["l"] - S):
                    continue
                if edge == "b" and r["t"] < o["t"]:
                    res.append({"pos": o["t"] - g, "out": -1, "key": (a, "bT"), "o": a})
                if edge == "t" and r["b"] > o["b"]:
                    res.append({"pos": o["b"] + g, "out": +1, "key": (a, "tB"), "o": a})
        return res

    def _align_cands(self, edge, neighbors):
        res = []
        for o in self.others:
            if neighbors is not None and o["addr"] not in neighbors:
                continue
            res.append({"pos": o[edge], "key": (o["addr"], "a" + edge)})
        return res

    def _side_neighbors(self, axis, r):
        """Vecinas pegadas 'de lado' respecto al eje que se alinea.
        axis 'y' (alinear arriba/abajo): vecinas a izquierda o derecha.
        axis 'x' (alinear izq/der): vecinas arriba o abajo."""
        g, T = self.gap, R_ADJ_TOL
        res = set()
        for o in self.others:
            if axis == "y":
                if (abs(r["l"] - (o["r"] + g)) <= T or abs(r["r"] - (o["l"] - g)) <= T) \
                        and r["t"] < o["b"] and r["b"] > o["t"]:
                    res.add(o["addr"])
            else:
                if (abs(r["t"] - (o["b"] + g)) <= T or abs(r["b"] - (o["t"] - g)) <= T) \
                        and r["l"] < o["r"] and r["r"] > o["l"]:
                    res.add(o["addr"])
        return res

    # ── unir / separar en un borde ──
    def _gap_edge(self, axis, value, cands):
        prev = self.prev_s
        new_prev = {}
        snap = self.snap[axis]
        result = None
        for c in cands:
            sd = (value - c["pos"]) * c["out"]
            new_prev[c["key"]] = sd
            if c["key"] in self.disarmed and abs(sd) > R_REARM_DIST:
                self.disarmed.discard(c["key"])

        if snap is not None and snap.get("kind") == "gap":
            cur = next((c for c in cands if c["key"] == snap["key"]), None)
            if cur is not None:
                sd = new_prev[cur["key"]]
                if -R_BREAK_INTO <= sd <= R_BREAK_AWAY:
                    result = dict(cur, kind="gap")
                else:
                    self._disarm(cur["key"])

        if result is None:
            best, bd = None, None
            for c in cands:
                k = c["key"]
                if k in self.disarmed or k not in prev:
                    continue
                sd, ps = new_prev[k], prev[k]
                approaching = RESNAP_ON_SEPARATE or sd < ps
                in_zone = -R_SNAP_DIST <= sd <= R_SNAP_DIST
                crossed = ps > 0 and sd <= 0 and sd >= -R_BREAK_INTO
                if approaching and (in_zone or crossed):
                    if bd is None or abs(sd) < bd:
                        best, bd = c, abs(sd)
            if best is not None:
                result = dict(best, kind="gap")
                log("resize", axis, "pega", best["key"])

        mine = ("rL", "lR") if axis == "x" else ("bT", "tB")
        for k in [k for k in prev if k[1] in mine and k not in new_prev]:
            del prev[k]
        prev.update(new_prev)
        return result

    # ── alinear un borde con la vecina de al lado ──
    def _align_edge(self, axis, edge, value, neighbors):
        snap = self.snap[axis]
        cands = self._align_cands(edge, neighbors) if (R_ALIGN and neighbors) else []
        for c in self._align_cands(edge, None):
            if c["key"] in self.disarmed and abs(value - c["pos"]) > R_ALIGN_REARM:
                self.disarmed.discard(c["key"])
        if snap is not None and snap.get("kind") == "align":
            cur = next((c for c in cands if c["key"] == snap["key"]), None)
            if cur is not None:
                if abs(value - cur["pos"]) <= R_ALIGN_BREAK:
                    return dict(cur, kind="align")
                self._disarm(cur["key"])
        best, bd = None, None
        for c in cands:
            if c["key"] in self.disarmed:
                continue
            d = abs(value - c["pos"])
            if d <= R_ALIGN_SNAP and (bd is None or d < bd):
                best, bd = c, d
        return dict(best, kind="align") if best else None

    # ── cada tick ──
    def _tick(self):
        cur = self.ipc.j("cursorpos")
        if not cur:
            return
        if time.monotonic() - self.others_t > REFRESH_OTHERS:
            self._refresh_others()

        want = self._intended(cur)
        was_snapped = self.snap["x"] is not None or self.snap["y"] is not None

        gx = self._gap_edge("x", want[self.ex], self._gap_cands(self.ex, want))
        gy = self._gap_edge("y", want[self.ey], self._gap_cands(self.ey, want))

        rect = dict(want)
        if gx:
            rect[self.ex] = gx["pos"]
        if gy:
            rect[self.ey] = gy["pos"]

        sx = gx or self._align_edge("x", self.ex, want[self.ex], self._side_neighbors("x", rect))
        if sx:
            rect[self.ex] = sx["pos"]
        sy = gy or self._align_edge("y", self.ey, want[self.ey], self._side_neighbors("y", rect))
        if sy:
            rect[self.ey] = sy["pos"]
        self.snap["x"], self.snap["y"] = sx, sy

        # nunca más chica que el mínimo
        if rect["r"] - rect["l"] < R_MIN_SIZE or rect["b"] - rect["t"] < R_MIN_SIZE:
            rect = want
            sx = sy = None
            self.snap["x"] = self.snap["y"] = None

        snapped = sx is not None or sy is not None
        ckey = (int(cur["x"]), int(cur["y"]))
        if snapped:
            if ckey != self.last_cursor or rect != self.last_rect:
                self._apply(rect)
            self.last_rect = rect
        else:
            if was_snapped:
                self._apply(want)
            self.last_rect = None
        self.last_cursor = ckey

    def _apply(self, r):
        w, h = r["r"] - r["l"], r["b"] - r["t"]
        exprs = [resize_window_exact_lua(w, h, self.addr)]
        if self.ex == "l" or self.ey == "t":
            exprs.append(move_window_exact_lua(r["l"], r["t"], self.addr))
        self.ipc.dispatch_many(exprs)

    def _end(self):
        if self.active and self.last_rect is not None:
            r = self.last_rect
            time.sleep(0.03)
            self._apply(r)
            log("resize suelta pegada en", r)
        self.noanim.disable()
        self._reset()


if __name__ == "__main__":
    print("Este módulo se arranca desde infinite_desktop_core.py (ver docstring).")