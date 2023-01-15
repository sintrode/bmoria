@echo off
call %*
exit /b

::------------------------------------------------------------------------------
:: Prints the gravestone of the character
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:printTomb
call game_files.cmd :displayDeathFile "%config.files.death_tomb%"
call :centerAndPrint "%py.misc.name%" 6

if "%game.total_winner%"=="false" (
    call player.cmd :playerRankTitle player_title
    set "royal_title=!classes[%py.misc.class_id%].title!"
) else (
    set "player_title=Magnificent"
    call player.cmd :isMale
    if "!errorlevel!"=="0" (
        set "royal_title=*King*"
    ) else (
        set "royal_title=*Queen*"
    )
)
call :centerAndPrint "!player_title!" 8
call :centerAndPrint "!royal_title!" 10
call ui_io.cmd :putString "%py.misc.level%" "11;30"
call :centerAndPrint "%py.misc.exp% Exp" 12
call :centerAndPrint "%py.misc.au% Au" 13
call ui_io.cmd :putString "%dg.current_level%" "14;34"
call :centerAndPrint "%game.character_died_from%" 16

call helpers.cmd :humanDateString day
call :centerAndPrint "%day%" 17

:retry
call ui_io.cmd :flushInputBuffer
call ui_io.cmd :putString "(Q to abort, space to print on screen)" "23;1"
call ui_io.cmd :putString "Character record?" "22;1"

set "str="
call ui_io.cmd :getStringInput "%str%" "22;18" 60
if "!errorlevel!"=="0" (
    for /L %%A in (0,1,33) do (
        call identification.cmd :itemSetAsIdentified "!py.inventory[%%A].category_id!" "!py.inventory[%%A].sub_category_id!"
        call identification.cmd :spellItemIdentifyAndRemoveRandomInscription "py.inventory[%%A]"
    )

    call player.cmd :playerRecalculateBonuses

    if "!str:~0,1!" NEQ "0" (
        call game_files.cmd :outputPlayerCharacterToFile "!str!"
        if "!errorlevel!"=="1" goto :retry
    ) else (
        call ui_io.cmd :clearScreen
        call ui.cmd :printCharacter
        call ui_io.cmd :putString "Type Q to skip the inventory." "23;1"

        call ui_io.cmd :getKeyInput key
        if /I "!key!" NEQ "Q" (
            call ui_io.cmd :clearScreen
            call ui_io.cmd :printMessage "You are using:"
            call ui_inventory.cmd :displayEquipment "true" 0
            call ui_io.cmd :printMessage "CNIL"
            call ui_io.cmd :printMessage "You are carrying:"
            call ui_io.cmd :clearToBottom 1
            call ui_inventory.cmd :displayInventoryItems 0 %py.pack.unique_items% "true" 0 "CNIL"
            call ui_io.cmd :printMessage "CNIL"
        )
    )
)

exit /b

::------------------------------------------------------------------------------
:: Display a crown to celebrate the player's victory
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:printCrown
call game_files :displayDeathFile "%config.files.death_royal%"
call player.cmd :isMale
if "!errorlevel!"=="0" (
    call ui_io.cmd :putString "KING" "17;45"
) else (
    call ui_io.cmd :putString "QUEEN" "17;45"
)
call ui_io.cmd :flushInputBuffer
call ui_io.cmd :waitForContinueKey 23
exit /b

::------------------------------------------------------------------------------
:: Label the player as royalty
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:be_regal
set "dg.current_level=0"
set "game.character_died_from=Ripe Old Age"
call spells.cmd :spellRestorePlayerLevels

set /a py.misc.level+=%player_max_level%
set /a py.misc.au+=250000
set /a py.misc.max_exp+=5000000
set "py.misc.exp=%py.misc.max_exp%"

call :printCrown
exit /b

::------------------------------------------------------------------------------
:: Handle the gravestone and top-twenty routines
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:endGame
call ui_io.cmd :printMessage "CNIL"
call ui_io.cmd :flushInputBuffer

:: If the game was saved, then save sets turn back to -1, which prevents the
:: tomb from being displayed.
if %dg.game_turn% GEQ 0 (
    if "%game.total_winner%"=="true" (
        call :be_regal
    )
    call :printTomb
)

:: Save the memory
if "%game.character_generated%"=="true" (
    if "%game.character_saved%"=="false" (
        call game_save.cmd :saveGame
    )
)

:: Add score to score file if applicable. Clearing game.character_saved will
:: prevent :getKeyInput from recursively calling :endGame
if "%game.character_generated%"=="true" (
    set "game.character_saved=false"
    call scores.cmd :recordNewHighScore
    call scores.cmd :showScoresScreen
)
call ui_io.cmd :eraseLine "23;1"
call game.cmd :exitProgram
exit /b

::------------------------------------------------------------------------------
:: Centers and prints text on a specified row
::
:: Arguments: %1 - The text to print
::            %2 - The row to print the text on
:: Returns:   None
::------------------------------------------------------------------------------
:centerAndPrint
set "text=%~1"
call helpers.cmd :getLength "!text!" text_length
set /a text_x=26-text_length/2
call ui_io.cmd :putString "!text!" "%~2;!text_x!"
exit /b