@echo off
call %*
exit /b

::------------------------------------------------------------------------------
:: Determines if a player is able to read the scroll at all
::
:: Arguments: %1 - The variable that the starting range of the scrolls is in
::            %2 - The variable that the ending range of the scrolls is in
:: Returns:   0 if the player is able to read a scroll
::            1 if there is some factor preventing the player from reading
::------------------------------------------------------------------------------
:playerCanReadScroll
if %py.flags.blind% GTR 0 (
    call ui_io.cmd :printMessage "You can't see to read the scroll."
    exit /b 1
)

call player.cmd :playerNoLight && (
    call ui_io.cmd :printMessage "You have no light to read by."
    exit /b 1
)

if %py.flags.confused% GTR 0 (
    call ui_io.cmd :printMessage "You are too confused to read a scroll."
    exit /b 1
)

if "%py.pack.unique_items%"=="0" (
    call ui_io.cmd :printMessage "You are not carrying anything."
    exit /b 1
)

call inventory.cmd :inventoryFindRange %TV_SCROLL1% %TV_SCROLL2% "%~1" "%~2" || (
    call ui_io.cmd :printMessage "You are not carrying any scrolls."
    exit /b 1
)
exit /b 0

:inventoryItemIdOfCursedEquipment
exit /b

:scrollEnchantWeaponToHit
exit /b

:scrollEnchantWeaponToDamage
exit /b

:scrollEnchantItemToAC
exit /b

:scrollIdentifyItem
exit /b

:scrollRemoveCurse
exit /b

:scrollSummonMonster
exit /b

:scrollTeleportLevel
exit /b

:scrollConfuseMonster
exit /b

:scrollEnchantWeapon
exit /b

:scrollCurseWeapon
exit /b

:scrollEnchantArmor
exit /b

:scrollCurseArmor
exit /b

:scrollSummonUndead
exit /b

:scrollWordOfRecall
exit /b

:scrollRead
exit /b

