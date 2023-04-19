call %*
exit /b

::------------------------------------------------------------------------------
:: Generates damage for _d_ style dice rolls
::
:: Arguments: %1 - The number of dice to roll
::            %2 - The number of sides on each die
:: Returns:   The sum of %1 rolls of %2-sided dice 
::------------------------------------------------------------------------------
:diceRoll
set "sum=0"
for /L %%A in (1,1,%~1) do (
    call rng.cmd :randomNumber "%~2"
    set /a sum+=!errorlevel!
)
exit /b !sum!

::------------------------------------------------------------------------------
:: Returns max dice roll value
::
:: Arguments: %1 - The number of dice to roll
::            %2 - The number of sides on each die
:: Returns:   %1*%2
::------------------------------------------------------------------------------
:maxDiceRoll
set /a sum=%~1*%~2
exit /b !sum!