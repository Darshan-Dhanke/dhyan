#!/usr/bin/env bash
# Optional one-time phone prep from a computer with adb (Linux/macOS/Git Bash).
# Needs: USB or wireless debugging enabled and authorised, Termux + Termux:API installed.
#   ./adb-setup.sh            (uses the only connected device)
#   ./adb-setup.sh SERIAL     (pick a device from `adb devices`)
set -e
export MSYS_NO_PATHCONV=1   # Git Bash on Windows: don't rewrite /sdcard paths
ADB="adb"; [ -n "${1:-}" ] && ADB="adb -s $1"

echo "1) Stop Android 12+ from killing Termux's background processes"
$ADB shell settings put global settings_enable_monitor_phantom_procs false || true
$ADB shell device_config set_sync_disabled_for_tests persistent || true
$ADB shell device_config put activity_manager max_phantom_processes 2147483647 || true

echo "2) Permissions"
for p in READ_EXTERNAL_STORAGE WRITE_EXTERNAL_STORAGE POST_NOTIFICATIONS; do
  $ADB shell pm grant com.termux android.permission.$p 2>/dev/null || true
done
for p in CAMERA RECORD_AUDIO ACCESS_FINE_LOCATION ACCESS_COARSE_LOCATION POST_NOTIFICATIONS; do
  $ADB shell pm grant com.termux.api android.permission.$p 2>/dev/null || true
done

echo "3) Battery: let Termux run in the background"
for pkg in com.termux com.termux.api; do
  $ADB shell dumpsys deviceidle whitelist +$pkg >/dev/null
  $ADB shell cmd appops set $pkg RUN_IN_BACKGROUND allow || true
done

echo
echo "phantom-process monitor: $($ADB shell settings get global settings_enable_monitor_phantom_procs)"
echo "Done. Now open Termux on the phone and run install.sh."
