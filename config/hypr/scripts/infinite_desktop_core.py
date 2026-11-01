# Infinite desktop daemon: reads mice/keyboards via evdev and drives
#   Super+Alt+mouse   pan every floating window (with inertia + parallax)
#   Super+wheel       zoom (monitor scale)
#   Super+drag        push the other windows when the dragged one hits an edge
#   Super+drag/right  window magnets (window_magnet.py)
# Usage: infinite_desktop_core.py [pan speed, default 1.0]
import sys, struct, threading, time, subprocess, json, os, socket
import math
from evdev import InputDevice, list_devices, ecodes

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from hypr_ipc import move_window_exact_lua, batch_async
from zoom_canvas import CanvasZoom
from window_magnet import WindowMagnet, ResizeMagnet

DEVICE_RESCAN_INTERVAL = 3.0

EVENT_SIZE = struct.calcsize('llHHi')
EV_KEY = 1; EV_REL = 2; REL_X = 0; REL_Y = 1
REL_WHEEL = 8   # hi-res mice also send REL_WHEEL_HI_RES (11); counting both doubles each click
KEY_LEFTMETA = 125; KEY_RIGHTMETA = 126
KEY_LEFTALT = 56; KEY_RIGHTALT = 100
KEY_LEFTCTRL = 29; KEY_RIGHTCTRL = 97
BTN_LEFT = 272; BTN_RIGHT = 273

try:
    speed = float(sys.argv[1]) if len(sys.argv) > 1 else 1.0
except ValueError:
    speed = 1.0

# ── Pan inertia: on release the canvas keeps gliding with exponential friction ──
INERTIA_ENABLED   = True
INERTIA_FRICTION  = 4.0     # 1/s, higher stops sooner (4 -> ~1 s)
INERTIA_SAMPLE    = 0.08    # s of recent motion used to measure release speed
INERTIA_MIN_START = 250.0   # px/s, slower releases stop dead
INERTIA_MIN_SPEED = 20.0    # px/s, glide ends here
INERTIA_MAX_SPEED = 5000.0  # px/s
INERTIA_MAX_DIST  = 0.6     # max glide distance as a fraction of monitor width

# Written by Quickshell settings: {"enabled", "friction", "maxDist"}; read on each release
INERTIA_CONFIG = "/tmp/infinite-desktop-inertia"

def read_inertia_config():
    cfg = {'enabled': INERTIA_ENABLED, 'friction': INERTIA_FRICTION, 'maxDist': INERTIA_MAX_DIST}
    try:
        with open(INERTIA_CONFIG) as f:
            d = json.load(f)
        if isinstance(d.get('enabled'), bool):
            cfg['enabled'] = d['enabled']
        if isinstance(d.get('friction'), (int, float)):
            cfg['friction'] = min(15.0, max(1.0, float(d['friction'])))
        if isinstance(d.get('maxDist'), (int, float)):
            cfg['maxDist'] = min(1.0, max(0.1, float(d['maxDist'])))
    except Exception:
        pass
    return cfg

# Bumped on every Super/Alt/Ctrl/left-click press; a change cancels the glide
input_press_seq = 0

# ── Parallax: deltas go to Quickshell over a unix datagram socket ──
PARALLAX_SOCK = "/tmp/qs-parallax.sock"
_parallax_sock = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
_parallax_sock.setblocking(False)

def notify_parallax(dx, dy):
    if dx == 0 and dy == 0:
        return
    try:
        _parallax_sock.sendto(f"{dx} {dy}".encode(), PARALLAX_SOCK)
    except OSError:
        pass   # nobody listening (parallax off)

# Window panning follows hyprctl's irregular rate, so parallax gets the raw
# float deltas at a fixed 120 Hz instead.
_plx_x = 0.0
_plx_y = 0.0

def parallax_sender():
    global _plx_x, _plx_y
    while True:
        time.sleep(1 / 120)
        with lock:
            x, y = _plx_x, _plx_y
            _plx_x = 0.0
            _plx_y = 0.0
        if x or y:
            notify_parallax(round(x, 2), round(y, 2))


STATE_FILE = "/tmp/infinite-desktop-state"   # 'inverse' | 'normal', written by Quickshell

lock = threading.Lock()
super_pressed = False; alt_pressed = False; ctrl_pressed = False; btn_left = False; btn_right = False
acc_x = 0.0; acc_y = 0.0
frame_held_hidden = False   # last state sent to Quickshell (avoids IPC spam)
mouse_rel_x = 0
mouse_rel_y = 0

# Read on every pan event, so cached for 0.25 s
_inv_cache = False
_inv_checked = 0.0

def read_inverted():
    global _inv_cache, _inv_checked
    now = time.monotonic()
    if now - _inv_checked < 0.25:
        return _inv_cache
    _inv_checked = now
    try:
        with open(STATE_FILE) as f:
            _inv_cache = f.read().strip() == 'inverse'
    except Exception:
        _inv_cache = False
    return _inv_cache

def notify_quickshell_hold(state):
    """Hide/show the shell frame while Super+Alt is held."""
    try:
        subprocess.run(
            ['qs', 'ipc', 'call', 'frame', 'setHeldHidden', 'true' if state else 'false'],
            capture_output=True, timeout=1.0
        )
    except Exception:
        pass

def _logical_bounds(m):
    """Monitor edges in logical coords (hyprctl gives physical px; divide by scale)."""
    s = m.get('scale') or 1.0
    w = round(m['width'] / s)
    h = round(m['height'] / s)
    return {
        'left': m['x'],
        'right': m['x'] + w,
        'top': m['y'],
        'bottom': m['y'] + h,
        'width': w,
        'height': h
    }

def get_monitor_bounds():
    try:
        r = subprocess.run(['hyprctl', 'monitors', '-j'], capture_output=True, text=True, timeout=0.1)
        monitors = json.loads(r.stdout)
        if monitors:
            for m in monitors:
                if m.get('focused', False):
                    return _logical_bounds(m)
            return _logical_bounds(monitors[0])
    except Exception:
        pass
    return {'left': 0, 'right': 1920, 'top': 0, 'bottom': 1080, 'width': 1920, 'height': 1080}


# Focused monitor scale = zoom level; cached for 0.25 s
_scale_cache = 1.0
_scale_checked = 0.0

def get_cached_scale():
    global _scale_cache, _scale_checked
    now = time.monotonic()
    if now - _scale_checked < 0.25:
        return _scale_cache
    _scale_checked = now
    try:
        r = subprocess.run(['hyprctl', 'monitors', '-j'], capture_output=True, text=True, timeout=0.1)
        for m in json.loads(r.stdout):
            if m.get('focused', False):
                _scale_cache = float(m.get('scale') or 1.0)
                break
    except Exception:
        pass
    return _scale_cache

def get_floating_windows(workspace_id):
    try:
        r = subprocess.run(['hyprctl', 'clients', '-j'], capture_output=True, text=True, timeout=0.1)
        return [w for w in json.loads(r.stdout)
                if w.get('floating') and w.get('workspace', {}).get('id') == workspace_id]
    except Exception:
        return []

def get_focused_window():
    try:
        r = subprocess.run(['hyprctl', 'activewindow', '-j'], capture_output=True, text=True, timeout=0.1)
        return json.loads(r.stdout)
    except Exception:
        return None

def get_window_bounds(window):
    x, y = window['at'][0], window['at'][1]
    w, h = window['size'][0], window['size'][1]
    return {'left': x, 'right': x + w, 'top': y, 'bottom': y + h}


def pan_other_windows(excluded_addr, dx, dy, workspace_id):
    """Move every floating window except `excluded_addr` in one batch."""
    if dx == 0 and dy == 0:
        return
    try:
        exprs = [move_window_exact_lua(int(w['at'][0] + dx), int(w['at'][1] + dy), w['address'])
                 for w in get_floating_windows(workspace_id) if w['address'] != excluded_addr]
        batch_async(exprs)
        notify_parallax(dx, dy)
    except Exception:
        pass


def monitor_window_drag():
    """While Super+dragging a window against a monitor edge, pan the others the opposite way."""
    global mouse_rel_x, mouse_rel_y
    MARGIN = 10
    dragged_addr = None

    while True:
        try:
            with lock:
                is_dragging = super_pressed and btn_left and not alt_pressed and not ctrl_pressed
                mouse_dx = mouse_rel_x
                mouse_dy = mouse_rel_y
                mouse_rel_x = 0
                mouse_rel_y = 0

            if is_dragging and dragged_addr is None:
                focused = get_focused_window()
                if focused and focused.get('address'):
                    dragged_addr = focused['address']
            elif not is_dragging:
                dragged_addr = None

            if dragged_addr and (mouse_dx or mouse_dy):
                window = get_focused_window()
                if window and window.get('address') == dragged_addr:
                    b = get_window_bounds(window)
                    mon = get_monitor_bounds()
                    pan_dx = pan_dy = 0
                    if (b['right'] >= mon['right'] - MARGIN and mouse_dx > 0) or \
                       (b['left'] <= mon['left'] + MARGIN and mouse_dx < 0):
                        pan_dx = -mouse_dx
                    if (b['bottom'] >= mon['bottom'] - MARGIN and mouse_dy > 0) or \
                       (b['top'] <= mon['top'] + MARGIN and mouse_dy < 0):
                        pan_dy = -mouse_dy

                    # mouse deltas are physical px, windows are logical
                    s = get_cached_scale()
                    pan_dx /= s
                    pan_dy /= s

                    if pan_dx or pan_dy:
                        r = subprocess.run(['hyprctl', 'activeworkspace', '-j'],
                                           capture_output=True, text=True, timeout=0.1)
                        pan_other_windows(dragged_addr, int(pan_dx), int(pan_dy), json.loads(r.stdout)['id'])
                else:
                    dragged_addr = None

            time.sleep(0.016)
        except Exception:
            time.sleep(0.1)


def classify_device(path):
    """'mouse', 'keyboard' or None, from the device's capabilities (not its name)."""
    try:
        dev = InputDevice(path)
        caps = dev.capabilities()
        dev.close()
    except Exception:
        return None

    keys = set(caps.get(ecodes.EV_KEY, []))
    rels = set(caps.get(ecodes.EV_REL, []))

    if ecodes.REL_X in rels and ecodes.REL_Y in rels and ecodes.BTN_LEFT in keys:
        return 'mouse'

    # Full alphanumeric range + Meta excludes the consumer/system-control
    # interfaces that 2.4G receivers also expose
    if (ecodes.KEY_A in keys and ecodes.KEY_Z in keys and ecodes.KEY_LEFTSHIFT in keys
            and (ecodes.KEY_LEFTMETA in keys or ecodes.KEY_RIGHTMETA in keys)):
        return 'keyboard'

    return None


def scan_devices():
    keyboards, mice = [], []
    for path in list_devices():
        kind = classify_device(path)
        if kind == 'mouse':
            mice.append(path)
        elif kind == 'keyboard':
            keyboards.append(path)
    return keyboards, mice


def kbd_reader_device(path):
    """Reader thread for one keyboard."""
    global super_pressed, alt_pressed, ctrl_pressed, frame_held_hidden, input_press_seq
    try:
        fd = open(path, 'rb')
    except Exception:
        return

    while True:
        try:
            data = fd.read(EVENT_SIZE)
        except Exception:
            break
        if not data or len(data) < EVENT_SIZE:
            break
        _, _, etype, code, value = struct.unpack('llHHi', data)
        if etype != EV_KEY or value == 2:
            continue

        notify_state = None
        with lock:
            if value == 1 and code in (KEY_LEFTMETA, KEY_RIGHTMETA, KEY_LEFTALT, KEY_RIGHTALT,
                                       KEY_LEFTCTRL, KEY_RIGHTCTRL):
                input_press_seq += 1
            if code in (KEY_LEFTMETA, KEY_RIGHTMETA):
                super_pressed = (value == 1)
            elif code in (KEY_LEFTALT, KEY_RIGHTALT):
                alt_pressed = (value == 1)
            elif code in (KEY_LEFTCTRL, KEY_RIGHTCTRL):
                ctrl_pressed = (value == 1)

            combo = super_pressed and alt_pressed
            if combo != frame_held_hidden:
                frame_held_hidden = combo
                notify_state = combo

        # IPC outside the lock and on its own thread so reading never blocks
        if notify_state is not None:
            threading.Thread(target=notify_quickshell_hold, args=(notify_state,), daemon=True).start()

    try:
        fd.close()
    except Exception:
        pass


def mouse_reader_device(path):
    """Reader thread for one mouse."""
    global acc_x, acc_y, btn_left, btn_right, mouse_rel_x, mouse_rel_y, _plx_x, _plx_y, input_press_seq
    try:
        fd = open(path, 'rb')
    except Exception:
        return

    while True:
        try:
            data = fd.read(EVENT_SIZE)
        except Exception:
            break
        if not data or len(data) < EVENT_SIZE:
            break
        _, _, etype, code, value = struct.unpack('llHHi', data)

        # Super + wheel = zoom (wheel up zooms in)
        if etype == EV_REL and code == REL_WHEEL:
            if super_pressed and not alt_pressed and not ctrl_pressed:
                zoomer.add_steps(value)
            continue

        with lock:
            if etype == EV_KEY and code == BTN_LEFT:
                btn_left = (value == 1)
                if value == 1:
                    input_press_seq += 1
            elif etype == EV_KEY and code == BTN_RIGHT:
                btn_right = (value == 1)
            elif etype == EV_REL:
                if code == REL_X:
                    mouse_rel_x += value
                elif code == REL_Y:
                    mouse_rel_y += value

                if super_pressed and alt_pressed:
                    sign = -1 if read_inverted() else 1
                    # parallax is in logical px; cached scale (no hyprctl inside the lock)
                    sc = _scale_cache or 1.0
                    if code == REL_X:
                        acc_x += value * speed * sign
                        _plx_x += value * speed * sign / sc
                    elif code == REL_Y:
                        acc_y += value * speed * sign
                        _plx_y += value * speed * sign / sc
                else:
                    acc_x = 0.0
                    acc_y = 0.0

    try:
        fd.close()
    except Exception:
        pass


_active_kbd_threads = {}
_active_mouse_threads = {}

def device_manager():
    """Start a reader thread for each new or reconnected device. Scans faster
    for the first 20 s because wireless dongles enumerate late at login."""
    WARMUP_DURATION = 20.0
    WARMUP_INTERVAL = 0.5
    start_time = time.time()

    while True:
        try:
            keyboards, mice = scan_devices()
            for registry, paths, target, label in ((_active_kbd_threads, keyboards, kbd_reader_device, "keyboard"),
                                                   (_active_mouse_threads, mice, mouse_reader_device, "mouse")):
                for path in paths:
                    t = registry.get(path)
                    if t is None or not t.is_alive():
                        nt = threading.Thread(target=target, args=(path,), daemon=True)
                        nt.start()
                        registry[path] = nt
                        print(f"[+] {label}: {path}", flush=True)
        except Exception as e:
            print(f"device_manager error: {e}", flush=True)

        elapsed = time.time() - start_time
        time.sleep(WARMUP_INTERVAL if elapsed < WARMUP_DURATION else DEVICE_RESCAN_INTERVAL)

# Must exist before the mouse threads start
zoomer = CanvasZoom()

threading.Thread(target=device_manager, daemon=True).start()
threading.Thread(target=monitor_window_drag, daemon=True).start()
threading.Thread(target=parallax_sender, daemon=True).start()
WindowMagnet(lambda: super_pressed and btn_left and not alt_pressed and not ctrl_pressed).start()
ResizeMagnet(lambda: super_pressed and btn_right and not btn_left
             and not alt_pressed and not ctrl_pressed).start()
print("Infinite desktop running", flush=True)

# Active workspace cached for 2 s
_cached_workspace_id = None
_last_workspace_check = 0
WORKSPACE_CACHE_TTL = 2.0

def get_cached_workspace_id():
    global _cached_workspace_id, _last_workspace_check
    now = time.time()
    if _cached_workspace_id is None or (now - _last_workspace_check) > WORKSPACE_CACHE_TTL:
        try:
            r = subprocess.run(['hyprctl', 'activeworkspace', '-j'],
                               capture_output=True, text=True, timeout=0.1)
            _cached_workspace_id = json.loads(r.stdout)['id']
            _last_workspace_check = now
        except Exception:
            pass
    return _cached_workspace_id

def move_all_floating(idx, idy):
    workspace_id = get_cached_workspace_id()
    if workspace_id is None:
        return
    exprs = [move_window_exact_lua(w['at'][0] + idx, w['at'][1] + idy, w['address'])
             for w in get_floating_windows(workspace_id)]
    batch_async(exprs)


# ── Main loop: desktop pan + release inertia ──
samples = []            # (t, dx, dy) in logical px while dragging
was_dragging = False
glide_vx = 0.0; glide_vy = 0.0
glide_active = False
glide_seq = 0
glide_friction = INERTIA_FRICTION
rem_x = 0.0; rem_y = 0.0   # sub-pixel remainder kept across frames
last_t = time.monotonic()

def stop_glide():
    global glide_active, glide_vx, glide_vy
    glide_active = False
    glide_vx = 0.0
    glide_vy = 0.0

while True:
    time.sleep(0.016)
    now = time.monotonic()
    dt = min(max(now - last_t, 0.001), 0.05)
    last_t = now

    with lock:
        active_drag = super_pressed and alt_pressed
        dx = acc_x
        dy = acc_y
        acc_x = 0.0
        acc_y = 0.0
        seq = input_press_seq

    if active_drag:
        stop_glide()
        was_dragging = True
        # zoom compensation: at scale 0.5 the canvas must move twice the logical px
        s = get_cached_scale()
        dx /= s
        dy /= s
        samples.append((now, dx, dy))
        while samples and now - samples[0][0] > INERTIA_SAMPLE:
            samples.pop(0)
    else:
        if was_dragging:
            was_dragging = False
            vx = sum(sm[1] for sm in samples if now - sm[0] <= INERTIA_SAMPLE) / INERTIA_SAMPLE
            vy = sum(sm[2] for sm in samples if now - sm[0] <= INERTIA_SAMPLE) / INERTIA_SAMPLE
            samples.clear()
            sp = math.hypot(vx, vy)
            icfg = read_inertia_config()
            if icfg['enabled'] and sp >= INERTIA_MIN_START:
                if sp > INERTIA_MAX_SPEED:
                    vx *= INERTIA_MAX_SPEED / sp; vy *= INERTIA_MAX_SPEED / sp; sp = INERTIA_MAX_SPEED
                # total glide = v / friction, capped to the monitor width
                glide_friction = icfg['friction']
                max_d = get_monitor_bounds()['width'] * icfg['maxDist']
                if sp / glide_friction > max_d:
                    k = max_d * glide_friction / sp
                    vx *= k; vy *= k
                glide_vx, glide_vy = vx, vy
                glide_active = True
                glide_seq = seq
        if not glide_active:
            continue
        if seq != glide_seq:
            stop_glide()
            continue
        # exact integral of the exponential decay over this frame
        f = math.exp(-glide_friction * dt)
        dx = glide_vx * (1 - f) / glide_friction
        dy = glide_vy * (1 - f) / glide_friction
        glide_vx *= f
        glide_vy *= f
        if math.hypot(glide_vx, glide_vy) < INERTIA_MIN_SPEED:
            stop_glide()
        with lock:
            _plx_x += dx
            _plx_y += dy

    # drag and glide share the remainder so windows travel exactly as far as the parallax
    rem_x += dx
    rem_y += dy
    idx = int(round(rem_x))
    idy = int(round(rem_y))
    if idx == 0 and idy == 0:
        continue
    rem_x -= idx
    rem_y -= idy

    try:
        move_all_floating(idx, idy)
    except Exception:
        pass
