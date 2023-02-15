@echo off
call %*
exit /b

::------------------------------------------------------------------------------
:: Calculates a player's ability to disarm a trap
::
:: Arguments: None
:: Returns:   The likelihood that the player will be able to disarm a trap
::------------------------------------------------------------------------------
:playerTrapDisarmAbility
set "ability=%py.misc.disarm%"
set /a ability+=2
call player_stats.cmd :playerDisarmAdjustment
set /a ability*=!errorlevel!
call player_stats.cmd :playerStatAdjustmentWisdomIntelligence %PlayerAttr.a_int%
set /a ability+=!errorlevel!
set /a ability+=!class_level_adj[%py.misc.class_id%][%PlayerClassLevelAdj.disarm%]!*%py.misc.level%/3

call player.cmd :playerNoLight
if "!errorlevel!"=="0" set /a ability/=10
if %py.flags.blind% GTR 0 set /a ability/=10
if %py.flags.confused% GTR 0 set /a ability/=10
if %py.flags.image% GTR 0 set /a ability/=10
exit /b !ability!

::------------------------------------------------------------------------------
:: Attempt to disarm a trap on the floor
::
:: Arguments: %1 - The coordinates of the trap
::            %2 - The odds of the player disarming the trap successfully
::            %3 - The floor where the trap was first found
::            %4 - The direction that the player is facing
::            %5 - The amount of EXP that the player gets for disarming a trap
:: Returns:   None
::------------------------------------------------------------------------------
:playerDisarmFloorTrap
set "confused=%py.flags.confused%"

set /a odds_adj=%~2 + 100 - %~3
call rng.cmd :randomNumber 100
if !odds_adj! GTR !errorlevel! (
    call ui_io.cmd :printMessage "You have disarmed the trap."
    set /a py.misc.exp+=%~5
    set "coord=%~1"
    call dungeon.cmd :dungeonDeleteObject "coord"

    REM Move onto the trap even if confused
    set "py.flags.confused=0"
    call player_move.cmd :playerMove "%~4" "false"
    set "py.flags.confused=!confused!"

    call ui.cmd :displayCharacterExperience
    exit /b

    if %~2 GTR 5 (
        call rng.cmd :randomNumber %~2
        if !errorlevel! GTR 5 (
            call ui_io.cmd :printMessageNoCommandInterrupt "You failed to disarm the trap."
            exit /b
        )
    )

    call ui_io.cmd :printMessage "You set the trap off."

    REM Move onto the trap even if confused
    set "py.flags.confused=0"
    call player_move.cmd :playerMove "%~4" "false"
    set "py.flags.confused=!confused!"
)
exit /b

::------------------------------------------------------------------------------
:: Remove a trap from a chest
::
:: Arguments: %1 - The coordinates of the chest
::            %2 - The odds of the trap being disarmed successfully
::            %3 - A reference to the chest item being disarmed
:: Returns:   None
::------------------------------------------------------------------------------
:playerDisarmChestTrap
call identification.cmd :spellItemIdentified %3
if "!errorlevel!"=="1" (
    set "game.player_free_turn=true"
    call ui_io.cmd :printMessage "I don't see a trap."
    exit /b
)

set "disarm_fail=0"
if %~2 GTR 5 set /a disarm_fail+=1
call rng.cmd :randomNumber 5
if !errorlevel! GTR 5 set /a disarm_fail+=1

set /a "is_trapped=!%~3.flags! & config.treasure.chests.ch_trapped%"
if not "!is_trapped!"=="0" (
    set "level=!%~3.depth_first_found!"
    
    set /a total_offset=%~2-!level!
    call rng.cmd :randomNumber 100
    if !total_offset! GTR !errorlevel! (
        set /a "%~3.flags&=~%config.treasure.chests.ch_trapped%"

        REM It's possible for a chest to be both trapped and locked
        set /a "is_locked=!%~3.flags! & config.treasure.chests.ch_locked%"
        if not "!is_locked!"=="0" (
            set "%~3.special_name_id=%SpecialNameIds.sn_locked%"
        ) else (
            set "%~3.special_name_id=%SpecialNameIds.sn_disarmed%"
        )

        call ui_io.cmd :printMessage "You have disarmed the chest."
        call identification.cmd :spellItemIdentifyAndRemoveRandomInscription %3
        set /a py.misc.exp+=!level!
        call ui.cmd :displayCharacterExperience
    ) else if "!disarm_fail!"=="2" (
        call ui_io.cmd :printMessageNoCommandInterrupt "You failed to disarm the chest."
    ) else (
        call ui_io.cmd :printMessage "You set a trap off."
        call identification.cmd :spellItemIdentifyAndRemoveRandomInscription %3
        call :chestTrap "%~1"
    )
    exit /b
)

call ui_io.cmd :printMessage "The chest was not trapped."
set "game.player_free_turn=true"
exit /b

::------------------------------------------------------------------------------
:: Disarms a trap
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerDisarmTrap
call game.cmd :getDirectionWithMemory "CNIL" "direction" || exit /b

set "coord=%py.pos.y%;%py.pos.x%"
call player.cmd :playerMovePosition !direction! "coord"

for /f "tokens=1,2 delims=;" %%A in ("!coord!") do set "tile=dg.floor[%%A][%%B]"
set "no_disarm=false"
set "tile_treasure_id=!%tile%.treasure_id!"

set "is_blocked=0"
if !%tile%.creature_id! GTR 1 set /a is_blocked+=1
if !%tile%.treasure_id! GTR 1 set /a is_blocked+=1
if "!game.treasure.list[%tile_treasure_id%].category_id!"=="%tv_vis_trap%" set /a is_blocked+=1
if "!game.treasure.list[%tile_treasure_id%].category_id!"=="%tv_chest%" set /a is_blocked+=1

:: It's 3 and not 4 because it can't be both a visible trap and a chest
if "!is_blocked!"="3" (
    call identification.cmd :objectBlockedByMonster !%tile%.creature_id!
) else if not "%tile_treasure_id%"=="0" (
    call :playerTrapDisarmAbility
    set "disarm_ability=!errorlevel!"

    if "!game.treasure.list[%tile_treasure_id%].category_id!"=="%TV_VIS_TRAP%" (
        call :playerDisarmFloorTrap "!coord!" !disarm_ability! !game.treasure.list[%tile_treasure_id%].depth_first_found! !direction! !game.treasure.list[%tile_treasure_id%].misc_use!
    ) else if "!game.treasure.list[%tile_treasure_id%].category_id!"=="%TV_CHEST%" (
        call :playerDisarmChestTrap "!coord!" !disarm_ability! "game.treasure.list[%tile_treasure_id%]"
    ) else (
        set "no_disarm=true"
    )
) else (
    set "no_disarm=true"
)

if "!no_disarm!"=="true" (
    call ui_io.cmd :printMessage "I do not see anything to disarm there."
    set "game.player_free_turn=true"
)
exit /b

::------------------------------------------------------------------------------
:: A chest trap causes the player to lose strength; weirdly, the player does
:: not get poisoned from the poison needle
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:chestLooseStrength
call ui_io.cmd :printMessage "A small needle has pricked you."

if "%py.flags.sustain_str%"=="true" (
    call ui_io.cmd :printMessage "You are unaffected."
    exit /b
)

call player_stats.cmd :playerStatRandomDecrease %PlayerAttr.a_str%
call dice.cmd :diceRoll 1 4
call player.cmd :playerTakesHit !errorlevel! "a poison needle"
call ui_io.cmd :printMessage "You feel weakened."
exit /b

::------------------------------------------------------------------------------
:: A chest trap poisons the player
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:chestPoison
call ui_io.cmd :printMessage "A small needle has pricked you."
call dice.cmd :diceRoll 1 4
call player.cmd :playerTakesHit !errorlevel! "a poison needle"
call rng.cmd :randomNumber 20
set /a py.flags.poisoned+=10 + !randomNumber!
exit /b

::------------------------------------------------------------------------------
:: A chest trap paralyses the player
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:chestParalysed
call ui_io.cmd :printMessage "A puff of yellow gas surrounds you."
if "%py.flags.free_action%"=="true" (
    call ui_io.cmd :printMessage "You are unaffected."
    exit /b
)

call ui_io.cmd :printMessage "You choke and pass out."
call rng.cmd :randomNumber 20
set /a py.flags.paralysis+=10 + !randomNumber!
exit /b

::------------------------------------------------------------------------------
:: A chest trap that summons three random monsters
::
:: Arguments: %1 - The chest's coordinates
:: Returns:   None
::------------------------------------------------------------------------------
:chestSummonMonster
set "coord=%~1"
for /L %%A in (1,1,3) do call monster_manager.cmd :monsterSummon "coord" "false"
exit /b

::------------------------------------------------------------------------------
:: A chest trap that sets off an explosion
::
:: Arguments: %1 - The chest's coordinates
:: Returns:   None
::------------------------------------------------------------------------------
:chestExplode
set "coord=%~1"
call ui_io.cmd :printMessage "There is a sudden explosion^^^!"
call dungeon.cmd :dungeonDeleteObject "coord"
call dice.cmd :diceRoll 5 8
call player.cmd :playerTakesHit !errorlevel! "an exploding chest"
exit /b

::------------------------------------------------------------------------------
:: Determine which kind of chest trap is being used
::
:: Arguments: %1 - The chest's coordinates
::------------------------------------------------------------------------------
:chestTrap
for /f "tokens=1,2 delims=;" %%A in ("%~1") do (
    set "t_id=!dg.floor[%%A][%%B].treasure_id!"
)
set "flags=!game.treasure.list[%t_id%].flags!"

:: TODO: Optimize with an array
set /a "is_trapped=!flags! & %config.treasure.chests.ch_lose_str%"
if not "!is_trapped!"=="0" call :chestLooseStrength
set /a "is_trapped=!flags! & %config.treasure.chests.ch_poison%"
if not "!is_trapped!"=="0" call :chestPoison
set /a "is_trapped=!flags! & %config.treasure.chests.ch_paralysed%"
if not "!is_trapped!"=="0" call :chestParalysed
set /a "is_trapped=!flags! & %config.treasure.chests.ch_summon%"
if not "!is_trapped!"=="0" call :chestSummonMonster "%~1"
set /a "is_trapped=!flags! & %config.treasure.chests.ch_explode%"
if not "!is_trapped!"=="0" call :chestExplode "%~1"
exit /b
