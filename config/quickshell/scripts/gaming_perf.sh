#!/usr/bin/env bash
# Applies a perf profile (low|medium|high). Args: <profile> <shadow 0|1>
P="$1"; SHADOW="$2"
LOG="$HOME/.cache/qs-perf.log"; mkdir -p "$HOME/.cache"; : > "$LOG"
case "$P" in
  low)  PPD=power-saver; GPU=low;  FX=0 ;;
  high) PPD=performance; GPU=high; FX=0 ;;
  *)    P=medium; PPD=balanced; GPU=auto; FX=1 ;;
esac
if command -v powerprofilesctl >/dev/null 2>&1; then
  powerprofilesctl set "$PPD" >>"$LOG" 2>&1 || echo "CPU:err"
  echo "PPD:$(powerprofilesctl get 2>/dev/null)"
else
  echo "CPU:none"
fi
if [ -S /run/lactd.sock ] && command -v python3 >/dev/null 2>&1; then
  python3 "$(dirname "$0")/lact_gpu_level.py" "$GPU" 2>>"$LOG"
else
  echo "GPU:none"
fi
if [ "$FX" = 1 ]; then B=true; A=true; S=$([ "$SHADOW" = 1 ] && echo true || echo false)
else B=false; A=false; S=false; fi
hyprctl eval "hl.config({ decoration = { blur = { enabled = $B }, shadow = { enabled = $S } }, animations = { enabled = $A } })" >/dev/null 2>&1
hyprctl keyword decoration:blur:enabled "$B" >/dev/null 2>&1
hyprctl keyword decoration:shadow:enabled "$S" >/dev/null 2>&1
hyprctl keyword animations:enabled "$A" >/dev/null 2>&1
echo "DONE:$P"
