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

:castSpellGetId
exit /b

:spellDetectTreasureWithinVicinity
exit /b

:spellDetectObjectsWithinVicinity
exit /b

:spellDetectTrapsWithinVicinity
exit /b

:spellDetectSecretDoorssWithinVicinity
exit /b

:spellDetectInvisibleCreaturesWithinVicinity
exit /b

:spellLightArea
exit /b

:spellDarkenArea
exit /b

:dungeonLightAreaAroundFloorTile
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

