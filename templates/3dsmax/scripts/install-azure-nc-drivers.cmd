
set vmsize=%~1
if "%vmsize%" == "" goto InstallDrivers
if "%vmsize:~0,11%" == "Standard_NC" goto InstallDrivers
goto Done

:InstallDrivers
rem Check for NVIDIA Tesla GPUs
rem Ignore check for now, system doesn't seem to be returning NVIDIA devices
rem wmic path win32_VideoController get name | findstr /C:"NVIDIA Tesla" || exit /b 0
wmic path win32_VideoController get name

set driver_version=452.39
set driver_filename=%driver_version%-data-center-tesla-desktop-winserver-2019-2016-international.exe

rem If already installed, skip
if exist %AZ_BATCH_NODE_SHARED_DIR%\init.txt exit /b 0

rem Install Chocolatey if required - https://chocolatey.org 
choco -v
if %errorlevel% neq 0 @"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"

rem Install 7zip
choco install -y 7zip
if %errorlevel% neq 0 exit /b %errorlevel%

rem Download NVIDIA Tesla/CUDA drivers
powershell.exe Invoke-WebRequest -Uri "http://us.download.nvidia.com/tesla/%driver_version%/%driver_filename%" -OutFile "%driver_filename%"
if %errorlevel% neq 0 exit /b %errorlevel%

rem Extract and install NVIDIA drivers
7z x -y %driver_filename%
if %errorlevel% neq 0 exit /b %errorlevel%

setup.exe -s -noreboot
if %errorlevel% neq 0 exit /b %errorlevel%

rem Write a flag so we know we're done
echo done > %AZ_BATCH_NODE_SHARED_DIR%\init.txt

rem Initiate a reboot of the VM
start shutdown /r /t 15

:Done
exit /b 0
