@echo off
call %*
exit /b

:inventoryCollectAllItemFlags
exit /b

:inventoryDestroyItem
exit /b

:inventoryTakeOneItem
exit /b

:inventoryDropItem
exit /b

:inventoryDamageItem
exit /b

:inventoryDiminishLightAttack
exit /b

:inventoryDiminishChargesAttack
exit /b

:executeDisenchantAttack
exit /b

:inventoryCanCarryItemCount
exit /b

:inventoryCanCarryItem
exit /b

:inventoryCarryItem
exit /b

:inventoryFindRange
exit /b

:inventoryItemCopyTo
exit /b

:inventoryItemSingleStackable
exit /b

:inventoryItemStackable
exit /b

:inventoryItemIsCursed
exit /b

:inventoryItemRemoveCurse
exit /b

:damageMinusAC
exit /b

:setNull
exit /b

:setCorrodableItems
exit /b

:setFlammableItems
exit /b

:setAcidAffectedItems
exit /b

:setFrostDestroyableItems
exit /b

:setLightningDestroyableItems
exit /b

:setAcidDestroyableItems
exit /b

:setFireDestroyableItems
exit /b

:damageCorrodingGas
exit /b

:damagePoisonedGas
exit /b

:damageFire
exit /b

:damageCold
exit /b

:damageLightningBolt
exit /b

:damageAcid
exit /b

::------------------------------------------------------------------------------
:: Copies one inventory item into another one
::
:: Arguments: %1 - The inventory item to copy values into
::            %2 - The inventory item to copy values from
:: Returns:   None
::------------------------------------------------------------------------------
:inventoryCopyItem
for %%T in (id special_name_id inscription flags category_id sprite misc_use
            cost sub_category_id items_count weight to_hit to_damage ac to_ac
            damage.dice damage.sides depth_first_round identification) do (
    set "%~1.%%T=!%~2.%%T"
)
exit /b