@echo off
call %*
exit /b

::------------------------------------------------------------------------------
:: Sets the seed to a value between 1 and m-1
::
:: Arguments: %1 - The initial seed value to use
:: Returns:   None
::------------------------------------------------------------------------------
:setRandomSeed
set /a rnd_seed=(%~1 %% (rng_m - 1)) + 1
exit /b

::------------------------------------------------------------------------------
:: Returns a pseudo-random number between 1 and rng_m-1
::
:: Arguments: None
:: Returns:   A random number
::------------------------------------------------------------------------------
:rnd
set /a high=rnd_seed / rng_q
set /a low=rnd_seed %% rng_q
set /a test=rng_a * low - rng_r * high

if !test! GTR 0 (
    set "rnd_seed=!test!"
) else (
    set /a rnd_seed=!test! + %rng_m%
)
exit /b !rnd_seed!

::------------------------------------------------------------------------------
:: Generates a random number between 1 and MAXVAL
::
:: Arguments: %1 - The maximum valid random value
:: Returns:   A random number between 1 and %1
::------------------------------------------------------------------------------
:randomNumber
call rng.cmd :rnd
set /a random_number=!errorlevel! %% %~1 + 1
exit /b !random_number!