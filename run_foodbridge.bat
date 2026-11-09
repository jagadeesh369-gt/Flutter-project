@echo off
setlocal enabledelayedexpansion

echo ========================================================
echo    FoodBridge - Food Bank Inventory & Donation Tracker
echo ========================================================
echo.

:: 1. Check if flutter command is in PATH
where flutter >nul 2>nul
if %errorlevel% equ 0 (
    echo [OK] Flutter SDK detected in system PATH.
    goto RUN_APP
)

:: 2. Check common installation directories
if exist "C:\src\flutter\bin\flutter.bat" (
    set "PATH=C:\src\flutter\bin;%PATH%"
    echo [OK] Found Flutter SDK at C:\src\flutter\bin
    goto RUN_APP
)

if exist "C:\flutter\bin\flutter.bat" (
    set "PATH=C:\flutter\bin;%PATH%"
    echo [OK] Found Flutter SDK at C:\flutter\bin
    goto RUN_APP
)

if exist "%USERPROFILE%\flutter\bin\flutter.bat" (
    set "PATH=%USERPROFILE%\flutter\bin;%PATH%"
    echo [OK] Found Flutter SDK at %USERPROFILE%\flutter\bin
    goto RUN_APP
)

echo [!] Flutter SDK was not found in your PATH or standard directories.
echo.
echo Please install Flutter or add its bin directory to your Environment PATH:
echo   Example: C:\src\flutter\bin
echo.
echo Official download: https://docs.flutter.dev/get-started/install/windows/mobile
echo.
pause
exit /b 1

:RUN_APP
echo.
echo [1/3] Fetching project packages (flutter pub get)...
call flutter pub get
if %errorlevel% neq 0 (
    echo [ERROR] Failed to fetch packages. Please check your internet connection.
    pause
    exit /b %errorlevel%
)

echo.
echo [2/3] Analyzing project code (flutter analyze)...
call flutter analyze

echo.
echo [3/3] Checking connected devices (flutter devices)...
call flutter devices
echo.

echo Launching FoodBridge App...
echo (Ensure your Android phone is connected via USB with USB Debugging enabled, or start an emulator)
echo.
call flutter run

pause

