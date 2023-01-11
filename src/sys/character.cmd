@echo off
call %*
exit /b

::------------------------------------------------------------------------------
:: Generates a player's stats
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:characterGenerateStats
set "total=0"
for /L %%A in (0,1,17) do (
    set /a max_rnd=3+%%A%%3
    call rng.cmd :randomNumber !max_rnd!
    set "dice[%%A]=!errorlevel!"
    set /a total=!dice[%%A]!
)
if !total! LEQ 42 goto :characterGenerateStats
if !total! GEQ 54 goto :characterGenerateStats

for /L %%A in (1,1,6) do (
    set /a d1=3*%%A, d2=3*%%A+1, d3=3*%%A+2
    set "py.stats.max[%%A]=5+d1+d2+d3"
)
exit /b

::------------------------------------------------------------------------------
:: Subtracts a specified amount from a given stat
::
:: Arguments: %1 - the amount to adjust
::            %2 - the starting value of the stat to be adjusted
:: Returns:   The new value of the stat
::------------------------------------------------------------------------------
:decrementStat
set "stat=%~2"
for /L %%A in (0,-1,%~1) do (
    if !stat! GTR 108 (
        set /a stat-=1
    ) else if !stat! GTR 88 (
        call rng.cmd :randomNumber 6
        set /a stat=!stat!-!errorlevel!-2
    ) else if !stat! GTR 18 (
        call rng.cmd :randomNumber 15
        set /a stat=!stat!-!errorlevel!-5
        if !stat! LSS 18 (
            set "stat=18"
        )
    ) else if !stat! GTR 3 (
        set /a stat-=1
    )
)
exit /b !stat!

::------------------------------------------------------------------------------
:: Adds a specified amount to a given stat
::
:: Arguments: %1 - the amount to adjust
::            %2 - the starting value of the stat to be adjusted
:: Returns:   The new value of the stat
::------------------------------------------------------------------------------
:incrementStat
set "stat=%~2"
for /L %%A in (0,1,%~1) do (
    if !stat! LSS 18 (
        set /a stat+=1
    ) else if !stat! LSS 88 (
        call rng.cmd :randomNumber 15
        set /a stat+=!errorlevel!+5
    ) else if !stat! LSS 108 (
        call rng.cmd :randomNumber 6
        set /a stat+=!errorlevel!+2
    ) else if !stat! LSS 118 (
        set /a stat+=1
    )
)
exit /b !stat!

::------------------------------------------------------------------------------
:: Randomly tweak player stats for fun. I have no idea why stat and adjustment
:: are flipped here; it's just what was in the cpp files.
::
:: Arguments: %1 - The stat to be modified
::            %2 - The amount to adjust
:: Returns:   The updated stat value
::------------------------------------------------------------------------------
:createModifyPlayerStat
if %~2 LSS 0 (
    call :decrementStat "%~2" "%~1"
) else (
    call :incrementStat "%~2" "%~1"
)
exit /b !errorlevel!

::------------------------------------------------------------------------------
:: Generates all stats and modify for race
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:characterGenerateStatsAndRace
for /L %%A in (0,1,5) do (
    call :createModifyPlayerStat "!py.stats.max[%%A]!" "!character_races[%py.misc.race_id%].adjustment[%%A]!" 
    set "py.stats.max[%%A]=!errorlevel!"
)
set "py.misc.level=1"

for /L %%A in (0,1,5) do (
    set "py.stats.current[%%A]=!py.stats.max[%%A]!"
    call player_stats.cmd :playerSetAndUseStat "%%A"
)

set "py.misc.chance_in_search=!character_races[%py.misc_race_id%].search_chance_base!"
set "py.misc.bth=!character_races[%py.misc_race_id%].base_to_hit!"
set "py.misc.bth_with_bows=!character_races[%py.misc_race_id%].base_to_hit_bows!"
set "py.misc.fos=!character_races[%py.misc_race_id%].fos!"
set "py.misc.stealth_factor=!character_races[%py.misc_race_id%].stealth!"
set "py.misc.saving_throw=!character_races[%py.misc_race_id%].saving_throw_base!"
set "py.misc.hit_die=!character_races[%py.misc_race_id%].hit_points_base!"
call player_stats.cmd :playerDamageAdjustment
set "py.misc.plusses_to_damage=!character_races[%py.misc_race_id%].%errorlevel%!"
call player_stats.cmd :playerToHitAdjustment
set "py.misc.plusses_to_hit=!character_races[%py.misc_race_id%].%errorlevel%!"
set "py.misc.magical_ac=0"
call player_stats.cmd :playerArmorClassAdjustment
set "py.misc.ac=!character_races[%py.misc_race_id%].%errorlevel%!"
set "py.misc.experience_factor=!character_races[%py.misc_race_id%].exp_factor_base!"
set "py.misc.see_infra=!character_races[%py.misc_race_id%].infra_vision!"
exit /b

::------------------------------------------------------------------------------
:: Prints a list of available races: Human, Elf, etc.
:: Shown during the character creation screens
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:displayCharacterRaces
call ui_io.cmd :clearToBottom 20
call ui_io.cmd :putString "Choose a race (? for Help):" "20;2"
set "coord.y=21"
set "coord.x=2"

for /L %%A in (0,1,7) do (
    set /a letter=97+%%A
    cmd /c exit /b !letter!
    set "description=!=ExitCodeAscii!) !character_races[%%A].name!"
    call ui_io.cmd :putString "!description!" "!coord.y!;!coord.x!"
)
set "letter="
exit /b

::------------------------------------------------------------------------------
:: Allows the player to select a race
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:characterChooseRace
call :displayCharacterRaces

:characterChooseRaceLoop
call ui_io.cmd :moveCursor "20;30"
call ui_io.cmd :getKeyInput key

for /f "delims=abcdefg" %%A in ("!key!") do (
    if "!key!"=="?" call game_files.cmd :displayTextHelpFile %config.files.welcome_screen%
    goto :characterChooseRaceLoop
)
set "counter=0"
for %%A in (a b c d e f g) do (
    if "!key!"=="%%A" set "id=!counter!"
    set /a counter+=1
)
set "py.misc.race_id=!id!"
call ui_io.cmd :putString "!character_races[%id%].name!" "3;15"
exit /b

::------------------------------------------------------------------------------
:: Print the history of the character
:: 
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:displayCharacterHistory
call ui_io.cmd :putString "Character Background" "14;27"
for /L %%A in (0,1,3) do (
    set /a y_coord=%%A+15
    call ui_io.cmd :putStringClearToEOL "!y_coord!;10"
)
exit /b

::------------------------------------------------------------------------------
:: Clear the previous history strings
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerClearHistory
for /L %%A in (0,1,4) do  set "py.misc.history[%%A]="
exit /b

::------------------------------------------------------------------------------
:: Get the racial history and determine social class
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:characterGetHistory
set /a history_id=%py.misc.race_id%*3+1
call rng.cmd :randomNumber 4
set "social_class=!errorlevel!"
set "history_block="
set "background_id=0"

:characterGetHistoryOuterLoop
set "flag=false"
:characterGetHistoryInnerLoop
if "!character_backgrounds[%background_id%].chart!"=="!history_id!" (
    call rng.cmd :randomNumber 100
    call :check_test "!test_roll!" "!background_id!"

    for /f "delims=" %%A in ("!background_id!") do (
        set "history_block=!history_block!!character_backgrounds[%%A].info!"
        set /a social_class+=!character_backgrounds[%%A].bonus! - 50
        
        if !history_id! GTR !character_backgrounds[%%A].next! set "background_id=0"

        set "history_id=!character_backgrounds[%%A].next!"
        set "flag=true"
    )
) else (
    set /a background_id+=1
)
if "!flag!"=="false" goto :characterGetHistoryInnerLoop
if !history_id! GEQ 1 goto :characterGetHistoryOuterLoop

call :playerClearHistory

:: TODO: Word wrap for history text
exit /b

:check_test
if %~1 GTR !character_backgrounds[%~2].roll! (
    set /a background_id+=1
    goto :check_test
)
exit /b

:characterSetGender
exit /b

:characterSetAgeHeightWeight
exit /b

:displayRaceClasses
exit /b

:generateCharacterClass
exit /b

:characterGetClass
exit /b

:monetaryValueCalculatedFromStat
exit /b

:playerCalculateStartGold
exit /b

:characterCreate
exit /b