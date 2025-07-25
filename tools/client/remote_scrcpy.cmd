@echo off
:: =============================================================================
:: REMOTE_SCRCPY.CMD
:: -----------------------------------------------------------------------------
:: This script mirrors a remote Android device's screen using Scrcpy.
::
:: PRE-REQUISITES:
:: A remote session must be active. Run 'start_session.cmd' first.
:: =============================================================================

setlocal EnableDelayedExpansion
set "SCRIPT_DIR=%~dp0"
set "WORKSPACE_ROOT=%SCRIPT_DIR%..\.."
set "ENV_FILE=%WORKSPACE_ROOT%\allocated_ports.env"

:: -----------------------------------------------------------------------------
::  1. CHECK FOR ACTIVE SESSION
:: -----------------------------------------------------------------------------
if not exist "%ENV_FILE%" (
    echo [ERROR] No active remote session found.
    echo [ERROR] Please run 'start_session.cmd' first to begin a session.
    pause
    exit /b
)
for /f "tokens=2 delims==" %%A in ('findstr "SCRCPY_PORT" "%ENV_FILE%"') do set "SCRCPY_PORT=%%A"

if not defined SCRCPY_PORT (
    echo [ERROR] Could not read SCRCPY_PORT from session file.
    echo [ERROR] Please try running 'start_session.cmd' again.
    pause
    exit /b
)

:: -----------------------------------------------------------------------------
::  2. LIST DEVICES AND GET USER CHOICE
:: -----------------------------------------------------------------------------
echo [INFO] Fetching available devices from the remote server...
adb devices >"%TEMP%\scrcpy_devices.txt" 2>&1
if errorlevel 1 (
    type "%TEMP%\scrcpy_devices.txt"
    echo [ERROR] Failed to list devices. Check ADB connection and server IP.
    pause
    del "%TEMP%\scrcpy_devices.txt"
    exit /b
)

set "device_count=0"
echo.
echo Available devices:
for /f "tokens=1" %%D in ('type "%TEMP%\scrcpy_devices.txt" ^| findstr /r "device$"') do (
    set /a device_count+=1
    set "DEVICE_ID_!device_count!=%%D"
    echo   !device_count!. %%D
)

if !device_count! equ 0 (
    echo [ERROR] No devices found or connected.
    type "%TEMP%\scrcpy_devices.txt"
    del "%TEMP%\scrcpy_devices.txt"
    pause
    exit /b
)
del "%TEMP%\scrcpy_devices.txt"
echo.

set "choice="
set /p "choice=Enter the number of the AVD to mirror: "

if not defined choice (
    echo [ERROR] No selection made.
    pause
    exit /b
)

set "valid_choice="
for /l %%N in (1,1,!device_count!) do (
    if "!choice!"=="%%N" (
        for /f "tokens=*" %%V in ("!DEVICE_ID_%%N!") do set "DEVICE_ID=%%V"
        set "valid_choice=true"
    )
)

if not defined valid_choice (
    echo [ERROR] Invalid selection. Please enter a number from the list.
    pause
    exit /b
)

:: -----------------------------------------------------------------------------
::  3. RUN SCRCPY
:: -----------------------------------------------------------------------------
echo [INFO] Starting Scrcpy for device !DEVICE_ID!
echo.

scrcpy -s !DEVICE_ID! --port=!SCRCPY_PORT! --no-audio
if errorlevel 1 (
    echo [ERROR] scrcpy failed to start.
    pause
    exit /b
)
pause
