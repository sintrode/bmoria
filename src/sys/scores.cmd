@echo off
call %*
exit /b

::------------------------------------------------------------------------------
:: Stores an M or F based on the character's gender
:: TODO: Merge with the other subroutine that does this and refactor other
:: subroutines that call it to pass an argument because we can't return strings
::
:: Arguments: %1 - The variable to store the response in
:: Returns:   None
::------------------------------------------------------------------------------
:highScoreGenderLabel
call player.cmd :playerIsMale
if "!errorlevel!"=="0" (
    set "%~1=M"
) else (
    set "%~1=F"
)
exit /b

::------------------------------------------------------------------------------
:: Enters a player's name on the top twenty list
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:recordNewHighScore
call ui._iocmd :clearScreen

if not "%game.noscore%"=="0" exit /b
if "%panic_save%"=="true" (
    call ui_io.cmd :printMessage "Sorry, scores for games restored from panic save files are not saved."
    exit /b
)

call player.cmd :playerCalculateTotalPoints
set "new_entry.points=!errorlevel!"
set "new_entry.birth_date=%py.misc.date_of_birth%"
set "new_entry.uid=0"
set "new_entry.mhp=%py.misc.max_hp%"
set "new_entry.chp=%py.misc.current_hp%"
set "new_entry.dungeon_depth=%dg.current_level%"
set "new_entry.level=%py.misc.level%"
set "new_entry.deepest_dungeon_depth=%py.misc.max_dungeon_depth%"
call :highScoreGenderLabel "new_entry.gender"
set "new_entry.race=%py.misc.race_id%"
set "new_entry.character_class=%py.misc.class_id%"
set "new_entry.name=%py.misc.name%"

set "tmp_died=%game.character_died_from%"
set "leading_article=0"
if "%tmp_died:~0,3%"=="an " set "leading_article=1"
if "%tmp_died:~0,2%"=="a " set "leading_article=1"
if "%leading_article%"=="1" (
    for /f "tokens=1,*" %%A in ("%tmp_died%") do (
        set "new_entry.died_from=%%~B"
    )
)

certutil -encodehex "%config.files.scores%" "%config.files.scores%.hex" >nul 2>&1
if not exist "%config.files.scores%.hex" (
    call ui_io.cmd :printMessage "Error locating scores file %config.files.scores%."
    call ui_io.cmd :printMessage "CNIL"
    exit /b
)

<"%config.files.scores%.hex" set /p "first_score_hex_line="
for /f "tokens=2-4" %%A in ("%first_score_hex_line%") do (
    set "version_maj=%%~A"
    set "version_min=%%~B"
    set "patch_level=%%~C"
)

for %%A in ("%config.files.scores%") do (
    if "%~zA"=="0" (
        <nul set /p ".=0000 " >"%config.files.scores%.hex"

        call scores.cmd :toHex "%CURRENT_VERSION_MAJOR%"
        <nul set /p ".= !hex!" >"%config.files.scores%.hex"

        call scores.cmd :toHex "%CURRENT_VERSION_MINOR%"
        <nul set /p ".= !hex!" >"%config.files.scores%.hex"

        call scores.cmd :toHex "%CURRENT_VERSION_PATCH%"
        <nul set /p ".= !hex!" >"%config.files.scores%.hex"
    ) else (
        call game.cmd :validGameVersion "%version_maj%" "%version_min%" "%patch_level%"
        if "!errorlevel!"=="1" exit /b
    )
)

call game_save.cmd :setFileptr "%config.files.scores%.hex"
set "i=0"
set "curpos=0"
set "current_byte=0"
call game_save.cmd :readHighScore "old_entry"

:recordNewHighScoreWhileLoop
if !new_entry.points! GEQ !old_entry.points! goto :recordNewHighScoreAfterWhileLoop

set /a i+=1
if !i! GEQ %MAX_HIGH_SCORE_ENTRIES% exit /b
set "curpos=!current_byte!"
call game_save.cmd :readHighScore "old_entry"
goto :recordNewHighScoreWhileLoop

:recordNewHighScoreAfterWhileLoop
call game_save.cmd :countBytesInSaveFile
if "!current_byte!"=="!total_bytes!" (
    call :saveHighScore "new_entry"
) else (
    for %%A in (points birth_date uid mhp chp dungeon_depth level
                deepest_dungeon_depth gender race character_class
                name died_from) do (
        set "entry.%%~A=!new_entry.%%~A!"
    )

    call :recordNewHighScoreSecondWhileLoop
    call game_save.cmd :saveHighScore "entry"
)
exit /b

:: TODO: Confirm that this isn't just some convoluted way of putting the
:: newest score at the end
:recordNewHighScoreSecondWhileLoop
if "!current_byte!"=="!total_bytes!" exit /b
call game_save.cmd :saveHighScore "entry"
for %%A in (points birth_date uid mhp chp dungeon_depth level
            deepest_dungeon_depth gender race character_class
            name died_from) do (
    set "entry.%%~A=!old_entry.%%~A!"
)
call game_save.cmd :readHighScore "old_entry"
goto :recordNewHighScoreSecondWhileLoop

::------------------------------------------------------------------------------
:: Display the game's high scores
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:showScoresScreen
certutil -f -encodehex "%config.files.scores%" "%config.files.scores%.hex" >nul 2>&1
if not exist "%config.files.scores%.hex" (
    call :ui_io.cmd :printMessage "Error opening score file '%config.files.scores%'."
    call :ui_io.cmd :printMessage "CNIL"
    exit /b
)

<"%config.files.scores%.hex" set /p "first_score_hex_line="
for /f "tokens=2-4" %%A in ("%first_score_hex_line%") do (
    set "version_maj=%%~A"
    set "version_min=%%~B"
    set "patch_level=%%~C"
)
call game.cmd :validGameVersion "%version_maj%" "%version_min%" "%patch_level%"
if "!errorlevel!"=="1" (
    call ui_io.cmd :printMessage "Sorry, this score files is from a different version of bMoria."
    call ui_io.cmd :printMessage "CNIL"
    exit /b
)

call game_save.cmd :setFileptr "%config.files.scores%.hex"
set "current_byte=0"
call game_save.cmd :readHighScore "score"
set "rank=1"

:showScoresScreenOuterWhile
if "!current_byte!"=="!total_bytes!" exit /b
set "i=1"
call ui_io.cmd :clearScreen
:showScoresScreenInnerWhile
if not "!current_byte!"=="!total_bytes!" (
    if !i! LSS 21 (
        set "msg="
        call :sprintf msg "!rank!" -4
        call :sprintf msg "!score.points!" 8
        call :sprintf msg "!score.name!" -19
        call :sprintf msg "!score.gender!" 1
        for /f "tokens=1,2" %%A in ("!score.race! !score.character_class!") do (
            call :sprintf msg "!character_races[%%~A].name!" -10
            call :sprintf msg "!classes[%%~B].title!" -7
        )
        call :sprintf msg "!score.level!" 3
        call :sprintf msg "!score.died_from!" -22
    ) else (
        goto :showScoresScreenAfterInnerWhile
    )
) else (
    goto :showScoresScreenAfterInnerWhile
)
set /a i+=1
call ui_io.cmd :putStringClearToEOL "!msg!" "!i!;0"
set /a rank+=1
call game_save.cmd :readHighScore "score"
goto :showScoresScreenInnerWhile

:showScoresScreenAfterInnerWhile
call ui_io.cmd :putStringClearToEOL "Rank  Points Name              Sex Race       Class  Lvl Killed By" "0;0"
call ui_io.cmd :eraseLine "1;0"
call ui_io.cmd :putStringClearToEOL "[ press any key to continue ]" "23;23"
call ui_io.cmd :getKeyInput
if "!key!"=="Q" exit /b
goto :showScoresScreenOuterWhile

:sprintf
set "disp=%~2"
if %~3 LSS 0 (
    for /L %%A in (%~3,-1,-1) do (
        set "disp=!disp! "
    )
    set "disp=!disp:~0,%~3!"
) else (
    for /L %%A in (1,1,%~3) do (
        set "disp= !disp!"
    )
    set "disp=!disp:~-%~3!"
)
set "%~1=!%~1!!disp!"
exit /b

::------------------------------------------------------------------------------
:: Calculates the total number of points earned
::
:: Arguments: None
:: Returns:   The player's score
::------------------------------------------------------------------------------
:playerCalculateTotalPoints
set /a total=%py.misc.max_exp% + (100 * %py.misc.max_dungeon_depth%)
set /a total+=(%py.misc.au% / 100)
for /L %%A in (0,1,33) do (
    call store_inventory.cmd :storeItemValue "py.inventory[%%A]"
    set /a total+=!errorlevel!
)
set /a total+=(%dg.current_level% * 50)

if %py.max_score% GTR !total! exit /b %py.max_score%
exit /b !total!