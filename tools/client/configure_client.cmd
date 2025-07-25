@echo off
setlocal EnableDelayedExpansion

:: =============================================================================
:: CONFIGURE_CLIENT.CMD
:: -----------------------------------------------------------------------------
:: This script configures a client machine for the ADB Lab by permanently
:: setting the ADB_SERVER_SOCKET environment variable for the entire system.
::
:: USAGE:
:: Run this script ONCE as Administrator on any new client machine.
:: After running, you MUST restart any open terminals and VS Code for the
:: change to take effect.
:: =============================================================================

:: -----------------------------------------------------------------------------
::  1. ELEVATE TO ADMINISTRATOR
::  This script needs admin rights to set a system-wide environment variable.
:: -----------------------------------------------------------------------------
echo Checking for administrator privileges...
net session >nul 2>&1
if errorlevel 1 (
    echo Requesting administrative privileges to set a system-wide environment variable...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)
echo Success: Running as administrator.
echo.

:: -----------------------------------------------------------------------------
::  2. DEFINE FILE PATHS
:: -----------------------------------------------------------------------------
set "SCRIPT_DIR=%~dp0"
set "WORKSPACE_ROOT=%SCRIPT_DIR%..\.."
set "CONFIG_FILE=%WORKSPACE_ROOT%\config\lab_config.json"

echo [INFO] Workspace Root: "%WORKSPACE_ROOT%"
echo [INFO] Config File: "%CONFIG_FILE%"
echo.

if not exist "%CONFIG_FILE%" (
    echo [ERROR] Configuration file not found at "%CONFIG_FILE%".
    echo [ERROR] Please ensure the config file exists and the script is in the correct directory.
    pause
    exit /b
)

:: -----------------------------------------------------------------------------
::  3. LOAD CONFIGURATION
:: -----------------------------------------------------------------------------
echo [INFO] Loading configuration from lab_config.json...
for /f "usebackq tokens=2 delims=:," %%A in ('findstr "server_ip" "%CONFIG_FILE%"') do set "SERVER_IP=%%~A"
for /f "usebackq tokens=2 delims=:," %%A in ('findstr "adb_port" "%CONFIG_FILE%"') do set "ADB_PORT=%%~A"

:: Clean up the parsed values
set "SERVER_IP=!SERVER_IP: =!"
set "SERVER_IP=!SERVER_IP:"=!"
set "ADB_PORT=!ADB_PORT: =!"
set "ADB_PORT=!ADB_PORT:"=!"

if not defined SERVER_IP (
    echo [ERROR] Could not read 'server_ip' from the config file.
    pause
    exit /b
)
if not defined ADB_PORT (
    echo [ERROR] Could not read 'adb_port' from the config file.
    pause
    exit /b
)

echo [INFO] Server IP found: !SERVER_IP!
echo [INFO] ADB Port found: !ADB_PORT!
echo.

:: -----------------------------------------------------------------------------
::  4. SET THE PERMANENT ENVIRONMENT VARIABLE
:: -----------------------------------------------------------------------------
set "ADB_SOCKET_VALUE=tcp:!SERVER_IP!:!ADB_PORT!"
echo [ACTION] Setting system-wide ADB_SERVER_SOCKET to: !ADB_SOCKET_VALUE!
setx ADB_SERVER_SOCKET "!ADB_SOCKET_VALUE!" /M

if errorlevel 1 (
    echo [ERROR] Failed to set the environment variable. Please ensure you are running as Administrator.
    pause
    exit /b
)

echo.
echo [SUCCESS] The system-wide environment variable 'ADB_SERVER_SOCKET' has been set.
echo.
echo ================================== IMPORTANT ==================================
echo.
echo  You MUST CLOSE and REOPEN any command prompts, PowerShell windows,
echo  and especially VISUAL STUDIO CODE for this change to take effect.
echo.
echo ===============================================================================
echo.
pause
exit /b
