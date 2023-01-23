@echo off
call %*
exit /b

::------------------------------------------------------------------------------
:: Gets a new random seed for the random number generator
::
:: Arguments: %1 - The initial seed to use
:: Returns:   None
::------------------------------------------------------------------------------
:seedsInitialize
if "%~1"=="0" (
    REM This is supposed to be the current UNIX time, but this is Windows
    REM and %RANDOM% is based on the clock, so it's good enough
    set "clock_var=!RANDOM!"
) else (
    set "clock_var=%~1"
)

set "game.magic_seed=!clock_var!"
set /a clock_var+=8762
set "game.town_seed=!clock_var!"
set /a clock_var+=113452
call rng.cmd :setRandomSeed !clock_var!

:: And now for additional randomness
call game.cpp :randomNumber 100
for /L %%A in (!errorlevel!,-1,1) do (
    call rng.cmd :rnd
)
exit /b

::------------------------------------------------------------------------------
:: Change to a different random number generator state
::
:: Arguments: %1 - the initial seed to use
:: Returns:   None
::------------------------------------------------------------------------------
:seedSet
set "old_seed=!rnd_seed!"
call rng.cmd :setRandomSeed "%~1"
exit /b

::------------------------------------------------------------------------------
:: Restore the normal random generator state
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:seedResetToOldSeed
call rng.cmd :setRandomSeed !old_seed!
exit /b

::------------------------------------------------------------------------------
:: Generates a random number between 1 and MAXVAL
::
:: Arguments: %1 - The maximum valid random value
:: Returns:   A random number between 1 and %1
::------------------------------------------------------------------------------
:randomNumber
call rng.cmd :rnd
set /a random_number=!errorlevel! %% %~1 + 1
exit /b !random_number!

::------------------------------------------------------------------------------
:: Generates a random integer number of normal distribution
::
:: Arguments: %1 - mean
::            %2 - standard
:: Returns:   A random number within a few standard deviations
::------------------------------------------------------------------------------
:randomNumberNormalDistribution
call :randomNumber 32767
set "tmp_random_number=!errorlevel!"

if "%tmp_random_number%"=="32767" (
    call :randomNumber %~2
    set /a offset=4 * %~2 + !errorlevel!

    call :randomNumber 2
    if "!errorlevel!"=="1" set /a offset=-!offset!
    set /a sd=%~1+!offset!
    exit /b !sd!
)

set "low=0"
set /a "iindex=%normal_table_size%>>1"
set "high=%normal_table_size%"

:loopNormalDistribution
set /a low_shift=low+1
if "!normal_table[%iindex%]!"=="%tmp_random_number%" goto :endLoopNormalDistribution
if "!high!"=="!low_shift!" goto :endLoopNormalDistribution
if !normal_table[%iindex%]! GTR !tmp_random_number! (
    set "high=!iindex!"
    set /a "iindex=low + ((iindex-low) >> 1)"
) else (
    set "low=!iindex!"
    set /a "iindex=iindex + ((high-iindex) >> 1)"
)
:endLoopNormalDistribution
set "low_shift="

if !normal_table[%iindex%]! LSS !tmp_random_number! (
    set /a iindex+=1
)

set /a "offset=((%~2*!iindex!)+(%normal_table_sd% >> 1)) / %normal_table_sd%"

call :randomNumber 2
if "!errorlevel!"=="1" set /a offset=-!offset!
set /a sd=%~1+!offset!
exit /b !sd!

::------------------------------------------------------------------------------
:: Set or unset various boolean config.options.displays_counts
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:setGameOptions
call ui_io.cmd :putStringClearToEOL "  Space when finished, y/n to set options, - to move cursor" "0;0"

for /L %%A in (0,1,10) do (
    set /a option_line=%%A+1
    set "display_line=!game_options[%%A].desc!                                      "
    set "display_line=!display_line:~0,38!"
    for /f %%B in ("!game_options[%%A].var!") do (
        call ui_io.cmd :putStringClearToEOL "!display_line! : !%%B!" "!option_line!;0"
    )
)
call ui_io.cmd :eraseLine "11;0"
set "option_line="
set "display_line="

set "option_id=0"
:setGameOptionsLoop
set /a option_offset=!option_id!+1
call ui_io.cmd :moveCursor "!option_offset!;40"

call ui_io.cmd :getKeyInput key
if "!key!"==" " goto :setGameOptionsEndLoop
if "!key!"=="-" (
    if !option_offset! LSS 10 (
        set /a option_id+=1
    ) else (
        set "option_id=0"
    )
)
if /I "!key!"=="Y" (
    call ui_io.cmd :putString "true " "!option_offset!;40"
    for /f "delims=" %%A in ("!game_options[%option_id%]!") do set "!%%A!=true"

    if !option_offset! LSS 10 (
        set /a option_id+=1
    ) else (
        set "option_id=0"
    )
)
if /I "!key!"=="N" (
    call ui_io.cmd :putString "false" "!option_offset!;40"
    for /f "delims=" %%A in ("!game_options[%option_id%]!") do set "!%%A!=false"

    if !option_offset! LSS 10 (
        set /a option_id+=1
    ) else (
        set "option_id=0"
    )
)
:setGameOptionsEndLoop
set "option_id="
set "option_offset="
exit /b

::------------------------------------------------------------------------------
:: Returns a non-five random number between 1 and 9
::
:: Arguments: None
:: Returns:   1, 2, 3, 4, 6, 7, 8 or 9
::------------------------------------------------------------------------------
:getRandomDirection
call game.cmd :randomNumber 9
if "!errorlevel!"=="5" (
    goto :getRandomDirection
) else (
    set "dir=!errorlevel!"
)
exit /b !dir!

::------------------------------------------------------------------------------
:: Prompts for a direction. Remembers that direction for repeated commands.
::
:: Arguments: %1 - The prompt to display
::            %2 - The variable representing the direction to move in
:: Returns:   0 if a valid command is entered, 1 otherwise
::------------------------------------------------------------------------------
:getDirectionWithMemory
if "%game.use_last_direction%"=="true" (
    set "%~2=!py.prev_dir!"
    exit /b 0
)
if "%~1"=="CNIL" (
    set "dir_prompt=Which direction?"
)

:getDirectionWithMemoryLoop
set "old_count=%game.command_count%"
call ui_io.cmd :getCommand "%~1" command || (
    set "game.player_free_turn=true"
    exit /b 1
)
set "game.command_count=%old_count%"
if !command! GEQ 1 (
    if !command! LEQ 9 (
        if !command! NEQ 5 (
            set "py.prev_dir=!command!"
            set "%~2=!py.prev_dir!"
            exit /b 0
        )
    )
)
call ui_io.cmd :terminalBellSound
goto :getDirectionWithMemoryLoop

::------------------------------------------------------------------------------
:: Like getDirectionWithMemory but doesn't remember the past
::
:: Arguments: %1 - The prompt to display
::            %2 - The variable representing the direction to move in
:: Returns:   0 if a valid command is entered, 1 otherwise
::------------------------------------------------------------------------------
:getAllDirections
call ui_io.cmd :getCommand "%~1" command || (
    set "game.player_free_turn=true"
    exit /b 1
)
if !command! GEQ 1 (
    if !command! LEQ 9 (
        set "%~2=!command!"
        exit /b 0
    )
)
call ui_io.cmd :terminalBellSound
goto :getAllDirections

::------------------------------------------------------------------------------
:: Quits the game
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:exitProgram
call ui_io.cmd :flushInputBuffer
call io_io.cmd :terminalRestore
exit /b