@echo off
:: Elevate to administrator if needed
net session >nul 2>&1
if errorlevel 1 (
    echo Requesting administrative privileges...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)
setlocal EnableDelayedExpansion
set "SCRIPT_DIR=%~dp0"
set "WORKSPACE_ROOT=%SCRIPT_DIR%..\.."
set "CONFIG_FILE=%WORKSPACE_ROOT%\config\lab_config.json"

:: Debug: Show script and config paths
echo [DEBUG] SCRIPT_DIR: %SCRIPT_DIR%
echo [DEBUG] WORKSPACE_ROOT: %WORKSPACE_ROOT%
echo [DEBUG] CONFIG_FILE: %CONFIG_FILE%

for /f "tokens=2 delims=:," %%A in ('findstr "server_ip" "%CONFIG_FILE%"') do set SERVER_IP=%%~A
for /f "tokens=2 delims=:," %%A in ('findstr "adb_port" "%CONFIG_FILE%"') do set ADB_PORT=%%~A
set "SERVER_IP=!SERVER_IP: =!"
:: Strip any double quotes from the IP string
set "SERVER_IP=!SERVER_IP:"=!"
set "ADB_PORT=!ADB_PORT: =!"

:: Debug: Show loaded config values
echo [DEBUG] SERVER_IP: !SERVER_IP!
echo [DEBUG] ADB_PORT: !ADB_PORT!

rem Load allocated ports
if not exist "%WORKSPACE_ROOT%\allocated_ports.env" (
    echo Ports not allocated. Run allocate_ports.cmd first.
    pause
    exit /b
)
for /f "tokens=2 delims==" %%A in ('findstr "SCRCPY_PORT" "%WORKSPACE_ROOT%\allocated_ports.env"') do set SCRCPY_PORT=%%~A

:: Debug: Show SCRCPY_PORT
echo [DEBUG] SCRCPY_PORT: !SCRCPY_PORT!

:: Point adb to use remote server
set ADB_SERVER_SOCKET=tcp:!SERVER_IP!:!ADB_PORT!
rem Kill any local adb server so next command uses remote socket
taskkill /F /IM adb.exe >nul 2>&1
echo Fetching running AVDs from server !SERVER_IP! ...
where adb >nul 2>&1 || (
    echo [ERROR] adb not found in PATH.
    pause
    exit /b
)
rem List attached devices via remote ADB server
echo Fetching running AVDs from server !SERVER_IP! ...
adb -H !SERVER_IP! -P !ADB_PORT! devices >"%TEMP%\scrcpy_devices.txt" 2>&1
if errorlevel 1 (
    type "%TEMP%\scrcpy_devices.txt"
    echo [ERROR] Failed to list devices. Check adb connection and server IP.
    pause
    del "%TEMP%\scrcpy_devices.txt"
    exit /b
)

rem Process the device list to create a numbered menu
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

rem Get user choice
set "choice="
set /p "choice=Enter the number of the AVD to mirror: "

rem Validate choice
if not defined choice (
    echo [ERROR] No selection made.
    pause
    exit /b
)

rem Check if choice is a number and within range
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

:: Debug: Show DEVICE_ID
echo [DEBUG] Selected DEVICE_ID: !DEVICE_ID!

rem Setup portproxy (requires admin)
netsh interface portproxy delete v4tov4 listenaddress=127.0.0.1 listenport=!SCRCPY_PORT! >nul 2>&1
netsh interface portproxy add v4tov4 listenaddress=127.0.0.1 listenport=!SCRCPY_PORT! connectaddress=!SERVER_IP! connectport=!SCRCPY_PORT!
if errorlevel 1 (
    echo [ERROR] Failed to set up portproxy.
    pause
    exit /b
)

where scrcpy >nul 2>&1
if errorlevel 1 (
    echo [ERROR] scrcpy not found in PATH.
    pause
    exit /b
)

scrcpy -s !DEVICE_ID! --force-adb-forward --port !SCRCPY_PORT! --no-audio
if errorlevel 1 (
    echo [ERROR] scrcpy failed to start.
    pause
    exit /b
)
pause
