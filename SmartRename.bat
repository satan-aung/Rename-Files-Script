@echo off
setlocal enabledelayedexpansion

:: 1. HANDLE FOLDER PATH (Context Menu or Manual)
if "%~1"=="" (
    set /p "targetDir=Enter full folder path: "
) else (
    set "targetDir=%~1"
)

:: Validate Path
if not exist "%targetDir%\" (echo [Error] Path does not exist. & pause & exit /b)
cd /d "%targetDir%"

:AUTH
cls
echo ====================================================
echo             RESTRICTED ACCESS: GEMINI
echo ====================================================
set /p "pswd=Enter Password to proceed: "
if NOT "!pswd!"=="satan-aung" (
    echo [Access Denied] Incorrect Password.
    pause
    exit
)

:MAIN_MENU
cls
echo ====================================================
echo                SMART RENAME ^& REVERT
echo ====================================================
echo  Target: %targetDir%
echo ----------------------------------------------------
echo  [1] Start New Rename (Number Sequence)
echo  [2] Start New Rename (Timestamp)
echo  [3] UNDO / REVERT a previous Rename
echo  [H] Help / Instructions
echo  [Q] Quit
echo ----------------------------------------------------
set /p "mainChoice=Select Action (1-4/H/Q): "

if /i "%mainChoice%"=="Q" exit /b
if /i "%mainChoice%"=="H" goto SHOW_HELP
if "%mainChoice%"=="3" goto START_UNDO

:: --- RENAME CONFIGURATION ---
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
set "oSign="
if not "%cat%"=="5" (
    set /p "order=Order: [A] Ascending [D] Descending: "
    if /i "!order!"=="D" set "oSign=-"
)

set /p "dryRun=Enable Dry Run? (Preview Only) [Y/N]: "

:: --- LOGIC HANDLING ---
set "sortCmd=n"
set "timeCmd="

if "%cat%"=="1" (set "timeCmd=/t:c" & set "sortCmd=d")
if "%cat%"=="2" (set "timeCmd=/t:w" & set "sortCmd=d")
if "%cat%"=="3" (set "sortCmd=n")
if "%cat%"=="4" (set "sortCmd=s")

if defined oSign set "sortCmd=%oSign%!sortCmd!"

:: Prepare Output
if /i "%dryRun%"=="N" if not exist "%outFolder%" mkdir "%outFolder%"
set "logFile=%outFolder%\rename_log.txt"
if /i "%dryRun%"=="N" echo # OLDNAME^|NEWNAME > "%logFile%"

set /a count=1
set /a successCount=0

:: Construct Loop Command
if "%cat%"=="5" (
    set "loopCmd=dir /b /a-d *.%extFilter%"
) else (
    set "loopCmd=dir /b /a-d %timeCmd% /o:!sortCmd! *.%extFilter%"
)

echo ----------------------------------------------------
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
            echo [PREVIEW] %%F --^> !fullNewName!
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
echo ----------------------------------------------------
echo Operation Complete. !successCount! files processed.
pause
goto MAIN_MENU

:SHOW_HELP
cls
echo [HELP] Sort Categories: 1=Created, 2=Modified, 3=Name, 4=Size, 5=Random.
echo [HELP] Undo: Reverts files based on the log in the sub-folder.
pause
goto MAIN_MENU

:START_UNDO
set /p "undoDir=Enter sub-folder name with log: "
if not exist "%undoDir%\rename_log.txt" (echo [Error] No log! & pause & goto MAIN_MENU)
cd /d "%undoDir%"
for /f "usebackq skip=1 tokens=1,2 delims=|" %%A in ("rename_log.txt") do (
    set "old=%%A" & set "new=%%B"
    set "old=!old:~0,-1!" & set "new=!new:~1!"
    if exist "!new!" (move "!new!" "..\" >nul & ren "..\!new!" "!old!")
)
cd ..
echo Undo complete.
pause
goto MAIN_MENU
