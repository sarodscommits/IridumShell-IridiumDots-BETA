#!/usr/bin/env bash
# Streams rows of the newest MangoHud CSV log
D="$HOME/.cache/mangohud-logs"; mkdir -p "$D"
cur=""
while true; do
  f=$(ls -t "$D"/*.csv 2>/dev/null | grep -v '_summary\.csv$' | head -n 1)
  if [ -n "$f" ] && [ "$f" != "$cur" ]; then
    cur="$f"
    echo "FILE:$(basename "$f" .csv)"
    tail -n 0 -F --pid=$$ "$cur" 2>/dev/null &
  fi
  sleep 2
done
