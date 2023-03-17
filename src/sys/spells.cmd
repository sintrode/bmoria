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

:spellMapCurrentArea
exit /b

:spellIdentifyItem
exit /b

:spellAggravateMonsters
exit /b

:spellSurroundPlayerWithTraps
exit /b

:spellSurroundPlayerWithDoors
exit /b

:spellDestroyAdjacentDoorsTraps
exit /b

:spellDetectMonsters
exit /b

:spellLightLineTouchesMonster
exit /b

:spellLightLine
exit /b

:spellStarlite
exit /b

:spellDisarmAllInDirection
exit /b

:spellGetAreaAffectFlags
exit /b

:printBoltStrikesMonsterMessage
exit /b

:spellFireBoltTouchesMonster
exit /b

:spellFireBolt
exit /b

:spellFireBall
exit /b

:spellBreath
exit /b

:spellRechargeItem
exit /b

:spellChangeMonsterHitPoints
exit /b

:spellDrainLifeFromMonster
exit /b

:spellSpeedMonster
exit /b

:spellConfuseMonster
exit /b

:spellSleepMonster
exit /b

:spellWallToMud
exit /b

:spellDestroyDoorsTrapsInDirection
exit /b

:spellPolymorphMonster
exit /b

:spellBuildWall
exit /b

:spellCloneMonster
exit /b

:spellTeleportAwayMonster
exit /b

:spellTeleportPlayerTo
exit /b

:spellTeleportAwayMonsterInDirection
exit /b

:spellMassGenocide
exit /b

:spellGenocide
exit /b

:spellSpeedAllMonsters
exit /b

:spellSleepAllMonsters
exit /b

:spellMassPolymorph
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

