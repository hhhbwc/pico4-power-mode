#!/system/bin/sh
# PICO 4 Power Mode Tuner - uninstall cleanup
RUNDIR=/data/adb/pico_power_tuner
RELAY=/data/local/tmp/res3d_pwr.relay
MODDIR=${0%/*}
sh "$MODDIR/kill_daemon.sh" 2>/dev/null
if [ -f "$RUNDIR/res3d_relay.saved" ]; then
  cat "$RUNDIR/res3d_relay.saved" > "$RELAY" 2>/dev/null
  chmod 666 "$RELAY" 2>/dev/null
  chown 1000:1000 "$RELAY" 2>/dev/null
fi
sh "$MODDIR/tune.sh" 1
rm -rf "$RUNDIR"
echo "PICO 4 Power Mode Tuner removed - stock scheduling restored."
exit 0
