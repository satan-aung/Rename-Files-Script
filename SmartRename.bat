@echo off
setlocal enabledelayedexpansion

:: 1. HANDLE FOLDER PATH
if "%~1"=="" (set /p "targetDir=Enter full folder path: ") else (set "targetDir=%~1")
if not exist "%targetDir%\" (echo [Error] Path does not exist. & pause & exit /b)
cd /d "%targetDir%"

:MAIN_MENU
cls
echo ====================================================
echo          GEMINI SMART RENAME ^& REVERT
echo ====================================================
echo  Target: %targetDir%
echo ----------------------------------------------------
echo  [1] Start New Rename (Number Sequence)
echo  [2] Start New Rename (Timestamp)
echo  [3] UNDO / REVERT a previous Rename
echo  [H] Help / Instructions
echo  [Q] Quit
echo ----------------------------------------------------
set /p "mainChoice=Select Action: "

if /i "%mainChoice%"=="Q" exit /b
if /i "%mainChoice%"=="H" goto SHOW_HELP
if "%mainChoice%"=="3" goto START_UNDO

:: --- RENAME CONFIGURATION ---
:GET_EXT
set /p "extFilter=Target extension (e.g., jpg) or * for all: "
set /p "prefix=Enter file prefix: "
set /p "outFolder=Enter name for new sub-folder: "

if "%mainChoice%"=="1" (
    set /p "padding=Digits for numbering (e.g., 3): "
)

:GET_CAT
echo.
echo Select Sorting: [1] Created [2] Modified [3] Name [4] Size [5] RANDOM
set /p "cat=Choice (1-5): "
if not "%cat%"=="5" (
    set /p "order=Order: [A] Ascending [D] Descending: "
    if /i "!order!"=="A" (set "oSign=") else (set "oSign=-")
)

:GET_DRYRUN
set /p "dryRun=Enable Dry Run? (Preview Only) [Y/N]: "

:: --- LOGIC HANDLING (RENAMING) ---
set "sortCmd=n"
set "timeCmd="

if "%cat%"=="1" (
    set "timeCmd=/t:c"
    set "sortCmd=d"
)
if "%cat%"=="2" (
    set "timeCmd=/t:w"
    set "sortCmd=d"
)
if "%cat%"=="3" set "sortCmd=n"
if "%cat%"=="4" set "sortCmd=s"

if defined oSign set "sortCmd=%oSign%%sortCmd%"

if /i "%dryRun%"=="N" if not exist "%outFolder%" mkdir "%outFolder%"
set "logFile=%outFolder%\rename_log.txt"
if /i "%dryRun%"=="N" (echo # OLDNAME^|NEWNAME > "%logFile%")

set /a count=1
set /a successCount=0

:: We now pass !timeCmd! separately from /o:!sortCmd!
if "%cat%"=="5" (
    set "loopCmd=dir /b /a-d *.%extFilter%"
) else (
    set "loopCmd=dir /b /a-d !timeCmd! /o:!sortCmd! *.%extFilter%"
)

for /f "delims=" %%F in ('%loopCmd%') do (
    if /i not "%%F"=="%~nx0" if /i not "%%F"=="rename_log.txt" (
        set "finalName="
        if "%mainChoice%"=="1" (
            set "num=00000000!count!"
            set "num=!num:~-%padding%!"
            set "finalName=%prefix%_!num!"
        )
        if "%mainChoice%"=="2" (
            for /f "tokens=1-4 delims=/.: " %%a in ("%%~tF") do (set "finalName=%prefix%_%%c%%a%%b_%%d")
        )
        set "fullNewName=!finalName!%%~xF"
        if exist "%outFolder%\!fullNewName!" set "fullNewName=!finalName!_DUP_!random!%%~xF"

        if /i "%dryRun%"=="Y" (
            echo [PREVIEW] %%F --^> %outFolder%\!fullNewName!
            set /a successCount+=1
        ) else (
            echo %%F^|!fullNewName! >> "%logFile%"
            move "%%F" "%outFolder%\!fullNewName!" >nul
            echo [DONE] %%F --^> !fullNewName!
            set /a successCount+=1
        )
        set /a count+=1
    )
)
echo.
echo Operation Complete. !successCount! files processed.
pause
goto MAIN_MENU

:: --- HELP SECTION ---
:SHOW_HELP
cls
echo ====================================================
echo                INSTRUCTIONS ^& HELP
echo ====================================================
echo  NAMING STYLES:
echo  1. Numbering: Uses a sequence (01, 001, 0001). 
echo  2. Timestamp: Uses file's "Last Modified" date.
echo.
echo  SORTING CATEGORIES:
echo  - Created:  Original time the file appeared on disk.
echo  - Modified: The last time the file was saved/edited.
echo  - Name:     Alphabetical order (A-Z or Z-A).
echo  - Size:     File weight (Smallest vs Largest).
echo  - Random:   Shuffles files (great for playlists).
echo.
echo  DRY RUN:
echo  - Always use this first to see the outcome without
echo    actually moving or renaming your files.
echo.
echo  UNDO:
echo  - Requires the sub-folder name. It uses the log file
echo    to move files back and restore original names.
echo ====================================================
pause
goto MAIN_MENU

:: --- UNDO LOGIC ---
:START_UNDO
set /p "undoDir=Enter the sub-folder name containing the log: "
if not exist "%undoDir%\rename_log.txt" (echo [Error] No log found! & pause & goto MAIN_MENU)
echo Reverting...
cd /d "%undoDir%"
for /f "usebackq skip=1 tokens=1,2 delims=|" %%A in ("rename_log.txt") do (
    set "old=%%A"
    set "new=%%B"
    set "old=!old:~0,-1!"
    set "new=!new:~1!"
    if exist "!new!" (
        echo [RESTORING] !new! --^> !old!
        move "!new!" "..\" >nul
        ren "..\!new!" "!old!"
    )
)
cd ..
echo Undo complete.
pause
goto MAIN_MENU