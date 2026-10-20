#!/system/bin/sh
# PICO 4 Power Mode Tuner - service.sh (boot)
# Starts the tuning daemon (v1.4):
#   - when res3d's relay exists, the tuner is its executor: it applies the relay
#     directly (so the frozen res3d process is not required), and during
#     Performance Mode temporarily substitutes a performance relay
#   - without res3d it applies CPU/GPU/sched tuning directly
#   - at 120 Hz it pins the eyebuffer to 2160 unless V-Sleep owns it
MODDIR=${0%/*}
RUNDIR=/data/adb/pico_power_tuner
mkdir -p "$RUNDIR"

# stop previous daemon (module update safety)
sh "$MODDIR/kill_daemon.sh" 2>/dev/null

# wait for boot to settle (property service / settings ready)
sleep 15

# start daemon (wrapper restarts it if it ever exits)
nohup sh -c "while true; do sh $MODDIR/daemon.sh; sleep 10; done" > "$RUNDIR/daemon.out" 2>&1 &
echo $! > "$RUNDIR/daemon.pid"

# Boot persistence for Pico3dResolution's GuardianService (Vector-independent).
# Vector's Xposed route can miss freshly-added system_server modules, so we
# fire the exact same trigger upstream's hook uses: a content query against
# the app's exported GuardianProvider (spawns the app process -> provider
# onCreate -> GuardianService 3s loop). Falls back to am start-service.
# GuardianService itself is idempotent (isRunning guard), so double triggers
# from a later-working Vector injection are harmless.
(
  sleep 40
  if pm path com.hamer.res3d >/dev/null 2>&1; then
    echo "$(date) res3d present, triggering guardian" >> "$RUNDIR/res3d_boot.log"
    content query --uri content://com.hamer.res3d.guardian >/dev/null 2>&1 \
      || am start-service -n com.hamer.res3d/.GuardianService >/dev/null 2>&1
  fi
) &
exit 0
