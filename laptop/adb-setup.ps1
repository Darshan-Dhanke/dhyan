# Optional one-time phone prep from Windows PowerShell with adb on PATH.
# Needs: USB or wireless debugging enabled and authorised, Termux + Termux:API installed.
#   .\adb-setup.ps1              (uses the only connected device)
#   .\adb-setup.ps1 -Serial XYZ  (pick a device from `adb devices`)
param([string]$Serial = "")
$a = @(); if ($Serial) { $a = @("-s", $Serial) }
function Invoke-Adb { & adb @a @args }

Write-Host "1) Stop Android 12+ from killing Termux's background processes"
Invoke-Adb shell settings put global settings_enable_monitor_phantom_procs false
Invoke-Adb shell device_config set_sync_disabled_for_tests persistent
Invoke-Adb shell device_config put activity_manager max_phantom_processes 2147483647

Write-Host "2) Permissions"
foreach ($p in "READ_EXTERNAL_STORAGE","WRITE_EXTERNAL_STORAGE","POST_NOTIFICATIONS") {
  Invoke-Adb shell pm grant com.termux "android.permission.$p" 2>$null
}
foreach ($p in "CAMERA","RECORD_AUDIO","ACCESS_FINE_LOCATION","ACCESS_COARSE_LOCATION","POST_NOTIFICATIONS") {
  Invoke-Adb shell pm grant com.termux.api "android.permission.$p" 2>$null
}

Write-Host "3) Battery: let Termux run in the background"
foreach ($pkg in "com.termux","com.termux.api") {
  Invoke-Adb shell dumpsys deviceidle whitelist "+$pkg" | Out-Null
  Invoke-Adb shell cmd appops set $pkg RUN_IN_BACKGROUND allow
}

Write-Host ""
Write-Host ("phantom-process monitor: " + (Invoke-Adb shell settings get global settings_enable_monitor_phantom_procs))
Write-Host "Done. Now open Termux on the phone and run install.sh."
