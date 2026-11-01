#!/usr/bin/env bash
# Individual CPU / GPU performance levels (Settings > System).
#   system_perf.sh get                     -> CPU:<lvl>  GPU:<lvl>
#   system_perf.sh cpu <low|medium|high>   -> power-profiles-daemon
#   system_perf.sh gpu <low|medium|high>   -> LACT (AMD)
# <lvl> = low|medium|high, or none (tool missing) / nodev / err
D="$(dirname "$0")"
LOG="$HOME/.cache/qs-perf.log"; mkdir -p "$HOME/.cache"

cpu_get() {
  if ! command -v powerprofilesctl >/dev/null 2>&1; then echo "CPU:none"; return; fi
  case "$(powerprofilesctl get 2>/dev/null)" in
    power-saver) echo "CPU:low" ;;
    balanced)    echo "CPU:medium" ;;
    performance) echo "CPU:high" ;;
    *)           echo "CPU:err" ;;
  esac
}
gpu_get() {
  if [ -S /run/lactd.sock ] && command -v python3 >/dev/null 2>&1; then
    python3 "$D/lact_gpu_level.py" get 2>>"$LOG"
  else
    echo "GPU:none"
  fi
}

case "$1" in
  get) cpu_get; gpu_get ;;
  cpu)
    case "$2" in low) PPD=power-saver ;; high) PPD=performance ;; *) PPD=balanced ;; esac
    if command -v powerprofilesctl >/dev/null 2>&1; then
      powerprofilesctl set "$PPD" >>"$LOG" 2>&1 || { echo "CPU:err"; exit 0; }
    fi
    cpu_get ;;
  gpu)
    case "$2" in low) L=low ;; high) L=high ;; *) L=auto ;; esac
    if [ -S /run/lactd.sock ] && command -v python3 >/dev/null 2>&1; then
      R="$(python3 "$D/lact_gpu_level.py" "$L" 2>>"$LOG")"
      case "$R" in GPU:err|GPU:nodev) echo "$R" ;; *) gpu_get ;; esac
    else
      echo "GPU:none"
    fi ;;
esac
