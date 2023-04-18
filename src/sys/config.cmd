::------------------------------------------------------------------------------
:: A port of config.cpp
::------------------------------------------------------------------------------
@echo off

:: Data files used by bmoria
:: Use relative paths to the main.cmd script
set "config.files.splash_screen=..\data\splash.txt"
set "config.files.welcome_screen=..\data\welcome.txt"
set "config.files.license=..\LICENSE"
set "config.files.versions_history=..\data\versions.txt"
set "config.files.help=..\data\help.txt"
set "config.files.help_wizard=..\data\help_wizard.txt"
set "config.files.help_roguelike=..\data\rl_help.txt"
set "config.files.help_roguelike_wizard=..\data\rl_help_wizard.txt"
set "config.files.death_tomb=..\data\death_tomb.txt"
set "config.files.death_royal=..\data\death_royal.txt"
set "config.files.scores=..\scores.dat"
set "config.files.save_game=..\game.sav"

:: Game options as set on startup and with '=' set options command
set "config.options.display_counts=true"          %= Display rest/repeat counts =%
set "config.options.find_bound=false"             %= Print yourself on a run (slower) =%
set "config.options.run_cut_corners=true"         %= Cut corners while running =%
set "config.options.run_examine_corners=true"     %= Check corners while running =%
set "config.options.run_ignore_doors=false"       %= Run through open doors =%
set "config.options.run_print_self=false"         %= Stop running when the map shifts =%
set "config.options.highlight_seams=false"        %= Highlight magma and quartz veins =%
set "config.options.prompt_to_pickup=false"       %= Prompt to pick something up =%
set "config.options.use_roguelike_keys=false"     %= Use classic Roguelike keys =%
set "config.options.show_inventory_weights=false" %= Display weights in inventory =%
set "config.options.error_beep_sound=true"        %= Beep for invalid characters =%

:: Dungeon generation values
:: The entire design of the dungeon can be changed by only slight adjustments here
set "config.dungeon.dun_random_dir=9"       %= 1/x chance of random direction =%
set "config.dungeon.dun_dir_change=70"      %= Chance of changing direction (99 max) =%
set "config.dungeon.dun_tunneling=15"       %= Chance of extra tunnelling =%
set "config.dungeon.dun_rooms_mean=32"      %= Mean of number of rooms, stddev 2 =%
set "config.dungeon.dun_room_doors=25"      %= Percent chance of room doors =%
set "config.dungeon.dun_tunnel_doors=15"    %= Percent chance of doors at tunnel junctions =%
set "config.dungeon.dun_streamer_density=5" %= Density of streamers =%
set "config.dungeon.dun_streamer_width=2"   %= Width of streamers =%
set "config.dungeon.dun_magma_streamer=3"   %= Number of magma streamers =%
set "config.dungeon.dun_magma_treasure=90"  %= 1/x chance of treasure per magme =%
set "config.dungeon.dun_quartz_streamer=2"  %= Number of quartz streamers =%
set "config.dungeon.dun_quartz_treasure=40" %= 1/x chance of treasure per quartz =%
set "config.dungeon.dun_unusual_rooms=300"  %= level/x chance of unusual room =%

set "config.dungeon.objects.obj_open_door=367"
set "config.dungeon.objects.obj_closed_door=368"
set "config.dungeon.objects.obj_secret_door=369"
set "config.dungeon.objects.obj_up_stair=370"
set "config.dungeon.objects.obj_down_stair=371"
set "config.dungeon.objects.obj_store_door=372"
set "config.dungeon.objects.obj_trap_list=378"
set "config.dungeon.objects.obj_rubble=396"
set "config.dungeon.objects.obj_mush=397"
set "config.dungeon.objects.obj_scare_mon=398"
set "config.dungeon.objects.obj_gold_list=399"
set "config.dungeon.objects.obj_nothing=417"
set "config.dungeon.objects.obj_ruined_chest=418"
set "config.dungeon.objects.obj_wizard=419"

set "config.dungeon.objects.max_gold_types=18" %= Number of different types of gold =%
set "config.dungeon.objects.max_traps=18"      %= Number of defined traps =%

set "config.dungeon.objects.level_objects_per_room=7"     %= Amount of objects for rooms =%
set "config.dungeon.objects.level_objects_per_corridor=2" %= Amount of objects for corridors =%
set "config.dungeon.objects.level_total_gold_and_gems=2"  %= Amount of gold and gems =%

:: Number of special objects and degree of enchantments can be adjusted here
set "config.treasure.min_treasure_list_id=1"           %= Minimum treasure_list index used =%
set "config.treasure.treasure_chance_of_great_item=12" %= 1/x chance of item being a Great Item =%

:: Magic Treasure Generation constants
set "config.treasure.level_std_object_adjust=125"      %= Adjust STD per level*100 =%
set "config.treasure.level_min_object_std=7"           %= Minimum STD =%
set "config.treasure.level_town_objects=7"             %= Town object generation level =%
set "config.treasure.object_base_magic=15"             %= Base amount of magic =%
set "config.treasure.object_max_base_magic=70"         %= Max amount of magic =%
set "config.treasure.object_chance_special=6"          %= magic_chance/# special magic =%
set "config.treasure.object_chance_cursed=13"          %= 10*magic_chance/# cursed items =%

:: Constants describing limits of certain objects
set "config.treasure.object_lamp_max_capacity=15000"   %= Maximum amount that lamp can be filled =%
set "config.treasure.object_bolts_max_range=18"        %= Maximimum range of bolts and balls =%
set "config.treasure.object_rune_protection=3000"      %= Rune of protection resistance =%

:: Definitions for objects that can be worn
set "config.treasure.flags.tr_stats=63"  %= stats must be the low 6 bits =%
set "config.treasure.flags.tr_str=1"
set "config.treasure.flags.tr_int=2"
set "config.treasure.flags.tr_wis=4"
set "config.treasure.flags.tr_dex=8"
set "config.treasure.flags.tr_con=16"
set "config.treasure.flags.tr_chr=32"
set "config.treasure.flags.tr_search=64"
set "config.treasure.flags.tr_slow_digest=128"
set "config.treasure.flags.tr_stealth=256"
set "config.treasure.flags.tr_aggravate=512"
set "config.treasure.flags.tr_teleport=1024"
set "config.treasure.flags.tr_regen=2048"
set "config.treasure.flags.tr_speed=4096"

set "config.treasure.flags.tr_ego_weapon=516096"
set "config.treasure.flags.tr_slay_dragon=8192"
set "config.treasure.flags.tr_slay_animal=16384"
set "config.treasure.flags.tr_slay_evil=32768"
set "config.treasure.flags.tr_slay_undead=65536"
set "config.treasure.flags.tr_frost_brand=131072"
set "config.treasure.flags.tr_flame_tongue=262144"

set "config.treasure.flags.tr_res_fire=524288"
set "config.treasure.flags.tr_res_acid=1048576"
set "config.treasure.flags.tr_res_cold=2097152"
set "config.treasure.flags.tr_sust_stat=4194304"
set "config.treasure.flags.tr_free_act=8388608"
set "config.treasure.flags.tr_see_invis=16777216"
set "config.treasure.flags.tr_res_light=33554432"
set "config.treasure.flags.tr_ffall=67108864"
set "config.treasure.flags.tr_blind=134217728"
set "config.treasure.flags.tr_timid=268435456"
set "config.treasure.flags.tr_tunnel=536870912"
set "config.treasure.flags.tr_infra=1073741824"
set "config.treasure.flags.tr_cursed=2147483648"

:: Definitions for chests
set "config.treasure.chests.ch_locked=1"
set "config.treasure.chests.ch_trapped=496"
set "config.treasure.chests.ch_lose_str=16"
set "config.treasure.chests.ch_poison=32"
set "config.treasure.chests.ch_paralysed=64"
set "config.treasure.chests.ch_explode=128"
set "config.treasure.chests.ch_summon=256"

:: Definitions for creatures
set "config.monsters.mon_chance_of_new=160"            %= 1/x chance of new monster each round =%
set "config.monsters.mon_max_sight=20"                 %= Maximum distance a creature can be seen =%
set "config.monsters.mon_max_spell_cast_distance=20"   %= Maximum distance a creature spell can be cast =%
set "config.monsters.mon_max_multiply_per_level=75"    %= Maximum reproductions on a level =%
set "config.monsters.mon_multiply_adjust=7"            %= High value slows multiplication =%
set "config.monsters.mon_chance_of_nasty=50"           %= 1/x chance of high-level creature =%
set "config.monsters.mon_min_per_level=14"             %= Minimum number of monsters per level =%
set "config.monsters.mon_min_townsfolk_day=4"          %= Number of people on town level during day =%
set "config.monsters.mon_min_townsfolk_night=8"        %= Number of people on towl level during night =%
set "config.monsters.mon_endgame_monsters=2"           %= Total number of 'win' creatures =%
set "config.monsters.mon_endgame_level=50"             %= Level where winning creatures begin =%
set "config.monsters.mon_summoned_level_adjust=2"      %= Adjust level of summoned creatures =%
set "config.monsters.mon_player_exp_drained_per_hit=2" %= Percent of player exp drained per hit =%
set "config.monsters.mon_min_index_id=2"               %= Minimum index in m_list (1=py, 0=no mon) =%
set "config.monsters.scare_monster=99"

:: Definitions for creatures, cmove field
set "config.monsters.move.cm_all_mv_flags=63"
set "config.monsters.move.cm_attack_only=1"
set "config.monsters.move.cm_move_normal=2"
set "config.monsters.move.cm_only_magic=4"   %= for Quylthulgs, which have no physical movement =%

set "config.monsters.move.cm_random_move=56"
set "config.monsters.move.cm_20_random=8"
set "config.monsters.move.cm_40_random=16"
set "config.monsters.move.cm_75_random=32"

set "config.monsters.move.cm_special=4128768"
set "config.monsters.move.cm_invisible=65536"
set "config.monsters.move.cm_open_door=131072"
set "config.monsters.move.cm_phase=262144"
set "config.monsters.move.cm_eats_other=524288"
set "config.monsters.move.cm_picks_up=1048576"
set "config.monsters.move.cm_multiply=2097152"

set "config.monsters.move.cm_small_obj=8388608"
set "config.monsters.move.cm_carry_obj=16777216"
set "config.monsters.move.cm_carry_gold=33554432"
set "config.monsters.move.cm_treasure=2080374784"
set "config.monsters.move.cm_tr_shift=26"    %= used for recall of treasure =%
set "config.monsters.move.cm_60_random=67108864"
set "config.monsters.move.cm_90_random=134217728"
set "config.monsters.move.cm_1D2_obj=268435456"
set "config.monsters.move.cm_2D2_obj=536870912"
set "config.monsters.move.cm_4D2_obj=1073741824"
set "config.monsters.move.cm_CM_WIN=2147483648"

:: Creature spell definitions
set "config.monsters.spells.cs_freq=15"
set "config.monsters.spells.cs_spells=131056"
set "config.monsters.spells.cs_tel_short=16"
set "config.monsters.spells.cs_tel_long=32"
set "config.monsters.spells.cs_tel_to=64"
set "config.monsters.spells.cs_light_wnd=128"
set "config.monsters.spells.cs_ser_wnd=256"
set "config.monsters.spells.cs_hold_per=512"
set "config.monsters.spells.cs_blind=1024"
set "config.monsters.spells.cs_confuse=2048"
set "config.monsters.spells.cs_fear=4096"
set "config.monsters.spells.cs_summon_mon=8192"
set "config.monsters.spells.cs_summon_und=16384"
set "config.monsters.spells.cs_slow_per=32768"
set "config.monsters.spells.cs_drain_mana=65536"

set "config.monsters.spells.cs_breathe=16252928"    %= may also just indicate resistance =%
set "config.monsters.spells.cs_br_light=524288"     %= if no spell frequency set =%
set "config.monsters.spells.cs_br_gas=1048576"
set "config.monsters.spells.cs_br_acid=2097152"
set "config.monsters.spells.cs_br_frost=4194304"
set "config.monsters.spells.cs_br_fire=8388608"

:: Creature defense flags
set "config.monsters.defense.cd_dragon=1"
set "config.monsters.defense.cd_animal=2"
set "config.monsters.defense.cd_evil=4"
set "config.monsters.defense.cd_undead=8"
set "config.monsters.defense.cd_weakness=1008"
set "config.monsters.defense.cd_frost=16"
set "config.monsters.defense.cd_fire=32"
set "config.monsters.defense.cd_poison=64"
set "config.monsters.defense.cd_acid=128"
set "config.monsters.defense.cd_light=256"
set "config.monsters.defense.cd_stone=512"
set "config.monsters.defense.cd_no_sleep=1024"
set "config.monsters.defense.cd_infra=2048"
set "config.monsters.defense.cd_max_hp=4096"

:: Player
set "config.player.player_max_exp=9999999"         %= Maximum amount of experience =%
set "config.player.player_use_device_difficulty=3" %= Greater for harder devices =%
set "config.player.player_food_full=10000"         %= Getting full =%
set "config.player.player_food_max=15000"          %= Maximimum food value, beyond is wasted =%
set "config.player.player_food_faint=300"          %= Character begins fainting =%
set "config.player.player_food_weak=1000"          %= Warn player that they're getting weak =%
set "config.player.player_food_alert=2000"         %= Alert plater that they're getting low on food =%
set "config.player.regen_faint=33"                 %= Regen factor*2^16 when fainting =%
set "config.player.regen_weak=98"                  %= Regen factor*2^16 when weak =%
set "config.player.regen_normal=197"               %= Regen factor*2^16 when full =%
set "config.player.regen_hpbase=1442"              %= Min amount hp regen*2^16 =%
set "config.player.regen_mnbase=524"               %= Min amount mana regen*2^16 =%
set "config.player.weight_cap=130"                 %= x/10 pounds per strength point=%

:: Definitions for the player's status field
set "config.player.status.hungry=1"
set "config.player.status.weak=2"
set "config.player.status.blind=4"
set "config.player.status.confused=8"
set "config.player.status.fear=16"
set "config.player.status.poisoned=32"
set "config.player.status.fast=64"
set "config.player.status.slow=128"
set "config.player.status.search=256"
set "config.player.status.rest=512"
set "config.player.status.study=1024"

set "config.player.status.py_invuln=4096"
set "config.player.status.py_hero=8192"
set "config.player.status.py_shero=16384"
set "config.player.status.py_blessed=32768"
set "config.player.status.py_det_inv=65536"
set "config.player.status.py_tim_infra=131072" %= the full name of the wizard is finally known =%
set "config.player.status.py_speed=262144"
set "config.player.status.py_str_wgt=524288"
set "config.player.status.py_paralysed=1048576"
set "config.player.status.py_repeat=2097152"
set "config.player.status.py_armor=4194304"

set "config.player.status.py_stats=1056964608"
set "config.player.status.py_str=16777216"     %= These 6 stat flags must be adjacent =%
set "config.player.status.py_int=33554432"
set "config.player.status.py_wis=67108864"
set "config.player.status.py_dex=134217728"
set "config.player.status.py_con=268435456"
set "config.player.status.py_chr=536870912"

set "config.player.status.py_hp=1073741824"
set "config.player.status.py_mana=2147483648"

:: IDs used for object description, stored in objects_identified array
set "config.identification.od_tried=1"
set "config.identification.od_known1=2"

:: IDs used for item description, stored in ident pointer
set "config.identification.id_magik=1"
set "config.identification.id_damd=2"
set "config.identification.id_empty=4"
set "config.identification.id_known2=8"
set "config.identification.id_store_bought=16"
set "config.identification.id_show_hit_dam=32"
set "config.identification.id_no_show_p1=64"
set "config.identification.id_show_p1=128"

:: Class spell types
set "config.spells.spell_type_none=0"
set "config.spells.spell_type_mage=1"
set "config.spells.spell_type_priest=2"

:: Offsets to spell names in the spell_names[] array
set "config.spells.name_offset_spells=0"
set "config.spells.name_offset_prayers=31"

set "config.stores.store_max_auto_buy_items=18"  %= Max diff objects in stock for auto buy =%
set "config.stores.store_min_auto_sell_items=10" %= Min diff objects in stock for auto sell =%
set "config.stores.store_stock_turn_around=9"    %= Amount of buying and selling normally =%