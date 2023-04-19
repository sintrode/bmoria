call %*
exit /b

::------------------------------------------------------------------------------
:: Shrinks the dungeon to a single screen
:: TODO: Determine if the pipes need more carets
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonDisplayMap
call ui_io.cmd :terminalSaveScreen
call ui_io.cmd :clearScreen

for /L %%A in (0,1,255) do set "priority[%%A]=0"
set "priority[60]=5"
set "priority[62]=5"
set "priority[64]=10"
set "priority[35]=-5"
set "priority[46]=-10"
set "priority[92]=-3"
set "priority[32]=-15"

set /a panel_width=%max_width%/%ratio%
set /a panel_height=%max_height%/%ratio%
set /a panel_width_dec=%panel_width%-1, panel_width_inc=%panel_width%+1
set /a panel_height_dec=%panel_height%-1, panel_height_inc=%panel_height%+1

set "map="
call ui_io.cmd :addChar "+" "0;0"
call ui_io.cmd :addChar "+" "0;%panel_width_inc"
for /L %%A in (0,1,%panel_width_dec%) do (
    set /a a_inc=%%A+1
    call ui_io.cmd :addChar "-" "0;!a_inc!"
    call ui_io.cmd :addChar "-" "%panel_height_inc%;!a_inc!"
)
for /L %%A in (0,1,%panel_height_dec%) do (
    set /a a_inc=%%A+1
    call ui_io.cmd :addChar "^|" "!a_inc!;0"
    call ui_io.cmd :addChar "^|" "!a_inc!;%panel_width_inc%"
)
call ui_io.cmd :addChar "+" "%panel_height_inc%;0"
call ui_io.cmd :addChar "+" "%panel_height_inc%;%panel_width_inc%"
call ui_io.cmd :putString "Press any key to continue." "23;23"

set "player_y=0"
set "player_x=0"
set "line=-1"

set /a max_height_dec=%max_height%-1, max_width_dec=%max_width%-1
for /L %%Y in (0,1,%max_height_dec%) do (
    set /a row=%%Y / %ratio%
    if not "!row!"=="!line!" (
        if !line! GEQ 0 (
            set /a line_inc=!line!+1
            call ui_io.cmd :putString "^|!map!^|" "!line_inc!;0"
        )
        for /L %%J in (0,1,%panel_width_dec%) do set "map[%%J]= "
        set "line=!row!"
    )

    for /L %%X in (0,1,%max_width_dec%) do (
        set /a col=%%X / %ratio%
        set "char_coords=%%Y;%%X"
        call :caveGetTileSymbol "char_coords" "cave_char"

        for /f "delims=" %%A in ("!col!") do (
            call :getAsciiFromChar "!map[%%A]!"
            set "map_ascii=!errorlevel!"
            call :getAsciiFromChar "!cave_char!"
            set "cave_char_ascii=!errorlevel!"
            for /f "tokens=-3" %%B in ("!map_ascii! !cave_char_ascii!") do (
                if !priority[%%B]! LSS !priority[%%C]! (
                    set "map[%%A]=!cave_char!"
                )
            )
            if "!map[%%A]!"=="@" (
                set /a player_x=!col!+1, player_y=!row!+1
            )
        )
    )
)

set /a line_inc=!line!+1
if !line! GEQ 0 call ui_io.cmd :putString "^|!map!^|" "!line_inc!;0"

call ui_io.cmd :moveCursor "!player_y!;!player_x!"
call ui_io.cmd :getKeyInput
call ui_io.cmd :terminalRestoreScreen
exit /b

::------------------------------------------------------------------------------
:: Checks if a specified set of coordinates is within the map bounds
::
:: Arguments: %1 - The name of the variable containing target coordinates
:: Returns:   0 if the target coordinates are on the map
::            1 if the target coordinates are not on the map
::------------------------------------------------------------------------------
:coordInBounds
set "y=false"
set "x=false"
set /a height_dec=%dg.height%-1, width_dec=%dg.width%-1

for /f "tokens=1,2 delims=;" %%A in ("!%~1!") do (
    if %%A GTR 0 if %%A LSS %height_dec% set "y=true"
    if %%B GTR 0 if %%B LSS %width_dec% set "x=true"
)
if "!x!"=="true" if "!y!"=="true" exit /b 0
exit /b 1

::------------------------------------------------------------------------------
:: Calculate a distance between two points
::
:: Arguments: %1 - The name of the variable containing the start coordinates
::            %2 - The name of the variable containing the end coordinates
:: Returns:   The number of tiles between the two coordinates
::------------------------------------------------------------------------------
:coordDistanceBetween
for /f "tokens=1-4 delims=; " %%A in ("!%~1! !%~2!") do (
    set /a dy=%%A-%%C
    if !dy! LSS 0 (
        set /a dy*=-1
    )

    set /a dx=%%B-%%D
    if !dx! LSS 0 (
        set /a dx*=-1
    )

    set /a "a=(!dy! + !dx!) << 1"
    if !dy! GTR !dx! (
        set "b=!dx!"
    ) else (
        set "b=!dy!"
    )

    set /a "distance=((!a! - !b!) >> 1)"
)
exit /b !distance!

::------------------------------------------------------------------------------
:: Checks adjacent tiles for a wall. Coordinates are assumed to be in bounds.
::
:: Arguments: %1 - The name of the variable containing the target coordinates
:: Returns:   The number of walls touching the specified coordinates
::------------------------------------------------------------------------------
:coordWallsNextTo
set "walls=0"
call helpers.cmd :expandCoordName "%~1"

for /f "tokens=1-6" %%A in ("!%~1.x! !%~1.x_dec! !%~1.x_inc! !%~1.y! !%~1.y_dec! !%~1.y_inc!") do (
    if !dg.floor[%%E][%%A]! GEQ %min_cave_wall% set /a walls+=1
    if !dg.floor[%%F][%%A]! GEQ %min_cave_wall% set /a walls+=1
    if !dg.floor[%%D][%%B]! GEQ %min_cave_wall% set /a walls+=1
    if !dg.floor[%%D][%%C]! GEQ %min_cave_wall% set /a walls+=1
)
exit /b !walls!

::------------------------------------------------------------------------------
:: Checks all adjacent spots for corridors. Coordinates are assumed to be
:: within bounds.
::
:: Arguments: %1 - The name of the variable containing the coordinates to check
:: Returns:   The number of corridor walls touching the specified coordinates
::------------------------------------------------------------------------------
:coordCorridorWallsNextTo
set "walls=0"
call helpers.cmd :expandCoordName "%~1"
for /L %%Y in (!%~1.y_dec!,1,!%~1.y_inc!) do (
    for /L %%X in (!%~1.x_dec!,1,!%~1.x_inc!) do (
        set "tile_id=!dg.floor[%%Y][%%X].feature_id!"
        set "treasure_id=!dg.floor[%%Y][%%X].treasure_id!"
    )

    if "!tile_id!"=="%tile_corr_floor%" (
        if "!treasure_id!"=="0" (
            set /a walls+=1
        )
        for /f "delims=" %%A in ("!treasure_id!") do (
            if !game.treasure.list[%%A].category_id! LSS %tv_min_doors% (
                set /a walls+=1
            )
        )
    )
)
exit /b !walls!

::------------------------------------------------------------------------------
:: Returns the symbol at a specified set of coordinates
:: Fun fact: the fact that this subroutine exists at all instead of using
::           ncurses' mvgetch is the reason that the port is possible because
::           that's the one thing that I can't emulate with VT100 sequences
::
:: Arguments: %1 - The name of the variable containing the coordinates to check
::            %2 - The variable to store the character in
:: Returns:   None
::------------------------------------------------------------------------------
:caveGetTileSymbol
for /f "tokens=1,2 delims=;" %%A in ("!%~1!") do set "tile=dg.floor[%%A][%%B]"

set "%~2=%%"

if "!%tile%.creature_id!"=="1" (
    if "%py.running_tracker%"=="0" set "%~2=@"
    if "%config.options.run_print_self%"=="true" set "%~2=@"
)

set /a "is_blind=%py.flags.status% & %config.player.status.py.blind%"
if not "%is_blind%"=="0" set "%~2= "

if %py.flags.image% GTR 0 (
    call rng.cmd :randomNumber 12
    if "!errorlevel!"=="1" (
        call rng.cmd :randomNumber 95
        set /a hallucination=!errorlevel!+31
        cmd /c exit /b !hallucination!
        set "%~2=!=ExitCodeAscii!"
    )
)

set "tile.creature_id=!%tile%.creature_id!"
set "monster_id=!monsters[%tile.creature_id%].creature_id!"
if %tile.creature_id% GTR 1 (
    if "!monsters[%tile.creature_id%].lit!"=="true" (
        set "%~2=!creatures_list[%monster_id%].sprite!"
    )
)

if "!%tile%.permanent_light!"=="false" (
    if "!%tile%.temporary_light!"=="false" (
        if "!%tile%.field_mark!"=="false" (
            set "%~2= "
        )
    )
)

set "tile.treasure_id=!%tile%.treasure_id!"
if not "%tile.treasure_id%"=="0" (
    if not "!game.treasure.list[%tile.treasure_id%].category_id!"=="%tv_invis_trap" (
        set "%~2=!game.treasure.list[%tile.treasure_id%].sprite!"
    )
)

if !%tile%.feature_id! LEQ %max_cave_floor% set "%~2=."

if "!%tile%.feature_id!"=="%tile_granite_wall%" set "%~2=#"
if "!%tile%.feature_id!"=="%tile_boundary_wall%" set "%~2=#"
if "%config.options.highlight_seams%"=="false" set "%~2=#"
exit /b

::------------------------------------------------------------------------------
:: Tests a spot for light or a field mark
::
:: Arguments: %1 - The name of the variable containing coordinates to test
:: Returns:   0 if the coordinates are lit
::            1 if the coordinates are dark
::------------------------------------------------------------------------------
:caveTileVisible
for /f "tokens=1,2 delims=;" %%A in ("!%~1!") do (
    if "!dg.floor[%%A][%%B].permanent_light!"=="true" exit /b 0
    if "!dg.floor[%%A][%%B].temporary_light!"=="true" exit /b 0
    if "!dg.floor[%%A][%%B].field_mark!"=="true" exit /b 0
)
exit /b 1

::------------------------------------------------------------------------------
:: Places a particular trap at specified coordinates
::
:: Arguments: %1 - The name of the variable containing trap coordinates
::            %2 - The type of trap to place
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonSetTrap
call game_objects.cmd :popt
set "free_treasure_id=%errorlevel%"
for /f "tokens=1,2 delims=;" %%A in ("!%~1!") do (
    set "dg.floor[%%A][%%B].treasure_id=%free_treasure_id%"
)
set /a trap_value=%config.dungeon.objects.obj_trap_list% + %~2
call inventory.cmd :inventoryItemCopyTo %trap_value% "game.treasure.list[%free_treasure_id%]"
exit /b

::------------------------------------------------------------------------------
:: Change a trap (or secret door) from invisible to visible
::
:: Arguments: %1 - The name of the variable containing trap coordinates
:: Returns:   None
::------------------------------------------------------------------------------
:trapChangeVisibility
for /f "tokens=1,2 delims=;" %%A in ("!%~1!") do (
    set "treasure_id=!dg.floor[%%A][%%B].treasure_id!"
)
set "item=game.treasure.list[%treasure_id%]"
if "!%item%.category_id!"=="%tv_invis_trap%" (
    set "%item%.category_id=%tv_vis_trap%"
    call :dungeonLiteSpot %1
    exit /b
)

if "!%item%.category_id!"=="%tv_secret_door%" (
    set "%item%.id=%config.dungeon.objects.obj_closed_door%"
    set "%item%.category_id=!game_objects[%config.dungeon.objects.obj_closed_door%].category_id!"
    set "%item%.sprite=!game_objects[%config.dungeon.objects.obj_closed_door%].sprite!"
    call :dungeonLiteSpot %1
    exit /b
)
exit /b

::------------------------------------------------------------------------------
:: Place rubble at specified coordinates
::
:: Arguments: %1 - The name of the variable containing rubble coordinates
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonPlaceRubble
call game_objects.cmd :popt
set "free_treasure_id=%errorlevel%"

for /f "tokens=1,2 delims=;" %%A in ("!%~1!") do (
    set "dg.floor[%%B][%%A].treasure_id=%free_treasure_id%"
    set "dg.floor[%%B][%%A].feature_id=%tile_blocked_floor%"
)

call inventory.cmd :inventoryItemCopyTo %config.dungeon.objects.obj_rubble% "game.treasure.list[%free_treasure_id%]"
exit /b

::------------------------------------------------------------------------------
:: Place a treasure at specified coordinates
::
:: Arguments: %1 - The name of the variable containing treasure coordinates
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonPlaceGold
call game_objects.cmd :popt
set "free_treasure_id=%errorlevel%"

set /a level_2inc=%dg.current_level%+2
call rng.cmd :randomNumber %level_2inc%
set /a gold_type_id=((!errorlevel! + 2) / 2) - 1
set "level_2inc="

call rng.cmd :randomNumber %config.treasure.treasure_chance_of_great_item%
if "!errorlevel!"=="1" (
    set /a level_inc=%dg.current_level%+1
    call rng.cmd :randomNumber !level_inc!
    set /a gold_type_id+=!errorlevel!
    set "level_inc="
)

if %gold_type_id% GEQ %config.dungeon.objects.max_gold_types% (
    set /a gold_type_id=%config.dungeon.objects.max_gold_types%-1
)

for /f "tokens=1,2 delims=;" %%A in ("!%~1!") do (
    set "dg.floor[%%A][%%B].treasure_id=%free_treasure_id%"
    set /a gold_value=%config.dungeon.objects.obj_gold_list%+%gold_type_id%
    call inventory.cmd :inventoryItemCopyTo !gold_value! "game.treasure.list[%free_treasure_id%]"
    if "!dg.floor[%%A][%%B].creature_id!"=="1" (
        call ui_io.cmd :printMessage "You feel something roll beneath your feet."
    )
)
exit /b

::------------------------------------------------------------------------------
:: Places an object at specified coordinates
::
:: Arguments: %1 - The name of the variable containing coordinates
::            %2 - "true" if the object must be small, "false" otherwise
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonPlaceRandomObjectAt
call game_objects.cmd :popt
set "free_treasure_id=%errorlevel%"

for /f "tokens=1,2 delims=;" %%A in ("!%~1!") do (
    set "dg.floor[%%A][%%B].treasure_id=%free_treasure_id%"
)
call game_objects.cmd :itemGetRandomObjectId %dg.current_level% "%~2"
set "object_id=!errorlevel!"
call inventory.cmd :inventoryItemCopyTo !sorted_objects[%object_id%]! "game.treasure.list[%free_treasure_id%]"
call treasure.cmd :magicTreasureMagicalAbility %free_treasure_id% %dg.current_level%

for /f "tokens=1,2 delims=;" %%A in ("!%~1!") do (
    if "!dg.floor[%%A][%%B].creature_id!"=="1" (
        call ui_io.cmd :printMessage "You feel something roll beneath your feet."
    )
)
exit /b

::------------------------------------------------------------------------------
:: Allocates an object for tunnels and rooms
::
:: Arguments: %1 - The name of the function to call
::            %2 - The type of object to place
::            %3 - The number of objects to allocate
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonAllocateAndPlaceObject
for /L %%A in (1,1,%~3) do (
    call :dungeonAllocateAndPlaceObjectSetCoordinates "%~1" "%~2"

    if "%~2"=="1" (
        call rng.cmd :randomNumber %config.dungeon.objects.max_traps%
        set /a trap_value=!errorlevel!-1
        call :dungeonSetTrap %1 !trap_value!
    ) else if "%~2"=="3" (
        call :dungeonPlaceRubble %1
    ) else if "%~2"=="4" (
        call :dungeonPlaceGold %1
    ) else if "%~2"=="5" (
        call :dungeonPlaceRandomObjectAt %1 "false"
    )
)
exit /b

:dungeonAllocateAndPlaceObjectSetCoordinates
call rng.cmd :randomNumber %dg.height%
set /a coord.y=!errorlevel!-1
call rng.cmd :randomNumber %dg.width%
set /a coord.x=!errorlevel!-1

call %~1 !dg.floor[%coord.y%][%coord.x%].feature_id! || goto :dungeonAllocateAndPlaceObjectSetCoordinates
if not "!dg.floor[%coord.y%][%coord.x%].treasure_id!"=="0" goto :dungeonAllocateAndPlaceObjectSetCoordinates
if "%coord.y%"=="%py.pos.y%" if "%coord.x%"=="%py.pos.x%" goto :dungeonAllocateAndPlaceObjectSetCoordinates
exit /b

::------------------------------------------------------------------------------
:: Creates objects near the coordinates given
::
:: Arguments: %1 - The coordinates to place the item near
::            %2 - The number of tries before the subroutine gives up
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonPlaceRandomObjectNear
for /f "tokens=1,2 delims=;" %%A in ("%~1") do (
    set "coord.y=%%A"
    set "coord.x=%%B"
)
set "tries=%~2"

:dungeonPlaceRandomObjectNearDoLoop
for /L %%A in (0,1,10) do (
    call rng.cmd :randomNumber 5
    set /a at_coord.y=%coord.y%-3+!errorlevel!
    call rng.cmd :randomNumber 7
    set /a at_coord.x=%coord.x%-4+!errorlevel!
    set "at_coord=!at_coord.y!;!at_coord.x!"

    for /f "tokens=1,2" %%X in ("!at.x! !at.y!") do (
        call :coordInBounds !at_coord!
        if "!errorlevel!"=="0" (
            if !dg.floor[%%Y][%%X].feature_id! LEQ %max_cave_floor% (
                if "!dg.floor[%%Y][%%X].treasure_id!"=="0" (
                    call rng.cmd :randomNumber 100
                    if !errorlevel! LSS 75 (
                        call :dungeonPlaceRandomObjectAt "!at_coord!" "false"
                    ) else (
                        call :dungeonPlaceGold "!at_coord!"
                    )
                    goto :dungeonPlaceRandomObjectNearBreakFor
                )
            )
        )
    )
)
:dungeonPlaceRandomObjectNearBreakFor
set /a tries-=1
if not "!tries!"=="0" goto :dungeonPlaceRandomObjectNearDoLoop
exit /b

::------------------------------------------------------------------------------
:: Teleports a creature to another tile
::
:: Arguments: %1 - The name of the variable containing the original location
::            %2 - The name of the variable containing the new location
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonMoveCreatureRecord
for /f "tokens=1-4 delims=; " %%A in ("!%~1! !%~2!") do (
    set /a "from.y=%%A", "from.x=%%B", "to.y=%%C", "to.x=%%D"
)

set "id=!dg.floor[%from.y%][%from.x%].creature_id!"
set "dg.floor[%from.y%][%from.x%].creature_id=0"
set "dg.floor[%to.y%][%to.x%].creature_id=!id!"
exit /b

::------------------------------------------------------------------------------
:: Lights up a room to make it appear
::
:: Arguments: %1 - The name of the variable containing the coordinates to light
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonLightRoom
set /a height_middle=%screen_height% / 2
set /a width_middle=%screen_width% / 2
for /f "tokens=1,2 delims=;" %%A in ("!%~1!") do (
    set /a top=(%%A / %height_middle%) * %height_middle%
    set /a left=(%%B / %width_middle%) * %width_middle%
    set /a bottom=!top!+%height_middle%-1
    set /a right=!left!+%width_middle%-1
)

for /L %%Y in (!top!,1,!bottom!) do (
    for /L %%X in (!left!,1,!right!) do (
        if "!dg.floor[%%Y][%%X].perma_lit_room!"=="true" (
            if "!dg.floor[%%Y][%%X].permanent_light!"=="false" (
                set "dg.floor[%%Y][%%X].permanent_light=true"

                if "!dg.floor[%%Y][%%X].feature_id!"=="%tile_dark_floor%" (
                    set "dg.floor[%%Y][%%X].feature_id=%tile_light_floor%"
                )
                if "!dg.floor[%%Y][%%X].field_mark!"=="false" (
                    if not "!dg.floor[%%Y][%%X].treasure_id!"=="0" (
                        for /f "delims=" %%A in ("!dg.floor[%%Y][%%X].treasure_id!") do (
                            set "treasure_id=!game.treasure.list[%%A].category_id!"
                        )
                        if !treasure_id! GEQ %tv_min_visible% (
                            if !treasure_id! LEQ %tv_max_visible% (
                                set "dg.floor[%%Y][%%X].field_mark=true"
                            )
                        )
                    )
                )

                set "location=%%Y;%%X"
                call :caveGetTileSymbol "location" c
                call ui_io.cmd :panelPutTile "!c!" "!location!"
            )
        )
    )
)
exit /b

::------------------------------------------------------------------------------
:: Lights up a given location
::
:: Arguments: %1 - The name of the variable containing the coordinates to light
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonLiteSpot
call ui.cmd :coordInsidePanel "!%~1!" || exit /b

call :caveGetTileSymbol %1 c
call ui_io.cmd :panelPutTile "!c!" %1
exit /b

::------------------------------------------------------------------------------
:: When FIND_FLAG is set, only light permanent features
::
:: Arguments: %1 - The name of the variable containing the start coordinates
::            %2 - The name of the variable containing the end coordinates
:: Returns:   None
::------------------------------------------------------------------------------
:sub1MoveLight
call helpers.cmd :expandCoordName "%~1"
call helpers.cmd :expandCoordName "%~2"
if "%py.temporary_light_only%"=="true" (
    for /L %%Y in (!%~1.y_dec!,1,!%~1.y_inc!) do (
        for /L %%X in (!%~1.x_dec!,1,!%~1.x_inc!) do (
            set "dg.floor[%%Y][%%X].temporary_light=false"
        )
    )
    if not "%py.running_tracker%"=="0" (
        if "%config.options.run_print_self%"=="false" (
            set "py.temporary_light_only=false"
        )
    )
) else (
    if "%py.running_tracker%"=="0" set "py.temporary_light_only=true"
    if "%config.options.run_print_self%"=="true" set "py.temporary_light_only=true"
)

for /L %%Y in (!%~2.y_dec!,1,!%~2.y_inc!) do (
    for /L %%X in (!%~2.x_dec!,1,!%~2.x_inc!) do (
        if "%py.temporary_light_only%"=="true" (
            set "dg.floor[%%Y][%%X].temporary_light=true"
        )

        if !dg.floor[%%Y][%%X].feature_id! GEQ %min_cave_wall% (
            set "dg.floor[%%Y][%%X].permanent_light=true"
        ) else (
            if "!dg.floor[%%Y][%%X].field_mark!"=="false" (
                if not "!dg.floor[%%Y][%%X].treasure_id!"=="0" (
                    for /f "delims=" %%A in ("!dg.floor[%%Y][%%X].treasure_id!") do (
                        set "tval=!game.treasure.list[%%A].category_id!"
                    )

                    if !tval! GEQ %tv_min_visible% (
                        if !tval! LEQ %tv_max_visible% (
                            set "dg.floor[%%Y][%%X].field_mark=true"
                        )
                    )
                )
            )
        )
    )
)

if !%~1.y! LSS !%~2.y! (
    set "top=!%~1.y_dec!"
    set "bottom=!%~1.y_inc!"
) else (
    set "top=!%~2.y_dec!"
    set "bottom=!%~2.y_inc!"
)
if !%~1.x! LSS !%~2.x! (
    set "left=!%~1.x_dec!"
    set "right=!%~1.x_inc!"
) else (
    set "left=!%~2.x_dec!"
    set "right=!%~2.x_inc!"
)

for /L %%Y in (!top!,1,!bottom!) do (
    for /L %%X in (!left!,1,!right!) do (
        set "coord=%%Y;%%X"
        call :caveGetTileSymbol "coord" c
        call ui_io.cmd :panelPutTile "!c!" "!coord!"
    )
)
exit /b

::------------------------------------------------------------------------------
:: When blinded, only move the player symbol
::
:: Arguments: %1 - The name of the variable containing the start coordinates
::            %2 - The name of the variable containing the end coordinates
:: Returns:   None
::------------------------------------------------------------------------------
:sub3MoveLight
call helpers.cmd :expandCoordName "%~1"
call helpers.cmd :expandCoordName "%~2"
if "%py.temporary_light_only%"=="true" (
    for /L %%Y in (!%~1.y_dec!,1,!%~1.y_inc!) do (
        for /L %%X in (!%~1.x_dec!,1,!%~1.x_inc!) do (
            set "dg.floor[%%Y][%%X].temporary_light=false"
            set "coord=%%Y;%%X"
            call :caveGetTileSymbol "coord" c
            call ui_io.cmd :panelPutTile "!c!" "!coord!"
        )
    )
    set "py.temporary_light_only=false"
) else (
    if "%py.running_tracker%"=="0" (
        call :caveGetTileSymbol "%~1" c
        call ui_io.cmd :panelPutTile "!c!" "!%~1!"
    )
    if "%config.options.run_print_self%"=="true" (
        call :caveGetTileSymbol "%~1" c
        call ui_io.cmd :panelPutTile "!c!" "!%~1!"
    )
)
if "%py.running_tracker%"=="0" (
    call ui_io.cmd :panelPutTile "@" "!%~2!"
)
if "%config.options.run_print_self%"=="true" (
    call ui_io.cmd :panelPutTile "@" "!%~2!"
)
exit /b

::------------------------------------------------------------------------------
:: Wrapper for moving the character's light around the screen
::
:: Arguments: %1 - The name of the variable containing the start coordinates
::            %2 - The name of the variable containing the end coordinates
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonMoveCharacterLight
if %py.flags.blind% GTR 0 (
    call :sub3MoveLight %*
) else if "%py.carrying_light%"=="false" (
    call :sub3MoveLight %*
) else (
    call :sub1MoveLight %*
)
exit /b

::------------------------------------------------------------------------------
:: Deletes a monster entry from the level
::
:: Arguments: %1 - The ID of the monster to remove
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonDeleteMonster
call :dungeonRemoveMonsterFromLevel "%~1"
call :dungeonDeleteMonsterRecord "%~1"
exit /b

::------------------------------------------------------------------------------
:: Ensure that the monster has no HP before removing its ID from the level
::
:: Arguments: %1 - the ID of the monster to remove
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonRemoveMonsterFromLevel
set "monster=monsters[%~1]"

set "%monster%.hp=-1"
for /f "tokens=1,2 delims= " %%X in ("!%monster%.pos.x! !%monster%.pos.y!") do (
    set "dg.floor[%%~Y][%%~X].creature_id=0"

    if "!%monster%.lit!"=="true" (
        set "monster_coord=%%Y;%%X"
        call :dungeonLiteSpot "monster_coord"
    )

    if !monster_multiply_total! GTR 0 (
        set /a monster_multiply_total-=1
    )
)
exit /b

::------------------------------------------------------------------------------
:: Deletes the monster record from the monsters list
::
:: Arguments: %1 - The ID of the monster to remove
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonDeleteMonsterRecord
set /a last_id=!next_free_monster_id!-1
set "monster.pos.x=!monsters[%last_id%].pos.x!"
set "monster.pos.y=!monsters[%last_id%].pos.y!"

if not "%~1"=="%last_id%" (
    set "dg.floor[%monster.pos.y%][%monster.pos.x%].creature_id=%~1"
    
    for %%A in (hp sleep_count speed creature_id "pos.y" "pos.x" distance_from_player lit stunned_amount confused_amount) do (
        set "monsters[%~1].%%A=!monsters[%last_id%].%%~A!"
    )
)

:: This is faster than making a blank_monster object and copying everything over
set "monsters[%last_id%].hp=0"
set "monsters[%last_id%].sleep_count=0"
set "monsters[%last_id%].speed=0"
set "monsters[%last_id%].creature_id=0"
set "monsters[%last_id%].pos.x=0"
set "monsters[%last_id%].pos.y=0"
set "monsters[%last_id%].distance_from_player=0"
set "monsters[%last_id%].lit=false"
set "monsters[%last_id%].stunned_amount=0"
set "monsters[%last_id%].confused_amount=0"
exit /b

::------------------------------------------------------------------------------
:: Creates an object or objects near the specified coordinates
::
:: Arguments: %1 - The coordinates to put the item
::            %2 - The amount of items to place
::            %3 - The type of object to place
:: Returns:   The object_id of the placed item
::------------------------------------------------------------------------------
:dungeonSummonObject
set "real_type=256"
if "%~3"=="1" set "real_type=1"
if "%~3"=="5" set "real_type=1"

for /f "tokens=1,2 delims=;" %%A in ("%~1") do (
    set "coord.y=%%A"
    set "coord.x=%%B"
)
set "amount=%~2"
set "result=0"

:: We're simulating a do loop because the original C code has us directly
:: manipulating the for loop counter to break out of an inner loop while
:: staying within the outer loop for some reason.
:dungeonSummonObjectDoLoop
for /L %%B in (0,1,20) do (
    call rng.cmd :randomNumber 5
    set /a at_coord.y=%coord.y% - 3 + !errorlevel!
    call rng.cmd :randomNumber 5
    set /a at_coord.x=%coord.x% - 3 + !errorlevel!
    set "at_coord=!at_coord.y!;!at_coord.x!"

    call :coordInBounds "at_coord"
    if "!errorlevel!"=="0" (
        call dungeon_los.cmd :los "%~1" "!at_coord!"
        if "!errorlevel!"=="0" (
            for /f "tokens=1,2" %%X in ("!at_coord.x! !at_coord.y!") do (
                if !dg.floor[%%Y][%%X].feature_id! LEQ %max_open_space% (
                    if "!dg.floor[%%Y][%%X].treasure_id!"=="0" (
                        set is_type=0
                        if "%~3"=="3" set "is_type=1"
                        if "%~3"=="7" set "is_type=1"

                        if "!is_type!"=="1" (
                            call rng.cmd :randomNumber 100
                            if !errorlevel! LSS 50 (
                                set "real_type=1"
                            ) else (
                                set "real_type=256"
                            )
                        )

                        if "!real_type!"=="1" (
                            set "small_object=false"
                            if %~3 GEQ 4 set "small_object=true"
                            call :dungeonPlaceRandomObjectAt "at_coord" "!small_object!"
                        ) else (
                            call :dungeonPlaceGold "at_coord"
                        )

                        call :dungeonLiteSpot "at_coord"

                        call :caveTileVisible "at_coord"
                        if "!errorlevel!"=="0" (
                            set /a result+=!real_type!
                        )

                        goto dungeonSummonObjectAfterForLoop
                    )
                )
            )
        )
    )
)
:dungeonSummonObjectAfterForLoop
set /a amount-=1
if not "%amount%"=="0" goto :dungeonSummonObjectDoLoop
exit /b !result!

::------------------------------------------------------------------------------
:: Deletes an object from a specified location
::
:: Arguments: %1 - The name of the variable containing the desired coordinates
:: Returns:   0 if the tile is lit after being cleared
::            1 if the tile is unlit after being cleared
::------------------------------------------------------------------------------
:dungeonDeleteObject
for /f "tokens=1,2 delims=;" %%A in ("!%~1!") do set "tile=dg.floor[%%A][%%B]"
if "!%tile%.feature_id!"=="%tile_blocked_floor%" (
    set "%tile%.feature_id=%tile_corr_floor%"
)

call game_objects.cmd :pusht !%tile%.treasure_id!

set "%tile%.treasure_id=0"
set "%tile%.field_mark=false"

call :dungeonLiteSpot %1
call :caveTileVisible %1
exit /b !errorlevel!
