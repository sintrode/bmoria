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

::------------------------------------------------------------------------------
:: Displays a single cost
::
:: Arguments: %1 - The store_id of the current store
::            %2 - The item_id of the item whose cost is being displayed
:: Returns:   None
::------------------------------------------------------------------------------
:displaySingleCost
set "cost=!stores.[%~1].inventory[%~2].cost!"

if !cost! LSS 0 (
    set /a c=!cost!*-1
    call player_stats.cmd :playerStatAdjustmentCharisma
    set /a c=!c! * !errorlevel! / 100
    set "msg=!c!"
) else (
    call scores.cmd :sprintf "msg" "!current_item_count!" 9
    set "msg=!msg! [fixed]"
)
set /a item_y_coord=(%~2 %% 12) + 5
call ui_io.cmd putStringClearToEOL "!msg!" "!item_y_coord!;59"
exit /b

::------------------------------------------------------------------------------
:: Displays the player's remaining gold
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:displayPlayerRemainingGold
call ui_io.cmd :putStringClearToEOL "Gold Remaining: %py.misc.au%" "18;17"
exit /b

::------------------------------------------------------------------------------
:: A wrapper for the store's main gameplay loop
::
:: Arguments: %1 - A reference to the current store
::            %2 - The name of the store owner
::            %3 - The item_id of the first item in the inventory
:: Returns:   None
::------------------------------------------------------------------------------
:displayStore
call ui_io.cmd :clearScreen
call ui_io.cmd :putString "%~2" "3;9"
call ui_io.cmd :putString "Item" "4;3"
call ui_io.cmd :putString "Asking Price" "4;60"
call :displayPlayerRemainingGold
call :displayStoreCommands
call :displayStoreInventory "%~1" "%~3"
exit /b

::------------------------------------------------------------------------------
:: Gets the ID of a store item
::
:: Arguments: %1 - A variable to store the item_id of the selected item
::            %2 - A prompt to display when selecting an item
::            %3 - The index of the first valid item in the range
::            %4 - The index of the last valid item in the range
:: Returns:   0 if an item was found
::            1 if no valid item was selected
::------------------------------------------------------------------------------
:storeGetItemId
set "%~1=-1"
set "item_found=1"

set /a disp_index_start=%~3+97, disp_index_end=%~4+97
cmd /c exit /b %disp_index_start%
set "disp_start=!=ExitCodeAscii!"
cmd /c exit /b %disp_index_end%
set "disp_end=!=ExitCodeAscii!"
set "msg=(Items !disp_start!-!disp_end!, Q to exit) %~2"

:storeGetItemIdWhileLoop
call ui_io.cmd :getMenuItemId "msg" "key_char"
set /a key_char-=97
if !key_char! GEQ %~3 (
    if !key_char! LEQ %~4 (
        set "item_found=0"
        set item_id=!key_char!
        goto :storeGetItemIdAfterWhileLoop
    )
    call ui_io.cmd :terminalBellSound
)
:storeGetItemIdAfterWhileLoop
call ui_io.cmd :messageLineClear
exit /b !item_found!

::------------------------------------------------------------------------------
:: Increase the insult counter and kick the player out if necessary
::
:: Arguments: %1 - The store_id of the current store
:: Returns:   0 if the owner is insulted
::            1 if the player is on thin ice
::------------------------------------------------------------------------------
:storeIncreaseInsults
set "store=stores[%~1]"

set /a %store%.insults_counter+=1
if !%store%.insults_counter! LEQ !store_owners[%~1].max_insults! exit /b 1

call :printSpeechGetOutOfMyStore
set "%store%.insults_counter=0"
set /a %store%.bad_purchases+=1
call rng.cmd :randomNumber 2500
set %store%.turns_left_before_closing=%dg.game_turn% + 2500 + !errorlevel!
exit /b 0

::------------------------------------------------------------------------------
:: Decrease the insult counter
::
:: Arguments: %1 - The store_id of the current store
:: Returns:   None
::------------------------------------------------------------------------------
:storeDecreaseInsults
if not "!stores[%~1].insults_counter!"=="0" set /a stores[%~1].insults_counter-=1
exit /b

::------------------------------------------------------------------------------
:: Check to see if the owner was insulted while haggling
::
:: Arguments: %1 - The store_id of the current store
:: Returns:   0 if the owner was insulted
::            1 if the player has not yet insulted the owner
::------------------------------------------------------------------------------
:storeHaggleInsults
call :storeIncreaseInsults %~1 && exit /b 0

call :printSpeechTryAgain
call ui_io.cmd :printMessage "CNIL"
exit /b 1

::------------------------------------------------------------------------------
:: Checks to see if the customer made a valid offer while haggling
::
:: Arguments: %1 - The prompt to display at the beginning of the haggle
::            %2 - A variable to store the amount of the new offer
::            %3 - The numer of times that the player has made an offer
:: Returns:   0 if the offer is valid
::            1 if the player aborts before making an offer
::------------------------------------------------------------------------------
:storeGetHaggle
set "offer_count=%~3"
set "valid_offer=0"

if "%offer_count%"=="0" set "store_last_increment=0"
set "increment=false"
set "adjustment=0"

call helpers.cmd :getLength "%~1" "prompt_len"
set "start_len=%prompt_len%"

set "msg="
set "last_offer_str="

:storeGetHaggleWhileLoop
if "!valid_offer!"=="false" goto :storeGetHaggleAfterWhileLoop
if not "!adjustment!"=="0" goto :storeGetHaggleAfterWhileLoop
call ui_io.cmd :putStringClearToEOL "%~1" "0;0"

if not "%offer_count%"=="0" (
    if not "!store_last_increment!"=="0" (
        set "abs_store_last_increment=!store_last_increment!"
        if !abs_store_last_increment! LSS 0 set /a store_last_increment*=-1

        if !store_last_increment! LSS 0 (
            set "c=-"
        ) else (
            set "c=+"
        )
        set "last_offer_str=[!c!!abs_store_last_increment!]"
        call ui_io.cmd :putStringClearToEOL "!last_offer_str!" "0;!start_len!"

        call helpers.cmd :getLength "!last_offer_str!" "last_offer_str_len"
        set /a prompt_len=!start_len!+!last_offer_str_len!
    )
)

call ui_io.cmd :getStringInput "msg" "0;!prompt_len!" 40
if "!errorlevel!"=="1" set "valid_offer=false"

:: Check to see if we're in Increment mode rather than Full Offer mode
:: TODO: check to see if we need to strip leading spaces
if "!msg:-0,1!"=="-" set "increment=true"
if "!msg:-0,1!"=="+" set "increment=true"

if not "!offer_count!"=="0" (
    if "!increment!"=="true" (
        if "!adjustment!"=="0" (
            set "increment=false"
        ) else (
            set "store_last_increment=!adjustment!"
        )
    )

    if not defined msg (
        set "adjustment=!store_last_increment!"
        set "increment=true"
    )
) else (
    set "msg=!adjustment!"
)
goto :storeGetHaggleWhileLoop

:storeGetHaggleAfterWhileLoop
if "!valid_offer!"=="true" (
    if "!increment!"=="true" (
        set /a new_offer+=!adjustment!
    ) else (
        set "new_offer=!adjustment!"
    )
) else (
    call ui_io.cmd :messageLineClear
)
exit /b !valid_offer!

::------------------------------------------------------------------------------
:: Process a haggle offer from the player
::
:: Arguments: %1 - The store_id of the current store
::            %2 - The prompt to display while haggling
::            %3 - A variable to store the new offer
::            %4 - The previous offer given by the player
::            %5 - The number of times the player has haggled
::            %6 - A multiplier for whether the player is buying or selling
:: Returns:   0 if the bid was successful
::            1 if the bid was rejected or cancelled by the customer
::            2 if the customer tried to sell something broken or cursed
::            3 if the store owner was insulted too many times by the bid
::------------------------------------------------------------------------------
:storeReceiveOffer
set "status=%BidState.Received%"
set "done=false"

:storeReceiveOfferWhileLoop
if "!done!"=="true" exit /b !status!
call :storeGetHaggle "%~2" "%~3" "%~5"
if "!errorlevel!"=="0" (
    set /a new_adj=!%~3!*%~6, old_adj=%~4*%~6
    if !new_adj! GTR !old_adj! (
        set "done=true"
    ) else (
        call :storeHaggleInsults "%~1"
        if "!errorlevel!"=="0" (
            set "status=%BidState.Insulted%"
            set "done=true"
        ) else (
            set "new_offer=%~4"
        )
    )
) else (
    set "status=%BidState.Rejected%"
    set "done=true"
)
goto :storeReceiveOfferWhileLoop

::------------------------------------------------------------------------------
:: Tweak the prices based on the player's Charisma stat
::
:: Arguments: %1 - A reference to the minimum sale price
::            %2 - A reference to the maximum sale price
::------------------------------------------------------------------------------
:storePurchaseCustomerAdjustment
call player_stats.cmd :playerStatAdjustmentCharisma
set "charisma=!errorlevel!"
set /a %~2=!%~2! * !charisma! / 100
if !%~2! LEQ 0 set "%~2=1"
set /a %~3=!%~3! * !charisma! / 100
if !%~3! LEQ 0 set "%~3=1"

set "charisma="
exit /b

::------------------------------------------------------------------------------
:: The actual subroutine for haggling
::
:: Arguments: %1 - The store_id of the current store
::            %2 - A variable to store the final price
::            %3 - A reference to the item being bought or sold
:: Returns:   0 if the bid was successful
::            1 if the bid was rejected or cancelled by the customer
::            2 if the customer tried to sell something broken or cursed
::            3 if the store owner was insulted too many times by the bid
::------------------------------------------------------------------------------
:storePurchaseHaggle
set "status=%BidState.Received%"
set "new_price=0"

set "store=stores[%~1]"
set "o_id=!%store%.owner_id!"
set "owner=store_owners[%o_id%]"

call store_inventory.cmd :storeItemSellPrice "%store%" "min_sell" "max_sell" "%~3"
set "cost=!errorlevel!"

call :storePurchaseCustomerAdjustment "min_sell" "max_sell"

set /a max_buy=%cost% * (200 - !%owner%.max_inflate!) / 100
if %max_buy% LEQ 0 set "max_buy=1"

call :displayStoreHaggleCommands 1

set "final_asking_price=%min_sell%"
set "current_asking_price=%max_sell%"

set "comment=Asking"
set "accepted_without_haggle=false"
set "offers_count=0"

call :storeNoNeedToBargain "%store%" "%final_asking_price%"
if "!errorlevel!"=="0" (
    call ui_io.cmd :printMessage "After a long bargaining session, you agree upon the price."
    set "current_asking_price=%min_sell%"
    set "comment=Final Offer"
    set "accepted_without_haggle=true"

    set "store_last_increment=%min_sell%"
    set "offers_count=1"
)

set "min_offer=%max_buy%"
set "last_offer=%min_offer%"
set "new_offer=0"

set "min_per=!%owner%.haggles_per!"
set /a max_per=%min_per% * 3

set "final_flag=0"

set "rejected=false"

:storePurchaseHaggleWhileLoop
if "!rejected!"=="true" goto :storePurchaseHaggleAfterWhileLoop

:storePurchaseHaggleInnerWhileLoop
set "bidding_open=true"
call ui_io.cmd :putString "!comment! : !current_asking_price!" "1;0"
call :storeReceiveOffer "%~1" "What do you offer? " "new_offer" "%last_offer%" "%offers_count%" 1
set "status=!errorlevel!"
if not "!status!"=="%BidState.Received%" (
    set "rejected=true"
) else (
    if !new_offer! GTR !current_asking_price! (
        call :printSpeechSorry
        set "new_offer=!last_offer!"
        set /a last_total=!last_offer!+!store_last_increment!
        if !last_total! GTR !current_asking_price! set "store_last_increment=0"
    ) else if "!new_offer!"=="!current_asking_price!" (
        set "rejected=true"
        set "new_price=!new_offer!"
    ) else (
        set "bidding_open=false"
    )
)
if "!rejected!"=="false" if "!bidding_open!"=="true" goto :storePurchaseHaggleInnerWhileLoop

if "!rejected!"=="false" (
    set /a "adjustment=(!new_offer! - !last_offer!) * 100 / (!current_asking_price! - !last_offer!)"
    if !adjustment! LSS %min_per% (
        call :storeHaggleInsults "%~1"
        set "rejected=!errorlevel!"
        if "!rejected!"=="0" set "status=%BidState.Insulted%"
    ) else if !adjustment! GTZR %max_per% (
        set /a adjustment=!adjustment! * 75 / 100
        if !adjustment! LSS %max_per% set "adjustment=%max_per%"
    )

    call rng.cmd :randomNumber 5
    set /a adjustment=((!current_asking_price! - !new_offer!) * (!adjustment! + !errorlevel! - 3) / 100) + 1

    if !adjustment! GTR 0 set /a current_asking_price-=!adjustment!

    if !current_asking_price! LSS !final_asking_price! (
        set "current_asking_price=!final_asking_price!"
        set "comment=Final Offer"

        set /a store_last_increment=!final_asking_price!-!new_offer!
        set /a final_flag+=1

        if !final_flag! GTR 3 (
            call :storeIncreaseInsults "%~1"
            if "!errorlevel!"=="0" (
                set "status=%BidState.Insulted%"
            ) else (
                set "status=%BidState.Rejected%"
            )
            set "rejected=true"
        )
    ) else if !new_offer! GEQ !current_asking_price! (
        set "rejected=true"
        set "new_price=!new_offer!"
    )

    if "!rejected!"=="false" (
        set "last_offer=!new_offer!"
        set /a offers_count+=1

        call ui_io.cmd :eraseLine "1;0"
        call ui_io.cmd :putString "Your last offer : !last_offer!" "1;39"
        call :printSpeechSellingHaggle "!last_offer!" "!current_asking_price!" "!final_flag!"

        set /a overask_check=!current_asking_price!-!last_offer!
        if !overask_check! LSS !store_last_increment! (
            set /a store_last_increment=!current_asking_price!-!last_offer!
        )
        set "overask_check="
    )
)
goto :storePurchaseHaggleWhileLoop

:storePurchaseHaggleAfterWhileLoop
if "!status!"=="%BidState.Received%" (
    if "!accepted_without_haggle!"=="false" (
        call :storeUpdateBargainingSkills "%store%" "!new_price!" "!final_asking_price!"
    )
)
set "%~2=!new_price!"
exit /b !status!

::------------------------------------------------------------------------------
:: Tweaks prices based on the customer's Charisma
::
:: Arguments: %1 - A reference to the store owner
::            %2 - A reference to the cost of the item
::            %3 - A variable to store the minimum that the owner will pay
::            %4 - A variable to store the maximum that the owner will pay
::            %5 - A variable to store the maximum that the player can sell for
:: Returns:   None
::------------------------------------------------------------------------------
:storeSellCustomerAdjustment
set "owner_race=!%~1.race!"
call player_stats.cmd :playerStatAdjustmentCharisma
set /a cost=!%~2! * (200 - !errorlevel!) / 100
set /a cost=!cost! * (200 - !race_gold_adjustments[%owner_race%][%py.misc.race_id%]!) / 100
if !cost! LSS 1 set "cost=1"
set "%~2=!cost!"

set /a %~5=!cost! * !%~1.max_inflate! / 100

set /a max_buy=!cost! * (200 - !%~1.max_inflate!) / 100
set /a min_buy=!cost! * (200 - !%~1.min_inflate!) / 100
if !min_buy! LSS 1 set "min_buy=1"
if !max_buy! LSS 1 set "max_buy=1"
if !min_buy! LSS !max_buy! set "min_buy=!max_buy!"

set "%~3=!min_buy!"
set "%~4=!max_buy!"
set "%~5=!max_sell!"
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

