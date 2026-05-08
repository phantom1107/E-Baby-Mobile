@echo off
echo ========================================
echo E-Baby Mobile - App Icon Setup
echo ========================================
echo.

REM Create assets/icon directory if it doesn't exist
if not exist "assets\icon" mkdir "assets\icon"

REM Copy existing logo from website
echo Copying E-Baby logo...
copy "..\E-Baby\static\images\logo\E-Baby Tab Icon Logo.png" "assets\icon\app_icon.png"

if %ERRORLEVEL% EQU 0 (
    echo ✓ Logo copied successfully!
    echo.
    
    echo Installing flutter_launcher_icons...
    call flutter pub add flutter_launcher_icons --dev
    
    echo.
    echo Generating app icons...
    call flutter pub get
    call flutter pub run flutter_launcher_icons
    
    echo.
    echo ========================================
    echo ✓ App icon setup complete!
    echo ========================================
    echo.
    echo Next steps:
    echo 1. Run: flutter clean
    echo 2. Run: flutter run
    echo 3. Check your new app icon!
    echo.
) else (
    echo ✗ Error: Could not find logo file
    echo Please make sure the website logo exists at:
    echo ..\E-Baby\static\images\logo\E-Baby Tab Icon Logo.png
    echo.
)

pause
