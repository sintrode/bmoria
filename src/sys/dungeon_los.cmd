
@echo off
call %*
exit /b

::------------------------------------------------------------------------------
:: A simple, fast, integer-based line-of-sight algorithm.  By Joseph Hall,
:: 4116 Brewster Drive, Raleigh NC 27606.  Email to jnh@ecemwl.ncsu.edu.
::
:: Returns true if a line of sight can be traced from x0, y0 to x1, y1.
::
:: The LOS begins at the center of the tile [x0, y0] and ends at the center of
:: the tile [x1, y1].  If los() is to return true, all of the tiles this line
:: passes through must be transparent, WITH THE EXCEPTIONS of the starting and
:: ending tiles.
::
:: We don't consider the line to be "passing through" a tile if it only passes
:: across one corner of that tile.
::
:: Because this function uses (short) ints for all calculations, overflow may
:: occur if deltaX and deltaY exceed 90.
::------------------------------------------------------------------------------
:: Arguments: %1 - Originating coordinates
::            %2 - Target coordinates
:: Returns:   0 if the target coordinates can be seen from the origin
::            1 otherwise
::------------------------------------------------------------------------------
:los
for /f "tokens=1,2 delims=;" %%A in ("%~1") do set /a "from.y=%%A", "from.x=%%B"
for /f "tokens=1,2 delims=;" %%A in ("%~2") do set /a "to.y=%%A", "to.x=%%B"
set /a delta_x=%to.x%-%from.x%, delta_y=%to.y%-%from.y%

:: Return true if the tiles are adjacent
if %delta_x% LSS 2 if %delta_x% GTR -2 if %delta_y% LSS 2 if %delta_y% GTR -2 exit /b 0

:: Handle cases where delta_x or delta_y are 0
if "%delta_x%"=="0" (
    if %delta_y% LSS 0 (
        set "tmp_y=!from.y!"
        set "from.y=!to.y!"
        set "to.y=!tmp_y!"
    )

    set /a from_inc=!from.y!+1, to_dec=!to.y!-1
    for /L %%Y in (!from_inc!,1,!to_dec!) do (
        if !dg.floor[%%Y][%from.x%].feature_id! GEQ %min_closed_space% exit /b 1
    )

    exit /b 0
)

if "%delta_y%"=="0" (
    if %delta_x% LSS 0 (
        set "tmp_x=!from.x!"
        set "from.x=!to.x!"
        set "to.x=!tmp_x!"
    )

    set /a from_inc=!from.x!+1, to_dec=!to.x!-1
    for /L %%X in (!from_inc!,1,!to_dec!) do (
        if !dg.floor[%from.y%][%%X].feature_id! GEQ %min_closed_space% exit /b 1
    )

    exit /b 0
)

set /a delta_multiply=%delta_x%*%delta_y%
set "scale_half=%delta_multiply%"
if %scale_half% LSS 0 set /a scale_half*=-1
set /a "scale=%scale_half%<<1"

for %%A in (x y) do (
    if !delta_%%A! LSS 0 (set "%%A_sign=-1") else (set "%%A_sign=1")
    set "abs_delta_%%A=!delta_%%A!"
    if !abs_delta_%%A! LSS 0 set /a abs_delta_%%A*=-1
)

if %abs_delta_x% GEQ %abs_delta_y% (
    REM We start at the border between the first and second tiles, where
    REM the y offset = .5 * slope.  Remember the scale factor.
    REM
    REM We have:     slope = delta_y / delta_x * 2 * (delta_y * delta_x)
    REM                    = 2 * delta_y * delta_y.
    set /a dy=%delta_y%*%delta_y%
    set /a "slope=!dy!<<1"
    set /a xx=%from_x%+%x_sign%

    REM Consider the special case where slope is 1
    if "!dy!"=="%scale_half%" (
        set /a yy=%from.y%+%y_sign%
        set /a dy-=!scale!
    ) else (
        set "yy=%from.y%"
    )

    call :los_x_loop "to.x" "xx" "x_sign" "yy" "y_sign" "dy" || exit /b 1
    exit /b 0
)

set /a dx=%delta_x%*%delta_x%
set /a "slope=!dx!<<1"
set /a yy=%from.y%+%y_sign%

if "!dx!"=="%scale_half%" (
    set /a xx=%from.x%+%x_sign%
    set /a dx-=%scale%
) else (
    set /a xx=%from.x%
)

call :los_x_loop "to.y" "yy" "y_sign" "xx" "x_sign" "dx"
exit /b 0

:los_x_loop
set /a x_diff=!%~1!-!%~2!
if "!x_diff!"=="0" exit /b 0

for /f "tokens=1,2" %%A in ("!xx! !yy!") do (
    if !dg.floor[%%~B][%%~A].feature_id! GEQ %min_closed_space% exit /b 1
)

set /a %~6+=!slope!

if !%~6! LSS %scale_half% (
    set /a %~2+=!%~3!
) else if !%~6! GTR %scale_half% (
    set /a %~2+=!%~3!
    for /f "tokens=1,2" %%A in ("!xx! !yy!") do (
        if !dg.floor[%%~B][%%~A].feature_id! GEQ %min_closed_space% exit /b 1
    )
    set /a %~4+=!%~5!
    set /a %~5-=!scale!
) else (
    set /a %~2+=!%~3!
    set /a %~4+=!%~5!
    set /a %~6-=!scale!
)
goto :los_x_loop

::------------------------------------------------------------------------------
:: Look at what we can see. This is a free move.
::
:: Prompts for a direction, and then looks at every object in turn within a
:: cone of vision in that direction. For each object, the cursor is moved over
:: the object, a description is given, and we wait for the user to type
:: something. Typing Q will abort the entire look.
::
:: Looks first at real objects and monsters, and looks at rock types only after
:: all other things have been seen.  Only looks at rock types if the
:: config.options.highlight_seams option is set.
::------------------------------------------------------------------------------
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:look
if %py.flags.blind% GTR 0 (
    call ui_io.cmd :printMessage "You can't see a thing^^^!"
    exit /b
)

if %py.flags.image% GTR 0 (
    call ui_io.cmd :printMessage "You can't believe what you are seeing^^^! It's like a dream^^^!"
    exit /b
)

call game.cmd :getAllDirections "Look in which direction?" dir || exit /b

set "los_num_places_seen=0"
set "los_rocks_and_objects=0"
set "los_hack_no_query=false"

call :lookSee "0;0" dummy && exit /b

:look_do_while
set "abort=false"
if "!dir!"=="5" (
    for /L %%I in (1,1,4) do (
        set los_fxx=!los_dir_set_fxx[%%I]!
        set los_fyx=!los_dir_set_fyx[%%I]!
        set los_fxy=!los_dir_set_fxy[%%I]!
        set los_fyy=!los_dir_set_fyy[%%I]!

        set /a gradf_offset=2*!gradf!-1
        call :lookRay 0 !gradf_offset! 1 && (
            set "abort=true"
            goto :look_after_while
        )

        set /a los_fxy*=-1
        set /a los_fyy*=-1

        set /a gradf_offset=2*!gradf!
        call :lookRay 0 !gradf_offset! 2 && (
            set "abort=true"
            goto :look_after_while
        )
    )
) else (
    set /a "straight_direction=!dir! & 1"
    if "!straight_direction!"=="0" (
        set /a "i=!dir!>>1"

        for %%I in ("!i!") do (
            set los_fxx=!los_dir_set_fxx[%%I]!
            set los_fyx=!los_dir_set_fyx[%%I]!
            set los_fxy=!los_dir_set_fxy[%%I]!
            set los_fyy=!los_dir_set_fyy[%%I]!
        )

        call :lookRay 0 !gradf! 1
        if "!errorlevel!"=="0" (
            set "abort=true"
        ) else (
            set /a los_fxy*=-1
            set /a los_fyy*=-1
            call :lookRay 0 !gradf! 2
            if "!errorlevel!"=="0" (
                set "abort=true"
            ) else (
                set "abort=false!"
            )
        )
    ) else (
        for /f "delims=" %%A in ('set /a "!dir!>>1"') do (
            set "i=!los_map_diagonals1[%%A]!"
        )
        for %%I in ("!i!") do (
            set los_fxx=!los_dir_set_fxx[%%I]!
            set los_fyx=!los_dir_set_fyx[%%I]!
            set los_fxy=!los_dir_set_fxy[%%I]!
            set los_fyy=!los_dir_set_fyy[%%I]!
        )
        set /a gradf_offset=2*!gradf!
        call :lookRay 1 !gradf_offset! !gradf! 
        if "!errorlevel!"=="0" (
            set "abort=true"
        ) else (
            for /f "delims=" %%A in ('set /a "!dir!>>1"') do (
                set "i=!los_map_diagonals2[%%A]!"
            )
            for %%I in ("!i!") do (
                set los_fxx=!los_dir_set_fxx[%%I]!
                set los_fyx=!los_dir_set_fyx[%%I]!
                set los_fxy=!los_dir_set_fxy[%%I]!
                set los_fyy=!los_dir_set_fyy[%%I]!
            )
            set /a gradf_offset=2*!gradf!-1
            call :lookRay 1 !gradf_offset! !gradf!
            if "!errorlevel!"=="0" (
                set "abort=true"
            ) else (
                set "abort=false!"
            )
        )
    )
)
set /a los_rocks_and_objects+=1

if "%abort%"=="false" (
    if "%config.options.highlight_seams%"=="true" (
        if %los_rocks_and_objects% LSS 2 (
            goto :look_do_while
        )
    )
)
:look_after_while
if "%abort%"=="true" (
    call ui_io.cmd :printMessage "--Aborting look--"
    exit /b
)
if not "%los_num_places_seen%"=="0" (
    if "%dir%"=="5" (
        call ui_io.cmd :printMessage "That's all you see."
    ) else (
        call ui_io.cmd :printMessage "That's all you see in that direction."
    )
) else if "%dir%"=="5" (
    call ui_io.cmd :printMessage "You see nothing of interest."
) else (
    call ui_io.cmd :printMessage "You see nothing of interest in that direction."
)
exit /b

::------------------------------------------------------------------------------
:: Look at everything within a cone of vision between two ray lines emanating
:: from  the player, and y or more places away from the direct line of view.
:: This is recursive.
::
:: Rays are specified by gradients, y over x, multiplied by 2*GRADF. This is ONLY
:: called with gradients between 2*GRADF (45 degrees) and 1 (almost horizontal).
::
::   (y axis)/ angle from
::     ^    /      ___ angle to
::     :   /     ___
::  ...:../.....___.................... parameter y (look at things in the
::     : /   ___                        cone, and on or above this line)
::     :/ ___
::     @-------------------->   direction in which you are looking. (x axis)
::     :
::     :
::------------------------------------------------------------------------------
:: Arguments: %1 - The Y-axis to start on
::            %2 - The gradient of the left side of the vision cone
::            %3 - The gradient of the right side of the vision cone
:: Returns:   0 if the player can see in that direction
::            1 otherwise
::------------------------------------------------------------------------------
:lookRay
set "y=%~1"
set "from=%~2"
set "to=%~3"

:: %from% is the larger angle of the ray, since we scan towards the
:: center line. If %from% is smaller, then the ray does not exist.
if %from% LEQ %to% exit /b 1
if %y% GTR %config.monsters.mon_max_sight% exit /b 1

:: Find first visible location along this line. Minimum x such
:: that (2x-1)/x < from/GRADF <=> x > GRADF(2x-1)/from. This may
:: be called with y=0 whence x will be set to 0. Thus we need a
:: special fix.
set /a "x=!gradf!*(2*!y!-1)/%from%+1"
if %x% LSS 0 set "x=1"

set /a "max_x=(!gradf!*(2*!y!+1)-1)/%to%"
if %max_x% GTR %config.monsters.mon_max_sight% (
    set "max_x=%config.monsters.mon_max_sight%"
)
if %max_x% LSS %x% exit /b 1

:: los_hack_no_query is a HACK to prevent doubling up on direct lines of
:: sight. If %to% is  greater than 1, we do not really look at
:: stuff along the direct line of sight, but we do have to see
:: what is opaque for the purposes of obscuring other objects.
set "los_hack_no_query=false"
set /a double_gradf=!gradf!*2
if "%y%"=="0" if %to% GTR 1 set "los_hack_no_query=true"
if "%y%"=="%x%" if %from% LSS %double_gradf% set "los_hack_no_query=true"

call :lookSee "%y%;%x%" transparent && exit /b 0

if "%y%"=="%x%" set "los_hack_no_query=false"
if "%transparent%"=="true" goto :init_transparent

:lookRay_outer_loop
:: Look down the window we've found
set /a y_inc=!y!+1, "next_to=(2*!y!+1)*!gradf!/!x!"
call :lookRay !y_inc! !from! !next_to! && exit /b 0

:: Find the start of the next window
:lookRay_first_inner_loop
if "!x!"=="!max_x!" exit /b 1
:: See if this seals off the scan. If !y! is zero, then it will.
set /a "from=(2*!y!+1)*!gradf!/!x!"
if !from! LEQ !to! exit /b 1
set /a x+=1
call :lookSee "!y!;!x!" transparent && exit /b 0
if "!transparent!"=="false" goto :lookRay_first_inner_loop

:init_transparent
:: Find the end of this window of visibility.
:: The window is trimmed by an earlier limit.
if "!x!"=="!max_x!" (
    call :lookRay !y_inc! !from! !to!
    exit /b !errorlevel!
)
set /a x+=1
call :lookSee "!y!;!x!" transparent && exit /b 0
goto :lookRay_outer_loop

::------------------------------------------------------------------------------
:: Looks at things based on specified coordinates
::
:: Arguments: %1 - The coordinates to look from
::            %2 - A variable that will indicate whether the tiles are empty
:: Returns:   0 if there is a clear line of sight
::            1 otherwise
::------------------------------------------------------------------------------
:lookSee
for /f "tokens=1,2 delims=;" %%A in ("%~1") do set /a "coord.y=%%~A", "coord.x=%%~B"
set "illegal_call=0"
if %coord.x% LSS 0 set /a illegal_call+=1
if %coord.y% LSS 0 set /a illegal_call+=1
if %coord.y% GTR %coord.x% set /a illegal_call+=1
if not "%illegal_call%"=="0" (
    call ui_io.cmd :printMessage "Illegal call to looksee(!coord.y!, !coord.x!)"
)

set "description="
if "%coord.x%"=="0" if "%coord.y%"=="0" (
    set "description=You are on"
) else (
    set "description=You see"
)

set /a j=%py.pos.x%+!los_fxx!+%coord.x%+!los_fxy!*%coord.y%
set /a coord.y=%py.pos.y%+!los_fyx!*%coord.x%+!los_fyy!*%coord.y%
set "coord.x=!j!"

call ui.cmd :coordInsidePanel "%~1" || (
    set "transparent=false"
    exit /b 1
)

for %%A in (feature_id creature_id temporary_light permanent_light field_mark treasure_id) do (
    set "tile.%%~A=!dg.floor[%coord.y%][%coord.x%].%%~A"
)

:: Don't look at a direct line of sight
if "%los_hack_no_query%"=="false" exit /b 1
set "key=Q"

for /f "delims=" %%A in ("%tile.creature_id%") do (
    if "%los_rocks_and_objects%"=="0" (
        if %%A GTR 1 (
            if "!monsters[%%~A].lit!"=="true" (
                set "j=!monsters[%%~A].creature_id!"
                for /f "delims=" %%B in ("!j!") do (
                    call helpers.cmd :isVowel "!creatures_list[%%~B].name:~0,1!"
                    if "!errorlevel!"=="0" (set "article=an") else (set "article=a")
                    set "msg=[(r)ecall] !description! !article! !creatures_list[%%~B].name!"
                )
                set "description=It is on"
                call ui_io.cmd :printStringClearToEOL "!msg!" "0;0"

                call ui.cmd :panelMoveCursor "!coord.y!;!coord.x!"
                call ui_io.cmd :getKeyInput key

                if /I "!key!"=="R" (
                    call ui_io.cmd :terminalSaveScreen
                    call recall.cmd :memoryRecall "!j!"
                    cmd /c exit /b !errorlevel!
                    set "key=!=ExitcodeAscii!"
                    call ui_io.cmd :terminalRestoreScreen
                )
            )
        )
    )
)

set "is_lit=0"
if "!tile.temporary_light!"=="true" set /a is_lit+=1
if "!tile.permanent_light!"=="true" set /a is_lit+=1
if "!tile.field_mark!"=="true" set /a is_lit+=1

if !is_lit! GTR 0 (
    if not "%tile.treasure_id%"=="0" (
        if "!game.treasure.list[%tile.treasure_id%].category_id!"=="%tv_secret_door%" set /a los_rocks_and_objects+=1

        if "!los_rocks_and_objects!"=="0" (
            if not "!game.treasure.list[%tile.treasure_id%].category_id!"=="%tv_invis_trap%" (
                call identification.cmd :itemDescription obj_string "game.treasure.list[%tile.treasure_id%]" "true"
                set "msg=!description! !obj_string! ---pause---"
                set "description=It is in"
                call ui_io.cmd :putStringClearToEOL "!msg!" "0;0"
                call ui_io.cmd :panelMoveCursor "%~1"
                call ui_io.cmd :getKeyInput key
            )
        )
    )

    set "something_to_see=0"
    if !los_rocks_and_objects! GTR 0 set /a something_to_see+=1
    if not "!msg!"=="" set /a something_to_see+=1
    if %tile.feature_id% GEQ %mon_closed_space% (
        if !something_to_see! GTR 0 (
            set "wall_description="
            if "!tile.feature_id!"=="%tile_boundary_wall%" (
                if not "!msg!"=="" (
                    set "wall_description=a granite wall"
                ) else (
                    set "wall_description="
                )
            )
            if "!tile.feature_id!"=="%tile_granite_wall%" (
                if not "!msg!"=="" (
                    set "wall_description=a granite wall"
                ) else (
                    set "wall_description="
                )
            )
            if "!tile.feature_id!"=="%tile_magma_wall%" (
                set "wall_description=some dark rock"
            )
            if "!tile.feature_id!"=="%tile_quartz_wall%" (
                set "wall_description=a quartz vein"
            )

            if not "!wall_description!"=="" (
                set "msg=!description! !wall_description! ---pause---"
                call ui_io.cmd :putStringClearToEOL "!msg!" "0;0"
                call ui_io.cmd :panelMoveCursor "%~1"
                call :ui_io.cmd :getKeyInput key
            )
        )
    )
)

if not "!msg!"=="" (
    set /a los_num_places_seen+=1
    if "!key!"=="Q" exit /b 0
)
exit /b 1