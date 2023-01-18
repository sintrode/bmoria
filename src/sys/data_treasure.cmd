:: Treasure data
@echo off

:: Object description:  Objects are defined here.  Each object has
:: the following attributes:
::
::  Descriptor : Name of item and formats.
::                 _ is replaced by "a" "an" or a number.
::                 ~ is replaced by null or "s".
::  Character  : Character that represents the item.
::  Type value : Value representing the type of object.
::  Sub value  : separate value for each item of a type.
::                   0 - 63:  object can not stack
::                  64 - 127: dungeon object can stack with other D object
::                 128 - 191: unused previously for store items
::                 192:       stack with other iff have same `misc_use` value always
::                            treated as individual objects
::                 193 - 255: object can stack with others iff they have
::                            the same `misc_use` value usually considered one group
::                 Objects which have two type values e.g. potions and
::                 scrolls need to have distinct `sub_category_id`s for
::                 each item regardless of its category_id
::  Damage     : amount of damage item can cause.
::  Weight     : relative weight of an item.
::  Number     : number of items appearing in group.
::  To hit     : magical plusses to hit.
::  To damage  : magical plusses to damage.
::  AC         : objects relative armor class.
::                 1 is worse than 5 is worse than 10 etc.
::  To AC      : Magical bonuses to AC.
::  misc_use   : Catch all for magical abilities such as
::               plusses to strength minuses to searching.
::  Flags      : Abilities of object.  Each ability is a
::               bit.  Bits 1-31 are used. (Signed integer)
::  Level      : Minimum level on which item can be found.
::  Cost       : Relative cost of item.
::
::  Special Abilities can be added to item by :magicInitializeItemNames
::
::  Scrolls Potions and Food:
::  Flags is used to define a function which reading/quaffing
::  will cause.  Most scrolls and potions have only one bit
::  set.  Potions will generally have some food value found
::  in `misc_use`.
::
::  Wands and Staffs:
::  Flags defines a function `misc_use` contains number of charges
::  for item.
::
::  Chests:
::  Traps are added randomly

::----- Dungeon Items
set /a "object_count=0"
call :addItemToGameObjects "Poison"                          0x00000001 TV_FOOD         ","  500    0  64 1    1  0  0  0  0  0  0   7
call :addItemToGameObjects "Blindness"                       0x00000002 TV_FOOD         ","  500    0  65 1    1  0  0  0  0  0  0   9
call :addItemToGameObjects "Paranoia"                        0x00000004 TV_FOOD         ","  500    0  66 1    1  0  0  0  0  0  0   9
call :addItemToGameObjects "Confusion"                       0x00000008 TV_FOOD         ","  500    0  67 1    1  0  0  0  0  0  0   7
call :addItemToGameObjects "Hallucination"                   0x00000010 TV_FOOD         ","  500    0  68 1    1  0  0  0  0  0  0  13
call :addItemToGameObjects "Cure Poison"                     0x00000020 TV_FOOD         ","  500   60  69 1    1  0  0  0  0  0  0   8
call :addItemToGameObjects "Cure Blindness"                  0x00000040 TV_FOOD         ","  500   50  70 1    1  0  0  0  0  0  0  10
call :addItemToGameObjects "Cure Paranoia"                   0x00000080 TV_FOOD         ","  500   25  71 1    1  0  0  0  0  0  0  12
call :addItemToGameObjects "Cure Confusion"                  0x00000100 TV_FOOD         ","  500   50  72 1    1  0  0  0  0  0  0   6
call :addItemToGameObjects "Weakness"                        0x04000200 TV_FOOD         ","  500    0  73 1    1  0  0  0  0  0  0   7
call :addItemToGameObjects "Unhealth"                        0x04000400 TV_FOOD         ","  500   50  74 1    1  0  0  0  0 10 10  15
call :addItemToGameObjects "Restore Constitution"            0x00010000 TV_FOOD         ","  500  350  75 1    1  0  0  0  0  0  0  20
call :addItemToGameObjects "First-Aid"                       0x00200000 TV_FOOD         ","  500    5  76 1    1  0  0  0  0  0  0   6
call :addItemToGameObjects "Minor Cures"                     0x00400000 TV_FOOD         ","  500   20  77 1    1  0  0  0  0  0  0   7
call :addItemToGameObjects "Light Cures"                     0x00800000 TV_FOOD         ","  500   30  78 1    1  0  0  0  0  0  0  10
call :addItemToGameObjects "Restoration"                     0x001F8000 TV_FOOD         ","  500 1000  79 1    1  0  0  0  0  0  0  30
call :addItemToGameObjects "Poison"                          0x00000001 TV_FOOD         "," 1200    0  80 1    1  0  0  0  0  0  0  15
call :addItemToGameObjects "Hallucination"                   0x00000010 TV_FOOD         "," 1200    0  81 1    1  0  0  0  0  0  0  18
call :addItemToGameObjects "Cure Poison"                     0x00000020 TV_FOOD         "," 1200   75  82 1    1  0  0  0  0  0  0  19
call :addItemToGameObjects "Unhealth"                        0x04000400 TV_FOOD         "," 1200   75  83 1    1  0  0  0  0 10 12  28
call :addItemToGameObjects "Major Cures"                     0x02000000 TV_FOOD         "," 1200   75  84 1    2  0  0  0  0  0  0  16
call :addItemToGameObjects "_ Ration~ of Food"               0x00000000 TV_FOOD         "," 5000    3  90 1   10  0  0  0  0  0  0   0
call :addItemToGameObjects "_ Ration~ of Food"               0x00000000 TV_FOOD         "," 5000    3  90 1   10  0  0  0  0  0  0   5
call :addItemToGameObjects "_ Ration~ of Food"               0x00000000 TV_FOOD         "," 5000    3  90 1   10  0  0  0  0  0  0  10
call :addItemToGameObjects "_ Slime Mold~"                   0x00000000 TV_FOOD         "," 3000    2  91 1    5  0  0  0  0  0  0   1
call :addItemToGameObjects "_ Piece~ of Elvish Waybread"     0x02000020 TV_FOOD         "," 7500   25  92 1    3  0  0  0  0  0  0   6
call :addItemToGameObjects "_ Piece~ of Elvish Waybread"     0x02000020 TV_FOOD         "," 7500   25  92 1    3  0  0  0  0  0  0  12
call :addItemToGameObjects "_ Piece~ of Elvish Waybread"     0x02000020 TV_FOOD         "," 7500   25  92 1    3  0  0  0  0  0  0  20

call :addItemToGameObjects "_ Dagger (Main Gauche)"          0x00000000 TV_SWORD       "^|"    0   25   1 1   30  0  0  0  0  1  5   2
call :addItemToGameObjects "_ Dagger (Misericorde)"          0x00000000 TV_SWORD       "^|"    0   10   2 1   15  0  0  0  0  1  4   0
call :addItemToGameObjects "_ Dagger (Stiletto)"             0x00000000 TV_SWORD       "^|"    0   10   3 1   12  0  0  0  0  1  4   0
call :addItemToGameObjects "_ Dagger (Bodkin)"               0x00000000 TV_SWORD       "^|"    0   10   4 1   20  0  0  0  0  1  4   1
call :addItemToGameObjects "_ Broken Dagger"                 0x00000000 TV_SWORD       "^|"    0    0   5 1   15 -2 -2  0  0  1  1   0
call :addItemToGameObjects "_ Backsword"                     0x00000000 TV_SWORD       "^|"    0  150   6 1   95  0  0  0  0  1  9   7
call :addItemToGameObjects "_ Bastard Sword"                 0x00000000 TV_SWORD       "^|"    0  350   7 1  140  0  0  0  0  3  4  14
call :addItemToGameObjects "_ Thrusting Sword (Bilbo)"       0x00000000 TV_SWORD       "^|"    0   60   8 1   80  0  0  0  0  1  6   4
call :addItemToGameObjects "_ Thrusting Sword (Baselard)"    0x00000000 TV_SWORD       "^|"    0   80   9 1  100  0  0  0  0  1  7   5
call :addItemToGameObjects "_ Broadsword"                    0x00000000 TV_SWORD       "^|"    0  255  10 1  150  0  0  0  0  2  5   9
call :addItemToGameObjects "_ Two-Handed Sword (Claymore)"   0x00000000 TV_SWORD       "^|"    0  775  11 1  200  0  0  0  0  3  6  30
call :addItemToGameObjects "_ Cutlass"                       0x00000000 TV_SWORD       "^|"    0   85  12 1  110  0  0  0  0  1  7   7
call :addItemToGameObjects "_ Two-Handed Sword (Espadon)"    0x00000000 TV_SWORD       "^|"    0  655  13 1  180  0  0  0  0  3  6  35
call :addItemToGameObjects "_ Executioner's Sword"           0x00000000 TV_SWORD       "^|"    0  850  14 1  260  0  0  0  0  4  5  40
call :addItemToGameObjects "_ Two-Handed Sword (Flamberge)"  0x00000000 TV_SWORD       "^|"    0 1000  15 1  240  0  0  0  0  4  5  45
call :addItemToGameObjects "_ Foil"                          0x00000000 TV_SWORD       "^|"    0   35  16 1   30  0  0  0  0  1  5   2
call :addItemToGameObjects "_ Katana"                        0x00000000 TV_SWORD       "^|"    0  400  17 1  120  0  0  0  0  3  4  18
call :addItemToGameObjects "_ Longsword"                     0x00000000 TV_SWORD       "^|"    0  200  18 1  130  0  0  0  0  1 10  12
call :addItemToGameObjects "_ Two-Handed Sword (No-Dachi)"   0x00000000 TV_SWORD       "^|"    0  675  19 1  200  0  0  0  0  4  4  45
call :addItemToGameObjects "_ Rapier"                        0x00000000 TV_SWORD       "^|"    0   42  20 1   40  0  0  0  0  1  6   4
call :addItemToGameObjects "_ Sabre"                         0x00000000 TV_SWORD       "^|"    0   50  21 1   50  0  0  0  0  1  7   5
call :addItemToGameObjects "_ Small Sword"                   0x00000000 TV_SWORD       "^|"    0   48  22 1   75  0  0  0  0  1  6   5
call :addItemToGameObjects "_ Two-Handed Sword (Zweihander)" 0x00000000 TV_SWORD       "^|"    0 1500  23 1  280  0  0  0  0  4  6  50
call :addItemToGameObjects "_ Broken Sword"                  0x00000000 TV_SWORD       "^|"    0    0  24 1   75 -2 -2  0  0  1  1   0
call :addItemToGameObjects "_ Ball and Chain"                0x00000000 TV_HAFTED       "\"    0  200   1 1  150  0  0  0  0  2  4  20
call :addItemToGameObjects "_ Cat-o'-Nine-Tails"             0x00000000 TV_HAFTED       "\"    0   14   2 1   40  0  0  0  0  1  4   3
call :addItemToGameObjects "_ Wooden Club"                   0x00000000 TV_HAFTED       "\"    0   10   3 1  100  0  0  0  0  1  3   0
call :addItemToGameObjects "_ Flail"                         0x00000000 TV_HAFTED       "\"    0  353   4 1  150  0  0  0  0  2  6  12
call :addItemToGameObjects "_ Two-Handed Great Flail"        0x00000000 TV_HAFTED       "\"    0  590   5 1  280  0  0  0  0  3  6  45
call :addItemToGameObjects "_ Morningstar"                   0x00000000 TV_HAFTED       "\"    0  396   6 1  150  0  0  0  0  2  6  10
call :addItemToGameObjects "_ Mace"                          0x00000000 TV_HAFTED       "\"    0  130   7 1  120  0  0  0  0  2  4   6
call :addItemToGameObjects "_ War Hammer"                    0x00000000 TV_HAFTED       "\"    0  225   8 1  120  0  0  0  0  3  3   5
call :addItemToGameObjects "_ Lead-Filled Mace"              0x00000000 TV_HAFTED       "\"    0  502   9 1  180  0  0  0  0  3  4  15
call :addItemToGameObjects "_ Awl-Pike"                      0x00000000 TV_POLEARM      "/"    0  200   1 1  160  0  0  0  0  1  8   8
call :addItemToGameObjects "_ Beaked Axe"                    0x00000000 TV_POLEARM      "/"    0  408   2 1  180  0  0  0  0  2  6  15
call :addItemToGameObjects "_ Fauchard"                      0x00000000 TV_POLEARM      "/"    0  326   3 1  170  0  0  0  0  1 10  17
call :addItemToGameObjects "_ Glaive"                        0x00000000 TV_POLEARM      "/"    0  363   4 1  190  0  0  0  0  2  6  20
call :addItemToGameObjects "_ Halberd"                       0x00000000 TV_POLEARM      "/"    0  430   5 1  190  0  0  0  0  3  4  22
call :addItemToGameObjects "_ Lucerne Hammer"                0x00000000 TV_POLEARM      "/"    0  376   6 1  120  0  0  0  0  2  5  11
call :addItemToGameObjects "_ Pike"                          0x00000000 TV_POLEARM      "/"    0  358   7 1  160  0  0  0  0  2  5  15
call :addItemToGameObjects "_ Spear"                         0x00000000 TV_POLEARM      "/"    0   36   8 1   50  0  0  0  0  1  6   5
call :addItemToGameObjects "_ Lance"                         0x00000000 TV_POLEARM      "/"    0  230   9 1  300  0  0  0  0  2  8  10
call :addItemToGameObjects "_ Javelin"                       0x00000000 TV_POLEARM      "/"    0   18  10 1   30  0  0  0  0  1  4   4
call :addItemToGameObjects "_ Battle Axe (Balestarius)"      0x00000000 TV_POLEARM      "/"    0  500  11 1  180  0  0  0  0  2  8  30
call :addItemToGameObjects "_ Battle Axe (European)"         0x00000000 TV_POLEARM      "/"    0  334  12 1  170  0  0  0  0  3  4  13
call :addItemToGameObjects "_ Broad Axe"                     0x00000000 TV_POLEARM      "/"    0  304  13 1  160  0  0  0  0  2  6  17
call :addItemToGameObjects "_ Short Bow"                     0x00000000 TV_BOW          "}"    2   50   1 1   30  0  0  0  0  0  0   3
call :addItemToGameObjects "_ Long Bow"                      0x00000000 TV_BOW          "}"    3  120   2 1   40  0  0  0  0  0  0  10
call :addItemToGameObjects "_ Composite Bow"                 0x00000000 TV_BOW          "}"    4  240   3 1   40  0  0  0  0  0  0  40
call :addItemToGameObjects "_ Light Crossbow"                0x00000000 TV_BOW          "}"    5  140  10 1  110  0  0  0  0  0  0  15
call :addItemToGameObjects "_ Heavy Crossbow"                0x00000000 TV_BOW          "}"    6  300  11 1  200  0  0  0  0  1  1  30
call :addItemToGameObjects "_ Sling"                         0x00000000 TV_BOW          "}"    1    5  20 1    5  0  0  0  0  0  0   1
call :addItemToGameObjects "_ Arrow~"                        0x00000000 TV_ARROW        "{"    0    1 193 1    2  0  0  0  0  1  4   2
call :addItemToGameObjects "_ Bolt~"                         0x00000000 TV_BOLT         "{"    0    2 193 1    3  0  0  0  0  1  5   2
call :addItemToGameObjects "_ Rounded Pebble~"               0x00000000 TV_SLING_AMMO   "{"    0    1 193 1    4  0  0  0  0  1  2   0
call :addItemToGameObjects "_ Iron Shot~"                    0x00000000 TV_SLING_AMMO   "{"    0    2 194 1    5  0  0  0  0  1  3   3
call :addItemToGameObjects "_ Iron Spike~"                   0x00000000 TV_SPIKE        "~"    0    1 193 1   10  0  0  0  0  1  1   1
call :addItemToGameObjects "_ Brass Lantern~"                0x00000000 TV_LIGHT        "~" 7500   35   1 1   50  0  0  0  0  1  1   1
call :addItemToGameObjects "_ Wooden Torch~"                 0x00000000 TV_LIGHT        "~" 4000    2 193 1   30  0  0  0  0  1  1   1
call :addItemToGameObjects "_ Orcish Pick"                   0x20000000 TV_DIGGING      "\"    2  500   2 1  180  0  0  0  0  1  3  20
call :addItemToGameObjects "_ Dwarven Pick"                  0x20000000 TV_DIGGING      "\"    3 1200   3 1  200  0  0  0  0  1  4  50
call :addItemToGameObjects "_ Gnomish Shovel"                0x20000000 TV_DIGGING      "\"    1  100   5 1   50  0  0  0  0  1  2  20
call :addItemToGameObjects "_ Dwarven Shovel"                0x20000000 TV_DIGGING      "\"    2  250   6 1  120  0  0  0  0  1  3  40
call :addItemToGameObjects "_ Pair of Soft Leather Shoes"    0x00000000 TV_BOOTS        "]"    0    4   1 1    5  0  0  1  0  0  0   1
call :addItemToGameObjects "_ Pair of Soft Leather Boots"    0x00000000 TV_BOOTS        "]"    0    7   2 1   20  0  0  2  0  1  1   4
call :addItemToGameObjects "_ Pair of Hard Leather Boots"    0x00000000 TV_BOOTS        "]"    0   12   3 1   40  0  0  3  0  1  1   6
call :addItemToGameObjects "_ Soft Leather Cap"              0x00000000 TV_HELM         "]"    0    4   1 1   10  0  0  1  0  0  0   2
call :addItemToGameObjects "_ Hard Leather Cap"              0x00000000 TV_HELM         "]"    0   12   2 1   15  0  0  2  0  0  0   4
call :addItemToGameObjects "_ Metal Cap"                     0x00000000 TV_HELM         "]"    0   30   3 1   20  0  0  3  0  1  1   7
call :addItemToGameObjects "_ Iron Helm"                     0x00000000 TV_HELM         "]"    0   75   4 1   75  0  0  5  0  1  3  20
call :addItemToGameObjects "_ Steel Helm"                    0x00000000 TV_HELM         "]"    0  200   5 1   60  0  0  6  0  1  3  40
call :addItemToGameObjects "_ Silver Crown"                  0x00000000 TV_HELM         "]"    0  500   6 1   20  0  0  0  0  1  1  44
call :addItemToGameObjects "_ Golden Crown"                  0x00000000 TV_HELM         "]"    0 1000   7 1   30  0  0  0  0  1  2  47
call :addItemToGameObjects "_ Jewel-Encrusted Crown"         0x00000000 TV_HELM         "]"    0 2000   8 1   40  0  0  0  0  1  3  50
call :addItemToGameObjects "_ Robe"                          0x00000000 TV_SOFT_ARMOR   "("    0    4   1 1   20  0  0  2  0  0  0   1
call :addItemToGameObjects "Soft Leather Armor"              0x00000000 TV_SOFT_ARMOR   "("    0   18   2 1   80  0  0  4  0  0  0   2
call :addItemToGameObjects "Soft Studded Leather"            0x00000000 TV_SOFT_ARMOR   "("    0   35   3 1   90  0  0  5  0  1  1   3
call :addItemToGameObjects "Hard Leather Armor"              0x00000000 TV_SOFT_ARMOR   "("    0   55   4 1  100 -1  0  6  0  1  1   5
call :addItemToGameObjects "Hard Studded Leather"            0x00000000 TV_SOFT_ARMOR   "("    0  100   5 1  110 -1  0  7  0  1  2   7
call :addItemToGameObjects "Woven Cord Armor"                0x00000000 TV_SOFT_ARMOR   "("    0   45   6 1  150 -1  0  6  0  0  0   7
call :addItemToGameObjects "Soft Leather Ring Mail"          0x00000000 TV_SOFT_ARMOR   "("    0  160   7 1  130 -1  0  6  0  1  2  10
call :addItemToGameObjects "Hard Leather Ring Mail"          0x00000000 TV_SOFT_ARMOR   "("    0  230   8 1  150 -2  0  8  0  1  3  12
call :addItemToGameObjects "Leather Scale Mail"              0x00000000 TV_SOFT_ARMOR   "("    0  330   9 1  140 -1  0 11  0  1  1  14
call :addItemToGameObjects "Metal Scale Mail"                0x00000000 TV_HARD_ARMOR   "["    0  430   1 1  250 -2  0 13  0  1  4  24
call :addItemToGameObjects "Chain Mail"                      0x00000000 TV_HARD_ARMOR   "["    0  530   2 1  220 -2  0 14  0  1  4  26
call :addItemToGameObjects "Rusty Chain Mail"                0x00000000 TV_HARD_ARMOR   "["    0    0   3 1  220 -5  0 14 -8  1  4  26
call :addItemToGameObjects "Double Chain Mail"               0x00000000 TV_HARD_ARMOR   "["    0  630   4 1  260 -2  0 15  0  1  4  28
call :addItemToGameObjects "Augmented Chain Mail"            0x00000000 TV_HARD_ARMOR   "["    0  675   5 1  270 -2  0 16  0  1  4  30
call :addItemToGameObjects "Bar Chain Mail"                  0x00000000 TV_HARD_ARMOR   "["    0  720   6 1  280 -2  0 18  0  1  4  34
call :addItemToGameObjects "Metal Brigandine Armor"          0x00000000 TV_HARD_ARMOR   "["    0  775   7 1  290 -3  0 19  0  1  4  36
call :addItemToGameObjects "Laminated Armor"                 0x00000000 TV_HARD_ARMOR   "["    0  825   8 1  300 -3  0 20  0  1  4  38
call :addItemToGameObjects "Partial Plate Armor"             0x00000000 TV_HARD_ARMOR   "["    0  900   9 1  320 -3  0 22  0  1  6  42
call :addItemToGameObjects "Metal Lamellar Armor"            0x00000000 TV_HARD_ARMOR   "["    0  950  10 1  340 -3  0 23  0  1  6  44
call :addItemToGameObjects "Full Plate Armor"                0x00000000 TV_HARD_ARMOR   "["    0 1050  11 1  380 -3  0 25  0  2  4  48
call :addItemToGameObjects "Ribbed Plate Armor"              0x00000000 TV_HARD_ARMOR   "["    0 1200  12 1  380 -3  0 28  0  2  4  50
call :addItemToGameObjects "_ Cloak"                         0x00000000 TV_CLOAK        "("    0    3   1 1   10  0  0  1  0  0  0   1
call :addItemToGameObjects "_ Set of Leather Gloves"         0x00000000 TV_GLOVES       "]"    0    3   1 1    5  0  0  1  0  0  0   1
call :addItemToGameObjects "_ Set of Gauntlets"              0x00000000 TV_GLOVES       "]"    0   35   2 1   25  0  0  2  0  1  1  12
call :addItemToGameObjects "_ Small Leather Shield"          0x00000000 TV_SHIELD      "^)"    0   30   1 1   50  0  0  2  0  1  1   3
call :addItemToGameObjects "_ Medium Leather Shield"         0x00000000 TV_SHIELD      "^)"    0   60   2 1   75  0  0  3  0  1  2   8
call :addItemToGameObjects "_ Large Leather Shield"          0x00000000 TV_SHIELD      "^)"    0  120   3 1  100  0  0  4  0  1  2  15
call :addItemToGameObjects "_ Small Metal Shield"            0x00000000 TV_SHIELD      "^)"    0   50   4 1   65  0  0  3  0  1  2  10
call :addItemToGameObjects "_ Medium Metal Shield"           0x00000000 TV_SHIELD      "^)"    0  125   5 1   90  0  0  4  0  1  3  20
call :addItemToGameObjects "_ Large Metal Shield"            0x00000000 TV_SHIELD      "^)"    0  200   6 1  120  0  0  5  0  1  3  30
call :addItemToGameObjects "Strength"                        0x00000001 TV_RING         "-"    0  400   0 1    2  0  0  0  0  0  0  30
call :addItemToGameObjects "Dexterity"                       0x00000008 TV_RING         "-"    0  400   1 1    2  0  0  0  0  0  0  30
call :addItemToGameObjects "Constitution"                    0x00000010 TV_RING         "-"    0  400   2 1    2  0  0  0  0  0  0  30
call :addItemToGameObjects "Intelligence"                    0x00000002 TV_RING         "-"    0  400   3 1    2  0  0  0  0  0  0  30
call :addItemToGameObjects "Speed"                           0x00001000 TV_RING         "-"    0 3000   4 1    2  0  0  0  0  0  0  50
call :addItemToGameObjects "Searching"                       0x00000040 TV_RING         "-"    0  250   5 1    2  0  0  0  0  0  0   7
call :addItemToGameObjects "Teleportation"                   0x80000400 TV_RING         "-"    0    0   6 1    2  0  0  0  0  0  0   7
call :addItemToGameObjects "Slow Digestion"                  0x00000080 TV_RING         "-"    0  200   7 1    2  0  0  0  0  0  0   7
call :addItemToGameObjects "Resist Fire"                     0x00080000 TV_RING         "-"    0  250   8 1    2  0  0  0  0  0  0  14
call :addItemToGameObjects "Resist Cold"                     0x00200000 TV_RING         "-"    0  250   9 1    2  0  0  0  0  0  0  14
call :addItemToGameObjects "Feather Falling"                 0x04000000 TV_RING         "-"    0  200  10 1    2  0  0  0  0  0  0   7
call :addItemToGameObjects "Adornment"                       0x00000000 TV_RING         "-"    0   20  11 1    2  0  0  0  0  0  0   7
call :addItemToGameObjects "_ Arrow~"                        0x00000000 TV_ARROW        "{"    0    1 193 1    2  0  0  0  0  1  4  15
call :addItemToGameObjects "Weakness"                        0x80000001 TV_RING         "-"   -5    0  13 1    2  0  0  0  0  0  0   7
call :addItemToGameObjects "Lordly Protection (FIRE)"        0x00080000 TV_RING         "-"    0 1200  14 1    2  0  0  0  5  0  0  50
call :addItemToGameObjects "Lordly Protection (ACID)"        0x00100000 TV_RING         "-"    0 1200  15 1    2  0  0  0  5  0  0  50
call :addItemToGameObjects "Lordly Protection (COLD)"        0x00200000 TV_RING         "-"    0 1200  16 1    2  0  0  0  5  0  0  50
call :addItemToGameObjects "WOE"                             0x80000644 TV_RING         "-"   -5    0  17 1    2  0  0  0 -3  0  0  50
call :addItemToGameObjects "Stupidity"                       0x80000002 TV_RING         "-"   -5    0  18 1    2  0  0  0  0  0  0   7
call :addItemToGameObjects "Increase Damage"                 0x00000000 TV_RING         "-"    0  100  19 1    2  0  0  0  0  0  0  20
call :addItemToGameObjects "Increase To-Hit"                 0x00000000 TV_RING         "-"    0  100  20 1    2  0  0  0  0  0  0  20
call :addItemToGameObjects "Protection"                      0x00000000 TV_RING         "-"    0  100  21 1    2  0  0  0  0  0  0   7
call :addItemToGameObjects "Aggravate Monster"               0x80000200 TV_RING         "-"    0    0  22 1    2  0  0  0  0  0  0   7
call :addItemToGameObjects "See Invisible"                   0x01000000 TV_RING         "-"    0  500  23 1    2  0  0  0  0  0  0  40
call :addItemToGameObjects "Sustain Strength"                0x00400000 TV_RING         "-"    1  750  24 1    2  0  0  0  0  0  0  44
call :addItemToGameObjects "Sustain Intelligence"            0x00400000 TV_RING         "-"    2  600  25 1    2  0  0  0  0  0  0  44
call :addItemToGameObjects "Sustain Wisdom"                  0x00400000 TV_RING         "-"    3  600  26 1    2  0  0  0  0  0  0  44
call :addItemToGameObjects "Sustain Constitution"            0x00400000 TV_RING         "-"    4  750  27 1    2  0  0  0  0  0  0  44
call :addItemToGameObjects "Sustain Dexterity"               0x00400000 TV_RING         "-"    5  750  28 1    2  0  0  0  0  0  0  44
call :addItemToGameObjects "Sustain Charisma"                0x00400000 TV_RING         "-"    6  500  29 1    2  0  0  0  0  0  0  44
call :addItemToGameObjects "Slaying"                         0x00000000 TV_RING         "-"    0 1000  30 1    2  0  0  0  0  0  0  50
call :addItemToGameObjects "Wisdom"                          0x00000004 TV_AMULET       "'"    0  300   0 1    3  0  0  0  0  0  0  20
call :addItemToGameObjects "Charisma"                        0x00000020 TV_AMULET       "'"    0  250   1 1    3  0  0  0  0  0  0  20
call :addItemToGameObjects "Searching"                       0x00000040 TV_AMULET       "'"    0  250   2 1    3  0  0  0  0  0  0  14
call :addItemToGameObjects "Teleportation"                   0x80000400 TV_AMULET       "'"    0    0   3 1    3  0  0  0  0  0  0  14
call :addItemToGameObjects "Slow Digestion"                  0x00000080 TV_AMULET       "'"    0  200   4 1    3  0  0  0  0  0  0  14
call :addItemToGameObjects "Resist Acid"                     0x00100000 TV_AMULET       "'"    0  250   5 1    3  0  0  0  0  0  0  24
call :addItemToGameObjects "Adornment"                       0x00000000 TV_AMULET       "'"    0   20   6 1    3  0  0  0  0  0  0  16
call :addItemToGameObjects "_ Bolt~"                         0x00000000 TV_BOLT         "{"    0    2 193 1    3  0  0  0  0  1  5  25
call :addItemToGameObjects "the Magi"                        0x01800040 TV_AMULET       "'"    0 5000   8 1    3  0  0  0  3  0  0  50
call :addItemToGameObjects "DOOM"                            0x8000007F TV_AMULET       "'"   -5    0   9 1    3  0  0  0  0  0  0  50
call :addItemToGameObjects "Enchant Weapon To-Hit"           0x00000001 TV_SCROLL1      "?"    0  125  64 1    5  0  0  0  0  0  0  12
call :addItemToGameObjects "Enchant Weapon To-Dam"           0x00000002 TV_SCROLL1      "?"    0  125  65 1    5  0  0  0  0  0  0  12
call :addItemToGameObjects "Enchant Armor"                   0x00000004 TV_SCROLL1      "?"    0  125  66 1    5  0  0  0  0  0  0  12
call :addItemToGameObjects "Identify"                        0x00000008 TV_SCROLL1      "?"    0   50  67 1    5  0  0  0  0  0  0   1
call :addItemToGameObjects "Identify"                        0x00000008 TV_SCROLL1      "?"    0   50  67 1    5  0  0  0  0  0  0   5
call :addItemToGameObjects "Identify"                        0x00000008 TV_SCROLL1      "?"    0   50  67 1    5  0  0  0  0  0  0  10
call :addItemToGameObjects "Identify"                        0x00000008 TV_SCROLL1      "?"    0   50  67 1    5  0  0  0  0  0  0  30
call :addItemToGameObjects "Remove Curse"                    0x00000010 TV_SCROLL1      "?"    0  100  68 1    5  0  0  0  0  0  0   7
call :addItemToGameObjects "Light"                           0x00000020 TV_SCROLL1      "?"    0   15  69 1    5  0  0  0  0  0  0   0
call :addItemToGameObjects "Light"                           0x00000020 TV_SCROLL1      "?"    0   15  69 1    5  0  0  0  0  0  0   3
call :addItemToGameObjects "Light"                           0x00000020 TV_SCROLL1      "?"    0   15  69 1    5  0  0  0  0  0  0   7
call :addItemToGameObjects "Summon Monster"                  0x00000040 TV_SCROLL1      "?"    0    0  70 1    5  0  0  0  0  0  0   1
call :addItemToGameObjects "Phase Door"                      0x00000080 TV_SCROLL1      "?"    0   15  71 1    5  0  0  0  0  0  0   1
call :addItemToGameObjects "Teleport"                        0x00000100 TV_SCROLL1      "?"    0   40  72 1    5  0  0  0  0  0  0  10
call :addItemToGameObjects "Teleport Level"                  0x00000200 TV_SCROLL1      "?"    0   50  73 1    5  0  0  0  0  0  0  20
call :addItemToGameObjects "Monster Confusion"               0x00000400 TV_SCROLL1      "?"    0   30  74 1    5  0  0  0  0  0  0   5
call :addItemToGameObjects "Magic Mapping"                   0x00000800 TV_SCROLL1      "?"    0   40  75 1    5  0  0  0  0  0  0   5
call :addItemToGameObjects "Sleep Monster"                   0x00001000 TV_SCROLL1      "?"    0   35  76 1    5  0  0  0  0  0  0   5
call :addItemToGameObjects "Rune of Protection"              0x00002000 TV_SCROLL1      "?"    0  500  77 1    5  0  0  0  0  0  0  50
call :addItemToGameObjects "Treasure Detection"              0x00004000 TV_SCROLL1      "?"    0   15  78 1    5  0  0  0  0  0  0   0
call :addItemToGameObjects "Object Detection"                0x00008000 TV_SCROLL1      "?"    0   15  79 1    5  0  0  0  0  0  0   0
call :addItemToGameObjects "Trap Detection"                  0x00010000 TV_SCROLL1      "?"    0   35  80 1    5  0  0  0  0  0  0   5
call :addItemToGameObjects "Trap Detection"                  0x00010000 TV_SCROLL1      "?"    0   35  80 1    5  0  0  0  0  0  0   8
call :addItemToGameObjects "Trap Detection"                  0x00010000 TV_SCROLL1      "?"    0   35  80 1    5  0  0  0  0  0  0  12
call :addItemToGameObjects "Door/Stair Location"             0x00020000 TV_SCROLL1      "?"    0   35  81 1    5  0  0  0  0  0  0   5
call :addItemToGameObjects "Door/Stair Location"             0x00020000 TV_SCROLL1      "?"    0   35  81 1    5  0  0  0  0  0  0  10
call :addItemToGameObjects "Door/Stair Location"             0x00020000 TV_SCROLL1      "?"    0   35  81 1    5  0  0  0  0  0  0  15
call :addItemToGameObjects "Mass Genocide"                   0x00040000 TV_SCROLL1      "?"    0 1000  82 1    5  0  0  0  0  0  0  50
call :addItemToGameObjects "Detect Invisible"                0x00080000 TV_SCROLL1      "?"    0   15  83 1    5  0  0  0  0  0  0   1
call :addItemToGameObjects "Aggravate Monster"               0x00100000 TV_SCROLL1      "?"    0    0  84 1    5  0  0  0  0  0  0   5
call :addItemToGameObjects "Trap Creation"                   0x00200000 TV_SCROLL1      "?"    0    0  85 1    5  0  0  0  0  0  0  12
call :addItemToGameObjects "Trap/Door Destruction"           0x00400000 TV_SCROLL1      "?"    0   50  86 1    5  0  0  0  0  0  0  12
call :addItemToGameObjects "Door Creation"                   0x00800000 TV_SCROLL1      "?"    0  100  87 1    5  0  0  0  0  0  0  12
call :addItemToGameObjects "Recharging"                      0x01000000 TV_SCROLL1      "?"    0  200  88 1    5  0  0  0  0  0  0  40
call :addItemToGameObjects "Genocide"                        0x02000000 TV_SCROLL1      "?"    0  750  89 1    5  0  0  0  0  0  0  35
call :addItemToGameObjects "Darkness"                        0x04000000 TV_SCROLL1      "?"    0    0  90 1    5  0  0  0  0  0  0   1
call :addItemToGameObjects "Protection from Evil"            0x08000000 TV_SCROLL1      "?"    0  100  91 1    5  0  0  0  0  0  0  30
call :addItemToGameObjects "Create Food"                     0x10000000 TV_SCROLL1      "?"    0   10  92 1    5  0  0  0  0  0  0   5
call :addItemToGameObjects "Dispel Undead"                   0x20000000 TV_SCROLL1      "?"    0  200  93 1    5  0  0  0  0  0  0  40
call :addItemToGameObjects "*Enchant Weapon*"                0x00000001 TV_SCROLL2      "?"    0  500  94 1    5  0  0  0  0  0  0  50
call :addItemToGameObjects "Curse Weapon"                    0x00000002 TV_SCROLL2      "?"    0    0  95 1    5  0  0  0  0  0  0  50
call :addItemToGameObjects "*Enchant Armor*"                 0x00000004 TV_SCROLL2      "?"    0  500  96 1    5  0  0  0  0  0  0  50
call :addItemToGameObjects "Curse Armor"                     0x00000008 TV_SCROLL2      "?"    0    0  97 1    5  0  0  0  0  0  0  50
call :addItemToGameObjects "Summon Undead"                   0x00000010 TV_SCROLL2      "?"    0    0  98 1    5  0  0  0  0  0  0  15
call :addItemToGameObjects "Blessing"                        0x00000020 TV_SCROLL2      "?"    0   15  99 1    5  0  0  0  0  0  0   1
call :addItemToGameObjects "Holy Chant"                      0x00000040 TV_SCROLL2      "?"    0   40 100 1    5  0  0  0  0  0  0  12
call :addItemToGameObjects "Holy Prayer"                     0x00000080 TV_SCROLL2      "?"    0   80 101 1    5  0  0  0  0  0  0  24
call :addItemToGameObjects "Word-of-Recall"                  0x00000100 TV_SCROLL2      "?"    0  150 102 1    5  0  0  0  0  0  0   5
call :addItemToGameObjects "*Destruction*"                   0x00000200 TV_SCROLL2      "?"    0  750 103 1    5  0  0  0  0  0  0  40

call :addItemToGameObjects "Slime Mold Juice"                0x30000000 TV_POTION1     "^!"  400    2  64 1    4  0  0  0  0  1  1   0
call :addItemToGameObjects "Apple Juice"                     0x00000000 TV_POTION1     "^!"  250    1  65 1    4  0  0  0  0  1  1   0
call :addItemToGameObjects "Water"                           0x00000000 TV_POTION1     "^!"  200    0  66 1    4  0  0  0  0  1  1   0
call :addItemToGameObjects "Strength"                        0x00000001 TV_POTION1     "^!"   50  300  67 1    4  0  0  0  0  1  1  25
call :addItemToGameObjects "Weakness"                        0x00000002 TV_POTION1     "^!"    0    0  68 1    4  0  0  0  0  1  1   3
call :addItemToGameObjects "Restore Strength"                0x00000004 TV_POTION1     "^!"    0  300  69 1    4  0  0  0  0  1  1  40
call :addItemToGameObjects "Intelligence"                    0x00000008 TV_POTION1     "^!"    0  300  70 1    4  0  0  0  0  1  1  25
call :addItemToGameObjects "Lose Intelligence"               0x00000010 TV_POTION1     "^!"    0    0  71 1    4  0  0  0  0  1  1  25
call :addItemToGameObjects "Restore Intelligence"            0x00000020 TV_POTION1     "^!"    0  300  72 1    4  0  0  0  0  1  1  40
call :addItemToGameObjects "Wisdom"                          0x00000040 TV_POTION1     "^!"    0  300  73 1    4  0  0  0  0  1  1  25
call :addItemToGameObjects "Lose Wisdom"                     0x00000080 TV_POTION1     "^!"    0    0  74 1    4  0  0  0  0  1  1  25
call :addItemToGameObjects "Restore Wisdom"                  0x00000100 TV_POTION1     "^!"    0  300  75 1    4  0  0  0  0  1  1  40
call :addItemToGameObjects "Charisma"                        0x00000200 TV_POTION1     "^!"    0  300  76 1    4  0  0  0  0  1  1  25
call :addItemToGameObjects "Ugliness"                        0x00000400 TV_POTION1     "^!"    0    0  77 1    4  0  0  0  0  1  1  25
call :addItemToGameObjects "Restore Charisma"                0x00000800 TV_POTION1     "^!"    0  300  78 1    4  0  0  0  0  1  1  40
call :addItemToGameObjects "Cure Light Wounds"               0x10001000 TV_POTION1     "^!"   50   15  79 1    4  0  0  0  0  1  1   0
call :addItemToGameObjects "Cure Light Wounds"               0x10001000 TV_POTION1     "^!"   50   15  79 1    4  0  0  0  0  1  1   1
call :addItemToGameObjects "Cure Light Wounds"               0x10001000 TV_POTION1     "^!"   50   15  79 1    4  0  0  0  0  1  1   2
call :addItemToGameObjects "Cure Serious Wounds"             0x30002000 TV_POTION1     "^!"  100   40  80 1    4  0  0  0  0  1  1   3
call :addItemToGameObjects "Cure Critical Wounds"            0x70004000 TV_POTION1     "^!"  100  100  81 1    4  0  0  0  0  1  1   5
call :addItemToGameObjects "Healing"                         0x70008000 TV_POTION1     "^!"  200  200  82 1    4  0  0  0  0  1  1  12
call :addItemToGameObjects "Constitution"                    0x00010000 TV_POTION1     "^!"   50  300  83 1    4  0  0  0  0  1  1  25
call :addItemToGameObjects "Gain Experience"                 0x00020000 TV_POTION1     "^!"    0 2500  84 1    4  0  0  0  0  1  1  50
call :addItemToGameObjects "Sleep"                           0x00040000 TV_POTION1     "^!"  100    0  85 1    4  0  0  0  0  1  1   0
call :addItemToGameObjects "Blindness"                       0x00080000 TV_POTION1     "^!"    0    0  86 1    4  0  0  0  0  1  1   0
call :addItemToGameObjects "Confusion"                       0x00100000 TV_POTION1     "^!"   50    0  87 1    4  0  0  0  0  1  1   0
call :addItemToGameObjects "Poison"                          0x00200000 TV_POTION1     "^!"    0    0  88 1    4  0  0  0  0  1  1   3
call :addItemToGameObjects "Haste Self"                      0x00400000 TV_POTION1     "^!"    0   75  89 1    4  0  0  0  0  1  1   1
call :addItemToGameObjects "Slowness"                        0x00800000 TV_POTION1     "^!"   50    0  90 1    4  0  0  0  0  1  1   1
call :addItemToGameObjects "Dexterity"                       0x02000000 TV_POTION1     "^!"    0  300  91 1    4  0  0  0  0  1  1  25
call :addItemToGameObjects "Restore Dexterity"               0x04000000 TV_POTION1     "^!"    0  300  92 1    4  0  0  0  0  1  1  40
call :addItemToGameObjects "Restore Constitution"            0x68000000 TV_POTION1     "^!"    0  300  93 1    4  0  0  0  0  1  1  40
call :addItemToGameObjects "Lose Experience"                 0x00000002 TV_POTION2     "^!"    0    0  95 1    4  0  0  0  0  1  1  10
call :addItemToGameObjects "Salt Water"                      0x00000004 TV_POTION2     "^!"    0    0  96 1    4  0  0  0  0  1  1   0
call :addItemToGameObjects "Invulnerability"                 0x00000008 TV_POTION2     "^!"    0 1000  97 1    4  0  0  0  0  1  1  40
call :addItemToGameObjects "Heroism"                         0x00000010 TV_POTION2     "^!"    0   35  98 1    4  0  0  0  0  1  1   1
call :addItemToGameObjects "Super Heroism"                   0x00000020 TV_POTION2     "^!"    0  100  99 1    4  0  0  0  0  1  1   3
call :addItemToGameObjects "Boldness"                        0x00000040 TV_POTION2     "^!"    0   10 100 1    4  0  0  0  0  1  1   1
call :addItemToGameObjects "Restore Life Levels"             0x00000080 TV_POTION2     "^!"    0  400 101 1    4  0  0  0  0  1  1  40
call :addItemToGameObjects "Resist Heat"                     0x00000100 TV_POTION2     "^!"    0   30 102 1    4  0  0  0  0  1  1   1
call :addItemToGameObjects "Resist Cold"                     0x00000200 TV_POTION2     "^!"    0   30 103 1    4  0  0  0  0  1  1   1
call :addItemToGameObjects "Detect Invisible"                0x00000400 TV_POTION2     "^!"    0   50 104 1    4  0  0  0  0  1  1   3
call :addItemToGameObjects "Slow Poison"                     0x00000800 TV_POTION2     "^!"    0   25 105 1    4  0  0  0  0  1  1   1
call :addItemToGameObjects "Neutralize Poison"               0x00001000 TV_POTION2     "^!"    0   75 106 1    4  0  0  0  0  1  1   5
call :addItemToGameObjects "Restore Mana"                    0x00002000 TV_POTION2     "^!"    0  350 107 1    4  0  0  0  0  1  1  25
call :addItemToGameObjects "Infra-Vision"                    0x00004000 TV_POTION2     "^!"    0   20 108 1    4  0  0  0  0  1  1   3
call :addItemToGameObjects "_ Flask~ of Oil"                 0x00040000 TV_FLASK       "^!" 7500    3  64 1   10  0  0  0  0  2  6   1
call :addItemToGameObjects "Light"                           0x00000001 TV_WAND         "-"    0  200   0 1   10  0  0  0  0  1  1   2
call :addItemToGameObjects "Lightning Bolts"                 0x00000002 TV_WAND         "-"    0  600   1 1   10  0  0  0  0  1  1  15
call :addItemToGameObjects "Frost Bolts"                     0x00000004 TV_WAND         "-"    0  800   2 1   10  0  0  0  0  1  1  20
call :addItemToGameObjects "Fire Bolts"                      0x00000008 TV_WAND         "-"    0 1000   3 1   10  0  0  0  0  1  1  30
call :addItemToGameObjects "Stone-to-Mud"                    0x00000010 TV_WAND         "-"    0  300   4 1   10  0  0  0  0  1  1  12
call :addItemToGameObjects "Polymorph"                       0x00000020 TV_WAND         "-"    0  400   5 1   10  0  0  0  0  1  1  20
call :addItemToGameObjects "Heal Monster"                    0x00000040 TV_WAND         "-"    0    0   6 1   10  0  0  0  0  1  1   2
call :addItemToGameObjects "Haste Monster"                   0x00000080 TV_WAND         "-"    0    0   7 1   10  0  0  0  0  1  1   2
call :addItemToGameObjects "Slow Monster"                    0x00000100 TV_WAND         "-"    0  500   8 1   10  0  0  0  0  1  1   2
call :addItemToGameObjects "Confuse Monster"                 0x00000200 TV_WAND         "-"    0  400   9 1   10  0  0  0  0  1  1   2
call :addItemToGameObjects "Sleep Monster"                   0x00000400 TV_WAND         "-"    0  500  10 1   10  0  0  0  0  1  1   7
call :addItemToGameObjects "Drain Life"                      0x00000800 TV_WAND         "-"    0 1200  11 1   10  0  0  0  0  1  1  50
call :addItemToGameObjects "Trap/Door Destruction"           0x00001000 TV_WAND         "-"    0  500  12 1   10  0  0  0  0  1  1  12
call :addItemToGameObjects "Magic Missile"                   0x00002000 TV_WAND         "-"    0  200  13 1   10  0  0  0  0  1  1   2
call :addItemToGameObjects "Wall Building"                   0x00004000 TV_WAND         "-"    0  400  14 1   10  0  0  0  0  1  1  25
call :addItemToGameObjects "Clone Monster"                   0x00008000 TV_WAND         "-"    0    0  15 1   10  0  0  0  0  1  1  15
call :addItemToGameObjects "Teleport Away"                   0x00010000 TV_WAND         "-"    0  350  16 1   10  0  0  0  0  1  1  20
call :addItemToGameObjects "Disarming"                       0x00020000 TV_WAND         "-"    0  500  17 1   10  0  0  0  0  1  1  20
call :addItemToGameObjects "Lightning Balls"                 0x00040000 TV_WAND         "-"    0 1200  18 1   10  0  0  0  0  1  1  35
call :addItemToGameObjects "Cold Balls"                      0x00080000 TV_WAND         "-"    0 1500  19 1   10  0  0  0  0  1  1  40
call :addItemToGameObjects "Fire Balls"                      0x00100000 TV_WAND         "-"    0 1800  20 1   10  0  0  0  0  1  1  50
call :addItemToGameObjects "Stinking Cloud"                  0x00200000 TV_WAND         "-"    0  400  21 1   10  0  0  0  0  1  1   5
call :addItemToGameObjects "Acid Balls"                      0x00400000 TV_WAND         "-"    0 1650  22 1   10  0  0  0  0  1  1  48
call :addItemToGameObjects "Wonder"                          0x00800000 TV_WAND         "-"    0  250  23 1   10  0  0  0  0  1  1   2
call :addItemToGameObjects "Light"                           0x00000001 TV_STAFF        "_"    0  250   0 1   50  0  0  0  0  1  2   5
call :addItemToGameObjects "Door/Stair Location"             0x00000002 TV_STAFF        "_"    0  350   1 1   50  0  0  0  0  1  2  10
call :addItemToGameObjects "Trap Location"                   0x00000004 TV_STAFF        "_"    0  350   2 1   50  0  0  0  0  1  2  10
call :addItemToGameObjects "Treasure Location"               0x00000008 TV_STAFF        "_"    0  200   3 1   50  0  0  0  0  1  2   5
call :addItemToGameObjects "Object Location"                 0x00000010 TV_STAFF        "_"    0  200   4 1   50  0  0  0  0  1  2   5
call :addItemToGameObjects "Teleportation"                   0x00000020 TV_STAFF        "_"    0  800   5 1   50  0  0  0  0  1  2  20
call :addItemToGameObjects "Earthquakes"                     0x00000040 TV_STAFF        "_"    0  350   6 1   50  0  0  0  0  1  2  40
call :addItemToGameObjects "Summoning"                       0x00000080 TV_STAFF        "_"    0    0   7 1   50  0  0  0  0  1  2  10
call :addItemToGameObjects "Summoning"                       0x00000080 TV_STAFF        "_"    0    0   7 1   50  0  0  0  0  1  2  50
call :addItemToGameObjects "*Destruction*"                   0x00000200 TV_STAFF        "_"    0 2500   8 1   50  0  0  0  0  1  2  50
call :addItemToGameObjects "Starlight"                       0x00000400 TV_STAFF        "_"    0  400   9 1   50  0  0  0  0  1  2  20
call :addItemToGameObjects "Haste Monsters"                  0x00000800 TV_STAFF        "_"    0    0  10 1   50  0  0  0  0  1  2  10
call :addItemToGameObjects "Slow Monsters"                   0x00001000 TV_STAFF        "_"    0  800  11 1   50  0  0  0  0  1  2  10
call :addItemToGameObjects "Sleep Monsters"                  0x00002000 TV_STAFF        "_"    0  700  12 1   50  0  0  0  0  1  2  10
call :addItemToGameObjects "Cure Light Wounds"               0x00004000 TV_STAFF        "_"    0  200  13 1   50  0  0  0  0  1  2   5
call :addItemToGameObjects "Detect Invisible"                0x00008000 TV_STAFF        "_"    0  200  14 1   50  0  0  0  0  1  2   5
call :addItemToGameObjects "Speed"                           0x00010000 TV_STAFF        "_"    0 1000  15 1   50  0  0  0  0  1  2  40
call :addItemToGameObjects "Slowness"                        0x00020000 TV_STAFF        "_"    0    0  16 1   50  0  0  0  0  1  2  40
call :addItemToGameObjects "Mass Polymorph"                  0x00040000 TV_STAFF        "_"    0  750  17 1   50  0  0  0  0  1  2  46
call :addItemToGameObjects "Remove Curse"                    0x00080000 TV_STAFF        "_"    0  500  18 1   50  0  0  0  0  1  2  47
call :addItemToGameObjects "Detect Evil"                     0x00100000 TV_STAFF        "_"    0  350  19 1   50  0  0  0  0  1  2  20
call :addItemToGameObjects "Curing"                          0x00200000 TV_STAFF        "_"    0 1000  20 1   50  0  0  0  0  1  2  25
call :addItemToGameObjects "Dispel Evil"                     0x00400000 TV_STAFF        "_"    0 1200  21 1   50  0  0  0  0  1  2  49
call :addItemToGameObjects "Darkness"                        0x01000000 TV_STAFF        "_"    0    0  22 1   50  0  0  0  0  1  2  50
call :addItemToGameObjects "Darkness"                        0x01000000 TV_STAFF        "_"    0    0  22 1   50  0  0  0  0  1  2   5
call :addItemToGameObjects "[Beginners-Magick]"              0x0000007F TV_MAGIC_BOOK   "?"    0   25  64 1   30  0  0  0  0  1  1  40
call :addItemToGameObjects "[Magick I]"                      0x0000FF80 TV_MAGIC_BOOK   "?"    0  100  65 1   30  0  0  0  0  1  1  40
call :addItemToGameObjects "[Magick II]"                     0x00FF0000 TV_MAGIC_BOOK   "?"    0  400  66 1   30  0  0  0  0  1  1  40
call :addItemToGameObjects "[The Mages' Guide to Power]"     0x7F000000 TV_MAGIC_BOOK   "?"    0  800  67 1   30  0  0  0  0  1  1  40
call :addItemToGameObjects "[Beginners Handbook]"            0x000000FF TV_PRAYER_BOOK  "?"    0   25  64 1   30  0  0  0  0  1  1  40
call :addItemToGameObjects "[Words of Wisdom]"               0x0000FF00 TV_PRAYER_BOOK  "?"    0  100  65 1   30  0  0  0  0  1  1  40
call :addItemToGameObjects "[Chants and Blessings]"          0x01FF0000 TV_PRAYER_BOOK  "?"    0  400  66 1   30  0  0  0  0  1  1  40
call :addItemToGameObjects "[Exorcisms and Dispellings]"     0x7E000000 TV_PRAYER_BOOK  "?"    0  800  67 1   30  0  0  0  0  1  1  40
call :addItemToGameObjects "_ Small Wooden Chest"            0x13800000 TV_CHEST       "^&"    0   20   1 1  250  0  0  0  0  2  3   7
call :addItemToGameObjects "_ Large Wooden Chest"            0x17800000 TV_CHEST       "^&"    0   60   4 1  500  0  0  0  0  2  5  15
call :addItemToGameObjects "_ Small Iron Chest"              0x17800000 TV_CHEST       "^&"    0  100   7 1  500  0  0  0  0  2  4  25
call :addItemToGameObjects "_ Large Iron Chest"              0x23800000 TV_CHEST       "^&"    0  150  10 1 1000  0  0  0  0  2  6  35
call :addItemToGameObjects "_ Small Steel Chest"             0x1B800000 TV_CHEST       "^&"    0  200  13 1  500  0  0  0  0  2  4  45
call :addItemToGameObjects "_ Large Steel Chest"             0x33800000 TV_CHEST       "^&"    0  250  16 1 1000  0  0  0  0  2  6  50
call :addItemToGameObjects "_ Rat Skeleton"                  0x00000000 TV_MISC         "s"    0    0   1 1   10  0  0  0  0  1  1   1
call :addItemToGameObjects "_ Giant Centipede Skeleton"      0x00000000 TV_MISC         "s"    0    0   2 1   25  0  0  0  0  1  1   1
call :addItemToGameObjects "some Filthy Rags"                0x00000000 TV_SOFT_ARMOR   "~"    0    0  63 1   20  0  0  1  0  0  0   0
call :addItemToGameObjects "_ empty bottle"                  0x00000000 TV_MISC        "^!"    0    0   4 1    2  0  0  0  0  1  1   0
call :addItemToGameObjects "some shards of pottery"          0x00000000 TV_MISC         "~"    0    0   5 1    5  0  0  0  0  1  1   0
call :addItemToGameObjects "_ Human Skeleton"                0x00000000 TV_MISC         "s"    0    0   7 1   60  0  0  0  0  1  1   1
call :addItemToGameObjects "_ Dwarf Skeleton"                0x00000000 TV_MISC         "s"    0    0   8 1   50  0  0  0  0  1  1   1
call :addItemToGameObjects "_ Elf Skeleton"                  0x00000000 TV_MISC         "s"    0    0   9 1   40  0  0  0  0  1  1   1
call :addItemToGameObjects "_ Gnome Skeleton"                0x00000000 TV_MISC         "s"    0    0  10 1   25  0  0  0  0  1  1   1
call :addItemToGameObjects "_ broken set of teeth"           0x00000000 TV_MISC         "s"    0    0  11 1    3  0  0  0  0  1  1   0
call :addItemToGameObjects "_ large broken bone"             0x00000000 TV_MISC         "s"    0    0  12 1    2  0  0  0  0  1  1   0
call :addItemToGameObjects "_ broken stick"                  0x00000000 TV_MISC         "~"    0    0  13 1    3  0  0  0  0  1  1   0

::----- Store Items
call :addItemToGameObjects "_ Ration~ of Food"               0x00000000 TV_FOOD         "," 5000    3  90 5   10  0  0  0  0  0  0   0
call :addItemToGameObjects "_ Hard Biscuit~"                 0x00000000 TV_FOOD         ","  500    1  93 5    2  0  0  0  0  0  0   0
call :addItemToGameObjects "_ Strip~ of Beef Jerky"          0x00000000 TV_FOOD         "," 1750    2  94 5    4  0  0  0  0  0  0   0
call :addItemToGameObjects "_ Pint~ of Fine Ale"             0x00000000 TV_FOOD         ","  500    1  95 3   10  0  0  0  0  0  0   0
call :addItemToGameObjects "_ Pint~ of Fine Wine"            0x00000000 TV_FOOD         ","  400    2  96 1   10  0  0  0  0  0  0   0
call :addItemToGameObjects "_ Pick"                          0x20000000 TV_DIGGING      "\"    1   50   1 1  150  0  0  0  0  1  3   0
call :addItemToGameObjects "_ Shovel"                        0x20000000 TV_DIGGING      "\"    0   15   4 1   60  0  0  0  0  1  2   0
call :addItemToGameObjects "Identify"                        0x00000008 TV_SCROLL1      "?"    0   50  67 2    5  0  0  0  0  0  0   0
call :addItemToGameObjects "Light"                           0x00000020 TV_SCROLL1      "?"    0   15  69 3    5  0  0  0  0  0  0   0
call :addItemToGameObjects "Phase Door"                      0x00000080 TV_SCROLL1      "?"    0   15  71 2    5  0  0  0  0  0  0   0
call :addItemToGameObjects "Magic Mapping"                   0x00000800 TV_SCROLL1      "?"    0   40  75 2    5  0  0  0  0  0  0   0
call :addItemToGameObjects "Treasure Detection"              0x00004000 TV_SCROLL1      "?"    0   15  78 2    5  0  0  0  0  0  0   0
call :addItemToGameObjects "Object Detection"                0x00008000 TV_SCROLL1      "?"    0   15  79 2    5  0  0  0  0  0  0   0
call :addItemToGameObjects "Detect Invisible"                0x00080000 TV_SCROLL1      "?"    0   15  83 2    5  0  0  0  0  0  0   0
call :addItemToGameObjects "Blessing"                        0x00000020 TV_SCROLL2      "?"    0   15  99 2    5  0  0  0  0  0  0   0
call :addItemToGameObjects "Word-of-Recall"                  0x00000100 TV_SCROLL2      "?"    0  150 102 3    5  0  0  0  0  0  0   0
call :addItemToGameObjects "Cure Light Wounds"               0x10001000 TV_POTION1     "^!"   50   15  79 2    4  0  0  0  0  1  1   0
call :addItemToGameObjects "Heroism"                         0x00000010 TV_POTION2     "^!"    0   35  98 2    4  0  0  0  0  1  1   0
call :addItemToGameObjects "Boldness"                        0x00000040 TV_POTION2     "^!"    0   10 100 2    4  0  0  0  0  1  1   0
call :addItemToGameObjects "Slow Poison"                     0x00000800 TV_POTION2     "^!"    0   25 105 2    4  0  0  0  0  1  1   0
call :addItemToGameObjects "_ Brass Lantern~"                0x00000000 TV_LIGHT        "~" 7500   35   0 1   50  0  0  0  0  1  1   1
call :addItemToGameObjects "_ Wooden Torch~"                 0x00000000 TV_LIGHT        "~" 4000    2 192 5   30  0  0  0  0  1  1   1
call :addItemToGameObjects "_ Flask~ of Oil"                 0x00040000 TV_FLASK       "^!" 7500    3  64 5   10  0  0  0  0  2  6   1

::----- Doors
call :addItemToGameObjects "_ open door"                     0x00000000 TV_OPEN_DOOR    "'"    0    0   1 1    0  0  0  0  0  1  1   0
call :addItemToGameObjects "_ closed door"                   0x00000000 TV_CLOSED_DOOR  "+"    0    0  19 1    0  0  0  0  0  1  1   0
call :addItemToGameObjects "_ secret door"                   0x00000000 TV_SECRET_DOOR  "#"    0    0  19 1    0  0  0  0  0  1  1   0

::----- Stairs
call :addItemToGameObjects "an up staircase"                 0x00000000 TV_UP_STAIR    "^<"    0    0   1 1    0  0  0  0  0  1  1   0
call :addItemToGameObjects "a down staircase"                0x00000000 TV_DOWN_STAIR  "^>"    0    0   1 1    0  0  0  0  0  1  1   0

::----- Store Doors
call :addItemToGameObjects "General Store"                   0x00000000 TV_STORE_DOOR   "1"    0    0 101 1    0  0  0  0  0  0  0   0
call :addItemToGameObjects "Armory"                          0x00000000 TV_STORE_DOOR   "2"    0    0 102 1    0  0  0  0  0  0  0   0
call :addItemToGameObjects "Weapon Smiths"                   0x00000000 TV_STORE_DOOR   "3"    0    0 103 1    0  0  0  0  0  0  0   0
call :addItemToGameObjects "Temple"                          0x00000000 TV_STORE_DOOR   "4"    0    0 104 1    0  0  0  0  0  0  0   0
call :addItemToGameObjects "Alchemy Shop"                    0x00000000 TV_STORE_DOOR   "5"    0    0 105 1    0  0  0  0  0  0  0   0
call :addItemToGameObjects "Magic Shop"                      0x00000000 TV_STORE_DOOR   "6"    0    0 106 1    0  0  0  0  0  0  0   0

::----- Traps
call :addItemToGameObjects "an open pit"                     0x00000000 TV_VIS_TRAP     " "    1    0   1 1    0  0  0  0  0  2  6  50
call :addItemToGameObjects "an arrow trap"                   0x00000000 TV_INVIS_TRAP  "^^"    3    0   2 1    0  0  0  0  0  1  8  90
call :addItemToGameObjects "a covered pit"                   0x00000000 TV_INVIS_TRAP  "^^"    2    0   3 1    0  0  0  0  0  2  6  60
call :addItemToGameObjects "a trap door"                     0x00000000 TV_INVIS_TRAP  "^^"    5    0   4 1    0  0  0  0  0  2  8  75
call :addItemToGameObjects "a gas trap"                      0x00000000 TV_INVIS_TRAP  "^^"    3    0   5 1    0  0  0  0  0  1  4  95
call :addItemToGameObjects "a loose rock"                    0x00000000 TV_INVIS_TRAP   ";"    0    0   6 1    0  0  0  0  0  0  0  10
call :addItemToGameObjects "a dart trap"                     0x00000000 TV_INVIS_TRAP  "^^"    5    0   7 1    0  0  0  0  0  1  4 110
call :addItemToGameObjects "a strange rune"                  0x00000000 TV_INVIS_TRAP  "^^"    5    0   8 1    0  0  0  0  0  0  0  90
call :addItemToGameObjects "some loose rock"                 0x00000000 TV_INVIS_TRAP  "^^"    5    0   9 1    0  0  0  0  0  2  6  90
call :addItemToGameObjects "a gas trap"                      0x00000000 TV_INVIS_TRAP  "^^"   10    0  10 1    0  0  0  0  0  1  4 105
call :addItemToGameObjects "a strange rune"                  0x00000000 TV_INVIS_TRAP  "^^"    5    0  11 1    0  0  0  0  0  0  0  90
call :addItemToGameObjects "a blackened spot"                0x00000000 TV_INVIS_TRAP  "^^"   10    0  12 1    0  0  0  0  0  4  6 110
call :addItemToGameObjects "some corroded rock"              0x00000000 TV_INVIS_TRAP  "^^"   10    0  13 1    0  0  0  0  0  4  6 110
call :addItemToGameObjects "a gas trap"                      0x00000000 TV_INVIS_TRAP  "^^"    5    0  14 1    0  0  0  0  0  2  6 105
call :addItemToGameObjects "a gas trap"                      0x00000000 TV_INVIS_TRAP  "^^"    5    0  15 1    0  0  0  0  0  1  4 110
call :addItemToGameObjects "a gas trap"                      0x00000000 TV_INVIS_TRAP  "^^"    5    0  16 1    0  0  0  0  0  1  8 105
call :addItemToGameObjects "a dart trap"                     0x00000000 TV_INVIS_TRAP  "^^"    5    0  17 1    0  0  0  0  0  1  8 110
call :addItemToGameObjects "a dart trap"                     0x00000000 TV_INVIS_TRAP  "^^"    5    0  18 1    0  0  0  0  0  1  8 110

::----- Rubble
call :addItemToGameObjects "some rubble"                     0x00000000 TV_RUBBLE       ":"    0    0   1 1    0  0  0  0  0  0  0   0

::----- Mush
call :addItemToGameObjects "_ Pint~ of Fine Grade Mush"      0x00000000 TV_FOOD         "," 1500    1  97 1    1  0  0  0  0  1  1   1

::----- Special Trap
call :addItemToGameObjects "a strange rune"                  0x00000000 TV_VIS_TRAP    "^^"    0    0  99 1    0  0  0  0  0  0  0  10

::----- Gold and Jewels
call :addItemToGameObjects "copper"                          0x00000000 TV_GOLD         "$"    0    3   1 1    0  0  0  0  0  0  0   1
call :addItemToGameObjects "copper"                          0x00000000 TV_GOLD         "$"    0    4   2 1    0  0  0  0  0  0  0   1
call :addItemToGameObjects "copper"                          0x00000000 TV_GOLD         "$"    0    5   3 1    0  0  0  0  0  0  0   1
call :addItemToGameObjects "silver"                          0x00000000 TV_GOLD         "$"    0    6   4 1    0  0  0  0  0  0  0   1
call :addItemToGameObjects "silver"                          0x00000000 TV_GOLD         "$"    0    7   5 1    0  0  0  0  0  0  0   1
call :addItemToGameObjects "silver"                          0x00000000 TV_GOLD         "$"    0    8   6 1    0  0  0  0  0  0  0   1
call :addItemToGameObjects "garnets"                         0x00000000 TV_GOLD         "*"    0    9   7 1    0  0  0  0  0  0  0   1
call :addItemToGameObjects "garnets"                         0x00000000 TV_GOLD         "*"    0   10   8 1    0  0  0  0  0  0  0   1
call :addItemToGameObjects "gold"                            0x00000000 TV_GOLD         "$"    0   12   9 1    0  0  0  0  0  0  0   1
call :addItemToGameObjects "gold"                            0x00000000 TV_GOLD         "$"    0   14  10 1    0  0  0  0  0  0  0   1
call :addItemToGameObjects "gold"                            0x00000000 TV_GOLD         "$"    0   16  11 1    0  0  0  0  0  0  0   1
call :addItemToGameObjects "opals"                           0x00000000 TV_GOLD         "*"    0   18  12 1    0  0  0  0  0  0  0   1
call :addItemToGameObjects "sapphires"                       0x00000000 TV_GOLD         "*"    0   20  13 1    0  0  0  0  0  0  0   1
call :addItemToGameObjects "gold"                            0x00000000 TV_GOLD         "$"    0   24  14 1    0  0  0  0  0  0  0   1
call :addItemToGameObjects "rubies"                          0x00000000 TV_GOLD         "*"    0   28  15 1    0  0  0  0  0  0  0   1
call :addItemToGameObjects "diamonds"                        0x00000000 TV_GOLD         "*"    0   32  16 1    0  0  0  0  0  0  0   1
call :addItemToGameObjects "emeralds"                        0x00000000 TV_GOLD         "*"    0   40  17 1    0  0  0  0  0  0  0   1
call :addItemToGameObjects "mithril"                         0x00000000 TV_GOLD         "$"    0   80  18 1    0  0  0  0  0  0  0   1

::------ Used as inventory placeholder
call :addItemToGameObjects "nothing"                         0x00000000 TV_NOTHING      " "    0    0  64 0    0  0  0  0  0  0  0   0

::------ Only needed for the names
call :addItemToGameObjects "_ ruined chest"                  0x00000000 TV_CHEST       "^&"    0    0   0 1  250  0  0  0  0  0  0   0
call :addItemToGameObjects " "                               0x00000000 TV_NOTHING      " "    0    0   0 0    0  0  0  0  0  0  0   0

::----- Special Item Names
set "_index=0"
for %%A in ("CNIL"              "(R)"              "(RA)",
            "(RF)"              "(RC)"             "(RL)",
            "(HA)"              "(DF)"             "(SA)",
            "(SD)"              "(SE)"             "(SU)",
            "(FT)"              "(FB)"             "of Free Action",
            "of Slaying"        "of Clumsiness"    "of Weakness",
            "of Slow Descent"   "of Speed"         "of Stealth",
            "of Slowness"       "of Noise"         "of Great Mass",
            "of Intelligence"   "of Wisdom"        "of Infra-Vision",
            "of Might"          "of Lordliness"    "of the Magi",
            "of Beauty"         "of Seeing"        "of Regeneration",
            "of Stupidity"      "of Dullness"      "of Blindness",
            "of Timidness"      "of Teleportation" "of Ugliness",
            "of Protection"     "of Irritation"    "of Vulnerability",
            "of Enveloping"     "of Fire"          "of Slay Evil",
            "of Dragon Slaying" "(Empty)"          "(Locked)",
            "(Poison Needle)"   "(Gas Trap)"       "(Explosion Device)",
            "(Summoning Runes)" "(Multiple Traps)" "(Disarmed)",
            "(Unlocked)"        "of Slay Animal") do (
    set "special_item_names[!_index!]=%%~A"
    set /a _index+=1
)
exit /b

::------------------------------------------------------------------------------
:: Adds an object to the game_objects array
::
:: Arguments: %1  - Name of the object
::            %2  - Special flags
::            %3  - Category number sometimes seen in the code as TVAL
::            %4  - Character used to represent object on the map
::            %5  - Number of uses of the object
::            %6  - Cost of item
::            %7  - Sub-category number
::            %8  - Number of items
::            %9  - Weight
::            %10 - Plusses to hit
::            %11 - Plusses to damage
::            %12 - Normal AC
::            %13 - Plusses to AC
::            %14 - Damage when hits (dice count)
::            %15 - Damage when hits (dice sides)
::            %16 - Dungeon level first found on
:: Returns:   None
::------------------------------------------------------------------------------
:addItemToGameObjects
set    "game_objects[%object_count%].name=%~1"
set /a "game_objects[%object_count%].flags=%~2"
set    "game_objects[%object_count%].category_id=!%~3!"
set    "game_objects[%object_count%].sprite=%~4"
set    "game_objects[%object_count%].misc_use=%~5"
set    "game_objects[%object_count%].cost=%~6"
set    "game_objects[%object_count%].sub_category_id=%~7"
set    "game_objects[%object_count%].items_count=%~8"
set    "game_objects[%object_count%].weight=%~9"

for /L %%A in (1,1,9) do shift

set    "game_objects[%object_count%].to_hit=%~1"
set    "game_objects[%object_count%].to_damage=%~2"
set    "game_objects[%object_count%].ac=%~3"
set    "game_objects[%object_count%].to_ac=%~4"
set    "game_objects[%object_count%].damage.dice=%~5"
set    "game_objects[%object_count%].damage.sides=%~6"
set    "game_objects[%object_count%].depth_first_found=%~7"
exit /b