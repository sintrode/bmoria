@echo off
:: Weird hack needed because of how :compactMonsters is called
set "hack_monptr=-1"
call %*
exit /b

::------------------------------------------------------------------------------
:: Determine if the monster is visible
::
:: Arguments: %1 - A reference to the monster
:: Returns:   0 if the monster can be seen
::            1 if the monster is invisible
::------------------------------------------------------------------------------
:monsterIsVisible
set "visible=1"
set "monster.pos.y=!%~1.pos.y!"
set "monster.pos.x=!%~1.pos.x!"
set "monster.creature_id=!%~1.creature_id!"

set "tile=dg.floor[%monster.pos.y%][%monster.pos.x%]"
set "creature=creatures_list[%monster.creature_id%]"

set "normal_sight=0"
if "!%tile%.permanent_light!"=="true" set "normal_sight=1"
if "!%tile%.temporary_light!"=="true" set "normal_sight=1"
if not "%py.running_tracker%"=="0" (
    if !%~1.distance_from_player! LSS 2 (
        if "%py.carrying_light%"=="true" (
            set "normal_sight=1"
        )
    )
)

set "infra_vision=0"
if %py.flags.see_infra% GTR 0 (
    if !%~1.distance_from_player! LEQ %py.flags.see_infra% (
        set /a "infra_defense=!%~1.defenses! & %config.monsters.defense.cd_infra%"
        if not "!infra_defense!"=="0" (
            set "infra_vision=1"
        )
    )
)

if "!normal_sight!"=="1" (
    set /a "moves_invisibly=!%~1.movement! & %config.monsters.move.cm_invisible%"
    if "!moves_invisibly!"=="0" (
        set "visible=0"
    ) else if "%py.flags.see_invisible%"=="true" (
        set "visible=0"
        set /a "creature_recall[!%~1.creature_id!].movement|=%config.monsters.move.cm_invisible%"
    )
) else if "!infra_vision!"=="1" (
    set "visible=0"
    set /a "creature_recall[!%~1.creature_id!].defenses|=%config.monsters.move.cd_infra%"
)

set "normal_sight="
set "infra_vision="
exit /b !visible!

::------------------------------------------------------------------------------
:: Update the screen when the monsters move about
::
:: Arguments: %1 - The ID of the monster that is moving
:: Returns:   None
::------------------------------------------------------------------------------
:monsterUpdateVisibility
set "visible=1"
set "monster=monsters[%~1]"

if !%monster%.distance_from_player! LEQ %config.monsters.mon_max_sight% (
    set /a "is_blind=%py.flags.status% & %config.player.status.py.blind%"
    if "!is_blind!"=="0" (
        call ui.cmd :coordInsidePanel "!%~1.pos.y!;!%~1.pos.x!"
        if "!errorlevel!"=="0" (
            if "%game.wizard_mode%"=="true" (
                set "visible=0"
            ) else (
                call dungeon_los.cmd :los "%py.pos.y%;%py.pos.x%" "!%~1.pos.y!;!%~1.pos.x!"
                if "!errorlevel!"=="0" (
                    call :monsterIsVisible "%~1"
                    set "visible=!errorlevel!"
                )
            )
        )
    )
)

set "coord=!%~1.pos.y!;!%~1.pos.x!"
if "!visible!"=="0" (
    if "!%~1.lit!"=="false" (
        call player.cmd :playerDisturb 1 0
        set "%~1.lit=true"
        call dungeon.cmd :dungeonLiteSpot "coord"
        set "screen_has_changed=true"
    )
) else if "!%~1.lit!"=="true" (
    set "%~1.lit=false"
    call dungeon.cmd :dungeonLiteSpot "coord"
    set "screen_has_changed=true"
)
exit /b

::------------------------------------------------------------------------------
:: Determine the number of moves that the monster is allowed to make this turn
::
:: Arguments: %1 - The monster's speed
:: Returns:   The number of moves this turn
::------------------------------------------------------------------------------
:monsterMovementRate
if %~1 GTR 0 (
    if not "%py.flags.rest%"=="0" (
        exit /b 1
    )
    exit /b %~1
)

:: Speed must be negative here
set "rate=0"
set /a turn_speed=%dg.game_turn% %% (2 - %~1)
if "%turn_speed%"=="0" set "rate=1"
set "turn_speed="
exit /b %rate%

::------------------------------------------------------------------------------
:: Makes sure a new creature gets lit properly
::
:: Arguments: %1 - The coordinates of the new monster
:: Returns:   0 if the new monster is lit
::            1 if the new monster is either not visible or not present
::------------------------------------------------------------------------------
:monsterMakeVisible
for /f "tokens=1,2 delims=;" %%A in ("%~1") do (
    set "monster_id=!dg.floor[%%~A][%%~B].creature_id!"
)
if !monster_id! LEQ 1 exit /b 1
call :monsterUpdateVisibility !monster_id!
if "!monsters[%monster_id%].lit!"=="true" exit /b 0
exit /b 1

:monsterGetMoveDirection
exit /b

:monsterPrintAttackDescription
exit /b

:monsterConfuseOnAttack
exit /b

:monsterAttackPlayer
exit /b

:monsterOpenDoor
exit /b

:glyphOfWardingProtection
exit /b

:monsterMovesOnPlayer
exit /b

:monsterAllowedToMove
exit /b

:makeMove
exit /b

:monsterCanCastSpells
exit /b

:monsterExecuteCastingOfSpell
exit /b

:monsterCastSpell
exit /b

:monsterMultiply
exit /b

:monsterMultiplyCritter
exit /b

:monsterMoveOutOfWall
exit /b

:monsterMoveUndead
exit /b

:monsterMoveConfused
exit /b

:monsterDoMove
exit /b

:monsterMoveRandomly
exit /b

:monsterMoveNormally
exit /b

:monsterAttackWithoutMoving
exit /b

:monsterMove
exit /b

:memoryUpdateRecall
exit /b

:monsterAttackingUpdate
exit /b

:updateMonsters
exit /b

:monsterTakeHit
exit /b

:monsterDeathItemDropType
exit /b

:monsterDeathItemDropCount
exit /b

:monsterDeath
exit /b

:printMonsterActionText
exit /b

:monsterNameDescription
exit /b

:monsterSleep
exit /b

:executeAttackOnPlayer
exit /b
