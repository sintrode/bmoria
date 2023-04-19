call %*
exit /b

::------------------------------------------------------------------------------
:: Initiate some action based on the type of potion that was just consumed
::
:: Arguments: %1 - The flags associated with the item being consumed
::            %2 - The type of potion being quaffed
:: Returns:   0 if the player now knows what potion they just drank
::            1 if it is still a mystery for one reason or another
::------------------------------------------------------------------------------
:playerDrinkPotion
set "identified=1"
set "flags=%~1"

:drinkPotionLoop
if "!flags!"=="0" goto :drinkPotionAfterLoop
call helpers.cmd :getAndClearFirstBit "flags"
set /a potion_id=!errorlevel!+1

if "%potion_id%"=="%PotionSpellTypes.Strength%" (
    call player_stats.cmd :playerStatRandomIncrease %PlayerAttr.a_str% && (
        call ui_io.cmd :printMessage "You feel stronger."
        set "identified=0"
    )
) else if "%potion_id%"=="%PotionSpellTypes.Weakness%" (
    call spells.cmd :spellLoseSTR
    set "identified=0"
) else if "%potion_id%"=="%PotionSpellTypes.RestoreStrength%" (
    call player_stats.cmd :playerStatRestore %PlayerAttr.a_str% && (
        call ui_io.cmd :printMessage "You feel warm all over."
        set "identified=0"
    )
) else if "%potion_id%"=="%PotionSpellTypes.Intelligence%" (
    call player_stats.cmd :playerStatRandomIncrease %PlayerAttr.a_int% && (
        call ui_io.cmd :printMessage "You feel smarter."
        set "identified=0"
    )
) else if "%potion_id%"=="%PotionSpellTypes.LoseIntelligence%" (
    call spells.cmd :spellLoseINT
    set "identified=0"
) else if "%potion_id%"=="%PotionSpellTypes.RestoreIntelligence%" (
    call player_stats.cmd :playerStatRestore %PlayerAttr.a_int% && (
        call ui_io.cmd :printMessage "You have a warm feeling."
        set "identified=0"
    )
) else if "%potion_id%"=="%PotionSpellTypes.Wisdom%" (
    call player_stats.cmd :playerStatRandomIncrease %PlayerAttr.a_wis% && (
        call ui_io.cmd :printMessage "You have a profound thought."
        set "identified=0"
    )
) else if "%potion_id%"=="%PotionSpellTypes.LoseWisdom%" (
    call spells.cmd :spellLoseWIS
    set "identified=0"
) else if "%potion_id%"=="%PotionSpellTypes.RestoreWisdom%" (
    call player_stats.cmd :playerStatRestore %PlayerAttr.a_int% && (
        call ui_io.cmd :printMessage "You feel your wisdom returning."
        set "identified=0"
    )
) else if "%potion_id%"=="%PotionSpellTypes.Charisma%" (
    call player_stats.cmd :playerStatRandomIncrease %PlayerAttr.a_chr% && (
        call ui_io.cmd :printMessage "You feel more attractive."
        set "identified=0"
    )
) else if "%potion_id%"=="%PotionSpellTypes.Ugliness%" (
    call spells.cmd :spellLoseWIS
    set "identified=0"
) else if "%potion_id%"=="%PotionSpellTypes.RestoreCharisma%" (
    call player_stats.cmd :playerStatRestore %PlayerAttr.a_chr% && (
        call ui_io.cmd :printMessage "You feel your looks returning."
        set "identified=0"
    )
) else if "%potion_id%"=="%PotionSpellTypes.CureLightWounds%" (
    call dice.cmd :diceRoll 2 7
    call spells.cmd :spellChangePlayerHitPoints !errorlevel!
    set "identified=!errorlevel!"
) else if "%potion_id%"=="%PotionSpellTypes.CureSeriousWounds%" (
    call dice.cmd :diceRoll 4 7
    call spells.cmd :spellChangePlayerHitPoints !errorlevel!
    set "identified=!errorlevel!"
) else if "%potion_id%"=="%PotionSpellTypes.CureCriticalWounds%" (
    call dice.cmd :diceRoll 6 7
    call spells.cmd :spellChangePlayerHitPoints !errorlevel!
    set "identified=!errorlevel!"
) else if "%potion_id%"=="%PotionSpellTypes.Healing%" (
    call spells.cmd :spellChangePlayerHitPoints 1000
    set "identified=!errorlevel!"
) else if "%potion_id%"=="%PotionSpellTypes.Constitution%" (
    call player_stats.cmd :playerStatRandomIncrease %PlayerAttr.a_wis% && (
        call ui_io.cmd :printMessage "You feel tingly for a moment."
        set "identified=0"
    )
) else if "%potion_id%"=="%PotionSpellTypes.GainExperience%" (
    if %py.misc.exp% LSS %config.player.player_max_exp% (
        set /a exp=%py.misc.exp%/2+10
        if !exp! GTR 100000 set "exp=100000"
        set /a py.misc.exp+=!exp!

        call ui_io.cmd :printMessage "You feel more experienced."
        call ui.cmd :displayCharacterExperience
        set "identified=0"
    )
) else if "%potion_id%"=="%PotionSpellTypes.Sleep%" (
    if "%py.flags.free_action%"=="0" (
        call ui_io.cmd :printMessage "You fall asleep."
        call rng.cmd :randomNumber 4
        set /a py.flags.paralysis+=!errorlevel!+4
        set "identified=0"
    )
) else if "%potion_id%"=="%PotionSpellTypes.Blindness%" (
    if "%py.flags.blind%"=="0" (
        call ui_io.cmd :printMessage "You are covered by a veil of darkness."
        set "identified=0"
    )
    call rng.cmd :randomNumber 100
    set /a py.flags.blind+=!randomNumber!+100
) else if "%potion_id%"=="%PotionSpellTypes.Confusion%" (
    if "%py.flags.confused%"=="0" (
        call ui_io.cmd :printMessage "This is good stuff^^^! *hic*"
        set "identified=0"
    )
    call rng.cmd :randomNumber 20
    set /a py.flags.confused+=!randomNumber!+12
) else if "%potion_id%"=="%PotionSpellTypes.Poison%" (
    if "%py.flags.poisoned%"=="0" (
        call ui_io.cmd :printMessage "You feel very sick."
        set "identified=0"
    )
    call rng.cmd :randomNumber 15
    set /a py.flags.poisoned+=!randomNumber!+10
) else if "%potion_id%"=="%PotionSpellTypes.HasteSelf%" (
    if "%py.flags.fast%"=="0" (
        set "identified=0"
    )
    call rng.cmd :randomNumber 25
    set /a py.flags.fast+=!randomNumber!+15
) else if "%potion_id%"=="%PotionSpellTypes.Slowness%" (
    if "%py.flags.slow%"=="0" (
        set "identified=0"
    )
    call rng.cmd :randomNumber 25
    set /a py.flags.slow+=!randomNumber!+15
) else if "%potion_id%"=="%PotionSpellTypes.Dexterity%" (
    call player_stats.cmd :playerStatRandomIncrease %PlayerAttr.a_dex% && (
        call ui_io.cmd :printMessage "You feel more limber."
        set "identified=0"
    )
) else if "%potion_id%"=="%PotionSpellTypes.RestoreDexterity%" (
    call player_stats.cmd :playerStatRestore %PlayerAttr.a_dex% && (
        call ui_io.cmd :printMessage "You feel less clumsy."
        set "identified=0"
    )
) else if "%potion_id%"=="%PotionSpellTypes.RestoreConstitution%" (
    call player_stats.cmd :playerStatRestore %PlayerAttr.a_con% && (
        call ui_io.cmd :printMessage "You feel your health returning."
        set "identified=0"
    )
) else if "%potion_id%"=="%PotionSpellTypes.CureBlindness%" (
    call player_magic.cmd :playerCureBlindness
    set "identified=!errorlevel!"
) else if "%potion_id%"=="%PotionSpellTypes.CureConfusion%" (
    call player_magic.cmd :playerCureConfusion
    set "identified=!errorlevel!"
) else if "%potion_id%"=="%PotionSpellTypes.CurePoison%" (
    call player_magic.cmd :playerCurePoison
    set "identified=!errorlevel!"
) else if "%potion_id%"=="%PotionSpellTypes.LoseExperience%" (
    if %py.misc.exp% GTR 0 (
        call ui_io.cmd :printMessage "You feel your memories fade."

        set /a exp=%py.misc.exp%/5

        if %py.misc.exp% GTR 32767 (
            set /a scale=2147483647 / %py.misc.exp%
            call rng.cmd :randomNumber !scale!
            set /a "exp+=(!errorlevel! * %py.misc.exp%) / (!scale! * 5)"
        )
    ) else (
        call rng.cmd :randomNumber %py.misc.exp%
        set /a exp+=!errorlevel!/5
    )
    call spells.cmd :spellLoseEXP !exp!
    set "identified=0"
) else if "%potion_id%"=="%PotionSpellTypes.SaltWater%" (
    call player_magic.cmd :playerCurePoison
    if %py.flags.food% GTR 150 (
        set "py.flags.food=150"
    )
    set "py.flags.paralysis=4"
    call ui_io.cmd :printMessage "The potion makes you vomit."
    set "identified=0"
) else if "%potion_id%"=="%PotionSpellTypes.Invulnerability%" (
    if "%py.flags.invulnerabilty%"=="0" (
        set "identified=0"
    )
    call rng.cmd :randomNumber 10
    set /a py.flags.invulnerabilty+=!errorlevel!+10
) else if "%potion_id%"=="%PotionSpellTypes.Heroism%" (
    if "%py.flags.heroism%"=="0" (
        set "identified=0"
    )
    call rng.cmd :randomNumber 25
    set /a py.flags.heroism+=!errorlevel!+25
) else if "%potion_id%"=="%PotionSpellTypes.SuperHeroism%" (
    if "%py.flags.super_heroism%"=="0" (
        set "identified=0"
    )
    call rng.cmd :randomNumber 25
    set /a py.flags.super_heroism+=!errorlevel!+25
) else if "%potion_id%"=="%PotionSpellTypes.Boldness%" (
    call player_magic.cmd :playerRemoveFear
    set "identified=!errorlevel!"
) else if "%potion_id%"=="%PotionSpellTypes.RestoreLifeLevels%" (
    call player_magic.cmd :playerRestorePlayerLevels
    set "identified=!errorlevel!"
) else if "%potion_id%"=="%PotionSpellTypes.ResistHeat%" (
    if "%py.flags.heat_resistance%"=="0" (
        set "identified=0"
    )
    call rng.cmd :randomNumber 10
    set /a py.flags.heat_resistance+=!errorlevel!+10
) else if "%potion_id%"=="%PotionSpellTypes.ResistCold%" (
    if "%py.flags.cold_resistance%"=="0" (
        set "identified=0"
    )
    call rng.cmd :randomNumber 10
    set /a py.flags.cold_resistance+=!errorlevel!+10
) else if "%potion_id%"=="%PotionSpellTypes.DetectInvisible%" (
    if "%py.flags.detect_invisible%"=="0" (
        set "identified=0"
    )
    call rng.cmd :randomNumber 12
    set /a detect_steps=!errorlevel!+12
    call player_magic.cmd :playerDetectInvisible !detect_steps!
) else if "%potion_id%"=="%PotionSpellTypes.SlowPoison%" (
    call spells.cmd :spellsSlowPoison
    set "identified=!errorlevel!"
) else if "%potion_id%"=="%PotionSpellTypes.NeutralizePoison%" (
    call player_magic.cmd :playerCurePoison
    set "identified=!errorlevel!"
) else if "%potion_id%"=="%PotionSpellTypes.RestoreMana%" (
    if %py.misc.current_mana% LSS %py.misc.mana% (
        set "py.misc.current_mana=%py.misc.mana%"
        call ui_io.cmd :printMessage "You feel your head clear."
        call ui.cmd :printCharacterCurrentMana
        set "identified=0"
    )
) else if "%potion_id%"=="%PotionSpellTypes.InfraVision%" (
    if "%py.flags.timed_infra%"=="0" (
        call ui_io.cmd :printMessage "Your eyes begin to tingle."
        set "identified=0"
    )
    call rng.cmd :randomNumber 100
    set /a py.flags.timed_infra+=!errorlevel!+100
) else (
    call ui_io.cmd :printMessage "Internal error in :playerDrinkPotion"
)
goto :drinkPotionLoop

:drinkPotionAfterLoop
exit /b !identified!

::------------------------------------------------------------------------------
:: Check if there is even something to drink, and then drink it.
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:quaff
set "game.player_free_turn=true"

if "%py.pack.unique_items%"=="0" (
    call ui_io.cmd :printMessage "But you are not carrying anything."
    exit /b
)
call inventory.cmd :inventoryFindRange "%tv_potion1%" "%tv_potion2%" item_pos_begin item_pos_end || (
    call ui_io.cmd :printMessage "You are not carrying any potions."
    exit /b
)
call ui_inventory.cmd :inventoryGetInputForItemId item_id "Quaff which potion?" !item_pos_begin! !item_pos_end! || (
    exit /b
)

set "item=py.inventory[%item_id%]"
if "!%item%.flags!"=="0" (
    call ui_io.cmd :printMessage "You feel less thirsty."
    set "identified=0"
) else (
    call :playerDrinkPotion "!%item%.flags!" "!%item%.category_id!"
    set "identified=!errorlevel!"
)

if "%identified%"=="0" (
    call identification.cmd :itemSetColorlessAsIdentified "!%item%.category_id!" "!%item%.sub_category_id!" "!%item%.identification!"
    if "!errorlevel!"=="1" (
        set /a "py.misc.exp+=(!%item%.depth_first_found! + (%py.misc.level% >> 1)) / %py.misc.level%"
        call ui.cmd :displayCharacterExperience
        call identification.cmd :itemIdentify "py.inventory[!item_id!]" "item_id"
        set "item=py.inventory[!item_id!]"
    )
) else (
    call identification.cmd :itemSetColorlessAsIdentified "!%item%.category_id!" "!%item%.sub_category_id!" "!%item%.identification!"
    if "!errorlevel!"=="1" (
        call identification.cmd :itemSetAsTried "item"
    )
)

call player_eat.cmd :playerIngestFood !%item%.misc_use!
call identification.cmd :itemTypeRemainingCountDescription !item_id!
call inventory.cmd :inventoryDestroyItem !item_id!
exit /b