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
    set /a "max_rnd=3 + (%%A %% 3)"
    call rng.cmd :randomNumber !max_rnd!
    set "dice[%%A]=!errorlevel!"
    set /a total+=!dice[%%A]!
)
if !total! LEQ 42 goto :characterGenerateStats
if !total! GEQ 54 goto :characterGenerateStats

for /L %%A in (0,1,5) do (
    set /a d1=3*%%A, d2=3*%%A+1, d3=3*%%A+2
    for /f "tokens=1-3" %%B in ("!d1! !d2! !d3!") do (
        set /a py.stats.max[%%A]= 5 + dice[%%~B] + dice[%%~C] + dice[%%~D]
    )
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
set "py.misc.plusses_to_damage=!errorlevel!"
call player_stats.cmd :playerToHitAdjustment
set "py.misc.plusses_to_hit=!errorlevel!"
set "py.misc.magical_ac=0"
call player_stats.cmd :playerArmorClassAdjustment
set "py.misc.ac=!errorlevel!"
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

:: Word wrap for history text
set "cursor_start=0"
call helpers.cmd :strlen "!history_block!"
set /a cursor_end=!errorlevel!-1

:stripLeadingHistoryBlockWhitespace
if "!history_block:~%cursor_start%,1!"==" " (
    set /a cursor_start+=1
    goto :stripLeadingHistoryBlockWhitespace
)
set /a current_cursor_position=cursor_end-cursor_start

if %current_cursor_position% GTR 60 (
    set "current_cursor_position=60"
    call :findPreviousSpace NEQ

    set /a new_cursor_start=cursor_start+current_cursor_position

    call :findPreviousSpace EQU
) else (
    set "flag=true"
)

set /a line_length=%current_cursor_position%-%cursor_start%
set "py.mis.history[!line_number!]=!history_block:~%cursor_start%,%line_length%"
set /a line_number+=1
set "line_length="
set "cursor_start=!new_cursor_start!"
exit /b

::------------------------------------------------------------------------------
:: Ridiculous hack for a while loop nested inside of an if because you can't
:: have labels in code blocks in batch. To be fair, the C++ version of this was
:: a triple-nested while loop, so...
::
:: Arguments: %1 - A random number between 1 and 100
::            %2 - The required roll for a character background
:: Returns:   None
::------------------------------------------------------------------------------
:check_test
if %~1 GTR !character_backgrounds[%~2].roll! (
    set /a background_id+=1
    goto :check_test
)
exit /b

::------------------------------------------------------------------------------
:: Searches the string for whitespace and moves the cursor to the previous
:: position based on whether we are or aren't looking for empty space.
::
:: Arguments: %1 - Whether or not to check for whitespace
:: Returns:   None
::------------------------------------------------------------------------------
:findPreviousSpace
set /a current_char=cursor_start+current_cursor_position-1
if "!history_block:~%current_char%,1!" %~1 " " (
    set /a current_cursor_position-=1
    goto :findPreviousSpace
)
exit /b

::------------------------------------------------------------------------------
:: Gets the character's gender.
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:characterSetGender
call ui_io.cmd :clearToBottom 20
call ui_io.cmd :putString "Choose a gender (? for Help):" "20;2"
call ui_io.cmd :putString "m) Male          f) Female" "21;2"

call ui_io.cmd :moveCursor "20;29"
call ui_io.cmd :getKeyInput key
for /f "delims=mMfF?" %%A in ("!key!") do (
    call ui_io.cmd :terminalBellSound
    goto :characterSetGender
)

if /I "!key!"=="f" (
    call player.cmd :playerSetGender "false"
    call ui_io.cmd :putString "Female" "4;15"
) else if /I "!key!"=="m" (
    call player.cmd :playerSetGender "true"
    call ui_io.cmd :putString "Male" "4;15"
) else (
    call game_files.cmd :displayTextHelpFile "%config.files.welcome_screen%"
)
exit /b

::------------------------------------------------------------------------------
:: Computes the character's age, height, and weight
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:characterSetAgeHeightWeight
call rng.cmd :randomNumber %py.misc.race_id.max_age%
set /a py.misc.age=!character_races[%py.misc.race_id%].base_age!+!errorlevel!

call player.cmd :isMale
if "!errorlevel!"=="0" (
    set "infix=male"
) else (
    set "infix=female"
)
for %%A in (height_base height_mod weight_base weight_mod) do (
    set %%A=!character_races[%py.misc.race_id%].%infix%_%%A!
)

call game.cmd :randomNumberNormalDistribution %height_base% %height_mod%
set "py.misc.height=!errorlevel!"
call game.cmd :randomNumberNormalDistribution %weight_base% %weight_mod%
set "py.misc.weight=!errorlevel!"
call player_stats.cmd :playerDisarmAdjustment
set /a py.misc.disarm=!character_races[%py.misc.race_id%].disarm_chance_base!+!errorlevel!
exit /b

::------------------------------------------------------------------------------
:: Returns the number of valid classes for a given race
::
:: Arguments: %1 - The race_id of the player's race
::            %2 - The variable to contain the list of valid classes
:: Returns:   The number of valid classes for a given race
::------------------------------------------------------------------------------
:displayRaceClasses
set "coord.y=21"
set "coord.x=2"
set "class_id=0"
set "mask=1"

call ui_io.cmd :clearToBottom 20
call ui_io.cmd :putString "Choose a class (? for Help):" "20;2"

for /L %%A in (0,1,%player_max_classes%) do (
    set /a "masked_bit_field=!character_races[%~1].classes_bit_field! & !mask!"
    if !masked_bit_field! NEQ 0 (
        set letter=!class_id!+97
        cmd /c exit /b !letter!
        set "description=!=ExitCodeAscii!) !classes[%%A].title!"
        call ui_io.cmd :putString "!description!" "!coord.y!;!coord.x!"
        set "!%~2![!class_id!]=%%A"

        set /a coord.x+=15
        if !coord.x! GTR 70 (
            set "coord.x=2"
            set /a coord.y+=1
        )
        set /a class_id+=1
    )
    set /a "mask<<=1"
)
exit /b !class_id!

::------------------------------------------------------------------------------
:: Actually set the character stats
::
:: Arguments: %1 - The selected class_id of the character
:: Returns:   None
::------------------------------------------------------------------------------
:generateCharacterClass
call ui_io.cmd :clearToBottom 20
call ui_io.cmd :putString "!classes[%py.misc.class_id%].title!" "5;15"

:: Tweak stats based on class
for /L %%A in (0,1,5) do (
    call :createModifyPlayerStat !py.stats.max[%%A]! !classes[%py.misc.class%].stats[%%A]!
    set "py.stats.max[%%A]=!errorlevel!"
    set "py.stats.current[%%A]=!py.stats.max[%%A]!"
    call player_stats.cmd :playerSetAndUseStat %%A
)

call player_stats.cmd :playerDamageAdjustment
set "py.misc.plusses_to_damage=!errorlevel!"
call player_stats.cmd :playerToHitAdjustment
set "py.misc.plusses_to_hit=!errorlevel!"
call player_stats.cmd :playerArmorClassAdjustment
set "py.misc.magical_ac=!errorlevel!"
set "py.misc.ac=0"

:: Displayed values
set "py.misc.display_to_damage=%py.misc.plusses_to_damage%"
set "py.misc.display_to_hit=%py.misc.plusses_to_hit%"
set "py.misc.display_to_ac=%py.misc.magical_ac%"
set /a py.misc.display_ac=%py.misc.ac%+%py.misc.display_to_ac%

set /a py.misc.hit_die+=!classes[%py.misc.class_id%].hit_points!
call player_stats.cmd :playerStatAdjustmentConstitution
set /a py.misc.max_hp+!errorlevel!+%py.misc_hit_die%
set "py.misc.current_hp=%py.misc.max_hp%"
set "py.misc.current_hp_fraction=0"

set /a min_value=(%player_max_level%*3/8*(%py.misc.hit_die%-1))+%player_max_level%
set /a max_value=(%player_max_level%*5/8*(%py.misc.hit_die%-1))+%player_max_level%
set "py.base_hp_levels[0]=%py.misc.hit_die%"

:generateHpLevels
for /L %%A in (1,1,%player_max_level%) do (
    call rng.rnd :randomNumber %py.misc.hit_die%
    set "py.base_hp_levels[%%A]=!errorlevel!"

    for /F "delims=" %%B in ('set /a %%A-1') do (
        set /a py.base_hp_levels[%%A]+=!py.base_hp_levels[%%B]!
    )
)
if !py.base_hp_levels[%player_max_level%]! GEQ %min_value% (
    if !py.base_hp_levels[%player_max_level%]! LEQ %max_value% (
        goto :concludeCharacterGeneration
    )
)
goto :generateHpLevels

:concludeCharacterGeneration
set "py.misc.bth+=!classes[%py.misc.class_id%].base_to_hit!"
set "py.misc.bth_with_bows+=!classes[%py.misc.class_id%].base_to_hit_with_bows!"
set "py.misc.chance_in_search+=!classes[%py.misc.class_id%].searching!"
set "py.misc.disarm+=!classes[%py.misc.class_id%].disarm_traps!"
set "py.misc.fos+=!classes[%py.misc.class_id%].fos!"
set "py.misc.stealth_factor+=!classes[%py.misc.class_id%].stealth!"
set "py.misc.saving_throw+=!classes[%py.misc.class_id%].saving_throw!"
set "py.misc.experience_factor+=!classes[%py.misc.class_id%].experience_factor!"
exit /b

::------------------------------------------------------------------------------
:: Gets the character class from user input
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:characterGetClass
for /L %%A in (0,1,%player_max_classes%) do set "class_list[%%A]=0"
call :displayRaceClasses %py.misc.race_id% class_list
set "class_count=!errorlevel!"

set "py.misc.class_id=0"
:characterGetClassLoop
call ui_io.cmd :moveCursor "20;31"
call ui_io.cmd :getKeyInput key
for /F "delims=abcdefABCDEF?" %%A in ("!key!") do goto :characterGetClassLoop

set "counter=0"
for %%A in (a b c d e f) do (
    set "ascii[%%A]=!counter!"
    set /a counter+=1
)
set "key_val=!ascii[%key%]!"

if !ascii[%key%]! LSS %class_count% (
    call :generateCharacterClass !class_list[%key_val%]!
    goto :characterGetClassAfterLoop
) else if "!key!"=="?" (
    call game_files.cmd :displayTextHelpFile "%config.files.welcome_screen%"
) else (
    call ui_io.cmd :terminalBellSound
)
goto :characterGetClassLoop

:characterGetClassAfterLoop
exit /b

::------------------------------------------------------------------------------
:: Given a stat value, return a monetary value
::
:: Arguments: %1 - The value of the stat to base the calculation on
:: Returns:   5*(%~1-10)
::------------------------------------------------------------------------------
:monetaryValueCalculatedFromStat
set /a stat=5 * (%~1 - 10)
exit /b !stat!

::------------------------------------------------------------------------------
:: Base the character's starting gold on their starting stats and social class
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerCalculateStartGold
set /a value=5 * (!py.stats.max[%PlayerAttr.a_str%]! - 10)
set /a value+=5 * (!py.stats.max[%PlayerAttr.a_int%]! - 10)
set /a value+=5 * (!py.stats.max[%PlayerAttr.a_wis%]! - 10)
set /a value+=5 * (!py.stats.max[%PlayerAttr.a_con%]! - 10)
set /a value+=5 * (!py.stats.max[%PlayerAttr.a_dex%]! - 10)

call rng.cmd :rnd 25
set /a new_gold=%py.misc.social_class% * 6 + !errorlevel! + 325
set /a new_gold-=value
set /a new_gold+=5 * (!py.stats.max[%PlayerAttr.a_chr%]! - 10)

:: Women start with more money because the pockets on their pants are too small
call player.cmd :isMale || set /a new_gold+=50

if %new_gold% LSS 80 set "new_gold=80"
set "py.misc.au=%new_gold%"
exit /b

::------------------------------------------------------------------------------
:: The main loop for character creation
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:characterCreate
call ui.cmd :printCharacterInformation
call :characterChooseRace
call :characterSetGender

set "done=true"
:getCharacteristicsLoop
call :characterGenerateStatsAndRace
call :characterGetHistory
call :characterSetAgeHeightWeight
call :displayCharacterHistory
call ui.cmd :printCharacterVitalStatistics
call ui.cmd :printCharacterStats

call ui_io.cmd :clearToBottom 20
call ui_io.cmd :putString "Press N to reroll or Y to accept characteristics" "20;2"

call ui_io.cmd :getKeyInput key
if /I "!key!"=="y" set "done=true"
if "!done!"=="false" goto :getCharacteristicsLoop
set "done="

call :characterGetClass
call :playerCalculateStartGold
call ui.cmd :printCharacterStats
call ui.cmd :printCharacterAbilities
call ui.cmd :getCharacterName

call ui_io.cmd :putStringClearToEOL "[ Press any key to continue, or Q to exit. ]" "23;17"
call ui_io.cmd :getKeyInput key
if /I "!key!"=="Q" call game.cmd :exitProgram
call ui_io.cmd :eraseLine "23;0"
exit /b