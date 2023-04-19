call %*
exit /b

::------------------------------------------------------------------------------
:: Removes an item from the player's inventory when it is thrown
::
:: Arguments: %1 - The index of the inventory item to throw
::            %2 - The variable to store the thrown item in
::------------------------------------------------------------------------------
:inventoryThrow
set "item=py.inventory[%~1]"
call inventory.cmd :inventoryCopyItem "%~2" "%item%"

if !%item%.items_count! GTR 1 (
    set %~2.items_count=1
    set /a %item%.items_count-=1
    set /a py.pack.weight-=!%item%.weight!
    set /a "py.flags.status|=%config.player.status.py_str_wgt%"
) else (
    call inventory.cmd :inventoryDestroyItem "%~1"
)
exit /b

::------------------------------------------------------------------------------
:: Obtain the hit bonus, damage bonus, and maximum distance for a thrown item
::
:: Arguments: %1 - A reference to the item being thrown
::            %2 - A reference to the item's base-to-hit
::            %3 - A reference to the item's plus-to-hit
::            %4 - A reference to the item's damage
::            %5 - A reference to the item's max distance
:: Returns:   None
::------------------------------------------------------------------------------
:weaponMissileFacts
set "weight=!%~1.weight!"
if %weight% LSS 1 set "weight=1"

call dice.cmd :diceRoll !%~1.damage!
set /a "%~4=!errorlevel!+!%~1.to_damage!"
set /a "%~2=%py.misc.bth_with_bows% * 75 / 100"
set /a "%~3=%py.misc.plusses_to_hit% + !%~1.to_hit!"

if not "!py.inventory[%PlayerEquipment.Wield%].category_id!"=="!TV_NOTHING!" (
    set /a "%~3-=!py.inventory[%PlayerEquipment.Wield%].to_hit!"
)

set /a "%~5=((!py.stats.used[%PlayerAttr.a_str%] + 20) * 10) / %weight%"
if %~5 GTR 10 set "%~5=10"

:: Make sure that the player is using bows, slings, or crossbows
if not "!py.inventory[%PlayerEquipment.Wield%].category_id!"=="!TV_BOW!" exit /b

if "!py.inventory[%PlayerEquipment.Wield%].misc_use!"=="1" (
    REM Slings
    if "!%~1.category_id!"=="%TV_SLING_AMMO%" (
        set "%~2=%py.misc.bth_with_bows%"
        set /a "%~3+=2 * !py.inventory[%PlayerEquipment.Wield%].to_hit!"
        set /a "%~4+=!py.inventory[%PlayerEquipment.Wield%].to_damage!"
        set /a "%~4*=2"
        set "%~5=20"
    )
) else if "!py.inventory[%PlayerEquipment.Wield%].misc_use!"=="2" (
    REM Short bows
    if "!%~1.category_id!"=="%TV_ARROW%" (
        set "%~2=%py.misc.bth_with_bows%"
        set /a "%~3+=2 * !py.inventory[%PlayerEquipment.Wield%].to_hit!"
        set /a "%~4+=!py.inventory[%PlayerEquipment.Wield%].to_damage!"
        set /a "%~4*=2"
        set "%~5=25"
    )
) else if "!py.inventory[%PlayerEquipment.Wield%].misc_use!"=="3" (
    REM Long bows
    if "!%~1.category_id!"=="%TV_ARROW%" (
        set "%~2=%py.misc.bth_with_bows%"
        set /a "%~3+=2 * !py.inventory[%PlayerEquipment.Wield%].to_hit!"
        set /a "%~4+=!py.inventory[%PlayerEquipment.Wield%].to_damage!"
        set /a "%~4*=3"
        set "%~5=30"
    )
) else if "!py.inventory[%PlayerEquipment.Wield%].misc_use!"=="4" (
    REM Composite bows
    if "!%~1.category_id!"=="%TV_ARROW%" (
        set "%~2=%py.misc.bth_with_bows%"
        set /a "%~3+=2 * !py.inventory[%PlayerEquipment.Wield%].to_hit!"
        set /a "%~4+=!py.inventory[%PlayerEquipment.Wield%].to_damage!"
        set /a "%~4*=4"
        set "%~5=35"
    )
) else if "!py.inventory[%PlayerEquipment.Wield%].misc_use!"=="5" (
    REM Light crossbow
    if "!%~1.category_id!"=="%TV_BOLT%" (
        set "%~2=%py.misc.bth_with_bows%"
        set /a "%~3+=2 * !py.inventory[%PlayerEquipment.Wield%].to_hit!"
        set /a "%~4+=!py.inventory[%PlayerEquipment.Wield%].to_damage!"
        set /a "%~4*=3"
        set "%~5=25"
    )
) else if "!py.inventory[%PlayerEquipment.Wield%].misc_use!"=="6" (
    REM Heavy crossbow
    if "!%~1.category_id!"=="%TV_BOLT%" (
        set "%~2=%py.misc.bth_with_bows%"
        set /a "%~3+=2 * !py.inventory[%PlayerEquipment.Wield%].to_hit!"
        set /a "%~4+=!py.inventory[%PlayerEquipment.Wield%].to_damage!"
        set /a "%~4*=4"
        set "%~5=35"
    )
)
exit /b

::------------------------------------------------------------------------------
:: Try to place an item on a random nearby tile. If there is no space, the item
:: simply disappears into the void.
::
:: Arguments: %1 - The initial coordinates for the placement
::            %2 - The item to dispose of
:: Returns:   None
::------------------------------------------------------------------------------
:inventoryDropOrThrowItem
for /f "tokens=1,2 delims=;" %%A in ("%~1") do (
    set /a "position.y=%%~A", "coord.y=%%~A"
    set /a "position.x=%%~B", "coord.x=%%~B"
)
set "position=!position.y!;!position.x!"
set "flag=false"

call rng.cmd :randomNumber 10
if !errorlevel! GTR 1 (
    set "k=0"
    call :placeAtRandomTile
)

if "!flag!"=="true" (
    call game_objects.cmd :popt
    set "cur_pos=!errorlevel!"
    set dg.floor[%position.y%][%position.x%].treasure_id=!cur_pos!
    call inventory.cmd :inventoryCopyItem "game.treasure.list[!cur_pos!]" "%~2"
    call dungeon.cmd :dungeonLiteSpot "position"
) else (
    call identification.cmd :itemDescription "description" "%~2" "false"
    call ui_io.cmd :printMessage "The !description! disappears."
)
exit /b

:placeAtRandomTile
if "!flag!"=="true" exit /b
if !k! GTR 9 exit /b

set "position=!position.y!;!position.x!"
call dungeon.cmd :coordInBounds position
if !dg.floor[%position.y%][%position.x%].feature_id! LEQ %max_open_space% (
    if "!dg.floor[%position.y%][%position.x%].treasure_id!"=="0" (
        set "flag=true"
    )
)

if "!flag!"=="false!" (
    call rng.cmd :randomNumber 3
    set "position.y=%coord.y%+!errorlevel!-2"
    call rng.cmd :randomNumber 3
    set "position.x=%coord.x%+!errorlevel!-2"
)
set /a k+=1
goto :placeAtRandomTile

::------------------------------------------------------------------------------
:: Throw an item across the dungeon
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerThrowItem
if "%py.pack.unique_items%"=="0" (
    call ui_io.cmd :printMessage "But you are not carrying anything."
    set "game.player_free_turn=true"
    exit /b
)

set /a counter_dec=%py.pack.unique_items%-1
call ui_inventory.cmd :inventoryGetInputForItemId item_id "Fire/Throw which one?" 0 %counter_dec% "CNIL" "CNIL" || exit /b
call game.cmd :getDirectionWithMemory "CNIL" direction || exit /b
call identification.cmd :itemTypeRemainingCountDescription !item_id!

if %py.flags.confused% GTR 0 (
    call ui_io.cmd :printMessage "You are confused."
    call game.cmd :getRandomDirection
    set "direction=!errorlevel!"
)

call :inventoryThrow !item_id! "thrown_item"
call :weaponMissileFacts "thrown_item" "tbth" "tpth" "tdam" "tdis"

set "tile_char=!thrown_item.sprite!"
set "current_distance=0"
set "coord.y=%py.pos.y%"
set "coord.x=%py.pos.x%"
set "old_coord.y=%py.pos.y%"
set "old_coord.x=%py.pos.x%"

set "flag=false"
:playerThrowItemWhileLoop
if "!flag!"=="true" exit /b

set "coord=!coord.y!;!coord.x!"
set "old_coord=!old_coord.y!;!old_coord.x!"
call player.cmd :playerMovePosition !direction! "coord"
set /a current_distance+=1
call dungeon.cmd :dungeonLiteSpot "old_coord"

if !current_distance! GTR !tdis! set "flag=true"

set "tile=dg.floor[%coord.y%][%coord.x%]"
if !%tile%.feature_id! LEQ %max_open_space% (
    if "!flag!"=="false" (
        if !%tile%.creature_id! GTR 1 (
            set "flag=true"
            for /f "delims=" %%A in ("!%tile%.creature_id!") do (
                set "m_ptr.creature_id=!monsters[%%A].creature_id!"
                set "m_ptr.lit=!monsters[%%A].lit!"
            )

            set /a tbth-=!current_distance!
            if "!m_ptr.lit!"=="false" (
                set /a "tbth/=!current_distance!+2"
                set /a "tbth-=%py.misc.level% * !class_level_adj[%py.misc.class_id%][%PlayerClassLevelAdj.BTHB%]! / 2"
                set /a "tbth-=!tpth! * (%bth_per_plus_to_hit_adjust% - 1)"
            )

            for /f "delims=" %%A in ("!m_ptr.creature_id!") do set "c_ac=!creatures_list[%%~A].ac!"
            call player.cmd :playerTestBeingHit !tbth! %py.misc.level% !tpth! !c_ac! %PlayerClassLevelAdj.BTHB%
            if "!errorlevel!"=="0" (
                set "damage=!m_ptr.creature_id!"
                call identification.cmd :itemDescription "" "thrown_item" "false"

                REM Are we firing blindly?
                if "!m_ptr.lit!"=="false" (
                    set "msg=You hear a cry as the !description! finds a mark."
                    set "visible=false"
                ) else (
                    for /f "delims=" %%A in ("!damage!") do set "msg=The !description! hits the !creatures_list[%%A].name!"
                    set "visible=true"
                )
                call ui_io.cmd :printMessage "!msg!"

                call player_magic.cmd :itemMagicAbilityDamage "thrown_item" !tdam! !damage!
                set "tdam=!errorlevel!"
                REM TODO: figure out if this even works
                call player.cmd :playerWeaponCriticalBlow !thrown_item.weight! !tpth! !tdam! %PlayerClassLevelAdj.bthb%
                set "tdam=!errorlevel!"

                if !tdam! LSS 0 set "tdam=0"
                call monster.cmd :monsterTakeHit !tile.creature_id! !tdam!
                set "damage=!errorlevel!"

                if !damage! GEQ 0 (
                    if "!visible!"=="false" (
                        call ui_io.cmd :printMessage "You have killed... something..."
                    ) else (
                        for /f "delims=" %%A in ("!damage!") do call ui_io.cmd :printMessage "You have killed the !creatures_list[%%~A].name!"
                    )
                    call ui.cmd :displayCharacterExperience
                )
            ) else (
                call :inventoryDropOrThrowItem "!old_coord!" "thrown_item"
            )
        )
    )
) else (
    set "flag=true"
    call :inventoryDestroyItem "!old_coord!" "thrown_item"
)

set "old_coord.y=!coord.y!"
set "old_coord.x=!coord.x!"
goto :playerThrowItemWhileLoop