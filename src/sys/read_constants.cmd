::------------------------------------------------------------------------------
:: Not one of the original files, but batch has no concept of headers and the
:: constants need to get initialized *somewhere* so we're doing it here.
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------

::----- general
set "bool_values[false]=1"
set "bool_values[true]=0"

::----- dungeon_tile.h
set "tile_null_wall=0"
set "tile_dark_floor=1"
set "tile_light_floor=2"
set "max_cave_room=2"
set "tile_corr_floor=3"
set "tile_blocked_floor=4" %= a corridor space with cl/st/se door or rubble =%
set "max_cave_floor=4"
set "max_open_space=3"
set "min_closed_space=4"
set "tmp1_wall=8"
set "tmp2_wall=9"
set "min_cave_wall=12"
set "tile_granite_wall=12"
set "tile_magma_wall=13"
set "tile_quartz_wall=14"
set "tile_boundary_wall=15"

::----- dungeon.h
set "ratio=1"                       %= Size ratio of the Map screen =%
set "max_height=22"                 %= Multiple of 11, GEQ 22 =%
set "max_width=66"                 %= Multiple of 33, GEQ 66 =%
set "screen_height=22"
set "screen_width=66"
set /a quart_height=screen_height/4
set /a quart_width=screen_width/4

::----- game.h
set "treasure_max_levels=50"       %= Deepest possible dungeon level =%

:: These three are all related, so don't change them. If you do, change them all.
:: Also, change player_base_provisions[] and store_choices[].
set "max_objects_in_game=420"
set "max_dungeon_objects=344"
set "object_ident_size=448"        %= 7x64, see object_offset in desc.cmd =%
set "level_max_objects=175"        %= max objects per level =%

:: Definitions for the pseudo-normal distribution generation
set "normal_table_size=256"
set "normal_table_sd=64"           %= standard deviation =%

:: Inventory command screen states
set "screen.blank=0"
set "screen.equipment=1"
set "screen.inventory=2"
set "screen.wear=3"
set "screen.help=4"
set "screen.wrong=5"

:: Game_t struct
set "game.magic_seed=0"              %= seed for initializing magic items =%
set "game.town_seed=0"               %= seed for town generation =%
set "game.character_generated=false" %= don't save score until character generation is finished =%
set "game.character_saved=false"     %= prevents save on kill after saving a character =%
set "game.character_is_dead=false"
set "game.total_winner=false"        %= character beat the Balrog =%
set "game.teleport_player=false"     %= handle teleport traps =%
set "game.player_free_turn=false"    %= player has a free turn, so do not move creatures =%
set "game.to_be_wizard=false"        %= -w option was used during startup =%
set "game.wizard_mode=false"         %= character is a Wizard when true =%
set "game.noscore=0"                 %= don't save a score for this game =%
set "game.use_last_direction=false"  %= 'true' when repeat commands should use last known direction =%
set "game.doing_inventory_command=0" %= track inventory commands =%
set "game.last_command= "            %= save of previous player command =%
set "game.command_count=0"           %= how many times to repeat a specific command =%
set "game.character_died_from= "     %= what the character died from - starvation, Bat, etc. =%

set "game.treasure.current_id=0"     %= current treasure heap pointer =%

set "game.screen.current_screen_id=0"
set "game.screen.screen_left_pos=0"
set "game.screen.screen_bottom_pos=0"
set "game.screen.wear_low_id=0"
set "game.screen.wear_high_id=0"

::----- identification.h
set "counter=0"
for %%A in (sn_null sn_r sn_ra sn_rf sn_rc sn_rl sn_ha sn_df sn_sa sn_sd sn_se sn_su sn_ft 
            sn_fb sn_free_action sn_slaying sn_clumsiness sn_weakness sn_slow_descent sn_speed
            sn_stealth sn_slowness sn_noise sn_great_mass sn_intelligence sn_wisdom
            sn_infravision sn_might sn_lordliness sn_magi sn_beauty sn_seeing sn_regeneration
            sn_stupidity sn_dullness sn_blindness sn_timidness sn_teleportation sn_ugliness
            sn_protection sn_irritation sn_vulnerability sn_enveloping sn_fire sn_slay_evil
            sn_dragon_slaying sn_empty sn_locked sn_poison_needle sn_gas_trap sn_explosion_device
            sn_summoning_runes sn_multiple_traps sn_disarmed sn_unlocked sn_slay_animal
            sn_array_size) do (
    set "SpecialNameIds.%%A=!counter!"
    set /a counter+=1
)

set "max_colors=49"                  %= used with potions =%
set "max_mushrooms=22"               %= used with mushrooms =%
set "max_woods=25"                   %= used with staffs =%
set "max_metals=25"                  %= used with wands =%
set "max_rocks=32"                   %= used with rings =%
set "max_amulets=11"                 %= used with amulets =%
set "max_titles=45"                  %= used with scrolls =%
set "max_syllables=153"              %= used with scrolls =%

::----- inventory.h
set "player_inventory_size=34"       %= do not touch this =%

set "item_never_stack_min=0"         %= these never stack =%
set "item_never_stack_max=63"

set "item_single_stack_min=64"       %= these stack with items of similar sub_category_id =%
set "item_single_stack_max=192"

set "item_group_min=192"             %= these stack with items of same sub_category_id and misc_use =%
set "item_group_max=255"

set "inscrip_size=13"

set "counter=22"
for %%A in (wield head neck body arm hands right left feet outer light auxiliary) do (
    set "PlayerEquipment.%%A=!counter!"
    set /a counter+=1
)

::----- monster.h
set "mon_max_creatures=279"          %= number of creature types in the universe =%
set "mon_attack_types=215"           %= number of monster attack types =%
set "mon_total_allocations=125"      %= max that can be allocated =%
set "mon_max_levels=40"              %= maximum level of creatures =%
set "mon_max_attacks=4"              %= max num attacks in mon's memory =%

::----- player.h
set "counter=0"
for %%A in (bth bthb device disarm save) do (
    set "PlayerClassLevelAdj.%%A=!counter!"
    set /a counter+=1
)

set "counter=0"
for %%A in (a_str a_int a_wis a_dex a_con a_chr) do (
    set "PlayerAttr.%%A=!counter!"
    set /a counter+=1
)

set "class_misc_hit=4"
set "class_max_level_adjust=5"
set "player_max_level=40"            %= maximum possible player level =%
set "player_max_classes=8"           %= number of defined classes =%
set "player_max_races=8"             %= number of defined races =%
set "player_max_backgrounds=128"     %= number of types of histories =%
set "bth_per_plus_to_hit_adjust=3"   %= adjust base-to-hit per plus-to-hit =%
set "player_name_size=27"

set "py.name= "
for %%A in (gender date_of_birth au max_exp exp exp_fraction age height weight level
            max_dungeon_depth chance_in_search fos bth bth_with_bows mana max_hp
            plusses_to_hit plusses_to_damage ac magical_ac display_to_hit display_ac
            display_to_ac disarm saving_throw social_class stealth_factor class_id
            race_id hit_die experience_factor current_mana current_mana_fraction
            current_hp current_hp_fraction) do (
    set "py.misc.%%~A=0"
)
for /L %%A in (0,1,3) do set "py.misc.history[%%A]= "
for %%A in (max current modified used) do (
    for /L %%B in (0,1,5) do (
        set "py.stats.%%A[%%B]=0"
    )
)
for %%A in (status rest blind paralysis confused food food_digested protection
            speed fast slow afraid poisoned image protect_evil invulnerability
            heroism super_heroism blessed heat_resistance cold_resistance
            detect_invisible word_of_recall see_infra timed_infra
            new_spells_to_learn spells_learnt spells_worked spells_forgotten) do (
    set "py.flags.%%~A=0"
)
for /L %%A in (0,1,31) do set "py.flags.spells_learned_order[%%A]=0"
for %%A in (see_invisible teleport free_action slow_digest aggravate
            resistant_to_fire resistant_to_cold resistant_to_acid regenerate_hp
            resistant_to_light free_fall sustain_str sustain_int sustain_wis
            sustain_con sustain_dex sustain_chr confuse_monster) do (
    set "py.flags.%%~A=false"
)
set "py.pos.y=0"
set "py.pos.x=0"
set "py.pos=0;0"
set "prev_dir= "
for /L %%A in (0,1,%player_max_level%) do (
    set "py.base_hp_levels[%%~A]=0"
    set "py.base_exp_levels[%%~A]=0"
)

set "py.running_tracker=0"           %= tracker for number of turns taken during one run cycle =%
set "py.temporary_light_only=false"  %= track if temporary light about player =%
set "py.max_score=0"                 %= maximum score attained =%
set "py.pack.unique_items=0"         %= unique inventory items in pack =%
set "py.pack.weight=0"               %= weight of currently carried items =%
set "py.pack.heaviness=0"            %= used to calculate if pack is too heavy =%
set "py.equipment_count=0"           %= number of equipped items =%
set "py.weapon_is_heavy=false"       %= weapon is too heavy =%
set "py.carrying_light=false"        %= player has a light source equipped =%

::----- scores.h
set "max_high_score_entries=1000"    %= number of entries allowed in the score file =%

::----- spells.h
set "counter=0"
for %%A in (magicmissile lightning poisongas acid frost fire holyorb) do (
    set "MagicSpellFlags.%%A=!counter!"
    set /a counter+=1
)

::----- store.h
set "max_owners=18"                  %= number of owners to choose from =%
set "max_stores=6"                   %= number of different stores =%
set "store_max_discrete_items=24"    %= max number of discrete objects in inventory =%
set "store_max_item_types=26"        %= number of items to choose stock from =%
set "cost_adjustment=100"            %= adjust prices for buying and selling =%

::----- treasure.h
set "tv_never=-1"                    %= used by find_range for non-search =%
set "tv_nothing=0"
set "tv_misc=1"
set "tv_chest=2"

:: items tested for enchantments
set "tv_min_wear=10"                 %= min tval for wearable item =%
set "tv_min_enchant=10"
set "tv_sling_ammo=10"
set "tv_bolt=11"
set "tv_arrow=12"
set "tv_spike=13"
set "tv_light=15"
set "tv_bow=20"
set "tv_hafted=21"
set "tv_polearm=22"
set "tv_sword=23"
set "tv_digging=25"
set "tv_boots=30"
set "tv_gloves=31"
set "tv_cloak=32"
set "tv_helm=33"
set "tv_shield=34"
set "tv_hard_armor=35"
set "tv_soft_armor=36"
set "tv_max_enchant=39"
set "tv_amulet=40"
set "tv_ring=45"
set "tv_max_wear=50"                 %= max tval for wearable item =%

set "tv_staff=55"
set "tv_wand=65"
set "tv_scroll1=70"
set "tv_scroll2=71"
set "tv_potion1=75"
set "tv_potion2=76"
set "tv_flask=77"
set "tv_food=80"
set "tv_magic_book=90"
set "tv_prayer_book=91"
set "tv_max_object=99"               %= objects with tval above this are never picked up by monsters =%
set "tv_gold=100"
set "tv_max_pick_up=100"             %= objects with higher tvals can not be picked up =%
set "tv_invis_trap=101"

set "tv_min_visible=102"             %= min tval for visible objects =%
set "tv_vis_trap=102"
set "tv_rubble=103"

:: the following objects are never deleted when trying to create another one during level generation
set "tv_min_doors=104"
set "tv_open_door=104"
set "tv_closed_door=105"
set "tv_up_stair=107"
set "tv_down_stair=108"
set "tv_secret_door=109"
set "tv_store_door=110"
set "tv_max_visible=110"             %= max tval for visible objects =%

::----- types.h
set "moria_message_size=80"

::----- ui.h
set "msg_line=0"                     %= message line location =%
set "message_history_size=22"        %= how many messages to save in the buffer =%
set "stat_column=0"
for /F %%A in ('echo prompt $E ^| cmd') do set "ESC=%%A"

::----- version.h
set "current_version_major=0"
set "current_version_minor=0"
set "current_version_patch=0"

::----- dungeon_generate.cpp
set "counter=0"
for %%A in (Plain TreasureVault Pillars Maze FourSmallRooms) do (
    set /a counter+=1
    set "InnerRoomTypes.%%A=!counter!"
)

::----- dungeon_los.cpp
set "counter=0"
for %%A in (0 1 0 0 -1) do (
    set "los_dir_set_fxy[!counter!]=%%~A"
    set /a counter+=1
)

set "counter=0"
for %%A in (0 0 -1 1 0) do (
    set "los_dir_set_fxx[!counter!]=%%~A"
    set /a counter+=1
)

set "counter=0"
for %%A in (0 0 1 -1 0) do (
    set "los_dir_set_fyy[!counter!]=%%~A"
    set /a counter+=1
)

set "counter=0"
for %%A in (0 1 0 0 -1) do (
    set "los_dir_set_fyx[!counter!]=%%~A"
    set /a counter+=1
)

set "GRADF=10000"

::----- dungeon.cpp
set "dg.height=0"
set "dg.width=0"
set "dg.game_turn=-1"
set "dg.current_level=0"
set "dg.generate_new_level=true"

::----- game.cpp
set "counter=0"
for %%A in (
    "Running: cut known corners`config.options.run_cut_corners"
    "Running: examine potential corners`config.options.run_examine_corners"
    "Running: print self during run`config.options.run_print_self"
    "Running: stop when map sector changes`config.options.find_bound"
    "Running: run through open doors`config.options.run_ignore_doors"
    "Prompt to pick up objects`config.options.prompt_to_pickup"
    "Rogue-like commands`config.options.use_roguelike_keys"
    "Show weights in inventory`config.options.show_inventory_weights"
    "Highlight and notice mineral seams`config.options.highlight_seams"
    "Beep for invalid character`config.options.error_beep_sound"
    "Display rest/repeat counts`config.options.display_counts"
) do (
    for /f "tokens=1,2 delims=`" %%B in ("%%~A") do (
        set "game_options[!counter!].desc=%%B"
        set "game_options[!counter!].var=%%C"
    )
    set /a counter+=1
)

::----- identification.cpp
set "counter=0"
for %%A in (Ignored Charges Plusses Light Flags ZPlusses) do (
    set "ItemMiscUse.%%A=!counter!"
    set /a counter+=1
)

::----- mage_spells.cpp
set "counter=0"
for %%A in (MagicMissile DetectMonsters PhaseDoor LightArea CureLightWounds
            FindHiddenTrapsDoors StinkingCloud Confusion LightningBolt
            TrapDoorDestruction Sleep1 CurePoison TeleportSelf RemoveCurse
            FrostBolt WallToMud CreateFood RechargeItem1 Sleep2 PolymorphOther
            IdentifyItem Sleep3 FireBolt SpeedMonster FrostBall RechargeItem2
            TeleportOther HasteSelf Fireball WordOfDestruction Genocide) do (
    set /a counter+=1
    set "MageSpellId.%%A=!counter!"
)

::----- player_eat.cpp
set "counter=0"
for %%A in (Poison Blindness Paranoia Confusion Hallucination CurePoison
            CureBlindness CureParanoia CureConfusion Weakness Unhealth
            x x x x RestoreSTR RestoreCON RestoreINT RestoreWIS RestoreDEX
            RestoreCHR FirstAid MinorCures LightCures x MajorCures
            PoisonousFood) do (
    set /a counter+=1
    set "FoodMagicTypes.%%A=!counter!"
)
set "FoodMagicTypes.x="

::----- player_move.cpp
set "counter=0"
for %%A in (OpenPit ArrowPit CoveredPit TrapDoor SleepingGas HiddenObject
            DartOfStr Teleport Rockfall CorrodingGas SummonMonster FireTrap
            AcidTrap PoisonGasTrap BlindingGas SlowDart DartOfCon SecretDoor) do (
    set /a counter+=1
    set "TrapTypes.%%A=!counter!"
)

set "TrapTypes.ScareMonster=99"

set "counter=100"
for %%A in (GeneralStore Armory Weaponsmith Temple Alchemist MagicShop) do (
    set /a counter+=1
    set "TrapTypes.%%A=!counter!"
)

::----- player_pray.cpp
set "counter=0"
for %%A in (DetectEvil CureLightWounds Bless RemoveFear CallLight FindTraps
            DetectDoorsStairs SlowPoison BlindCreature Portal CureMediumWounds
            Chant Sanctuary CreateFood RemoveCurse ResistHeadCold NeutralizePoison
            OrbOfDraining CureSeriousWounds SenseInvisible ProtectFromEvil
            Earthquake SenseSurroundings CureCriticalWounds TurnUndead Prayer
            DispelUndead Heal DispelEvil GlyphOfWarding HolyWord) do (
    set /a counter+=1
    set "PriestSpellTypes.%%A=!counter!"
)

::----- player_quaff.cpp
set "counter=0"
for %%A in (Strength Weakness RestoreStrength Intelligence LoseIntelligence
            RestoreIntelligence Wisdom LoseWisdom RestoreWisdom Charisma
            Ugliness RestoreCharisma CureLightWounds CureSeriousWounds
            CureCriticalWounds Healing Constitution GainExperience Sleep
            Blindness Confusion Poison HasteSelf Slowness) do (
    set /a counter+=1
    set "PotionSpellTypes.%%A=!counter!"
)

set "counter=25"
for %%A in (Dexterity RestoreDexterity RestoreConstitution
            CureBlindness CureConfusion CurePoison) do (
    set /a counter+=1
    set "PotionSpellTypes.%%A=!counter!"
)

set "counter=33"
for %%A in (LoseExperience SaltWater Invulnerability Heroism SuperHeroism
            Boldness RestoreLifeLevels ResistHeat ResistCold DetectInvisible
            SlowPoison NeutralizePoison RestoreMana InfraVision) do (
    set /a counter+=1
    set "PotionSpellTypes.%%A=!counter!"
)

::----- player_run.cpp
set "counter=0"
for %%A in (1 2 3 6 9 8 7 4 1 2 3 6 9 8 7 4 1) do (
    set "cycle[!counter!]=%%A"
    set /a counter+=1
)

set "counter=0"
for %%A in (-1 8 9 10 7 -1 11 6 5 4) do (
    set "chrome[!counter!]=%%A"
    set /a counter+=1
)

::----- player_stats.cpp
set "counter=0"
for %%A in (10     25     45     70     100    140    200     280     380     500
            650    850    1100   1400   1800   2300   2900    3600    4400    5400
            6800   8400   10200  12500  17500  25000  35000   50000   75000   100000
            150000 200000 300000 400000 500000 750000 1500000 2500000 5000000 10000000) do (
    set "levels[!counter!]=%%A"
    set /a counter+=1
)

::----- rng.cpp
set "rng_m=2147483647"
set "rng_a=16807"
set /a rng_q=rng_m / rng_a
set /a rng_r=rng_m %% rng_a

::----- staves.cpp
set "counter=0"
for %%A in (StaffLight DetectDoorsStairs TrapLocation TreasureLocation ObjectLocation
            Teleportation Earthquake Summoning x Destruction StarLight HasteMonsters
            SlowMonsters SleepMonsters CureLightWounds DetectInvisible Speed Slowness
            MassPolymorph RemoveCurse DetectEvil Curing DispelEvil x Darkness x x x x
            x x StoreBoughtFlag) do (
    set /a counter+=1
    set "StaffSpellTypes.%%A=!counter!"
)

set "counter=0"
for %%A in (WandLight LightningBolt FrostBolt FireBolt StoneToMud Polymorph HealMonster
            HasteMonster SlowMonster ConfuseMonster DrainLife TrapDoorDestruction
            WandMagicMissile WallBuilding CloneMonster TeleportAway Disarming
            LightningBall ColdBall FireBall StinkingCloud AcidBall Wonder) do (
    set /a counter+=1
    set "WandSpellTypes.%%A=!counter!"
)

::----- store.cpp
set "counter=0"
for %%A in (Received Rejected Offended Insulted) do (
    set "BidState.%%A=!counter!"
    set /a counter+=1
)

::----- treasure.cpp
set "missiles_counter=0"

::----- ui_inventory.cpp
set "counter=0"
for %%A in (CloseMenu Equipment Inventory) do (
    set "PackMenu.%%A=!counter!"
    set /a counter+=1
)

::----- ui_io.cpp
set "eof_flag=0"
set "panic_save=false"

::----- ui.cpp
set "counter=0"
for %%A in (STR INT WIS DEX CON CHR) do (
    set "stat_names[!counter!]=%%~A : "
    set /a counter+=1
)
set "BLANK_LENGTH=24"
set "screen_has_changed=false"
set "last_message_id=0"
exit /b