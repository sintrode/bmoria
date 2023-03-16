@echo off
call %*
exit /b

::------------------------------------------------------------------------------
:: Returns the position of the first set bit and clears that bit
::
:: Arguments: %1 - The name of the flag variable to process
:: Returns:   The first bit set, or -1 if no one bits are found
::------------------------------------------------------------------------------
:getAndClearFirstBit
set "mask=1"

for /L %%A in (0,1,31) do (
    set /a "is_masked=!%~1!&!mask!"
    if not "!is_masked!"=="0" (
        set /a "!%~1!&=~!mask!"
        exit /b %%A
    )
    set /a "mask<<=1"
)
exit /b -1

::------------------------------------------------------------------------------
:: Used to replace a placeholder in a haggling comment with the actual value.
:: When this subroutine is called, the template will already be in place. This
:: was a bit tricky in C++, but it's much easier in batch as long as the
:: identifier doesn't contain a percent sign like it originally did.
::
:: Arguments: %1 - The name of the variable containing the template string
::            %2 - The identifier to be replaced
::            %3 - The value to replace the identifier with
:: Returns:   None
::------------------------------------------------------------------------------
:insertNumberIntoString
set "template_string=!%~1!"
set "template_replacee=%~2"
set "template_replacer=%~3"
set "%~1=!template_string:%template_replacee%=%template_replacer%!"
set "template_string="
set "template_replacee="
set "template_replacer="
exit /b

::------------------------------------------------------------------------------
:: Used to add a plural suffix to an item description if necessary
::
:: Arguments: %1 - The name of the variable containing the template string
::            %2 - The identifier to be replaced
::            %3 - The value to replace the identifier with
:: Returns:   None
::------------------------------------------------------------------------------
:insertStringIntoString
set "template_string=!%~1!"
set "template_replacee=%~2"
set "template_replacer=%~3"
if "%template_replacer%"=="CNIL" set "template_replacer="

set "%~1=!template_string:%template_replacee%=%template_replacer%!"
set "template_string="
set "template_replacee="
set "template_replacer="
exit /b

::------------------------------------------------------------------------------
:: Determines if a specified character is a vowel or not. Used to see if the
:: next word needs to be "a" or "an." Note that we're being lazy and using the
:: actual first letter rather than the starting sound, so things like "an unique"
:: will still happen.
::
:: Arguments: %1 - The character to validate
:: Returns:   0 if the character is a vowel
::            1 otherwise
::------------------------------------------------------------------------------
:isVowel
if /I "%~1"=="a" exit /b 0
if /I "%~1"=="e" exit /b 0
if /I "%~1"=="i" exit /b 0
if /I "%~1"=="o" exit /b 0
if /I "%~1"=="u" exit /b 0
exit /b 1

::------------------------------------------------------------------------------
:: Returns the number of seconds since Jan 1 1970 at midnight
:: https://stackoverflow.com/a/11385908
::
:: Arguments: %1 - The variable to store the value in
:: Returns:   A standard UNIX timestamp
::------------------------------------------------------------------------------
:getCurrentUnixTime
for /f %%x in ('wmic path win32_utctime get /format:list ^| findstr "="') do set "%%~x"
set /a z=(14-100%Month%%%100)/12, y=10000%Year%%%10000-z
set /a ut=y*365+y/4-y/100+y/400+(153*(100%Month%%%100+12*z-3)+2)/5+Day-719469
set /a ut=ut*86400+100%Hour%%%100*3600+100%Minute%%%100*60+100%Second%%%100
set "%~1=!ut!"
exit /b

::------------------------------------------------------------------------------
:: Prints a date in the ISO standard format
::
:: Arguments: %1 - The variable to store the output in
:: Returns:   None
::------------------------------------------------------------------------------
:humanDateString
for /f "delims=" %%A in ('wmic os get localdatetime ^| find "."') do set "dt=%%A"
set "%~1=!dt:~0,4!-!dt:~4,2!-!dt:~6,2!"
exit /b

::------------------------------------------------------------------------------
:: strLen7 by dbenham
:: Calculates the length of a string and stores that value in a variable
:: https://ss64.org/viewtopic.php?pid=6478#p6478
::
:: Arguments: %1 - The string to calculate the length of
::            %2 - The variable to store the length in
:: Returns:   None
::------------------------------------------------------------------------------
:getLength
setlocal EnableDelayedExpansion
set "s=#%~1"
set "len=0"
for %%N in (4096 2048 1024 512 256 128 64 32 16 8 4 2 1) do (
	if "!s:~%%N,1!" neq "" (
		set /a "len+=%%N"
		set "s=!s:~%%N!"
	)
)
endlocal&set %~2=%len%
exit /b

::------------------------------------------------------------------------------
:: Expands coordinate variable names into their X and Y parts, as well as
:: incremented and decremented variations, which is generally useful for
:: dungeon.cmd subroutines
::
:: Arguments: %1 - The name of the variable to expand
:: Returns:   None
::------------------------------------------------------------------------------
:expandCoordName
for /f "tokens=1,2 delims=;" %%A in ("!%~1!") do (
    set /a %~1.y=%%A, %~1.x=%%B
    set /a %~1.y_dec=%%A-1, %~1.x_dec=%%B-1
    set /a %~1.y_inc=%%A+1, %~1.x_inc=%%B+1
)
exit /b

::------------------------------------------------------------------------------
:: Determines if a character is uppercase
::
:: Arguments: %1 - The character to test
:: Returns:   0 if the character is uppercase
::            1 if the character does not match the regex [A-Z]
::------------------------------------------------------------------------------
:isUpper
set "is_upper=0"
for /f "delims=abcdefghijklmnopqrstuvwxyz" %%A in ("%~1") do set "is_upper=1"
exit /b %is_upper%

::------------------------------------------------------------------------------
:: Determines if a character is lowercase
:: Note that this is here because * is a valid character in :spellGetId
::
:: Arguments: %1 - The character to test
:: Returns:   0 if the character is lowercase
::            1 if the character does not match the regex [a-z]
::------------------------------------------------------------------------------
:isLower
set "is_lower=0"
for /f "delims=ABCDEFGHIJKLMNOPQRSTUVWXYZ" %%A in ("%~1") do set "is_lower=1"
exit /b %is_lower%

::------------------------------------------------------------------------------
:: Checks a character to determine if it is alphabetic, and if it's uppercase
:: or lowercase
::
:: Arguments: %1 - The character to check
:: Returns:   0 if the character does not match the regex [A-Za-z]
::            1 if the character matches the regex [A-Z]
::            2 if the character matches the regex [a-z]
::------------------------------------------------------------------------------
:checkLetter
set "char=%~1"
set "char=!char:~0,1!"
for /f "delims=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz" %%A in ("!char!") do exit /b 0
for /f "delims=abcdefghijklmnopqrstuvwxyz" %%A in ("!char!") do exit /b 1
exit /b 2