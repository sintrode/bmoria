@echo off
call %*
exit /b

::------------------------------------------------------------------------------
:: Returns all set flags on all items in the inventory
::
:: Arguments: None
:: Returns:   A list of all flags that are set in the inventory
::------------------------------------------------------------------------------
:inventoryCollectAllItemFlags
set "flags=0"
set /a counter_dec=%PlayerEquipment.Light%-1
for /L %%A in (%PlayerEquipment.Wield%,1,%counter_dec%) do (
    set /a "flags|=!py.inventory[%%A].flags!"
)
exit /b !flags!

::------------------------------------------------------------------------------
:: Destroy an item in the inventory
::
:: Arguments: %1 - The ID of the item to destroy
:: Returns:   None
::------------------------------------------------------------------------------
:inventoryDestroyItem
set "item=py.inventory[%~1]"

set "multiple_items=0"
if !%item%.items_count! GTR 1 set /a multiple_items+=1
if !%item%.sub_category_id! LEQ %item_single_stack_max% set /a multiple_items+=1
if "!multiple_items!"=="2" (
    set /a %item%.items_count-=1
    set /a py.pack.weight-=!%item%.weight!
) else (
    set /a py.pack.weight-=!%item%.weight!*!%item%.items_count!

    set /a counter_dec=!py.pack.unique_items!-2
    for /L %%A in (%~1,1,!counter_dec!) do (
        set /a counter_inc=%%A+1
        call :inventoryCopyItem "py.inventory[%%A]" "py.inventory[!counter_inc!]"
    )

    set /a counter_dec=!py.pack.unique_items!-1
    call :inventoryItemCopyTo "%config.dungeon.objects.obj_nothing%" "py.inventory[!counter_dec!]"
    set /a py.pack.unique_items-=1
)
set /a "py.flags.status|=%config.player.status.py_str_wgt%"
exit /b

::------------------------------------------------------------------------------
:: Copies the object in the second argument over the first argument. The second
:: always gets a number of one except for ammo, etc.
::
:: Arguments: %1 - The item being copied to
::            %2 - The item being copied from
:: Returns:   None
::------------------------------------------------------------------------------
:inventoryTakeOneItem
call :inventoryCopyItem "%~2" "%~1"

if !%~1.items_count! GTR 1 (
    call :inventoryItemSingleStackable "%~1"
    if "!errorlevel!"=="0" (
        set "%~1.items_count=1"
    )
)
exit /b

::------------------------------------------------------------------------------
:: Drops an item from the inventory to a given location
::
:: Arguments: %1 - The item being dropped
::            %2 - Whether to drop a single instance of that item or all of it
:: Returns:   None
::------------------------------------------------------------------------------
:inventoryDropItem
if not "!dg.floor[%py.pos.y%][%py.pos.x%].treasure_id!"=="0" (
    set "py.pos=%py.pos.y%;%py.pos.x%"
    call dungeon.cmd :dungeonDeleteObject "py.pos"
)

call game_objects.cmd :popt
set "treasure_id=!errorlevel!"

:: game.treasure.list is technically an array of Inventory items, so this works
call :inventoryCopyItem "py.inventory[%~1]" "game.treasure.list[!treasure_id!]"

if %~1 GEQ %PlayerEquipment.Wield% (
    call player.cmd :playerTakeOff "%~1" -1
) else (
    set "total_removal=0"
    if "%~2"=="true" set "total_removal=1"
    if "!py.inventory[%~1].items_count!"=="1" set "total_removal=1"
    
    if "!total_removal!"=="1" (
        set /a py.pack.weight-=!py.inventory[%~1].weight! * !py.inventory[%~1].items_count!
        set /a py.pack.unique_items-=1

        set /a counter_dec=!py.pack.unique_items!-1
        for /L %%A in (%~1,1,!counter_dec!) do (
            set /a counter_inc=%~1+1
            call :inventoryCopyItem "py.inventory[%~1]" "py.inventory[!counter_inc!]"
        )

        call :inventoryItemCopyTo "%config.dungeon.objects.obj_nothing%" "py.inventory[!py.pack.unique_items!]"
    ) else (
        set "game.treasure.list[%treasure_id%].items_count=1"
        set /a py.pack.weight-=!py.inventory[%~1].weight!
        set /a py.inventory[%~1].items_count-=1
    )

    call identfication.cmd :itemDescription prt1 "game.treasure.list[!treasure_id!]" "true"
    call ui_io.cmd :printMessage "Dropped !prt1!"
)
set /a "py.flags.status|=%config.player.status.py_str_wgt%"
exit /b

::------------------------------------------------------------------------------
:: Destroys a type of item on a given percent chance
::
:: Arguments: %1 - The item type verification subroutine to run
::            %2 - The chance of damage to the items in the inventory
:: Returns:   The amount of items that were destroyed by the condition
::------------------------------------------------------------------------------
:inventoryDamageItem
set "damage=0"
set /a "counter_dec=!py.pack.unique_items!"

for /L %%A in (0,1,!counter_dec!) do (
    call :%~1 "py.inventory[%%A]"
    if "!errorlevel!"=="0" (
        call rng.cmd :randomNumber 100
        if !errorlevel! LSS %~2 (
            call inventoryDestroyItem %%~A
            set /a damage+=1
        )
    )
)
exit /b !damage!

:inventoryDiminishLightAttack
exit /b

:inventoryDiminishChargesAttack
exit /b

:executeDisenchantAttack
exit /b

:inventoryCanCarryItemCount
exit /b

:inventoryCanCarryItem
exit /b

:inventoryCarryItem
exit /b

:inventoryFindRange
exit /b

:inventoryItemCopyTo
exit /b

:inventoryItemSingleStackable
exit /b

:inventoryItemStackable
exit /b

:inventoryItemIsCursed
exit /b

:inventoryItemRemoveCurse
exit /b

:damageMinusAC
exit /b

:setNull
exit /b

:setCorrodableItems
exit /b

:setFlammableItems
exit /b

::------------------------------------------------------------------------------
:: Determines if an item can be destroyed by acid
::
:: Arguments: %1 - The name of the item to check for dissolvability
:: Returns:   0 if the item can be dissolved by acid
::            1 if the item is resistant to being dissolved
::------------------------------------------------------------------------------
:setAcidAffectedItems
if "!%~1.category_id!"=="%TV_MISC%" exit /b 0
if "!%~1.category_id!"=="%TV_CHEST%" exit /b 0

set "check_resist=0"
if "!%~1.category_id!"=="%TV_CHEST%" set "check_resist=1"
if "!%~1.category_id!"=="%TV_BOLT%" set "check_resist=1"
if "!%~1.category_id!"=="%TV_ARROW%" set "check_resist=1"
if "!%~1.category_id!"=="%TV_BOW%" set "check_resist=1"
if "!%~1.category_id!"=="%TV_HAFTED%" set "check_resist=1"
if "!%~1.category_id!"=="%TV_POLEARM%" set "check_resist=1"
if "!%~1.category_id!"=="%TV_BOOTS%" set "check_resist=1"
if "!%~1.category_id!"=="%TV_GLOVES%" set "check_resist=1"
if "!%~1.category_id!"=="%TV_CLOAK%" set "check_resist=1"
if "!%~1.category_id!"=="%TV_SOFT_ARMOR%" set "check_resist=1"
if "%check_resist%"=="1" (
    set /a "is_resist=!%~1.flags! & %config.treasure.flags.tr_res_acid%"
    exit /b !is_resist!
)
exit /b 1

:setFrostDestroyableItems
exit /b

:setLightningDestroyableItems
exit /b

:setAcidDestroyableItems
exit /b

:setFireDestroyableItems
exit /b

:damageCorrodingGas
exit /b

:damagePoisonedGas
exit /b

:damageFire
exit /b

:damageCold
exit /b

:damageLightningBolt
exit /b

::------------------------------------------------------------------------------
:: Throws acid on the player, either via monster or trap
::
:: Arguments: %1 - The amount of base damage to do to the player
::            %2 - The name of the creature doing the damage
:: Returns:   None
::------------------------------------------------------------------------------
:damageAcid
set "flag=0"

call inventory.cmd :damageMinusAC "%config.treasure.flags.tr_res_acid%" && (
    set "flag=1"
)

if "%py.flags.resistant_to_acid%"=="true" set /a flag+=2
set "total_damage=%~1/(!flag!+1)"
call player.cmd :playerTakesHit !total_damage! "%~2"

call :inventoryDamageItem "setAcidAffectedItems" 3
if !errorlevel! GTR 0 (
    call ui_io.cmd :printMessage "There is an acrid smell coming from your pack."
)
exit /b

::------------------------------------------------------------------------------
:: Copies one inventory item into another one
::
:: Arguments: %1 - The inventory item to copy values into
::            %2 - The inventory item to copy values from
:: Returns:   None
::------------------------------------------------------------------------------
:inventoryCopyItem
for %%T in (id special_name_id inscription flags category_id sprite misc_use
            cost sub_category_id items_count weight to_hit to_damage ac to_ac
            damage.dice damage.sides depth_first_round identification) do (
    set "%~1.%%T=!%~2.%%T"
)
exit /b