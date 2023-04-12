:: Multidimensional arrays for Class rank title, racial biases, race stats,
:: background information, class stats, class saves, magic spells, spell
:: names, and initial starting gear. Pretty much just pure data.
@echo off

::----- Class rank titles for different levels
:: Warrior
set "rank_title=0"
for %%A in ("Rookie"        "Private"       "Soldier"       "Mercenary" 
            "Veteran(1st)"  "Veteran(2nd)"  "Veteran(3rd)"  "Warrior(1st)" 
            "Warrior(2nd)"  "Warrior(3rd)"  "Warrior(4th)"  "Swordsman-1" 
            "Swordsman-2"   "Swordsman-3"   "Hero"          "Swashbuckler" 
            "Myrmidon"      "Champion-1"    "Champion-2"    "Champion-3" 
            "Superhero"     "Knight"        "Superior Knt"  "Gallant Knt" 
            "Knt Errant"    "Guardian Knt"  "Baron"         "Duke" 
            "Lord (1st)"    "Lord (2nd)"    "Lord (3rd)"    "Lord (4th)" 
            "Lord (5th)"    "Lord (6th)"    "Lord (7th)"    "Lord (8th)" 
            "Lord (9th)"    "Lord Gallant"  "Lord Keeper"   "Lord Noble") do (
    set /a rank_title+=1
    set "class_rank_title[0][!rank_title!]=%%A"
)

:: Mage
set "rank_title=0"
for %%A in ("Novice"       "Apprentice"   "Trickster-1"  "Trickster-2"
            "Trickster-3"  "Cabalist-1"   "Cabalist-2"   "Cabalist-3"
            "Visionist"    "Phantasmist"  "Shadowist"    "Spellbinder"
            "Illusionist"  "Evoker (1st)" "Evoker (2nd)" "Evoker (3rd)"
            "Evoker (4th)" "Conjurer"     "Theurgist"    "Thaumaturge"
            "Magician"     "Enchanter"    "Warlock"      "Sorcerer"
            "Necromancer"  "Mage (1st)"   "Mage (2nd)"   "Mage (3rd)"
            "Mage (4th)"   "Mage (5th)"   "Wizard (1st)" "Wizard (2nd)"
            "Wizard (3rd)" "Wizard (4th)" "Wizard (5th)" "Wizard (6th)"
            "Wizard (7th)" "Wizard (8th)" "Wizard (9th)" "Wizard Lord") do (
    set /a rank_title+=1
    set "class_rank_title[1][!rank_title!]=%%A"
)

:: Priest
set "rank_title=0"
for %%A in ("Believer"     "Acolyte(1st)" "Acolyte(2nd)" "Acolyte(3rd)"
            "Adept (1st)"  "Adept (2nd)"  "Adept (3rd)"  "Priest (1st)"
            "Priest (2nd)" "Priest (3rd)" "Priest (4th)" "Priest (5th)"
            "Priest (6th)" "Priest (7th)" "Priest (8th)" "Priest (9th)"
            "Curate (1st)" "Curate (2nd)" "Curate (3rd)" "Curate (4th)"
            "Curate (5th)" "Curate (6th)" "Curate (7th)" "Curate (8th)"
            "Curate (9th)" "Canon (1st)"  "Canon (2nd)"  "Canon (3rd)"
            "Canon (4th)"  "Canon (5th)"  "Low Lama"     "Lama-1"
            "Lama-2"       "Lama-3"       "High Lama"    "Great Lama"
            "Patriarch"    "High Priest"  "Great Priest" "Noble Priest") do (
    set /a rank_title+=1
    set "class_rank_title[2][!rank_title!]=%%A"
)

:: Rogue
set "rank_title=0"
for %%A in ("Vagabond"     "Footpad"     "Cutpurse"      "Robber"
            "Burglar"      "Filcher"     "Sharper"       "Magsman"
            "Common Rogue" "Rogue (1st)" "Rogue (2nd)"   "Rogue (3rd)"
            "Rogue (4th)"  "Rogue (5th)" "Rogue (6th)"   "Rogue (7th)"
            "Rogue (8th)"  "Rogue (9th)" "Master Rogue"  "Expert Rogue"
            "Senior Rogue" "Chief Rogue" "Prime Rogue"   "Low Thief"
            "Thief (1st)"  "Thief (2nd)" "Thief (3rd)"   "Thief (4th)"
            "Thief (5th)"  "Thief (6th)" "Thief (7th)"   "Thief (8th)"
            "Thief (9th)"  "High Thief"  "Master Thief"  "Executioner"
            "Low Assassin" "Assassin"    "High Assassin" "Guildsmaster") do (
    set /a rank_title+=1
    set "class_rank_title[2][!rank_title!]=%%A"
)

:: Ranger
set "rank_title=0"
for %%A in ("Runner (1st)"  "Runner (2nd)"  "Runner (3rd)"  "Strider (1st)"
            "Strider (2nd)" "Strider (3rd)" "Scout (1st)"   "Scout (2nd)"
            "Scout (3rd)"   "Scout (4th)"   "Scout (5th)"   "Courser (1st)"
            "Courser (2nd)" "Courser (3rd)" "Courser (4th)" "Courser (5th)"
            "Tracker (1st)" "Tracker (2nd)" "Tracker (3rd)" "Tracker (4th)"
            "Tracker (5th)" "Tracker (6th)" "Tracker (7th)" "Tracker (8th)"
            "Tracker (9th)" "Guide (1st)"   "Guide (2nd)"   "Guide (3rd)"
            "Guide (4th)"   "Guide (5th)"   "Guide (6th)"   "Guide (7th)"
            "Guide (8th)"   "Guide (9th)"   "Pathfinder-1"  "Pathfinder-2"
            "Pathfinder-3"  "Ranger"        "High Ranger"   "Ranger Lord") do (
    set /a rank_title+=1
    set "class_rank_title[2][!rank_title!]=%%A"
)

:: Paladin
set "rank_title=0"
for %%A in ("Gallant"      "Keeper (1st)" "Keeper (2nd)" "Keeper (3rd)"
            "Keeper (4th)" "Keeper (5th)" "Keeper (6th)" "Keeper (7th)"
            "Keeper (8th)" "Keeper (9th)" "Protector-1"  "Protector-2"
            "Protector-3"  "Protector-4"  "Protector-5"  "Protector-6"
            "Protector-7"  "Protector-8"  "Defender-1"   "Defender-2"
            "Defender-3"   "Defender-4"   "Defender-5"   "Defender-6"
            "Defender-7"   "Defender-8"   "Warder (1st)" "Warder (2nd)"
            "Warder (3rd)" "Warder (4th)" "Warder (5th)" "Warder (6th)"
            "Warder (7th)" "Warder (8th)" "Warder (9th)" "Guardian"
            "Chevalier"    "Justiciar"    "Paladin"      "High Lord") do (
    set /a rank_title+=1
    set "class_rank_title[2][!rank_title!]=%%A"
)
set "rank_title="

::----- Add race stats
set "race_count=0"
call :addRaceToRaceList "Human"       0  0  0  0  0  0 14  6 72  6 180 25 66 4 150 20  0  0  0  0   0   0  0 10 0 100 0x3F
call :addRaceToRaceList "Half-Elf"   -1  1  0  1 -1  1 24 16 66  6 130 15 62 6 100 10  2  6  1 -1  -1   5  3  9 2 110 0x3F
call :addRaceToRaceList "Elf"        -1  2  1  1 -2  1 75 75 60  4 100  6 54 4  80  6  5  8  1 -2  -5  15  6  8 3 120 0x1F
call :addRaceToRaceList "Halfling"   -2  2  1  3  1  1 21 12 36  3  60  3 33 3  50  3 15 12  4 -5 -10  20 18  6 4 110 0x0B
call :addRaceToRaceList "Gnome"      -1  2  0  2  1 -2 50 40 42  3  90  6 39 3  75  3 10  6  3 -3  -8  12 12  7 4 125 0x0F
call :addRaceToRaceList "Dwarf"       2 -3  1 -2  2 -3 35 15 48  3 150 10 46 3 120 10  2  7 -1  0  15   0  9  9 5 120 0x05
call :addRaceToRaceList "Half-Orc"    2 -1  0  0  1 -4 11  4 66  1 150  5 62 1 120  5 -3  0 -1  3  12  -5 -3 10 3 110 0x0D
call :addRaceToRaceList "Half-Troll"  4 -4 -2 -4  3 -6 20 10 96 10 255 50 84 8 225 40 -5 -1 -2  5  20 -10 -8 12 3 120 0x05
set "race_count="

::----- Add character background segments
set "bg_count=0"
call :addBackgroundToBackgroundList "You are the illegitimate and unacknowledged child "   10  1  2  25
call :addBackgroundToBackgroundList "You are the illegitimate but acknowledged child "     20  1  2  35
call :addBackgroundToBackgroundList "You are one of several children "                     95  1  2  45
call :addBackgroundToBackgroundList "You are the first child "                            100  1  2  50
call :addBackgroundToBackgroundList "of a Serf.  "                                         40  2  3  65
call :addBackgroundToBackgroundList "of a Yeoman.  "                                       65  2  3  80
call :addBackgroundToBackgroundList "of a Townsman.  "                                     80  2  3  90
call :addBackgroundToBackgroundList "of a Guildsman.  "                                    90  2  3 105
call :addBackgroundToBackgroundList "of a Landed Knight.  "                                96  2  3 120
call :addBackgroundToBackgroundList "of a Titled Noble.  "                                 99  2  3 130
call :addBackgroundToBackgroundList "of a Royal Blood Line.  "                            100  2  3 140
call :addBackgroundToBackgroundList "You are the black sheep of the family.  "             20  3 50  20
call :addBackgroundToBackgroundList "You are a credit to the family.  "                    80  3 50  55
call :addBackgroundToBackgroundList "You are a well liked child.  "                       100  3 50  60
call :addBackgroundToBackgroundList "Your mother was a Green-Elf.  "                       40  4  1  50
call :addBackgroundToBackgroundList "Your father was a Green-Elf.  "                       75  4  1  55
call :addBackgroundToBackgroundList "Your mother was a Grey-Elf.  "                        90  4  1  55
call :addBackgroundToBackgroundList "Your father was a Grey-Elf.  "                        95  4  1  60
call :addBackgroundToBackgroundList "Your mother was a High-Elf.  "                        98  4  1  65
call :addBackgroundToBackgroundList "Your father was a High-Elf.  "                       100  4  1  70
call :addBackgroundToBackgroundList "You are one of several children "                     60  7  8  50
call :addBackgroundToBackgroundList "You are the only child "                             100  7  8  55
call :addBackgroundToBackgroundList "of a Green-Elf "                                      75  8  9  50
call :addBackgroundToBackgroundList "of a Grey-Elf "                                       95  8  9  55
call :addBackgroundToBackgroundList "of a High-Elf "                                      100  8  9  60
call :addBackgroundToBackgroundList "Ranger.  "                                            40  9 54  80
call :addBackgroundToBackgroundList "Archer.  "                                            70  9 54  90
call :addBackgroundToBackgroundList "Warrior.  "                                           87  9 54 110
call :addBackgroundToBackgroundList "Mage.  "                                              95  9 54 125
call :addBackgroundToBackgroundList "Prince.  "                                            99  9 54 140
call :addBackgroundToBackgroundList "King.  "                                             100  9 54 145
call :addBackgroundToBackgroundList "You are one of several children of a Halfling "       85 10 11  45
call :addBackgroundToBackgroundList "You are the only child of a Halfling "               100 10 11  55
call :addBackgroundToBackgroundList "Bum.  "                                               20 11  3  55
call :addBackgroundToBackgroundList "Tavern Owner.  "                                      30 11  3  80
call :addBackgroundToBackgroundList "Miller.  "                                            40 11  3  90
call :addBackgroundToBackgroundList "Home Owner.  "                                        50 11  3 100
call :addBackgroundToBackgroundList "Burglar.  "                                           80 11  3 110
call :addBackgroundToBackgroundList "Warrior.  "                                           95 11  3 115
call :addBackgroundToBackgroundList "Mage.  "                                              99 11  3 125
call :addBackgroundToBackgroundList "Clan Elder.  "                                       100 11  3 140
call :addBackgroundToBackgroundList "You are one of several children of a Gnome "          85 13 14  45
call :addBackgroundToBackgroundList "You are the only child of a Gnome "                  100 13 14  55
call :addBackgroundToBackgroundList "Beggar.  "                                            20 14  3  55
call :addBackgroundToBackgroundList "Braggart.  "                                          50 14  3  70
call :addBackgroundToBackgroundList "Prankster.  "                                         75 14  3  85
call :addBackgroundToBackgroundList "Warrior.  "                                           95 14  3 100
call :addBackgroundToBackgroundList "Mage.  "                                             100 14  3 125
call :addBackgroundToBackgroundList "You are one of two children of a Dwarven "            25 16 17  40
call :addBackgroundToBackgroundList "You are the only child of a Dwarven "                100 16 17  50
call :addBackgroundToBackgroundList "Thief.  "                                             10 17 18  60
call :addBackgroundToBackgroundList "Prison Guard.  "                                      25 17 18  75
call :addBackgroundToBackgroundList "Miner.  "                                             75 17 18  90
call :addBackgroundToBackgroundList "Warrior.  "                                           90 17 18 110
call :addBackgroundToBackgroundList "Priest.  "                                            99 17 18 130
call :addBackgroundToBackgroundList "King.  "                                             100 17 18 150
call :addBackgroundToBackgroundList "You are the black sheep of the family.  "             15 18 57  10
call :addBackgroundToBackgroundList "You are a credit to the family.  "                    85 18 57  50
call :addBackgroundToBackgroundList "You are a well liked child.  "                       100 18 57  55
call :addBackgroundToBackgroundList "Your mother was an Orc, but it is unacknowledged.  "  25 19 20  25
call :addBackgroundToBackgroundList "Your father was an Orc, but it is unacknowledged.  " 100 19 20  25
call :addBackgroundToBackgroundList "You are the adopted child "                          100 20  2  50
call :addBackgroundToBackgroundList "Your mother was a Cave-Troll "                        30 22 23  20
call :addBackgroundToBackgroundList "Your father was a Cave-Troll "                        60 22 23  25
call :addBackgroundToBackgroundList "Your mother was a Hill-Troll "                        75 22 23  30
call :addBackgroundToBackgroundList "Your father was a Hill-Troll "                        90 22 23  35
call :addBackgroundToBackgroundList "Your mother was a Water-Troll "                       95 22 23  40
call :addBackgroundToBackgroundList "Your father was a Water-Troll "                      100 22 23  45
call :addBackgroundToBackgroundList "Cook.  "                                               5 23 62  60
call :addBackgroundToBackgroundList "Warrior.  "                                           95 23 62  55
call :addBackgroundToBackgroundList "Shaman.  "                                            99 23 62  65
call :addBackgroundToBackgroundList "Clan Chief.  "                                       100 23 62  80
call :addBackgroundToBackgroundList "You have dark brown eyes, "                           20 50 51  50
call :addBackgroundToBackgroundList "You have brown eyes, "                                60 50 51  50
call :addBackgroundToBackgroundList "You have hazel eyes, "                                70 50 51  50
call :addBackgroundToBackgroundList "You have green eyes, "                                80 50 51  50
call :addBackgroundToBackgroundList "You have blue eyes, "                                 90 50 51  50
call :addBackgroundToBackgroundList "You have blue-gray eyes, "                           100 50 51  50
call :addBackgroundToBackgroundList "straight "                                            70 51 52  50
call :addBackgroundToBackgroundList "wavy "                                                90 51 52  50
call :addBackgroundToBackgroundList "curly "                                              100 51 52  50
call :addBackgroundToBackgroundList "black hair, "                                         30 52 53  50
call :addBackgroundToBackgroundList "brown hair, "                                         70 52 53  50
call :addBackgroundToBackgroundList "auburn hair, "                                        80 52 53  50
call :addBackgroundToBackgroundList "red hair, "                                           90 52 53  50
call :addBackgroundToBackgroundList "blond hair, "                                        100 52 53  50
call :addBackgroundToBackgroundList "and a very dark complexion."                          10 53  0  50
call :addBackgroundToBackgroundList "and a dark complexion."                               30 53  0  50
call :addBackgroundToBackgroundList "and an average complexion."                           80 53  0  50
call :addBackgroundToBackgroundList "and a fair complexion."                               90 53  0  50
call :addBackgroundToBackgroundList "and a very fair complexion."                         100 53  0  50
call :addBackgroundToBackgroundList "You have light grey eyes, "                           85 54 55  50
call :addBackgroundToBackgroundList "You have light blue eyes, "                           95 54 55  50
call :addBackgroundToBackgroundList "You have light green eyes, "                         100 54 55  50
call :addBackgroundToBackgroundList "straight "                                            75 55 56  50
call :addBackgroundToBackgroundList "wavy "                                               100 55 56  50
call :addBackgroundToBackgroundList "black hair, and a fair complexion."                   75 56  0  50
call :addBackgroundToBackgroundList "brown hair, and a fair complexion."                   85 56  0  50
call :addBackgroundToBackgroundList "blond hair, and a fair complexion."                   95 56  0  50
call :addBackgroundToBackgroundList "silver hair, and a fair complexion."                 100 56  0  50
call :addBackgroundToBackgroundList "You have dark brown eyes, "                           99 57 58  50
call :addBackgroundToBackgroundList "You have glowing red eyes, "                         100 57 58  60
call :addBackgroundToBackgroundList "straight "                                            90 58 59  50
call :addBackgroundToBackgroundList "wavy "                                               100 58 59  50
call :addBackgroundToBackgroundList "black hair, "                                         75 59 60  50
call :addBackgroundToBackgroundList "brown hair, "                                        100 59 60  50
call :addBackgroundToBackgroundList "a one foot beard, "                                   25 60 61  50
call :addBackgroundToBackgroundList "a two foot beard, "                                   60 60 61  51
call :addBackgroundToBackgroundList "a three foot beard, "                                 90 60 61  53
call :addBackgroundToBackgroundList "a four foot beard, "                                 100 60 61  55
call :addBackgroundToBackgroundList "and a dark complexion."                              100 61  0  50
call :addBackgroundToBackgroundList "You have slime green eyes, "                          60 62 63  50
call :addBackgroundToBackgroundList "You have puke yellow eyes, "                          85 62 63  50
call :addBackgroundToBackgroundList "You have blue-bloodshot eyes, "                       99 62 63  50
call :addBackgroundToBackgroundList "You have glowing red eyes, "                         100 62 63  55
call :addBackgroundToBackgroundList "dirty "                                               33 63 64  50
call :addBackgroundToBackgroundList "mangy "                                               66 63 64  50
call :addBackgroundToBackgroundList "oily "                                               100 63 64  50
call :addBackgroundToBackgroundList "sea-weed green hair, "                                33 64 65  50
call :addBackgroundToBackgroundList "bright red hair, "                                    66 64 65  50
call :addBackgroundToBackgroundList "dark purple hair, "                                  100 64 65  50
call :addBackgroundToBackgroundList "and green "                                           25 65 66  50
call :addBackgroundToBackgroundList "and blue "                                            50 65 66  50
call :addBackgroundToBackgroundList "and white "                                           75 65 66  50
call :addBackgroundToBackgroundList "and black "                                          100 65 66  50
call :addBackgroundToBackgroundList "ulcerous skin."                                       33 66  0  50
call :addBackgroundToBackgroundList "scabby skin."                                         66 66  0  50
call :addBackgroundToBackgroundList "leprous skin."                                       100 66  0  50
set "bg_count="

::----- Class stats
set "class_count=0"
call :addClassToClassList "Warrior" 9 25 14 1 38 70 55 18  5 -2 -2  2  2 -1 %config.spells.SPELL_TYPE_NONE%    0 0
call :addClassToClassList "Mage"    0 30 16 2 20 34 20 36 -5  3  0  1 -2  1 %config.spells.SPELL_TYPE_MAGE%   30 1
call :addClassToClassList "Priest"  2 25 16 2 32 48 35 30 -3 -3  3 -1  0  2 %config.spells.SPELL_TYPE_PRIEST% 20 1
call :addClassToClassList "Rogue"   6 45 32 5 16 60 66 30  2  1 -2  3  1 -1 %config.spells.SPELL_TYPE_MAGE%    0 5
call :addClassToClassList "Ranger"  4 30 24 3 24 56 72 30  2  2  0  1  1  1 %config.spells.SPELL_TYPE_MAGE%   40 3
call :addClassToClassList "Paladin" 6 20 12 1 38 68 40 24  3 -3  1  0  2  2 %config.spells.SPELL_TYPE_PRIEST% 35 1

::----- Class level adjustments
set "class_count=0"
call :addAdjustment 4 4 2 2 3 %= Warrior =%
call :addAdjustment 2 2 4 3 3 %= Mage =%
call :addAdjustment 2 2 4 3 3 %= Priest =%
call :addAdjustment 3 4 3 4 3 %= Rogue =%
call :addAdjustment 3 4 3 3 3 %= Ranger =%
call :addAdjustment 3 3 3 2 3 %= Paladin =%

::----- Spells
:: Mage
set /a class_id=1, spell_count=0
call :addSpellToSpellList  1  1 22   1
call :addSpellToSpellList  1  1 23   1
call :addSpellToSpellList  1  2 24   1
call :addSpellToSpellList  1  2 26   1
call :addSpellToSpellList  3  3 25   2
call :addSpellToSpellList  3  3 25   1
call :addSpellToSpellList  3  3 27   2
call :addSpellToSpellList  3  4 30   1
call :addSpellToSpellList  5  4 30   6
call :addSpellToSpellList  5  5 30   8
call :addSpellToSpellList  5  5 30   5
call :addSpellToSpellList  5  5 35   6
call :addSpellToSpellList  7  6 35   9
call :addSpellToSpellList  7  6 50  10
call :addSpellToSpellList  7  6 40  12
call :addSpellToSpellList  9  7 44  19
call :addSpellToSpellList  9  7 45  19
call :addSpellToSpellList  9  7 75  22
call :addSpellToSpellList  9  7 45  19
call :addSpellToSpellList 11  7 45  25
call :addSpellToSpellList 11  7 99  19
call :addSpellToSpellList 13  7 50  22
call :addSpellToSpellList 15  9 50  25
call :addSpellToSpellList 17  9 50  31
call :addSpellToSpellList 19 12 55  38
call :addSpellToSpellList 21 12 90  44
call :addSpellToSpellList 23 12 60  50
call :addSpellToSpellList 25 12 65  63
call :addSpellToSpellList 29 18 65  88
call :addSpellToSpellList 33 21 80 125
call :addSpellToSpellList 37 25 95 200

:: Priest
set /a class_id=2, spell_count=0
call :addSpellToSpellList  1  1 10   1
call :addSpellToSpellList  1  2 15   1
call :addSpellToSpellList  1  2 20   1
call :addSpellToSpellList  1  2 25   1
call :addSpellToSpellList  3  2 25   1
call :addSpellToSpellList  3  3 27   2
call :addSpellToSpellList  3  3 27   2
call :addSpellToSpellList  3  3 28   3
call :addSpellToSpellList  5  4 29   4
call :addSpellToSpellList  5  4 30   5
call :addSpellToSpellList  5  4 32   5
call :addSpellToSpellList  5  5 34   5
call :addSpellToSpellList  7  5 36   6
call :addSpellToSpellList  7  5 38   7
call :addSpellToSpellList  7  6 38   9
call :addSpellToSpellList  7  7 38   9
call :addSpellToSpellList  9  6 38  10
call :addSpellToSpellList  9  7 38  10
call :addSpellToSpellList  9  7 40  10
call :addSpellToSpellList 11  8 42  10
call :addSpellToSpellList 11  8 42  12
call :addSpellToSpellList 11  9 55  15
call :addSpellToSpellList 13 10 45  15
call :addSpellToSpellList 13 11 45  16
call :addSpellToSpellList 15 12 50  20
call :addSpellToSpellList 15 14 50  22
call :addSpellToSpellList 17 14 55  32
call :addSpellToSpellList 21 16 60  38
call :addSpellToSpellList 25 20 70  75
call :addSpellToSpellList 33 24 90 125
call :addSpellToSpellList 39 32 80 200

::Rogue
set /a class_id=3, spell_count=0
call :addSpellToSpellList 99 99  0   0
call :addSpellToSpellList  5  1 50   1
call :addSpellToSpellList  7  2 55   1
call :addSpellToSpellList  9  3 60   2
call :addSpellToSpellList 11  4 65   2
call :addSpellToSpellList 13  5 70   3
call :addSpellToSpellList 99 99  0   0
call :addSpellToSpellList 15  6 75   3
call :addSpellToSpellList 99 99  0   0
call :addSpellToSpellList 17  7 80   4
call :addSpellToSpellList 19  8 85   5
call :addSpellToSpellList 21  9 90   6
call :addSpellToSpellList 99 99  0   0
call :addSpellToSpellList 23 10 95   7
call :addSpellToSpellList 99 99  0   0
call :addSpellToSpellList 99 99  0   0
call :addSpellToSpellList 25 12 95   9
call :addSpellToSpellList 27 15 99  11
call :addSpellToSpellList 99 99  0   0
call :addSpellToSpellList 99 99  0   0
call :addSpellToSpellList 29 18 99  19
call :addSpellToSpellList 99 99  0   0
call :addSpellToSpellList 99 99  0   0
call :addSpellToSpellList 99 99  0   0
call :addSpellToSpellList 99 99  0   0
call :addSpellToSpellList 99 99  0   0
call :addSpellToSpellList 99 99  0   0
call :addSpellToSpellList 99 99  0   0
call :addSpellToSpellList 99 99  0   0
call :addSpellToSpellList 99 99  0   0
call :addSpellToSpellList 99 99  0   0

:: Ranger
set /a class_id=4, spell_count=0
call :addSpellToSpellList  3  1 30   1
call :addSpellToSpellList  3  2 35   2
call :addSpellToSpellList  3  2 35   2
call :addSpellToSpellList  5  3 35   2
call :addSpellToSpellList  5  3 40   2
call :addSpellToSpellList  5  4 45   3
call :addSpellToSpellList  7  5 40   6
call :addSpellToSpellList  7  6 40   5
call :addSpellToSpellList  9  7 40   7
call :addSpellToSpellList  9  8 45   8
call :addSpellToSpellList 11  8 40  10
call :addSpellToSpellList 11  9 45  10
call :addSpellToSpellList 13 10 45  12
call :addSpellToSpellList 13 11 55  13
call :addSpellToSpellList 15 12 50  15
call :addSpellToSpellList 15 13 50  15
call :addSpellToSpellList 17 17 55  15
call :addSpellToSpellList 17 17 90  17
call :addSpellToSpellList 21 17 55  17
call :addSpellToSpellList 21 19 60  18
call :addSpellToSpellList 23 25 95  20
call :addSpellToSpellList 23 20 60  20
call :addSpellToSpellList 25 20 60  20
call :addSpellToSpellList 25 21 65  20
call :addSpellToSpellList 27 21 65  22
call :addSpellToSpellList 29 23 95  23
call :addSpellToSpellList 31 25 70  25
call :addSpellToSpellList 33 25 75  38
call :addSpellToSpellList 35 25 80  50
call :addSpellToSpellList 37 30 95 100
call :addSpellToSpellList 99 99  0   0

:: Paladin
set /a class_id=5, spell_count=0
call :addSpellToSpellList  1  1 30   1
call :addSpellToSpellList  2  2 35   2
call :addSpellToSpellList  3  3 35   3
call :addSpellToSpellList  5  3 35   5
call :addSpellToSpellList  5  4 35   5
call :addSpellToSpellList  7  5 40   6
call :addSpellToSpellList  7  5 40   6
call :addSpellToSpellList  9  7 40   7
call :addSpellToSpellList  9  7 40   8
call :addSpellToSpellList  9  8 40   8
call :addSpellToSpellList 11  9 40  10
call :addSpellToSpellList 11 10 45  10
call :addSpellToSpellList 11 10 45  10
call :addSpellToSpellList 13 10 45  12
call :addSpellToSpellList 13 11 45  13
call :addSpellToSpellList 15 13 45  15
call :addSpellToSpellList 15 15 50  15
call :addSpellToSpellList 17 15 50  17
call :addSpellToSpellList 17 15 50  18
call :addSpellToSpellList 19 15 50  19
call :addSpellToSpellList 19 15 50  19
call :addSpellToSpellList 21 17 50  20
call :addSpellToSpellList 23 17 50  20
call :addSpellToSpellList 25 20 50  20
call :addSpellToSpellList 27 21 50  22
call :addSpellToSpellList 29 22 50  24
call :addSpellToSpellList 31 24 60  25
call :addSpellToSpellList 33 28 60  31
call :addSpellToSpellList 35 32 70  38
call :addSpellToSpellList 37 36 90  50
call :addSpellToSpellList 39 38 90 100
set "class_id="

::----- Spell Names
set "spell_count=0"
for %%A in ("Magic Missile" "Detect Monsters" "Phase Door" "Light Area"
            "Cure Light Wounds" "Find Hidden Traps/Doors" "Stinking Cloud"
            "Confusion" "Lightning Bolt" "Trap/Door Destruction" "Sleep I"
            "Cure Poison" "Teleport Self" "Remove Curse" "Frost Bolt"
            "Turn Stone to Mud" "Create Food" "Recharge Item I" "Sleep II"
            "Polymorph Other" "Identify" "Sleep III" "Fire Bolt" "Slow Monster"
            "Frost Ball" "Recharge Item II" "Teleport Other" "Haste Self"
            "Fire Ball" "Word of Destruction" "Genocide"
            "Detect Evil" "Cure Light Wounds" "Bless" "Remove Fear" "Call Light"
            "Find Traps" "Detect Doors/Stairs" "Slow Poison" "Blind Creature"
            "Portal" "Cure Medium Wounds" "Chant" "Sanctuary" "Create Food"
            "Remove Curse" "Resist Heat and Cold" "Neutralize Poison"
            "Orb of Draining" "Cure Serious Wounds" "Sense Invisible"
            "Protection from Evil" "Earthquake" "Sense Surroundings"
            "Cure Critical Wounds" "Turn Undead" "Prayer" "Dispel Undead" "Heal"
            "Dispel Evil" "Glyph of Warding" "Holy Word") do (
    set "spell_names[!spell_count!]=%%~A"
    set /a spell_count+=1
)
set "spell_count="

::----- Starting provisions
:: Note that the entries refer to elements of the game_objects[] array.
::      344 = Food Ration
::      365 = Wooden Torch
::      123 = Cloak
::      318 = Beginners-Magick
::      103 = Soft Leather Armor
::       30 = Stiletto
::      322 = Beginners Handbook
set "class_count=0"
call :addProvisions 344 365 123 30 103 %= Warrior =%
call :addProvisions 344 365 123 30 318 %= Mage =%
call :addProvisions 344 365 123 30 322 %= Priest =%
call :addProvisions 344 365 123 30 318 %= Rogue =%
call :addProvisions 344 365 123 30 318 %= Ranger =%
call :addProvisions 344 365 123 30 322 %= Paladin =%
set "class_count="
exit /b

::------------------------------------------------------------------------------
:: Adds a race type to the character_races array
::
:: Arguments: %1  - Name
::            %2  - STR adjustment
::            %3  - INT adjustment
::            %4  - WIS adjustment
::            %5  - DEX adjustment
::            %6  - CON adjustment
::            %7  - CHR adjustment
::            %8  - Base age
::            %9  - Age mod
::            %10 - Height base (male)
::            %11 - Height mod  (male)
::            %12 - Weight base (male)
::            %13 - Weight mod  (male)
::            %14 - Height base (female)
::            %15 - Height mod  (female)
::            %16 - Weight base (female)
::            %17 - Weight mod  (female)
::            %18 - Base chance to disarm
::            %19 - Base chance to search
::            %20 - Stealth
::            %21 - Frequency of auto search
::            %22 - Adjusted base chance to hit
::            %23 - Adjusted base chance to hit with bows
::            %24 - Race base for saving throws
::            %25 - Base hit points for race
::            %26 - Race can see infrared
::            %27 - Base experience factor
::            %28 - Bit field for class types (hexadecimal)
:: Returns:   None
::------------------------------------------------------------------------------
:addRaceToRaceList
set "character_races[%race_count%].name=%~1"
set "character_races[%race_count%].adjustment[0]=%~2"
set "character_races[%race_count%].adjustment[1]=%~3"
set "character_races[%race_count%].adjustment[2]=%~4"
set "character_races[%race_count%].adjustment[3]=%~5"
set "character_races[%race_count%].adjustment[4]=%~6"
set "character_races[%race_count%].adjustment[5]=%~7"
set "character_races[%race_count%].base_age=%~8"
set "character_races[%race_count%].max_age=%~9"

for /L %%A in (1,1,9) do shift

set "character_races[%race_count%].male_height_base=%~1"
set "character_races[%race_count%].male_height_mod=%~2"
set "character_races[%race_count%].male_weight_base=%~3"
set "character_races[%race_count%].male_weight_mod=%~4"
set "character_races[%race_count%].female_height_base=%~5"
set "character_races[%race_count%].female_height_mod=%~6"
set "character_races[%race_count%].female_weight_base=%~7"
set "character_races[%race_count%].female_weight_mod=%~8"
set "character_races[%race_count%].disarm_chance_base=%~9"

for /L %%A in (1,1,9) do shift

set "character_races[%race_count%].search_chance_base=%~1"
set "character_races[%race_count%].stealth=%~2"
set "character_races[%race_count%].fos=%~3"
set "character_races[%race_count%].base_to_hit=%~4"
set "character_races[%race_count%].base_to_hit_bows=%~5"
set "character_races[%race_count%].saving_throw_base=%~6"
set "character_races[%race_count%].hit_points_base=%~7"
set "character_races[%race_count%].infra_vision=%~8"
set "character_races[%race_count%].exp_factor_base=%~9"

for /L %%A in (1,1,9) do shift

set /a character_races[%race_count%].classes_bit_field=%~1
set /a race_count+=1
exit /b

::------------------------------------------------------------------------------
:: Adds a background part to the character_backgrounds array
::
:: Arguments: %1 - The snippet of background to add
::            %2 - Die roll needed for history
::            %3 - Table number
::            %4 - Pointer to the next table
::            %5 - Bonus to social class +50
:: Returns:   None
::------------------------------------------------------------------------------
:addBackgroundToBackgroundList
set "character_backgrounds[%bg_count%].info=%~1"
set "character_backgrounds[%bg_count%].roll=%~2"
set "character_backgrounds[%bg_count%].chart=%~3"
set "character_backgrounds[%bg_count%].next=%~4"
set "character_backgrounds[%bg_count%].bonus=%~5"
set /a bg_count+=1
exit /b

::------------------------------------------------------------------------------
:: Adds a class to the classes array
::
:: Arguments: %1  - Class title
::            %2  - Hit point adjustment
::            %3  - modifier to disarming traps
::            %4  - modifier to searching
::            %5  - modifier to stealth
::            %6  - modifier to frequency of search
::            %7  - modifier to base to-hit
::            %8  - modifier to base to-hit with bows
::            %9  - modifier to saving throws
::            %10 - modifier for STR
::            %11 - modifier for INT
::            %12 - modifier for WIS
::            %13 - modifier for DEX
::            %14 - modifier for CON
::            %15 - modifier for CHR
::            %16 - can use mage spells
::            %17 - class experience factor
::            %18 - first level where the class can use spells
:: Returns:   None
::------------------------------------------------------------------------------
:addClassToClassList
set "classes[%class_count%].title=%~1"
set "classes[%class_count%].hit_points=%~2"
set "classes[%class_count%].disarm_traps=%~3"
set "classes[%class_count%].searching=%~4"
set "classes[%class_count%].stealth=%~5"
set "classes[%class_count%].fos=%~6"
set "classes[%class_count%].base_to_hit=%~7"
set "classes[%class_count%].base_to_hit_with_bows=%~8"
set "classes[%class_count%].saving_throw=%~9"

for /L %%A in (1,1,9) do shift

set "classes[%class_count%].strength=%~1"
set "classes[%class_count%].intelligence=%~2"
set "classes[%class_count%].wisdom=%~3"
set "classes[%class_count%].dexterity=%~4"
set "classes[%class_count%].constitution=%~5"
set "classes[%class_count%].charisma=%~6"
set "classes[%class_count%].class_to_use_mage_spells=%~7"
set "classes[%class_count%].experience_factor=%~8"
set "classes[%class_count%].min_level_for_spell_casting=%~9"
set /a class_count+=1
exit /b

::------------------------------------------------------------------------------
:: Adds class level adjustments to assorted saves since they are independent of
:: class-specific values. Weirdly, this wasn't a struct in the C++ code, just
:: a 2D array.
::
:: Arguments: %1 - Base to-hit
::            %2 - Base to-hit with bows
::            %3 - Device
::            %4 - Disarm
::            %5 - Save/misc hit
:: Returns:   None
::------------------------------------------------------------------------------
:addAdjustment
set "class_level_adj[%class_count%][0]=%~1"
set "class_level_adj[%class_count%][1]=%~2"
set "class_level_adj[%class_count%][2]=%~3"
set "class_level_adj[%class_count%][3]=%~4"
set "class_level_adj[%class_count%][4]=%~5"
set /a class_count+=1
exit /b

::------------------------------------------------------------------------------
:: Adds a spell to the magic_spells array.
::
:: Arguments: %1 - Level required to learn
::            %2 - Mana required for spell
::            %3 - Chance of failure
::            %4 - Experience gained for learning the spell
:: Returns:   None
::------------------------------------------------------------------------------
:addSpellToSpellList
set "magic_spells[%class_id%][%spell_count%].level_required=%~1"
set "magic_spells[%class_id%][%spell_count%].mana_required=%~2"
set "magic_spells[%class_id%][%spell_count%].failure_chance=%3"
set "magic_spells[%class_id%][%spell_count%].exp_gain_for_learning=%~4"
set /a spell_count+=1
exit /b

::------------------------------------------------------------------------------
:: Adds class-based initial provisions
::
:: Arguments: %1 - food
::            %2 - torch
::            %3 - cloak
::            %4 - dagger
::            %5 - Soft Leather Armor for warriors
::                 Beginners-Magick for mages, rogues, and rangers
::                 Beginners Handbook for priests and paladins
::------------------------------------------------------------------------------
:addProvisions
set "class_base_provisions[%class_count%][0]=%~1"
set "class_base_provisions[%class_count%][1]=%~2"
set "class_base_provisions[%class_count%][2]=%~3"
set "class_base_provisions[%class_count%][3]=%~4"
set "class_base_provisions[%class_count%][4]=%~5"
set /a class_count
exit /b