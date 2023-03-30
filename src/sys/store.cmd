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

:printSpeechFinishedHaggling
exit /b

:printSpeechSellingHaggle
exit /b

:printSpeechBuyingHaggle
exit /b

:printSpeechGetOutOfMyStore
exit /b

:printSpeechTryAgain
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

