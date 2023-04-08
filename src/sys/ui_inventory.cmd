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

:requestAndShowInventoryScreen
exit /b

:uiCommandInventoryTakeOffItem
exit /b

:uiCommandInventoryDropItem
exit /b

:uiCommandInventoryWearWieldItem
exit /b

:uiCommandInventoryUnwieldItem
exit /b

:inventoryGetItemMatchingInscription
exit /b

:buildCommandHeading
exit /b

:changeScreenForCommand
exit /b

:flipInventoryEquipmentScreens
exit /b

:requestPutRingOnWhichHand
exit /b

:inventoryGetSlotToWearEquipment
exit /b

:inventoryItemIsCursedMessage
exit /b

:executeRemoveItemCommand
exit /b

:executeWearItemCommand
exit /b

:executeDropItemCommand
exit /b

:selectItemCommands
exit /b

:inventoryDisplayAppropriateHeader
exit /b

:uiCommandDisplayInventory
exit /b

:uiCommandDisplayEquipment
exit /b

:inventoryExecuteCommand
exit /b

:inventorySwitchPackMenu
exit /b

:inventoryGetInputForItemId
exit /b
