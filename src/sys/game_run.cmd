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
    set "cmd=~"
    if "%direction%"=="1" set "cmd=b"
    if "%direction%"=="2" set "cmd=j"
    if "%direction%"=="3" set "cmd=n"
    if "%direction%"=="4" set "cmd=h"
    if "%direction%"=="6" set "cmd=l"
    if "%direction%"=="7" set "cmd=y"
    if "%direction%"=="8" set "cmd=k"
    if "%direction%"=="9" set "cmd=u"
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