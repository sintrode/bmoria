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
:: Selects an arbitrary piece of equipment and checks to see if it is cursed
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

::------------------------------------------------------------------------------
:: Enchants a weapon with bonuses to improve chance of weapon hitting
::
:: Arguments: None
:: Returns:   0 if an item was supposed to be enchanted
::            1 if the player tried to enchant nothing
::------------------------------------------------------------------------------
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

::------------------------------------------------------------------------------
:: Pretty much just :scrollEnchantWeaponToHit but with more chances to
:: successfully enchant the weapon.
:: TODO: Determine if needed
:: 
:: Arguments: None
:: Returns:   0 if an item was supposed to be enchanted
::            1 if the player tried to enchant nothing
::------------------------------------------------------------------------------
:scrollEnchantWeapon
set "item=py.inventory[%PlayerEquipment.wield%]"

if "!%item%.category_id!"=="%TV_NOTHING%" exit /b 1

call identification.cmd :itemDescription "desc" "%item%" "false"
call ui_io.cmd :printMessage "Your %desc% glows faintly."

set "enchanted=false"
call rng.cmd :randomNumber 2
for /L %%A in (1,1,!errorlevel!) do (
    call spells.cmd :spellEnchantItem "%item%.to_hit" 10
    if "!errorlevel!"=="0" set "enchanted=true"
)

set "scroll_type=10"
if !%item%.category_id! GEQ %TV_HAFTED% (
    if !%item%.category_id! LEQ %TV_DIGGING% (
        call dice.cmd :maxDiceRoll !%item%.damage.dice! !%item%.damage.sides!
        set "scroll_type=!errorlevel!"
    )
)

call rng.cmd :randomNumber 2
for /L %%A in (1,1,!errorlevel!) do (
    call spells.cmd :spellEnchantItem "%item%.to_damage" %scroll_type%
    if "!errorlevel!"=="0" set "enchanted=true"
)
if "%enchanted%"=="true" (
    call inventory.cmd :inventoryItemRemoveCurse "%item%"
    call player.cmd :playerRecalculateBonuses
) else (
    call ui_io.cmd :printMessage "The enchantment failed."
)
exit /b 0

::------------------------------------------------------------------------------
:: Curses a weapon, lowering its to_hit and damage
::
:: Arguments: None
:: Returns:   0 if an item was supposed to be cursed
::            1 if the player tried to curse nothing
::------------------------------------------------------------------------------
:scrollCurseWeapon
set "item=py.inventory[%PlayerEquipment.Wield%]"
if "!%item%.category_id!"=="%TV_NOTHING%" exit /b 1

call identification.cmd :itemDescription "desc" "%item%" "false"
call ui_io.cmd :printMessage "Your %desc% glows black and fades."
call identification.cmd :itemRemoveMagicNaming "%item%"

call rng.cmd :randomNumber 5
set "to_hit_dec=-!errorlevel!"
call rng.cmd :randomNumber 5
set /a to_hit_dec-=!errorlevel!
set /a %item%.to_hit-=%to_hit_dec%
call rng.cmd :randomNumber 5
set "to_damage_dec=-!errorlevel!"
call rng.cmd :randomNumber 5
set /a to_damage_dec-=!errorlevel!
set /a %item%.to_damage-=%to_damage_dec%
set "%item%.to_ac=0"

set "to_hit_dec="
set "to_damage_dec="

call player.cmd :playerAdjustBonusesForItem "%item%" "-1"
set "%item%.flags=%config.treasure.flags.tr_cursed%"
call player.cmd :playerRecalculateBonuses
exit /b 0

::------------------------------------------------------------------------------
:: Removes any curses from armor and boosts its AC
::
:: Arguments: None
:: Returns:   0 if an item was supposed to be enchanted
::            1 if the player tried to enchant nothing
::------------------------------------------------------------------------------
:scrollEnchantArmor
call :inventoryItemIdOfCursedEquipment
set "item_id=!errorlevel!"
if %item_id% LEQ 0 exit /b 1

set "item=py.inventory[%item_id%]"
call identification.cmd :itemDescription "desc" "%item%" "false"
call ui_io.cmd :printMessage "Your %desc% glows brightly."

set "enchanted=false"
call rng.cmd :randomNumber 2
for /L %%A in (1,1,!errorlevel!) do (
    call spells.cmd :spellEnchantItem "%item%.to_ac" 10
    if "!errorlevel!"=="0" set "enchanted=true"
)

if "%enchanted%"=="true" (
    call inventory.cmd :inventoryItemRemoveCurse "%item%"
    call player.cmd :playerRecalculateBonuses
) else (
    call ui_io.cmd :printMessage "The enchantment failed."
)
exit /b 0

::------------------------------------------------------------------------------
:: Adds a curse to armor to lower its AC
::
:: Arguments: None
:: Returns:   0 if an item was supposed to be cursed
::            1 if the player attempted to curse nothing
::------------------------------------------------------------------------------
:scrollCurseArmor
set "item_id=0"

:: TODO: Determine if this needs to be changed to randomly select armor
if "!py.inventory[%PlayerEquipment.Body%].category_id!"=="%TV_NOTHING%" (
    set "item_id=%PlayerEquipment.Body%"
) else if "!py.inventory[%PlayerEquipment.Arm%].category_id!"=="%TV_NOTHING%" (
    set "item_id=%PlayerEquipment.Arm%"
) else if "!py.inventory[%PlayerEquipment.Outer%].category_id!"=="%TV_NOTHING%" (
    set "item_id=%PlayerEquipment.Outer%"
) else if "!py.inventory[%PlayerEquipment.Head%].category_id!"=="%TV_NOTHING%" (
    set "item_id=%PlayerEquipment.Head%"
) else if "!py.inventory[%PlayerEquipment.Hands%].category_id!"=="%TV_NOTHING%" (
    set "item_id=%PlayerEquipment.Hands%"
) else if "!py.inventory[%PlayerEquipment.Feet%].category_id!"=="%TV_NOTHING%" (
    set "item_id=%PlayerEquipment.Feet%"
) else (
    set "item_id=0"
)
if %item_id% LEQ 0 exit /b 1

set "item=py.inventory[%item_id%]"
call identification.cmd :itemDescription "desc" "%item%" "false"
call ui_io.cmd :printMessage "Your %desc% glows black and fades."

call identification.cmd :itemRemoveMagicNaming "%item%"

set "%item%.flags=%config.treasure.flags.tr_cursed%"
set "%item%.to_hit=0"
set "%item%.to_damage=0"
call rng.cmd :randomNumber 5
set "to_ac_dec=-!errorlevel!"
call rng.cmd :randomNumber 5
set /a to_ac_dec-=!errorlevel!
set /a %item%.to_ac-=%to_ac_dec%
set "to_ac_dec="

call player.cmd :playerRecalculateBonuses
exit /b 0

::------------------------------------------------------------------------------
:: It's just :scrollSummonMonster but with :monsterSummonUndead instead
:: TODO: Merge the two :scrollSummon____ subroutines
::
:: Arguments: None
:: Returns:   0 if an undead monster was summoned and identified
::            1 if no monster was summoned or identified
::------------------------------------------------------------------------------
:scrollSummonUndead
set "identified=0"
call rng.cmd :randomNumber 3
for /L %%A in (1,1,!errorlevel!) do (
    set "coord=%py.pos.y%;%py.pos.x%"
    call monster_manager.cmd :monsterSummonUndead "coord" "false"
    set /a "identified|=!errorlevel!"
)

:: Because *SOMEONE* decided that true should be 1 but success is errorlevel 0...
if "!identified!"=="1" exit /b 0
exit /b 1

::------------------------------------------------------------------------------
:: Adds between 26 and 55 charges to the Word of Recall flag if it is zero
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:scrollWordOfRecall
if "%py.flags.word_of_recall%"=="0" (
    call rng.cmd :randomNumber 30
    set /a py.flags.word_of_recall=!errorlevel!+25
)
call ui_io.cmd :printMessage "The air about you becomes charged."
exit /b

::------------------------------------------------------------------------------
:: A wrapper subroutine for reading scrolls
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:scrollRead
set "game.player_free_turn=true"
call :playerCanReadScroll "item_pos_start" "item_pos_end" || exit /b
call ui_inventory.cmd :inventoryGetInputForItemId "item_id" "Read which scroll?" %item_pos_start% %item_pos_end% "CNIL" "CNIL" || exit /b

set "game.player_free_turn=true"
set "used_up=true"
set "identified=false"

set "item=py.inventory[%item_id%]"
set "item_flags=!%item%.flags!"

:scrollReadWhileLoop
if "!item_flags!"=="0" goto :scrollReadAfterWhileLoop
call helpers.cmd :getAndClearFirstBit "item_flags"
set /a scroll_type=!errorlevel!+1

if "!%item%.category_id!"=="%TV_SCROLL2%" set /a scroll_type+=32

if "%scroll_type%"=="1" (
    call :scrollEnchantWeaponToHit
    set "identified=!errorlevel!"
    goto :scrollReadWhileLoop
) else if "%scroll_type%"=="2" (
    call :scrollEnchantWeaponToDamage
    set "identified=!errorlevel!"
    goto :scrollReadWhileLoop
) else if "%scroll_type%"=="3" (
    call :scrollEnchantItemToAC
    set "identified=!errorlevel!"
    goto :scrollReadWhileLoop
) else if "%scroll_type%"=="4" (
    call :scrollIdentifyItem "%item_id%" "used_up"
    set "item_id=!errorlevel!"
    set "identified=0"
    goto :scrollReadWhileLoop
) else if "%scroll_type%"=="5" (
    call :scrollRemoveCurse
    set "identified=!errorlevel!"
    goto :scrollReadWhileLoop
) else if "%scroll_type%"=="6" (
    call spells.cmd :spellLightArea "%py.pos%"
    set "identified=!errorlevel!"
    goto :scrollReadWhileLoop
) else if "%scroll_type%"=="7" (
    call :scrollSummonMonster
    set "identified=!errorlevel!"
    goto :scrollReadWhileLoop
) else if "%scroll_type%"=="8" (
    REM Phase Door
    call player.cmd :playerTeleport 10
    set "identified=0"
    goto :scrollReadWhileLoop
) else if "%scroll_type%"=="9" (
    call player.cmd :playerTeleport 100
    set "identified=0"
    goto :scrollReadWhileLoop
) else if "%scroll_type%"=="10" (
    call :scrollTeleportLevel
    set "identified=0"
    goto :scrollReadWhileLoop
) else if "%scroll_type%"=="11" (
    call :scrollConfuseMonster
    set "identified=!errorlevel!"
    goto :scrollReadWhileLoop
) else if "%scroll_type%"=="12" (
    call spells.cmd :spellMapCurrentArea
    set "identified=0"
    goto :scrollReadWhileLoop
) else if "%scroll_type%"=="13" (
    call monster.cmd :monsterSleep "%py.pos%"
    set "identified=!errorlevel!"
    goto :scrollReadWhileLoop
) else if "%scroll_type%"=="14" (
    call spells.cmd :spellWardingGlyph
    set "identified=0"
    goto :scrollReadWhileLoop
) else if "%scroll_type%"=="15" (
    call spells.cmd :spellDetectTreasureWithinVicinity
    set "identified=!errorlevel!"
    goto :scrollReadWhileLoop
) else if "%scroll_type%"=="16" (
    call spells.cmd :spellDetectObjectsWithinVicinity
    set "identified=!errorlevel!"
    goto :scrollReadWhileLoop
) else if "%scroll_type%"=="17" (
    call spells.cmd :spellDetectTrapsWithinVicinity
    set "identified=!errorlevel!"
    goto :scrollReadWhileLoop
) else if "%scroll_type%"=="18" (
    call spells.cmd :spellDetectSecretDoorsWithinVicinity
    set "identified=!errorlevel!"
    goto :scrollReadWhileLoop
) else if "%scroll_type%"=="19" (
    call ui_io.cmd :printMessage "This is a mass genocide scroll."
    call spells.cmd :spellMassGenocide
    set "identified=0"
    goto :scrollReadWhileLoop
) else if "%scroll_type%"=="20" (
    call spells.cmd :spellDetectInvisibleCreaturesWithinVicinity
    set "identified=!errorlevel!"
    goto :scrollReadWhileLoop
) else if "%scroll_type%"=="21" (
    call ui_io.cmd :printMessage "There is a high-pitched humming noise."
    call spells.cmd :spellAggravateMonsters 20
    set "identified=0"
    goto :scrollReadWhileLoop
) else if "%scroll_type%"=="22" (
    call spells.cmd :spellSurroundPlayerWithTraps
    set "identified=!errorlevel!"
    goto :scrollReadWhileLoop
) else if "%scroll_type%"=="23" (
    call spells.cmd :spellDestroyAdjacentDoorsTraps
    set "identified=!errorlevel!"
    goto :scrollReadWhileLoop
) else if "%scroll_type%"=="24" (
    call spells.cmd :spellSurroundPlayerWithDoors
    set "identified=!errorlevel!"
    goto :scrollReadWhileLoop
) else if "%scroll_type%"=="25" (
    call ui_io.cmd :printMessage "This is a Recharge-Item scroll."
    call spells.cmd :spellRechargeItem 60
    set "used_up=!errorlevel!"
    set "identified=0"
    goto :scrollReadWhileLoop
) else if "%scroll_type%"=="26" (
    call ui_io.cmd :printMessage "This is a genocide scroll."
    call spells.cmd :spellGenocide
    set "identified=0"
    goto :scrollReadWhileLoop
) else if "%scroll_type%"=="27" (
    call spells.cmd :spellDarkenArea "%py.pos%"
    set "identified=!errorlevel!"
    goto :scrollReadWhileLoop
) else if "%scroll_type%"=="28" (
    call player_magic.cmd :playerProtectEvil
    set "identified=!errorlevel!"
    goto :scrollReadWhileLoop
) else if "%scroll_type%"=="29" (
    call spells.cmd :spellCreateFood
    set "identified=!errorlevel!"
    goto :scrollReadWhileLoop
) else if "%scroll_type%"=="30" (
    call spells.cmd :spellDispelCreature "%config.monsters.defense.cd_undead%" 60
    set "identified=!errorlevel!"
    goto :scrollReadWhileLoop
) else if "%scroll_type%"=="33" (
    call :scrollEnchantWeapon
    set "identified=!errorlevel!"
    goto :scrollReadWhileLoop
) else if "%scroll_type%"=="34" (
    call :scrollCurseWeapon
    set "identified=!errorlevel!"
    goto :scrollReadWhileLoop
) else if "%scroll_type%"=="35" (
    call :scrollEnchantArmor
    set "identified=!errorlevel!"
    goto :scrollReadWhileLoop
) else if "%scroll_type%"=="36" (
    call :scrollCurseArmor
    set "identified=!errorlevel!"
    goto :scrollReadWhileLoop
) else if "%scroll_type%"=="37" (
    call :scrollSummonUndead
    set "identified=!errorlevel!"
    goto :scrollReadWhileLoop
) else if "%scroll_type%"=="38" (
    call rng.cmd :randomNumber 12
    set /a bless_num=!errorlevel!+6
    call player_magic.cmd :playerBless !bless_num!
    set "identified=0"
    set "bless_num="
    goto :scrollReadWhileLoop
) else if "%scroll_type%"=="39" (
    call rng.cmd :randomNumber 24
    set /a bless_num=!errorlevel!+12
    call player_magic.cmd :playerBless !bless_num!
    set "identified=0"
    set "bless_num="
    goto :scrollReadWhileLoop
) else if "%scroll_type%"=="40" (
    call rng.cmd :randomNumber 48
    set /a bless_num=!errorlevel!+24
    call player_magic.cmd :playerBless !bless_num!
    set "identified=0"
    set "bless_num="
    goto :scrollReadWhileLoop
) else if "%scroll_type%"=="41" (
    call :scrollWordOfRecall
    set "identified=0"
    goto :scrollReadWhileLoop
) else if "%scroll_type%"=="42" (
    call spells.cmd :spellDestroyArea "%py.pos%"
    set "identified=!errorlevel!"
    goto :scrollReadWhileLoop
) else (
    call ui_io.cmd :printMessage "Internal error in scrolls.cmd"
    goto :scrollReadWhileLoop
)

:scrollReadAfterWhileLoop
set "item=py.inventory[%item_id%]"

if "!identified!"=="true" (
    call identification.cmd :itemSetColorlessAsIdentified "!%item%.category_id!" "!%item%.sub_category_id!" "!%item%.identification!"
    if "!errorlevel!"=="1" (
        set /a "py.misc.exp+=(!%item%.depth_first_found! + (%py.misc.level% >> 1)) / %py.misc.level%"
        call ui.cmd :displayCharacterExperience
        call identification.cmd :itemIdentify "py.inventory[%item_id%]" "item_id"
    )
) else (
    call identification.cmd :itemSetColorlessAsIdentified "!%item%.category_id!" "!%item%.sub_category_id!" "!%item%.identification!"
    if "!errorlevel!"=="1" (
        call identification.cmd :itemSetAsTried "%item%"
    )
)

if "%used_up%"=="true" (
    call identification.cmd :itemTypeRemainingCountDescription "%item_id%"
    call inventory.cmd :inventoryDestroyItem "%item_id%"
)
exit /b