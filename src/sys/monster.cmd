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
:: Arguments: %1 - A reference to the monster's creature_list[] data
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
exit /b

:glyphOfWardingProtection
exit /b

:monsterMovesOnPlayer
exit /b

:monsterAllowedToMove
exit /b

:makeMove
exit /b

:monsterCanCastSpells
exit /b

:monsterExecuteCastingOfSpell
exit /b

:monsterCastSpell
exit /b

:monsterMultiply
exit /b

:monsterMultiplyCritter
exit /b

:monsterMoveOutOfWall
exit /b

:monsterMoveUndead
exit /b

:monsterMoveConfused
exit /b

:monsterDoMove
exit /b

:monsterMoveRandomly
exit /b

:monsterMoveNormally
exit /b

:monsterAttackWithoutMoving
exit /b

:monsterMove
exit /b

:memoryUpdateRecall
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
