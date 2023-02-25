@echo off
call %*
exit /b

::------------------------------------------------------------------------------
:: Print out strings, filling up lines as we go and implementing word wrap
:: while keeping in mind that roff_buffer can only hold 80 characters
::
:: Arguments: %1 - The string to print out
:: Returns:   None
::------------------------------------------------------------------------------
:memoryPrint
:: If the string is just '\n' by itself, we're done printing
if "%~1"=="\n" (
    call ui_io.cmd :putStringClearToEOF "CNIL" "!roff_print_line!;0"
    set /a roff_print_line+=1
    exit /b
)

REM Add %1 to the buffer
set "roff_buffer=!roff_buffer!%~1"

REM If %1 contains a '\n', then split the string there and putStringClearToEOF
REM it, setting the new buffer to the back half of %1.
if not "!roff_buffer!"=="!roff_buffer:\n=!" (
    set "back_half=!roff_buffer:*\n=!"
    for /f "delims=" %%A in ("!back_half!") do set "front_half=!roff_buffer:%%~A=!"
    call ui_io.cmd :putStringClearToEOF "!front_half!" "!roff_print_line!;0"
    set /a roff_print_line+=1
    set "roff_buffer=!back_half!"
)

REM If the buffer length is greater than 80, move characters from the end of
REM the buffer string to the start of a temp string, then putStringClearToEOF
REM the buffer and then replace the buffer string with the temp string.
call helpers.cmd :getLength "!roff_buffer!" buffer_length
if !buffer_length! GEQ 80 (
    for /L %%A in (!buffer_length!,-1,79) do (
        set "temp_string=!roff_buffer:~-1!!temp_string!"
        set "roff_buffer=!roff_buffer:~0,-1!"
    )
    call :dropCharsUntilSpace
    call ui_io.cmd :putStringClearToEOF "!roff_buffer!" "!roff_print_line!;0"
    set /a roff_print_line+=1
    set "roff_buffer=!temp_string!"
)
exit /b

:: Remove the rightmost characters until we are at a space
:dropCharsUntilSpace
if not "!roff_buffer:~-1!"==" " (
    set "temp_string=!roff_buffer:~-1!!temp_string!"
    set "roff_buffer=!roff_buffer:~0,-1!"
    goto :dropCharsUntilSpace
) else (
    set "roff_buffer=!roff_buffer:~0,-1!"
)
exit /b

:memoryMonsterKnown
exit /b

:memoryWizardModeInit
exit /b

:memoryConflictHistory
exit /b

:memoryDepthFoundAt
exit /b

:memoryMovement
exit /b

:memoryKillPoints
exit /b

:memoryMagicSkills
exit /b

:memoryKillDifficulty
exit /b

:memorySpecialAbilities
exit /b

:memoryWeaknesses
exit /b

:memoryAwareness
exit /b

:memoryLootCarried
exit /b

:memoryAttackNumberAndDamage
exit /b

:memoryRecall
exit /b

:recallMonsterAttributes
exit /b

