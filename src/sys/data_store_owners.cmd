:: Speech text for store owners
@echo off

set "owner_count=0"
call :addOwnerToStoreOwners "Erick the Honest       (Human)      General Store"   250 175 108 4 0 12
call :addOwnerToStoreOwners "Mauglin the Grumpy     (Dwarf)      Armory"        32000 200 112 4 5  5
call :addOwnerToStoreOwners "Arndal Beast-Slayer    (Half-Elf)   Weaponsmith"   10000 185 110 5 1  8
call :addOwnerToStoreOwners "Hardblow the Humble    (Human)      Temple"         3500 175 109 6 0 15
call :addOwnerToStoreOwners "Ga-nat the Greedy      (Gnome)      Alchemist"     12000 220 115 4 4  9
call :addOwnerToStoreOwners "Valeria Starshine      (Elf)        Magic Shop"    32000 175 110 5 2 11
call :addOwnerToStoreOwners "Andy the Friendly      (Halfling)   General Store"   200 170 108 5 3 15
call :addOwnerToStoreOwners "Darg-Low the Grim      (Human)      Armory"        10000 190 111 4 0  9
call :addOwnerToStoreOwners "Oglign Dragon-Slayer   (Dwarf)      Weaponsmith"   32000 195 112 4 5  8
call :addOwnerToStoreOwners "Gunnar the Paladin     (Human)      Temple"         5000 185 110 5 0 23
call :addOwnerToStoreOwners "Mauser the Chemist     (Half-Elf)   Alchemist"     10000 190 111 5 1  8
call :addOwnerToStoreOwners "Gopher the Great!      (Gnome)      Magic Shop"    20000 215 113 6 4 10
call :addOwnerToStoreOwners "Lyar-el the Comely     (Elf)        General Store"   300 165 107 6 2 18
call :addOwnerToStoreOwners "Mauglim the Horrible   (Half-Orc)   Armory"         3000 200 113 5 6  9
call :addOwnerToStoreOwners "Ithyl-Mak the Beastly  (Half-Troll) Weaponsmith"    3000 210 115 6 7  8
call :addOwnerToStoreOwners "Delilah the Pure       (Half-Elf)   Temple"        25000 180 107 6 1 20
call :addOwnerToStoreOwners "Wizzle the Chaotic     (Halfling)   Alchemist"     10000 190 110 6 3  8
call :addOwnerToStoreOwners "Inglorian the Mage     (Human?)     Magic Shop"    32000 200 110 7 0 10

set "_index=0"
for %%A in (
    "Done^^^!"
    "Accepted^^^!"
    "Fine."
    "Agreed^^^!"
    "Ok."
    "Taken^^^!"
    "You drive a hard bargain, but taken."
    "You'll force me bankrupt, but it's a deal."
    "Sigh.  I'll take it."
    "My poor sick children may starve, but done^^^!"
    "Finally^^^!  I accept."
    "Robbed again."
    "A pleasure to do business with you^^^!"
    "My spouse will skin me, but accepted."
) do (
    set "speech_sale_accepted[!_index!]=%%~A"
    set /a _index+=1
)

set "_index=0"
for %%A in (
    "_A2 is my final offer; take it or leave it."
    "I'll give you no more than _A2."
    "My patience grows thin.  _A2 is final."
) do (
    set "speech_selling_haggle_final[!_index!]=%%~A"
    set /a _index+=1
)

set "_index=0"
for %%A in (
    "_A1 for such a fine item?  HA^^^!  No less than _A2."
    "_A1 is an insult^^^!  Try _A2 gold pieces."
    "_A1?^^^!?  You would rob my poor starving children?"
    "Why, I'll take no less than _A2 gold pieces."
    "Ha^^^!  No less than _A2 gold pieces."
    "Thou knave^^^!  No less than _A2 gold pieces."
    "_A1 is far too little, how about _A2?"
    "I paid more than _A1 for it myself, try _A2."
    "_A1?  Are you mad?^^^!?  How about _A2 gold pieces?"
    "As scrap this would bring _A1.  Try _A2 in gold."
    "May the fleas of 1000 Orcs molest you.  I want _A2."
    "My mother you can get for _A1, this costs _A2."
    "May your chickens grow lips.  I want _A2 in gold^^^!"
    "Sell this for such a pittance?  Give me _A2 gold."
    "May the Balrog find you tasty^^^!  _A2 gold pieces?"
    "Your mother was a Troll!  _A2 or I'll tell."
) do (
    set "speech_selling_haggle[!_index!]=%%~A"
    set /a _index+=1
)

set "_index=0"
for %%A in (
    "I'll pay no more than _A1; take it or leave it."
    "You'll get no more than _A1 from me."
    "_A1 and that's final."
) do (
    set "speech_buying_haggle_final[!_index!]=%%~A"
    set /a _index+=1
)

set "_index=0"
for %%A in (
    "_A2 for that piece of junk?  No more than _A1."
    "For _A2 I could own ten of those.  Try _A1."
    "_A2?  NEVER^^^!  _A1 is more like it."
    "Let's be reasonable. How about _A1 gold pieces?"
    "_A1 gold for that junk, no more."
    "_A1 gold pieces and be thankful for it^^^!"
    "_A1 gold pieces and not a copper more."
    "_A2 gold?  HA^^^!  _A1 is more like it."
    "Try about _A1 gold."
    "I wouldn't pay _A2 for your children, try _A1."
    "*CHOKE* For that^^^!?  Let's say _A1."
    "How about _A1?"
    "That looks war surplus^^^!  Say _A1 gold."
    "I'll buy it as scrap for _A1."
    "_A2 is too much, let us say _A1 gold."
) do (
    set "speech_buying_haggle[!_index!]=%%~A"
    set /a _index+=1
)

set "_index=0"
for %%A in (
    "ENOUGH^^^!  You have abused me once too often^^^!"
    "THAT DOES IT^^^!  You shall waste my time no more^^^!"
    "This is getting nowhere.  I'm going home^^^!"
    "BAH^^^!  No more shall you insult me^^^!"
    "Begone^^^!  I have had enough abuse for one day."
) do (
    set "speech_insulted_haggling_done[!_index!]=%%~A"
    set /a _index+=1
)

set "_index=0"
for %%A in (
    "Out of my place^^^!", "out... Out... OUT^^^!^^^!^^^!"
    "Come back tomorrow.", "Leave my place.  Begone!"
    "Come back when thou art richer."
) do (
    set "speech_get_out_of_my_store[!_index!]=%%~A"
    set /a _index+=1
)

set "_index=0"
for %%A in (
    "You will have to do better than that^^^!"
    "That's an insult^^^!"
    "Do you wish to do business or not?"
    "Hah^^^!  Try again."
    "Ridiculous!"
    "You've got to be kidding^^^!"
    "You'd better be kidding^^^!"
    "You try my patience."
    "I don't hear you."
    "Hmmm, nice weather we're having."
) do (
    set "speech_haggling_try_again[!_index!]=%%~A"
    set /a _index+=1
)

set "_index=0"
for %%A in (
    "I must have heard you wrong."
    "What was that?"
    "I'm sorry, say that again."
    "What did you say?"
    "Sorry, what was that again?"
) do (
    set "speech_sorry[!_index!]=%%~A"
    set /a _index+=1
)
exit /b

::------------------------------------------------------------------------------
:: Adds a store owner to the store_owners array
::
:: Arguments: %1 - The owner's name, race, and store
::            %2 - The most gold that the owner will charge for an item
::            %3 - Maximum price inflation factor
::            %4 - Minimum price inflation factor
::            %5 - How many times the player can haggle before being insulting
::            %6 - The store owner's race
::            %7 - The maximum number of times a player can insult the owner
::------------------------------------------------------------------------------
:addOwnerToStoreOwners
set "store_owners[%owner_count%].name=%~1"
set "store_owners[%owner_count%].max_cost=%~2"
set "store_owners[%owner_count%].max_inflate=%~3"
set "store_owners[%owner_count%].min_inflate=%~4"
set "store_owners[%owner_count%].haggles_per=%~5"
set "store_owners[%owner_count%].race=%~6"
set "store_owners[%owner_count%].max_insults=%~7"
set /a owner_count+=1
exit /b