call %*
exit /b

::------------------------------------------------------------------------------
:: Checks to see if the player is carrying any staffs
::
:: Arguments: %1 - A variable to hold the start index of the inventory range
::            %2 - A variable to hold the end index of the inventory range
:: Returns:   0 if the player is carrying staffs
::            1 if the player has no staffs in their inventory
::------------------------------------------------------------------------------
:staffPlayerIsCarrying
if "%py.pack.unique_items%"=="0" (
    call ui_io.cmd :printMessage "But you are not carrying anything.
    exit /b 1
)

call inventory.cmd :inventoryFindRange "%TV_STAFF%" "%TV_NEVER%" "%~1" "%~2"
if "!errorlevel!"=="1" (
    call ui_io.cmd :printMessage "You are not carrying any staffs."
    exit /b 1
)
exit /b 0

::------------------------------------------------------------------------------
:: Checks to see if the selected staff is usable by the player
::
:: Arguments: %1 - A reference to the staff selected by the player
:: Returns:   0 if the staff can be used by the player
::            1 if the player is unable to use the staff
::------------------------------------------------------------------------------
:staffPlayerCanUse
set "chance=%py.misc.saving_throw%"
call player_stats.cmd :playerStatAdjustmentWisdomIntelligence "%PlayerAttr.a_int%"
set /a chance+=!errorlevel!
set /a chance-=!%~1.depth_first_found! - 5
set /a chance+=!class_level_adj[%py.misc.class_id%][%PlayerClassLevelAdj.DEVICE%]! * %py.misc.level% / 3

if %py.flags.confused% GTR 0 set a chance/=2
if %chance% LSS %config.player.player_use_device_difficulty% (
    set /a difficulty_diff=%config.player.player_use_device_difficulty% - %chance% + 1
    call rng.cmd :randomNumber "!difficulty_diff!"
    if "!errorlevel!"=="1"(
        set "chance=%config.player.player_use_device_difficulty%"
    )
)

if %chance% LSS 1 set "chance=1"

call rng.cmd :randomNumber "%chance%"
if !errorlevel! LSS %config.player.player_use_device_difficulty% (
    call ui_io.cmd :printMessage "You failed to use the staff properly."
    exit /b 1
)

if !%~1.misc_use! LSS 1 (
    call ui_io.cmd :printMessage "The staff has no charges left."
    call identification.cmd :spellItemId "%~1"
    if "!errorlevel!"=="1" (
        call identification.cmd :itemAppendToInscription "%~1" "%config.identification.ID_EMPTY%"
    )
    exit /b 1
)
exit /b 0

::------------------------------------------------------------------------------
:: Determine which spell to cast based on the type of staff that is used
::
:: Arguments: %1 - A reference to the staff being fired
:: Returns:   0 if the player knows what staff was used
::            1 if the spell fails, keeping the player from learning about it
::------------------------------------------------------------------------------
:staffDischarge
set "identified=1"
set /a "%~1.misc_use-=1"

set "flags=!%~1.flags!"

:staffDischargeWhileLoop
set "staff_switch="
if "!flags!"=="0" exit /b !identified!
set /a flag_inc=!flags!+1
call helpers.cmd :getAndClearFirstBit "!flag_inc!"
set "staff_switch=!errorlevel!"

if "!staff_switch!"=="%StaffSpellTypes.StaffLight%" (
    call spells.cmd :spellLightArea "!py.pos!"
    set "identified=!errorlevel!"
    goto :staffDischargeWhileLoop
) else if "!staff_switch!"=="%StaffSpellTypes.DetectDoorsStairs%" (
    call spells.cmd :spellDetectSecretDoorssWithinVicinity
    set "identified=!errorlevel!"
    goto :staffDischargeWhileLoop
) else if "!staff_switch!"=="%StaffSpellTypes.TrapLocation%" (
    call spells.cmd :spellDetectTrapsWithinVicinity
    set "identified=!errorlevel!"
    goto :staffDischargeWhileLoop
) else if "!staff_switch!"=="%StaffSpellTypes.TreasureLocation%" (
    call spells.cmd :spellDetectTreasureWithinVicinity
    set "identified=!errorlevel!"
    goto :staffDischargeWhileLoop
) else if "!staff_switch!"=="%StaffSpellTypes.ObjectLocation%" (
    call spells.cmd :spellDetectObjectsWithinVicinity
    set "identified=!errorlevel!"
    goto :staffDischargeWhileLoop
) else if "!staff_switch!"=="%StaffSpellTypes.Teleportation%" (
    call player.cmd :playerTeleport 100
    set "identified=!errorlevel!"
    goto :staffDischargeWhileLoop
) else if "!staff_switch!"=="%StaffSpellTypes.Earthquakes%" (
    call spells.cmd :spellEarthquake
    set "identified=!errorlevel!"
    goto :staffDischargeWhileLoop
) else if "!staff_switch!"=="%StaffSpellTypes.Summoning%" (
    set "identified=1"
    call rng.cmd :randomNumber 4
    for /L %%A in (1,1,!errorlevel!) do (
        set "coord=!py.pos!"
        call monster_manager.cmd :monsterSummon "coord" "false"
        set "identified=!errorlevel!"
    )
    goto :staffDischargeWhileLoop
) else if "!staff_switch!"=="%StaffSpellTypes.Destruction%" (
    set "identified=0"
    call spells.cmd :spellDestroyArea "!py.pos!"
    goto :staffDischargeWhileLoop
) else if "!staff_switch!"=="%StaffSpellTypes.Starlight%" (
    set "identified=0"
    call spells.cmd :spellStarlite "!py.pos!"
    goto :staffDischargeWhileLoop
) else if "!staff_switch!"=="%StaffSpellTypes.HasteMonsters%" (
    call spells.cmd :spellSpeedAllMonsters 1
    set "identified=!errorlevel!"
    goto :staffDischargeWhileLoop
) else if "!staff_switch!"=="%StaffSpellTypes.SlowMonsters%" (
    call spells.cmd :spellSpeedAllMonsters -1
    set "identified=!errorlevel!"
    goto :staffDischargeWhileLoop
) else if "!staff_switch!"=="%StaffSpellTypes.SleepMonsters%" (
    call spells.cmd :spellSleepAllMonsters
    set "identified=!errorlevel!"
    goto :staffDischargeWhileLoop
) else if "!staff_switch!"=="%StaffSpellTypes.CureLightWounds%" (
    call rng.cmd :randomNumber 8
    call spells.cmd :spellChangePlayerHitPoints !errorlevel!
    set "identified=!errorlevel!"
    goto :staffDischargeWhileLoop
) else if "!staff_switch!"=="%StaffSpellTypes.DetectInvisible%" (
    call spells.cmd :spellDetectInvisibleCreaturesWithinVicinity
    set "identified=!errorlevel!"
    goto :staffDischargeWhileLoop
) else if "!staff_switch!"=="%StaffSpellTypes.Speed%" (
    if "%py.flags.fast%"=="0" (
        set "identified=0"
    )
    call rng.cmd :randomNumber 30
    set /a py.flags.fast+=!errorlevel!+15
    goto :staffDischargeWhileLoop
) else if "!staff_switch!"=="%StaffSpellTypes.Slowness%" (
    if "%py.flags.slow%"=="0" (
        set "identified=0"
    )
    call rng.cmd :randomNumber 30
    set /a py.flags.slow+=!errorlevel!+15
    goto :staffDischargeWhileLoop
) else if "!staff_switch!"=="%StaffSpellTypes.MassPolymorph%" (
    call spells.cmd :spellMassPolymorph
    set "identified=!errorlevel!"
    goto :staffDischargeWhileLoop
) else if "!staff_switch!"=="%StaffSpellTypes.RemoveCurse%" (
    call spells.cmd :spellRemoveCurseFromAllWornItems
    if "!errorlevel!"=="0" (
        if %py.flags.blind% LSS 1 (
            call ui_io.cmd :printMessage "The staff glows blue for a moment..."
        )
        set "identified=0"
    )
    goto :staffDischargeWhileLoop
) else if "!staff_switch!"=="%StaffSpellTypes.DetectEvil%" (
    call spells.cmd :spellDetectEvil
    set "identified=!errorlevel!"
    goto :staffDischargeWhileLoop
) else if "!staff_switch!"=="%StaffSpellTypes.Curing%" (
    call player_magic.cmd :spellCureBlindness && set "identified=0"
    call player_magic.cmd :spellCurePoison && set "identified=0"
    call player_magic.cmd :spellCureConfusion && set "identified=0"
    goto :staffDischargeWhileLoop
) else if "!staff_switch!"=="%StaffSpellTypes.DispelEvil%" (
    call spells.cmd :spellDispelCreature "%config.monsters.defense.CD_EVIL%" 60
    set "identified=!errorlevel!"
    goto :staffDischargeWhileLoop
) else if "!staff_switch!"=="%StaffSpellTypes.Darkness%" (
    call spells.cmd :spellDarkenArea "!py.pos!"
    set "identified=!errorlevel!"
    goto :staffDischargeWhileLoop
)
goto :staffDischargeWhileLoop

::------------------------------------------------------------------------------
:: Wrapper subroutine for using a staff
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:staffUse
set "game.player_free_turn=true"

call :staffPlayerIsCarrying "item_pos_start" "item_pos_end" || exit /b
call inventory.cmd :inventoryGetInputForItemId "item_id" "Use which staff?" "%item_pos_start%" "%item_pos_end%" "CNIL" "CNIL" || exit /b

set "game.player_free_turn=false"
set "item=py.inventory[%item_id%]"
call :staffPlayerCanUse "item" || exit /b
call :staffDischarge "item"
set "identified=!errorlevel!"

if "!identified!"=="0" (
    call identification.cmd :itemSetColorlessAsIdentified "!%item%.category_id!" "!%item%.sub_category_id!" "!%item%.identification!"
    if "!errorlevel!"=="1" (
        set /a "py.misc.exp+=(!%item%.depth_first_found! + (%py.misc.level% >> 1)) / %py.misc.level%"
        call ui.cmd :displayCharacterExperience
        call identification.cmd :itemIdentify "py.inventory[%item_id%]" "item_id"
    )
) else (
    call identification.cmd :itemSetColorlessAsIdentified "!%item%.category_id!" "!%item%.sub_category_id!" "!%item%.identification!"
    if "!errorlevel!"=="1" (
        call identification.cmd :itemSetAsTried "item"
    )
)
call identification.cmd :itemChargesRemainingDescription "%item_id%"
exit /b

::------------------------------------------------------------------------------
:: Determine which spell to cast based on which wand is used
::
:: Arguments: %1 - A reference to the wand being fired
::            %2 - The direction that the spell is being cast in
:: Returns:   0 if the spell was successfully cast
::            1 if the spell failed
::------------------------------------------------------------------------------
:wandDischarge
set /a "%~1.misc_use-=1"
set "direction=%~2"
set "identified=1"
set "flags=!%~1.flags!"

:wandDischargeWhileLoop
set "wand_switch="
if "!flags!"=="0" exit /b !identified!

set "coord.y=!py.pos.y!"
set "coord.x=!py.pos.x!"
set "coord=!coord.y!;!coord.x!"

set /a flag_inc=!flags!+1
call helpers.cmd :getAndClearFirstBit "!flag_inc!"
set "wand_switch=!errorlevel!"

if "!wand_switch!"=="%WandSpellTypes.WandLight%" (
    REM Unlike the Staff of Light, the Wand of Light is visible even if the player is blind
    call ui_io.cmd :printMessage "A line of blue shimmering light appears."
    call spells.cmd :spellLightLine "!py.pos!" "%direction%"
    set "identified=0"
    goto :wandDischargeWhileLoop
) else if "!wand_switch!"=="%WandSpellTypes.WandMagicMissile%" (
    call dice.cmd :diceRoll 2 6
    call spells.cmd :spellFireBolt "!coord!" "%direction%" "!errorlevel!" "%MagicSpellFlags.MagicMissile%" "!spell_names[0]!"
    set "identified=0"
    goto :wandDischargeWhileLoop
) else if "!wand_switch!"=="%WandSpellTypes.LightningBolt%" (
    call dice.cmd :diceRoll 4 8
    call spells.cmd :spellFireBolt "!coord!" "%direction%" "!errorlevel!" "%MagicSpellFlags.Lightning%" "!spell_names[8]!"
    set "identified=0"
    goto :wandDischargeWhileLoop
) else if "!wand_switch!"=="%WandSpellTypes.FrostBolt%" (
    call dice.cmd :diceRoll 4 8
    call spells.cmd :spellFireBolt "!coord!" "%direction%" "!errorlevel!" "%MagicSpellFlags.Frost%" "!spell_names[14]!"
    set "identified=0"
    goto :wandDischargeWhileLoop
) else if "!wand_switch!"=="%WandSpellTypes.FireBolt%" (
    call dice.cmd :diceRoll 4 8
    call spells.cmd :spellFireBolt "!coord!" "%direction%" "!errorlevel!" "%MagicSpellFlags.Fire%" "!spell_names[22]!"
    set "identified=0"
    goto :wandDischargeWhileLoop
) else if "!wand_switch!"=="%WandSpellTypes.StoneToMud%" (
    call spells.cmd :spellWallToMud "!coord!" "%direction%"
    set "identified=!errorlevel!"
    goto :wandDischargeWhileLoop
) else if "!wand_switch!"=="%WandSpellTypes.Polymorph%" (
    call spells.cmd :spellPolymorphMonster "!coord!" "%direction%"
    set "identified=!errorlevel!"
    goto :wandDischargeWhileLoop
) else if "!wand_switch!"=="%WandSpellTypes.HealMonster%" (
    call dice.cmd :diceRoll 4 6
    call spells.cmd :spellChangeMonsterHitPoints "!coord!" "%direction%" "-!errorlevel!"
    set "identified=!errorlevel!"
    goto :wandDischargeWhileLoop
) else if "!wand_switch!"=="%WandSpellTypes.HasteMonster%" (
    call spells.cmd :spellSpeedMonster "!coord!" "%direction%" 1
    set "identified=!errorlevel!"
    goto :wandDischargeWhileLoop
) else if "!wand_switch!"=="%WandSpellTypes.SlowMonster%" (
    call spells.cmd :spellSpeedMonster "!coord!" "%direction%" -1
    set "identified=!errorlevel!"
    goto :wandDischargeWhileLoop
) else if "!wand_switch!"=="%WandSpellTypes.ConfuseMonster%" (
    call spells.cmd :spellConfuseMonster "!coord!" "%direction%"
    set "identified=!errorlevel!"
    goto :wandDischargeWhileLoop
) else if "!wand_switch!"=="%WandSpellTypes.SleepMonster%" (
    call spells.cmd :spellSleepMonster "!coord!" "%direction%"
    set "identified=!errorlevel!"
    goto :wandDischargeWhileLoop
) else if "!wand_switch!"=="%WandSpellTypes.DrainLife%" (
    call spells.cmd :spellDrainLifeFromMonster "!coord!" "%direction%"
    set "identified=!errorlevel!"
    goto :wandDischargeWhileLoop
) else if "!wand_switch!"=="%WandSpellTypes.TrapDoorDestruction%" (
    call spells.cmd :spellWallToMud "!coord!" "%direction%"
    set "identified=!errorlevel!"
    goto :wandDischargeWhileLoop
) else if "!wand_switch!"=="%WandSpellTypes.WallBuilding%" (
    call spells.cmd :spellBuildWall "!coord!" "%direction%"
    set "identified=!errorlevel!"
    goto :wandDischargeWhileLoop
) else if "!wand_switch!"=="%WandSpellTypes.CloneMonster%" (
    call spells.cmd :spellCloneMonster "!coord!" "%direction%"
    set "identified=!errorlevel!"
    goto :wandDischargeWhileLoop
) else if "!wand_switch!"=="%WandSpellTypes.TeleportAway%" (
    call spells.cmd :spellTeleportAwayMonsterInDirection "!coord!" "%direction%"
    set "identified=!errorlevel!"
    goto :wandDischargeWhileLoop
) else if "!wand_switch!"=="%WandSpellTypes.Disarming%" (
    call spells.cmd :spellDisarmAllInDirection "!coord!" "%direction%"
    set "identified=!errorlevel!"
    goto :wandDischargeWhileLoop
) else if "!wand_switch!"=="%WandSpellTypes.LightningBall%" (
    call spells.cmd :spellFireBall "!coord!" "%direction%" 32 "%MagicSpellFlags.Lightning%" "Lightning Ball"
    set "identified=!errorlevel!"
    goto :wandDischargeWhileLoop
) else if "!wand_switch!"=="%WandSpellTypes.ColdBall%" (
    call spells.cmd :spellFireBall "!coord!" "%direction%" 48 "%MagicSpellFlags.Frost%" "Cold Ball"
    set "identified=!errorlevel!"
    goto :wandDischargeWhileLoop
) else if "!wand_switch!"=="%WandSpellTypes.FireBall%" (
    REM No idea why some spell names are in spell_names and others aren't
    call spells.cmd :spellFireBall "!coord!" "%direction%" 72 "%MagicSpellFlags.Fire%" "!spell_names[28]!"
    set "identified=!errorlevel!"
    goto :wandDischargeWhileLoop
) else if "!wand_switch!"=="%WandSpellTypes.StinkingCloud%" (
    call spells.cmd :spellFireBall "!coord!" "%direction%" 12 "%MagicSpellFlags.Lightning%" "!spell_names[6]!"
    set "identified=!errorlevel!"
    goto :wandDischargeWhileLoop
) else if "!wand_switch!"=="%WandSpellTypes.AcidBall%" (
    call spells.cmd :spellFireBall "!coord!" "%direction%" 32 "%MagicSpellFlags.Lightning%" "Acid Ball"
    set "identified=!errorlevel!"
    goto :wandDischargeWhileLoop
) else if "!wand_switch!"=="%WandSpellTypes.Wonder%" (
    call rng.cmd :randomNumber 23
    set /a "flags=1 << (!errorlevel! - 1)"
    goto :wandDischargeWhileLoop
) else (
    call ui_io.cmd :printMessage "Internal error in :wands"
)
goto :wandDischargeWhileLoop

::------------------------------------------------------------------------------
:: Wrapper subroutine for firing a wand
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:wandAim
set "game.player_free_turn=true"

if "%py.pack.unique_items%"=="0" (
    call ui_io.cmd :printMessage "But you are not carrying anything."
    exit /b
)

call inventory.cmd :inventoryFindRange "%TV_WAND%" "%TV_NEVER%" "item_pos_start" "item_pos_end"
if "!errorlevel!"=="1" (
    call ui_io.cmd :printMessage "You are not carrying any wands."
    exit /b
)
call inventory.cmd :inventoryGetInputForItemId "item_id" "Aim which wand?" "%item_pos_start%" "%item_pos_end%" "CNIL" "CNIL" || exit /b

set "game.player_free_turn=false"

call game.cmd :getDirectionWithMemory "CNIL" "direction" || exit /b

if %py.flags.confused% GTR 0 (
    call ui_io.cmd :printMessage "You are confused."
    call game.cmd :getRandomDirection
    set "direction=!errorlevel!"
)

set "item=py.inventory[%item_id%]"
set /a player_class_lev_adj=!class_level_adj[%py.misc.class_id%][5PlayerClassLevelAdj.DEVICE%]! * %py.misc.level% / 3
call player_stats.cmd :playerStatAdjustmentWisdomIntelligence "%PlayerAttr.a_int%"
set /a chance=%py.misc.saving_throw% + !errorlevel! - !%item%.depth_first_found! + %player_class_lev_adj%

if %py.flags.confused% GTR 0 set /a chance/=2

if %chance% LSS %config.player.player_use_device_difficulty% (
    set /a difficulty_diff=%config.player.player_use_device_difficulty% - %chance% + 1
    call rng.cmd :randomNumber "!difficulty_diff!"
    if "!errorlevel!"=="1"(
        set "chance=%config.player.player_use_device_difficulty%"
    )
)

if %chance% LSS 1 set "chance=1"

call rng.cmd :randomNumber "%chance%"
if !errorlevel! LSS %config.player.player_use_device_difficulty% (
    call ui_io.cmd :printMessage "You failed to use the wand properly."
    exit /b
)

if !%~1.misc_use! LSS 1 (
    call ui_io.cmd :printMessage "The wand has no charges left."
    call identification.cmd :spellItemId "%~1"
    if "!errorlevel!"=="1" (
        call identification.cmd :itemAppendToInscription "%~1" "%config.identification.ID_EMPTY%"
    )
    exit /b
)

call :wandDischarge "item" "%direction%"
set "identified=!errorlevel!"

if "!identified!"=="0" (
    call identification.cmd :itemSetColorlessAsIdentified "!%item%.category_id!" "!%item%.sub_category_id!" "!%item%.identification!"
    if "!errorlevel!"=="1" (
        set /a "py.misc.exp+=(!%item%.depth_first_found! + (%py.misc.level% >> 1)) / %py.misc.level%"
        call ui.cmd :displayCharacterExperience
        call identification.cmd :itemIdentify "py.inventory[%item_id%]" "item_id"
    )
) else (
    call identification.cmd :itemSetColorlessAsIdentified "!%item%.category_id!" "!%item%.sub_category_id!" "!%item%.identification!"
    if "!errorlevel!"=="1" (
        call identification.cmd :itemSetAsTried "item"
    )
)
call identification.cmd :itemChargesRemainingDescription "%item_id%"
exit /b
