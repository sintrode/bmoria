call %*
exit /b

::------------------------------------------------------------------------------
:: Checks to see if the player is tunneling somewhere that can actually be
:: tunneled into
::
:: Arguments: %1 - The treasure ID of the tile being tunneled into
::            %2 - The feature_id of the tile being tunneled into
:: Returns:   0 if the player is allowed to tunnel there
::            1 if the player is not allowed to tunnel there
::------------------------------------------------------------------------------
:playerCanTunnel
:: You should see the original C code tbh
set "cant_tunnel=0"
if %~2 LSS %min_cave_wall% (
    if "%~1"=="0" set "cant_tunnel=1"
    if not "!game.treasure.list[%~1].category_id!"=="%TV_RUBBLE%" (
        if not "!game.treasure.list[%~1].category_id!"=="%TV_SECRET_DOOR%" (
            set "cant_tunnel=1"
        )
    )

    if "!cant_tunnel!"=="1" (
        set "game.player_free_turn=true"

        if "%~1"=="0" (
            call ui_io.cmd :printMessage "Tunnel through what? Empty air?"
        ) else (
            call ui_io.cmd :printMessage "You can't tunnel through that."
        )
        exit /b 1
    ) else (
        exit /b 0
    )
)
exit /b 0

::------------------------------------------------------------------------------
:: Compute the digging ability of the player, based on strength and tool used
::
:: Arguments: %1 - A reference to the digging tool used
:: Returns:   The player's digging ability
::------------------------------------------------------------------------------
:playerDiggingAbility
set "digging_ability=!py.stats.used[%PlayerAttr.a_str%]!"
set /a "can_tunnel=!%~1.flags! & %config.treasure.flags.tr_tunnel%"
if not "!can_tunnel!"=="0" (
    set /a digging_ability+=25 + !%~1.misc_use! * 50
) else (
    call dice.cmd :maxDiceRoll !%~1.damage.dice! !%~1.damage.sides!
    set /a digging_ability+=!errorlevel! + !%~1.to_hit! + !%~1.to_damage!
    set /a "digging_ability>>=1"
)

:: If the weapon is too heavy, make it harder to dig with
if "%py.weapon_is_heavy%"=="true" (
    set /a "digging_ability+=(!py.stats.used[%PlayerAttr.a_str%]! * 15) - !%~1.weight!"
    if !digging_ability! LSS 0 set "digging_ability=0"
)
exit /b !digging_ability!

:: TODO: Merge the three wall-digging subroutines
::------------------------------------------------------------------------------
:: Dig into a granite wall, the softest of all the walls
::
:: Arguments: %1 - The coordinates to dig at
::            %2 - The player's ability to dig
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonDigGraniteWall
call rng.cmd :randomNumber 1200
set /a i=!errorlevel!+80

call player.cmd :playerTunnelWall "%~1" "%~2" !i!
if "!errorlevel!"=="0" (
    call ui_io.cmd :printMessage "You have finished the tunnel."
) else (
    call ui_io.cmd :printMessageNoCommandInterrupt "You tunnel into the granite wall."
)
exit /b

::------------------------------------------------------------------------------
:: Dig into a magma wall, the mediumest of all the walls
::
:: Arguments: %1 - The coordinates to dig at
::            %2 - The player's ability to dig
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonDigMagmaWall
call rng.cmd :randomNumber 600
set /a i=!errorlevel!+10

call player.cmd :playerTunnelWall "%~1" "%~2" !i!
if "!errorlevel!"=="0" (
    call ui_io.cmd :printMessage "You have finished the tunnel."
) else (
    call ui_io.cmd :printMessageNoCommandInterrupt "You tunnel into the magma intrusion."
)
exit /b

::------------------------------------------------------------------------------
:: Dig into a quartz vein, the hardest of all the walls
::
:: Arguments: %1 - The coordinates to dig at
::            %2 - The player's ability to dig
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonDigQuartzWall
call rng.cmd :randomNumber 400
set /a i=!errorlevel!+10

call player.cmd :playerTunnelWall "%~1" "%~2" !i!
if "!errorlevel!"=="0" (
    call ui_io.cmd :printMessage "You have finished the tunnel."
) else (
    call ui_io.cmd :printMessageNoCommandInterrupt "You tunnel into the quartz vein."
)
exit /b

::------------------------------------------------------------------------------
:: Dig into rubble
::
:: Arguments: %1 - The coordinates to dig at
::            %2 - The player's ability to dig
:: Returns:   None
::------------------------------------------------------------------------------
:dungeonDigRubble
set "coord=%~1"
call rng.cmd :randomNumber 180
if %~2 GTR !errorlevel! (
    call dungeon.cmd :dungeonDeleteObject "coord"
    call ui_io.cmd :printMessage "You have removed the rubble."

    call rng.cmd :randomNumber 10
    if "!errorlevel!"=="1" (
        call dungeon.cmd :dungeonPlaceRandomObjectAt "coord" "false"

        call dungeon.cmd :caveTileVisible "coord" && (
            call ui_io.cmd :printMessage "You have found something."
        )
    )
    call dungeon.cmd :dungeonLiteSpot "coord"
) else (
    call ui_io.cmd :printMessageNoCommandInterrupt "You dig in the rubble."
)
exit /b

::------------------------------------------------------------------------------
:: Determine which type of wall the player is tunneling into
::
:: Arguments: %1 - The coordinates to dig at
::            %2 - The type of wall to dig into
::            %3 - The player's ability to dig
:: Returns:   0 if a wall was dug at
::            1 if the player was not trying to dig into a wall
::------------------------------------------------------------------------------
:dungeonDigAtLocation
if "%~2"=="%tile_granite_wall%" (
    call :dungeonDigGraniteWall "%~1" "%~3"
    exit /b 0
)
if "%~2"=="%tile_magma_wall%" (
    call :dungeonDigMagmaWall "%~1" "%~3"
    exit /b 0
) 
if "%~2"=="%tile_quartz_wall%" (
    call :dungeonDigQuartzWall "%~1" "%~3"
    exit /b 0
)
if "%~2"=="%tile_boundary_wall%" (
    call ui_io.cmd :printMessage "This seems to be permanent rock."
    exit /b 0
)
exit /b 1

::------------------------------------------------------------------------------
:: Tunnel through rubble and walls
::
:: Arguments: %1 - The direction in which to tunnel
:: Returns:   None
::------------------------------------------------------------------------------
:playerTunnel
:: 75 percent chance of random movement if confused
if %py.flags.confused% GTR 0 (
    call rng.cmd :randomNumber 4
    if !errorlevel! GTR 1 (
        call rng.cmd :randomNumber 9
        set "direction=!errorlevel!"
    )
)

set "coord=%py.pos.y%;%py.pos.x%"
set "coord.y=%py.pos.y%"
set "coord.x=%py.pos.x%"
call player.cmd :playerMovePosition !direction! "coord"

set "tile=dg.floor[%coord.y%][%coord.x%]"
set "item=py.inventory[%PlayerEquipment.Wield%]"

call :playerCanTunnel "!%tile%.treasure_id!" "!%tile%.feature_id!" || exit /b

if !%tile%.creature_id! GTR 1 (
    call identification.cmd :objectBlockedByMonster !%tile%.creature_id!
    call player.cmd :playerAttackPosition "!coord!"
    exit /b
)

set "t_id=!%tile%.treasure_id!"
if "!%item%.category_id!"=="%TV_NOTHING%" (
    REM TODO: confirm that this shouldn't be "item" instead of "%item%"
    call :playerDiggingAbility "%item%"
    set "digging_ability=!errorlevel!"

    call :dungeonDigAtLocation "!coord!" "!%tile%.feature_id!" "!digging_ability!"
    if "!errorlevel!"=="1" (
        if not "!%tile%.treasure_id!"=="0" (
            if "!game.treasure.list[%t_id%].category_id!"=="%TV_RUBBLE%" (
                call :dungeonDigRubble "!coord!" "!digging_ability!"
            ) else if "!game.treasure.list[%t_id%].category_id!"=="%TV_SECRET_DOOR%" (
                call ui_io.cmd :printMessageNoCommandInterrupt "You tunnel into the granite wall."
                call player.cmd :playerSearch "%py.pos.y%;%py.pos.x%" "%py.misc.change_in_search%"
            ) else (
                exit /b
            )
        ) else (
            exit /b
        )
    )
    exit /b
)
call ui_io.cmd :printMessage "You dig with your hands, making no progress."
exit /b
