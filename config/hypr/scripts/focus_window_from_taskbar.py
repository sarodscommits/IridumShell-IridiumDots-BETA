#!/usr/bin/env python3
"""
focus_window_from_taskbar.py
Uso: python3 focus_window_from_taskbar.py <address>

Llamado desde el click en el módulo de ventanas abiertas de quickshell
(openWindowsRepeater en shell.qml).

Si la ventana clickeada es flotante: replica pan_to_window() de
navigate_windows.py -> mueve TODAS las ventanas flotantes del mismo
workspace relativamente para que la clickeada quede centrada en el
monitor. Si es tileada, solo enfoca.

A diferencia de navigate_windows.py (donde el salto del mouse al centro
de la ventana enfocada es un comportamiento querido, parte de la
navegación con teclado), acá el click ya puso el mouse justo donde el
usuario lo quiere. Probamos primero forzar cursor:no_warps durante la
operación, pero el salto seguía pasando igual (esa opción no es la
causa, o no alcanza para este caso) — así que en vez de eso, la
solución es: guardar la posición real del mouse ANTES de mover/enfocar,
y devolverlo ahí con hl.dsp.cursor.move() al final, sin importar qué
mecanismo interno de Hyprland haya causado el salto.

Confirmado en vivo (no estaba en la wiki):
    hyprctl dispatch 'hl.dsp.cursor.move({ x = 100, y = 100 })'  -> ok
    hyprctl cursorpos -j  -> {"x": .., "y": ..}
"""

import sys
import os
import socket

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from hypr_ipc import (hyprctl_json, move_window_exact_lua, batch, focus_window,
                       dispatch, desktop_lock, _load_peek_state, _save_peek_state)
RUNTIME_DIR = os.environ.get("XDG_RUNTIME_DIR") or "/tmp"  # per-user; /tmp is shared between users


# Mismo socket que infinite_desktop_core.py y navigate_windows.py: Quickshell
# desplaza el wallpaper y los widgets en parallax con este paneo. Si el
# parallax está apagado nadie escucha y el envío simplemente se ignora.
PARALLAX_SOCK = os.path.join(RUNTIME_DIR, "qs-parallax.sock")


def notify_parallax(dx, dy):
    if dx == 0 and dy == 0:
        return
    try:
        s = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
        s.setblocking(False)
        s.sendto(f"{dx} {dy}".encode(), PARALLAX_SOCK)
        s.close()
    except OSError:
        pass


def get_monitor_center():
    monitors = hyprctl_json(["monitors"]) or []
    for m in monitors:
        if m.get("focused"):
            return m["x"] + m["width"] // 2, m["y"] + m["height"] // 2
    return 960, 540


def cursor_move_lua(x, y):
    return f'hl.dsp.cursor.move({{ x = {int(x)}, y = {int(y)} }})'


def get_cursor_pos():
    pos = hyprctl_json(["cursorpos"])
    if not pos:
        return None
    return pos.get("x"), pos.get("y")


def restore_cursor_pos(pos):
    if pos is None:
        return
    x, y = pos
    dispatch(cursor_move_lua(x, y))


def do_focus_holding_cursor(address, exprs=None):
    """Ejecuta el paneo (si hay exprs) + focus_window, y al final devuelve
    el mouse a donde estaba antes de todo esto. Todo síncrono (batch/
    dispatch normales, no las variantes _async), para poder restaurar el
    cursor recién cuando el foco+paneo YA se aplicaron, no antes (si no,
    el propio warp de Hyprland pisaría nuestra restauración)."""
    saved_pos = get_cursor_pos()
    try:
        if exprs:
            batch(exprs)
        focus_window(address)
    finally:
        restore_cursor_pos(saved_pos)


def resolve_positions(windows):
    """Para cada ventana, la posicion REAL a usar para calcular el
    paneo -- si tenia una posicion "peekeada" pendiente (guardada por
    peek_window.py mientras esperaba en la esquina para el thumbnail),
    usa esa posicion original en vez de la actual (la de la esquina), y
    cancela ese registro de una vez (una sola lectura/escritura del
    archivo de estado para todas las ventanas, no una por ventana).

    Sin esto: si esta ventana (u otra del mismo workspace) estaba
    peekeada cuando se clickeo el taskbar, el paneo se calculaba desde
    su posicion en la esquina en vez de su posicion real -- un dx/dy
    mas chico del que hacia falta, que "encogia" el canvas un poco en
    cada click sobre una ventana lejana en vez de centrarla del todo.
    Ademas, sin cancelar el registro, un restore() posterior (disparado
    al salir el mouse del taskbar) deshacia este centrado."""
    state = _load_peek_state()
    changed = False
    positions = {}
    for w in windows:
        addr = w["address"]
        orig = state.pop(addr, None)
        if orig is not None:
            changed = True
            positions[addr] = (orig["x"], orig["y"])
        else:
            positions[addr] = (w["at"][0], w["at"][1])
    if changed:
        _save_peek_state(state)
    return positions


def main():
    if len(sys.argv) < 2 or not sys.argv[1]:
        sys.exit(1)

    address = sys.argv[1]

    # Todo el ciclo "leer posiciones -> calcular -> mover -> enfocar"
    # va dentro del lock compartido con peek_window.py: si un
    # restore() de un hover anterior todavia esta a mitad de camino,
    # esperamos a que termine en vez de leer datos a medio aplicar
    # (esa condicion de carrera era la causa real del "acercamiento").
    with desktop_lock():
        clients = hyprctl_json(["clients"]) or []
        target = next((w for w in clients if w.get("address") == address), None)

        if not target or not target.get("floating"):
            do_focus_holding_cursor(address)
            return

        ws_id = target.get("workspace", {}).get("id")
        floating = [
            w for w in clients
            if w.get("floating") and w.get("workspace", {}).get("id") == ws_id
        ]

        positions = resolve_positions(floating)

        center_x, center_y = get_monitor_center()
        tx0, ty0 = positions[target["address"]]
        tx = tx0 + target["size"][0] // 2
        ty = ty0 + target["size"][1] // 2
        dx = center_x - tx
        dy = center_y - ty

        exprs = [
            move_window_exact_lua(int(positions[w["address"]][0] + dx),
                                   int(positions[w["address"]][1] + dy),
                                   w["address"])
            for w in floating
        ]

        # Solo si la ventana está en el workspace visible: si está en otro,
        # Quickshell recibiría el delta justo durante el cambio de workspace
        # y podría aplicárselo al que se está dejando.
        active_ws = (hyprctl_json(["activeworkspace"]) or {}).get("id")
        same_ws = active_ws == ws_id

        do_focus_holding_cursor(address, exprs)

        if same_ws:
            notify_parallax(dx, dy)


if __name__ == "__main__":
    main()