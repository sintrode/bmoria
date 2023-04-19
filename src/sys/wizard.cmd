call %*
exit /b

::------------------------------------------------------------------------------
:: Display a disclaimer and enter Wizard Mode
::
:: Arguments: None
:: Returns:   0 if the player agrees to enter Wizard Mode
::            1 if the player wants to play a scored game instead
::------------------------------------------------------------------------------
:enterWizardMode
set "answer=1"

if "%game.noscore%"=="0" (
    call ui_io.cmd :printMessage "Wizard mode is for debugging and experimenting."
    call ui_io.cmd :getInputConfirmation "The game will not be scored if you enter Wizard Mode. Are you sure?"
    set "answer=!errorlevel!"
)

set "become_wizard=0"
if not "%game.noscore%"=="0" set "become_wizard=1"
if "!answer!"=="0" set "become_wizard=1"
if "!become_wizard!"=="1" (
    set /a "game.noscore|=2"
    set "game.wizard_mode=true"
    exit /b 0
)
exit /b 1

::------------------------------------------------------------------------------
:: Remove all status impairments and enfeeblements
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:wizardCureAll
call spells.cmd :spellRemoveCurseFromAllWornItems
call player_magic.cmd :playerCureBlindness
call player_magic.cmd :playerCureConfusion
call player_magic.cmd :playerCurePoison
call player_magic.cmd :playerRemoveFear
call player_stats.cmd :playerStatRestore "%PlayerAttr.A_STR%"
call player_stats.cmd :playerStatRestore "%PlayerAttr.A_INT%"
call player_stats.cmd :playerStatRestore "%PlayerAttr.A_WIS%"
call player_stats.cmd :playerStatRestore "%PlayerAttr.A_CON%"
call player_stats.cmd :playerStatRestore "%PlayerAttr.A_DEX%"
call player_stats.cmd :playerStatRestore "%PlayerAttr.A_CHR%"
if %py.flags.slow% GTR 1 set "py.flags.slow=1"
if %py.flags.image% GTR 1 set "py.flags.image=1"
exit /b

::------------------------------------------------------------------------------
:: Drop random items
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:wizardDropRandomItems
if %game.command_count% GTR 0 (
    set "i=%game.command_count%"
    set "game.command_count=0"
) else (
    set "i=1"
)
call dungeon.cmd :dungeonPlaceRandomObjectNear "%py.pos.y%;%py.pos.x%" "%i%"
call ui.cmd :drawDungeonPanel
exit /b

::------------------------------------------------------------------------------
:: Teleport to a specific depth
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:wizardJumpLevel
if %game.command_count% GTR 0 (
    if %game.command_count% GTR 99 (
        set "i=0"
    ) else (
        set "i=%game.command_count%"
    )
    set "game.command_count=0"
) else (
    set "i=-1"
    call ui_io.cmd :putStringClearToEOL "Go to which level (0-99)? " "0;0"
    call ui_io.cmd :getStringInput "input" "0;27" "10"
    set /a "i=!input!"
)

if !i! GEQ 0 (
    set "dg.current_level=!i!"
    if !dg.current_level! GTR 99 set "dg.current_level=99"
    set "dg.generate_new_level=true"
) else (
    call ui_io.cmd :messageLineClear
)
exit /b

::------------------------------------------------------------------------------
:: Increase the character's experience points
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:wizardGainExperience
if %game.command_count% GTR 0 (
    set "py.misc.exp=%game.command_count%"
    set "game.command_count=0"
) else if "%py.misc.exp%"=="0" (
    set "py.misc.exp=1"
) else (
    set /a py.misc.exp*=2
)
call ui.cmd :displayCharacterExperience
exit /b

::------------------------------------------------------------------------------
:: Spawn in a new random monster
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:wizardSummonMonster
set "coord=%py.pos.y%;%py.pos.x%"
call monster_manager.cmd :monsterSummon "coord" "true"
call monster.cmd :updateMonsters "false"
exit /b

::------------------------------------------------------------------------------
:: Light the tiles in the dungeon
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:wizardLightUpDungeon
if "!dg.floor[%py.pos.y%][%py.pos.x%].permanent_light!"=="true" (
    set "flag=false"
) else (
    set "flag=true"
)

set /a height_dec=%dg.height%-1, width_dec=%dg.width%-1
for /L %%Y in (0,1,%height_dec%) do (
    for /L %%X in (0,1,%width_dec%) do (
        if !dg.floor[%%Y][%%X].feature_id! LEQ %MAX_CAVE_FLOOR% (
            set /a y_dec=%%Y-1, y_inc=%%Y+1, x_dec=%%X-1, x_inc=%%X+1
            for /L %%A in (!y_dec!,1,!y_inc!) do (
                for /L %%B in (!x_dec!,1,!x_inc!) do (
                    set "dg.floor[%%A][%%B].permanent_light=!flag!"
                    if "!flag!"=="false" (
                        set "dg.floor[%%A][%%B].field_mark=false"
                    )
                )
            )
        )
    )
)
call ui.cmd :drawDungeonPanel
exit /b

::------------------------------------------------------------------------------
:: Manually set the character's stats
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:wizardCharacterAdjustment
call ui_io.cmd :putStringClearToEOL "(3 - 118) Strength     = " "0;0"
call ui_io.cmd :getStringInput "input" "0;25" "3"
if "!errorlevel!"=="0" (
    set /a "number=!input!"
    if !number! GTR 2 if !number! LSS 199 (
        set "py.stats.max[%PlayerAttr.A_STR%]=!number!"
        call player_stats.cmd :playerStatRestore "%PlayerAttr.A_STR%"
    )
) else (
    exit /b
)

call ui_io.cmd :putStringClearToEOL "(3 - 118) Intelligence = " "0;0"
call ui_io.cmd :getStringInput "input" "0;25" "3"
if "!errorlevel!"=="0" (
    set /a "number=!input!"
    if !number! GTR 2 if !number! LSS 199 (
        set "py.stats.max[%PlayerAttr.A_INT%]=!number!"
        call player_stats.cmd :playerStatRestore "%PlayerAttr.A_INT%"
    )
) else (
    exit /b
)

call ui_io.cmd :putStringClearToEOL "(3 - 118) Wisdom       = " "0;0"
call ui_io.cmd :getStringInput "input" "0;25" "3"
if "!errorlevel!"=="0" (
    set /a "number=!input!"
    if !number! GTR 2 if !number! LSS 199 (
        set "py.stats.max[%PlayerAttr.A_WIS%]=!number!"
        call player_stats.cmd :playerStatRestore "%PlayerAttr.A_WIS%"
    )
) else (
    exit /b
)

call ui_io.cmd :putStringClearToEOL "(3 - 118) Dexterity    = " "0;0"
call ui_io.cmd :getStringInput "input" "0;25" "3"
if "!errorlevel!"=="0" (
    set /a "number=!input!"
    if !number! GTR 2 if !number! LSS 199 (
        set "py.stats.max[%PlayerAttr.A_DEX%]=!number!"
        call player_stats.cmd :playerStatRestore "%PlayerAttr.A_DEX%"
    )
) else (
    exit /b
)

call ui_io.cmd :putStringClearToEOL "(3 - 118) Constitution = " "0;0"
call ui_io.cmd :getStringInput "input" "0;25" "3"
if "!errorlevel!"=="0" (
    set /a "number=!input!"
    if !number! GTR 2 if !number! LSS 199 (
        set "py.stats.max[%PlayerAttr.A_CON%]=!number!"
        call player_stats.cmd :playerStatRestore "%PlayerAttr.A_CON%"
    )
) else (
    exit /b
)

call ui_io.cmd :putStringClearToEOL "(3 - 118) Charisma     = " "0;0"
call ui_io.cmd :getStringInput "input" "0;25" "3"
if "!errorlevel!"=="0" (
    set /a "number=!input!"
    if !number! GTR 2 if !number! LSS 199 (
        set "py.stats.max[%PlayerAttr.A_CHR%]=!number!"
        call player_stats.cmd :playerStatRestore "%PlayerAttr.A_CHR%"
    )
) else (
    exit /b
)

call ui_io.cmd :putStringClearToEOL "(1 - 32767) Hit Points = " "0;0"
call ui_io.cmd :getStringInput "input" "0;25" "5"
if "!errorlevel!"=="0" (
    set /a "number=!input!"
    if !number! GTR 0 if !number! LEQ 32767 (
        set "py.misc.max_hp=!number!"
        set "py.misc.current_hp=!number!"
        set "py.misc.current_hp_fraction=0"
        call ui.cmd :printCharacterMaxHitPoints
        call ui.cmd :printCharacterCurrentHitPoints
    )
) else (
    exit /b
)

call ui_io.cmd :putStringClearToEOL "(0 - 32767) Mana       = " "0;0"
call ui_io.cmd :getStringInput "input" "0;25" "5"
if "!errorlevel!"=="0" (
    set /a "number=!input!"
    if !number! GTR -1 if !number! LEQ 32767 (
        set "py.misc.mana=!number!"
        set "py.misc.current_mana=!number!"
        set "py.misc.current_mana_fraction=0"
        call ui.cmd :printCharacterCurrentMana
    )
) else (
    exit /b
)

:: TODO: Make sure the two extra equals signs are okay here
set "input=Current=%py.misc.au%  Gold = "
call helpers.cmd :getLength "!input!" "number"
call ui_io.cmd :putStringClearToEOL "!input!" "0;0"
call ui_io.cmd :getStringInput "!input!" "0;!number!" "7"
if "!errorlevel!"=="0" (
    set /a "new_gold=!input!"
    if !new_gold! GTR 0 (
        set "py.misc.au=!new_gold!"
        call ui.cmd :printCharacterGoldValue
    )
) else (
    exit /b
)

set "input=Current=%py.misc.chance_in_search%  (0-200) Searching = "
call helpers.cmd :getLength "!input!" "number"
call ui_io.cmd :putStringClearToEOL "!input!" "0;0"
call ui_io.cmd :getStringInput "!input!" "0;!number!" "3"
if "!errorlevel!"=="0" (
    set /a "number=!input!"
    if !number! GTR -1 if !number! LSS 201 (
        set "py.misc.chance_in_search=!number!"
    )
) else (
    exit /b
)

set "input=Current=%py.misc.stealth_factor%  (-1-18) Stealth = "
call helpers.cmd :getLength "!input!" "number"
call ui_io.cmd :putStringClearToEOL "!input!" "0;0"
call ui_io.cmd :getStringInput "!input!" "0;!number!" "3"
if "!errorlevel!"=="0" (
    set /a "number=!input!"
    if !number! GTR -2 if !number! LSS 19 (
        set "py.misc.stealth_factor=!number!"
    )
) else (
    exit /b
)

set "input=Current=%py.misc.disarm%  (0-200) Disarming = "
call helpers.cmd :getLength "!input!" "number"
call ui_io.cmd :putStringClearToEOL "!input!" "0;0"
call ui_io.cmd :getStringInput "!input!" "0;!number!" "3"
if "!errorlevel!"=="0" (
    set /a "number=!input!"
    if !number! GTR -1 if !number! LSS 201 (
        set "py.misc.disarm=!number!"
    )
) else (
    exit /b
)

set "input=Current=%py.misc.saving_throw%  (0-100) Save = "
call helpers.cmd :getLength "!input!" "number"
call ui_io.cmd :putStringClearToEOL "!input!" "0;0"
call ui_io.cmd :getStringInput "!input!" "0;!number!" "3"
if "!errorlevel!"=="0" (
    set /a "number=!input!"
    if !number! GTR -1 if !number! LSS 201 (
        set "py.misc.saving_throw=!number!"
    )
) else (
    exit /b
)

set "input=Current=%py.misc.bth%  (0-200) Base to hit = "
call helpers.cmd :getLength "!input!" "number"
call ui_io.cmd :putStringClearToEOL "!input!" "0;0"
call ui_io.cmd :getStringInput "!input!" "0;!number!" "3"
if "!errorlevel!"=="0" (
    set /a "number=!input!"
    if !number! GTR -1 if !number! LSS 201 (
        set "py.misc.bth=!number!"
    )
) else (
    exit /b
)

set "input=Current=%py.misc.bth_with_bows%  (0-100) Bows/Throwing = "
call helpers.cmd :getLength "!input!" "number"
call ui_io.cmd :putStringClearToEOL "!input!" "0;0"
call ui_io.cmd :getStringInput "!input!" "0;!number!" "3"
if "!errorlevel!"=="0" (
    set /a "number=!input!"
    if !number! GTR -1 if !number! LSS 201 (
        set "py.misc.bth_with_bows=!number!"
    )
) else (
    exit /b
)

set "input=Current=%py.misc.weight%  Weight = "
call helpers.cmd :getLength "!input!" "number"
call ui_io.cmd :putStringClearToEOL "!input!" "0;0"
call ui_io.cmd :getStringInput "!input!" "0;!number!" "3"
if "!errorlevel!"=="0" (
    set /a "number=!input!"
    if !number! GTR -1 (
        set "py.misc.weight=!number!"
    )
) else (
    exit /b
)

:wizardCharacterAdjustmentWhileLoop
call ui_io.cmd :getCommand "Alter speed? (+/-)" "input"
if "!errorlevel!"=="1" exit /b

if "!input!"=="+" (
    call player.cmd :playerChangeSpeed -1
) else if "!input!"=="-" (
    call player.cmd :playerChangeSpeed 1
) else (
    exit /b
)
call ui.cmd :printCharacterSpeed
goto :wizardCharacterAdjustmentWhileLoop

::------------------------------------------------------------------------------
:: Retrieve the specified element of the game_objects array
::
:: Arguments: %1 - The variable to store the index in
::            %2 - A label to display
::            %3 - The first valid item_id that can be selected
::            %4 - The last valid item_id that can be selected
:: Returns:   0 if a valid number is entered
::            1 if the player aborts or enters an invalid number
::------------------------------------------------------------------------------
:wizardRequestObjectId
set "msg=!%~2! ID (%~3-%~4): "
call ui_io.cmd :putStringClearToEOL "!msg!" "0;0"
call helpers.getLength "!msg!" "msg_length"

call ui_io.cmd :getStringInput "input" "0;!msg_length!" "3" || exit /b 1
for /f "delims=0123456789" %%A in ("!input!") do exit /b 1
if !input! LSS %~3 (
    call ui_io.cmd :putStringClearToEOL "Invalid ID. Must be %~3-%~4" "0;0"
    exit /b 1
)
if !input! GTR %~4 (
    call ui_io.cmd :putStringClearToEOL "Invalid ID. Must be %~3-%~4" "0;0"
    exit /b 1
)
set "%~1=!input!"
exit /b 0

::------------------------------------------------------------------------------
:: Basic subroutine for object generation
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:wizardGenerateObject
call :wizardRequestObjectId "id" "Dungeon/Store object" 0 366 || exit /b

set /a coord.y=0, coord.x=0
for /L %%A in (0,1,9) do (
    call rng.cmd :randomNumber 5
    set /a coord.y=!py.pos.y! - 3 + !errorlevel!
    call rng.cmd :randomNumber 7
    set /a coord.x=!py.pos.x! - 3 + !errorlevel!
    set "coord=!coord.y!;!coord.x!"

    call dungeon.cmd :coordInBounds "coord"
    for /f "tokens=1,2" %%X in ("!coord.x! !coord.y!") do (
        if !dg.floor[%%~Y][%%~X].feature_id! LEQ %MAX_CAVE_FLOOR% (
            if "!dg.floor[%%~Y][%%~X].treasure_id!"=="0" (
                call game_objects.cmd :popt
                set "free_treasure_id=!errorlevel!"
                set "dg.floor[%%Y][%%X].treasure_id=!free_treasure_id!"
                call inventory.cmd :inventoryItemCopyTo "!id!" "game.treasure.list[!free_treasure_id!]"
                call treasure.cmd :magicTreasureMagicalAbility "!free_treasure_id!" "%dg.current_level%"
                call identification.cmd :itemIdentify "game.treasure.list[!free_treasure_id!]" "free_treasure_id"

                exit /b
            )
        )
    )
)
exit /b

::------------------------------------------------------------------------------
:: Advanced subroutine for object generation
:: WARNING: This will probably break something. Try not to use this one.
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:wizardCreateObjects
:: Initialize new object
for %%A in (id special_name_id inscription flags category_id sprite misc_use 
            cost sub_category_id items_count weight to_hit to_damage ac to_ac
            "damage.dice" "damage.sides" depth_first_found identification) do (
    set "forge.%%~A=0"
)

set "forge.id=%config.dungeon.objects.OBJ_WIZARD%"
call identification.cmd :itemReplaceInscription "forge" "wizard item"
set /a "forge.identification=%config.identification.ID_KNOWN2%|%config.identification.ID_STORE_BOUGHT%"

call :wizardSetProperty "category_id"       "Tval   : "        "0;9"  3 "true"
call :wizardSetProperty "sprite"            "Tchar  : "        "0;9"  1 "false"
call :wizardSetProperty "sub_category_id"   "Subval : "        "0;9"  5 "true"
call :wizardSetProperty "weight"            "Weight : "        "0;9"  5 "true"
call :wizardSetProperty "items_count"       "Number : "        "0;9"  5 "true"
call :wizardSetProperty "damage.dice"       "Damage (dice): "  "0;15" 3 "true"
call :wizardSetProperty "damage.sides"      "Damage (sides): " "0;16" 3 "true"
call :wizardSetProperty "to_hit"            "+To hit: "        "0;9"  3 "true"
call :wizardSetProperty "to_damage"         "+To dam: "        "0;9"  3 "true"
call :wizardSetProperty "ac"                "AC     : "        "0;9"  3 "true"
call :wizardSetProperty "to_ac"             "+To AC : "        "0;9"  3 "true"
call :wizardSetProperty "misc_use"          "P1     : "        "0;9"  5 "true"
call :wizardSetProperty "flags"             "Flags (IN HEX): " "0;16" 8 "false"
call :wizardSetProperty "cost"              "Cost : "          "0;9"  8 "true"
call :wizardSetProperty "depth_first_found" "Level : "         "0;10" 3 "true"

set "forge.sprite=!forge.sprite:~0,1!"
set /a "forge.flags=0x!forge.flags!"

call ui_io.cmd :getInputConfirmation "Allocate?"
set "tile=dg.floor[%py.pos.y%][%py.pos.x%]"
if "!errorlevel!"=="0" (
    if not "!%tile%.treasure_id!"=="0" (
        call dungeon.cmd :dungeonDeleteObject "py.pos"
    )

    call game_objects.cmd :popt
    set "number=!errorlevel!"
    call inventory.cmd :inventoryCopyItem "game.treasure.list[!number!]" "forge"
    set "%tile%.treasure_id=!number!"
    call ui_io.cmd :printMessage "Allocated."
) else (
    call ui_io.cmd :printMessage "Aborted."
)
exit /b

::------------------------------------------------------------------------------
:: Sets a specific property of the forge object
::
:: Arguments: %1 - The name of the property to set
::            %2 - The putStringClearToEOL prompt
::            %3 - The getStringInput coordinates
::            %4 - The getStringInput length
::            %5 - Determines if the input should be converted to a number
:: Returns:   0 if the player enters text in getStringInput
::            1 if the player aborts the creation process
::------------------------------------------------------------------------------
:wizardSetProperty
call ui_io.cmd :putStringClearToEOL "%~2" "0;0"
call ui_io.cmd :getStringInput "input" "%~3" %~4 || exit /b 1
if "%~5"=="true" set /a "input=!input!"
set "forge.%~1=!input!"
exit /b 0