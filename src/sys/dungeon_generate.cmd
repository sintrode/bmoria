@echo off
call %*
exit /b

::------------------------------------------------------------------------------
:: Returns a dark or light floor tile based on the current dungeon level and
:: a random number
::
:: Arguments: None
:: Returns:   1 if the floor tile is dark
::            2 if the floor tile is light
::------------------------------------------------------------------------------
:dungeonFloorTileForLevel
call rng.cmd :randomNumber 25
if %dg.current_level% LEQ !errorlevel! (
    exit /b %tile_light_floor%
)
exit /b %tile_dark_floor%

::------------------------------------------------------------------------------
:: Orient the tunneler in the correct direction based on start and end points
::
:: Arguments: %1 - The name of the variable to store verticality in
::            %2 - The name of the variable to store horizontality in
::            %3 - The starting coordinates of the tunnel
::            %4 - The target coordinates of the tunnel
:: Returns:   None
::------------------------------------------------------------------------------
:pickCorrectDirection
for /f "tokens=1,2 delims=;" %%A in ("%~3") do (
    set "start.y=%%A"
    set "start.x=%%B"
)
for /f "tokens=1,2 delims=;" %%A in ("%~4") do (
    set "end.y=%%A"
    set "end.x=%%B"
)

if %start.y% LSS %end.y% (
    set "%~1=1"
) else if "%start.y%"=="%end.y%" (
    set "%~1=0"
) else (
    set "%~1=-1"
)

if %start.x% LSS %end.x% (
    set "%~2=1"
) else if "%start.x%"=="%end.x%" (
    set "%~2=0"
) else (
    set "%~2=-1"
)

if not "!%~1!"=="0" (
    if not "!%~2!"=="0" (
        call rng.cmd :randomNumber 2
        if "!errorlevel!"=="1" (
            set "%~1=0"
        ) else (
            set "%~2=0"
        )
    )
)
exit /b

::------------------------------------------------------------------------------
:: Move in a random direction
::
:: Arguments: %1 - The name of the variable holding vertical direction
::            %2 - The name of the variable holding horizontal direction
:: Returns:   None
::------------------------------------------------------------------------------
:chanceOfRandomDirection
call rng.cmd :randomNumber 4
set "direction=!errorlevel!"

if !direction! LSS 3 (
    set "%~2=0"
    set /a "%~1=-3 + (!direction! << 1)"
) else (
    set "%~1=0"
    set /a "%~2=-7 + (!direction! << 1)"
)
exit /b

::------------------------------------------------------------------------------
:: Blanks out the entire cave
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonBlankEntireCave
for /L %%A in (0,1,66) do (
    for /L %%B in (0,1,198) do (
        set "dg.floor[%%A][%%B].creature_id=0"
        set "dg.floor[%%A][%%B].treasure_id=0"
        set "dg.floor[%%A][%%B].feature_id=0"

        REM TODO: determine if these need to be "false" instead of "0"
        set "dg.floor[%%A][%%B].perma_lit_room=0"
        set "dg.floor[%%A][%%B].field_mark=0"
        set "dg.floor[%%A][%%B].permanent_light=0"
        set "dg.floor[%%A][%%B].temporary_light=0"
    )
)
exit /b

::------------------------------------------------------------------------------
:: Fill in empty spots with desired rock
::
:: Arguments: %1 - The type of rock to fill in with
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonFillEmptyTilesWith
set /a max_height=%dg.height%-2, max_width=%dg.width%-2
for /L %%Y in (%max_height%,-1,1) do (
    set "x=1"
    for /L %%B in (%max_width%,-1,1) do (
        for /f "delims=" %%X in ("!x!") do (
            if "!dg.floor[%%Y][%%X].feature_id!"=="%tile_null_wall%" set "dg.floor[%%Y][%%X].feature_id=%~1"
            if "!dg.floor[%%Y][%%X].feature_id!"=="%tmp1_wall%" set "dg.floor[%%Y][%%X].feature_id=%~1"
            if "!dg.floor[%%Y][%%X].feature_id!"=="%tmp2_wall%" set "dg.floor[%%Y][%%X].feature_id=%~1"
        )
        set /a x+=1
    )
)
exit /b

::------------------------------------------------------------------------------
:: Place indestructible rock around the edges of the dungeon
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonPlaceBoundaryWalls
set /a max_width=%dg.width%-1
set /a max_height=%dg.height%-1

for /L %%A in (0,1,%max_height%) do (
    set "dg.floor[%%A][0].feature_id=%tile_boundary_wall%"
    set "dg.floor[%%A][%max_width%].feature_id=%tile_boundary_wall%"
)

for /L %%A in (0,1,%max_width%) do (
    set "dg.floor[0][%%A].feature_id=%tile_boundary_wall%"
    set "dg.floor[%max_height%][%%A].feature_id=%tile_boundary_wall%"
)
exit /b

::------------------------------------------------------------------------------
:: Place streamers of rock through the dungeon
::
:: Arguments: %1 - The type of rock to place
::            %2 - The odds of the rock containing treasure
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonPlaceStreamerRock
:: Choose a starting point
call rng.cmd :randomNumber 23
set /a "coord.y=(%dg.height% / 2) + 11 - !errorlevel!"
call rng.cmd :randomNumber 33
set /a "coord.x=(%dg.width% / 2) + 16 - !errorlevel!"

:: Choose a random direction
call rng.cmd :randomNumber 8
set "dir=!errorlevel!"
if !dir! GTR 4 set /a dir+=1

:: Place the streamer
set /a t1=2 * %config.dungeon.dun_streamer_width% + 1
set /a t2=%config.dungeon.dun_streamer_width% + 1

:dungeonPlaceStreamerRockLoop
for /L %%A in (1,1,%config.dungeon.dun_streamer_intensity%) do (
    call rng.cmd :randomNumber !t1!
    set /a spot.y=%coord.y% + !errorlevel! - !t2!
    call rng.cmd :randomNumber !t1!
    set /a spot.x=%coord.x% + !errorlevel! - !t2!

    call dungeon.cmd :coordInBounds "coord" && (
        for /f "tokens=1,2" %%X in ("!spot.x! !spot.y!") do (
            if "!dg.floor[%%Y][%%X].feature_id!"=="%tile_granite_wall%" (
                set "dg.floor[%%Y][%%X].feature_id=%~1"
            )
        )

        call rng.cmd :randomNumber %~2
        if "!errorlevel!"=="1" (
            call dungeon.cmd :dungeonPlaceGold "spot"
        )
    )
)
call player.cmd :playerMovePosition "!dir!" "coord" && goto :dungeonPlaceStreamerRockLoop
exit /b

::------------------------------------------------------------------------------
:: Place open doors throughout the dungeon
::
:: Arguments: %1 - The coordinates to place the open door at
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonPlaceOpenDoor
call game_objects.cmd :popt
set "curs_pos=!errorlevel!"

for /f "tokens=1,2 delims=;" %%A in ("%~1") do (
    set "dg.floor[%%A][%%B].treasure_id=%cur_pos%"
    call inventory.cmd :inventoryItemCopyTo %config.dungeon.objects.obj_open_door% "game.treasure.list[%cur_pos%]"
    set "dg.floor[%%A][%%B].treasure_id=%tile_corr_floor%"
)
exit /b

::------------------------------------------------------------------------------
:: Place broken doors throughout the dungeon
::
:: Arguments: %1 - The coordinates to place the broken door at
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonPlaceBrokenDoor
call game_objects.cmd :popt
set "curs_pos=!errorlevel!"

for /f "tokens=1,2 delims=;" %%A in ("%~1") do (
    set "dg.floor[%%A][%%B].treasure_id=%cur_pos%"
    call inventory.cmd :inventoryItemCopyTo %config.dungeon.objects.obj_open_door% "game.treasure.list[%cur_pos%]"
    set "dg.floor[%%A][%%B].treasure_id=%tile_corr_floor%"
    set "game.treasure.list[%cur_pos%].misc_use=1"
)
exit /b

::------------------------------------------------------------------------------
:: Place closed doors throughout the dungeon
::
:: Arguments: %1 - The coordinates to place the closed door at
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonPlaceClosedDoor
call game_objects.cmd :popt
set "curs_pos=!errorlevel!"

for /f "tokens=1,2 delims=;" %%A in ("%~1") do (
    set "dg.floor[%%A][%%B].treasure_id=%cur_pos%"
    call inventory.cmd :inventoryItemCopyTo %config.dungeon.objects.obj_closed_door% "game.treasure.list[%cur_pos%]"
    set "dg.floor[%%A][%%B].treasure_id=%tile_blocked_floor%"
)
exit /b

::------------------------------------------------------------------------------
:: Place locked doors throughout the dungeon
::
:: Arguments: %1 - The coordinates to place the locked door at
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonPlaceLockedDoor
call game_objects.cmd :popt
set "curs_pos=!errorlevel!"

for /f "tokens=1,2 delims=;" %%A in ("%~1") do (
    set "dg.floor[%%A][%%B].treasure_id=%cur_pos%"
    call inventory.cmd :inventoryItemCopyTo %config.dungeon.objects.obj_closed_door% "game.treasure.list[%cur_pos%]"
    set "dg.floor[%%A][%%B].treasure_id=%tile_blocked_floor%"
)
call rng.cmd :randomNumber 10
set /a game.treasure.list[%cur_pos%].misc_use=!errorlevel! + 10
exit /b

::------------------------------------------------------------------------------
:: Place stuck doors throughout the dungeon
::
:: Arguments: %1 - The coordinates to place the stuck door at
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonPlaceStuckDoor
call game_objects.cmd :popt
set "curs_pos=!errorlevel!"

for /f "tokens=1,2 delims=;" %%A in ("%~1") do (
    set "dg.floor[%%A][%%B].treasure_id=%cur_pos%"
    call inventory.cmd :inventoryItemCopyTo %config.dungeon.objects.obj_closed_door% "game.treasure.list[%cur_pos%]"
    set "dg.floor[%%A][%%B].treasure_id=%tile_blocked_floor%"
)
call rng.cmd :randomNumber 10
set /a game.treasure.list[%cur_pos%].misc_use=-!errorlevel! - 10
exit /b

::------------------------------------------------------------------------------
:: Place secret doors throughout the dungeon
::
:: Arguments: %1 - The coordinates to place the secret door at
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonPlaceSecretDoor
call game_objects.cmd :popt
set "curs_pos=!errorlevel!"

for /f "tokens=1,2 delims=;" %%A in ("%~1") do (
    set "dg.floor[%%A][%%B].treasure_id=%cur_pos%"
    call inventory.cmd :inventoryItemCopyTo %config.dungeon.objects.obj_closed_door% "game.treasure.list[%cur_pos%]"
    set "dg.floor[%%A][%%B].treasure_id=%tile_blocked_floor%"
)
exit /b

::------------------------------------------------------------------------------
:: A wrapper subroutine to determine the type of door to place. Door types are
:: *just* different enough that a generic subroutine with parameters isn't
:: feasible.
::
:: Arguments: %1 - The coordinates to place the door at
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonPlaceDoor
:: 1 - doors that let you pass
:: 2 - doors that do not let you pass
:: 3 - secret doors
call rng.cmd :randomNumber 3
set "door_type=!errorlevel!"

if "%door_type%"=="1" (
    call rng.cmd :randomNumber 4
    if "!errorlevel!"=="1" (
        call :dungeonPlaceBrokenDoor "%~1"
    ) else (
        call :dungeonPlaceOpenDoor "%~1"
    )
) else if "%door_type%"=="2" (
    call rng.cmd :randomNumber 12
    set "door_type=!errorlevel!"

    if !door_type! GTR 3 (
        call :dungeonPlaceClosedDoor "%~1"
    ) else if "!door_type!"=="3" (
        call :dungeonPlaceStuckDoor "%~1"
    ) else (
        call :dungeonPlaceLockedDoor "%~1"
    )
) else (
    call :dungeonPlaceSecretDoor "%~1"
)
exit /b

::------------------------------------------------------------------------------
:: Place an up staircase at specified coordinates
::
:: Arguments: %1 - The coordinates to place the staircase at
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonPlaceUpStairs
for /f "tokens=1,2 delims=;" %%A in ("%~1") do (
    if not "!dg.floor[%%A][%%B].treasure_id!"=="0" (
        set "coord=%~1"
        call dungeon.cmd :dungeonDeleteObject "coord"
    )

    call game_objects.cmd :popt
    set "curs_pos=!errorlevel!"

    set "dg.floor[%%A][%%B].treasure_id=!cur_pos!"
    call call inventory.cmd :inventoryItemCopyTo %config.dungeon.objects.obj_up_stair% "game.treasure.list[!cur_pos!]"
)
exit /b

::------------------------------------------------------------------------------
:: Place an down staircase at specified coordinates
::
:: Arguments: %1 - The coordinates to place the staircase at
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonPlaceDownStairs
for /f "tokens=1,2 delims=;" %%A in ("%~1") do (
    if not "!dg.floor[%%A][%%B].treasure_id!"=="0" (
        set "coord=%~1"
        call dungeon.cmd :dungeonDeleteObject "coord"
    )

    call game_objects.cmd :popt
    set "curs_pos=!errorlevel!"

    set "dg.floor[%%A][%%B].treasure_id=!cur_pos!"
    call call inventory.cmd :inventoryItemCopyTo %config.dungeon.objects.obj_down_stair% "game.treasure.list[!cur_pos!]"
)
exit /b

::------------------------------------------------------------------------------
:: A wrapper subroutine for placing stairs
::
:: Arguments: %1 - The type of stairs to place (1 for up, 2 for down)
::            %2 - The number of staircases to place
::            %3 - The number of walls that there should be near the stairs
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonPlaceStairs
set /a coord1.x=0, coord1.y=0, coord2.x=0, coord2.y=0
for /L %%A in (1,1,%~2) do (
    set "placed=false"
    call :dungeonPlaceStairsWhileLoop "%~1" "%~3"
)
exit /b

:dungeonPlaceStairsWhileLoop
if "!placed!"=="true" exit /b

set "j=0"
:dungeonPlaceStairsFirstDoLoop
set /a height_offset=%dg.height%-14
call rng.cmd :randomNumber !height_offset!
set "coord1.y=!errorlevel!"
set /a width_offset=%dg.width%-14
call rng.cmd :randomNumber !width_offset!
set "coord1.x=!errorlevel!"
set /a coord2.y=!coord1.y! + 12
set /a coord2.x=!coord1.x! + 12

:dungeonPlaceStairsSecondDoLoop
:dungeonPlaceStairsThirdDoLoop
for /f "tokens=1,2 delims=;" %%B in ("!coord1.y! !coord1.x!") do (
    if !dg.floor[%%B][%%C].feature_id! LEQ %max_open_space% (
        if "!dg.floor[%%B][%%C].treasure_id!"=="0" (
            call dungeon.cmd :coordWallsNextTo "coord1"
            if !errorlevel! GEQ %~2 (
                set "placed=true"
                if "%~1"=="1" (
                    call :dungeonPlaceUpStairs "!coord1.y!;!coord1.x!"
                ) else (
                    call :dungeonPlaceDownStairs "!coord1.y!;!coord1.x!"
                )
                set /a coord1.x+=1
            )
        )
    )
)
if not "!coord1.x!"=="!coord2.x!" if "!placed!"=="false" goto :dungeonPlaceStairsThirdDoLoop
set /a coord1.x=!coord2.x!-12
set /a coord1.y+=1
if not "!coord1.y!"=="!coord2.y!" if "!placed!"=="false" goto :dungeonPlaceStairsSecondDoLoop
set /a j+=1
if "!placed!"=="false" if !j! LEQ 30 goto :dungeonPlaceStairsFirstDoLoop
set /a walls-=1
goto :dungeonPlaceStairsWhileLoop

::------------------------------------------------------------------------------
:: Place a specified number of traps around given coordinates
::
:: Arguments: %1 - The main coordinates of the trap
::            %2 - The range of values the trap could be placed within
::            %3 - The number of traps to place
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonPlaceVaultTrap
for /L %%A in (1,1,%~3) do (
    set "placed=false"
    for /L %%B in (0,1,5) do (
        if "!placed!"=="true" exit /b

        for /F "tokens=1-4 delims=; " %%C in ("%~1 %~2") do (
            set /a disp_y_rnd_offset=2 * %%E + 1
            set /a disp_x_rnd_offset=2 * %%F + 1
            call rng.cmd :randomNumber !disp_y_rnd_offset!
            set /a spot.y=%%C - %%E - 1 + !errorlevel!
            call rng.cmd :randomNumber !disp_x_rnd_offset!
            set /a spot.x=%%D - %%F - 1 + !errorlevel!
        )

        for /F "tokens=1,2 delims=;" %%C in ("!spot.y! !spot.x!") do (
            if not "!dg.floor[%%C][%%D].feature_id!"=="%tile_null_wall%" (
                if !dg.floor[%%C][%%D].feature_id LEQ %max_cave_floor% (
                    if "!dg.floor[%%C][%%D].treasure_id!"=="0" (
                        call rng.cmd :randomNumber %config.dungeon.objects.max_traps%
                        set /a trap_type=!errorlevel!-1
                        call dungeon.cmd :dungeonSetTrap "spot" !trap_type!
                        set "placed=true"
                    )
                )
            )
        )
    )
)
exit /b

::------------------------------------------------------------------------------
:: Places a monster at specified coordinates
::
:: Arguments: %1 - The coordinates of the new monster
::            %2 - The number of monsters to place
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonPlaceVaultMonster
set "spot=%~1"
for /L %%A in (1,1,%~2) do (
    call monster_manager.cmd :monsterSummon "spot" "true"
)
exit /b

::------------------------------------------------------------------------------
:: Builds a room at a row,column coordinate
::
:: Arguments: %1 - The coordinates of the new room
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonBuildRoom
call :dungeonFloorTileForLevel
set "floor=!errorlevel!"

for /f "tokens=1,2 delims=;" %%A in ("%~1") do (
    call rng.cmd :randomNumber 4
    set /a height=%%A + !errorlevel!

    call rng.cmd :randomNumber 3
    set /a depth=%%A + !errorlevel!

    call rng.cmd :randomNumber 11
    set /a left=%%B + !errorlevel!

    call rng.cmd :randomNumber 11
    set right=%%B + !errorlevel!
)

for /L %%Y in (%height%,1,%depth%) do (
    for /L %%X in (%left%,1,%right%) do (
        set "dg.floor[%%Y][%%X].feature_id=!floor!"
        set "dg.floor[%%Y][%%X].perma_lit_room=true"
    )
)

set /a height_offset=%height%-1, depth_offset=%depth%+1
set /a left_offset=%left%-1, right_offset=%right%+1
for /L %%Y in (%height_offset%,1,%depth_offset%) do (
    set "dg.floor[%%Y][%left_offset%].feature_id=%tile_granite_wall%"
    set "dg.floor[%%Y][%left_offset%].perma_lit_room=true"

    set "dg.floor[%%Y][%right_offset%].feature_id=%tile_granite_wall%"
    set "dg.floor[%%Y][%right_offset%].perma_lit_room=true"
)

for /L %%X in (%left%,1,%right%) do (
    set "dg.floor[%height_offset%][x].feature_id=%tile_granite_wall%"
    set "dg.floor[%height_offset%][x].feature_id=true"

    set "dg.floor[%height_offset%][x].feature_id=%tile_granite_wall%"
    set "dg.floor[%height_offset%][x].feature_id=true"
)
exit /b

::------------------------------------------------------------------------------
:: Builds a room at specified coordinates made out of other overlapping rooms
::
:: Arguments: %1 - The coordinates of the new room
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonBuildRoomOverlappingRectangles
call :dungeonFloorTileForLevel
set "floor=!errorlevel!"

call rng.cmd :randomNumber 2
set /a limit=1+!errorlevel!

for /L %%A in (1,1,%limit%) do (
    for /f "tokens=1,2 delims=;" %%B in ("%~1") do (
        call rng.cmd :randomNumber 4
        set /a height=%%A + !errorlevel!

        call rng.cmd :randomNumber 3
        set /a depth=%%A + !errorlevel!

        call rng.cmd :randomNumber 11
        set /a left=%%B + !errorlevel!

        call rng.cmd :randomNumber 11
        set right=%%B + !errorlevel!
    )

    for %%Y in (!height!,1,!depth!) do (
        for %%X in (!left!,1,!right!) do (
            set "dg.floor[%%Y][%%X].feature_id=!floor!"
            set "dg.floor[%%Y][%%X].perma_lit_room=true"
        )
    )

    set /a height_offset=!height!-1, depth_offset=!depth!+1
    set /a left_offset=!left!-1, right_offset=!right!+1

    for /f "tokens=1-4 %%B in ("!left_offset! !right_offset! !height_offset! !depth_offset!") do (
        for /L %%Y in (!height_offset!,1,!depth_offset!) do (
            if not "!dg.floor[%%Y][%%B].feature_id!"=="!floor!" (
                set "dg.floor[%%Y][%%B].feature_id=%tile_granite_wall%"
                set "dg.floor[%%Y][%%B].perma_lit_room=true"
            )
            if not "!dg.floor[%%Y][%%C].feature_id!"=="!floor!" (
                set "dg.floor[%%Y][%%C].feature_id=%tile_granite_wall%"
                set "dg.floor[%%Y][%%C].perma_lit_room=true"
            )
        )

        for /L %%X in (!left!,1,!right!) do (
            if not "!dg.floor[%%D][%%X].feature_id!"=="!floor!" (
                set "dg.floor[%%D][%%X].feature_id=%tile_granite_wall%"
                set "dg.floor[%%D][%%X].perma_lit_room=true"
            )
            if not "!dg.floor[%%E][%%X].feature_id!"=="!floor!" (
                set "dg.floor[%%E][%%X].feature_id=%tile_granite_wall%"
                set "dg.floor[%%E][%%X].perma_lit_room=true"
            )
        )
    )
)
exit /b

::------------------------------------------------------------------------------
:: Places a secret door at random coordinates that are adjacent to specified
:: coordinates
::
:: Arguments: %1 - The target coordinates of the secret door
::            %2 - The bottom offset of the secret door
::            %3 - The top offset of the secret door
::            %4 - The left offset of the secret door
::            %5 - The right offset of the secret door
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonPlaceRandomSecretDoor
for /f "tokens=1,2 delims=;" %%A in ("%~1") do (
    set "coord.y=%%~A"
    set "coord.x=%%~B"
)
call rng.cmd :randomNumber 4
if "!errorlevel!"=="1" (
    set /a height_offset=%~3-1
    call :dungeonPlaceSecretDoor "!height_offset!;!coord.x!"
) else if "!errorlevel!"=="2" (
    set /a depth_offset=%~2+1
    call :dungeonPlaceSecretDoor "!depth_offset!;!coord.x!"
) else if "!errorlevel!"=="3" (
    set /a left_offset=%~4+1
    call :dungeonPlaceSecretDoor "!coord.y!;!left_offset!"
) else if "!errorlevel!"=="4" (
    set /a right_offset=%~5+1
    call :dungeonPlaceSecretDoor "!coord.y!;!right_offset!"
)
exit /b

::------------------------------------------------------------------------------
:: Places a vault in the dungeon at specified coordinates
::
:: Arguments: %1 - The coordinates to place the vault at
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonPlaceVault
for /f "tokens=1,2 delims=;" %%A in ("%~1") do (
    set /a coord.y_dec=%%~A-1
    set /a coord.y_inc=%%~A+1
    set /a coord.x_dec=%%~B-1
    set /a coord.x_inc=%%~B+1

    for /L %%Y in (!coord.y_dec!,1,!coord.y_inc!) do (
        set "dg.floor[%%Y][!coord.x_dec!].feature_id=%TMP1_WALL%"
        set "dg.floor[%%Y][!coord.x_inc!].feature_id=%TMP1_WALL%"
    )
    set "dg.floor[!coord.y_dec!][!coord.x!].feature_id=%TMP1_WALL%"
    set "dg.floor[!coord.y_inc!][!coord.x!].feature_id=%TMP1_WALL%"
)
exit /b

::------------------------------------------------------------------------------
:: Create a secret door and a vault behind it
::
:: Arguments: %1 - The coordinates for the door and vault
::            %2 - The bottom side of the vault
::            %3 - The top side of the vault
::            %4 - The left side of the vault
::            %5 - The right side of the vault
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonPlaceTreasureVault
call :dungeonPlaceRandomSecretDoor %*
call :dungeonPlaceVault "%~1"

for /f "tokens=1,2 delims=;" %%A in ("%~1") do (
    set "coord.y=%%~A"
    set "coord.x=%%~B"
)
call rng.cmd :randomNumber 4
set "offset=!errorlevel!"
if !offset! LSS 3 (
    set /a "y_offset=!coord.y! - 3 + (!offset! << 1)"
    call :dungeonPlaceLockedDoor "!y_offset!;!coord.x!"
) else (
    set /a "x_offset=!coord.x! - 7 + (!offset! << 1)"
    call :dungeonPlaceLockedDoor "!coord.y!;!x_offset!"
)
exit /b

::------------------------------------------------------------------------------
:: Place pillars around specified coordinates
::
:: Arguments: %1 - The coordinates of the new pillars
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonPlaceInnerPillars
for /f "tokens=1,2 delims=;" %%A in ("%~1") do (
    set /a coord.y_dec=%%~A-1
    set /a coord.y_inc=%%~A+1
    set /a coord.x_dec=%%~B-1
    set /a coord.x_inc=%%~B+1

    for /L %%Y in (!coord.y_dec!,1,!coord.y_inc!) (
        for /L %%X in (!coord.x_dec!,1,!coord.x_inc!) do (
            set "dg.floor[%%Y][%%X].feature_id=%TMP1_WALL%"
        )
    )

    call rng.cmd :randomNumber 2
    if not "!errorlevel!"=="1" exit /b

    call rng.cmd :randomNumber 2
    set "offset=!errorlevel!"
    set /a coord.x_3dec=%%~B - 3 - !offset!
    set /a coord.x_3inc=%%~B + 3 + !offset!
    set /a coord.x_5dec=%%~B - 5 - !offset!
    set /a coord.x_5inc=%%~B + 5 + !offset!
    for /L %%Y in (!coord.y_dec!,1,!coord.y_inc!) do (
        for /L %%X in (!coord.x_5dec!,1,!coord.x_3_dec!) do (
            set "dg.floor[%%Y][%%X].feature_id=%TMP1_WALL%"
        )
        for /L %%X in (!coord.x_3inc!,1,!coord.x_5inc!) do (
            set "dg.floor[%%Y][%%X].feature_id=%TMP1_WALL%"
        )
    )
)
exit /b

::------------------------------------------------------------------------------
:: Places a maze inside of a given range of dimensions
::
:: Arguments: %1 - The bottom of the maze
::            %2 - The top of the maze
::            %3 - The left side of the maze
::            %4 - The right side of the maze
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonPlaceMazeInsideRoom
for /L %%Y in (%~2,1,%~1) do (
    for /L %%X in (%~3,1,%~4) do (
        set /a "add_wall=(1 & (%%X + %%Y))"
        if not "!add_wall!"=="0" (
            set "dg.floor[%%Y][%%X].feature_id=%TMP1_WALL%"
        )
    )
)
exit /b

::------------------------------------------------------------------------------
:: Creates a room with four smaller rooms inside of it
::
:: Arguments: %1 - The coordinates of the larger room
::            %2 - The bottom of the larger room
::            %3 - The top of the larger room
::            %4 - The left side of the larger room
::            %5 - The right side of the larger room
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonPlaceFourSmallRooms
for /f "tokens=1,2 delims=;" %%A in ("%~1") do (
    for /L %%Y in (%~3,1,%~2) do (
        set "dg.floor[%%Y][%%B].feature_id=%TMP1_WALL%"
    )
    for /L %%X in (%~4,1,%~5) do (
        set "dg.floor[%%A][%%X].feature_id=%TMP1_WALL%"
    )

    call rng.cmd :randomNumber 2
    if "!errorlevel!"=="1" (
        call rng.cmd :randomNumber 10
        set "offset=!errorlevel!"
        set /a height_dec=%~3-1, depth_inc=%~2+1
        set /a x_dec=%%B-!offset!, x_inc=%%B+!offset!

        call :dungeonPlaceSecretDoor "!height_dec!;!x_dec!"
        call :dungeonPlaceSecretDoor "!height_dec!;!x_inc!"
        call :dungeonPlaceSecretDoor "!depth_inc!;!x_dec!"
        call :dungeonPlaceSecretDoor "!depth_inc!;!x_inc!"
    ) else (
        call rng.cmd :randomNumber 10
        set "offset=!errorlevel!"
        set /a left_dec=%~4-1, right_inc=%~5+1
        set /a y_dec=%%A-!offset!, y_inc=%%A+!offset!

        call :dungeonPlaceSecretDoor "!y_inc!;!left_dec!"
        call :dungeonPlaceSecretDoor "!y_dec!;!left_dec!"
        call :dungeonPlaceSecretDoor "!y_inc!;!right_inc!"
        call :dungeonPlaceSecretDoor "!y_dec!;!right_inc!"
    )
)
exit /b

::------------------------------------------------------------------------------
:: Builds an unusual room at specified coordinates
::
:: Arguments: %1 - The coordinates of the new room
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonBuildRoomWithInnerRooms
call :dungeonFloorTileForLevel
set "floor=!errorlevel!"
for /f "tokens=1,2 delims=;" %%A in ("%~1") do (
    set /a coord.y=%%A, coord.x=%%B
    set /a height=%%A-4, depth=%%A+4, left=%%B-11, right=%%B+11
)

for /L %%Y in (!height!,1,!depth!) do (
    for /L %%X in (!left!,1,!right!) do (
        set "dg.floor[%%Y][%%X].feature_id=!floor!"
        set "dg.floor[%%Y][%%X].perma_lit_room=true"
    )
)

set /a height_dec=!height!-1, depth_inc=!depth!+1
set /a left_dec=!left!-1, right_inc=!right!+1
for /L %%Y in (!height_dec!,1,!depth_inc!) do (
    set "dg.floor[%%Y][!left_dec!].feature_id=%tile_granite_wall%"
    set "dg.floor[%%Y][!left_dec!].perma_lit_room=true"
    set "dg.floor[%%Y][!right_inc!].feature_id=%tile_granite_wall%"
    set "dg.floor[%%Y][!right_inc!].perma_lit_room=true"
)
for /L %%X in (!left!,1,!right!) do (
    set "dg.floor[!height_dec!][%%X].feature_id=%tile_granite_wall%"
    set "dg.floor[!height_dec!][%%X].perma_lit_room=true"
    set "dg.floor[!depth_inc!][%%X].feature_id=%tile_granite_wall%"
    set "dg.floor[!depth_inc!][%%X].perma_lit_room=true"
)

:: The inner room
set /a height+=2, depth-=2, left+=2, right-=2
set /a height_dec=!height!-1, depth_inc=!depth!+1
set /a left_dec=!left!-1, right_inc=!right!+1
for /L %%Y in (!height_dec!,1,!depth_inc!) do (
    set "dg.floor[%%Y][!left_dec!].feature_id=%tmp1_wall%"
    set "dg.floor[%%Y][!right_inc!].feature_id=%tmp1_wall%"
)
for /L %%X in (!left!,1,!right!) do (
    set "dg.floor[!height_dec!][%%X].feature_id=%tmp1_wall%"
    set "dg.floor[!depth_inc!][%%X].feature_id=%tmp1_wall%"
)

set /a coord.x_dec=!coord.x!-1, coord.x_inc=!coord.x!+1
set /a coord.x_2dec=!coord.x!-2, coord.x_2inc=!coord.x!+2
set /a coord.x_3dec=!coord.x!-3, coord.x_3inc=!coord.x!+3
set /a coord.x_4dec=!coord.x!-4, coord.x_4inc=!coord.x!+4
set /a coord.x_5dec=!coord.x!-5, coord.x_5inc=!coord.x!+5
call rng.cmd :randomNumber 5
set "inner_room_type=!errorlevel!"

if "!inner_room_type!"=="%InnerRoomTypes.Plain%" (
    call :dungeonPlaceRandomSecretDoor "%~1" !depth! !height! !left! !right!
    call :dungeonPlaceVaultMonster "%~1" 1
    exit /b
)
if "!inner_room_type!"=="%InnerRoomTypes.TreasureVault%" (
    call :dungeonPlaceTreasureVault "%~1" !depth! !height! !left! !right!
    call rng.cmd :randomNumber 3
    set /a treasure_vault_monsters=!errorlevel!+2
    call :dungeonPlaceVaultMonster "%~1" !treasure_vault_monsters!
    call rng.cmd :randomNumber 3
    set /a treasure_vault_traps=!errorlevel!+2
    call :dungeonPlaceVaultTrap "%~1" "4;10" !treasure_vault_traps!
    exit /b
)
if "!inner_room_type!"=="%InnerRoomTypes.Pillars%" (
    call :dungeonPlaceRandomSecretDoor "%~1" !depth! !height! !left! !right!
    call :dungeonPlaceInnerPillars "%~1"
    call rng.cmd :randomNumber 3
    if not "!errorlevel!"=="1" exit /b

    for /L %%X in (!coord.x_5dec!,1,!coord.x_5inc!) do (
        set "dg.floor[!coord.y_dec!][%%X].feature_id=%tmp1_wall%"
        set "dg.floor[!coord.y_inc!][%%X].feature_id=%tmp1_wall%"
    )
    set "dg.floor[!coord.y!][!coord.x_5dec!].feature_id=%tmp1_wall%"
    set "dg.floor[!coord.y!][!coord.x_5inc!].feature_id=%tmp1_wall%"

    call rnd.cmd :randomNumber 2
    set /a "y_secret=!coord.y! - 3 + (!errorlevel! << 1)"
    call :dungeonPlaceSecretDoor "!y_secret!;!coord.x_3dec!"
    call rnd.cmd :randomNumber 2
    set /a "y_secret=!coord.y! - 3 + (!errorlevel! << 1)"
    call :dungeonPlaceSecretDoor "!y_secret!;!coord.x_3inc!"

    call rnd.cmd :randomNumber 3
    if "!errorlevel!"=="1" (
        set "rnd_obj_coord=!coord.y!;!coord.x_2dec!"
        call dungeon.cmd :dungeonPlaceRandomObjectAt "rnd_obj_coord" "false"
    )
    call rnd.cmd :randomNumber 3
    if "!errorlevel!"=="1" (
        set "rnd_obj_coord=!coord.y!;!coord.x_2inc!"
        call dungeon.cmd :dungeonPlaceRandomObjectAt "rnd_obj_coord" "false"
    )

    call rng.cmd :randomNumber 2
    call :dungeonPlaceVaultMonster "!coord.y!;!coord.x_2dec!" !errorlevel!
    call rng.cmd :randomNumber 2
    call :dungeonPlaceVaultMonster "!coord.y!;!coord.x_2inc!" !errorlevel!
    exit /b
)
if "!inner_room_type!"=="%InnerRoomTypes.Maze%" (
    call :dungeonPlaceRandomSecretDoor "%~1" !depth! !height! !left! !right!
    call :dungeonPlaceMazeInsideRoomcall !depth! !height! !left! !right!

    call rng.cmd :randomNumber 3
    call :dungeonPlaceVaultMonster "!coord.y!;!coord.x_5dec!" !errorlevel!
    call rng.cmd :randomNumber 3
    call :dungeonPlaceVaultMonster "!coord.y!;!coord.x_5inc!" !errorlevel!

    call rng.cmd :randomNumber 3
    call :dungeonPlaceVaultTrap "!coord.y!;!coord.x_3dec!" "2;8" !errorlevel!
    call rng.cmd :randomNumber 3
    call :dungeonPlaceVaultTrap "!coord.y!;!coord.x_3inc!" "2;8" !errorlevel!

    for /L %%A in (0,1,2) do (
        call dungeon.cmd :dungeonPlaceRandomObjectNear "!coord.y!;!coord.x!" 1
    )
    exit /b
)
if "!inner_room_type!"=="%InnerRoomTypes.FourSmallRooms%" (
    call :dungeonPlaceFourSmallRooms "%~1" !depth! !height! !left! !right!

    call rng.cmd :randomNumber 2
    set /a treasure_tries=!errorlevel!+2
    call dungeon.cmd :dungeonPlaceRandomObjectNear "!coord.y!;!coord.x!" !treasure_tries!

    call rng.cmd :randomNumber 2
    call :dungeonPlaceVaultMonster "!coord.y_2inc!;!coord.x_4dec!" !errorlevel!
    call rng.cmd :randomNumber 2
    call :dungeonPlaceVaultMonster "!coord.y_2inc!;!coord.x_4inc!" !errorlevel!
    call rng.cmd :randomNumber 2
    call :dungeonPlaceVaultMonster "!coord.y_2dec!;!coord.x_4dec!" !errorlevel!
    call rng.cmd :randomNumber 2
    call :dungeonPlaceVaultMonster "!coord.y_2dec!;!coord.x_4inc!" !errorlevel!
    exit /b
)
exit /b

::------------------------------------------------------------------------------
:: Place a large pillar in the middle of the room
::
:: Arguments: %1 - The coordinates of the pillar
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonPlaceLargeMiddlePillar
for /f "tokens=1-2 delims=;" %%A in ("%~1") do (
    set /a coord.y_dec=%%A-1, coord.y_inc=%%A+1
    set /a coord.x_dec=%%B-1, coord.x_inc=%%B+1

    for /L %%Y in (!coord.y_dec!,1,!coord.y_inc!) do (
        for /L %%X in (!coord.x_dec!,1,!coord.x_inc!) do (
            set "dg.floor[%%Y][%%X].feature_id=%tmp1_wall%"
        )
    )
)
exit /b

::------------------------------------------------------------------------------
:: Builds a cross-shaped room at specified coordinates
::
:: Arguments: %1 - The desired location of the new room
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonBuildRoomCrossShaped
call :dungeonFloorTileForLevel
set "floor=!errorlevel!"

call rng.cmd :randomNumber 2
set /a random_offset=!errorlevel!+2

for /f "tokens=1-2 delims=;" %%A in ("%~1") do (
    set "coord.y=%%A"
    set "coord.x=%%B"
)
set /a height=!coord.y!-!random_offset!
set /a depth=!coord.y!+!random_offset!
set /a left=!coord.x!-1
set /a right=!coord.x!+1

for /L %%Y in (!height!,1,!depth!) do (
    for /L %%X in (!left!,1,!right!) do (
        set "dg.floor[%%Y][%%X].feature_id=!floor!"
        set "dg.floor[%%Y][%%X].perma_lit_room=true"
    )
)
set /a height_dec=!height!-1, depth_inc=!depth!+1
set /a left_dec=!left!-1, right_inc=!right!+1
for /L %%Y in (!height_dec!,1,!depth_inc!) do (
    set "dg.floor[%%Y][%left_dec%].feature_id=%tile_granite_wall%"
    set "dg.floor[%%Y][%left_dec%].perma_lit_room=true"
    set "dg.floor[%%Y][%right_inc%].feature_id=%tile_granite_wall%"
    set "dg.floor[%%Y][%right_inc%].perma_lit_room=true"
)
for /L %%X in (!left!,1,!right!) do (
    set "dg.floor[%height_dec%][%%X].feature_id=%tile_granite_wall%"
    set "dg.floor[%height_dec%][%%X].perma_lit_room=true"
    set "dg.floor[%depth_inc%][%%X].feature_id=%tile_granite_wall%"
    set "dg.floor[%depth_inc%][%%X].perma_lit_room=true"
)

call rng.cmd :randomNumber 9
set /a random_offset=!errorlevel!+2
set /a height=!coord.y!-1
set /a depth=!coord.y!+1
set /a left=!coord.x!-!random_offset!
set /a right=!coord.x!+!random_offset!

for /L %%Y in (!height!,1,!depth!) do (
    for /L %%X in (!left!,1,!right!) do (
        set "dg.floor[%%Y][%%X].feature_id=!floor!"
        set "dg.floor[%%Y][%%X].perma_lit_room=true"
    )
)
set /a height_dec=!height!-1, depth_inc=!depth!+1
set /a left_dec=!left!-1, right_inc=!right!+1
for /L %%Y in (!height_dec!,1,!depth_inc!) do (
    if not "!dg.floor[%%Y][%left_dec%].feature_id!"=="!floor!" (
        set "dg.floor[%%Y][%left_dec%].feature_id=%tile_granite_wall%"
        set "dg.floor[%%Y][%left_dec%].perma_lit_room=true"
    )
    if not "!dg.floor[%%Y][%right_inc%].feature_id!"=="!floor!" (
        set "dg.floor[%%Y][%right_inc%].feature_id=%tile_granite_wall%"
        set "dg.floor[%%Y][%right_inc%].perma_lit_room=true"
    )
)
for /L %%X in (!left!,1,!right!) do (
    if not "!dg.floor[%height_dec%][%%X].feature_id!"=="!floor!" (
        set "dg.floor[%height_dec%][%%X].feature_id=%tile_granite_wall%"
        set "dg.floor[%height_dec%][%%X].perma_lit_room=true"
    )
    if not "!dg.floor[%depth_inc%][%%X].feature_id!"=="!floor!" (
        set "dg.floor[%depth_inc%][%%X].feature_id=%tile_granite_wall%"
        set "dg.floor[%depth_inc%][%%X].perma_lit_room=true"
    )
)

call rng.cmd :randomNumber 4
set "special_feature=!errorlevel!"

if "!special_feature!"=="1" (
    call :dungeonPlaceLargeMiddlePillar "%~1"
    exit /b
) else if "!special_feature!"=="2" (
    call :dungeonPlaceVault "%~1"

    call rng.cmd :randomNumber 4
    set "random_offset=!errorlevel!"
    if !random_offset! LSS 3 (
        set /a "y_offset=!coord.y! - 3 + (!random_offset! << 1)"
        call :dungeonPlaceSecretDoor "!y_offset!;!coord.x!"
    ) else (
        set /a "x_offset=!coord.x! - 7 + (!random_offset! << 1)"
        call :dungeonPlaceSecretDoor "!coord.y!;!x_offset!"
    )

    call dungeon.cmd :dungeonPlaceRandomObjectAt "coord" "false"
    
    call rng.cmd :randomNumber 2
    set /a treasure_vault_monsters=!errorlevel!+2
    call :dungeonPlaceVaultMonster "%~1" !treasure_vault_monsters!

    call rng.cmd :randomNumber 3
    set /a treasure_vault_traps=!errorlevel!+1
    call :dungeonPlaceVaultTrap "%~1" "4;4" !treasure_vault_traps!
    exit /b
) else if "!special_feature!"=="3" (
    set /a coord.y_dec=!coord.y!-1, coord.y_inc=!coord.y!+1
    set /a coord.y_2dec=!coord.y!-2, coord.y_2inc=!coord.y!+2
    set /a coord.x_dec=!coord.x!-1, coord.x_inc=!coord.x!+1
    set /a coord.x_2dec=!coord.x!-2, coord.x_2inc=!coord.x!+2

    call rng.cmd :randomNumber 3
    if "!errorlevel!"=="1" (
        set "dg.floor[!coord.y_dec!][!coord.x_2dec!].feature_id=%tmp1_wall%"
        set "dg.floor[!coord.y_inc!][!coord.x_2dec!].feature_id=%tmp1_wall%"
        set "dg.floor[!coord.y_dec!][!coord.x_2inc!].feature_id=%tmp1_wall%"
        set "dg.floor[!coord.y_inc!][!coord.x_2inc!].feature_id=%tmp1_wall%"
        set "dg.floor[!coord.y_2dec!][!coord.x_inc!].feature_id=%tmp1_wall%"
        set "dg.floor[!coord.y_2dec!][!coord.x_dec!].feature_id=%tmp1_wall%"
        set "dg.floor[!coord.y_2inc!][!coord.x_inc!].feature_id=%tmp1_wall%"
        set "dg.floor[!coord.y_2inc!][!coord.x_dec!].feature_id=%tmp1_wall%"

        call rng.cmd :randomNumber 3
        if "!errorlevel!"=="1" (
            call :dungeonPlaceSecretDoor "!coord.y!;!coord.x_2dec!"
            call :dungeonPlaceSecretDoor "!coord.y!;!coord.x_2inc!"
            call :dungeonPlaceSecretDoor "!coord.y_2dec!;!coord.x!"
            call :dungeonPlaceSecretDoor "!coord.y_2inc!;!coord.x!"
        )
    ) else (
        call rng.cmd :randomNumber 3
        if "!errorlevel!"=="1" (
            set "dg.floor[!coord.y!][!coord.x!].feature_id=%tmp1_wall%"
            set "dg.floor[!coord.y_dec!][!coord.x!].feature_id=%tmp1_wall%"
            set "dg.floor[!coord.y_inc!][!coord.x!].feature_id=%tmp1_wall%"
            set "dg.floor[!coord.y!][!coord.x_dec!].feature_id=%tmp1_wall%"
            set "dg.floor[!coord.y!][!coord.x_inc!].feature_id=%tmp1_wall%"
        ) else (
            call rng.cmd :randomNumber 3
            if "!errorlevel!"=="1" (
                set "dg.floor[!coord.y!][!coord.x!].feature_id=%tmp1_wall%"
            )
        )
    )
    exit /b
)
exit /b

:dungeonBuildTunnel
exit /b

:dungeonIsNextTo
exit /b

:dungeonPlaceDoorIfNextToTwoWalls
exit /b

:dungeonNewSpot
exit /b

:setRooms
exit /b

:setCorridors
exit /b

:setFloors
exit /b

:dungeonGenerate
exit /b

:dungeonBuildStore
exit /b

:treasureLinker
exit /b

:monsterLinker
exit /b

:dungeonPlaceTownStores
exit /b

:isNighTime
exit /b

:lightTown
exit /b

:townGeneration
exit /b

:generateCave
exit /b