::------------------------------------------------------------------------------
:: Because of how batch interacts with files compared to how C interacts with
:: files, there are significant changes from the original code. However, the
:: choice to write encrypted bytes to the file instead of writing values
:: directly has been emulated as closely as possible in order to be able to
:: load in save files from the original game.
::------------------------------------------------------------------------------
call %*
exit /b

::------------------------------------------------------------------------------
:: Set up prior to the actual save, do the save, then clean up
::
:: Arguments: None
:: Returns:   0 if a save file was successfully created
::            1 if the file was not successfully saved to
::------------------------------------------------------------------------------
:saveGame
call :saveChar "%config.files.save_game%" && exit /b 0
call ui_io.cmd :printMessage "Save file '%config.files.save_game%' fails."

set "i=0"
call ui_io.cmd :getInputConfirmation "File exists. Delete old save file?"
if "!errorlevel!"=="0" (
    del /q "%config.files.save_game%" 2>nul
    if exist "%config.files.save_game%" (
        call ui_io.cmd :printMessage "Can't delete '%config.files.save_game%'."
    )
    call ui_io.cmd :putStringClearToEOL "New Save file:" "0;0"
    call ui_io.cmd :getStringInput "input" "0;31" 45 || exit /b 1
    if not "!input!"=="" set "config.files.save_game=!input!"

    call ui_io.cmd :putStringClearToEOL "Saving with '!config.files.save_game!'..." "0;0"
)
goto :saveGame

::------------------------------------------------------------------------------
:: A wrapper for saving the character to a file
::
:: Arguments: None
:: Returns:   0 if the file was saved properly
::            1 if there was some issue saving the file
::------------------------------------------------------------------------------
:svWrite
set "l=0"
if "%config.options.run_cut_corners%"=="true" set /a "l|=0x1"
if "%config.options.run_examine_corners%"=="true" set /a "l|=0x2"
if "%config.options.run_print_self%"=="true" set /a "l|=0x4"
if "%config.options.find_bound%"=="true" set /a "l|=0x8"
if "%config.options.prompt_to_pickup%"=="true" set /a "l|=0x10"
if "%config.options.use_roguelike_keys%"=="true" set /a "l|=0x20"
if "%config.options.show_inventory_weights%"=="true" set /a "l|=0x40"
if "%config.options.highlight_seams%"=="true" set /a "l|=0x80"
if "%config.options.run_ignore_doors%"=="true" set /a "l|=0x100"
if "%config.options.error_beep_sound%"=="true" set /a "l|=0x200"
if "%config.options.display_counts%"=="true" set /a "l|=0x400"
if "%game.character_is_dead%"=="true" set /a "l|=0x80000000"
if "%game.total_winner%"=="true" set /a "l|=0x40000000"

set /a mon_count=%mon_max_creatures%-1
for /L %%A in (0,1,%mon_count%) do (
    set "is_remembered=0"
    for %%R in (movement defenses kills spells deaths attacks[0] attacks[1] attacks[2] attacks[3]) do (
        if !creature_recall[%%A].%%~R! GTR 0 set "is_remembered=1"
    )
    if "!is_remembered!"=="1" (
        call :wrShort %%A
        call :wrLong !creature_recall[%%A].movement!
        call :wrLong !creature_recall[%%A].spells!
        call :wrShort !creature_recall[%%A].kills!
        call :wrShort !creature_recall[%%A].deaths!
        call :wrShort !creature_recall[%%A].defenses!
        call :wrByte !creature_recall[%%A].wake!
        call :wrByte !creature_recall[%%A].ignore!
        call :wrByte !creature_recall[%%A].attacks[0]! %mon_max_attacks%
        call :wrByte !creature_recall[%%A].attacks[1]! %mon_max_attacks%
        call :wrByte !creature_recall[%%A].attacks[2]! %mon_max_attacks%
        call :wrByte !creature_recall[%%A].attacks[3]! %mon_max_attacks%
    )
)
:: Sentinel to indicate no more monster info
call :wrShort 65535

call :wrLong !l!

call :wrString "%py.misc.name%"
call :wrBool "%py.misc.gender%"
call :wrLong "%py.misc.au%"
call :wrLong "%py.misc.max_exp%"
call :wrLong "%py.misc.exp%"
call :wrShort "%py.misc.exp_fraction%"
call :wrShort "%py.misc.age%"
call :wrShort "%py.misc.height%"
call :wrShort "%py.misc.weight%"
call :wrShort "%py.misc.level%"
call :wrShort "%py.misc.max_dungeon_depth%"
call :wrShort "%py.misc.chance_in_search%"
call :wrShort "%py.misc.fos%"
call :wrShort "%py.misc.bth%"
call :wrShort "%py.misc.bth_with_bows%"
call :wrShort "%py.misc.mana%"
call :wrShort "%py.misc.max_hp%"
call :wrShort "%py.misc.plusses_to_hit%"
call :wrShort "%py.misc.plusses_to_damage%"
call :wrShort "%py.misc.ac%"
call :wrShort "%py.misc.magical_ac%"
call :wrShort "%py.misc.display_to_hit%"
call :wrShort "%py.misc.display_to_damage%"
call :wrShort "%py.misc.display_ac%"
call :wrShort "%py.misc.disarm%"
call :wrShort "%py.misc.saving_throw%"
call :wrShort "%py.misc.social_class%"
call :wrShort "%py.misc.stealth_factor%"
call :wrByte "%py.misc.class_id%"
call :wrByte "%py.misc.race_id%"
call :wrByte "%py.misc.hit_die%"
call :wrByte "%py.misc.experience_factor%"
call :wrShort "%py.misc.current_mana%"
call :wrShort "%py.misc.current_mana_fraction%"
call :wrShort "%py.misc.current_hp%"
call :wrShort "%py.misc.current_hp_fraction%"
for /L %%A in (0,1,3) do (
    if defined py.misc.history[%%A] (
        call :wrString "!py.misc.history[%%A]!"
    )
)

call :wrBytes "py.stats.max" 6
call :wrBytes "py.stats.currrent" 6
call :wrShorts "py.stats.modified" 6
call :wrBytes "py.stats.used" 6

call :wrLong "%py.flags.status%"
call :wrShort "%py.flags.rest%"
call :wrShort "%py.flags.blind%"
call :wrShort "%py.flags.paralysis%"
call :wrShort "%py.flags.confused%"
call :wrShort "%py.flags.food%"
call :wrShort "%py.flags.food_digested%"
call :wrShort "%py.flags.protection%"
call :wrShort "%py.flags.speed%"
call :wrShort "%py.flags.fast%"
call :wrShort "%py.flags.slow%"
call :wrShort "%py.flags.afraid%"
call :wrShort "%py.flags.poisoned%"
call :wrShort "%py.flags.image%"
call :wrShort "%py.flags.protect_evil%"
call :wrShort "%py.flags.invulnerability%"
call :wrShort "%py.flags.heroism%"
call :wrShort "%py.flags.super_heroism%"
call :wrShort "%py.flags.blessed%"
call :wrShort "%py.flags.heat_resistance%"
call :wrShort "%py.flags.cold_resistance%"
call :wrShort "%py.flags.detect_invisible%"
call :wrShort "%py.flags.word_of_recall%"
call :wrShort "%py.flags.see_infra%"
call :wrShort "%py.flags.timed_infra%"
call :wrBool "%py.flags.see_invisible%"
call :wrBool "%py.flags.teleport%"
call :wrBool "%py.flags.free_action%"
call :wrBool "%py.flags.slow_digest%"
call :wrBool "%py.flags.aggravate%"
call :wrBool "%py.flags.resistant_to_fire%"
call :wrBool "%py.flags.resistant_to_cold%"
call :wrBool "%py.flags.resistant_to_acid%"
call :wrBool "%py.flags.regenerate_hp%"
call :wrBool "%py.flags.resistant_to_light%"
call :wrBool "%py.flags.free_fall%"
call :wrBool "%py.flags.sustain_str%"
call :wrBool "%py.flags.sustain_int%"
call :wrBool "%py.flags.sustain_wis%"
call :wrBool "%py.flags.sustain_con%"
call :wrBool "%py.flags.sustain_dex%"
call :wrBool "%py.flags.sustain_chr%"
call :wrBool "%py.flags.confuse_monster%"
call :wrByte "%py.flags.new_spells_to_learn%"

call :wrShort "%missiles_counter%"
call :wrLong "%dg.game_turn%"
call :wrShort "%py.pack.unique_items%"

:: stupid C LSS-instead-of-LEQ for loop syntax...
set /a counter_dec=%py.pack.unique_items%-1
for /L %%A in (0,1,%counter_dec%) do call :wrItem "py.inventory[%%A]"

:: Literally the only reason that I can do this is because there's a warning in
:: read_constants that explicitly says not to change the value of
:: PLAYER_INVENTORY_SIZE. If you were stupid and changed it to something else,
:: you'll have to update the 33 to whatever you changed it to minus one.
for /L %%A in (%PlayerEquipment.Wield%,1,33) do (
    call :wrItem "py.inventory[%%A]"
)

call :wrShort "%py.pack.weight%"
call :wrShort "%py.equipment_count%"
call :wrLong "%py.flags.spells_learnt%"
call :wrLong "%py.flags.spells_worked%"
call :wrLong "%py.flags.spells_forgotten%"
call :wrBytes "py.flags.spells_learned_order" 32
call :wrBytes "objects_identified" %object_ident_size%
call :wrLong "%game.magic_seed%"
call :wrLong "%game.town_seed%"
call :wrShort "%last_message_id%"
for /L %%A in (0,1,21) do (
    if defined messages[%%A] (
        call :wrString "!messages[%%A]!"
    )
)

call :wrShort "%panic_save%"
call :wrShort "%game.total_winner%"
call :wrShort "%game.noscore%"
call :wrShorts "py.base_hp_levels" %player_max_level%

for /L %%A in (0,1,5) do (
    call :wrLong "!stores[%%A].turns_left_before_closing!"
    call :wrShort "!store[%%A].insults_counter!"
    call :wrByte "!store[%%A].owner_id!"
    call :wrByte "!store[%%A].unique_items_counter!"
    call :wrShort "!store[%%A].good_purchases!"
    call :wrShort "!store[%%A].bad_purchases!"

    set /a counter_dec=!store[%%A].unique_items_counter!-1
    for /L %%B in (0,1,!counter_dec!) do (
        call :wrLong "!stores[%%A].inventory[%%B].cost!"
        call :wrItem "stores[%%A].inventory[%%B].item"
    )
)

call helpers.cmd :getCurrentUnixTime l
if !l! LSS %start_time% (
    set /a l=%start_time%+86400
)
call :wrLong "!l!"

call :wrString "%game.character_died_from%"

call scores.cmd :playerCalculateTotalPoints
call :wrLong "!errorlevel!"

call :wrLong "%py.misc.date_of_birth%"

:: If the character is dead, don't bother saving dungeon info
if "%game.character_is_dead%"=="true" (
    if exist "%config.files.save_game%" (
        exit /b 0
    ) else (
        exit /b 1
    )
)

call :wrShort "%dg.current_level%"
call :wrShort "%py.pos.y%"
call :wrShort "%py.pos.x%"
call :wrShort "%monster_multiply_total%"
call :wrShort "%dg.height%"
call :wrShort "%dg.width%"
call :wrShort "%dg.panel.max_rows%"
call :wrShort "%dg.panel.max_cols%"

for /L %%Y in (0,1,%max_height%) do (
    for /L %%X in (0,1,%max_width%) do (
        REM This is just me being lazy
        if defined dg.floor[%%Y][%%X].creature_id (
            if not "!dg.floor[%%Y][%%X].creature_id!"=="0" (
                call :wrByte "%%~Y"
                call :wrByte "%%~X"
                call :wrByte "!dg.floor[%%Y][%%X].creature_id!"
            )
        )
    )
)

:: Mark the end of the creature info
call :wrByte "255"

for /L %%Y in (0,1,%max_height%) do (
    for /L %%X in (0,1,%max_width%) do (
        REM This is just me being lazy
        if defined dg.floor[%%Y][%%X].treasure_id (
            if not "!dg.floor[%%Y][%%X].treasure_id!"=="0" (
                call :wrByte "%%~Y"
                call :wrByte "%%~X"
                call :wrByte "!dg.floor[%%Y][%%X].treasure_id!"
            )
        )
    )
)

:: Mark the end of the treasure info
call :wrByte "255"

set "count=0"
set "prev_char=0"
for /L %%Y in (0,1,65) do (
    for /L %%X in (0,1,197) do (
        set /a "char_tmp=!dg.floor[%%Y][%%X].feature_id!"
        set /a "char_tmp|=(!dg.floor[%%Y][%%X].perma_lit_room! << 4)"
        set /a "char_tmp|=(!dg.floor[%%Y][%%X].field_mark! << 5)"
        set /a "char_tmp|=(!dg.floor[%%Y][%%X].permanent_light! << 6)"
        set /a "char_tmp|=(!dg.floor[%%Y][%%X].temporary_light! << 7)"

        if not "!char_tmp!"=="!prev_char!" (
            call :wrByte "!count!"
            call :wrByte "!prev_char!"
            set "prev_char=!char_tmp!"
            set "count=1"
        ) else if "!count!"=="255" (
            call :wrByte "!count!"
            call :wrByte "!prev_char!"
            set "prev_char=!char_tmp!"
            set "count=1"
        ) else (
            set /a count+=1
        )
    )
)

call :wrByte "!count!"
call :wrByte "!prev_char!"

call :wrShort "%game.treasure.current_id%"
set /a counter_dec=%game.treasure_id%-1
for /L %%A in (%config.treasure.min_treasure_list_id%,1,%counter_dec%) do (
    call :wrItem "game.treasure.list[%%A]"
)
call :wrShort "%next_free_monster_id%"
set /a counter_dec=%next_free_monster_id%-1
for /L %%A in (%config.monsters.mon_min_index_id%,1,%counter_dec%) do (
    call :wrMonster "monsters[%%A]"
)

if exist "%config.files.save_game%" (
    exit /b 0
) else (
    exit /b 1
)

::------------------------------------------------------------------------------
:: A wrapper for svWrite that includes the current version and encryption byte
::
:: Arguments: %1 - The name of the file to save the data in
:: Returns:   0 if the file was successfully saved
::            1 if issues were encountered during the save process
::------------------------------------------------------------------------------
:saveChar
if "%game.character_saved%"=="true" exit /b 0

set "fileptr=%~1.hex"
call ui_io.cmd :putQIO
call player.cmd :playerDisturb 1 0
call player.cmd :playerChangeSpeed -%py.pack.heaviness%
set "py.pack.heaviness=0"
set "ok=false"

set "xor_byte=0"
call :wrByte "%current_version_major%"
set "xor_byte=0"
call :wrByte "%current_version_minor%"
set "xor_byte=0"
call :wrByte "%current_version_patch%"
set "xor_byte=0"

call rng.cmd :randomNumber 256
set /a char_tmp=!errorlevel!-1
call :wrByte %char_tmp%

call :svWrite
set "ok=!errorlevel!"

certutil -f -decodehex "!fileptr!" "%config.files.save_game%" >nul 2>&1
if not exist "%~1" (
    call ui_io.cmd :printMessage "Error writing to file '%~1'."
    exit /b 1
)

del "!fileptr!"

set "game.character_saved=true"
set "dg.game_turn=-1"
exit /b 0

::------------------------------------------------------------------------------
:: Load the file into memory
::
:: Arguments: %1 - The name of a variable that stores whether a new dungeon
::                 needs to be generated or not
:: Returns:   0 if the file was loaded correctly
::            1 if there was some error reading in the file
::------------------------------------------------------------------------------
:loadGame
set "fileptr=%config.files.save_game%.hex"
set "time_saved=0"
set "version_maj=0"
set "version_min=0"
set "patch_level=0"

set "%~1=true"
set "total_count=0"

if not exist "%config.files.save_game%" (
    call ui_io.cmd :printMessage "Save file does not exist."
    exit /b 1
)

certutil -f -encodehex "%config.files.save_game%" "!fileptr!" >nul 2>&1
call :countBytesInSaveFile
set "current_byte=1"

call ui_io.cmd :clearScreen
call ui_io.cmd :putString "Save file '%config.files.save_game%' present. Attempting to restore." "23;0"

if %dg.game_turn% GEQ 0 (
    set "continue_from_main_else=false"
    call ui_io.cmd :printMessage "[ERROR] Attempt to restore while still alive."
) else (
    set "continue_from_main_else=true"
    set "dg.game_turn=-1"
    set "ok=true"

    call ui_io.cmd :putStringClearToEOL "Restoring Memory..." "0;0"
    call ui_io.cmd :putQIO

    set "xor_byte=0"
    call :rdByte & set "version_maj=!errorlevel!"
    set "xor_byte=0"
    call :rdByte & set "version_min=!errorlevel!"
    set "xor_byte=0"
    call :rdByte & set "patch_level=!errorlevel!"
    call :getByte & set "xor_byte=!errorlevel!"

    call game.cmd :validGameVersion !version_maj! !version_min! !patch_level! || (
        call ui_io.cmd :putStringClearToEOL "Sorry. This save file is from a different version of Moria." "2;0"
        goto :error
    )

    call :rdShort & set "uint_16_t_tmp=!errorlevel!"
    call :loadCreatures || goto :error

    call :rdLong & set "l=!errorlevel!"
    call :andOffsetExists "config.options.run_cut_corners" "0x1"
    call :andOffsetExists "config.options.run_examine_corners" "0x2"
    call :andOffsetExists "config.options.run_print_self" "0x4"
    call :andOffsetExists "config.options.find_bound" "0x8"
    call :andOffsetExists "config.options.prompt_to_pickup" "0x10"
    call :andOffsetExists "config.options.use_roguelike_keys" "0x20"
    call :andOffsetExists "config.options.show_inventory_weights" "0x40"
    call :andOffsetExists "config.options.highlight_seams" "0x80"
    call :andOffsetExists "config.options.run_ignore_doors" "0x100"
    call :andOffsetExists "config.options.error_beep_sound" "0x200"
    call :andOffsetExists "config.options.display_counts" "0x400"

    REM Don't allow resurrection of game.total_winner characters because
    REM the character level is greater than the maximum allowed level.
    set /a "beat_game=!l! & 0x40000000"
    set /a "dead_character=!l! & 0x80000000"
    if "%game.to_be_wizard%"=="true" (
        if not "!beat_game!"=="0" (
            call ui_io.cmd :printMessage "Sorry, this character is retired from Moria."
            call ui_io.cmd :printMessage "You cannot resurrect a retired character."
        )

        if not "!dead_character!"=="0" (
            call ui_io.cmd :getInputConfirmation "Resurrect a dead character?" && (
                set /a "l&=~0x80000000"
            )
        )
    )

    if "!dead_character!"=="0" (
        call :rdString "py.misc.name"
        call :rdBool & set "py.misc.gender=!errorlevel!"
        call :rdLong & set "py.misc.au=!errorlevel!"
        call :rdLong & set "py.misc.max_exp=!errorlevel!"
        call :rdLong & set "py.misc.exp=!errorlevel!"
        call :rdShort & set "py.misc.exp_fraction=!errorlevel!"
        call :rdShort & set "py.misc.age=!errorlevel!"
        call :rdShort & set "py.misc.height=!errorlevel!"
        call :rdShort & set "py.misc.weight=!errorlevel!"
        call :rdShort & set "py.misc.level=!errorlevel!"
        call :rdShort & set "py.misc.max_dungeon_depth=!errorlevel!"
        call :rdShort & set "py.misc.chance_in_search=!errorlevel!"
        call :rdShort & set "py.misc.fos=!errorlevel!"
        call :rdShort & set "py.misc.bth=!errorlevel!"
        call :rdShort & set "py.misc.bth_with_bows=!errorlevel!"
        call :rdShort & set "py.misc.mana=!errorlevel!"
        call :rdShort & set "py.misc.max_hp=!errorlevel!"
        call :rdShort & set "py.misc.plusses_to_hit=!errorlevel!"
        call :rdShort & set "py.misc.plusses_to_damage=!errorlevel!"
        call :rdShort & set "py.misc.ac=!errorlevel!"
        call :rdShort & set "py.misc.magical_ac=!errorlevel!"
        call :rdShort & set "py.misc.display_to_hit=!errorlevel!"
        call :rdShort & set "py.misc.display_to_damage=!errorlevel!"
        call :rdShort & set "py.misc.display_ac=!errorlevel!"
        call :rdShort & set "py.misc.display_to_ac=!errorlevel!"
        call :rdShort & set "py.misc.disarm=!errorlevel!"
        call :rdShort & set "py.misc.saving_throw=!errorlevel!"
        call :rdShort & set "py.misc.social_class=!errorlevel!"
        call :rdShort & set "py.misc.stealth_factor=!errorlevel!"
        call :rdByte & set "py.misc.class_id=!errorlevel!"
        call :rdByte & set "py.misc.race_id=!errorlevel!"
        call :rdByte & set "py.misc.hit_die=!errorlevel!"
        call :rdByte & set "py.misc.experience_factor=!errorlevel!"
        call :rdShort & set "py.misc.current_mana=!errorlevel!"
        call :rdShort & set "py.misc.current_mana_fraction=!errorlevel!"
        call :rdShort & set "py.misc.current_hp=!errorlevel!"
        call :rdShort & set "py.misc.current_hp_fraction=!errorlevel!"
        for /L %%A in (0,1,3) do (
            call :rdString "py.misc.history[%%A]"
        )

        call :rdBytes "py.stats.max" 6
        call :rdBytes "py.stats.current" 6
        call :rdShorts "py.stats.modified" 6
        call :rdBytes "py.stats.used" 6

        call :rdLong & set "py.flags.status=!errorlevel!"
        call :rdShort & set "py.flags.rest=!errorlevel!"
        call :rdShort & set "py.flags.blind=!errorlevel!"
        call :rdShort & set "py.flags.paralysis=!errorlevel!"
        call :rdShort & set "py.flags.confused=!errorlevel!"
        call :rdShort & set "py.flags.food=!errorlevel!"
        call :rdShort & set "py.flags.food_digested=!errorlevel!"
        call :rdShort & set "py.flags.protection=!errorlevel!"
        call :rdShort & set "py.flags.speed=!errorlevel!"
        call :rdShort & set "py.flags.fast=!errorlevel!"
        call :rdShort & set "py.flags.slow=!errorlevel!"
        call :rdShort & set "py.flags.afraid=!errorlevel!"
        call :rdShort & set "py.flags.poisoned=!errorlevel!"
        call :rdShort & set "py.flags.image=!errorlevel!"
        call :rdShort & set "py.flags.protect_evil=!errorlevel!"
        call :rdShort & set "py.flags.invulnerability=!errorlevel!"
        call :rdShort & set "py.flags.heroism=!errorlevel!"
        call :rdShort & set "py.flags.super_heroism=!errorlevel!"
        call :rdShort & set "py.flags.blessed=!errorlevel!"
        call :rdShort & set "py.flags.heat_resistance=!errorlevel!"
        call :rdShort & set "py.flags.cold_resistance=!errorlevel!"
        call :rdShort & set "py.flags.detect_invisible=!errorlevel!"
        call :rdShort & set "py.flags.word_of_recall=!errorlevel!"
        call :rdShort & set "py.flags.see_infra=!errorlevel!"
        call :rdShort & set "py.flags.timed_infra=!errorlevel!"
        call :rdBool & set "py.flags.see_invisible=!errorlevel!"
        call :rdBool & set "py.flags.teleport=!errorlevel!"
        call :rdBool & set "py.flags.free_action=!errorlevel!"
        call :rdBool & set "py.flags.slow_digest=!errorlevel!"
        call :rdBool & set "py.flags.aggravate=!errorlevel!"
        call :rdBool & set "py.flags.resistant_to_fire=!errorlevel!"
        call :rdBool & set "py.flags.resistant_to_cold=!errorlevel!"
        call :rdBool & set "py.flags.resistant_to_acid=!errorlevel!"
        call :rdBool & set "py.flags.regenerate_hp=!errorlevel!"
        call :rdBool & set "py.flags.resistant_to_light=!errorlevel!"
        call :rdBool & set "py.flags.free_fall=!errorlevel!"
        call :rdBool & set "py.flags.sustain_str=!errorlevel!"
        call :rdBool & set "py.flags.sustain_int=!errorlevel!"
        call :rdBool & set "py.flags.sustain_wis=!errorlevel!"
        call :rdBool & set "py.flags.sustain_con=!errorlevel!"
        call :rdBool & set "py.flags.sustain_dex=!errorlevel!"
        call :rdBool & set "py.flags.sustain_chr=!errorlevel!"
        call :rdBool & set "py.flags.confuse_monster=!errorlevel!"
        call :rdByte & set "py.flags.new_spells_to_learn=!errorlevel!"

        call :rdShort & set "missiles_counter=!errorlevel!"
        call :rdLong & set "dg.game_turn=!errorlevel!"
        call :rdShort & set "py.pack.unique_items=!errorlevel!"
        if !py.pack.unique_items! GTR %PlayerEquipment.Wield% (
            goto :error
        )
        set /a counter_dec=!py.pack.unique_items!-1
        for /L %%A in (0,1,!counter_dec!) do (
            call :rdItem "py.inventory[%%A]"
        )
        set /a counter_dec=%PLAYER_INVENTORY_SIZE%-1
        for /L %%A in (%PlayerEquipment.Wield%,1,!counter_dec!) do (
            call :rdItem "py.inventory[%%A]"
        )
        call :rdShort & set "py.pack.weight=!errorlevel!"
        call :rdShort & set "py.equipment_count=!errorlevel!"
        call :rdLong & set "py.flags.spells_learnt=!errorlevel!"
        call :rdLong & set "py.flags.spells_worked=!errorlevel!"
        call :rdLong & set "py.flags.spells_forgotten=!errorlevel!"
        call :rdBytes "py.flags.spells_learned_order" 32
        call :rdBytes "objects_identified" %object_ident_size%
        call :rdLong & set "game.magic_seed=!errorlevel!"
        call :rdLong & set "game.town_seed=!errorlevel!"
        call :rdShort & set "last_message_id=!errorlevel!"
        for /L %%A in (0,1,21) do call :rdString !messages[%%A]!

        call :rdShort & set "panic_save_short=!errorlevel!"
        call :rdShort & set "total_winner_short=!errorlevel!"
        if "!panic_save_short!"=="0" (
            set "panic_save=false"
        ) else (
            set "panic_save=true"
        )
        if "!total_winner_short!"=="0" (
            set "game.total_winner=false"
        ) else (
            set "game.total_winner=true"
        )
        
        call :rdShort & set "game.noscore=!errorlevel!"
        call :rdShorts "py.base_hp_levels" %player_max_level%

        for /L %%A in (0,1,5) do (
            call :rdLong & set "stores[%%A].turns_left_before_closing=!errorlevel!"
            call :rdShort & set "stores[%%A].insults_counter=!errorlevel!"
            call :rdByte & set "stores[%%A].owner_id=!errorlevel!"
            call :rdByte & set "stores[%%A].unique_items_counter=!errorlevel!"
            call :rdShort & set "stores[%%A].good_purchases=!errorlevel!"
            call :rdShort & set "stores[%%A].bad_purchases=!errorlevel!"

            if !stores[%%A].unique_items_counter! GTR %store_max_discrete_items% (
                goto :error
            )
            set /a counter_dec=!stores[%%A].unique_items_counter!-1
            for /L %%B in (0,1,!counter_dec!) do (
                call :rdLong & set "stores[%%A].inventory[%%B].cost=!errorlevel!"
                call :rdItem "stores[%%A].inventory[%%B].item"
            )
        )

        call :rdLong & set "time_saved=!errorlevel!"
        call :rdString "game.character_died_from"
        call :rdLong & set "py.max_score=!errorlevel!"
        call :rdLong & set "py.misc.date_of_birth=!errorlevel!"
    )

    REM Dead characters don't have data beyond this point
    set /a "is_dead_bit=!l! & 0x800000000"
    set "try_res=0"
    if "!current_byte!"=="!total_bytes!" set "try_res=1"
    if not "!is_dead_bit!"=="0" set "try_res=1"

    if "!try_res!"=="1"(
        if "!is_dead_bit!"=="0" (
            if "%game.to_be_wizard%"=="false" goto :error
            if %dg.game_turn% LSS 0 goto :error

            call ui_io.cmd :putStringClearToEOL "Attempting a resurrection..." "0;0"
            if !py.misc.current_hp! LSS 0 (
                set "py.misc.current_hp=0"
                set "py.misc.current_hp_fraction=0"
            )

            if !py.flags.food! LSS 0 set "py.flags.food=0"
            if !py.flags.poisoned! LSS 0 set "py.flags.poisoned=0"
            set "dg.current_level=0"
            set "game.character_generated=true"
            set "game.to_be_wizard=false"
            set /a "game.noscore|=0x1"
        ) else (
            call ui_io.cmd :printMessage :Restoring Memory of a departed spirit...
            set "dg.game_turn=-1"
        )
        call ui_io.cmd :putQIO
        goto :closefiles
    )


    call ui_io.cmd :putStringClearToEOL "Restoring Character..." "0;0"
    call ui_io.cmd :putQIO

    call :rdShort & set "dg.current_level=!errorlevel!"
    call :rdShort & set "py.pos.y=!errorlevel!"
    call :rdShort & set "py.pos.x=!errorlevel!"
    call :rdShort & set "monster_multiply_total=!errorlevel!"
    call :rdShort & set "dg.height=!errorlevel!"
    call :rdShort & set "dg.weight=!errorlevel!"
    call :rdShort & set "dg.panel.max_rows=!errorlevel!"
    call :rdShort & set "dg.panel.max_cols=!errorlevel!"

    call :rdByte & set "char_tmp=!errorlevel!"
    call :readCreatures || goto :error
    call :rdByte & set "char_tmp=!errorlevel!"
    call :readTreasures || goto :error

    set /a "tile_count=0", "total_count=0"
    set /a full_dimensions=%max_height%*%max_width%
    call :readDungeon || goto :error

    call :rdShort & set "game.treasure.current_id=!errorlevel!"
    if !game.treasure.current_id! GTR !level_max_objects! goto :error
    set /a counter_dec=!game.treasure.current_id!-1
    for /L %%A in (%config.treasure.min_treasure_list_id%,1,!counter_dec!) do (
        call :rdItem "game.treasure.list[%%A]"
    )
    call :rdShort & set "next_free_monster_id=!errorlevel!"
    if !next_free_monster_id! GTR %mon_total_allocations% goto :error
    set /a counter_dec=!next_free_monster_id!-1
    for /L %%A in (%config.monsters.mon_min_index_id%,1,!counter_dec!) do (
        call :rdMonster "monsters[%%A]"
    )

    set "generate=false"
    if !dg.game_turn! LSS 0 (
        goto :error
    ) else (
        if !py.misc.current_hp! GEQ 0 (
            set "game.character_died_from=(alive and well)"
        )
        set "game.character_generated=true"
    )
)

:error
set "ok=false"

:closefiles
del /q "!fileptr!" >nul
if "!ok!"=="false" (
    call ui_io.cmd :printMessage "Error during reading of file."
) else (
    set "from_save_file=1"

    if "!panic_save!"=="true" (
        call :ui_io.cmd :printMessage "This game is from a panic save. Score will not be added to scoreboard."
    ) else (
        REM Batch's logical negation doesn't seem to be working for numbers other than 0
        REM so we'll just see if the number is less than 4 to see if the 0x4 bit is unset
        if !game.noscore! LSS 4 (
            call ui_io.cmd :printMessage "This character is already on the scoreboard. It will not be scored again."
            set /a "game.noscore|=0x4"
        )
    )

    if !dg.game_turn! GEQ 0 (
        set "py.weapon_is_heavy=false"
        set "py.pack.heaviness=0"
        call player.cmd :playerStrength

        call helpers.getCurrentUnixTime
        set "start_time=!errorlevel!"

        if !start_time! LSS !time_saved! (
            set "age=0"
        ) else (
            set /a age=!start_time!-!time_saved!
        )

        set /a "age=(!age! + 43200) / 86400"
        if !age! GTR 10 set "age=10"

        for /L %%A in (1,1,!age!) do (
            call store_inventory.cmd :storeMaintenance
        )
    )

    if not "!game.noscore!"=="0" (
        call ui_io.cmd :printMessage "This save file cannot be used to get on to the score board."
    )
    call game.cmd :validGameVersion !version_maj! !version_min! !patch_level!
    if "!errorlevel!"=="0" (
        call game.cmd :isCurrentGameVersion !version_maj! !version_min! !patch_level!
        if "!errorlevel!"=="1" (
            call ui_io.cmd :printMessage "Save file version !version_maj!.!version_min!.!patch_level! accepted by game version %current_version_major%.%current_version_minor%."
        )
    )
    if !dg.game_turn! GEQ 0 exit /b 0
    exit /b 1
)
set "dg.game_turn=-1"
call ui_io.cmd :putStringClearToEOL "Please try again without that save file." "1;0"
call ui_io.cmd :printMessage "CNIL"
call game.cmd :exitProgram
exit /b 1

:countBytesInSaveFile
set "total_bytes=0"
for /f "usebackq delims=" %%A in ("!fileptr!") do (
	set "line=%%A"
	set "line=!line:~5,48!"
	for /f "tokens=1-16" %%B in ("!line!") do (
		if not "%%~Q"=="" (
			set /a total_bytes+=16
		) else (
            REM This is incredibly inelegant
			for %%A in (%%B %%C %%D %%E %%F %%G %%H %%I %%J %%K %%L %%M %%N %%O %%P) do (
				set /a total_bytes+=1
			)
		)
	)
)
exit /b

:loadCreatures
if "!uint_16_t_tmp!"=="65535" exit /b 0
if !uint_16_t_tmp! GEQ %mon_max_creatures% exit /b 1
call :rdLong & set "creature_recall[!uint_16_t_tmp!].movement=!errorlevel!"
call :rdLong & set "creature_recall[!uint_16_t_tmp!].spells=!errorlevel!"
call :rdShort & set "creature_recall[!uint_16_t_tmp!].kills=!errorlevel!"
call :rdShort & set "creature_recall[!uint_16_t_tmp!].deaths=!errorlevel!"
call :rdShort & set "creature_recall[!uint_16_t_tmp!].defenses=!errorlevel!"
call :rdByte & set "creature_recall[!uint_16_t_tmp!].wake=!errorlevel!"
call :rdByte & set "creature_recall[!uint_16_t_tmp!].ignore=!errorlevel!"
call :rdBytes "creature[!uint_16_t_tmp!].attacks" %mon_max_attacks%
call :rdShort & set "uint_16_t_tmp=!errorlevel!"
goto :loadCreatures

:andOffsetExists
set /a "has_value=(!l! & %~2)"
if "!has_value!"=="0" (
    set "%~1=false"
) else (
    set "%~1=true"
)
exit /b

:readCreatures
if "!char_tmp!"=="255" exit /b 0
set "ychar=!char_tmp!"
call :rdByte & set "xchar=!errorlevel!"
call :rdByte & set "char_tmp=!errorlevel!"
if !xchar! GTR %max_width% exit /b 1
if !ychar! GTR %max_height% exit /b 1
set "dg.floor[!ychar!][!xchar!].creature_id=!char_tmp!"
call :rdByte & set "char_tmp=!errorlevel!"
goto :readCreatures

:readTreasures
if "!char_tmp!"=="255" exit /b 0
set "ychar=!char_tmp!"
call :rdByte & set "xchar=!errorlevel!"
call :rdByte & set "char_tmp=!errorlevel!"
if !xchar! GTR %max_width% exit /b 1
if !ychar! GTR %max_height% exit /b 1
set "dg.floor[!ychar!][!xchar!].creature_id=!char_tmp!"
call :rdByte & set "char_tmp=!errorlevel!"
goto :readTreasures

:readDungeon
set "bool[0]=false"
set "bool[1]=true"
if "!total_count!"=="!full_dimensions!" exit /b 0
call :rdByte & set "count=!errorlevel!"
call :rdByte & set "char_tmp=!errorlevel!"
for /L %%A in (!count!,-1,1) do (
    REM If reading in !count! somehow blew past !full_dimensions!, abort.
    REM Also, this is weird because SOMEONE decided to use pointers in the C code.
    if !tile_count! GTR !full_dimensions! exit /b 1
    
    set /a tile_y=!tile_count!/198
    set /a tile_x=!tile_count!%%198
    set /a "dg.floor[!tile_y!][!tile_x!].feature_id=!char_tmp! & 0xF"

    for /f "delims=" %%B in ('set /a "(!char_tmp! >> 4) & 0x1"') do set "dg.floor[!tile_y!][!tile_x!].perma_lit_room=!bool[%%B]!"
    for /f "delims=" %%B in ('set /a "(!char_tmp! >> 5) & 0x1"') do set "dg.floor[!tile_y!][!tile_x!].field_mark=!bool[%%B]!"
    for /f "delims=" %%B in ('set /a "(!char_tmp! >> 6) & 0x1"') do set "dg.floor[!tile_y!][!tile_x!].permanent_light=!bool[%%B]!"
    for /f "delims=" %%B in ('set /a "(!char_tmp! >> 7) & 0x1"') do set "dg.floor[!tile_y!][!tile_x!].temporary_light=!bool[%%B]!"
    set /a tile_count+=1
)
set /a total_count+=!count!
goto :readDungeon

::------------------------------------------------------------------------------
:: Writes a boolean value to the save file
::
:: Arguments: %1 - The value to put into the file
:: Returns:   None
::------------------------------------------------------------------------------
:wrBool
call :wrByte %1
exit /b

::------------------------------------------------------------------------------
:: Writes a byte value to the save file as hexadecimal
::
:: Arguments: %1 - The value to put into the file
:: Returns:   None
::------------------------------------------------------------------------------
:wrByte
set /a "xor_byte^=%~1"
call :toHex !xor_byte!
<nul set /p ".=!hex!" >>"!fileptr!"
exit /b

::------------------------------------------------------------------------------
:: Writes two bytes to the save file as hexadecimal
::
:: Arguments: %1 - The value to put into the file
:: Returns:   None
::------------------------------------------------------------------------------
:wrShort
set /a "xor_byte^=%~1"
call :toHex !xor_byte!
<nul set /p ".=!hex!" >>"!fileptr!"

set /a "xor_byte^=(%~1 >> 8) & 0xFF"
call :toHex !xor_byte!
<nul set /p ".=!hex!" >>"!fileptr!"
exit /b

::------------------------------------------------------------------------------
:: Writes your bytes to the save file as hexadecimal
::
:: Arguments: %1 - The value to put into the file
:: Returns:   None
::------------------------------------------------------------------------------
:wrLong
set /a "xor_byte^=%~1"
call :toHex !xor_byte!
<nul set /p ".=!hex!" >>"!fileptr!"

set /a "xor_byte^=(%~1 >> 8) & 0xFF"
call :toHex !xor_byte!
<nul set /p ".=!hex!" >>"!fileptr!"

set /a "xor_byte^=(%~1 >> 16) & 0xFF"
call :toHex !xor_byte!
<nul set /p ".=!hex!" >>"!fileptr!"

set /a "xor_byte^=(%~1 >> 24) & 0xFF"
call :toHex !xor_byte!
<nul set /p ".=!hex!" >>"!fileptr!"
exit /b

::------------------------------------------------------------------------------
:: Writes a series of bytes to the save file
::
:: Arguments: %1 - The name of the array to write from
::            %2 - The number of elements in the array
:: Returns:   None
::------------------------------------------------------------------------------
:wrBytes
set /a loop_counter=%~2-1
for /L %%A in (0,1,!loop_counter!) do (
    call :wrByte "!%~1[%%A]!"
)
exit /b

::------------------------------------------------------------------------------
:: Writes a string to the save file one character at a time
::
:: Arguments: %1 - The string to write into the save file
:: Returns:   None
::------------------------------------------------------------------------------
:wrString
set "tmp_string=%~1"

:wrStringLoop
if "!tmp_string!"=="" goto :wrStringAfterLoop
set "next_char=!tmp_string:~0,1!"
set "tmp_string=!tmp_string:~1!"

call :charToDec "!next_char!"
set /a "xor_byte^=!dec!"
<nul set /p ".=!xor_byte!" >>"!fileptr!"
goto :wrStringLoop

:wrStringAfterLoop
:: Batch strings aren't null-terminated, but C strings are so if we don't do this
:: then umoria save files won't be compatible due to off-by-one errors
set /a "xor_byte^=0"
<nul set /p ".=!xor_byte!" >>"!fileptr!"
exit /b

::------------------------------------------------------------------------------
:: Writes a series of shorts to the save file
::
:: Arguments: %1 - The name of the array to write from
::            %2 - The number of elements in the array
:: Returns:   None
::------------------------------------------------------------------------------
:wrShorts
set /a loop_counter=%~2-1
for /L %%A in (0,1,!loop_counter!) do (
    call :wrShort "!%~1[%%A]!"
)
exit /b

::------------------------------------------------------------------------------
:: Writes an item's properties to the save file
::
:: Arguments: %1 - The name of the variable containing the item object
:: Returns:   None
::------------------------------------------------------------------------------
:wrItem
call :wrShort "!%~1.id!"
call :wrByte "!%~1.special_name_id!"
call :wrString "!%~1.inscription!"
call :wrLong "!%~1.flags!"
call :wrByte "!%~1.category_id!"
call :wrByte "!%~1.sprite!"
call :wrShort "!%~1.misc_use!"
call :wrLong "!%~1.cost!"
call :wrByte "!%~1.sub_category_id!"
call :wrByte "!%~1.items_count!"
call :wrShort "!%~1.weight!"
call :wrShort "!%~1.to_hit!"
call :wrShort "!%~1.to_damage!"
call :wrShort "!%~1.ac!"
call :wrShort "!%~1.to_ac!"
call :wrByte "!%~1.damage.dice!"
call :wrByte "!%~1.damage.sides!"
call :wrByte "!%~1.depth_first_found!"
call :wrByte "!%~1.identification!"
exit /b

::------------------------------------------------------------------------------
:: Writes a monster's properties to the save file
::
:: Arguments: %1 - The name of the variable containing the monster object
:: Returns:   None
::------------------------------------------------------------------------------
:wrMonster
call :wrShort "!%~1.hp!"
call :wrShort "!%~1.sleep_count!"
call :wrShort "!%~1.speed!"
call :wrShort "!%~1.creature_id!"
call :wrByte "!%~1.pos.y!"
call :wrByte "!%~1.pos.x!"
call :wrByte "!%~1.distance_from_player!"
call :wrBool "!%~1.lit!"
call :wrByte "!%~1.stunned_amount!"
call :wrByte "!%~1.confused_amount!"
exit /b

::------------------------------------------------------------------------------
:: Pulls a single byte from the file, without any xor_byte encryption
::
:: Arguments: None
:: Returns:   The value of the byte at the specified index
::------------------------------------------------------------------------------
:getByte
:: col gets incremented by 1 to offset the leftmost column, which is just line labels
set /a fileptr_row=!current_byte! /  16
set /a fileptr_col=!current_byte! %% 16 + 1

for /f "delims=" %%A in ('setx /F "!fileptr!" dummyvar /A !fileptr_row!,!fileptr_col! 2^>nul') do (
    set "next_byte=%%A"
    goto :getByteAfterLoop
)

:getByteAfterLoop
set /a current_byte
set /a byte_value=0x!next_byte!&0xFF
exit /b !byte_value!

::------------------------------------------------------------------------------
:: Reads a boolean value from the save file
:: Note that it made more sense for this subroutine to exist in the C code,
:: where type casting is a thing
::
:: Arguments: None
:: Returns:   either a 0 or a 1
::------------------------------------------------------------------------------
:rdBool
call :rdByte
exit /b !errorlevel!

::------------------------------------------------------------------------------
:: Reads one byte of data from the save file
::
:: Arguments: None
:: Returns:   A number between 0 and 255
::------------------------------------------------------------------------------
:rdByte
call :getByte
set "c=!errorlevel!"
set /a "decoded_byte=!c! ^ !xor_byte!"
set "xor_byte=!c!"
exit /b !decoded_byte!

::------------------------------------------------------------------------------
:: Return two bytes of data from the save file
::
:: Arguments: None
:: Returns:   A number between 0 and 65535
::------------------------------------------------------------------------------
:rdShort
call :getByte
set "c=!errorlevel!"
set /a "decoded_byte=!c! ^ !xor_byte!"

call :getByte
set "xor_byte=!errorlevel!"
set /a "decoded_int|=(!c! ^ !xor_byte!) << 8"
exit /b !decoded_int!

::------------------------------------------------------------------------------
:: Returns four bytes of data from the save file
::
:: Arguments: None
:: Returns:   A number between -2147483648 and 2147483647
:: It should have been 0 and 4294967295 but batch insisted on signed ints
::------------------------------------------------------------------------------
:rdLong
call :getByte
set "c=!errorlevel!"
set /a "decoded_long=!c! ^ !xor_byte!"

call :getByte
set "xor_byte=!errorlevel!"
set /a "decoded_long|=(!c! ^ !xor_byte!) << 8"

call :getByte
set "xor_byte=!errorlevel!"
set /a "decoded_long|=(!c! ^ !xor_byte!) << 16"

call :getByte
set "xor_byte=!errorlevel!"
set /a "decoded_long|=(!c! ^ !xor_byte!) << 24"
exit /b !decoded_long!

::------------------------------------------------------------------------------
:: Reads in a number of bytes and stores them in a specified array
::
:: Arguments: %1 - The name of the array to store the values in
::            %2 - The number of bytes to read in
:: Returns:   None
::------------------------------------------------------------------------------
:rdBytes
set /a loop_counter=%~2-1
for /L %%A in (0,1,!loop_counter!) do (
    call :rdByte
    set "%~1[%%A]=!errorlevel!"
)
exit /b

::------------------------------------------------------------------------------
:: Reads in a string from the save file
::
:: Arguments: %1 - the variable to store the string in
:: Returns:   None
::------------------------------------------------------------------------------
:rdString
call :getByte
set "c=!errorlevel!"
set /a "str=!c! ^ !xor_byte!"
set "xor_byte=!c!"
if "!str!"=="0" exit /b
cmd /c exit /b !str!
set "%~1=!%~1!!=ExitCodeAscii!"
goto :rdString

::------------------------------------------------------------------------------
:: Reads in a number of shorts and stores them in a specified array
::
:: Arguments: %1 - The name of the array to store the values in
::            %2 - The number of bytes to read in
:: Returns:   None
::------------------------------------------------------------------------------
:rdShorts
set /a loop_counter=%~2-1
for /L %%A in (0,1,!loop_counter!) do (
    call :rdShort
    set "%~1[%%A]=!errorlevel!"
)
exit /b

::------------------------------------------------------------------------------
:: Read in the properties of an item
::
:: Arguments: %1 - The name of the item whose properties are being read in
:: Returns:   None
::------------------------------------------------------------------------------
:rdItem
call :rdShort & set "%~1.id=!errorlevel!"
call :rdByte & set "%~1.special_name_id=!errorlevel!"
call :rdString "%1.inscription"
call :rdLong & set "%~1.flags=!errorlevel!"
call :rdByte & set "%~1.category_id=!errorlevel!"
call :rdByte & set "%~1.sprite=!errorlevel!"
call :rdShort & set "%~1.misc.use=!errorlevel!"
call :rdLong & set "%~1.cost=!errorlevel!"
call :rdByte & set "%~1.sub_category_id=!errorlevel!"
call :rdByte & set "%~1.items_count=!errorlevel!"
call :rdShort & set "%~1.weight=!errorlevel!"
call :rdShort & set "%~1.to_hit=!errorlevel!"
call :rdShort & set "%~1.to_damage=!errorlevel!"
call :rdShort & set "%~1.ac=!errorlevel!"
call :rdShort & set "%~1.to_ac=!errorlevel!"
call :rdByte & set "%~1.damage.dice=!errorlevel!"
call :rdByte & set "%~1.damage.sides=!errorlevel!"
call :rdByte & set "%~1.depth_first_found=!errorlevel!"
call :rdByte & set "%~1.identification=!errorlevel!"
exit /b

::------------------------------------------------------------------------------
:: Reads in the properties of a monster
::
:: Arguments: %1 - The name of the monster whose properties are being read in
:: Returns:   None
::------------------------------------------------------------------------------
:rdMonster
call :rdShort & set "%~1.hp=!errorlevel!"
call :rdShort & set "%~1.sleep_count=!errorlevel!"
call :rdShort & set "%~1.speed=!errorlevel!"
call :rdShort & set "%~1.creature_id=!errorlevel!"
call :rdByte & set "%~1.pos.y=!errorlevel!"
call :rdByte & set "%~1.pos.x=!errorlevel!"
call :rdByte & set "%~1.distance_from_player=!errorlevel!"
call :rdBool & set "%~1.lit=!errorlevel!"
call :rdByte & set "%~1.stunned_amount=!errorlevel!"
call :rdByte & set "%~1.confused_amount=!errorlevel!"
exit /b

::------------------------------------------------------------------------------
:: Sets the local filepointer to the score file filepointer
:: Used by death.cmd to implement the score file
::
:: Arguments: %1 - The new filename to use for I/O operations
:: Returns:   None
::------------------------------------------------------------------------------
:setFileptr
set "fileptr=%1"
exit /b

::------------------------------------------------------------------------------
:: Writes a high score to the High Score file
::
:: Arguments: %1 - The name of the HighScore object
:: Returns:   None
::------------------------------------------------------------------------------
:saveHighScore
call :wrByte "!xor_byte!"

call :wrLong "!%~1.points!"
call :wrLong "!%~1.birth_date!"
call :wrShort "!%~1.uid!"
call :wrShort "!%~1.mhp!"
call :wrShort "!%~1.chp!"
call :wrByte "!%~1.dungeon_depth!"
call :wrByte "!%~1.level!"
call :wrByte "!%~1.deepest_dungeon_depth!"
call :wrByte "!%~1.gender!"
call :wrByte "!%~1.race!"
call :wrByte "!%~1.character_class!"
call :wrBytes "!%~1.name!" %player_name_size%
call :wrBytes "!%~1.died_from!" 25
exit /b

::------------------------------------------------------------------------------
:: Reads a high score from the High Score file
::
:: Arguments: %1 - The name of the HighScore object
:: Returns:   None
::------------------------------------------------------------------------------
:readHighScore
call :getByte & set "xor_byte=!errorlevel!"

call :rdLong & set "%~1.points=!errorlevel!"
call :rdLong & set "%~1.birth_date=!errorlevel!"
call :rdShort & set "%~1.uid=!errorlevel!"
call :rdShort & set "%~1.mhp=!errorlevel!"
call :rdShort & set "%~1.chp=!errorlevel!"
call :rdByte & set "%~1.dungeon_depth=!errorlevel!"
call :rdByte & set "%~1.level=!errorlevel!"
call :rdByte & set "%~1.deepest_dungeon_depth=!errorlevel!"
call :rdByte & set "%~1.gender=!errorlevel!"
call :rdByte & set "%~1.race=!errorlevel!"
call :rdByte & set "%~1.character_class=!errorlevel!"
call :rdBytes "%~1.name" %player_name_size%
call :rdBytes "%~1.died_from" 25
exit /b

::------------------------------------------------------------------------------
:: Converts an integer to a two-digit hexadecimal value
:: Heavily based on https://www.dostips.com/DtCodeCmdLib.php#toHex
::
:: Arguments: %1 - The decimal value to convert
:: Returns:   None
::------------------------------------------------------------------------------
:toHex
set /a dec=%~1
set "hex="
set "map=0123456789ABCDEF"
for /L %%N in (1,1,8) do (
    set /a "d=dec&15,dec>>=4"
    for %%D in (!d!) do set "hex=!map:~%%D,1!!hex!"
)
set "hex=!hex:~-2!"
exit /b

::------------------------------------------------------------------------------
:: Converts a string character to its decimal ASCII value
:: From https://www.dostips.com/forum/viewtopic.php?p=45405#p45405
::
:: Arguments: %1 - The character to convert
:: Returns:   None
::------------------------------------------------------------------------------
:charToDec
<nul set /p ".=%~1" >"%~1.tmp"

for %%a in (%1) do fsutil file createnew zero.tmp %%~Za > NUL
set "hex="
set "dec="
for /F "skip=1 tokens=2" %%a in ('fc /B %1 zero.tmp') do (
   set /A "d=0x%%a"
   set "dec=!dec!!d!"
)
del zero.tmp "%~1.tmp"

exit /b