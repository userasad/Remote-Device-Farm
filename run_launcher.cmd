@echo off
setlocal EnableDelayedExpansion

set "WORKSPACE_ROOT=%~dp0"
set "BIN_DIR=%WORKSPACE_ROOT%bin"
set "CLIENT_TOOLS_DIR=%WORKSPACE_ROOT%tools\client"

:: Define script paths
set "SCRIPT_SERVER_1=%BIN_DIR%\start_adb.ps1"
set "SCRIPT_SERVER_2=%BIN_DIR%\start_avds.ps1"
set "SCRIPT_CLIENT_1=%CLIENT_TOOLS_DIR%\configure_client.cmd"
set "SCRIPT_CLIENT_2=%CLIENT_TOOLS_DIR%\allocate_ports.cmd"
set "SCRIPT_CLIENT_3=%CLIENT_TOOLS_DIR%\remote_scrcpy.cmd"
set "SCRIPT_CLIENT_4=%CLIENT_TOOLS_DIR%\remote_flutter_run.cmd"

:main_menu
cls
echo ================================================
echo              ADB Lab Launcher
echo ================================================
echo.
echo   1. Server Operations (For the main PC)
echo   2. Client Operations (For client PCs)
echo.
echo   3. Exit
echo ------------------------------------------------
echo.

set "choice="
set /p "choice=Please enter your choice (1-3): "

if not defined choice (
    echo Invalid choice.
    pause
    goto main_menu
)

if "%choice%"=="1" goto server_menu
if "%choice%"=="2" goto client_menu
if "%choice%"=="3" (
    echo Exiting.
    exit /b
)

echo Invalid choice. Please try again.
pause
goto main_menu


:server_menu
cls
echo ================================================
echo           Server Operations
echo ================================================
echo.
echo   1. (Step 1) Start ADB Server
echo   2. (Step 2) Start Android Virtual Devices (AVDs)
echo.
echo   3. Back to Main Menu
echo ------------------------------------------------
echo.

set "server_choice="
set /p "server_choice=Please enter your choice (1-3): "

if not defined server_choice (
    echo Invalid choice.
    pause
    goto server_menu
)

if "%server_choice%"=="1" (
    echo Running: Start ADB Server...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_SERVER_1%"
    pause
    goto server_menu
)
if "%server_choice%"=="2" (
    echo Running: Start Android Virtual Devices (AVDs)...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_SERVER_2%"
    pause
    goto server_menu
)
if "%server_choice%"=="3" goto main_menu

echo Invalid choice. Please try again.
pause
goto server_menu


:client_menu
cls
echo ================================================
echo           Client Operations
echo ================================================
echo.
echo   1. (Step 1 - Run Once) Configure Client for Remote ADB
echo   2. (Step 2 - Run Per Session) Allocate Network Ports
echo   3. (Step 3) Run Remote Scrcpy
echo   4. (Step 4) Run Remote Flutter
echo.
echo   5. Back to Main Menu
echo ------------------------------------------------
echo.

set "client_choice="
set /p "client_choice=Please enter your choice (1-5): "

if not defined client_choice (
    echo Invalid choice.
    pause
    goto client_menu
)

if "%client_choice%"=="1" (
    echo Running: Configure Client for Remote ADB...
    call "%SCRIPT_CLIENT_1%"
    pause
    goto client_menu
)
if "%client_choice%"=="2" (
    echo Running: Allocate Network Ports...
    call "%SCRIPT_CLIENT_2%"
    pause
    goto client_menu
)
if "%client_choice%"=="3" (
    echo Running: Remote Scrcpy...
    call "%SCRIPT_CLIENT_3%"
    pause
    goto client_menu
)
if "%client_choice%"=="4" (
    echo Running: Remote Flutter...
    call "%SCRIPT_CLIENT_4%"
    pause
    goto client_menu
)
if "%client_choice%"=="5" goto main_menu

echo Invalid choice. Please try again.
pause
goto client_menu
