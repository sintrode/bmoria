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
:: Prints the map of the dungeon
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:drawDungeonPanel
set "line=1"
for /L %%Y in (%dg.panel.top%,1,%dg.panel.bottom%) do (
    call ui_io.cmd :eraseLine "!line!;13"
    set /a line+=1

    for /L %%X in (%dg.panel.left%,1,%dg.panel.right%) do (
        call dungeon.cmd :caveGetTileSymbol "%%Y;%%X" "ch"
        if not "!ch!"==" " call ui_io.cmd :panelPutTile "!ch!" "%%Y;%%X"
    )
)
exit /b

::------------------------------------------------------------------------------
:: Draw the entire screen
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:drawCavePanel
call ui_io.cmd :clearScreen
call :printCharacterStatsBlock
call :drawDungeonPanel
call :printCharacterCurrentDepth
exit /b

::------------------------------------------------------------------------------
:: Redraw the panel and update the lighting if needed
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonResetView
set "tile=dg.floor[%py.pos.y%][%py.pos.x%]"

call :coordOutsidePanel "%py.pos.y%;%py.pos.x%" "false" && call :drawDungeonPanel
call dungeon.cmd :dungeonMoveCharacterLight "py.pos" "py.pos"

if "!%tile%.feature_id!"=="%TILE_LIGHT_FLOOR%" (
    if %py.flags.blind% LSS 1 (
        if "!%tile%.permanent_light!"=="false" (
            call dungeon.cmd :dungeonLightRoom "py.pos"
        )
    )
    exit /b
)

if "!%tile%.perma_lit_room!"=="true" (
    if %py.flags.blind% LSS 1 (
        call helpers.cmd :expandCoordName "py.pos"
        for /L %%Y in (%py.pos.y_dec%,1,%py.pos.y_inc%) do (
            for /L %%X in (%py.pos.x_dec%,1,%py.pos.x_inc%) do (
                if "!dg.floor[%%Y][%%X].feature_id!"=="%TILE_LIGHT_FLOOR%" (
                    if "!dg.floor[%%Y][%%X].permanent_light!"=="false" (
                        set "coord=%%Y;%%X"
                        call dungeon.cmd :dungeonLightRoom "coord"
                    )
                )
            )
        )
    )
)
exit /b

::------------------------------------------------------------------------------
:: Convert stat to a string if the stat is greater than 18
::
:: Arguments: %1 - The base stat value
::            %2 - A variable to store the output in
:: Returns:   None
::------------------------------------------------------------------------------
:statsAsString
set /a percentile=%~1-18
if %~1 LSS 18 (
    call scores.cmd :sprintf "%~2" "%~1" 6
) else if "%percentile%"=="100" (
    set "%~2=18/100"
) else (
    set "percentile=0!percentile!"
    set "%~2= 18/!percentile:~0,2!"
)
exit /b

::------------------------------------------------------------------------------
:: Print character stat in its dedicated row and column
::
:: Arguments: %1 - The index of the stat to display
:: Returns:   None
::------------------------------------------------------------------------------
:displayCharacterStats
call :statsAsString "!py.stats.used[%~1]!" "text"
set /a stat_row=%~1+6, stat_col_inc=%stat_column%+6
call ui_io.cmd :putString "!stat_names!" "!stat_row!;%STAT_COLUMN%"
call ui_io.cmd :putString "!text!" "!stat_row!;!stat_col_inc!"
exit /b

::------------------------------------------------------------------------------
:: Print character information at specified coordinates
::
:: Arguments: %1 - The info to display
::            %2 - The coordinates to place the string at
::------------------------------------------------------------------------------
:printCharacterInfoInField
call ui_io.cmd :putString "             " "%~2"
call ui_io.cmd :putString %*
exit /b

::------------------------------------------------------------------------------
:: A wrapper for :printHeaderNumber
:: TODO: Merge the :five print____Number subroutines
::------------------------------------------------------------------------------
:printHeaderLongNumber
call :printHeaderNumber %*
exit /b

::------------------------------------------------------------------------------
:: Print a number with a header at specified coordinates
::
:: Arguments: %1 - The header to display
::            %2 - The number to display
::            %3 - The coordinates at which to display the string
:: Returns:   None
::------------------------------------------------------------------------------
:printHeaderNumber
call scores.cmd :sprintf "str" "%~2" 6
call ui_io.cmd :putString "%~1: !str!" "%~3"
exit /b

::------------------------------------------------------------------------------
:: Print a 7-digit number with a header at specified coordinates
::
:: Arguments: %1 - The header to display
::            %2 - The number to display
::            %3 - The coordinates at which to display the string
:: Returns:   None
::------------------------------------------------------------------------------
:printHeaderLongNumber7Spaces
call scores.cmd :sprintf "str" "%~2" 7
call ui_io.cmd :putString "%~1: !str!" "%~3"
exit /b

::------------------------------------------------------------------------------
:: An overloaded method for :printNumber because int32_t and int are different
:: things in C/C++
::------------------------------------------------------------------------------
:printLongNumber
call :printNumber %*
exit /b

::------------------------------------------------------------------------------
:: Print a number at specified coordinates with no header
::
:: Arguments: %1 - The number to display
::            %2 - The coordinates at which to display the string
:: Returns:   None
::------------------------------------------------------------------------------
:printNumber
call scores.cmd :sprintf "str" "%~1" 6
call ui_io.cmd :putString "!str!" "%~2"
exit /b

::------------------------------------------------------------------------------
:: Prints the character's rank-based title
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:printCharacterTitle
call player.cmd :playerRankTitle "player_rank"
call :printCharacterInfoInField "!player_rank!" "4;0"
exit /b

::------------------------------------------------------------------------------
:: Prints the character's level
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:printCharacterLevel
call :printNumber "%py.misc.level%" "13;6"
exit /b

::------------------------------------------------------------------------------
:: Prints the character's current mana points
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:printCharacterCurrentMana
call :printNumber "%py.misc.current_mana%" "15;6"
exit /b

::------------------------------------------------------------------------------
:: Prints the character's maximum hit points
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:printCharacterMaxHitPoints
call :printNumber "%py.misc.max_hp%" "16;6"
exit /b

::------------------------------------------------------------------------------
:: Prints the character's current hit points
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:printCharacterCurrentHitPoints
call :printNumber "%py.misc.current_hp%" "17;6"
exit /b

::------------------------------------------------------------------------------
:: Prints the character's armor class
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:printCharacterCurrentArmorClass
call :printNumber "%py.misc.display_ac%" "19;6"
exit /b

::------------------------------------------------------------------------------
:: Prints the character's gold
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:printCharacterGoldValue
call :printNumber "%py.misc.au%" "20;6"
exit /b

::------------------------------------------------------------------------------
:: Print the character's depth in feet
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:printCharacterCurrentDepth
set /a depth=%dg.current_level% * 50
if "!depth!"=="0" (
    call ui_io.cmd :putStringClearToEOL "Town level" "23;65"
) else (
    call ui_io.cmd :putStringClearToEOL "!depth! feet" "23;65"
)
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

