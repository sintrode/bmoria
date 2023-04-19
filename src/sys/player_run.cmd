call %*
exit /b

::------------------------------------------------------------------------------
:: Determine if the player can actually see the wall of if they'll find it the
:: hard way momentarily
::
:: Arguments: %1 - The direction to look in
::            %2 - The current coordinates of the player
:: Returns:   0 if there is a wall tile adjacent to the player
::            1 if there is no wall touching the player
::------------------------------------------------------------------------------
:playerCanSeeDungeonWall
set "coord=%~2"
call player.cmd :playerMovePosition "%~1" "coord" || exit /b 0

:: TODO: Remember to store the tile symbol in the second argument
call dungeon.cmd :caveGetTileSymbol "coord" c
if "!c!"=="#" exit /b 0
if "!c!"=="%%" exit /b 0
exit /b 1

::------------------------------------------------------------------------------
:: Checks to see if there's anything at all around the player
::
:: Arguments: %1 - The direction to look in
::            %2 - The current coordinates of the player
:: Returns:   0 if movement to the specified location is possible
::            1 if the player can not move to the given coordinates
::------------------------------------------------------------------------------
:playerSeeNothing
set "coord=%~2"
call player.cmd :playerMovePosition "%~1" "coord"
set "can_move=!errorlevel!"

call dungeon.cmd :caveGetTileSymbol "coord" c

if "!can_move!"=="0" (
    if "!c!"==" " (
        exit /b 0
    )
)
exit /b 1

::------------------------------------------------------------------------------
:: Determine when to stop running
::
:: Arguments: %1 - The direction the player is running in
::            %2 - The current coordinates of the player
:: Returns:   None
::------------------------------------------------------------------------------
:findRunningBreak
for %%A in (deep_left deep_right short_left short_right) do set "%%~A=false"
set "cycle_index=!chrome[%~1]!"
set /a cycle_index_dec=cycle_index-1, cycle_index_inc=cycle_index+1
set /a cycle_index_ddec=cycle_index-2, cycle_index_iinc=cycle_index+2

call :playerCanSeeDungeonWall !cycle[%cycle_index_inc%]! "%py.pos.y%;%py.pos.x%"
if "!errorlevel!"=="0" (
    set "find_breakleft=true"
    set "short_left=true"
) else (
    call :playerCanSeeDungeonWall !cycle[%cycle_index_inc%]! "%~2"
    if "!errorlevel!"=="0" (
        set "find_breakleft=true"
        set "short_left=true"
    )
)

call :playerCanSeeDungeonWall !cycle[%cycle_index_dec%]! "%py.pos.y%;%py.pos.x%"
if "!errorlevel!"=="0" (
    set "find_breakright=true"
    set "short_right=true"
) else (
    call :playerCanSeeDungeonWall !cycle[%cycle_index_dec%]! "%~2"
    if "!errorlevel!"=="0" (
        set "find_breakright=true"
        set "short_right=true"
    )
)

set "find_openarea=true"
if "!find_breakleft!"=="true" (
    if "!find_breakright!"=="true" (
        set "find_openarea=false"

        set /a "is_angled=%~1 & 1"
        if not "!is_angled!"=="0" (
            if "!deep_left!"=="true" if "!deep_right!"=="false" set "find_prevdir=!cycle[%cycle_index_dec%]!"
            if "!deep_left!"=="false" if "!deep_right!"=="true" set "find_prevdir=!cycle[%cycle_index_inc%]!"
        ) else (
            call :playerCanSeeDungeonWall !cycle[%cycle_index%]! "%~2" && (
                if "!short_left!"=="true" if "!short_right!"=="false" set "find_prevdir=!cycle[%cycle_index_ddec%]!"
                if "!short_left!"=="false" if "!short_right!"=="true" set "find_prevdir=!cycle[%cycle_index_iinc%]!"
            )
        )
    )
)
exit /b

::------------------------------------------------------------------------------
:: Start running
::
:: Arguments: %1 - The direction to run in
:: Returns:   None
::------------------------------------------------------------------------------
:playerFindInitialize
set "coord.y=%py.pos.y%"
set "coord.x=%py.pos.x%"

call player.cmd :playerMovePosition "%~1" "coord"
if "!errorlevel!"=="1" (
    set "py.running_tracker=0"
) else (
    set "py.running_tracker=1"

    set "find_direction=%~1"
    set "find_prevdir=%~1"
    set "find_breakright=false"
    set "find_breakleft=false"

    if %py.flags.blind% LSS 1 (
        call :findRunningBreak "%~1" "%coord.y%;%coord.x%"
    )
)

if "%py.temporary_light_only%"=="false" (
    if "%config.options.run_print_self%"=="false" (
        call dungeon.cmd :caveGetTileSymbol "py.pos" c
        call ui_io.cmd :panelPutTile "!c!" "%py.pos.y%;%py.pos.x%"
    )
)

call player_move.cmd :playerMove "%~1" "true"

if "%py.running_tracker%"=="0" (
    set "game.command_count=0"
)
exit /b

::------------------------------------------------------------------------------
:: Do the actual running part
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerRunAndFind
set "tracker=%py.running_tracker%"
set /a py.running_tracker+=1

if !tracker! GTR 100 (
    call ui_io.cmd :printMessage "You stop running to catch your breath."
    call :playerEndRunning
    exit /b
)

call player_move.cmd :playerMove "!find_direction!" "true"
exit /b

::------------------------------------------------------------------------------
:: Stop running and turn the lights on
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:playerEndRunning
if "%py.running_tracker%"=="0" exit /b

:: Only light up the current spot
set "py.running_tracker=0"
call dungeon.cmd :dungeonMoveCharacterLight "py.pos" "py.pos"
exit /b

::------------------------------------------------------------------------------
:: Look at the tiles to determine if the player should stop running
:: 
:: Arguments: %1 - A specified adjacent tile
::            %2 - The direction the player is currently running in
::            %3 - A direction that the player could run in
::            %4 - The coordinates of the player
::            %5 - A variable to store one potential new direction
::            %6 - A variable to store a second potential new direction
:: Returns:   0 if the player should stop running
::            1 if the player may continue running
::------------------------------------------------------------------------------
:areaAffectStopLookingAtSquares
for /f "tokens=1,2 delims=;" %%A in ("%~4") do set "tile=dg.floor[%%~A][%%~B]"
set "invisible=true"

set "is_lit=false"
if "%py.carrying_light%"=="true" set "is_lit=true"
if "!%tile%.temporary_light!"=="true" set "is_lit=true"
if "!%tile%.permanent_light!"=="true" set "is_lit=true"
if "!%tile%.field_mark!"=="true" set "is_lit=true"

set "tile.treasure_id=!%tile%.treasure_id!"
set "tile.creature_id=!%tile%.creature_id!"
if "%is_lit%"=="true" (
    if not "%tile.treasure_id%"=="0" (
        set "tile_id=!game.treasure.list[%tile.treasure_id%].category_id!"

        if not "!tile_id!"=="%tv_invis_trap%" (
            if not "!tile_id!"=="%tv_secret_door%" (
                if not "!tile_id!"=="%tv_open_door%" (
                    call :playerEndRunning
                    exit /b 0
                )
                if "%config.options.run_ignore_doors%"=="false" (
                    call :playerEndRunning
                    exit /b 0
                )
            )
        )
    )

    if %tile.creature_id% GTR 1 (
        if "!monsters[%tile.creature_id%].lit!"=="true" (
            call :playerEndRunning
            exit /b 0
        )
    )
    set "invisible=false"
)

set /a cycle_adj=!chrome[%~2]! + %~1 - 1
set "check_for_breaks=%invisible%"
if !%tile%.feature_id! LSS %max_open_space% set "check_for_breaks=true"
if "%check_for_breaks%"=="true" (
    if "%find_openarea%"=="true" (
        if %~1 LSS 0 (
            if "!find_breakright!"=="true" (
                call :playerEndRunning
                exit /b 0
            )
        ) else if %~1 GTR 0 (
            if "!find_breakleft!"=="true" (
                call :playerEndRunning
                exit /b 0
            )
        )
    ) else if "!%~5!"=="0" (
        set "%~5=!%~3!"
    ) else if not "!%~6!"=="0" (
        call :playerEndRunning
        exit /b 0
    ) else if not "!%~5!"=="!cycle[%cycle_adj%]!" (
        call :playerEndRunning
        exit /b 0
    ) else (
        set /a "is_diagonal=!%~3! & 1"
        if "!is_diagonal!"=="1" (
            set /a cycle_offset=!chrome[%~2]! + %~1 - 2
            for /f "delims=" %%A in ("!cycle_offset!") do set "check_dir=!cycle[%%~A]!"
            set "%~6=!%~3!"
        ) else (
            set /a cycle_offset=!chrome[%~2]! + %~1 + 1
            for /f "delims=" %%A in ("!cycle_offset!") do set "check_dir=!cycle[%%~A]!"
            set "%~6=!%~5!"
            set "%~5=!%~3!"
        )
    )
) else if "%find_openarea%"=="true" (
    if !%~1! LSS 0 (
        if "!find_breakleft!"=="true" (
            call :playerEndRunning
            exit /b 0
        )
    ) else if !%~1! GTR 0 (
        if "!find_breakright!"=="true" (
            call :playerEndRunning
            exit /b 0
        )
    )
)
exit /b 1

::------------------------------------------------------------------------------
:: Determine the next direction for a run, or if the player should stop
::
:: Arguments: %1 - The current direction that the player is facing
::            %2 - The current position of the player
:: Returns:   None
::------------------------------------------------------------------------------
:playerAreaAffect
if %py.flags.blind% GEQ 1 exit /b

set /a check_dir=0, dir_a=0, dir_b=0
set "direction=!find_prevdir!"
set /a "dir_is_diag=!direction! & 1"
set /a max=!dir_is_diag!+1

for /L %%A in (-%max%, 1, %max%) do (
    set /a cycle_inc=!chrome[%~1]! + %%A
    for /f %%B in ("!cycle_inc!") do set "new_dir=!cycle![%%~B]!"

    set "spot=0;0"
    call player.cmd :playerMovePosition "!new_dir!" "spot" && (
        cal :areaAffectStopLookingAtSquares "%%~A" "!direction!" "!new_dir!" "!spot.y!;!spot.x!" "check_dir" "dir_a" "dir_b"
    )
)

if "!find_openarea!"=="true" exit /b

set "no_corners=false"
if "!dir_b!"=="0" set "no_corners=true"
if "%config.options.run_examine_corners%"=="true" (
    if "%config.options.run_cut_corners%"=="false" (
        set "no_corners=true"
    )
)
if "!no_corners!"=="true" (
    if not "!dir_a!"=="0" set "find_direction=!dir_a!"
    
    if "!dir_b!"=="0" (
        set "find_prevdir=!dir_a!"
    ) else (
        set "find_prevdir=!dir_b!"
    )
    exit /b
)

set "location=%~2"
call player.cmd :playerMovePosition "!dir_a!" "location"

set "could_move=false"
call :playerCanSeeDungeonWall "!dir_a!" "!location.y!;!location.x!" || set "could_move=true"
call :playerCanSeeDungeonWall "!check_dir!" "!location.y!;!location.x!" || set "could_move=true"
if "%could_move%"=="true" (
    set "keep_moving=%config.options.run_examine_corners%"
    call :playerSeeNothing "!dir_a!" "!location.y!;!location.x!" && set "keep_moving=true"
    call :playerSeeNothing "!dir_b!" "!location.y!;!location.x!" && set "keep_moving=true"

    if "!keep_moving!"=="true" (
        set "find_direction=!dir_a!"
        set "find_prevdir=!dir_b!"
    ) else (
        call :playerEndRunning
    )
) else if "%config.options.run_cut_corners%"=="true" (
    set "find_direction=!dir_b!"
    set "find_prevdir=!dir_b!"
) else (
    set "find_direction=!dir_a!"
    set "find_prevdir=!dir_b!"
)
exit /b
