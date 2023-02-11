@echo off
call %*
exit /b

::------------------------------------------------------------------------------
:: Generates an array of experience points required to level up
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerInitializeBaseExperienceLevels
for /L %%A in (0,1,39) do set "py.base_exp_levels[%%A]=!levels[%%A]!"
exit /b

::------------------------------------------------------------------------------
:: Calculates the player's hit points
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerCalculateHitPoints
set /a level_dec=%py.misc.level%-1, level_inc=%py.misc_level%+1
call :playerStatAdjustmentConstitution
set /a "hp=!py.base_hp_levels[%level_dec%]!+(!errorlevel!*%py.misc.level%)"

if %hp% LSS %level_inc% set "hp=%level_inc%"
set /a "is_hero=%py.flags.status% & %config.player.status.py_hero%"
if not "%is_hero%"=="0" set /a hp+=10
set /a "is_shero=%py.flags.status% & %config.player.status.py_shero%"
if not "%is_shero%"=="0" set /a hp+=20

if not "%hp%"=="%py.misc.max_hp%" (
    if not "%py.misc.max_hp%"=="0" (
        set /a "value=((%py.misc.current_hp% << 16) + %py.misc.current_hp_fraction%) / %py.misc.max_hp% * %hp%"
        set /a "py.misc.current_hp=!value! >> 16"
        set /a "py.misc.current_hp_fraction=!value! & 0xFFFF"
        set "py.misc.max_hp=!hp!"
        set /a "py.flags.status|=%config.player.status.py_hp%"
    )
)
exit /b

::------------------------------------------------------------------------------
:: Returns the number of dexterity-based blows a player gets in combat
::
:: Arguments: %1 - The player's dexterity value
:: Returns:   1 or 2, mostly tbh
::------------------------------------------------------------------------------
:playerAttackBlowsDexterity
if %~1 LSS 10 (
    set "dex=0"
) else if %~1 LSS 19 (
    set "dex=1"
) else if %~1 LSS 68 (
    set "dex=2"
) else if %~1 LSS 108 (
    set "dex=3"
) else if %~1 LSS 118 (
    set "dex=4"
) else (
    set "dex=5"
)
exit /b !dex!

::------------------------------------------------------------------------------
:: Returns the number of strength-based blows a player gets in combat
::
:: Arguments: %1 - The player's strength value
::            %2 - The weight of the weapon being used
::------------------------------------------------------------------------------
:playerAttackBlowsStrength
set /a adj_weight=%~1 * 10 / %~2

if !adj_weight! LSS 2 (
    set "str=0"
) else if !adj_weight! LSS 3 (
    set "str=1"
) else if !adj_weight! LSS 4 (
    set "str=2"
) else if !adj_weight! LSS 5 (
    set "str=3"
) else if !adj_weight! LSS 7 (
    set "str=4"
) else if !adj_weight! LSS 9 (
    set "str=5"
) else (
    set "str=6"
)
exit /b !str!

::------------------------------------------------------------------------------
:: Calculate the number of attacks a player is able to perform per turn
::
:: Arguments: %1 - The weight of the weapon being used
::            %2 - The player's to_hit, affected by weight
:: Returns:   The number of attacks a player is able to perform per turn
::------------------------------------------------------------------------------
:playerAttackBlows
set "%~2=0"
set "player_strength=!py.stats.used[%PlayerAttr.a_str%]!"
set /a str_inc=%player_strength%*15
if %str_inc% LSS %~1 (
    set /a weight_to_hit=%player_strength% * 15 - %~1
    exit /b 1
)

call :playerAttackBlowsDexterity !py.stats.used[%PlayerAttr.a_dex%]!
set "dexterity=!errorlevel!"
call :playerAttackBlowsStrength %player_strength% %~1
set "strength=!errorlevel!"
exit /b !blows_table[%strength%][%dexterity%]!

::------------------------------------------------------------------------------
:: Adjustment for Wisdom and Intelligence
::
:: Arguments: %1 - The stat being used
:: Returns:   An offset value based on the specified value
::------------------------------------------------------------------------------
:playerStatAdjustmentWisdomIntelligence
if !py.stats.used[%~1]! GTR 117 (
    set "adjustment=7"
) else if !py.stats.used[%~1]! GTR 107 (
    set "adjustment=6"
) else if !py.stats.used[%~1]! GTR 87 (
    set "adjustment=5"
) else if !py.stats.used[%~1]! GTR 67 (
    set "adjustment=4"
) else if !py.stats.used[%~1]! GTR 17 (
    set "adjustment=3"
) else if !py.stats.used[%~1]! GTR 14 (
    set "adjustment=2"
) else if !py.stats.used[%~1]! GTR 7 (
    set "adjustment=1"
) else (
    set "adjustment=0"
)
exit /b !adjustment!

::------------------------------------------------------------------------------
:: Adjustment for Charisma - percent increase or decrease in price of goods
::
:: Arguments: None
:: Returns:   An offset value based on the player's charisma
::------------------------------------------------------------------------------
:playerStatAdjustmentCharisma
if !py.stats.used[%PlayerAttr.a_chr%]! GTR 117 (
    exit /b 90
) else if !py.stats.used[%PlayerAttr.a_chr%]! GTR 107 (
    exit /b 92
) else if !py.stats.used[%PlayerAttr.a_chr%]! GTR 87 (
    exit /b 94
) else if !py.stats.used[%PlayerAttr.a_chr%]! GTR 67 (
    exit /b 96
) else if !py.stats.used[%PlayerAttr.a_chr%]! GTR 18 (
    exit /b 98
) else if !py.stats.used[%PlayerAttr.a_chr%]! EQU 18 (
    exit /b 100
) else if !py.stats.used[%PlayerAttr.a_chr%]! EQU 17 (
    exit /b 101
) else if !py.stats.used[%PlayerAttr.a_chr%]! EQU 16 (
    exit /b 102
) else if !py.stats.used[%PlayerAttr.a_chr%]! EQU 15 (
    exit /b 103
) else if !py.stats.used[%PlayerAttr.a_chr%]! EQU 14 (
    exit /b 104
) else if !py.stats.used[%PlayerAttr.a_chr%]! EQU 13 (
    exit /b 106
) else if !py.stats.used[%PlayerAttr.a_chr%]! EQU 12 (
    exit /b 108
) else if !py.stats.used[%PlayerAttr.a_chr%]! EQU 11 (
    exit /b 110
) else if !py.stats.used[%PlayerAttr.a_chr%]! EQU 10 (
    exit /b 112
) else if !py.stats.used[%PlayerAttr.a_chr%]! EQU 9 (
    exit /b 114
) else if !py.stats.used[%PlayerAttr.a_chr%]! EQU 8 (
    exit /b 116
) else if !py.stats.used[%PlayerAttr.a_chr%]! EQU 7 (
    exit /b 118
) else if !py.stats.used[%PlayerAttr.a_chr%]! EQU 6 (
    exit /b 120
) else if !py.stats.used[%PlayerAttr.a_chr%]! EQU 5 (
    exit /b 122
) else if !py.stats.used[%PlayerAttr.a_chr%]! EQU 4 (
    exit /b 125
) else if !py.stats.used[%PlayerAttr.a_chr%]! EQU 3 (
    exit /b 130
)
exit /b 100

::------------------------------------------------------------------------------
:: Adjustment for Constitution
::
:: Arguments: None
:: Returns:   An offset based on the player's constitution
::------------------------------------------------------------------------------
:playerStatAdjustmentConstitution
if !py.stats.used[%PlayerAttr.a_con%]! LSS 7 (
    set /a cons=!py.stats.used[%PlayerAttr.a_con%]!-7
    exit /b !cons!
) else if !py.stats.used[%PlayerAttr.a_con%]! LSS 17 (
    exit /b 0
) else if !py.stats.used[%PlayerAttr.a_con%]! EQU 17 (
    exit /b 1
) else if !py.stats.used[%PlayerAttr.a_con%]! LSS 94 (
    exit /b 2
) else if !py.stats.used[%PlayerAttr.a_con%]! LSS 117 (
    exit /b 3
)
exit /b 4

:playerModifyStat
exit /b

:playerSetAndUseStat
exit /b

:playerStatRandomIncrease
exit /b

:playerStatRandomDecrease
exit /b

:playerStatRestore
exit /b

:playerStatBoost
exit /b

:playerToHitAdjustment
exit /b

:playerArmorClassAdjustment
exit /b

:playerDisarmAdjustment
exit /b

:playerDamageAdjustment
exit /b
