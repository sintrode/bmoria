@echo off
call %*
exit /b

::------------------------------------------------------------------------------
:: Gets the ID of the selected spell being cast
:: TODO: Rewrite to use XCOPY
::
:: Arguments: %1 - The list of spells to choose from
::            %2 - The number of spells available
::            %3 - A variable to store the ID of the spell that is chosen
::            %4 - A variable to store the spell's chance of success
::            %5 - The prompt for the spell selection screen
::            %6 - The first spell in the list of spells
:: Returns:   0 if a valid spell was selected
::            1 if the player did not press a valid key
::------------------------------------------------------------------------------
:spellGetId
set "spell_id=-1"

:: This was a one-liner in the C version...
set /a first_spell_id=!%~1[0]! + 97 - %~6
cmd /c exit /b %first_spell_id%
set "disp_first_spell_id=!=ExitCodeAscii!"
set /a num_dec=%~2-1, last_spell_id=!%~1[%num_dec%]! + 97 - %~6
cmd /c exit /b %last_spell_id%
set "disp_last_spell_id=!=ExitCodeAscii!"
set "str=(Spells %disp_first_spell_id%-%disp_last_spell_id%, *=List, Z=exit) %~5"

set "spell_found=false"
set "redraw=false"

if "!classes[%py.misc.class_id%].class_to_use_mage_spells!"=="%config.spells.spell_type_mage%" (
    set "offset=%config.spells.name_offset_spells%"
) else (
    set "offset=%config.spells.name_offset_prayers%"
)

:spellGetIdWhileLoop
if "!spell_found!"=="true" goto :spellGetIdAfterWhileLoop
call ui_io.cmd :getMenuItemId "str" "spellChoice" || goto :spellGetIdAfterWhileLoop

call helpers.cmd :checkLetter "%spellChoice%"
if "!errorlevel!"=="1" (
    set /a spell_id=%spellChoice% - 1 + %~6
    set "test_spell_id=%~2"
    for /L %%A in (0,1,%num_dec%) do (
        if "!spell_id!"=="!%~1[%%A]!" set "test_spell_id=%%A"
    )

    if "!test_spell_id!"=="%~2" (
        set "spell_id=-2"
    ) else (
        set /a name_index=!spell_id! + !offset!
        set /a class_dec=%py.misc.class_id%-1
        for /f "tokens=1,2" %%A in ("!class_dec! !spell_id!") do (
            set "spell=magic_spells[%%A][%%B]"
        )

        for /f "delims=" %%A in ("!name_index!") do (
            call mage_spells.cmd :spellChanceOfSuccess "!spell_id!"
            set "tmp_str=Cast !spell_names[%%A]! (!%spell%.mana_required! mana, !errorlevel!%% chance of failure)?"
        )
        call ui_io.cmd :getInputConfirmation "!tmp_str!"
        if "!errorlevel!"=="1" (
            set "spell_found=true"
        ) else (
            set "spell_id=-1"
        )
    )
) else if "!errorlevel!"=="2" (
    set /a spell_id=%spellChoice% - 1 + %~6
    set "test_spell_id=%~2"
    for /L %%A in (0,1,%num_dec%) do (
        if "!spell_id!"=="!%~1[%%A]!" set "test_spell_id=%%A"
    )

    if "!test_spell_id!"=="%~2" (
        set "spell_id=-2"
    ) else (
        set "spell_found=true"
    )
) else if "%spellChoice%"=="42" (
    if "!redraw!"=="false" (
        call ui_io.cmd :terminalSaveScreen
        set "redraw=true"
        call ui.cmd :displaySpellsList "%~1" "%~2" "false" "%~6"
    )
) else if not "!errorlevel!"=="0" (
    set "spell_id=-2"
) else (
    set "spell_id=-1"
    call ui_io.cmd :terminalBellSound
)

if "!spell_id!"=="-2" (
    set "tmp_str=You don't know that"
    if "!offset!"=="%config.spells.name_offset_spells%" (
        set "tmp_str=!tmpstr! spell."
    ) else (
        set "tmp_str=!tmpstr! prayer."
    )
    call ui_io.cmd :printMessage "!tmp_str!"
)

if "!redraw!"=="true" call ui_io.cmd :terminalRestoreScreen
call ui_io.cmd :messageLineClear

if "!spell_found!"=="true" (
    call mage_spells.cmd :spellChanceOfSuccess "!spell_id!"
    set "%~4=!errorlevel!"
)
if "!spell_found!"=="false" exit /b 1
exit /b 0

::------------------------------------------------------------------------------
:: A wrapper for :spellGetId
::
:: Arguments: %1 - The prompt for getting user input
::            %2 - The inventory ID of the spell book or prayer book
::            %3 - A variable that stores the value of the spell_id
::            %4 - A variable that stores the odds of the spell failing
:: Returns:   -1 if there are no spells in the book
::             0 if no spell was chosen
::             1 if a spell was successfully chosen
::------------------------------------------------------------------------------
:castSpellGetId
set "flags=!py.inventory[%~2].flags!"
call helpers.cmd :getAndClearFirstBit "flags"
set "first_spell=!errorlevel!"

set /a "flags=!py.inventory[%~2].flags! & !py.flags.spells_learnt!"
set /a class_dec=%py.misc.class_id%-1
set "spells=magic_spells[%class_dec%]"

set "spell_count=0"

:castSpellGetIdWhileLoop
if "!flags!"=="0" goto :castSpellGetIdAfterWhileLoop
call helpers.cmd :getAndClearFirstBit "flags"
set "pos=!errorlevel!"
if !%spells%[%pos%].level_required! LEQ %py.misc.level% (
    set "spell_list[!spell_count!]=!pos!"
    set /a spell_count+=1
)
goto :castSpellGetIdWhileLoop


:castSpellGetIdAfterWhileLoop
if "!spell_count!"=="0" exit /b -1

set "result=0"
call :spellGetId "spell_list" "!spell_count!" "%~3" "%~4" "%~1" "!first_spell!"
if "!errorlevel!"=="0" set "result=1"

if not "!result!"=="0" (
    if !magic_spells[%class_dec%][%spell_id%].mana_required! GTR %py.misc.current_mana% (
        if "!classes[%py.misc.class_id%].class_to_use_mage_spells!"=="%config.spells.spell_type_mage%" (
            call ui_io.cmd :getInputConfirmation "You summon your limited strength to cast this one. Confirm?"
            set "result=!errorlevel!"
        ) else (
            call ui_io.cmd :getInputConfirmation "The gods may think you presumptuous for this. Confirm?"
        )
    )
)
exit /b !result!

::------------------------------------------------------------------------------
:: Detects any treasure on the current panel
::
:: Arguments: None
:: Returns:   0 if any treasure is found
::            1 if there is nothing left to find
::------------------------------------------------------------------------------
:spellDetectTreasureWithinVicinity
set "detected=1"

for %%Y in (%dg.panel.top%,1,%dg.panel.bottom%) do (
    for %%X in (%dg.panel.left%,1,%dg.panel.right%) do (
        for /f "delims=" %%A in ("!dg.floor[%%Y][%%X].treasure_id!") do (
            if not "%%~A"=="0" (
                set "coord=%%Y;%%X"
                call dungeon.cmd :caveTileVisible "coord"
                if "!errorlevel!"=="1" (
                    if "!game.treasure.list[%%~A].category_id!"=="%TV_GOLD%" (
                        set "dg.floor[%%Y][%%X].field_mark=true"
                        call dungeon.cmd :dungeonLiteSpot "coord"
                        set "detected=0"
                    )
                )
            )
        )
    )
)
exit /b %detected%

::------------------------------------------------------------------------------
:: Detect all objects on the current panel
::
:: Arguments: None
:: Returns:   0 if any objects are found
::            1 if there is nothing left to find
::------------------------------------------------------------------------------
:spellDetectObjectsWithinVicinity
set "detected=1"

for %%Y in (%dg.panel.top%,1,%dg.panel.bottom%) do (
    for %%X in (%dg.panel.left%,1,%dg.panel.right%) do (
        for /f "delims=" %%A in ("!dg.floor[%%Y][%%X].treasure_id!") do (
            if not "%%~A"=="0" (
                set "coord=%%Y;%%X"
                call dungeon.cmd :caveTileVisible "coord"
                if "!errorlevel!"=="1" (
                    if !game.treasure.list[%%~A].category_id! LSS %TV_MAX_OBJECT% (
                        set "dg.floor[%%Y][%%X].field_mark=true"
                        call dungeon.cmd :dungeonLiteSpot "coord"
                        set "detected=0"
                    )
                )
            )
        )
    )
)
exit /b %detected%

::------------------------------------------------------------------------------
:: Locates and displays traps on the current panel
::
:: Arguments: None
:: Returns:   0 if any traps are detected
::            1 if no traps are present
::------------------------------------------------------------------------------
:spellDetectTrapsWithinVicinity
set "detected=1"

for %%Y in (%dg.panel.top%,1,%dg.panel.bottom%) do (
    for %%X in (%dg.panel.left%,1,%dg.panel.right%) do (
        for /f "delims=" %%A in ("!dg.floor[%%Y][%%X].treasure_id!") do (
            if not "%%~A"=="0" (
                if "!game.treasure.list[%%~A].category_id!"=="%TV_INVIS_TRAP%" (
                    set "dg.floor[%%Y][%%X].field_mark=true"
                    set "coord=%%Y;%%X"
                    call dungeon.cmd :trapChangeVisibility "coord"
                    set "detected=0"
                ) else if "!game.treasure.list[%%~A].category_id!"=="%TV_CHEST%" (
                    set "item=game.treasure.list[%%~A]"
                    call identification.cmd :spellItemIdentifyAndRemoveRandomInscription "item"
                )
            )
        )
    )
)
exit /b %detected%

::------------------------------------------------------------------------------
:: Locate and display all secret doors on the current panel
::
:: Arguments: None
:: Returns:   0 if secret doors are found
::            1 if there are no more doors to find
::------------------------------------------------------------------------------
:spellDetectSecretDoorssWithinVicinity
set "detected=1"

for %%Y in (%dg.panel.top%,1,%dg.panel.bottom%) do (
    for %%X in (%dg.panel.left%,1,%dg.panel.right%) do (
        set "coord=%%Y;%%X"
        for /f "delims=" %%A in ("!dg.floor[%%Y][%%X].treasure_id!") do (
            if not "%%~A"=="0" (
                if "!game.treasure.list[%%~A].category_id!"=="%TV_SECRET_DOOR%" (
                    set "dg.floor[%%Y][%%X].field_mark=true"
                    call dungeon.cmd :trapChangeVisibility "coord"
                    set "detected=0"
                ) else if "!dg.floor[%%Y][%%X].field_mark!"=="true" (
                    set "is_stairs=0"
                    if "!game.treasure.list[%%~A].category_id!"=="%TV_UP_STAIR%" set "is_stairs=1"
                    if "!game.treasure.list[%%~A].category_id!"=="%TV_DOWN_STAIR%" set "is_stairs=1"

                    if "!is_stairs!"=="1" (
                        set "dg.floor[%%Y][%%X].field_mark=true"
                        call dungeon.cmd :dungeonLiteSpot "coord"
                        set "detected=0"
                    )
                    set "is_stairs="
                )
            )
        )
    )
)
exit /b %detected%

::------------------------------------------------------------------------------
:: Locates and displays all invisible creatures on the current panel
::
:: Arguments: None
:: Returns:   0 if any monsters are detected
::            1 if there are no more monsters to find
::------------------------------------------------------------------------------
:spellDetectInvisibleCreaturesWithinVicinity
set "detected=1"
set /a mon_dec=%next_free_monster_id%-1
for /L %%A in (%mon_dec%,-1,%config.monsters.mon_min_index_id%) do (
    set "mon_coord=!monsters[%%A].pos.y!;!monsters[%%A].pos.x!"
    call ui.cmd :coordInsidePanel "!mon_coord!"
    if "!errorlevel!"=="0" (
        for /f "delims=" %%C in ("!monsters[%%A].creature_id!") do (
            set /a "is_invisible=!creatures_list[%%~C].movement! & %config.monsters.move.cm_invisible%"
            if not "!is_invisible!"=="0" (
                set "monsters[%%A].lit=true"
                call ui_io.cmd :panelPutTile "!creatures_list[%%~C].sprite!" "!mon_coord!"
                set "detected=0"
            )
        )
    )
)
set "mon_coord="

if "!detected!"=="0" (
    call ui_io.cmd :printMessage "You sense the presence of invisible creatures."
    call ui_io.cmd :printMessage "CNIL"
    call monster.cmd :updateMonsters "false"
)
exit /b %detected%

::------------------------------------------------------------------------------
:: Lights the immediate area if the player is in a corridor, or lights the
:: entire room plus the immediate area if the player is in a room
::
:: Arguments: %1 - The player's coordinates
:: Returns:   0 always
::------------------------------------------------------------------------------
:spellLightArea
if %py.flags.blind% LSS 1 (
    call ui_io.cmd :printMessage "You are surrounded by a white light."
)

set "coord=%~1"
call helpers.cmd :expandCoordName "coord"
if "!dg.floor[%coord.y%][%coord.x%].perma_lit_room!"=="true" (
    if %dg.current_level% GTR 0 (
        call dungeon.cmd :dungeonLightRoom "coord"
    )
)

for /L %%Y in (%coord.y_dec%,1,%coord.y_inc%) do (
    for /L %%X in (%coord.x_dec%,1,%coord.x_inc%) do (
        set "dg.floor[%%Y][%%X].permanent_light=true"
        set "spot=%%Y;%%X"
        call dungeon.cmd :dungeonLiteSpot "spot"
    )
)
exit /b 0

::------------------------------------------------------------------------------
:: Darkens an area
::
:: Arguments: %1 - The player's coordinates
:: Returns:   0 if the area is successfully darkened
::            1 if the area remains lit
::------------------------------------------------------------------------------
:spellDarkenArea
set "darkened=1"
set "coord=%~1"
call helpers.cmd :expandCoordName "coord"

if "!dg.floor[%coord.y%][%coord.x%].perma_lit_room!"=="true" (
    if %dg.current_level% GTR 0 (
        set /a half_height=%screen_height%/2, half_width=%screen_width%/2
        set /a "start_row=(%coord.y% / !half_height!) * !half_height! + 1"
        set /a "start_col=(%coord.x% / !half_width!)  * !half_width!  + 1"
        set /a end_row=!start_row! + !half_height! - 1
        set /a end_col=!start_col! + !half_width!  - 1

        for /L %%Y in (!start_row!,1,!end_row!) do (
            for /L %%X in (!start_col!,1,!end_col!) do (
                set "spot=%%Y;%%X"
                if "!dg.floor[%%Y][%%X].perma_lit_room!"=="true" (
                    if !dg.floor[%%Y][%%X].feature_id! LEQ %MAX_CAVE_FLOOR% (
                        set "dg.floor[%%Y][%%X].permanent_light=false"
                        set "dg.floor[%%Y][%%X].feature_id=%TILE_DARK_FLOOR%"
                        call dungeon.cmd :dungeonLiteSpot "spot"

                        call dungeon.cmd :caveTileVisible "spot"
                        if "!errorlevel!"=="1" set "darkened=0"
                    )
                )
            )
        )
    )
) else (
    for /L %%Y in (%coord.y_dec%,1,%coord.y_inc%) do (
        for /L %%X in (%coord.x_dec%,1,%coord.x_inc%) do (
            if "!dg.floor[%%Y][%%X].feature_id!"=="%TILE_CORR_FLOOR%" (
                if "!dg.floor[%%Y][%%X].permanent_light!"=="true" (
                    set "dg.floor[%%Y][%%X].permanent_light=false"
                    set "darkened=0"
                )
            )
        )
    )
)

if "!darkened!"=="0" (
    if %py.flags.blind% LSS 1 (
        call ui_io.cmd :printMessage "Darkness surrounds you."
    )
)
exit /b %darkened%

::------------------------------------------------------------------------------
:: Lights the area around a specified tile
::
:: Arguments: %1 - The coordinates of the center of the lit area
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonLightAreaAroundFloorTile
set "coord=%~1"
call helpers.cmd :expandCoordName "coord"

for /L %%Y in (%coord.y_dec%,1,%coord.y_inc%) do (
    for /L %%X in (%coord.x_dec%,1,%coord.x_inc%) do (
        if !dg.floor[%%Y][%%X].feature_id! GEQ %MIN_CAVE_WALL% (
            set "dg.floor[%%Y][%%X]=true"
        ) else (
            for /f "delims=" %%A in ("!dg.floor[%%Y][%%X].treasure_id!") do (
                if not "%%~A"=="0" (
                    if !game.treasure.list[%%~A].category_id! GEQ %TV_MIN_VISIBLE% (
                        if !game.treasure.list[%%~A].category_id! LEQ %TV_MAX_VISIBLE% (
                            set "dg.floor[%%Y][%%X].field_mark=true"
                        )
                    )
                )
            )
        )
    )
)
exit /b

::------------------------------------------------------------------------------
:: Maps the current area and a bit extra
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:spellMapCurrentArea
call rng.cmd :randomNumber 10
set /a row_min=%dp.panel.top%-!errorlevel!
call rng.cmd :randomNumber 10
set /a row_max=%dp.panel.bottom%+!errorlevel!
call rng.cmd :randomNumber 20
set /a col_min=%dp.panel.left%-!errorlevel!
call rng.cmd :randomNumber 20
set /a col_max=%dp.panel.right%+!errorlevel!

for /L %%Y in (%row_min%,1,%row_max%) do (
    for /L %%X in (%col_min%,1,%col_max%) do (
        set "coord=%%Y;%%X"
        call dungeon.cmd :coordInBounds "coord"
        if "!errorlevel!"=="0" (
            if !dg.floor[%%Y][%%X].feature_id! LEQ %MAX_CAVE_FLOOR% (
                call dungeon.cmd :dungeonLightAreaAroundFloorTile "!coord!"
            )
        )
    )
)
call ui.cmd :drawDungeonPanel
exit /b

::------------------------------------------------------------------------------
:: Identifies an object
::
:: Arguments: None
:: Returns:   0 if an item is selected
::            1 if the player backs out before making a selection
::------------------------------------------------------------------------------
:spellIdentifyItem
call ui_inventory.cmd :inventoryGetInputForItemId "item_id" "Item you wish identified?" 0 "%PLAYER_INVENTORY_SIZE%" "CNIL" "CNIL"
if "!errorlevel!"=="1" exit /b 1

call identification.cmd :itemIdentify "py.inventory[%item_id%]" "item_id"

set "item=py.inventory[%item_id%]"
call identification.cmd :spellItemIdentifyAndRemoveRandomInscription "item"
call identification.cmd :itemDescription "description" "item" "true"

if %item_id% GEQ %PlayerEquipment.Wield% (
    call player.cmd :playerRecalculateBonuses
    call ui_inventory.cmd :playerItemWearingDescription "%item_id%" "item_char"
    call ui_io.cmd :printMessage "!item_char!: !description!"
) else (
    set /a disp_item_ascii=%item_id%+97
    cmd /c exit /b !disp_item_ascii!
    call ui_io.cmd :printMessage "!=ExitCodeAscii! !description!"
)
exit /b 0

::------------------------------------------------------------------------------
:: Makes all of the nearby monsters angry
::
:: Arguments: %1 - The range of the spell
:: Returns:   0 if there are nearby monsters to annoy
::            1 if there are no monsters in the area
::------------------------------------------------------------------------------
:spellAggravateMonsters
set "aggravated=1"
set /a mon_dec=%next_free_monster_id%-1
for /L %%A in (%mon_dec%,-1,%config.monsters.mon_min_index_id%) do (
    set "monsters[%%A].sleep_count=0"
    if !monsters[%%A].distance_from_player! LEQ %~1 (
        if !monsters[%%A].speed! LSS 2 (
            set /a monsters[%%A].speed+=1
            set "aggravated=0"
        )
    )
)

if "%aggravated%"=="0" (
    call ui_io.cmd :printMessage "You hear a sudden stirring in the distance."
)
exit /b %aggravated%

::------------------------------------------------------------------------------
:: Puts traps on up to all eight available spaces around the player
::
:: Arguments: None
:: Returns:   0 always
::------------------------------------------------------------------------------
:spellSurroundPlayerWithTraps
call helpers.cmd :expandCoordName "py.pos"
for /L %%Y in (%py.pos.y_dec%,1,%py.pos.y_inc%) do (
    for /L %%X in (%py.pos.x_dec%,1,%py.pos.x_inc%) do (
        REM Make sure there is no trap under a player so that they can rest
        if not "%%Y"=="%py.pos.y%" if not "%%X"=="%py.pos.x%" (
            if !dg.floor[%%Y][%%X].feature_id! LEQ %MAX_CAVE_FLOOR% (
                if not "!dg.floor[%%Y][%%X].treasure_id!"=="0" (
                    set "coord=%%Y;%%X"
                    call dungeon.cmd :dungeonDeleteObject "coord"
                )

                call rng.cmd :randomNumber %config.dungeon.objects.max_traps%
                set /a rnd_trap=!errorlevel!-1
                call dungeon.cmd :dungeonSetTrap "coord" !rnd_trap!

                REM The player can not gain experience from disarming these traps
                for /f "delims=" %%A in ("!dg.floor[%%Y][%%X].treasure_id!") do (
                    set "game.treasure_list[%%~A].misc_use=0"
                )

                REM Light the area to see open pits
                call dungeon.cmd :dungeonLiteSpot "coord"
            )
        )
    )
)
exit /b 0

::------------------------------------------------------------------------------
:: Puts doors on all eight spaces surrounding the player
::
:: Arguments: None
:: Returns:   0 if any doors are placed
::            1 if no doors are able to be placed
::------------------------------------------------------------------------------
:spellSurroundPlayerWithDoors
set "created=1"
call helpers.cmd :expandCoordName "py.pos"
for /L %%Y in (%py.pos.y_dec%,1,%py.pos.y_inc%) do (
    for /L %%X in (%py.pos.x_dec%,1,%py.pos.x_inc%) do (
        REM Make sure there is no door under a player
        if not "%%Y"=="%py.pos.y%" if not "%%X"=="%py.pos.x%" (
            if !dg.floor[%%Y][%%X].feature_id! LEQ %MAX_CAVE_FLOOR% (
                if not "!dg.floor[%%Y][%%X].treasure_id!"=="0" (
                    set "coord=%%Y;%%X"
                    call dungeon.cmd :dungeonDeleteObject "coord"
                )

                call game_objects.cmd :popt
                set "free_id=!errorlevel!"
                set "dg.floor[%%Y][%%X].feature_id=%TILE_BLOCKED_FLOOR%"
                set "dg.floor[%%Y][%%X].treasure_id=!free_id!"

                call inventory.cmd :inventoryItemCopyTo "%config.dungeon.objects.obj_closed_door%" "game.treasure.list[!free_id!]"
                set "coord=%%Y;%%X"
                call dungeon.cmd :dungeonLiteSpot "coord"
                set "created=true"
            )
        )
    )
)
exit /b %created%

::------------------------------------------------------------------------------
:: Destroys any adjacent doors or traps
::
:: Arguments: None
:: Returns:   0 if any door or trap was destroyed
::            1 if there was nothing to get rid of
::------------------------------------------------------------------------------
:spellDestroyAdjacentDoorsTraps
set "destroyed=1"

call helpers.cmd :expandCoordName "py.pos"
for /L %%Y in (%py.pos.y_dec%,1,%py.pos.y_inc%) do (
    for /L %%X in (%py.pos.x_dec%,1,%py.pos.x_inc%) do (
        if not "!dg.floor[%%Y][%%X].treasure_id!"=="0" (
            call :spellDestroyAdjacentDoorsTrapsSub "!dg.floor[%%Y][%%X].treasure_id!" "%%Y;%%X"
        )
    )
)
exit /b %destroyed%

:spellDestroyAdjacentDoorsTrapsSub
set "item=game.treasure.list[%~1]"
set "auto_destroy=0"
if !%item%!.category_id! GEQ %TV_INVIS_TRAP% (
    if !%item%.category_id! LEQ %TV_CLOSED_DOOR% (
        if not "!%item%.category_id!"=="%TV_RUBBLE%" (
            set "auto_destroy=1"
        )
    )
)
if "!%item%.category_id!"=="%TV_SECRET_DOOR%" set "auto_destroy=1"
if "!auto_destroy!"=="1" (
    set "coord=%~2"
    call dungeon.cmd :dungeonDeleteObject "coord"
    if "!errorlevel!"=="0" set "destroyed=0"
) else (
    if "!%item%.category_id!"=="%TV_CHEST%" (
        if not "!%item%.flags!"=="0" (
            set /a "%item%.flags&=~(%config.treasure.chests.ch_trapped% | %config.treasure.chests.ch_locked%)"
            set "%item%.special_name_id=%SpecialNameIds.sn_unlocked%"
            set "destroyed=0"

            call ui_io.cmd :printMessage "You have disarmed the chest."
            call identification.cmd :spellItemIdentifyAndRemoveRandomInscription "%item%"
        )
    )
)
exit /b

::------------------------------------------------------------------------------
:: Displays all creatures on the current panel
::
:: Arguments: None
:: Returns:   0 if any monsters are detected
::            1 if there are no monsters to be found or if they are invisible
::------------------------------------------------------------------------------
:spellDetectMonsters
set "detected=1"

set /a mon_dec=%next_free_monster_id%-1
for /L %%A in (%mon_dec%,-1,%config.monsters.mon_min_index_id%) do (
    for /f "delims=" %%M in ("monsters[%%A]") do (
        call ui.cmd :coordInsidePanel "!%%~M.pos.y!;!%%~M.pos.x!"
        if "!errorlevel!"=="0" (
            for /f "delims=" %%C in ("!%%~M.creature_id!") do (
                set /a "is_invisible=!creatures_list[%%~C].movement! & %config.monsters.move.cm_invisible%"
                if "!is_invisible!"=="0" (
                    set "%%~M.lit=true"
                    set "detected=0"

                    call ui_io.cmd :panelPutTile "!creatures_list[%%~C].sprite!" "!%%~M.pos.y!;!%%~M.pos.x!"
                )
            )
        )
    )
)
exit /b %detected%

::------------------------------------------------------------------------------
:: Update a monster when the light line spell touches it
::
:: Arguments: %1 - The monster_id of the monster that is seen
:: Returns:   None
::------------------------------------------------------------------------------
:spellLightLineTouchesMonster
set "monster=monsters[%~1]"
set "c_id=!%monster%.creature_id!"
set "creature=creatures_list[%c_id%]"

call monster.cmd :monsterUpdateVisibility "%~1"
call monster.cmd :monsterNameDescription "!%creature%.name!" "!%monster%.lit!" "name"

set /a "hates_light=!%creature%.defenses! & %config.monsters.defense.cd_light%"
if not "!hates_light!"=="0" (
    if "!%monster%.lit!"=="true" (
        set /a "creature_recall[!%monster%.creature_id!].defenses|=%config.monsters.defense.cd_light%"
    )

    call dice.cmd :diceRoll 2 8
    call monster.cmd :monsterTakeHit "%~1" "!errorlevel!"
    if !errorlevel! GEQ 0 (
        call monster.cmd :printMonsterActionText "!name!" "shrivels away in the light."
        call ui.cmd :displayCharacterExperience
    ) else (
        call monster.cmd :printMonsterActionText "!name!" "cringes from the light."
    )
)
exit /b

::------------------------------------------------------------------------------
:: Creates a line of light in a given direction
::
:: Arguments: %1 - The coordinates of the player
::            %2 - The direction to shoot the light in
:: Returns:   None
::------------------------------------------------------------------------------
:spellLightLine
set "distance=0"

:spellLightLineWhileLoop
for /f "tokens=1,2" %%X in ("!coord.x! !coord.y!") do set "tile=dg.floor[%%Y][%%X]"

set "break_condition_met=0"
if %~2 GTR %config.treasure.objects_bolts_max_range% set "break_condition_met=1"
if !%tile%.feature_id! GEQ %MIN_CLOSED_SPACE% set "break_condition_met=1"
if "!break_condition_met!"=="1" (
    call player.cmd :playerMovePosition "%~2" "coord"
    exit /b
)

if "!%tile%.permanent_light!"=="false" (
    if "!%tile%.temporary_light!"=="false" (
        set "%tile%.permanent_light=true"
        set "tmp_coord.y=!%~1.y!"
        set "tmp_coord.x=!%~1.x!"
        set "tmp_coord=!tmp_coord.y!;!tmp_coord.x!"

        if "!%tile%.feature_id!"=="%TILE_LIGHT_FLOOR%" (
            call ui.cmd :coordInsidePanel "!tmp_coord!"
            if "!errorlevel!"=="0" call dungeon.cmd :dungeonLightRoom "tmp_coord"
        ) else (
            call dungeon.cmd :dungeonLiteSpot "tmp_coord"
        )
    )
)

set "%tile%.permanent_light=true"
if !%tile%.creature_id! GTR 1 (
    call :spellLightLineTouchesMonster "!%tile%.creature_id!"
)

set "coord=%~1"
call player.cmd :playerMovePosition "%~2" "coord"
set /a distance+=1
goto :spellLightLineWhileLoop

::------------------------------------------------------------------------------
:: Lights a line in all directions
::
:: Arguments: %1 - The coordinates of the player
:: Returns:   None
::------------------------------------------------------------------------------
:spellStarlite
if %py.flags.blind% LSS 1 (
    call ui_io.cmd :printMessage "The end of the staff bursts into a blue shimmering light."
)
for /L %%A in (1,1,9) do (
    if not "%%A"=="5" (
        call :spellLightLine "%~1" "%%~A"
    )
)
exit /b

::------------------------------------------------------------------------------
:: Disarms all traps/chests in a given direction
::
:: Arguments: %1 - The coordinates of the player
::            %2 - The direction to disarm in
:: Returns:   0 if something was successfully disarmed
::            1 if there is nothing to disarm
::------------------------------------------------------------------------------
:spellDisarmAllInDirection
set "coord=%~1"
set "distance=0"
set "disarmed=1"

:spellDisarmAllInDirectionWhileLoop
for /f "tokens=1,2 delims=;" %%A in ("!coord!") do set "tile=dg.floor[%%~A][%%~B]"
set "t_id=!%tile%.treasure_id!"
set "item=game.treasure.list[%t_id%]"
if not "!%tile%.treasure_id!"=="0" (
    set "is_trap=0"
    if "!%item%.category_id!"=="%TV_INVIS_TRAP%" set "is_trap=1"
    if "!%item%.category_id!"=="%TV_VIS_TRAP%" set "is_trap=1"
    if "!is_trap!"=="1" (
        call dungeon.cmd :dungeonDeleteObject "coord"
        if "!errorlevel!"=="0" set "disarmed=0"
    ) else if "!%item%.category_id!"=="%TV_CLOSED_DOOR%" (
        REM Locked or jammed doors become merely closed
        set "%item%.misc_use=0"
    ) else if "!%item%.category_id!"=="%TV_SECRET_DOOR%" (
        set "%tile%.field_mark=true"
        call dungeon.cmd :trapChangeVisibility "coord"
        set "disarmed=0"
    ) else (
        if "!%item%.category_id!"=="%TV_CHEST%" (
            if not "!%item%.flags!"=="0" (
                set "disarmed=0"
                call ui_io.cmd :printMessage "Click^^!"

                set /a "%item%.flags&=~(%config.treasure.chests.ch_trapped%|%config.treasure.chests.ch_locked%)"
                set "%item%.special_name_id=%SpecialNameIds.sn_unlocked%"
                call identification.cmd :spellItemIdentifyAndRemoveRandomInscription "%item%"
            )
        )
    )
)
call player.cmd :playerMovePosition "%~2" "coord"
set /a distance+=1

if !distance! LEQ %config.treasure.objects_bolts_max_range% (
    if !%tile%.feature_id! LEQ %MAX_OPEN_SPACE% (
        goto :spellDisarmAllInDirectionWhileLoop
    )
)
exit /b

::------------------------------------------------------------------------------
:: Returns flags for a given type area affect
::
:: Arguments: %1 - The type of spell
::            %2 - A variable to store the type of weapon used
::            %3 - A variable to store the damage type
::            %4 - A variable that indicates if certain items get destroyed
::            %5 - A reference to the item located in the area
:: Returns:   None
::------------------------------------------------------------------------------
:spellGetAreaAffectFlags
if "%~1"=="%MagicSpellFlags.MagicMissile%" (
    set "weapon_type=0"
    set "harm_type=0"
    call inventory.cmd :setNull
    set "%~4=!errorlevel!"
) else if "%~1"=="%MagicSpellFlags.Lightning%" (
    set "weapon_type=%config.monsters.spells.cs_br_light%"
    set "harm_type=%config.monsters.defense.cd_light%"
    call inventory.cmd :setLightningDestroyableItems "%~5"
    set "%~4=!errorlevel!"
) else if "%~1"=="%MagicSpellFlags.PoisonGas%" (
    set "weapon_type=%config.monsters.spells.cs_br_gas%"
    set "harm_type=%config.monsters.defense.cd_poison%"
    call inventory.cmd :setNull
    set "%~4=!errorlevel!"
) else if "%~1"=="%MagicSpellFlags.Acid%" (
    set "weapon_type=%config.monsters.spells.cs_br_acid%"
    set "harm_type=%config.monsters.defense.cd_acid%"
    call inventory.cmd :setAcidDestroyableItems "%~5"
    set "%~4=!errorlevel!"
) else if "%~1"=="%MagicSpellFlags.Frost%" (
    set "weapon_type=%config.monsters.spells.cs_br_frost%"
    set "harm_type=%config.monsters.defense.cd_frost%"
    call inventory.cmd :setFrostDestroyableItems "%~5"
    set "%~4=!errorlevel!"
) else if "%~1"=="%MagicSpellFlags.Fire%" (
    set "weapon_type=%config.monsters.spells.cs_br_fire%"
    set "harm_type=%config.monsters.defense.cd_fire%"
    call inventory.cmd :setFireDestroyableItems "%~5"
    set "%~4=!errorlevel!"
) else if "%~1"=="%MagicSpellFlags.HolyOrb%" (
    set "weapon_type=0"
    set "harm_type=%config.monsters.defense.cd_evil%"
    call inventory.cmd :setLightningDestroyableItems "%~5"
    set "%~4=!errorlevel!"
) else (
    call ui_io.cmd :printMessage "Error in :spellGetAreaAffectFlags"
)
exit /b

::------------------------------------------------------------------------------
:: Prints a message saying that the monster was struck
:: 
:: Arguments: %1 - A reference to the monster being struck
::            %2 - A reference to the type of bolt striking the monster
::            %3 - Determines if the monster is visible or not
:: Returns:   None
::------------------------------------------------------------------------------
:printBoltStrikesMonsterMessage
if "%~3"=="true" (
    set "monster_name=the !%~1.name!"
) else (
    set "monster_name=it"
)
call ui_io.cmd :printMessage "The !%~2! strikes !monster_name!."
exit /b

::------------------------------------------------------------------------------
:: Light up the tile since fire glows and then try to burn the monster
:: TODO: s/spellFire/spell/g
::
:: Arguments: %1 - A reference to the tile that the monster is on
::            %2 - The damage done by the spell
::            %3 - The type of damage done by the spell
::            %4 - The weapon_id of the weapon that cast the spell
::            %5 - A reference to the name of the spell that was cast
::------------------------------------------------------------------------------
:spellFireBoltTouchesMonster
set "damage=%~2"
set "t_id=!%~1.creature_id!"
set "monster=monsters[%t_id%]"
set "c_id=!%monster%.creature_id!"
set "creature=creatures_list[%c_id%]"

:: Temporarily set permanent light so that :monsterUpdateVisibility works
set "saved_lit_status=!%~1.permanent_light!"
set "%~1.permanent_light=true"
call monster.cmd :monsterUpdateVisibility "%c_id%"
set "%~1.permanent_light=%saved_lit_status%"

call ui_io.cmd :putQIO
call :printBoltStrikesMonsterMessage "%creature%" "%~5" "!%monster%.lit!"

set /a "is_weak_to_type=%~3 & !%creature%.defenses!"
set /a "is_monster_type=%~4 & !%creatures%.spells!"

if not "%is_weak_to_type%"=="0" (
    set /a damage*=2
    if "!%monster%.lit!"=="true" (
        set /a "creature_recall[%c_id%].defenses|=%~3"
    )
) else if not "%is_monster_type%"=="0" (
    set /a damage/=4
    if "!%monster%.lit!"=="true" (
        set /a "creature_recall[%c_id%].defenses|=%~4"
    )        
)

call monster.cmd :monsterNameDescription "!%creature%.name!" "!%monster%.lit!" "name"
call monster.cmd :monsterTakeHit "!%~1.creature_id!" "!damage!"
if !errorlevel! GEQ 0 (
    call monster.cmd :printMonsterActionText "!name!" "dies in a fit of agony."
    call ui.cmd :displayCharacterExperience
) else (
    call monster.cmd :printMonsterActionText "!name!" "screams in agony."
)
exit /b

::------------------------------------------------------------------------------
:: Fires a generic bolt in a specified direction
::
:: Arguments: %1 - The coordinates of the player
::            %2 - The direction the bolt is being fired
::            %3 - The damage done to any monster that is hit
::            %4 - The type of spell (missile, lightning, frost, fire)
::            %5 - A reference to the name of the spell
:: Returns:   None
::------------------------------------------------------------------------------
:spellFireBolt
set "harm_type=0"
call :spellGetAreaAffectFlags "%~4" "weapon_type" "harm_type" "dummy"

set "distance=0"
for /f "tokens=1,2 delims=;" %%A in ("%~1") do (
    set "coord.y=%%A"
    set "coord.x=%%B"
    set "coord=%%A;%%B"
)

:spellFireBoltWhileLoop
set "old_coord.y=!coord.y!"
set "old_coord.x=!coord.x!"
set "old_coord=!coord!"
call player.cmd :playerMovePosition "%~2" "coord"
set /a distance+=1

set "tile=dg.floor[%coord.y%][%coord.x%]"
call dungeon.cmd :dungeonLiteSpot "old_coord"

if %distance% GTR %config.treasure.objects_bolts_max_range% exit /b
if !%tile%.feature_id! GEQ %MIN_CLOSED_SPACE% exit /b

if !%tile%.creature_id! GTR 1 (
    call :spellFireBoltTouchesMonster "%tile%" "%~3" "%harm_type%" "%weapon_type%" "%~5"
    exit /b
) else (
    call ui.cmd :coordInsidePanel "!coord!"
    if "!errorlevel!"=="0" (
        if %py.flags.blind% LSS 1 (
            call ui_io.cmd :panelPutTile "*" "!coord!"
            call ui_io.cmd :putQIO
        )
    )
)
goto :spellFireBoltWhileLoop

::------------------------------------------------------------------------------
:: Fires a projectile ball in a specified direction with AoE damage
::
:: Arguments: %1 - The coordinates of the player
::            %2 - The direction of the spell
::            %3 - The damage done to any monster that is hit
::            %4 - The type of spell (missile, lightning, frost, fire)
::            %5 - A reference to the name of the spell
:: Returns:   None
::------------------------------------------------------------------------------
:spellFireBall
set "coord=%~1"
set "direction=%~2"
set "damage_hp=%~3"
set "spell_type=%~4"
set "total_hits=0"
set "total_kills=0"
set "distance=0"
set "finished=false"

:spellFireBallWhileLoop
if "!finished!"=="true" goto :spellFireBallAfterWhileLoop

for /f "tokens=1,2 delims=;" %%A in ("%coord%") do (
    set "coord.y=%%~A"
    set "coord.x=%%~B"
)
set "old_coord.y=%coord.y%"
set "old_coord.x=%coord.x%"
set "old_coord=%coord%"
call player.cmd :playerMovePosition "%direction%" "coord"

set /a distance+=1
call dungeon.cmd :dungeonLiteSpot "old_coord"

if %distance% GTR %config.treasure.objects_bolts_max_range% exit /b

set "tile=dg.floor[%coord.y%][%coord.x%]"

set "ball_can_hit=0"
if !%tile%.feature_id! GEQ %MIN_CLOSED_SPACE% set "ball_can_hit=1"
if !%tile%.creature_id! GTR 1 set "ball_can_hit=1"
if "%ball_can_hit%"=="1" (
    set "finished=true"

    if !%tile%.feature_id! GEQ %MIN_CLOSED_SPACE% (
        set "coord.y=!old_coord.y!"
        set "coord.x=!old_coord.x!"
        set "coord=!old_coord!"
    )

    REM Explosion have an area of effect
    set /a aoe_top=!coord.y!-2, aoe_bottom=!coord.y!+2, aoe_left=!coord.x!-2, aoe_right=!coord.x!+2
    for /L %%Y in (!aoe_top!,1,!aoe_bottom!) do (
        for /L %%X in (!aoe_left!,1,!aoe_right!) do (
            set "spot.y=%%Y"
            set "spot.x=%%X"
            set "spot=%%Y;%%X"

            set "can_be_seen=0"
            call dungeon.cmd :coordInBounds "spot" && set /a can_be_seen+=1
            call dungeon.cmd :coordDistanceBetween "coord" "spot"
            if !errorlevel! LEQ 2 set /a can_be_seen+=1
            call dungeon_los.cmd :los "!coord!" "!spot!" && set /a can_be_seen+=1
            if "!can_be_seen!"=="3" (
                call :spellFireBallOuterIf "!spot.y!" "!spot.x!"
            )
        )
    )

    call ui_io.cmd :putQIO

    REM TODO: See what happens when I put this in the outer if statment
    for /L %%Y in (!aoe_top!,1,!aoe_bottom!) do (
        for /L %%X in (!aoe_left!,1,!aoe_right!) do (
            set "spot.y=%%Y"
            set "spot.x=%%X"

            set "can_be_seen=0"
            call dungeon.cmd :coordInBounds "spot" && set /a can_be_seen+=1
            call dungeon.cmd :coordDistanceBetween "coord" "spot"
            if !errorlevel! LEQ 2 set /a can_be_seen+=1
            call dungeon_los.cmd :los "!coord!" "!spot!" && set /a can_be_seen+=1
            if "!can_be_seen!"=="3" (
                call dungeon.cmd :dungeonLiteSpot "spot"
            )
        )
    )

    if "!total_hits!"=="1" (
        call ui_io.cmd :printMessage "The !%~5! envelops a creature."
    ) else if !total_hits! GTR 1 (
        call ui_io.cmd :printMessage "The !%~5! envelops several creatures."
    )

    if "!total_hits!"=="1" (
        call ui_io.cmd :printMessage "There is a scream of agony."
    ) else if !total_kills! GTR 1 (
        call ui_io.cmd :printMessage "There are several screams of agony."
    )

    if !total_kills! GEQ 0 (
        call ui.cmd :displayCharacterExperience
    )
) else (
    call ui.cmd :coordInsidePanel "!spot!"
    if "!errorlevel!"=="0" (
        if %py.flags.blind% LSS 1 (
            call ui_io.cmd :panelPutTile "*" "!spot!"
        )
    )
    call ui_io.cmd :putQIO
)
goto :spellFireBallWhileLoop

:spellFireBallOuterIf
set "tile=dg.floor[%~1][%~2]"
set "t_id=!%tile%.treasure_id!"
set "c_id=!%tile%.creature_id!"
set "monster=monsters[%c_id%]"
set "mc_id=!%monsters%.creature_id!"
set "creature=creatures_list[%mc_id%]"

if not "%t_id%"=="0" (
    call :spellGetAreaAffectFlags "%spell_type%" "weapon_type" "harm_type" "destroy" "game.treasure.list[%t_id%]"
    if "!destroy!"=="0" (
        call dungeon.cmd :dungeonDeleteObject "spot"
    )

    if !%tile%.feature_id! LEQ %MAX_OPEN_SPACE% (
        if !%tile%.creature_id! GTR 1 (
            set "saved_lit_status=!%tile%.permanent_light!"
            set "%tile%.permanent_light=true"
            call monster.cmd :monsterUpdateVisibility "%c_id%"

            set /a total_hits+=1
            set "damage=!damage_hp!"

            set /a "is_weak_to_type=!harm_type! & !%creature%.defenses!"
            set /a "is_monster_type=!weapon_type! & !%creature%.spells!"
            if not "!is_weak_to_type!"=="0" (
                set /a damage*=2
                if "!%monster%.lit!"=="true" (
                    set /a "creature_recall[%mc_id%].defenses|=!harm_type!"
                )
            ) else if not "!is_monster_type!"=="0" (
                set /a damage/=4
                if "!%monster%.lit!"=="0" (
                    set /a "creature_recall[%mc_id%].spells|=!weapon_type!"
                )
            )

            call dungeon.cmd :coordDistanceBetween "spot" "coord"
            set /a "damage=(damage / (!errorlevel! + 1))"

            call monster.cmd :monsterTakeHit "%c_id%" "!damage!"
            if !errorlevel! GEQ 0 set /a total_kills+=1
            set "%tile%.permanent_light=!saved_lit_status!"
        ) else (
            call ui.cmd :coordInsidePanel "!spot!"
            if "!errorlevel!"=="0" (
                if %py.flags.blind% LSS 1 (
                    call ui_io.cmd :panelPutTile "*" "!spot!"
                )
            )
        )
    )
)
exit /b

::------------------------------------------------------------------------------
:: A ranged AoE attack performed by a monster against a player
::
:: Arguments: %1 - The coordinates of the player
::            %2 - The monster_id of the monster attacking
::            %3 - The damage done by the attack
::            %4 - The type of spell
::            %5 - A reference to the name of the spell
:: Returns:   None
::------------------------------------------------------------------------------
:spellBreath
set "coord=%~1"
set "monster_id=%~2"
set "damage_hp=%~3"
set "spell_type=%~4"
set "spell_name=%~5"

set /a aoe_top=!coord.y!-2, aoe_bottom=!coord.y!+2, aoe_left=!coord.x!-2, aoe_right=!coord.x!+2
for /L %%Y in (%aoe_top%,1,%aoe_bottom%) do (
    for /L %%X in (%aoe_left%,1,%aoe_right%) do (
        set "location=%%Y;%%X"
        set "can_be_seen=0"
        call dungeon.cmd :coordInBounds "location" && set /a can_be_seen+=1
        call dungeon.cmd :coordDistanceBetween "coord" "location"
        if !errorlevel! LEQ 2 set /a can_be_seen+=1
        call dungeon_los.cmd :los "!coord!" "!location!" && set /a can_be_seen+=1
        if "!can_be_seen!"=="3" call :spellBreathOuterIf "%%Y" "%%X"
    )
)

call ui_io.cmd :putQIO

for /L %%Y in (%aoe_top%,1,%aoe_bottom%) do (
    for /L %%X in (%aoe_left%,1,%aoe_right%) do (
        set "spot=%%Y;%%X"
        set "can_be_seen=0"
        call dungeon.cmd :coordInBounds "spot" && set /a can_be_seen+=1
        call dungeon.cmd :coordDistanceBetween "coord" "spot"
        if !errorlevel! LEQ 2 set /a can_be_seen+=1
        call dungeon_los.cmd :los "!coord!" "!spot!" && set /a can_be_seen+=1
        if "!can_be_seen!"=="3" call dungeon.cmd :dungeonLiteSpot "spot"
    )
)
exit /b

:spellBreathOuterIf
set "tile=dg.floor[%~1][%~2]"
set "t_id=!%tile%.treasure_id!"
set "c_id=!%tile%.creature_id!"
set "monster=monsters[%c_id%]"
set "mc_id=!%monsters%.creature_id!"
set "creature=creatures_list[%mc_id%]"

if not "%t_id%"=="0" (
    call :spellGetAreaAffectFlags "%spell_type%" "weapon_type" "harm_type" "destroy" "game.treasure.list[%t_id%]"
    if "!destroy!"=="0" (
        call dungeon.cmd :dungeonDeleteObject "location"
    )
)

if !%tile%.feature_id! LEQ %MAX_OPEN_SPACE% (
    call dungeon.cmd :coordInBounds "location"
    if "!errorlevel!"=="0" (
        set /a "is_blind=%py.flags.status% & %config.player.status.py.blind%"
        if "!is_blind!"=="0" call ui_io.cmd :panelPutTile "*" "location"
    )

    if %c_id% GTR 1 (
        set "damage=%damage_hp%"
        set /a "is_weak_to_type=!harm_type! & !%creature%.defenses!"
        set /a "is_monster_type=!weapon_type! & !%creature%.spells!"
        if not "!is_weak_to_type!"=="0" (
            set /a damage*=2
        ) else if not "!is_monster_type!"=="0" (
            set /a damage/=4
        )
        call dungeon.cmd :coordDistanceBetween "location" "coord"
        set /a "damage=(damage / (!errorlevel! + 1))"

        set /a %monster%.hp-=!damage!
        set "%monster%.sleep_count=0"

        if !%monster%.hp! LSS 0 (
            call monster.cmd :monsterDeath "!%monster%.pos.y!;!%monster%.pos.x!" "!%creature%.movement!"
            set "treasure_id=!errorlevel!"

            if "!%monster%.lit!"=="true" (
                set /a "has_treasure=(!creature_recall[%mc_id%].movement! & %config.monsters.move.cm_treasure%) >> %config.monsters.move.cm_tr_shift%"
                set /a "is_treasure=(!treasure_id! & %config.monsters.move.cm_treasure%) >> %config.monsters.move.cm_tr_shift%"
                if !has_treasure! GTR !is_treasure! (
                    set /a "treasure_id=((!treasure_id! & ~%config.monsters.move.cm_treasure%) | (!has_treasure! << %config.monsters.move.cm_tr_shift%))"
                )
                set /a "creature_recall[%mc_id%].movement=(!treasure_id! | !creature_recall[%mc_id%].movement! & ~%config.monsters.move.cm_treasure%)"
            )

            if %monster_id% LSS !%tile%.creature_id! (
                call dungeon.cmd :dungeonDeleteMonster "!%tile%.creature_id!"
            ) else (
                call dungeon.cmd :dungeonRemoveMonsterFromLevel "!%tile%.creature_id!"
            )
        )
    ) else (
        if "!damage!"=="0" set "damage=1"

        if "%spell_type%"=="%MagicSpellFlags.Lightning%" (
            call inventory.cmd :damageLightningBolt "!damage!" "!%spell_name%!"
            exit /b
        ) else if "%spell_type%"=="%MagicSpellFlags.Lightning%" (
            call inventory.cmd :damagePoisonedGas "!damage!" "!%spell_name%!"
            exit /b
        ) else if "%spell_type%"=="%MagicSpellFlags.Acid%" (
            call inventory.cmd :damageAcid "!damage!" "!%spell_name%!"
            exit /b
        ) else if "%spell_type%"=="%MagicSpellFlags.Frost%" (
            call inventory.cmd :damageCold "!damage!" "!%spell_name%!"
            exit /b
        ) else if "%spell_type%"=="%MagicSpellFlags.Fire%" (
            call inventory.cmd :damageFire "!damage!" "!%spell_name%!"
            exit /b
        ) else (
            exit /b
        )
    )
)
exit /b
::------------------------------------------------------------------------------
:: Recharges a wand, staff, or rod
::
:: Arguments: %1 - The maximum number of charges to add to the item
:: Returns:   0 if an item is successfully selected for recharge
::            1 if there is nothing to charge or the user backs out
::------------------------------------------------------------------------------
:spellRechargeItem
call inventory.cmd :inventoryFindRange "%TV_STAFF%" "%TV_WAND%" "item_pos_start" "item_pos_end"
if "!errorlevel!"=="1" (
    call ui_io.cmd :printMessage "You have nothing to recharge."
    exit /b 1
)

call ui_inventory.cmd :inventoryGetInputForItemId "item_id" "Recharge which item?" "%item_pos_start%" "%item_pos_end%" "CNIL" "CNIL"
if "!errorlevel!"=="1" exit /b 1

set "item=py.inventory[%item_id%]"

:: Recharge  I - recharge (20) - 1/6  failure for empty 10th level wand
:: Recharge II - recharge (60) - 1/10 failure for empty 10th level wand
:: recharging a high level wand that already has many charges is difficult
set /a fail_chance=%~1 + 50 - !%item%.depth_first_found! - !%item%.misc_use!

if %fail_chance% LSS 19 (
    set "fail_chance=1"
) else (
    set /a fail_chance/=10
    call rng.cmd :randomNumber !fail_chance!
    set "fail_chance=!errorlevel!"
)

if "!fail_chance!"=="1" (
    call ui_io.cmd :printMessage "There is a bright flash of light."
    call inventory.cmd :inventoryDestroyItem "%item_id%"
) else (
    set /a "number_of_charges=(!number_of_charges! / (!%item%.depth_first_found! + 2)) + 1"
    call rng.cmd :randomNumber !number_of_charges!
    set /a %item%.misc_use+=2 + !errorlevel!

    call identification.cmd :spellItemIdentified "item"
    if "!errorlevel!"=="0" (
        call identification.cmd :spellItemRemoveIdentification "item"
    )
    call identification.cmd :itemIdentificationClearEmpty "item"
)
exit /b 0

::------------------------------------------------------------------------------
:: Increase or decrease a monster's hit points
::
:: Arguments: %1 - The coordinates of the monster
::            %2 - The direction that the player is moving in
::            %3 - The damage done to the monster [negative if it's healing]
:: Returns:   0 if a monster's HP was changed
::            1 if there was no monster on screen in that direction
::------------------------------------------------------------------------------
:spellChangeMonsterHitPoints
set "coord=%~1"
set "direction=%~2"
set "damage_hp=%~3"

set "distance=0"
set "changed=1"
set "finished=false"

:spellChangeMonsterHitPointsWhileLoop
if "!finished!"=="true" goto :spellChangeMonsterHitPointsAfterWhileLoop

call player.cmd :playerMovePosition "%direction%" "coord"
set /a distance+=1
for /f "tokens=1,2 delims=;" %%A in ("!coord!") do (
    set "tile=dg.floor[%%~A][%%~B]"
)

if %distance% GTR %config.treasure.objects_bolts_max_range% goto :spellChangeMonsterHitPointsAfterWhileLoop
if !%tile%.feature_id! GEQ %MIN_CLOSED_SPACE% goto :spellChangeMonsterHitPointsAfterWhileLoop

set "c_id=!%tile%.creature_id!"
set "monster=monsters[%c_id%]"
set "mc_id=!%monster%.creature_id!"
set "creature=creatures_list[%mc_id%]"
if !%tile%.creature_id! GTR 1 (
    set "finished=true"

    call :monsterNameDescription "!%creature%.name!" "!%monster%.lit!" "name"

    call monster.cmd :monsterTakeHit "%c_id%" "%damage_hp%"
    if !errorlevel! GEQ 0 (
        call monster.cmd :printMonsterActionText "!name!" "dies in a fit of agony."
        call ui.cmd :displayCharacterExperience
    ) else if %damage_hp% GTR 0 (
        call monster.cmd :printMonsterActionText "!name!" "screams in agony."
    )

    set "changed=0"
)
goto :spellChangeMonsterHitPointsWhileLoop

:spellChangeMonsterHitPointsAfterWhileLoop
exit /b %changed%

::------------------------------------------------------------------------------
:: It's just :changeMonsterHitPoints but it always does 75 damage and doesn't
:: work against undead monsters
::
:: Arguments: %1 - The coordinates of the monster
::            %2 - The direction to cast in
:: Returns:   0 if HP was removed from the monster
::            1 if the target creature is undead
::------------------------------------------------------------------------------
:spellDrainLifeFromMonster
set "coord=%~1"
set "direction=%~2"

set "distance=0"
set "drained=1"
set "finished=false"

:spellDrainLifeFromMonsterWhileLoop
if "!finished!"=="true" goto :spellDrainLifeFromMonsterAfterWhileLoop

call player.cmd :playerMovePosition "%direction%" "coord"
set /a distance+=1
for /f "tokens=1,2 delims=;" %%A in ("!coord!") do (
    set "tile=dg.floor[%%~A][%%~B]"
)

if %distance% GTR %config.treasure.objects_bolts_max_range% goto :spellDrainLifeFromMonsterAfterWhileLoop
if !%tile%.feature_id! GEQ %MIN_CLOSED_SPACE% goto :spellDrainLifeFromMonsterAfterWhileLoop

set "c_id=!%tile%.creature_id!"
set "monster=monsters[%c_id%]"
set "mc_id=!%monster%.creature_id!"
set "creature=creatures_list[%mc_id%]"
if !%tile%.creature_id! GTR 1 (
    set "finished=true"

    set /a "is_undead=!%creature%.defenses! & %config.monsters.defense.cd_undead%"
    if "!is_undead!"=="0" (
        call :monsterNameDescription "!%creature%.name!" "!%monster%.lit!" "name"
        call monster.cmd :monsterTakeHit "%c_id%" 75
        if !errorlevel! GEQ 0 (
            call monster.cmd :printMonsterActionText "!name!" "dies in a fit of agony."
            call ui.cmd :displayCharacterExperience
        ) else if %damage_hp% GTR 0 (
            call monster.cmd :printMonsterActionText "!name!" "screams in agony."
        )
        set "drained=0"
    ) else (
        set /a "creature_recall[%mc_id%].defenses|=%config.monsters.defense.cd_undead%"
    )
)
:spellDrainLifeFromMonsterAfterWhileLoop
exit /b !drained!

::------------------------------------------------------------------------------
:: Changes the speed of a monster [other than the Balrog]
::
:: Arguments: %1 - The coordinates of the monster
::            %2 - The direction the spell is cast in
::            %3 - The amount to increase the speed by [can be negative]
:: Returns:   0 if the monster speeds up or if a random number between 1 and 40
::              is less than the monster's level
::            1 if the monster's speed does not change
::------------------------------------------------------------------------------
:spellSpeedMonster
set "coord=%~1"
set "direction=%~2"
set "speed=%~3"

set "distance=0"
set "changed=1"
set "finished=false"

:spellSpeedMonsterWhileLoop
if "!finished!"=="true" exit /b !changed!
call player.cmd :playerMovePosition "%direction%" "coord"
set /a distance+=1

for /f "tokens=1,2 delims=;" %%A in ("!coord!") do (
    set "tile=dg.floor[%%~A][%%~B]"
)

if %distance% GTR %config.treasure.objects_bolts_max_range% exit /b !changed!
if !%tile%.feature_id! GEQ %MIN_CLOSED_SPACE% exit /b !changed!

set "c_id=!%tile%.creature_id!"
set "monster=monsters[%c_id%]"
set "mc_id=!%monster%.creature_id!"
set "creature=creatures_list[%mc_id%]"
if !%tile%.creature_id! GTR 1 (
    set "finished=true"
    call :monsterNameDescription "!%creature%.name!" "!%monster%.lit!" "name"

    if %speed% GTR 0 (
        set /a %monster%.speed+=%speed%
        set "%monster%.sleep_count=0"
        set "changed=true"
        call monster.cmd :printMonsterActionText "!name!" "starts moving faster."
    ) else (
        call rng.cmd :randomNumber %MON_MAX_LEVELS%
        if !errorlevel! GTR !%creature%.level! (
            set /a %monster%.speed+=%speed%
            set "%monster%.sleep_count=0"
            set "changed=true"
            call monster.cmd :printMonsterActionText "!name!" "starts moving slower."
        ) else (
            set "%monster%.sleep_count=0"
            call monster.cmd :printMonsterActionText "!name!" "is unaffected."
        )
    )
)
goto :spellSpeedMonsterWhileLoop

::------------------------------------------------------------------------------
:: Confuses a monster
::
:: Arguments: %1 - The coordinates of the monster
::            %2 - The direction to cast the spell in
:: Returns:   0 if a monster is confused
::            1 if no monster is present or it can't sleep
::------------------------------------------------------------------------------
:spellConfuseMonster
set "coord=%~1"
set "direction=%~2"

set "distance=0"
set "confused=1"
set "finished=false"

:spellConfuseMonsterWhileLoop
if "!finished!"=="true" exit /b !confused!

call player.cmd :playerMovePosition "%direction%" "coord"
set /a distance+=1

for /f "tokens=1,2 delims=;" %%A in ("!coord!") do (
    set "tile=dg.floor[%%~A][%%~B]"
)
if !distance! GTR %config.treasure.objects_bolts_max_range% exit /b !confused!
if !%tile%.feature_id! GEQ %MIN_CLOSED_SPACE% exit /b !confused!

set "c_id=!%tile%.creature_id!"
set "monster=monsters[%c_id%]"
set "mc_id=!%monster%.creature_id!"
set "creature=creatures_list[%mc_id%]"
if !%tile%.creature_id! GTR 1 (
    set "finished=true"
    call :monsterNameDescription "!%creature%.name!" "!%monster%.lit!" "name"

    set "is_unaffected=0"
    call rng.cmd :randomNumber %MON_MAX_LEVELS%
    if !errorlevel! LSS !%creature%.level! set "is_unaffected=1"
    set /a "cant_sleep=!%creature%.defenses! & %config.monsters.defense.cd_no_sleep%"
    if not "!cant_sleep!"=="0" set "is_unaffected=1"
    if "!is_unaffected!"=="1" (
        if "!%monster%.lit!"=="true" (
            if not "!cant_sleep!"=="0" (
                set /a "creature_recall[%mc_id%].defenses|=%config.monsters.defense.cd_no_sleep%"
            )

            if "!cant_sleep!"=="0" set "%monster%.sleep_count=0"
            call monster.cmd :printMonsterActionText "!name!" "is unaffected."
        )
    ) else (
        if not "!%monster%.confused_amount!"=="0" (
            set /a %monster%.confused_amount+=3
        ) else (
            call rng.cmd :randomNumber 16
            set /a %monster%.confused_amount=2+!errorlevel!
        )
        set "%monster%.sleep_count=0"
        set "confused=1"
        call monster.cmd :printMonsterActionText "!name!" "appears confused."
    )
)
goto :spellConfuseMonsterWhileLoop

::------------------------------------------------------------------------------
:: Puts a monster to sleep
::
:: Arguments: %1 - The coordinates of the monster
::            %2 - The direction to cast the spell in
:: Returns:   0 if the monster is put to sleep
::            1 if the monster remains awake
::------------------------------------------------------------------------------
:spellSleepMonster
set "coord=%~1"
set "direction=%~2"

set "distance=0"
set "asleep=1"
set "finished=false"

:spellSleepMonsterWhileLoop
if "!finished!"=="true" exit /b !asleep!

call player.cmd :playerMovePosition "%direction%" "coord"
set /a distance+=1

for /f "tokens=1,2 delims=;" %%A in ("!coord!") do (
    set "tile=dg.floor[%%~A][%%~B]"
)

if !distance! GTR %config.treasure.objects_bolts_max_range% exit /b !asleep!
if !%tile%.feature_id! GEQ %MIN_CLOSED_SPACE% exit /b !asleep!

set "c_id=!%tile%.creature_id!"
set "monster=monsters[%c_id%]"
set "mc_id=!%monster%.creature_id!"
set "creature=creatures_list[%mc_id%]"
if !%tile%.creature_id! GTR 1 (
    set "finished=true"
    call :monsterNameDescription "!%creature%.name!" "!%monster%.lit!" "name"

    set "is_unaffected=0"
    call rng.cmd :randomNumber %MON_MAX_LEVELS%
    if !errorlevel! LSS !%creature%.level! set "is_unaffected=1"
    set /a "cant_sleep=!%creature%.defenses! & %config.monsters.defense.cd_no_sleep%"
    if not "!cant_sleep!"=="0" set "is_unaffected=1"
    if "!is_unaffected!"=="1" (
        if "!%monster%.lit!"=="true" (
            if not "!cant_sleep!"=="0" (
                set /a "creature_recall[%mc_id%].defenses|=%config.monsters.defense.cd_no_sleep%"
            )
            call monster.cmd :printMonsterActionText "!name!" "is unaffected."
        )
    ) else (
        set "%monster%.sleep_count=500"
        set "asleep=0"
        call monster.cmd :printMonsterActionText "!name!" "falls asleep."
    )
)
goto :spellSleepMonsterWhileLoop

::------------------------------------------------------------------------------
:: Turns stone into mud and deletes any nearby walls
::
:: Arguments: %1 - The coordinates of the player
::            %2 - The direction the spell is cast in
:: Returns:   0 if any walls turned into mud
::            1 if there were no walls to convert
::------------------------------------------------------------------------------
:spellWallToMud
set "coord=%~1"
set "direction=%~2"

set "distance=0"
set "turned=1"
set "finished=false"

:spellWallToMudWhileLoop
if "!finished!"=="true" exit /b !turned!

call player.cmd :playerMovePosition "%direction%" "coord"
set /a distance+=1
for /f "tokens=1,2 delims=;" %%A in ("!coord!") do (
    set "tile=dg.floor[%%~A][%%~B]"
)
set "t_id=!%tile%.treasure_id!"

if "!distance!"=="%config.treasure.objects_bolts_max_range%" set "finished=true"

set "hit_wall=0"
if !%tile%.feature_id! GEQ %MIN_CAVE_WALL% set /a hit_wall+=1
if not "!%tile%.feature_id!"=="%TILE_BUONDARY_WALL%" set /a hit_wall+=1
if "!hit_wall!"=="2" (
    call player.cmd :playerTunnelWall "!coord!" 1 0

    call dungeon.cmd :caveTileVisible "coord"
    if "!errorlevel!"=="0" (
        set "turned=0"
        call ui_io.cmd :printMessage "The wall turns into mud."
    )
) else (
    set "hit_item=0"
    if not "!%tile%.treasure_id!"=="0" set /a hit_item+=1
    if !%tile%.feature_id! GEQ %MIN_CLOSED_SPACE% set /a hit_item+=1
    if "!hit_item!"=="2" (
        set "finished=true"

        set "on_screen=0"
        call ui.cmd :coordInsidePanel "!coord!" && set /a on_screen+=1
        call dungeon.cmd :caveTileVisible "coord" && set /a on_screen+=1
        if "!on_screen!"=="2" (
            set "turned=0"
            call identification.cmd :itemDescription "description" "game.treasure.list[%t_id%]" "false"
            call ui_io.cmd :printMessage "The !description! turns into mud."
        )

        if "!game.treasure.list[%t_id%].category_id!"=="%TV_RUBBLE%" (
            call dungeon.cmd :dungeonDeleteObject "coord"
            call rng.cmd :randomNumber 10
            if "!errorlevel!"=="1" (
                call dungeon.cmd :dungeonPlaceRandomObjectAt "coord" "false"
                call dungeon.cmd :caveTileVisible "coord"
                if "!errorlevel!"=="0" (
                    call ui_io.cmd :printMessage "You have found something."
                )
            )
        ) else (
            call dungeon.cmd :dungeonDeleteObject "coord"
        )
    )
)

set "c_id=!%tile%.creature_id!"
set "monster=monsters[%c_id%]"
set "mc_id=!%monster%.creature_id!"
set "creature=creatures_list[%mc_id%]"
if !%tile%.creature_id! GTR 1 (
    set /a "is_stone=!%creature%.defenses! & %config.monsters.defense.cd_stone%"
    if "!is_stone!"=="0" (
        call monster.cmd :monsterNameDescription "!%creature%.name!" "!%monster%.lit!" "name"

        call monster.cmd :monsterTakeHit "!%tile%.creature_id!" 100
        set "creature_id=!errorlevel!"
        if !creature_id! GEQ 0 (
            REM wtf why is this a separate thing from %c_id% and %mc_id%?
            for /f "delims=" %%A in ("!creature_id!") do (
                set /a "creature_recall[%%~A].defenses|=%config.monsters.defense.cd_stone%"
            )
            call monster.cmd :printMonsterActionText "!name!" "dissolves."
            call ui.cmd :displayCharacterExperience
        ) else (
            set /a "creature_recall[%mc_id%].defenses|=%config.monsters.defense.cd_stone%"
            call monster.cmd :printMonsterActionText "!name!" "grunts in pain."
        )
        set "finished=true"
    )
)
goto :spellWallToMudWhileLoop

::------------------------------------------------------------------------------
:: Destroys all traps and doors in a specified direction
::
:: Arguments: %1 - The coordinates of the player
::            %2 - The direction to cast the spell in
:: Returns:   0 if a door or trap was destroyed
::            1 if nothing was hit
::------------------------------------------------------------------------------
:spellDestroyDoorsTrapsInDirection
set "coord=%~1"
set "direction=%~2"

set "destroyed=1"
set "distance=0"

:spellDestroyDoorsTrapsInDirectionWhileLoop
call player.cmd :playerMovePosition "%direction%" "coord"
set /a distance+=1
for /f "tokens=1,2 delims=;" %%A in ("!coord!") do (
    set "tile=dg.floor[%%~A][%%~B]"
)

set "t_id=!%tile%.treasure_id!"
if not "%t_id%"=="0" (
    set "item=game.treasure.list[%t_id%]"

    set "is_trapdoor=0"
    if "!%item%.category_id!"=="%TV_INVIS_TRAP%" set "is_trapdoor=1"
    if "!%item%.category_id!"=="%TV_VIS_TRAP%" set "is_trapdoor=1"
    if "!%item%.category_id!"=="%TV_CLOSED_DOOR%" set "is_trapdoor=1"
    if "!%item%.category_id!"=="%TV_OPEN_DOOR%" set "is_trapdoor=1"
    if "!%item%.category_id!"=="%TV_SECRET_DOOR%" set "is_trapdoor=1"
    if "!is_trapdoor!"=="1" (
        call dungeon.cmd :dungeonDeleteObject "coord"
        if "!errorlevel!"=="0" (
            set "destroyed=0"
            call ui_io.cmd :printMessage "There is a bright flash of light."
        )
    ) else (
        if "!%item%.category_id!"=="%TV_CHEST%" (
            if not "!%item%.flags!"=="0" (
                set "destroyed=0"
                call ui_io.cmd :printMessage "CLICK"

                set /a "%item%.flags&=~(%config.treasure.chests.ch_trapped%|%config.treasure.chests.ch_locked%)"
                set "%item%.special_name_id=%SpecialNameIds.sn_unlocked%"
                call identification.cmd :spellItemIdentifyAndRemoveRandomInscription "%item%"
            )
        )
    )
)

if !distance! LEQ %config.treasure.objects_bolts_max_range% exit /b !destroyed!
if !%tile%.feature_id! LEQ %MAX_OPEN_SPACE% exit /b !destroyed!
goto :spellDestroyDoorsTrapsInDirectionWhileLoop

::------------------------------------------------------------------------------
:: Turn a monster into a different monster, except the Balrog
::
:: Arguments: %1 - The coordinates of the player
::            %2 - The direction to cast the spell in
:: Returns:   0 if a monster was successfully turned into another monster
::              and it was onscreen and the tile with the monster was lit
::            1 if none of those things happened
::------------------------------------------------------------------------------
:spellPolymorphMonster
set "coord=%~1"
set "direction=%~2"

set "distance=0"
set "morphed=1"
set "finished=false"

:spellPolymorphMonsterWhileLoop
if "!finished!"=="true" exit /b !morphed!

call player.cmd :playerMovePosition "%direction%" "coord"
set /a distance+=1

for /f "tokens=1,2 delims=;" %%A in ("!coord!") do (
    set "tile=dg.floor.[%%~A][%%~B]"
)
if !distance! GTR %config.treasure.objects_bolts_max_range% exit /b !morphed!
if !%tile%.feature_id! GEQ %MIN_CLOSED_SPACE% exit /b !morphed!

set "c_id=!%tile%.creature_id!"
set "monster=monsters[%c_id%]"
set "mc_id=!%monster%.creature_id!"
set "creature=creatures_list[%mc_id%]"
if !%tile%.creature_id! GTR 1 (
    call rng.cmd %MON_MAX_LEVELS%
    if !errorlevel! GTR !%creature%.level! (
        set "finished=true"
        call dungeon.cmd :dungeonDeleteMonster "!%tile%.creature_id!"

        set /a mon_level_range=!monster_levels[%MON_MAX_LEVELS%]! - !monster_levels[0]!
        call rng.cmd :randomNumber !mon_level_range!
        set /a rnd_level=!errorlevel! - 1 + !monster_levels[0]!
        call monster_manager.cmd :monsterPlaceNew "!coord!" "!rnd_level!" "false"
        set "morphed=!errorlevel!"

        set "morphin_time=0"
        if "!morphed!"=="0" set /a morphin_time+=1
        call ui.cmd :coordInsidePanel "!coord!" && set /a morphin_time+=1
        if "!%tile%.permanent_light!"=="true" set /a morphin_time+=1
        if "!%tile%.temporary_light!"=="true" set /a morphin_time+=1
        if !morphin_time! GEQ 3 set "morphed=0"
    )
) else (
    call monster.cmd :monsterNameDescription "!%creature%.name!" "!%monster%.lit!" "name"
    call monster.cmd :printMonsterActionText "!name!" "is unaffected."
)
goto :spellPolymorphMonsterWhileLoop

::------------------------------------------------------------------------------
:: Creates a wall
::
:: Arguments: %1 - The coordinates of the player
::            %2 - The direction to cast the spell in
:: Returns:   0 if a wall was built
::            1 if the target is out of range
::------------------------------------------------------------------------------
:spellBuildWall
set "coord=%~1"
set "direction=%~2"

set "distance=0"
set "built=1"
set "finished=false"

:spellBuildWallWhileLoop
call player.cmd :playerMovePosition "%direction%" "coord"
set /a distance+=1

for /f "tokens=1,2 delims=;" %%A in ("!coord!") do (
    set "tile=dg.floor[%%~A][%%~B]"
)

if !distance! GTR %config.treasure.objects_bolts_max_range% exit /b !built!
if !%tile%.feature_id! GEQ %MIN_CLOSED_SPACE% exit /b !built!

if not "!%tile%.treasure_id!"=="0" call dungeon.cmd :dungeonDeleteObject "coord"

set "c_id=!%tile%.creature_id!"
set "monster=monsters[%c_id%]"
set "mc_id=!%monster%.creature_id!"
set "creature=creatures_list[%mc_id%]"
if %c_id% GTR 1 (
    set "finished=true"

    set /a "can_phase=!%creature%.movement! & %config.monsters.move.cm_phase%"
    if "!can_phase!"=="0" (
        set /a "is_attack_only=!%creature%.movement! & %config.monsters.move.cm_attack_only%"
        if not "!is_attack_only!"=="0" (
            set "damage=3000"
        ) else (
            call dice.cmd :diceRoll 4 8
            set "damage=!errorlevel!"
        )

        call monster.cmd :monsterNameDescription "!%creature%.name!" "!%monster%.lit!" "name"
        call monster.cmd :printMonsterActionText "!name!" "wails out in pain."

        call monster.cmd :monsterTakeHit "!%tile%.creature_id!" "!damage!"
        if !errorlevel! GEQ 0 (
            call monster.cmd :printMonsterActionText "!name!" "is embedded in the rock."
            call ui.cmd :displayCharacterExperience
        )
    ) else (
        set "is_earth_monster=0"
        if "!%creature%.sprite!"=="E" set "is_earth_monster=1"
        if "!%creature%.sprite!"=="X" set "is_earth_monster=1"
        if "!is_earth_monster!"=="1" (
            call dice.cmd :diceRoll 4 8
            set /a %monster%.hp+=!errorlevel!
        )
    )
)

set "%tile%.feature_id=%TILE_MAGMA_WALL%"
set "%tile%.field_mark=false"
set "has_light=false"
if "!%tile%.temporary_light!"=="true" set "has_light=true"
if "!%tile%.permanent_light!"=="true" set "has_light=true"
set "%tile%.permanent_light=!has_light!"
call dungeon.cmd :dungeonLiteSpot "coord"
set "built=0"
goto :spellBuildWallWhileLoop

::------------------------------------------------------------------------------
:: Replicating a monster
::
:: Arguments: %1 - The coordinates of the player
::            %2 - The direction to cast the spell in
:: Returns:   0 if a monster was able to be replicated
::            1 if there is no room for a new monster
::------------------------------------------------------------------------------
:spellCloneMonster
set "coord=%~1"
set "direction=%~2"

set "distance=0"
set "finished=false"

:spellCloneMonsterWhileLoop
if "!finished!"=="true" exit /b 1

call player.cmd :playerMovePosition "%direction%" "coord"
set /a distance+=1

for /f "tokens=1,2 delims=;" %%A in ("!coord!") do (
    set "tile=dg.floor[%%~A][%%~B]"
)

if !distance! GTR %config.treasure.objects_bolts_max_range% exit /b 1
if !%tile%.feature_id! GEQ %MIN_CLOSED_SPACE% exit /b 1

set "c_id=!%tile%.creature_id!"
if %c_id% GTR 1 (
    set "mosnters[%c_id%].sleep_count=0"
    call monster.cmd :monsterMultiply "!coord!" "!monsters[%c_id%].creature_id!" 0
    exit /b !errorlevel!
)
goto :spellCloneMonsterWhileLoop

::------------------------------------------------------------------------------
:: Moves the creature to a new location
::
:: Arguments: %1 - The monster_id of the monster being teleported
::            %2 - The maximum distance from the player to put the monster
::------------------------------------------------------------------------------
:spellTeleportAwayMonster
set "monster_id=%~1"
set "distance_from_player=%~2"
set "counter=0"
set "monster=monsters[%monster_id%]"

:spellTeleportAwayMonsterOuterWhileLoop
call :spellTeleportAwayMonsterGetRndCoords
set /a counter+=1
if !counter! GTR 9 (
    set "counter=0"
    set /a distance_from_player+=5
)
for /f "tokens=1,2 delims=;" %%A in ("!coord!") do (
    if !dg.floor[%%~A][%%~B].feature_id! LSS %MIN_CLOSED_SPACE% goto :spellTeleportAwayMonsterAfterOuterWhileLoop
    if "!dg.floor[%%~A][%%~B].creature_id!"=="0" goto :spellTeleportAwayMonsterAfterOuterWhileLoop
)
goto :spellTeleportAwayMonsterOuterWhileLoop

:spellTeleportAwayMonsterAfterOuterWhileLoop
set "%monster%.pos=!%monster%.pos.y!;!%monster%.pos.x!"
call dungeon.cmd :dungeonMoveCreatureRecord "%monster%.pos" "coord"
call dungeon.cmd :dungeonLiteSpot "%monster%.pos"

for /f "tokens=1,2 delims=;" %%A in ("!coord!") do (
    set "%monster%.pos.y=%%~A"
    set "%monster%.pos.x=%%~B"
)

set "%monster%.lit=false"
call dungeon.cmd :coordDistanceBetween "py.pos" "coord"
call monster.cmd :monsterUpdateVisibility "%monster_id%"
exit /b

:: The original equation was (2*distance_from_player+1)-(distance_from_player+1)
:: but this just equals distance_from_player so idk what was going on there
:spellTeleportAwayMonsterGetRndCoords
call rng.cmd :randomNumber %distance_from_player%
set "rnd_dist=!errorlevel!"
set /a coord.y=!%monster%.pos.y!+!rnd_dist!
set /a coord.x=!%monster%.pos.x!+!rnd_dist!
set "coord=!coord.y!;!coord.x!"
call ui.cmd :coordInBounds "coord"
if "!errorlevel!"=="1" goto :spellTeleportAwayMonsterGetRndCoords
exit /b

::------------------------------------------------------------------------------
:: Teleports the player adjacent to the spellcasting creature
::
:: Arguments: %1 - The coordinates of the monster
:: Returns:   None
::------------------------------------------------------------------------------
:spellTeleportPlayerTo
set "coord=%~1"
set "distance=1"
set "counter=0"

:spellTeleportPlayerToWhileLoop
call rng.cmd :randomNumber !distance!
set "rnd_dist=!errorlevel!"
for /f "tokens=1,2 delims=;" %%A in ("!coord!") do (
    set /a rnd_coord.y=%%~A+!rnd_dist!
    set /a rnd_coord.x=%%~B+!rnd_dist!
)
set "rnd_coord=!rnd_coord.y!;!rnd_coord.x!"

set /a counter+=1
if !counter! GTR 9 (
    set "counter=0"
    set /a distance+=1
)

set "break_while=0"
call dungeon.cmd :coordInBounds "rnd_coord" && set "break_while=1"
if !dg.floor[%rng_coord.y%][%rng_coord.x%].feature_id! LSS %MIN_CLOSED_SPACE% set "break_while=1"
if !dg.floor[%rng_coord.y%][%rng_coord.x%].creature_id! LSS 2 set "break_while=1"
if "!break_while!"=="1" goto :spellTeleportPlayerToAfterWhileLoop
goto :spellTeleportPlayerToWhileLoop

:spellTeleportPlayerToAfterWhileLoop
call dungeon.cmd :dungeonMoveCreatureRecord "py.pos" "rnd_coord"

call helpers.cmd :expandCoordName "py.pos"
for /L %%Y in (%py.pos.y_dec%,1,%py.pos.y_inc%) do (
    for /L %%X in (%py.pos.x_dec%,1,%py.pos.x_inc%) do (
        set "spot=%%Y;%%X"
        set "dg.floor[%%Y][%%X].temporary_light=false"
        call dungeon.cmd :dungeonLiteSpot "spot"
    )
)
call dungeon.cmd :dungeonLiteSpot "py.pos"
set "py.pos.y=%rng_coord.y%"
set "py.pos.x=%rng_coord.x%"
set "py.pos=%py.pos.y%;%py.pos.x%"

call ui.cmd :dungeonResetView
call monster.cmd :updateMonsters "false"
exit /b

::------------------------------------------------------------------------------
:: Teleport all creatures in a given direction away
::
:: Arguments: %1 - The coordinates of the player
::            %2 - The direction to move the monsters in
:: Returns:   0 if any monsters were teleported away
::            1 if there was nothing to teleport
::------------------------------------------------------------------------------
:spellTeleportAwayMonsterInDirection
set "coord=%~1"
set "direction=%~2"

set "distance=0"
set "teleported=1"
set "finished=false"

:spellTeleportAwayMonsterInDirectionWhileLoop
call player.cmd :playerMovePosition "%direction%" "coord"
set /a distance+=1

for /f "tokens=1,2 delims=;" %%A in ("!coord!") do (
    set "tile=dg.floor[%%~A][%%~B]"
)
if !distance! GTR %config.treasure.objects_bolts_max_range% exit /b !teleported!
if !%tile%.feature_id! GEQ %MIN_CLOSED_SPACE% exit /b !teleported!

set "t_id=!%tile%.creature_id!"
if %t_id% GTR 1 (
    set "monsters[%t_id%].sleep_count=0"
    call :spellTeleportAwayMonster "!%tile%.creature_id!" "%config.monsters.MON_MAX_SIGHT%"
    set "teleported=0"
)
goto :spellTeleportAwayMonsterInDirectionWhileLoop

::------------------------------------------------------------------------------
:: Delete all creatures within max sight distance except the Balrog
::
:: Arguments: None
:: Returns:   0 if any monster is killed
::            1 if there is no monster on screen that can be killed this way
::------------------------------------------------------------------------------
:spellMassGenocide
set "killed=1"

set mon_dec=%next_free_monster_id%-1
for /L %%A in (%mon_dec%,-1,%config.monsters.mon_min_index_id%) do (
    call :spellMassGenocideIfStatement "%%~A"
)
exit /b !killed!

:spellMassGenocideIfStatement
set "monster=monsters[%~1]"
set "c_id=!%monster%.creature_id!"
set "creature=creatures_list[%c_id%]"

if !%monster%.distance_from_player! LEQ %config.monsters.MON_MAX_SIGHT% (
    set /a "is_balrog=!%creature%.movement! & %config.monsters.move.cm_win%"
    if "!is_balrog!"=="0" (
        set "killed=0"
        call dungeon.cmd :dungeonDeleteMonster "%~1"
    )
)
exit /b

::------------------------------------------------------------------------------
:: Deletes all creatures of a specified type from the level except the Balrog
::
:: Arguments: None
:: Returns:   0 if any monster is killed
::            1 if there is no monster on screen that can be killed this way
::------------------------------------------------------------------------------
:spellGenocide
call ui_io.cmd :getTileCharacter "Which type of creature do you wish exterminated?" "creature_char"
if "!errorlevel!"=="1" exit /b 1

set "killed=1"

set /a mon_dec=%next_free_monster_id%-1
for /L %%A in (%mon_dec%,-1,%config.monsters.mon_min_index_id%) do (
    call :spellGenocideIfStatement "%%~A"
)
exit /b !killed!

:spellGenocideIfStatement
set "monster=monsters[%~1]"
set "c_id=!%monster%.creature_id!"
set "creature=creatures_list[%c_id%]"

if "!creature_char!"=="!%creature%.sprite!" (
    set /a "is_balrog=!%creature%.movement! & %config.monsters.move.cm_win%"
    if "!is_balrog!"=="0" (
        set "killed=0"
        call dungeon.cmd :dungeonDeleteMonster "%~1"
    ) else (
        call ui_io.cmd :printMessage "The !%creature%.name! is unaffected."
    )
)
exit /b

::------------------------------------------------------------------------------
:: Changes the speed of all monsters on the screen except the Balrog
::
:: Arguments: %1 - The difference between original speed and desired speed
:: Returns:   0 if a visible monster was affected
::            1 if a monster that would have been affected was not visible
::              or if there is no monster to affect
::------------------------------------------------------------------------------
:spellSpeedAllMonsters
set "speedy=1"

set /a mon_dec=%next_free_monster_id%-1
for /L %%A in (%mon_dec%,-1,%config.monsters.mon_min_index_id%) do (
    call :spellSpeedAllMonstersForLoop "%~1" "%%~A"
)
exit /b

:spellSpeedAllMonstersForLoop
set "monster=monsters[%~2]"
set "c_id=!%monster%.creature_id!"
set "creature=creatures_list[%c_id%]"

call monster.cmd :monsterNameDescription "!%creature%.name!" "!%monster%.lit!" "name"
if !%monster%.distance_from_player! GTR %config.monsters.MON_MAX_SIGHT% exit /b
call dungeon_los.cmd :los "!py.pos!" "!%monster%.pos!" || exit /b

if %~1 GTR 0 (
    set /a %monster%.speed+=%~1
    set "%monster%.sleep_count=0"

    if "!%monster%.lit!"=="true" (
        set "speedy=0"
        call monster.cmd :printMonsterActionText "!name!" "starts moving faster."
    )
) else (
    call rng.cmd :randomNumber %MON_MAX_LEVELS%
    if !errorlevel! GTR !%creature%.level! (
        set /a %monster%.speed+=%~1
        set "%monster%.sleep_count=0"

        if "!%monster%.lit!"=="true" (
            set "speedy=0"
            call monster.cmd :printMonsterActionText "!name!" "starts moving slower."
        )
    ) else (
        set "%monster%.sleep_count=0"
        call monster.cmd :printMonsterActionText "!name!" "is unaffected."
    )
)
exit /b

::------------------------------------------------------------------------------
:: Puts all creatures on screen to sleep unless they are sleepless
::
:: Arguments: None
:: Returns:   0 if a monster was put to sleep
::            1 if the monster has the cd_no_sleep flag set
::------------------------------------------------------------------------------
:spellSleepAllMonsters
set "asleep=1"

set /a mon_dec=%next_free_monster_id%-1
for /L %%A in (%mon_dec%,-1,%config.monsters.mon_min_index_id%) do (
    call :spellSleepAllMonstersForLoop "%%~A"
)
exit /b !asleep!

:spellSleepAllMonstersForLoop
set "monster=monsters[%~1]"
set "c_id=!%monster%.creature_id!"
set "creature=creatures_list[%c_id%]"

call monster.cmd :monsterNameDescription "!%creature%.name!" "!%monster%.lit!" "name"
if !%monster%.distance_from_player! GTR %config.monsters.MON_MAX_SIGHT% exit /b
call dungeon_los.cmd :los "!py.pos!" "!%monster%.pos!" || exit /b

set "is_unaffected=0"
call rng.cmd :randomNumber %MON_MAX_LEVELS%
if !errorlevel! LSS !%creature_level! set "is_unaffected=1"
set /a "is_sleepless=!%creature%.defenses! & %config.monsters.defense.cd_no_sleep%"
if not "!is_sleepless!"=="0" set "is_unaffected=1"
if "!is_unaffected!"=="1" (
    if "!%monster%.lit!"=="true" (
        if not "!is_sleepless!"=="0" (
            set /a "creature_recall[%c_id%].defenses|=%config.monsters.defense.cd_no_sleep%"
        )
        call monster.cmd :printMonsterActionText "!name!" "is unaffected."
    )
) else (
    set "%monster%.sleep_count=500"
    if "!%monster%.lit!"=="true" (
        set "asleep=0"
        call monster.cmd :printMonsterActionText "!name!" "falls asleep."
    )
)
exit /b

::------------------------------------------------------------------------------
:: Polymorph all visible creatures except the Balrog into other monsters
::
:: Arguments: None
:: Returns:   0 if new monsters are able to be placed
::            1 if no creatures other than the Balrog are visible
::------------------------------------------------------------------------------
:spellMassPolymorph
set "morphed=1"
set /a mon_dec=%next_free_monster_id%-1

for /L %%A in (%mon_dec%,-1,%config.monsters.mon_min_index_id%) do (
    call :spellMassPolymorphForLoop "%%~A"
)
exit /b !morphed!

:spellMassPolymorphForLoop
set "monster=monsters[%~1]"
set "c_id=!%monster%.creature_id!"
set "creature=creatures_list[%c_id%]"

if !%monster%.distance_from_player! LEQ %config.monsters.MON_MAX_SIGHT% (
    set /a "is_winning=!%creature%.movement! & %config.monsters.move.cm_win%"
    if "!is_winning!"=="0" (
        set "coord.y=!%monster%.pos.y!"
        set "coord.x=!%monster%.pos.x!"
        set "coord=!coord.y!;!coord.x!"

        call dungeon.cmd :dungeonDeleteMonster "%~1"

        set /a mon_level_range=!monster_levels[%MON_MAX_LEVELS%]! - !monster_levels[0]!
        call rng.cmd :randomNumber !mon_level_range!
        set /a rnd_level=!errorlevel! - 1 + !monster_levels[0]!
        call monster_manager.cmd :monsterPlaceNew "!coord!" "!rnd_level!" "false"
        set "morphed=!errorlevel!"
    )
)
exit /b

:spellDetectEvil
exit /b

:spellChangePlayerHitPoints
exit /b

:earthquakeHitsMonster
exit /b

:spellEarthquake
exit /b

:spellCreateFood
exit /b

:spellDispelCreature
exit /b

:spellTurnUndead
exit /b

:spellWardingGlyph
exit /b

:spellLoseSTR
exit /b

:spellLoseINT
exit /b

:spellLoseWIS
exit /b

:spellLoseDEX
exit /b

:spellLoseCON
exit /b

:spellLoseCHR
exit /b

:spellLoseEXP
exit /b

:spellSlowPoison
exit /b

:replaceSpot
exit /b

:spellDestroyArea
exit /b

:spellEnchantItem
exit /b

:spellRemoveCurseFromAllWornItems
exit /b

:spellRestorePlayerLevels
exit /b

