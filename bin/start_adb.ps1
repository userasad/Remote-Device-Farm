# Navigate to script folder
Push-Location $PSScriptRoot
# Restart adb server listening on all interfaces
Stop-Process -Name adb -ErrorAction SilentlyContinue
adb -a start-server
Pop-Location
