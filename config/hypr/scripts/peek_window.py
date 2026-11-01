#!/usr/bin/env python3
"""
peek_window.py

Hace "peek" de una ventana flotante hacia la esquina de pantalla mas cercana
a su posicion actual, dejando solo unos pocos pixeles dentro del area fisica
del monitor. Esto es suficiente para que windowPreviewPopup (ScreencopyView)
pueda renderizar su thumbnail en vivo, aunque la ventana este "paneada" fuera
del escritorio por el sistema de infinite desktop.

La esquina se elige segun el CUADRANTE actual de la ventana respecto al
centro del monitor (no una esquina fija ni aleatoria) para que la animacion
de movimiento de Hyprland nunca cruce por el centro del escritorio.

Uso:
    python3 peek_window.py peek <address>
    python3 peek_window.py restore <address>
    python3 peek_window.py cancel <address>
    python3 peek_window.py setpos <address> <x> <y>
    python3 peek_window.py declutter <address>

Estado (posicion original antes del peek) se guarda en /tmp/qs_peek_state.json,
mapeado por address, para poder restaurar exactamente aunque la ventana se
haya "movido" (peekeado) mientras tanto. Si se pide peek() dos veces seguidas
sobre la misma ventana sin restore() en medio (hover rapido dentro-fuera-
dentro), NO se vuelve a guardar la posicion (ya guardada) para no terminar
"restaurando" a la posicion peekeada por error.

"setpos" (agregado para el minimapa/window map de Quickshell) escribe la
posicion "original" directamente, sin releerla de hyprctl -- ver su
docstring mas abajo para el porque (evita una ventana de tiempo real entre
mover una ventana y que Hyprland refleje esa posicion en "hyprctl clients
-j", que podia hacer que un peek() posterior guardara una posicion vieja
como si fuera la real).

"declutter" (agregado para el arrastre de widgets de escritorio de
Quickshell) hace lo mismo que "peek" pero SIN el chequeo de "¿ya es
visible en algun monitor?" -- peek() se salta a proposito una ventana
ya visible porque para SU caso de uso (mantener el thumbnail
renderizando) no hace falta tocarla; declutter() SI necesita moverla
igual, porque el objetivo es despejar el escritorio para verlo debajo
del widget que se esta arrastrando, sin importar si la ventana ya
estaba a la vista o no.
"""
import sys
import os
import traceback
from datetime import datetime

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from hypr_ipc import (hyprctl_json, move_window_exact, desktop_lock,
                       _load_peek_state as load_state,
                       _save_peek_state as save_state)

PEEK_MARGIN = 5  # px visibles dentro del monitor en la esquina
DEBUG_LOG = "/tmp/qs_peek_debug.log"


def log(msg):
    try:
        with open(DEBUG_LOG, "a") as f:
            f.write(f"[{datetime.now().isoformat(timespec='seconds')}] {msg}\n")
    except Exception:
        pass


def find_client(address):
    clients = hyprctl_json(["clients"]) or []
    norm = address.lower()
    for w in clients:
        if w.get("address", "").lower() == norm:
            return w
    return None


def get_focused_monitor(monitors):
    for m in monitors:
        if m.get("focused"):
            return m
    return monitors[0] if monitors else None


def rects_overlap(ax, ay, aw, ah, bx, by, bw, bh):
    return not (ax + aw <= bx or ax >= bx + bw or ay + ah <= by or ay >= by + bh)


def is_window_visible(win, monitors):
    """True si el rectangulo de la ventana ya se solapa con ALGUN monitor,
    aunque sea 1px — que es justo lo que hace falta para que el
    ScreencopyView renderice el thumbnail. En ese caso no hay nada que
    peekear."""
    wx, wy = win["at"][0], win["at"][1]
    ww, wh = win["size"][0], win["size"][1]
    for m in monitors:
        if rects_overlap(wx, wy, ww, wh, m["x"], m["y"], m["width"], m["height"]):
            return True
    return False


def compute_peek_target(win, mon):
    wx, wy = win["at"][0], win["at"][1]
    ww, wh = win["size"][0], win["size"][1]
    mx, my, mw, mh = mon["x"], mon["y"], mon["width"], mon["height"]

    wcx, wcy = wx + ww / 2, wy + wh / 2
    mcx, mcy = mx + mw / 2, my + mh / 2

    # Cuadrante horizontal: si el centro de la ventana esta a la izquierda
    # del centro del monitor, la esquina destino es la IZQUIERDA (solo el
    # borde derecho de la ventana asoma PEEK_MARGIN px dentro del monitor).
    if wcx < mcx:
        tx = mx + PEEK_MARGIN - ww
    else:
        tx = mx + mw - PEEK_MARGIN

    if wcy < mcy:
        ty = my + PEEK_MARGIN - wh
    else:
        ty = my + mh - PEEK_MARGIN

    return int(tx), int(ty)


def peek(address):
    log(f"--- peek({address}) ---")
    with desktop_lock():
        win = find_client(address)
        if not win:
            log("find_client: NO encontro la ventana (address no matcheo ninguna en 'hyprctl clients -j')")
            return
        log(f"find_client OK: floating={win.get('floating')} at={win.get('at')} size={win.get('size')} "
            f"monitor={win.get('monitor')} workspace={win.get('workspace')}")

        # Solo aplica al sistema de infinite desktop (ventanas flotantes).
        # Las tileadas ya estan siempre dentro del area visible del monitor.
        if not win.get("floating"):
            log("SALIO: floating es False/None -> se ignora (no deberia pasar para ventanas del infinite desktop)")
            return

        monitors = hyprctl_json(["monitors"]) or []
        if not monitors:
            log("SALIO: 'hyprctl monitors -j' no devolvio nada")
            return
        log(f"monitors: {[(m.get('name'), m.get('x'), m.get('y'), m.get('width'), m.get('height'), m.get('focused')) for m in monitors]}")

        visible = is_window_visible(win, monitors)
        log(f"is_window_visible = {visible}")
        if visible:
            log("SALIO: la ventana ya se solapa con un monitor -> no se peekea (esto es correcto SOLO si de verdad ya es visible)")
            return

        mon = get_focused_monitor(monitors)
        if not mon:
            log("SALIO: no hay monitor enfocado")
            return
        log(f"monitor destino: {mon.get('name')} x={mon['x']} y={mon['y']} w={mon['width']} h={mon['height']}")

        state = load_state()
        if address not in state:
            state[address] = {"x": win["at"][0], "y": win["at"][1]}
            save_state(state)
            log(f"posicion original guardada: {state[address]}")
        else:
            log(f"ya habia posicion original guardada: {state[address]}")

        tx, ty = compute_peek_target(win, mon)
        log(f"moviendo a target=({tx},{ty})")
        result = move_window_exact(tx, ty, address)
        log(f"dispatch resultado: returncode={result.returncode} stdout={result.stdout!r} stderr={result.stderr!r}")


def setpos(address, x, y):
    """Escribe DIRECTAMENTE la posicion "original" para esta address, SIN
    volver a leerla de hyprctl. Pensado para el minimapa (window map) de
    Quickshell: cuando el usuario arrastra una ventana ahi, Quickshell ya
    sabe exactamente donde la solto -- no conviene que este script vuelva
    a preguntarle a Hyprland "donde esta ahora", porque hay una ventana de
    tiempo real entre que se emite el dispatch de movimiento y que
    Hyprland termina de aplicarlo/reflejarlo en "hyprctl clients -j"; si
    peek() (que SI relee via hyprctl) corriera primero o justo en ese
    hueco, terminaba guardando una posicion vieja/a mitad de camino como
    si fuera la "original" -- exactamente el bug reportado de ventanas
    recien arrastradas mostrando mal su posicion en el minimapa.

    A diferencia de peek() (que solo guarda si "address not in state"),
    esto PISA cualquier estado previo para esta address a proposito: una
    reubicacion manual del usuario siempre gana sobre lo que hubiera
    guardado antes. No mueve la ventana ni decide si peekearla -- eso lo
    sigue haciendo un peek() posterior (se llama encadenado justo
    despues desde el minimapa), que al encontrar la address YA en el
    estado no la vuelve a pisar (ver "if address not in state" mas
    abajo) y solo se encarga de decidir si hace falta moverla a una
    esquina para que Hyprland la siga renderizando.
    """
    with desktop_lock():
        state = load_state()
        state[address] = {"x": int(x), "y": int(y)}
        save_state(state)
        log(f"setpos({address}): posicion original fijada manualmente a x={x} y={y}")


def restore(address):
    with desktop_lock():
        state = load_state()
        orig = state.get(address)
        if not orig:
            return

        move_window_exact(orig["x"], orig["y"], address)

        del state[address]
        save_state(state)


def cancel(address):
    """Borra el registro de posicion original de esta ventana SIN
    moverla. Se usa cuando el usuario clickeo el icono del taskbar
    mientras la ventana estaba peekeada: focus_window_from_taskbar.py
    (script aparte) ya la reposiciono a proposito (centrada), asi que
    un restore() posterior NO debe llevarla de vuelta a la posicion de
    ANTES del peek -- eso deshacia el click."""
    with desktop_lock():
        state = load_state()
        if address in state:
            del state[address]
            save_state(state)
            log(f"cancel({address}): registro borrado sin mover la ventana")


def declutter(address):
    """Como peek(), pero FUERZA el movimiento a la esquina aunque la
    ventana ya sea visible en algun monitor -- se salta a proposito el
    chequeo is_window_visible() que peek() si respeta.

    Pensado para un caso de uso distinto al de peek(): peek() existe
    para que Hyprland siga renderizando el thumbnail de una ventana que
    el escritorio infinito paneo FUERA del area visible (si ya es
    visible, no hace falta moverla, de ahi el chequeo). declutter() es
    para alejar temporalmente TODAS las ventanas del escritorio -- aunque
    ya esten a la vista -- mientras se arrastra un widget, para poder
    ver el escritorio debajo. Comparte el mismo estado
    (/tmp/qs_peek_state.json) y la misma logica de "no pisar la posicion
    original ya guardada" que peek(), asi que restore() funciona igual
    sin importar si la ventana llego a su esquina via peek() o
    declutter().
    """
    log(f"--- declutter({address}) ---")
    with desktop_lock():
        win = find_client(address)
        if not win:
            log("declutter: NO encontro la ventana (address no matcheo ninguna en 'hyprctl clients -j')")
            return

        if not win.get("floating"):
            log("declutter SALIO: floating es False/None -> se ignora")
            return

        monitors = hyprctl_json(["monitors"]) or []
        if not monitors:
            log("declutter SALIO: 'hyprctl monitors -j' no devolvio nada")
            return

        mon = get_focused_monitor(monitors)
        if not mon:
            log("declutter SALIO: no hay monitor enfocado")
            return

        state = load_state()
        if address not in state:
            state[address] = {"x": win["at"][0], "y": win["at"][1]}
            save_state(state)
            log(f"declutter: posicion original guardada: {state[address]}")
        else:
            log(f"declutter: ya habia posicion original guardada: {state[address]}")

        tx, ty = compute_peek_target(win, mon)
        log(f"declutter: moviendo a target=({tx},{ty})")
        result = move_window_exact(tx, ty, address)
        log(f"declutter: dispatch resultado: returncode={result.returncode} stdout={result.stdout!r} stderr={result.stderr!r}")


def main():
    if len(sys.argv) < 3 or sys.argv[1] not in ("peek", "restore", "cancel", "setpos", "declutter"):
        print("Uso: peek_window.py <peek|restore|cancel|declutter> <address>")
        print("     peek_window.py setpos <address> <x> <y>")
        sys.exit(1)

    action, address = sys.argv[1], sys.argv[2]
    try:
        if action == "peek":
            peek(address)
        elif action == "restore":
            restore(address)
        elif action == "declutter":
            declutter(address)
        elif action == "setpos":
            if len(sys.argv) < 5:
                print("Uso: peek_window.py setpos <address> <x> <y>")
                sys.exit(1)
            setpos(address, sys.argv[3], sys.argv[4])
        else:
            cancel(address)
    except Exception:
        log("EXCEPCION:\n" + traceback.format_exc())


if __name__ == "__main__":
    main()