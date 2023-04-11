@echo off
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

:wizardSummonMonster
exit /b

:wizardLightUpDungeon
exit /b

:wizardCharacterAdjustment
exit /b

:wizardRequestObjectId
exit /b

:wizardGenerateObject
exit /b

:wizardCreateObjects
exit /b

