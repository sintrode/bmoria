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

::------------------------------------------------------------------------------
:: Converts a set of armor to magical armor
::
:: Arguments: %1 - A reference to the item being enchanted
::            %2 - The odds of the item gaining magical resistance
::            %3 - The level of the dungeon that the player is on
:: Returns:   None
::------------------------------------------------------------------------------
:magicalArmor
call :magicEnchantmentBonus 1 30 %~3
set /a %~1.to_ac+=!errorlevel!

call :magicShouldBeEnchanted %~2 || exit /b

call rng.cmd :randomNumber 9
set "resist_rnd=!errorlevel!"
set "ctf=config.treasure.flags"
if "!resist_rnd!"=="1" (
    REM Armor of Resist All
    set /a "%~1.flags|=(!%ctf%.TR_RES_LIGHT! | !%ctf%.TR_RES_COLD! | !%ctr%.TR_RES_ACID! | !%ctr%.TR_RES_FIRE!)"
    set "%~1.special_name_id=%SpecialNameIds.SN_R%"
    set /a "%~1.to_ac+=5"
    set /a "%~1.cost+=2500"
) else if "!resist_rnd!"=="2" (
    REM Armor of Resist Acid
    set /a "%~1.flags|=!%ctf%.TR_RES_ACID!"
    set "%~1.special_name_id=%SpecialNameIds.SN_RA"
    set /a "%~1.cost+=1000"
) else if !resist_rnd! GEQ 3 (
    if !resist_rnd! LEQ 4 (
        REM Armor of Resist Fire
        set /a "%~1.flags|=!%ctf%.TR_RES_FIRE!"
        set "%~1.special_name_id=%SpecialNameIds.SN_RF"
        set /a "%~1.cost+=600"
    ) else (
        if !resist_rnd! LEQ 6 (
            REM Armor of Resist Cold
            set /a "%~1.flags|=!%ctf%.TR_RES_COLD!"
            set "%~1.special_name_id=%SpecialNameIds.SN_RC"
            set /a "%~1.cost+=600"
        ) else (
            REM Armor of Resist Lightning
            set /a "%~1.flags|=!%ctf%.TR_RES_LIGHT!"
            set "%~1.special_name_id=%SpecialNameIds.SN_RL"
            set /a "%~1.cost+=500"
        )
    )
)
exit /b

::------------------------------------------------------------------------------
:: Convert a set of armor to cursed armor
::
:: Arguments: %1 - A reference to the item being cursed
::            %2 - The level of the dungeon that the player is on
:: Returns:   None
::------------------------------------------------------------------------------
:cursedArmor
call :magicEnchantmentBonus 0 40 %~3
set /a %~1.to_ac-=!errorlevel!
set "%~1.cost=0"
set /a "%~1.flags|=%config.treasure.flags.TR_CURSED%"
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

