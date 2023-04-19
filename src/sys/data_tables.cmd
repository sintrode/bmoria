:: Data tables for attack and RNG including lists of names of things that the
:: player will find down in the dungeons

::----- Arrays for descriptive pieces
set "_index=0"
for %%A in ("Icky Green" "Light Brown" "Clear",
            "Azure" "Blue" "Blue Speckled" "Black" "Brown" "Brown Speckled" "Bubbling",
            "Chartreuse" "Cloudy" "Copper Speckled" "Crimson" "Cyan" "Dark Blue",
            "Dark Green" "Dark Red" "Gold Speckled" "Green" "Green Speckled" "Grey",
            "Grey Speckled" "Hazy" "Indigo" "Light Blue" "Light Green" "Magenta",
            "Metallic Blue" "Metallic Red" "Metallic Green" "Metallic Purple" "Misty",
            "Orange" "Orange Speckled" "Pink" "Pink Speckled" "Puce" "Purple",
            "Purple Speckled" "Red" "Red Speckled" "Silver Speckled" "Smoky",
            "Tangerine" "Violet" "Vermilion" "White" "Yellow") do (
    set "colors[!_index!]=%%~A"
    set /a _index+=1
)

set "_index=0"
for %%A in ("Blue" "Black" "Black Spotted" "Brown" "Dark Blue" "Dark Green" "Dark Red",
            "Ecru" "Furry" "Green" "Grey" "Light Blue" "Light Green" "Plaid" "Red",
            "Slimy" "Tan" "White" "White Spotted" "Wooden" "Wrinkled" "Yellow") do (
    set "mushrooms[!_index!]=%%~A"
    set /a _index+=1
)

set "_index=0"
for %%A in ("Aspen" "Balsa" "Banyan" "Birch" "Cedar" "Cottonwood" "Cypress" "Dogwood",
            "Elm" "Eucalyptus" "Hemlock" "Hickory" "Ironwood" "Locust" "Mahogany",
            "Maple" "Mulberry" "Oak" "Pine" "Redwood" "Rosewood" "Spruce" "Sycamore",
            "Teak" "Walnut") do (
    set "woods[!_index!]=%%~A"
    set /a _index+=1
)

set "_index=0"
for %%A in ("Aluminum" "Cast Iron" "Chromium" "Copper" "Gold" "Iron" "Magnesium",
            "Molybdenum" "Nickel" "Rusty" "Silver" "Steel" "Tin" "Titanium" "Tungsten",
            "Zirconium" "Zinc" "Aluminum-Plated" "Copper-Plated" "Gold-Plated",
            "Nickel-Plated" "Silver-Plated" "Steel-Plated" "Tin-Plated" "Zinc-Plated") do (
    set "mushrooms[!_index!]=%%~A"
    set /a _index+=1
)

set "_index=0"
for %%A in ("Alexandrite" "Amethyst" "Aquamarine" "Azurite" "Beryl" "Bloodstone",
            "Calcite" "Carnelian" "Corundum" "Diamond" "Emerald" "Fluorite" "Garnet",
            "Granite" "Jade" "Jasper" "Lapis Lazuli" "Malachite" "Marble" "Moonstone",
            "Onyx" "Opal" "Pearl" "Quartz" "Quartzite" "Rhodonite" "Ruby" "Sapphire",
            "Tiger Eye" "Topaz" "Turquoise" "Zircon") do (
    set "rocks[!_index!]=%%~A"
    set /a _index+=1
)

set "_index=0"
for %%A in ("Amber" "Driftwood" "Coral" "Agate" "Ivory" "Obsidian",
            "Bone" "Brass" "Bronze" "Pewter" "Tortoise Shell") do (
    set "amulets[!_index!]=%%~A"
    set /a _index+=1
)

set "_index=0"
for %%A in ("a"    "ab"   "ag"   "aks"  "ala"  "an"  "ankh" "app" "arg",
            "arze" "ash"  "aus"  "ban"  "bar"  "bat" "bek"  "bie" "bin",
            "bit"  "bjor" "blu"  "bot"  "bu"   "byt" "comp" "con" "cos",
            "cre"  "dalf" "dan"  "den"  "doe"  "dok" "eep"  "el"  "eng",
            "er"   "ere"  "erk"  "esh"  "evs"  "fa"  "fid"  "for" "fri",
            "fu"   "gan"  "gar"  "glen" "gop"  "gre" "ha"   "he"  "hyd",
            "i"    "ing"  "ion"  "ip"   "ish"  "it"  "ite"  "iv"  "jo",
            "kho"  "kli"  "klis" "la"   "lech" "man" "mar"  "me"  "mi",
            "mic"  "mik"  "mon"  "mung" "mur"  "nej" "nelg" "nep" "ner",
            "nes"  "nis"  "nih"  "nin"  "o"    "od"  "ood"  "org" "orn",
            "ox"   "oxy"  "pay"  "pet"  "ple"  "plu" "po"   "pot" "prok",
            "re"   "rea"  "rhov" "ri"   "ro"   "rog" "rok"  "rol" "sa",
            "san"  "sat"  "see"  "sef"  "seh"  "shu" "ski"  "sna" "sne",
            "snik" "sno"  "so"   "sol"  "sri"  "sta" "sun"  "ta"  "tab",
            "tem"  "ther" "ti"   "tox"  "trol" "tue" "turs" "u"   "ulk",
            "um"   "un"   "uni"  "ur"   "val"  "viv" "vly"  "vom" "wah",
            "wed"  "werg" "wex"  "whon" "wun"  "x"   "yerg" "yp"  "zun") do (
    set "syllables[!_index!]=%%~A"
    set /a _index+=1
)

::----- Calculate the number of hits the player gets in combat
::      based on strength and dexterity
call :addListTo2dArray blows_table "1 1 1 1 1 1"
call :addListTo2dArray blows_table "1 1 1 1 2 2"
call :addListTo2dArray blows_table "1 1 1 2 2 3"
call :addListTo2dArray blows_table "1 1 2 2 3 3"
call :addListTo2dArray blows_table "1 2 2 3 3 4"
call :addListTo2dArray blows_table "1 2 2 3 4 4"
call :addListTo2dArray blows_table "2 2 3 3 4 4"

::----- A table for pseudo-normal distribution
set "_index=0"
for %%A in (206   613   1022  1430  1838  2245  2652  3058
            3463  3867  4271  4673  5075  5475  5874  6271
            6667  7061  7454  7845  8234  8621  9006  9389
            9770  10148 10524 10898 11269 11638 12004 12367
            12727 13085 13440 13792 14140 14486 14828 15168
            15504 15836 16166 16492 16814 17133 17449 17761
            18069 18374 18675 18972 19266 19556 19842 20124
            20403 20678 20949 21216 21479 21738 21994 22245
            22493 22737 22977 23213 23446 23674 23899 24120
            24336 24550 24759 24965 25166 25365 25559 25750
            25937 26120 26300 26476 26649 26818 26983 27146
            27304 27460 27612 27760 27906 28048 28187 28323
            28455 28585 28711 28835 28955 29073 29188 29299
            29409 29515 29619 29720 29818 29914 30007 30098
            30186 30272 30356 30437 30516 30593 30668 30740
            30810 30879 30945 31010 31072 31133 31192 31249
            31304 31358 31410 31460 31509 31556 31601 31646
            31688 31730 31770 31808 31846 31882 31917 31950
            31983 32014 32044 32074 32102 32129 32155 32180
            32205 32228 32251 32273 32294 32314 32333 32352
            32370 32387 32404 32420 32435 32450 32464 32477
            32490 32503 32515 32526 32537 32548 32558 32568
            32577 32586 32595 32603 32611 32618 32625 32632
            32639 32645 32651 32657 32662 32667 32672 32677
            32682 32686 32690 32694 32698 32702 32705 32708
            32711 32714 32717 32720 32722 32725 32727 32729
            32731 32733 32735 32737 32739 32740 32742 32743
            32745 32746 32747 32748 32749 32750 32751 32752
            32753 32754 32755 32756 32757 32757 32758 32758
            32759 32760 32760 32761 32761 32761 32762 32762
            32763 32763 32763 32764 32764 32764 32764 32765
            32765 32765 32765 32766 32766 32766 32766 32766) do (
    set "normal_table[!_index!]=%%~A"
    set /a _index+=1
)
set "_index="
exit /b

::------------------------------------------------------------------------------
:: Adds a list of items to an array and then increments the first dimension
::
:: Arguments: %1 - The name of the array to add a list of elements to
::            %2 - The list of values to store in the 2D array
:: Returns:   None
::------------------------------------------------------------------------------
:addListTo2dArray
set "element=0"
for %%A in (%~2) do (
    set "%~1[!counter!][!element!]=%%~A"
    set /a element+=1
)
set /a counter+=1
exit /b