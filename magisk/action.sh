#!/system/bin/sh
# PICO 4 Power Mode Tuner - Magisk action button: status display (v1.4)
RUNDIR=/data/adb/pico_power_tuner
RELAY=/data/local/tmp/res3d_pwr.relay
eb=$(getprop persist.pvr.config.eyebuffer_width)
pa=$(getprop pico_power_coord_v2_perf_active)
pl=$(settings get global powerlevel 2>/dev/null)
owner=$(settings get global pico_power_coord_v2_effective_owner 2>/dev/null)
res3d=$(pm path com.hamer.res3d >/dev/null 2>&1 && echo installed || echo absent)
relay_state="absent"
[ -f "$RELAY" ] && relay_state=$(cat "$RELAY" 2>/dev/null)
cpu_gov=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)
gpu_gov=$(cat /sys/class/kgsl/kgsl-3d0/devfreq/governor 2>/dev/null)
tp=$(pidof pvrtrackingservice)
tn="n/a"; [ -n "$tp" ] && tn=$(cut -d' ' -f19 /proc/$tp/stat 2>/dev/null)
pid=$(cat "$RUNDIR/daemon.pid" 2>/dev/null)
alive="no"; [ -n "$pid" ] && [ -d "/proc/$pid" ] && alive="yes"
echo "=============================================="
echo " PICO 4 Power Mode Tuner v1.4"
echo "=============================================="
echo " Pico3dResolution : $res3d"
echo " res3d relay      : $relay_state"
echo " powerlevel       : ${pl:-<empty>}"
echo " coord owner      : ${owner:-<empty>}"
if [ "$relay_state" != "absent" ] && [ "$res3d" = "installed" ]; then
  echo " ownership        : relay executor (res3d relay is the source of truth)"
  echo "                    this tuner applies cpu/gpu/latency + tracking nice directly"
  case "$owner" in
    power:2) echo " relay profile    : performance (PowerMode active)" ;;
    *)       echo " relay profile    : from relay modes (222=stock, 111=performance)" ;;
  esac
else
  if [ "$pl" = "2" ] || [ "$pa" = "1" ]; then
    echo " mode signal      : powerlevel/perf_active -> PERF tuning ON"
  elif [ "$eb" = "2448" ]; then
    echo " mode signal      : eyebuffer=$eb -> PERF tuning ON (legacy signal)"
  else
    echo " mode signal      : powerlevel=${pl:-<empty>} perf_active=${pa:-<empty>} eyebuffer=${eb:-<empty>} -> stock scheduling"
  fi
fi
echo " cpu0 governor    : $cpu_gov"
echo " gpu governor     : $gpu_gov"
echo " tracking nice    : $tn"
echo " daemon           : pid=$pid alive=$alive"
echo "----------------------------------------------"
echo " last tune events:"
tail -n 4 "$RUNDIR/tune.log" 2>/dev/null
echo "=============================================="
exit 0
