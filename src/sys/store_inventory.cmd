@echo off
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

:getPickShovelBuyPrice
exit /b

:storeItemSellPrice
exit /b

:storeCheckPlayerItemsCount
exit /b

:storeItemInsert
exit /b

:storeCarryItem
exit /b

:storeDestroyItem
exit /b

:storeItemCreate
exit /b

