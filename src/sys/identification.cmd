@echo off
call %*
exit /b

::------------------------------------------------------------------------------
:: Returns a description of a map object based on the specified symbol
::
:: Arguments: %1 - The symbol to identify
::            %2 - The variable to store the description in
:: Returns:   None
::------------------------------------------------------------------------------
:objectDescription
if "%~1"==" " (
    set "%~2=  - An open pit."
) else if "%~1"=="!" (
    set "%~2=^^^! - A potion."
) else if "%~1"=="^"" (
    set "%~2=^^^" - An amulet, periapt, or necklace."
) else if "%~1"=="#" (
    set "%~2=# - A stone wall."
) else if "%~1"=="$" (
    set "%~2=$ - Treasure"
) else if "%~1"=="%%" (
    if "%config.options.highlight_seams%"=="false" (
        set "%~2=%% - Not used."
    ) else (
        set "%~2=%% - A magma or quartz vein."
    )
) else if "%~1"=="^&" (
    set "%~2=^^^& - Treasure chest."
) else if "%~1"=="'" (
    set "%~2=' - An open door."
) else if "%~1"=="(" (
    set "%~2=( - Soft armor."
) else if "%~1"==")" (
    set "%~2=) - A shield."
) else if "%~1"=="*" (
    set "%~2=* - Gems."
) else if "%~1"=="+" (
    set "%~2=+ - A closed door."
) else if "%~1"=="," (
    set "%~2=, - Foor or mushroom patch"
) else if "%~1"=="-" (
    set "%~2=- - A wand."
) else if "%~1"=="." (
    set "%~2=. - Floor."
) else if "%~1"=="/" (
    set "%~2=/ - A pole weapon."
) else if "%~1"=="1" (
    set "%~2=1 - Entrance to General Store."
) else if "%~1"=="2" (
    set "%~2=2 - Entrance to Armory."
) else if "%~1"=="3" (
    set "%~2=3 - Entrance to Weaponsmith."
) else if "%~1"=="4" (
    set "%~2=4 - Entrance to Temple."
) else if "%~1"=="5" (
    set "%~2=5 - Entrance to Alchemy Shop."
) else if "%~1"=="6" (
    set "%~2=6 - Entrance to Magic-User's Shop."
) else if "%~1"==":" (
    set "%~2=^: - Rubble."
) else if "%~1"==";" (
    set "%~2=; - A loose rock."
) else if "%~1"=="<" (
    set "%~2=^^^< - An up staircase."
) else if "%~1"=="=" (
    set "%~2=^= - A ring."
) else if "%~1"==">" (
    set "%~2=^^^> - A down staircase."
) else if "%~1"=="@" (
    set "%~2=@ - %py.misc.name%"
) else if "%~1"=="A" (
    set "%~2=A - Giant Ant Lion."
) else if "%~1"=="B" (
    set "%~2=B - The Balrog."
) else if "%~1"=="C" (
    set "%~2=C - Gelatinous Cube."
) else if "%~1"=="D" (
    set "%~2=D - An Ancient Dragon ^(Beware^)."
) else if "%~1"=="E" (
    set "%~2=E - Elemental."
) else if "%~1"=="F" (
    set "%~2=F - Giant Fly."
) else if "%~1"=="G" (
    set "%~2=G - Ghost."
) else if "%~1"=="H" (
    set "%~2=H - Hobgoblin."
) else if "%~1"=="J" (
    set "%~2=J - Jelly."
) else if "%~1"=="K" (
    set "%~2=K - Killer Beetle."
) else if "%~1"=="L" (
    set "%~2=L - Lich."
) else if "%~1"=="M" (
    set "%~2=M - Mummy."
) else if "%~1"=="O" (
    set "%~2=O - Ooze."
) else if "%~1"=="P" (
    set "%~2=P - Giant humanoid."
) else if "%~1"=="Q" (
    set "%~2=Q - Quylthulg ^(Pulsing Flesh Mound^)."
) else if "%~1"=="R" (
    set "%~2=R - Reptile."
) else if "%~1"=="S" (
    set "%~2=S - Giant Scorpion."
) else if "%~1"=="T" (
    set "%~2=T - Troll."
) else if "%~1"=="U" (
    set "%~2=U - Umber Hulk."
) else if "%~1"=="V" (
    set "%~2=V - Vampire."
) else if "%~1"=="W" (
    set "%~2=W - Wight or Wraith."
) else if "%~1"=="X" (
    set "%~2=X - Xorn."
) else if "%~1"=="Y" (
    set "%~2=Y - Yeti."
) else if "%~1"=="[" (
    set "%~2=[ - Hard armor."
) else if "%~1"=="\" (
    set "%~2=\ - A hafted weapon."
) else if "%~1"=="]" (
    set "%~2=] - Misc. armor."
) else if "%~1"=="^" (
    set "%~2=^ - A trap."
) else if "%~1"=="_" (
    set "%~2=_ - A staff."
) else if "%~1"=="a" (
    set "%~2=a - Giant Ant."
) else if "%~1"=="b" (
    set "%~2=b - Giant Bat."
) else if "%~1"=="c" (
    set "%~2=c - Giant Centipede."
) else if "%~1"=="d" (
    set "%~2=d - Dragon."
) else if "%~1"=="e" (
    set "%~2=e - Floating Eye."
) else if "%~1"=="f" (
    set "%~2=f - Giant Frog."
) else if "%~1"=="g" (
    set "%~2=g - Golem."
) else if "%~1"=="h" (
    set "%~2=h - Harpy."
) else if "%~1"=="i" (
    set "%~2=i - Icky Thing."
) else if "%~1"=="j" (
    set "%~2=j - Jackal."
) else if "%~1"=="k" (
    set "%~2=k - Kobold."
) else if "%~1"=="l" (
    set "%~2=l - Giant Louse."
) else if "%~1"=="m" (
    set "%~2=m - Mold."
) else if "%~1"=="n" (
    set "%~2=n - Naga."
) else if "%~1"=="o" (
    set "%~2=o - Orc or Ogre."
) else if "%~1"=="p" (
    set "%~2=p - Person ^(Humanoid^)."
) else if "%~1"=="q" (
    set "%~2=q - Quasit."
) else if "%~1"=="r" (
    set "%~2=r - Rodent."
) else if "%~1"=="s" (
    set "%~2=s - Skeleton."
) else if "%~1"=="t" (
    set "%~2=t - Giant Tick."
) else if "%~1"=="w" (
    set "%~2=w - Worm or Worm Mass."
) else if "%~1"=="y" (
    set "%~2=y - Yeek."
) else if "%~1"=="z" (
    set "%~2=z - Zombie."
) else if "%~1"=="{" (
    set "%~2={ - Arrow, bolt, or bullet."
) else if "%~1"=="^|" (
    set "%~2=^^^| - A sword or dagger."
) else if "%~1"=="}" (
    set "%~2=} - Bow, crossbow, or sling."
) else if "%~1"=="~" (
    set "%~2=^~ - Miscellaneous item."
) else (
    set "%~2=Not used."
)
exit /b

::------------------------------------------------------------------------------
:: Identifies a specified character
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:identifyGameObject
call ui_io.cmd :getCommand "Enter character to be identified :" itemId || exit /b
call :objectDescription !itemId! object_description
call ui_io.cmd :putStringClearToEOL object_description "0;0"
call recall.cmd :recallMonsterAttributes !itemId!
exit /b

::------------------------------------------------------------------------------
:: Initialize all potions, wands, staves, scrolls, etc.
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:magicInitializeItemNames
call game.cmd :seedSet %game.magic_seed%

for /L %%A in (3,1,%max_colors%) do (
    set /a id_rnd_max=max_color-3
    call rng.cmd :randomNumber !id_rnd_max!
    set /a id=!errorlevel!+2

    for %%B in ("!id!") do (
        set "color=!colors[%%A]!"
        set "colors[%%A]=!colors[%%B]!"
        set "colors[%%B]=!color!"
    )
)
call :scrambleArray woods
call :scrambleArray metals
call :scrambleArray rocks
call :scrambleArray amulets
call :scrambleArray mushrooms

for %%A in (0,1,44) do (
    call rng.cmd :randomNumber 2
    set /a k=!errorlevel!

    for /L %%I in (0,1,!k!) do (
        call rng.cmd :randomNumber 2
        set "s=!errorlevel!"
        for /L %%S in (!s!,-1,1) do (
            call rng.cmd :randomNumber 44
            for %%B in ("!errorlevel!") do (
                set "item_title=!item_title!!syllables[%%B]!"
            )
        )
        set /a i_cmp=k-1
        if !i! LSS !i_cmp! set "item_title=!item_title! "
    )
)
call game.cmd :seedResetToOldSeed
exit /b

::------------------------------------------------------------------------------
:: Rearranges the order of the elements of a specified array
::
:: Arguments: %1 - The name of the array to scramble
:: Returns:   None
::------------------------------------------------------------------------------
:scrambleArray
set /a max_num=!max_%~1!-1

for /L %%A in (0,1,!max_num!) do (
    call rng.cmd :randomNumber !max_num!
    set /a id=!errorlevel!-1
    for %%B in ("!id!") do (
        set "_%~1=!%~1[%%A]!"
        set "!%~1[%%A]!=!%~1[%%B]!"
        set "!%~1[%%B]!=!_%~1!"
    )
)
exit /b

::------------------------------------------------------------------------------
:: Returns the offset in memory of the object's position
::
:: Arguments: %1 - The category ID
::            %2 - The subcategory ID
:: Returns:   Where in the inventory the specific object is located
::------------------------------------------------------------------------------
:objectPositionOffset
if "%~1"=="%tv_amulet%" exit /b 0
if "%~1"=="%tv_ring%" exit /b 1
if "%~1"=="%tv_staff%" exit /b 2
if "%~1"=="%tv_wand%" exit /b 3
if "%~1"=="%tv_scroll1%" exit /b 4
if "%~1"=="%tv_scroll2%" exit /b 4
if "%~1"=="%tv_potion1%" exit /b 5
if "%~1"=="%tv_potion2%" exit /b 5
if "%~1"=="%tv_food%" (
    set /a "within_mushroom_tolerance=sub_category_id&(item_single_stack_min-1)"
    if !within_mushroom_tolerance! LSS !max_mushrooms! (
        exit /b 6
    ) else (
        exit /b -1
    )
)
exit /b -1

::------------------------------------------------------------------------------
:: Removes the Tried flag for a given object
::
:: Arguments: %1 - The index of the object to clear the flag for
:: Returns:   None
::------------------------------------------------------------------------------
:clearObjectTriedFlag
set /a "objects_identified[%~1]&=~%config.identification.od_tried%"
exit /b

::------------------------------------------------------------------------------
:: Adds the Tried flag for a given object
::
:: Arguments: %1 - The index of the object to set the flag for
:: Returns:   None
::------------------------------------------------------------------------------
:setObjectTriedFlag
set /a "objects_identified[%~1]|=%config.identification.od_tried%"
exit /b

::------------------------------------------------------------------------------
:: Determines if an object is known or not
::
:: Arguments: %1 - The index of the object to check
:: Returns:   0 if the object is known
::            1 if the object is unknown
::------------------------------------------------------------------------------
:isObjectKnown
set /a "is_known=!objects_identified[%~1]! & %config.identification.od_known1%"
exit /b !is_known!

::------------------------------------------------------------------------------
:: Remove the "secret" symbol for the identity of a specified object
::
:: Arguments: %1 - The category ID
::            %2 - The subcategory ID
:: Returns:   None
::------------------------------------------------------------------------------
:itemSetAsIdentified
call :objectPositionOffset "%~1" "%~2"
set "id=!errorlevel!"
if !id! LSS 0 exit /b

set /a "id<<=6"
set /a "id+=(%~2 & (item_single_stack_min - 1))"
set /a "objects_identified[!id!]|=%config.identification.od_known1%"

call :clearObjectTriedFlag !id!
exit /b

::------------------------------------------------------------------------------
:: Remove an automatically-generated description
::
:: Arguments: %1 - The name of the item to process
:: Returns:   None
::------------------------------------------------------------------------------
:unsample
set /a "%~1.identification&=~(%config.identification.id_magik% | %config.identification.id_empty%)"

call :objectPositionOffset "!%~1.category_id!" "!%~1.sub_category_id!"
set "id=!errorlevel!"
set /a "id<<=6"
set /a "id+=(!%~1.sub_category_id! & (item_single_stack_min - 1))"

call :clearObjectTriedFlag !id!
exit /b

::------------------------------------------------------------------------------
:: Remove the "secret" symbol for the identity of plusses
::
:: Arguments: %1 - The name of the item to process
:: Returns:   None
::------------------------------------------------------------------------------
:spellItemIdentifyAndRemoveRandomInscription
call :unsample "%~1"
set /a "%~1.identification|=%config.identification.id_known2%"
exit /b

::------------------------------------------------------------------------------
:: Validates that a specified spell item has been identified
::
:: Arguments: %1 - The name of the item to validate
:: Returns:   0 if the item has been identified before
::            1 otherwise
::------------------------------------------------------------------------------
:spellItemIdentified
set /a "is_known=!%~1.identification! & %config.identification.id_known2%"
exit /b !is_known!

::------------------------------------------------------------------------------
:: Removes the flag that specifies that a given item has been identified
::
:: Arguments: %1 - The name of the item to process
:: Returns:   None
::------------------------------------------------------------------------------
:spellItemRemoveIdentification
set /a "%~1.identification&=~%config.identification.id_known2%"
exit /b

::------------------------------------------------------------------------------
:: Removes the flag that specifies that a given item has an empty ID
::
:: Arguments: %1 - The name of the item to process
:: Returns:   None
::------------------------------------------------------------------------------
:itemIdentificationClearEmpty
set /a "%~1.identification&=~%config.identification.id_empty%"
exit /b

::------------------------------------------------------------------------------
:: Sets the flag that identifies an item as storebought
::
:: Arguments: %1 - The name of the item to process
:: Returns:   None
::------------------------------------------------------------------------------
:itemIdentifyAsStoreBought
set /a "%~1.identification|=%config.identification.id_store_bought%"
call :spellItemIdentifyAndRemoveRandomInscription "%~1"
exit /b

::------------------------------------------------------------------------------
:: Checks if a given item is marked as having been bought in a store because
:: for some unknown in-universe reason, store owners won't buy back items.
::
:: Arguments: %1 - The identification flag value of the item to validate
:: Returns:   0 if the item has been bought in a store
::            1 if the item was found outside
::------------------------------------------------------------------------------
:itemStoreBought
set /a "was_bought=%~1 & %config.identification.id_store_bought%"
exit /b !was_bought!

::------------------------------------------------------------------------------
:: Items which don't have a color are always known so that they're listed
:: correctly in the inventory
::
:: Arguments: %1 - The category ID of the item
::            %2 - The subcategory ID of the item
::            %3 - The identification flag value of the item
:: Returns:   0 if the object is known
::            1 otherwise
::------------------------------------------------------------------------------
:itemSetColorlessAsIdentified
call :objectPositionOffset "%~1" "%~2"
set "id=!errorlevel!"

if !id! LSS 0 (
    REM Pretty sure this is a constant, but whatever
    if not "%config.identification.od_known1%"=="0" (
        exit /b 0
    ) else (
        exit /b 1
    )

    call :itemStoreBought "%~3"
    if "!errorlevel!"=="0" (
        exit /b 0
    ) else (
        exit /b 1
    )
)

set /a "id<<=6"
set /a "id+=(%~2 & (item_single_stack_min - 1))"

call :isObjectKnown "!id!"
exit /b !errorlevel!

::------------------------------------------------------------------------------
:: Mark a specified item as having been sampled
::
:: Arguments: %1 - The name of the item to process
:: Returns:   None
::------------------------------------------------------------------------------
:itemSetAsTried
call :objectPositionOffset "!%~1.category_id!" "!%~1.subcategory_id!"
set "id=!errorlevel!"

if !id! LSS 0 exit /b

set /a "id<<=6"
set /a "id+=(!%~1.sub_category_id! & (item_single_stack_min - 1))"
call :setObjectTriedFlag "!id!"
exit /b

::------------------------------------------------------------------------------
:: Identify a specified object
::
:: Arguments: %1 - The name of the item to identify
::            %2 - A reference to the ID of the item
:: Returns:   None
::------------------------------------------------------------------------------
:itemIdentify
set "item_id=%~2"

call inventory.cmd :inventoryItemIsCursed "%~1" && (
    call :itemAppendToInscription "%~1" "%config.identification.id_damd%"
)
call :itemSetColorlessAsIdentified "!%~1.category_id!" "!%~1.sub_category_id!" "!%~1.identification!" && (
    exit /b
)

call :itemSetAsIdentified "!%~1.category_id!" "!%~1.sub_category_id!"

call inventory.cmd :inventoryItemSingleStackable "%~1" || (
    exit /b
)

set /a max_counter=%py.pack.unique_items%-1
set /a matching_cat=1, matching_sub_cat=1, total_items_count=0
for /L %%A in (0,1,%max_counter%) do (
    set "i=%%A"
    if "!py.inventory[%%A].category_id!"=="!%~1.category_id!" set "matching_cat=0"
    if "!py.inventory[%%A].sub_category_id!"=="!%~1.sub_category_id!" set "matching_sub_cat=0"
    set /a total_items_count=!py.inventory[%%A].items_count!+!%~1.items_count!

    REM I only hate this a lot, so it's fine
    if "!matching_cat!"=="0" if "!matching_sub_cat!"=="0" if not "%%A"=="!%~2!" (
        if !total_items_count! LSS 256 (
            if !%~2! GTR %%A (
                set "j=!%~2!"
                set "%~2=!i!"
                set "i=!j!"
            )

            call ui_io.cmd :printMessage "You combine similar objects from the shop and dungeon."

            set /a py.inventory[!%~2!].items_count+=py.inventory[!i!].items_count
            set /a py.pack.unique_items-=1

            for /L %%B in (!i!,1,!max_counter!) do (
                for /f "delims=" %%C in ('set /a %%B+1') do (
                    call inventory.cmd :inventoryCopyItem "py.inventory[%%B]" "py.inventory[%%C]"
                )
            )
        )
    )
)

exit /b

::------------------------------------------------------------------------------
:: If an object has lost magical properties, remove the appropriate portion of
:: its name
::
:: Arguments: %1 - The name of the item to process
:: Returns:   None
::------------------------------------------------------------------------------
:itemRemoveMagicNaming
set /a "%~1.special_name_id=%SpecialNameIds.sn_null%"
exit /b

::------------------------------------------------------------------------------
:: Returns the amount of damage that a bow does based on its misc_use value
::
:: Arguments: %1 - The misc_use value of the bow
:: Returns:   How much damage that bow does
::------------------------------------------------------------------------------
:bowDamageValue
if "%~1"=="1" exit /b 2
if "%~1"=="2" exit /b 2
if "%~1"=="3" exit /b 3
if "%~1"=="4" exit /b 4
if "%~1"=="5" exit /b 3
if "%~1"=="6" exit /b 4
exit /b -1

::------------------------------------------------------------------------------
:: Sets the description for an inventory item
::
:: Arguments: %1 - The description to add
::            %2 - The name of the item to process
::            %3 - True if an article must be added, False otherwise
:: Returns:   None
::------------------------------------------------------------------------------
:itemDescription
set /a "indexx=!%~2.sub_category_id! & (%item_single_stack_min% - 1)"

for /f "delims=" %%A in ("!%~2.id!") do (
    set "basenm=!game_objects[%%A].name!"
)
set "append_name=false"
call :itemSetColorlessAsIdentified "!%~2.category_id!" "!%~2.sub_category_id!" "!%~2.identification!"
set "misc_type=%ItemMiscUse.Ignored%"

if "!%~2.category_id!"=="%tv_misc%" goto :itemDescriptionAfterSwitch
if "!%~2.category_id!"=="%tv_chest%" goto :itemDescriptionAfterSwitch
if "!%~2.category_id!"=="%tv_spike%" goto :itemDescriptionAfterSwitch
if "!%~2.category_id!"=="%tv_boots%" goto :itemDescriptionAfterSwitch
if "!%~2.category_id!"=="%tv_gloves%" goto :itemDescriptionAfterSwitch
if "!%~2.category_id!"=="%tv_cloak%" goto :itemDescriptionAfterSwitch
if "!%~2.category_id!"=="%tv_helm%" goto :itemDescriptionAfterSwitch
if "!%~2.category_id!"=="%tv_shield%" goto :itemDescriptionAfterSwitch
if "!%~2.category_id!"=="%tv_hard_armor%" goto :itemDescriptionAfterSwitch
if "!%~2.category_id!"=="%tv_soft_armor%" goto :itemDescriptionAfterSwitch
if "!%~2.category_id!"=="%tv_flask%" goto :itemDescriptionAfterSwitch
if "!%~2.category_id!"=="%tv_open_door%" goto :itemDescriptionAfterSwitch
if "!%~2.category_id!"=="%tv_closed_door%" goto :itemDescriptionAfterSwitch
if "!%~2.category_id!"=="%tv_secret_door%" goto :itemDescriptionAfterSwitch
if "!%~2.category_id!"=="%tv_rubble%" goto :itemDescriptionAfterSwitch
if "!%~2.category_id!"=="%tv_sling_ammo%" (
    set "damstr= (!%~2.damage.dice!d!%~2.damage.sides!)"
    goto :itemDescriptionAfterSwitch
)
if "!%~2.category_id!"=="%tv_bolt%" (
    set "damstr= (!%~2.damage.dice!d!%~2.damage.sides!)"
    goto :itemDescriptionAfterSwitch
)
if "!%~2.category_id!"=="%tv_arrow%" (
    set "damstr= (!%~2.damage.dice!d!%~2.damage.sides!)"
    goto :itemDescriptionAfterSwitch
)
if "!%~2.category_id!"=="%tv_light%" (
    set "misc_type=%ItemMiscUse.Light%"
    goto :itemDescriptionAfterSwitch
)
if "!%~2.category_id!"=="%tv_bow%" (
    call :bowDamageValue "!%~2.misc_use!"
    set "damstr= (x!errorlevel!)"
    goto :itemDescriptionAfterSwitch
)
if "!%~2.category_id!"=="%tv_hafted%" (
    set "damstr= (!%~2.damage.dice!d!%~2.damage.sides!)"
    set "misc_type=%ItemMiscUse.flags%"
    goto :itemDescriptionAfterSwitch
)
if "!%~2.category_id!"=="%tv_polearm%" (
    set "damstr= (!%~2.damage.dice!d!%~2.damage.sides!)"
    set "misc_type=%ItemMiscUse.flags%"
    goto :itemDescriptionAfterSwitch
)
if "!%~2.category_id!"=="%tv_sword%" (
    set "damstr= (!%~2.damage.dice!d!%~2.damage.sides!)"
    set "misc_type=%ItemMiscUse.flags%"
    goto :itemDescriptionAfterSwitch
)
if "!%~2.category_id!"=="%tv_digging%" (
    set "damstr= (!%~2.damage.dice!d!%~2.damage.sides!)"
    set "misc_type=%ItemMiscUse.zplusses%"
    goto :itemDescriptionAfterSwitch
)
if "!%~2.category_id!"=="%tv_amulet%" (
    if /I "%~3"=="true" (
        set "basenm=_ /s/ Amulet"
        set "modstr=!amulets[%indexx%]!"
    ) else (
        set "basenm=_ Amulet"
        set "append_name=true"
    )
    set "misc_type=%ItemMiscUse.Plusses%"
    goto :itemDescriptionAfterSwitch
)
if "!%~2.category_id!"=="%tv_ring%" (
    if /I "%~3"=="true" (
        set "basenm=_ /s/ Ring"
        set "modstr=!rocks[%indexx%]!"
    ) else (
        set "basenm=_ Ring"
        set "append_name=true"
    )
    set "misc_type=%ItemMiscUse.Plusses%"
    goto :itemDescriptionAfterSwitch
)
if "!%~2.category_id!"=="%tv_staff%" (
    if /I "%~3"=="true" (
        set "basenm=_ /s/ Staff"
        set "modstr=!woods[%indexx%]!"
    ) else (
        set "basenm=_ Staff"
        set "append_name=true"
    )
    set "misc_type=%ItemMiscUse.Charges%"
    goto :itemDescriptionAfterSwitch
)
if "!%~2.category_id!"=="%tv_wand%" (
    if /I "%~3"=="true" (
        set "basenm=_ /s/ Wand"
        set "modstr=!metals[%indexx%]!"
    ) else (
        set "basenm=_ Wand"
        set "append_name=true"
    )
    set "misc_type=%ItemMiscUse.Charges%"
    goto :itemDescriptionAfterSwitch
)
if "!%~2.category_id!"=="%tv_scroll1%" (
    if /I "%~3"=="true" (
        set "basenm=_ Scroll~ titled '/s/'"
        set "modstr=!magic_item_titles[%indexx%]!"
    ) else (
        set "basenm=_ Scroll~"
        set "append_name=true"
    )
    goto :itemDescriptionAfterSwitch
)
if "!%~2.category_id!"=="%tv_scroll2%" (
    if /I "%~3"=="true" (
        set "basenm=_ Scroll~ titled '/s/'"
        set "modstr=!magic_item_titles[%indexx%]!"
    ) else (
        set "basenm=_ Scroll~"
        set "append_name=true"
    )
    goto :itemDescriptionAfterSwitch
)
if "!%~2.category_id!"=="%tv_potion1%" (
    if /I "%~3"=="true" (
        set "basenm=_ /s/ Potion~"
        set "modstr=!colors[%indexx%]!"
    ) else (
        set "basenm=_ Potion~"
        set "append_name=true"
    )
    goto :itemDescriptionAfterSwitch
)
if "!%~2.category_id!"=="%tv_potion2%" (
    if /I "%~3"=="true" (
        set "basenm=_ /s/ Potion~"
        set "modstr=!colors[%indexx%]!"
    ) else (
        set "basenm=_ Potion~"
        set "append_name=true"
    )
    goto :itemDescriptionAfterSwitch
)
if "!%~2.category_id!"=="%tv_food%" (
    if /I "%~3"=="true" (
        if %indexx% LEQ 15 (
            set "basenm=_ /s/ Mushroom~"
        ) else if %indexx% LEQ 20 (
            set "basenm=_ Hairy /s/ Mold~"
        )

        if %indexx% LEQ 20 (
            set "modstr=!mushrooms[%indexx%]!"
        )
    ) else (
        set "append_name=true"
        if %indexx% LEQ 15 (
            set "basenm=_ Mushroom~"
        ) else if %indexx% LEQ 20 (
            set "basenm=_ Hairy Mold~"
        ) else (
            set "append_name=false"
        )
    )
    goto :itemDescriptionAfterSwitch
)
if "!%~2.category_id!"=="%tv_magic_book%" (
    set "modstr=!basenm!"
    set "basenm=_ Book~ of Magic Spells /s/"
    goto :itemDescriptionAfterSwitch
)
if "!%~2.category_id!"=="%tv_prayer_book%" (
    set "modstr=!basenm!"
    set "basenm=_ Holy Book~ of Prayers /s/"
    goto :itemDescriptionAfterSwitch
)
if "!%~2.category_id!"=="%tv_gold%" (
    set "description=!basenm!."
    exit /b
)
if "!%~2.category_id!"=="%tv_invis_trap%" (
    set "description=!basenm!."
    exit /b
)
if "!%~2.category_id!"=="%tv_vis_trap%" (
    set "description=!basenm!."
    exit /b
)
if "!%~2.category_id!"=="%tv_up_stair%" (
    set "description=!basenm!."
    exit /b
)
if "!%~2.category_id!"=="%tv_down_stair%" (
    set "description=!basenm!."
    exit /b
)
if "!%~2.category_id!"=="%tv_store_door%" (
    set "description=the entrance to the !basenm!."
    exit /b
)
set "description=Error in :itemDescription"
exit /b
:itemDescriptionAfterSwitch
if "%modstr%"=="" (
    set "tmp_val=!basenm!"
) else (
    set "tmp_val=!basenm:/s/=%modstr%!"
)
if "%append_name%"=="true" (
    for /f "delims=" %%A in ("!%~2.id!") do (
        set "tmp_val=!tmp_val! of !game_objects[%%A].name!"
    )
)

if "!%~2.items_count!"=="1" (
    call helpers.cmd :insertStringIntoString "~" "CNIL"
) else (
    call helpers.cmd :insertStringIntoString "ch~" "ches"
    call helpers.cmd :insertStringIntoString "~" "es"
)

if "%~3"=="false" (
    if "!tmp_val!"=="some" (
        set "description=!description!!tmp_val:~5!"
    ) else if "!tmp_val:~0,1!"=="_" (
        set "description=!description!!tmp_val:~2!"
    ) else (
        set "description=!description!!tmp_val!"
    )
    exit /b
)

set "tmp_str="
call :spellItemIdentified "%~2"
set "is_identified=!errorlevel!"
if "!%~2.special_name_id!" NEQ "%specialNameIds.sn_null%" (
    if "!is_identified!"=="0" (
        for /f "delims=" %%A in ("!%~2.special_name_id!") do (
            set "tmp_val=!tmp_val! !special_item_names[%%~A]!"
        )
    )
)

if defined damstr set "tmp_val=!tmp_val!!damstr!"

if "!is_identified!"=="0" (
    REM Get the absolute value to properly display a + or - in front of the value
    REM because positive values do not lead with a visible +
    set "abs_to_hit=!%~2.to_hit!"
    set "abs_to_damage=!%~2.to_damage!"
    if !abs_to_hit! LSS 0 set /a abs_to_hit*=-1
    if !abs_to_damage! LSS 0 set /a abs_to_damage*=-1

    set /a "show_hit_damage=!%~2.identification! & %config.identification.id_show_hit_dam%"
    if !show_hit_damage! NEQ 0 (
        if !%~2.to_hit! LSS 0 (
            set "tmp_str=(-!abs_to_hit!,"
        ) else (
            set "tmp_str=(+!abs_to_hit!,"
        )
        if !%~2.to_damage! LSS 0 (
            set "tmp_str=!tmp_str!-!abs_to_damage!)"
        ) else (
            set "tmp_str=!tmp_str!+!abs_to_damage!)"
        )
    ) else if not "!%~2.to_hit!"=="0" (
        if !%~2.to_hit! LSS 0 (
            set "tmp_str=(-!abs_to_hit!)"
        ) else (
            set "tmp_str=(+!abs_to_hit!)"
        )
    ) else if not "!%~2.to damage!"=="0" (
        if !%~2.to_hit! LSS 0 (
            set "tmp_str=(-!abs_to_damage!)"
        ) else (
            set "tmp_str=(+!abs_to_damage!)"
        )
    ) else (
        set "tmp_str="
    )
    set "tmp_val=!tmp_val!!tmp_str!"
)

set "abs_to_ac=!%~2.to_ac!"
if !abs_to_ac! LSS 0 set /a abs_to_ac*=-1
set "is_crown=1"
if not "!%~2.ac!"=="0" set "is_crown=0"
if "!%~2.category_id!"=="%tv_helm%" set "is_crown=0"
if "!is_crown!"=="0" (
    set "tmp_val=!tmp_val! [!%~2.ac!"
    if "!is_identified!"=="0" (
        if !%~2.to_ac! LSS 0 (
            set "tmp_val=!tmp_val!-!abs_to_ac!"
        ) else (
            set "tmp_val=!tmp_val!+!abs_to_ac!"
        )
    )
    set "tmp_val=!tmp_val!]"
)

set /a "has_no_show=!%~2.identification! & %config.identification.id_no_show_p1%"
set /a "has_show=!%~2.identification! & %config.identification.id_show_p1%"
if not "!has_no_show!"=="0" set "misc_type=%ItemMiscUse.ignored%"
if not "!has_show!"=="0" set "misc_type=%ItemMiscUse.zplusses%"

set "tmp_str="
if "!misc_use!"=="%ItemMiscUse.ignored%" goto :parseUnderscore
if "!misc_use!"=="%ItemMiscUse.light%" (
    set "tmp_str= with !%~2.misc_use! turns of light"
) else if "!is_identified!"=="0" (
    set /a abs_misc_use=!%~2.misc_use!
    if !abs_misc_use! LSS 0 set /a abs_misc_use*=-1

    if "!misc_type!"=="%ItemMiscUse.zplusses%" (
        if !%~2.misc_use! LSS 0 (
            set "tmp_str= (-!abs_misc_use!)"
        ) else (
            set "tmp_str= (+!abs_misc_use!)"
        )
    ) else if "!misc_type!"=="%ItemMiscUse.charges%" (
        set "tmp_str= (!%~2.misc_use! charges)"
    ) else if not "!%~2.misc_use!"=="0" (
        if "!misc_type!"=="%ItemMiscUse.plusses%" (
            if !%~2.misc_use! LSS 0 (
                set "tmp_str= (-!abs_misc_use!)"
            ) else (
                set "tmp_str= (+!abs_misc_use!)"
            )
        ) else if "!misc_type!"=="%ItemMiscUse.flags%" (
            set /a "has_to_str=!%~2.flags! & %config.treasure.flags.tr_str%"
            set /a "has_to_stealth=!%~2.flags! & %config.treasure.flags.tr_stealth%"

            if not "!has_to_str!"=="0" (
                if !%~2.misc_use! LSS 0 (
                    set "tmp_str= (-!abs_misc_use! to STR)"
                ) else (
                    set "tmp_str= (+!abs_misc_use! to STR)"
                )
            )
            if not "!has_to_stealth!"=="0" (
                if !%~2.misc_use! LSS 0 (
                    set "tmp_str= (-!abs_misc_use! to stealth)"
                ) else (
                    set "tmp_str= (+!abs_misc_use! to stealth)"
                )
            )
        )
    )
)
set "tmp_val=!tmp_val!!tmp_str!"

:parseUnderscore
call helpers.cmd :isVowel !tmp_val:~2,1!
set "uses_an=!errorlevel!
"
if "!tmp_val:~0,1!"=="_" (
    if !%~2.items_count! GTR 1 (
        set "description=!%~2.items_count!!tmp_val:~1!"
    ) else if !%~2.items_count! LSS 0 (
        set "description=no more!tmp_val:~1!"
    ) else if "!uses_an!"=="0" (
        set "description=an!tmp_val:~1!"
    ) else (
        set "description=a!tmp_val:~1!"
    )
) else if !%~2.items_count! LSS 1 (
    if "!tmp_val:~0,4!"=="some" (
        set "description=no more !tmp_val:~5!"
    ) else (
        set "description=no more !tmp_val!"
    )
) else (
    set "description=!tmp_val!"
)

set "tmp_str="
call :objectPositionOffset "!%~2.category_id!" "!%~2.sub_category_id!"
set "indexx=!errorlevel!"
if !indexx! GEQ 0 (
    set /a "indexx<<=6"
    set /a "id+=(!%~2.sub_category_id! & (item_single_stack_min - 1))"
    for /f "delims=" %%A in ("!indexx!") do (
        set /a "is_tried=!objects_identified[%%~A]! & %config.identification.og_tried%"
    )
    if not "!is_tried!"=="0" (
        call :itemStoreBought "!%~2.identification!" || (
            set "tmp_str=!tmp_str!tried "
        )
    )
)

set /a "is_magik=!%~2.identification! & %config.identification.id_magik%"
set /a "is_empty=!%~2.identification! & %config.identification.id_empty%"
set /a "is_damd=!%~2.identification! & %config.identification.id_damd%"
if not "!is_magik!"=="0" set "tmp_str=!tmp_str!magik "
if not "!is_empty!"=="0" set "tmp_str=!tmp_str!empty "
if not "!is_damd!"=="0" set "tmp_str=!tmp_str!damned "

if not "!%~2.inscription!"=="" (
    set "tmp_str=!tmp_str!!%~2.inscription!"
) else (
    call helpers.cmd :getLength "!tmp_str!" indexx
    if !indexx! GTR 0 set "tmp_str=!tmp_str:~0,-1!"
)

if not "!tmp_str:~0,1!"=="0" (
    set "description=!description! {!tmp_str!}"
)
set "description=!description!."
set "%~1=!description!"
exit /b

::------------------------------------------------------------------------------
:: Lists the number of remaining charges
::
:: Arguments: %1 - The index of the inventory that contains the described item
:: Returns:   None
::------------------------------------------------------------------------------
:itemChargesRemainingDescription
call :spellItemIdentified "py.inventory.[%~1]" || exit /b

call ui_io.cmd :printMessage "You have !py.inventory[%~1].misc_use! charges remaining."
exit /b

::------------------------------------------------------------------------------
:: Describe the amount of item remaining
::
:: Arguments: %1 - The index of the inventory that contains the described item
:: Returns:   None
::------------------------------------------------------------------------------
:itemTypeRemainingCountDescription
set /a py.inventory[%~1].items_count-=1
call :itemDescription tmp_str "py.inventory[%~1]" "true"
set /a py.inventory[%~1].items_count+=1

:: The string already ends with a period
call ui_io.cmd :printMessage "You have !tmp_str!"
exit /b

::------------------------------------------------------------------------------
:: Adds a comment to an item inscription
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:itemInscribe
if "%py.pack.unique_items%"=="0" (
    if "%py.equipment_count%"=="0" (
        call ui_io.cmd :printMessage "You are not carrying anything to inscribe."
        exit /b
    )
)

call ui_inventory.cmd :inventoryGetInputForItemId item_id "Which one? " 0 %player_inventory_size% CNIL CNIL || exit /b
call :itemDescription msg "py.inventory[%item_id%]" "true"
call ui_io.cmd :printMessage "Inscribing %msg%"

if not "!py.inventory[%item_id%].inscription!"=="" (
    set "inscription=Replace !py.inventory[%item_id%].inscription! New inscription:"
) else (
    set "inscription=Inscription: "
)

call helpers.cmd :getLength %msg% msg_len
set /a msg_len=78-%msg_len%
if %msg_len% GTR 12 set "msg_len=12"

call ui_io.cmd :putStringClearToEOL "!inscription!" "0;0"
call helpers.cmd :getLength "!inscription!" insc_len
call ui_io.cmd :getStringInput "!inscription!" "0;!insc_len!" %msg_len% && (
    call :itemReplaceInscription "py.inventory[%item_id%]" "!inscription!"
)
exit /b

::------------------------------------------------------------------------------
:: Append an additional comment to an object description
::
:: Arguments: %1 - The name of the item to inscribe
::            %2 - The identification type of the object
:: Returns:   None
::------------------------------------------------------------------------------
:itemAppendToInscription
set /a "%~1.identification|=%~2"
exit /b

::------------------------------------------------------------------------------
:: Replaces an existing comment in an object description with a new one
::
:: Arguments: %1 - The name of the item to inscribe
::            %2 - The inscription to add
:: Returns:   None
::------------------------------------------------------------------------------
:itemReplaceInscription
set "%~1.inscription=%~2"
exit /b

::------------------------------------------------------------------------------
:: Prints a message if an object is blocked by a monster
::
:: Arguments: %1 - The ID of the monster blocking the way
:: Returns:   None
::------------------------------------------------------------------------------
:objectBlockedByMonster
set "c_id=!monsters[%~1].creature_id!"
set "m_name=!creatures_list[%cid%].name!"

if "!monsters[%~1].lit"=="true" (
    call ui_io.cmd :printMessage "The %m_name% is in your way."
) else (
    call ui_io.cmd :printMessage "Something is in your way."
)
exit /b