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
    call ui_io.cmd :putStringClearToEOL "CNIL" "!roff_print_line!;0"
    set /a roff_print_line+=1
    exit /b
)

:: Add %1 to the buffer
set "roff_buffer=!roff_buffer!%~1"

:: If %1 contains a '\n', then split the string there and putStringClearToEOL
:: it, setting the new buffer to the back half of %1.
if not "!roff_buffer!"=="!roff_buffer:\n=!" (
    set "back_half=!roff_buffer:*\n=!"
    for /f "delims=" %%A in ("!back_half!") do set "front_half=!roff_buffer:%%~A=!"
    call ui_io.cmd :putStringClearToEOL "!front_half!" "!roff_print_line!;0"
    set /a roff_print_line+=1
    set "roff_buffer=!back_half!"
)

:: If the buffer length is greater than 80, move characters from the end of
:: the buffer string to the start of a temp string, then putStringClearToEOL
:: the buffer and then replace the buffer string with the temp string.
call helpers.cmd :getLength "!roff_buffer!" buffer_length
if !buffer_length! GEQ 80 (
    for /L %%A in (!buffer_length!,-1,79) do (
        set "temp_string=!roff_buffer:~-1!!temp_string!"
        set "roff_buffer=!roff_buffer:~0,-1!"
    )
    call :dropCharsUntilSpace
    call ui_io.cmd :putStringClearToEOL "!roff_buffer!" "!roff_print_line!;0"
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
:: Arguments: %1 - A reference to the creature's known characteristics
::            %2 - A reference to the creature's actual characteristics
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
::            %2 - the creature's known spell flags
::            %3 - the creature's actual spell flags
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

::------------------------------------------------------------------------------
:: Display how hard the monster is to kill
::
:: Arguments: %1 - A reference to the creature being remembered
::            %2 - The number of times this monster has been killed
:: Returns:   None
::------------------------------------------------------------------------------
:memoryKillDifficulty
set /a kill_knowledge_threshold=304/(4+!%~1.level!)
if %~2 LEQ !kill_knowledge_threshold! exit /b
set "kill_knowledge_threshold="

call :memoryPrint " It has an armor rating of !%~1.ac!"

set /a "uses_max_hp=!%~1.defenses! & %config.monsters.defense.cd_max_hp%"
set "hp_type="
if not "%uses_max_hp%"=="0" set "hp_type= maximized"
call :memoryPrint " and a%hp_type% life rating of !%~1.hit_die.dice!d!%~1.hit_die.sides!."
exit /b

::------------------------------------------------------------------------------
:: Display special abilities
::
:: Arguments: %1 - The movement type of the creature
:: Returns:   None
::------------------------------------------------------------------------------
:memorySpecialAbilities
set "known=true"
set "move_type=%~1"

set "i=0"
:memorySpecialAbilitiesLoop
set /a "special_move=!move_type! & %config.monsters.move.cm_special%"
if "!special_move!"=="0" goto :memorySpecialAbilitiesAfterLoop

:: TODO : Determine if I need to use %i% or !i!
set /a "move_invisibly=!move_type! & (%config.monsters.move.cm_invisible% << %i%)"
if not "!move_invisibly!"=="0" (
    set /a "move_type&=~(%config.monsters.move.cm_invisible% << %i%)"

    if "!known!"=="true" (
        call :memoryPrint " It can "
        set "known=false"
    ) else if not "!special_move!"=="0" (
        call :memoryPrint ", "
    ) else (
        call :memoryPrint " and "
    )
    call :memoryPrint "!recall_description_move[%i%]!"
)

set /a i+=1
goto :memorySpecialAbilitiesLoop

:memorySpecialAbilitiesAfterLoop
if "!known!"=="false" call :memoryPrint "."

:: Cleanup
for %%A in (known i move_type special_move move_invisibly) do set "%%~A="
exit /b

::------------------------------------------------------------------------------
:: Display any known special weaknesses
::
:: Arguments: %1 - The creature's defenses flag
:: Returns:   None
::------------------------------------------------------------------------------
:memoryWeaknesses
set "known=true"
set "defense=%~1"

set "i=0"
:memoryWeaknessesLoop
set /a "def_weakness=!defense! & %config.monsters.defense.cd_weakness%"
if "!def_weakness!"=="0" goto :memoryWeaknessesAfterLoop

set /a "frost_defense=!defense! & (%config.monsters.defense.cd_frost% << %i%)"
if not "!frost_defense!"=="0" (
    set /a "defense&=!(%config.monsters.defense.cd_frost% << %i%)"

    if "!known!"=="true" (
        call :memoryPrint " It is susceptible to "
        set "known=false"
    ) else if not "!frost_defense!"=="0" (
        call :memoryPrint ", "
    ) else (
        call :memoryPrint " and "
    )
    call :memoryPrint "!recall_description_weakness[%i%]!"
)

set /a i+=1
goto :memoryWeaknessesLoop

:memoryWeaknessesAfterLoop
if "!known!"=="false" call :memoryPrint "."

:: Cleanup
for %%A in (known i frost_defense defense def_weakness) do set "%%~A="
exit /b

::------------------------------------------------------------------------------
:: Display the creature's awareness
::
:: Arguments: %1 - A reference to the creature's actual characteristics
::            %2 - A reference to the creature's known characteristics
:: Returns:   None
::------------------------------------------------------------------------------
:memoryAwareness
set "memorable=0"
set /a square_wake=!%~2.wake!*!%~2.wake!
if !square_wake! GTR !%~1.sleep_counter! set "memorable=1"
if "!%~2.ignore!"=="32767" set "memorable=1"
if "!%~1.sleep_counter!"=="0" if !%~2.kills! GEQ 10 set "memorable=1"

if "!memorable!"=="1" (
    call :memoryPrint " It "
    if !%~1.sleep_counter! GTR 200 (
        call :memoryPrint "prefers to ignore"
    ) else if !%~1.sleep_counter! GTR 95 (
        call :memoryPrint "pays very little attention to"
    ) else if !%~1.sleep_counter! GTR 75 (
        call :memoryPrint "pays little attention to"
    ) else if !%~1.sleep_counter! GTR 45 (
        call :memoryPrint "tends to overlook"
    ) else if !%~1.sleep_counter! GTR 25 (
        call :memoryPrint "takes quite a while to see"
    ) else if !%~1.sleep_counter! GTR 10 (
        call :memoryPrint "takes a while to see"
    ) else if !%~1.sleep_counter! GTR 5 (
        call :memoryPrint "is fairly observant of"
    ) else if !%~1.sleep_counter! GTR 3 (
        call :memoryPrint "is observant of"
    ) else if !%~1.sleep_counter! GTR 1 (
        call :memoryPrint "is very observant of"
    ) else if !%~1.sleep_counter! NEQ 0 (
        call :memoryPrint "is vigilant for"
    ) else (
        call :memoryPrint "is ever vigilant for"
    )

    call :memoryPrint " intruders, which it may notice from !%~1.area_affect_radius! feet."
)

:: Cleanup
set "memorable="
set "square_wake="
exit /b

::------------------------------------------------------------------------------
:: Display what the creature might carry
::
:: Arguments: %1 - The creature's actual movement flags
::            %2 - The creature's known movement flags
:: Returns:   None
::------------------------------------------------------------------------------
:memoryLootCarried
set /a "carries_gold=%~2 & %config.monsters.move.cm_carry_gold%"
set /a "carries_obj=%~2 & %config.monsters.move.cm_carry_obj%"
if "!carries_gold!"=="0" if "!carries_treasure!"=="0" exit /b

call :memoryPrint " It may"
set /a "carrying_chance=(%~2 & %config.monsters.move.cm_treasure%) >> %config.monsters.move.cm_tr_shift%"
set /a "carries_treasure=%~1 & %config.monsters.move.cm_treasure%"
set /a "carries_small_objects=%~2 & %config.monsters.move.cm_small_obj%"
if "%carrying_chance%"=="1" (
    if "%carries_treasure%"=="%config.monsters.move.cm_60_random%" (
        call :memoryPrint " sometimes"
    ) else (
        call :memoryPrint " often"
    )
) else if "%carrying_chance%"=="2" (
    if "%carries_treasure%"=="%config.monsters.move.cm_60_random%" call :memoryPrint " often"
    if "%carries_treasure%"=="%config.monsters.move.cm_90_random%" call :memoryPrint " often"
)
call :memoryPrint " carry"

if not "!carries_small_objects!"=="0" set "p= small"
set "p=!p! objects"

if "%carrying_chance%"=="1" (
    if not "!carries_small_objects!"=="0" (
        set "p= a small object"
    ) else (
        set " an object"
    )
) else if "%carrying_chance%"=="2" (
    call :memoryPrint " one or two"
) else (
    call :memoryPrint " up to %carrying chance%"
)

if not "%carries_obj%"=="0" (
    call :memoryPrint "!p!"
    if not "%carries_gold%"=="0" (
        call :memoryPrint " or treasure"
        if %carrying_chance% GTR 1 call :memoryPrint "s"
    )
    call :memoryPrint "."
) else if not "%carrying_chance%"=="1" (
    call :memoryPrint " treasures."
) else (
    call :memoryPrint " treasure."
)
exit /b

::------------------------------------------------------------------------------
:: Display known attack stats
::
:: Arguments: %1 - A reference to the creature's known characteristics
::            %2 - A reference to the creature's actual characteristics
:: Returns:   None
::------------------------------------------------------------------------------
:memoryAttackNumberAndDamage
set "known_attacks=0"
for /L %%A in (0,1,3) do (
    if not "!%~1.attacks[%%A]!"=="0" (
        set /a known_attacks+=1
    )
)

set "attack_count=0"
set /a counter_dec=%MON_MAX_ATTACKS%-1
for /L %%A in (0,1,%counter_dec%) do (
    set "attack_id=!%~2.damage[%%A]!"
    if "!attack_id!"=="0" goto :memoryAttackNumberAndDamageAfterLoop

    REM Only print known attacks. The C code was using a bouncer pattern here,
    REM but batch doesn't have a `continue` equivalent.
    if not "!%~1.attacks[%%A]!"=="0" (
        for /f "delims=" %%B in ("!attack_id!") do (
            set "attack_type=!monster_attacks[%%~B].type_id!"
            set "attack_description_id=!monster_attacks[%%~B].description_id!"
            set "dice.dice=!monster_attacks[%%~B].dice.dice!"
            set "dice.sides=!monster_attacks[%%~B].dice.sides!"
        )
        set /a attack_count+=1

        if "!attack_count!"=="1" (
            call :memoryPrint " It can "
        ) else if "!attack_count!"=="!known_attacks!" (
            call :memoryPrint ", and "
        ) else (
            call :memoryPrint ", "
        )

        if !attack_description_id! GTR 19 set "attack_description_id=0"
        for /f "delims=" %%B in ("!attack_description_id!") do (
            call :memoryPrint "!recall_description_attack_method[%%~B]!"
        )

        set /a "multidie_attack=0"
        if not "!attack_type!"=="1" set "multidie_attack=1"
        if !dice.dice! GTR 0 if !dice.sides! GTR 0 set "multidie_attack=1"
        if "!multidie_attack!"=="1" (
            call :memoryPrint " to "
            if !attack_type! GTR 24 set "attack_type=0"
            
            for /f "delims=" %%B in ("!attack_type!") do (
                call :memoryPrint "!recall_description_attack_type[%%~B]!"
            )

            if not "!dice.dice!"=="0" (
                if not "!dice.sides!"=="0" (
                    set /a "left_side=(4 + !%~2.level!) * !%~1.attacks[%%~A]!"
                    set /a right_side=80*!dice.dice!*!dice.sides!
                    if !left_side! GTR !right_side! (
                        if "!attack_type!"=="19" (
                            call :memoryPrint " by"
                        ) else (
                            call :memoryPrint " with damage"
                        )

                        call :memoryPrint " !dice.dice!d!dice.sides!"
                    )
                )
            )
        )
    )
)

:memoryAttackNumberAndDamageAfterLoop
if not "!attack_count!"=="0" (
    call :memoryPrint "."
) else if !known_attacks! GTR 0 (
    if !%~1.attacks[0]! GEQ 10 (
        call :memoryPrint " It has no physical attacks."
    )
) else (
    call :memoryPrint " Nothing is known about its attack."
)
exit /b

::------------------------------------------------------------------------------
:: Print out what the player has discovered about the monster
::
:: Arguments: %1 - The ID of the monster to remember
:: Returns:   The value returned by getKeyInput so that the game knows if it
::            needs to abort rather than continue
::------------------------------------------------------------------------------
:memoryRecall
set "memory=creature_recall[%~1]"
set "creature=creatures_list[%~1]"

if "%game.wizard_mode%"=="true" (
    call :copyMemory saved_memory "%memory%"
    call :memoryWizardModeInit "%memory%" "%creature%"
)

set "roff_print_line=0"
set /a "spells=!%memory%.spells! & !%creature%.spells! & ~%config.monsters.spells.cs_freq%"

:: CM_WIN is always known to the player
set /a "win_creature=!%creature%.movement! & %config.monsters.move.cm_win%"
set /a "movement_type=!%memory%.movement! ^| %win_creature%"
set /a "defense=!%memory%.defenses! & !%creature%.defenses!"

call :memoryPrint "The !%creature%.name!:\n"

set "known=false"
call :memoryConflictHistory "!%memory%.deaths!" "!%memory%.kills!"
call :memoryDepthFoundAt "!%creature%.level!" "!%memory%.kills!"
call :memoryMovement "!movement_type!" "!%creature%.speed!" "!errorlevel!"
if "!errorlevel!"=="0" set "known=true"

:: Finish the paragraph with a period
if "!known!"=="true" call :memoryPrint "."

if not "!%memory%.kills!"=="0" (
    call :memoryKillPoints "!%creature%.defenses!" "!%creature%.kill_exp_value!" "!%creature%.level!"
)

call :memoryMagicSkills "!spells!" "!%memory%.spells!" "!%creature%.spells!"
call :memoryKillDifficulty "%creature%" "!%memory%.kills!"
call :memorySpecialAbilities "!movement_type!"
call :memoryWeaknesses "!defense!"

set /a "warm_blooded=!defense! & %config.monsters.defense.cd_infra%"
set /a "sleepless=!defense! & %config.monsters.defense.cd_no_sleep%"
if not "!warm_blooded!"=="0" call :memoryPrint " It is warm blooded"
if not "!sleepless!"=="0" (
    if not "!warm_blooded!"=="0" (
        call :memoryPrint ", and"
    ) else (
        call :memoryPrint " It"
    )
    call :memoryPrint " cannot be charmed or slept"
)
set "no_charm=0"
if not "!sleepless!"=="0" set "no_charm=1"
if not "!warm_blooded!"=="0" set "no_charm=1"
if "!no_charm!"=="1" call :memoryPrint "."

call :memoryAwareness "%creature%" "%memory%"
call :memoryLootCarried "!%creature%.movement!" "!movement_type!"
call :memoryAttackNumberAndDamage "%memory%" "%creature%"

if not "%win_creature%"=="0" (
    call :memoryPrint " Killing one of these wins the game^^!"
)
call :memoryPrint "\n"
call ui_io.cmd :putStringClearToEOL "--pause--" "!roff_print_line!;0"

if "%game.wizard_mode%"=="true" (
    call :copyMemory "%memory%" "saved_memory"
)

:: Cleanup
for %%A in (no_charm sleepless warm_blooded movement_type known) do (
    set "%%A="
)

call ui_io.cmd :getKeyInput key
call helpers.cmd :charToDec "!key!"
exit /b !errorlevel!

:copyMemory
for %%A in (movement spells kills deaths defenses wake ignore) do (
    set "%~1.%%~A=!%~2.%%~A!"
)
set /a counter_dec=%MON_MAX_ATTACKS%-1
for /L %%A in (0,1,%counter_dec%) do (
    set "%~1.attacks[%%A]=!%~2.attacks[%%A]!"
)
exit /b

::------------------------------------------------------------------------------
:: Ask the user if they want to remember a monster
:: TODO: refactor to not have everything inside of the loop
::
:: Arguments: %1 - Sprite character of the monster to recall
:: Returns:   None
::------------------------------------------------------------------------------
:recallMonsterAttributes
set "n=0"
set /a counter_dec=%MON_MAX_ATTACKS%-1

for /L %%A in (%counter_dec%,-1,0) do (
    if "!creatures_list[%%A].sprite!"=="%~1" (
        call :memoryMonsterKnown "creature_recall[%%A]"
        if "!errorlevel!"=="0" (
            if "!n!"=="0" (
                call ui_io.cmd :getConfirmationWithAbort 40 "You recall those details?"
                if not "!errorlevel!"=="1" exit /b

                call ui_io.cmd :eraseLine "0;40"
                call ui_io.cmd :terminalSaveScreen
            )
            set /a n+=1

            call :memoryRecall %%A
            set "query=!errorlevel!"
            call ui_io.cmd :terminalRestoreScreen
            if "!query!"=="-1" exit /b
        )
    )
)
exit /b
