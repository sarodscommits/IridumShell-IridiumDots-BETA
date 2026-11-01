#!/usr/bin/env bash
# Full screenshot of the focused monitor. Args: <title> <app name>
D=$(xdg-user-dir PICTURES 2>/dev/null); [ -d "$D" ] || D="$HOME/Pictures"; D="$D/Screenshots"; mkdir -p "$D"
F="$D/screenshot-$(date +%Y%m%d-%H%M%S).png"
MON=$(hyprctl monitors -j 2>/dev/null | jq -r '[.[]|select(.focused)][0].name // empty' 2>/dev/null)
if [ -n "$MON" ]; then grim -o "$MON" "$F"; else grim "$F"; fi
[ -s "$F" ] || exit 1
wl-copy --type image/png < "$F" >/dev/null 2>&1 &
notify-send -a "$2" -i "$F" "$1" "$F"
