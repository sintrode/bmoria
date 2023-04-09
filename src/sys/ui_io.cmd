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

:terminalInitialize
exit /b

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

