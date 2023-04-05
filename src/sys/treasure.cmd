@echo off
call %*
exit /b

::------------------------------------------------------------------------------
:: Determines if an item should be enchanted
::
:: Arguments: %1 - The percent chance that an item is enchanted
:: Returns:   0 if the item is enchanted
::            1 if it is just a regular item
::------------------------------------------------------------------------------
:magicShouldBeEnchanted
call rng.cmd :randomNumber 100
if !errorlevel! LEQ %~1 exit /b 0
exit /b 1

:magicEnchantmentBonus
exit /b

:magicalArmor
exit /b

:cursedArmor
exit /b

:magicalSword
exit /b

:cursedSword
exit /b

:magicalBow
exit /b

:cursedBow
exit /b

:magicalDiggingTool
exit /b

:cursedDiggingTool
exit /b

:magicalGloves
exit /b

:cursedGloves
exit /b

:magicalBoots
exit /b

:cursedBoots
exit /b

:magicalHelms
exit /b

:cursedHelms
exit /b

:processRings
exit /b

:processAmulets
exit /b

:wandMagic
exit /b

:staffMagic
exit /b

:magicalCloak
exit /b

:cursedCloak
exit /b

:magicalChests
exit /b

:magicalProjectileAdjustment
exit /b

:cursedProjectileAdjustment
exit /b

:magicalProjectile
exit /b

:magicTreasureMagicalAbility
exit /b

