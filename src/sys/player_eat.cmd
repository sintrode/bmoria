call %*
exit /b

::------------------------------------------------------------------------------
:: Allows the player to eat some food.
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerEat
set "game.player_free_turn=true"

if "%py.pack.unique_items%"=="0" (
    call ui_io.cmd :printMessage "But you are not carrying anything."
    exit /b
)

call inventory.cmd :inventoryFindRange "%tv_food%" "%tv_never%" item_pos_start item_pos_end || (
    call ui_io.cmd :printMessage "You are not carrying any food."
    exit /b
)

call ui_inventory.cmd :inventoryGetInputForItemId item_id "Eat what?" %item_pos_start% %item_pos_end% "CNIL" "CNIL" || exit /b

set "game.player_free_turn=false"
set "identified=false"

set "item=py.inventory[%item_id%]"
set "item_flags=!%item%.flags!"

:playerEatLoop
if "!item_flags!"=="0" goto :playerEatAfterLoop
call helpers.getAndClearFirstBit "item_flags"
set clear_flag_inc=!errorlevel!+1

if "!clear_flag_inc!"=="%FoodMagicTypes.Poison%" (
    call rng.cmd :randomNumber 10
    set /a py.flags.poisoned+=!errorlevel!+!%item%.depth_first_found!
    set "identified=true"
    goto :playerEatAfterLoop
) else if "!clear_flag_inc!"=="%FoodMagicTypes.Blindness%" (
    call rng.cmd :randomNumber 250
    set /a py.flags.blind+=!errorlevel!+10*!%item%.depth_first_found!+100
    call ui.cmd :drawCavePanel
    call ui_io.cmd :printMessage "A veil of darkness surrounds you."
    set "identified=true"
    goto :playerEatAfterLoop
) else if "!clear_flag_inc!"=="%FoodMagicTypes.Paranoia%" (
    call rng.cmd :randomNumber 10
    set /a py.flags.afraid+=!errorlevel!+!%item%.depth_first_found!
    call ui_io.cmd :printMessage "You feel terrified."
    set "identified=true"
    goto :playerEatAfterLoop
) else if "!clear_flag_inc!"=="%FoodMagicTypes.Confusion%" (
    call rng.cmd :randomNumber 10
    set /a py.flags.confused+=!errorlevel!+!%item%.depth_first_found!
    set "identified=true"
    goto :playerEatAfterLoop
) else if "!clear_flag_inc!"=="%FoodMagicTypes.Hallucination%" (
    call rng.cmd :randomNumber 200
    set /a py.flags.image+=!randomNumber!+25*!%item%.depth_first_found!+200
    call ui_io.cmd :printMessage "You feel drugged."
    set "identified=true"
    goto :playerEatAfterLoop
) else if "!clear_flag_inc!"=="%FoodMagicTypes.CurePoison%" (
    call player_magic.cmd :playerCurePoison
    if "!errorlevel!"=="0" set "identified=true"
    goto :playerEatAfterLoop
) else if "!clear_flag_inc!"=="%FoodMagicTypes.CureBlindness%" (
    call player_magic.cmd :playerCureBlindness
    if "!errorlevel!"=="0" set "identified=true"
    goto :playerEatAfterLoop
) else if "!clear_flag_inc!"=="%FoodMagicTypes.CureParanoia%" (
    REM No idea why this one doesn't have its own dedicated subroutine
    REM We'll fix that in the second pass of code-writing
    if %py.flags.afraid% GTR 1 (
        set "py.flags.afraid=1"
        set "identified=true"
    )
    goto :playerEatAfterLoop
) else if "!clear_flag_inc!"=="%FoodMagicTypes.CureConfusion%" (
    call player_magic.cmd :playerCureConfusion
    if "!errorlevel!"=="0" set "identified=true"
    goto :playerEatAfterLoop
) else if "!clear_flag_inc!"=="%FoodMagicTypes.Weakness%" (
    call spells.cmd :spellLoseSTR
    set "identified=true"
    goto :playerEatAfterLoop
) else if "!clear_flag_inc!"=="%FoodMagicTypes.Unhealth%" (
    call spells.cmd :spellLoseCON
    set "identified=true"
    goto :playerEatAfterLoop
) else if "!clear_flag_inc!"=="%FoodMagicTypes.RestoreSTR%" (
    call player_stats.cmd :playerStatRestore %PlayerAttr.a_str% && (
        call ui_io.cmd :printMessage "You feel your strength returning."
        set "identified=true"
    )
    goto :playerEatAfterLoop
) else if "!clear_flag_inc!"=="%FoodMagicTypes.RestoreCON%" (
    call player_stats.cmd :playerStatRestore %PlayerAttr.a_con% && (
        call ui_io.cmd :printMessage "You feel your health returning."
        set "identified=true"
    )
    goto :playerEatAfterLoop
) else if "!clear_flag_inc!"=="%FoodMagicTypes.RestoreINT%" (
    call player_stats.cmd :playerStatRestore %PlayerAttr.a_int% && (
        call ui_io.cmd :printMessage "Your head spins a moment."
        set "identified=true"
    )
    goto :playerEatAfterLoop
) else if "!clear_flag_inc!"=="%FoodMagicTypes.RestoreWIS%" (
    call player_stats.cmd :playerStatRestore %PlayerAttr.a_wis% && (
        call ui_io.cmd :printMessage "You feel your wisdom returning."
        set "identified=true"
    )
    goto :playerEatAfterLoop
) else if "!clear_flag_inc!"=="%FoodMagicTypes.RestoreDEX%" (
    call player_stats.cmd :playerStatRestore %PlayerAttr.a_dex% && (
        call ui_io.cmd :printMessage "You feel more dexterous."
        set "identified=true"
    )
    goto :playerEatAfterLoop
) else if "!clear_flag_inc!"=="%FoodMagicTypes.RestoreCHR%" (
    call player_stats.cmd :playerStatRestore %PlayerAttr.a_chr% && (
        call ui_io.cmd :printMessage "Your skin stops itching."
        set "identified=true"
    )
    goto :playerEatAfterLoop
) else if "!clear_flag_inc!"=="%FoodMagicTypes.FirstAid%" (
    call rng.cmd :randomNumber 6
    call spells.cmd :spellChangePlayerHitPoints !errorlevel!
    if "!errorlevel!"=="0" set "identified=true"
    goto :playerEatAfterLoop
) else if "!clear_flag_inc!"=="%FoodMagicTypes.MinorCures%" (
    call rng.cmd :randomNumber 12
    call spells.cmd :spellChangePlayerHitPoints !errorlevel!
    if "!errorlevel!"=="0" set "identified=true"
    goto :playerEatAfterLoop
) else if "!clear_flag_inc!"=="%FoodMagicTypes.LightCures%" (
    call rng.cmd :randomNumber 18
    call spells.cmd :spellChangePlayerHitPoints !errorlevel!
    if "!errorlevel!"=="0" set "identified=true"
    goto :playerEatAfterLoop
) else if "!clear_flag_inc!"=="%FoodMagicTypes.MajorCures%" (
    call dice.cmd :diceRoll 3 12
    call spells.cmd :spellChangePlayerHitPoints !errorlevel!
    if "!errorlevel!"=="0" set "identified=true"
    goto :playerEatAfterLoop
) else if "!clear_flag_inc!"=="%FoodMagicTypes.PoisonousFood%" (
    call rng.cmd :randomNumber 18
    call player.cmd :playerTakesHit !errorlevel! "poisonous food."
    set "identified=true"
    goto :playerEatAfterLoop
) else (
    call ui_io.cmd :printMessage "Internal error in :playerEat"
    goto :playerEatAfterLoop
)
goto :playerEatLoop

:playerEatAfterLoop
:: The player has technically identified an item, so grant experience
if "!identified!"=="true" (
    call identification.cmd :itemSetColorlessAsIdentified !%item%.category_id! !%item%.sub_category_id! !%item%.identification! || (
        set /a "py.misc.exp+=(!%item%.depth_first_found! + (%py.misc.level% >> 1)) / %py.misc.level%"
        call ui.cmd :displayCharacterExperience
        call identification.cmd :itemIdentify "py.inventory[%item_id%]" "item_id"
        set "item=py.inventory[!item_id!]"
    )
) else (
    call identification.cmd :itemSetColorlessAsIdentified !%item%.category_id! !%item%.sub_category_id! !%item%.identification! || (
        call identification.cmd :itemSetAsTried "!item!"
    )
)

call :playerIngestFood "!%item%.misc_use!"
set /a "py.flags.status&=~(%config.player.status.py_weak% | %config.player.status.py_hungry%)"

call ui.cmd :printCharacterHungerStatus

call identification.cmd :itemTypeRemainingCountDescription "%item_id%"
call inventory.cmd :inventoryDestroyItem "%item_id%"
exit /b

::------------------------------------------------------------------------------
:: Add to the player's food time
::
:: Arguments: %1 - The amount of food eaten by the player
:: Returns:   None
::------------------------------------------------------------------------------
:playerIngestFood
set "amount=%~1"
if %py.flags.food% LSS 0 (
    set "py.flags.food=0"
)

set /a py.flags.food+=%amount%
if %py.flags.food% GTR %config.player.player_food_max% (
    call ui_io.cmd :printMessage "You are bloated from overeating."

    REM Calculate how much is responsible for the bloating. Give the player
    REM food credit for 1/50 and slow them for that many turns.
    set /a extra=%py.flags.food%-%config.player.player_food_max%
    if !extra! GTR %amount% (
        set "extra=%amount%"
    )
    set /a penalty=!extra!/50

    set /a py.flags.slow+=!penalty!

    if "!extra!"=="%amount%" (
        set /a py.flags.food-=%amount%+!penalty!
    ) else (
        set /a py.flags.food=%config.player.player_food_max%+!penalty!
    )
) else if %py.flags.food% GTR %config.player.player_food_full% (
    call ui_io.cmd :printMessage "You are full."
)
exit /b