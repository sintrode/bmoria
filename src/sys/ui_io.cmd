::------------------------------------------------------------------------------
:: In case you were wondering why all of the coordinates in the game are in Y;X
:: format, it's specifically for this script. There's a non-zero chance that
:: everything has an off-by-one error since ncurses thinks the top-left corner
:: is 0,0 and VT100 thinks the top-left corner is 1,1 but we can adjust values
:: as necessary
::------------------------------------------------------------------------------
call %*
exit /b

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

::------------------------------------------------------------------------------
:: Clear a line and display a message on it
::
:: Arguments: %1 - The string to display
::            %2 - The coordinates to place the text
:: Returns:   None
::------------------------------------------------------------------------------
:putStringClearToEOL
for /f "tokens=1,2 delims=;" %%A in ("%~2") do (
    if "%%~B"=="%MSG_LINE%" (
        if "!message_ready_to_print!"=="true" (
            call :printMessage "CNIL"
        )
    )
)

<nul set /p ".=%ESC%[%~2H%ESC%[0K"
call :putString %*
exit /b

::------------------------------------------------------------------------------
:: Clear a line of text
::
:: Arguments: %1 - The coordinates of the line to clear
:: Returns:   None
::------------------------------------------------------------------------------
:eraseLine
for /f "tokens=1,2 delims=;" %%A in ("%~1") do (
    if "%%~B"=="%MSG_LINE%" (
        if "!message_ready_to_print!"=="true" (
            call :printMessage "CNIL"
        )
    )
)

<nul set /p ".=%ESC%[%~1H%ESC%[0K"
exit /b

::------------------------------------------------------------------------------
:: Moves the cursor to a relative Y;X position
::
:: Arguments: %1 - The new coordinates of the cursor
:: Returns:   None
::------------------------------------------------------------------------------
:panelMoveCursor
for /f "tokens=1,2 delims=;" %%A in ("%~1") do (
    set /a coord.y=%%~A-%dg.panel.row_prt%, coord.x=%%~B-%dg.panel_col_prt%
)
<nul set /p ".=%ESC%[%coord.y%;%coord.x%H"
exit /b

::------------------------------------------------------------------------------
:: Moves the cursor to a relative Y;X position and displays a character
::
:: Arguments: %1 - The character to display
::            %2 - The new coordinates of the cursor
:: Returns:   None
::------------------------------------------------------------------------------
:panelPutTile
for /f "tokens=1,2 delims=;" %%A in ("%~2") do (
    set /a coord.y=%%~A-%dg.panel.row_prt%, coord.x=%%~B-%dg.panel_col_prt%
)
<nul set /p ".=%ESC%[%coord.y%;%coord.x%H%~1"
exit /b

::------------------------------------------------------------------------------
:: Print a line of text to the message line, clearing the line first
::
:: Arguments: %1 - The message to display
:: Returns:   None
::------------------------------------------------------------------------------
:messageLinePrintMessage
:: Save the current cursor position
echo %ESC%7

set "message=%~1"
set "message=!message:~0,79!"
<nul set /p ".=%ESC%[0;0H%ESC%[0K!message!"

:: Restore the cursor position
echo %ESC%8
exit /b

::------------------------------------------------------------------------------
:: Clears the top line for later use
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:messageLineClear
echo %ESC%7
<nul set /p ".=%ESC%[0;0H%ESC%[0J"
echo %ESC%8
exit /b

::------------------------------------------------------------------------------
:: Output messages to the top of the screen
::
:: Arguments: %1 - The message to display
:: Returns:   None
::------------------------------------------------------------------------------
:printMessage
set "new_len=0"
set "old_len=0"
set "combine_messages=false"

if "!message_ready_to_print!"=="true" (
    call helpers.cmd :getLength "!messages[%last_message_id%]!" old_len
    set /a old_len+=1

    if not "%~1"=="" (
        call helpers.cmd :getLength "%~1" new_len
    ) else (
        set "new_len=0"
    )

    set "merge_unnecessary=0"
    if "%~1"=="" set "merge_unnecessary=1"
    set /a msg_total=!new_len! + !old_len! + 2
    if !msg_total! GEQ 73 set "merge_unnecessary=1"
    if "!merge_unnecessary!"=="1" (
        if !old_len! GTR 73 set "old_len=73"
        call :putString " -more-" "%MSG_LINE%;!old_len!"
        call :getKeyInput dummy
    ) else (
        set "combine_messages=true"
    )
)

if "!combine_messages!"=="false" call :eraseLine "%MSG_LINE%;0"

if "%~1"=="" (
    set "message_ready_to_print=false"
    exit /b
)

set "game.command_count=0"
set "message_ready_to_print=true"

:: If the new message and old message are short enough, put them on the same line
if "!combine_messages!"=="true" (
    set /a old_len_inc=!old_len!+2
    call :putString "%~1" "%MSG_LINE%;!old_len_inc!"
    set "messages[%last_message_id%]=!messages[%last_message_id%]! %~1"
) else (
    call :messageLinePrintMessage "%~1"
    set /a last_message_id+=1
    if !last_message_id! GEQ %MESSAGE_HISTORY_SIZE% set "last_message_id=0"

    set "tmp_msg=%~1"
    set "tmp_msg=!tmp_msg:~0,79!"
    set "messages[!last_message_id!]=!tmp_msg!"
)
exit /b

::------------------------------------------------------------------------------
:: Display a message without interrupting a counted command
::
:: Arguments: %1 - The message to display
:: Returns:   None
::------------------------------------------------------------------------------
:printMessageNoCommandInterrupt
set "tmp_count=%game.command_count%"
call :printMessage "%~1"
set "game.command_count=%tmp_count%"
set "tmp_count="
exit /b

::------------------------------------------------------------------------------
:: Returns a single character input from the terminal.
::
:: Arguments: %1 - The variable to store the character in
:: Returns:   None
:: Thanks:    https://gist.github.com/Grub4K/2d3f5875c488164b44454cbf37deae80
::------------------------------------------------------------------------------
:getKeyInput
set "game.command_count=0"
set "key="
for /f "delims=" %%A in ('xcopy /w "!comspec!" "!comspec!" 2^>nul') do (
    if not defined key set "key=%%A^!"
)
if !key:~-1!==^^ (
    set "key=^"
) else set "key=!key:~-2,1!"
set "%~1=!key:~0,1!"
exit /b

::------------------------------------------------------------------------------
:: Prompts for input and stores the value in a variable
::
:: Arguments: %1 - The message to display while prompting for input
::            %2 - A variable to store the command given by the player
:: Returns:   0 if the player entered a valid command
::            1 if the player entered Q as the escape command
::------------------------------------------------------------------------------
:getCommand
if not "%~1"=="dummy" call :putStringClearToEOL "%~1" "0;0"
call :getKeyInput "command"
call :messageLineClear
if "!command!"=="Q" exit /b 1
exit /b 0

::------------------------------------------------------------------------------
:: Wrappers for :getCommand but with a more meaningful name
::------------------------------------------------------------------------------
:getTileCharacter
call :getCommand %*
exit /b !errorlevel!

:getMenuItemId
call :getCommand %*
exit /b !errorlevel!

::------------------------------------------------------------------------------
:: Gets a string terminated by a RETURN
::
:: Arguments: %1 - The variable to store the input in
::            %2 - The coordinates to place the cursor initially
::            %3 - The length of a space buffer to place at the coordinates
:: Returns:   0 if a string has been provided
::            1 if the user hit enter without typing anything
::------------------------------------------------------------------------------
:getStringInput
<nul set /p ".=%ESC%[%~2H"
for /L %%A in (%~3,-1,1) do <nul set /p ".= "
<nul set /p ".=%ESC%[%~2H"
set /p "%~1=" || exit /b 1
exit /b 0

::------------------------------------------------------------------------------
:: Prompt the user to validate a choice
::
:: Arguments: %1 - The prompt to display
:: Returns:   0 if the user entered Y
::            1 if the user entered anything else
::------------------------------------------------------------------------------
:getInputConfirmation
call :getInputConfirmationWithAbort 0 "%~1"
if "!errorlevel!"=="1" exit /b 0
exit /b 1

::------------------------------------------------------------------------------
:: A wrapper for :getInputConfirmation
::
:: Arguments: %1 - The column to place the prompt at
::            %2 - The prompt to display before verification
:: Returns:    0 if the player enters N
::             1 if the player enters Y
::            -1 if the player enters anything else
::------------------------------------------------------------------------------
:getInputConfirmationWithAbort
call :get_cursor_pos getyx
if !getyx.x! GTR 73 <nul set /p ".=%ESC%[0;73H"

<nul set /p ".= [y/n]"
call :getKeyInput key

call :messageLineClear

if /I "!key!"=="n" (
    exit /b 0
) else if /I "!key!"=="y" (
    exit /b 1
) else (
    exit /b -1
)

::------------------------------------------------------------------------------
:: Pauses for user response before returning
::
:: Arguments: %1 - The line number to place the message on
:: Returns:   None
::------------------------------------------------------------------------------
:waitForContinueKey
call :putStringClearToEOL "[ press any key to continue ]" "%~1;23"
pause >nul
call :eraseLine "%~1;0"
exit /b

::------------------------------------------------------------------------------
:: Gets a default username in case the player doesn't name their character
::
:: Arguments: %1 - A variable to store the player's name
:: Returns:   None
::------------------------------------------------------------------------------
:getDefaultPlayerName
set "%~1=!USERNAME:~0,%PLAYER_NAME_SIZE%!"
exit /b

::------------------------------------------------------------------------------
:: Uses the VT100 sequence ESC[6n to get the cursor position
:: Code by Dave Benham
:: Originally found at https://www.dostips.com/forum/viewtopic.php?p=61345#p61345
::
:: Arguments: %1 - The variable to store the coordinates in
:: Returns:   0 if coordinates were successfully retrieved
::            1 if something went wrong while getting the coordinates
::------------------------------------------------------------------------------
:get_cursor_pos
setlocal enableDelayedExpansion
set "response="
for /l %%N in (2 1 13) do (
  <nul set /p "=%ESC%[6n"
  for /l %%# in (1 1 %%N) do pause < con > nul
  for /f "skip=1 eol=" %%C in ('"replace /w ? . < con"') do (
    if "%%C"=="R" (
      if "%~1" neq "" (
        for /f "delims=; tokens=1,2" %%A in ("!response!") do (
          endlocal
          set "%~1.y=%%A"
          set "%~1.x=%%B"
        )
      ) else echo {!response!}
      exit /b 0
    ) else set "response=!response!%%C"
  )
)
>&2 echo ERROR: get_cursor_pos failed to return a value
exit /b 1
