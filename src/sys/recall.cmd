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

:: Add %1 to the buffer
set "roff_buffer=!roff_buffer!%~1"

:: If %1 contains a '\n', then split the string there and putStringClearToEOF
:: it, setting the new buffer to the back half of %1.
if not "!roff_buffer!"=="!roff_buffer:\n=!" (
    set "back_half=!roff_buffer:*\n=!"
    for /f "delims=" %%A in ("!back_half!") do set "front_half=!roff_buffer:%%~A=!"
    call ui_io.cmd :putStringClearToEOF "!front_half!" "!roff_print_line!;0"
    set /a roff_print_line+=1
    set "roff_buffer=!back_half!"
)

:: If the buffer length is greater than 80, move characters from the end of
:: the buffer string to the start of a temp string, then putStringClearToEOF
:: the buffer and then replace the buffer string with the temp string.
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

::------------------------------------------------------------------------------
:: Check to see if the player has encountered this monster before
::
:: Arguments: %1 - A reference to the monster being recalled
:: Returns:   0 if the player knows anything about this monster
::            1 if this monster is still a mystery
::------------------------------------------------------------------------------
:memoryMonsterKnown
if "%game.wizard_mode%"=="true" exit /b 0

if not "!%~1.movement!"=="0" exit /b 0
if not "!%~1.defenses!"=="0" exit /b 0
if not "!%~1.kills!"=="0" exit /b 0
if not "!%~1.spells!"=="0" exit /b 0
if not "!%~1.deaths!"=="0" exit /b 0

for /L %%A in (0,1,3) do (
    if not "!%~1.attacks[%%~A]!"=="0" exit /b 0
)
exit /b 1

::------------------------------------------------------------------------------
:: Wizards know everything
::
:: Arguments: %1 - A reference to the recollection
::            %2 - A reference to the creature being recalled
:: Returns:   None
::------------------------------------------------------------------------------
:memoryWizardModeInit
set "%~1.kills=32767"
set "%~1.wake=255"
set "%~1.ignore=255"

:: TODO: put this in a for loop
set /a "move_flag=!%~2.movement! & %config.monsters.move.cm_4d2_obj%"
if not "%move_flag%"=="0" set /a move=8
set /a "move_flag=!%~2.movement! & %config.monsters.move.cm_2d2_obj%"
if not "%move_flag%"=="0" set /a move+=4
set /a "move_flag=!%~2.movement! & %config.monsters.move.cm_1d2_obj%"
if not "%move_flag%"=="0" set /a move+=2
set /a "move_flag=!%~2.movement! & %config.monsters.move.cm_90_random%"
if not "%move_flag%"=="0" set /a move+=1
set /a "move_flag=!%~2.movement! & %config.monsters.move.cm_60_random%"
if not "%move_flag%"=="0" set /a move+=1

set /a "%~1.movement=(!%~2.movement! & ~%config.monsters.move.cm_treasure%) ^| (%move% << %config.monsters.move.cm_tr_shift%)"
set "%~1.defenses=!%~2.defenses!"

set /a "has_freq=!%~2.spells! & %config.monsters.spells.cs_freq%"
if not "%has_freq%"=="0" (
    set /a "%~1.spells=!%~2.spells! ^| %config.monsters.spells.cs_freq%"
) else (
    set "%~1.spells=!%~2.spells!"
)
set "has_freq="

for /L %%A in (0,1,3) do (
    if "!%~2.damage[%%~A]!"=="0" goto :memoryWizardModeInitBreak
    set "%~1.attacks[%%~A]=32767"
)
:memoryWizardModeInitBreak
set /a "is_only_magic=!%~1.movement! & %config.monsters.move.cm_only_magic%"
if not "!is_only_magic!"=="0" set "%~1.attacks[0]=32767"
set "is_only_magic="
exit /b

::------------------------------------------------------------------------------
:: Displays known battles with the monster being remembered
::
:: Arguments: %1 - The number of times that the player has died to the monster
::            %2 - The number of times that the player has killed the monster
:: Returns:   None
::------------------------------------------------------------------------------
:memoryConflictHistory
if not "%~1"=="0" (
    if "%~1"=="1" (
        set "plural=has"
    ) else (
        set "plural=have"
    )
    call :memoryPrint "%~1 of the contributers to your monster memory !plural!"
    call :memoryPrint " been killed by this creature, and "
    if "%~2"=="0" (
        call :memoryPrint "it is not ever known to have been defeated."
    ) else (
        if "%~2"=="1" (
            set "plural=has"
        ) else (
            set "plural=have"
        )
        call :memoryPrint "at least %~2 of the beasts !plural! been exterminated."
    )
) else if not "%~2"=="0" (
    if "%~2"=="1" (
        set "plural=has"
    ) else (
        set "plural=have"
    )
    call :memoryPrint "At least %~2 of these creatures !plural!"
    call :memoryPrint " been killed by contributers to your monster memory."
) else (
    call :memoryPrint "No known battles to the death are recalled."
)
exit /b

::------------------------------------------------------------------------------
:: Displays the depth at which the monster is usually found
::
:: Arguments: %1 - The level of dungeon where the monster is encountered
::            %2 - The number of times that the monster has been killed
:: Returns:   0 if the monster has been encountered before
::            1 if the monster has never been seen before
::------------------------------------------------------------------------------
:memoryDepthFoundAt
set "known=1"

if "%~2"=="0" (
    set "known=0"
    call :memoryPrint " It lives in the town"
) else if not "%~2"=="0" (
    set "known=0"

    if %~1 GTR %config.monsters.mon_endgame_level% (
        set /a level=%config.monsters.mon_endgame_level%*50
    ) else (
        set /a level=%~1*50
    )

    call :memoryPrint " It is normally found at depths of !level! feet"
)
exit /b !known!

::------------------------------------------------------------------------------
:: Remembers how the monster moves
::
:: Arguments: %1 - The monster's movement style
::            %2 - The monster's movement speed
::            %3 - Whether the monster is known
:: Returns:   0 if the monster is known
::            1 if the monster is not known
::------------------------------------------------------------------------------
:memoryMovement
set /a monster_speed=%~2-10
set "is_known=%~3"

set /a "has_movement_flags=%~1 & %config.monsters.move.cm_all_mv_flags%"
set /a "moves_randomly=%~1 & %config.monsters.move.cm_random_move%"
set /a "only_attacks=%~1 & %config.monsters.move.cm_attack_only%"
set /a "only_magic=%~1 & %config.monsters.move.cm_only_magic%"

set /a "move_desc=%moves_randomly%>>3"

if not "!has_movement_flags!"=="0" (
    if "%is_known%"=="true" (
        call :memoryPrint ", and"
    ) else (
        call :memoryPrint " It"
        set "is_known=true"
    )

    call :memoryPrint " moves"

    if not "!moves_randomly!"=="0" (
        call :memoryPrint "!recall_description_how_much[%move_desc%]!"
        call :memoryPrint " erratically"
    )

    if "%monster_speed%"=="1" (
        call :memoryPrint " at normal speed"
    ) else (
        if not "%moves_randomly%"=="0" (
            call :memoryPrint ", and"
        )

        if %monster_speed% LEQ 0 (
            if "%monster_speed%"=="-1" (
                call :memoryPrint " very"
            ) else if %monster_speed% LSS -1 (
                call :memoryPrint " incredibly"
            )
            call :memoryPrint " slowly"
        ) else (
            if "%monster_speed%"=="3" (
                call :memoryPrint " very"
            ) else if %monster_speed% GTR 3 (
                call :memoryPrint " unbelievably"
            )
            call :memoryPrint " quickly"
        )
    )

    if not "%only_attacks%"=="0" (
        if "!is_known!"=="true" (
            call :memoryPrint ", but"
        ) else (
            call :memoryPrint " It"
            set "is_known=true"
        )
        call :memoryPrint " does not deign to chase intruders"
    )

    if not "%only_magic%"=="0" (
        if "!is_known!"=="true" (
            call :memoryPrint ", but"
        ) else (
            call :memoryPrint " It"
            set "is_known=true"
        )
        call :memoryPrint " always moves and attacks by using magic"
    )
)
exit /b !is_known!

::------------------------------------------------------------------------------
:: Display how many experience points the monster is worth
::
:: Arguments: %1 - The monster's type [evil, undead, natural]
::            %2 - The monster's experience point value
::            %3 - The monster's level
:: Returns:   None
::------------------------------------------------------------------------------
:memoryKillPoints
call :memoryPrint " A kill of this"
set /a "is_type=%~1 & %config.monsters.defense.cd_animal%"
if not "%is_type%"=="0" call :memoryPrint " natural"
set /a "is_type=%~1 & %config.monsters.defense.cd_evil%"
if not "%is_type%"=="0" call :memoryPrint " evil"
set /a "is_type=%~1 & %config.monsters.defense.cd_undead%"
if not "%is_type%"=="0" call :memoryPrint " undead"

:: Calculate the integer exp part, which can theoretically be larger than 64K
:: if a level 1 character sees a Balrog. That won't happen, but it could.
set /a quotient=%~2 * %~3 / %py.misc.level%

:: Calculate the fractional exp part, scaled by 100
set /a remainder=((%~2 * %~3 %% %py.misc.level%) * 1000 / %py.misc.level%) / 10

set "plural=s"
if "%quotient%"=="1" if "%remainder%"=="0" set "plural="
set "remainder=00%remainder%"
set "remainder=%remainder:~-2%"

call :memoryPrint " creature is worth %quotient%.%remainder% point%plural%"

:: Generate ordinal ending based on player's level
if "%py.misc.level:~0,1%"=="1" (
    set "p=th"
) else (
    set /a ord=%py.misc.level% %% 10
    if "!ord!"=="1" (
        set "p=st"
    ) else if "!ord!"=="2" (
        set "p=nd"
    ) else if "!ord!"=="3" (
        set "p=rd"
    ) else (
        set "p=th"
    )
)
set "q="
if "%py.misc.level%"=="8" set "q=n"
if "%py.misc.level%"=="11" set "q=n"
if "%py.misc.level%"=="18" set "q=n"

call :memoryPrint " for a%q% %py.misc.level%%p% level character."
exit /b

::------------------------------------------------------------------------------
:: Display known spells if they've been used against the player, or
:: resistances if the player has cast spells at the monster
::
:: Arguments: %1 - frequent monster spells
::            %2 - monster spell flags
::            %3 - creature spell flags
:: Returns:   None
::------------------------------------------------------------------------------
:memoryMagicSkills
set "known=true"
set "spell_flags=%~2"

for /L %%A in (0,1,31) do (
    set /a "has_breath_attacks=%spell_flags% & %config.monsters.spells.cs_breathe%"
    if "!has_breath_attacks!"=="0" goto :memoryMagicSkillsSpells

    set /a "br_light=%spell_flags% & (%config.monsters.spells.cs_br_light%<<%%A)"
    if not "!br_light!"=="0" (
        set /a "spell_flags&=~(%config.monsters.spells.cs_br_light%<<%%A)"

        if "!known!"=="true" (
            set /a "freq_attack=%~2 & %config.monsters.spells.cs_freq%"
            if not "!freq_attack!"=="0" (
                call :memoryPrint " It can breathe "
            ) else (
                call :memoryPrint " It is resistant to "
            )
            set "known=false"
        ) else if not "!has_breath_attacks!"=="0" (
            call :memoryPrint ", "
        ) else (
            call :memoryPrint " and "
        )
        call :memoryPrint !recall_description_breath[%%A]!
    )
)

set "known=true"
:memoryMagicSkillsSpells
for /L %%A in (0,1,31) do (
    set /a "has_spell_attacks=%spell_flags% & %config.monsters.spells.cs_spells%"
    if "!has_spell_attacks!"=="0" goto :memoryMagicSkillsFreq

    set /a "t_short=%spell_flags% & (%config.monsters.spells.cs_tel_short%<<%%A)"
    if not "!t_short!"=="0" (
        set /a "spell_flags&=~(%config.monsters.spells.cs_tel_short%<<%%A)"

        if "!known!"=="true" (
            set /a "freq_attack=%~1 & %config.monsters.spells.cs_breathe%"
            if not "!freq_attack!"=="0" (
                call :memoryPrint ", and is also"
            ) else (
                call :memoryPrint " It is"
            )
            call :memoryPrint " magical, casting spells which "
            set "known=false"
        ) else if not "!has_spell_attacks!"=="0" (
            call :memoryPrint ", "
        ) else (
            call :memoryPrint " or "
        )
        call :memoryPrint !recall_description_breath[%%A]!
    )
)

:memoryMagicSkillsFreq
set /a "either_or=%~1 & (%config.monsters.spells.cs_breathe% ^| %config.monsters.spells.cs_spells%)"
if not "%either_or%"=="0" (
    set /a "quite_freq=%~1 & %config.monsters.spells.cs_freq%"
    if !quite_freq! GTR 5 (
        call :memoryPrint "; 1 time in !quite_freq!"
    )
    call :memoryPrint "."
)
set "either_or="
set "quite_freq="
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

