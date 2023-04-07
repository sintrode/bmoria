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

::------------------------------------------------------------------------------
:: Converts boots to cursed boots
::
:: Arguments: %1 - A reference to the item being enchanted
::            %2 - The level of the dungeon that the player is on
:: Returns:   None
::------------------------------------------------------------------------------
:cursedBoots
set "item=%~1"
set "level=%~2"

call rng.cmd :randomNumber 3
set "magic_type=!errorlevel!"
if "!magic_type!"=="1" (
    set /a "%item%.flags|=%config.treasure.flags.TR_SPEED%"
    set "%item%.special_name_id=%SpecialNameIds.SN_SLOWNESS%"
    set /a "%item%.identification|=%config.identification.ID_SHOW_P1%"
    set "%item%.misc_use=-1"
) else if "!magic_type!"=="2" (
    set /a "%item%.flags|=%config.treasure.flags.TR_AGGRAVATE%"
    set "%item%.special_name_id=%SpecialNameIds.SN_NOISE%"
) else (
    set "%item%.special_name_id=%SpecialNameIds.SN_GREAT_MASS%"
    set /a %item%.weight*=5
)

set "%item%.cost=0"
call :magicEnchantmentBonus 2 45 %level%
set /a %item%.to_ac-=!errorlevel!
set /a "%item%.flags|=%config.treasure.flags.TR_CURSED%"
exit /b

::------------------------------------------------------------------------------
:: Convert helms to magical helms
::
:: Arguments: %1 - A reference to the item being enchanted
::            %2 - The odds of the item gaining magical attributes
::            %3 - The level of the dungeon that the player is on
:: Returns:   None
::------------------------------------------------------------------------------
:magicalHelms
set "item=%~1"
set "special=%~2"
set "level=%~3"

call :magicEnchantmentBonus 1 20 %level%
set /a %item%.to_ac+=!errorlevel!

call :magicShouldBeEnchanted %special% || exit /b

if !%item%.sub_category! LSS 6 (
    set /a "%item%.identification|=%config.identification.ID_SHOW_P1%"

    call rng.cmd :randomNumber 3
    set "magic_type=!errorlevel!"

    if "!magic_type!"=="1" (
        call rng.cmd :randomNumber 2
        set "%item%.misc_use=!errorlevel!"
        set /a "%item%.flags|=%config.treasure.flags.TR_INT%"
        set "%item%.special_name_id=%SpecialNameIds.SN_INTELLIGENCE%"
        set /a %item%.cost+=!%item%.misc_use!*500
    ) else if "!magic_type!"=="2" (
        call rng.cmd :randomNumber 2
        set "%item%.misc_use=!errorlevel!"
        set /a "%item%.flags|=%config.treasure.flags.TR_WIS%"
        set "%item%.special_name_id=%SpecialNameIds.SN_WISDOM%"
        set /a %item%.cost+=!%item%.misc_use!*500
    ) else (
        call rng.cmd :randomNumber 4
        set /a %item%.misc_use=!errorlevel!+1
        set /a "%item%.flags|=%config.treasure.flags.TR_INFRA%"
        set "%item%.special_name_id=%SpecialNameIds.SN_INFRAVISION%"
        set /a %item%.cost+=!%item%.misc_use!*250
    )
    exit /b
)

call rng.cmd :randomNumber 6
set "magic_type=!errorlevel!"

if "!magic_type!"=="1" (
    set /a "%item%.identification|=%config.identification.ID_SHOW_P1%"
    call rng.cmd :randomNumber 3
    set "%item%.misc_use=!errorlevel!"
    set /a "%item%.flags|=(%config.treasure.flags.TR_FREE_ACT% | %config.treasure.flags.TR_CON% | %config.treasure.flags.TR_DEX% | %config.treasure.flags.TR_STR%)"
    set "%item%.special_name_id=%SpecialNameIds.SN_MIGHT%"
    set /a %item%.cost+=1000 + !%item%.misc_use! * 500
) else if "!magic_type!"=="2" (
    set /a "%item%.identification|=%config.identification.ID_SHOW_P1%"
    call rng.cmd :randomNumber 3
    set "%item%.misc_use=!errorlevel!"
    set /a "%item%.flags|=(%config.treasure.flags.TR_CHR% | %config.treasure.flags.TR_WIS%)"
    set "%item%.special_name_id=%SpecialNameIds.SN_LORDLINESS%"
    set /a %item%.cost+=1000 + !%item%.misc_use! * 500
) else if "!magic_type!"=="3" (
    set /a "%item%.identification|=%config.identification.ID_SHOW_P1%"
    call rng.cmd :randomNumber 3
    set "%item%.misc_use=!errorlevel!"
    set /a "%item%.flags|=(%config.treasure.flags.TR_RES_LIGHT% | %config.treasure.flags.TR_RES_COLD% | %config.treasure.flags.TR_RES_ACID% | %config.treasure.flags.TR_RES_FIRE% | %config.treasure.flags.TR_INT%)"
    set "%item%.special_name_id=%SpecialNameIds.SN_MAGI%"
    set /a %item%.cost+=3000 + !%item%.misc_use! * 500
) else if "!magic_type!"=="4" (
    set /a "%item%.identification|=%config.identification.ID_SHOW_P1%"
    call rng.cmd :randomNumber 3
    set "%item%.misc_use=!errorlevel!"
    set /a "%item%.flags|=%config.treasure.flags.TR_CHR%"
    set "%item%.special_name_id=%SpecialNameIds.SN_BEAUTY%"
    set /a %item%.cost+=750
) else if "!magic_type!"=="5" (
    set /a "%item%.identification|=%config.identification.ID_SHOW_P1%"
    call rng.cmd :randomNumber 4
    set /a "%item%.misc_use=(5 * (1 + !errorlevel!))"
    set /a "%item%.flags|=(%config.treasure.flags.TR_SEE_INVIS% | %config.treasure.flags.TR_SEARCH%)"
    set "%item%.special_name_id=%SpecialNameIds.SN_SEEING%"
    set /a %item%.cost+=1000 + !%item%.misc_use! * 100
) else if "!magic_type!"=="6" (
    set /a "%item%.flags|=%config.treasure.flags.TR_REGEN%"
    set "%item%.special_name_id=%SpecialNameIds.SN_REGENERATION%"
    set /a %item%.cost+=1500
)
exit /b

::------------------------------------------------------------------------------
:: Convert helms to cursed helms
::
:: Arguments: %1 - A reference to the item being enchanted
::            %2 - The odds of the item gaining magical attributes
::            %3 - The level of the dungeon that the player is on
:: Returns:   None
::------------------------------------------------------------------------------
:cursedHelms
set "item=%~1"
set "special=%~2"
set "level=%~3"

call :magicEnchantmentBonus 1 45 %level%
set /a %item%.to_ac-=!errorlevel!
set /a "%item%.flags|=%config.treasure.flags.TR_CURSED%"
set "%item%.cost=0"

call :magicShouldBeEnchanted %special% || exit /b

call rng.cmd :randomNumber 7
set "magic_type=!errorlevel!"

if "!magic_type!"=="1" (
    set /a "%item%.identification|=%config.identification.TD_SHOW_P1%"
    call rng.cmd :randomNumber 5
    set /a %item%.misc_use=!errorlevel! * -1
    set /a "%item%.flags|=%config.treasure.flags.TR_INT%"
    set "%item%.special_name_id=%SpecialNameIds.SN_STUPIDITY%"
) else if "!magic_type!"=="2" (
    set /a "%item%.identification|=%config.identification.TD_SHOW_P1%"
    call rng.cmd :randomNumber 5
    set /a %item%.misc_use=!errorlevel! * -1
    set /a "%item%.flags|=%config.treasure.flags.TR_WIS%"
    set "%item%.special_name_id=%SpecialNameIds.SN_DULLNESS%"
) else if "!magic_type!"=="3" (
    set /a "%item%.flags|=%config.treasure.flags.TR_BLIND%"
    set "%item%.special_name_id=%SpecialNameIds.SN_BLINDNESS%"
) else if "!magic_type!"=="4" (
    set /a "%item%.flags|=%config.treasure.flags.TR_TIMID%"
    set "%item%.special_name_id=%SpecialNameIds.SN_TIMIDNESS%"
) else if "!magic_type!"=="5" (
    set /a "%item%.identification|=%config.identification.TD_SHOW_P1%"
    call rng.cmd :randomNumber 5
    set /a %item%.misc_use=!errorlevel! * -1
    set /a "%item%.flags|=%config.treasure.flags.TR_STR%"
    set "%item%.special_name_id=%SpecialNameIds.SN_WEAKNESS%"
) else if "!magic_type!"=="6" (
    set /a "%item%.flags|=%config.treasure.flags.TR_TELEPORT%"
    set "%item%.special_name_id=%SpecialNameIds.SN_TELEPORTATION%"
) else if "!magic_type!"=="7" (
    set /a "%item%.identification|=%config.identification.TD_SHOW_P1%"
    call rng.cmd :randomNumber 5
    set /a %item%.misc_use=!errorlevel! * -1
    set /a "%item%.flags|=%config.treasure.flags.TR_CHR%"
    set "%item%.special_name_id=%SpecialNameIds.SN_UGLINESS%"
)
exit /b

::------------------------------------------------------------------------------
:: Adds attributes to rings
:: TODO: Refactor the previous variations of this subroutine to match this
::
:: Arguments: %1 - A reference to the item being enchanted
::            %2 - The level of the dungeon that the player is on
::            %3 - The odds that the ring is cursed
:: Returns:   None
::------------------------------------------------------------------------------
:processRings
set "item=%~1"
set "level=%~2"
set "cursed=%~3"

if !%item%.sub_category_id! LEQ 3(
    call :magicShouldBeEnchanted %cursed%
    if "!errorlevel!"=="0" (
        call :magicEnchantmentBonus 1 20 %level%
        set /a %item%.misc_use=!errorlevel! * -1
        set /a "%item%.flags|=%config.treasure.flags.TR_CURSED%"
        set /a %item%.cost*=-1
    ) else (
        call :magicEnchantmentBonus 1 10 %level%
        set "%item%.misc_use=!errorlevel!"
        set /a %item%.cost+=!%item%.misc_use!*100
    )
) else if "!%item%.sub_category_id!"=="4" (
    call :magicShouldBeEnchanted %cursed%
    if "!errorlevel!"=="0" (
        call rng.cmd :randomNumber 3
        set /a %item%.misc_use=!errorlevel! * -1
        set "%item%.flags|=%config.treasure.flags.TR_CURSED%"
        set /a %item%.cost*=-1
    ) else (
        set "%item%.misc_use=1"
    )
) else if "!%item%.sub_category_id!"=="5" (
    call :magicEnchantmentBonus 1 20 %level%
    set /a %item%.misc_use=5 * !errorlevel!
    set /a %item%.cost+=!%item%.misc_use! * 50
    call :magicShouldBeEnchanted %cursed%
    if "!errorlevel!"=="0" (
        set /a %item%.misc_use=!%item%.misc_use! * -1
        set /a "%item%.flags|=%config.treasure.flags.TR_CURSED%"
        set /a %item%.cost*=-1
    )
) else if "!%item%.sub_category_id!"=="19" (
    call :magicEnchantmentBonus 1 20 %level%
    set /a %item%.to_damage+=!errorlevel!
    set /a %item%.cost+=!%item%.to_damage! * 50
    call :magicShouldBeEnchanted %cursed%
    if "!errorlevel!"=="0" (
        set /a %item%.to_damage=!%item%.to_damage! * -1
        set /a "%item%.flags|=%config.treasure.flags.TR_CURSED%"
        set /a %item%.cost*=-1
    )
) else if "!%item%.sub_category_id!"=="20" (
    call :magicEnchantmentBonus 1 20 %level%
    set /a %item%.to_hit+=!errorlevel!
    set /a %item%.cost+=!%item%.to_hit! * 50
    call :magicShouldBeEnchanted %cursed%
    if "!errorlevel!"=="0" (
        set /a %item%.to_hit*=-1
        set /a "%item%.flags|=%config.treasure.flags.TR_CURSED%"
        set /a %item%.cost*=-1
    )
) else if !%item%.sub_category_id! GEQ 24 (
    if !%item%.sub_category_id! LEQ 29 (
        set /a "%item%.identification|=%config.identification.ID_NO_SHOW_P1%"
    ) else if "!%item%.sub_category_id!"=="30" (
        set /a "%item%.identification|=%config.identification.ID_SHOW_HIT_DAM%"
        call :magicEnchantmentBonus 1 25 %level%
        set /a %item%.to_damage+=!errorlevel!
        call :magicEnchantmentBonus 1 25 %level%
        set /a %item%.to_hit+=!errorlevel!
        set /a "%item%.cost+=(!%item%.to_hit! + !%item%.to_damage!) * 100"
        call :magicShouldBeEnchanted %cursed%
        if "!errorlevel!"=="0" (
            set /a %item%.to_hit*=-1
            set /a %item%.to_damage*=-1
            set /a "%item%.flags|=%config.treasure.flags.TR_CURSED%"
            set /a %item%.cost*=-1
        )
    )
)
exit /b

::------------------------------------------------------------------------------
:: Add attributes to amulets
::
:: Arguments: %1 - A reference to the item being enchanted
::            %2 - The level of the dungeon that the player is on
::            %3 - The odds that the ring is cursed
:: Returns:   None
::------------------------------------------------------------------------------
:processAmulets
set "item=%~1"
set "level=%~2"
set "cursed=%~3"

if !%item%.sub_category_id! LSS 2 (
    call :magicShouldBeEnchanted %cursed%
    if "!errorlevel!"=="0" (
        call :magicEnchantmentBonus 1 20 %level%
        set /a %item%.misc_use=!errorlevel! * -1
        set /a "%item%.flags|=%config.treasure.flags.TR_CURSED%"
        set /a %item%.cost*=-1
    ) else (
        call :magicEnchantmentBonus 1 10 %level%
        set "%item%.misc_use=!errorlevel!"
        set /a %item%.cost+=!%item%.misc_use! * 100
    )
) else if "!%item%.sub_category_id!"=="2" (
    call :magicEnchantmentBonus 1 25 %level%
    set /a %item%.misc_use=!errorlevel! * 5
    call :magicShouldBeEnchanted %cursed%
    if "!errorlevel!"=="0" (
        set /a %item%.misc_use=*-1
        set /a %item%.cost=*-1
        set /a "%item%.flags|=%config.treasure.flags.TR_CURSED%"
    ) else (
        set /a %item%.cost+=50 * !%item%.misc_use!
    )
) else if "!%item%.sub_category_id!"=="8" (
    call :magicEnchantmentBonus 1 25 %level%
    set /a %item%.misc_use=!errorlevel! * 5
    set /a %item%.cost+=20 * !%item%.misc_use!
)
exit /b

::------------------------------------------------------------------------------
:: Randomly picks a type of magic wand based on its subtype
::
:: Arguments: %1 - The sub_category_id of the wand
:: Returns:   A random number based on the sub_category_id
::------------------------------------------------------------------------------
:wandMagic
set "item_stat_block[0]=10 6"
set "item_stat_block[1]=8 6"
set "item_stat_block[2]=5 6"
set "item_stat_block[3]=8 6"
set "item_stat_block[4]=4 3"
set "item_stat_block[5]=8 6"
set "item_stat_block[6]=20 12"
set "item_stat_block[7]=20 12"
set "item_stat_block[8]=10 6"
set "item_stat_block[9]=12 6"
set "item_stat_block[10]=10 12"
set "item_stat_block[11]=3 3"
set "item_stat_block[12]=8 6"
set "item_stat_block[13]=10 6"
set "item_stat_block[14]=5 3"
set "item_stat_block[15]=5 3"
set "item_stat_block[16]=5 6"
set "item_stat_block[17]=5 4"
set "item_stat_block[18]=8 4"
set "item_stat_block[19]=6 2"
set "item_stat_block[20]=4 2"
set "item_stat_block[21]=8 6"
set "item_stat_block[22]=5 2"
set "item_stat_block[23]=12 12"

if not defined item_stat_block[%~1] exit /b -1
for /f "tokens=1,2" %%A in ("!item_stat_block[%~1]!") do (
    call rng.cmd :randomNumber %%A
    set /a magic_number=!errorlevel!+%%B
)
exit /b !magic_number!

::------------------------------------------------------------------------------
:: Randomly picks a type of magic staff based on its subtype
::
:: Arguments: %1 - The sub_category_id of the staff
:: Returns:   A random number based on the sub_category_id
::------------------------------------------------------------------------------
:staffMagic
set "item_stat_block[0]=20 12"
set "item_stat_block[1]=8 6"
set "item_stat_block[2]=5 6"
set "item_stat_block[3]=20 12"
set "item_stat_block[4]=15 6"
set "item_stat_block[5]=4 5"
set "item_stat_block[6]=5 3"
set "item_stat_block[7]=3 1"
set "item_stat_block[8]=3 1"
set "item_stat_block[9]=5 6"
set "item_stat_block[10]=10 12"
set "item_stat_block[11]=5 6"
set "item_stat_block[12]=5 6"
set "item_stat_block[13]=5 6"
set "item_stat_block[14]=10 12"
set "item_stat_block[15]=3 4"
set "item_stat_block[16]=5 6"
set "item_stat_block[17]=5 6"
set "item_stat_block[18]=3 4"
set "item_stat_block[19]=10 12"
set "item_stat_block[20]=3 4"
set "item_stat_block[21]=3 4"
set "item_stat_block[22]=10 6"

if not defined item_stat_block[%~1] exit /b -1
for /f "tokens=1,2" %%A in ("!item_stat_block[%~1]!") do (
    call rng.cmd :randomNumber %%A
    set /a magic_number=!errorlevel!+%%B
)
exit /b !magic_number!

::------------------------------------------------------------------------------
:: Add cloaks to magical cloaks
::
:: Arguments: %1 - A reference to the item being enchanted
::            %2 - The odds of the item gaining magical attributes
::            %3 - The level of the dungeon that the player is on
:: Returns:   None
::------------------------------------------------------------------------------
:magicalCloak
set "item=%~1"
set "special=%~2"
set "level=%~3"

call :magicShouldBeEnchanted %special%
if "!errorlevel!"=="1" (
    call :magicEnchantmentBonus 1 20 %level%
    set /a %item%.to_ac+=!errorlevel!
    exit /b
)

call rng.cmd :randomNumber 2
if "!errorlevel!"=="1" (
    set "%item%.special_name_id=%SpecialNameIds.SN_PROTECTION%"
    call :magicEnchantmentBonus 2 40 %level%
    set /a %item%.to_ac+=!errorlevel!
    set /a %item%.cost+=250
    exit /b
)

call :magicEnchantmentBonus 1 20 %level%
set /a %item%.to_ac+=!errorlevel!
set /a "%item%.identification|=%config.identification.ID_SHOW_P1%"
call rng.cmd :randomNumber 3
set "%item%.misc_use=!errorlevel!"
set "%item%.flags|=%config.treasure.flags.TR_STEALTH%"
set "%item%.special_name_id=%SpecialNameIds.SN_STEALTH%"
set /a %item%.cost+=500
exit /b

::------------------------------------------------------------------------------
:: Convert cloaks to cursed cloaks
::
:: Arguments: %1 - A reference to the item being enchanted
::            %2 - The level of the dungeon that the player is on
:: Returns:   None
::------------------------------------------------------------------------------
:cursedCloak
set "item=%~1"
set "level=%~2"

call rng.cmd :randomNumber 3
set "magic_type=!errorlevel!"

if "!magic_type!"=="1" (
    set /a "%item%.flags|=%config.treasure.flags.TR_AGGRAVATE%"
    set "%item%.special_name_id=%SpecialNameIds.SN_IRRITATION%"
    call :magicEnchantmentBonus 1 10 %level%
    set /a %item%.to_ac-=!errorlevel!
    set /a "%item%.identification|=%config.identification.ID_SHOW_HIT_DAM%"
    call :magicEnchantmentBonus 1 10 %level%
    set /a %item%.to_hit-=!errorlevel!
    call :magicEnchantmentBonus 1 10 %level%
    set /a %item%.to_damage-=!errorlevel!
) else if "!magic_type!"=="2" (
    set "%item%.special_name_id=%SpecialNameIds.SN_VULNERABILITY%"
    set /a level_inc=%level%+50
    call :magicEnchantmentBonus 10 100 !level_inc!
    set /a %item%.to_ac-=!errorlevel!
) else (
    set "%item%.special_name_id=%SpecialNameIds.SN_ENVELOPING%"
    call :magicEnchantmentBonus 1 10 %level%
    set /a %item%.to_ac-=!errorlevel!
    set /a "%item%.identification|=%config.identification.ID_SHOW_HIT_DAM%"
    set /a level_inc=%level%+10
    call :magicEnchantmentBonus 2 40 !level_inc!
    set /a %item%.to_hit-=!errorlevel!
    call :magicEnchantmentBonus 2 40 !level_inc!
    set /a %item%.to_damage-=!errorlevel!
)

set "%item%.cost=0"
set /a "%item%.flags|=%config.treasure.flags.TR_CURSED%"
exit /b

::------------------------------------------------------------------------------
:: Enchants a magical chest
::
:: Arguments: %1 - A reference to the item being enchanted
::            %2 - The level of the dungeon that the player is on
:: Returns:   None
::------------------------------------------------------------------------------
:magicalChests
set "item=%~1"
set "level=%~2"

set /a level_inc=%level%+4
call rng.cmd :randomNumber %level_inc%
set "magic_type=!errorlevel!"

set "item_stat_block[1]=0 %SpecialNameIds.SN_EMPTY%"
set "item_stat_block[2]=%config.treasure.chests.CH_LOCKED% %SpecialNameIds.SN_LOCKED%"
set "item_stat_block[3]=%config.treasure.chests.CH_LOSE_STR%|%config.treasure.chests.CH_LOCKED% %SpecialNameIds.SN_POISON_NEEDLE%"
set "item_stat_block[4]=%config.treasure.chests.CH_LOSE_STR%|%config.treasure.chests.CH_LOCKED% %SpecialNameIds.SN_POISON_NEEDLE%"
set "item_stat_block[5]=%config.treasure.chests.CH_POISON%|%config.treasure.chests.CH_LOCKED% %SpecialNameIds.SN_POISON_NEEDLE%"
set "item_stat_block[6]=%config.treasure.chests.CH_POISON%|%config.treasure.chests.CH_LOCKED% %SpecialNameIds.SN_POISON_NEEDLE%"
set "item_stat_block[7]=%config.treasure.chests.CH_PARALYSED%|%config.treasure.chests.CH_LOCKED% %SpecialNameIds.SN_GAS_TRAP%"
set "item_stat_block[8]=%config.treasure.chests.CH_PARALYSED%|%config.treasure.chests.CH_LOCKED% %SpecialNameIds.SN_GAS_TRAP%"
set "item_stat_block[9]=%config.treasure.chests.CH_PARALYSED%|%config.treasure.chests.CH_LOCKED% %SpecialNameIds.SN_GAS_TRAP%"
set "item_stat_block[10]=%config.treasure.chests.CH_EXPLODE%|%config.treasure.chests.CH_LOCKED% %SpecialNameIds.SN_EXPLOSION_DEVICE%"
set "item_stat_block[11]=%config.treasure.chests.CH_EXPLODE%|%config.treasure.chests.CH_LOCKED% %SpecialNameIds.SN_EXPLOSION_DEVICE%"
set "item_stat_block[12]=%config.treasure.chests.CH_SUMMON%|%config.treasure.chests.CH_LOCKED% %SpecialNameIds.SN_SUMMONING_RUNES%"
set "item_stat_block[13]=%config.treasure.chests.CH_SUMMON%|%config.treasure.chests.CH_LOCKED% %SpecialNameIds.SN_SUMMONING_RUNES%"
set "item_stat_block[14]=%config.treasure.chests.CH_SUMMON%|%config.treasure.chests.CH_LOCKED% %SpecialNameIds.SN_SUMMONING_RUNES%"
set "item_stat_block[15]=%config.treasure.chests.CH_PARALYSED%|%config.treasure.chests.CH_POISON%|%config.treasure.chests.CH_LOST_STR%|%config.treasure.chests.CH_LOCKED% %SpecialNameIds.SN_MULTIPLE_TRAPS%"
set "item_stat_block[16]=%config.treasure.chests.CH_PARALYSED%|%config.treasure.chests.CH_POISON%|%config.treasure.chests.CH_LOST_STR%|%config.treasure.chests.CH_LOCKED% %SpecialNameIds.SN_MULTIPLE_TRAPS%"
set "item_stat_block[17]=%config.treasure.chests.CH_PARALYSED%|%config.treasure.chests.CH_POISON%|%config.treasure.chests.CH_LOST_STR%|%config.treasure.chests.CH_LOCKED% %SpecialNameIds.SN_MULTIPLE_TRAPS%"
set "item_stat_block[18]=%config.treasure.chests.CH_SUMMON%|%config.treasure.chests.CH_EXPLODE%|%config.treasure.chests.CH_LOCKED% %SpecialNameIds.SN_MULTIPLE_TRAPS%"

if not defined item_stat_block[%magic_type%] set "magic_type=18"
for /f "tokens=1,2" %%A in ("!item_stat_block[%magic_type%]!") do (
    if "%%A"=="0" (
        set "%item%.flags=0"
    ) else (
        set /a "%item%.flags|=(%%~A)"
    )
    set "%item%.special_name_id=%%~B"
)
exit /b

:magicalProjectileAdjustment
exit /b

:cursedProjectileAdjustment
exit /b

:magicalProjectile
exit /b

:magicTreasureMagicalAbility
exit /b

