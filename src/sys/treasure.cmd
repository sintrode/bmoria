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
::            %2 - The odds of the item gaining magical attributes
::            %3 - The level of the dungeon that the player is on
:: Returns:   None
::------------------------------------------------------------------------------
:magicalArmor
call :magicEnchantmentBonus 1 30 %~3
set /a %~1.to_ac+=!errorlevel!

call :magicShouldBeEnchanted %~2 || exit /b

call rng.cmd :randomNumber 9
set "rnd_bonus=!errorlevel!"
set "ctf=config.treasure.flags"
if "!rnd_bonus!"=="1" (
    REM Armor of Resist All
    set /a "%~1.flags|=(!%ctf%.TR_RES_LIGHT! | !%ctf%.TR_RES_COLD! | !%ctr%.TR_RES_ACID! | !%ctr%.TR_RES_FIRE!)"
    set "%~1.special_name_id=%SpecialNameIds.SN_R%"
    set /a "%~1.to_ac+=5"
    set /a "%~1.cost+=2500"
) else if "!rnd_bonus!"=="2" (
    REM Armor of Resist Acid
    set /a "%~1.flags|=!%ctf%.TR_RES_ACID!"
    set "%~1.special_name_id=%SpecialNameIds.SN_RA"
    set /a "%~1.cost+=1000"
) else if !rnd_bonus! GEQ 3 (
    if !rnd_bonus! LEQ 4 (
        REM Armor of Resist Fire
        set /a "%~1.flags|=!%ctf%.TR_RES_FIRE!"
        set "%~1.special_name_id=%SpecialNameIds.SN_RF"
        set /a "%~1.cost+=600"
    ) else (
        if !rnd_bonus! LEQ 6 (
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

::------------------------------------------------------------------------------
:: Convert a sword to a magical sword
::
:: Arguments: %1 - A reference to the item being enchanted
::            %2 - The odds of the item gaining magical attributes
::            %3 - The level of the dungeon that the player is on
:: Returns:   None
::------------------------------------------------------------------------------
:magicalSword
set "item=%~1"
set "special=%~2"
set "level=%~3"

call :magicEnchantmentBonus 0 40 %level%
set /a %item%.to_hit+=!errorlevel!

call dice.cmd :maxDiceRoll "!%item%.damage.dice!" "!%item%.damage.sides!"
set "damage_bonus=!errorlevel!"

set /a "enchant_std=4 * %damage_bonus%", "enchant_level=%damage_bonus% * %level% / 10"
call :magicEnchantmentBonus 0 %enchant_std% %enchant_level%
set /a %item%.to_damage+=!errorlevel!

:: 1.5x modifier to special because weapons are not as common as armor
set /a special=3 * %special% / 2
call :magicShouldBeEnchanted %special% || exit /b
call rng.cmd :randomNumber 16
set "rnd_bonus=!errorlevel!"

call :magicalSword_!rnd_bonus!
exit /b

:: Holy Avenger
:magicalSword_1
set /a "%item%.flags|=(%config.treasure.flags.TR_SEE_INVIS% | %config.treasure.flags.TR_SUST_STAT% | %config.treasure.flags.TR_SLAY_UNDEAD% | %config.treasure.flags.TR_SLAY_EVIL% | %config.treasure.flags.TR_STR%)"
set /a %item%.to_hit+=5
set /a %item%.to_damage+=5
call rng.cmd :randomNumber 4
set /a %item%.to_ac+=!errorlevel!

call rng.cmd :randomNumber 4
set "%item%.misc_use=!errorlevel!"
set "%item%.special_name_id=%SpecialNameIds.SN_HA%"
set /a %item%.cost+=!%item%.misc_use! * 500
set /a %item%.cost+=10000
exit /b

:: Defender
:magicalSword_2
set /a "%item%.flags|=(%config.treasure.flags.TR_FFALL% | %config.treasure.flags.TR_RES_LIGHT% | %config.treasure.flags.TR_SEE_INVIS% | %config.treasure.flags.TR_FREE_ACT% | %config.treasure.flags.TR_RES_COLD% | %config.treasure.flags.TR_RES_ACID% | %config.treasure.flags.TR_RES_FIRE% | %config.treasure.flags.TR_REGEN% | %config.treasure.flags.TR_STEALTH%)"
set /a %item%.to_hit+=3
set /a %item%.to_damage+=3
call rng.cmd :randomNumber 5
set /a %item%.to_ac+=5 + !errorlevel!
set "%item%.special_name_id=%SpecialNameIds.SN_DF%"

call rng.cmd :randomNumber 3
set "%item%.misc_use=!errorlevel!"
set /a %item%.cost+=!%item%.misc_use! * 500
set /a %item%.cost+=7500
exit /b

:: Slay Animal
:magicalSword_3
:magicalSword_4
set /a "%item%.flags|=%config.treasure.flags.TR_SLAY_ANIMAL%"
set /a %item%.to_hit+=2
set /a %item%.to_damage+=2
set "%item%.special_name_id=%SpecialNameIds.SN_SA%"
set /a %item%.cost+=3000
exit /b

:: Slay Dragon
:magicalSword_5
:magicalSword_6
set /a "%item%.flags|=%config.treasure.flags.TR_SLAY_DRAGON%"
set /a %item%.to_hit+=3
set /a %item%.to_damage+=4
set "%item%.special_name_id=%SpecialNameIds.SN_SD%"
set /a %item%.cost+=4000
exit /b

:: Slay Evil
:magicalSword_7
:magicalSword_8
set /a "%item%.flags|=%config.treasure.flags.TR_SLAY_EVIL%"
set /a %item%.to_hit+=3
set /a %item%.to_damage+=4
set "%item%.special_name_id=%SpecialNameIds.SN_SE%"
set /a %item%.cost+=4000

:: Slay Undead
:magicalSword_9
:magicalSword_10
set /a "%item%.flags|=(%config.treasure.flags.TR_SEE_INVIS% | %config.treasure.flags.TR_SLAY_UNDEAD%)"
set /a %item%.to_hit+=3
set /a %item%.to_damage+=4
set "%item%.special_name_id=%SpecialNameIds.SN_SU%"
set /a %item%.cost+=4000
exit /b

:: Flame Tongue
:magicalSword_11
:magicalSword_12
:magicalSword_13
set /a "%item%.flags|=%config.treasure.flags.TR_FLAME_TONGUE%"
set /a %item%.to_hit+=1
set /a %item%.to_damage+=3
set "%item%.special_name_id=%SpecialNameIds.SN_FT%"
set /a %item%.cost+=2000
exit /b

:: Frost Brand
:magicalSword_14
:magicalSword_15
:magicalSword_16
set /a "%item%.flags|=%config.treasure.flags.TR_FROST_BRAND%"
set /a %item%.to_hit+=1
set /a %item%.to_damage+=2
set "%item%.special_name_id=%SpecialNameIds.SN_FB%"
set /a %item%.cost+=1200
exit /b

::------------------------------------------------------------------------------
:: Convert a sword to a cursed sword
::
:: Arguments: %1 - A reference to the item being cursed
::            %2 - The level of the dungeon that the player is on
:: Returns:   None
::------------------------------------------------------------------------------
:cursedSword
set "item=%~1"
set "level=%~2"

call :magicEnchantmentBonus 1 55 %level%
set /a %item%.to_hit-=!errorlevel!

call dice.cmd :maxDiceRoll !%item%.damage.dice! !%item%.damage.sides!
set "damage_bonus=!errorlevel!"

set /a "enchant_std=11 * %damage_bonus% / 2", "enchant_level=%damage_bonus% * %level% / 10"
call :magicEnchantmentBonus 1 %enchant_std% %enchant_level%
set /a "%item%.flags|=%config.treasure.flags.TR_CURSED%"
set "%item%.cost=0"
exit /b

::------------------------------------------------------------------------------
:: Convert a bow to a magical bow
::
:: Arguments: %1 - A reference to the item being enchanted
::            %2 - The level of the dungeon that the player is on
:: Returns:   None
::------------------------------------------------------------------------------
:magicalBow
set "item=%~1"
set "level=%~2"

call :magicEnchantmentBonus 1 30 %~2
set /a %item%.to_hit+=!errorlevel!

call :magicEnchantmentBonus 1 20 %~2
set /a %item%.to_damage+=!errorlevel!
exit /b

::------------------------------------------------------------------------------
:: Convert a bow to a cursed bow
::
:: Arguments: %1 - A reference to the item being enchanted
::            %2 - The level of the dungeon that the player is on
:: Returns:   None
::------------------------------------------------------------------------------
:cursedBow
set "item=%~1"
set "level=%~2"

call :magicEnchantmentBonus 1 50 %level%
set /a %item%.to_hit-=!errorlevel!

call :magicEnchantmentBonus 1 30 %level%
set /a %item%.to_damage-=!errorlevel!

set /a "%item%.flags|=%config.treasure.flags.TR_CURSED%"
set "%item%.cost=0"
exit /b

::------------------------------------------------------------------------------
:: Converts a pickaxe or shovel to a magical digging tool
::
:: Arguments: %1 - A reference to the item being enchanted
::            %2 - The level of the dungeon that the player is on
:: Returns:   None
::------------------------------------------------------------------------------
:magicalDiggingTool
set "item=%~1"
set "level=%~2"

call :magicEnchantmentBonus 0 25 %level%
set /a %item%.misc_use+=!errorlevel!
exit /b

::------------------------------------------------------------------------------
:: Converts a pickaxe or shovel to a cursed digging tool
::
:: Arguments: %1 - A reference to the item being enchanted
::            %2 - The level of the dungeon that the player is on
:: Returns:   None
::------------------------------------------------------------------------------
:cursedDiggingTool
set "item=%~1"
set "level=%~2"

call :magicEnchantmentBonus 1 30 %level%
set /a %item%.misc_use-=!errorlevel!
set "%item%.cost=0"
set /a "%item%.flags|=%config.treasure.flags.TR_CURSED%"
exit /b

::------------------------------------------------------------------------------
:: Converts gloves to magical gloves
::
:: Arguments: %1 - A reference to the item being enchanted
::            %2 - The odds of the item gaining magical attributes
::            %3 - The level of the dungeon that the player is on
:: Returns:   None
::------------------------------------------------------------------------------
:magicalGloves
set "item=%~1"
set "special=%~2"
set "level=%~3"

call :magicEnchantmentBonus 1 20 %level%
set %item%.to_ac+=!errorlevel!

call :magicShouldBeEnchanted %special% || exit /b

call rng.cmd :randomNumber 2
if "!errorlevel!"=="1" (
    set /a "%item%.flags|=%config.treasure.flags.TR_FREE_ACT%"
    set "%item%.special_name_id=%SpecialNameIds.SN_FREE.ACTION%"
    set /a %item%.cost+=1000
) else (
    set /a "%item%.identification|=%config.identification.ID_SHOW_HIT_DAM%"
    call rng.cmd :randomNumber 3
    set /a %item%.to_hit+=1+!errorlevel!
    call rng.cmd :randomNumber 3
    set /a %item%.to_damage+=1+!errorlevel!
    set "%item%.special_name_id=%SpecialNameIds.SN.SLAYING%"
    set /a "%item%.cost+=(!%item%.to_hit! + !%item%.to_damage!) * 250"
)
exit /b

::------------------------------------------------------------------------------
:: Converts gloves to cursed gloves
::
:: Arguments: %1 - A reference to the item being enchanted
::            %2 - The odds of the item gaining magical attributes
::            %3 - The level of the dungeon that the player is on
:: Returns:   None
::------------------------------------------------------------------------------
:cursedGloves
set "item=%~1"
set "special=%~2"
set "level=%~3"

call :magicShouldBeEnchanted %special%
if "!errorlevel!"=="0" (
    call rng.cmd :randomNumber 2
    if "!errorlevel!"=="1" (
        set /a "%item%.flags|=%config.treasure.flags.TR_DEX%"
        set "%item%.special_name_id=%SpecialNameIds.SN_CLUMSINESS%"
    ) else (
        set /a "%item%.flags|=%config.treasure.flags.TR_STR%"
        set "%item%.special_name_id=%SpecialNameIds.SN_WEAKNESS%"
    )
    set /a "%item%.identification|=%config.identification.ID_SHOW_P1%"
    call :magicEnchantmentBonus 1 10 %level%
    set /a %item%.misc_use-=!errorlevel!
)

call :magicEnchantmentBonus 1 40 %level%
set /a %item%.to_ac-=!errorlevel!
set /a "%item%.flags|=%config.treasure.flags.TR_CURSED%"
set "%item%.cost=0"
exit /b

::------------------------------------------------------------------------------
:: Converts boots to magical boots
::
:: Arguments: %1 - A reference to the item being enchanted
::            %2 - The odds of the item gaining magical attributes
::            %3 - The level of the dungeon that the player is on
:: Returns:   None
::------------------------------------------------------------------------------
:magicalBoots
set "item=%~1"
set "special=%~2"
set "level=%~3"

call :magicEnchantmentBonus 1 20 %level%
set /a %item%.to_ac+=!errorlevel!

call :magicShouldBeEnchanted %special% || exit /b

call rng.cmd :randomNumber 12
set "magic_type=!errorlevel!"

if !magic_type! GTR 5 (
    set /a "%item%.flags|=%config.treasure.flags.TR_FFALL%"
    set "%item%.special_name_id=%SpecialNameIds.SN_SLOW_DESCENT%"
    set /a %item%.cost+=250
) else if "!magic_type!"=="1" (
    set /a "%item%.flags|=%config.treasure.flags.TR_SPEED%"
    set "%item%.special_name_id=%SpecialNameIds.SN_SPEED%"
    set /a "%item%.identification|=%config.identification.ID_SHOW_P1%"
    set "%item%.misc_use=1"
    set /a %item%.cost+=5000
) else (
    set /a "%item%.flags|=%config.treasure.flags.TR_STEALTH%"
    set /a "%item%.identification|=%config.identification.ID_SHOW_P1%"
    call rng.cmd :randomNumber 3
    set "%item%.misc_use=!errorlevel!"
    set "%item%.special_name_id=%SpecialNameIds.SN_STEALTH%"
    set /a %item%.cost+=500
)
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

