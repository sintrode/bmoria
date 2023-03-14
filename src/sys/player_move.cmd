@echo off
call %*
exit /b

::------------------------------------------------------------------------------
:: The player falls into a pit
::
:: Arguments: %1 - A reference to the trap that has been activated
::            %2 - The damage done by the trap
:: Returns:   None
::------------------------------------------------------------------------------
:trapOpenPit
call ui_io.cmd :printMessage "You fall into a pit."

if "%py.flags.free_fall%"=="true" (
    call ui_io.cmd :printMessage "You gently float down."
    exit /b
)

call identification.cmd :itemDescription "description" "!%~1!" "true"
call player.cmd :playerTakesHit "%~2" "!description!"
exit /b 

::------------------------------------------------------------------------------
:: The player is shot by an arrow
::
:: Arguments: %1 - A reference to the trap that has been activated
::            %2 - The damage done by the trap
:: Returns:   None
::------------------------------------------------------------------------------
:trapArrow
set /a ac_total=%py.misc.ac%+%py.misc.magical_ac%
call player.cmd :playerTestBeingHit 125 0 0 %ac_total% %class_misc_hit%
if "!errorlevel!"=="0" (
    call identification.cmd :itemDescription "description" "!%~1!" "true"
    call player.cmd :playerTakesHit "%~2" "!description!"
    call ui_io.cmd :printMessage "An arrow hits you."
    exit /b
)
call ui_io.cmd :printMessage "An arrow barely misses you."
exit /b 

::------------------------------------------------------------------------------
:: The player falls into a previously-covered pit
::
:: Arguments: %1 - A reference to the trap that has been activated
::            %2 - The damage done by the trap
::            %3 - The coordinates of the trap
:: Returns:   None
::------------------------------------------------------------------------------
:trapCoveredPit
call ui_io.cmd :printMessage "You fall into a covered pit."

if "%py.flags.free_fall%"=="true" (
    call ui_io.cmd :printMessage "You gently float down."
) else (
    call identification.cmd :itemDescription "description" "!%~1!" "true"
    call player.cmd :playerTakesHit "%~2" "!description!"
)

set "coord=%~3"
call dungeon.cmd :dungeonSetTrap "coord" 0
exit /b 

::------------------------------------------------------------------------------
:: The player falls through a trap door
::
:: Arguments: %1 - A reference to the trap that has been activated
::            %2 - The damage done by the trap
:: Returns:   None
::------------------------------------------------------------------------------
:trapDoor
set "dg.generate_new_level=true"
set /a dg.current_level+=1

call ui_io.cmd :printMessage "You fall through a trap door."

if "%py.flags.free_fall%"=="true" (
    call ui_io.cmd :printMessage "You gently float down."
) else (
    call identification.cmd :itemDescription "description" "!%~1!" "true"
    call player.cmd :playerTakesHit "%~2" "!description!"
)

call ui_io.cmd :printMessage "CNIL"
exit /b 

::------------------------------------------------------------------------------
:: The player is affected by sleeping gas
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:trapSleepingGas
if not "%py.flags.paralysis%"=="0" exit /b

call ui_io.cmd :printMessage "A strange white mist surrounds you."
if "%py.flags.free_action%"=="true" (
    call ui_io.cmd :printMessage "You are unaffected."
    exit /b
)

call rng.cmd :randomNumber 10
set /a py.flags.paralysis+=!errorlevel!+4
call ui_io.cmd :printMessage "You fall asleep."
exit /b 

::------------------------------------------------------------------------------
:: The player finds a hidden object
::
:: Arguments: %1 - The coordinates of the player
:: Returns:   None
::------------------------------------------------------------------------------
:trapHiddenObject
set "coord=%~1"
call dungeon.cmd :dungeonDeleteObject "coord"
call dungeon.cmd :dungeonPlaceRandomObjectAt "coord" "false"
call ui_io.cmd :printMessage "Hmmm, there was something under this rock."
exit /b 

::------------------------------------------------------------------------------
:: The player gets hit with a strength-reduction dart
::
:: Arguments: %1 - A reference to the trap that has been activated
::            %2 - The damage done by the trap
:: Returns:   None
::------------------------------------------------------------------------------
:trapStrengthDart
set /a ac_total=%py.misc.ac%+%py.misc.magical_ac%
call player.cmd :playerTestBeingHit 125 0 0 %ac_total% %class_misc_hit%
if "!errorlevel!"=="0" (
    if "%py.flags.sustain_str%"=="false" (
        call player_stats.cmd :playerStatRandomDecrease "%PlayerAttr.a_str%"
        call identification.cmd :itemDescription "description" "!%~1!" "true"
        call player.cmd :playerTakesHit "%~2" "!description!"
        call ui_io.cmd :printMessage "A small dart weakens you."
    ) else (
        call ui_io.cmd :printMessage "A small dart hits you."
    )
)
call ui_io.cmd :printMessage "A small dart barely misses you."
exit /b 

::------------------------------------------------------------------------------
:: The player is teleported away
::
:: Arguments: %1 - The coordinates of the player
:: Returns:   None
::------------------------------------------------------------------------------
:trapTeleport
set "coord=%~1"
set "game.teleport_player=true"
call ui_io.cmd :printMessage "You hit a teleport trap."

:: Light up the trap before we teleport away
call dungeon.cmd :dungeonMoveCharacterLight "coord" "coord"
exit /b 

::------------------------------------------------------------------------------
:: The player is hit by a falling rock
::
:: Arguments: %1 - The coordinates of the player
::            %2 - The damage done by the falling rock
:: Returns:   None
::------------------------------------------------------------------------------
:trapRockfall
set "coord=%~1"
call player.cmd :playerTakesHit "%~2" "a falling rock"
call dungeon.cmd :dungeonDeleteObject "coord"
call dungeon.cmd :dungeonPlaceRubble "coord"
call ui_io.cmd :printMessage "You are hit by a falling rock."
exit /b 

::------------------------------------------------------------------------------
:: The player is surrounded by corroding gas
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:trapCorrodeGas
call ui_io.cmd :printMessage "A strange red gas surrounds you."
call inventory.cmd :damageCorrodingGas "corrosion gas"
exit /b 

::------------------------------------------------------------------------------
:: A monster is summoned
::
:: Arguments: %1 - The coordinates of the player
:: Returns:   None
::------------------------------------------------------------------------------
:trapSummonMonster
set "coord=%1"
call dungeon.cmd :dungeonDeleteObject "coord"
call rng.cmd :randomNumber 3
set /a num=!errorlevel!+2
for /f "tokens=1,2 delims=;" %%A in ("%~1") do (
    set "coord.y=%%~A"
    set "coord.x=%%~B"
)
for /L %%A in (1,1,%num%) do (
    set "location=!coord.y!;!coord.x!"
    call monster_manager.cmd :monsterSummon "location" "false"
)
exit /b 

::------------------------------------------------------------------------------
:: The player is surrounded by fire
::
:: Arguments: %1 - The damage done by the fire
:: Returns:   None
::------------------------------------------------------------------------------
:trapFire
call ui_io.cmd :printMessage "You are enveloped by flames."
call inventory.cmd :damageFire "%~1" "a fire trap"
exit /b 

::------------------------------------------------------------------------------
:: The player is surrounded by acid
::
:: Arguments: %1 - The damage done by the acid
:: Returns:   None
::------------------------------------------------------------------------------
:trapAcid
call ui_io.cmd :printMessage "You are splashed by acid."
call inventory.cmd :damageAcid "%~1" "an acid trap"
exit /b 

::------------------------------------------------------------------------------
:: The player is surrounded by poison gas
::
:: Arguments: %1 - The damage done by the poison gas
:: Returns:   None
::------------------------------------------------------------------------------
:trapPoisonGas
call ui_io.cmd :printMessage "A pungent green gas surrounds you."
call inventory.cmd :damagePoisonedGas "%~1" "a poison gas trap"
exit /b 

::------------------------------------------------------------------------------
:: The player is surrounded by blinding gas
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:trapBlindGas
call ui_io.cmd :printMessage "A black gas surrounds you."
call rng.cmd :randomNumber 50
set /a py.flags.blind+=!errorlevel!+50
exit /b 

::------------------------------------------------------------------------------
:: The player is surrounded by confusing gas
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:trapConfuseGas
call ui_io.cmd :printMessage "A gas of scintillating colors surrounds you."
call rng.cmd :randomNumber 15
set /a py.flags.confused+=!errorlevel!+15
exit /b 

::------------------------------------------------------------------------------
:: The player gets hit with a speed-reduction dart
::
:: Arguments: %1 - A reference to the trap that has been activated
::            %2 - The damage done by the trap
:: Returns:   None
::------------------------------------------------------------------------------
:trapSlowDart
set /a ac_total=%py.misc.ac%+%py.misc.magical_ac%
call player.cmd :playerTestBeingHit 125 0 0 %ac_total% %class_misc_hit%
if "!errorlevel!"=="0" (
    call identification.cmd :itemDescription "description" "!%~1!" "true"
    call player.cmd :playerTakesHit "%~2" "!description!"
    call ui_io.cmd :printMessage "A small dart hits you."

    if "%py.flags.free_action%"=="true" (
        call ui_io.cmd :printMessage "You are unaffected."
    ) else (
        call rng.cmd :randomNumber 20
        set /a py.flags.slow+=!errorlevel!+10
    )
) else (
    call ui_io.cmd :printMessage "A small dart barely misses you."
)
exit /b 

::------------------------------------------------------------------------------
:: The player gets hit with a constitution-reduction dart
::
:: Arguments: %1 - A reference to the trap that has been activated
::            %2 - The damage done by the trap
:: Returns:   None
::------------------------------------------------------------------------------
:trapConstitutionDart
set /a ac_total=%py.misc.ac%+%py.misc.magical_ac%
call player.cmd :playerTestBeingHit 125 0 0 %ac_total% %class_misc_hit%
if "!errorlevel!"=="0" (
    if "%py.flags.sustain_con%"=="false" (
        call player_stats.cmd :playerStatRandomDecrease "%PlayerAttr.a_con%"
        call identification.cmd :itemDescription "description" "!%~1!" "true"
        call player.cmd :playerTakesHit "%~2" "!description!"
        call ui_io.cmd :printMessage "A small dart saps your health."
    ) else (
        call ui_io.cmd :printMessage "A small dart hits you."
    )
)
call ui_io.cmd :printMessage "A small dart barely misses you."
exit /b 

::------------------------------------------------------------------------------
:: A wrapper for the player stepping on a trap
::
:: Arguments: %1 - The coordinates of the player
:: Returns:   None
::------------------------------------------------------------------------------
:playerStepsOnTrap
set "coord=%~1"
call player_run.cmd :playerEndRunning
call dungeon.cmd :trapChangeVisibility "coord"

for /f "tokens=1,2 delims=;" %%A in ("%~1") do (
    set "t_id=!dg.floor[%%A][%%B].treasure_id!"
)
set "item=game.treasure.list[%t_id%]"
call dice.cmd :diceRoll "!%item%.damage.dice!" "!%item.damage.sides!"
set "damage=!errorlevel!"

:: TODO: Stick each option in an array element and call that element instead of
::       having a massive nested if statement chain
if "!%item%.sub_category_id!"=="%TrapTypes.OpenPit%" (
    call :trapOpenPit "%item%" "%damage%"
) else if "!%item%.sub_category_id!"=="%TrapTypes.ArrowPit%" (
    call :trapArrow "%item%" "%damage%"
) else if "!%item%.sub_category_id!"=="%TrapTypes.CoveredPit%" (
    call :trapCoveredPit "%item%" "%damage%" "%coord%"
) else if "!%item%.sub_category_id!"=="%TrapTypes.TrapDoor%" (
    call :trapDoor "%item%" "%damage%"
) else if "!%item%.sub_category_id!"=="%TrapTypes.SleepingGas%" (
    call :trapSleepingGas
) else if "!%item%.sub_category_id!"=="%TrapTypes.HiddenObject%" (
    call :trapHiddenObject "%coord%"
) else if "!%item%.sub_category_id!"=="%TrapTypes.DartOfStr%" (
    call :trapStrengthDart "%item%" "%damage%"
) else if "!%item%.sub_category_id!"=="%TrapTypes.Teleport%" (
    call :trapTeleport "%coord%"
) else if "!%item%.sub_category_id!"=="%TrapTypes.Rockfall%" (
    call :trapRockfall "%coord%" "%damage%"
) else if "!%item%.sub_category_id!"=="%TrapTypes.CorrodingGas%" (
    call :trapCorrodeGas
) else if "!%item%.sub_category_id!"=="%TrapTypes.SummonMonster%" (
    call :trapSummonMonster "%coord%"
) else if "!%item%.sub_category_id!"=="%TrapTypes.FireTrap%" (
    call :trapFire "%damage%"
) else if "!%item%.sub_category_id!"=="%TrapTypes.AcidTrap%" (
    call :trapAcid "%damage%"
) else if "!%item%.sub_category_id!"=="%TrapTypes.PoisonGasTrap%" (
    call :trapPoisonGas "%damage%"
) else if "!%item%.sub_category_id!"=="%TrapTypes.BlindingGas%" (
    call :trapBlindGas
) else if "!%item%.sub_category_id!"=="%TrapTypes.ConfuseGas%" (
    call :trapConfuseGas
) else if "!%item%.sub_category_id!"=="%TrapTypes.SlowDart%" (
    call :trapSlowDart "%item%" "%damage%"
) else if "!%item%.sub_category_id!"=="%TrapTypes.DartOfCon%" (
    call :trapConstitutionDart "%item%" "%damage%"
) else if "!%item%.sub_category_id!"=="%TrapTypes.SecretDoor%" (
    exit /b
) else if "!%item%.sub_category_id!"=="%TrapTypes.ScareMonster%" (
    exit /b
) else if "!%item%.sub_category_id!"=="%TrapTypes.GeneralStore%" (
    call store.cmd :storeEnter 0
) else if "!%item%.sub_category_id!"=="%TrapTypes.Armory%" (
    call store.cmd :storeEnter 1
) else if "!%item%.sub_category_id!"=="%TrapTypes.Weaponsmith%" (
    call store.cmd :storeEnter 2
) else if "!%item%.sub_category_id!"=="%TrapTypes.Temple%" (
    call store.cmd :storeEnter 3
) else if "!%item%.sub_category_id!"=="%TrapTypes.Alchemist%" (
    call store.cmd :storeEnter 4
) else if "!%item%.sub_category_id!"=="%TrapTypes.MagicShop%" (
    call store.cmd :storeEnter 5
) else (
    call ui_io.cmd :printMessage "You encounter an unknown trap. It does not do anything."
)
exit /b 

::------------------------------------------------------------------------------
:: Move the player randomly
::
:: Arguments: %1 - The direction to move the player in
:: Returns:   0 if the player is confused and a 1d4 rolled a 2 or higher
::            1 if the player is sitting or not confused, or if a 1d4 rolled a 1
::------------------------------------------------------------------------------
:playerRandomMovement
:: Player is standing still or sitting
if "%~1"=="5" exit /b 1

set "player_random_move=false"
set "player_is_confused=false"

:: 75% chance of random movement
call rng.cmd :randomNumber 4
if !errorlevel! GTR 1 set "player_random_move=true"
if %py.flags.confused% GTR 0 set "player_is_confused=true"

if "%player_is_confused%"=="true" (
    if "%player_random_move%"=="true" (
        exit /b 0
    )
)
exit /b 1

::------------------------------------------------------------------------------
:: Do something based on the TVAL of the object that the player is standing on
::
:: Arguments: %1 - The coordinates of the player
::            %2 - Determines whether or not the player picks something up
:: Returns:   None
::------------------------------------------------------------------------------
:carry
set "coord=%~1"
set "pickup=1"
if "%~2"=="true" set "pickup=0"

for /f "tokens=1,2 delims=;" %%A in ("%coord%") do (
    set "t_id=!dg.floor[%%A][%%B].treasure_id!"
)
set "item=game.treasure.list[%t_id%]"
set "tile_flags=!%item%.category_id!"

if %tile_flags% GTR %TV_MAX_PICK_UP% (
    if not "%tile_flags%"=="%TV_INVIS_TRAP%" (
        if not "%tile_flags%"=="%TV_VIS_TRAP%" (
            if not "%tile_flags%"=="%TV_STORE_DOOR%" (
                exit /b
            )
        )
    )
    call :playerStepsOnTrap "%coord%"
    exit /b
)

call player_run.cmd :playerEndRunning

if "%tile_flags%"=="%TV_GOLD%" (
    set /a py.misc.au+=!%item%.cost!

    call identification.cmd :itemDescription "description" "%item%" "true"
    call ui.cmd :printCharacterGoldValue
    call dungeon.cmd :dungeonDeleteObject "coord"
    call ui_io.cmd :printMessage "You have found !%item%.cost! gold pieces worth of !description!"
    exit /b
)

call inventory.cmd :inventoryCanCarryItemCount "%item%"
if "!errorlevel!"=="0" (
    if "!pickup!"=="0" (
        if "%config.options.prompt_to_pickup%"=="true" (
            call identification.cmd :itemDescription "description" "%item%" "true"
            set "description=!description:~0,-1!?"
            call ui_io.cmd :getInputConfirmation "Pick up !description!"
            set "pickup=!errorlevel!"
        )
    )

    if "!pickup!"=="0" (
        call inventory.cmd :inventoryCanCarryItem "%item%"
        if "!errorlevel!"=="1" (
            call identification.cmd :itemDescription "description" "%item%" "true"
            set "description=!description:~0,-1!?"
            call ui_io.cmd :getInputConfirmation "Exceed your weight limit to pick up !description!"
            set "pickup=!errorlevel!"
        )
    )

    if "!pickup!"=="0" (
        call inventory.cmd :inventoryCarryItem "%item%"
        set "locn=!errorlevel!"

        for /f "delims=" %%A in ("!locn!") do (
            call identification.cmd :itemDescription "description" "!py.inventory[%%A]!" "true"
            set /a eca=65+%%A
            cmd /c exit /b !eca!
            call ui_io.cmd :printMessage "You have !description! (!=ExitCodeAscii!)"
            call dungeon.cmd :dungeonDeleteObject "coord"
        )
    )
) else (
    call identification.cmd :itemDescription "description" "%item%" "true"
    call ui_io.cmd :printMessage "You can't carry !description!"
)
exit /b 

::------------------------------------------------------------------------------
:: Moves the player from one space to another
::
:: Arguments: %1 - The direction in which to move
::            %2 - Whether or not the player picks anything up
:: Returns:   None
::------------------------------------------------------------------------------
:playerMove
set "direction=%~1"
call :playerRandomMovement "%direction%"
if "!errorlevel!"=="0" (
    call rnd.cmd :randomNumber 9
    set "direction=!errorlevel!"
    call player_run.cmd :playerEndRunning
)

set "coord.y=%py.pos.y%"
set "coord.x=%py.pos.x%"
set "coord=%coord.y%;%coord.x%"

call player.cmd :playerMovePosition "%direction%" "coord" || exit /b

set "tile=dg.floor[%coord.y%][%coord.x%]"
set "c_id=!%tile%.creature_id!"
set "monster=monsters[%c_id%]"

set "should_attack=0"
if !%tile%.creature_id! LSS 2 set "should_attack=1"
if "!%monster%.lit!"=="false" (
    if !%tile%.feature_id! GEQ %MIN_CLOSED_SPACE% (
        set "should_attack=1"
    )
)

if "!should_attack!"=="1" (
    if !%tile%.feature_id! LEQ %MAX_OPEN_SPACE% (
        REM TODO: Turn this into a helpers.cmd subroutine
        set "old_coord.y=%py.pos.y%"
        set "old_coord.x=%py.pos.x%"
        set "old_coord=!old_coord.y!;!old_coord.x!"

        set "py.pos.y=!coord.y!"
        set "py.pos.x=!coord.x!"
        set "py.pos=!coord.y!;!coord.x!"

        call dungeon.cmd :dungeonMoveCreatureRecord "old_coord" "py.pos"
        
        REM Check for a new panel
        call ui.cmd :coordOutsidePanel "!py.pos!" "false"
        if "!errorlevel!"=="0" call ui.cmd :drawDungeonPanel

        REM Check to see if the player should stop running
        if not "!py.running_tracker!"=="0" (
            call player_run.cmd :playerAreaAffect "!direction!" "!py.pos!"
        )

        REM Check to see if the player noticed something
        set "noticed_something=0"
        if !py.misc.fos! LEQ 1 set "noticed_something=1"
        call rng.cmd :randomNumber "!py.misc.fos!"
        if "!errorlevel!"=="1" set "noticed_something=1"
        set /a "in_search_mode=%py.flags.status% & %config.player.status.py_search%"
        if not "!in_search_mode!"=="0" set "noticed_something=1"
        if "!noticed_something!"=="1" (
            call player.cmd :playerSearch "!py.pos!" "!py.misc.chance_in_search!"
        )

        REM Light up the room if necessary
        if "!%tile%.feature_id!"=="%TILE_LIGHT_FLOOR%" (
            if "!%tile%.permanent_light!"=="true" (
                if "%py.flags.blind%"=="0" (
                    call dungeon.cmd :dungeonLightRoom "py.pos"
                )
            )
        ) else (
            if "!%tile%.perma_lit_room!"=="true" (
                if %py.flags.blind% LSS 1 (
                    call helpers.cmd :expandCoordName "py.pos"

                    for /L %%Y in (!py.pos.y_dec!,1,!py.pos.y_inc!) do (
                        for /L %%X in (!py.pos.x_dec!,1,!py.pos.x_inc!) do (
                            if "!dg.floor[%%Y][%%X].feature_id!"=="%TILE_LIGHT_FLOOR%" (
                                if "!dg.floor[%%Y][%%X].permanent_light!"=="true" (
                                    set "tmp_coord=%%Y;%%X"
                                    call dungeon.cmd :dungeonLightRoom "tmp_coord"
                                )
                            )
                        )
                    )
                )
            )
        )

        call :dungeon.cmd dungeonMoveCharacterLight "old_coord" "py.pos"

        if not "!%tile%.treasure_id!"=="0" (
            call :carry "!py.pos!" "%~2"

            for /f "delims=" %%A in ("!%tile%.treasure_id!") do (
                set "c_id=!game.treasure.list[%%A].category_id!"
            )
            if "!c_id!"=="%TV_RUBBLE%" (
                call dungeon.cmd :dungeonMoveCreatureRecord "py.pos" "old_coord"
                call dungeon.cmd :dungeonMoveCharacterLight "py.pos" "old_coord"

                set "py.pos.y=!old.coord.y!"
                set "py.pos.x=!old.coord.x!"

                for /f "tokens=1,2" %%X in ("!py.pos.x! !py.pos.y!") do (
                    set "id=!dg.floor[%%Y][%%X].treasure_id!"
                )
                if not "!id!"=="0" (
                    for /f "delims=" %%A in ("!id!") do set "val=!game.treasure.list[%%A].category_id!"

                    set "is_on_trap=0"
                    if "!val!"=="%TV_INVIS_TRAP%" set "is_on_trap=1"
                    if "!val!"=="%TV_VIS_TRAP%"   set "is_on_trap=1"
                    if "!val!"=="%TV_STORE_DOOR%" set "is_on_trap=1"
                    if "!is_on_trap!"=="1" call :playerStepsOnTrap "!py.pos!"
                )
            )
        )
    ) else (
        for /f "delims=" %%A in ("!%tile%.treasure_id!") do set "gtlc_id=!game.treasure.list[%%A].category_id!"
        REM Can't move onto floor space
        if "!py.running_tracker!"=="0" (
            if not "!%tile%.treasure_id!"=="0" (
                if "!gtlc_id!"=="%TV_RUBBLE%" (
                    call ui_io.cmd :printMessage "There is rubble blocking your way."
                ) else (
                    call ui_io.cmd :printMessage "There is a closed door blocking your way."
                )
            ) else (
                call player_run.cmd :playerEndRunning
            )
        ) else (
            call player_run.cmd :playerEndRunning
        )
        set "game.player_free_turn=true"
    )
) else (
    REM Attacking a creature
    set "old_find_flag=!py.running_tracker!"

    call player_run.cmd :playerEndRunning

    set "do_nothing=0"
    if "!%monster%.lit!"=="true"  set "do_nothing=1"
    if not "!old_find_flag!"=="0" set "do_nothing=1"
    if "!do_nothing!"=="1" (
        set "game.player_free_turn=true"
    ) else (
        call player.cmd :playerAttackPosition "!coord!"
    )
)
exit /b 
