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

::------------------------------------------------------------------------------
:: Constructs a tunnel between two points
::
:: Arguments: %1 - The coordinates of the start point
::            %2 - The coordinates of the end point
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonBuildTunnel
set "door_flag=false"
set "stop_flag=false"
set "main_loop_count=0"
set "tunnel_index=0"
set "wall_index=0"
for /f "tokens=1-4 delims=; " %%A in ("%~1 %~2") do (
    set "start.y=%%~A"
    set "start.x=%%~B"
    set "end.y=%%~C"
    set "end.x=%%~D"
)
set "start_row=!start.y!"
set "start_col=!start.x!"

call :pickCorrectDirection "y_direction" "x_direction" "%~1" "%~2"

:dungeonBuildTunnelDoLoop
set /a main_loop_count+=1
if !main_loop_count! GTR 2000 set "stop_flag=true"

call rng.cmd :randomNumber 100
if !errorlevel! GTR %config.dungeon.dun_dir_change% (
    call rng.cmd randomNumber %config.dungeon.dun_random_dir%
    if "!errorlevel!"=="1" (
        call :chanceOfRandomDirection "y_direction" "x_direction"
    ) else (
        call :pickCorrectDirection "y_direction" "x_direction" "%~1" "%~2"
    )
)
set /a tmp_row=!start.y! + !y_direction!
set /a tmp_col=!start.x! + !x_direction!

:dungeonBuildTunnelWhileLoop
set "tmp_coord=!tmp_row!;!tmp_col!"
call dungeon.cmd :coordInBounds "tmp_coord" && goto :dungeonBuildTunnelAfterWhile
call rng.cmd :randomNumber %config.dungeon.dun_random_dir%
if "!errorlevel!"=="1" (
    call :chanceOfRandomDirection "y_direction" "x_direction"
) else (
    call :pickCorrectDirection "y_direction" "x_direction" "%~1" "%~2"
)
set /a tmp_row=!start.y! + !y_direction!
set /a tmp_col=!start.x! + !x_direction!
:dungeonBuildTunnelAfterWhile

if "!dg.floor[%tmp_row%][%tmp_col%].feature_id!"=="%tile_null_wall%" (
    set "start.y=!tmp_row!"
    set "start.x=!tmp_col!"
    if !tunnel_index! LSS 1000 (
        set "tunnels_tk[!tunnel_index!].y=!start.y!"
        set "tunnels_tk[!tunnel_index!].x=!start.x!"
        set /a tunnel_index+=1
    )
    set "door_flag=false"
    goto :dungeonBuildTunnelAfterSwitch
) else if "!dg.floor[%tmp_row%][%tmp_col%].feature_id!"=="%tmp2_wall%" (
    goto :dungeonBuildTunnelAfterSwitch
) else if "!dg.floor[%tmp_row%][%tmp_col%].feature_id!"=="%tile_granite_wall%" (
    set "start.y=!tmp_row!"
    set "start.x=!tmp_col!"

    if !wall_index! LSS 1000 (
        set "walls_tk[!wall_index!].y=!start.y!"
        set "walls_tk[!wall_index!].x=!start.x!"
        set /a wall_index+=1
    )

    set /a start.y_dec=!start.y!-1, start.y_inc=!start.y!+1
    set /a start.x_dec=!start.x!-1, start.x_inc=!start.x!+1
    for /L %%Y in (!start.y_dec!,1,!start.y_inc!) do (
        for /L %%X in (!start.x_dec!,1,!start.x_inc!) do (
            set "tmp_coord=%%Y;%%X"
            call dungeon.cmd :coordInBounds "tmp_coord" && (
                if "!dg.floor[%%Y][%%X].feature_id!"=="%tile_granite_wall%" (
                    set "dg.floor[%%Y][%%X].feature_id=%tmp2_wall%"
                )
            )
        )
    )
    goto :dungeonBuildTunnelAfterSwitch
) else if !dg.floor[%tmp_row%][%tmp_col%].feature_id! GEQ %tile_corr_floor% (
    if !dg.floor[%tmp_row%][%tmp_col%].feature_id! LEQ %tile_blocked_floor% (
        set "start.y=!tmp_row!"
        set "start.x=!tmp_col!"

        if "!door_flag!"=="false" (
            if !door_index! LSS 100 (
                set "doors_tk[!door_index!].y=!start.y!"
                set "doors_tk[!door_index!].x=!start.x!"
                set /a door_index+=1
            )
            set "door_flag=true"
        )

        call rng.cmd :randomNumber 100
        if !errorlevel! GTR %config.dungeon.dun_tunneling% (
            set /a tmp_row=!start.y! - !start_row!
            if !tmp_row! LSS 0 set "tmp_row=-!tmp_row!"
            
            set /a tmp_col=!start.x! - !start_col!
            if !tmp_col! LSS 0 set "tmp_col=-!tmp_col!"

            if !tmp_row! GTR 10 set "stop_flag=true"
            if !tmp_col! GTR 10 set "stop_flag=true"
        )
        goto :dungeonBuildTunnelAfterSwitch
    )
) else (
    set "start.y=!tmp_row!"
    set "start.x=!tmp_col!"
)

:dungeonBuildTunnelAfterSwitch
if "!stop_flag!"=="false" (
    if not "!start.y!"=="!end.y!" goto :dungeonBuildTunnelDoLoop
    if not "!start.x!"=="!end.x!" goto :dungeonBuildTunnelDoLoop
)

set /a tunnel_index-=1
for /L %%A in (0,1,!tunnel_index!) do (
    set "dg.floor[!tunnels_tk[%%A].y!][!tunnels_tk[%%A].x!].feature_id=%tile_corr_floor%"
)

set /a wall_index-=1
for /L %%A in (0,1,!wall_index!) do (
    set "tile=dg.floor[!walls_tk[%%A].y!][!walls_tk[%%A].x!]"
    for /f "delims=" %%B in ("!tile!") do (
        if "!%%A.feature_id!"=="%tmp2_wall%" (
            call rng.cmd :randomNumber 100
            if !errorlevel! LSS %config.dungeon.dun_room_doors% (
                call :dungeonPlaceDoor "!walls_tk[%%A].y!;!walls_tk[%%A].x!"
            ) else (
                set "!tile!.feature_id=%tile_corr_floor%"
            )
        )
    )
)
exit /b

::------------------------------------------------------------------------------
:: Determine if specified coordinates are next to two walls
::
:: Arguments: %1 - The coordinates to check
:: Returns:   0 if coord is next to two walls
::            1 if coord is not next to two walls
::------------------------------------------------------------------------------
:dungeonIsNextTo
for /F "tokens=1,2 delims=;" %%A in ("%~1") do (
    set /a coord.y==%%~A, coord.x=%%~B
    set /a coord.y_dec=!coord.y!-1, coord.y_inc=!coord.y!+1
    set /a coord.x_dec=!coord.x!-1, coord.x_inc=!coord.x!+1
)

set "coord=%~1"
call dungeon.cmd :coordCorridorWallsNextTo "coord"
if !errorlevel! GTR 2 (
    if !dg.floor[%coord.y_dec%][%coord.x%].feature_id! GEQ %min_cave_wall% (
        if !dg.floor[%coord.y_inc%][%coord.x%].feature_id! GEQ %min_cave_wall% (
            exit /b 0
        )
    )
    if !dg.floor[%coord.y%][%coord.x_dec%].feature_id! GEQ %min_cave_wall% (
        if !dg.floor[%coord.y%][%coord.x_inc%].feature_id! GEQ %min_cave_wall% (
            exit /b 0
        )
    )
)
exit /b 1

::------------------------------------------------------------------------------
:: Places a door at the given coordinates if at least two walls are found
::
:: Arguments: %1 - The coordinates to place the door at
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonPlaceDoorIfNextToTwoWalls
for /F "tokens=1,2 delims=;" %%A in ("%~1") do (
    if "!dg.floor[%%A][%%B].feature_id!"=="%tile_corr_floor%" (
        call rng.cmd :randomNumber 100
        if !errorlevel! GTR %config.dungeon.dun_tunnel_doors% (
            call :dungeonIsNextTo "%~1" && (
                call :dungeonPlaceDoor "%~1"
            )
        )
    )
)
exit /b

::------------------------------------------------------------------------------
:: Return random coordinates
::
:: Arguments: %1 - The name of the variable to store the new coordinates in
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonNewSpot
set /a height_offset=%dg.height%-2, width_offset=%dg.width%-2
call rng.cmd :randomNumber %height_offset%
set "position.y=!errorlevel!"
call rng.cmd :randomNumber %width_offset%
set "position.x=!errorlevel!"
if !dg.floor[%position.y%][%position.x%].feature_id! GEQ %min_closed_space% goto :dungeonNewSpot
if !dg.floor[%position.y%][%position.x%].creature_id! NEQ 0 goto :dungeonNewSpot
if !dg.floor[%position.y%][%position.x%].treasure_id! NEQ 0 goto :dungeonNewSpot

set "%~1.y=!position.y!"
set "%~1.x=!position.x!"
exit /b

::------------------------------------------------------------------------------
:: Determines if a specified tile is a room floor tile
::
:: Arguments: %1 - The ID of the tile to check
:: Returns:   0 if the tile is a dark_floor tile or a light_floor tile
::            1 if the tile is neither a dark_floor tile nor a light_floor tile
::------------------------------------------------------------------------------
:setRooms
if "%~1"=="%tile_dark_floor%" exit /b 0
if "%~1"=="%tile_light_floor%" exit /b 0
exit /b 1

::------------------------------------------------------------------------------
:: Determines if a specified tile is a hallway floor tile
::
:: Arguments: %1 - The ID of the tile to check
:: Returns:   0 if the tile is a coor_floor tile or a blocked_floor tile
::            1 if the tile is neither a coor_floor nor a blocked_floor tile
::------------------------------------------------------------------------------
:setCorridors
if "%~1"=="%tile_coor_floor%" exit /b 0
if "%~1"=="%tile_blocked_floor%" exit /b 0
exit /b 1

::------------------------------------------------------------------------------
:: Determines if a specified tile is a valid floor tile
::
:: Arguments: %1 - The ID of the tile to check
:: Returns:   0 if the tile ID is under the max_cave_floor threshold
::            1 if the tile is not a valid floor tile
::------------------------------------------------------------------------------
:setFloors
if %~1 LEQ %max_cave_floor% exit /b 0
exit /b 1

::------------------------------------------------------------------------------
:: Wrapper subroutine for generating a new dungeon
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonGenerate
set /a "row_rooms=2 * (%dg.height% / %screen_height%)"
set /a "col_rooms=2 * (%dg.width% / %screen_width%)"
set /a row_rooms_dec=!row_rooms!-1, col_rooms_dec=!col_rooms!-1

for /L %%Y in (0,1,!row_rooms_dec!) do (
    for /L %%X in (0,1,!col_rooms_dec!) do (
        set "room_map[%%Y][%%X]=false"
    )
)

call game.cmd :randomNumberNormalDistribution %config.dungeon.dun_rooms_mean% 2
set /a random_room_count=!errorlevel! - 1
for /L %%A in (0,1,!random_room_count!) do (
    call rng.cmd :randomNumber !row_rooms!
    set /a rnd_row=!errorlevel!-1
    call rng.cmd :randomNumber !col_rooms!
    set /a rnd_col=!errorlevel!-1

    set "room_map[!rnd_row!][!rnd_col!]=true"
)

:: Build rooms
set "location_id=0"
for /L %%Y in (0,1,!row_rooms_dec!) do (
    for /L %%X in (0,1,!col_rooms_dec!) do (
        if "!room_map[%%Y][%%X]!"=="true" (
            set /a "locations[!location_id!].y=%%Y * (%screen_height% >> 1) + %quart_height%"
            set /a "locations[!location_id!].x=%%X * (%screen_width% >> 1) + %quart_width%"

            for /f "delims=" %%A in ("!location_id!") do (
                set "loc_coord=!locations[%%A].y!;!locations[%%A].x!"
            )
            call rng.cmd :randomNumber %config.dungeon.dun_unusual_rooms%
            if %dg.current_level% GTR !errorlevel! (
                call rng.cmd :randomNumber 3
                set "room_type=!errorlevel!"

                if "!room_type!"=="1" (
                    call :dungeonBuildRoomOverlappingRectangles "!loc_coord!"
                ) else if "!room_type!"=="2" (
                    call :dungeonBuildRoomWithInnerRooms "!loc_coord!"
                ) else (
                    call :dungeonBuildRoomCrossShaped "!loc_coord!"
                )
            ) else (
                call :dungeonBuildRoom "!loc_coord!"
            )
            set /a location_id+=1
        )
    )
)

for /L %%A in (1,1,!location_id!) do (
    call rng.cmd :randomNumber !location_id!
    set /a pick1=!errorlevel!-1
    call rng.cmd :randomNumber !location_id!
    set /a pick2=!errorlevel!-1

    for /f "tokens=1,2" %%B in ("!pick1! !pick2!") do (
        set "y=!locations[%%B].y!"
        set "x=!locations[%%B].x!"
        set "locations[%%B].y=!locations[%%C].y!"
        set "locations[%%B].x=!locations[%%C].x!"
        set "locations[%%C].y=!y!"
        set "locations[%%C].x=!x!"
    )
)
set "door_index=0"

set "locations[!location_id!].y=!locations[0].y!"
set "locations[!location_id!].x=!locations[0].x!"

for /L %%A in (1,1,!location_id!) do (
    set /a location_id_dec=%%A-1
    set "start_loc=!locations[%%A].y!;!locations[%%A].x!"
    for /f "delims=" %%B in ("!location_id_dec!") do (
        set "end_loc=!locations[%%B].y!;!locations[%%B].x!"
    )
    call :dungeonBuildTunnel "!start_loc!" "!end_loc!"
)

:: Generate walls and streamers
call :dungeonFillEmptyTilesWith "%tile_granite_wall%"
for /L %%A in (1,1,%config.dungeon.dun_magma_streamer%) do (
    call :dungeonPlaceStreamerRock %tile_magma_wall% %config.dungeon.dun_magma_treasure%
)
for /L %%A in (1,1,%config.dungeon.dun_quartz_streamer%) do (
    call :dungeonPlaceStreamerRock %tile_quartz_wall% %config.dungeon.dun_quartz_treasure%
)
call :dungeonPlaceBoundaryWalls

:: Place intersection doors
set /a door_index-=1
for /L %%A in (0,1,!door_index!) do (
    set /a x_dec=!doors_tk[%%A].x!-1, x_inc=!doors_tk[%%A].x!+1
    set /a y_dec=!doors_tk[%%A].y!-1, y_inc=!doors_tk[%%A].y!+1

    call :dungeonPlaceDoorIfNextToTwoWalls "!doors_tk[%%A].y!;!x_dec!"
    call :dungeonPlaceDoorIfNextToTwoWalls "!doors_tk[%%A].y!;!x_inc!"
    call :dungeonPlaceDoorIfNextToTwoWalls "!y_dec!;!doors_tk[%%A].x!"
    call :dungeonPlaceDoorIfNextToTwoWalls "!y_inc!;!doors_tk[%%A].x!"
)
set /a door_index+=1

set /a alloc_level=%dg.current_level%/3
if %alloc_level% LSS 2 (
    set "alloc_level=2"
) else if %alloc_level% GTR 10 (
    set "alloc_level=10"
)

call rng.cmd :randomNumber 2
set /a down_stair_count=!errorlevel!+2
call :dungeonPlaceStairs 2 !down_stair_count! 3
call rng.cmd :randomNumber 2
call :dungeonPlaceStairs 1 !errorlevel! 3

:: Set up character coordinates for placing monsters
call :dungeonNewSpot "coord"
set "py.pos.y=!coord.y!"
set "py.pos.x=!coord.x!"

call rng.cmd :randomNumber 8
set /a monster_count=!errorlevel! + %config.monsters.mon_min_per_level% + %alloc_level%
call monster_manager.cmd :monsterPlaceNewWithinDistance !monster_count! 0 "true"

call rng.cmd :randomNumber %alloc_level%
call dungeon.cmd :dungeonAllocateAndPlaceObject "dungeon_generate.cmd :setCorridors" 3 !errorlevel!
call game.cmd :randomNumberNormalDistribution "%config.dungeon.objects.level_objects_per_room%" 3
call dungeon.cmd :dungeonAllocateAndPlaceObject "dungeon_generate.cmd :setRooms" 5 !errorlevel!
call game.cmd :randomNumberNormalDistribution "%config.dungeon.objects.level_objects_per_corridor%" 3
call dungeon.cmd :dungeonAllocateAndPlaceObject "dungeon_generate.cmd :setFloors" 5 !errorlevel!
call game.cmd :randomNumberNormalDistribution "%config.dungeon.objects.level_total_gold_and_gems%" 3
call dungeon.cmd :dungeonAllocateAndPlaceObject "dungeon_generate.cmd :setFloors" 4 !errorlevel!
call rng.cmd :randomNumber %alloc_level%
call dungeon.cmd :dungeonAllocateAndPlaceObject "dungeon_generate.cmd :setFloors" 1 !errorlevel!

if %dg.current_level% GEQ %config.monsters.mon_endgame_level% call monster_manager.cmd :monsterPlaceWinning
exit /b

::------------------------------------------------------------------------------
:: Builds a store at specified coordinates
::
:: Arguments: %1 - The type of store to build
::            %2 - The desired location of the new store
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonBuildStore
for /f "tokens=1,2 delims=;" %%A in ("%~2") do (
    set /a y_val=%%A * 10 + 5
    set /a x_val=%%A * 16 + 16
)
call rng.cmd :randomNumber 3
set /a height=!y_val! - !errorlevel!
call rng.cmd :randomNumber 4
set /a depth=!y_val! + !errorlevel!
call rng.cmd :randomNumber 6
set /a left=!x_val! - !errorlevel!
call rng.cmd :randomNumber 6
set /a right=!x_val! + !errorlevel!

for /L %%Y in (!height!,1,!depth!) do (
    for /L %%X in (!left!,1,!right!) do (
        set "dg.floor[%%Y][%%X].feature_id=%tile_boundary_wall%"
    )
)

call rng.cmd :randomNumber 4
set "tmp_val=!errorlevel!"
if !tmp_val! LSS 3 (
    set /a y_diff=!depth! - !height!
    call rng.cmd :randomNumber !y_diff!
    set /a y=!errorlevel! + !height! - 1

    if "!tmp_val!"=="1" (
        set "x=!left!"
    ) else (
        set "x=!right!"
    )
) else (
    set /a x_diff=!right! - !left!
    call rng.cmd :randomNumber !x_diff!
    set /a x=!errorlevel! + !left! - 1

    if "!tmp_val!"=="3" (
        set "y=!depth!"
    ) else (
        set "y=!height!"
    )
)

set "dg.floor[!y!][!x!].feature_id=%tile_corr_floor%"
call game_objects.cmd :popt
set "cur_pos=!errorlevel!"
set "dg.floor[!y!][!x!].treasure_id=%cur_pos%"

set /a store_door=%config.dungeon.objects.obj_store_door% + %~1
call inventory.cmd :inventoryItemCopyTo !store_door! "game.treasure.list[%cur_pos%]"
exit /b

::------------------------------------------------------------------------------
:: Link all free space in treasure list together
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:treasureLinker
for /L %%A in (0,1,174) do (
    call inventory.cmd :inventoryItemCopyTo "%config.dungeon.objects.obj_nothing%" "game.treasure.list[%%~A]"
)
set "game.treasure.current_id=%config.treasure.min_treasure_list_id%"
exit /b

::------------------------------------------------------------------------------
:: Link all free space in monster list together
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:monsterLinker
for /L %%A in (0,1,124) do (
    set "monsters[%%A].hp=0"
    set "monsters[%%A].sleep_count=0"
    set "monsters[%%A].speed=0"
    set "monsters[%%A].creature_id=0"
    set "monsters[%%A].pos.x=0"
    set "monsters[%%A].pos.y=0"
    set "monsters[%%A].distance_from_player=0"
    set "monsters[%%A].lit=false"
    set "monsters[%%A].stunned_amount=0"
    set "monsters[%%A].confused_amount=0"
)
set "next_free_monster_id=%config.monsters.mon_min_index_id%"
exit /b

::------------------------------------------------------------------------------
:: Place the six stores on the town map
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonPlaceTownStores
for /L %%A in (0,1,5) do set "rooms[%%A]=%%A"
set "rooms_count=6"

for /L %%Y in (0,1,1) do (
    for /L %%X in (0,1,2) do (
        call rng.cmd :randomNumber !rooms_count!
        set /a room_id=!errorlevel!-1

        for /f "delims=" %%A in ("!room_id!") do (
            call :dungeonBuildRoom !rooms[%%A]! "%%Y;%%X"
        )

        set /a rooms_count_dec=!rooms_count!-2
        for /L %%A in (!room_id!,1,!rooms_dec_count!) do (
            set /a a_inc=%%A+1
            for /f "delims=" %%B in ("!a_inc!") do (
                set "rooms[%%A]=!rooms[%%B]!"
            )
        )

        set /a rooms_count-=1
    )
)
exit /b

::------------------------------------------------------------------------------
:: Every 5000 turns, the town toggles between day and night
::
:: Arguments: None
:: Returns:   0 if it is currently nighttime
::            1 if it is currently daytime
::------------------------------------------------------------------------------
:isNighTime
set /a "is_night=1 & (%dg.game_turn% / 5000)"
if "!is_night!"=="0" exit /b 1
exit /b 0

::------------------------------------------------------------------------------
:: Lights the town based on the current time of day
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:lightTown
set /a height_dec=%dg.height%-1, width_dec=%dg.width%-1
call :isNighTime
if "!errorlevel!"=="0" (
    for /L %%Y in (0,1,%height_dec%) do (
        for /L %%X in (0,1,%width_dec%) do (
            if not "!dg.floor[%%Y][%%X].feature_id!"=="%tile_dark_floor%" (
                set "dg.floor[%%Y][%%X].permanent_light=true"
            )
        )
    )
    call monster_manager.cmd :monsterPlaceNewWithinDistance %config.monsters.mon_min_townsfolk_night% 3 "true"
) else (
    for /L %%Y in (0,1,%height_dec%) do (
        for /L %%X in (0,1,%width_dec%) do (
            set "dg.floor[%%Y][%%X].permanent_light=true"
        )
    )
    call monster_manager.cmd :monsterPlaceNewWithinDistance %config.monsters.mon_min_townsfolk_day% 3 "true"
)
exit /b

::------------------------------------------------------------------------------
:: Wrapper subroutine for generating a town level
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:townGeneration
call game.cmd :seedSet %game.town_seed%
call :dungeonPlaceTownStores
call :dungeonFillEmptyTilesWith %tile_dark_floor%
call :dungeonPlaceBoundaryWalls
call :dungeonPlaceStairs 2 1 0
call game.cmd :seedResetToOldSeed

call :dungeonNewSpot "coord"
set "py.pos.y=!coord.y!"
set "py.pos.x=!coord.x!"

call :lightTown
call store_inventory.cmd :storeMaintenance
exit /b

::------------------------------------------------------------------------------
:: Generates a random dungeon level
::
:: Arguments: None
:: Returnss:  None
::------------------------------------------------------------------------------
:generateCave
set "dg.panel.top=0"
set "dg.panel.bottom=0"
set "dg.panel.left=0"
set "dg.panel.right=0"

set "py.pos.y=-1"
set "py.pos.x=-1"

call :treasureLinker
call :monsterLinker
call :dungeonBlankEntireCave

set "dg.height=%max_height%"
set "dg.width=%max_width%"

if "%dg.current_level%"=="0" (
    set "dg.height=%screen_height%"
    set "dg.width=%screen_width%"
)

set /a "dg.panel.max_rows=(%dg.height% / %screen_height%) * 2 - 2"
set /a "dg.panel.max_cols=(%dg.width% / %screen_width%) * 2 - 2"

set "dg.panel.row=%dg.panel.max_rows%"
set "dg.panel.col=%dg.panel.max_cols%"

if "%dg.current_level%"=="0" (
    call :townGeneration
) else (
    call :dungeonGenerate
)
exit /b