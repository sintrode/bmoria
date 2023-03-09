@echo off
:: Weird hack needed because of how :compactMonsters is called
set "hack_monptr=-1"
call %*
exit /b

::------------------------------------------------------------------------------
:: Determine if the monster is visible
::
:: Arguments: %1 - A reference to the monster
:: Returns:   0 if the monster can be seen
::            1 if the monster is invisible
::------------------------------------------------------------------------------
:monsterIsVisible
set "visible=1"
set "monster.pos.y=!%~1.pos.y!"
set "monster.pos.x=!%~1.pos.x!"
set "monster.creature_id=!%~1.creature_id!"

set "tile=dg.floor[%monster.pos.y%][%monster.pos.x%]"
set "creature=creatures_list[%monster.creature_id%]"

set "normal_sight=0"
if "!%tile%.permanent_light!"=="true" set "normal_sight=1"
if "!%tile%.temporary_light!"=="true" set "normal_sight=1"
if not "%py.running_tracker%"=="0" (
    if !%~1.distance_from_player! LSS 2 (
        if "%py.carrying_light%"=="true" (
            set "normal_sight=1"
        )
    )
)

set "infra_vision=0"
if %py.flags.see_infra% GTR 0 (
    if !%~1.distance_from_player! LEQ %py.flags.see_infra% (
        set /a "infra_defense=!%~1.defenses! & %config.monsters.defense.cd_infra%"
        if not "!infra_defense!"=="0" (
            set "infra_vision=1"
        )
    )
)

if "!normal_sight!"=="1" (
    set /a "moves_invisibly=!%~1.movement! & %config.monsters.move.cm_invisible%"
    if "!moves_invisibly!"=="0" (
        set "visible=0"
    ) else if "%py.flags.see_invisible%"=="true" (
        set "visible=0"
        set /a "creature_recall[!%~1.creature_id!].movement|=%config.monsters.move.cm_invisible%"
    )
) else if "!infra_vision!"=="1" (
    set "visible=0"
    set /a "creature_recall[!%~1.creature_id!].defenses|=%config.monsters.move.cd_infra%"
)

set "normal_sight="
set "infra_vision="
exit /b !visible!

::------------------------------------------------------------------------------
:: Update the screen when the monsters move about
::
:: Arguments: %1 - The ID of the monster that is moving
:: Returns:   None
::------------------------------------------------------------------------------
:monsterUpdateVisibility
set "visible=1"
set "monster=monsters[%~1]"

if !%monster%.distance_from_player! LEQ %config.monsters.mon_max_sight% (
    set /a "is_blind=%py.flags.status% & %config.player.status.py.blind%"
    if "!is_blind!"=="0" (
        call ui.cmd :coordInsidePanel "!%~1.pos.y!;!%~1.pos.x!"
        if "!errorlevel!"=="0" (
            if "%game.wizard_mode%"=="true" (
                set "visible=0"
            ) else (
                call dungeon_los.cmd :los "%py.pos.y%;%py.pos.x%" "!%~1.pos.y!;!%~1.pos.x!"
                if "!errorlevel!"=="0" (
                    call :monsterIsVisible "%~1"
                    set "visible=!errorlevel!"
                )
            )
        )
    )
)

set "coord=!%~1.pos.y!;!%~1.pos.x!"
if "!visible!"=="0" (
    if "!%~1.lit!"=="false" (
        call player.cmd :playerDisturb 1 0
        set "%~1.lit=true"
        call dungeon.cmd :dungeonLiteSpot "coord"
        set "screen_has_changed=true"
    )
) else if "!%~1.lit!"=="true" (
    set "%~1.lit=false"
    call dungeon.cmd :dungeonLiteSpot "coord"
    set "screen_has_changed=true"
)
exit /b

::------------------------------------------------------------------------------
:: Determine the number of moves that the monster is allowed to make this turn
::
:: Arguments: %1 - The monster's speed
:: Returns:   The number of moves this turn
::------------------------------------------------------------------------------
:monsterMovementRate
if %~1 GTR 0 (
    if not "%py.flags.rest%"=="0" (
        exit /b 1
    )
    exit /b %~1
)

:: Speed must be negative here
set "rate=0"
set /a turn_speed=%dg.game_turn% %% (2 - %~1)
if "%turn_speed%"=="0" set "rate=1"
set "turn_speed="
exit /b %rate%

::------------------------------------------------------------------------------
:: Makes sure a new creature gets lit properly
::
:: Arguments: %1 - The coordinates of the new monster
:: Returns:   0 if the new monster is lit
::            1 if the new monster is either not visible or not present
::------------------------------------------------------------------------------
:monsterMakeVisible
for /f "tokens=1,2 delims=;" %%A in ("%~1") do (
    set "monster_id=!dg.floor[%%~A][%%~B].creature_id!"
)
if !monster_id! LEQ 1 exit /b 1
call :monsterUpdateVisibility !monster_id!
if "!monsters[%monster_id%].lit!"=="true" exit /b 0
exit /b 1

::------------------------------------------------------------------------------
:: Choose the correct directions for monster movement
::
:: Arguments: %1 - The ID of the monster that is moving
::            %2 - An array of possible directions
:: Returns:   None
::------------------------------------------------------------------------------
:monsterGetMoveDirection
set /a y=!monsters[%~1].pos.y!-%py.pos.y%
set /a x=!monsters[%~1].pos.x!-%py.pos.x%

if %y% LSS 0 (
    set "movement=8"
    set /a ay=-%y%
) else (
    set "movement=0"
    set "ay=%y%"
)
if %x% GTR 0 (
    set /a movement+=4
    set "ax=4"
) else (
    set /a ax=-%x%
)

set /a "shift_x=ax << 1", "shift_y=ay << 1"
if %ay% GTR %shift_x% (
    set /a movement+=2
) else if %ax% GTR %shift_y% (
    set /a movement+=1
)

goto :monsterGetMoveDirection_%movement%

:: TODO: refactor fake switch into subroutine that takes expression
::       and direction values as arguments
:monsterGetMoveDirection_0
set "%~2[0]=0"
if %ay% GTR %ax% (
    set "%~2[1]=8"
    set "%~2[2]=6"
    set "%~2[3]=7"
    set "%~2[4]=3"
) else (
    set "%~2[1]=6"
    set "%~2[2]=8"
    set "%~2[3]=3"
    set "%~2[4]=7"
)
exit /b

:monsterGetMoveDirection_1
:monsterGetMoveDirection_9
set "%~2[0]=6"
if %y% LSS 0 (
    set "%~2[1]=3"
    set "%~2[2]=9"
    set "%~2[3]=2"
    set "%~2[4]=8"
) else (
    set "%~2[1]=9"
    set "%~2[2]=3"
    set "%~2[3]=8"
    set "%~2[4]=2"
)
exit /b

:monsterGetMoveDirection_2
:monsterGetMoveDirection_6
set "%~2[0]=8"
if %x% LSS 0 (
    set "%~2[1]=9"
    set "%~2[2]=7"
    set "%~2[3]=6"
    set "%~2[4]=4"
) else (
    set "%~2[1]=7"
    set "%~2[2]=9"
    set "%~2[3]=4"
    set "%~2[4]=6"
)
exit /b

:monsterGetMoveDirection_4
set "%~2[0]=7"
if %ay% GTR %ax% (
    set "%~2[1]=8"
    set "%~2[2]=4"
    set "%~2[3]=9"
    set "%~2[4]=1"
) else (
    set "%~2[1]=4"
    set "%~2[2]=8"
    set "%~2[3]=1"
    set "%~2[4]=9"
)
exit /b

:monsterGetMoveDirection_5
:monsterGetMoveDirection_13
set "directions[0]=4"
if %y% LSS 0 (
    set "%~2[1]=1"
    set "%~2[2]=7"
    set "%~2[3]=2"
    set "%~2[4]=8"
) else (
    set "%~2[1]=7"
    set "%~2[2]=1"
    set "%~2[3]=8"
    set "%~2[4]=2"
)
exit /b

:monsterGetMoveDirection_8
set "%~2[0]=3"
if %ay% GTR %ax% (
    set "%~2[1]=2"
    set "%~2[2]=6"
    set "%~2[3]=1"
    set "%~2[4]=9"
) else (
    set "%~2[1]=6"
    set "%~2[2]=2"
    set "%~2[3]=9"
    set "%~2[4]=1"
)
exit /b

:monsterGetMoveDirection_10
:monsterGetMoveDirection_14
set "%~2[0]=2"
if %x% LSS 0 (
    set "%~2[1]=3"
    set "%~2[2]=1"
    set "%~2[3]=6"
    set "%~2[4]=4"
) else (
    set "%~2[1]=1"
    set "%~2[2]=3"
    set "%~2[3]=4"
    set "%~2[4]=6"
)
exit /b

:monsterGetMoveDirection_12
set "%~2[0]=1"
if %ay% GTR %ax% (
    set "%~2[1]=2"
    set "%~2[2]=4"
    set "%~2[3]=3"
    set "%~2[4]=7"
) else (
    set "%~2[1]=4"
    set "%~2[2]=2"
    set "%~2[3]=7"
    set "%~2[4]=3"
)
exit /b

::------------------------------------------------------------------------------
:: Prints a string describing how the monster attacks
::
:: Arguments: %1 - The name of the monster
::            %2 - The ID of the attack performed by the monster
:: Returns:   None
::------------------------------------------------------------------------------
:monsterPrintAttackDescription
:: TODO: Convert this to an array
if "%~2"=="1" (
    call ui_io.cmd :printMessage "%~1hits you."
) else if "%~2"=="2" (
    call ui_io.cmd :printMessage "%~1bites you."
) else if "%~2"=="3" (
    call ui_io.cmd :printMessage "%~1claws you."
) else if "%~2"=="4" (
    call ui_io.cmd :printMessage "%~1stings you."
) else if "%~2"=="5" (
    call ui_io.cmd :printMessage "%~1touches you."
) else if "%~2"=="6" (
    call ui_io.cmd :printMessage "%~1kicks you."
) else if "%~2"=="7" (
    call ui_io.cmd :printMessage "%~1gazes at you."
) else if "%~2"=="8" (
    call ui_io.cmd :printMessage "%~1breathes on you."
) else if "%~2"=="9" (
    call ui_io.cmd :printMessage "%~1spits on you."
) else if "%~2"=="10" (
    call ui_io.cmd :printMessage "%~1makes a horrible wail."
) else if "%~2"=="11" (
    call ui_io.cmd :printMessage "%~1embraces you."
) else if "%~2"=="12" (
    call ui_io.cmd :printMessage "%~1crawls on you."
) else if "%~2"=="13" (
    call ui_io.cmd :printMessage "%~1releases a cloud of spores."
) else if "%~2"=="14" (
    call ui_io.cmd :printMessage "%~1begs you for money."
) else if "%~2"=="15" (
    call ui_io.cmd :printMessage "You've been slimed^^!"
) else if "%~2"=="16" (
    call ui_io.cmd :printMessage "%~1crushes you."
) else if "%~2"=="17" (
    call ui_io.cmd :printMessage "%~1tramples you."
) else if "%~2"=="18" (
    call ui_io.cmd :printMessage "%~1drools on you."
) else if "%~2"=="19" (
    call rng.cmd :randomNumber 9
    if "!errorlevel!"=="1" (
        call ui_io.cmd :printMessage "%~1insults you."
    ) else if "!errorlevel!"=="2" (
        call ui_io.cmd :printMessage "%~1insults your mother."
    ) else if "!errorlevel!"=="3" (
        call ui_io.cmd :printMessage "%~1gives you the finger."
    ) else if "!errorlevel!"=="4" (
        call ui_io.cmd :printMessage "%~1humiliates you."
    ) else if "!errorlevel!"=="5" (
        call ui_io.cmd :printMessage "%~1wets on your leg."
    ) else if "!errorlevel!"=="6" (
        call ui_io.cmd :printMessage "%~1spits at your feet."
    ) else if "!errorlevel!"=="7" (
        call ui_io.cmd :printMessage "%~1dances around you."
    ) else if "!errorlevel!"=="8" (
        call ui_io.cmd :printMessage "%~1makes obscene gestures."
    ) else if "!errorlevel!"=="9" (
        call ui_io.cmd :printMessage "%~1moons you^^!"
    )
) else if "%~2"=="99" (
    call ui_io.cmd :printMessage "%~1is repelled."
)
exit /b

::------------------------------------------------------------------------------
:: Confuses a monster if applicable
::
:: Arguments: %1 - A reference to the monster's creatures_list[] data
::            %2 - A reference to the monster's monsters[] data
::            %3 - The attack type used against the monster
::            %4 - An extended version of the creature's name
::            %5 - Indicates if the creatures is currently visible
:: Returns:   None
::------------------------------------------------------------------------------
:monsterConfuseOnAttack
if "%py.flags.confuse_monster%"=="true" (
    if not "%~3"=="99" (
        call ui_io.cmd :printMessage "Your hands stop glowing."
        set "py.flags.confuse_monster=false"

        call rng.cmd :randomNumber %mon_max_levels%
        set "is_affected=0"
        if !errorlevel! LSS !%~1.level! set "is_affected=1"
        set /a "is_sleepless=!%~1.defenses! & %config.monsters.defense.cd_no_sleep%"
        if not "!is_sleepless!"=="0" set "is_affected=1"

        if "!is_sleepless!"=="1" (
            set "msg=%~4is unaffected."
        ) else (
            set "msg=%~4appears confused."
            if not "!%~2.confused_amount!"=="0" (
                set /a %~2.confused_amount+=3
            ) else (
                call rng.cmd :randomNumber 16
                set /a %~2.confused_amount=!errorlevel!+2
            )
        )
        call ui_io.cmd :printMessage "!msg!"

        if "%~5"=="true" (
            if "%game.character_is_dead%"=="false" (
                call rng.cmd :randomNumber 4
                if "!errorlevel!"=="1" (
                    set /a "creature_recall[!%~2.creature_id!].defenses|=!%~1.defenses! & %config.monsters.defense.cd_no_sleep%"
                )
            )
        )
    )
)
exit /b

::------------------------------------------------------------------------------
:: Have the monster attack the player
::
:: Arguments: %1 - The ID of the monster performing the attack
:: Returns:   None
::------------------------------------------------------------------------------
:monsterAttackPlayer
if "%game.character_is_dead%"=="true" exit /b

set "monster=monsters[%~1]"
set "creature_id=!%monster%.creature_id!"
set "creature=creatures_list[%creature_id%]"

if "!%monster%.lit!"=="false" (
    set "name=It "
) else (
    set "name=The !%creature%.name! "
)

call player.cmd :playerDiedFromString "death_description" "!%creature%.name!" "!%creature%.movement!"

set "attack_counter=0"
for /L %%A in (0,1,3) do (
    if "!%creature%.damage[%%~A]!"=="0" exit /b
    if "%game.character_is_dead%"=="true" exit /b

    for /f "delims=" %%B in ("!%creature%.damage[%%~A]!") do (
        set "attack_type=!monster_attacks[%%~B].type_id!"
        set "attack_desc=!monster_attacks[%%~B].description_id!"
        set "dice.dice=!monster_attacks[%%~B].dice.dice!"
        set "dice.sides=!monster_attacks[%%~B].dice.sides!"
    )

    if %py.flags.protect_evil% GTR 0 (
        set /a "is_evil=!%creature%.defenses! & %config.monsters.defense.cd_evil%"
        if not "!is_evil!"=="0" (
            set /a level_inc=%py.misc.level%+1
            if !level_inc! GTR !%creature%.level! (
                if "!%monster%.lit!"=="true" (
                    set /a "creature_recall[!%monster%.creature_id!].defenses|=%config.monsters.defense.cd_evil%"
                )
                set "attack_type=99"
                set "attack_desc=99"
            )
        )
    )

    call player.cmd :playerTestAttackHits "!attack_type!" "!%creature%.level!"
    if "!errorlevel!"=="0" (
        call player.cmd :playerDisturb 1 0

        set "description=!name!"
        call :monsterPrintAttackDescription "!description!" "!attack_desc!"

        set "notice=true"
        set "visible=true"
        if "!%monster%.lit!"=="false" (
            set "notice=false"
            set "visible=false"
        )

        call dice.cmd :diceRoll !dice!
        set "damage=!errorlevel!"
        call :executeAttackOnPlayer "!%creature%.level!" "!%monster%.hp!" "%~1" "!attack_type!" "!damage!" "!death_description!" "notice"
        set "notice=!errorlevel!"

        call :monsterConfuseOnAttack "%creature%" "%monster%" "!attack_desc!" "!name!" "!visible!"

        REM TODO: Refactor
        for /f "tokens=1,2" %%B in ("!%monster%.creature_id! !attack_counter!") do (
            set "c_attack=!creature_recall[%%~B].attacks[%%~C]!"
        
        )
        set "attack_inc=0"
        if !c_attack! LSS 32767 (
            if "!notice!"=="0" set "attack_inc=1"
            if "!visible!"=="true" (
                if not "!c_attack!"=="0" (
                    if not "!attack_type!"=="99" (
                        set "attack_inc=1"
                    )
                )
            )
        )
        if "!attack_inc!"=="1" (
            set /a creature_recall[!%monster%.creature_id!].attacks[!attack_counter!]+=1
        )

        if "%game.character_is_dead%"=="true" (
            for /f "delims=" %%B in ("!%monster%.creature_id!") do (
                if !creature_recall[%%~B].deaths! LSS 32767 (
                    set /a creature_recall[!%monster%.creature_id!].deaths+=1
                )
            )
        )
    ) else (
        set "attack_missed=0"
        if !attack_desc! GEQ 1 if !attack_desc! LEQ 3 set "attack_missed=1"
        if "!attack_desc!"=="6" set "attack_missed=1"
        if "!attack_missed!"=="1" (
            call player.cmd :playerDisturb 1 0
            call ui_io.cmd :printMessage "!name!misses you."
        )
    )

    set /a max_dec=%mon_max_attacks%-1
    if !attack_counter! LSS !max_dec! (
        set /a attack_counter+=1
    ) else (
        exit /b
    )
)
exit /b

::------------------------------------------------------------------------------
:: Lets the monster open a door and possibly go through it
::
:: Arguments: %1 - A reference to the tile that contains the monster
::            %2 - The monster's HP
::            %3 - The monster's set of movement flags
::            %4 - A variable that stores whether the monster turns or not
::            %5 - A variable that stores whether the monster moves or not
::            %6 - A reference to the monster's movement history for recall
::            %7 - The coordinates of the monster
:: Returns:   None
::------------------------------------------------------------------------------
:monsterOpenDoor
set "t_id=!%~1.treasure_id!"
set "item=game.treasure.list[%t_id%]"

set /a "can_open_doors=%~3 & %config.monsters.move.cm_open_door%"
if not "!can_open_doors!"=="0" (
    set "door_is_stuck=false"
    if "!%item%.category_id!"=="%TV_CLOSED_DOOR%" (
        set "%~4=true"

        set /a "rnd_misc_left=(%~2+1)*(50-!%item%.misc_use!)"
        set /a "rnd_misc_right=%~2-10-!%item%.misc_use!"
        if "!%item%.misc_use!"=="0" (
            REM Closed doors
            set "%~5=true"
        ) else if !%item%.misc_use! GTR 0 (
            REM Locked doors
            call rng.cmd :randomNumber !rnd_misc_left!
            if !errorlevel! LSS !rnd_misc_right! (
                set "%item%.misc_use=0"
            )
        ) else if !%item%.misc_use! LSS 0 (
            REM Stuck doors
            call rng.cmd :randomNumber !rnd_misc_left!
            if !errorlevel! LSS !rnd_misc_right! (
                call ui_io.cmd :printMessage "You hear a door burst open."
                call player.cmd :playerDisturb 1 0
                set "door_is_stuck=true"
                set "%~5=true"
            )
        )
    ) else if "!%item%.category_id!"=="%TV_SECRET_DOOR%" (
        set "%~4=true"
        set "%~5=true"
    )

    if "!%~5!"=="true" (
        REM KNOCK KNOCK OPEN UP THE DOOR IT'S REAL
        call inventory.cmd :inventoryItemCopyTo "%config.dungeon.objects.obj_open_door%" "%item%"
        if "!door_is_stuck!"=="true" (
            call rng.cmd :randomNumber 2
            set /a %item%.misc_use=1-!errorlevel!
        )
        set "!%~1.feature_id!=%TILE_CORR_FLOOR%"
        set "coord=%~7"
        call dungeon.cmd :dungeonLiteSpot "coord"
        call ui_io.cmd :printMessage "You hear a door burst open."
        call player.cmd :playerDisturb 1 0
    )
)
exit /b

::------------------------------------------------------------------------------
:: Check to see if a Glyph of Warding Protection was broken, which destroys any
:: monster that crosses through its threshold
::
:: Arguments: %1 - The ID of the creature that is approaching the glyph
::            %2 - The creature's movement flags
::            %3 - A variable that stores whether the creature moves
::            %4 - A variable that stores whether the creature turns
::            %5 - The coordinates of the creature
:: Returns:   None
::------------------------------------------------------------------------------
:glyphOfWardingProtection
call rng.cmd :randomNumber %config.treasure.objects_rune_protection%
if !errorlevel! LSS !creatures_list[%~1].level! (
    for /f "tokens=1,2 tokens=;" %%A in ("%~5") do (
        if "%%~A"=="%py.pos.y%" (
            if "%%~B"=="%py.pos.x%" (
                call ui_io.cmd :printMessage "The rune of protection is broken^^!"
            )
        )
    )
    set "coord=%~5"
    call dungeon.cmd :dungeonDeleteObject "coord"
    exit /b
)

set "%~3=false"

set /a "is_attack_only=%~2 & %config.monsters.move.cm_attack_only%"
if not "!is_attack_only!"=="0" (
    set "%~4=true"
)
exit /b

::------------------------------------------------------------------------------
:: Code for the monster moving towards the player and interacting with things
:: along its path
::
:: NOTE: This is too many arguments imo
::
:: Arguments: %1 - A reference to the monster that is moving
::            %2 - The creature_id of the monster being moved onto
::            %3 - The monster_id of the monster
::            %4 - The monster's movement flags
::            %5 - A variable that stores whether the creature moves
::            %6 - A variable that stores whether the creature turns
::            %7 - A reference to the monster's movement recall data
::            %8 - The monster's coordinates
:: Returns:   None
::------------------------------------------------------------------------------
:monsterMovesOnPlayer
set "source_id=!%~1.creature_id!"
set "target_id=!monsters[%~2].creature_id!"
if "%~3"=="1" (
    if "!%~1.lit!"=="false" call :monsterUpdateVisibility %~3
    call :monsterAttackPlayer %~3
    set "%~5=false"
    set "%~4=true"
) else (
    if %~3 GTR 1 (
        set "is_misaligned=0"
        for /f "tokens=1,2 delims=;" %%A in ("%~8") do (
            if not "%%~A"=="!%~1.pos.y!" set "is_misaligned=1"
            if not "%%~B"=="!%~1.pos.x!" set "is_misaligned=1"
        )
        if "!is_misaligned!"=="1" (
            set /a "eats_monsters=%~4 & %config.monsters.move.cm_eats_others%"
            if not "!eats_monsters!"=="0" (
                if !creatures_list[%source_id%].kill_exp_value! GEQ !creatures_list[%target_id%].kill_exp_value! (
                    if "!monsters[%~2].lit!"="true" (
                        set /a "%~7|=%config.monsters.move.cm_eats_others%"
                    )

                    if %~3 LSS %~2 (
                        call dungeon.cmd :dungeonDeleteMonster %~2
                    ) else (
                        call dungeon.cmd :dungeonRemoveMonsterFromLevel %~2
                    )
                )
            ) else (
                set "%~5=false"
            )
        )
    )
)
exit /b

::------------------------------------------------------------------------------
:: Checks that the monster is allowed to move
::
:: Arguments: %1 - A reference the monster that is trying to move
::            %2 - The movement flags of the monster that is moving
::            %3 - A variable that stores whether or not the monster turns
::            %4 - A reference to the monster's movement recall data
::            %5 - The coordinates of the monster
:: Returns:   None
::------------------------------------------------------------------------------
:monsterAllowedToMove
set "coord=%~5"
set /a "can_pick_up=%~2 & %config.monsters.move.cm_picks_up%"
if not "%can_pick_up%"=="0" (
    for /f "tokens=1,2 delims=;" %%A in ("%~5") do (
        set "treasure_id=!dg.floor[%%~A][%%~B].treasure_id!"
    )

    for /f "delims=" %%A in ("!treasure_id!") do (
        if not "%%~A"=="0" (
            if !game.treasure.list[%%~A].category_id! LEQ %TV_MAX_OBJECT% (
                set /a "%~4|=%config.monsters.move.cm_picks_up%"
                call dungeon.cmd :dungeonDeleteObject "coord"
            )
        )
    )
)

set "from_coord=!%~1.pos.y!;!%~1.pos.x!"
call dungeon.cmd :dungeonMoveCreatureRecord "from_coord" "coord"

if "!%~1.lit!"=="true" (
    set "%~1.lit=false"
    call dungeon.cmd :dungeonLiteSpot "from_coord"
)

for /f "tokens=1,2 delims=;" %%A in ("!coord!") do (
    set "%~1.pos.y=%%~A"
    set "%~1.pos.x=%%~B"
)
call dungeon.cmd :coordDistanceBetween "py.pos" "coord"
set "%~1.distance_from_player=!errorlevel!"
set "%~3=true"
exit /b

::------------------------------------------------------------------------------
:: Makes the monster move if possible
::
:: Arguments: %1 - The ID of the monster that is moving
::            %2 - an array of directions that the monster can move in
::            %3 - a reference to the monster's recalled movement
:: Returns:   None
::------------------------------------------------------------------------------
:makeMove
set "do_turn=false"
set "do_move=false"

set "monster=monsters[%~1]"
set "c_id=!%monster%.creature_id!"
set "move_bits=!creatures_list[%c_id%].movement!"

set "starter=0"
set "continue=set /a starter+=1&goto :makeMoveForLoop"
:makeMoveForLoop
for /L %%A in (!starter!,1,4) do (
    set "starter=%%A"
    if "!do_turn!"=="true" exit /b

    set "coord.y=!%monster%.pos.y!"
    set "coord.x=!%monster%.pos.x!"
    set "coord=!coord.y!;!coord.x!"

    call player.cmd :playerMovePosition "!%~2[%%A]!" "coord"
    for /f "tokens=1,2" %%X in ("!coord.x! !coord.y!") do set "tile=dg.floor[%%~Y][%%~X]"
    if "!%tile%.feature_id!"=="%TILE_BOUNDARY_WALL%" %continue%

    set /a "move_through_walls=%~2 & %config.monsters.move.cm_phase%"
    if !%tile%.feature_id! LEQ %MAX_OPEN_SPACE% (
        REM The floor is open
        set "do_move=true"
    ) else if not "!move_through_walls!"=="0" (
        REM The creature moves through walls
        set "do_move=true"
        set /a "%~3|=%config.monsters.move.cm_phase%"
    ) else if not "!%tile%.treasure_id!"=="0" (
        REM The creature can open doors. Clever girl.
        call :monsterOpenDoor "%tile%" "!%monster%.hp!" "%~2" "do_turn" "do_move" "%~3" "!coord!"
    )

    REM A Glyph of warding is present
    for /f "delims=" %%B in ("!%tile%.treasure_id!") do (
        if "!do_move!"=="true" (
            if not "%%~B"=="0" (
                if "!game.treasure.list[%%~B].category_id!"=="%TV_VIS_TRAP%" (
                    if "!game.treasure.list[%%~B].sub_category_id!"=="99" (
                        call :glyphOfWardingProtection "!%monster%.creature_id!" "%~2" "do_move" "do_turn" "!coord!"
                    )
                )
            )
        )
    )

    REM Determine if the creature has attempted to move towards the player
    if "!do_move!"=="true" (
        call :monsterMovesOnPlayer "%monster%" "!%tile%.creature_id!" "%~1" "%~2" "do_move" "do_turn" "%~3" "!coord!"
    )

    REM There's a separate !do_move! check here in case :monsterMovesOnPlayer changes its value
    if "!do_move!"=="true" (
        call :monsterAllowedToMove "%monster%" "%~2" "do_turn" "%~3" "!coord!"
    )
)
exit /b

::------------------------------------------------------------------------------
:: Some monsters have a 1 in x chance of casting a spell
::
:: Arguments: %1 - A reference to the monster that is casting the spell
::            %2 - A bit flag of the creature's spells
:: Returns:   0 if the monster successfully cast a spell
::            1 if the monster is out of range, is obstructed, or could not get
::              the spell off
::------------------------------------------------------------------------------
:monsterCanCastSpells
set /a "can_cast_spell=%~2 & %config.monsters.spells.cs_freq%"
call rng.cmd :randomNumber %can_cast_spell%
if not "!errorlevel!"=="1" exit /b 1
set "can_cast_spell="

set "within_range=false"
set "unobstructed=false"

if !%~1.distance_from_player! LEQ %config.monsters.mon_max_spell_cast_distance% set "within_range=true"
call dungeon_los.cmd :los "%py.pos.y%;%py.pos.x%" "!%~1.pos.y!;!%~1.pos.x!" &&  set "unobstructed=true"

if "!within_range!"=="true" (
    if "!unobstructed!"=="true" (
        exit /b 0
    )
)
exit /b 1

::------------------------------------------------------------------------------
:: Performs the actual casting of the monster's spell
::
:: Arguments: %1 - A reference to the monster that is casting the spell
::            %2 - The ID of the monster that is casting the spell
::            %3 - The ID of the spell that is being cast
::            %4 - The level of the monster that is casting the spell
::            %5 - The name of the monster that is casting the spell
::            %6 - A description of the player's death
:: Returns:   None
::------------------------------------------------------------------------------
:monsterExecuteCastingOfSpell
set "coord=%py.pos.y%;%py.pos.x%"
set "death_description=%~6"

if "%~3"=="5" (
    REM Short teleport
    call spells.cmd :spellTeleportAwayMonster %~2 5
    exit /b
) else if "%~3"=="6" (
    REM Long teleport
    call spells.cmd :spellTeleportAwayMonster %~2 %config.monsters.mon_max_sight%
) else if "%~3"=="7" (
    REM Teleport the player to the monster
    call spells.cmd :spellTeleportPlayerTo "!%~1.pos.y!;!%~1.pos.x!"
    exit /b
) else if "%~3"=="8" (
    REM Light wound
    call player.cmd :playerSavingThrow
    if "!errorlevel!"=="0" (
        call ui_io.cmd :printMessage "You resist the effects of the spell."
    ) else (
        call dice.cmd :diceRoll 3 8
        call player.cmd :playerTakesHit !errorlevel! "!death_description!"
    )
    exit /b
) else if "%~3"=="9" (
    REM Serious wound
    call player.cmd :playerSavingThrow
    if "!errorlevel!"=="0" (
        call ui_io.cmd :printMessage "You resist the effects of the spell."
    ) else (
        call dice.cmd :diceRoll 8 8
        call player.cmd :playerTakesHit !errorlevel! "!death_description!"
    )
    exit /b
) else if "%~3"=="10" (
    REM Hold person
    if "%py.flags.free_action%"=="true" (
        call ui_io.cmd :printMessage "You are unaffected."
    ) else (
        call player.cmd :playerSavingThrow
        if "!errorlevel!"=="0" (
            call ui_io.cmd :printMessage "You resist the effects of the spell."
        ) else if %py.flags.paralysis% GTR 0 (
            set /a py.flags.paralysis+=2
        ) else (
            call rng.cmd :randomNumber 5
            set /a paralysis+=!errorlevel!+4
        )
    )
    exit /b
) else if "%~3"=="11" (
    REM Cause blindness
    call player.cmd :playerSavingThrow
    if "!errorlevel!"=="0" (
        call ui_io.cmd :printMessage "You resist the effects of the spell."
    ) else (
        if %py.flags.blind% GTR 0 (
            set /a py.flags.blind+=6
        ) else (
            call rng.cmd :randomNumber 3
            set /a py.flags.blind=!errorlevel!+12
        )
    )
    exit /b
) else if "%~3"=="12" (
    REM Cause confusion
    call player.cmd :playerSavingThrow
    if "!errorlevel!"=="0" (
        call ui_io.cmd :printMessage "You resist the effects of the spell."
    ) else (
        if %py.flags.confused% GTR 0 (
            set /a py.flags.confused+=2
        ) else (
            call rng.cmd :randomNumber 5
            set /a py.flags.confused=!errorlevel!+3
        )
    )
    exit /b
) else if "%~3"=="13" (
    REM Cause fear
    call player.cmd :playerSavingThrow
    if "!errorlevel!"=="0" (
        call ui_io.cmd :printMessage "You resist the effects of the spell."
    ) else (
        if %py.flags.afraid% GTR 0 (
            set /a py.flags.afraid+=2
        ) else (
            call rng.cmd :randomNumber 5
            set /a py.flags.afraid=!errorlevel!+3
        )
    )
    exit /b
) else if "%~3"=="14" (
    REM Summon monster
    call ui_io.cmd :printMessage "%~5 magically summons a monster."
    set "coord.y=%py.pos.y%"
    set "coord.x=%py.pos.x%"
    set "coord=!coord.y!;!coord.x!"

    set "hack_monptr=%~2"
    call monster_manager.cmd :monsterSummon "coord" "false"
    set "hack_monptr=-1"
    for /f "tokens=1,2" %%X in ("!coord.x! !coord.y!") do (
        call :monsterUpdateVisibility "!dg.floor[%%~Y][%%~X].creature_id!"
    )
    exit /b
) else if "%~3"=="15" (
    REM Summon undead
    call ui_io.cmd :printMessage "%~5 magically summons an undead."
    set "coord.y=%py.pos.y%"
    set "coord.x=%py.pos.x%"
    set "coord=!coord.y!;!coord.x!"

    set "hack_monptr=%~2"
    call monster_manager.cmd :monsterSummonUndead "coord" "false"
    set "hack_monptr=-1"
    for /f "tokens=1,2" %%X in ("!coord.x! !coord.y!") do (
        call :monsterUpdateVisibility "!dg.floor[%%~Y][%%~X].creature_id!"
    )
    exit /b
) else if "%~3"=="16" (
    REM Slow person
    if "%py.flags.free_action%"=="true" (
        call ui_io.cmd :printMessage "You are unaffected."
    ) else (
        call player.cmd :playerSavingThrow
        if "!errorlevel!"=="0" (
            call ui_io.cmd :printMessage "You resist the effects of the spell."
        ) else (
            if %py.flags.slow% GTR 0 (
                set /a py.flags.slow+=2
            ) else (
                call rng.cmd :randomNumber 5
                set /a py.flags.slow=!errorlevel!+3
            )
        )
    )
    exit /b
) else if "%~3"=="17" (
    REM Drain mana
    if %py.misc.current_mana% GTR 0 (
        call player.cmd :playerDisturb 1 0

        call ui_io.cmd :printMessage "%~5draws psychic energy from you."
        if "!%monster%.lit!"=="true" (
            call ui_io.cmd :printMessage "%~5appears healthier."
        )

        call rng.cmd :randomNumber %~4
        set /a "num=(!errorlevel! >> 1) + 1"
        if !num! GTR %py.misc.current_mana% (
            set "num=%py.misc.current_mana%"
            set "py.misc.current_mana=0"
            set "py.misc.current_mana_fraction=0"
        ) else (
            set /a py.misc.current_mana-=!num!
        )
        call ui.cmd :printCharacterCurrentMana
        set /a %monster%.hp+=6*!num!
    )
    exit /b
) else if "%~3"=="20" (
    REM Breathe light
    call ui_io.cmd :printMessage "%~5breathes lightning."
    set /a damage_hp=!%monster%.hp!/4
    call spells.cmd. :spellBreath "%py.pos.y%;%py.pos.x%" "%~2" "!damage_hp!" "%MagicSpellFlags.Lightning%" "death_description"
    exit /b
) else if "%~3"=="21" (
    REM Breathe Gas
    call ui_io.cmd :printMessage "%~5breathes gas."
    set /a damage_hp=!%monster%.hp!/3
    call spells.cmd. :spellBreath "%py.pos.y%;%py.pos.x%" "%~2" "!damage_hp!" "%MagicSpellFlags.PoisonGas%" "death_description"
    exit /b
) else if "%~3"=="22" (
    REM Breathe Acid
    call ui_io.cmd :printMessage "%~5breathes acid."
    set /a damage_hp=!%monster%.hp!/3
    call spells.cmd. :spellBreath "%py.pos.y%;%py.pos.x%" "%~2" "!damage_hp!" "%MagicSpellFlags.Acid%" "death_description"
    exit /b
) else if "%~3"=="23" (
    REM Breathe Frost
    call ui_io.cmd :printMessage "%~5breathes frost."
    set /a damage_hp=!%monster%.hp!/3
    call spells.cmd. :spellBreath "%py.pos.y%;%py.pos.x%" "%~2" "!damage_hp!" "%MagicSpellFlags.Frost%" "death_description"
    exit /b
) else if "%~3"=="24" (
    REM Breathe Fire
    call ui_io.cmd :printMessage "%~5breathes fire."
    set /a damage_hp=!%monster%.hp!/3
    call spells.cmd. :spellBreath "%py.pos.y%;%py.pos.x%" "%~2" "!damage_hp!" "%MagicSpellFlags.Fire%" "death_description"
    exit /b
) else (
    call ui_io.cmd :printMessage "%~5casts an unknown spell. Nothing seems to happen."
)
exit /b

::------------------------------------------------------------------------------
:: A wrapper for monsterExecuteCastingOfSpell, mostly
::
:: Arguments: %1 - The ID of the monster that is casting the spell
:: Returns:   0 if the monster cast a spell
::            1 if the monster was not able to cast a spell
::------------------------------------------------------------------------------
:monsterCastSpell
if "%game.character_is_dead%"=="true" exit /b 1

set "monster=monsters[%~1]"
set "c_id=!%monster%.creature_id!"
set "creature=creatures_list[%c_id%]"

call :monsterCanCastSpells "%monster%" "!%creature%.spells!" || exit /b 1

call :monsterUpdateVisibility "%~1"

if "!%monster%.lit!"=="true" (
    set "name=The !%creature%.name! "
) else (
    set "name It "
)

call player.cmd :playerDiedFromString "death_description" "!%creature%.name!" "!%creature%.movement!"

set /a "spell_flags=!%creature%.spells! & ~%config.monsters.spells.cs_freq%"
set "id=0"
:monsterCastSpellWhileLoop
if "!spell_flags!"=="0" goto :monsterCastSpellAfterWhileLoop
call helpers.cmd :getAndClearFirstBit "!spell_flags!"
set "spell_choice[!id!]=!errorlevel!"
set /a id+=1
goto :monsterCastSpellWhileLoop
:monsterCastSpellAfterWhileLoop

call rng.cmd :randomNumber !id!
set /a rnd_dec=!errorlevel!-1
set /a thrown_spell=!spell_choice[%rnd_dec%]! + 1

:: All spells spellTeleportAwayMonster and Drain Mana spells always disturb the player
if %thrown_spell% GTR 6 (
    if not "%thrown_spell% "=="17" (
        call player.cmd :playerDisturb 1 0
    )

    if %thrown_spell% LSS 14 (
        call ui_io.cmd :printMessage "%name%casts a spell."
    )
)

if "%thrown_spell%"=="16" (
    call ui_io.cmd :printMessage "%name%casts a spell."
)

call :monsterExecuteCastingOfSpell "%monster%" "%~1" "%thrown_spell%" "!%creature%.level!" "%name%" "%death_description%"

if "!%monster%.lit!"=="true" (
    set /a "creature_recall[%c_id%].spells|=1 << (%thrown_spell% - 1)"
    set /a "freq_time=!creature_recall[%c_id%].spells! & %config.monsters.spells.cs_freq%"
    if not "!freq_time!"=="%config.monsters.spells.cs_freq%" (
        set /a creature_recall[%c_id%].spells+=1
    )

    if "!game.character_is_dead!"=="true" (
        if !creature_recall[%c_id%].deaths! LSS 32767 (
            set /a creature_recall[%c_id%].deaths+=1
        )
    )
)

set "c_id="
set "freq_time="
set "thrown_spell="
set "many_deaths="
exit /b 0

::------------------------------------------------------------------------------
:: Places creature adjacent to a specified set of coordinates
::
:: Arguments: %1 - The coordinates to place the monster next to
::            %2 - The creature_id of the monster being placed
::            %3 - The monster_id of the monster being placed
:: Returns:   0 if a monster is successfully placed
::            1 if there is no place to put the monster
::------------------------------------------------------------------------------
:monsterMultiply
for /f "tokens=1,2 delims=;" %%A in ("%~1") do (
    set "coord.y=%%~A"
    set "coord.x=%%~B"
)
set "coord=%coord.y%;%coord.x%"

for /L %%A in (0,1,18) do (
    call rng.cmd :randomNumber 3
    set /a position.y=%coord.y% - 2 + !errorlevel!
    call rng.cmd :randomNumber 3
    set /a position.x=%coord.x% - 2 + !errorlevel!

    set "position=!position.y!;!position.x!"
    call dungeon.cmd :coordInBounds "position"
    if "!errorlevel!"=="0" (
        set "is_misaligned=0"
        if not "!position.y!"=="!coord.y!" set "is_misaligned=1"
        if not "!position.x!"=="!coord.x!" set "is_misaligned=1"
        if "!is_misaligned!"=="1" (
            for /f "delims" %%T in ("dg.floor[!position.y!][!position.x!]") do (
                if !%%~T.feature_id! LEQ %MAX_OPEN_SPACE% (
                    if "!%%~T.treasure_id!"=="0" (
                        if not "!%%~T.creature_id!"=="1" (
                            if !%%~T.creature_id! GTR 1 (
                                set "cannibalistic=false"
                                set /a "is_cannibalistic=!creatures_list[%~2].movement! & %config.monsters.move.cm_eats_others%"
                                if not "!is_cannibalistic!"=="0" set "cannibalistic=true"

                                set "experienced=false"
                                for /f "delims=" %%B in ("!%%~T.creature_id!") do (
                                    for /f "delims=" %%C in ("!monsters[%%~B].creature_id!") do (
                                        if !creatures_list[%~2].kill_exp_value! GEQ !creatures_list[%%~C].kill_exp_value! (
                                            REM TODO: Rewrite so that this isn't eleven indents deep
                                            set "experienced=true"
                                        )
                                    )
                                )

                                if "!cannibalistic!"=="true" (
                                    if "!experienced!"=="true" (
                                        if %~3 LSS !%%~T.creature_id! (
                                            REM It ate an already-processed monster. Handle normally.
                                            call dungeon.cmd :dungeonDeleteMonster "!%%~T.creature_id!"
                                        ) else (
                                            REM An already-processed monster will take its place, which breaks things
                                            call dungeon.cmd :dungeonRemoveMonsterFromLevel "!%%~T.creature_id!"
                                        )

                                        REM In case :compact_monster is called, it needs monster_id
                                        set "hack_monptr=%~3"
                                        call monster_manager.cmd :monsterPlaceNew "coord" "%~2" "false"
                                        set "result=!errorlevel!"
                                        set "hack_monptr=-1"
                                        if "!result!"=="1" exit /b 1

                                        set /a monster_multiply_total+=1
                                        call :monsterMakeVisible "!position.y!;!position.x!"
                                        exit /b !errorlevel!
                                    )
                                )
                            ) else (
                                REM Place a monster
                                REM In case :compact_monster is called, it needs monster_id
                                set "hack_monptr=%~3"
                                call monster_manager.cmd :monsterPlaceNew "coord" "%~2" "false"
                                set "result=!errorlevel!"
                                set "hack_monptr=-1"
                                if "!result!"=="1" exit /b 1

                                set /a monster_multiply_total+=1
                                call :monsterMakeVisible "!position.y!;!position.x!"
                                exit /b !errorlevel!
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
:: Remember that certain monsters can multiply
::
:: Arguments: %1 - A reference to the monster
::            %2 - The monster_id of the monster
::            %3 - A reference to the recalled movement of the monster
:: Returns:   None
::------------------------------------------------------------------------------
:monsterMultiplyCritter
set "monster=%~1"
set "counter=0"

call helpers.cmd :expandCoordName "monster.pos"

for /L %%Y in (%monster.pos.y_dec%,1,%monster.pos.y_inc%) do (
    for /L %%X in (%monster.pos.x_dec%,1,%monster.pos.x_inc%) do (
        set "coord=%%Y;%%X"
        call dungeon.cmd :coordInBounds "coord"
        if "!errorlevel!"=="0" (
            if !dg.floor[%%Y][%%X].creature_id! GTR 1 (
                set /a counter+=1
            )
        )
    )
)

:: randomNumber can't be called with a value of zero so increment it
if "!counter!"=="0" set /a counter+=1

if !counter! LSS 4 (
    set /a mon_mult=!counter!*%config.monsters.mon_multiply_adjust%
    call rng.cmd :randomNumber !mon_mult!
    if "!errorlevel!"=="1" (
        call :monsterMultiply "%monster.pos.y%;%monster.pos.x%" "!%~1.creature_id!" "%~2"
        if "!errorlevel!"=="0" (
            set /a "%~3|=%config.monsters.move.cm_multiply%"
        )
    )
)
exit /b

::------------------------------------------------------------------------------
:: Extracts a monster from inside of a rock wall
::
:: Arguments: %1 - A reference to the monster that is being moved
::            %2 - The monster_id of the monster
::            %3 - A reference to the monster's recalled movement
:: Returns:   None
::------------------------------------------------------------------------------
:monsterMoveOutOfWall
set "monster=%~1"
set "rcmove=%~3"
if !%monster%.hp! LSS 0 exit /b

set "id=0"
set "dir=1"

call helpers.cmd :expandCoordName "monster.pos"
for /L %%Y in (%monster.pos.y_dec%,1,%monster.pos.y_inc%) do (
    for /L %%X in (%monster.pos.x_dec%,1,%monster.pos.x_inc%) do (
        if not "!dir!"=="5" (
            if !dg.floor[%%Y][%%X].feature_id! LEQ %MAX_OPEN_SPACE% (
                if not "!dg.floor[%%Y][%%X].creature_id!"=="1" (
                    set "directions[!id!]=!dir!"
                    set /a id+=1
                )
                set "dir+=1"
            )
        )
    )
)

if not "!id!"=="0" (
    call rng.cmd :randomNumber !id!
    set /a dir=!errorlevel!-1

    for /f "delims=" %%A in ("!dir!") do (
        set "saved_id=!directions[0]!"
        set "directions[0]=!directions[%%~A]!"
        set "directions[%%~A]=!saved_id!"
    )

    call :makeMove "%~2" "directions" "%~3" rcmove
)

:: If it's still in the wall, let it try to dig out
if !dg.floor[%monster.pos.y%][%monster.pos.x%].feature_id! GEQ %MIN_CAVE_WALL% (
    set "hack_monptr=%~2"
    call dice.cmd :diceRoll 8 8
    call :monsterTakeHit "%~2" "!errorlevel!"
    set "i=!errorlevel!"
    set "hack_monptr=-1"

    if !i! GEQ 0 (
        call ui_io.cmd :printMessage "You hear a scream muffled by rock."
        call ui.cmd :displayCharacterExperience
    ) else (
        call ui_io.cmd : printMessage "A creature digs itself out from the rock."
        call player.cmd :playerTunnelWall "%monster.pos.y%;%monster.pos.x%" 1 0
    )
)
exit /b

::------------------------------------------------------------------------------
:: Undead move away unless cornered
::
:: Arguments: %1 - A reference to the creature that is moving
::            %2 - The monster_id of the undead creature
::            %3 - A reference to the monster's recalled movement
:: Returns:   None
::------------------------------------------------------------------------------
:monsterMoveUndead
call :monsterGetMoveDirection "%~2" "directions"

set /a directions[0]=10-!directions[0]!
set /a directions[1]=10-!directions[1]!
set /a directions[2]=10-!directions[2]!
call rng.cmd :randomNumber 9
set "directions[3]=!errorlevel!"
call rng.cmd :randomNumber 9
set "directions[4]=!errorlevel!"

set /a "is_attack_only=!%~1.movement! & %config.monsters.move.cm_attack_only%"
if "!is_attack_only!"=="0" (
    call :makeMove "%~2" "directions" "%~3"
)
exit /b

::------------------------------------------------------------------------------
:: Have the creature move in a random direction when it's confused
::
:: Arguments: %1 - A reference to the creature that is moving
::            %2 - The monster_id of the undead creature
::            %3 - A reference to the monster's recalled movement
:: Returns:   None
::------------------------------------------------------------------------------
:monsterMoveConfused
for /L %%A in (0,1,4) do (
    call rng.cmd :randomNumber 9
    set "directions[%%A]=!errorlevel!"
)

set /a "is_attack_only=!%~1.movement! & %config.monsters.move.cm_attack_only%"
if "!is_attack_only!"=="0" (
    call :makeMove "%~2" "directions" "%~3"
)
set "is_attack_only="
exit /b

::------------------------------------------------------------------------------
:: Determines how a monster can move
::
:: Arguments: %1 - The monster_id of the monster that is moving
::            %2 - A reference to the monster's recalled movement
::            %3 - A reference to the monster
::            %4 - A reference to the creature
:: Returns:   0 if the monster moves
::            1 if the monster stays still
::------------------------------------------------------------------------------
:monsterDoMove
if not "!%~3.confused_amount!"=="0" (
    set /a "is_undead=!%~4.defenses! & %config.monsters.defense.cd_undead%"
    if not "!is_undead!"=="0" (
        call :monsterMoveUndead "%~4" "%~1" "%~2"
    ) else (
        call :monsterMoveConfused "%~4" "%~1" "%~2"
    )
    set "is_undead="
    set /a %~3.confused_amount-=1
    exit /b 0
)

set /a "can_cast_spell=!%~4.spells! & %config.monsters.spells.cs_freq%"
if not "%can_cast_spell%"=="0" (
    call :monsterCastSpell "%~1"
    exit /b !errorlevel!
)
exit /b 1

::------------------------------------------------------------------------------
:: Moves the monster in a random direction
::
:: Arguments: %1 - The monster_id of the monster that is moving
::            %2 - A reference to the monster's recalled movement
::            %3 - The level of randomness in the monster's movements
:: Returns:   None
::------------------------------------------------------------------------------
:monsterMoveRandomly
for /L %%A in (0,1,8) do set "directions[%%A]=0"
for /L %%A in (0,1,4) do (
    call rng.cmd :randomNumber 9
    set "directions[%%A]=!errorlevel!"
)
set /a "%~2|=%~3"
call :makeMove "%~1" "directions" "%~2"
exit /b

::------------------------------------------------------------------------------
:: Moves the monster in a preset direction, but also has a 1/200 chance of
:: moving randomly instead
::
:: Arguments: %1 - The monster_id of the monster that is moving
::            %2 - A reference to the monster's recalled movement
:: Returns:   None
::------------------------------------------------------------------------------
:monsterMoveNormally
for /L %%A in (0,1,8) do set "directions[%%A]=0"
call rng.cmd :randomNumber 200
if "!errorlevel!"=="1" (
    for /L %%A in (0,1,4) do (
        call rng.cmd :randomNumber 9
        set "directions[%%A]=!errorlevel!"
    )
) else (
    call :monsterGetMoveDirection "%~1" "directions"
)

set /a "%~2|=%config.monsters.move.cm_move_normal%"
call :makeMove "%~1" "directions" "%~2"
exit /b

::------------------------------------------------------------------------------
:: Attacks if the player is within range but does not move otherwise
::
:: Arguments: %1 - The monster_id of the monster that is attacking
::            %2 - A reference to the monster's recalled movement
::            %3 - The monster's distance from the player
:: Returns:   None
::------------------------------------------------------------------------------
:monsterAttackWithoutMoving
for /L %%A in (0,1,8) do set "directions[%%A]=0"
if %~3 LSS 2 (
    call :monsterGetMoveDirection "%~1" "directions"
    call :makeMove "%~1" "directions" "%~2"
) else (
    REM Learn that the monster does not move when it normally would
    set /a "rcmove|=%config.monsters.move.cm_attack_only%"
)
exit /b

::------------------------------------------------------------------------------
:: A wrapper for all of the monster movement subroutines
::
:: Arguments: %1 - The monster_id of the monster that is attacking
::            %2 - A reference to the monster's recalled movement
:: Returns:   None
::------------------------------------------------------------------------------
:monsterMove
set "monster=monsters[%~1]"
set "c_id=!%monster%.creature_id!"
set "creature=creatures_list[%c_id%]"

:: Check to see if the monster can multiply
set "abs_rest_period=%py.flags.rest%"
if %abs_rest_period% LSS 0 set /a abs_rest_period*=-1
set /a "can_multiply=!%creature%.movement! & %config.monsters.move.cm_multiply%"
set /a mult_freq=%abs_rest_period% %% %config.monsters.mon_multiply_adjust% mon_mult
if not "%can_multiply%"=="0" (
    if %config.monsters.mon_max_multiply_per_level% GEQ %monster_multiply_total% (
        if "%mult_freq%"=="0" (
            call :monsterMultiplyCritter "%monster%" "%~1" "%~2"
        )
    )
)
for %%A in (abs_rest_period can_multiply mult_freq) do set "%%~A="

:: Move the monster out of the wall if applicable
set /a "can_phase=!%creature%.movement! & %config.monsters.move.cm_phase%"
set "monster_coords=!%monster%.pos.y!][!%monster%.pos.x!"
if "%can_phase%"=="0" (
    REM I'm weirdly proud of this
    if !dg.floor[%monster_coords%].feature_id! GEQ %MIN_CAVE_WALL% (
        call :monsterMoveOutOfWall "%monster%" "%~1" "%~2"
        exit /b
    )
)
set "can_phase="
set "monster_coords="

call :monsterDoMove "%~1" "%~2" "%monster%" "%creature%" && exit /b

:: Random movement
for %%A in ("75" "40" "20") do (
    set /a "rnd_move=!%creature%.movement! & !config.monsters.move.cm_%%~A_random!"
    if not "%rnd_move%"=="0" (
        call rng.cmd :randomNumber 100
        if !errorlevel! LSS %%~A (
            call :monsterMoveRandomly "%~1" "%~2" "!config.monsters.move.cm_%%~A_random!"
            exit /b
        )
    )
)
set "rnd_move="

:: Normal movement
set /a "is_normal_movement=!%creature%.movement! & %config.monsters.move.cm_move_normal%"
if not "!is_normal_movement!"=="0" (
    call :monsterMoveNormally %*
    exit /b
)
set "is_normal_movement="

:: Attacking while standing still
set /a "is_attack_only=!%creature%.movement! & %config.mosnters.move.cm_attack_only%"
if not "%is_attack_only%"=="0" (
    call :monsterAttackWithoutMoving "%~1" "%~2" "!%monster%.distance_from_player!"
    exit /b
)
set "is_attack_only="

:: And the Quylthulgs are also here
set /a "is_only_magic=!%creature%.movement! & %config.monsters.move.cm_only_magic%"
if not "%is_only_magic%"=="0" (
    if !%monster%.distance_from_player! LSS 2 (
        if !creature_recall[%c_id%].attacks[0]! LSS 32767 (
            set /a creature_recall[%c_id%].attacks[0]+=1
        )

        if !creature_recall[%c_id%].attacks[0]! GTR 20 (
            set /a "creature_recall[%c_id%].movement|=%config.monsters.move.cm_only_magic%"
        )
    )
)
set "is_only_magic="
exit /b

::------------------------------------------------------------------------------
:: Updates various recollection flags for a specified monster
::
:: Arguments: %1 - A reference to the monster being recalled
::            %2 - Indicates if the monster is currently awake
::            %3 - Indicates if the monster is currently ignoring the player
::            %4 - The monster's recalled movement flags
:: Returns:   None
::------------------------------------------------------------------------------
:memoryUpdateRecall
if "!%~1.lit!"=="false" exit /b

set "c_id=!%~1.creature_id!"
set "memory=creature_recall[%c_id%]"

if "%~2"=="true" (
    if !%memory%.wake! LSS 255 (
        set /a %memory%.wake+=1
    )
) else if "%~3"=="true" (
    if !%memory%.ignore! LSS 255 (
        set /a %memory%.ignore+=1
    )
)
set /a "%memory%.movement|=%~4"
exit /b

:monsterAttackingUpdate
exit /b

:updateMonsters
exit /b

:monsterTakeHit
exit /b

:monsterDeathItemDropType
exit /b

:monsterDeathItemDropCount
exit /b

:monsterDeath
exit /b

:printMonsterActionText
exit /b

:monsterNameDescription
exit /b

:monsterSleep
exit /b

:executeAttackOnPlayer
exit /b
