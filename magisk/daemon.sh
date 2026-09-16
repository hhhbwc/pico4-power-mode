#!/system/bin/sh
# PICO 4 Power Mode Tuner - daemon
# Derives the current power mode from the module's forced eyebuffer value:
#   2448 -> Performance Mode (powerlevel=2) -> apply performance tuning
#   else -> standard/battery (0/1)         -> restore stock scheduling
RUNDIR=/data/adb/pico_power_tuner
MODDIR=${0%/*}
mkdir -p "$RUNDIR"

last=""
while true; do
  eb=$(getprop persist.pvr.config.eyebuffer_width 2>/dev/null)
  case "$eb" in
    2448) cur=2 ;;
    *)    cur=1 ;;
  esac
  if [ "$cur" != "$last" ]; then
    sh "$MODDIR/tune.sh" "$cur"
    last="$cur"
  fi
  sleep 2
done
