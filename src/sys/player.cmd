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
            call player_stats.cmd :playerStatBoots %%A %amount%
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

:playerTakeOff
exit /b

:playerTestBeingHit
exit /b

:playerTakesHit
exit /b

:playerSearch
exit /b

:playerCarryingLoadLimit
exit /b

:playerStrength
exit /b

:playerLeftHandRingEmpty
exit /b

:playerRightHandRingEmpty
exit /b

:playerIsWieldingItem
exit /b

:playerWornItemIsCursed
exit /b

:playerWornItemRemoveCurse
exit /b

:playerCanRead
exit /b

:lastKnownSpell
exit /b

:playerDetermineLearnableSpells
exit /b

:playerGainSpells
exit /b

:newMana
exit /b

:playerGainMana
exit /b

:playerWeaponCriticalBlow
exit /b

:playerSavingThrow
exit /b

:playerGainKillExperience
exit /b

:playerCalculateToHitBlows
exit /b

:playerCalculateBaseToHit
exit /b

:playerAttackMonster
exit /b

:playerLockPickingSkill
exit /b

:openClosedDoor
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
