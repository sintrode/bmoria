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

:wizardDropRandomItems
exit /b

:wizardJumpLevel
exit /b

:wizardGainExperience
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

