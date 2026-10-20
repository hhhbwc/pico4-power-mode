#!/system/bin/sh
# PICO 4 Power Mode Tuner - daemon (v1.4)
# Ownership protocol:
#   1. Pico3dResolution (com.hamer.res3d) owns CPU/GPU/sched/pwrlevels while its
#      relay exists. When Performance Mode is active this daemon temporarily
#      replaces the relay with a performance profile (saving the user's relay
#      first) and restores it when Performance Mode ends.
#   2. Without res3d, Performance Mode (Settings.Global powerlevel=2, the v1.3
#      perf_active prop, or the legacy eyebuffer=2448 signal) is applied here.
#   3. At 120 Hz (persist.pvr.display.type=jdi493120) the eyebuffer is pinned to
#      native 2160x2160 because PowerMode's 2448/1504 values exceed the 120 Hz
#      GPU budget. V-Sleep keeps ownership of the eyebuffer while it restores.
RUNDIR=/data/adb/pico_power_tuner
MODDIR=${0%/*}
RELAY=/data/local/tmp/res3d_pwr.relay
SAVED=$RUNDIR/res3d_relay.saved
PERF_RELAY="0:6:1:1:1"
mkdir -p "$RUNDIR"

res3d_ok=-1   # -1 unknown, 1 installed, 0 absent
res3d_installed() {
  [ "$res3d_ok" = "1" ] && return 0
  [ "$res3d_ok" = "0" ] && return 1
  if pm path com.hamer.res3d >/dev/null 2>&1; then res3d_ok=1; return 0; fi
  res3d_ok=0; return 1
}

vsleep_active() {
  [ "$(settings get global pico_power_coord_v2_effective_owner 2>/dev/null)" = "vsleep" ] && return 0
  [ "$(settings get global pico_power_coord_v2_phase 2>/dev/null)" = "restoring" ] && return 0
  [ "$(settings get global pico_vsleep_enabled 2>/dev/null)" = "1" ] && return 0
  return 1
}

power_mode_perf() {
  [ "$(settings get global powerlevel 2>/dev/null)" = "2" ] && return 0
  [ "$(getprop pico_power_coord_v2_perf_active 2>/dev/null)" = "1" ] && return 0
  case "$(settings get global pico_power_coord_v2_effective_owner 2>/dev/null)" in
    power:2) return 0 ;;
  esac
  # Legacy v1.2 signal only when res3d is absent (otherwise the relay is truth).
  if ! res3d_installed; then
    [ "$(getprop persist.pvr.config.eyebuffer_width 2>/dev/null)" = "2448" ] && return 0
  fi
  return 1
}

guard_120hz() {
  [ "$(getprop persist.pvr.display.type 2>/dev/null)" = "jdi493120" ] || return 0
  vsleep_active && return 0
  w=$(getprop persist.pvr.config.eyebuffer_width 2>/dev/null)
  h=$(getprop persist.pvr.config.eyebuffer_height 2>/dev/null)
  if [ "$w" != "2160" ] || [ "$h" != "2160" ]; then
    setprop persist.pvr.config.eyebuffer_width 2160
    setprop persist.pvr.config.eyebuffer_height 2160
    echo "$(date '+%F %T') 120Hz guard: eyebuffer ${w:-<empty>}x${h:-<empty>} -> 2160x2160" >> "$RUNDIR/tune.log"
  fi
}

write_relay() {
  current=$(cat "$RELAY" 2>/dev/null)
  [ "$current" = "$1" ] && return 0
  printf '%s\n' "$1" > "$RELAY" 2>/dev/null || return 1
  chmod 666 "$RELAY" 2>/dev/null
  chown 1000:1000 "$RELAY" 2>/dev/null
  echo "$(date '+%F %T') res3d relay: $current -> $1" >> "$RUNDIR/tune.log"
}

# PICO's freezer parks the res3d process when it is idle, which stops its 3 s
# replay loop. Querying its exported provider wakes the process so the relay is
# applied; this does not open the UI.
wake_res3d() {
  res3d_installed || return 0
  content query --uri content://com.hamer.res3d.guardian >/dev/null 2>&1 &
}

# res3d's GuardianService only implements the cpu/gpu/latency == 1 branches; it
# never restores 2 (stock). Executing the relay here as well makes the result
# independent of that bug and of the freezer.
apply_relay_profile() {
  [ -f "$RELAY" ] || return 0
  rl=$(cat "$RELAY" 2>/dev/null)
  max=$(echo "$rl" | cut -d':' -f1)
  min=$(echo "$rl" | cut -d':' -f2)
  cpu=$(echo "$rl" | cut -d':' -f3)
  gpu=$(echo "$rl" | cut -d':' -f4)
  lat=$(echo "$rl" | cut -d':' -f5)
  case "$max" in ''|*[!0-9]*) ;; *) echo "$max" > /sys/class/kgsl/kgsl-3d0/max_pwrlevel 2>/dev/null ;; esac
  case "$min" in ''|*[!0-9]*) ;; *) echo "$min" > /sys/class/kgsl/kgsl-3d0/min_pwrlevel 2>/dev/null ;; esac
  case "$gpu" in
    1) echo 0 > /sys/class/kgsl/kgsl-3d0/default_pwrlevel 2>/dev/null
       echo 0 > /sys/class/kgsl/kgsl-3d0/throttling 2>/dev/null ;;
    2) echo 6 > /sys/class/kgsl/kgsl-3d0/default_pwrlevel 2>/dev/null
       echo 1 > /sys/class/kgsl/kgsl-3d0/throttling 2>/dev/null ;;
  esac
  case "$cpu$gpu$lat" in
    222) sh "$MODDIR/tune.sh" 1 ;;
    111) sh "$MODDIR/tune.sh" 2 ;;
    *)   sh "$MODDIR/tune.sh" niceoff ;;
  esac
}

last=""
last_relay=""
while true; do
  guard_120hz
  if [ -f "$SAVED" ] && ! res3d_installed; then
    rm -f "$SAVED"
  fi

  perf=0
  power_mode_perf && perf=1

  cur=1
  if [ -f "$RELAY" ] && grep -q ':' "$RELAY" 2>/dev/null && res3d_installed; then
    if [ "$perf" = "1" ]; then
      if [ ! -f "$SAVED" ]; then
        cp "$RELAY" "$SAVED" 2>/dev/null && chmod 644 "$SAVED" 2>/dev/null
      fi
      write_relay "$PERF_RELAY"
      cur=3   # defer + tracking nice (perf)
    else
      if [ -f "$SAVED" ]; then
        saved=$(cat "$SAVED" 2>/dev/null)
        case "$saved" in *:*) write_relay "$saved" ;; esac
        rm -f "$SAVED"
      fi
      cur=4   # defer + tracking nice restore
    fi
  else
    [ "$perf" = "1" ] && cur=2
  fi

  relay_now=$(cat "$RELAY" 2>/dev/null)
  changed=0
  [ "$cur" != "$last" ] && changed=1
  case "$cur" in
    3|4) [ "$relay_now" != "$last_relay" ] && changed=1 ;;
  esac
  if [ "$changed" = "1" ]; then
    case "$cur" in
      3|4) apply_relay_profile ;;
      2) sh "$MODDIR/tune.sh" 2 ;;
      *) sh "$MODDIR/tune.sh" 1 ;;
    esac
    case "$cur" in
      3|4) wake_res3d ;;
    esac
    last="$cur"
    last_relay="$relay_now"
  fi
  sleep 2
done
