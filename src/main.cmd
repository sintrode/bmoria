::------------------------------------------------------------------------------
:: Original Moria  code copyright (c) 1981-86 Robert A. Koeneke
:: Original UMoria code copyright (c) 1987-94 James E. Wilson
::
:: SPDX-License-Identifier: GPL-3.0-or-later
::------------------------------------------------------------------------------
@echo off
setlocal enabledelayedexpansion
call sys\read_config.cmd
call sys\read_version.cmd

:main
set "seed=0"
set "new_game=false"

REM call :initializeScoreFile || (
REM     echo Can't open score file.
REM     exit /b 1
REM )

:: checkFilePermissions and terminalInitialize have not been included due to
:: lack of applicability on Windows machines
:parseArgs
if "%~1"=="" (
    call sys\game_run.cmd :startMoria !seed! !new_game!
    exit /b
)
if /i "%~1"=="-v" (
    echo %CURRENT_VERSION_MAJOR%.%CURRENT_VERSION_MINOR%.%CURRENT_VERSION_PATCH%
    exit /b 0
)
if /i "%~1"=="-n" (
    set "new_game=true"
    shift
    goto :parseArgs
)
if /i "%~1"=="-d" (
    call :showScoresScreen
    exit /b 0
)
if /i "%~1"=="-s" (
    if not "%~2"=="" set "seed=%~2"
    call :parseGameSeed "%~2" || (
        echo Game seed must be an integer between 1 and 2147483647
        exit /b 1
    )
    shift
    shift
    goto :parseArgs
)
if /i "%~1"=="-w" (
    set "game.to_be_wizard=true"
    shift
    goto :parseArgs
)
echo Robert A. Koeneke's classic dungeon crawler
echo bmoria %CURRENT_VERSION_MAJOR%.%CURRENT_VERSION_MINOR%.%CURRENT_VERSION_PATCH% is released under a GPL-3.0-or-later license.
echo Usage:
echo     umoria [OPTIONS] SAVEGAME
echo(
echo SAVEGAME is an optional save game filename (default: game.sav)
echo(
echo Options:
echo     -n           Force start of new game
echo     -d           Display high scores and exit
echo     -s NUMBER    Game Seed, as an integer number (1-2147483647)
echo(
echo     -v           Print version info and exit
echo     -h           Display this help message
exit /b 0

::------------------------------------------------------------------------------
:: Checks that the score file is read/writable
::
:: Arguments: None
:: Returns:   0 if the file can be accessed, 1 otherwise
::------------------------------------------------------------------------------
:initializeScoreFile
>>"%config.files.scores%" type nul
exit /b %errorlevel%

::------------------------------------------------------------------------------
:: Confirms that the given seed is an integer
::
:: Arguments: %1 - The value to check
:: Returns:   0 if the value is an integer, 1 otherwise
::------------------------------------------------------------------------------
:parseGameSeed
set "is_valid_num=0"
for /f "delims=012345789" %%A in ("%~1") do set "is_valid_num=1"
if "%~1" LSS "1" set "is_valid_num=1"
exit /b %is_valid_num%