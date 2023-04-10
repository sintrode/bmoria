@echo off
call %*
exit /b

::------------------------------------------------------------------------------
:: Calculates current boundaries
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:panelBounds
set /a dg.panel.top=%dg.panel.row% * (%screen_height% / 2)
set /a dg.panel.bottom=%dg.panel.top% + %screen_height% - 1
set /a dg.panel.row_prt=%dg.panel.top% - 1
set /a dg.panel.left=%dg.panel.col% * (%screen_width% / 2)
set /a dg.panel.right=%dg.panel.left% + %screen_width% - 1
set /a dg.panel.col_prt=%dg.panel.left% - 13
exit /b

::------------------------------------------------------------------------------
:: Calculate new borders if a specified set of coordinates goes offscreen
::
:: Arguments: %1 - The set of coordinates to validate
::            %2 - Determines if a recalculation should be forced
:: Returns:   0 if the coordinates are outside of the panel
::            1 if the coordinates exist on the current panel
::------------------------------------------------------------------------------
:coordOutsidePanel
set "coord=%~1"
set "force=%~2"

for /f "tokens=1,2 delims=;" %%A in ("%coord%") do (
    set "coord.y=%%~A"
    set "coord.x=%%~B"
)
set "panel=%dg.panel.row%;%dg.panel.col%"
set "panel.y=%dg.panel.row%"
set "panel.x=%dg.panel.col%"

set "recalc_y=0"
if "%force%"=="true" set "recalc_y=1"
set /a border_inc=%dg.panel.top%+2
if %coord.y% LSS %border_inc% set "recalc_y=1"
set /a border_inc=%dg.panel.bottom%-2
if %coord.y% GTR %border_inc% set "recalc_y=1"
if "!recalc_y!"=="1" (
    set /a "panel.y=(%coord.y% - %screen_height% / 4) / (%screen_height% / 2)"
    if !panel.y! GTR %dg.panel.max_rows% (
        set "panel.y=%dg.panel.max_rows%"
    ) else if !panel.y! LSS 0 (
        set "panel.y=0"
    )
)
set "recalc_y="

set "recalc_x=0"
if "%force%"=="true" set "recalc_x=1"
set /a border_inc=%dg.panel.left%+3
if %coord.x% LSS %border_inc% set "recalc_x=1"
set /a border_inc=%dg.panel.right%+3
if %coord.x% GTR %border_inc% set "recalc_x=1"
if "!recalc_x!"=="1" (
    set /a "panel.x=(%coord.x% - %screen_width% / 4) / (%screen_width% / 2)"
    if !panel.x! GTR %dg.panel.max_cols% (
        set "panel.x=%dg.panel.max_cols%"
    ) else if !panel.x! LSS 0 (
        set "panel.x=0"
    )
)
set "recalc_x="

set "new_bounds=0"
if not "!panel.y!"=="%dg.panel.row%" set "new_bounds=1"
if not "!panel.x!"=="%dg.panel.col%" set "new_bounds=1"
if "!new_bounds!"=="1" (
    set "dg.panel.row=!panel.y!"
    set "dg.panel.col=!panel.x!"
    call :panelBounds

    if "%config.options.find_bound%"=="true" (
        call player_run.cmd :playerEndRunning
    )
    exit /b 0
)
exit /b 1

::------------------------------------------------------------------------------
:: Check if the specified coordinates are on the current screen panel
::
:: Arguments: %1 - The coordinates to check
:: Returns:   0 if the coordinates are on the panel
::            1 if the coordinates are out of bounds
::------------------------------------------------------------------------------
:coordInsidePanel
set "valid_y=1"
set "valid_x=1"

for /f "tokens=1,2 delims=;" %%A in ("%~1") do (
    if %%~A GEQ %dg.panel.top% if %%~A LEQ %dg.panel.bottom% set "valid_y=0"
    if %%~B GEQ %dg.panel.left% if %%~B LEQ %dg.panel.right% set "valid_y=0"
)
set /a "is_valid=!valid_y! | !valid_x!"
exit /b !is_valid!

::------------------------------------------------------------------------------
:: Draw the entire screen
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:drawDungeonPanel
call ui_io.cmd :clearScreen
call :printCharacterStatsBlock
call :drawDungeonPanel
call :printCharacterCurrentDepth
exit /b

:drawCavePanel
exit /b

:dungeonResetView
exit /b

:statsAsString
exit /b

:displayCharacterStats
exit /b

:printCharacterInfoInField
exit /b

:printHeaderLongNumber
exit /b

:printHeaderLongNumber7Spaces
exit /b

:printHeaderNumber
exit /b

:printLongNumber
exit /b

:printNumber
exit /b

:printCharacterTitle
exit /b

:printCharacterLevel
exit /b

:printCharacterCurrentMana
exit /b

:printCharacterMaxHitPoints
exit /b

:printCharacterCurrentHitPoints
exit /b

:printCharacterCurrentArmorClass
exit /b

:printCharacterGoldValue
exit /b

:printCharacterCurrentDepth
exit /b

:printCharacterHungerStatus
exit /b

:printCharacterBlindStatus
exit /b

:printCharacterConfusedState
exit /b

:printCharacterFearState
exit /b

:printCharacterPoisonedState
exit /b

:printCharacterMovementState
exit /b

:printCharacterSpeed
exit /b

:printCharacterStudyInstruction
exit /b

:printCharacterWinner
exit /b

:printCharacterStatsBlock
exit /b

:printCharacterInformation
exit /b

:printCharacterStats
exit /b

:statRating
exit /b

:printCharacterVitalStatistics
exit /b

:printCharacterLevelExperience
exit /b

:printCharacterAbilities
exit /b

:printCharacter
exit /b

:getCharacterName
exit /b

:changeCharacterName
exit /b

:displaySpellsList
exit /b

:playerGainLevel
exit /b

:displayCharacterExperience
exit /b

