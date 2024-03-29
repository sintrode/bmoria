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
:: Prints the character's depth in feet
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

::------------------------------------------------------------------------------
:: Prints how hungry the character is
:: TODO: Merge :printCharacter____Status subroutines
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:printCharacterHungerStatus
set /a "is_weak=%py.flags.status% & %config.player.status.PY_WEAK%"
set /a "is_hungry=%py.flags.status% & %config.player.status.PY_HUNGRY%"

if not "%is_weak%"=="0" (
    call ui_io.cmd :putString "Weak  " "23;0"
) else if not "%is_hungry%"=="0" (
    call ui_io.cmd :putString "Hungry" "23;0"
) else (
    call ui_io.cmd :putString "      " "23;0"
)

set "is_weak="
set "is_hungry="
exit /b

::------------------------------------------------------------------------------
:: Prints the character's blind status
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:printCharacterBlindStatus
set /a "is_blind=%py.flags.status% & %config.player.status.PY_BLIND%"
if not "!is_blind!"=="0" (
    call ui_io.cmd :putString "Blind" "23;7"
) else (
    call ui_io.cmd :putString "     " "23;7"
)
set "is_blind="
exit /b

::------------------------------------------------------------------------------
:: Prints the character's confused status
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:printCharacterConfusedState
set /a "is_confused=%py.flags.status% & %config.player.status.PY_CONFUSED%"
if not "!is_confused!"=="0" (
    call ui_io.cmd :putString "Confused" "23;13"
) else (
    call ui_io.cmd :putString "        " "23;13"
)
set "is_confused="
exit /b

::------------------------------------------------------------------------------
:: Prints the character's fear status
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:printCharacterFearState
set /a "is_afraid=%py.flags.status% & %config.player.status.PY_FEAR%"
if not "!is_afraid!"=="0" (
    call ui_io.cmd :putString "Afraid" "23;22"
) else (
    call ui_io.cmd :putString "      " "23;22"
)
set "is_afraid="
exit /b

::------------------------------------------------------------------------------
:: Prints the character's poisoned status
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:printCharacterPoisonedState
set /a "is_poisoned=%py.flags.status% & %config.player.status.PY_POISONED%"
if not "!is_poisoned!"=="0" (
    call ui_io.cmd :putString "Poisoned" "23;29"
) else (
    call ui_io.cmd :putString "        " "23;29"
)
set "is_poisoned="
exit /b

::------------------------------------------------------------------------------
:: Prints the character's movement state - searching, resting, paralyzed, count
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:printCharacterMovementState
set /a "is_repeat=%py.flags.status%&=~%config.player.status.PY_REPEAT%"

if %py.flags.paralysis% GTR 1 (
    call ui_io.cmd :putString "Paralysed" "23;38"
    exit /b
)

set /a "is_resting=%py.flags.status% & %config.player.status.PY_REST%"
if not "!is_resting!"=="0" (
    if %py.flags.rest% LSS 0 (
        set "rest_string=Rest *"
    ) else if "%config.options.display_counts%"=="true" (
        call scores.cmd :sprintf "rest_string" "%py.flags.rest%" -5
        set "rest_string=Rest !rest_string!"
    ) else (
        set "rest_string=Rest"
    )

    call ui_io.cmd :putString "!rest_string!" "23;38"
    set "is_resting="
    exit /b
)

if %game.command_count% GTR 0 (
    if "%config.options.display_counts%"=="true" (
        call scores.cmd :sprintf "repeat_string" "%game.command_count%" -3
        set "repeat_string=Repeat !repeat_string!"
    ) else (
        set "repeat_string=Repeat"
    )

    set /a "py.flags.status|=%config.player.status.PY_REPEAT%"
    call ui_io.cmd :putString "!repeat_string!" "23;38"

    set /a "is_searching=!py.flags.status! & %config.player.status.PY_SEARCH%"
    if not "!is_searching!"=="0" call ui_io.cmd :putString "Search" "23;38"
    set "is_searching="
    exit /b
)

set /a "is_searching=!py.flags.status! & %config.player.status.PY_SEARCH%"
if not "!is_searching!"=="0" (
    call ui_io.cmd :putString "Searching" "23;38"
    set "is_searching="
    exit /b
)
call ui_io.cmd :putString "          " "23;38"
exit /b

::------------------------------------------------------------------------------
:: Prints the character's speed
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:printCharacterSpeed
:: Go faster in Search mode
set "speed=%py.flags.speed%"
set "is_searching=%py.flags.status% & %config.player.status.PY_SEARCH%"
if not "!is_searching!"=="0" set /a speed-=1
set "is_searching="

if !speed! GTR 1 (
    call ui_io.cmd :putString "Very Slow" "23;49"
) else if "!speed!"=="1" (
    call ui_io.cmd :putString "Slow     " "23;49"
) else if "!speed!"=="0" (
    call ui_io.cmd :putString "         " "23;49"
) else if "!speed!"=="-1" (
    call ui_io.cmd :putString "Fast     " "23;49"
) else (
    call ui_io.cmd :putString "Very Fast" "23;49"
)
set "speed="
exit /b

::------------------------------------------------------------------------------
:: Prints the character's study reminder
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:printCharacterStudyInstruction
set /a "py.flags.status&=~%config.player.status.PY_STUDY%"
if "%py.flags.new_spells_to_learn%"=="0" (
    call ui_io.cmd :putString "     " "23;59"
) else (
    call ui_io.cmd :putString "Study" "23;59"
)
exit /b

::------------------------------------------------------------------------------
:: Prints the character's winner status
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:printCharacterWinner
set /a "is_res=%game.noscore%&1", "is_wiz=%game.noscore%&2", "is_dup=%game.noscore%&4"
if not "!is_wiz!"=="0" (
    if "%game.wizard_mode%"=="true" (
        call ui_io.cmd :putString "Is wizard  " "22;0"
    ) else (
        call ui_io.cmd :putString "Was wizard " "22;0"
    )
) else if not "!is_res!"=="0" (
    call ui_io.cmd :putString "Resurrected" "22;0"
) else if not "!is_dup!"=="0" (
    call ui_io.cmd :putString "Duplicate  " "22;0"
) else if "%game.total_winner%"=="true" (
    call ui_io.cmd :putString "*Winner*   " "22;0"
)
exit /b

::------------------------------------------------------------------------------
:: Prints character screen information
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:printCharacterStatsBlock
call :printCharacterInfoInField "!character_races[%py.misc.race_id%].name!" "2;0"
call :printCharacterInfoInField "!classes[%py.misc.class_id%].title!" "3;0"
call :printCharacterTitle

for /L %%A in (0,1,5) do call :displayCharacterStats %%A

call :printHeaderNumber "LEV " %py.misc.level% "13;0"
call :printHeaderNumber "EXP " %py.misc.exp% "14;0"
call :printHeaderNumber "MANA" %py.misc.current_mana% "15;0"
call :printHeaderNumber "MHP " %py.misc.max_hp% "16;0"
call :printHeaderNumber "CHP " %py.misc.current_hp% "17;0"
call :printHeaderNumber "AC  " %py.misc.display_ac% "19;0"
call :printHeaderNumber "GOLD" %py.misc.au% "20;0"
call :printCharacterWinner

:: This originally had a bunch of if statements, but the same checks are also
:: done inside of each of the :print subroutines, so no sense checking twice
call :printCharacterHungerStatus
call :printCharacterBlindStatus
call :printCharacterConfusedStatus
call :printCharacterFearStatus
call :printCharacterPoisonedStatus
call :printCharacterMovementStatus

set /a "speed=%py.flags.speed% - (%py.flags.status% & %config.player.status.PY_SEARCH%) >> 8"
if not "!speed!"=="0" call :printCharacterSpeed

call :printCharacterStudyInstruction
exit /b

::------------------------------------------------------------------------------
:: Prints character name/race/sex/class
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:printCharacterInformation
call ui_io.cmd :clearScreen

call ui_io.cmd :putString "Name        :" "2;1"
call ui_io.cmd :putString "Race        :" "3;1"
call ui_io.cmd :putString "Sex         :" "4;1"
call ui_io.cmd :putString "Class       :" "5;1"
if "%game.character_generated%"=="false" exit /b

call ui_io.cmd :putString "%py.misc.name%" "2;15"
call ui_io.cmd :putString "!character_races[%py.misc.race_id%]!" "3;15"
call player.cmd :playerGetGenderLabel gender_string
call ui_io.cmd :putString "!gender_string!" "4;15"
call ui_io.cmd :putString "!classes[%py.misc.class_id%].title!" "5;15"
exit /b

::------------------------------------------------------------------------------
:: Print stats, to_hit, to_damage, and AC
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:printCharacterStats
for /L %%A in (0,1,5) do (
    set a_inc=%%A+2
    call :statsAsString "!py.stats.used[%%A]!" "buf"
    call ui_io.cmd :putString "!stat_names[%%A]!" "!a_inc!;61"
    call ui_io.cmd :putString "!buf!" "!a_inc!;66"

    if !py.stats.max[%%A]! GTR !py.stats.current[%%A]! (
        call :statsAsString "!py.stats.max[%%A]!" "buf"
        call ui_io.cmd :putString "!buf!" "!a_inc!;73"
    )
)

call :printHeaderNumber "+ To Hit    " "%py.misc.display_to_hit%"     "9;1"
call :printHeaderNumber "+ To Damage " "%py.misc.display_to_damage%" "10;1"
call :printHeaderNumber "+ To AC     " "%py.misc.display_to_ac%"     "11;1"
call :printHeaderNumber "  Total AC  " "%py.misc.display_ac%"        "12;1"
exit /b

::------------------------------------------------------------------------------
:: Calculates an efficiency rating based on various stats
::
:: Arguments: %1 - The threshold value of the stat
::            %2 - The actual value of the stat
::            %3 - A variable to store the output in
:: Returns:   None
::------------------------------------------------------------------------------
:statRating
set /a stat_ratio=%~1/%~2
set "%~3=Superb"
if !stat_ratio! LEQ -1 set "%~3=Very Bad"
if !stat_ratio! GEQ 0 if !stat_ratio! LEQ 1 set "%~3=Bad"
if "!stat_ratio!"=="2" set "%~3=Poor"
if !stat_ratio! GEQ 3 if !stat_ratio! LEQ 4 set "%~3=Fair"
if "!stat_ratio!"=="5" set "%~3=Good"
if "!stat_ratio!"=="6" set "%~3=Very Good"
if !stat_ratio! GEQ 7 if !stat_ratio! LEQ 8 set "%~3=Excellent"
exit /b

::------------------------------------------------------------------------------
:: Prints age/height/weight/social class
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:printCharacterVitalStatistics
call :printHeaderNumber "Age          " "%py.misc.age%" "2;38"
call :printHeaderNumber "Height       " "%py.misc.height%" "3;38"
call :printHeaderNumber "Weight       " "%py.misc.weight%" "4;38"
call :printHeaderNumber "Social Class " "%py.misc.social_class%" "5;38"
exit /b

::------------------------------------------------------------------------------
:: Prints level/XP/gold/HP/MP
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:printCharacterLevelExperience
call :printHeaderLongNumber7Spaces "Level      " "%py.misc.level%"    "9;28"
call :printHeaderLongNumber7Spaces "Experience " "%py.misc.exp%"     "10;28"
call :printHeaderLongNumber7Spaces "Max Exp    " "%py.misc.max_exp%" "11;28"

set /a level_dec=%py.misc.level%-1
if %py.misc.level% GEQ %player_max_level% (
    call ui_io.cmd :putStringClearToEOL "Exp to Adv.: *******" "12;28"
) else (
    set /a next_xp=!py.base_exp_levels[%level_dec%]! * %py.misc.experience_factor% / 100
    call :printHeaderLongNumber7Spaces "Exp to Adv." "!next_xp!" "12;28"
)

call :printHeaderLongNumber7Spaces "Gold       " "%py.misc.au%"    "13;28"
call :printHeaderNumber "Max Hit Points " "%py.misc.max_hp%"        "9;52"
call :printHeaderNumber "Cur Hit Points " "%py.misc.current_hp%"   "10;52"
call :printHeaderNumber "Max Mana       " "%py.misc.mana%"         "11;52"
call :printHeaderNumber "Cur Mana       " "%py.misc.current_mana%" "12;52"
exit /b

::------------------------------------------------------------------------------
:: Prints miscellaneous character abilities
:: TODO: Refactor for readability
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:printCharacterAbilities
call ui_io.cmd :clearToBottom 14

set /a xbth=%py.misc.bth% + %py.misc.plusses_to_hit% * %bth_per_plus_to_hit_adjust% + (!class_level_adj[%py.misc.class_id%][%PlayerClassLevelAdj.BTH%]! * %py.misc.level%)
set /a xbthb=%py.misc.bth_with_bows% + %py.plusses_to_hit% * %bth_per_plus_to_hit_adjust% + (!class_level_adj[%py.misc.class_id%][%PlayerClassLevelAdj.BTHB%]! * %py.misc.level%)

set /a xfos=40 - %py.misc.fos%
if !xfos! LSS 0 set "xfos=0"

set "xsrh=%py.misc.chance_in_search%"

set /a xstl=%py.misc.stealth_factor%+1
call player_stats.cmd :playerDisarmAdjustment
set "disarm_adj=!errorlevel!"
call player_stats.cmd :playerStatAdjustmentWisdomIntelligence "%PlayerAttr.a_int%"
set "int_adj=!errorlevel!"
set /a xdis=%py.misc.disarm% + 2 * !disarm_adj! + !int_adj! + (!class_level_adj[%py.misc.class_id%][%PlayerClassLevelAdj.disarm%]! * %py.misc.level% / 3)
call player_stats.cmd :playerStatAdjustmentWisdomIntelligence "%PlayerAttr.a_wis%"
set "wis_adj=!errorlevel!"
set /a xsave=%py.misc.saving_throw% + !wis_adj! + (!class_level_adj[%py.misc.class_id%][%PlayerClassLevelAdj.save%]! * %py.misc.level% / 3)
set /a xdev=%py.misc.saving_throw% + !int_adj! + (!class_level_adj[%py.misc.class_id%][%PlayerClassLevelAdj.device%]! * %py.misc.level% / 3)

set /a xinfra=%py.flags.see_infra% * 10
set "xinfra=!xinfra! feet"

call ui_io.cmd :putString "(Miscellaneous Abilities)" "15;25"
call ui_io.cmd :putString "Fighting    :" "16;1"
call :statRating 12 !xbth! "bth_stat"
call ui_io.cmd :putString "!bth_stat!"    "16;15"
call ui_io.cmd :putString "Bows/Throw  :" "17;1"
call :statRating 12 !xbthb! "bthb_stat"
call ui_io.cmd :putString "!bthb_stat!"   "17;15"
call ui_io.cmd :putString "Saving Throw:" "18;1"
call :statRating 6 !xsave! "save_stat"
call ui_io.cmd :putString "!save_stat!"   "18;15"

call ui_io.cmd :putString "Stealth     :" "16;28"
call :statRating 1 !xstl! "stl_stat"
call ui_io.cmd :putString "!save_stat!"   "16;42"
call ui_io.cmd :putString "Disarm      :" "17;28"
call :statRating 8 !xdis! "dis_stat"
call ui_io.cmd :putString "!dis_stat!"    "17;42"
call ui_io.cmd :putString "Magic Device:" "18;28"
call :statRating 6 !xdev! "dev_stat"
call ui_io.cmd :putString "!dev_stat!"    "18;42"

call ui_io.cmd :putString "Perception  :" "16;55"
call :statRating 3 !xfos! "fos_stat"
call ui_io.cmd :putString "!fos_stat!"    "16;69"
call ui_io.cmd :putString "Searching   :" "17;55"
call :statRating 3 !xsrh! "srh_stat"
call ui_io.cmd :putString "!srh_stat!"    "17;69"
call ui_io.cmd :putString "Infra-Vision:" "18;55"
call ui_io.cmd :putString "!xinfra!"      "18;69"
exit /b

::------------------------------------------------------------------------------
:: Display the character on the screen
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:printCharacter
call :printCharacterInformation
call :printCharacterVitalStatistics
call :printCharacterStats
call :printCharacterLevelExperience
call :printCharacterAbilities
exit /b

::------------------------------------------------------------------------------
:: Get the character's name from the player
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:getCharacterName
call ui_io.cmd :putStringClearToEOL "Enter your character's name" "21;2"
call ui_io.cmd :putString "                       " "2;15"

call ui_io.cmd :getStringInput "py.misc.name" "2;15" 23
if "!errorlevel!"=="1" (
    call ui_io.cmd :getDefaultPlayerName "py.misc.name"
    call ui_io.cmd :putString "!py.misc.name!" "2;15"
)

call ui_io.cmd :clearToBottom 20
exit /b

::------------------------------------------------------------------------------
:: Change the character's name or savefile name
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:changeCharacterName
set "flag=false"
call :printCharacter

:changeCharacterNameWhileLoop
if "!flag!"=="true" exit /b
call ui_io.cmd :putStringClearToEOL "<f>ile character description. <c>hange character name. <Q>uit." "21;2"

call ui_io.cmd :getKeyInput key
if "!key!"=="c" (
    call :getCharacterName
    set "flag=true"
) else if "!key!"=="f" (
    call ui_io.cmd :putStringClearToEOL "File name:" "0;0"
    call ui_io.cmd :getStringInput "temp_name" "0;10" 60
    if "!errorlevel!"=="0" if not "!temp_name!"=="" (
        call game_files.cmd :outputPlayerCharacterToFile "!temp_name!"
        if "!errorlevel!"=="0" set "flag=true"
    )
) else if "!key!"=="Q" (
    set "flag=true"
) else (
    call ui_io.cmd :terminalBellSound
)
goto :changeCharacterNameWhileLoop

::------------------------------------------------------------------------------
:: Print a list of spells
::
:: Arguments: %1 - A variable to store the list of spells
::            %2 - The number of choices in the list
::            %3 - Determine if the spells are commented
::            %4 -  -1 if the spells start at 'a'
::                 >=0 if the spells are offset
:: Returns:   None
::------------------------------------------------------------------------------
:displaySpellsList
set "number_of_choices=%~2"
set "comment=%~3"
set "non_consecutive=%~4"

if "%comment%"=="true" (
    set "col=22"
) else (
    set "col=31"
)

if "!classes[%py.misc.class_id%].class_to_use_mage_spells!"=="%config.spells.SPELL_MAGE_TYPE%" (
    set "consecutive_offset=%config.spells.NAME_OFFSET_SPELLS%"
) else (
    set "consecutive_offset=%config.spells.NAME_OFFSET_PRAYERS%"
)

call ui_io.cmd :eraseLine "1;%col%"
set /a col_inc=%col%+5
call ui_io.cmd :putString "Name" "1;%col_inc%"
set /a col_inc=%col%+35
call ui_io.cmd :putString "Lv Mana Fail" "1;%col_inc%"

:: Only show 22 choices at a time
if %number_of_choices% GTR 22 set "number_of_choices=22"
set /a number_of_choices-=1
for /L %%A in (0,1,%number_of_choices%) do (
    set "spell_id=!spell_ids[%%A]!"
    set /a class_dec=%py.misc.class_id%-1
    for /f "tokens=1,2" %%B in ("!class_dec! !spell_id!") do (
        set "spell=magic_spells[%%~B][%%~C]"
    )

    set /a "did_forget=%py.flags.spells_forgotten% & (1 << !spell_id!)"
    set /a "did_learn=%py.flags.spells.learnt% & (1 << !spell_id!)"
    set /a "did_work=%py.flags.spells.worked% & (1 << !spell_id!)"
    set "p="
    if "%comment%"=="false" (
        set "p="
    ) else if not "!did_forget!"=="0" (
        set "p=forgotten"
    ) else if "!did_learn!"=="0" (
        set "p=unknown"
    ) else if "!did_work!"=="0" (
        set "p=untried"
    ) else (
        set "p="
    )

    if "%non_consecutive%"=="-1" (
        set /a spell_char_ascii=%%A+97
        cmd /c exit /b !spell_char_ascii!
        set "spell_char=!=ExitCodeAscii!"
    ) else (
        set /a spell_char_ascii=97 + !spell_id! - !non_consecutive!
        cmd /c exit /b !spell_char_ascii!
        set "spell_char=!=ExitCodeAscii!"
    )

    set /a spell_offset=!spell_id!+!consecutive_offset!, a_inc=%%A+2
    call :displayOneSpell "!spell!" "!spell_offset!" "!spell_id!" !a_inc!
)
exit /b

:displayOneSpell
call scores.cmd :sprintf "disp_spell_name" "!spell_names[%~2]!" -30
call scores.cmd :sprintf "disp_level_needed" "!%~1.level_required!" 2
call scores.cmd :sprintf "disp_mana_needed" "!%~1.mana_required!" 4
call mage_spells.cmd :spellChangeOfSuccess "%~3"
set "disp_odds=!errorlevel!"

set "out_val=!spell_char!) !disp_spell_name!!disp_level_needed! !disp_mana_needed! !disp_odds!%%!p!"
call ui_io.cmd :putStringClearToEOL "!out_val!" "%~4;!col!"

::------------------------------------------------------------------------------
:: Increase hit points and level
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerGainLevel
set /a py.misc.level+=1
call ui_io.cmd :printMessage "Welcome to level %py.misc.level%."

call player_stats.cmd :playerCalculateHitPoints

set /a level_dec=%py.misc.level%-1
set /a new_exp=!py.base_exp_levels[%level_dec%]! * %py.misc.experience_factor% / 100
if %py.misc.exp% GTR %new_exp% (
    set /a diff_exp=%py.misc.exp% - %new_exp%
    set /a "py.misc.exp=%new_exp% + (!diff_exp! / 2)"
)

call :printCharacterLevel
call :printCharacterTitle

set "player_class=classes[%py.misc.class_id%]"
if "!%player_class%.class_to_use_mage_spells!"=="%config.spells.SPELL_TYPE_MAGE%" (
    call player.cmd :playerCalculateAllowedSpellsCount "%PlayerAttr.a_int%"
    call player.cmd :playerGainMana "%PlayerAttr.a_int%"
) else if "!%player_class%.class_to_use_mage_spells!"=="%config.spells.SPELL_TYPE_PRIEST%" (
    call player.cmd :playerCalculateAllowedSpellsCount "%PlayerAttr.a_wis%"
    call player.cmd :playerGainMana "%PlayerAttr.a_wis%"
)
exit /b

::------------------------------------------------------------------------------
:: Prints the character's experience points
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:displayCharacterExperience
if %py.misc.exp% GTR %config.player.PLAYER_MAX_EXP% (
    set "py.misc.exp=%config.player.PLAYER_MAX_EXP%"
)

:displayCharacterExperienceWhileLoop
set /a level_dec=!py.misc.exp!-1
if !py.misc.level! GEQ %PLAYER_MAX_LEVEL% goto :displayCharacterExperienceAfterWhileLoop
set /a check_exp=!py.base_exp_levels[%level_dec%]! * %py.misc.experience_factor% / 100
if !check_exp! GTR !py.misc.exp! goto :displayCharacterExperienceAfterWhileLoop
call :playerGainLevel
:displayCharacterExperienceWhileLoop

:displayCharacterExperienceAfterWhileLoop
if %py.misc.exp% GTR %py.misc.max_exp% set "py.misc.max_exp=%py.misc.exp%"

call :printLongNumber "%py.misc.exp%" "14;6"
exit /b

