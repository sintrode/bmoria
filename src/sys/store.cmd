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

:printSpeechSorry
exit /b

:displayStoreCommands
exit /b

:displayStoreHaggleCommands
exit /b

:displayStoreInventory
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

