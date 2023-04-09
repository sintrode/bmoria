::------------------------------------------------------------------------------
:: In case you were wondering why all of the coordinates in the game are in Y;X
:: format, it's specifically for this script. There's a non-zero chance that
:: everything has an off-by-one error since ncurses thinks the top-left corner
:: is 0,0 and VT100 thinks the top-left corner is 1,1 but we can adjust values
:: as necessary
::------------------------------------------------------------------------------
@echo off
call %*
exit /b

::------------------------------------------------------------------------------
:: Originally a bunch of stuff for ncurses that prevents people from inputting
:: CTRL+C or displaying entered characters. We're not going to do any of that
:: stuff because of how we're taking input, so this is super short.
::------------------------------------------------------------------------------
:moriaTerminalInitialize
set "curses_on=true"
exit /b

::------------------------------------------------------------------------------
:: Ensure that the window is at least 80x24. We're going to have to run the
:: game via conhost because SOMEBODY decided that Windows Terminal doesn't need
:: to respect the `mode con` command. But on the bright side, Terminal is at
:: least 120x30, so it should be fine unless the player resizes it.
::
:: Arguments: None
:: Returns:   0 if the screen is at least 80x24
::            1 if the screen is too small for some reason
::------------------------------------------------------------------------------
:terminalInitialize
set "lines="
set "cols="
for /f "skip=2 tokens=2" %%A in ('mode con') do (
    if not defined lines (
        set "lines=%%A"
    ) else if not defined cols (
        set "cols=%%A"
    )
)

set "is_too_small=0"
if %lines% LSS 24 set "is_too_small=1"
if %cols% LSS 80 set "is_too_small=1"
if "!is_too_small!"=="1" (
    echo Screen too small for Moria.
    exit /b 1
)

call :moriaTerminalInitialize
cls
exit /b 0

::------------------------------------------------------------------------------
:: Dump the buffer and flush, moving the cursor to the bottom left
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:terminalRestore
if "!curses_on!"=="false" exit /b

call :putQIO
cls
set /a line_dec=%lines%-1
echo %ESC%[%line_dec%;1H
set "line_dec="
exit /b

::------------------------------------------------------------------------------
:: Engage the alternate screen buffer. Thankfully, we never have to run this
:: while on the other screen or else I'd have no way of doing this.
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:terminalSaveScreen
echo %ESC%[?1049h
exit /b

::------------------------------------------------------------------------------
:: Restore from the alternate screen buffer
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:terminalRestoreScreen
echo %ESC%[?1049l
exit /b

::------------------------------------------------------------------------------
:: Technically display a BEL character, but actually make the computer beep.
:: Can be disabled in the settings.
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:terminalBellSound
call :putQIO

:: There's probably a more elegant way to do this
if "%config.options.error_beep_sound%"=="true" echo 
exit /b 0

::------------------------------------------------------------------------------
:: This was needed more in the C++ code because ncurses manipulates values
:: without displaying anything unless refresh() is called, but we're doing
:: everything directly, so there's no need to read from a buffer since there
:: isn't one.
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:putQIO
set "screen_has_changed=true"
exit /b

::------------------------------------------------------------------------------
:: Don't keep user input in the input buffer. I'm not sure this is needed tbh.
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:flushInputBuffer
if not "!eof_flag!"=="0" exit /b
call :checkForNonBlockingKeyPress 0
exit /b

::------------------------------------------------------------------------------
:: Clears the screen, printing an extra line first if necessary
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:clearScreen
if "!message_ready_to_print!"=="true" call :printMessage "CNIL"
cls
exit /b

::------------------------------------------------------------------------------
:: Clears all rows from the specified row down
::
:: Arguments: %1 - The first row to clear
:: Returns:   None
::------------------------------------------------------------------------------
:clearToBottom
echo %ESC%[%~1;1H%ESC%[0J
exit /b

::------------------------------------------------------------------------------
:: Move the location of the cursor. We're using set /p instead of echo so that
:: we don't end up on the next line, and the . is in front of the = purely for
:: syntax highlighting reasons; it isn't necessary.
::
:: Arguments: %1 - A string in "Y;X" format
:: Returns:   None
::------------------------------------------------------------------------------
:moveCursor
<nul set /p ".=%ESC%[%~1H"
exit /b

::------------------------------------------------------------------------------
:: Place a specified character at given coordinates
::
:: Arguments: %1 - The character to display
::            %2 - The coordates to place the character at
:: Returns:   None
::------------------------------------------------------------------------------
:addChar
<nul set /p ".=%ESC%[%~2H%~1"
exit /b

::------------------------------------------------------------------------------
:: Display text on the screen
::
:: Arguments: %1 - The string to display
::            %2 - The coordinates to place the text
:: Returns:   None
::------------------------------------------------------------------------------
:putString
set "out_str=%~1"

:: Truncate the string to 79 characters if necessary
set "out_str=!out_str:~0,79!"
<nul set /p ".=%ESC%[%~2H%~1"
exit /b

:putStringClearToEOL
exit /b

:eraseLine
exit /b

:panelMoveCursor
exit /b

:panelPutTile
exit /b

:currentCursorPosition
exit /b

:messageLinePrintMessage
exit /b

:messageLineClear
exit /b

:printMessage
exit /b

:printMessageNoCommandInterrupt
exit /b

:getKeyInput
exit /b

:getCommand
exit /b

:getTileCharacter
exit /b

:getMenuItemId
exit /b

:getStringInput
exit /b

:getInputConfirmation
exit /b

:getInputConfirmationWithAbort
exit /b

:waitForContinueKey
exit /b

:checkForNonBlockingKeyPress
exit /b

:getDefaultPlayerName
exit /b

:topen
exit /b

:tilde
exit /b

:checkFilePermissions
exit /b

