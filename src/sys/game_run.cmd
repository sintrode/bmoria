@echo off
pushd sys
call %*
popd
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
call store.cmd :storeInitializeOwners

:: Base EXP levels need initializing before loading a game
call player_stats.cmd :playerInitializeBaseExperienceLevels

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
    call wizard.cmd :enterWizardMode || call game_death.cmd :endGame
)

if "%result%"=="true" (
    call ui.cmd :changeCharacterName

    if "%py.misc.current_hp%" LSS "0" set "game.character_is_dead=true"
) else (
    call character.cmd :characterCreate
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

::------------------------------------------------------------------------------
:: Check for a maximum level
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerUpdateMaxDungeonDepth
if "%dg.current_level%"=="%py.misc.max_dungeon_depth%" (
    set "py.misc.max_dungeon_depth=%dg.current_level%"
)
exit /b

::------------------------------------------------------------------------------
:: Check light status
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerUpdateLightStatus
:: Pointers aren't a thing in batch. This is just here so that I don't have to
:: type so much.
set "item=!py.inventory[%inventory.PlayerEquipment.Light%].misc_use!"

if "%py.carrying_light%"=="true" (
    if !item! GTR 0 (
        set /a item-=1

        if "!item!"=="0" (
            set "py.carrying_light=false"
            call ui_io.cmd :printMessage "Your light has gone out."
            call player.cmd :playerDisturb 0 1
            call monster.cmd :updateMonsters false
        ) else (
            if !item! LSS 40 (
                call game.cmd :randomNumber 5
                if "!errorlevel!"=="1" (
                    if %py.flags.blind% LSS 1 (
                        call player.cmd :playerDisturb 0 0
                        call ui_io.cmd :printMessage "Your light is growing faint."
                    )
                )
            )
        )
    ) else (
        set "py.carrying_light=false"
        call player.cmd :playerDisturb 0 1
        call monster.cmd :updateMonsters false
    )
) else (
    if !item! GTR 0 (
        set /a item-=1
        set "py.carrying_light=true"
        call player.cmd :playerDisturb 0 1
        call monster.cmd :updateMonsters false
    )
)
set "py.inventory[%inventory.PlayerEquipment.Light%].misc_use=!item!"
exit /b

::------------------------------------------------------------------------------
:: git gud
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerActivateHeroism
set /a "py.flags.status|=%config.player.status.py_hero%"
call player.cmd :playerDisturb 0 0

set /a py.misc.max_hp+=10
set /a py.misc.current_hp+=10
set /a py.misc.bth+=12
set /a py.misc.bth_with_bows+=12

call ui_io.cmd :printMessage "You feel like a HERO."
call ui.cmd :printCharacterMaxHitPoints
call ui.cmd :printCharacterCurrentHitPoints
exit /b

::------------------------------------------------------------------------------
:: stop getting gud
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerDisableHeroism
set /a "py.flags.status&=~%config.player.status.py_hero%"
call player.cmd :playerDisturb 0 0

set /a py.misc.max_hp-=10
if !py.misc.current_hp! LSS !py.misc.max_hp! (
    set "py.misc.current_hp=!py.misc.max_hp!"
    set "py.misc.current_hp_fraction=0"
    call ui.cmd :printCharacterCurrentHitPoints
)
set /a py.misc.bth-=12
set /a py.misc.bth_with_bows-=12
call ui_io.cmd :printMessage "The heroism wears off."
call ui.cmd :printCharacterMaxHitPoints
exit /b

::------------------------------------------------------------------------------
:: git gudder
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerActivateSuperHeroism
set /a "py.flags.status|=%config.player.status.py_shero%"
call player.cmd :playerDisturb 0 0

set /a py.misc.max_hp+=20
set /a py.misc.current_hp+=20
set /a py.misc.bth+=24
set /a py.misc.bth_with_bows+=24

call ui_io.cmd :printMessage "You feel like a SUPERHERO."
call ui.cmd :printCharacterMaxHitPoints
call ui.cmd :printCharacterCurrentHitPoints
exit /b

::------------------------------------------------------------------------------
:: stop getting gudder
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerDisableSuperHeroism
set /a "py.flags.status&=~%config.player.status.py_shero%"
call player.cmd :playerDisturb 0 0

set /a py.misc.max_hp-=20
if !py.misc.current_hp! LSS !py.misc.max_hp! (
    set "py.misc.current_hp=!py.misc.max_hp!"
    set "py.misc.current_hp_fraction=0"
    call ui.cmd :printCharacterCurrentHitPoints
)
set /a py.misc.bth-=24
set /a py.misc.bth_with_bows-=24
call ui_io.cmd :printMessage "The superheroism wears off."
call ui.cmd :printCharacterMaxHitPoints
exit /b

::------------------------------------------------------------------------------
:: Updates the Hero status
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerUpdateHeroStatus
if %py.flags.heroism% GTR 0 (
    set /a "already_hero=!py.flags.status!&!config.player.status.py_hero!"
    if "!already_hero!"=="0" call :playerActivateHeroism
    set "already_hero="
    set /a py.flags.heroism-=1
    if "!py.flags.heroism!"=="0" call :playerDisableHeroism
)
if %py.flags.super_heroism% GTR 0 (
    set /a "already_hero=!py.flags.status!&!config.player.status.py_shero!"
    if "!already_hero!"=="0" call :playerActivateSuperHeroism
    set "already_hero="
    set /a py.flags.super_heroism-=1
    if "!py.flags.super_heroism!"=="0" call :playerDisableSuperHeroism
)
exit /b

::------------------------------------------------------------------------------
:: Calculates the amount of regeneration to be done
::
:: Arguments: None
:: Returns:   How much HP and mana should be regenerated
::------------------------------------------------------------------------------
:playerFoodConsumption
exit /b !regen_amount!

::------------------------------------------------------------------------------
:: Regenerates health and mana
::
:: Arguments: %1 - The amount of HP/MP to regenerate
:: Returns:   None
::------------------------------------------------------------------------------
:playerUpdateRegeneration
exit /b

::------------------------------------------------------------------------------
:: Act on the player's blindness
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerUpdateBlindness
exit /b

::------------------------------------------------------------------------------
:: Act on the player's confusion
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerUpdateConfusion
exit /b

::------------------------------------------------------------------------------
:: Act on the player's fear
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerUpdateFearState
exit /b

::------------------------------------------------------------------------------
:: Act on the player's being poisoned
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerUpdatePoisonedState
exit /b

::------------------------------------------------------------------------------
:: Act on the player's quickness
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerUpdateFastness
exit /b

::------------------------------------------------------------------------------
:: Act on the player's slowness
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerUpdateSlowness
exit /b

::------------------------------------------------------------------------------
:: Act on the player's speed
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerUpdateSpeed
call :playerUpdateFastness
call :playerUpdateSlowness
exit /b

::------------------------------------------------------------------------------
:: Determine if naptime is over
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerUpdateRestingState
exit /b

::------------------------------------------------------------------------------
:: Make random characters appear if the player is hallucinating
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerUpdateHallucination
exit /b

::------------------------------------------------------------------------------
:: Act on the player's paralysis
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerUpdateParalysis
exit /b

::------------------------------------------------------------------------------
:: Act on the player's protection from evil
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerUpdateEvilProtection
exit /b

::------------------------------------------------------------------------------
:: Act on the player's invulnerability
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerUpdateInvulnerability
exit /b

::------------------------------------------------------------------------------
:: Act on the player's blessedness
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerUpdateBlessedness
exit /b

::------------------------------------------------------------------------------
:: Act on the player's heat resistance
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerUpdateHeatResistance
exit /b

::------------------------------------------------------------------------------
:: Act on the player's cold resistance
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerUpdateColdResistance
exit /b

::------------------------------------------------------------------------------
:: Act on the player's ability to see things
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerUpdateDetectInvisible
exit /b

::------------------------------------------------------------------------------
:: Act on the player's infra vision
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerUpdateInfraVision
exit /b

::------------------------------------------------------------------------------
:: Act on the Word-of-Recall
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerUpdateWordOfRecall
exit /b

::------------------------------------------------------------------------------
:: Act on the player's status flags
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerUpdateStatusFlags
exit /b

::------------------------------------------------------------------------------
:: See if any of the player's items are enchanted
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerDetectEnchantment
exit /b

::------------------------------------------------------------------------------
:: Determine how many times a command is to be repeated
::
:: Arguments: %1 - The command to rerun
:: Returns:   The number of times to repeat the command
::------------------------------------------------------------------------------
:getCommandRepeatCount
exit /b !repeat_count!

::------------------------------------------------------------------------------
:: Accept a command and input it
::
:: Arguments: %1 - The command to run
::            %2 - A counter for finding things
:: Returns:   None
::------------------------------------------------------------------------------
:executeInputCommands
exit /b

::------------------------------------------------------------------------------
:: Set command based on input
::
:: Arguments: %1 - The key pressed by the user
:: Returns:   None
::------------------------------------------------------------------------------
:originalCommands
exit /b

::------------------------------------------------------------------------------
:: Allows the player to run in a direction without picking up unwanted items
::
:: Arguments: %1 - The key pressed by the user
:: Returns:   None
::------------------------------------------------------------------------------
:moveWithoutPickup
exit /b

::------------------------------------------------------------------------------
:: Exit the game
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:commandQuit
exit /b

::------------------------------------------------------------------------------
:: Determines how many previous messages to display
::
:: Arguments: None
:: Returns:   The number of previous messages to return
::------------------------------------------------------------------------------
:calculateMaxMessageCount
exit /b !max_messages!

::------------------------------------------------------------------------------
:: Displays previous messages
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:commandPreviousMessage
exit /b

::------------------------------------------------------------------------------
:: Toggles Wizard Mode
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:commandFlipWizardMode
exit /b

::------------------------------------------------------------------------------
:: Save and exit the game
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:commandSaveAndExit
exit /b

::------------------------------------------------------------------------------
:: Looks at the map
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:commandLocateOnMap
exit /b

::------------------------------------------------------------------------------
:: Toggles the Search feature
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:commandToggleSearch
exit /b

::------------------------------------------------------------------------------
:: Like executeInputCommands, but as a Wizard
::
:: Arguments: %1 - The key pressed by the Wizard user
:: Returns:   None
::------------------------------------------------------------------------------
:doWizardCommands
exit /b

::------------------------------------------------------------------------------
:: A switch statement for determining the action to take based on the command
::
:: Arguments: %1 - The key pressed by the user
:: Returns:   None
::------------------------------------------------------------------------------
:doCommand
exit /b

::------------------------------------------------------------------------------
:: Check whether the command will accept a count
::
:: Arguments: %1 - The key pressed by the user
:: Returns:   0 if the command accepts a count, 1 otherwise
::------------------------------------------------------------------------------
:validCountCommand
exit /b !is_valid_count_command!

::------------------------------------------------------------------------------
:: Regenerates hit points
::
:: Arguments: %1 - The percent of HP to regain
:: Returns:   None
::------------------------------------------------------------------------------
:playerRegenerateHitPoints
exit /b

::------------------------------------------------------------------------------
:: Regenerates mana
::
:: Arguments: %1 - The percent of mana to regain
:: Returns:   None
::------------------------------------------------------------------------------
:playerRegenerateMana
exit /b

::------------------------------------------------------------------------------
:: Determines if an item is secretly an enchanted weapon or armor
::
:: Arguments: %1 - The item to check
:: Returns:   0 if the item is enchanted, 1 otherwise
::------------------------------------------------------------------------------
:itemEnchanted
exit /b

::------------------------------------------------------------------------------
:: Read a book
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:examineBook
exit /b

::------------------------------------------------------------------------------
:: Go up one level
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonGoUpLevel
exit /b

::------------------------------------------------------------------------------
:: Go down one level
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonGoDownLevel
exit /b

::------------------------------------------------------------------------------
:: Jam a closed door
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonJamDoor
exit /b

::------------------------------------------------------------------------------
:: Refill the player's lamp
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:inventoryRefillLamp
exit /b

::------------------------------------------------------------------------------
:: Main procedure for the dungeon
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playDungeon
exit /b