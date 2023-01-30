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

:dungeonPlaceRandomSecretDoor
exit /b

:dungeonPlaceVault
exit /b

:dungeonPlaceTreasureVault
exit /b

:dungeonPlaceInnerPillars
exit /b

:dungeonPlaceMazeInsideRoom
exit /b

:dungeonPlaceFourSmallRooms
exit /b

:dungeonBuildRoomWithInnerRooms
exit /b

:dungeonPlaceLargeMiddlePillar
exit /b

:dungeonBuildRoomCrossShaped
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