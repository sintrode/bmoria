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

:terminalRestore
exit /b

:terminalSaveScreen
exit /b

:terminalRestoreScreen
exit /b

:terminalBellSound
exit /b

:putQIO
exit /b

:flushInputBuffer
exit /b

:clearScreen
exit /b

:clearToBottom
exit /b

:moveCursor
exit /b

:addChar
exit /b

:putString
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

