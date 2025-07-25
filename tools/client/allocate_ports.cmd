@echo off
:: Check for admin rights
openfiles >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrative privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)
setlocal EnableDelayedExpansion
set "SCRIPT_DIR=%~dp0"
set "WORKSPACE_ROOT=%SCRIPT_DIR%..\.."
set "CONFIG_FILE=%WORKSPACE_ROOT%\config\lab_config.json"

:: Debug: Show paths
echo [DEBUG] SCRIPT_DIR: %SCRIPT_DIR%
echo [DEBUG] WORKSPACE_ROOT: %WORKSPACE_ROOT%
echo [DEBUG] CONFIG_FILE: %CONFIG_FILE%
if not exist "%CONFIG_FILE%" (
    echo [ERROR] Config file not found: %CONFIG_FILE%
    pause
    exit /b
)

for /f "tokens=2 delims=:," %%A in ('findstr "vmservice_ports_start" "%CONFIG_FILE%"') do set VM_PORT=%%~A
for /f "tokens=2 delims=:," %%A in ('findstr "scrcpy_ports_start" "%CONFIG_FILE%"') do set SCRCPY_PORT=%%~A

set "VM_PORT=!VM_PORT: =!"
set "SCRCPY_PORT=!SCRCPY_PORT: =!"

:: Debug: Show extracted base ports
echo [DEBUG] Base VM_PORT: !VM_PORT!
echo [DEBUG] Base SCRCPY_PORT: !SCRCPY_PORT!

:: Find next available VM_PORT locally to avoid conflicts
set "PORT=!VM_PORT!"
:find_vm_port
netstat -ano | find ":!PORT! " >nul 2>&1
if not errorlevel 1 (
    set /a PORT+=1
    goto find_vm_port
)
set "VM_PORT=!PORT!"
echo [DEBUG] Allocated VM_PORT: !VM_PORT!

:: Find next available SCRCPY_PORT locally to avoid conflicts
set "PORT=!SCRCPY_PORT!"
:find_scrcpy_port
netstat -ano | find ":!PORT! " >nul 2>&1
if not errorlevel 1 (
    set /a PORT+=1
    goto find_scrcpy_port
)
set "SCRCPY_PORT=!PORT!"
echo [DEBUG] Allocated SCRCPY_PORT: !SCRCPY_PORT!

rem Save allocated ports to a file for use by other scripts
echo VM_PORT=!VM_PORT!> "%WORKSPACE_ROOT%\allocated_ports.env"
echo SCRCPY_PORT=!SCRCPY_PORT!>> "%WORKSPACE_ROOT%\allocated_ports.env"
echo [DEBUG] Ports allocated: VM_PORT=!VM_PORT!, SCRCPY_PORT=!SCRCPY_PORT!
pause
