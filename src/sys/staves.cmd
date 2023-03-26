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

:staffPlayerCanUse
exit /b

:staffDischarge
exit /b

:staffUse
exit /b

:wandDischarge
exit /b

:wandAim
exit /b

