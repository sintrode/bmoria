:: TODO: Merge the four Cure subroutines into one subroutine and pass the
:: impairment being cured
@echo off
call %*
exit /b

::------------------------------------------------------------------------------
:: Cure the player's confusion
::
:: Arguments: None
:: Returns:   0 if the player is no longer confused
::            1 if the spell was cast when the player was not confused
::------------------------------------------------------------------------------
:playerCureConfusion
if %py.flags.confused% GTR 1 (
    set "py.flags.confused=1"
    exit /b 0
)
exit /b 1

::------------------------------------------------------------------------------
:: Cure the player's blindness
::
:: Arguments: None
:: Returns:   0 if the player is no longer blind
::            1 if the spell was cast when the player was not blind
::------------------------------------------------------------------------------
:playerCureBlindness
if %py.flags.blind% GTR 1 (
    set "py.flags.blind=1"
    exit /b 0
)
exit /b 1

::------------------------------------------------------------------------------
:: Cure the player's poisoning
::
:: Arguments: None
:: Returns:   0 if the player is no longer poisoned
::            1 if the spell was cast when the player was not poisoned
::------------------------------------------------------------------------------
:playerCurePoison
if %py.flags.poisoned% GTR 1 (
    set "py.flags.poisoned=1"
    exit /b 0
)
exit /b 1

::------------------------------------------------------------------------------
:: Cure the player's fear
::
:: Arguments: None
:: Returns:   0 if the player is no longer afraid
::            1 if the spell was cast when the player was not afraid
::------------------------------------------------------------------------------
:playerRemoveFear
if %py.flags.afraid% GTR 1 (
    set "py.flags.afraid=1"
    exit /b 0
)
exit /b 1

::------------------------------------------------------------------------------
:: Protect the player from evil for a number of turns equal to the player's
:: level times 3, plus a random number between 1 and 25
::
:: Arguments: None
:: Returns:   0 if the player is no longer vulnerable to evil
::            1 if the player was already protected from evil
::------------------------------------------------------------------------------
:playerProtectEvil
if "%py.flags.protect_evil%"=="0" (
    set "is_protected=0"
) else (
    set "is_protected=1"
)

call rnd.cmd :randomNumber 25
set /a py.flags.protect_evil+=!errorlevel! + 3 * %py.misc.level%
exit /b !is_protected!

::------------------------------------------------------------------------------
:: Bless the player
::
:: Arguments: %1 - The number of turns to add a blessing
:: Returns:   None
::------------------------------------------------------------------------------
:playerBless
set /a py.flags.blessed+=%~1
exit /b

::------------------------------------------------------------------------------
:: Allows the player to detect invisible monsters for a period of time
::
:: Arguments: %1 - The number of turns to add detection
:: Returns:   None
::------------------------------------------------------------------------------
:playerDetectInvisible
set /a py.flags.detect_invisible=%~1
exit /b

::------------------------------------------------------------------------------
:: Sometimes magic items have properties that allow them to do more damage
::
:: Arguments: %1 - A reference to the item to check
::            %2 - The base damage that a weapon will do without properties
::            %3 - The ID of the monster being attacked
:: Returns:   The adjusted damage of the weapon based on its properties
::------------------------------------------------------------------------------
:itemMagicAbilityDamage
:: Get a load of everything I need to do in order to simulate
:: if (is_ego_weapon && (is_projectile || is_hafted_sword || is_flask)) {
set /a "ego_weapon_flag=!%~1.flags! & %config.treasure.flags.tr_ego_weapon%"
if "%ego_weapon_flag%"=="0" exit /b %~2
for %%A in (is_ego_weapon is_projectile is_hafted_sword is_flask) do set "%%~A=0"
if !%~1.category_id! GEQ %tv_sling_ammo% (
    if !%~1.category_id! LEQ %tv_arrow% (
        set "is_projectile=1"
    )
)
if !%~1.category_id! GEQ %tv_hafted_sword% (
    if !%~1.category_id! LEQ %tv_sword% (
        set "is_hafted_sword=1"
    )
)
if "!%~1.category_id!"=="%tv_flask%" set "is_flask=1"
set /a is_special_ego_weapon_type=!is_projectile!+!is_hafted_sword!+!is_flask!
if "!is_special_ego_weapon_type!"=="0" exit /b %~2

:: Okay, now that that's done, match monster types to their ego weapon types
set "total_damage=%~2"
set "creature=creatures_list[%~3]"
set "memory=creature_recall[%~3]"

:: TODO: Genericize
set /a "is_right_monster=!%creature%.defenses! & %config.monsters.defense.cd_dragon%"
set /a "is_right_weapon=!%~1.flags! & %config.treasure.flags.tr_slay_dragon%"
if !is_right_monster! NEQ 0 (
    if !is_right_weapon! NEQ 0 (
        set /a "%memory%.defenses|=%config.monsters.defense.cd_dragon%"
        set /a total_damage*=4
    )
)

set /a "is_right_monster=!%creature%.defenses! & %config.monsters.defense.cd_undead%"
set /a "is_right_weapon=!%~1.flags! & %config.treasure.flags.tr_slay_undead%"
if !is_right_monster! NEQ 0 (
    if !is_right_weapon! NEQ 0 (
        set /a "%memory%.defenses|=%config.monsters.defense.cd_undead%"
        set /a total_damage*=3
    )
)
set /a "is_right_monster=!%creature%.defenses! & %config.monsters.defense.cd_animal%"
set /a "is_right_weapon=!%~1.flags! & %config.treasure.flags.tr_slay_animal%"
if !is_right_monster! NEQ 0 (
    if !is_right_weapon! NEQ 0 (
        set /a "%memory%.defenses|=%config.monsters.defense.cd_animal%"
        set /a total_damage*=2
    )
)
set /a "is_right_monster=!%creature%.defenses! & %config.monsters.defense.cd_evil%"
set /a "is_right_weapon=!%~1.flags! & %config.treasure.flags.tr_slay_evil%"
if !is_right_monster! NEQ 0 (
    if !is_right_weapon! NEQ 0 (
        set /a "%memory%.defenses|=%config.monsters.defense.cd_evil%"
        set /a total_damage*=2
    )
)
set /a "is_right_monster=!%creature%.defenses! & %config.monsters.defense.cd_frost%"
set /a "is_right_weapon=!%~1.flags! & %config.treasure.flags.tr_frost_brand%"
if !is_right_monster! NEQ 0 (
    if !is_right_weapon! NEQ 0 (
        set /a "%memory%.defenses|=%config.monsters.defense.cd_frost%"
        set /a total_damage*=3/2
    )
)
set /a "is_right_monster=!%creature%.defenses! & %config.monsters.defense.cd_fire%"
set /a "is_right_weapon=!%~1.flags! & %config.treasure.flags.tr_flame_tongue%"
if !is_right_monster! NEQ 0 (
    if !is_right_weapon! NEQ 0 (
        set /a "%memory%.defenses|=%config.monsters.defense.cd_fire%"
        set /a total_damage*=3/2
    )
)

exit /b !total_damage!