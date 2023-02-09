@echo off
call %*
exit /b

::------------------------------------------------------------------------------
:: Returns the next available space for a monster
::
:: Arguments: None
:: Returns:   -1 if no monster can be allocated
::            Otherwise, next_free_monster_id is incremented and returned
::------------------------------------------------------------------------------
:popm
if "%next_free_monster_id%"=="%MON_TOTAL_ALLOCATIONS%" (
    call :compactMonsters || exit /b -1
)
set /a next_free_monster_id+=1
exit /b !next_free_monster_id!

::------------------------------------------------------------------------------
:: Places a monster a speficied coordinates
::
:: Arguments: %1 - The location of the new monster
::            %2 - The ID of the creature to place
::            %3 - A flag for if the new monster is sleeping or not
:: Returns:   0 if a monster was successfully placed
::            1 if no monster could be placed
::------------------------------------------------------------------------------
:monsterPlaceNew
call :popm
set "monster_id=!errorlevel!"
if "!monster_id!"=="-1" exit /b 1

set "monster=monsters[%monster_id%]"
set "coord=%~1"
for /f "tokens=1,2 delims=;" %%A in ("%coord%") do (
    set "coord.y=%%A"
    set "coord.x=%%B"
)

set "%monster%.pos.y=%coord.y%"
set "%monster%.pos.x=%coord.x%"
set "%monster%.creature_id=%~2"

set /a "maxxed_out=!creatures_list[%~2].defenses! & %config.monsters.defense.cd_max_hp%"
if not "%maxxed_out%"=="0" (
    call dice.cmd :maxDiceRoll !creatures_list[%~2].hit_die.dice! !creatures_list[%~2].hit_die.sides!
) else (
    call dice.cmd :diceRoll !creatures_list[%~2].hit_die.dice! !creatures_list[%~2].hit_die.sides!
)

set /a %monster%.speed=!creatures_list[%~2].speed!-10+%py.flags.speed%
set "%monster%.stunned_amount=0"
call dungeon.cmd :coordDistanceBetween "py.pos" "coord"
set "%monster.distance_from_player=!errorlevel!"
set "%monster%.lit=false"

set "dg.floor[%coord.y%][%coord.x%].creature_id=%monster_id%"
if "%~3"=="true" (
    if "!creatures_list[%~2].sleep_counter!"=="0" (
        set "%monster%.sleep_count=0"
    ) else (
        set /a rnd_sleep=!creatures_list[%~2].sleep_counter!*10
        call rng.cmd :randomNumber !rnd_sleep!
        set /a %monster%.sleep_count=!creatures_list[%~2].sleep_counter*2+!errorlevel!
    )
)
exit /b 0

::------------------------------------------------------------------------------
:: Places a monster at a given location
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:monsterPlaceWinning
if "%game.total_winner%"=="true" exit /b

:monsterPlaceWinningDoLoop
set /a rnd_dec=%dg.height%-2
call rng.cmd :randomNumber %rnd_dec%
set "coord.y=!errorlevel!"
set /a rnd_dec=%dg.width%-2
call rng.cmd :randomNumber %rnd_dec%
set "coord.x=!errorlevel!"
set "coord=%coord.y%;%coord.x%"

set "space_free=1"
if !dg.floor[%coord.y%][%coord.x%].feature_id! GEQ %min_closed_space% set "space_free=0"
if not "!dg.floor[%coord.y%][%coord.x%].creature_id!"=="0" set "space_free=0"
if not "!dg.floor[%coord.y%][%coord.x%].treasure_id!"=="0" set "space_free=0"
call dungeon.cmd :coordDistanceBetween "coord" "py.pos"
if !errorlevel! LEQ %config.monsters.mon_max_sight% set "space_free=0"
if "!space_free!"=="0" goto :monsterPlaceWinningDoLoop

call rng.cmd :randomNumber %config.monsters.mon_endgame_monsters%
set /a creature_id=!errorlevel! - 1 + !monster_levels[%mon_max_levels%]!

call :popm
set "monster_id=!errorlevel!"
:: The original C code runs abort(), which kills the program entirely
if "!monster_id!"=="-1" exit /b 1

set "monster=monsters[%monster_id%]"
set "%monster%.pos.y=%coord.y%"
set "%monster%.pos.x=%coord.x%"
set "%monster%.creature_id=%creature_id%"

set /a "maxxed_out=!creatures_list%creature_id%].defenses! & %config.monsters.defense.cd_max_hp%"
if not "%maxxed_out%"=="0" (
    call dice.cmd :maxDiceRoll !creatures_list[%creature_id%].hit_die.dice! !creatures_list[%creature_id%].hit_die.sides!
) else (
    call dice.cmd :diceRoll !creatures_list[%creature_id%].hit_die.dice! !creatures_list[%creature_id%].hit_die.sides!
)

set /a %monster%.speed=!creatures_list[%creature_id%].speed! - 10 + %py.flags.speed%
set "%monster%.stunned_amount=0"
call dungeon.cmd :coordDistanceBetween "py.pos" "coord"
set "%monster.distance_from_player=!errorlevel!"
set "dg.floor[%coord.y%][%coord.x%].creature_id=%monster_id%"
set "%monster%.sleep_count=0"
exit /b

::------------------------------------------------------------------------------
:: Returns a monster suitable to be placed at a specified level. This makes
:: high-level monsters slightly more common than low-level monsters at any
:: given level.
::
:: Arguments: %1 - The target level for the monster
:: Returns:   The index of creatures_list that holds the monster
::------------------------------------------------------------------------------
:monsterGetOneSuitableForLevel
set "level=%~1"
if "%level%"=="0" (
    call rng.cmd :randomNumber !monster_levels[0]!
    set /a counter_dec=!errorlevel!-1
    exit /b !counter_dec!
)

if %level% GTR %mon_max_levels% set "level=%mon_max_levels%"

call rng.cmd :randomNumber %config.monsters.mon_chance_of_nasty%
if "!errorlevel!"=="1" (
    call game.cmd :randomNumberNormalDistribution 0 4
    set "abs_distribution=!errorlevel!"
    if !abs_distribution! LSS 0 set /a abs_distribution*=-1
    set /a level=!abs_distribution!+1
    if !level! GTR %mon_max_levels% set "level=%mon_max_levels%"
) else (
    set /a num=!monster_levels[%level%]!-!monster_levels[0]!
    call rng.cmd :randomNumber !num!
    set /a i=!errorlevel!-1
    call rng.cmd :randomNumber !num!
    set /a j=!errorlevel!-1
    if !j! GTR !i! set "i=!j!"
    set /a i_offset=!i!+!monster_levels[0]!
    
    REM TODO: I'm *pretty* sure I can do this, but double-check...
    set /a level=creatures_list[i_offset].level
)

set /a counter_dec=!level!-1
set /a level_offset=!monster_levels[%level%]-!monster_levels[%counter_dec%]!
call rng.cmd :randomNumber !level_offset!
set /a rnd_mon=!errorlevel! - 1 + !monster_levels[%counter_dec%]!
exit /b !rnd_mon!

::------------------------------------------------------------------------------
:: Allocates a random monster or monsters
::
:: Arguments: %1 - The number of monsters to place
::            %2 - The minimum distance from the player to place the monster
::            %3 - Indicates if the monster is spawned in while asleep
:: Returns:   None
::------------------------------------------------------------------------------
:monsterPlaceNewWithinDistance
set /a "position.y=0", "position.x=0"
set "sleeping=%~3"

for /L %%A in (1,1,%~1) do (
    call :newRandomPosition %~2

    call :monsterGetOneSuitableForLevel %dg.current_level%
    set "l=!errorlevel!"
    for /F %%L in ("!l!") do (
        REM Spawn dragons while sleeping to give the player a chance
        if /I "!creatures_list[%%L].sprite!"=="d" set "sleeping=true"
    )

    call :monsterPlaceNew "!position!" "!l!" "!sleeping!"
)
exit /b

:newRandomPosition
set /a counter_dec=%dg.height%-2
call rng.cmd :randomNumber %counter_dec%
set "position.y=!errorlevel!"
set /a counter_dec=%dg.weight%-2
call rng.cmd :randomNumber %counter_dec%
set "position.x=!errorlevel!"
set "position=%position.y%;%position.x%"

set "replace_monster=0"
if !dg.floor[%position.y%][%position.x%].feature_id! GEQ %min_closed_space% set "replace_monster=1"
if not "!dg.floor[%position.y%][%position.x%].creature_id!"=="0" set "replace_monster=1"
call dungeon.cmd :coordDistanceBetween "position" "py.pos"
if !errorlevel! LEQ %~1 set "replace_monster=1"
if "!replace_monster!"=="1" goto :newRandomPosition
exit /b

:placeMonsterAdjacentTo
exit /b

:monsterSummon
exit /b

:monsterSummonUndead
exit /b

:compactMonsters
exit /b
