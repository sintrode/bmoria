:: This one is pure data and is going to take a while to actually code
:: There are 279 creatures to add
@echo off
set "monster_count=0"
call :loadAttackData

call :addMonsterToCreatureList "Filthy Street Urchin" 1179658 0 8244 0 40 4 1 11 "p" 1 4 72 148 0 0 0
call :addMonsterToCreatureList "Blubbering Idiot"     1179658 0 8240 0  0 6 1 11 "p" 1 2 79   0 0 0 0

exit /b

::------------------------------------------------------------------------------
:: Adds a monster type to the creature_list array
::
:: Arguments: %1  - Name of the creature
::            %2  - CMOVE flags
::            %3  - SPELL flags
::            %4  - CDEFENSE flags
::            %5  - XP value
::            %6  - How many turns it takes for the player to be noticed
::            %7  - Max range that the creature is able to notice the player
::            %8  - Armor Class
::            %9  - speed
::            %10 - character displayed on map
::            %11 - number of hit dice
::            %12 - hit die max
::            %13 - attack type 1
::            %14 - attack type 2
::            %15 - attack type 3
::            %16 - attack type 4
::            %17 - monster level
:: Returns:   None
::------------------------------------------------------------------------------
:addMonsterToCreatureList
set "creatures_list[%monster_count%].name=%~1"
set "creatures_list[%monster_count%].movement=%~2"
set "creatures_list[%monster_count%].spells=%~3"
set "creatures_list[%monster_count%].defenses=%~4"
set "creatures_list[%monster_count%].kill_exp_value=%~5"
set "creatures_list[%monster_count%].sleep_counter=%~6"
set "creatures_list[%monster_count%].area_affect_radius=%~7"
set "creatures_list[%monster_count%].ac=%~8"
set "creatures_list[%monster_count%].speed=%~9"

for /L %%A in (1,1,9) do shift

set "creatures_list[%monster_count%].sprite=%~1"
set "creatures_list[%monster_count%].hit_die.dice=%~2"
set "creatures_list[%monster_count%].hit_die.sides=%~3"
set "creatures_list[%monster_count%].damage[1]=%~4"
set "creatures_list[%monster_count%].damage[2]=%~5"
set "creatures_list[%monster_count%].damage[3]=%~6"
set "creatures_list[%monster_count%].damage[4]=%~7"
set "creatures_list[%monster_count%].level=%~8"

set /a monster_count+=1
exit /b

::------------------------------------------------------------------------------
:: Adds all 215 attack types to the monster_attacks array
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:loadAttackData
set "attack_count=0"
call :addAttackToMonsterAttacks 0 0 0 0
call :addAttackToMonsterAttacks 1 1 1 2
exit /b

::------------------------------------------------------------------------------
:: Creates an element of the monster_attacks array
::
:: Arguments: %1 - attack type
::            %2 - attack description
::            %3 - attack hit die dice
::            %4 - attack hit die sides
:: Returns:   None
::------------------------------------------------------------------------------
:addAttackToMonsterAttacks
set "monster_attacks[%attack_count%].type=%~1"
set "monster_attacks[%attack_count%].description=%~2"
set "monster_attacks[%attack_count%].hit_die.dice=%~3"
set "monster_attacks[%attack_count%].hit_die.sides=%~4"
set /a attack_count+=1
exit /b