:: This one is pure data. There are 279 creatures to add, but through the magic
:: of CTRL+C, CTRL+V, and CTRL+H, this isn't too bad to port over.
@echo off
set "monster_count=0"
call :loadAttackData

::                             Name                        CMOVE      SPELL      DEFENSE   XP SLP RNG AC SPD Sprite  hit_die  [attack_list ]  level
call :addMonsterToCreatureList "Filthy Street Urchin"      0x0012000A 0x00000000 0x2034     0  40  4   1  11 "p"     1  4     72 148   0   0   0
call :addMonsterToCreatureList "Blubbering Idiot"          0x0012000A 0x00000000 0x2030     0  0   6   1  11 "p"     1  2     79   0   0   0   0
call :addMonsterToCreatureList "Pitiful-Looking Beggar"    0x0012000A 0x00000000 0x2030     0  40 10   1  11 "p"     1  4     72   0   0   0   0
call :addMonsterToCreatureList "Mangy-Looking Leper"       0x0012000A 0x00000000 0x2030     0  50 10   1  11 "p"     1  1     72   0   0   0   0
call :addMonsterToCreatureList "Squint-Eyed Rogue"         0x07120002 0x00000000 0x2034     0  99 10   8  11 "p"     2  8      5 149   0   0   0
call :addMonsterToCreatureList "Singing Happy Drunk"       0x06120038 0x00000000 0x2030     0   0 10   1  11 "p"     2  3     72   0   0   0   0
call :addMonsterToCreatureList "Mean-Looking Mercenary"    0x0B12000A 0x00000000 0x2034     0 250 10  20  11 "p"     5  8      9   0   0   0   0
call :addMonsterToCreatureList "Battle-Scarred Veteran"    0x0B12000A 0x00000000 0x2030     0 250 10  30  11 "p"     7  8     15   0   0   0   0
call :addMonsterToCreatureList "Grey Mushroom patch"       0x00000001 0x00000000 0x10A0     1   0  2   1  11 ","     1  2     91   0   0   0   1
call :addMonsterToCreatureList "Giant Yellow Centipede"    0x00000002 0x00000000 0x0002     2  30  8  12  11 "c"     2  6     26  60   0   0   1
call :addMonsterToCreatureList "Giant White Centipede"     0x0000000A 0x00000000 0x0002     2  40  7  10  11 "c"     3  5     25  59   0   0   1
call :addMonsterToCreatureList "White Icky-Thing"          0x00000012 0x00000000 0x0020     2  10 12   7  11 "i"     3  5     63   0   0   0   1
call :addMonsterToCreatureList "Clear Icky-Thing"          0x00010012 0x00000000 0x0020     1  10 12   6  11 "i"     2  5     63   0   0   0   1
call :addMonsterToCreatureList "Giant White Mouse"         0x0020000A 0x00000000 0x2072     1  20  8   4  11 "r"     1  3     25   0   0   0   1
call :addMonsterToCreatureList "Large Brown Snake"         0x0000000A 0x00000000 0x00B2     3  99  4  35  10 "R"     4  6     26  73   0   0   1
call :addMonsterToCreatureList "Large White Snake"         0x00000012 0x00000000 0x00B2     2  99  4  30  11 "R"     3  6     24   0   0   0   1
call :addMonsterToCreatureList "Kobold"                    0x07820002 0x00000000 0x2030     5  10 20  16  11 "k"     3  7      5   0   0   0   1
call :addMonsterToCreatureList "White Worm mass"           0x00200022 0x00000000 0x01B2     2  10  7   1  10 "w"     4  4    173   0   0   0   1
call :addMonsterToCreatureList "Floating Eye"              0x00000001 0x0001000D 0x2100     1  10  2   6  11 "e"     3  6    146   0   0   0   1
call :addMonsterToCreatureList "Shrieker Mushroom patch"   0x00000001 0x00000000 0x10A0     1   0  2   1  11 ","     1  1    203   0   0   0   2
call :addMonsterToCreatureList "Blubbering Icky-Thing"     0x0B980012 0x00000000 0x0020     8  10 14   4  11 "i"     5  8    174 210   0   0   2
call :addMonsterToCreatureList "Metallic Green Centipede"  0x00000012 0x00000000 0x0002     3  10  5   4  12 "c"     4  4     68   0   0   0   2
call :addMonsterToCreatureList "Novice Warrior"            0x07020002 0x00000000 0x2030     6   5 20  16  11 "p"     9  4      6   0   0   0   2
call :addMonsterToCreatureList "Novice Rogue"              0x07120002 0x00000000 0x2034     6   5 20  12  11 "p"     8  4      5 148   0   0   2
call :addMonsterToCreatureList "Novice Priest"             0x07020002 0x0000108C 0x2030     7   5 20  10  11 "p"     7  4      4   0   0   0   2
call :addMonsterToCreatureList "Novice Mage"               0x07020002 0x0000089C 0x2030     7   5 20   6  11 "p"     6  4      3   0   0   0   2
call :addMonsterToCreatureList "Yellow Mushroom patch"     0x00000001 0x00000000 0x10A0     2   0  2   1  11 ","     1  1    100   0   0   0   2
call :addMonsterToCreatureList "White Jelly"               0x00000001 0x00000000 0x11A0    10  99  2   1  12 "J"     8  8    168   0   0   0   2
call :addMonsterToCreatureList "Giant Green Frog"          0x0000000A 0x00000000 0x00A2     6  30 12   8  11 "f"     2  8     26   0   0   0   2
call :addMonsterToCreatureList "Giant Black Ant"           0x0000000A 0x00000000 0x0002     8  80  8  20  11 "a"     3  6     27   0   0   0   2
call :addMonsterToCreatureList "White Harpy"               0x00000012 0x00000000 0x2034     5  10 16  17  11 "h"     2  5     49  49  25   0   2
call :addMonsterToCreatureList "Blue Yeek"                 0x07020002 0x00000000 0x2030     4  10 18  14  11 "y"     2  6      4   0   0   0   2
call :addMonsterToCreatureList "Green Worm mass"           0x00200022 0x00000000 0x0132     3  10  7   3  10 "w"     6  4    140   0   0   0   2
call :addMonsterToCreatureList "Large Black Snake"         0x0000000A 0x00000000 0x00B2     9  75  5  38  10 "R"     4  8     27  74   0   0   2
call :addMonsterToCreatureList "Poltergeist"               0x0F95003A 0x0000001F 0x110C     6  10  8  15  13 "G"     2  5     93   0   0   0   3
call :addMonsterToCreatureList "Metallic Blue Centipede"   0x00000012 0x00000000 0x0002     7  15  6   6  12 "c"     4  5     69   0   0   0   3
call :addMonsterToCreatureList "Giant White Louse"         0x00200022 0x00000000 0x01F2     1  10  6   5  12 "l"     1  1     24   0   0   0   3
call :addMonsterToCreatureList "Black Naga"                0x0710000A 0x00000000 0x20E4    20 120 16  40  11 "n"     6  8     75   0   0   0   3
call :addMonsterToCreatureList "Spotted Mushroom patch"    0x00000001 0x00000000 0x10A0     3   0  2   1  11 ","     1  1    175   0   0   0   3
call :addMonsterToCreatureList "Yellow Jelly"              0x00000001 0x0001000F 0x11A0    12  99  2   1  12 "J"    10  8    169   0   0   0   3
call :addMonsterToCreatureList "Scruffy-Looking Hobbit"    0x07920002 0x00000000 0x2034     4  10 16   8  11 "p"     3  5      3 148   0   0   3
call :addMonsterToCreatureList "Huge Brown Bat"            0x00000022 0x00000000 0x2162     4  40  8  12  13 "b"     2  6     25   0   0   0   3
call :addMonsterToCreatureList "Giant White Ant"           0x00000002 0x00000000 0x0002     7  80  8  16  11 "a"     3  6     27   0   0   0   3
call :addMonsterToCreatureList "Yellow Mold"               0x00000001 0x00000000 0x10A0     9  99  2  10  11 "m"     8  8      3   0   0   0   3
call :addMonsterToCreatureList "Metallic Red Centipede"    0x0000000A 0x00000000 0x0002    12  20  8   9  12 "c"     4  8     69   0   0   0   3
call :addMonsterToCreatureList "Yellow Worm mass"          0x00200022 0x00000000 0x01B2     4  10  7   4  10 "w"     4  8    182   0   0   0   3
call :addMonsterToCreatureList "Large Green Snake"         0x0000000A 0x00000000 0x00B2    10  70  5  40  10 "R"     6  8     27  74   0   0   3
call :addMonsterToCreatureList "Radiation Eye"             0x00000001 0x0001000B 0x2100     6  10  2   6  11 "e"     3  6     88   0   0   0   3
call :addMonsterToCreatureList "Drooling Harpy"            0x00000012 0x00000000 0x2034     7  10 16  22  11 "h"     2  8     49  49  25  79   3
call :addMonsterToCreatureList "Silver Mouse"              0x0020000A 0x00000000 0x0072     1  10  8   5  11 "r"     1  1    212   0   0   0   4
call :addMonsterToCreatureList "Black Mushroom patch"      0x00000001 0x00000000 0x10A0     8   0  2   1  11 ","     8  8     71   0   0   0   4
call :addMonsterToCreatureList "Blue Jelly"                0x00000001 0x00400000 0x11A0    14  99  2   1  11 "J"    12  8    125   0   0   0   4
call :addMonsterToCreatureList "Creeping Copper Coins"     0x12000002 0x00000000 0x1000     9  10  3  24  10 "$"     7  8      3 170   0   0   4
call :addMonsterToCreatureList "Giant White Rat"           0x0020000A 0x00000000 0x2072     1  30  8   7  11 "r"     2  2    153   0   0   0   4
call :addMonsterToCreatureList "Giant Black Centipede"     0x0000000A 0x00000000 0x0002    11  30  8  20  11 "c"     5  8     25  59   0   0   4
call :addMonsterToCreatureList "Giant Blue Centipede"      0x00000002 0x00000000 0x0002    10  50  8  20  11 "c"     4  8     26  61   0   0   4
call :addMonsterToCreatureList "Blue Worm mass"            0x00200022 0x00400000 0x01A2     5  10  7  12  10 "w"     5  8    129   0   0   0   4
call :addMonsterToCreatureList "Large Grey Snake"          0x0000000A 0x00000000 0x00B2    14  50  6  41  10 "R"     6  8     28  75   0   0   4
call :addMonsterToCreatureList "Jackal"                    0x00000012 0x00000000 0x2032     8  30 12  16  11 "j"     3  8     29   0   0   0   4
call :addMonsterToCreatureList "Green Naga"                0x0710000A 0x00200000 0x2064    30 120 18  40  11 "n"     9  8     75 118   0   0   5
call :addMonsterToCreatureList "Green Glutton Ghost"       0x0F950032 0x0000003F 0x110C    15  10 10  20  13 "G"     3  6    211   0   0   0   5
call :addMonsterToCreatureList "White Mushroom patch"      0x00000001 0x00000000 0x10A0     5   0  2   1  11 ","     1  1    147   0   0   0   5
call :addMonsterToCreatureList "Green Jelly"               0x00000001 0x00200000 0x1120    18  99  2   1  12 "J"    22  8    136   0   0   0   5
call :addMonsterToCreatureList "Skeleton Kobold"           0x00020002 0x00000000 0x100C    12  40 20  26  11 "s"     5  8      5   0   0   0   5
call :addMonsterToCreatureList "Silver Jelly"              0x00000001 0x00000000 0x10A0    15  40  2  25  11 "J"    20  8    213   0   0   0   5
call :addMonsterToCreatureList "Giant Black Frog"          0x0000000A 0x00000000 0x00A2    12  40 12  18  11 "f"     4  8     29   0   0   0   5
call :addMonsterToCreatureList "Grey Icky-Thing"           0x00000012 0x00000000 0x0020    10  15 14  12  11 "i"     4  8     66   0   0   0   5
call :addMonsterToCreatureList "Disenchanter Eye"          0x00000001 0x00010009 0x2100    20  10  2  10  10 "e"     7  8    207   0   0   0   5
call :addMonsterToCreatureList "Black Yeek"                0x07020002 0x00000000 0x2030     8  10 18  16  11 "y"     2  8      4   0   0   0   5
call :addMonsterToCreatureList "Red Worm mass"             0x00200022 0x00800000 0x2192     6  10  7  12  10 "w"     5  8    111   0   0   0   5
call :addMonsterToCreatureList "Giant House Fly"           0x00000022 0x00000000 0x0062    10  20 12  16  13 "F"     3  8     25   0   0   0   5
call :addMonsterToCreatureList "Copperhead Snake"          0x00000012 0x00000000 0x00B2    15   1  6  20  11 "R"     4  6    158   0   0   0   5
call :addMonsterToCreatureList "Rot Jelly"                 0x00000001 0x00000000 0x10A0    15  99  2  30  11 "J"    20  8    209   0   0   0   5
call :addMonsterToCreatureList "Purple Mushroom patch"     0x00000001 0x00000000 0x10A0    12   0  2   1  12 ","     1  1    183   0   0   0   6
call :addMonsterToCreatureList "Brown Mold"                0x00000001 0x00000000 0x10A0    20  99  2  12  11 "m"    15  8     89   0   0   0   6
call :addMonsterToCreatureList "Giant Brown Bat"           0x0000001A 0x00000000 0x2162    10  30 10  15  13 "b"     3  8     26   0   0   0   6
call :addMonsterToCreatureList "Creeping Silver Coins"     0x16000002 0x00000000 0x1000    18  10  4  30  10 "$"    12  8      5 171   0   0   6
call :addMonsterToCreatureList "Orc"                       0x0B020002 0x00000000 0x2034    16  30 20  32  11 "o"     9  8      7   0   0   0   6
call :addMonsterToCreatureList "Grey Harpy"                0x00000012 0x00000000 0x2034    14  10 16  20  12 "h"     3  8     50  50  25   0   6
call :addMonsterToCreatureList "Blue Icky-Thing"           0x00000012 0x00400000 0x0020    12  20 14  14  11 "i"     4  8    126   0   0   0   6
call :addMonsterToCreatureList "Rattlesnake"               0x00000012 0x00000000 0x00B2    20   1  6  24  11 "R"     6  7    159   0   0   0   6
call :addMonsterToCreatureList "Bloodshot Eye"             0x00000001 0x00010007 0x2100    15  10  2   6  11 "e"     4  8    143   0   0   0   7
call :addMonsterToCreatureList "Red Naga"                  0x0710000A 0x00000000 0x20E4    40 120 20  40  11 "n"    11  8     76  82   0   0   7
call :addMonsterToCreatureList "Red Jelly"                 0x00000001 0x00000000 0x11A0    26  99  2   1  11 "J"    26  8     87   0   0   0   7
call :addMonsterToCreatureList "Giant Red Frog"            0x0000000A 0x00000000 0x00A2    16  50 12  16  11 "f"     5  8     83   0   0   0   7
call :addMonsterToCreatureList "Green Icky-Thing"          0x00000012 0x00000000 0x0020    18  20 14  12  11 "i"     5  8    137   0   0   0   7
call :addMonsterToCreatureList "Zombie Kobold"             0x00020002 0x00000000 0x102C    14  30 20  14  11 "z"     6  8      1   1   0   0   7
call :addMonsterToCreatureList "Lost Soul"                 0x0F95001A 0x0001002F 0x110C    18  10 12  10  11 "G"     2  8     11 185   0   0   7
call :addMonsterToCreatureList "Greedy Little Gnome"       0x0B920002 0x00000000 0x2034    13  10 18  14  11 "p"     3  8      6 149   0   0   7
call :addMonsterToCreatureList "Giant Green Fly"           0x00000022 0x00000000 0x0062    15  20 12  14  12 "F"     3  8     27   0   0   0   7
call :addMonsterToCreatureList "Brown Yeek"                0x07020002 0x00000000 0x2030    11  10 18  18  11 "y"     3  8      5   0   0   0   8
call :addMonsterToCreatureList "Green Mold"                0x00000001 0x00000000 0x10A0    28  75  2  14  11 "m"    21  8     94   0   0   0   8
call :addMonsterToCreatureList "Skeleton Orc"              0x00020002 0x00000000 0x100C    26  40 20  36  11 "s"    10  8     14   0   0   0   8
call :addMonsterToCreatureList "Seedy Looking Human"       0x13020002 0x00000000 0x2034    22  20 20  26  11 "p"     8  8     17   0   0   0   8
call :addMonsterToCreatureList "Red Icky-Thing"            0x00000012 0x00200000 0x0020    22  20 14  18  12 "i"     4  8     64 117   0   0   8
call :addMonsterToCreatureList "Bandit"                    0x13120002 0x00000000 0x2034    26  10 20  24  11 "p"     8  8     13 148   0   0   8
call :addMonsterToCreatureList "Yeti"                      0x00020002 0x00400000 0x2024    30  10 20  24  11 "Y"    11  8     51  51  27   0   9
call :addMonsterToCreatureList "Bloodshot Icky-Thing"      0x00000012 0x0001000B 0x0020    24  20 14  18  11 "i"     7  8     65 139   0   0   9
call :addMonsterToCreatureList "Giant Grey Rat"            0x0020000A 0x00000000 0x2072     2  20  8  12  11 "r"     2  3    154   0   0   0   9
call :addMonsterToCreatureList "Black Harpy"               0x0000000A 0x00000000 0x2034    19  10 16  22  12 "h"     3  8     50  50  26   0   9
call :addMonsterToCreatureList "Giant Black Bat"           0x00000012 0x00000000 0x2162    16  25 12  18  13 "b"     2  8     29   0   0   0   9
call :addMonsterToCreatureList "Clear Yeek"                0x07030002 0x00000000 0x0030    14  10 18  24  11 "y"     3  6      4   0   0   0   9
call :addMonsterToCreatureList "Orc Shaman"                0x0B020002 0x00008085 0x2034    30  20 20  15  11 "o"     7  8      5   0   0   0   9
call :addMonsterToCreatureList "Giant Red Ant"             0x00000002 0x00000000 0x0002    22  60 12  34  11 "a"     4  8     27  85   0   0   9
call :addMonsterToCreatureList "King Cobra"                0x00000012 0x00000000 0x00B2    28   1  8  30  11 "R"     8  8    144 161   0   0   9
call :addMonsterToCreatureList "Clear Mushroom patch"      0x00210001 0x00000000 0x10A0     1   0  4   1  12 ","     1  1     70   0   0   0  10
call :addMonsterToCreatureList "Giant White Tick"          0x0000000A 0x00000000 0x0022    27  20 12  40  10 "t"    15  8    160   0   0   0  10
call :addMonsterToCreatureList "Hairy Mold"                0x00000001 0x00000000 0x10A0    32  70  2  15  11 "m"    15  8    151   0   0   0  10
call :addMonsterToCreatureList "Disenchanter Mold"         0x00000001 0x0001000B 0x10A0    40  70  2  20  11 "m"    16  8    206   0   0   0  10
call :addMonsterToCreatureList "Giant Red Centipede"       0x00000002 0x00000000 0x0002    24  50 12  26  12 "c"     3  8     25 164   0   0  10
call :addMonsterToCreatureList "Creeping Gold Coins"       0x1A000002 0x00000000 0x1000    32  10  5  36  10 "$"    18  8     14 172   0   0  10
call :addMonsterToCreatureList "Giant Fruit Fly"           0x00200022 0x00000000 0x0062     4  10  8  14  12 "F"     2  2     25   0   0   0  10
call :addMonsterToCreatureList "Brigand"                   0x13120002 0x00000000 0x2034    35  10 20  32  11 "p"     9  8     13 149   0   0  10
call :addMonsterToCreatureList "Orc Zombie"                0x00020002 0x00000000 0x102C    30  25 20  24  11 "z"    11  8      3   3   0   0  11
call :addMonsterToCreatureList "Orc Warrior"               0x0B020002 0x00000000 0x2034    34  25 20  36  11 "o"    11  8     15   0   0   0  11
call :addMonsterToCreatureList "Vorpal Bunny"              0x0020000A 0x00000000 0x2072     2  30  8  10  12 "r"     2  3     28   0   0   0  11
call :addMonsterToCreatureList "Nasty Little Gnome"        0x13820002 0x000020B5 0x2034    32  10 18  10  11 "p"     4  8      4   0   0   0  11
call :addMonsterToCreatureList "Hobgoblin"                 0x0F020002 0x00000000 0x2034    38  30 20  38  11 "H"    12  8      9   0   0   0  11
call :addMonsterToCreatureList "Black Mamba"               0x00000012 0x00000000 0x00B2    40   1 10  32  12 "R"    10  8    163   0   0   0  12
call :addMonsterToCreatureList "Grape Jelly"               0x00000001 0x0001000B 0x11A0    60  99  2   1  11 "J"    52  8    186   0   0   0  12
call :addMonsterToCreatureList "Master Yeek"               0x07020002 0x00008018 0x2030    28  10 18  24  11 "y"     5  8      7   0   0   0  12
call :addMonsterToCreatureList "Priest"                    0x13020002 0x00000285 0x2030    36  40 20  22  11 "p"     7  8     12   0   0   0  12
call :addMonsterToCreatureList "Giant Clear Ant"           0x00010002 0x00000000 0x0002    24  60 12  18  11 "a"     3  7     27   0   0   0  12
call :addMonsterToCreatureList "Air Spirit"                0x00030022 0x00000000 0x1000    40  20 12  20  13 "E"     5  8      2   0   0   0  12
call :addMonsterToCreatureList "Skeleton Human"            0x00020002 0x00000000 0x100C    38  30 20  30  11 "s"    12  8      7   0   0   0  12
call :addMonsterToCreatureList "Human Zombie"              0x00020002 0x00000000 0x102C    34  20 20  24  11 "z"    11  8      3   3   0   0  12
call :addMonsterToCreatureList "Moaning Spirit"            0x0F15000A 0x0001002F 0x110C    44  10 14  20  11 "G"     4  8     99 178   0   0  12
call :addMonsterToCreatureList "Swordsman"                 0x13020002 0x00000000 0x2030    40  20 20  34  11 "p"    11  8     18   0   0   0  12
call :addMonsterToCreatureList "Killer Brown Beetle"       0x0000000A 0x00000000 0x0002    38  30 10  40  11 "K"    13  8     41   0   0   0  13
call :addMonsterToCreatureList "Ogre"                      0x07020002 0x00000000 0x2034    42  30 20  32  11 "o"    13  8     16   0   0   0  13
call :addMonsterToCreatureList "Giant Red Speckled Frog"   0x0000000A 0x00000000 0x00A2    32  30 12  20  11 "f"     6  8     41   0   0   0  13
call :addMonsterToCreatureList "Magic User"                0x13020002 0x00002413 0x2030    35  10 20  10  11 "p"     7  8     11   0   0   0  13
call :addMonsterToCreatureList "Black Orc"                 0x0B020002 0x00000000 0x2034    40  20 20  36  11 "o"    12  8     17   0   0   0  13
call :addMonsterToCreatureList "Giant Long-Eared Bat"      0x00000012 0x00000000 0x2162    20  20 12  20  13 "b"     5  8     27  50  50   0  13
call :addMonsterToCreatureList "Giant Gnat"                0x00200022 0x00000000 0x0062     1  10  8   4  13 "F"     1  2     24   0   0   0  13
call :addMonsterToCreatureList "Killer Green Beetle"       0x0000000A 0x00000000 0x0002    46  30 12  45  11 "K"    16  8     43   0   0   0  14
call :addMonsterToCreatureList "Giant Flea"                0x00200022 0x00000000 0x0062     1  10  8  25  12 "F"     2  2     25   0   0   0  14
call :addMonsterToCreatureList "Giant White Dragon Fly"    0x00000012 0x0040000A 0x0062    54  50 20  20  11 "F"     5  8    122   0   0   0  14
call :addMonsterToCreatureList "Hill Giant"                0x07020002 0x00000000 0x2034    52  50 20  36  11 "P"    16  8     19   0   0   0  14
call :addMonsterToCreatureList "Skeleton Hobgoblin"        0x00020002 0x00000000 0x100C    46  30 20  34  11 "s"    13  8     14   0   0   0  14
call :addMonsterToCreatureList "Flesh Golem"               0x00000002 0x00000000 0x1030    48  10 12  10  11 "g"    12  8      5   5   0   0  14
call :addMonsterToCreatureList "White Dragon Bat"          0x00000012 0x00400004 0x0162    40  50 12  20  13 "b"     2  6    121   0   0   0  14
call :addMonsterToCreatureList "Giant Black Louse"         0x00200012 0x00000000 0x01F2     1  10  6   7  12 "l"     1  1     25   0   0   0  14
call :addMonsterToCreatureList "Guardian Naga"             0x1710000A 0x00000000 0x20E4    60 120 20  50  11 "n"    24  8     77  31   0   0  15
call :addMonsterToCreatureList "Giant Grey Bat"            0x00000012 0x00000000 0x2162    22  15 12  22  13 "b"     4  8     29  50  50   0  15
call :addMonsterToCreatureList "Giant Clear Centipede"     0x00010002 0x00000000 0x0002    30  30 12  30  11 "c"     5  8     34  62   0   0  15
call :addMonsterToCreatureList "Giant Yellow Tick"         0x0000000A 0x00000000 0x0022    48  20 12  48  10 "t"    20  8    162   0   0   0  15
call :addMonsterToCreatureList "Giant Ebony Ant"           0x00200002 0x00000000 0x0002     3  60 12  24  11 "a"     3  4     33   0   0   0  15
call :addMonsterToCreatureList "Frost Giant"               0x07020002 0x00400000 0x0024    54  50 20  38  11 "P"    17  8    120   0   0   0  15
call :addMonsterToCreatureList "Clay Golem"                0x00000002 0x00000000 0x1200    50  10 12  20  11 "g"    14  8      7   7   0   0  15
call :addMonsterToCreatureList "Huge White Bat"            0x00200012 0x00000000 0x2162     3  40  7  12  12 "b"     3  8     29   0   0   0  15
call :addMonsterToCreatureList "Giant Tan Bat"             0x00000012 0x00000000 0x2162    18  40 12  18  12 "b"     3  8     95  49  49   0  15
call :addMonsterToCreatureList "Violet Mold"               0x00000001 0x00010009 0x10A0    50  70  2  15  11 "m"    17  8    145   0   0   0  15
call :addMonsterToCreatureList "Umber Hulk"                0x00020002 0x00000000 0x2124    75  10 20  20  11 "U"    20  8     92   5   5  36  16
call :addMonsterToCreatureList "Gelatinous Cube"           0x2F98000A 0x00200000 0x1020    36   1 12  18  10 "C"    45  8    115   0   0   0  16
call :addMonsterToCreatureList "Giant Black Rat"           0x0020000A 0x00000000 0x2072     3  20  8  16  11 "r"     3  4    155   0   0   0  16
call :addMonsterToCreatureList "Giant Green Dragon Fly"    0x00000012 0x0010000A 0x0032    58  50 20  20  11 "F"     5  8    156   0   0   0  16
call :addMonsterToCreatureList "Fire Giant"                0x07020002 0x00800000 0x2014    62  50 20  40  11 "P"    20  8    102   0   0   0  16
call :addMonsterToCreatureList "Green Dragon Bat"          0x00000012 0x00100004 0x2112    44  50 12  22  13 "b"     2  7    153   0   0   0  16
call :addMonsterToCreatureList "Quasit"                    0x1183000A 0x000010FA 0x1004    48  20 20  30  11 "q"     5  8    176  51  51   0  16
call :addMonsterToCreatureList "Troll"                     0x0F020002 0x00000000 0x2024    64  40 20  40  11 "T"    17  8      3   3  29   0  17
call :addMonsterToCreatureList "Water Spirit"              0x0000000A 0x00000000 0x1020    58  40 12  28  12 "E"     8  8     13   0   0   0  17
call :addMonsterToCreatureList "Giant Brown Scorpion"      0x0000000A 0x00000000 0x0002    62  20 12  44  11 "S"    11  8     34  86   0   0  17
call :addMonsterToCreatureList "Earth Spirit"              0x0016000A 0x00000000 0x1200    64  50 10  40  11 "E"    13  8      7   7   0   0  17
call :addMonsterToCreatureList "Fire Spirit"               0x0000000A 0x00800000 0x3010    66  20 16  30  12 "E"    10  8    101   0   0   0  18
call :addMonsterToCreatureList "Uruk-Hai Orc"              0x0B020002 0x00000000 0x2034    68  20 20  42  11 "o"    14  8     18   0   0   0  18
call :addMonsterToCreatureList "Stone Giant"               0x07020002 0x00000000 0x2204    80  50 20  40  11 "P"    22  8     20   0   0   0  18
call :addMonsterToCreatureList "Stone Golem"               0x00000002 0x00000000 0x1200   100  10 12  75  10 "g"    28  8      9   9   0   0  19
call :addMonsterToCreatureList "Grey Ooze"                 0x07980022 0x00400000 0x10A0    40   1 15  10  11 "O"     6  8    127   0   0   0  19
call :addMonsterToCreatureList "Disenchanter Ooze"         0x07980022 0x00000000 0x10B0    50   1 15  15  11 "O"     6  8    205   0   0   0  19
call :addMonsterToCreatureList "Giant Spotted Rat"         0x0020000A 0x00000000 0x2072     3  20  8  20  11 "r"     4  3    155   0   0   0  19
call :addMonsterToCreatureList "Mummified Kobold"          0x0B820002 0x00000000 0x102C    46  75 20  24  11 "M"    13  8      5   5   0   0  19
call :addMonsterToCreatureList "Killer Black Beetle"       0x0000000A 0x00000000 0x0002    75  30 12  46  11 "K"    18  8     44   0   0   0  19
call :addMonsterToCreatureList "Red Mold"                  0x00000001 0x00800000 0x3090    64  70  2  16  11 "m"    17  8    108   0   0   0  19
call :addMonsterToCreatureList "Quylthulg"                 0x00010004 0x00002017 0x5000   200   0 10   1  11 "Q"     4  8      0   0   0   0  20
call :addMonsterToCreatureList "Giant Red Bat"             0x00000012 0x00000000 0x2162    40  20 12  24  12 "b"     5  8     30  51  51   0  20
call :addMonsterToCreatureList "Giant Black Dragon Fly"    0x00000012 0x00200009 0x0072    58  50 20  22  11 "F"     4  8    141   0   0   0  20
call :addMonsterToCreatureList "Cloud Giant"               0x07020002 0x00080000 0x2034   125  50 20  44  11 "P"    24  8    130   0   0   0  20
call :addMonsterToCreatureList "Black Dragon Bat"          0x00000012 0x00200004 0x2152    50  50 12  24  13 "b"     2  8    112   0   0   0  21
call :addMonsterToCreatureList "Blue Dragon Bat"           0x00000012 0x00080004 0x2052    54  50 12  26  13 "b"     3  6    131   0   0   0  21
call :addMonsterToCreatureList "Mummified Orc"             0x0B020002 0x00000000 0x102C    56  75 20  28  11 "M"    14  8     13  13   0   0  21
call :addMonsterToCreatureList "Killer Boring Beetle"      0x0000000A 0x00000000 0x0002    70  30 12  48  11 "K"    18  8     44   0   0   0  21
call :addMonsterToCreatureList "Killer Stag Beetle"        0x0000000A 0x00000000 0x0002    80  30 12  50  11 "K"    20  8     41  10   0   0  22
call :addMonsterToCreatureList "Black Mold"                0x00000081 0x00000000 0x10A0    68  50  2  18  11 "m"    15  8     21   0   0   0  22
call :addMonsterToCreatureList "Iron Golem"                0x00000002 0x00000000 0x1080   160  10 12  99   9 "g"    80  8     10  10   0   0  22
call :addMonsterToCreatureList "Giant Yellow Scorpion"     0x0000000A 0x00000000 0x0002    60  20 12  38  11 "S"    12  8     31 167   0   0  22
call :addMonsterToCreatureList "Green Ooze"                0x07BA0012 0x00200000 0x1030     6   1 15   5  10 "O"     4  8    116   0   0   0  22
call :addMonsterToCreatureList "Black Ooze"                0x07BA0012 0x0001000B 0x1030     7   1 10   6   9 "O"     6  8    138   0   0   0  23
call :addMonsterToCreatureList "Warrior"                   0x13020002 0x00000000 0x2030    60  40 20  40  11 "p"    15  8     18   0   0   0  23
call :addMonsterToCreatureList "Red Dragon Bat"            0x00000012 0x00800004 0x2152    60  50 12  28  13 "b"     3  8    105   0   0   0  23
call :addMonsterToCreatureList "Killer Blue Beetle"        0x0000000A 0x00000000 0x0002    85  30 14  50  11 "K"    20  8     44   0   0   0  23
call :addMonsterToCreatureList "Giant Silver Ant"          0x0000000A 0x00200000 0x0002    45  60 10  38  11 "a"     6  8    114   0   0   0  23
call :addMonsterToCreatureList "Crimson Mold"              0x00000001 0x00000000 0x10A0    65  50  2  18  11 "m"    16  8      2  97   0   0  23
call :addMonsterToCreatureList "Forest Wight"              0x0F02000A 0x0000100F 0x112C   140  30 20  30  11 "W"    12  8      5   5 187   0  24
call :addMonsterToCreatureList "Berzerker"                 0x13020002 0x00000000 0x2030    65  10 20  20  11 "p"    15  8      7   7   0   0  24
call :addMonsterToCreatureList "Mummified Human"           0x0B020002 0x00000000 0x102C    70  60 20  34  11 "M"    17  8     13  13   0   0  24
call :addMonsterToCreatureList "Banshee"                   0x0F15001A 0x0001002F 0x110C    60  10 20  24  12 "G"     6  8     99 188   0   0  24
call :addMonsterToCreatureList "Giant Troll"               0x0F020002 0x00000000 0x2024    85  50 20  40  11 "T"    19  8      5   5  41   0  25
call :addMonsterToCreatureList "Giant Brown Tick"          0x0000000A 0x00000000 0x0022    70  20 12  50  10 "t"    18  8    157 142   0   0  25
call :addMonsterToCreatureList "Killer Red Beetle"         0x0000000A 0x00000000 0x0002    85  30 14  50  11 "K"    20  8     84   0   0   0  25
call :addMonsterToCreatureList "Wooden Mold"               0x00000001 0x00000000 0x10A0   100  50  2  50  11 "m"    25  8    171   0   0   0  25
call :addMonsterToCreatureList "Giant Blue Dragon Fly"     0x00000012 0x00080009 0x0072    75  50 20  24  11 "F"     6  8     29   0   0   0  25
call :addMonsterToCreatureList "Giant Grey Ant Lion"       0x0008000A 0x00000000 0x0032    90  40 10  40  11 "A"    19  8     39   0   0   0  26
call :addMonsterToCreatureList "Disenchanter Bat"          0x00000012 0x00000000 0x2162    75   1 14  24  13 "b"     4  8    204   0   0   0  26
call :addMonsterToCreatureList "Giant Fire Tick"           0x0000000A 0x00800000 0x2012    90  20 14  54  11 "t"    16  8    109   0   0   0  26
call :addMonsterToCreatureList "White Wraith"              0x0F02000A 0x0000100C 0x112C   165  10 20  40  11 "W"    15  8      5   5 189   0  26
call :addMonsterToCreatureList "Giant Black Scorpion"      0x0000000A 0x00000000 0x0002    85  20 12  50  11 "S"    13  8     32 167   0   0  26
call :addMonsterToCreatureList "Clear Ooze"                0x0799000A 0x00000000 0x10B0    12   1 10  14  11 "O"     4  8     90   0   0   0  26
call :addMonsterToCreatureList "Killer Fire Beetle"        0x0000000A 0x00800000 0x2012    95  30 14  45  11 "K"    13  8     41 110   0   0  27
call :addMonsterToCreatureList "Vampire"                   0x17020002 0x00001209 0x112C   175  10 20  45  11 "V"    20  8      5   5 190   0  27
call :addMonsterToCreatureList "Giant Red Dragon Fly"      0x00000012 0x00800008 0x2052    75  50 20  24  11 "F"     7  8     96   0   0   0  27
call :addMonsterToCreatureList "Shimmering Mold"           0x00000081 0x00080000 0x10A0   180  50  2  24  11 "m"    32  8    135   0   0   0  27
call :addMonsterToCreatureList "Black Knight"              0x13020002 0x0000010F 0x2034   140  10 20  60  11 "p"    25  8     23   0   0   0  28
call :addMonsterToCreatureList "Mage"                      0x13020002 0x00002C73 0x2030   150  10 20  30  11 "p"    10  8     14   0   0   0  28
call :addMonsterToCreatureList "Ice Troll"                 0x0F020002 0x00400000 0x0024   160  50 20  46  11 "T"    22  8      4   4 123   0  28
call :addMonsterToCreatureList "Giant Purple Worm"         0x0000000A 0x00200000 0x2032   400  30 14  65  11 "w"    65  8      7 113 166   0  29
call :addMonsterToCreatureList "Young Blue Dragon"         0x1F00000A 0x0008100B 0x2005   300  70 20  50  11 "d"    33  8     52  52  29   0  29
call :addMonsterToCreatureList "Young White Dragon"        0x1F00000A 0x0040100B 0x0025   275  70 20  50  11 "d"    32  8     52  52  29   0  29
call :addMonsterToCreatureList "Young Green Dragon"        0x1F00000A 0x0010100B 0x2005   290  70 20  50  11 "d"    32  8     52  52  29   0  29
call :addMonsterToCreatureList "Giant Fire Bat"            0x00000012 0x00800000 0x2152    85  10 14  30  12 "b"     5  8    106  52  52   0  29
call :addMonsterToCreatureList "Giant Glowing Rat"         0x0020000A 0x00080000 0x2072     4  20  8  24  11 "r"     3  3    132   0   0   0  29

:: Some of the creatures have Max hit points noted in CDEFENSE as the "4000" bit set
call :addMonsterToCreatureList "Skeleton Troll"            0x00020002 0x00000000 0x500C   225  20 20  55  11 "s"    14  8      5   5  41   0  30
call :addMonsterToCreatureList "Giant Lightning Bat"       0x00000012 0x00080000 0x2042    80  10 15  34  12 "b"     8  8    133  53  53   0  30
call :addMonsterToCreatureList "Giant Static Ant"          0x0000000A 0x00080000 0x0002    80  60 10  40  11 "a"     8  8    134   0   0   0  30
call :addMonsterToCreatureList "Grave Wight"               0x0F02000A 0x0000110A 0x512C   325  30 20  35  11 "W"    12  8      6   6 191   0  30
call :addMonsterToCreatureList "Killer Slicer Beetle"      0x0000000A 0x00000000 0x0002   200  30 14  55  11 "K"    22  8     48   0   0   0  30
call :addMonsterToCreatureList "Giant White Ant Lion"      0x0008000A 0x00400000 0x0022   175  40 12  45  11 "A"    20  8    124   0   0   0  30
call :addMonsterToCreatureList "Ghost"                     0x1715000A 0x0001002F 0x510C   350  10 20  30  12 "G"    13  8     99 192 184   0  31
call :addMonsterToCreatureList "Giant Black Ant Lion"      0x0008000A 0x00200000 0x0032   170  40 14  45  11 "A"    23  8     39 119   0   0  31
call :addMonsterToCreatureList "Death Watch Beetle"        0x0000000A 0x00000000 0x0002   190  30 16  60  11 "K"    25  8     47  67   0   0  31
call :addMonsterToCreatureList "Ogre Mage"                 0x0B020002 0x0000A355 0x6034   250  30 20  42  11 "o"    14  8     19   0   0   0  31
call :addMonsterToCreatureList "Two-Headed Troll"          0x0F020002 0x00000000 0x6024   275  50 20  48  11 "T"    14  8      7   7  29  29  32
call :addMonsterToCreatureList "Invisible Stalker"         0x00030022 0x00000000 0x1000   200  20 20  46  13 "E"    19  8      5   0   0   0  32
call :addMonsterToCreatureList "Giant Hunter Ant"          0x00000002 0x00000000 0x0002   150   1 16  40  11 "a"    12  8     46   0   0   0  32
call :addMonsterToCreatureList "Ninja"                     0x13020002 0x00000000 0x6034   300  10 20  65  11 "p"    15  8    152  80   0   0  32
call :addMonsterToCreatureList "Barrow Wight"              0x0F02000A 0x00001308 0x512C   375  10 20  40  11 "W"    13  8      7   7 193   0  33
call :addMonsterToCreatureList "Skeleton 2-Headed Troll"   0x00020002 0x00000000 0x500C   325  20 20  48  11 "s"    20  8      8   8  28  28  33
call :addMonsterToCreatureList "Water Elemental"           0x0008000A 0x00000000 0x1020   325  50 12  36  11 "E"    25  8      9   9   0   0  33
call :addMonsterToCreatureList "Fire Elemental"            0x0008000A 0x00800000 0x3010   350  70 16  40  10 "E"    25  8    103   0   0   0  33
call :addMonsterToCreatureList "Lich"                      0x1F020002 0x00019F75 0x510C   750  60 20  50  11 "L"    25  8    179 194 214   0  34
call :addMonsterToCreatureList "Master Vampire"            0x17020002 0x00001307 0x512C   700  10 20  55  11 "V"    23  8      5   5 195   0  34
call :addMonsterToCreatureList "Spirit Troll"              0x17150002 0x00000000 0x510C   425  10 20  40  11 "G"    15  8     53  53  29 185  34
call :addMonsterToCreatureList "Giant Red Scorpion"        0x0000000A 0x00000000 0x0002   275  40 12  50  12 "S"    18  8     29 165   0   0  34
call :addMonsterToCreatureList "Earth Elemental"           0x001E000A 0x00000000 0x1200   375  90 10  60  10 "E"    30  8     22  22   0   0  34
call :addMonsterToCreatureList "Young Black Dragon"        0x1F00000A 0x0020100B 0x6005   600  50 20  55  11 "d"    32  8     53  53  29   0  35
call :addMonsterToCreatureList "Young Red Dragon"          0x1F00000A 0x0080100A 0x6015   650  50 20  60  11 "d"    36  8     54  54  37   0  35
call :addMonsterToCreatureList "Necromancer"               0x13020002 0x00005763 0x6030   600  10 20  40  11 "p"    17  8     15   0   0   0  35
call :addMonsterToCreatureList "Mummified Troll"           0x0F020002 0x00000000 0x502C   400  50 20  38  11 "M"    18  8     15  15   0   0  35
call :addMonsterToCreatureList "Giant Red Ant Lion"        0x0008000A 0x00800000 0x2012   350  40 14  48  11 "A"    23  8    107   0   0   0  35
call :addMonsterToCreatureList "Mature White Dragon"       0x2F00000A 0x0040100A 0x4025  1000  70 20  65  11 "d"    48  8     54  54  37   0  35
call :addMonsterToCreatureList "Xorn"                      0x00160002 0x00000000 0x4200   650  10 20  80  11 "X"    20  8      5   5   5   0  36
call :addMonsterToCreatureList "Giant Mottled Ant Lion"    0x0008000A 0x00000000 0x0032   350  40 14  50  12 "A"    24  8     38   0   0   0  36
call :addMonsterToCreatureList "Grey Wraith"               0x0F02000A 0x00001308 0x512C   700  10 20  50  11 "W"    23  8      9   9 196   0  36
call :addMonsterToCreatureList "Young Multi-Hued Dragon"   0x4F00000A 0x00F81005 0x6005  1250  50 20  55  11 "d"    40  8     55  55  38   0  36
call :addMonsterToCreatureList "Mature Blue Dragon"        0x2F00000A 0x00081009 0x6005  1200  70 20  75  11 "d"    48  8     54  54  38   0  36
call :addMonsterToCreatureList "Mature Green Dragon"       0x2F00000A 0x0010100A 0x6005  1100  70 20  70  11 "d"    48  8     52  52  29   0  36
call :addMonsterToCreatureList "Iridescent Beetle"         0x0000000A 0x00000000 0x0002   850  30 16  60  11 "K"    32  8     45  10 146   0  37
call :addMonsterToCreatureList "King Vampire"              0x17020002 0x00001307 0x512C  1000  10 20  65  11 "V"    38  8      5   5 198   0  37
call :addMonsterToCreatureList "King Lich"                 0x1F020002 0x00019F73 0x510C  1400  50 20  65  11 "L"    52  8    180 197 214   0  37
call :addMonsterToCreatureList "Mature Red Dragon"         0x2F00000A 0x00801808 0x6015  1400  30 20  80  11 "d"    60  8     56  56  39   0  37
call :addMonsterToCreatureList "Mature Black Dragon"       0x2F00000A 0x00201009 0x6005  1350  30 20  55  11 "d"    58  8     54  54  38   0  37
call :addMonsterToCreatureList "Mature Multi-Hued Dragon"  0x6F00000A 0x00F81A05 0x6005  1650  50 20  65  11 "d"    80  8     56  56  39   0  38
call :addMonsterToCreatureList "Ancient White Dragon"      0x4F000002 0x00401A09 0x4025  1500  80 20  80  12 "D"    88  8     54  54  37   0  38
call :addMonsterToCreatureList "Emperor Wight"             0x1B02000A 0x00001306 0x512C  1600  10 20  40  12 "W"    48  8     10  10 199   0  38
call :addMonsterToCreatureList "Black Wraith"              0x1F02000A 0x00001307 0x512C  1700  10 20  55  11 "W"    50  8     10  10 200   0  38
call :addMonsterToCreatureList "Nether Wraith"             0x1F07000A 0x00005316 0x512C  2100  10 20  55  11 "W"    58  8     10  10 202   0  39
call :addMonsterToCreatureList "Sorcerer"                  0x1F020002 0x0000FF73 0x6030  2150  10 20  50  12 "p"    30  8     16   0   0   0  39
call :addMonsterToCreatureList "Ancient Blue Dragon"       0x4F000002 0x00081A08 0x6005  2500  80 20  90  12 "D"    87  8     55  55  39   0  39
call :addMonsterToCreatureList "Ancient Green Dragon"      0x4F000002 0x00101A09 0x6005  2400  80 20  85  12 "D"    90  8     54  54  38   0  39
call :addMonsterToCreatureList "Ancient Black Dragon"      0x4F000002 0x00201A07 0x6005  2500  70 20  90  12 "D"    90  8     55  55  38   0  39
call :addMonsterToCreatureList "Crystal Ooze"              0x07BB000A 0x00400000 0x10A0     8   1 10  30   9 "O"    12  8    128   0   0   0  40
call :addMonsterToCreatureList "Disenchanter Worm"         0x00200022 0x00000000 0x01B2    30  10  7   5  10 "w"    10  8    208   0   0   0  40
call :addMonsterToCreatureList "Rotting Quylthulg"         0x00010004 0x00004014 0x5000  1000   0 20   1  12 "Q"    12  8      0   0   0   0  40
call :addMonsterToCreatureList "Ancient Red Dragon"        0x6F000002 0x00801E06 0x6015  2750  70 20 100  12 "D"   105  8     56  56  40   0  40
call :addMonsterToCreatureList "Death Quasit"              0x1103000A 0x000010FA 0x1004  1000   0 20  80  13 "q"    55  8    177  58  58   0  40
call :addMonsterToCreatureList "Emperor Lich"              0x2F020002 0x00019F72 0x510C 10000  50 20  75  12 "L"    38 40    181 201 214   0  40
call :addMonsterToCreatureList "Ancient Multi-Hued Dragon" 0x7F000002 0x00F89E05 0x6005 12000  70 20 100  12 "D"    52 40     57  57  42   0  40

:: A huge pain, but technically not a winning creature
call :addMonsterToCreatureList "Evil Iggy"                 0x7F130002 0x0001D713 0x5004 18000   0 30  80  12 "p"    60 40     81 150   0   0  50

:: The actual winning creature
call :addMonsterToCreatureList "Balrog"                    0xFF1F0002 0x0081C743 0x5004 55000   0 40 125  13 "B"    75 40    104  78 214   0 100
exit /b

::------------------------------------------------------------------------------
:: Adds a monster type to the creature_list array
::
:: Arguments: %1  - Name of the creature
::            %2  - CMOVE flags    (hexadecimal)
::            %3  - SPELL flags    (hexadecimal)
::            %4  - CDEFENSE flags (hexadecimal)
::            %5  - XP value
::            %6  - How many turns it takes for the player to be noticed
::            %7  - Max range that the creature is able to notice the player
::            %8  - Armor Class
::            %9  - speed
::            %10 - character displayed on map
::            %11 - number of hit dice
::            %12 - hit die max
::            %13 - attack type 1
::            %14 - attack type 2
::            %15 - attack type 3
::            %16 - attack type 4
::            %17 - monster level
::
::  CMOVE flags:
::      Movement.  00000001  Move only to attack
::              .  00000002  Move, attack normal
::              .  00000008  20% random movement
::              .  00000010  40% random movement
::              .  00000020  75% random movement
::      Special +  00010000  Invisible movement
::              +  00020000  Move through door
::              +  00040000  Move through wall
::              +  00080000  Move through creatures
::              +  00100000  Picks up objects
::              +  00200000  Multiply monster
::      Carries =  01000000  Carries objects.
::              =  02000000  Carries gold.
::              =  04000000  Has 60% of time.
::              =  08000000  Has 90% of time.
::              =  10000000  1d2 objects/gold.
::              =  20000000  2d2 objects/gold.
::              =  40000000  4d2 objects/gold.
::      Special ~  80000000  Win-the-Game creature.
::
::  SPELL Flags:
::      Frequency  000001    1  These add up to x.  Then
::      (1 in x).  000002    2  if RANDINT(X) = 1 the
::              .  000004    4  creature casts a spell.
::              .  000008    8
::      Spells  =  000010  Teleport short (blink)
::              =  000020  Teleport long
::              =  000040  Teleport player to monster
::              =  000080  Cause light wound
::              =  000100  Cause serious wound
::              =  000200  Hold person (Paralysis)
::              =  000400  Cause blindness
::              =  000800  Cause confusion
::              =  001000  Cause fear
::              =  002000  Summon monster
::              =  004000  Summon undead
::              =  008000  Slow Person
::              =  010000  Drain Mana
::              =  020000  Not Used
::              =  040000  Not Used
::      Breath/ +  080000  Breathe/Resist Lightning
::      Resist  +  100000  Breathe/Resist Gas
::              +  200000  Breathe/Resist Acid
::              +  400000  Breathe/Resist Frost
::              +  800000  Breathe/Resist Fire
::
::  CDEFENSE flags:
::      0001  Hurt by Slay Dragon.
::      0002  Hurt by Slay Animal.
::      0004  Hurt by Slay Evil.
::      0008  Hurt by Slay Undead.
::      0010  Hurt by Frost.
::      0020  Hurt by Fire.
::      0040  Hurt by Poison.
::      0080  Hurt by Acid.
::      0100  Hurt by Light-Wand.
::      0200  Hurt by Stone-to-Mud.
::      0400  Not used.
::      0800  Not used.
::      1000  Cannot be charmed or slept.
::      2000  Can be seen with infra-vision.
::      4000  Max Hit points.
::      8000  Not used.
:: Returns:   None
::------------------------------------------------------------------------------
:addMonsterToCreatureList
set "creatures_list[%monster_count%].name=%~1"
set /a creatures_list[%monster_count%].movement=%~2
set /a creatures_list[%monster_count%].spells=%~3
set /a creatures_list[%monster_count%].defenses=%~4
set "creatures_list[%monster_count%].kill_exp_value=%~5"
set "creatures_list[%monster_count%].sleep_counter=%~6"
set "creatures_list[%monster_count%].area_affect_radius=%~7"
set "creatures_list[%monster_count%].ac=%~8"
set "creatures_list[%monster_count%].speed=%~9"

for /L %%A in (1,1,9) do shift

set "creatures_list[%monster_count%].sprite=%~1"
set "creatures_list[%monster_count%].hit_die.dice=%~2"
set "creatures_list[%monster_count%].hit_die.sides=%~3"
set "creatures_list[%monster_count%].attack[1]=%~4"
set "creatures_list[%monster_count%].attack[2]=%~5"
set "creatures_list[%monster_count%].attack[3]=%~6"
set "creatures_list[%monster_count%].attack[4]=%~7"
set "creatures_list[%monster_count%].level=%~8"

set /a monster_count+=1
exit /b

::------------------------------------------------------------------------------
:: Adds all 215 attack types to the monster_attacks array.
::
::  Attack types:
::       1  Normal attack
::       2  Poison Strength
::       3  Confusion attack
::       4  Fear attack
::       5  Fire attack
::       6  Acid attack
::       7  Cold attack
::       8  Lightning attack
::       9  Corrosion attack
::      10  Blindness attack
::      11  Paralysis attack
::      12  Steal Money
::      13  Steal Object
::      14  Poison
::      15  Lose dexterity
::      16  Lose constitution
::      17  Lose intelligence
::      18  Lose wisdom
::      19  Lose experience
::      20  Aggravation
::      21  Disenchants
::      22  Eats food
::      23  Eats light
::      24  Eats charges
::      99  Blank
::
::  Attack descriptions:
::       1  hits you.
::       2  bites you.
::       3  claws you.
::       4  stings you.
::       5  touches you.
::       6  kicks you.
::       7  gazes at you.
::       8  breathes on you.
::       9  spits on you.
::      10  makes a horrible wail.
::      11  embraces you.
::      12  crawls on you.
::      13  releases a cloud of spores.
::      14  begs you for money.
::      15  You've been slimed.
::      16  crushes you.
::      17  tramples you.
::      18  drools on you.
::      19  insults you.
::      99  is repelled.
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:loadAttackData
set "attack_count=0"
:: Attack_Type  Attack_Description  Hit_Die_Count  Hit_Die_Sides
:: 0
call :addAttackToMonsterAttacks  0  0  0  0
call :addAttackToMonsterAttacks  1  1  1  2
call :addAttackToMonsterAttacks  1  1  1  3
call :addAttackToMonsterAttacks  1  1  1  4
call :addAttackToMonsterAttacks  1  1  1  5
call :addAttackToMonsterAttacks  1  1  1  6
call :addAttackToMonsterAttacks  1  1  1  7
call :addAttackToMonsterAttacks  1  1  1  8
call :addAttackToMonsterAttacks  1  1  1  9
call :addAttackToMonsterAttacks  1  1  1 10
call :addAttackToMonsterAttacks  1  1  1 12
call :addAttackToMonsterAttacks  1  1  2  2
call :addAttackToMonsterAttacks  1  1  2  3
call :addAttackToMonsterAttacks  1  1  2  4
call :addAttackToMonsterAttacks  1  1  2  5
call :addAttackToMonsterAttacks  1  1  2  6
call :addAttackToMonsterAttacks  1  1  2  8
call :addAttackToMonsterAttacks  1  1  3  4
call :addAttackToMonsterAttacks  1  1  3  5
call :addAttackToMonsterAttacks  1  1  3  6
:: 20
call :addAttackToMonsterAttacks  1  1  3  8
call :addAttackToMonsterAttacks  1  1  4  3
call :addAttackToMonsterAttacks  1  1  4  6
call :addAttackToMonsterAttacks  1  1  5  5
call :addAttackToMonsterAttacks  1  2  1  1
call :addAttackToMonsterAttacks  1  2  1  2
call :addAttackToMonsterAttacks  1  2  1  3
call :addAttackToMonsterAttacks  1  2  1  4
call :addAttackToMonsterAttacks  1  2  1  5
call :addAttackToMonsterAttacks  1  2  1  6
call :addAttackToMonsterAttacks  1  2  1  7
call :addAttackToMonsterAttacks  1  2  1  8
call :addAttackToMonsterAttacks  1  2  1 10
call :addAttackToMonsterAttacks  1  2  2  3
call :addAttackToMonsterAttacks  1  2  2  4
call :addAttackToMonsterAttacks  1  2  2  5
call :addAttackToMonsterAttacks  1  2  2  6
call :addAttackToMonsterAttacks  1  2  2  8
call :addAttackToMonsterAttacks  1  2  2 10
call :addAttackToMonsterAttacks  1  2  2 12
:: 40
call :addAttackToMonsterAttacks  1  2  2 14
call :addAttackToMonsterAttacks  1  2  3  4
call :addAttackToMonsterAttacks  1  2  3 12
call :addAttackToMonsterAttacks  1  2  4  4
call :addAttackToMonsterAttacks  1  2  4  5
call :addAttackToMonsterAttacks  1  2  4  6
call :addAttackToMonsterAttacks  1  2  4  8
call :addAttackToMonsterAttacks  1  2  5  4
call :addAttackToMonsterAttacks  1  2  5  8
call :addAttackToMonsterAttacks  1  3  1  1
call :addAttackToMonsterAttacks  1  3  1  2
call :addAttackToMonsterAttacks  1  3  1  3
call :addAttackToMonsterAttacks  1  3  1  4
call :addAttackToMonsterAttacks  1  3  1  5
call :addAttackToMonsterAttacks  1  3  1  8
call :addAttackToMonsterAttacks  1  3  1  9
call :addAttackToMonsterAttacks  1  3  1 10
call :addAttackToMonsterAttacks  1  3  1 12
call :addAttackToMonsterAttacks  1  3  3  3
call :addAttackToMonsterAttacks  1  4  1  2
:: 60
call :addAttackToMonsterAttacks  1  4  1  3
call :addAttackToMonsterAttacks  1  4  1  4
call :addAttackToMonsterAttacks  1  4  2  4
call :addAttackToMonsterAttacks  1  5  1  2
call :addAttackToMonsterAttacks  1  5  1  3
call :addAttackToMonsterAttacks  1  5  1  4
call :addAttackToMonsterAttacks  1  5  1  5
call :addAttackToMonsterAttacks  1 10  5  6
call :addAttackToMonsterAttacks  1 12  1  1
call :addAttackToMonsterAttacks  1 12  1  2
call :addAttackToMonsterAttacks  1 13  1  1
call :addAttackToMonsterAttacks  1 13  1  3
call :addAttackToMonsterAttacks  1 14  0  0
call :addAttackToMonsterAttacks  1 16  1  4
call :addAttackToMonsterAttacks  1 16  1  6
call :addAttackToMonsterAttacks  1 16  1  8
call :addAttackToMonsterAttacks  1 16  1 10
call :addAttackToMonsterAttacks  1 16  2  8
call :addAttackToMonsterAttacks  1 17  8 12
call :addAttackToMonsterAttacks  1 18  0  0
:: 80
call :addAttackToMonsterAttacks  2  1  3  4
call :addAttackToMonsterAttacks  2  1  4  6
call :addAttackToMonsterAttacks  2  2  1  4
call :addAttackToMonsterAttacks  2  2  2  4
call :addAttackToMonsterAttacks  2  2  4  4
call :addAttackToMonsterAttacks  2  4  1  4
call :addAttackToMonsterAttacks  2  4  1  7
call :addAttackToMonsterAttacks  2  5  1  5
call :addAttackToMonsterAttacks  2  7  1  6
call :addAttackToMonsterAttacks  3  1  1  4
call :addAttackToMonsterAttacks  3  5  1  8
call :addAttackToMonsterAttacks  3 13  1  4
call :addAttackToMonsterAttacks  3  7  0  0
call :addAttackToMonsterAttacks  4  1  1  1
call :addAttackToMonsterAttacks  4  1  1  4
call :addAttackToMonsterAttacks  4  2  1  2
call :addAttackToMonsterAttacks  4  2  1  6
call :addAttackToMonsterAttacks  4  5  0  0
call :addAttackToMonsterAttacks  4  7  0  0
call :addAttackToMonsterAttacks  4 10  0  0
:: 100
call :addAttackToMonsterAttacks  4 13  1  6
call :addAttackToMonsterAttacks  5  1  2  6
call :addAttackToMonsterAttacks  5  1  3  7
call :addAttackToMonsterAttacks  5  1  4  6
call :addAttackToMonsterAttacks  5  1 10 12
call :addAttackToMonsterAttacks  5  2  1  3
call :addAttackToMonsterAttacks  5  2  3  6
call :addAttackToMonsterAttacks  5  2  3 12
call :addAttackToMonsterAttacks  5  5  4  4
call :addAttackToMonsterAttacks  5  9  3  7
call :addAttackToMonsterAttacks  5  9  4  5
call :addAttackToMonsterAttacks  5 12  1  6
call :addAttackToMonsterAttacks  6  2  1  3
call :addAttackToMonsterAttacks  6  2  2  8
call :addAttackToMonsterAttacks  6  2  4  4
call :addAttackToMonsterAttacks  6  5  1 10
call :addAttackToMonsterAttacks  6  5  2  3
call :addAttackToMonsterAttacks  6  8  1  5
call :addAttackToMonsterAttacks  6  9  2  6
call :addAttackToMonsterAttacks  6  9  3  6
:: 120
call :addAttackToMonsterAttacks  7  1  3  6
call :addAttackToMonsterAttacks  7  2  1  3
call :addAttackToMonsterAttacks  7  2  1  6
call :addAttackToMonsterAttacks  7  2  3  6
call :addAttackToMonsterAttacks  7  2  3 10
call :addAttackToMonsterAttacks  7  5  1  6
call :addAttackToMonsterAttacks  7  5  2  3
call :addAttackToMonsterAttacks  7  5  2  6
call :addAttackToMonsterAttacks  7  5  4  4
call :addAttackToMonsterAttacks  7 12  1  4
call :addAttackToMonsterAttacks  8  1  3  8
call :addAttackToMonsterAttacks  8  2  1  3
call :addAttackToMonsterAttacks  8  2  2  6
call :addAttackToMonsterAttacks  8  2  3  8
call :addAttackToMonsterAttacks  8  2  5  5
call :addAttackToMonsterAttacks  8  5  5  4
call :addAttackToMonsterAttacks  9  5  1  2
call :addAttackToMonsterAttacks  9  5  2  5
call :addAttackToMonsterAttacks  9  5  2  6
call :addAttackToMonsterAttacks  9  8  2  4
:: 140
call :addAttackToMonsterAttacks  9 12  1  3
call :addAttackToMonsterAttacks 10  2  1  6
call :addAttackToMonsterAttacks 10  4  1  1
call :addAttackToMonsterAttacks 10  7  2  6
call :addAttackToMonsterAttacks 10  9  1  2
call :addAttackToMonsterAttacks 11  1  1  2
call :addAttackToMonsterAttacks 11  7  0  0
call :addAttackToMonsterAttacks 11 13  2  4
call :addAttackToMonsterAttacks 12  5  0  0
call :addAttackToMonsterAttacks 13  5  0  0
call :addAttackToMonsterAttacks 13 19  0  0
call :addAttackToMonsterAttacks 14  1  1  3
call :addAttackToMonsterAttacks 14  1  3  4
call :addAttackToMonsterAttacks 14  2  1  3
call :addAttackToMonsterAttacks 14  2  1  4
call :addAttackToMonsterAttacks 14  2  1  5
call :addAttackToMonsterAttacks 14  2  1  6
call :addAttackToMonsterAttacks 14  2  1 10
call :addAttackToMonsterAttacks 14  2  2  4
call :addAttackToMonsterAttacks 14  2  2  5
:: 160
call :addAttackToMonsterAttacks 14  2  2  6
call :addAttackToMonsterAttacks 14  2  3  4
call :addAttackToMonsterAttacks 14  2  3  9
call :addAttackToMonsterAttacks 14  2  4  4
call :addAttackToMonsterAttacks 14  4  1  2
call :addAttackToMonsterAttacks 14  4  1  4
call :addAttackToMonsterAttacks 14  4  1  8
call :addAttackToMonsterAttacks 14  4  2  5
call :addAttackToMonsterAttacks 14  5  1  2
call :addAttackToMonsterAttacks 14  5  1  3
call :addAttackToMonsterAttacks 14  5  2  4
call :addAttackToMonsterAttacks 14  5  2  6
call :addAttackToMonsterAttacks 14  5  3  5
call :addAttackToMonsterAttacks 14 12  1  2
call :addAttackToMonsterAttacks 14 12  1  4
call :addAttackToMonsterAttacks 14 13  2  4
call :addAttackToMonsterAttacks 15  2  1  6
call :addAttackToMonsterAttacks 15  2  3  6
call :addAttackToMonsterAttacks 15  5  1  8
call :addAttackToMonsterAttacks 15  5  2  8
:: 180
call :addAttackToMonsterAttacks 15  5  2 10
call :addAttackToMonsterAttacks 15  5  2 12
call :addAttackToMonsterAttacks 15 12  1  3
call :addAttackToMonsterAttacks 16 13  1  2
call :addAttackToMonsterAttacks 17  3  1 10
call :addAttackToMonsterAttacks 18  5  0  0
call :addAttackToMonsterAttacks 19  5  5  8
call :addAttackToMonsterAttacks 19  5 12  8
call :addAttackToMonsterAttacks 19  5 14  8
call :addAttackToMonsterAttacks 19  5 15  8
call :addAttackToMonsterAttacks 19  5 18  8
call :addAttackToMonsterAttacks 19  5 20  8
call :addAttackToMonsterAttacks 19  5 22  8
call :addAttackToMonsterAttacks 19  5 26  8
call :addAttackToMonsterAttacks 19  5 30  8
call :addAttackToMonsterAttacks 19  5 32  8
call :addAttackToMonsterAttacks 19  5 34  8
call :addAttackToMonsterAttacks 19  5 36  8
call :addAttackToMonsterAttacks 19  5 38  8
call :addAttackToMonsterAttacks 19  5 42  8
:: 200
call :addAttackToMonsterAttacks 19  5 44  8
call :addAttackToMonsterAttacks 19  5 46  8
call :addAttackToMonsterAttacks 19  5 52  8
call :addAttackToMonsterAttacks 20 10  0  0
call :addAttackToMonsterAttacks 21  1  0  0
call :addAttackToMonsterAttacks 21  5  0  0
call :addAttackToMonsterAttacks 21  5  1  6
call :addAttackToMonsterAttacks 21  7  0  0
call :addAttackToMonsterAttacks 21 12  1  4
call :addAttackToMonsterAttacks 22  5  2  3
call :addAttackToMonsterAttacks 22 12  0  0
call :addAttackToMonsterAttacks 22 15  1  1
call :addAttackToMonsterAttacks 23  1  1  1
call :addAttackToMonsterAttacks 23  5  1  3
call :addAttackToMonsterAttacks 24  5  0  0
exit /b

::------------------------------------------------------------------------------
:: Creates an element of the monster_attacks array
::
:: Arguments: %1 - attack type
::            %2 - attack description
::            %3 - attack hit die dice
::            %4 - attack hit die sides
:: Returns:   None
::------------------------------------------------------------------------------
:addAttackToMonsterAttacks
set "monster_attacks[%attack_count%].type=%~1"
set "monster_attacks[%attack_count%].description=%~2"
set "monster_attacks[%attack_count%].hit_die.dice=%~3"
set "monster_attacks[%attack_count%].hit_die.sides=%~4"
set /a attack_count+=1
exit /b