@echo off
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
set /a chance+=!class_level_adj[%py.misc.class_id%][%PlayerClassLevelAdj.device%]! * %py.misc.level% / 3

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

:staffDischarge
exit /b

:staffUse
exit /b

:wandDischarge
exit /b

:wandAim
exit /b

