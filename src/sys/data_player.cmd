:: Multidimensional arrays for Class rank title, racial biases, race stats,
:: background information, class stats, class saves, magic spells, spell
:: names, and initial starting gear. Pretty much just pure data.
@echo off

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