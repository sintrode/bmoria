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

:playerRestOn
exit /b

:playerRestOff
exit /b

:playerDiedFromString
exit /b

:playerTestAttackHits
exit /b

:playerChangeSpeed
exit /b

:playerAdjustBonusesForItem
exit /b

:playerRecalculateBonusesFromInventory
exit /b

:playerRecalculateSustainStatsFromInventory
exit /b

:playerRecalculateBonuses
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
