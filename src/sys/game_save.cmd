::------------------------------------------------------------------------------
:: Because of how batch interacts with files compared to how C interacts with
:: files, there are significant changes from the original code. However, the
:: choice to write encrypted bytes to the file instead of writing values
:: directly has been emulated as closely as possible in order to be able to
:: load in save files from the original game. Since everything in batch is
:: either a string or a signed 32-bit integer, everything that's not :wrString
:: or :wrLong is probably gonna look weird.
::------------------------------------------------------------------------------
@echo off
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
        call :wrBytes !creature_recall[%%A].attacks! %mon_max_attacks%
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

call :wrBytes "%py.stats.max%" 6
call :wrBytes "%py.stats.currrent%" 6
call :wrShorts "%py.stats.modified%" 6
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

        if not "!char_temp!"=="!prev_char!" (
            call :wrByte "!count!"
            call :wrByte "!prev_char!"
            set "prev_char=!char_temp!"
            set "count=1"
        ) else if "!count!"=="255" (
            call :wrByte "!count!"
            call :wrByte "!prev_char!"
            set "prev_char=!char_temp!"
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

if not exist "%~1" (
    call ui_io.cmd :printMessage "Error writing to file '%~1'."
    exit /b 1
)

set "game.character_saved=true"
set "dg.game_turn=-1"
exit /b 0

:loadGame
exit /b

:wrBool
exit /b

:wrByte
exit /b

:wrShort
exit /b

:wrLong
exit /b

:wrBytes
exit /b

:wrString
exit /b

:wrShorts
exit /b

:wrItem
exit /b

:wrMonster
exit /b

:getByte
exit /b

:rdBool
exit /b

:rdByte
exit /b

:rdShort
exit /b

:rdLong
exit /b

:rdBytes
exit /b

:rdString
exit /b

:rdShorts
exit /b

:rdItem
exit /b

:rdMonster
exit /b

:setFileptr
exit /b

:saveHighScore
exit /b

:readHighScore
exit /b
