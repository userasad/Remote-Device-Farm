@echo off
:: =============================================================================
:: REMOTE_FLUTTER_RUN.CMD (Manual Mode)
:: -----------------------------------------------------------------------------
:: This script provides a manual way to run a Flutter app on a remote device
:: without relying on VS Code's debugger. It is useful for quick tests or
:: for environments where the full IDE is not available.
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
for /f "tokens=2 delims==" %%A in ('findstr "VM_PORT" "%ENV_FILE%"') do set "VM_PORT=%%A"

if not defined VM_PORT (
    echo [ERROR] Could not read VM_PORT from session file.
    echo [ERROR] Please try running 'start_session.cmd' again.
    pause
    exit /b
)

:: -----------------------------------------------------------------------------
::  2. LIST DEVICES AND GET USER CHOICE
:: -----------------------------------------------------------------------------
echo [INFO] Fetching available devices from the remote server...
adb devices >"%TEMP%\flutter_devices.txt" 2>&1
if errorlevel 1 (
    type "%TEMP%\flutter_devices.txt"
    echo [ERROR] Failed to list devices. Check ADB connection and server IP.
    pause
    del "%TEMP%\flutter_devices.txt"
    exit /b
)

set "device_count=0"
echo.
echo Available devices:
for /f "tokens=1" %%D in ('type "%TEMP%\flutter_devices.txt" ^| findstr /r "device$"') do (
    set /a device_count+=1
    set "DEVICE_ID_!device_count!=%%D"
    echo   !device_count!. %%D
)

if !device_count! equ 0 (
    echo [ERROR] No devices found or connected.
    type "%TEMP%\flutter_devices.txt"
    del "%TEMP%\flutter_devices.txt"
    pause
    exit /b
)
del "%TEMP%\flutter_devices.txt"
echo.

set "choice="
set /p "choice=Enter the number of the AVD to run Flutter on: "

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
::  3. RUN FLUTTER
:: -----------------------------------------------------------------------------
echo [INFO] Starting Flutter app on device !DEVICE_ID!
echo [INFO] This will not attach the VS Code debugger. For debugging, use F5 in VS Code.
echo.

flutter run -d !DEVICE_ID! --host-vmservice-port=!VM_PORT! --no-dds
if errorlevel 1 (
    echo [ERROR] flutter run command failed.
    pause
    exit /b
)
pause
