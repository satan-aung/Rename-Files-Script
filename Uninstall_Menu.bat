@echo off
setlocal enabledelayedexpansion

:: 1. Define the location of the script to be removed
set "destFolder=C:\Scripts"
set "destFile=%destFolder%\SmartRename.bat"

echo ====================================================
echo              SMART RENAME - UNINSTALLER
echo ====================================================
echo.

:: 2. Check for Administrator Privileges (Required to edit HKEY_CLASSES_ROOT)
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Please right-click this file and "Run as Administrator".
    pause
    exit /b
)

:: 3. Remove Registry Entries
echo [SYSTEM] Removing Right-Click menu entries...
reg delete "HKEY_CLASSES_ROOT\Directory\shell\SmartRename" /f >nul 2>&1

if %errorlevel% equ 0 (
    echo [OK] Registry keys successfully removed.
) else (
    echo [!] Registry keys were already missing or not found.
)

:: 4. Delete the Script File
if exist "%destFile%" (
    del /f /q "%destFile%" >nul
    echo [OK] Deleted script from %destFile%.
)

:: 5. Attempt to remove the folder (only if empty)
if exist "%destFolder%" (
    rd "%destFolder%" >nul 2>&1
    if not exist "%destFolder%" (
        echo [OK] Removed empty folder: %destFolder%
    ) else (
        echo [INFO] Folder %destFolder% kept (it contains other files).
    )
)

echo.
echo ----------------------------------------------------
echo UNINSTALL COMPLETE!
echo The Smart Rename menu has been removed.
echo ----------------------------------------------------
pause
