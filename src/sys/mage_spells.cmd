@echo off
call %*
exit /b

::------------------------------------------------------------------------------
:: Checks if the player is able to read the spell book
::
:: Arguments: None
:: Returns:   0 if the player can read their spells
::            1 otherwise
::------------------------------------------------------------------------------
:canReadSpells
if %py.flags.blind% GTR 0 (
    call ui_io.cmd :printMessage "You can't see to read your spell book."
    exit /b 1
)

call player.cmd :playerNoLight && (
    call ui_io.cmd :printMessage "You have no light to read by."
    exit /b 1
)

if %py.flags.confused% GTR 0 (
    call ui_io.cmd :printMessage "You are too confused."
    exit /b 1
)

if not "!classes[%py.misc.class_id%].class_to_use_mage_spells!"=="%config.spells.spell_type_mage%" (
    call ui_io.cmd :printMessage "You can't cast spells."
    exit /b 1
)
exit /b 0

::------------------------------------------------------------------------------
:: Calls the relevant subroutine based on which spell was cast
::
:: Arguments: %1 - The ID of the spell to cast
:: Returns:   None
::------------------------------------------------------------------------------
:castSpell
call game.cmd :getDirectionWithMemory "CNIL" "dir"
set "keep_dir=!errorlevel!"

if "%~1"=="%MageSpellId.MagicMissile%" (
    if "%keep_dir%"=="0" (
        call dice.cmd :diceRoll 2 6
        call spells.cmd :spellFireBolt "%py.pos.y%;%py.pos.x%" "%dir%" "!errorlevel!" "%MagicSpellFlags.MagicMissile%" "!spell_names[0]!"
    )
) else if "%~1"=="%MageSpellId.DetectMonsters%" (
    call spells.cmd :spellDetectMonsters
) else if "%~1"=="%MageSpellId.PhaseDoor%" (
    call player.cmd :playerTeleport 10
) else if "%~1"=="%MageSpellId.LightArea%" (
    call spells.cmd :spellLightArea "%py.pos.y%;%py.pos.x%"
) else if "%~1"=="%MageSpellId.CureLightWounds%" (
    call dice.cmd :diceRoll 4 4
    call spells.cmd :spellChangePlayerHitPoints !errorlevel!
) else if "%~1"=="%MageSpellId.FindHiddenTrapsDoors%" (
    call spells.cmd :spellDetectSecretDoorsWithinVicinity
    call spells.cmd :spellDetectTrapsWithinVicinity
) else if "%~1"=="%MageSpellId.StinkingCloud%%" (
    if "%keep_dir%"=="0" (
        call spells.cmd :spellFireBall "%py.pos.y%;%py.pos.x%" "%dir%" 12 "%MagicSpellFlags.PoisonGas%" "!spell_names[6]!"
    )
) else if "%~1"=="%MageSpellId.Confusion%" (
    if "%keep_dir%"=="0" (
        call spells.cmd :spellConfuseMonster "%py.pos.y%;%py.pos.x%" "%dir%"
    )
) else if "%~1"=="%MageSpellId.LightningBolt%" (
    if "%keep_dir%"=="0" (
        call dice.cmd :diceRoll 4 8
        call spells.cmd :spellFireBolt "%py.pos.y%;%py.pos.x%" "%dir%" "!errorlevel!" "%MagicSpellFlags.Lightning%" "!spell_names[8]!"
    )
) else if "%~1"=="%MageSpellId.TrapDoorDestruction%" (
    call spells.cmd :spellDestroyAdjacentTrapDoors
) else if "%~1"=="%MageSpell.Sleep1%" (
    if "%keep_dir%"=="0" (
        call spells.cmd :spellsSleepMonster "%py.pos.y%;%py.pos.x%" "%dir%"
    )
) else if "%~1"=="%MageSpell.CurePoison%" (
    call player_magic.cmd :playerCurePoison
) else if "%~1"=="%MageSpellId.TeleportSelf%" (
    set /a teleport_range=%py.misc.level%*5
    call player.cmd :playerTeleport !teleport_range!
) else if "%~1"=="%MageSpellId.RemoveCurse%" (
    for /L %%I in (22,1,%player_inventory_size%) do (
        call inventory.cmd :inventoryItemRemoveCurse "py.inventory[%%I]"
    )
) else if "%~1"=="%MageSpellId.FrostBolt%" (
    if "%keep_dir%"=="0" (
        call dice.cmd :diceRoll 6 8
        call spells.cmd :spellFireBolt "%py.pos.y%;%py.pos.x%" "%dir%" "!errorlevel!" "%MagicSpellFlags.Frost%" "!spell_names[14]!"
    )
) else if "%~1"=="%MageSpellId.WallToMud%" (
    if "%keep_dir%"=="0" (
        call spells.cmd :spellWallToMud "%py.pos.y%;%py.pos.x%" "%dir%"
    )
) else if "%~1"=="%MageSpellId.CreateFood%" (
    call spells.cmd :spellCreateFood
) else if "%~1"=="%MageSpellId.RechargeItem1%" (
    call spells.cmd :spellRechargeItem 20
) else if "%~1"=="%MageSpellId.Sleep2%" (
    call monster.cmd :monsterSleep "%py.pos.y%;%py.pos.x%"
) else if "%~1"=="%MageSpellId.PolymorphOther%" (
    if "%keep_dir%"=="0" (
        call spells.cmd :spellPolymorphMonster "%py.pos.y%;%py.pos.x%" "%dir%"
    )
) else if "%~1"=="%MageSpellId.IdentifyItem%" (
    call spells.cmd :spellIdentifyItem
) else if "%~1"=="%MageSpellId.Sleep3%" (
    call spells.cmd :spellSleepAllMonsters
) else if "%~1"=="%MageSpellId.FireBolt%" (
    if "%keep_dir%"=="0" (
        call dice.cmd :diceRoll 9 8
        call spells.cmd :spellFireBolt "%py.pos.y%;%py.pos.x%" "%dir%" "!errorlevel!" "%MagicSpellFlags.Fire%" "!spell_names[22]!"
    )
) else if "%~1"=="%MageSpellId.SpeedMonster%" (
    if "%keep_dir%"=="0" (
        call spells.cmd :spellSpeedMonster "%py.pos.y%;%py.pos.x%" "%dir%" -1
    )
) else if "%~1"=="%MageSpellId.FrostBall%" (
    if "%keep_dir%"=="0" (
        call spells.cmd :spellFireBall "%py.pos.y%;%py.pos.x%" "%dir%" 48 "%MagicSpellFlags.Frost%" "!spell_names[34]!"
    )
) else if "%~1"=="%MageSpellId.RechargeItem2%" (
    call spells.cmd :spellRechargeItem 60
) else if "%~1"=="%MageSpellId.TeleportOther%" (
    if "%keep_dir%"=="0" (
        call spells.cmd :spellTeleportAwayMonsterInDirection "%py.pos.y%;%py.pos.x%" "%dir%"
    )
) else if "%~1"=="%MageSpellId.HasteSelf%" (
    call rng.cmd :randomNumber 20
    set /a py.flags.fast+=!errorlevel!+%py.misc.level%
) else if "%~1"=="%MageSpellId.FireBall%" (
    if "%keep_dir%"=="0" (
        call spells :spellFireBall "%py.pos.y%;%py.pos.x%" "%dir%" 72 "%MageSpellFlags.Fire%" "!spell_names[28]!"
    )
) else if "%~1"=="%MageSpellId.WordOfDestruction%" (
    call spells.cmd :spellDestroyArea "%py.pos.y%;%py.pos.x%"
) else if "%~1"=="%MageSpellId.Genocide%" (
    call spells.cmd :spellGenocide
)
exit /b

::------------------------------------------------------------------------------
:: Cast a magic spell
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:getAndCastMagicSpell
set "game.player_free_turn=true"
call :canReadSpells || exit /b

call inventory.cmd :inventoryFindRange %tv_magic_book% %tv_never% i j || (
    call ui_io.cmd :printMessage "But you are not carrying any spell books."
    exit /b
)

call inventory.cmd :inventoryGetInputForItemId item_val "Use which spell book?" !i! !j! "CNIL" "CNIL" || exit /b

call spells.cmd :castSpellGetId "Cast which spell?" "!item_val!" spell_choice chance
if !errorlevel! LSS 0 (
    call ui_io.cmd :printMessage "You don't know any spells in that book."
    exit /b
) else if "!errorlevel!"=="0" (
    exit /b
)

set "game.player_free_turn=false"
set class_id_offset=%py.misc.class_id%-1

call rng.cmd :randomNumber 100
if !errorlevel! LSS %chance% (
    call ui_io.cmd :printMessage "You failed to get the spell off."
) else (
    set /a choice_offset=spell_choice+1
    call :castSpell !choice_offset!

    if "%game.player_free_turn%"=="false" (
        set /a "choice_shift=1<<%spell_choice%"
        set /a "valid_spell=%py.flags.spells_worked% & !choice_shift!"
        if "!valid_spell!"=="0" (
            set /a "py.misc.exp+=!magic_spells[%class_id_offset%][%spell_choice%].exp_gain_for_learning!<<2"
            set /a "py.flags.spells_worked|=(1<<%spell_choice%)"

            call ui.cmd :displayCharacterExperience
        )
    )
)

if "%game.player_free_turn%"=="true" exit /b

if !magic_spells[%class_id_offset%][%spell_choice%].mana_required! GTR %py.misc.current_mana% (
    call ui_io.cmd :printMessage "You faint from the effort."
    set /a "stuck_for_turns=5*(!magic_spells[%class_id_offset%][%spell_choice%].mana_required!-%py.misc.current_mana%)"
    call rng.cmd :randomNumber !stuck_for_turns!
    set "py.flags.paralysis=!errorlevel!"
    set /a py.misc.current_mana=0, py.misc.current_mana_fraction=0

    call rng.cmd :randomNumber 3
    if "!errorlevel!"=="1" (
        call ui_io.cmd :printMessage "You have damaged your health."
        call player_stats.cmd :playerStatRandomDecrease "%PlayerAttr.a_con%"
    )
) else (
    set /a py.misc.current_mana-=!magic_spells[%class_id_offset%][%spell_choice%].mana_required!
)
call ui.cmd :printCharacterCurrentMana
exit /b

::------------------------------------------------------------------------------
:: Returns spell chance of failure for class_to_use_mage_spells
::
:: Arguments: %1 - The ID of the spell being cast
:: Returns:   An integer between 5 and 95
::------------------------------------------------------------------------------
:spellChanceOfSuccess
set /a class_id_offset=%py.misc.class_id%-1
set /a "chance=!magic_spells[%class_id_offset%][%~1].failure_chance!-3*(%py.misc.level%-!magic_spells[%class_id_offset%][%~1].level_required!)"

if "!classes[%py.misc.class_id%].class_to_use_mage_spells!"=="%config.spells.spell_type_mage%" (
    set "stat=%PlayerAttr.a_int%"
) else (
    set "stat=%PlayerAttr.a_wis%"
)

call player_stats.cmd :playerStatAdjustmentWisdomIntelligence !stat!
set /a "chance-=3*(!errorlevel!-1)"

if !magic_spells[%class_id_offset%][%~1].mana_required! GTR %py.misc.current_mana% (
    set /a "chance+=5*(!magic_spells[%class_id_offset%][%~1].mana_required!-%py.misc.current_mana%)"
)

if !chance! GTR 95 set "chance=95"
if !chance! LSS 5 set "chance=5"
exit /b !chance!