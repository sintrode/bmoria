@echo off
call %*
exit /b

::------------------------------------------------------------------------------
:: If there are too many objects on the current floor, delete some
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:compactObjects
set "counter=0"
set "current_distance=66"

:compactObjectsLoop
for /L %%Y in (0,1,%dg.height%) do (
    for /L %%X in (0,1,%dg.width%) do (
        for /f %%T in ("!dg.floor[%%Y][%%X].treasure_id!") do (
            if not "%%~T"=="0" (
                call dungeon.cmd :coordDistanceBetween "%%Y;%%X" "%py.pos.y%;%py.pos.x%"
                if !errorlevel! GTR !current_distance! (
                    set "chance=10"
                    if "!game.treasure.list[%%~T].category_id!"=="%tv_vis_trap%" set "chance=15"
                    if "!game.treasure.list[%%~T].category_id!"=="%tv_invis_trap%" set "chance=5"
                    if "!game.treasure.list[%%~T].category_id!"=="%tv_rubble%" set "chance=5"
                    if "!game.treasure.list[%%~T].category_id!"=="%tv_open_door%" set "chance=5"
                    if "!game.treasure.list[%%~T].category_id!"=="%tv_closed_door%" set "chance=5"
                    if "!game.treasure.list[%%~T].category_id!"=="%tv_up_stair%" set "chance=0"
                    if "!game.treasure.list[%%~T].category_id!"=="%tv_down_stair%" set "chance=0"
                    if "!game.treasure.list[%%~T].category_id!"=="%tv_store_door%" set "chance=0"
                    if "!game.treasure.list[%%~T].category_id!"=="%tv_secret_door%" set "chance=3"

                    call rng.rnd :randomNumber 100
                    if !errorlevel! LEQ !chance! (
                        call dungeon.cmd :dungeonDeleteObject "%%Y;%%X"
                        set /a counter+=1
                    )
                )
            )
        )
    )
)
if "!counter!"=="0" set /a current_distance-=6
if !counter! LEQ 0 goto :compactObjectsLoop

if !current_distance! LSS 66 call ui.cmd :dungeonDrawPanel
exit /b

::------------------------------------------------------------------------------
:: Returns a pointer to the next free game treasure ID
::
:: Arguments: None
:: Returns:   game.treasure.current_id + 1
::------------------------------------------------------------------------------
:popt
if "%game.treasure.current_id%"=="%level_max_objects%" (
    call :compactObjects
)
set /a next_id=%game.treasure.current_id%+1
exit /b !next_id!

::------------------------------------------------------------------------------
:: Pushes a record back onto the free space list
::
:: Arguments: %1 - The ID of the treasure to push onto the list
:: Returns:   None
::------------------------------------------------------------------------------
:pusht
set "treasure_id=%~1"
set /a dec_current_id=%game.treasure.current_id%-1

:: Look at what they have to do to mimic an object
if not "%treasure_id%"=="%dec_current_id%" (
    for %%A in (id special_name_id inscription flags category_id sprite misc_use
                cost sub_category_id items_count weight to_hit to_damage ac
                to_ac damage depth_first_found identification) do (
        set "game.treasure.list[%treasure_id%].%%A=!game.treasure.list[%dec_current_id%].%%A"
    )

    for /L %%Y in (0,1,%dg.height%) do (
        for /L %%X in (0,1,%dg.width%) do (
            if "!dg.floor[%%Y][%%X].treasure_id!"=="%dec_current_id%" (
                set "dg.floor[%%Y][%%X].treasure_id=%treasure_id%"
            )
        )
    )
)
set /a game.treasure.current_id-=1

call inventory.cmd :inventoryItemCopyTo "%config.dungeon.objects.obj_nothing%" game.treasure.list[%game.treasure.current_id%]
exit /b

::------------------------------------------------------------------------------
:: Determine if a specified item is too large to fit in a chest
::
:: Arguments: %1 - The item to validate
:: Returns:   0 if the item fits in a chest
::            1 otherwise
::------------------------------------------------------------------------------
:itemBiggerThanChest
if "!%~1.category_id!"=="%tv_chest%" exit /b 0
if "!%~1.category_id!"=="%tv_bow%" exit /b 0
if "!%~1.category_id!"=="%tv_polearm%" exit /b 0
if "!%~1.category_id!"=="%tv_hard_armor%" exit /b 0
if "!%~1.category_id!"=="%tv_soft_armor%" exit /b 0
if "!%~1.category_id!"=="%tv_staff%" exit /b 0

if !%~1.weight! GTR 150 (
    set "too_large=0"
) else (
    set "too_large=1"
)
if "!%~1.category_id!"=="%tv_hafted%" exit /b %too_large%
if "!%~1.category_id!"=="%tv_sword%" exit /b %too_large%
if "!%~1.category_id!"=="%tv_digging%" exit /b %too_large%
exit /b 1

::------------------------------------------------------------------------------
:: Returns the array index of a random object
::
:: Arguments: %1 - The floor level the item is being generated on
::            %2 - Whether or not the item must be small
:: Returns:   The index of the object in game_objects[sorted_objects]
::------------------------------------------------------------------------------
:itemGetRandomObjectId
set "level=%~1"
set "must_be_small=%~2"

if "%level%"=="0" (
    call rng.cmd :randomNumber !treasure_levels[0]!
    set /a object_id=!errorlevel!-1
    exit /b !object_id!
)

if !level! GEQ %treasure_max_levels% (
    set "level=%treasure_max_levels%"
) else (
    call rng.cmd :randomNumber %config.treasure.treasure_chance_of_great_item%
    if "!errorlevel!"=="1" (
        call rng.cmd :randomNumber %treasure_max_levels%
        set "rnd_max_level=!errorlevel!"
        set /a level=!level! * %treasure_max_levels% / !rnd_max_level! + 1

        if !level! GTR %treasure_max_levels% set "level=%treasure_max_levels%"
    )
)

:makeRandomItem
call rng.cmd :randomNumber 2
if "!errorlevel!"=="1" (
    call rng.cmd :randomNumber !treasure_levels[%level%]!
    set /a object_id=!errorlevel!-1
) else (
    REM Choose three objects and pick the highest level
    call rng.cmd :randomNumber !treasure_levels[%level%]!
    set /a object_id=!errorlevel!-1

    call rng.cmd :randomNumber !treasure_levels[%level%]!
    set /a j=!errorlevel!-1
    if !object_id! LSS !j! set "object_id=!j!"

    call rng.cmd :randomNumber !treasure_levels[%level%]!
    set /a j=!errorlevel!-1
    if !object_id! LSS !j! set "object_id=!j!"

    for /f "delims=" %%A in ("!object_id!") do (
        for /f "delims=" %%B in ("!sorted_objects[%%~A]!") do (
            set "found_level=!game_objects[%%~B].depth_first_found!"
        )
    )

    if "!found_level!"=="0" (
        call rng.cmd :randomNumber !treasure_levels[0]!
        set /a object_id=!errorlevel!-1
    ) else (
        set /a dec_found_level=!found_level!-1
        for /f "tokens=1,2" %%A in ("!found_level! !dec_found_level!") do (
            set /a "delta_tlevel=(!treasure_levels[%%~A]!-!treasure_levels[%%~B]!)-1+!treasure_levels[%%~B]!"
        )
        call rng.cmd :randomNumber !delta_tlevel!
        set "object_id=!errorlevel!"
    )
)
if "!must_be_small!"=="true" (
    for /f "delims=" %%A in ("!object_id!") do (
        for /f "delims=" %%B in ("!sorted_objects[%%~A]!") do (
            call :itemBiggerThanChest game_objects[%%~B]
            if "!errorlevel!"=="0" goto :makeRandomItem
        )
    )
)
exit /b !object_id!