#!/system/bin/sh
# PICO 4 Power Mode Tuner - Magisk action button: status display
RUNDIR=/data/adb/pico_power_tuner
eb=$(getprop persist.pvr.config.eyebuffer_width)
cpu_gov=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)
gpu_gov=$(cat /sys/class/kgsl/kgsl-3d0/devfreq/governor 2>/dev/null)
tp=$(pidof pvrtrackingservice)
tn="n/a"; [ -n "$tp" ] && tn=$(cat /proc/$tp/stat 2>/dev/null | awk '{print $19}')
pid=$(cat "$RUNDIR/daemon.pid" 2>/dev/null)
alive="no"; [ -n "$pid" ] && [ -d "/proc/$pid" ] && alive="yes"
echo "=============================================="
echo " PICO 4 Power Mode Tuner (LSPosed companion)"
echo "=============================================="
if [ "$eb" = "2448" ]; then
  echo " mode signal : eyebuffer=$eb -> PERF tuning ON"
else
  echo " mode signal : eyebuffer=${eb:-<empty>} -> stock scheduling"
fi
echo " cpu0 governor: $cpu_gov"
echo " gpu governor : $gpu_gov"
echo " tracking nice: $tn"
echo " daemon       : pid=$pid alive=$alive"
echo "----------------------------------------------"
echo " last tune events:"
tail -n 4 "$RUNDIR/tune.log" 2>/dev/null
echo "=============================================="
exit 0
