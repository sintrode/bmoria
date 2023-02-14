@echo off
call %*
exit /b

::------------------------------------------------------------------------------
:: Calculates a player's ability to disarm a trap
::
:: Arguments: None
:: Returns:   The likelihood that the player will be able to disarm a trap
::------------------------------------------------------------------------------
:playerTrapDisarmAbility
set "ability=%py.misc.disarm%"
set /a ability+=2
call player_stats.cmd :playerDisarmAdjustment
set /a ability*=!errorlevel!
call player_stats.cmd :playerStatAdjustmentWisdomIntelligence %PlayerAttr.a_int%
set /a ability+=!errorlevel!
set /a ability+=!class_level_adj[%py.misc.class_id%][%PlayerClassLevelAdj.disarm%]!*%py.misc.level%/3

call player.cmd :playerNoLight
if "!errorlevel!"=="0" set /a ability/=10
if %py.flags.blind% GTR 0 set /a ability/=10
if %py.flags.confused% GTR 0 set /a ability/=10
if %py.flags.image% GTR 0 set /a ability/=10
exit /b !ability!

::------------------------------------------------------------------------------
:: Attempt to disarm a trap on the floor
::
:: Arguments: %1 - The coordinates of the trap
::            %2 - The odds of the player disarming the trap successfully
::            %3 - The floor where the trap was first found
::            %4 - The direction that the player is facing
::            %5 - The amount of EXP that the player gets for disarming a trap
:: Returns:   None
::------------------------------------------------------------------------------
:playerDisarmFloorTrap
set "confused=%py.flags.confused%"

set /a odds_adj=%~2 + 100 - %~3
call rng.cmd :randomNumber 100
if !odds_adj! GTR !errorlevel! (
    call ui_io.cmd :printMessage "You have disarmed the trap."
    set /a py.misc.exp+=%~5
    set "coord=%~1"
    call dungeon.cmd :dungeonDeleteObject "coord"

    REM Move onto the trap even if confused
    set "py.flags.confused=0"
    call player_move.cmd :playerMove "%~4" "false"
    set "py.flags.confused=!confused!"

    call ui.cmd :displayCharacterExperience
    exit /b

    if %~2 GTR 5 (
        call rng.cmd :randomNumber %~2
        if !errorlevel! GTR 5 (
            call ui_io.cmd :printMessageNoCommandInterrupt "You failed to disarm the trap."
            exit /b
        )
    )

    call ui_io.cmd :printMessage "You set the trap off."

    REM Move onto the trap even if confused
    set "py.flags.confused=0"
    call player_move.cmd :playerMove "%~4" "false"
    set "py.flags.confused=!confused!"
)
exit /b

:playerDisarmChestTrap
exit /b

::------------------------------------------------------------------------------
:: Disarms a trap
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerDisarmTrap
call game.cmd :getDirectionWithMemory "CNIL" "direction" || exit /b

set "coord=%py.pos.y%;%py.pos.x%"
call player.cmd :playerMovePosition !direction! "coord"

for /f "tokens=1,2 delims=;" %%A in ("!coord!") do set "tile=dg.floor[%%A][%%B]"
set "no_disarm=false"
set "tile_treasure_id=!%tile%.treasure_id!"

set "is_blocked=0"
if !%tile%.creature_id! GTR 1 set /a is_blocked+=1
if !%tile%.treasure_id! GTR 1 set /a is_blocked+=1
if "!game.treasure.list[%tile_treasure_id%].category_id!"=="%tv_vis_trap%" set /a is_blocked+=1
if "!game.treasure.list[%tile_treasure_id%].category_id!"=="%tv_chest%" set /a is_blocked+=1

:: It's 3 and not 4 because it can't be both a visible trap and a chest
if "!is_blocked!"="3" (
    call identification.cmd :objectBlockedByMonster !%tile%.creature_id!
) else if not "%tile_treasure_id%"=="0" (
    call :playerTrapDisarmAbility
    set "disarm_ability=!errorlevel!"

    if "!game.treasure.list[%tile_treasure_id%].category_id!"=="%TV_VIS_TRAP%" (
        call :playerDisarmFloorTrap "!coord!" !disarm_ability! !game.treasure.list[%tile_treasure_id%].depth_first_found! !direction! !game.treasure.list[%tile_treasure_id%].misc_use!
    ) else if "!game.treasure.list[%tile_treasure_id%].category_id!"=="%TV_CHEST%" (
        call :playerDisarmChestTrap "!coord!" !disarm_ability! "game.treasure.list[%tile_treasure_id%]"
    ) else (
        set "no_disarm=true"
    )
) else (
    set "no_disarm=true"
)

if "!no_disarm!"=="true" (
    call ui_io.cmd :printMessage "I do not see anything to disarm there."
    set "game.player_free_turn=true"
)
exit /b

:chestLooseStrength
exit /b

:chestPoison
exit /b

:chestParalysed
exit /b

:chestSummonMonster
exit /b

:chestExplode
exit /b

:chestTrap
exit /b
