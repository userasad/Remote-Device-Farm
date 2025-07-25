param(
  [string]$ConfigPath = "$PSScriptRoot/../config/lab_config.json"
)
$cfg = Get-Content $ConfigPath | ConvertFrom-Json
$availableAvds = & avdmanager list avd | Select-String 'Name:' | ForEach-Object { ($_ -split ':')[1].Trim() }

Write-Host "Available AVDs:" -ForegroundColor Cyan
$availableAvds | ForEach-Object { Write-Host "> $_" }

$selected = Read-Host "Enter the name of the AVD to start"
if ($availableAvds -contains $selected) {
    Start-Process emulator -ArgumentList "-avd $selected -no-snapshot-load" -WindowStyle Minimized
    Write-Host "Started AVD: $selected" -ForegroundColor Green
} else {
    Write-Warning "AVD '$selected' not found. Please check the name and try again."
}
