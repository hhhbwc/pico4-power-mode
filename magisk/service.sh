#!/system/bin/sh
# PICO 4 Power Mode Tuner - service.sh (boot)
# Starts the tuning daemon. The daemon:
#   - re-applies tuning after boot according to the current mode
#   - follows mode changes (poll of persist.pvr.config.eyebuffer_width)
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
exit 0
