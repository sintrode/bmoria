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

::------------------------------------------------------------------------------
:: Selects a random piece of equipment and checks to see if it is cursed
::
:: Arguments: None
:: Returns:   The PlayerEquipment enum value of the first cursed item
::------------------------------------------------------------------------------
:inventoryItemIdOfCursedEquipment
set "item_count=0"

:: TODO: Convert to a for loop that iterates over the PlayerEquipment slots
:: Note that these aren't sequential values so it can't be a for /L loop
if "!py.inventory[%PlayerEquipment.Body%].category_id!"=="%TV_NOTHING%" (
    set "items[!item_count!]=%PlayerEquipment.Body%"
    set /a item_count+=1
)
if "!py.inventory[%PlayerEquipment.Arm%].category_id!"=="%TV_NOTHING%" (
    set "items[!item_count!]=%PlayerEquipment.Arm%"
    set /a item_count+=1
)
if "!py.inventory[%PlayerEquipment.Outer%].category_id!"=="%TV_NOTHING%" (
    set "items[!item_count!]=%PlayerEquipment.Outer%"
    set /a item_count+=1
)
if "!py.inventory[%PlayerEquipment.Hands%].category_id!"=="%TV_NOTHING%" (
    set "items[!item_count!]=%PlayerEquipment.Hands%"
    set /a item_count+=1
)
if "!py.inventory[%PlayerEquipment.Head%].category_id!"=="%TV_NOTHING%" (
    set "items[!item_count!]=%PlayerEquipment.Head%"
    set /a item_count+=1
)
if "!py.inventory[%PlayerEquipment.Feet%].category_id!"=="%TV_NOTHING%" (
    set "items[!item_count!]=%PlayerEquipment.Feet%"
    set /a item_count+=1
)

set "item_id=0"
if !item_count! GTR 0 (
    call rng.cmd :randomNumber !item_count!
    set /a rnd_item=!errorlevel!-1
    for /f "delims=" %%A in ("!rnd_item!") do set "item_id=!items[%%~A]!"
    set "rnd_item="
)

call player.cmd :playerWornItemIsCursed %PlayerEquipment.Body% && set "item_id=%PlayerEquipment.Body%"
call player.cmd :playerWornItemIsCursed %PlayerEquipment.Body% && set "item_id=%PlayerEquipment.Arm%"
call player.cmd :playerWornItemIsCursed %PlayerEquipment.Body% && set "item_id=%PlayerEquipment.Outer%"
call player.cmd :playerWornItemIsCursed %PlayerEquipment.Body% && set "item_id=%PlayerEquipment.Head%"
call player.cmd :playerWornItemIsCursed %PlayerEquipment.Body% && set "item_id=%PlayerEquipment.Hands%"
call player.cmd :playerWornItemIsCursed %PlayerEquipment.Body% && set "item_id=%PlayerEquipment.Feet%"
exit /b !item_id!

:scrollEnchantWeaponToHit
set "item=py.inventory[%PlayerEquipment.wield%]"

if "!%item%.category_id!"=="%TV_NOTHING%" exit /b 1

call identification.cmd :itemDescription "desc" "%item%" "false"
call ui_io.cmd :printMessage "Your %desc% glows faintly."

call spells.cmd :spellEnchantItem "%item%.to_hit" 10
if "!errorlevel!"=="0" (
    call inventory.cmd :inventoryItemRemoveCurse "%item%"
    call player.cmd :playerRecalculateBonuses
) else (
    call ui_io.cmd :printMessage "The enchantment failed."
)
exit /b 0

::------------------------------------------------------------------------------
:: Enchants a weapon with bonuses to improve damage
::
:: Arguments: None
:: Returns:   0 if an item was supposed to be enchanted
::            1 if the player tried to enchant nothing
::------------------------------------------------------------------------------
:scrollEnchantWeaponToDamage
set "item=py.inventory[%PlayerEquipment.wield%]"

if "!%item%.category_id!"=="%TV_NOTHING%" exit /b 1

call identification.cmd :itemDescription "desc" "%item%" "false"
call ui_io.cmd :printMessage "Your %desc% glows faintly."

set "scroll_type=10"
if !%item%.category_id! GEQ %TV_HAFTED% (
    if !%item%.category_id! LEQ %TV_DIGGING% (
        call dice.cmd :maxDiceRoll !%item%.damage.dice! !%item%.damage.sides!
        set "scroll_type=!errorlevel!"
    )
)

call spells.cmd :spellEnchantItem "%item%.to_damage" %scroll_type%
if "!errorlevel!"=="0" (
    call inventory.cmd :inventoryItemRemoveCurse "%item%"
    call player.cmd :playerRecalculateBonuses
) else (
    call ui_io.cmd :printMessage "The enchantment failed."
)
exit /b 0

::------------------------------------------------------------------------------
:: Enchants an item to improve its AC
::
:: Arguments: None
:: Returns:   0 if an item was supposed to be enchanted
::            1 if the player tried to enchant nothing
::------------------------------------------------------------------------------
:scrollEnchantItemToAC
call :inventoryItemIdOfCursedEquipment
set "item_id=!errorlevel!"

if !item_id! LEQ 0 exit /b 1

set "item=py.inventory[%item_id%]"
call identification.cmd :itemDescription "desc" "%item%" "false"
call ui_io.cmd :printMessage "Your %desc% glows faintly."

call spells.cmd :spellEnchantItem "%item%.to_hit" 10
if "!errorlevel!"=="0" (
    call inventory.cmd :inventoryItemRemoveCurse "%item%"
    call player.cmd :playerRecalculateBonuses
) else (
    call ui_io.cmd :printMessage "The enchantment failed."
)
exit /b 0

::------------------------------------------------------------------------------
:: A wrapper for :spellIdentifyItem that merges items if necessary
::
:: Arguments: %1 - The ID of the item being identified
::            %2 - A variable that stores whether the scroll was used or not
:: Returns:   The new ID of the item
::------------------------------------------------------------------------------
:scrollIdentifyItem
set "item_id=%~1"
call ui_io.cmd :printMessage "This is an identify scroll."

call spells.cmd :spellIdentifyItem
set "%~2=!errorlevel!"

set "item=py.inventory[%item_id%]"

:scrollIdentifyItemWhileLoop
if !item_id! LEQ 0 goto :scrollIdentifyItemAfterWhileLoop
set "is_invalid_scroll_flag=0"
if "!%item%.category_id!"=="%TV_SCROLL1%" set "is_invalid_scroll_flag=1"
if "!%item%.flags!"=="8" set "is_invalid_scroll_flag=1"
if "!is_invalid_scroll_flag!"=="1" goto :scrollIdentifyItemAfterWhileLoop
set /a item_id-=1
set "item=py.inventory[%item_id%]"
goto :scrollIdentifyItemWhileLoop

:scrollIdentifyItemAfterWhileLoop
exit /b !item_id!

::------------------------------------------------------------------------------
:: A wrapper for :spellRemoveCurseFromAllWornItems
::
:: Arguments: None
:: Returns:   0 if the curse was successfully removed
::            1 if the curse remains or was never there in the first place
::------------------------------------------------------------------------------
:scrollRemoveCurse
call spells.cmd :spellRemoveCurseFromAllWornItems && (
    call ui_io.cmd :printMessage "You feel as if someone is watching over you."
    exit /b 0
)
exit /b 1

::------------------------------------------------------------------------------
:: Places a monster adjacent to the player and identifies it
::
:: Arguments: None
:: Returns:   0 if the monster was identified
::            1 if the monster remains unknown
::------------------------------------------------------------------------------
:scrollSummonMonster
set "identified=0"
call rng.cmd :randomNumber 3
for /L %%A in (1,1,!errorlevel!) do (
    set "coord=%py.pos.y%;%py.pos.x%"
    call monster_manager.cmd :monsterSummon "coord" "false"
    set /a "identified|=!errorlevel!"
)

:: Because *SOMEONE* decided that true should be 1 but success is errorlevel 0...
if "!identified!"=="1" exit /b 0
exit /b 1

::------------------------------------------------------------------------------
:: Teleports the player to a different floor
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:scrollTeleportLevel
call rng.cmd :randomNumber 2
set /a dg.current_level+=-3+2*!errorlevel!

if %dg.current_level% LSS 1 set "dg.current_level=1"
set "dg.generate_new_level=true"
exit /b

::------------------------------------------------------------------------------
:: Allows the player to confuse monsters, because glowing hands don't occur in
:: nature or something, idk
::
:: Arguments: None
:: Returns:   0 if the monster is now confused
::            1 if the monster was already confused
::------------------------------------------------------------------------------
:scrollConfuseMonster
if "%py.flags.confuse_monster%"=="false" (
    call ui_io.cmd :printMessage "Your hands begin to glow."
    set "py.flags.confuse_monster=true"
    exit /b 0
)
exit /b 1

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

