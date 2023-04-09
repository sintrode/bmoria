@echo off
call %*
exit /b

::------------------------------------------------------------------------------
:: Displays the weight of a specified inventory item
::
:: Arguments: %1 - A variable to store the string containing the weight data
::            %2 - The item_id of the item being weighed
:: Returns:   None
::------------------------------------------------------------------------------
:inventoryItemWeightText
set /a total_weight=!py.inventory[%~2].weight! * !py.inventory[%~2].items_count!
set /a "quotient=%total_weight% / 10", "remainder=%total_weight% %% 10"
call scores.cmd :sprintf "text" "%quotient%" 3
set "text=%text%.%remainder% lb"
exit /b

::------------------------------------------------------------------------------
:: Displays inventory items from item_id_start to item_id_end
::
:: Arguments: %1 - The item_id of the first item to display
::            %2 - The item_id of the last item to display
::            %3 - Indicates if a column should be moved to the left
::            %4 - The default column to start at
::            %5 - A bitwise filter for items to display
:: Returns:   The column to start the display on
::------------------------------------------------------------------------------
:displayInventoryItems
set "item_id_start=%~1"
set "item_id_end=%~2"
set "weighted=%~3"
set "column=%~4"
set "mask=%~5"

set /a strlen=79-%column%
if "%weighted%"=="true" (
    set "lim=68"
) else (
    set "lim=76"
)

set "loop_start=%item_id_start%"
:displayInventoryItemsFirstLoop
for /L %%A in (%loop_start%,1,%item_id_end%) do (
    if not "%mask%"=="CNIL" (
        if "!%mask%[%%A]!"=="0" (
            REM Faking a continue is weird in batch
            set /a loop_start+=1
            goto :displayInventoryItemsFirstLoop
        )
    )

    call identification.cmd :itemDescription "description" "py.inventory[%%A]" "true"
    set "description=!description:~0,%lim%!"

    set /a item_letter=%%A+97
    cmd /c exit /b !item_letter!
    set "descriptions[%%A]=!=ExitCodeAscii!) !description!"

    call helpers.cmd :getLength "!descriptions[%%A]!"
    set /a l=!errorlevel!+2
    if "%weighted%"=="true" set /a l+=9
    if !l! GTR !strlen! set "strlen=!l!"
)

set /a column=79-!len!
if %column% LSS 0 set "column=0"
set "current_line=1"

set "loop_start=%item_id_start%"
:displayInventoryItemsSecondLoop
for /L %%A in (%loop_start%,1,%item_id_end%) do (
    if not "%mask%"=="CNIL" (
        if "!%mask%[%%A]!"=="0" (
            set /a loop_start+=1
            goto :displayInventoryItemsSecondLoop
        )
    )

    if "!column!"=="0" (
        call ui_io.cmd :putStringClearToEOL "!descriptions[%%A]!" "!current_line!;!column!"
    ) else (
        call ui_io.cmd :putString "  " "!current_line!;!column!"
        set /a col_inc=!column!+2
        call ui_io.cmd :putStringClearToEOL "!descriptions[%%A]!" "!current_line!;!col_inc!"
    )

    if "%weighted%"=="true" (
        call :inventoryItemWeightText "text" %%A
        call ui_io.cmd :putStringClearToEOL "!text!" "!current_line!;71"
    )

    set /a current_line+=1
)
exit /b !column!

::------------------------------------------------------------------------------
:: Set a string describing how a given equipment item is carried
::
:: Arguments: %1 - A number corresponding to the PlayerEquipment enum
::            %2 - The variable to store the description in
:: Returns:   None
::------------------------------------------------------------------------------
:playerItemWearingDescription
if "%~1"=="%PlayerEquipment.Wield%" (
    set "%~2=wielding"
) else if "%~1"=="%PlayerEquipment.Head%" (
    set "%~2=wearing on your head"
) else if "%~1"=="%PlayerEquipment.Neck%" (
    set "%~2=wearing around your neck"
) else if "%~1"=="%PlayerEquipment.Body%" (
    set "%~2=wearing on your body"
) else if "%~1"=="%PlayerEquipment.Arm%" (
    set "%~2=wearing on your arm"
) else if "%~1"=="%PlayerEquipment.Hands%" (
    set "%2=wearing on your hands"
) else if "%~1"=="%PlayerEquipment.Right%" (
    set "%~2=wearing on your right hand"
) else if "%~1"=="%PlayerEquipment.Left%" (
    set "%~2=wearing on your left hand"
) else if "%~1"=="%PlayerEquipment.Feet%" (
    set "%~2=wearing on your feet"
) else if "%~1"=="%PlayerEquipment.Outer%" (
    set "%~2=wearing about your body"
) else if "%~1"=="%PlayerEquipment.Light%" (
    set "%~2=using to light the way"
) else if "%~1"=="%PlayerEquipment.Auxiliary%" (
    set "%~2=holding ready by your side"
) else (
    set "%~2=carrying in your pack"
)
exit /b

::------------------------------------------------------------------------------
:: Set a string describing where a given piece of equipment is located
::
:: Arguments: %1 - A number corresponding to the PlayerEquipment enum
::            %2 - The weight of the item
::            %3 - The variable to store the description in
:: Returns:   None
::------------------------------------------------------------------------------
:equipmentPositionDescription
if "%~1"=="%PlayerEquipment.Wield%" (
    set /a min_strength=!py.stats.used[%PlayerAttr.a_str%]!*15
    if !min_strength! LSS %~2 (
        set "%~3=Just lifting"
    ) else (
        set "%~3=Wielding"
    )
) else if "%~1"=="%PlayerEquipment.Head%" (
    set "%~3=On head"
) else if "%~1"=="%PlayerEquipment.Neck%" (
    set "%~3=Around neck"
) else if "%~1"=="%PlayerEquipment.Body%" (
    set "%~3=On body"
) else if "%~1"=="%PlayerEquipment.Arm%" (
    set "%~3=On arm"
) else if "%~1"=="%PlayerEquipment.Hands%" (
    set "%~3=On hands"
) else if "%~1"=="%PlayerEquipment.Right%" (
    set "%~3=On right hand"
) else if "%~1"=="%PlayerEquipment.Left%" (
    set "%~3=On left hand"
) else if "%~1"=="%PlayerEquipment.Feet%" (
    set "%~3=On feet"
) else if "%~1"=="%PlayerEquipment.Outer%" (
    set "%~3=About body"
) else if "%~1"=="%PlayerEquipment.Light%" (
    set "%~3=Light source"
) else if "%~1"=="%PlayerEquipment.Auxiliary%" (
    set "%~3=Spare weapon"
) else (
    set "%~3=Unknown equipment position ID"
)
exit /b

::------------------------------------------------------------------------------
:: Display equipment items
::
:: Arguments: %1 - Determines if the item weights should be shown
::            %2 - The rightmost column
:: Returns:   The leftmost column to display on
::------------------------------------------------------------------------------
:displayEquipment
set "show_weights=%~1"
set "column=%~2"

for /L %%A in (0,1,11) do set "descriptions[%%A]="
set /a len=79-%column%
if "%show_weights%"=="true" (
    set "lim=52"
) else (
    set "lim=60"
)

set "line=0"
for /L %%A in (22,1,33) do (
    if not "!py.inventory[%%A].category_id!"=="%TV_NOTHING%" (
        call :equipmentPositionDescription %%A "!py.inventory[%%A].weight!" "equipped_description"
        call identification.cmd :itemDescription "description" "!py.inventory[%%A]!" "true"
        set "description=!description:~0,%lim%!"

        call scores.cmd :sprintf "pad_description" "!equipped_description!" -14
        set /a line_letter=!line!+97
        cmd /c exit /b !line_letter!
        set "tmp_desc=!=ExitCodeAscii!) !pad_description!: !description!"
        set "descriptions[!line!]=!tmp_desc!"
        call helpers.cmd :getLength "!tmp_desc!" str_len
        set /a l=!str_len!+2
        set "tmp_desc="

        if "!show_weights!"=="true" set /a l+=9
        if !l! GTR !len! set "len=!l!"

        set /a line+=1
    )
)

set /a column=79-%len%
if %column% LSS 0 set "column=0"

set "line=0"
for /L %%A in (22,1,33) do (
    if not "!py.inventory[%%A].category_id!"=="%TV_NOTHING%" (
        for /F "delims=" %%B in ("!line!") do (
            set /a line_inc=%%B+1
            if "%column%"=="0" (
                call ui_io.cmd :putStringClearToEOL "!descriptions[%%B]!" "!line_inc!;%column%"
            ) else (
                call ui_io.cmd :putString "  " "!line_inc!;%column%"
                set /a col_inc=%column%+2
                call ui_io.cmd :putStringClearToEOL "!descriptions[%%B]!" "!line_inc!;!col_inc!"
            )
            if "!show_weights!"=="true" (
                call :inventoryItemWeightText "text" %%A
                call ui_io.cmd :putStringClearToEOL "!text!" "!line_inc!;71"
            )
        )

        set /a line+=1
    )
)
call ui_io.cmd :eraseLine "!line_inc!;%column%"
exit /b %column%

::------------------------------------------------------------------------------
:: Display the Help menu for the inventory
::
:: Arguments: %1 - The leftmost column of the text
:: Returns:   7 always
::------------------------------------------------------------------------------
:showEquipmentHelpMenu
set "left_column=%~1"
if %left_column% GTR 52 set "left_column=52"

call ui_io.cmd :putStringClearToEOL "  Q: quit" "1;%left_column%"
call ui_io.cmd :putStringClearToEOL "  w: wear or wield object" "2;%left_column%"
call ui_io.cmd :putStringClearToEOL "  t: take off item" "3;%left_column%"
call ui_io.cmd :putStringClearToEOL "  d: drop object" "4;%left_column%"
call ui_io.cmd :putStringClearToEOL "  x: exchange weapons" "5;%left_column%"
call ui_io.cmd :putStringClearToEOL "  i: inventory of pack" "6;%left_column%"
call ui_io.cmd :putStringClearToEOL "  e: list used equipment" "7;%left_column%"
exit /b 7

::------------------------------------------------------------------------------
:: Allows different inventory subscreens to be displayed
::
:: Arguments: %1 - The screen to switch to
:: Returns:   None
::------------------------------------------------------------------------------
:uiCommandSwitchScreen
set "next_screen=%~1"
if "%next_screen%"=="%game.screen.current_screen_id%" exit /b
set "%game.screen.current_screen_id%=%next_screen%"

set "current_line_pos=0"
if "%next_screen%"=="%Screen.Help%" (
    call :showEquipmentHelpMenu "%game.screen.screen_left_pos%"
    set "current_line_pos=!errorlevel!"
) else if "%next_screen%"=="%Screen.Inventory%" (
    set /a unique_items_dec=%py.pack.unique_items%-1
    call :displayInventoryItems 0 "!unique_items_dec!" "%config.options.show_inventory_weights%" "%game.screen.screen_left_pos%" "CNIL"
    set "game.screen.screen_left_pos=!errorlevel!"
    set "current_line_pos=%py.pack.unique_items%"
) else if "%next_screen%"=="%Screen.Wear%" (
    call :displayInventoryItems "%game.screen.wear_low_id%" "%game.screen.wear_high_id%" "%config.options.show_inventory_weights%" "%game.screen.screen_left_pos%" "CNIL"
    set "game.screen.screen_left_pos=!errorlevel!"
    set /a current_line_pos=%game.screen.wear_high_id% - %game.screen.wear_low_id% + 1
) else if "%next_screen%"=="%Screen.Equipment%" (
    call :displayEquipment "%config.options.show_inventory_weights%" "%game.screen.screen_left_pos%"
    set "game.screen.screen_left_pos=!errorlevel!"
    set "current_line_pos=%py.equipment_count%"
)

if !current_line_pos! GEQ %game.screen.screen_bottom_pos% (
    set /a game.screen.screen_bottom_pos=!current_line_pos! + 1
    call ui_io.cmd :eraseLine "!game.screen.screen_bottom_pos!;!game.screen.screen_left_pos!"
    exit /b
)
set /a current_line_pos+=1

for /L %%A in (!current_line_pos!,1,!game.screen.screen_bottom_pos!) do (
    call ui_io.cmd :eraseLine "%%A;!game.screen.screen_left_pos!"
)
set "current_line_pos=!game.screen.screen_bottom_pos!"
exit /b

::------------------------------------------------------------------------------
:: Confirm if the user wants to wear or read an item
::
:: Arguments: %1 - The prompt to display before getting input
::            %2 - The index of the item being manipulated
:: Returns:   0 if the user agrees
::            1 if the user wants to back out
::------------------------------------------------------------------------------
:verifyAction
call identification.cmd :itemDescription "description" "py.inventory[%~1]" "true"
set "description=!description:~0,-1!?"
call ui_io.cmd :getInputConfirmation "%~1 !description!"
exit /b !errorlevel!

::------------------------------------------------------------------------------
:: Update the inventory screen after something happens
::
:: Arguments: %1 - Determine if the user should be prompted to continue
:: Returns:   None
::------------------------------------------------------------------------------
:requestAndShowInventoryScreen
if "%game.doing_inventory_command%"=="0" (
    set "game.screen.screen_left_pos=0"
    set "game.screen.screen_bottom_pos=0"
    set "game.screen.current_screen_id=%Screen.Blank%"
    exit /b
)

if "%screen_has_changed%"=="true" (
    if "%~1"=="true" (
        set "game.doing_inventory_command=0"
        exit /b
    )
    call ui_io.cmd :getInputConfirmation "Continuing with inventory command?"
    if "!errorlevel!"=="1" (
        set "game.doing_inventory_command=0"
        exit /b
    )

    set "game.screen.screen_left_pos=50"
    set "game.screen.screen_bottom_pos=0"
)

set "current_screen=%game.screen.current_screen_id%"
set "game.screen.current_screen_id=%Screen.Wrong%"
call :uiCommandSwitchScreen "%current_screen%"
exit /b

::------------------------------------------------------------------------------
:: Handle unequipping items
::
:: Arguments: None
:: Returns:   0 if the player removes an item
::            1 if the player has nothing equipped or no room to store the item
::------------------------------------------------------------------------------
:uiCommandInventoryTakeOffItem
if "%py.equipment_count%"=="0" (
    call ui_io.cmd :printMessage "You are not using any equipment."
    exit /b 1
)

if %py.pack.unique_items% GEQ %PlayerEquipment.Wield% (
    if "%game.doing_inventory_command%"=="0" (
        call ui_io.cmd :printMessage "You will have to drop something first."
        exit /b 1
    )
)

if not "%game.screen.current_screen_id%"=="%Screen.Blank%" (
    call :uiCommandSwitchScreen "%Screen.Equipment%"
)
exit /b 0

::------------------------------------------------------------------------------
:: Handle dropping items
::
:: Arguments: %1 - A reference to the command given to get here
:: Returns:   0 if the player drops an item
::            1 if there is nothing to drop or if they are standing on something
::------------------------------------------------------------------------------
:uiCommandInventoryDropItem
if "%py.pack.unique_items%"=="0" (
    if "%py.equipment_count%"=="0" (
        call ui_io.cmd :printMessage "But you are not carrying anything."
        exit /b 1
    )
)

if not "!dg.floor[%py.pos.y%][%py.pos.x%].treasure_id!"=="0" (
    call ui_io.cmd :printMessage "There's no room to drop anything here."
    exit /b 1
)

set "set_command=0"
if "%game.screen.current_screen_id%"=="%Screen.Equipment%" (
    if %py.equipment_count% GTR 0 set "set_command=1"
)
if "%py.pack.unique_items%"=="0" set "set_command=1"
if "!set_command!"=="1" (
    if not "%game.screen.current_screen_id%"=="%Screen.Blank%" (
        call :uiCommandSwitchScreen "%Screen.Equipment%"
    )
    set "%~1=r"
) else if not "%game.screen.current_screen_id%"=="%Screen.Blank%" (
    call :uiCommandSwitchScreen "%Screen.Inventory%"
)
exit /b 0

::------------------------------------------------------------------------------
:: Validator for accessing the Wear screen
::
:: Arguments: None
:: Returns:   0 if the player was able to access the Wear screen
::            1 if the player has nothing to wear or wield
::------------------------------------------------------------------------------
:uiCommandInventoryWearWieldItem
set "game.screen.wear_low_id=0"
for /L %%A in (0,1,%py.pack.unique_items%) do (
    for /f "delims=" %%B in ("!game.screen.wear_low_id!") do (
        if !py.inventory[%%~B].category_id! GTR %TV_MAX_WEAR% (
            set /a game.screen.wear_low_id+=1
        )
    )
)

set "game.screen.wear_high_id=!game.screen.wear_low_id!"
for /L %%A in (!game.screen.wear_low_id!,1,%py.pack.unique_items%) do (
    for /f "delims=" %%B in ("!game.screen.wear_high_id!") do (
        if !py.inventory[%%~B].category_id! GEQ %TV_MIN_WEAR% (
            set /a game.screen.wear_high_id+=1
        )
    )
)
set /a game.screen.wear_high_id-=1

if !game.screen.wear_low_id! GTR !game.screen.wear_high_id! (
    call ui_io.cmd :printMessage "You have nothing to wear or wield."
    exit /b 1
)

if not "!game.screen.current_screen_id!"=="%Screen.Blank%" (
    if not "!game.screen.current_screen_id!"=="%Screen.Inventory%" (
        call :uiCommandSwitchScreen "%Screen.Wear%"
    )
)
exit /b 0

::------------------------------------------------------------------------------
:: Try to unwield an item
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:uiCommandInventoryUnwieldItem
call player.cmd :playerIsWieldingItem
if "!errorlevel!"=="1" (
    call ui_io.cmd :printMessage "But you are wielding no weapon."
    exit /b
)

call player.cmd :playerWornItemIsCursed "%PlayerEquipment.Wield%"
if "!errorlevel!"=="0" (
    call identification.cmd :itemDescription "description" "py.inventory[%PlayerEquipment.Wield%]" "false"
    call ui_io.cmd :printMessage "The !description! you are wielding appears to be cursed."
    exit /b
)

set "game.player_turn_free=false"

:: Swap auxiliary and wield weapons
call inventory.cmd :inventoryCopyItem "saved_item" "py.inventory[%PlayerEquipment.Auxiliary%]"
call inventory.cmd :inventoryCopyItem "py.inventory[%PlayerEquipment.Auxiliary%]" "py.inventory[%PlayerEquipment.Wield%]"
call inventory.cmd :inventoryCopyItem "py.inventory[%PlayerEquipment.Wield%]" "saved_item"

if "%game.screen.current_screen_id%"=="%Screen.Equipment%" (
    call :displayEquipment "%config.options.show_inventory_weights%" "%game.screen.screen_left_pos%"
    set "game.screen.screen_left_pos=!errorlevel!"
)

call player.cmd :playerAdjustBonusesForItem "py.inventory[%PlayerEquipment.Auxiliary%]" -1
call player.cmd :playerAdjustBonusesForItem "py.inventory[%PlayerEquipment.Wield%]" 1

if not "!py.inventory[%PlayerEquipment.Wield%].category_id!"=="%TV_NOTHING%" (
    set "label=Primary weapon   : "
    call inventory.cmd :itemDescription "description" "py.inventory[%PlayerEquipment.Wield%]" "true"
    call ui_io.cmd :printMessage "!label! !description!"
) else (
    call ui_io.cmd :printMessage "No primary weapon."
)

set "py.weapon_is_heavy=false"
call player.cmd :playerStrength
exit /b

::------------------------------------------------------------------------------
:: Look for an item based on provided search criteria
::
:: Arguments: %1 - The item to look for
::            %2 - The command that was used to get here
::            %3 - The first item in the inventory to look at
::            %4 - The last item in the inventory to look at
::: Returns:  The item_id of the selected item
::------------------------------------------------------------------------------
:inventoryGetItemMatchingInscription
set "which=%~1"
set "command=%~2"
set "from=%~3"
set "to=%~4"

call helpers.cmd :charToDec "%which%"
set "which_ascii=!errorlevel!"

if !which_ascii! GEQ 48 if !which_ascii! LEQ 57 (
    if not "%command%"=="r" if not "%command%"=="t" (
        set "m=%from%"
        call :inventoryGetItemMatchingInscriptionWhileLoop

        if !m! LEQ %to% (
            set "item_id=!m!"
        ) else (
            set "item_id=-1"
        )
    )
) else if !which_ascii! GEQ 65 if !which_ascii! LEQ 90 (
    set /a item_id=!which_ascii!-65
) else (
    set /a item_id=!which_ascii!-97
)
exit /b !item_id!

:inventoryGetItemMatchingInscriptionWhileLoop
set "tmp_m=!m!"
if !m! LEQ %to% (
    if !m! LSS %PLAYER_INVENTORY_SIZE% (
        set "m_inc=0"
        if not "!py.inventory[%tmp_m%].inscription:~0,1!"=="%which%" set "m_inc=1"
        if not "!py.inventory[%tmp_m%].inscription:~1,1!"=="" set "m_inc=1"
        if "!m_inc!"=="1" set /a m+=1
        goto :inventoryGetItemMatchingInscriptionWhileLoop
    )
)
exit /b

::------------------------------------------------------------------------------
:: Builds a prompt for later use
::
:: Arguments: %1 - A variable to hold the prompt string
::            %2 - An integer to represent the first item in the list
::            %3 - An integer to represent the last item in the list
::            %4 - A string to include a swap command
::            %5 - The command to perform the triggering action
::            %6 - The prompt string, a verbose form of %5
:: Returns:   None
::------------------------------------------------------------------------------
:buildCommandHeading
set "from=%~2"
set "to=%~3"
set "swap=%~4"
set "command=%~5"
set "str_prompt=%~6"

set /a from+=97, to+=97
cmd /c exit /b %from%
set "from_letter=!=ExitCodeAscii!"
cmd /c exit /b %to%
set "to_letter=!=ExitCodeAscii!"

set "list="
if "%game.screen.current_screen_id%"=="%Screen.Blank%" set "list=, * to list"

set "digits="
if "%command%"=="w" set "digits=, 0-9"
if "%command%"=="d" set "digits=, 0-9"

set "%~1=(%from_letter%-%to_letter%%list%%swap%%digits%, space to break, Q to quit) %str_prompt% which one?"
exit /b

::------------------------------------------------------------------------------
:: A wrapper for switching the screen while in the inventory
::
:: Arguments: %1 - The command passed to the menu
:: Returns:   None
::------------------------------------------------------------------------------
:changeScreenForCommand
if "%~1"=="t" (
    call :uiCommandSwitchScreen "%Screen.Equipment%"
) else if "%~1"=="r" (
    call :uiCommandSwitchScreen "%Screen.Equipment%"
) else if "%~1"=="w" (
    if not "%game.screen.current_screen_id%"=="%Screen.Inventory%" (
        call :uiCommandSwitchScreen "%Screen.Wear%"
    )
) else (
    call :uiCommandSwitchScreen "%Screen.Inventory%"
)
exit /b

::------------------------------------------------------------------------------
:: Toggle between the Equipment and Inventory screens
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:flipInventoryEquipmentScreens
if "%game.screen.current_screen_id%"=="%Screen.Equipment%" (
    call :uiCommandSwitchScreen "%Screen.Inventory%"
) else if "%game.screen.current_screen_id%"=="%Screen.Equipment%" (
    call :uiCommandSwitchScreen "%Screen.Equipment%"
)
exit /b

::------------------------------------------------------------------------------
:: Determine where to place rings, which famously can only go on one finger
:: per hand and can't share a hand with other rings
::
:: Arguments: None
:: Returns:   The PlayerEquipment enum value representing which hand to use
::------------------------------------------------------------------------------
:requestPutRingOnWhichHand
set "hand=0"

:requestPutRingOnWhichHandWhileLoop
call ui_io.cmd :getMenuItem "Put ring on which hand (l/r)?" "query"
if "!errorlevel!"=="1" (
    set "hand=-1"
) else (
    if /I "!query!"=="l" (
        set "hand=%PlayerEquipment.Left%"
    ) else if /I "!query!"=="r" (
        set "hand=%PlayerEquipment.Right%"
    ) else (
        call ui_io.cmd :terminalBellSound
        if not "!hand!"=="0" (
            call :verifyAction "Replace" "!hand!"
            if "!errorlevel!"=="1" set "hand=0"
        )
    )
)
if "!hand!"=="0" goto :requestPutRingOnWhichHandWhileLoop

exit /b !hand!

::------------------------------------------------------------------------------
:: Determine where an item is equipped
::
:: Arguments: %1 - The category_id of the specified item
:: Returns:   The PlayerEquipment enum where the item is equipped
::            -1 if the item is not equipped
::------------------------------------------------------------------------------
:inventoryGetSlotToWearEquipment
set "slot=-1"
set "slot[%TV_SLING_AMMO%]=%PlayerEquipment.Wield%"
set "slot[%TV_BOLT%]=%PlayerEquipment.Wield%"
set "slot[%TV_ARROW%]=%PlayerEquipment.Wield%"
set "slot[%TV_BOW%]=%PlayerEquipment.Wield%"
set "slot[%TV_HAFTED%]=%PlayerEquipment.Wield%"
set "slot[%TV_POLEARM%]=%PlayerEquipment.Wield%"
set "slot[%TV_SWORD%]=%PlayerEquipment.Wield%"
set "slot[%TV_DIGGING%]=%PlayerEquipment.Wield%"
set "slot[%TV_SPIKE%]=%PlayerEquipment.Wield%"
set "slot[%TV_LIGHT%]=%PlayerEquipment.Light%"
set "slot[%TV_BOOTS%]=%PlayerEquipment.Feet%"
set "slot[%TV_GLOVES%]=%PlayerEquipment.Hands%"
set "slot[%TV_CLOAK%]=%PlayerEquipment.Outer%"
set "slot[%TV_HELM%]=%PlayerEquipment.Head%"
set "slot[%TV_SHIELD%]=%PlayerEquipment.Arm%"
set "slot[%TV_HARD_ARMOR%]=%PlayerEquipment.Body%"
set "slot[%TV_SOFT_ARMOR%]=%PlayerEquipment.Body%"
set "slot[%TV_AMULET%]=%PlayerEquipment.Neck%"

if "%~1"=="%TV_RING%" (
    call player.cmd :playerRightHandRingEmpty
    if "!errorlevel!"=="0" (
        set "slot[%TV_RING%]=%PlayerEquipment.Right%"
    ) else (
        call player.cmd :playerLeftHandRingEmpty
        if "!errorlevel!"=="0" (
            set "slot[%TV_RING%]=%PlayerEquipment.Left%"
        ) else (
            call :requestPutRingOnWhichHand
            set "slot[%TV_RING%]=!errorlevel!"
        )
    )
)

if defined slot[%~1] (
    set "slot=!slot[%~1]!"
) else (
    call ui_io.cmd :printMessage "I don't see how you can use that."
)
exit /b %slot%

::------------------------------------------------------------------------------
:: Indicate that an item is cursed
::
:: Arguments: %1 - The item_id of the specified item
:: Returns:   None
::------------------------------------------------------------------------------
:inventoryItemIsCursedMessage
call identification.cmd :itemDescription "description" "py.inventory[%~1]" "false"
set "msg=The !description! you are"
if "%~1"=="%PlayerEquipment.Head%" (
    set "msg=!msg! wielding"
) else (
    set "msg=!msg! wearing"
)
call ui_io.cmd :printMessage "!msg! appears to be cursed."
exit /b

::------------------------------------------------------------------------------
:: Determine which item to remove
::
:: Arguments: %1 - Determines if the item is being selected or not
::            %2 - The item_id of the specified item
::            %3 - A reference to the command that was used to get here
::            %4 - The button that was pressed to specify the item
::            %5 - The prompt to display during verification
:: Returns:   0 if the item is not being removed
::            1 if the item will be removed
::------------------------------------------------------------------------------
:executeRemoveItemCommand
set "item_id=%~2"
set "command=%~3"
set "which=%~4"
set "str_prompt=%~5"

set "item_id_to_take_off=%~2"
set "item_id=21"
:executeRemoveItemCommandWhileLoop
set /a item_id+=1
for /f "delims=" %%A in ("!item_id!") do (
    if not "!py.inventory[%%~B].category_id!"=="%TV_NOTHING%" (
        set /a item_id_to_take_off-=1
    )
)
if %item_id_to_take_off% GEQ 0 goto :executeRemoveItemCommandWhileLoop

set "is_valid_letter=0"
call helpers.cmd :isUpper "%which%"
if "!errorlevel!"=="1" set /a is_valid_letter+=1
call :verifyAction "%str_prompt%" "%item_id%"
if "!errorlevel!"=="1" set /a is_valid_letter+=1
if "!is_valid_letter!"=="2" (
    set "item_id=-1"
) else (
    call inventory.cmd :inventoryItemIsCursed "py.inventory[%item_id%]"
    if "!errorlevel!"=="0" (
        set /a "item_id=-1"
        call ui_io.cmd :printMessage "Hmm, it seems to be cursed."
    ) else if "!%command%!"=="t" (
        call inventory.cmd :inventoryCanCarryItemCount "py.inventory[%item_id%]"
        if "!errorlevel!"=="1" (
            if not "!dg.floor[%py.pos.y%][%py.pos.x%].treasure_id!"=="0" (
                set "item_id=-1"
                call ui_io.cmd :printMessage "You can't carry it."
            ) else (
                call ui_io.cmd :getInputConfirmation "You can't carry it. Drop it?"
                if "!errorlevel!"=="0" (
                    set "%~3=r"
                ) else (
                    set "item_id=-1"
                )
            )
        )
    )
)

if %item_id% GEQ 0 (
    if "!%command%!"=="r" (
        call inventory.cmd :inventoryDropItem "%item_id%" "true"

        if "%py.pack.unique_items%"=="0" if "%py.equipment_count%"=="0" set "py.pack.weight=0"
    ) else (
        call inventory.cmd :inventoryCarryItem "py.inventory[%item_id%]"
        call player.cmd :playerTakeOff "%item_id%" "!errorlevel!"
    )

    call player.cmd :playerStrength
    set "game.player_free_turn=false"

    if "!%command%!"=="r" set "%~1=false"
)
exit /b %~1

::------------------------------------------------------------------------------
:: Determine which item to wear
::
:: Arguments: %1 - The item_id of the selected item
::            %2 - The choice that was selected in the menu
::            %3 - The prompt to display when verifying
:: Returns:   None
::------------------------------------------------------------------------------
:executeWearItemCommand
set "item_id=%~1"
set "which=%~2"
set "str_prompt=%~3"

set "slot=0"
set "is_valid_letter=0"
call helpers.cmd :isUpper "%which%" || set /a is_valid_letter+=1
call :verifyAction "%prompt%" "%item_id%" || set /a is_valid_letter+=1
if "!is_valid_letter!"=="2" (
    set "item_id=-1"
) else (
    call :inventoryGetSlotToWearEquipment "!py.inventory[%item_id%].category_id!"
    set "slot=!errorlevel!"
    if "!slot!"=="-1" set "item_id=-1"
)

if !item_id! GEQ 0 (
    if not "!py.inventory[%slot%].category_id!"=="%TV_NOTHING%" (
        call inventory.cmd :inventoryItemIsCursed "py.inventory[%slot%]"
        if "!errorlevel!"=="0" (
            call :inventoryItemIsCursedMessage "%slot%"
            set "item_id=-1"
        ) else if "!py.inventory[%item_id%].sub_category_id!"=="%ITEM_GROUP_MIN%" (
            if !py.inventory[%item_id%].items_count! GTR 1 (
                call inventory.cmd :inventoryCanCarryItemCount "py.inventory[%slot%]"
                if "!errorlevel!"=="1" (
                    call ui_io.cmd :printMessage "You will have to drop something first."
                    set "itemn_id=-1"
                )
            )
        )
    )
)

if "%item_id%"=="-1" exit /b

set "game.player_free_turn=false"

:: Remove the new item from the inventory
call inventory.cmd :inventoryCopyItem "saved_item" "py.inventory[%item_id%]"
call inventory.cmd :inventoryCopyItem "item" "saved_item"

set /a game.screen.wear_high_id-=1
if !item.items_count! GTR 1 (
    if !item.sub_category_id! LEQ %ITEM_SINGLE_STACK_MAX% (
        set "item.items_count=1"
        set /a game.screen.wear_high_id+=1
    )
)

set /a py.pack.weight+=!item.weight! * !item.items_count!
call inventory.cmd :inventoryDestroyItem "%item_id%"

:: Add the old item to the inventory and remove from the equipment list if necessary
call inventory.cmd :inventoryCopyItem "item" "py.inventory[%slot%]"
if not "!item.category_id!"=="%TV_NOTHING%" (
    set "uniq_items=%py.pack.unique_items%"
    call inventory.cmd :inventoryCarryItem "item"
    set "id=!errorlevel!"

    if not "!py.pack.unique_items!"=="!uniq_items!" set /a game.screen.wear_high_id+=1

    call player.cmd :playerTakeOff "%slot%" "!id!"
)

:: Wear the new item
call inventory.cmd :inventoryCopyItem "item" "saved_item"
set /a py.equipment_count+=1

call player.cmd :playerAdjustBonusesForItem "item" 1

set "text="
if "%slot%"=="%PlayerEquipment.Wield%" (
    set "text=You are wielding"
) else if "%slot%"=="%PlayerEquipment.Light%" (
    set "text=Your light source is"
) else (
    set "text=You are wearing"
)

call identification.cmd :itemDescription "description" "item" "true"
set "item_id_to_take_off=%PlayerEquipment.Wield%"
set "item_id=0"

for /L %%A in (%item_id_to_take_off%,1,%slot%) do (
    if not "!py.inventory[%%A].category_id!"=="%TV_NOTHING%" set /a item_id+=1
)

set /a item_letter=%item_id%+97
cmd /c exit /b !item_letter!
call ui_io.cmd :printMessage "!text! !description! (!=ExitCodeAscii!)"

if "%slot%"=="%PlayerEquipment.Wield%" set "py.weapon_is_heavy=false"
call player.cmd :playerStrength

call inventory.cmd :inventoryItemIsCursed "item"
call ui_io.cmd :printMessage "It feels deathly cold."
call identification.cmd :itemAppendToInscription "item" "%config.identification.ID_DAMD%"
set "!item.cost!=-1"
exit /b

::------------------------------------------------------------------------------
:: Actions for the Drop command
::
:: Arguments: %1 - The item_id of the item being dropped
::            %2 - The choice that was selected in the previous menu
::            %3 - The verification prompt
:: Returns:   None
::------------------------------------------------------------------------------
:executeDropItemCommand
set "item_id=%~1"
set "which=%~2"
set "str_prompt=%~3"

set "confirmed=-1"
if !py.inventory[%item_id%].items_count! GTR 1 (
    call identification.cmd :itemDescription "description" "py.inventory[%item_id%]" "true"
    set "description=!description:~0,-1!?"
    call ui_io.cmd :getInputConfirmationWithAbort 0 "Drop all !description!"
    set "confirmed=!errorlevel!"
    if "!confirmed!"=="-1" set "item_id=-1"
) else (
    call helpers.cmd :isUpper "%which%"
    if "!errorlevel!"=="1" (
        call :verifyAction "%prompt%" "%item_id%"
        if "!errorlevel!"=="1" set "item_id=-1"
    )
)

if %item_id! GEQ 0 (
    set "game.player_free_turn=false"
    if "!confirmed!"=="0" (
        set "bool_conf=true"
    ) else (
        set "bool_conf=false"
    )
    call inventory.cmd :inventoryDropItem "%item_id%" "!bool_conf!"
    call player.cmd :playerStrength
)

if "%py.pack.unique_items%"=="0" (
    if "%py.equipment_count%"=="0" (
        set "py.pack.weight=0"
    )
)
exit /b

::------------------------------------------------------------------------------
:: Select an item for later use
::
:: Arguments: %1 - The command that was given to get here
::            %2 - A variable to hold a subcommand
::            %3 - Determines if an item was selected or not
:: Returns:   0 if an item was selected
::            1 if the process was aborted or otherwise failed
::------------------------------------------------------------------------------
:selectItemCommands
set "command=%~1"
set "which=%~2"
set "selecting=%~3"

:selectItemCommandsWhileLoop
if "!selecting!"=="false" exit /b 1
if "!game.player_free_turn!"=="false" exit /b !bool_values[%selecting%]!

set "swap="
if "%command%"=="w" (
    set "from_line=%game.screen.wear_low_id%"
    set "to_line=%game.screen.wear_high_id%"
    set "str_prompt=Wear/Wield"
) else (
    set "from_line=0"
    if "%command%"=="d" (
        set /a to_line=%py.pack.unique_items% - 1
        set "str_prompt=Drop"

        if %py.equipment_count% GTR 0 (
            set "swap=, / for Equip"
        )
    ) else (
        set /a to_line=%py.equipment_count% - 1
        if "%command%"=="t" (
            set "str_prompt=Take off"
        ) else (
            set "str_prompt=Throw off"
            if %py.pack.unique_items% GTR 0 (
                set "swap=, / for Inven"
            )
        )
    )
)

if %from_line% GTR %to_line% exit /b 1

:: TODO: See if there are scenarios where only swap or only str_prompt are present
call :buildCommandHeading "heading_msg" "%from_line%" "%to_line%" "%swap%" "%str_prompt%"

:: Abort everything
call ui_io/cmd :getCommand "heading_msg" "%which%"
if "!errorlevel!"=="1" (
    set "which=Q"
    exit /b 1
)

:: Draw the screen and maybe exit main prompt
if "%which%"==" " (
    call :changeScreenForCommand "%command%"
    exit /b 1
)
if "%which%"=="*" (
    call :changeScreenForCommand "%command%"
    goto :selectItemCommandsWhileLoop
)

:: Swap screens for dropping items
if "%which%"=="/" (
    if not "%swap%"=="" (
        if "%command%"=="d" (
            set "command=r"
        ) else (
            set "command=d"
        )
        call :flipInventoryEquipmentScreens
        goto :selectItemCommandsWhileLoop
    )
)

:: Look for an item whose description matches "which"
call :inventoryGetItemMatchingInscription "%which%" "%command%" "%from_line%" "%to_line%"
set "item_id=!errorlevel!"
set "is_invalid=0"
if !item_id! LSS %from_line% set "is_invalid=1"
if !item_id! GTR %to_line% set "is_invalid=1"
if "!is_invalid!"=="1" (
    call ui_io.cmd :terminalBellSound
    goto :selectItemCommandsWhileLoop
)

:: Do something with the item that was found
if "%command%"=="r" (
    call :executeRemoveItemCommand "!selecting!" "%item_id%" "%command%" "%which%" "%str_prompt%" || exit /b 1
) else if "%command%"=="t" (
    call :executeRemoveItemCommand "!selecting!" "%item_id%" "%command%" "%which%" "%str_prompt%" || exit /b 1
) else if "%command%"=="w" (
    call :executeWearItemCommand "%item_id%" "%which%" "%str_prompt%"
) else (
    call :executeDropItemCommand "%item_id%" "%which%" "%str_prompt%"
    exit /b 1
)

if "!game.player_free_turn!"=="false" (
    if "%game.screen.current_screen_id%"=="%Screen.Blank%" (
        exit /b 1
    )
)
goto :selectItemCommandsWhileLoop

::------------------------------------------------------------------------------
:: Generate a header line based on the current screen ID
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:inventoryDisplayAppropriateHeader
if "%game.screen.current_screen_id%"=="%Screen.Inventory%" (
    set /a weight_quotient=%py.pack.weight% / 10
    set /a weight_remainder=%py.pack.weight% %% 10

    set "no_weights=0"
    if "%config.options.show_inventory_weights%"=="false" set "no_weights=1"
    if "%py.pack.unique_items%"=="0" set "no_weights=1"

    if "!no_weights!"=="1" (
        if "%py.pack.unique_items%"=="0" (
            set "pack_list=nothing."
        ) else (
            set "pack_list=-"
        )
        set "msg=You are carrying !weight_quotient!.!weight_remainder! pounds. In your pack there is !pack_list!"
    ) else (
        call player.cmd :playerCarryingLoadList
        set "full_capacity=!errorlevel!"
        set /a capacity_quotient=!full_capacity!/10, capacity_remainder=!full_capacity!%%10
        set "msg=You are carrying !weight_quotient!.!weight_remainder! pounds. Your capacity is !capacity_quotient!.!capacity_remainder! pounds. In your pack is -"
    )
    call ui_io.cmd :putStringClearToEOL "!msg!" "0;0"
) else if "%game.screen.current_screen_id%"=="%Screen.Wear%" (
    if %game.screen.wear_high_id% LSS %game.screen.wear_low_id% (
        call ui_io.cmd :putStringClearToEOL "You have nothing you could wield." "0;0"
    ) else (
        call ui_io.cmd :putStringClearToEOL "You could wield -" "0;0"
    )
) else if "%game.screen.current_screen_id%"=="%Screen.Equipment%" (
    if "%py.equipment_count%"=="0" (
        call ui_io.cmd :putStringClearToEOL "You are not using anything." "0;0"
    ) else (
        call ui_io.cmd :putStringClearToEOL "You are using -" "0;0"
    )
) else (
    call ui_io.cmd :putStringClearToEOL "Allowed commands:" "0;0"
)

call ui_io.cmd :eraseLine "%game.screen.screen_bottom_pos%;%game.screen.screen_left_pos%"
exit /b

::------------------------------------------------------------------------------
:: Display the Inventory screen if the player has things
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:uiCommandDisplayInventory
if "%py.pack.unique_items%"=="0" (
    call ui_io.cmd :printMessage "You are not carrying anything."
) else (
    call :uiCommandSwitchScreen "%Screen.Inventory%"
)
exit /b

::------------------------------------------------------------------------------
:: Display the Equipment screen if the player has things equipped
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:uiCommandDisplayEquipment
if "%py.equipment_count%"=="0" (
    call ui_io.cmd :printMessage "You are not using any equipment."
) else (
    call :uiCommandSwitchScreen "%Screen.Equipment%"
)
exit /b

::------------------------------------------------------------------------------
:: The main Inventory subroutine
::
:: Arguments: %1 - The command that was given to get here
:: Returns:   None
::------------------------------------------------------------------------------
:inventoryExecuteCommand
set "command=%~1"
set "game.player_free_turn=true"
call ui_io.cmd :terminalSaveScreen

set "recover_screen=false"
if "%command%"==" " set "recover_screen=true"
call :requestAndShowInventoryScreen "%recover_screen%"

:inventoryExecuteCommandWhileLoop
set "selecting=false"
if /I "%command%"=="i" (
    call :uiCommandDisplayInventory
) else if /I "%command%"=="e" (
    call :uiCommandDisplayEquipment
) else if /I "%command%"=="t" (
    call :uiCommandInventoryTakeOffItem "!selecting!"
    if "!errorlevel!"=="0" set "selecting=true"
) else if /I "%command%"=="d" (
    call :uiCommandInventoryDropItem "%command%" "!selecting!"
    if "!errorlevel!"=="0" set "selecting=true"
) else if /I "%command%"=="w" (
    call :uiCommandInventoryWearWieldItem "!selecting!"
    if "!errorlevel!"=="0" set "selecting=true"
) else if /I "%command%"=="x" (
    call :uiCommandInventoryUnwieldItem
) else if /I "%command%"=="?" (
    call :uiCommandSwitchScreen "%Screen.Help%"
) else if /I "%command%"==" " (
    REM dummy command to return to the main prompt
) else (
    call ui_io.cmd :terminalBellSound
)

set "game.doing_inventory_command=0"
set "which=z"

call :selectItemCommands "%command%" "which" "!selecting!"
if "!errorlevel!"=="0" (
    set "selecting=true"
) else (
    set "selecting=false"
)

if "!which!"=="Q" (
    set "command=Q"
) else if "%game.screen.current_screen_id%"=="%Screen.Blank%" (
    set "command=Q"
) else if "!game.player_free_turn!"=="false" (
    REM Save state for recovery in case this is called again
    if "!selecting!"=="true" (
        set "game.doing_inventory_command=!command!"
    ) else (
        set "game.doing_inventory_command= "
    )

    REM Flush last message before clearing screen_has_changed
    call ui_io.cmd :printMessage "CNIL"

    REM Let us know if the world has changed
    set "screen_has_changed=false"
    set "command=Q"
) else (
    call :inventoryDisplayAppropriateHeader
    call ui_io.cmd :putString "e\i\t\w\x\d\?\Q:" "%game.screen.screen_bottom_pos%;60"
    call ui_io.cmd :getKeyInput command
    call ui_io.cmd :eraseLine "%game.screen.screen_bottom_pos%;%game.screen.screen_left_pos%"
)
if not "!command!"=="Q" goto :inventoryExecuteCommandWhileLoop

if not "%game.screen.current_screen_id%"=="%Screen.Blank%" call ui_io.cmd :terminalRestoreScreen
call player.cmd :playerRecalculateBonuses
exit /b

::------------------------------------------------------------------------------
:: Switch between the Equipment and Inventory menus
::
:: Arguments: %1 - The prompt to display
::            %2 - A reference to which menu to display
::            %3 - Determines if the menu is active
::            %4 - A reference to the item_id of the last item in the menu
:: Returns:   0 if the menu changed
::            1 if the player did not change the menu
::------------------------------------------------------------------------------
:inventorySwitchPackMenu
set "str_prompt=%~1"
set "menu_active=%~3"
set "item_id_end=%~4"

if "!%~2!"=="%PackMenu.Inventory%" (
    set "changed=1"

    if "%py.equipment_count%"=="0" (
        call ui_io.cmd :putStringClearToEOL "But you're not using anything -more-" "0;0"
        call ui_io.cmd :getKeyInput "dummy"
    ) else (
        set "%~2=%PackMenu.Equipment%"
        set "changed=0"

        if "%menu_active%"=="true" (
            set "%~4=%py.equipment_count%"
            set /a unique_items_dec=%py.pack.unique_items%-1
            for /L %%A in (!%~4!,1,!unique_items_dec!) do (
                call ui_io.cmd :eraseLine "%%A;0"
            )
        )
        set /a item_id_end=%py.equipment_count%-1
    )

    call ui_io.cmd :putStringClearToEOL "%str_prompt%" "0;0"
    exit /b !changed!
)

if "%py.pack.unique_items%"=="0" (
    call ui_io.cmd :putStringClearToEOL "But you're not carrying anything -more-" "0;0"
    call ui_io.cmd :getKeyInput "dummy"
    exit /b 1
)

set "%~2=%PackMenu.Inventory%"
if "!menu_active!"=="true" (
    set "%~4=%py.pack.unique_items%"
    set /a unique_items_dec=%py.pack.unique_items%-1
    for /L %%A in (!%~4!,1,!unique_items_dec!) do (
        call ui_io.cmd :eraseLine "%%A;0"
    )
)
set /a %~4=%py.equipment_count%-1
exit /b !changed!

::------------------------------------------------------------------------------
:: Get the item_id of an item and return its menu letter value
::
:: Arguments: %1 - A variable to store the command key in
::            %2 - The prompt to display
::            %3 - The item_id of the first item in the list
::            %4 - The item_id of the last item in the list
::            %5 - A filter to only return certain items
::            %6 - A message to display, if any
:: Returns:   0 if an item is found
::            1 if the player does not select an item
::------------------------------------------------------------------------------
:inventoryGetInputForItemId
set "str_prompt=%~2"
set "item_id_start=%~3"
set "item_id_end=%~4"
set "mask=%~5"
set "message=%~6"

set "menu=%PackMenu.Inventory%"
set "pack_full=false"

if %item_id_end% GTR %PlayerEquipment.Wield% (
    set "pack_full=true"

    if "%py.pack.unique_items%"=="0" (
        set "menu=%PackMenu.Equipment%"
        set /a item_id_end=%py.equipment_count%-1
    ) else (
        set /a item_id_end=%py.pack.unique_items%-1
    )
)

if %py.pack.unique_items% LSS 1 (
    set "no_items=0"
    if "!pack_full!"=="false" set "no_items=1"
    if %py.equipment_count% LSS 1 set "no_items=1"
    if "!no_items!"=="1" (
        call ui_io.cmd :putStringClearToEOL "You are not carrying anything." "0;0"
        exit /b 1
    )
)

set "%~1="
set "item_found=false"
set "menu_active=false"

:inventoryGetInputForItemIdWhileLoop
if "!menu_active!"=="true" (
    if "%menu%"=="%PackMenu.Inventory%" (
        call :displayInventoryItems "%item_id_start%" "%item_id_end%" "false" "80" "%mask%"
    ) else (
        call :displayEquipment "false" "80"
    )
)

:: These are in both if statements no matter what
set /a item_start_ascii=!item_id_start!+97, item_end_ascii=!item_id_end!+97
cmd /c exit /b !item_start_ascii!
set "item_id_start_letter=!=ExitCodeAscii!"
cmd /c exit /b !item_end_ascii!
set "item_id_end_letter=!=ExitCodeAscii!"
if "%menu%"=="%PackMenu.Inventory%" (set "num_range=0-9") else (set "num_range=")

if "!pack_full!"=="true" (
    if "%menu%"=="%PackMenu.Inventory%" (set "disp_menu=Inven") else (set "disp_menu=Equip")
    if "!menu_active!"=="true" (set "opt_cmd=") else (set "opt_cmd= * to see,")
    if "%menu%"=="%PackMenu.Inventory%" (set "toggle_name=Equip") else (set "toggle_name=Inven")
    set "description=(!disp_menu!: !item_id_start_letter!-!item_id_end_letter!,!num_range!!opt_cmd! / for !toggle_name!, or Q) %str_prompt%"
) else (
    if "!menu_active!"=="true" (set "opt_cmd=") else (set "opt_cmd= * for inventory list,")
    set "description=(Items !item_id_start_letter!-!item_id_end_letter!,!num_range!!opt_cmd! Q to quit) %str_prompt%"
)

call :ui_io.cmd :putStringClearToEOL "!description!" "0;0"

set "done=false"
:inventoryGetInputForItemIdInnerWhileLoop
if "!done!"=="true" goto :inventoryGetInputForItemIdAfterInnerWhileLoop
call ui_io.cmd :getKeyInput "which"
if "!which!"=="Q" (
    set "menu=%PackMenu.CloseMenu%"
    set "done=true"
    set "game.player_free_turn=true"
) else if "!which!"=="/" (
    call :inventorySwitchPackMenu "str_prompt" "menu" "!menu_active!" "item_id_end"
) else if "!which!"=="*" (
    if "!menu_active!"=="false" (
        set "done=true"
        call ui_io.cmd :terminalSaveScreen
        set "menu_active=true"
    )
) else (
    call helpers.cmd :charToDec "%which%"
    set "which_ascii=!errorlevel!"

    if !which_ascii! GEQ 48 if !which_ascii! LEQ 57 (
        if not "!menu!"=="%PackMenu.Equipment%" (
            set "m=!item_id_start!"
            for /L %%M in (!item_id_start!,1,%PlayerEquipment.Wield%) do (
                set "inc_m=0"
                if not "!py.inventory[%%A].inscription:~0,1!"=="!which!" set "inc_m=1"
                if not "!py.inventory[%%A].inscription:~1,1!"=="" set "inc_m=1"
                if "!inc_m!"=="1" set /a m+=1
                set "inc_m="
            )

            if !m! LSS %PlayerEquipment.Wield% (
                set "%~1=!m!"
            ) else (
                set "%~1=-1"
            )
        )
    ) else if !which_ascii! GEQ 65 if !which_ascii! LEQ 90 (
        set /a item_id=!which_ascii!-65
    ) else (
        set /a item_id=!which_ascii!-97
    )

    set "valid_item=0"
    if !%~1! GEQ !item_id_start! set /a valid_item+=1
    if !%~1! LEQ !item_id_end! set /a valid_item+=1
    set "no_mask=0"
    if "%mask%"=="CNIL" set "no_mask=1"
    if not "!mask:~%~1,1!"=="" set "no_mask=1"
    if "!no_mask!"=="1" set /a valid_item+=1


    if "!valid_item!"=="3" (
        if "!menu!"=="%PackMenu.Equipment%" (
            set "item_id_start=21"
            set "item_id_end=!%~1!"

            for /L %%A in (!item_id_start!,-1,0) do (
                set /a item_id_start+=1
                call :inventoryGetInputForItemIdInnermostWhileLoop "item_id_start"
            )
            set "%~1=!item_id_start!"
        )

        call :verifyAction "Try" "!%~1!"
        if "!errorlevel!"=="1" (
            set "menu=%PackMenu.CloseMenu%"
            set "done=true"
            set "game.player_free_turn=true"
            goto :inventoryGetInputForItemIdInnerWhileLoop
        )

        set "menu=%PackMenu.CloseMenu%"
        set "done=true"
        set "item_found=true"
    ) else if not "%message%"=="" (
        call ui_io.cmd :printMessage "%message%"
        set "done=true"
    ) else (
        call ui_io.cmd :terminalBellSound
    )
)
goto :inventoryGetInputForItemIdAfterInnerWhileLoop

:inventoryGetInputForItemIdAfterInnerWhileLoop
if not "!menu!"=="%PackMenu.CloseMenu%" goto :inventoryGetInputForItemIdWhileLoop

:inventoryGetInputForItemIdAfterWhileLoop
if "!menu_active!"=="true" call ui_io.cmd :terminalRestoreScreen
call ui_io.cmd :messageLineClear
exit /b !item_found!

:: The C++ code has a quadruple-nested while loop. Nope.
:inventoryGetInputForItemIdInnermostWhileLoop
set "itemIdStart=!%~1!"
:inventoryGetInputForItemIdInnermostWhileLoopNext
if not "!py.inventory[%itemIdStart%].category_id!"=="%TV_NOTHING%" (
    set "%~1=!itemIdStart!"
    exit /b
)
set /a itemIdStart+=1
goto :inventoryGetInputForItemIdInnermostWhileLoopNext