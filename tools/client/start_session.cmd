@echo off
:: =============================================================================
:: START_SESSION.CMD
:: -----------------------------------------------------------------------------
:: This script prepares a client machine for a remote development session.
:: It allocates available local ports for Scrcpy and the Flutter VM Service,
:: then creates the necessary network port forwarding rules to the remote
:: server.
::
:: USAGE:
:: Run this script ONCE at the beginning of your development session.
:: It requires Administrator privileges to modify network settings.
:: =============================================================================

:: -----------------------------------------------------------------------------
::  1. ELEVATE TO ADMINISTRATOR
:: -----------------------------------------------------------------------------
net session >nul 2>&1
if errorlevel 1 (
    echo [INFO] Requesting administrative privileges to set up port forwarding...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)
setlocal EnableDelayedExpansion

:: -----------------------------------------------------------------------------
::  2. DEFINE FILE PATHS & LOAD CONFIG
:: -----------------------------------------------------------------------------
set "SCRIPT_DIR=%~dp0"
set "WORKSPACE_ROOT=%SCRIPT_DIR%..\.."
set "CONFIG_FILE=%WORKSPACE_ROOT%\config\lab_config.json"

echo [INFO] Loading configuration from: %CONFIG_FILE%

if not exist "%CONFIG_FILE%" (
    echo [ERROR] Configuration file not found: "%CONFIG_FILE%"
    pause
    exit /b
)

echo [INFO] Using PowerShell to reliably parse JSON configuration...

:: Create a temporary PowerShell script to avoid complex quoting issues in cmd.exe
set "TMP_PS_SCRIPT=%TEMP%\_tmp_parse_config.ps1"
(
    echo try {
    echo     $config = Get-Content -Path '%CONFIG_FILE%' -Raw -ErrorAction Stop ^| ConvertFrom-Json -ErrorAction Stop
    echo     Write-Output "$($config.server_ip) $($config.vmservice_ports_start) $($config.scrcpy_ports_start)"
    echo } catch {
    echo     Write-Error "Failed to parse JSON: $_"
    echo     exit 1
    echo }
) > "%TMP_PS_SCRIPT%"

:: Execute the script and capture the output
for /f "tokens=1-3" %%a in ('powershell -NoProfile -ExecutionPolicy Bypass -File "%TMP_PS_SCRIPT%"') do (
    set "SERVER_IP=%%a"
    set "VM_PORT_START=%%b"
    set "SCRCPY_PORT_START=%%c"
)

:: Clean up the temporary script
if exist "%TMP_PS_SCRIPT%" del "%TMP_PS_SCRIPT%"

echo [INFO] Remote Server IP: !SERVER_IP!
echo [INFO] VM Service Port Start: !VM_PORT_START!
echo [INFO] Scrcpy Port Start: !SCRCPY_PORT_START!
echo.

:: -----------------------------------------------------------------------------
::  3. VALIDATE AND ALLOCATE PORTS
:: -----------------------------------------------------------------------------
if not defined VM_PORT_START (
    echo [ERROR] Could not read 'vmservice_ports_start' from the config file.
    pause
    exit /b
)
if not defined SCRCPY_PORT_START (
    echo [ERROR] Could not read 'scrcpy_ports_start' from the config file.
    pause
    exit /b
)

echo [INFO] Finding available local ports...
set "VM_PORT=!VM_PORT_START!"
:find_vm_port
netstat -ano | find ":!VM_PORT! " >nul 2>&1
if not errorlevel 1 (
    set /a VM_PORT+=1
    goto find_vm_port
)
echo [OK]   Flutter VM Service Port allocated: !VM_PORT!

set "SCRCPY_PORT=!SCRCPY_PORT_START!"
:find_scrcpy_port
netstat -ano | find ":!SCRCPY_PORT! " >nul 2>&1
if not errorlevel 1 (
    set /a SCRCPY_PORT+=1
    goto find_scrcpy_port
)
echo [OK]   Scrcpy Port allocated: !SCRCPY_PORT!
echo.

:: -----------------------------------------------------------------------------
::  4. SETUP PORT FORWARDING
:: -----------------------------------------------------------------------------
echo [INFO] Setting up port forwarding rules for this session...

:: Delete any previous rule to ensure a clean state
netsh interface portproxy delete v4tov4 listenaddress=127.0.0.1 listenport=!VM_PORT! >nul 2>&1
netsh interface portproxy delete v4tov4 listenaddress=127.0.0.1 listenport=!SCRCPY_PORT! >nul 2>&1

:: Add the new rules
netsh interface portproxy add v4tov4 listenaddress=127.0.0.1 listenport=!VM_PORT! connectaddress=!SERVER_IP! connectport=!VM_PORT!
if errorlevel 1 (
    echo [ERROR] Failed to set up portproxy for Flutter.
    pause
    exit /b
)
echo [OK]   Flutter port forwarding enabled: 127.0.0.1:!VM_PORT! --^> !SERVER_IP!:!VM_PORT!

netsh interface portproxy add v4tov4 listenaddress=127.0.0.1 listenport=!SCRCPY_PORT! connectaddress=!SERVER_IP! connectport=!SCRCPY_PORT!
if errorlevel 1 (
    echo [ERROR] Failed to set up portproxy for Scrcpy.
    pause
    exit /b
)
echo [OK]   Scrcpy port forwarding enabled:  127.0.0.1:!SCRCPY_PORT! --^> !SERVER_IP!:!SCRCPY_PORT!
echo.

::  5. SAVE ENVIRONMENT FILE & SET SYSTEM VARIABLE
:: -----------------------------------------------------------------------------
echo [INFO] Saving allocated ports to allocated_ports.env for other scripts...
(
    echo VM_PORT=!VM_PORT!
    echo SCRCPY_PORT=!SCRCPY_PORT!
) > "%WORKSPACE_ROOT%\allocated_ports.env"

echo [INFO] Setting system-wide environment variable for VS Code integration...
setx ADB_LAB_VM_PORT !VM_PORT! >nul

echo.
echo ===============================================================================
echo  REMOTE SESSION IS NOW ACTIVE
echo ===============================================================================
echo.
echo  You can now:
echo    - Run the 'remote_scrcpy.cmd' script to mirror devices.
echo    - For Flutter, proceed to the VS Code setup instructions.
echo.
echo  IMPORTANT: If VS Code was open, you MUST RESTART IT for it to see the
echo             new environment variable needed for debugging.
echo.
echo  These settings will be reset when you restart your computer.
echo ===============================================================================
echo.
pause
