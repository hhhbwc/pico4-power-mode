#!/system/bin/sh
# PICO 4 Power Mode Tuner - apply/restore scheduling (v1.4)
# usage: tune.sh 2         -> performance tuning (CPU/GPU governor, scheduler latencies, tracking nice)
#        tune.sh 0|1       -> restore stock scheduling
#        tune.sh niceperf  -> DEFER mode: Pico3dResolution owns gov/sched; only tracking nice -10
#        tune.sh niceoff   -> DEFER mode: Pico3dResolution owns gov/sched; only tracking nice restore
# Migrated from the pico4-trackerlimit performance/extreme flavors:
#   CPU governor -> performance ; GPU governor -> performance ;
#   kernel sched latency 5ms/1ms ; tracking service + threads nice -10
# (Skipped in migration: IO scheduler - only noop/cfq available on this kernel;
#  persist.pvr.performance_mode / sys.pxr.cpu.level - verified no effect.)
RUNDIR=/data/adb/pico_power_tuner
mkdir -p "$RUNDIR"
MODE="${1:-1}"
LOG="$RUNDIR/tune.log"
TS=$(date "+%Y-%m-%d %H:%M:%S")

log() { echo "$TS $1" >> "$LOG"; }

set_gov() {
  n=0; ok=0
  for c in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    [ -f "$c" ] || continue
    n=$((n+1))
    echo "$1" > "$c" 2>/dev/null
    [ "$(cat "$c" 2>/dev/null)" = "$1" ] && ok=$((ok+1))
  done
  echo "cpu=$1($ok/$n)"
}

set_gpu_gov() {
  f=/sys/class/kgsl/kgsl-3d0/devfreq/governor
  [ -f "$f" ] || { echo "gpu=missing"; return; }
  echo "$1" > "$f" 2>/dev/null
  echo "gpu=$1(now:$(cat "$f" 2>/dev/null))"
}

renice_tracking() {
  # $1 = target nice. NOTE: toybox/busybox renice -n are INCREMENT semantics
  # on this ROM, so compute per-thread increments from live values (idempotent).
  # cut instead of busybox awk: this unit's awk can SIGSEGV when a thread exits
  # between ls and the read.
  pid=$(pidof pvrtrackingservice 2>/dev/null)
  [ -n "$pid" ] || { echo "nice=n/a"; return; }
  nice_of() { cut -d' ' -f19 "$1" 2>/dev/null; }
  set_one() {
    for tid in $(ls /proc/$pid/task 2>/dev/null); do
      cur=$(nice_of /proc/$tid/stat)
      [ -n "$cur" ] || continue
      inc=$(( $1 - cur ))
      [ "$inc" -ne 0 ] && renice -n "$inc" -p "$tid" >/dev/null 2>&1
    done
  }
  set_one "$1"
  set_one "$1"   # second pass: only fixes stragglers (inc=0 skips)
  echo "nice=$1(now:$(nice_of /proc/$pid/stat))"
}

if [ "$MODE" = "2" ]; then
  msg="APPLY perf mode=2"
  r1=$(set_gov performance)
  r2=$(set_gpu_gov performance)
  echo 5000000 > /proc/sys/kernel/sched_latency_ns 2>/dev/null
  echo 1000000 > /proc/sys/kernel/sched_min_granularity_ns 2>/dev/null
  r3="sched=$(cat /proc/sys/kernel/sched_latency_ns 2>/dev/null)/$(cat /proc/sys/kernel/sched_min_granularity_ns 2>/dev/null)"
  r4=$(renice_tracking -10)
elif [ "$MODE" = "niceperf" ]; then
  msg="DEFER to Pico3dResolution (relay present, perf flag) - gov/sched untouched"
  r1="cpu=defer"; r2="gpu=defer"; r3="sched=defer"
  r4=$(renice_tracking -10)
elif [ "$MODE" = "niceoff" ]; then
  msg="DEFER to Pico3dResolution (relay present, stock flags) - gov/sched untouched"
  r1="cpu=defer"; r2="gpu=defer"; r3="sched=defer"
  r4=$(renice_tracking 0)
else
  msg="RESTORE stock"
  r1=$(set_gov schedutil)
  r2=$(set_gpu_gov msm-adreno-tz)
  echo 10000000 > /proc/sys/kernel/sched_latency_ns 2>/dev/null
  echo 3000000 > /proc/sys/kernel/sched_min_granularity_ns 2>/dev/null
  r3="sched=$(cat /proc/sys/kernel/sched_latency_ns 2>/dev/null)/$(cat /proc/sys/kernel/sched_min_granularity_ns 2>/dev/null)"
  r4=$(renice_tracking 0)
fi
log "$msg mode=$MODE | $r1 | $r2 | $r3 | $r4"

# rotate log
if [ -f "$LOG" ] && [ "$(wc -l < "$LOG" 2>/dev/null)" -gt 400 ]; then
  tail -n 200 "$LOG" > "$LOG.tmp" 2>/dev/null && mv "$LOG.tmp" "$LOG"
fi
exit 0
