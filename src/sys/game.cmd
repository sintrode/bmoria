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

:setGameOptions
exit /b

:validGameVersion
exit /b

:isCurrentGameVersion
exit /b

:getRandomDirection
exit /b

:mapRoguelikeKeysToKeypad
exit /b

:getDirectionWithMemory
exit /b

:getAllDirections
exit /b

:exitProgram
exit /b

:abortProgram
exit /b
