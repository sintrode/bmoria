@echo off
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
    if !dy! LSS 0 (
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

:dungeonSetTrap
exit /b

:trapChangeVisibility
exit /b

:dungeonPlaceRubble
exit /b

:dungeonPlaceGold
exit /b

:dungeonPlaceRandomObjectAt
exit /b

:dungeonAllocateAndPlaceObject
exit /b

:dungeonPlaceRandomObjectNear
exit /b

:dungeonMoveCreatureRecord
exit /b

:dungeonLightRoom
exit /b

:dungeonLiteSpot
exit /b

:sub1MoveLight
exit /b

:sub3MoveLight
exit /b

:dungeonMoveCharacterLight
exit /b

:dungeonDeleteMonster
exit /b

:dungeonRemoveMonsterFromLevel
exit /b

:dungeonDeleteMonsterRecord
exit /b

:dungeonSummonObject
exit /b

:dungeonDeleteObject
exit /b
