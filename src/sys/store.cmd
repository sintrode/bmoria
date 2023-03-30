@echo off
call %*
exit /b

::------------------------------------------------------------------------------
:: Sets up stores and owners
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:storeInitializeOwners
set /a count=%MAX_OWNERS%/%MAX_STORES%, store_dec=%MAX_STORES%-1

for /L %%A in (0,1,%store_dec%) do (
    set "store=stores[%%A]"
    call rng.cmd :randomNumber %count%
    set /a "%store%.owner_id=%MAX_STORES% * (!errorlevel! - 1) + %%A"
    for %%B in (insults_counter turns_left_before_closing
                unique_items_counter good_purchases bad_purchases) do (
        set "%store%.%%~B=0"
    )

    for /L %%A in (0,1,23) do (
        call inventory.cmd :inventoryItemCopyTo "%config.dungeon.objects.OBJ_NOTHING%" "%store%.inventory[%%A].item"
        set "%store%.inventory[%%A].cost=0"
    )
)
exit /b

::------------------------------------------------------------------------------
:: Print a statement at the end of haggling
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:printSpeechFinishedHaggling
call rng.cmd :randomNumber 14
set /a final_speech=!errorlevel!-1
call ui_io.cmd :printMessage "!speech_sale_accepted[%final_speech%]!"
exit /b

::------------------------------------------------------------------------------
:: Respond to a sell haggle offer with a response
::
:: Arguments: %1 - The amount offered by the player
::            %2 - The amount requested by the owner
::            %3 - The number of times that the owner has been insulted
:: Returns:   None
::------------------------------------------------------------------------------
:printSpeechSellingHaggle
if %~3 GTR 0 (
    call rng.cmd :randomNumber 3
    set /a comment_index=!errorlevel!-1
    for /f "delims=" %%A in ("!comment_index!") do set "comment=!speech_selling_haggle_final[%%~A]!"
) else (
    call rng.cmd :randomNumber 16
    set /a comment_index=!errorlevel!-1
    for /f "delims=" %%A in ("!comment_index!") do set "comment=!speech_selling_haggle[%%~A]!"
)

call helpers.cmd :insertNumberIntoString "comment" "_A1" "%~1" "false"
call helpers.cmd :insertNumberIntoString "comment" "_A2" "%~2" "false"
call ui_io.cmd :printMessage "!comment!"
exit /b

::------------------------------------------------------------------------------
:: Respond to a buy haggle offer with a response
:: TODO: Merge the two subroutines into a single one
::
:: Arguments: %1 - The amount offered by the player
::            %2 - The amount requested by the owner
::            %3 - The number of times that the owner has been insulted
:: Returns:   None
::------------------------------------------------------------------------------
:printSpeechBuyingHaggle
if %~3 GTR 0 (
    call rng.cmd :randomNumber 3
    set /a comment_index=!errorlevel!-1
    for /f "delims=" %%A in ("!comment_index!") do set "comment=!speech_buying_haggle_final[%%~A]!"
) else (
    call rng.cmd :randomNumber 15
    set /a comment_index=!errorlevel!-1
    for /f "delims=" %%A in ("!comment_index!") do set "comment=!speech_buying_haggle[%%~A]!"
)

call helpers.cmd :insertNumberIntoString "comment" "_A1" "%~1" "false"
call helpers.cmd :insertNumberIntoString "comment" "_A2" "%~2" "false"
call ui_io.cmd :printMessage "!comment!"
exit /b

::------------------------------------------------------------------------------
:: Kick the player out after they insult the owner too many times
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:printSpeechGetOutOfMyStore
call rng.cmd :randomNumber 5
set /a comment_index=!errorlevel!-1
call ui_io.cmd :printMessage "!speech_insulted_haggling_done[%comment_index%]!"
call ui_io.cmd :printMessage "!speech_get_out_of_my_store[%comment_index%]!"
exit /b

::------------------------------------------------------------------------------
:: Tells the player to try again
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:printSpeechTryAgain
call rng.cmd :randomNumber 10
set /a comment_index=!errorlevel!-1
call ui_io.cmd :printMessage "!speech_haggling_try_again[%comment_index%]!"
exit /b

::------------------------------------------------------------------------------
:: Don't let the player offer more than is asked for some reason
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:printSpeechSorry
call rng.cmd :randomNumber 5
set /a comment_index=!errorlevel!-1
call ui_io.cmd :printMessage "!speech_sorry[%comment_index%]!"
exit /b

::------------------------------------------------------------------------------
:: Displays the store menu
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:displayStoreCommands
call ui_io.cmd :putStringClearToEOL "You may:" "20;0"
call ui_io.cmd :putStringClearToEOL " p) Purchase an item.           b) Browse store's inventory." "21;0"
call ui_io.cmd :putStringClearToEOL " s) Sell an item.               i/e/t/w/x) Inventory/Equipment Lists." "22;0"
call ui_io.cmd :putStringClearToEOL " Q) Exit from Building.        R) Redraw the screen." "23;0"
exit /b

::------------------------------------------------------------------------------
:: Displays the set of commands
::
:: Arguments: %1 -  1 if the player is buying
::                 -1 if the player is selling
:: Returns:   None
::------------------------------------------------------------------------------
:displayStoreHaggleCommands
if "%~1"=="-1" (
    call ui_io.cmd :putStringClearToEOL "Specify an asking price in gold pieces." "21;0"
) else (
    call ui_io.cmd :putStringClearToEOL "Specify an offer in gold pieces." "21;0"
)
call ui_io.cmd :putStringClearToEOL "Q) Quit Haggling." "22;0"
call ui_io.cmd :eraseLine "23;0"
exit /b

::------------------------------------------------------------------------------
:: Display the store's inventory
::
:: Arguments: %1 - A reference to the current store
::            %2 - The first item in the inventory
:: Returns:   None
::------------------------------------------------------------------------------
:displayStoreInventory
set "item_pos_start=%~2"
set /a item_pos_end=((%item_pos_start% / 12) + 1) * 12
if %item_pos_end% GTR !%~1.unique_items_counter! (
    set "item_pos_end=!%~1.unique_items_counter!"
)

set /a loop_end=%item_pos_end%-1
for /L %%A in (%item_pos_start%,1,%loop_end%) do (
    set /a item_line_num=%%A %% 12
    set "current_item_count=!%store%.inventory[%item_pos_start%].item.items_count!"
    call inventory.cmd :inventoryItemSingleStackable "%store%.inventory[%item_pos_start%].item"
    if "!errorlevel!"=="0" set "%store%.inventory[%item_pos_start%].item.items_count=1"

    call identification.cmd :itemDescription "description" "%store%.inventory[%item_pos_start%].item" "true"
    set "%store%.inventory[%item_pos_start%].item.items_count=!current_item_count!"

    set /a item_letter=!item_line_num!+97, item_y_coord=!item_line_num!+5
    cmd /c exit /b !item_letter!
    set "msg=!=ExitCodeAscii!) !description!"
    call ui_io.cmd putStringClearToEOL "!msg!" "!item_y_coord!;0"

    set "current_item_count=!%store%.inventory[%item_pos_start%].cost!"
    if !current_item_count! LEQ 0 (
        set /a value=!current_item_count! * -1
        call player_stats.cmd :playerStatAdjustmentCharisma
        set /a value=!value! * !errorlevel! / 100
        if !value! LEQ 0 set "value=1"
        call scores.cmd :sprintf "msg" "!value!" 9
    ) else (
        call scores.cmd :sprintf "msg" "!current_item_count!" 9
        set "msg=!msg! [fixed]"
    )

    call ui_io.cmd putStringClearToEOL "!msg!" "!item_y_coord!;59"
)
if !item_line_num! LSS 12 (
    set /a i_max=11-!item_line_num!
    for /L %%A in (0,1,!i_max!) do (
        set /a line_index=%%A + !item_line_num! + 5
        call ui_io.cmd :eraseLine "!line_index!;0"
    )
)

if !%store%.unique_items_counter! GTR 12 (
    call ui_io.cmd :putString "- cont. -" "17;60"
) else (
    call ui_io.cmd :eraseLine "17;60"
)
exit /b

:displaySingleCost
exit /b

:displayPlayerRemainingGold
exit /b

:displayStore
exit /b

:storeGetItemId
exit /b

:storeIncreaseInsults
exit /b

:storeDecreaseInsults
exit /b

:storeHaggleInsults
exit /b

:storeGetHaggle
exit /b

:storeReceiveOffer
exit /b

:storePurchaseCustomerAdjustment
exit /b

:storePurchaseHaggle
exit /b

:storeSellCustomerAdjustment
exit /b

:storeSellHaggle
exit /b

:storeItemsToDisplay
exit /b

:storePurchaseAnItem
exit /b

:setGeneralStoreItems
exit /b

:setArmoryItems
exit /b

:setWeaponsmithItems
exit /b

:setTempleItems
exit /b

:setAlchemistItems
exit /b

:setMagicShopItems
exit /b

:storeSellAnItem
exit /b

:storeEnter
exit /b

:storeNoNeedToBargain
exit /b

:storeUpdateBargainingSkills
exit /b

