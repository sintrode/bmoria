call %*
exit /b

::------------------------------------------------------------------------------
:: Determine if a player has the capacity to pray and display a message if not
::
:: Arguments: %1 - A reference to the inventory search start index
::            %2 - A reference to the inventory search end index
:: Returns:   0 if the player is able to pray
::            1 if there is some reason that they are not able to pray
::------------------------------------------------------------------------------
:playerCanPray
if %py.flags.blind% GTR 0 (
    call ui_io.cmd :printMessage "You can't see to read your prayer."
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

:: God: "Literally who are you"
if not "!classes[%py.misc.class_id%].class_to_use_mage_spell!"=="%config.spells.spell_type_priest%" (
    call ui_io.cmd :printMessage "Pray hard enough and your prayers may be answered."
    exit /b 1
)

if "%py.pack.unique_items%"=="0" (
    call ui_io.cmd :printMessage "But you are not carrying anything."
    exit /b 1
)

call inventory.cmd :inventoryFindRange %tv_prayer_book% %tv_never% "%~1" "%~2" || (
    call ui_io.cmd :printMessage "You are not carrying any Holy Books."
    exit /b 1
)
exit /b 0

::------------------------------------------------------------------------------
:: Recite a prayer - it's like casting a spell, but different
::
:: Arguments: The index of the prayer in PriestSpellTypes to recite
:: Returns:   None
::------------------------------------------------------------------------------
:playerRecitePrayer
set /a prayer_type=%~1+1

if "%prayer_type%"=="%PriestSpellTypes.DetectEvil%" (
    call spells.cmd :spellDetectEvil
) else if "%prayer_type%"=="%PriestSpellTypes.CureLightWounds%" (
    call dice.cmd :diceRoll 3 3
    call spells.cmd :spellChangePlayerHitPoints !errorlevel!
) else if "%prayer_type%"=="%PriestSpellTypes.Bless%" (
    call rng.cmd :randomNumber 12
    set /a bless_amount=!errorlevel!+12
    call player_magic.cmd :playerBless !bless_amount!
    set "bless_amount="
) else if "%prayer_type%"=="%PriestSpellTypes.RemoveFear%" (
    call player_magic.cmd :playerRemoveFear
) else if "%prayer_type%"=="%PriestSpellTypes.CallLight%" (
    call spells.cmd :spellLightArea "%py.pos.y%;%py.pos.x%"
) else if "%prayer_type%"=="%PriestSpellTypes.FindTraps%" (
    call spells.cmd :spellDetectTrapsWithinVicinity
) else if "%prayer_type%"=="%PriestSpellTypes.DetectDoorsStairs%" (
    call spells.cmd :spellDetectSecretDoorssWithinVicinity
) else if "%prayer_type%"=="%PriestSpellTypes.SlowPoison%" (
    call spells.cmd :spellSlowPoison
) else if "%prayer_type%"=="%PriestSpellTypes.BlindCreature%" (
    call game.cmd :getDirectionWithMemory "CNIL" "dir"
    if "!errorlevel!"=="0" (
        call spells.cmd :spellConfuseMonster "%py.pos.y%;%py.pos.x%" "!dir!"
    )
) else if "%prayer_type%"=="%PriestSpellTypes.Portal%" (
    set /a teleport_range=%py.misc.level% * 3
    call player.cmd :playerTeleport !teleport_range!
    set "teleport_range="
) else if "%prayer_type%"=="%PriestSpellTypes.CureMediumWounds%" (
    call dice.cmd :diceRoll 4 4
    call spells.cmd :spellChangePlayerHitPoints !errorlevel!
) else if "%prayer_type%"=="%PriestSpellTypes.Chant%" (
    call rng.cmd :randomNumber 24
    set /a bless_amount=!errorlevel!+24
    call player_magic.cmd :playerBless !bless_amount!
    set "bless_amount="
) else if "%prayer_type%"=="%PriestSpellTypes.Sanctuary%" (
    call monster.cmd :monsterSleep "%py.pos.y%;%py.pos.x%"
) else if "%prayer_type%"=="%PriestSpellTypes.CreateFood%" (
    call spells.cmd :spellCreateFood
) else if "%prayer_type%"=="%PriestSpellTypes.RemoveCurse%" (
    for /L %%A in (0,1,33) do (
        if !py.inventory[%%A].category_id! GEQ %tv_min_wear% (
            if !py.inventory[%A%].category_id! LEQ %tv_max_wear% (
                call inventory.cmd :inventoryItemRemoveCurse "py.inventory[%%A]"
            )
        )
    )
) else if "%prayer_type%"=="%PriestSpellTypes.ResistHeadCold%" (
    call rng.cmd :randomNumber 10
    set /a py.flags.heat_resistance+=!errorlevel!+10
    call rng.cmd :randomNumber 10
    set /a py.flags.cold_resistance+=!errorlevel!+10
) else if "%prayer_type%"=="%PriestSpellTypes.NeutralizePoison%" (
    call player_magic.cmd :playerCurePoison
) else if "%prayer_type%"=="%PriestSpellTypes.OrbOfDraining%" (
    call game.cmd :getDirectionWithMemory "CNIL" "dir"
    if "!errorlevel!"=="0" (
        call dice.cmd :diceRoll 3 6
        set /a ball_damage=!errorlevel!+%py.misc.level%
        call spells.cmd :spellFireBall "%py.pos.y%;%py.pos.x%" "!dir!" !ball_damage! %MagicSpellFlags.HolyOrb% "Black Sphere"
    )
) else if "%prayer_type%"=="%PriestSpellTypes.CureSeriousWounds%" (
    call dice.cmd :diceRoll 8 4
    call spells.cmd :spellChangePlayerHitPoints !errorlevel!
) else if "%prayer_type%"=="%PriestSpellTypes.SenseInvisible%" (
    call rng.cmd :randomNumber 24
    set /a invisible_steps=!errorlevel!+24
    call player_magic.cmd :playerDetectInvisible !invisible_steps!
    set "invisible_steps="
) else if "%prayer_type%"=="%PriestSpellTypes.ProtectFromEvil%" (
    call player_magic.cmd :playerProtectEvil
) else if "%prayer_type%"=="%PriestSpellTypes.Earthquake%" (
    call spells.cmd :spellEarthquake
) else if "%prayer_type%"=="%PriestSpellTypes.SenseSurroundings%" (
    call spells.cmd :spellMapCurrentArea
) else if "%prayer_type%"=="%PriestSpellTypes.CureCriticalWounds%" (
    call dice.cmd :diceRoll 16 4
    call spells.cmd :spellChangePlayerHitPoints !errorlevel!
) else if "%prayer_type%"=="%PriestSpellTypes.TurnUndead%" (
    call spells.cmd :spellTurnUndead
) else if "%prayer_type%"=="%PriestSpellTypes.Prayer%" (
    call rng.cmd :randomNumber 48
    set /a bless_amount=!errorlevel!+48
    call player_magic.cmd :playerBless !bless_amount!
    set "bless_amount="
) else if "%prayer_type%"=="%PriestSpellTypes.DispelUndead%" (
    set /a level_x3=%py.misc.level%*3
    call spells.cmd :spellDispelCreature %config.monsters.defense.cd_undead% !level_x3!
    set "level_x3="
) else if "%prayer_type%"=="%PriestSpellTypes.Heal%" (
    call spells.cmd :spellChangePlayerHitPoints 200
) else if "%prayer_type%"=="%PriestSpellTypes.DispelEvil%" (
    set /a level_x3=%py.misc.level%*3
    call spells.cmd :spellDispelCreature %config.monsters.defense.cd_evil% !level_x3!
    set "level_x3="
) else if "%prayer_type%"=="%PriestSpellTypes.GlyphOfWarding%" (
    call spells.cmd :spellWardingGlyph
) else if "%prayer_type%"=="%PriestSpellTypes.HolyWord%" (
    call player_magic.cmd :playerRemoveFear
    call player_magic.cmd :playerCurePoison
    call spells.cmd :spellChangePlayerHitPoints 1000

    for /L %%A in (%PlayerAttr.a_str%,1,%PlayerAttr.a_chr%) do call player_stats.cmd :playerStatRestore %%A

    set /a level_x4=%py.misc.level%*4
    call spells.cmd :spellDispelCreature %config.monsters.defense.cd_evil% !level_x4!
    set "level_x4="
    call spells.cmd :spellTurnUndead

    if %py.flags.Invulnerability% LSS 3 (
        set "py.flags.invulnerability=3"
    ) else (
        set /a py.flags.invulnerability+=1
    )
)
exit /b

::------------------------------------------------------------------------------
:: It's like casting magic, but a second person is involved
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:pray
set "game.player_free_turn=true"
call :playerCanPray item_pos_begin item_pos_end || exit /b
call ui_inventory.cmd :inventoryGetInputForItemId item_id "Use which Holy Book?" !item_pos_begin! !item_pos_end! "CNIL" "CNIL" || exit /b
call spells.cmd :castSpellGetId "Recite which prayer?" !item_id! "prayer_choice" "chance"
if !errorlevel! LSS 0 (
    call ui_io.cmd :printMessage "You don't know any prayers in that book."
    exit /b
) else if "!errorlevel!"=="0" (
    exit /b
)

set /a class_dec=%py.misc.class_id%-1
set "spell=magic_spells[%class_dec%][%prayer_choice%]"

set "game.player_free_turn=false"
call rng.cmd :randomNumber 100
if !errorlevel! LSS %chance% (
    call ui_io.cmd :printMessage "You lost your concentration."
) else (
    call :playerRecitePrayer "%prayer_choice%"
    if "!game.player_free_turn!"=="false" (
        set /a "is_new_spell=%py.flags.spells_worked% & (1 << %prayer_choice%)"
        if "!is_new_spell!"=="0" (
            set /a "py.misc.exp+=!%spell%.exp_gain_for_learning! << 2"
            call ui.cmd :displayCharacterExperience
            set /a "py.flags.spells_worked|=(1 << %prayer_choice%)"
        )
    )
)

if "%game.player_free_turn%"=="true" exit /b

if !%spell%.mana_required! GTR %py.misc.current_mana% (
    call ui_io.cmd :printMessage "You faint from fatigue."
    set /a "paralyze_turns=5 * (!%spell%.mana_required! - %py.misc.current_mana%)"
    call rng.cmd :randomNumber !paralyze_turns!
    set /a py.flags.paralysis=!errorlevel!
    set "py.misc.current_mana=0"
    set "py.misc.current_mana_fraction=0"

    call rng.cmd :randomNumber 3
    if "!errorlevel!"=="1" (
        call ui_io.cmd :printMessage "You have damaged your health."
        call player_stats.cmd :playerStatRandomDecrease %PlayerAttr.a_con%
    )
) else (
    set /a py.misc.current_mana-=!%spell%.mana_required!
)

call ui.cmd :printCharacterCurrentMana
exit /b