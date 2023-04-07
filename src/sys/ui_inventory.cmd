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

:displayInventoryItems
exit /b

:playerItemWearingDescription
exit /b

:char
exit /b

:displayEquipment
exit /b

:showEquipmentHelpMenu
exit /b

:uiCommandSwitchScreen
exit /b

:verifyAction
exit /b

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

