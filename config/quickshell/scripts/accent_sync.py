#!/usr/bin/env python3
# Prints BORDER/CAVA colors from pywal. Args: <dark|light> <border 0|1> <cava 0|1>
import json, os, sys, colorsys
mode = sys.argv[1]; need_b = sys.argv[2] == '1'; need_c = sys.argv[3] == '1'
d = json.load(open(os.path.expanduser('~/.cache/wal/colors.json')))
cols = [d['colors']['color%d' % i] for i in range(1, 7)]
def rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i+2], 16) / 255.0 for i in (0, 2, 4))
def lum(h):
    r, g, b = rgb(h)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b
def hx(c):
    return '#%02x%02x%02x' % tuple(int(round(max(0.0, min(1.0, v)) * 255)) for v in c)
def flip(h, lo, hi, sat=1.0):
    hh, l, s = colorsys.rgb_to_hls(*rgb(h))
    l = min(hi, max(lo, 1.0 - l))
    return hx(colorsys.hls_to_rgb(hh, l, min(1.0, s * sat)))
light = mode == 'light'
srt = sorted(cols, key=lum)
if need_b:
    b = srt[-1]
    if light:
        b = flip(b, 0.30, 0.45, 1.2)
    print('BORDER ' + b.lstrip('#'))
if need_c:
    bg = d['special']['background']
    hi, mid, lo = srt[-1], srt[len(srt) // 2], srt[0]
    if light:
        v = [flip(hi, 0.22, 0.38, 1.2), flip(mid, 0.32, 0.48, 1.2), flip(lo, 0.45, 0.62, 1.1), flip(bg, 0.90, 0.96)]
    else:
        v = [hi, mid, lo, bg]
    print('CAVA ' + ' '.join(v))
