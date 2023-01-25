@echo off
call %*
exit /b

::------------------------------------------------------------------------------
:: Bash open a door or chest
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerBash
call game.cmd :getDirectionWithMemory "CNIL" "dir" || exit /b
if %py.flags.confused% GTR 0 (
    call ui_io.cmd :printMessage "You are confused."
    call game.cmd :getRandomDirection
    set "dir=!errorlevel!"
)

set "coord.x=%py.pos.x%"
set "coord.y=%py.pos.y%"
call player.cmd :playerMovePosition "%dir%" "coord"

if !dg.floor[%coord.y%][%coord.x%].creature_id! GTR 1 (
    call :playerBashPosition "coord"
    exit /b
)

set "tile.treasure_id=!dg.floor[%coord.y%][%coord.x%].treasure_id!"
if not "%tile.treasure_id%"=="0" (
    if "!game.treasure.list[%tile.treasure_id%].category_id!"=="%tv_closed_door%" (
        call :playerBashClosedDoor "coord" "%dir%" "dg.floor[%coord.y%][%coord.x%]" "game.treasure.list[%tile.treasure_id%]"
    ) else if "!game.treasure.list[%tile.treasure_id%].category_id!"=="%tv_chest%" (
        call :playerBashClosedChest "game.treasure.list[%tile.treasure_id%]"
    ) else (
        call ui_io.cmd :printMessage "You bash it, but nothing interesting happens."
    )
    exit /b
)

if !dg.floor[%coord.y%][%coord.x%].feature_id! LSS %min_cave_wall% (
    call ui_io.cmd :printMessage "You bash at empty space."
    exit /b
)

:: Same message for wall as for secret door
call ui_io.cmd :printMessage "You bash at it, but nothing interesting happens."
exit /b

::------------------------------------------------------------------------------
:: Make a bash attack on something or someone
::
:: Arguments: %1 - Coordinates of the monster
:: Returns:   None
::------------------------------------------------------------------------------
:playerBashAttack
for /f "tokens=1,2 delims=;" %%A in ("%~1") do (
    set "monster_id=!dg.floor[%%A][%%B].creature_id!"
)

:: I'm only doing this to type less and so that the lines fit in 80 characters
:: because I've _TOTALLY_ been making an effort to do that
set "monsters[%monster_id%].sleep_count=0"
for %%A in (creature_id lit sleep_count hp stunned_amount) do (
    set "monster.%%A=!monsters[%monster_id%].%%A!"
)
for %%A in (name ac "hit_die.dice" "hit_die.sides") do (
    set "creature.%%~A=!creatures_list[%monster.creature_id%].%%~A!"
)

if "%monster.lit%"=="false" (
    set "name=it"
) else (
    set "name=the %creature.name%"
)

set "base_to_hit=!py.stats.used[%PlayerAttr.a_str%]!"
set /a base_to_hit+=(!py.inventory[%PlayerEquipment.arm%].weight! / 2)
set /a base_to_hit+=(%py.misc.weight% / 10)

if "%monster.lit%"=="false" (
    set /a base_to_hit/=2
    set /a "base_to_hit-=!py.stats.used[%PlayerAttr.a_dex%]! * (%bth_per_plus_to_hit_adjust% - 1)"
    set /a "base_to_hit-=%py.misc.level% * !class_level_adj[%py.misc.class_id%][%PlayerClassLevelAdj.bth%]! / 2"
)

call player.cmd :playerTestBeingHit !base_to_hit! %py.misc.level% !py.stats.used[%PlayerAttr.a_dex%]! !creature.ac! %PlayerClassLevelAdj.bth%
if "!errorlevel!"=="0" (
    call ui_io.cmd :printMessage "You hit %name%."

    call dice.cmd :diceRoll !py.inventory[%PlayerEquipment.arm%].damage!
    set "damage=!errorlevel!"
    set /a weapon_weight=!py.inventory[%PlayerEquipment.arm%].weight! / 4 + !py.stats.used[%PlayerAttr.a_str%]!
    call player.cmd :playerWeaponCriticalBlow !weapon_weight! 0 !damage! %PlayerClassLevelAdj.bth%
    set "damage=!errorlevel!"
    set /a damage+=%py.misc.weight% / 60
    set /a damage+=3

    if !damage! LSS 0 set "damage=0"

    call monster.cmd :monsterTakeHit %monster_id% !damage!
    if !errorlevel! GEQ 0 (
        call ui_io.cmd :printMessage "You have slain !name!."
        call ui.cmd :displayCharacterExperience
    ) else (
        if "!name!"=="it" (
            set "name=It"
        ) else (
            set "name=T!name:~1!"
        )

        set /a "stunnable=!creature.defenses! & %config.monsters.defense.cd_max_hp%"
        if not "!stunnable!"=="0" (
            call dice.cmd :maxDiceRoll !creature.hit_die.dice! !creature.hit_die.sides!
            set "avg_max_hp=!errorlevel!"
        )
    )
) else (
    call ui_io.cmd :printMessage "You miss %name%."
)
exit /b

:playerBashPosition
exit /b

:playerBashClosedDoor
exit /b

:playerBashClosedChest
exit /b