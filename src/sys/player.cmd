@echo off
call %*
exit /b

::------------------------------------------------------------------------------
:: Manually set all player flags except confuse_monster to false
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerResetFlags
for %%A in (see_invisible teleport free_action slow_digest aggravate
            resistant_to_fire resistant_to_cold resistant_to_acid regenerate_hp
            resistant_to_light free_fall sustain_str sustain_int sustain_wis
            sustain_con sustain_dex sustain_chr) do (
    set "py.flags.%%~A=false"
)
exit /b

::------------------------------------------------------------------------------
:: Determines if the player is a man or a woman. Used for victory titles in the
:: postgame where the player is a King or a Queen. No idea why this needed to
:: be its own subroutine.
::
:: TODO: Change to :playerIsFemale so that I can just use the value directly
::
:: Arguments: None
:: Returns:   0 if the player is male
::            1 if the player is female
::------------------------------------------------------------------------------
:playerIsMale
set /a "is_male=^!%py.misc.gender%"
exit /b %is_male%

::------------------------------------------------------------------------------
:: Sets the player's gender. No idea why this needed to be its own subroutine.
:: TODO: update character.cmd to set the values directly
::
:: Argumets: %1 - Whether the character is male or female
:: Returns:  None
::------------------------------------------------------------------------------
:playerSetGender
if "%~1"=="true" (
    set "py.misc.gender=1"
) else (
    set "py.misc.gender=0"
)
exit /b

::------------------------------------------------------------------------------
:: Returns the word "Male" or "Female" based on the player's gender
::
:: Arguments: %1 - The variable to store the string in
::------------------------------------------------------------------------------
:playerGetGenderLabel
set "%~1=Female"
call :playerIsMale && set "%~1=Male"
exit /b

::------------------------------------------------------------------------------
:: Given a specific direction, moves the player there if possible
::
:: Arguments: %1 - The direction to move in
::            %2 - A reference to the current coordinates of the player
:: Returns:   0 if the player was able to be moved
::            1 if the player could not move there
::------------------------------------------------------------------------------
:playerMovePosition
call helpers.cmd :expandCoordName "%~2"
if "%~1"=="1" (
    set "new_coord.y=!%~1.y_inc!"
    set "new_coord.x=!%~1.x_dec!"
) else if "%~1"=="2" (
    set "new_coord.y=!%~1.y_inc!"
    set "new_coord.x=!%~1.x!"
) else if "%~1"=="3" (
    set "new_coord.y=!%~1.y_inc!"
    set "new_coord.x=!%~1.x_inc!"
) else if "%~1"=="4" (
    set "new_coord.y=!%~1.y!"
    set "new_coord.x=!%~1.x_dec!"
) else if "%~1"=="5" (
    set "new_coord.y=!%~1.y!"
    set "new_coord.x=!%~1.x!"
) else if "%~1"=="6" (
    set "new_coord.y=!%~1.y!"
    set "new_coord.x=!%~1.x_inc!"
) else if "%~1"=="7" (
    set "new_coord.y=!%~1.y_dec!"
    set "new_coord.x=!%~1.x_dec!"
) else if "%~1"=="8" (
    set "new_coord.y=!%~1.y_dec!"
    set "new_coord.x=!%~1.x!"
) else if "%~1"=="9" (
    set "new_coord.y=!%~1.y_dec!"
    set "new_coord.x=!%~1.x_inc!"
) else (
    set "new_coord.y=0"
    set "new_coord.x=0"
)

set "can_move=1"

if !new_coord.y! GEQ 0 (
    if !new_coord.y! LSS %dg.height% (
        if !new_coord.x! GEQ 0 (
            if !new_coord.x! LSS %dg.width% (
                set "coord.y=!new_coord.y!"
                set "coord.x=!new_coord.x!"
                set "can_move=0"
            )
        )
    )
)
exit /b !can_move!

::------------------------------------------------------------------------------
:: Teleports the player to a new location
::
:: Arguments: %1 - The maximum distance to move the player
:: Returns:   None
::------------------------------------------------------------------------------
:playerTeleport
call rng.cmd :randomNumber %dg.height%
set /a location.y=!errorlevel!-1
call rng.cmd :randomNumber %dg.width%
set /a location.x=!errorlevel!-1
set "location=%location.y%;%location.x%"

:playerTeleportWhileLoop
call dungeon.cmd :coordDistanceBetween "location" "py.pos"
if !errorlevel! LEQ !%~1 goto :playerTeleportAfterWhileLoop
set /a location.y+=(%py.pos.y% - %location.y%) / 2
set /a location.x+=(%py.pos.x% - %location.x%) / 2
goto :playerTeleportWhileLoop

if !dg.floor[%location.y%][%location.x%].feature_id! GEQ %MIN_CLOSED_SPACE% goto :playerTeleport
if !dg.floor[%location.y%][%location.x%].creature_id! GEQ 2 goto :playerTeleport

:: TODO: Confirm that every time I've updated py.pos.x or py.pos.y
::       that I've actually updated py.pos as well
call helpers.cmd :expandCoordName "py.pos"
for /L %%Y in (!py.pos.y_dec!,1,!py.pos.y_inc!) do (
    for /L %%X in (!py.pos.x_dec!,1,!py.pos.x_inc!) (
        set "dg.floor[%%Y][%%X].temporary_light=false"
        set "spot=%%Y;%%X"
        call dungeon.cmd :dungeonLiteSpot "spot"
    )
)
call dungeon.cmd :dungeonLiteSpot "py.pos"

set "py.pos.y=!location.y!"
set "py.pos.x=!location.x!"
set "py.pos=%py.pos.y%;%py.pos.x%"

call ui.cmd :dungeonResetView
call monster.cmd :updateMonsters "false"
set "game.teleport_player=false"
exit /b

::------------------------------------------------------------------------------
:: Checks to see if the player has no light
::
:: Arguments: None
:: Returns:   0 if the current tile is unlit
::            1 if the current tile has either temporary or permanent light
::------------------------------------------------------------------------------
:playerNoLight
if "!dg.floor[%py.pos.y%][%py.pos.x%].temporary_light!"=="true" exit /b 0
if "!dg.floor[%py.pos.y%][%py.pos.x%].permanent_light!"=="true" exit /b 0
exit /b 1

::------------------------------------------------------------------------------
:: Handles something interrupting the character
::
:: Arguments: %1 - The player receives a major, search-stopping disturbance
::            %2 - The player receives a minor, running-stopping disturbance
:: Returns:   None
::------------------------------------------------------------------------------
:playerDisturb
set "game.command_count=0"
if not "%~1"=="0" (
    set /a "was_searching=%py.flags.status% & %config.player.status.py_search%"
    if not "!was_searching!"=="0" call :playerSearchOff
)

if not "%py.flags.rest%"=="0" call :playerRestOff

set "was_running=0"
if not "%~2"=="0" set "was_running=1"
if not "%py.running_tracker%"=="0" set "was_running=1"
if "!was_running!"=="1" (
    set "py.running_tracker=0"
    call ui.cmd :dungeonResetView
)

call ui_io.cmd :flushInputBuffer
exit /b

::------------------------------------------------------------------------------
:: Puts the player into Search Mode
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerSearchOn
call :playerChangeSpeed 1
set /a "py.flags.status|=%config.player.status.py_search%"
call ui.cmd :printCharacterMovementState
call ui.cmd :printCharacterSpeed
set /a "py.flags.food_digested+=1"
exit /b

::------------------------------------------------------------------------------
:: Takes the player out of Search Mode
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerSearchOff
call ui.cmd :dungeonResetView
call :playerChangeSpeed -1
set /a "py.flags.status&=~%config.player.status.py_search%"
call ui.cmd :printCharacterMovementState
call ui.cmd :printCharacterSpeed
set /a "py.flags.food_digested-=1"
exit /b

::------------------------------------------------------------------------------
:: Lets the player rest to recover HP
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerRestOn
if %game.command_count% GTR 0 (
    set "rest_num=%game.command_count%"
    set "game.command_count=0"
) else (
    set "rest_num=0"
    call ui_io.cmd :putStringClearToEOL "Rest for how long?" "0;0"

    call ui_io.cmd :getStringInput "rest_str" "0;19" "5"
    if "!rest_str:0,1!"=="*" (
        set "rest_num=-32767"
    ) else (
        set "rest_num=!rest_str!"
    )
)

set "is_valid_rest_length=0"
if "!rest_num!"=="-32767" set "is_valid_rest_length=1"
if !rest_num! GTR 0 if !rest_num! LEQ 32767 set "is_valid_rest_length=1"
if "!is_valid_rest_length!"=="1" (
    set /a "is_searching=%py.flags.status% & %config.player.status.py_search%"
    if not "!is_searching!"=="0" (
        call :playerSearchOff
    )

    set "py.flags.rest=!rest_num!"
    set /a "py.flags.status|=%config.player.status.py_rest%"
    call ui.cmd :printCharacterMovementState
    set /a py.flags.food_digested-=1

    call ui_io.cmd :putStringClearToEOL "Press any key to stop resting" "0;0"
    call ui_io.cmd :putQIO
    exit /b
)

if not "!rest_num!"=="0" (
    call ui_io.cmd :printMessage "Invalid rest count."
)
call ui_io.cmd :messageLineClear
set "game.player_free_turn=true"
exit /b

::------------------------------------------------------------------------------
:: Lets the player stop resting
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerRestOff
set "py.flags.rest=0"
set /a "py.flags.status&=~%config.player.status.py_rest%"
call ui.cmd :printCharacterMovementState
call ui_io.cmd :printMessage "CNIL"
set /a py.flags.food_digested+=1
exit /b

::------------------------------------------------------------------------------
:: Sets the string that indicates how the player died
::
:: Arguments: %1 - The variable that will contain the death string
::            %2 - The name of the monster that killed the player
::            %3 - True if the monster moved to kill the player
:: Returns:   None
::------------------------------------------------------------------------------
:playerDiedFromString
set /a "is_balrog=%~3 & %config.monsters.move_cm_win%"
if not "!is_balrog!"=="0" (
    set "%~1=The %~2"
) else (
    set "monster_name=%~2"
    call helpers.cmd :isVowel !monster_name:~0,1!
    if "!errorlevel!"=="0" (
        set "%~1=an %~2"
    ) else (
        set "%~1=a %~2"
    )
)
exit /b

::------------------------------------------------------------------------------
:: Determine if the player was hit by a monster attack given the specific type
:: of attack used and the level of the creature
::
:: TODO: Rewrite entirely. This is admittedly exceptionally inelegant, but
::       switch statements in batch genuinely are pretty ugly even at their
::       most well-formed.
::
:: Arguments: %1 - The ID of the attack
::            %2 - The level of the attacking creature
:: Returns:   0 if the attack lands
::            1 if the attack misses
::------------------------------------------------------------------------------
:playerTestAttackHits
set "success=1"
set /a ac_total=%py.misc.ac%+%py.misc.magical_ac%

findstr /R "^:playerTestAttackHitsSwitch_%~1" "%~0" >nul && goto :playerTestAttackHitsSwitch_%~1
goto :playerTestAttackHitsSwitchEnd

:playerTestAttackHitsSwitch_1 %= normal attack =%
call :playerTestBeingHit 60 "%~2" %ac_total%  %class_misc_hit% && set "success=0"
goto :playerTestAttackHitsSwitchEnd

:playerTestAttackHitsSwitch_2 %= lose strength =%
call :playerTestBeingHit -3 "%~2" %ac_total%  %class_misc_hit% && set "success=0"
goto :playerTestAttackHitsSwitchEnd

:playerTestAttackHitsSwitch_3 %= confusion attack =%
:playerTestAttackHitsSwitch_4 %= fear attack =%
:playerTestAttackHitsSwitch_5 %= fire attack =%
:playerTestAttackHitsSwitch_7 %= cold attack =%
:playerTestAttackHitsSwitch_8 %= lightning attack =%
call :playerTestBeingHit 10 "%~2" %ac_total%  %class_misc_hit% && set "success=0"
goto :playerTestAttackHitsSwitchEnd

:playerTestAttackHitsSwitch_6  %= acid attack =%
:playerTestAttackHitsSwitch_9  %= corrosion attack =%
:playerTestAttackHitsSwitch_15 %= lose dexterity =%
:playerTestAttackHitsSwitch_16 %= lose constitution =%
call :playerTestBeingHit 0 "%~2" %ac_total%  %class_misc_hit% && set "success=0"
goto :playerTestAttackHitsSwitchEnd

:playerTestAttackHitsSwitch_10 %= blindness attack =%
:playerTestAttackHitsSwitch_11 %= paralysis attack =%
:playerTestAttackHitsSwitch_17 %= paralysis attack =%
:playerTestAttackHitsSwitch_18 %= paralysis attack =%
call :playerTestBeingHit 2 "%~2" %ac_total%  %class_misc_hit% && set "success=0"
goto :playerTestAttackHitsSwitchEnd

:playerTestAttackHitsSwitch_12 %= steal money =%
if %py.misc.au% GTR 0 (
    call :playerTestBeingHit 5 "%~2" %py.misc.level%  %class_misc_hit% && set "success=0"
)
goto :playerTestAttackHitsSwitchEnd

:playerTestAttackHitsSwitch_13 %= steal object =%
if %py.pack.unique_items% GTR 0 (
    call :playerTestBeingHit 2 "%~2" %py.misc.level%  %class_misc_hit% && set "success=0"
)
goto :playerTestAttackHitsSwitchEnd

:playerTestAttackHitsSwitch_14 %= poison attack =%
:playerTestAttackHitsSwitch_19 %= lose experience =%
:playerTestAttackHitsSwitch_22 %= eat food =%
:playerTestAttackHitsSwitch_23 %= eat light =%
call :playerTestBeingHit 5 "%~2" %ac_total%  %class_misc_hit% && set "success=0"
goto :playerTestAttackHitsSwitchEnd

:playerTestAttackHitsSwitch_20 %= aggravate monsters =%
:playerTestAttackHitsSwitch_99 %= blank =%
set "success=0"
goto :playerTestAttackHitsSwitchEnd

:playerTestAttackHitsSwitch_21 %= disenchant =%
call :playerTestBeingHit 20 "%~2" %ac_total%  %class_misc_hit% && set "success=0"
goto :playerTestAttackHitsSwitchEnd

:playerTestAttackHitsSwitch_24 %= eat charges =%
if %py.pack.unique_items% GTR 0 (
    call :playerTestBeingHit 15 "%~2" %ac_total%  %class_misc_hit% && set "success=0"
)
goto :playerTestAttackHitsSwitchEnd

:playerTestAttackHitsSwitchEnd
exit /b !success!

::------------------------------------------------------------------------------
:: Changes the speed of monsters relative to the player
::
:: Arguments: %1 - The amount to change the speed by
:: Returns:   None
::------------------------------------------------------------------------------
:playerChangeSpeed
set /a py.flags.speed+=%~1
set /a "py.flags.status|=%config.player.status.py.speed%"

for /L %%A in (%next_free_monster_id%,-1,%config.monsters.mon_min_index_id%) do (
    set /a monsters[%%A]+=%~1
)
exit /b

::------------------------------------------------------------------------------
:: When an item is worn or taken off, this re-adjusts the player bonuses with
:: cumulative effect; properties that depend on everything being worn are
:: recalculated by :playerRecalculateBonuses
::
:: Arguments: %1 - A reference to the item changing bonuses
::            %2 - 1 if the item is being worn, -1 if the item is being removed
:: Returns:   None
::------------------------------------------------------------------------------
:playerAdjustBonusesForItem
set /a amount=!%~1.misc_use!*%~2

set /a "flag_set=!%~1.flags!&%config.treasure.flags.tr_stats%"
if not "!flag_set!"=="0" (
    for /L %%A in (0,1,5) do (
        set /a "flag_stat=((1<<%%A) & !%~1.flags!)"
        if not "!flag_stat!"=="0" (
            call player_stats.cmd :playerStatBoost %%A %amount%
        )
    )
)

set /a "flag_set=!%~1.flags! & %config.treasure.flags.tr_search%"
if not "!flag_set!"=="0" (
    set /a py.misc.chance_in_search+=%amount%
    set /a py.misc.fos-=%amount%
)

set /a "flag_set=!%~1.flags! & %config.treasure.flags.tr_stealth%"
if not "!flag_set!"=="0" (
    set /a py.misc.stealth_factor+=%amount%
)

set /a "flag_set=!%~1.flags! & %config.treasure.flags.tr_speed%"
if not "!flag_set!"=="0" (
    REM The original code called for -%amount%, but --1 doesn't read as 1
    REM because everything is a string in batch
    set /a unamount=%amount%*-1
    call :playerChangeSpeed !unamount!
    set "unamount="
)

set /a "flag_set=!%~1.flags! & %config.treasure.flags.tr_blind%"
if not "!flag_set!"=="0" (
    if "%~2"=="1" (
        set /a py.flags.blind+=1000
    )
)

set /a "flag_set=!%~1.flags! & %config.treasure.flags.tr_timid%"
if not "!flag_set!"=="0" (
    if "%~2"=="1" (
        set /a py.flags.afraid+=50
    )
)

set /a "flag_set=!%~1.flags! & %config.treasure.flags.tr_infra%"
if not "!flag_set!"=="0" (
    set /a py.flags.see_infra+=%amount%
)
exit /b

::------------------------------------------------------------------------------
:: Gives bonuses based on equipped gear
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerRecalculateBonusesFromInventory
for /L %%A in (22,1,31) do (
    if not "!py.inventory[%%A].category_id!"=="%TV_NOTHING%" (
        set /a py.misc.plusses_to_hit+=!py.inventory[%%A].to_hit!

        if not "!py.inventory[%%A].category_id!"=="%TV_BOW%" (
            set /a py.misc.plusses_to_damage+=!py.inventory[%%A].to_damage!
        )

        set /a py.misc.magical_ac+=!py.inventory[%%A].to_ac!
        set /a py.misc.ac+=!py.inventory[%%A].ac!

        call identification.cmd :spellItemIdentified "py.inventory[%%A]"
        if "!errorlevel!"=="0" (
            set /a py.misc.display_to_hit+=!py.inventory[%%A].to_hit!

            if not "!py.inventory[%%A].category_id!"=="%TV_BOW%" (
                set /a py.misc.display_to_damage+=!py.inventory[%%A].to_damage!
            )

            set /a py.misc.display_to_ac+=!py.inventory[%%A].to_ac!
            set /a py.misc.display_ac+=!py.inventory[%%A].ac!
        ) else (
            call inventory.cmd :inventoryItemIsCursed "py.inventory[%%A]" || (
                set /a py.misc.display_ac+=!py.inventory[%%A].ac!
            )
        )
    )
)
exit /b

::------------------------------------------------------------------------------
:: Gives additional stat adjustments based on equipped gear
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerRecalculateSustainStatsFromInventory
for /L %%A in (22,1,31) do (
    set /a "is_sust_stat=!py.inventory[%%A].flags!&%config.treasure.flags.tr_sust_stat%"
    if not "!is_sust_stat!"=="0" (
        if "!py.inventory[%%A].misc_use!"=="1" (
            set "py.flags.sustain_str=true"
        ) else if "!py.inventory[%%A].misc_use!"=="2" (
            set "py.flags.sustain_int=true"
        ) else if "!py.inventory[%%A].misc_use!"=="3" (
            set "py.flags.sustain_wis=true"
        ) else if "!py.inventory[%%A].misc_use!"=="4" (
            set "py.flags.sustain_con=true"
        ) else if "!py.inventory[%%A].misc_use!"=="5" (
            set "py.flags.sustain_dex=true"
        ) else if "!py.inventory[%%A].misc_use!"=="6" (
            set "py.flags.sustain_chr=true"
        )
    )
)
exit /b

::------------------------------------------------------------------------------
:: Recalculate the effects of all equipment
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerRecalculateBonuses
if "%py.flags.slow_digest%"=="true" set /a py.flags.food_digested+=1
if "%py.flags.regenerate_hp%"=="true" set /a py.flags.food_digested-=3
set "saved_display_ac=%py.misc.display_ac%"
call :playerResetFlags

:: Real values
call player_stats.cmd :playerToHitAdjustment
set "py.misc.plusses_to_hit=!errorlevel!"
call player_stats.cmd :playerDamageAdjustment
set "py.misc.plusses_to_damage=!errorlevel!"
call player_stats.cmd :playerArmorClassAdjustment
set "py.misc.magical_ac=!errorlevel!"
set "py.misc.ac=0"

:: Display values
set "py.misc.display_to_hit=%py.misc.plusses_to_hit%"
set "py.misc.display_to_damage=%py.misc.plusses_to_damage%"
set "py.misc.display_to_ac=%py.misc.magical_ac%"
set "py.misc.display_ac=0"

call :playerRecalculateBonusesFromInventory

set /a py.misc.display_ac+=%py.misc.display_to_ac%

if "%py.weapon_is_heavy%"=="true" (
    set /a "py.misc.display_to_hit+=(!py.stats.used[%PlayerAttr.a_str%]!*15-!py.inventory[%PlayerEquipment.Wield%].weight!)"
)

:: Add in temporary spell increases
if %py.flags.invulnerability% GTR 0 (
    set /a py.misc.ac+=100
    set /a py.misc.display_ac+=100
)

if %py.flags.blessed% GTR 0 (
    set /a py.misc.ac+=2
    set /a py.misc.display_ac+=2
)

if %py.flags.detect_invisible% GTR 0 (
    set "py.flags.see_invisible=true"
)

:: Don't print AC in case the player is in a store
if not "%saved_display_ac%"=="%py.misc.display_ac%" (
    set /a "py.flags.status|=%config.player.status.py_armor%"
)

call inventory.cmd :inventoryCollectAllItemFlags
set "item_flags=!errorlevel!"

set /a "has_flags=!item_flags! & %config.treasure.flags.tr_slow_digest%"
if not "!has_flags!"=="0" set "py.flags.slow_digest=true"
set /a "has_flags=!item_flags! & %config.treasure.flags.tr_aggravate%"
if not "!has_flags!"=="0" set "py.flags.aggravate=true"
set /a "has_flags=!item_flags! & %config.treasure.flags.tr_teleport%"
if not "!has_flags!"=="0" set "py.flags.teleport=true"
set /a "has_flags=!item_flags! & %config.treasure.flags.tr_regen%"
if not "!has_flags!"=="0" set "py.flags.regenerate_hp=true"
set /a "has_flags=!item_flags! & %config.treasure.flags.tr_res_fire%"
if not "!has_flags!"=="0" set "py.flags.resistant_to_fire=true"
set /a "has_flags=!item_flags! & %config.treasure.flags.tr_res_acid%"
if not "!has_flags!"=="0" set "py.flags.resistant_to_acid=true"
set /a "has_flags=!item_flags! & %config.treasure.flags.tr_res_cold%"
if not "!has_flags!"=="0" set "py.flags.resistant_to_cold=true"
set /a "has_flags=!item_flags! & %config.treasure.flags.tr_free_act%"
if not "!has_flags!"=="0" set "py.flags.free_action=true"
set /a "has_flags=!item_flags! & %config.treasure.flags.tr_see_invis%"
if not "!has_flags!"=="0" set "py.flags.see_invisible=true"
set /a "has_flags=!item_flags! & %config.treasure.flags.tr_res_light%"
if not "!has_flags!"=="0" set "py.flags.resistant_to_light=true"
set /a "has_flags=!item_flags! & %config.treasure.flags.tr_ffall%"
if not "!has_flags!"=="0" set "py.flags.free_fall=true"

call :playerRecalculateSustainStatsFromInventory

if "%py.flags.slow_digest%"=="true" set /a py.flags.food_digested-=1
if "%py.flags.regenerate_hp%"=="true" set /a py.flags.food_digested+=3
exit /b

::------------------------------------------------------------------------------
:: Remove an item from the equipment list
::
:: Arguments: %1 - The ID of the item being removed
::            %2 - The location in the pack that the item is stored in
:: Returns:   None
::------------------------------------------------------------------------------
:playerTakeOff
set /a "py.flags.status|=%config.player.status.py_str_wgt%"
set "item=py.inventory[%~1]"

set /a py.pack.weight-=!%item%.weight!*!%item%.items_count!
set /a py.equipment_count-=1

if "%~1"=="%PlayerEquipment.Wield%" (
    set "p=Was wielding "
) else if "%~1"=="%PlayerEquipment.Auxiliary%" (
    set "p=Was wielding "
) else if "%~1"=="%PlayerEquipment.Light%" (
    set "p=Light source was "
) else (
    set "p=Was wearing "
)

call identification.cmd :itemDescription "description" "%item%" "true"

if %~2 GEQ 0 (
    cmd /c exit /b %~2
    set "msg=%p%%description% (!=ExitCodeAscii!)"
) else (
    set "msg=%p%%description%"
)
call ui_io.cmd :printMessage "!msg!"

if not "%~1"=="%PlayerEquipment.Auxiliary%" (
    call :playerAdjustBonusesForItem "%item%" -1
)
call inventory.cmd :inventoryItemCopyTo "%config.dungeon.objects.obj_nothing%" "%item%"
exit /b

::------------------------------------------------------------------------------
:: Compare an attacker's level and bonuses vs the defender's AC
::
:: Arguments: %1 - base to hit
::            %2 - level
::            %3 - plus to hit
::            %4 - armor class
::            %5 - attack type ID
:: Returns:   0 if the attack succeeds
::            1 if the attack fails
::------------------------------------------------------------------------------
:playerTestBeingHit
call :playerDisturb 1 0

:: plus_to_hit could be less than 0 if the player is wielding a weapon that is
:: too heavy for them
set /a "hit_chance=%~1 + %~3 * %bth_per_plus_to_hit_adjust% + (%~2 * !class_level_adj[%py.misc.class_id%][%~5]!)"

call rng.cmd :randomNumber 20
set die=!errorlevel!

:: Always miss on a 1, always hit on a 20
if "!die!"=="1" exit /b 1
if "!die!"=="20" exit /b 0

if %hit_chance% GTR 0 (
    call rng.cmd :randomNumber %hit_chance%
    if !errorlevel! GTR %~4 exit /b 0
)
exit /b

::------------------------------------------------------------------------------
:: Decreases player's hit points and sets the character_is_dead flag if needed
::
:: Arguments: %1 - The amount of damage being taken
::            %2 - The name of the creature that killed the player
:: Returns:   None
::------------------------------------------------------------------------------
:playerTakesHit
set "damage=%~1"
if %py.flags.invulnerability% GTR 0 set "damage=0"
set /a py.misc.current_hp-=%damage%

if %py.misc.current_hp% GEQ 0 (
    call ui.cmd :printCharacterCurrentHitPoints
    exit /b
)

if "%game.character_is_dead%"=="false" (
    set "game.character_is_dead=true"
    set "game.character_died_from=%~2"
    set "game.total_winner=false"
)

set "dg.generate_new_level=true"
exit /b

::------------------------------------------------------------------------------
:: Search for hidden things
::
:: Arguments: %1 - The coordinates to search
::            %2 - The chance of actually finding something
:: Returns:   None
::------------------------------------------------------------------------------
:playerSearch
if %py.flags.confused% GTR 0 set /a chance/=10
set "cant_see=0"
if %py.flags.blind% GTR 0 set "cant_see=1"
call :playerNoLight && set "cant_see=1"
if "%cant_see%"=="1" set /a chance/=10
if %py.flags.image% GTR 0 set /a chance/=10

call helpers.cmd :expandCoordName "%~1"
for /L %%Y in (!%~1.y_dec!,1,!%~1.y_inc!) do (
    for /L %%X in (!%1.x_dec!,1,!%~1.x_inc!) do (
        REM This would be so much prettier if batch had a continue command
        call rng.cmd :randomNumber 100
        if !errorlevel! LSS %~2 (
            set "t_id=!dg.floor[%%Y][%%X].treasure_id!"
            if not "!t_id!"=="0" (
                for /F "delims=" %%A in ("!t_id!") do (
                    if "!game.treasure.list[%%A].category_id!"=="%TV_INVIS_TRAP%" (
                        call identification.cmd :itemDescription "description" "game.treasure.list[%%A]" "true"
                        call ui_io.cmd :printMessage "You have found !description!"
                        call dungeon.cmd :trapChangeVisibility "%~1"
                        call player_run.cmd :playerEndRunning
                    ) else if "!game.treasure.list[%%A].category_id!"=="%TV_SECRET_DOOR%" (
                        call ui_io.cmd :printMessage "You have found a secret door."
                        call dungeon.cmd :trapChangeVisibility "%~1"
                        call player_run.cmd :playerEndRunning
                    ) else if "!game.treasure.list[%%A].category_id!"=="%TV_CHEST%" (
                        set /a "is_trapped=!game.treasure.list[%%A].flags! & %config.treasure.chests.ch_trapped%"
                        if !is_trapped! GTR 1 (
                            call identification.cmd :spellItemIdentified "game.treasure.list[%%A]"
                            if "!errorlevel!"=="1" (
                                REM wtf how many layers deep am I going to nest here? This is EIGHT
                                call identification.cmd :spellItemIdentifyAndRemoveRandomDescription "game.treasure.list[%%A]"
                                call ui_io.cmd :printMessage "You have discovered a trap on the chest."
                            ) else (
                                call ui_io.cmd :printMessage "The chest is trapped."
                            )
                        )
                    )
                )
            )
        )
    )
)
exit /b

::------------------------------------------------------------------------------
:: Computes the current weight limit
::
:: Arguments: None
:: Returns:   The maximum weight that the player can carry
::------------------------------------------------------------------------------
:playerCarryingLoadLimit
set /a weight_cap=!py.stats.used[%PlayerAttr.a_str%]! * %config.player.player_weight_cap% + %py.misc.weight%
if !weight_cap! GTR 3000 set "weight_cap=3000"
exit /b !weight_cap!

::------------------------------------------------------------------------------
:: Check to see if the player is strong enough for the current pack and weapon
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerStrength
set "item=py.inventory[%PlayerEquipment.Wield%]"

set "too_heavy=0"
if not "!%item%.category_id!"=="%TV_NOTHING%" set too_heavy+=1
set /a str_mult=!py.stats.used[%PlayerAttr.a_str%]!*15
if !str_mult! LSS !%item%.weight! set /a too_heavy+=1

if "!too_heavy!"=="2" (
    if "%py.weapon_is_heavy%"=="false" (
        call ui_io.cmd :printMessage "You have trouble wielding such a heavy weapon."
        set "py.weapon_is_heavy=true"
        call :playerRecalculateBonuses
    )
) else if "%py.weapon_is_heavy%"=="true" (
    set "py.weapon_is_heavy=false"
    if not "!%item%.category_id!"=="%TV_NOTHING%" (
        call ui_io.cmd :printMessage "You are strong enough to wield your weapon."
    )
    call :playerRecalculateBonuses
)
set "too_heavy="

call :playerCarryingLoadLimit
set "limit=!errorlevel!"

if !limit! LSS %py.pack.weight% (
    set /a "limit=%py.pack.weight% / (!limit! + 1)"
) else (
    set "limit=0"
)

if not "%py.pack.heaviness%"=="!limit!" (
    if %py.pack.heaviness% LSS !limit! (
        call ui_io.cmd :printMessage "Your pack is so heavy that it slows you down."
    ) else (
        call ui_io.cmd :printMessage "You move more easily under the weight of your pack."
    )
    set /a speed_change=!limit!-%py.pack.heaviness%
    call :playerChangeSpeed !speed_change!
    set "py.pack.heaviness=!limit!"
)

set "py.flags.status&=~%config.player.status.py_str_wgt%"
exit /b

::------------------------------------------------------------------------------
:: Checks to see if the player has a ring on their left hand
::
:: TODO: Remove this subroutine entirely
::
:: Arguments: None
:: Returns:   0 if the player does not currently have a left ring equipped
::            1 if the player is wearing a ring on their left
::------------------------------------------------------------------------------
:playerLeftHandRingEmpty
if "!py.inventory[%PlayerEquipment.Left%].category_id!"=="%TV_NOTHING%" exit /b 0
exit /b 1

::------------------------------------------------------------------------------
:: Checks to see if the player has a ring on their right hand
::
:: TODO: Remove this subroutine entirely
::
:: Arguments: None
:: Returns:   0 if the player does not currently have a right ring equipped
::            1 if the player is wearing a ring on their right
::------------------------------------------------------------------------------
:playerRightHandRingEmpty
if "!py.inventory[%PlayerEquipment.Right%].category_id!"=="%TV_NOTHING%" exit /b 0
exit /b 1

::------------------------------------------------------------------------------
:: Checks to see if the player has a weapon
::
:: TODO: Remove this subroutine entirely
::
:: Arguments: None
:: Returns:   0 if the player does not currently have a weapon equipped
::            1 if the player has either a main or auxiliary weapon
::------------------------------------------------------------------------------
:playerIsWieldingItem
if "!py.inventory[%PlayerEquipment.Wield%].category_id!"=="%TV_NOTHING%" (
    if "!py.inventory[%PlayerEquipment.Auxiliary%].category_id!"=="%TV_NOTHING%" (
        exit /b 1
    )
)
exit /b 0

::------------------------------------------------------------------------------
:: Checks to see if the player has a cursed item equipped
::
:: Arguments: %1 - The ID of the item to check
:: Returns:   0 if the specified item is cursed
::            1 if the specified item is not cursed
::------------------------------------------------------------------------------
:playerWornItemIsCursed
call inventory.cmd :inventoryItemIsCursed "py.inventory[%~1]"
exit /b !errorlevel!

::------------------------------------------------------------------------------
:: Removes a curse from a worn item
::
:: Arguments: %1 - The ID of the item to remove the curse from
:: Returns:   None
::------------------------------------------------------------------------------
:playerWornItemRemoveCurse
call inventory.cmd :inventoryItemRemoveCursed "py.inventory[%~1]"
exit /b

::------------------------------------------------------------------------------
:: Checks to see if the player can see in order to read
::
:: TODO: Merge with the same code in mage_spells.cmd
::
:: Arguments: None
:: Returns:   0 if the player can see
::            1 if the player is blind or otherwise in the dark
::------------------------------------------------------------------------------
:playerCanRead
if %py.flags.blind% GTR 0 (
    call ui_io.cmd :printMessage "You can't see to read your spell book."
    exit /b 1
)

call :playerNoLight && (
    call ui_io.cmd :printMessage "You have no light to read by."
    exit /b 1
)
exit /b 0

::------------------------------------------------------------------------------
:: Get the index of the last spell in spells_learned_order[]
::
:: Arguments: None
:: Returns:   The index of the last spell in spells_learned_order
::------------------------------------------------------------------------------
:lastKnownSpell
for /L %%A in (0,1,31) do (
    if "!py.flags.spells_learned_order[%%A]!"=="99" exit /b %%A
)
exit /b 0

::------------------------------------------------------------------------------
:: Determines which spells a player may learn
::
:: Arguments: None
:: Returns:   An integer whose binary value is which spells can be learned
::------------------------------------------------------------------------------
:playerDetermineLearnableSpells
set "spell_flag=0"
set /a counter_dec=%py.pack.unique_items%-1

for /L %%A in (0,1,%counter_dec%) do (
    if "!py.inventory[%%A].category_id!"=="%TV_MAGIC_BOOK%" (
        set /a "spell_flag|=!py.inventory[%%A].flags!"
    )
)
exit /b %spell_flag%

::------------------------------------------------------------------------------
:: Gain spells when the player wants to
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerGainSpells
if %py.flags.confused% GTR 0 (
    call ui_io.cmd :printMessage "You are too confused."
    exit /b
)

set "new_spells=%py.flags.new_spells_to_learn%"
set "diff_spells=0"

set /a class_dec=%py.misc.class_id%-1
set "spells=magic_spells[%class_dec%]"

:: Priests don't need light because they get spells from their god, so only
:: fail when a blind player has mage spells
if "!classes[%py.misc.class_id%].class_to_use_mage_spells!"=="%config.spells.spell_type_mage%" (
    call :playerCanRead || exit /b
    set "stat=%PlayerAttr.a_int%"
    set "offset=%config.spells.name_offset_spells%"
) else (
    set "stat=%PlayerAttr.a_wis%"
    set "offset=%config.spells.name_offset_spells%"
)

call :lastKnownSpell
set "last_known=!errorlevel!"

if "%new_spells%"=="0" (
    if "!stat!"=="%PlayerAttr.a_int%" (
        call ui_io.cmd :printMessage "You can't learn any new spells."
    ) else (
        call ui_io.cmd :printMessage "You can't learn any new prayers."
    )
    set "game.player_free_turn=true"
    exit /b
)

:: Determine which spells the player can learn
if "!stat!"=="%PlayerAttr.a_int%" (
    call :playerDetermineLearnableSpells
    set "spell_flag=!errorlevel!"
) else (
    set "spell_flag=2147483647"
)

:: Clear bits for spells already learned
set /a "spell_flag&=~%py.flags.spells_learnt%", "spell_id=0", "mask=1", "i=0"

:playerGainSpellsWhileLoop
if "!spell_flag!"=="0" goto :playerGainSpellsAfterWhileLoop
set /a "mask<<=1"
set /a "masked_flag=!spell_flag!&!mask!"
if not "!masked_flag!"=="0" (
    set /a "spell_flag&=~!mask!"
    if !%spells%[%i%].level_required! LEQ %py.misc.level% (
        set "spell_bank[!spell_id!]=%i%"
        set /a spell_id+=1
    )
)
set /a i+=1
goto :playerGainSpellsWhileLoop

:playerGainSpellsAfterWhileLoop
if !new_spells! GTR !spell_id! (
    call ui_io.cmd :printMessage "You seem to be missing a book."
    set /a diff_spells=!new_spells!-!spell_id!
    set "new_spells=!spell_id!"
)

if "!new_spells!"=="0" (
    goto :noNewSpells
) else if "%stat%"=="%PlayerAttr.a_int%" (
    call ui_io.cmd :terminalSaveScreen
    call ui.cmd :displaySpellsList "spell_bank" "!spell_id!" "false" "-1"

    call :getNewSpell
) else (
    call :getNewPrayer
)

:noNewSpells
set /a py.flags.new_spells_to_learn=!new_spells!+!diff_spells!
if "%py.flags.new_spells_to_learn%"=="0" (
    set /a "py.flags.status|=%config.player.status.py_study%"
)

:: Set the mana for the first level characters when they learn their first spell
if "%py.misc.mana%"=="0" (
    call :playerGainMana !stat!
)
exit /b

:getNewSpell
if "!new_spells!"=="0" exit /b
call ui.cmd :getMenuItemId "Learn which spell?" "query" || exit /b
set /a c=!query!-1
set "is_valid_spell=0"
if !c! GTR 0 set /a is_valid_spell+=1
if !c! LSS !spell_id! set /a is_valid_spell+=1
if !c! LSS 22 set /a is_valid_spell+=1
if "!is_valid_spell!"=="3" (
    set /a new_spells-=1
    set /a "py.flags.spells_learnt|=1<<!spell_bank[%c%]!"
    set "py.flags.spells_learned_order[!last_known!]=!spell_bank[%c%]!"
    set /a last_known+=1

    set /a counter_dec=!spell_id!-1
    for /L %%C in (!c!,1,!counter_dec!) do (
        set /a d=%%C+1
        for /f "delims=" %%D in ("!d!") do (
            set "spell_bank[%%C]=!spell_bank[%%D]!"
        )
    )
    set "c=!counter_dec!"
    set /a spell_id-=1
    call ui_io.cmd :eraseLine "!d!;31"
    call ui.cmd :displaySpellsList "spell_bank" "!spell_id!" "false" "-1"
) else (
    call ui_io.cmd :terminalBellSound
)
goto :getNewSpell

:getNewPrayer
if "!new_spells!"=="0" exit /b
call rng.cmd :randomNumber !spell_id!
set /a id=!errorlevel!-1
set /a "py.flags.spells_learnt|=1<<!spell_bank[%id%]!"
set "py.flags.spells_learned_order[!last_known!]=!spell_bank[%id%]!"
set /a last_known+=1

set /a spell_index=!spell_bank[%id%]!+!offset!
call ui_io.cmd :printMessage "You have learned the prayer of !spell_names[%spell_index%]!"
set /a counter_dec=!spell_id!-1
for /L %%C in (!id!,1,!counter_dec!) do (
    set /a d=%%C+1
    for /f "delims=" %%D in ("!d!") do (
        set "spell_bank[%%C]=!spell_bank[%%D]!"
    )
)
set /a spell_id-=1
set /a new_spells-=1
goto :getNewPrayer

::------------------------------------------------------------------------------
:: Determine the player's new maximum mana level
::
:: Arguments: %1 - Either Wisdom or Intelligence, depending on player's class
:: Returns:   The new maximum amount of mana, based on level
::------------------------------------------------------------------------------
:newMana
set /a levels=%py.misc.level% - !classes[%py,misc.class_id%].min_level_for_spell_casting! + 1
call player_stats.cmd :playerStatAdjustmentWisdomIntelligence "%~1"
if !errorlevel! LSS 3 (
    set "new_level=!levels!"
) else if "!errorlevel!"=="3" (
    set /a new_level=3 * !levels! / 2
) else if "!errorlevel!"=="4" (
    set /a new_level=2 * !levels!
) else if "!errorlevel!"=="5" (
    set /a new_level=5 * !levels! / 2
) else if "!errorlevel!"=="6" (
    set /a new_level=3 * !levels!
) else if "!errorlevel!"=="7" (
    set /a new_level=4 * !levels!
) else (
    set "new_level=0"
)
exit /b !new_level!

::------------------------------------------------------------------------------
:: Gain some mana if you know at least one spell
::
:: Arguments: %1 - Either Wisdom or Intelligence, depending on player's class
:: Returns:   None
::------------------------------------------------------------------------------
:playerGainMana
if not "%py.flags.spells_learnt%"=="0" (
    call :newMana "%~1"
    set "new_mana=!errorlevel!"

    REM Increment mana by one so that first-level characters have 2 mana
    if !new_mana! GTR 0 set /a new_mana+=1

    if not "%py.misc.mana%"=="!new_mana!" (
        if not "%py.misc.mana%"=="0" (
            set /a "value=((%py.misc.current_mana << 16) + %py.misc.current_mana_fraction%) / %py.misc.mana% * !new_mana!"
            set /a "py.misc.current_mana=!value!>>16"
            set /a "py.misc.current_mana_fraction=!value! & 0xFFFF"
        ) else (
            set "py.misc.current_mana=!new_mana!"
            set "py.misc.current_mana_fraction=0"
        )

        set "py.misc.mana=!new_mana!"
        set /a "py.flags.status|=%config.player.status.py_mana%"
    )
) else if not "%py.misc.mana%"=="0" (
    set "py.misc.mana=0"
    set "py.misc.current_mana=0"
    set /a "py.flags.status|=%config.player.status.py_mana%"
)
exit /b

::------------------------------------------------------------------------------
:: Deal critical damage
::
:: Arguments: %1 - The weight of the weapon
::            %2 - The player's plus_to_hit
::            %3 - The base damage of the weapon
::            %4 - The ID of the attack type being done
:: Returns:   The total amount of damage done by the player
::------------------------------------------------------------------------------
:playerWeaponCriticalBlow
set "weapon_weight=%~1"
set "critical=%~3"
set /a crit_chance=%~1 + 5 * %~2 + (!class_level_adj[%py.misc.class_id%][%~4]! * %py.misc.level%)
call rng.cmd :randomNumber 5000
if !errorlevel! LEQ !crit_chance! (
    call rng.cmd :randomNumber 650
    set /a weapon_weight+=!errorlevel!

    if !weapon_weight! LSS 400 (
        set /a critical=2 * %~3 + 5
        call ui_io.cmd :printMessage "It was a good hit^^! (x2 damage)"
    ) else if !weapon_weight! LSS 700 (
        set /a critical=3 * %~3 + 10
        call ui_io.cmd :printMessage "It was an excellent hit^^! (x3 damage)"
    ) else if !weapon_weight! LSS 900 (
        set /a critical=4 * %~3 + 15
        call ui_io.cmd :printMessage "It was a superb hit^^! (x4 damage)"
    ) else (
        set /a critical=5 * %~3 + 20
        call ui_io.cmd :printMessage "It was a *GREAT* hit^^! (x5 damage)"
    )
)
exit /b !critical!

::------------------------------------------------------------------------------
:: Saving throws for the player
::
:: Arguments: None
:: Returns:   0 if the player makes their saving throw
::            1 if the player fails to dodge, block, etc.
::------------------------------------------------------------------------------
:playerSavingThrow
set /a class_level_adjustment=!class_level_adj[%py.misc.class_id%][%PlayerClassLevelAdj.save%]! * %py.misc.level% / 3
call player_stats.cmd :playerStatAdjustmentWisdomIntelligence "%PlayerAttr.a_wis%"
set /a saving=%py.misc.saving_throw% + !errorlevel! + !class_level_adjustment!

call rng.cmd :randomNumber 100
if !errorlevel! LEQ !saving! exit /b 0
exit /b 1

::------------------------------------------------------------------------------
:: Gives the player experience points for killing monsters
::
:: Arguments: %1 - A reference to the monster that was killed
:: Returns:   None
::------------------------------------------------------------------------------
:playerGainKillExperience
set /a exp=!%~1.kill_exp_value! * !%~1.level!
set /a "quotient=%exp% / %py.misc.level%", "remainder=%exp% %% %py.misc.level%"

set /a remainder*=65536
set /a remainder/=%py.misc.level%
set /a remainder+=%py.misc.exp_fraction%

if %remainder% GEQ 65536 (
    set /a quotient+=1, py.misc.exp_fraction=%remainder%-65536
) else (
    set "py.misc.exp_fraction=%remainder%"
)
set /a py.misc.exp+=%quotient%
exit /b

::------------------------------------------------------------------------------
:: Calculate the number of times a player can hit with their weapon
:: TODO: Refactor to return %4
::
:: Arguments: %1 - The ID of the weapon used
::            %2 - The weight of the weapon
::            %3 - The name of the variable that stores the number of blows
::            %4 - The name of the variable that stores the total to_hit
:: Returns:   None
::------------------------------------------------------------------------------
:playerCalculateToHitBlows
if not "%~1"=="%TV_NOTHING%" (
    call player_stats.cmd :playerAttackBlows "%~2" "%~4"
    set "blows=!errorlevel!"
) else (
    set "blows=2"
    set "total_to_hit=-3"
)

if %~1 GEQ %TV_SLING_AMMO% (
    if %~1 LEQ %TV_SPIKE% (
        set /blows=1
    )
)
set /a total_to_hit+=%py.misc.plusses_to_hit%
exit /b

::------------------------------------------------------------------------------
:: Calculates the player's base to_hit
::
:: Arguments: %1 - whether or not the creature being attacked is lit
::            %2 - total_to_hit from :playerCalculateToHitBlows
:: Returns:   The player's base to_hit
::------------------------------------------------------------------------------
:playerCalculateBaseToHit
if "%~1"=="true" exit /b %py.misc.bth%

set /a bth=%py.misc.bth% / 2
set /a bth-=%~2 * (%bth_per_plus_to_hit_adjust% - 1)
set /a bth-=%py.misc.level% * !class_level_adj[%py.misc.class_id%][%PlayerClassLevelAdj.bth%]! / 2
exit /b %bth%

::------------------------------------------------------------------------------
:: Player attacks a monster
::
:: Arguments: %1 - The coordinates of the monster being attacked
:: Returns:   None
::------------------------------------------------------------------------------
:playerAttackMonster
for /f "tokens=1,2 delims=;" %%A in ("%~1") do (
    set "creature_id=!dg.floor[%%A][%%B].creature_id!"
)
set "monster=monsters[%creature_id%]"
set "creature=creatures_list[%creature_id%]"
set "item=py.inventory[%PlayerEquipment.Wield%]"
set "%monster%.sleep_count=0"

:: Does the player know what they're fighting?
if "!%monster%.lit!"=="false" (
    set "name=it"
) else (
    set "name=the !%creature%.name!"
)
call :playerCalculateToHitBlows !%item%.category_id! !%item%.weight! blows total_to_hit
call :playerCalculateBaseToHit !%monster%.to_hit! %total_to_hit%

for /L %%A in (%blows%,-1,1) do (
    call :blowLoop || exit /b
)
exit /b

:blowLoop
call :playerTestBeingHit %base_to_hit% %py.misc.level% %total_to_hit% !%creature%.ac! %PlayerClassLevelAdj.bth%
if "!errorlevel!"=="1" exit /b 0

call ui_io.cmd :printMessage "You hit !name!."

if not "!%item%.category_id!"=="%TV_NOTHING%" (
    call dice.cmd :diceRoll !%item%.damage.dice! !%item%.damage.sides!
    call player_magic.cmd :itemMagicAbilityDamage "%item%" !errorlevel! !%monster%.creature_id!
    call :playerWeaponCriticalBlow !%item%.weight! %total_to_hit% !errorlevel! %PlayerClassLevelAdj.bth%
    set "damage=!errorlevel!"
) else (
    call :playerWeaponCriticalBlow 1 0 1 %PlayerClassLevelAdj.bth%
    set "damage=!errorlevel!"
)

set /a damage+=%py.misc.plusses_to_damage%
if %damage% LSS 0 set "damage=0"

if "%py.flags.confuse_monster%"=="true" (
    set "py.flags.confuse_monster=false"
    call ui_io.cmd :printMessage "Your hands stop glowing."

    set "is_unaffected=0"
    set /a "cant_sleep=!%creature%.defenses! & %config.monsters.defense.cd_no_sleep%"
    if not "!cant_sleep!"=="0" set "is_unaffected=1"
    call rng.cmd :randomNumber %mon_max_levels%
    if !errorlevel! LSS !%creature%.level! set "is_unaffected=1"

    if "!is_unaffected!"=="1" (
        set "msg=!name! is unaffected."
    ) else (
        set "msg=!name! appears confused."
        if not "!%monster%.confused_amount!"=="0" (
            set /a %monster%.confused_amount+=3
        ) else (
            call rng.cmd :randomNumber 16
            set /a %monster%.confused_amount=!errorlevel!+2
        )
    )
    call ui_io.cmd :printMessage "!msg!"

    if "!%monster%.lit!"=="true" (
        call rng.cmd :randomNumber 4
        if "!errorlevel!"=="1" (
            set /a "creature_recall[!%monster%.creature_id!].defenses|=!%creature%.defenses! & %config.monsters.defense.cd_no_sleep%"
        )
    )
)

call monster.cmd :monsterTakeHit %creature_id% !damage!
if !errorlevel! GEQ 0 (
    call ui_io.cmd :printMessage "You have slain !name!."
    call ui.cmd :displayCharacterExperience
    exit /b 1
)

if !%item%.category_id! GEQ %TV_SLING% (
    if !%item%.category_id! LEQ %TV_SPIKE% (
        set /a %item%.items_count-=1
        set /a py.pack.weight-=!%item%.weight!
        set /a "py.flags.status|=%config.player.status.py_str_wgt%"

        if "!%item%.items_count!"=="0" (
            set /a py.equipment_count-=1
            call :playerAdjustBonusesForItem "%item%" -1
            call inventory.cmd :inventoryItemCopyTo "%config.dungeon.objects.obj_nothing%" "%item%"
            call :playerRecalculateBonuses
        )
    )
)
exit /b

::------------------------------------------------------------------------------
:: Establishes the player's ability to pick a lock
::
:: Arguments: None
:: Returns:   The player's lockpicking skill
::------------------------------------------------------------------------------
:playerLockPickingSkill
set "skill=%py.misc.disarm%"
set /a skill+=2

call player_stats.cmd :playerDisarmAdjustment
set /a skill*=!errorlevel!

:: TODO: Decide if DEX should influence lockpicking rather than INT
call player_stats.cmd :playerStatAdjustmentWisdomIntelligence %PlayerAttr.a_int%
set /a skill+=!errorlevel!

set /a skill+=!class_level_adj[%py.misc.class_id%][%PlayerClassLevelAdj.disarm%]! * %py.level% / 3
exit /b !skill!

::------------------------------------------------------------------------------
:: Opens a closed door
::
:: Arguments: %1 - The coordinates of the door
:: Returns:   None
::------------------------------------------------------------------------------
:openClosedDoor
for /f "tokens=1,2 delims=;" %%A in ("%~1") do set "tile=dg.floor[%%A][%%B]"
set "t_id=!%tile%.treasure_id!"
set "item=game.treasure.list[%t_id%]"
if !%item%.misc_use! GTR 0 (
    if %py.flags.confused% GTR 0 (
        call ui_io.cmd :printMessage "You are too confused to pick the lock."
    ) else (
        call :playerLockPickingSkill
        set /a can_pick=!errorlevel!-!%item%.misc_use!
        call rng.cmd :randomNumber 100
        if !can_pick! GTR !errorlevel! (
            call ui_io.cmd :printMessage "You have picked the lock."
            set /a py.misc.exp+=1
            call ui.cmd :displayCharacterExperience
            set "%item%.misc_use=0"
        ) else (
            call ui_io.cmd :printMessage "You failed to pick the lock."
        )
    )
) else if !%item%.misc_use! LSS 0 (
    call ui_io.cmd :printMessage "It appears to be stuck."
)

if "!%item%.misc_use!"=="0" (
    call inventory.cmd :inventoryItemCopyTo "%config.dungeon.objects.obj_open_door%" "game.treasure.list[%t_id%]"
    set "%tile%.feature_id=%TILE_CORR_FLOOR%"
    set "coord=%~1"
    call dungeon.cmd :dungeonLiteSpot "coord"
    set "game.command_count=0"
)
exit /b

:openClosedChest
exit /b

:playerOpenClosedObject
exit /b

:playerCloseDoor
exit /b

:playerTunnelWall
exit /b

:playerAttackPosition
exit /b

:eliminateKnownSpellsGreaterThanLevel
exit /b

:numberOfSpellsAllowed
exit /b

:numberOfSpellsKnown
exit /b

:rememberForgottenSpells
exit /b

:learnableSpells
exit /b

:forgetSpells
exit /b

:playerCalculateAllowedSpellsCount
exit /b

:playerRankTitle
exit /b
