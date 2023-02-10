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

::------------------------------------------------------------------------------
:: Place a monsters next to specified coordinates
::
:: Arguments: %1 - The ID of the monster to place
::            %2 - A reference to the coordinates of the placement center
::            %3 - Indicates if the monster is spawned in while asleep
:: Returns:   0 if the monster was successfully placed
::            1 if there was an issue placing the monster
::------------------------------------------------------------------------------
:placeMonsterAdjacentTo
set "placed=1"
call helpers.cmd :expandCoordName %2
for /L %%A in (0,1,9) do (
    call rng.cmd :randomNumber 3
    set /a position.y=!%~2.y! - 2 + !errorlevel!
    call rng.cmd :randomNumber 3
    set /a position.x=!%~2.x! - 2 + !errorlevel!
    set "position=!position.y!;!position.x!"

    call dungeon.cmd :coordInBounds "position"
    for %%X in ("!position.x! !position.y!") do (
        if !dg.floor[%%Y][%%X].feature_id! LEQ %max_open_space% (
            if "!dg.floor[%%Y][%%X].creature_id!"=="0" (
                call :monsterPlaceNew "!position!" "%~1" "%~3"
                if "!errorlevel!"=="1" exit /b 1

                set "%~2.y=!position.y!"
                set "%~2.x=!position.x!"
                exit /b 0
            )
        )
    )
)
exit /b !placed!

::------------------------------------------------------------------------------
:: A wrapper for :placeMonsterAdjacentTo
::
:: Arguments: %1 - A reference to the coordinates to place the monster near
::            %2 - Indicates if the monster is spawned in while asleep
:: Returns:   0 if the monster was successfully placed
::            1 if there was an issue placing the monster
::------------------------------------------------------------------------------
:monsterSummon
set /a tmp_max_level=%dg.current_level%+%config.monsters.mon_summoned_level_adjust%
call :monsterGetOneSuitableForLevel %tmp_max_level%
call :placeMonsterAdjacentTo !errorlevel! %*
exit /b !errorlevel!

::------------------------------------------------------------------------------
:: Places undead adjacent to a specified location
::
:: Arguments: %1 - A reference to the coordinates to place the undear near
:: Returns:   0 if the monster was successfully placed
::            1 if there was an issue placing the monster
::------------------------------------------------------------------------------
:monsterSummonUndead
set "max_levels=!monster_levels[%mon_max_levels%]!"

:monsterSummonUndeadDoLoop
call rng.cmd :randomNumber %max_levels%
set /a monster_id=!errorlevel!-1
for /L %%A in (0,1,19) do (
    for /F "delims=" %%B in ("!monster_id!") do (
        set /a "is_undead=!creatures_list[%%B].defenses! & %config.monsters.defense.cd_undead%"
    )
    if not "!is_undead!"=="0" (
        set "max_levels=20"
        goto :monsterSummonUndeadAfterForLoop
    ) else (
        set /a monster_id+=1
        if !monster_id! GTR !max_levels! goto :monsterSummonUndeadAfterForLoop
    )
)
:monsterSummonUndeadAfterForLoop
if not "!max_levels!"=="0" goto :monsterSummonUndeadDoLoop
call :placeMonsterAdjacentTo !monster_id! %1 "false"
exit /b !errorlevel!

::------------------------------------------------------------------------------
:: Remove any unnecessary monsters
::
:: Arguments: None
:: Returns:   0 if any monsters were deleted
::            1 if no monsters could be deleted
::------------------------------------------------------------------------------
:compactMonsters
call ui_io.cmd :printMessage "Compacting monsters..."
set "cur_dis=66"
set "delete_any=false"

:compactMonstersWhileLoop
if "!delete_any!"=="true" exit /b 0
set /a counter_dec=!next_free_monster_id!-1
for /L %%A in (!counter_dec!,-1,%config.monsters.mon_min_index_id%) do (
    for /f "delims=" %%M in ("!monsters[%%A],creature_id!") do (
        set /a "is_winning_creature=!creatures_list[%%M].movement! & %config.monsters.move.cm_win%"
    )
    REM Never compact away the Balrog
    if "!is_winning_creature!"=="0" (
        if !hack_monptr! LSS %%A (
            REM TODO: Rewrite this, apparently. The original C code is also ashamed of it.
            call dungeon.cmd :dungeonDeleteMonster %%A
            set "delete_any=true"
        ) else (
            call dungeon.cmd :dungeonRemoveMonsterFromLevel %%A
        )
    )

    if "!delete_any!"=="false" (
        set /a cur_dis-=6

        if !cur_dis! LSS 0 exit /b 1
    )
)
goto :compactMonstersWhileLoop