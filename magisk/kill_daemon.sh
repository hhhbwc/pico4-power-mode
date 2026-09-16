#!/system/bin/sh
# PICO 4 Power Mode Tuner - kill daemon helper
RUNDIR=/data/adb/pico_power_tuner
if [ -f "$RUNDIR/daemon.pid" ]; then
  kill "$(cat "$RUNDIR/daemon.pid")" 2>/dev/null
  rm -f "$RUNDIR/daemon.pid"
fi
# kill stragglers by cmdline match
for p in /proc/[0-9]*; do
  cmdline=$(tr '\0' ' ' < "$p/cmdline" 2>/dev/null)
  case "$cmdline" in
    *pico4_power_tuner/daemon.sh*|*pico4_power_tuner/tune.sh*) kill "${p#/proc/}" 2>/dev/null ;;
  esac
done
exit 0
