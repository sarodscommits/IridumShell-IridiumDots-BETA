#!/bin/bash
# Accent → Hyprland border + cava. Args: <border> <c1> <c2> <c3> <bg>
bcol="$1"; c1="$2"; c2="$3"; c3="$4"; c0="$5"
if [ -n "$bcol" ]; then
  hyprctl eval "hl.config({ general = { col = { active_border = \"rgba(${bcol}cc)\", inactive_border = \"rgba(${bcol}66)\" } } })" >/dev/null 2>&1
  hyprctl keyword general:col.active_border "rgba(${bcol}cc)" >/dev/null 2>&1
  hyprctl keyword general:col.inactive_border "rgba(${bcol}66)" >/dev/null 2>&1
  mkdir -p "$HOME/.cache/wal"; echo "$bcol" > "$HOME/.cache/wal/border-color.txt"
fi
if [ -f "$HOME/.config/cava/config" ] && [ -n "$c1" ]; then
  sed -i "s/^gradient = .*/gradient = 1/" "$HOME/.config/cava/config"
  sed -i "s/^gradient_count = .*/gradient_count = 3/" "$HOME/.config/cava/config"
  sed -i "s/^gradient_color_1 = .*/gradient_color_1 = '$c1'/" "$HOME/.config/cava/config"
  sed -i "s/^gradient_color_2 = .*/gradient_color_2 = '$c2'/" "$HOME/.config/cava/config"
  sed -i "s/^gradient_color_3 = .*/gradient_color_3 = '$c3'/" "$HOME/.config/cava/config"
  [ -n "$c0" ] && sed -i "s/^background = .*/background = '$c0'/" "$HOME/.config/cava/config"
  pkill -USR1 cava 2>/dev/null
fi
