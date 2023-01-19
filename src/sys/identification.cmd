@echo off
call %*
exit /b

::------------------------------------------------------------------------------
:: Returns a description of a map object based on the specified symbol
::
:: Arguments: %1 - The symbol to identify
::            %2 - The variable to store the description in
:: Returns:   None
::------------------------------------------------------------------------------
:objectDescription
if "%~1"==" " (
    set "%~2=  - An open pit."
) else if "%~1"=="!" (
    set "%~2=^^^! - A potion."
) else if "%~1"=="^"" (
    set "%~2=^^^" - An amulet, periapt, or necklace."
) else if "%~1"=="#" (
    set "%~2=# - A stone wall."
) else if "%~1"=="$" (
    set "%~2=$ - Treasure"
) else if "%~1"=="%%" (
    if "%config.options.highlight_seams%"=="false" (
        set "%~2=%% - Not used."
    ) else (
        set "%~2=%% - A magma or quartz vein."
    )
) else if "%~1"=="^&" (
    set "%~2=^^^& - Treasure chest."
) else if "%~1"=="'" (
    set "%~2=' - An open door."
) else if "%~1"=="(" (
    set "%~2=( - Soft armor."
) else if "%~1"==")" (
    set "%~2=) - A shield."
) else if "%~1"=="*" (
    set "%~2=* - Gems."
) else if "%~1"=="+" (
    set "%~2=+ - A closed door."
) else if "%~1"=="," (
    set "%~2=, - Foor or mushroom patch"
) else if "%~1"=="-" (
    set "%~2=- - A wand."
) else if "%~1"=="." (
    set "%~2=. - Floor."
) else if "%~1"=="/" (
    set "%~2=/ - A pole weapon."
) else if "%~1"=="1" (
    set "%~2=1 - Entrance to General Store."
) else if "%~1"=="2" (
    set "%~2=2 - Entrance to Armory."
) else if "%~1"=="3" (
    set "%~2=3 - Entrance to Weaponsmith."
) else if "%~1"=="4" (
    set "%~2=4 - Entrance to Temple."
) else if "%~1"=="5" (
    set "%~2=5 - Entrance to Alchemy Shop."
) else if "%~1"=="6" (
    set "%~2=6 - Entrance to Magic-User's Shop."
) else if "%~1"==":" (
    set "%~2=^: - Rubble."
) else if "%~1"==";" (
    set "%~2=; - A loose rock."
) else if "%~1"=="<" (
    set "%~2=^^^< - An up staircase."
) else if "%~1"=="=" (
    set "%~2=^= - A ring."
) else if "%~1"==">" (
    set "%~2=^^^> - A down staircase."
) else if "%~1"=="@" (
    set "%~2=@ - %py.misc.name%"
) else if "%~1"=="A" (
    set "%~2=A - Giant Ant Lion."
) else if "%~1"=="B" (
    set "%~2=B - The Balrog."
) else if "%~1"=="C" (
    set "%~2=C - Gelatinous Cube."
) else if "%~1"=="D" (
    set "%~2=D - An Ancient Dragon ^(Beware^)."
) else if "%~1"=="E" (
    set "%~2=E - Elemental."
) else if "%~1"=="F" (
    set "%~2=F - Giant Fly."
) else if "%~1"=="G" (
    set "%~2=G - Ghost."
) else if "%~1"=="H" (
    set "%~2=H - Hobgoblin."
) else if "%~1"=="J" (
    set "%~2=J - Jelly."
) else if "%~1"=="K" (
    set "%~2=K - Killer Beetle."
) else if "%~1"=="L" (
    set "%~2=L - Lich."
) else if "%~1"=="M" (
    set "%~2=M - Mummy."
) else if "%~1"=="O" (
    set "%~2=O - Ooze."
) else if "%~1"=="P" (
    set "%~2=P - Giant humanoid."
) else if "%~1"=="Q" (
    set "%~2=Q - Quylthulg ^(Pulsing Flesh Mound^)."
) else if "%~1"=="R" (
    set "%~2=R - Reptile."
) else if "%~1"=="S" (
    set "%~2=S - Giant Scorpion."
) else if "%~1"=="T" (
    set "%~2=T - Troll."
) else if "%~1"=="U" (
    set "%~2=U - Umber Hulk."
) else if "%~1"=="V" (
    set "%~2=V - Vampire."
) else if "%~1"=="W" (
    set "%~2=W - Wight or Wraith."
) else if "%~1"=="X" (
    set "%~2=X - Xorn."
) else if "%~1"=="Y" (
    set "%~2=Y - Yeti."
) else if "%~1"=="[" (
    set "%~2=[ - Hard armor."
) else if "%~1"=="\" (
    set "%~2=\ - A hafted weapon."
) else if "%~1"=="]" (
    set "%~2=] - Misc. armor."
) else if "%~1"=="^" (
    set "%~2=^ - A trap."
) else if "%~1"=="_" (
    set "%~2=_ - A staff."
) else if "%~1"=="a" (
    set "%~2=a - Giant Ant."
) else if "%~1"=="b" (
    set "%~2=b - Giant Bat."
) else if "%~1"=="c" (
    set "%~2=c - Giant Centipede."
) else if "%~1"=="d" (
    set "%~2=d - Dragon."
) else if "%~1"=="e" (
    set "%~2=e - Floating Eye."
) else if "%~1"=="f" (
    set "%~2=f - Giant Frog."
) else if "%~1"=="g" (
    set "%~2=g - Golem."
) else if "%~1"=="h" (
    set "%~2=h - Harpy."
) else if "%~1"=="i" (
    set "%~2=i - Icky Thing."
) else if "%~1"=="j" (
    set "%~2=j - Jackal."
) else if "%~1"=="k" (
    set "%~2=k - Kobold."
) else if "%~1"=="l" (
    set "%~2=l - Giant Louse."
) else if "%~1"=="m" (
    set "%~2=m - Mold."
) else if "%~1"=="n" (
    set "%~2=n - Naga."
) else if "%~1"=="o" (
    set "%~2=o - Orc or Ogre."
) else if "%~1"=="p" (
    set "%~2=p - Person ^(Humanoid^)."
) else if "%~1"=="q" (
    set "%~2=q - Quasit."
) else if "%~1"=="r" (
    set "%~2=r - Rodent."
) else if "%~1"=="s" (
    set "%~2=s - Skeleton."
) else if "%~1"=="t" (
    set "%~2=t - Giant Tick."
) else if "%~1"=="w" (
    set "%~2=w - Worm or Worm Mass."
) else if "%~1"=="y" (
    set "%~2=y - Yeek."
) else if "%~1"=="z" (
    set "%~2=z - Zombie."
) else if "%~1"=="{" (
    set "%~2={ - Arrow, bolt, or bullet."
) else if "%~1"=="^|" (
    set "%~2=^^^| - A sword or dagger."
) else if "%~1"=="}" (
    set "%~2=} - Bow, crossbow, or sling."
) else if "%~1"=="~" (
    set "%~2=^~ - Miscellaneous item."
) else (
    set "%~2=Not used."
)
exit /b

::------------------------------------------------------------------------------
:: Identifies a specified character
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:identifyGameObject
call ui_io.cmd :getCommand "Enter character to be identified :" itemId || exit /b
call :objectDescription !itemId! object_description
call ui_io.cmd :putStringClearToEOL object_description "0;0"
call recall.cmd :recallMonsterAttributes !itemId!
exit /b

::------------------------------------------------------------------------------
:: Initialize all potions, wands, staves, scrolls, etc.
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:magicInitializeItemNames
call game.cmd :seedSet %game.magic_seed%

for /L %%A in (3,1,%max_colors%) do (
    set /a id_rnd_max=max_color-3
    call rng.cmd :randomNumber !id_rnd_max!
    set /a id=!errorlevel!+2

    for %%B in ("!id!") do (
        set "color=!colors[%%A]!"
        set "colors[%%A]=!colors[%%B]!"
        set "colors[%%B]=!color!"
    )
)
call :scrambleArray woods
call :scrambleArray metals
call :scrambleArray rocks
call :scrambleArray amulets
call :scrambleArray mushrooms

for %%A in (0,1,44) do (
    call rng.cmd :randomNumber 2
    set /a k=!errorlevel!

    for /L %%I in (0,1,!k!) do (
        call rng.cmd :randomNumber 2
        set "s=!errorlevel!"
        for /L %%S in (!s!,-1,1) do (
            call rng.cmd :randomNumber 44
            for %%B in ("!errorlevel!") do (
                set "item_title=!item_title!!syllables[%%B]!"
            )
        )
        set /a i_cmp=k-1
        if !i! LSS !i_cmp! set "item_title=!item_title! "
    )
)
call game.cmd :seedResetToOldSeed
exit /b

::------------------------------------------------------------------------------
:: Rearranges the order of the elements of a specified array
::
:: Arguments: %1 - The name of the array to scramble
:: Returns:   None
::------------------------------------------------------------------------------
:scrambleArray
set /a max_num=!max_%~1!-1

for /L %%A in (0,1,!max_num!) do (
    call rng.cmd :randomNumber !max_num!
    set /a id=!errorlevel!-1
    for %%B in ("!id!") do (
        set "_%~1=!%~1[%%A]!"
        set "!%~1[%%A]!=!%~1[%%B]!"
        set "!%~1[%%B]!=!_%~1!"
    )
)
exit /b

::------------------------------------------------------------------------------
:: Returns the offset in memory of the object's position
::
:: Arguments: %1 - The category ID
::            %2 - The subcategory ID
:: Returns:   Where in the inventory the specific object is located
::------------------------------------------------------------------------------
:objectPositionOffset
if "%~1"=="%tv_amulet%" exit /b 0
if "%~1"=="%tv_ring%" exit /b 1
if "%~1"=="%tv_staff%" exit /b 2
if "%~1"=="%tv_wand%" exit /b 3
if "%~1"=="%tv_scroll1%" exit /b 4
if "%~1"=="%tv_scroll2%" exit /b 4
if "%~1"=="%tv_potion1%" exit /b 5
if "%~1"=="%tv_potion2%" exit /b 5
if "%~1"=="%tv_food%" (
    set /a "within_mushroom_tolerance=sub_category_id&(item_single_stack_min-1)"
    if !within_mushroom_tolerance! LSS !max_mushrooms! (
        exit /b 6
    ) else (
        exit /b -1
    )
)
exit /b -1

:clearObjectTriedFlag
exit /b

:setObjectTriedFlag
exit /b

:isObjectKnown
exit /b

:itemSetAsIdentified
exit /b

:unsample
exit /b

:spellItemIdentifyAndRemoveRandomInscription
exit /b

:spellItemIdentified
exit /b

:spellItemRemoveIdentification
exit /b

:itemIdentificationClearEmpty
exit /b

:itemIdentifyAsStoreBought
exit /b

:itemStoreBought
exit /b

:itemSetColorlessAsIdentified
exit /b

:itemSetAsTried
exit /b

:itemIdentify
exit /b

:itemRemoveMagicNaming
exit /b

:bowDamageValue
exit /b

:itemDescription
exit /b

:itemChargesRemainingDescription
exit /b

:itemTypeRemainingCountDescription
exit /b

:itemInscribe
exit /b

:itemAppendToInscription
exit /b

:itemReplaceInscription
exit /b

:objectBlockedByMonster
exit /b
