#!/usr/bin/env python3
# Terminal palette from pywal or matugen. Args: <dark|light> <source>
import json, os, sys, glob, colorsys
mode = sys.argv[1] if len(sys.argv) > 1 else 'dark'
tmode = sys.argv[2] if len(sys.argv) > 2 else 'pywal'
H = os.path.expanduser('~/.cache/wal')
light = mode == 'light'

def rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i+2], 16) / 255.0 for i in (0, 2, 4))
def hx(c):
    return '#%02x%02x%02x' % tuple(int(round(max(0.0, min(1.0, v)) * 255)) for v in c)
def hls(h):
    return colorsys.rgb_to_hls(*rgb(h))
def mk(hh, l, s):
    return hx(colorsys.hls_to_rgb(hh % 1.0, max(0.0, min(1.0, l)), max(0.0, min(1.0, s))))
def flip(h, lo, hi, sat=1.0):
    hh, l, s = hls(h)
    l = min(hi, max(lo, 1.0 - l))
    return mk(hh, l, s * sat)
def lin(v):
    return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4
def lum(h):
    r, g, b = rgb(h)
    return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)
def contrast(a, b):
    la, lb = lum(a), lum(b)
    if la < lb: la, lb = lb, la
    return (la + 0.05) / (lb + 0.05)
def ensure(c, bg, target):
    hh, l, s = hls(c)
    step = -0.01 if light else 0.01
    n = 0
    while contrast(c, bg) < target and n < 100:
        l = max(0.0, min(1.0, l + step))
        c = mk(hh, l, s)
        n += 1
    return c

def load_matugen():
    for p in (os.path.join(H, 'matugen-term.json'), os.path.expanduser('~/.config/matugen/colors.json')):
        try:
            d = json.load(open(p))
        except Exception:
            continue
        c = d.get('colors', d)
        if not isinstance(c, dict) or not c:
            continue
        def role(name, c=c):
            if name in c:
                r = c[name]
                if isinstance(r, str): return r
                v = r.get(mode) or r.get('dark') or r.get('default') or r.get('light')
                if isinstance(v, dict): v = v.get('color')
                return v if isinstance(v, str) else None
            m = c.get(mode) or c.get('dark')
            if isinstance(m, dict) and isinstance(m.get(name), str):
                return m[name]
            return None
        if role('surface') and role('primary'):
            return role
    return None

def load_pywal():
    try:
        return json.load(open(os.path.join(H, 'colors.json')))
    except Exception:
        return None

def pywal_palette(d):
    sp = d['special']; src = d['colors']
    if light:
        bg = flip(sp['background'], 0.90, 0.96)
        fg = flip(sp['foreground'], 0.10, 0.22)
        cols = {}
        for i in range(16):
            k = 'color%d' % i; v = src[k]
            if i == 0:    cols[k] = flip(v, 0.80, 0.92)
            elif i == 8:  cols[k] = flip(v, 0.50, 0.64)
            elif i == 7:  cols[k] = flip(v, 0.18, 0.32)
            elif i == 15: cols[k] = flip(v, 0.06, 0.18)
            elif i < 8:   cols[k] = flip(v, 0.26, 0.42, 1.2)
            else:         cols[k] = flip(v, 0.32, 0.48, 1.2)
        cur = fg
    else:
        bg = sp['background']; fg = sp['foreground']
        cols = dict((('color%d' % i), src['color%d' % i]) for i in range(16))
        cur = sp.get('cursor', fg)
    return bg, fg, cur, cols

def matugen_palette(role):
    bg = role('surface')
    fg = role('on_surface') or ('#1b1b1f' if light else '#e4e1e6')
    hp, _, sp_ = hls(role('primary'))
    sat = max(0.30, min(0.65, sp_))
    drift = [0.0, 0.012, -0.012, 0.024, -0.024, 0.0]
    satk  = [1.00, 0.85, 0.70, 0.90, 0.75, 0.55]
    nsat = min(0.18, sat * 0.35)
    if light:
        norm = [0.44 - 0.03 * i for i in range(6)]
        brig = [0.38 - 0.03 * i for i in range(6)]
        c0 = mk(hp, hls(bg)[1] - 0.10, nsat)
        c8 = mk(hp, 0.54, nsat)
        c7 = mk(hp, 0.30, nsat)
        c15 = mk(hp, 0.12, nsat)
    else:
        norm = [0.58 + 0.04 * i for i in range(6)]
        brig = [0.68 + 0.04 * i for i in range(6)]
        c0 = mk(hp, hls(bg)[1] + 0.08, nsat)
        c8 = mk(hp, 0.48, nsat)
        c7 = mk(hp, 0.80, nsat)
        c15 = mk(hp, 0.94, nsat)
    cols = {'color0': c0, 'color7': ensure(c7, bg, 7.0), 'color8': ensure(c8, bg, 3.0), 'color15': ensure(c15, bg, 12.0)}
    for i in range(6):
        cols['color%d' % (i + 1)] = ensure(mk(hp + drift[i], norm[i], sat * satk[i]), bg, 4.5)
        cols['color%d' % (i + 9)] = ensure(mk(hp + drift[i], brig[i], min(1.0, sat * satk[i] * 1.05)), bg, 6.0)
    fg = ensure(fg, bg, 9.0)
    if light:
        cava = [mk(hp, 0.30, sat), mk(hp, 0.42, sat), mk(hp, 0.56, sat * 0.9)]
    else:
        cava = [mk(hp, 0.80, sat), mk(hp, 0.64, sat), mk(hp, 0.46, sat * 0.9)]
    return bg, fg, fg, cols, cava

pw = load_pywal()
mt = load_matugen() if tmode != 'pywal' else None
cava = None
if tmode == 'matugen' and mt:
    bg, fg, cur, cols, cava = matugen_palette(mt)
elif pw:
    bg, fg, cur, cols = pywal_palette(pw)
    if tmode == 'matugen_bg' and mt:
        bg = mt('surface')
        bh, bl, bs = hls(bg)
        cols['color0'] = mk(bh, bl + (-0.10 if light else 0.08), min(bs, 0.25))
        for i in range(1, 16):
            if i == 8:   t = 3.0
            elif i in (7, 15): t = 7.0
            elif i < 8:  t = 4.5
            else:        t = 6.0
            cols['color%d' % i] = ensure(cols['color%d' % i], bg, t)
        fg = ensure(fg, bg, 9.0)
        cur = ensure(cur, bg, 4.5)
elif mt:
    bg, fg, cur, cols, cava = matugen_palette(mt)
else:
    sys.exit(0)

NL = chr(10)
sel = cols['color8'] if tmode != 'pywal' else fg
lines = ['background ' + bg, 'foreground ' + fg, 'cursor ' + cur,
         'cursor_text_color ' + bg, 'selection_background ' + sel,
         'selection_foreground ' + (fg if tmode != 'pywal' else bg)]
lines += ['color%d %s' % (i, cols['color%d' % i]) for i in range(16)]
os.makedirs(H, exist_ok=True)
with open(os.path.join(H, 'colors-kitty.conf'), 'w') as f:
    f.write(NL.join(lines) + NL)

cava_path = os.path.join(H, 'term-cava.txt')
if tmode != 'pywal':
    if cava:
        v = cava + [bg]
    else:
        acc = sorted([cols['color%d' % i] for i in range(9, 15)], key=lum)
        if light:
            acc = acc[::-1]
        v = [acc[-1], acc[len(acc) // 2], acc[0], bg]
    with open(cava_path, 'w') as f:
        f.write(' '.join(v) + NL)
elif os.path.exists(cava_path):
    os.remove(cava_path)

E = chr(27); ST = E + chr(92)
seq = ''.join(E + ']4;%d;%s' % (i, cols['color%d' % i]) + ST for i in range(16))
seq += E + ']10;' + fg + ST + E + ']11;' + bg + ST + E + ']12;' + cur + ST
with open(os.path.join(H, 'sequences'), 'w') as f:
    f.write(seq)
for t in glob.glob('/dev/pts/[0-9]*'):
    try:
        with open(t, 'w') as f:
            f.write(seq)
    except Exception:
        pass
