@echo off
setlocal enabledelayedexpansion

:: Get the folder where THIS installer is sitting
set "currentDir=%~dp0"
set "sourceFile=%currentDir%SmartRename.bat"
set "destFolder=C:\Scripts"
set "destFile=%destFolder%\SmartRename.bat"

echo Source: %sourceFile%
echo Destination: %destFile%

:: 1. Admin Check
net session >nul 2>&1 || (echo Run as Admin! & pause & exit)

:: 2. Folder Check
if not exist "%destFolder%" mkdir "%destFolder%"

:: 3. Explicit File Check
if exist "%sourceFile%" (
    copy /y "%sourceFile%" "%destFile%"
    echo [OK] File copied successfully.
) else (
    echo [ERROR] Could not find: %sourceFile%
    echo Make sure SmartRename.bat is in: %currentDir%
    pause
    exit /b
)

:: 4. Registry Update
reg add "HKEY_CLASSES_ROOT\Directory\shell\SmartRename\command" /ve /d "cmd.exe /c \"\"%destFile%\" \"%%1\"\"" /f

echo Done!
pause