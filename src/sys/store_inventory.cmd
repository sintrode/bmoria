call %*
exit /b

::------------------------------------------------------------------------------
:: Initialize and upkeep the store's inventory
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:storeMaintenance
set /a store_dec=%MAX_STORES%-1
for /L %%A in (0,1,%store_dec%) do (
    set "store=stores[%%A]"

    set "%store%.insults_counter=0"
    if !%store%.unique_items_counter! GEQ %config.stores.STORE_MIN_AUTO_SELL_ITEMS% (
        call rng.cmd :randomNumber  %config.stores.STORE_STOCK_TURN_AROUND%
        set "turnaround=!errorlevel!"

        if !%store%.unique_items_counter! GEQ %config.stores.STORE_MAX_AUTO_SELL_ITEMS% (
            set /a turnaround+=1 + !%store%.unique_items_counter! - %config.stores.STORE_MAX_AUTO_SELL_ITEMS%
        )
        set /a turnaround-=1

        for /L %%B in (!turnaround!,-1,0) do (
            call rng.cmd :randomNumber !%store%.unique_items_counter!
            set /a rnd_dec=!errorlevel!-1
            call :storeDestroyItem "%%A" "!rnd_dec!" "false"
        )
        set "turnaround=0"
    )

    if !%store%.unique_items_counter! LEQ %config.stores.STORE_MAX_AUTO_SELL_ITEMS% (
        call rng.cmd :randomNumber %config.stores.STORE_STOCK_TURN_AROUND%
        set "turnaround=!errorlevel!"
        if !%store%.unique_items_counter! LSS %config.stores.STORE_MIN_AUTO_SELL_ITEMS% (
            set /a turnaround+=%config.stores.STORE_MIN_AUTO_SELL_ITEMS% - !%store%.unique_items_counter!
        )

        for /f "delims=" %%B in ("!%store%.owner_id!") do set "max_cost=!store_owners[%%~B].max_cost!"

        set /a turnaround-=1
        for /L %%B in (!turnaround!,-1,0) do (
            call :storeItemCreate "%%A" "!max_cost!"
        )
    )
)
exit /b

::------------------------------------------------------------------------------
:: Returns the value for a specified item
::
:: Arguments: A reference to the item being priced
:: Returns:   The cost of the item
::------------------------------------------------------------------------------
:storeItemValue
set /a "is_cursed=!%~1.identification! & %config.identification.ID_DAMD%"
set /a is_weapon=0, is_ammo=0, is_potion=0, is_food=0, is_jewelry=0, is_magic=0, is_dig=0

if !%~1.category_id! GEQ %TV_BOW% if !%~1.category_id! LEQ %TV_SWORD% set "is_weapon=1"
if !%~1.category_id! GEQ %TV_BOOTS% if !%~1.category_id! LEQ %TV_SOFT_ARMOR% set "is_weapon=1"
if !%~1.category_id! GEQ %TV_SLING_AMMO% if !%~1.category_id! KEQ %TV_SPIKE% set "is_armor=1"
if "!%~1.category_id!"=="%TV_SCROLL1%" set "is_potion=1"
if "!%~1.category_id!"=="%TV_SCROLL2%" set "is_potion=1"
if "!%~1.category_id!"=="%TV_POTION1%" set "is_potion=1"
if "!%~1.category_id!"=="%TV_POTION2%" set "is_potion=1"
if "!%~1.category_id!"=="%TV_FOOD%" set "is_food=1"
if "!%~1.category_id!"=="%TV_AMULET%" set "is_jewelry=1"
if "!%~1.category_id!"=="%TV_RING%" set "is_jewelry=1"
if "!%~1.category_id!"=="%TV_STAFF%" set "is_magic=1"
if "!%~1.category_id!"=="%TV_WAND%" set "is_magic=1"
if "!%~1.category_id!"=="%TV_DIGGING%" set "is_dig=1"

if not "!is_cursed!"=="0" (
    set "value=0"
) else if "!is_weapon!"=="1" (
    call :getWeaponArmorBuyPrice "%~1"
    set "value=!errorlevel!"
) else if "!is_ammo!"=="1" (
    call :getAmmoBuyPrice "%~1"
    set "value=!errorlevel!"
) else if "!is_potion!"=="1" (
    call :getPotionScrollBuyPrice "%~1"
    set "value=!errorlevel!"
) else if "!is_food!"=="1" (
    call :getFoodBuyPrice "%~1"
    set "value=!errorlevel!"
) else if "!is_jewelry!"=="1" (
    call :getRingAmuletBuyPrice "%~1"
    set "value=!errorlevel!"
) else if "!is_magic!"=="1" (
    call :getWandStaffBuyPrice "%~1"
    set "value=!errorlevel!"
) else if "!is_dig!"=="1" (
    call :getPickShovelBuyPrice "%~1"
    set "value=!errorlevel!"
) else (
    set "value=!%~1.cost!"
)

:: Multiply value by number of items if it is a group stack item
:: Not torches, since those are bundled
if !%~1.sub_category_id! GTR %ITEM_GROUP_MIN% set /a value*=!%~1.items_count!
for %%A in (is_weapon is_ammo is_potion is_food is_jewelry is_magic is_dig) do set "%%A="
exit /b !value!

::------------------------------------------------------------------------------
:: Gets the price for weapons and armor
::
:: Arguments: %~1 - A reference to the item being sold
:: Returns:   The price of the weapon or armor
::------------------------------------------------------------------------------
:getWeaponArmorBuyPrice
set "i_id=!%~1.id!"
call identification.cmd :spellItemIdentified "%~1" || exit /b !game_objects[%i_id%].cost!

if !%~1.category_id! GEQ %TV_BOW% if !%~1.category_id! LEQ %TV_SWORD% (
    for %%A in (to_hit to_damage to_ac) do if !%~1.%%A! LSS 0 exit /b 0
    
    set /a "real_cost=!%~1.cost! + (!%~1.to_hit! + !%~1.to_damage! + !%~1.to_ac!) * 100"
    exit /b !real_cost!
)

if !%~1.to_ac! LSS 0 exit /b 0

set /a real_cost=!%~1.cost! + !%~1.to_ac! * 100
exit /b !real_cost!

::------------------------------------------------------------------------------
:: Gets the price for ammo like arrows and bolts
::
:: Arguments: %1 - A reference to the item being sold
:: Returns:   The price of the ammo
::------------------------------------------------------------------------------
:getAmmoBuyPrice
set "i_id=!%~1.id!"
call identification.cmd :spellItemIdentified "%~1" || exit /b !game_objects[%i_id%].cost!
for %%A in (to_hit to_damage to_ac) do if !%~1.%%A! LSS 0 exit /b 0

:: Multiply by 5 instead of 100 because ammo comes in packs of 20
set /a real_cost=!%~1.cost! + (!%~1.to_hit! + !%~1.to_damage! + !%~1.to_ac!) * 5
exit /b !real_cost!

::------------------------------------------------------------------------------
:: Gets the price for potions and scrolls
::
:: Arguments: %1 - A reference to the item being sold
:: Returns:   The price of the potion or scroll
::------------------------------------------------------------------------------
:getPotionScrollBuyPrice
call identification.cmd :itemSetColorlessAsIdentified "!%~1.category_id!" "!%~1.sub_category_id!" "!%~1.identification!"
if "!errorlevel!"=="1" exit /b 20
exit /b !%~1.cost!

::------------------------------------------------------------------------------
:: Gets the price for food
::
:: Arguments: %1 - A reference to the item being sold
:: Returns:   The price of the food
::------------------------------------------------------------------------------
:getFoodBuyPrice
if !%~1.sub_category_id! LSS 86 (
    call identification.cmd :itemSetColorlessAsIdentified "!%~1.category_id!" "!%~1.sub_category_id!" "!%~1.identification!"
    if "!errorlevel!"=="1" exit /b 1
)
exit /b !%~1.cost!

::------------------------------------------------------------------------------
:: Gets the price for a ring or amulet
::
:: Arguments: %1 - A reference to the item being sold
:: Returns:   The price of the ring or amulet
::------------------------------------------------------------------------------
:getRingAmuletBuyPrice
call identification.cmd :itemSetColorlessAsIdentified "!%~1.category_id!" "!%~1.sub_category_id!" "!%~1.identification!"
if "!errorlevel!"=="1" exit /b 45

set "i_id=!%~1.id!"
call identification.cmd :spellItemIdentified "%~1" || exit !game_objects[%i_id%].cost!
exit /b !%~1.cost!

::------------------------------------------------------------------------------
:: Gets the price for wands and staffs
::
:: Arguments: %1 - A reference to the item being sold
:: Returns:   The price of the wand or staff
::------------------------------------------------------------------------------
:getWandStaffBuyPrice
call identification.cmd :itemSetColorlessAsIdentified "!%~1.category_id!" "!%~1.sub_category_id!" "!%~1.identification!"
if "!errorlevel!"=="1" (
    if "!%~1.category_id!"=="%TV_WAND%" exit /b 50
    exit /b 70
)

call identification.cmd :spellItemIdentified "%~1" 
if "!errorlevel!"=="0" (
    set /a "real_cost=!%~1.cost! + (!%~1.cost! / 20) * !%~1.misc_use!"
    exit /b !real_cost!
)
exit /b !%~1.cost!

::------------------------------------------------------------------------------
:: Gets the price of picks and shovels
::
:: Arguments: %1 - A reference to the item being sold
:: Returns:   The price of the picks and shovels
::------------------------------------------------------------------------------
:getPickShovelBuyPrice
set "i_id=!%~1.id!"
call identification.cmd :spellItemIdentified "%~1" || exit /b !game_objects[%i_id%].cost!
if !%~1.misc_use! LSS 0 exit /b 0

set /a real_cost=!%~1.cost!+(!%~1.misc_use! * !game_objects[%i_id%].misc_use!) * 100
if !real_cost! LSS 0 set "real_cost=0"
exit /b !real_cost!

::------------------------------------------------------------------------------
:: Gets the price range for an item
::
:: Arguments: %1 - The store that the player is at
::            %2 - A variable to store the min valid price of the item
::            %3 - A variable to store the max valid price of the item
::            %4 - A reference to the item being sold
:: Returns:   The initial asking price for the item
::------------------------------------------------------------------------------
:storeItemSellPrice
call :storeItemValue "%~1"
set "price=!errorlevel!"

:: Cursed and damaged items will not be sold
if !%item%.cost! LSS 1 exit /b 0
if %price% LSS 1 exit /b 0

set "s_id=!%~1.owner_id!"
set "owner=store_owners[%s_id%]"
set "owner_race=!%owner!.race!"

set /a price=%price% * !race_gold_adjustments[%owner_race%][%py.misc.race_id%]! / 100
if %price% LSS 1 set "price=1"

set /a %~2=%price% * !%owner%.min_inflate! / 100
set /a %~3=%price% * !%owner%.max_inflate! / 100

if !%~2! GTR !%~3! set "%~2=!%~3!"
exit /b !price!

::------------------------------------------------------------------------------
:: Prevent the player from becoming overencumbered as a result of a purchase
::
:: Arguments: %1 - A reference to the store that the player is in
::            %2 - A reference to the item being bought
:: Returns:   0 if the player can hold the new item
::            1 if there is no more room at the inn-ventory
::------------------------------------------------------------------------------
:storeCheckPlayerItemsCount
if !%~1.unique_items_counter! LSS %STORE_MAX_DISCRETE_ITEMS% exit /b 0
call inventory.cmd :inventoryItemStackable "%~2" || exit /b 1

set "store_check=1"
set /a store_dec=!%~1.unique_items_counter!-1
for /L %%A in (0,1,%store_dec%) do (
    if "!%~1.inventory[%%A].item.category_id!"=="!%~2.category_id!" (
        if "!%~1.inventory[%%A].item.sub_category_id!"=="!%~2.sub_category_id!" (
            set /a potential_total_items=!%~1.inventory[%%A].items_count!+!%~2.items_count!
            if !potential_total_items! LSS 256 (
                if !%~2.sub_category_id! LSS %ITEM_GROUP_MIN% set "store_check=0"
                if "!%~1.inventory[%%A].item.misc_use!"=="!%~2.misc_use!" set "store_check=0"
            )
        )
    )
)
exit /b !store_check!

::------------------------------------------------------------------------------
:: Insert an item into the store's inventory at a specified location
::
:: Arguments: %1 - The store_id of the current store
::            %2 - The position to store the item at
::            %3 - The value of the item
::            %4 - The item being sold
:: Returns:   None
::------------------------------------------------------------------------------
:storeItemInsert
set "store=stores[%~1]"
set /a item_dec=!%store%.unique_items_counter!-1
for /L %%A in (%item_dec%,-1,%~2) do (
    set /a item_inc=%%A+1
    call :copyStoreInventoryItem "%store%.inventory[!item_inc!]" "%store%.inventory[%%A]"
)
call inventory.cmd :inventoryCopyItem "%store%.inventory[%~2].item" "%~4"
set /a %store%.inventory[%~2].cost=%~3*-1
set /a %store%.unique_items_counter+=1
exit /b

::------------------------------------------------------------------------------
:: Adds an item to the store's inventory
::
:: Arguments: %1 - The store_id of the current store
::            %2 - A variable to store the index of the item in the store's
::                 inventory
::            %3 - A reference to the item being sold
:: Returns:   None
::------------------------------------------------------------------------------
:storeCarryItem
set "index_id=-1"
set "store=stores[%~1]"

call :storeItemSellPrice "%store%" "dummy" "item_cost" "%~4" && exit /b

set "item_id=0"
set "flag=false"

:storeCarryItemWhileLoop
set "store_item=store.inventory[%item_id%].item"

if "!%~3.category_id!"=="!%store_item%.category_id!" (
    if "!%~3.sub_category_id!"=="!%store_item%.sub_category_id!" (
        if !%~3.sub_category_id! GEQ %ITEM_SINGLE_STACK_MIN% (
            set "itemable=0"
            if !%~3.sub_category_id! LSS %ITEM_GROUP_MIN% set "itemable=1"
            if "!%store_item%.misc_use!"=="!%~3.misc_use!" set "itemable=1"
            if "!itemable!"=="1" (
                set "index_id=%item_id%"
                set /a %store_item%.items_count+=!%~3.items_count!

                if !%~3.sub_category_id! GTR %ITEM_GROUP_MIN% (
                    call :storeItemSellPrice "%store%" "dummy" "item_cost" "%store_item%"
                    set /a %store%.inventory[%item_id%]=!item_cost!*-1
                ) else if !%store_item%.items_count! GTR 24 (
                    set "%store_item%.items_count=24"
                )
                set "flag=true"
            )
        )
    )
) else if !%~3.category_id! GTR !%store_item%.category_id! (
    call :storeItemInsert "%~1" "%item_id%" "!item_cost!" "%~3"
    set "flag=true"
    set "index_id=!item_id!"
)
set /a item_id+=1
if !item_id! LSS !%store%.unique_items_counter! (
    if "!flag!"=="false" (
        goto :storeCarryItemWhileLoop
    )
)

if "!flag!"=="false" (
    call :storeItemInsert "%~1" "!%store%.unique_items_counter!" "!item_cost!" "%~3"
    set /a index_id=!%store%.unique_items_counter!-1
)
exit /b

::------------------------------------------------------------------------------
:: Destroys one item in the store's inventory or the entire slot if %3 is false
::
:: Arguments: %1 - The store_id of the current store
::            %2 - The item_id of the item being destroyed
::            %3 - True if only one instance of the item should be destroyed
::                 False if all instances of the item should be destroyed
:: Returns:   None
::------------------------------------------------------------------------------
:storeDestroyItem
set "store=stores[%~1]"
set "store_item=%store%.inventory[%~2].item"

call inventory.cmd :inventoryItemSingleStackable "%store_item%"
if "!errorlevel!"=="0" (
    if "%~3"=="true" (
        set "number=1"
    ) else (
        call rng.cmd :randomNumber !%store_item%.items_count!
        set "number=!errorlevel!"
    )
) else (
    set "number=!%store_item%.items_count!"
)

if not "!number!"=="!%store_item%.items_count!" (
    set /a %store_item%.items_count-=!number!
) else (
    set /a item_dec=!%store%.unique_items_counter!-1
    for /L %%A in (%~2,1,!item_dec!) do (
        set /a item_inc=%%A+1
        call :copyStoreInventoryItem "%store%.inventory[%%A]" "%store%.inventory[!item_inc!]"
    )
    call inventory.cmd :inventoryItemCopyTo "%config.dungeon.objects.OBJ_NOTHING%" "%store%.inventory[!item_dec!].item"
    set /a %store%.inventory[!item_dec!].cost=0
    set /a %store%.unique_items_counter-=1
)
exit /b

::------------------------------------------------------------------------------
:: Creates an item and inserts it into the store's inventory
::
:: Arguments: %1 - The store_id of the current store
::            %2 - The maximum cost of the item
:: Returns:   None
::------------------------------------------------------------------------------
:storeItemCreate
call game_objects.cmd :popt
set "free_id=!errorlevel!"

for /L %%A in (0,1,3) do (
    call rng.cmd :randomNumber %STORE_MAX_ITEM_TYPES%
    set /a rnd_dec=!errorlevel!-1
    for /f "delims=" %%B in ("!rnd_dec!") do set "id=!store_choices[%~1][%%~B]!"
    call inventory.cmd :inventoryItemCopyTo "!id!" "game.treasure.list[%free_id%]"
    call treasure.cmd :magicTreasureMagicalAbility "%free_id%" "%config.treasure.LEVEL_TOWN_OBJECTS%"

    call :storeCheckPlayerItemsCount "stores[%~1]" "game.treasure.list[%free_id%]"
    if !game.treasure.list[%free_id%].cost! GTR 0 (
        if !game.treasure.list[%free_id%].cost! LSS %~2 (
            call identification.cmd :itemIdentifyAsStoreBought "game.treasure.list[%free_id%]"
            call :storeCarryItem "%~1" "dummy" "game.treasure.list[%free_id%]"
            
            goto :storeItemCreateAfterForLoop
        )
    )
)

:storeItemCreateAfterForLoop
call game_objects.cmd :pusht "%free_id%"
exit /b

::------------------------------------------------------------------------------
:: Copies one Store_Inventory item into another one
::
:: Arguments: %1 - The inventory item to copy values into
::            %2 - The inventory item to copy values from
:: Returns:   None
::------------------------------------------------------------------------------
:copyStoreInventoryItem
for %%T in (id special_name_id inscription flags category_id sprite misc_use
            cost sub_category_id items_count weight to_hit to_damage ac to_ac
            damage.dice damage.sides depth_first_found identification) do (
    set "%~1.item.%%T=!%~2.item.%%T"
)
set "%~1.cost=!%~2.cost!"
exit /b