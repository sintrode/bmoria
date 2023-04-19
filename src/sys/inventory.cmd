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

    call identification.cmd :itemDescription prt1 "game.treasure.list[!treasure_id!]" "true"
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

::------------------------------------------------------------------------------
:: Reduces the amount of light available by the light-providing item
::
:: Arguments: %1 - Indicates if the player noticed that the light dimmed or not
:: Returns:   0 if the player sees that the light dimmed
::            1 if the player did not see the light dim
::------------------------------------------------------------------------------
:inventoryDiminishLightAttack
set "noticed=%~1"
if !py.inventory[%PlayerEquipment.Light%]! GTR 0 (
    call rng.cmd :randomNumber 250
    set /a py.inventory[%PlayerEquipment.Light%].misc_use-=250+!errorlevel!

    if !py.inventory[%PlayerEquipment.Light%].misc_use! LSS 1 (
        set "py.inventory[%PlayerEquipment.Light%].misc_use=1"
    )

    if %py.flags.blind% LSS 1 (
        call ui_io.cmd :printMessage "Your light dims."
    ) else (
        set "noticed=false"
    )
) else (
    set "noticed=false"
)

:: ah, the pains of using a string to simulate a boolean...
if "!noticed!"=="true" exit /b 0
exit /b 1

::------------------------------------------------------------------------------
:: Reduces the number of available charges and increases a monster's HP
::
:: Arguments: %1 - The level of the creature draining the item's energy
::            %2 - A reference to the monster's HP
::            %3 - Determines if the player noticed energy being taken
:: Returns:   0 if the player gets informed about the drain
::            1 if the drain happens silently
::------------------------------------------------------------------------------
:inventoryDiminishChargesAttack
call rng.cmd :randomNumber %py.pack.unique_items%
set /a rnd_item=!errorlevel!-1
set "item=py.inventory[%rnd_item%]"

set "has_charges=false"
if "!%item%.category_id!"=="%tv_staff%" set "has_charges=true"
if "!%item%.category_id!"=="%tv_wand%"  set "has_charges=true"

if "%has_charges%"=="true" (
    if !%item%.misc_use! GTR 0 (
        set /a !%~2!+=%~1*!%item%.misc_use!
        set "%item%.misc_use=0"

        call identification.cmd :spellItemIdentified "%item%" || (
            call identification.cmd :itemAppendToInscription "%item%" "%config.identification.id_empty%"
        )
        call ui_io.cmd :printMessage "Energy drains from your pack."
    ) else (
        set "noticed=false"
    )
)
if "!noticed!"=="true" exit /b 0
exit /b 1

::------------------------------------------------------------------------------
:: Removes the enchantment from a random wielded item
::
:: Arguments: None
:: Returns:   0 if to_hit, to_damage, or to_ac is reduced
::            1 if there is nothing to reduce
::------------------------------------------------------------------------------
:executeDisenchantAttack
call rng.cmd :randomNumber 7
set "rnd_item=!errorlevel!"

if "!rnd_item!"=="1" set "item_id=%PlayerEquipment.Wield%"
if "!rnd_item!"=="2" set "item_id=%PlayerEquipment.Body%"
if "!rnd_item!"=="3" set "item_id=%PlayerEquipment.Arm%"
if "!rnd_item!"=="4" set "item_id=%PlayerEquipment.Outer%"
if "!rnd_item!"=="5" set "item_id=%PlayerEquipment.Hands%"
if "!rnd_item!"=="6" set "item_id=%PlayerEquipment.Head%"
if "!rnd_item!"=="7" set "item_id=%PlayerEquipment.Feet%"

set "success=1"
set "item=py.inventory[%item_id%]"

for %%A in (to_hit to_damage to_ac) do (
    if !%item%.%%A! GTR 0 (
        call rng.cmd :randomNumber 2
        set /a %item%.%%A-=!errorlevel!
        if !%item%.%%A! LSS 0 set "%item%.%%A=0"
        set "success=0"
    )
)
exit /b !success!

::------------------------------------------------------------------------------
:: Determine if picking up an object would change the player's speed
::
:: Arguments: %1 - A reference to the item to pick up
:: Returns:   0 if this item makes the pack too heavy to move
::            1 if this item can be picked up without effort
::------------------------------------------------------------------------------
:inventoryCanCarryItem
call player.cmd :playerCarryingLoadLimit
set "limit=!errorlevel!"
set /a new_weight=!%~1.items_count!*!%~1.weight!+%py.pack.weight%

if !limit! LSS !new_weight! (
    set /a "limit=!new_weight!/(!limit!+1)"
) else (
    set "limit=0"
)

if "%py.pack.heaviness%"=="!limit!" exit /b 0
exit /b 1

::------------------------------------------------------------------------------
:: Tries to pick up an item and stack it in the inventory. The C code insists
:: that this code needs to be identical to :inventoryCarryItem for some reason.
:: This will likely get purged during the second pass rewrite.
::
:: Arguments: %1 - A reference to the item being picked up
:: Returns:   0 if the item being picked up is stacked with others like it
::            1 if the item is different from the rest of the inventory
::------------------------------------------------------------------------------
:inventoryCanCarryItemCount
if %py.pack.unique_items% LSS %PlayerEquipment.Wield% exit /b 0
call :inventoryItemStackable %1 || exit /b 1

set /a counter_dec=%py.pack.unique_items%-1
for /L %%A in (0,1,!counter_dec!) do (
    set "same_character=false"
    set "same_category=false"
    set "same_number=false"
    set "same_group=false"
    set "identification=false"

    if "!py.inventory[%%A].category_id!"=="!%~1.category_id!" set "same_character=true"
    if "!py.inventory[%%A].sub_category_id!"=="!%~1.sub_category_id!" set "same_category=true"
    
    set /a new_item_total=!py.inventory[%%A].items_count!+!%~1.items_count!
    if !new_item_total! LSS 256 set "same_number=true"

    call identification.cmd :itemSetColorlessAsIdentified !py.inventory[%%A].category_id! !py.inventory[%%A].sub_category_id! !py.inventory[%%A].identification!
    set "inventory_item_is_colorless=!errorlevel!"
    call identification.cmd :itemSetColorlessAsIdentified !%~1.category_id! !%~1.sub_category_id! !%~1.identification!
    set "item_is_colorless=!errorlevel!"
    if "!inventory_item_is_colorless!"=="!item_is_colorless!" set "identification=true"

    if "!same_character!"=="true" (
        if "!same_category!"=="true" (
            if "!same_number!"=="true" (
                if "!same_group!"=="true" (
                    if "!identification!"=="true" (
                        exit /b 0
                    )
                )
            )
        )
    )
)
exit /b 1

::------------------------------------------------------------------------------
:: Picks up an item and adds it to the inventory, returning the item position
:: for a description if needed.  The C code insists that this code needs to be
:: identical to :inventoryCarryItemCount for some reason.
::
:: Arguments: %1 - A reference to the item being picked up
:: Returns:   The index of py.inventory that the item is stored in
::------------------------------------------------------------------------------
:inventoryCarryItem
call identification.cmd :itemSetColorlessAsIdentified !%~1.category_id! !%~1.sub_category_id! !%~1.identification!
set "is_known=!errorlevel!"
set "is_always_known=false"
call identification.cmd :objectPositionOffset !%~1.category_id! !%~1.sub_category_id!
if "!errorlevel!"=="-1" set "is_always_known=true"

set "is_same_category=false"
set "is_same_sub_category=false"
set "not_too_many_items=false"
set "same_known_status=false"
set "is_stackable=false"
set "is_same_group=false"

set /a counter_dec=%player_inventory_size%-1
for /L %%A in (0,1,!counter_dec!) do (
    set "slot_id=%%A"
    if "!%~1.category_id!"=="!py.inventory[%%A].category_id!" set "is_same_category=true"
    if "!%~1.sub_category_id!"=="!py.inventory[%%A].sub_category_id!" set "is_same_sub_category=true"
    set /a new_item_total=!%~1.items_count!+!py.inventory[%%A].items_count!
    if !new_item_total! LSS 256 set "not_too_many_items=true"

    call identification.cmd :itemSetColorlessAsIdentified !py.inventory[%%A].category_id! !py.inventory[%%A].sub_category_id! !py.inventory[%%A].identification!
    call :inventoryItemStackable %1 && set "is_stackable=true"
    if "!is_known!"=="!errorlevel!" set "same_known_status=true"
    if !%~1.sub_category_id! LSS %item_group_min% set "is_same_group=true"
    if "!%~1.misc_use!"=="!py.inventory[%%A].misc_use!" set "is_same_group=true"

    set "add_item=0"
    for %%B in (is_same_category is_same_sub_category is_stackable not_too_many_items is_same_group same_known_status) do (
        if "!%%B!"=="true" set /a add_item+=1
    )
    if "!add_item!"=="6" (
        set /a py.inventory[%%A].items_count+=!%~1.items_count!
        goto :inventoryCarryItemAfterLoop
    )

    set "add_item=0"
    if "!is_same_category!"=="true" (
        if !%~1.sub_category_id! LSS !py.inventory[%%A].sub_category_id! (
            if "!is_always_known!"=="true" (
                set "add_item=1"
            )
        )
    )
    if !%~1.category_id! GTR !py.inventory[%%A].category_id! set "add_item=1"

    if "!add_item!"=="1" (
        set /a counter_dec=%py.pack.unique_items%-1
        for /L %%B in (!counter_dec!,-1,%%A) do (
            set /a counter_inc=%%B+1
            call :inventoryCopyItem "py.inventory[!counter_inc!]" "py.inventory[%%B]"
        )
        call :inventoryCopyItem "py.inventory[%%A]" "%~1"
        set /a py.pack.unique_items+=1
        goto :inventoryCarryItemAfterLoop
    )
)

:inventoryCarryItemAfterLoop
set /a py.pack.weight+=!%~1.items_count!*!%~1.weight!
set /a "py.flags.status|=%config.player.status.py.str_wgt%"
exit /b !slot_id!

::------------------------------------------------------------------------------
:: Sets the start and end indices for a range of items in the inventory
::
:: Arguments: %1 - The start of the range to search
::            %2 - The end of the range to search
::            %3 - A reference to the start of the found range
::            %4 - A reference to the end of the found range
:: Returns:   0 if there is an item at either end of the given range
::            1 if the item is not in the given range
::------------------------------------------------------------------------------
:inventoryFindRange
set "%~3=-1"
set "%~4=-1"

set "at_end_of_range=false"
set /a counter_dec=%py.pack.unique_items%-1
for /L %%A in (0,1,!counter_dec!) do (
    set "item_id=!py.inventory[%%A].category_id!"

    if "!at_end_of_range!"=="false" (
        if "!item_id!"=="%~1" (
            set "at_end_of_range=true"
            set "%~3=%%A"
        )
        if "!item_id!"=="%~2" (
            set "at_end_of_range=true"
            set "%~3=%%A"
        )
    ) else (
        if not "!item_id!"=="%~1" (
            if not "!item_id!"=="%~2" (
                set /a %~4=%%A-1
                goto :inventoryFindRangeAfterLoop
            )
        )
    )
)

:inventoryFindRangeAfterLoop
if "!at_end_of_range!"=="true" (
    if "!%~4!"=="-1" (
        set k=!counter_dec!
    )
)

if "!at_end_of_range!"=="true" exit /b 0
exit /b 1

::------------------------------------------------------------------------------
:: Copies an item from the game_objects array to the inventory
::
:: Arguments: %1 - The ID of the item to copy
::            %2 - A reference to the item being copied to
:: Returns:   None
::------------------------------------------------------------------------------
:inventoryItemCopyTo
set "from=game_objects[%~1]"

set "%~2.id=%~1"
set "%~2.special_name_id=%SpecialNameIds.sn_null%"
set "%~2.inscription="
for %%A in (category_id sprite misc_use cost sub_category_id items_count
            weight to_hit to_damage ac to_ac "damage.dice" "damage.sides"
            depth_first_found) do (
    set "%~2.%%A=!%game%.%%A!"
)
set "%~2.identification=0"
exit /b

::------------------------------------------------------------------------------
:: Checks if a single item is stackable
::
:: Arguments: %1 - A reference to the item being checked
:: Returns:   0 if the item can be stacked
::            1 if the item can not be stacked
::------------------------------------------------------------------------------
:inventoryItemSingleStackable
if !%~1.sub_category_id! GEQ %item_single_stack_min% (
    if !%~1.sub_category_id! LEQ %item_single_stack_max% (
        exit /b 0
    )
)
exit /b 1

::------------------------------------------------------------------------------
:: Checks if an item or group of items is stackable
::
:: Arguments: %1 - A reference to the item being checked
:: Returns:   0 if the item can be stacked
::            1 if the item can not be stacked
::------------------------------------------------------------------------------
:inventoryItemStackable
if !%~1.sub_category_id! GEQ %item_single_stack_min% (
    exit /b 0
)
exit /b 1

::------------------------------------------------------------------------------
:: Checks if an item is cursed
::
:: Arguments: %1 - A reference to the item being checked
:: Returns:   0 if the item is cursed
::            1 if the item is not cursed
::------------------------------------------------------------------------------
:inventoryItemIsCursed
set /a "is_cursed=!%~1.flags! & %config.treasure.flags.tr_cursed%"
if "!is_cursed!"=="0" exit /b 1
exit /b 0

::------------------------------------------------------------------------------
:: Removes any curse on a specified item
::
:: Arguments: %1 - A reference to the item being decursed
:: Returns:   None
::------------------------------------------------------------------------------
:inventoryItemRemoveCurse
set /a "%~1.flags&=~%config.treasure.flags.tr_cursed%"
exit /b

::------------------------------------------------------------------------------
:: Reduces the AC of a random equipped item
::
:: Arguments: %1 - The type of damage resistance to reduce
:: Returns:   0 if a random item's AC has been reduced
::            1 if there was no AC to reduce
::------------------------------------------------------------------------------
:damageMinusAC
set "items_count=0"
if not "!py.inventory[%PlayerEquipment.Body%].category_id!"=="%TV_NOTHING%" (
    set "items[!items_count!]=%PlayerEquipment.Body%"
    set /a items_count+=1
)
if not "!py.inventory[%PlayerEquipment.Arm%].category_id!"=="%TV_NOTHING%" (
    set "items[!items_count!]=%PlayerEquipment.Arm%"
    set /a items_count+=1
)
if not "!py.inventory[%PlayerEquipment.Outer%].category_id!"=="%TV_NOTHING%" (
    set "items[!items_count!]=%PlayerEquipment.Outer%"
    set /a items_count+=1
)
if not "!py.inventory[%PlayerEquipment.Hands%].category_id!"=="%TV_NOTHING%" (
    set "items[!items_count!]=%PlayerEquipment.Hands%"
    set /a items_count+=1
)
if not "!py.inventory[%PlayerEquipment.Head%].category_id!"=="%TV_NOTHING%" (
    set "items[!items_count!]=%PlayerEquipment.Head%"
    set /a items_count+=1
)
if not "!py.inventory[%PlayerEquipment.Feet%].category_id!"=="%TV_NOTHING%" (
    set "items[!items_count!]=%PlayerEquipment.Feet%"
    set /a items_count+=1
)

set "minus=1"
if "!items_count!"=="0" exit /b 1

call rng.cmd :randomNumber !items_count!
set /a counter_dec=!errorlevel!-1
set "item_id=!items[%counter_dec%]!"
set "description="

set /a "correct_damage_type=!py.inventory[%item_id%].flags!&%~1"
set /a total_ac=!py.inventory[%item_id%].ac!+!py.inventory[%item_id%].to_ac!

if !correct_damage_type! NEQ 0 (
    set "minus=0"
    call identification.cmd :itemDescription description "py.inventory[%item_id%]" "false"
    call ui_io.cmd :printMessage "Your !description! resists damage."
) else if !total_ac! GTR 0 (
    set "minus=0"
    call identification.cmd :itemDescription description "py.inventory[%item_id%]" "false"
    call ui_io.cmd :printMessage "Your !description! is damaged."
    set /a py.inventory[%item_id%].to_ac-=1
    call player.cmd :playerRecalculateBonuses
)
exit /b !minus!

::------------------------------------------------------------------------------
:: This function exists to emulate the original Pascal code and will be removed
:: during the second pass rewrite.
:: TODO: Remove references to this subroutine in spells.cmd
::
:: Arguments: %1 - Ignored
:: Returns:   1
::------------------------------------------------------------------------------
:setNull
exit /b 1

::------------------------------------------------------------------------------
:: Determines which items can be damaged by corroding gas
::
:: Arguments: %1 - A reference to the item to check
:: Returns:   0 if the item can be damaged by corroding gas
::            1 if the item is uncorrodable
::------------------------------------------------------------------------------
:setCorrodableItems
set "is_weak=1"
if "!%~1.category_id!"=="%tv_sword%"      set "is_weak=0"
if "!%~1.category_id!"=="%tv_helm%"       set "is_weak=0"
if "!%~1.category_id!"=="%tv_shield%"     set "is_weak=0"
if "!%~1.category_id!"=="%tv_hard_armor%" set "is_weak=0"
if "!%~1.category_id!"=="%tv_wand%"       set "is_weak=0"
exit /b %is_weak%

::------------------------------------------------------------------------------
:: Determines which items are flammable
::
:: Arguments: %1 - A reference to the item to check
:: Returns:   0 if the item can be damaged by flame
::            1 if the item is fireproof
::------------------------------------------------------------------------------
:setFlammableItems
set "is_weak=1"
set /a "resists=!%~1.flags! & %config.treasure.flags.tr_res_fire%"

if "!%~1.category_id!"=="%tv_arrow%"      set "is_weak=%resists%"
if "!%~1.category_id!"=="%tv_bow%"        set "is_weak=%resists%"
if "!%~1.category_id!"=="%tv_hafted%"     set "is_weak=%resists%"
if "!%~1.category_id!"=="%tv_polearm%"    set "is_weak=%resists%"
if "!%~1.category_id!"=="%tv_boots%"      set "is_weak=%resists%"
if "!%~1.category_id!"=="%tv_gloves%"     set "is_weak=%resists%"
if "!%~1.category_id!"=="%tv_cloak%"      set "is_weak=%resists%"
if "!%~1.category_id!"=="%tv_soft_armor%" set "is_weak=%resists%"

if "!%~1.category_id!"=="%tv_staff%"      set "is_weak=0"
if "!%~1.category_id!"=="%tv_scroll1%"    set "is_weak=0"
if "!%~1.category_id!"=="%tv_scroll2%"    set "is_weak=0"
exit /b %is_weak%

::------------------------------------------------------------------------------
:: Determines if an item can be destroyed by acid
::
:: Arguments: %1 - A reference to the item to check for dissolvability
:: Returns:   0 if the item can be dissolved by acid
::            1 if the item is resistant to being dissolved
::------------------------------------------------------------------------------
:setAcidAffectedItems
set "is_weak=1"
set /a "resists=!%~1.flags! & %config.treasure.flags.tr_res_acid%"

if "!%~1.category_id!"=="%TV_BOLT%"       set "is_weak=%resists%"
if "!%~1.category_id!"=="%TV_ARROW%"      set "is_weak=%resists%"
if "!%~1.category_id!"=="%TV_BOW%"        set "is_weak=%resists%"
if "!%~1.category_id!"=="%TV_HAFTED%"     set "is_weak=%resists%"
if "!%~1.category_id!"=="%TV_POLEARM%"    set "is_weak=%resists%"
if "!%~1.category_id!"=="%TV_BOOTS%"      set "is_weak=%resists%"
if "!%~1.category_id!"=="%TV_GLOVES%"     set "is_weak=%resists%"
if "!%~1.category_id!"=="%TV_CLOAK%"      set "is_weak=%resists%"
if "!%~1.category_id!"=="%TV_SOFT_ARMOR%" set "is_weak=%resists%"

if "!%~1.category_id!"=="%TV_MISC%"       set "is_weak=0"
if "!%~1.category_id!"=="%TV_CHEST%"      set "is_weak=0"
exit /b %is_weak%

::------------------------------------------------------------------------------
:: Determines if an item on the ground can be destroyed by frost
::
:: Arguments: %1 - A reference to the item to check for shatterability
:: Returns:   0 for potions and flasks
::            1 if the item is not made of glass
::------------------------------------------------------------------------------
:setFrostDestroyableItems
set "is_weak=1"
if "!%~1.category_id!"=="%TV_POTION1%"    set "is_weak=0"
if "!%~1.category_id!"=="%TV_POTION2%"    set "is_weak=0"
if "!%~1.category_id!"=="%TV_FLASK%"      set "is_weak=0"
exit /b %is_weak%

::------------------------------------------------------------------------------
:: Determines if an item on the ground can be destroyed by lightning
:: No idea why swords, armor, and shields are unaffected by this
::
:: Arguments: %1 - A reference to the item to check for conductivity
:: Returns:   0 for rings, wands, and spikes
::            1 if the item is not made of magic metal
::------------------------------------------------------------------------------
:setLightningDestroyableItems
set "is_weak=1"
if "!%~1.category_id!"=="%TV_RING%"       set "is_weak=0"
if "!%~1.category_id!"=="%TV_WAND%"       set "is_weak=0"
if "!%~1.category_id!"=="%TV_SPIKE%"      set "is_weak=0"
exit /b %is_weak%

::------------------------------------------------------------------------------
:: Determines if an item on the ground can be destroyed by acid
::
:: Arguments: %1 - A reference to the item to check for dissolvability
:: Returns:   0 if the item can be dissolved in acid
::            1 if the item will not dissolve
::------------------------------------------------------------------------------
:setAcidDestroyableItems
set "is_weak=1"
set /a "resists=!%~1.flags! & %config.treasure.flags.tr_res_acid%"

if "!%~1.category_id!"=="%TV_ARROW%"       set "is_weak=%resists%"
if "!%~1.category_id!"=="%TV_BOW%"         set "is_weak=%resists%"
if "!%~1.category_id!"=="%TV_HAFTED%"      set "is_weak=%resists%"
if "!%~1.category_id!"=="%TV_POLEARM%"     set "is_weak=%resists%"
if "!%~1.category_id!"=="%TV_BOOTS%"       set "is_weak=%resists%"
if "!%~1.category_id!"=="%TV_GLOVES%"      set "is_weak=%resists%"
if "!%~1.category_id!"=="%TV_CLOAK%"       set "is_weak=%resists%"
if "!%~1.category_id!"=="%TV_HELM%"        set "is_weak=%resists%"
if "!%~1.category_id!"=="%TV_SHIELD%"      set "is_weak=%resists%"
if "!%~1.category_id!"=="%TV_HARD_ARMOR%"  set "is_weak=%resists%"
if "!%~1.category_id!"=="%TV_SOFT_ARMOR%"  set "is_weak=%resists%"

if "!%~1.category_id!"=="%TV_STAFF%"       set "is_weak=0"
if "!%~1.category_id!"=="%TV_SCROLL1%"     set "is_weak=0"
if "!%~1.category_id!"=="%TV_SCROLL2%"     set "is_weak=0"
if "!%~1.category_id!"=="%TV_FOOD%"        set "is_weak=0"
if "!%~1.category_id!"=="%TV_OPEN_DOOR%"   set "is_weak=0"
if "!%~1.category_id!"=="%TV_CLOSED_DOOR%" set "is_weak=0"
exit /b %is_weak%

::------------------------------------------------------------------------------
:: Determines if an item on the ground can be destroyed by fire
::
:: Arguments: %1 - A reference to the item to check for flammability
:: Returns:   0 if the item can be burned
::            1 if the item is fireproof
::------------------------------------------------------------------------------
:setFireDestroyableItems
set "is_weak=1"
set /a "resists=!%~1.flags! & %config.treasure.flags.tr_res_fire%"

if "!%~1.category_id!"=="%TV_ARROW%"       set "is_weak=%resists%"
if "!%~1.category_id!"=="%TV_BOW%"         set "is_weak=%resists%"
if "!%~1.category_id!"=="%TV_HAFTED%"      set "is_weak=%resists%"
if "!%~1.category_id!"=="%TV_POLEARM%"     set "is_weak=%resists%"
if "!%~1.category_id!"=="%TV_BOOTS%"       set "is_weak=%resists%"
if "!%~1.category_id!"=="%TV_GLOVES%"      set "is_weak=%resists%"
if "!%~1.category_id!"=="%TV_CLOAK%"       set "is_weak=%resists%"
if "!%~1.category_id!"=="%TV_SOFT_ARMOR%"  set "is_weak=%resists%"

if "!%~1.category_id!"=="%TV_STAFF%"       set "is_weak=0"
if "!%~1.category_id!"=="%TV_SCROLL1%"     set "is_weak=0"
if "!%~1.category_id!"=="%TV_SCROLL2%"     set "is_weak=0"
if "!%~1.category_id!"=="%TV_POTION1%"     set "is_weak=0"
if "!%~1.category_id!"=="%TV_POTION2%"     set "is_weak=0"
if "!%~1.category_id!"=="%TV_FLASK%"       set "is_weak=0"
if "!%~1.category_id!"=="%TV_FOOD%"        set "is_weak=0"
if "!%~1.category_id!"=="%TV_OPEN_DOOR%"   set "is_weak=0"
if "!%~1.category_id!"=="%TV_CLOSED_DOOR%" set "is_weak=0"
exit /b %is_weak%

::------------------------------------------------------------------------------
:: Blows corroding gas onto the player - not to be confused with poison gas
::
:: Arguments: %1 - The creature doing the damage
:: Returns:   None
::------------------------------------------------------------------------------
:damageCorrodingGas
call :damageMinusAC %config.treasure.flags.tr_res_acid% || (
    call rng.cmd :randomNumber 8
    call player.cmd :playerTakesHit !errorlevel! "%~1"
)

call :inventoryDamageItem "setCorrodableItems" 5
if !errorlevel! GTR 0 (
    call ui_io.cmd :printMessage "There is an acrid smell coming from your pack."
)
exit /b

::------------------------------------------------------------------------------
:: Blows poison gas onto the player - not to be confused with corroding gas
::
:: Arguments: %1 - The amount of damage done to the player
::            %2 - The creature doing the damage
:: Returns:   None
::------------------------------------------------------------------------------
:damagePoisonedGas
call player.cmd :playerTakesHit %*
call rng.cmd :randomNumber %~1
set /a py.flags.poisoned+=12+!errorlevel!
exit /b

::------------------------------------------------------------------------------
:: Hits the player with fire
::
:: Arguments: %1 - The amount of damage done to the player
::            %2 - The creature doing the damage
:: Returns:   None
::------------------------------------------------------------------------------
:damageFire
set "damage=%~1"
if "%py.flags.resistant_to_fire%"=="true" set /a damage/=3
if %py.flags.heat_resistance% GTR 0 set /a damage/=3

call player.cmd :playerTakesHit !damage! "%~2"

call :inventoryDamageItem "setFlammableItems" 3
if !errorlevel! GTR 0 (
    call ui_io.cmd :printMessage "There is smoke coming from your pack."
)
exit /b

::------------------------------------------------------------------------------
:: Hits the player with frost
::
:: Arguments: %1 - The amount of damage done to the player
::            %2 - The creature doing the damage
:: Returns:   None
::------------------------------------------------------------------------------
:damageCold
set "damage=%~1"
if "%py.flags.resistant_to_cold%"=="true" set /a damage/=3
if %py.flags.cold_resistance% GTR 0 set /a damage/=3

call player.cmd :playerTakesHit !damage! "%~2"

call :inventoryDamageItem "setFrostDestroyableItems" 3
if !errorlevel! GTR 0 (
    call ui_io.cmd :printMessage "Something shatters inside your pack."
)
exit /b

::------------------------------------------------------------------------------
:: Hits the player with a lightning bolt
::
:: Arguments: %1 - The amount of damage done to the player
::            %2 - The creature doing the damage
:: Returns:   None
::------------------------------------------------------------------------------
:damageLightningBolt
set "damage=%~1"
if "%py.flags.resistant_to_light%"=="true" set /a damage/=3

call player.cmd :playerTakesHit !damage! "%~2"

call :inventoryDamageItem "setLightningDestroyableItems" 3
if !errorlevel! GTR 0 (
    call ui_io.cmd :printMessage "There are sparks coming from your pack."
)
exit /b

::------------------------------------------------------------------------------
:: Throws acid on the player, either via monster or trap
::
:: Arguments: %1 - The amount of base damage to do to the player
::            %2 - The creature doing the damage
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
            damage.dice damage.sides depth_first_found identification) do (
    set "%~1.%%T=!%~2.%%T"
)
exit /b