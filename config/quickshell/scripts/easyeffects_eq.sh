#!/usr/bin/env bash
# Loads EQ preset $1 into EasyEffects and routes streams through it
PRESET_DIR="$HOME/.config/easyeffects/output"; mkdir -p "$PRESET_DIR"
printf '%s\n' "$1" > "$PRESET_DIR/qs-live.json"
if ! pgrep -x easyeffects >/dev/null 2>&1; then
  nohup easyeffects --gapplication-service >/dev/null 2>&1 & disown
  for i in 1 2 3 4 5 6 7 8 9 10; do pgrep -x easyeffects >/dev/null 2>&1 && break; sleep 0.3; done
  sleep 0.5
fi
easyeffects -l qs-live >/dev/null 2>&1
(easyeffects -b 0 >/dev/null 2>&1 || gsettings set com.github.wwmm.easyeffects bypass false >/dev/null 2>&1 || true)
pactl set-sink-volume easyeffects_sink 100% >/dev/null 2>&1
if command -v pactl >/dev/null 2>&1 && command -v pw-link >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
  HW_SINK_FILE="$HOME/.cache/qs-eq-hw-sink"
  NEWHW_NAME=""
  for i in 1 2 3 4 5; do
    NEWHW_NAME=$(pw-link -l 2>/dev/null | grep -B1 '|<- easyeffects_sink:monitor_' | grep ':playback_FL$' | head -1 | sed 's/:playback_FL$//')
    [ -n "$NEWHW_NAME" ] && break
    sleep 0.3
  done
  if [ -n "$NEWHW_NAME" ]; then
    HW_SINK=$(pw-dump 2>/dev/null | jq -r --arg n "$NEWHW_NAME" '.[] | select(.info.props."node.name"==$n and .type=="PipeWire:Interface:Node") | .id' | head -1)
    if [ -n "$HW_SINK" ]; then
      echo "$HW_SINK" > "$HW_SINK_FILE"
      echo "$NEWHW_NAME" > "$HOME/.cache/qs-eq-hw-sink-name"
      pactl set-sink-mute "$NEWHW_NAME" 0 >/dev/null 2>&1
    fi
  fi
  for i in 1 2 3 4 5 6 7 8 9 10; do pactl list short sinks 2>/dev/null | grep -q easyeffects_sink && break; sleep 0.3; done
  pactl set-default-sink easyeffects_sink >/dev/null 2>&1
  pactl list short sink-inputs 2>/dev/null | cut -f1 | while read -r sid; do
    [ -n "$sid" ] && pactl move-sink-input "$sid" easyeffects_sink >/dev/null 2>&1
  done
fi
