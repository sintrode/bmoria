@echo off
call %*
exit /b

::------------------------------------------------------------------------------
:: The main game loop
::
:: Arguments: %1 - Seed for randomization
::            %2 - true if a new game should be forced, false otherwise
::------------------------------------------------------------------------------
:startMoria
set "seed=%~1"
set "start_new_game=%~2"

:: Roguelike keys are disabled by default.
:: This will be overridden by the setting in the game save file
set "config.options.use_roguelike_keys=false"

call :priceAdjust

:: Show the game splash screen
call game_files.cmd :displaySplashScreen

:: Grab a random seed from the clock
call game.cmd :seedsInitialize "%~1"

:: Initialize monster and treasure levels for allocation
call :initializeMonsterLevels
call :initializeTreasureLevels

:: Initialize store inventories
call :storeInitializeOwners

:: Base EXP levels need initializing before loading a game
call :playerInitializeBaseExperienceLevels

:: Initialize some player fields
set "py.flags.spells_learnt=0"
set "py.flags.spells_worked=0"
set "py.flags.spells_forgotten=0"

:: This restoration of a saved character may get ONLY the monster memory. In
:: this case, loadGame() returns false. It may also resurrect a dead character
:: (if you are the wizard). In this case, it returns true, but also sets the
:: parameter "generate" to true, as it does not recover any cave details.
set "result=false"
set "generate=false"

if "%start_new_game%"=="false" (
    if exist "%config.files.save_game%" (
        call game_save.cmd :loadGame %generate% && set "result=true"
    )
)

:: Enter wizard mode before showing the character display, but must wait
:: until after loadGame() in case it was just a resurrection
if "%game.to_be_wizard%"=="true" (
    call :enterWizardMode || call :endGame
)

if "%result%"=="true" (
    call :changeCharacterName

    if %py.misc.current_hp% GTR 0 set "game.character_is_dead=true"
) else (
    call :characterCreate
    for /f "tokens=2 delims==." %%A in ('wmic os get localdatetime /value ^| find "="') do (
        set "py.misc.date_of_birth=%%A"
    )

    call :initializeCharacterInventory
    set "py.flags.food=7500"
    set "py.flags.food_digested=2"

    if "!classes[%py.misc.class_id%].class_to_use_mage_spells!"=="%config.spells.spell_type_mage%" (
        cls
        call player.cmd :playerCalculateAllowedSpellsCount %PlayerAttr.a_int%
        call player.cmd :playerGainMana %PlayerAttr.a_int%
    )
    if "!classes[%py.misc.class_id%].class_to_use_mage_spells!"=="%config.spells.spell_type_priest%" (
        cls
        call player.cmd :playerCalculateAllowedSpellsCount %PlayerAttr.a_wis%
        call player.cmd :playerGainMana %PlayerAttr.a_wis%
    )

    set "py.temporary_light_only=false"
    set "py.weapon_is_heavy=false"
    set "py.pack.heaviness=0"
    set "game.character_generated=true"
    set "generate=true"
)

call identification.cmd :magicInitializeItemNames

:: Actually begin the game at this point
cls
call ui_io.cmd :putString "Press ? for help" 0 63
call ui.cmd :printCharacterStatsBlock

if "%generate%"=="true" call dungeon_generate.cmd :generateCave

:coreGameLoop
call :playDungeon
call dungeon_generate.cmd :generateCave
if "%game.character_is_dead%"=="false" goto :coreGameLoop
call game_death.cmd :endGame
exit /b

::------------------------------------------------------------------------------
:: Initialize players with some belongings
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:initializeCharacterInventory
call inventory.cmd :new_inventory
for /L %%A in (0,1,4) do (
    call inventory.cmd :inventoryItemCopyTo "!class_base_provisions[%py.misc.class_id%][%%A]!" item
    call identification.cmd :itemIdentifyAsStoreBought item
    if "!item.category_id!"=="%treasure.tv_sword%" (
        set /a "item.identification|=%config.identification.id_show_hit_dam%"
    )
    call inventory.cmd :inventoryCarryItem item
)

:: I don't know why this is here, but here it is
for /L %%A in (0,1,31) do set "py.flags.spells_learned_order[%%A]=99"
exit /b

::------------------------------------------------------------------------------
:: Initializes the monster_level array for use with PLACE_MONSTER
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:initializeMonsterLevels
for /L %%A in (0,1,40) do set "monster_levels[%%A]=0"
set /a monster_count=%mon_max_creatures%-%config.monsters.mon_endgame_monsters%

for /L %%A in (0,1,%monster_count%) do (
    set "temp_mon_level=!creatures_list[%%A].level!"
    set /a monster_levels[!temp_mon_level!]+=1
)
set "temp_mon_level="

for /L %%A in (1,1,%mon_max_levels%) do (
    set /a temp_prev=%%A-1
    set /a monster_levels[%%A]+=monster_levels[!temp_prev!]
)
set "temp_prev="
exit /b

::------------------------------------------------------------------------------
:: Initializes the treasure_level array for use with PLACE_OBJECT
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:initializeTreasureLevels
for /L %%A in (1,1,50) do set "treasure_levels[%%A]=0"

for /L %%A in (0,1,%max_dungeon_objects%) do (
    set "temp_first_depth=!game_objects[%%A].depth_first_found!"
    set /a treasure_levels[!temp_first_depth!]+=1
)
set "temp_first_depth="

for /L %%A in (1,1,%treasure_max_levels%) do (
    set /a temp_prev=%%A-1
    set /a treasure_levels[%%A]=treasure_levels[!temp_prev!]
)
set "temp_prev="

:: Produce an array with object indices sorted by level by using the info
:: in treasure_levels. This claims to be O(n).
for /L %%A in (0,1,%treasure_max_levels%) do set "indexes[%%A]=1"
for /L %%A in (0,1,%max_dungeon_objects%) do (
    set "level=!game_objects[%%A].depth_first_found!"
    set /a object_id=treasure_levels[!level!]-indexes[!level!]
    set "sorted_objects[!object_id!]=%%A"
    set /a indexes[!level!]+=1
)
exit /b

::------------------------------------------------------------------------------
:: Adjusts the proces of objects
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:priceAdjust
if not "%cost_adjustment%"=="100" (
    for /L %%A in (0,1,419) do (
        set /a "game_objects[%%A].cost=((!game_objects[%%A].cost!*%cost_adjustment%+50)/100"
    )
)
exit /b

::------------------------------------------------------------------------------
:: Reset flags and initialize variables
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:resetDungeonFlags
set "game.command_count=0"
set "dg.generate_new_level=false"
set "py_running_tracker=0"
set "game.teleport_player=false"
set "monster_multiply_total=0"
set "dg.floor[!py.pos.y!][!py.pos.x!].creature_id=1"
exit /b

::------------------------------------------------------------------------------
:: Checks light status for dungeon setup
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerInitializePlayerLight
if !py.inventory[inventory.PlayerEquipment.Light].misc_use! GTR 0 (
    set "py.carrying_light=true"
) else (
    set "py.carrying_light=false"
)
exit /b