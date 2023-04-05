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

::------------------------------------------------------------------------------
:: Enchant a bonus based on a desired amount
::
:: Arguments: %1 - The base value of the bonus
::            %2 - The maximum value from one standard_deviation
::            %3 - The level of the dungeon that the player is on
:: Returns:   The new bonus for the item
::------------------------------------------------------------------------------
:magicEnchantmentBonus
set /a standard_deviation=(%config.treasure.LEVEL_STD_OBJECT_ADJUST% * %~3 / 100) + %config.treasure.LEVEL_MIN_OBJECT_STD%

if %standard_deviation% GTR %~2 set "standard_deviation=%~2"
if %~3 GTR %~2 set "standard_deviation=%~2"

call game.cmd :randomNumberNormalDistribution 0 %standard_deviation%
set "abs_distribution=!errorlevel!"
if !abs_distribution! LSS 0 set /a abs_distribution*=-1
set /a bonus=(!abs_distribution! / 10) + %~1

if !bonus! LSS %~1 exit /b %~1
exit /b !bonus!

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

