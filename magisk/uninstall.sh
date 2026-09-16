#!/system/bin/sh
# PICO 4 Power Mode Tuner - uninstall cleanup
RUNDIR=/data/adb/pico_power_tuner
MODDIR=${0%/*}
sh "$MODDIR/kill_daemon.sh" 2>/dev/null
sh "$MODDIR/tune.sh" 1
rm -rf "$RUNDIR"
echo "PICO 4 Power Mode Tuner removed - stock scheduling restored."
exit 0
