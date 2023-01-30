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
call ui_io.cmd :putString "Press ? for help" "0;63"
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
set "regen_amount=%config.player.player_regen_normal%"

if %py.flags.food% LSS %config.player.player_food_alert% (
    if %py.flags.food% LSS %config.player.player_food_weak% (
        if %py.flags.food% LSS 0 (
            set "regen_amount=0"
        ) else if %py.flags.food% LSS %config.player.player_food_faint% (
            set "regen_amount=%config.player.player_regen_faint%"
        ) else if %py.flags.food% LSS %config.player.player_food_weak% (
            set "regen_amount=%config.player.player_regen_weak%"
        )

        set /a "is_weak=%py.flags.status%&%config.player.status.py_weak%"
        if "!is_weak!"=="0" (
            set /a "py.flags.status|=%config.player.status.py_weak%"
            call ui.io.cmd :printMessage "You are getting weak from hunger."
            call player.cmd :playerDisturb 0 0
            call ui.cmd :printCharacterHungerStatus
        )
        set "is_weak="

        if %py.flags.food% LSS %config.player.player_food_faint% (
            call :game.cmd :randomNumber 8
            if "!errorlevel!"=="1" (
                call :game.cmd :randomNumber 5
                set /a py.flags.paralysis+=!errorlevel!
                call ui_io.cmd :printMessage "You faint from the lack of food."
                call player.cmd :playerDisturb 1 0
            )
        )
    ) else (
        set /a "is_hungry=%py.flags.status%&%config.player.status.py_hungry%"
        if "!is_hungry!"=="0" (
            set /a "py.flags.status|=%config.player.status.py_hungry%"
            call ui_io.cmd :printMessage "You are getting hungry."
            call player.cmd :playerDisturb 0 0
            call ui.cmd :printCharacterHungerStatus
        )
    )
)

:: Food consumption
if %py.flags.speed% LSS 0 (
    set /a speed_squared=%py.flags.speed%*%py.flags.speed%
    set /a py.flags.food-=speed_squared
    set "speed_squared="
)
set /a py.flags.food-=%py.flags.food_digested%

if %py.flags.food% LSS 0 (
    set /a hunger_damage=-%py.flags.food%/16
    call player.cmd :playerTakesHit !hunger_damage! "starvation"
    set "hunger_damage="
    call player.cmd :playerDisturb 1 0
)
exit /b !regen_amount!

::------------------------------------------------------------------------------
:: Regenerates health and mana
::
:: Arguments: %1 - The amount of HP/MP to regenerate
:: Returns:   None
::------------------------------------------------------------------------------
:playerUpdateRegeneration
set "amount=%~1"
if "%py_flags.regenerate_hp%"=="true" (
    set /a amount=!amount!*3/2
)

set /a "is_searching=%py.flags.status%&%config.player.status.py_search%"
if !is_searching! NEQ 0 set /a amount*=2
set "is_searching="
if %py.flags.rest% NEQ 0 set /a amount*=2

if %py.flags.poisoned% LSS 1 (
    if %py.misc.current_hp% LSS %py.misc.max_hp% (
        call :playerRegenerateHitPoints !amount!
    )
)

if %py.misc.current_mana% LSS %py.misc.mana% (
    call :playerRegenerateMana !amount!
)
exit /b

::------------------------------------------------------------------------------
:: Act on the player's blindness
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerUpdateBlindness
if %py.flags.blind% LEQ 0 exit /b

set /a "is_blind=%py.flags.status%&%config.player.status.py_blind%"
if "!is_blind!"=="0" (
    set /a "py.flags.status|=%config.player.status.py_blind%"

    call ui.cmd :drawDungeonPanel
    call ui.cmd :printCharacterBlindStatus
    call player.cmd :playerDisturb 0 1

    call monster.cmd :updateMonsters "false"
)
set "is_blind="

set /a py.flags.blind-=1

if "%py.flags.blind%"=="0" (
    set /a "py.flags.status&=~%config.player.status.py_blind%"

    call ui.cmd :printCharacterBlindStatus
    call ui.cmd :drawDungeonPanel
    call player.cmd :playerDisturb 0 1

    call monster.cmd :updateMonsters "false"

    call ui_io.cmd :printMessage "The veil of darkness lifts."
)
exit /b

::------------------------------------------------------------------------------
:: Act on the player's confusion
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerUpdateConfusion
if %py.flags.confused% LEQ 0 exit /b

set /a "is_confused=%py.flags.status%&%config.player.status.py_confused%"
if "!is_confused!"=="0" (
    set /a "py.flags.status|=%config.player.status.py_confused%"
    call ui.cmd :printCharacterConfusedState
)
set "is_confused="

set /a py.flags.confused-=1

if "%py.flags.confused%"=="0" (
    set /a "py.flags.status&=~%config.player.status.py_confused%"
    
    call ui.cmd :printCharacterConfusedState
    call ui_io.cmd :printMessage "You feel less confused now."

    if %py.flags.rest% NEQ 0 (
        call player.cmd :playerRestOff
    )
)
exit /b

::------------------------------------------------------------------------------
:: Act on the player's fear
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerUpdateFearState
if %py.flags.afraid% LEQ 0 exit /b

set /a "is_afraid=%py.flags.status%&%config.player.status.py_fear%"
set /a "is_hero=%py.flags.super_heroism%+%py.flags.heroism%"
if "!is_afraid!"=="0" (
    if !is_hero! GTR 0 (
        set "py.flags.afraid=0"
    ) else (
        set /a "py.flags.status|=%config.player.status.py_fear%"
        call ui.cmd :printCharacterFearState
    )
) else if !is_hero! GTR 0 (
    set "py.flags.afraid=1"
)
set "is_afraid="
set "is_hero="

set /a py.flags.afraid-=1

if "%py.flags.afraid%"=="0" (
    set /a "py.flags.status&=~%config.player.status.py_fear%"
    call ui.cmd :printCharacterFearState
    call ui_io.cmd :printMessage "You feel bolder now."
    call player.cmd :playerDisturb 0 0
)
exit /b

::------------------------------------------------------------------------------
:: Act on the player's being poisoned
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerUpdatePoisonedState
if %py.flags.poisoned% LEQ 0 exit /b

set /a "is_poisoned=%py.flags.status%&%config.player.status.py_poisoned%"
if "!is_poisoned!"=="0" (
    set /a "py.flags.status|=%config.player.status.py_poisoned%"
    call ui.cmd :printCharacterPoisonedState
)
set "is_poisoned="

set /a py.flags.poisoned-=1

if "%py.flags.poisoned%"=="0" (
    set /a "py.flags.status&=~%config.player.status.py_poisoned%"

    call ui.cmd :printCharacterPoisonedState
    call ui_io.cmd :printMessage "You feel better."
    call player.cmd :playerDisturb 0 0
    exit /b
)

:: Batch doesn't have switch statements so you either have a ton of extra
:: labels or a monstrosity of if statements
set "damage=0"
call player_stats.cmd :playerStatAdjustmentConstitution
set "con_delta=!errorlevel!"
call :poi!con_delta!
set "con_delta="

call player.cmd :playerTakesHit !damage! "poison!"
call player.cmd :playerDisturb 1 0
set "damage="
exit /b

:: I am genuinely surprised that this works
:poi-4
set "damage=4"
exit /b

:poi-3
:poi-2
set "damage=3"
exit /b

:poi-1
set "damage=2"
exit /b

:poi0
set "damage=1"
exit /b

:poi1
:poi2
:poi3
set /a turn_mod=%dg.game_turn%%%2
if "%turn_mod%"=="0" set "damage=1"
set "turn_mod="
exit /b

:poi4
:poi5
set /a turn_mod=%dg.game_turn%%%3
if "%turn_mod%"=="0" set "damage=1"
set "turn_mod="
exit /b

:poi6
set /a turn_mod=%dg.game_turn%%%4
if "%turn_mod%"=="0" set "damage=1"
set "turn_mod="
exit /b

::------------------------------------------------------------------------------
:: Act on the player's quickness
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerUpdateFastness
if %py.flags.fast% LEQ 0 exit /b

set /a "is_fast=%py.flags.status%&%config.player.status.py_fast%"
if "!is_fast!"=="0" (
    set /a "py.flags.status|=%config.player.status.py_fast%"
    call player.cmd :playerChangeSpeed -1
    call ui_io.cmd :printMessage "You feel yourself moving faster."
    call player.cmd :playerDisturb 0 0
)
set "is_fast="

set /a py_flags.fast-=1

if "%py.flags.fast%"=="0" (
    set /a "py.flags.status&=~%config.player.status.py_fast%"
    call player.cmd :playerChangeSpeed 1

    call ui_io.cmd :printMessage "You feel yourself slow down."
    call player.cmd :playerDisturb 0 0
)
exit /b

::------------------------------------------------------------------------------
:: Act on the player's slowness
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerUpdateSlowness
if %py.flags.slow% LEQ 0 exit /b

set /a "is_slow=%py.flags.status%&%config.player.status.py_slow%"
if "!is_slow!"=="0" (
    set /a "py.flags.status|=%config.player.status.py_slow%"
    call player.cmd :playerChangeSpeed 1
    call ui_io.cmd :printMessage "You feel yourself moving slower."
    call player.cmd :playerDisturb 0 0
)
set "is_slow="

set /a py_flags.slow-=1

if "%py.flags.slow%"=="0" (
    set /a "py.flags.status&=~%config.player.status.py_slow%"
    call player.cmd :playerChangeSpeed -1

    call ui_io.cmd :printMessage "You feel yourself speed up."
    call player.cmd :playerDisturb 0 0
)
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
if %py.flags.rest% GTR 0 (
    set /a py.flags.rest-=1

    if "!py.flags.rest!"=="0" call player.cmd :playerRestOff
) else if %py.flags.rest% LSS 0 (
    set /a py.flags.rest+=1

    if "%py.misc.current_hp%"=="%py.misc.max_hp%" (
        if "%py.misc.current_mana%"=="%py.misc.mana%" (
            call player.cmd :playerRestOff
        )
    )
    if "!py.flags.rest!"=="0" call player.cmd :playerRestOff
)
exit /b

::------------------------------------------------------------------------------
:: Make random characters appear if the player is hallucinating
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerUpdateHallucination
if %py.flags.image% LEQ 0 exit /b

call player_run.cmd :playerEndRunning
set /a py.flags.image-=1

if "%py.flags.image%"=="0" call ui.cmd :drawDungeonPanel
exit /b

::------------------------------------------------------------------------------
:: Act on the player's paralysis
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerUpdateParalysis
if %py.flags.paralysis% LEQ 0 exit /b
set /a py.flags.paralysis-=1
call player.cmd :playerDisturb 1 0
exit /b

::------------------------------------------------------------------------------
:: Act on the player's protection from evil
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerUpdateEvilProtection
if %py.flags.protect_evil% LEQ 0 exit /b
set /a py.flags.protect_evil-=1

if "%py.flags.protect_evil%"=="0" (
    call ui_io.cmd :printMessage "You no longer feel safe from evil."
)
exit /b

::------------------------------------------------------------------------------
:: Act on the player's invulnerability
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerUpdateInvulnerability
if %py.flags.invulnerability% LEQ 0 exit /b

set /a "is_invuln=%py.flags.status%&%config.player.status.py_invuln%"
if "!is_invuln!"=="0" (
    set /a "py.flags.status|=%config.player.status.py_invuln%"
    call player.cmd :playerDisturb 0 0

    set /a py.misc.ac+=100
    set /a py.misc.display_ac+=100

    call ui.cmd :printCharacterCurrentArmorClass
    call ui_io.cmd :printMessage "Your skin turns to steel."
)
set "is_invuln="

set /a py.flags.invulnerability-=1

if "%py.flags.invulnerability%"=="0" (
    set /a "py.flags.status&=~%config.player.status.py_invuln%"
    call player.cmd :playerDisturb 0 0

    set /a py.misc.ac-=100
    set /a py.misc.display_ac-=100

    call ui.cmd :printCharacterCurrentArmorClass
    call ui_io.cmd :printMessage "Your skin returns to normal."
)
exit /b

::------------------------------------------------------------------------------
:: Act on the player's blessedness
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerUpdateBlessedness
if %py.flags.blessed% LEQ 0 exit /b

set /a "is_blessed=%py.flags.status%&%config.player.status.py_blessed%"
if "!is_blessed!"=="0" (
    set /a "py.flags.status|=%config.player.status.py_blessed%"
    call player.cmd :playerDisturb 0 0

    set /a py.misc.bth+=5
    set /a py.misc.bth_with_bows+=5
    set /a py.misc.ac+=2
    set /a py.misc.display_ac+=2

    call ui_io.cmd :printMessage "You feel righteous."
    call player.cmd :printCharacterCurrentArmorClass
)
set "is_blessed="

set /a py.flags.blessed-=1

if "%py.flags.blessed%"=="0" (
    set /a "py.flags.status&=~%config.player.status.py_blessed%"
    call player.cmd :playerDisturb 0 0

    set /a py.misc.bth-=5
    set /a py.misc.bth_with_bows-=5
    set /a py.misc.ac-=2
    set /a py.misc.display_ac-=2

    call ui_io :printMessage "The prayer has expired."
    call player.cmd :printCharacterCurrentArmorClass
)
exit /b

::------------------------------------------------------------------------------
:: Act on the player's heat resistance
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerUpdateHeatResistance
if %py.flags.heat_resistance% LEQ 0 exit /b
set /a py.flags.heat_resistance-=1
if "%py.flags.heat_resistance%"=="0" (
    call ui_io.cmd :printMessage "You no longer feel safe from flame."
)
exit /b

::------------------------------------------------------------------------------
:: Act on the player's cold resistance
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerUpdateColdResistance
if %py.flags.cold_resistance% LEQ 0 exit /b
set /a py.flags.cold_resistance-=1
if "%py.flags.cold_resistance%"=="0" (
    call ui_io.cmd :printMessage "You no longer feel safe from cold."
)
exit /b

::------------------------------------------------------------------------------
:: Act on the player's ability to see things
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerUpdateDetectInvisible
if %py.flags.detect_invisible% LEQ 0 exit /b

set /a "can_det_inv=%py.flags.status%&%config.player.status.py_det_inv%"
if "!can_det_inv!"=="0" (
    set /a "py.flags.status|=%config.player.status.py_det_inv%"
    set "py.flags.see_invisible=true"
    call monster.cmd :updateMonsters "false"
)
set "can_det_inv="

set /a py.flags.detect_invisible-=1

if "%py.flags.detect_invisible%"=="0" (
    set /a "py.flags.status&=~%config.player.status.py_det_inv%"
    call player.cmd :playerRecalculateBonuses
    call monster.cmd :updateMonsters "false"
)
exit /b

::------------------------------------------------------------------------------
:: Act on the player's infra vision
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerUpdateInfraVision
if %py.flags.timed_infra% LEQ 0 exit /b

set /a "has_tim_infra=%py.flags.status%&%config.player.status.py_tim_infra%"
if "!has_tim_infra!"=="0" (
    set /a "py.flags.status|=%config.player.status.py_tim_infra%"
    set /a py.flags.see_infra+=1
    call monster.cmd :updateMonsters "false"
)
set "has_tim_infra="

set /a py.flags.timed_infra-=1

if "%py.flags.timed_infra%"=="0" (
    set /a "py.flags.status&=~%config.player.status.py_tim_infra%"
    set /a py.flags.see_infra-=1
    call monster.cmd :updateMonsters "false"
)
exit /b

::------------------------------------------------------------------------------
:: Act on the Word-of-Recall
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerUpdateWordOfRecall
if %py.flags.word_of_recall% LEQ 0 exit /b

if "%py.flags.word_of_recall%"=="1" (
    set "dg.generate_new_level=true"

    set /a py.flags.paralysis+=1
    set "py.flags.word_of_recall=0"

    if %dg.current_level% GTR 0 (
        set "dg.current_level=0"
        call ui_io.cmd :printMessage "You feel yourself yanked upwards."
    ) else (
        if %py.misc.max_dungeon_depth% NEQ 0 (
            set "dg.current_level=%py.misc.max.dungeon_depth%"
            call ui_io.cmd :printMessage "You feel yourself yanked downwards."
        )
    )
) else (
    set /a py.flags.word_of_recall-=1
)
exit /b

::------------------------------------------------------------------------------
:: Act on the player's status flags
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerUpdateStatusFlags
set /a "stat_check=%py.flags.status%&%config.player.status.py_speed%"
if !stat_check! NEQ 0 (
    set /a "py.flags.status&=~%config.player.status.py_speed%"
    call ui.cmd :printCharacterSpeed
)

set /a "stat_check=%py.flags.status%&%config.player.status.py_paralysed%"
if !stat_check! NEQ 0 (
    call ui.cmd :printCharacterMovementState
    if %py.flags.paralysis% LSS 1 (
        set /a "py.flags.status&=~%config.player.status.py_paralysed%"
    ) else if %py.flags.paralysis% GTR 0 (
        set /a "py.flags.status|=~%config.player.status.py_paralysed%"
    )
)

set /a "stat_check=%py.flags.status%&%config.player.status.py_armor%"
if !stat_check! NEQ 0 (
    call ui.cmd :printCharacterCurrentArmorClass
    set /a "py.flags.status&=~%config.player.status.py_armor%"
)

set /a "stat_check=%py.flags.status%&%config.player.status.py_stats%"
if !stat_check! NEQ 0 (
    for /L %%A in (1,1,6) do (
        set /a "p_stat_check=(%config.player.status.py_str%<<n)&%py.flags.status%"
        if !p_stat_check! NEQ 0 (
            call ui.cmd :displayCharacterStats
        )
    )

    set /a "py.flags.status&=~%config.player.status.py_stats%"
)

set /a "stat_check=%py.flags.status%&%config.player.status.py_hp%"
if !stat_check! NEQ 0 (
    call ui.cmd :printCharacterMaxHitPoints
    call ui.cmd :printCharacterCurrentHitPoints
    set /a "py.flags.status&=~%config.player.status.py_hp%"
)

set /a "stat_check=%py.flags.status%&%config.player.status.py_mana%"
if !stat_check! NEQ 0 (
    call ui.cmd :printCharacterCurrentMana
    set /a "py.flags.status&=~%config.player.status.py_mana%"
)
set "stat_check="
set "p_stat_check="
exit /b

::------------------------------------------------------------------------------
:: See if any of the player's items are enchanted
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerDetectEnchantment
for /L %%A in (0,1,%player_inventory_size%) do (
    set "enchant_item=%%A"
    if "!enchant_item!"=="%py.pack.unique_items%" (
        set "enchant_item=22"
    )

    for %%B in ("!enchant_item!") do (
        set "item=!py.inventory[%%B]!"
        set "item.category_id=!py.inventory[%%B].category_id!"
    )

    if !enchant_item! LSS 22 (
        set "chance=50"
    ) else (
        set "chance=10"
    )

    if !item.category_id! NEQ %tv_nothing% (
        call :itemEnchanted item
        if "!errorlevel!"=="0" (
            call game.cmd :randomNumber !chance!
            if "!errorlevel!"=="1" (
                set "tmp_str=There's something about what you are "
                call ui_inventory.cmd :playerItemWearingDescription !enchant_item!
                call player.cmd :playerDisturb 0 0
                call ui_io.cmd :printMessage "!tmp_str!"
                call identification.cmd :itemAppendToInscription item %config.identification.id_magik%
            )
        )
    )
    set "enchant_item="
    set "item="
    set "item.category="
)
exit /b

::------------------------------------------------------------------------------
:: Determine how many times a command is to be repeated.
::
:: Arguments: %1 - The command to rerun
:: Returns:   The number of times to repeat the command
::------------------------------------------------------------------------------
:getCommandRepeatCount
call ui_io.cmd :putStringClearToEOL "Repeat count:" "0;0"
call helper.cmd :getinput "0123456789 " repeat_count
exit /b !repeat_count!

::------------------------------------------------------------------------------
:: Accept a command and input it
::
:: Arguments: %1 - The command to run
::            %2 - A counter for finding things
:: Returns:   None
::------------------------------------------------------------------------------
:executeInputCommands
set "last_input_command=%~1"
set "find_count=%~2"

set /a "do_repeat=%py.flags.status%&%config.player.status.py_repeat%"
if !do_repeat! NEQ 0 (
    call ui.cmd :printCharacterMovementState
)

set "game.use_last_direction=false"
set "game.player_free_turn=false"

if %py.running.tracker% NEQ 0 (
    call player_run.cmd :playerRunAndFind
    set /a find_count-=1

    if "!find_count!"=="0" (
        call player_run.cmd :playerEndRunning
    )

    call ui_io.cmd :putQIO
    goto :continueExecuteInputCommands
)

if %game.doing_inventory_command% NEQ 0 (
    call ui_inventory.cmd :inventoryExecuteCommand %game.doing_inventory_command%
    goto :continueExecuteInputCommands
)

call ui_io.cmd :panelMoveCursor "%py.pos.y%;%py.pos.x%"
set "message_ready_to_print=false"

if %game.command_count% GTR 0 (
    set "game.use_last_direction=true"
) else (
    call ui_io.cmd :getKeyInput last_input_command

    set "repeat_count=0"
    if "%last_input_command%"=="#" (
        call :getCommandRepeatCount %last_input_command%
        set "repeat_count=!errorlevel!"
    )

    call ui_io.cmd :panelMoveCursor "%py.pos.y%;%py.pos.x%"

    if !repeat_count! GTR 0 (
        call game_run.cmd :validCountCommand "!last_input_command!"
        if "!errorlevel!"=="1" (
            set "game.player_free_turn=true"
            set "last_input_command= "
            call ui_io.cmd :printMessage "Invalid command with a count."
        ) else (
            set "game.command_count=!repeat_count!"
            call ui.cmd :printCharacterMovementState
        )
    )
)
exit /b

::------------------------------------------------------------------------------
:: Allows the player to run in a direction without picking up unwanted items
::
:: Arguments: %1 - The key pressed by the user
:: Returns:   0 if moving without pickup, 1 otherwise
::------------------------------------------------------------------------------
:moveWithoutPickup
set "cmd=!%~1!"

if not "%cmd%" NEQ "-" return 0
set "count_save=%game.command_count%"
call game.cmd :getDirectionWithMemory " " "%direction%"
if "!errorlevel!"=="0" (
    set "game.command_count=%count_save%"
    set "cmd=%direction%"
) else (
    set "cmd= "
)

set "%~1=!cmd!"
exit /b 1

::------------------------------------------------------------------------------
:: Exit the game
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:commandQuit
call ui_io.cmd :flushInputBuffer
call ui_io.cmd :getInputConfirmation "Do you really want to quit? "
if "!errorlevel!"=="0" (
    set "game.character_is_dead=true"
    set "dg.generate_new_level=true"
    set "game.character_died_from=Quitting"
)
exit /b

::------------------------------------------------------------------------------
:: Determines how many previous messages to display
::
:: Arguments: None
:: Returns:   The number of previous messages to return
::------------------------------------------------------------------------------
:calculateMaxMessageCount
set "max_messages=%message_history_size%"

if %game.command_count% GTR 0 (
    if %game.command_count% LSS %message_history_size% (
        set "max_messages=%game.command_count%"
    )
    set "game.command_count=0"
) else if /I not "%game.last_command%"=="P" (
    set "max_messages=1"
)
exit /b !max_messages!

::------------------------------------------------------------------------------
:: Displays previous messages
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:commandPreviousMessage
call :calculateMaxMessageCount
set "max_messages=!errorlevel!"

if %max_messages% LEQ 1 (
    call ui_io.cmd :putString ">" "0;0"
    call ui_io.cmd :putStringClearToEOL "!messages[%last_message_id%]!" "0;1"
    exit /b
)

:: Seems like a lot of work just to call the Alernate Screen Buffer tbh
call ui_io.cmd :terminalSaveScreen

set "line_number=%max_messages%"
set "msg_id=%last_message_id%"

for /L %%A in (%max_messages%,-1,0) do (
    for /f "delims=" %%B in ("!msg_id!") do (
        call ui_io.cmd :putStringClearToEOL "!messages[%%B]!" "%%A;0"
    )
    if "!msg_id!"=="0" (
        set /a msg_id=%message_history_size%-1
    ) else (
        set /a msg_id-=1
    )
)

call ui_io.cmd :eraseLine "%line_number%;0"
call ui_io.cmd :waitForContinueKey "%line_number%"
call ui_io.cmd :terminalRestoreScreen
exit /b

::------------------------------------------------------------------------------
:: Toggles Wizard Mode
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:commandFlipWizardMode
if "%game.wizard_mode%"=="true" (
    set "game.wizard_mode=false"
    call ui_io.cmd :printMessage "Wizard mode off."
) else (
    call wizard.cmd :enterWizardMode && call ui_io.cmd :printMessage "Wizard mode on."
)

call ui.cmd :printCharacterWinner
exit /b

::------------------------------------------------------------------------------
:: Save and exit the game
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:commandSaveAndExit
if "%game.total_winner%"=="true" (
    call ui_io.cmd :printMessage "You are a Total Winner. Your character must be retired."
    call ui_io.cmd :printMessage "Use 'Q' when you are ready to quit."
) else (
    set "game.character_died_from=(saved)"
    call ui.io.cmd :printMessage "Saving game..."

    call game_save.cmd :saveGame && call game_death.cmd :endGame
    set "game.character_died_from=(alive and well)"
)
exit /b

::------------------------------------------------------------------------------
:: Looks at the map
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:commandLocateOnMap
if %py.flags.blind% GTR 0 (
    call ui_io.cmd :printMessage "You can't see your map."
    exit /b
)
call player.cmd :playerNoLight && (
    call ui_io.cmd :printMessage "You can't see your map."
    exit /b
)

set /a "player_coord.y=%py.pos.y%", "player_coord.x=%py.pos.x%"
set /a "old_panel.y=%dg.panel.row%", "old_panel.x=%dg.panel.col%"
set /a "panel.y=0", "panel.x=0", "dir_val=0"

:: Look at what they need to mimic a fraction of the power of while/break
:locateOuterWhileLoop
set /a "panel.y=!dg.panel.row!", "panel.x=!dg.panel.col!"
set "tmp_str="
if !panel.y! LSS !old_panel.y! (
    set "tmp_str=!tmp_str! North"
) else if !panel.y! GTR !old_panel.y! (
    set "tmp_str=!tmp_str! South"
)
if !panel.x! LSS !old_panel.x! (
    set "tmp_str=!tmp_str! West"
) else if !panel.x! GTR !old_panel.x! (
    set "tmp_str=!tmp_str! East"
)

set "out_val=Map sector [!panel.y!,!panel.x!], which is!tmp_str! your sector. Look in which direction?"

call game.cmd :getDirectionWithMemory "!out_val!" "!dir_val!" || goto :locateAfterWhileLoop

:: Note that there's no :locateAfterInnerWhileLoop because there's nothing after
:: the inner while loop so it just goes back to the start of the outer loop
:locateInnerWhileLoop
set /a "player_coord.x+=((!dir_val! - 1) %% 3 - 1) * %screen_width% / 2"
set /a "player_coord.y-=((!dir_val! - 1) /  3 - 1) * %screen_height% / 2"

if !player.coord.x! LSS 0 goto :tooFar
if !player.coord.y! LSS 0 goto :tooFar
if !player.coord.x! GEQ !dg.width! goto :tooFar
if !player.coord.4! GEQ !dg.width! goto :tooFar

call ui.cmd :coordOutsidePanel "!player_coord.y!;!player_coord.x!" "true" && (
    call ui.cmd :drawDungeonPanel
    goto :locateOuterWhileLoop
)
goto :locateInnerWhileLoop

:locateAfterWhileLoop
call ui.cmd :coordOutsidePanel "!player_coord.y!;!player_coord.x!" "false" && (
    call ui.cmd :drawDungeonPanel
)
exit /b

:tooFar
call ui_io.cmd :printMessage "You've gone past the end of your map."
set /a "player_coord.x-=((!dir_val! - 1) %% 3 - 1) * %screen_width% / 2"
set /a "player_coord.y+=((!dir_val! - 1) /  3 - 1) * %screen_height% / 2"
goto :locateOuterWhileLoop

::------------------------------------------------------------------------------
:: Toggles the Search feature
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:commandToggleSearch
set /a "is_searching=%py.flags.status%&%config.player.status.py_search%"
if "!is_searching!"=="0" (
    call player.cmd :playerSearchOn
) else (
    call player.cnd :playerSearchOff
)
set "is_searching="
exit /b

::------------------------------------------------------------------------------
:: Like executeInputCommands, but as a Wizard
::
:: Arguments: %1 - The key pressed by the Wizard user
:: Returns:   None
::------------------------------------------------------------------------------
:doWizardCommands
:: There are no switch statement in batch, but labels and variables (which would
:: normally be used to simulate them) are both case-insensitive, so we're stuck
:: with a massive if chain instead.
if "%~1"=="A" (
    call wizard.cmd :wizareCureAll
) else if "%~1"=="H" (
    call wizard.cmd :wizardCharacterAdjustment
    call ui_io.cmd :messageLineClear
) else if "%~1"=="K" (
    call spells.cmd :spellMassGenocide
) else if "%~1"=="g" (
    call wizard.cmd :wizardDropRandomItems
) else if "%~1"=="k" (
    call wizard.cmd :wizardJumpLevel
) else if "%~1"=="O" (
    call game_files.cmd :outputRandomLevelObjectsToFile
) else if "%~1"=="h" (
    call game_files.cmd :displayTextHelpFile "%config.files.help_wizard%"
) else if "%~1"=="I" (
    call spells.cmd :spellIdentifyItem
) else if "%~1"=="Y" (
    call wizard.cmd :wizardLightUpDungeon
) else if "%~1"=="y" (
    call spells.cmd :spellMapCurrentArea
) else if "%~1"=="z" (
    call player.cmd :playerTeleport 100
) else if "%~1"=="n" (
    call wizard.cmd :wizardGenerateObject
    call ui.cmd drawDungeonPanel
) else if "%~1"=="W" (
    call wizard.cmd :wizardGainExperience
) else if "%~1"=="N" (
    call wizard.cmd :wizardSummonMonster
) else if "%~1"=="Z" (
    call wizard.cmd :wizardCreateObjects
) else (
    call ui_io.cmd :putStringClearToEOL "Type '?' or 'h' for help." "0;0"
)
exit /b

::------------------------------------------------------------------------------
:: A switch statement for determining the action to take based on the command
::
:: Arguments: %1 - The key pressed by the user
:: Returns:   None
::------------------------------------------------------------------------------
:doCommand
:: See :doWizardCommands for an explanation about why this is like this.
:: Also, running is weird because modern Umoria translated all commands to
:: classic roguelike controls before performing things, but I already reused
:: those commands for other things so now I have to bodge it.
if "%~1"=="Q" (
    call :commandQuit
    set "game.player_free_turn=true"
)
if "%~1"=="P" (
    call :commandPreviousMessage
    set "game.player_free_turn=true"
)
if "%~1"=="Z" (
    call game_files.cmd :displayTextHelpFile "%config.files.license%"
    set "game.player_free_turn=true"
)
if "%~1"=="W" (
    call :commandFlipWizardMode
    set "game.player_free_turn=true"
)
if "%~1"=="X" (
    call :commandSaveAndExit
    set "game.player_free_turn=true"
)
if "%~1"=="=" (
    call ui_io.cmd :terminalSaveScreen
    call game.cmd :setGameOptions
    call ui_io.cmd :terminalRestoreScreen
    set "game.player_free_turn=true"
)
if "%~1"=="{" (
    call identification.cmd :itemInscribe
    set "game.player_free_turn=true"
)
if "%~1"=="1" call player_move.cmd :playerMove 1 "%do_pickup%"
if "%~1"=="2" call player_move.cmd :playerMove 2 "%do_pickup%"
if "%~1"=="3" call player_move.cmd :playerMove 3 "%do_pickup%"
if "%~1"=="4" call player_move.cmd :playerMove 4 "%do_pickup%"
if "%~1"=="5" (
    call player_move.cmd :playerMove 5 "%do_pickup%"
    if %game.command_count% GTR 1 (
        set /a game.command.count-=1
        call player.cmd :playerRestOn
    )
)
if "%~1"=="6" call player_move.cmd :playerMove 6 "%do_pickup%"
if "%~1"=="7" call player_move.cmd :playerMove 7 "%do_pickup%"
if "%~1"=="8" call player_move.cmd :playerMove 8 "%do_pickup%"
if "%~1"=="9" call player_move.cmd :playerMove 9 "%do_pickup%"
if "%~1"=="run_1" call player_run.cmd :playerFindInitialize 1
if "%~1"=="run_2" call player_run.cmd :playerFindInitialize 2
if "%~1"=="run_3" call player_run.cmd :playerFindInitialize 3
if "%~1"=="run_4" call player_run.cmd :playerFindInitialize 4
if "%~1"=="run_6" call player_run.cmd :playerFindInitialize 6
if "%~1"=="run_7" call player_run.cmd :playerFindInitialize 7
if "%~1"=="run_8" call player_run.cmd :playerFindInitialize 8
if "%~1"=="run_9" call player_run.cmd :playerFindInitialize 9
if "%~1"=="/" call identification.cmd :identifyGameObject
if "%~1"=="<" call :dungeonGoUpLevel
if "%~1"==">" call :dungeonGoDownLevel
if "%~1"=="?" (
    call game_files.cmd :displayTextHelpFile "%config.files.help%"
    set "game.player_free_turn=true"
)
if "%~1"=="B" call player_bash.cmd :playerBash
if "%~1"=="C" (
    call ui_io.cmd :terminalSaveScreen
    call ui.cmd :changeCharacterName
    call ui_io.cmd :terminalRestoreScreen
    set "game.player_free_turn=true"
)
if "%~1"=="D" call player_traps.cmd :playerDisarmTrap
if "%~1"=="E" call player_eat.cmd :playerEat
if "%~1"=="F" call :inventoryRefillLamp
if "%~1"=="G" call player.cmd :playerGainSpells
if "%~1"=="V" (
    call ui_io.cmd :terminalSaveScreen
    call scores.cmd :showScoresScreen
    call ui_io.cmd :terminalRestoreScreen
    set "game.player_free_turn=true"
)
if "%~1"=="L" (
    call :commandLocateOnMap
    set "game.player_free_turn=true"
)
if "%~1"=="R" call player.cmd :playerRestOn
if "%~1"=="S" (
    call :commandToggleSearch
    set "game.player_free_turn=true"
)
if "%~1"=="tunnel_1" call player_tunnel.cmd :playerTunnel 1
if "%~1"=="tunnel_2" call player_tunnel.cmd :playerTunnel 2
if "%~1"=="tunnel_3" call player_tunnel.cmd :playerTunnel 3
if "%~1"=="tunnel_4" call player_tunnel.cmd :playerTunnel 4
if "%~1"=="tunnel_6" call player_tunnel.cmd :playerTunnel 6
if "%~1"=="tunnel_7" call player_tunnel.cmd :playerTunnel 7
if "%~1"=="tunnel_8" call player_tunnel.cmd :playerTunnel 8
if "%~1"=="tunnel_9" call player_tunnel.cmd :playerTunnel 9
if "%~1"=="a" call staves.cmd :wandAim
if "%~1"=="M" (
    call dungeon.cmd :dungeonDisplayMap
    set "game.player_free_turn=true"
)
if "%~1"=="b" (
    call :examineBook
    set "game.player_free_turn=true"
)
if "%~1"=="c" call player.cmd :playerCloseDoor
if "%~1"=="d" call ui_inventory.cmd :inventoryExecuteCommand "d"
if "%~1"=="e" call ui_inventory.cmd :inventoryExecuteCommand "e"
if "%~1"=="f" call player_throw.cmd :playerThrowItem
if "%~1"=="i" call ui_inventory.cmd :inventoryExecuteCommand "i"
if "%~1"=="J" call :dungeonJamDoor
if "%~1"=="l" (
    call dungeon_los.cmd :look
    set "game.player_free_turn=true"
)
if "%~1"=="m" call mage_spells.cmd :getAndCastMagicSpell
if "%~1"=="o" call player.cmd :playerOpenClosedObject
if "%~1"=="p" call player_pray.cmd :pray
if "%~1"=="q" call player_quaff.cmd :quaff
if "%~1"=="r" call scrolls.cmd :scrollRead
if "%~1"=="s" call player.cmd :playerSearch "%py.pos.y%;%py.pos.x%" "%py.misc.chance_in_search%"
if "%~1"=="t" call ui_inventory.cmd :inventoryExecuteCommand "t"
if "%~1"=="u" call staves.cmd :staffUse
if "%~1"=="v" (
    call game_files.cmd :displayTextHelpFile "%config.files.versions_history%"
    set "game.player_free_turn=true"
)
if "%~1"=="w" call ui.inventory.cmd :inventoryExecuteCommand "w"
if "%~1"=="x" call ui.inventory.cmd :inventoryExecuteCommand "x"

set "game.player_free_turn=true"
if "%game.wizard_mode%"=="true" (
     call :doWizardCommands "%~1"
) else (
    call ui_io.cmd :putStringClearToEOL "Type '?' for help." "0;0"
)
set "game.last_command=%~1"
exit /b

::------------------------------------------------------------------------------
:: Check whether the command will accept a count
::
:: Arguments: %1 - The key pressed by the user
:: Returns:   0 if the command accepts a count, 1 otherwise
::------------------------------------------------------------------------------
:validCountCommand
set "is_valid_count_command=0"
for /f "delims=DPRSsok123456789+" %%A in ("%~1") do set "is_valid_count_command=1"
for /L %%A in (1,1,9) do if "%~1"=="run_%%A" set "is_valid_count_command=0"
exit /b !is_valid_count_command!

::------------------------------------------------------------------------------
:: Regenerates hit points
::
:: Arguments: %1 - The percent of HP to regain
:: Returns:   None
::------------------------------------------------------------------------------
:playerRegenerateHitPoints
set "old_chp=%py.misc.current_hp%"
set /a new_chp=%py.misc.max_hp% * 100 / %~1 + %config.player.player_regen_base%

set /a "py.misc.current_hp+=new_chp>>16"
if %py.misc.current_hp% LSS 0 (
    if %old_chp% GTR 0 (
        set "py.misc.current_hp=32767" %= SHORT_MAX but who's counting? =%
    )
)

set /a "new_chp_fraction=(new_chp&65535)+%py.misc.current_hp_fraction%"
if %new_chp_fraction% GEQ 65536 (
    set /a py.misc.current_hp_fraction=%new_chp_fraction%-65536
    set /a py.misc.current_hp+=1
) else (
    set "py.misc.current_hp_fraction=%new_chp_fraction%"
)

if %py.misc.current_hp% GEQ %py.misc.max_hp% (
    set "py.misc.current_hp=%py.misc.max_hp%"
    set "py.misc.current_hp_fraction=0"
)

if %old_chp% NEQ %py.misc.current_hp% call ui.cmd :printCharacterCurrentHitPoints
exit /b

::------------------------------------------------------------------------------
:: Regenerates mana
::
:: Arguments: %1 - The percent of mana to regain
:: Returns:   None
::------------------------------------------------------------------------------
:playerRegenerateMana
set "old_cmana=%py.misc.current_mana%"
set /a new_cmana=%py.misc.max_mana% * 100 / %~1 + %config.player.player_regen_mnbase%

set /a "py.misc.current_mana+=new_cmana>>16"
if %py.misc.current_mana% LSS 0 (
    if %old_cmana% GTR 0 (
        set "py.misc.current_mana=32767" %= SHORT_MAX but who's counting? =%
    )
)

set /a "new_mana_fraction=(new_cmana&65535)+%py.misc.current_mana_fraction%"
if %new_mana_fraction% GEQ 65536 (
    set /a py.misc.current_mana_fraction=%new_mana_fraction%-65536
    set /a py.misc.current_mana+=1
) else (
    set "py.misc.current_mana_fraction=%new_mana_fraction%"
)

if %py.misc.current_mana% GEQ %py.misc.max_mana% (
    set "py.misc.current_mana=%py.misc.max_mana%"
    set "py.misc.current_mana_fraction=0"
)

if %old_cmana% NEQ %py.misc.current_mana% call ui.cmd :printCharacterCurrentHitPoints
exit /b

::------------------------------------------------------------------------------
:: Determines if an item is secretly an enchanted weapon or armor
::
:: Arguments: %1 - The inventory index of the item to check
:: Returns:   0 if the item is enchanted, 1 otherwise
::------------------------------------------------------------------------------
:itemEnchanted
if %item.category_id% LSS %tv_min_enchant% exit /b 1
if %item.category_id% GTR %tv_max_enchant% exit /b 1
call inventory.cmd :inventoryItemIsCursed "%~1" && exit /b 1
call identification.cmd :spellItemIdentified "%~1" && exit /b 1

set /a "is_magic=!py.inventory[%~1].identification! & %config.identification.id_magik%"
if %is_magic% NEQ 0 exit /b 1

if !py.inventory[%~1].to_hit! GTR 0 exit /b 0
if !py.inventory[%~1].to_damage! GTR 0 exit /b 0
if !py.inventory[%~1].to_ac! GTR 0 exit /b 0

if !py.inventory[%~1].misc_use! GTR 0 (
    set /a "is_enchanted=!py.inventory[%~1].flags! & 1073746047"
    if !is_enchanted! NEQ 0 exit /b 1
)

set /a "is_enchanted=!py.inventory[%~1].flags! & 134211968"
if !is_enchanted! NEQ 0 exit /b 0
exit /b 1

::------------------------------------------------------------------------------
:: Read a book
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:examineBook
call inventory.cmd :inventoryFindRange %tv_magic_book% %tv_prayer_book% item_pos_start item_pos_end || (
    call ui_io.cmd :printMessage "You are not carrying any books"
    exit /b
)

if %py.flags.blind% GTR 0 (
    call ui_io.cmd :printMessage "You are blind and cannot read your book."
    exit /b
)

call player.cmd :playerNoLight || (
    call ui_io.cmd :printMessage "You have no light to read by."
    exit /b
)

if %py.flags.confused% GTR 0 (
    call ui_io.cmd :printMessage "You are too confused."
)

call ui_inventory.cmd item_id "Which book?" cnil cnil
if "!errorlevel!"=="0" (
    set "can_read=true"
    set "treasure_type=!py.inventory[%item_id%].category_id!"

    if "!classes[%py.misc.class_id%].class_to_use_mage_spells!"=="%config.spells.spell_type_mage%" (
        if "!treasure_type!" NEQ "%tv_magic_book%" set "can_read=false"
    ) else if "!classes[%py.misc.class_id%].class_to_use_mage_spells!"=="%config.spells.spell_type_priest%" (
        if "!treasure_type!" NEQ "%tv_prayer_book%" set "can_read=false"
    ) else {
        set "can_read=false"
    }

    if "!can_read!"=="false" (
        call ui_io.cmd :printMessage "You do not understand the language."
        exit /b
    )

    set "item_flags=!py.inventory[%item_id%].flags!"

    set "spell_id=0"
    call :readInSpells item_flags

    call ui_io.cmd :terminalSaveScreen
    call ui.cmd :displaySpellsList "spell_index" !spell_id! "true" "-1"
    call ui_io.cmd :waitForContinueKey 0
    call ui_io.cmd :terminalRestoreScreen
)
exit /b

::------------------------------------------------------------------------------
:: Creates an array of spells that can be read
::
:: Arguments: %1 - flags of the inventory item being listed
:: Returns:   None
::------------------------------------------------------------------------------
:readInSpells
call helpers.cmd :getAndClearFirstBit "%~1" item_pos_end
set /a class_id_offset=%py.misc.class_id%-1

if !magic_spells[%class_id_offset%][%item_pos_end%].level_required! LSS 99 (
    set "spell_index[!spell_id!]=!item_pos_end!"
    set /a spell_id+=1
)
if !item_flags! NEQ 0 goto :readInSpells
exit /b

::------------------------------------------------------------------------------
:: Go up one level
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonGoUpLevel
set "tile_id=!dg.floor[%py.pos.y%][%py.pos.x%].treasure_id!"

if %tile_id% NEQ 0 (
    if "!game.treasure.list[%tile_id%].category_id!"=="%tv_up_stair%" (
        set /a dg.current_level-=1

        call ui_io.cmd :printMessage "You enter a maze of up staircases."
        call ui_io.cmd :printMessage "You pass through a one-way door."

        set "dg.generate_level=true"
    ) else (
        call ui_io.cmd :printMessage "I see no up staircase there."
        set "game.player_free_turn=true"
    )
)
set "tile_id="
exit /b

::------------------------------------------------------------------------------
:: Go down one level
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonGoDownLevel
set "tile_id=!dg.floor[%py.pos.y%][%py.pos.x%].treasure_id!"

if %tile_id% NEQ 0 (
    if "!game.treasure.list[%tile_id%].category_id!"=="%tv_down_stair%" (
        set /a dg.current_level+=1

        call ui_io.cmd :printMessage "You enter a maze of down staircases."
        call ui_io.cmd :printMessage "You pass through a one-way door."

        set "dg.generate_level=true"
    ) else (
        call ui_io.cmd :printMessage "I see no down staircase there."
        set "game.player_free_turn=true"
    )
)
set "tile_id="
exit /b

::------------------------------------------------------------------------------
:: Jam a closed door
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonJamDoor
set "game.player_free_turn=true"
set "coord.x=%py.pos.x%"
set "coord.y=%py.pos.y%"

call game.cmd "cnil" direction || exit /b
call player.cmd :playerMovePosition "%direction%" "coord"

for %%A in (creature_id treasure_id) do (
    set "tile.%%A=!dg.floor[%coord.y%][%coord.x%].%%A!"
)
if "!tile.treasure_id!"=="0" (
    call ui_io.cmd :printMessage "That isn't a door."
    exit /b
)

for /f "delims=" %%A in ("!tile.treasure_id!") do (
    for %%B in (category_id misc_use) do (
        set "item.%%B=!game.treasure_list[%%A].%%B!"
    )
)
set "item_id=!item.category_id!"
set "item.category_id="
if %item_id% NEQ %tv_closed_door% (
    if %item_id% NEQ %tv_open_door% (
        call ui_io.cmd :printMessage "That isn't a door."
        exit /b
    )
)

if "%item_id%"=="%tv_open_door%" (
    call ui_io.cmd :printMessage "The door must be closed first."
    exit /b
)

:: At this point, the door is both closed and a door
if "!tile.creature_id!"=="0" (
    call inventory.cmd :inventoryFindRange "%tv_spike%" "%tv_never%" item_pos_start item_pos_end
    if "!errorlevel!"=="0" (
        set "game.player_free_turn=true"

        call ui_io.cmd :printMessageNoCommandInterrupt "You jam the door with a spike."

        if %item.misc_use% GTR 0 (
            set /a item.misc_use-=1
        )

        REM Successive spikes have a progressively smaller effect
        REM Series is: 0 20 30 37 43 48 52 56 60 64 67 70 ...
        set /a "item.misc_use-=1+190/(10-!item.misc_use!)"

        for /f "delims=" %%A in ("!item_pos_start!") do (
            if !py.inventory[%%A].items_count! GTR 1 (
                set /a py.inventory[%%A].items_count-=1
                set /a py.pack.weight-=!py.inventory[%%A].weight!
            ) else (
                call inventory.cmd :inventoryDestroyItem "%%~A"
            )
        )
    ) else (
        call ui_io.cmd :printMessage "But you have no spikes."
    )
) else (
    set "game.player_free_turn=false"
    call ui_io.cmd :printMessage "A monster is in your way."
)

exit /b

::------------------------------------------------------------------------------
:: Refill the player's lamp
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:inventoryRefillLamp
set "game.player_free_turn=true"

if !py.inventory[%PlayerEquipment.Light%].sub_category_id! NEQ 0 (
    call ui_io.cmd :printMessage "But you are not using a lamp."
    exit /b
)

call inventory.cmd :inventoryFindRange "%tv_flask%" "%tv_never%" item_pos_start item_pos_end || (
    call ui_io.cmd :printMessage "You have no oil."
    exit /b
)

set "game.player_free_turn=false"

set "item.misc_use=!py.inventory[%PlayerEquipment.Light%].misc_use"
set /a item.misc_use+=!py.inventory[%item_pos_start%].misc_use!

set /a "lamp_half_full=%config.treasure.object_lamp_max_capacity%/2"
if !item.misc_use! GTR %config.treasure.object_lamp_max_capacity% (
    set "item.misc_use=%config.treasture.object_lamp_max_capacity%"
    call ui_io.cmd :printMessage "Your lamp overflows, spilling oil on the ground."
    call ui_io.cmd :printMessage "Your lamp is full."
) else if !item.misc_use! GTR %lamp_half_full% (
    call ui_io.cmd :printMessage "Your lamp is more than half full."
) else if !item.misc_use! EQU %lamp_half_full% (
    call ui_io.cmd :printMessage "Your lamp is half full."
) else (
    call ui_io.cmd :printMessage "Your lamp is less than half full."
)

call identification.cmd :itemTypeRemainingCountDescription !item_pos_start!
call inventory.cmd :inventoryDestroyItem !item_pos_start!
exit /b

::------------------------------------------------------------------------------
:: Main procedure for the dungeon
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playDungeon
call :playerInitializePlayerLight
call :playerUpdateMaxDungeonDepth
call :resetDungeonFlags

set "find_count=0"
set "dg.panel.row=-1"
set "dg.panel.col=-1"

:: Light up the area around the character
call ui.cmd :dungeonResetView

set /a "is_searching=%py.flags.status%&%config.player.status.py_search%"
if %is_searching% NEQ 0 call player.cmd :playerSearchOff

:: Light critters but do not move them
call monster.cmd :updateMonsters "false"

:: Print the depth
call ui.cmd :printCharacterCurrentDepth

set "last_input_command=0"

:playLoop
set /a dg.game_turn+=1

:: Change the store contents every 1000 turns in the dungeon
set /a rotate_stock=%dg.game_turn%%%1000
if %dg.current_level% NEQ 0 (
    if "%rotate_stock%"=="0" (
        call store_inventory.cmd :storeMaintenance
    )
)
set "rotate_stock="

call game.cmd :randomNumber "%config.monsters.mon_chance_of_new%"
if "!errorlevel!"=="1" (
    call monster_manager.cmd :monsterPlaceNewWithinDistance 1 "%config.monsters.mon_max_sight%" "false"
)

call :playerUpdateLightStatus

:: Update counters and messages
call :playerUpdateHeroStatus
call :playerFoodConsumption
call :playerUpdateRegeneration "!errorlevel!"

call :playerUpdateBlindness
call :playerUpdateConfusion
call :playerUpdateFearState
call :playerUpdatePoisonedState
call :playerUpdateSpeed
call :playerUpdateRestingState

call :playerUpdateHallucination
call :playerUpdateParalysis
call :playerUpdateEvilProtection
call :playerUpdateInvulnerability
call :playerUpdateBlessedness
call :playerUpdateHeatResistance
call :playerUpdateColdResistance
call :playerUpdateDetectInvisible
call :playerUpdateInfraVision
call :playerUpdateWordOfRecall

:: Random teleportation
if "%py.flags.teleport%"=="true" (
    call game.cmd :randomNumber 100
    if "!errorlevel!"=="1" (
        call player.cmd :playerDisturb 0 0
        call player.cmd :playerTeleport 40
    )
)

:: See if we're too weak to hold a weapon or carry a pack
set /a "too_heavy=%py.flags.status%&%config.player.status.py_str_wgt%"
if %too_heavy% NEQ 0 (
    call player.cmd :playerStrength
)
set "too_heavy="

set /a "can_study=%py.flags.status%&%config.player.status.py_study%"
if %can_study% NEQ 0 (
    call ui.cmd :printCharacterStudyInstruction
)
set "can_study="

call :playerUpdateStatusFlags

:: Tiny chance for detecting enchantment
::  1st level characters check every 2160 turns
:: 40th level characters check every  416 turns
set /a "chance=10+750/(5+%py.misc.level%)"
set /a "f_turn=%dg.game_turn% & 15"
if "%f_turn%"=="0" (
    if "%py.flags.confused%"=="0" (
        call game.cmd :randomChance %chance%
        if "!errorlevel!"=="1" (
            call :playerDetectEnchantment
        )
    )
)
set "chance="
set "f_turn="

:: Purge the monster list if needed
set /a free_mons=%mon_total_allocations%-%next_free_monster_id%
if %free_mons% LSS 10 call monster_manager.cmd :compactMonsters

:: Are we in a good state to accept commands?
if %py.flags.paralysis% LSS 1 (
    if "%py.flags.rest%"=="1" (
        if "%game.character_is_dead%"=="false" (
            call :executeInputCommands "!last_input_command!" "!find_count!"
        )
    )
)
if %py.flags.paralysis% GEQ 1 (
    call ui_io.cmd :panelMoveCursor "%py.pos.y%;%py.pos.x%"
    call ui_io.cmd :putQIO
)
if %py.flags.rest% NEQ 0 (
    call ui_io.cmd :panelMoveCursor "%py.pos.y%;%py.pos.x%"
    call ui_io.cmd :putQIO
)
if "%game.character_is_dead%"=="true" (
    call ui_io.cmd :panelMoveCursor "%py.pos.y%;%py.pos.x%"
    call ui_io.cmd :putQIO
)

if "%game.teleport_player%"=="true" (
    call player.cmd :playerTeleport 100
)

if "%dg.generate_new_level%"=="false" (
    call monster.cmd :updateMonsters "true"
)

if "%dg.generate_level%"=="false" (
    if "%eof_flag%"=="0" (
        goto :playLoop
    )
)
exit /b