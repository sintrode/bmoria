::------------------------------------------------------------------------------
:: C++ has to do a lot to do stuff with files, whereas batch exists to interact
:: with them. If you're looking at this file and comparing it to game_files.cpp
:: to learn either batch or C++, this is not the file to be looking at.
::------------------------------------------------------------------------------
@echo off
call %*
exit /b

::------------------------------------------------------------------------------
:: Do the absolute bare minimum for file creation. If the file doesn't exist,
:: touch it. If the file still doesn't exist after that, return an error.
:: 
:: Arguments: None
:: Returns:   0 if config.files.scores exists by the end of this subroutine,
::            1 otherwise
::------------------------------------------------------------------------------
:initializeScoreFile
if not exist "%config.files.scores%" (
    >"%config.files.scores%" type nul
)
if not exist "%config.files.scores%" exit /b 1
exit /b 0

::------------------------------------------------------------------------------
:: Attempt to open and print the file containing the intro splash screen text.
:: The C++ code was using a for loop and fgets, but we can just type it out.
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:displaySplashScreen
if exist "%config.files.splash_screen%" (
    call ui_io.cmd :clearScreen
    type "%config.files.splash_screen%"
    call ui_io.cmd :waitForContinueKey 23
)
exit /b

::------------------------------------------------------------------------------
:: Open and display a text help file 23 lines at a time
::
:: Arguments: %1 - The file to open
:: Returns:   None
::------------------------------------------------------------------------------
:displayTextHelpFile
if not exist "%~1" (
    call ui_io.cmd :putStringClearToEOL "Can not find help file '%~1'." "0;0"
    exit /b
)
call ui_io.cmd :terminalSaveScreen

call ui_io.cmd :clearScreen
set /a counter=0
for /f "usebackq tokens=1,* delims=:" %%A in (`findstr /n /v /c:"^$" "%~1"`) do (
    echo %%~B
    set /a counter+=1
    set /a counter_mod=!counter!%%23

    if "!counter_mod!"=="0" (
        call ui_io.cmd :putStringClearToEOL "[ press any key to continue ]" "23;23"
        call ui_io.cmd :clearScreen
    )
)

call ui_io.cmd :terminalRestoreScreen
exit /b

::------------------------------------------------------------------------------
:: Open and display a death text file. Unlike the help files, the death files
:: are both under 23 lines long so we can use type instead of a loop.
::
:: Arguments: %1 - The file to open
:: Returns:   None
::------------------------------------------------------------------------------
:displayDeathFile
if not exist "%~1" (
    call ui_io.cmd :putStringClearToEOL "Can not find file '%~1'." "0;0"
    exit /b
)

call ui_io.cmd :clearScreen
type "%~1"
exit /b

::------------------------------------------------------------------------------
:: Prints a list of random objects to a file. The objects produced are a sample
:: of objects which can be expected to appear on that level.
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:outputRandomLevelObjectsToFile
call ui_io.cmd :putStringClearToEOL "Product objects on what level?: " "0;0"
call ui_io.cmd :getStringInput level "0;32" 10 || exit /b

call ui_io.cmd :putStringClearToEOL "Produce how many objects?: " "0;0"
call ui_io.cmd :getStringInput count "0;27" 10 || exit /b

if !count! GEQ 1 if !level! GEQ 0 if !level! LEQ 1200 goto :validParameters
call ui_io.cmd :putStringClearToEOL "Parameters no good" "0;0"
exit /b

:validParameters
if !count! GTR 10000 set "count=10000"
call ui_io.cmd :getInputConfirmation "Small objects only?"
if "!errorlevel!"=="0" (
    set "small_objects=true"
) else (
    set "small_objects=false"
)

call ui_io.cmd :putStringClearToEOL "File name: " "0;0"

set "filename="
call ui_io.cmd :getStringInput filename "0;11" 64 || exit /b
if "!filename!"=="" exit /b

>"!filename!" type nul
if not exist "!filename!" (
    call ui_io.cmd :putStringClearToEOL "File could not be opened." "0;0"
)
call ui_io.cmd :putStringClearToEOL "!count! random objects being produced..." "0;0"
call ui_io.cmd :putQIO

(
    echo *** Random Object Sampling:
    echo *** !count! objects
    echo *** For Level !level!
    echo.
    echo.
) >>"!filename!"

call game_objects.cmd :popt
set "treasure_id=!errorlevel!"

for /L %%A in (1,1,!count!) do (
    call game_objects.cmd :itemGetRandomObjectId !level! !small_objects!
    set "object_id=!errorlevel!"

    for /f "delims=" %%B in ("!object_id!") do (
        call inventory.cmd :inventoryItemCopyTo !sorted_objects[%%B]! game.treasure.list[!treasure_id!]
    )

    call treasure.cmd :magicTreasureMagicalAbility !treasure_id! !level!
    call identification.cmd :itemIdentifyAsStoreBought game.treasure.list[!treasure_id!]

    call inventory.cmd :inventoryItemIsCursed game.treasure.list[!treasure_id!] && (
        call identification.cmd :itemAppendToInscription game.treasure.list[!treasure_id!] %config.identification.id_damd%
    )

    call identification.cmd :itemDescription description game.treasure.list[!treasure_id!] "true"
    for /f "delims=" %%B in ("!treasure_id!") do (
        >>"!filename!" echo !game.treasure.list[%%B].depth_first_round! !description!
    )
)

call game_objects.cmd :pusht
call ui_io.cmd :putStringClearToEOL "Completed." "0;0"
exit /b

::------------------------------------------------------------------------------
:: Writes the character sheet to a file. I'm almost certainly going to have to
:: rewrite the whole thing to get leading spaces to work. Maybe something with
:: building a string ahead of time and then echoing that? I'd have to adjust
:: :rightpad to append to a string rather than display...
::
:: Arguments: %1 - The name of the file to save the character sheet in
:: Returns:   None
::------------------------------------------------------------------------------
:writeCharacterSheetToFile
set "char_file=%~1"
call ui_io.cmd :putStringClearToEOL "Writing character sheet..." "0;0"
call ui_io.cmd :putQIO

(
    <nul set /p ".= Name        : "
    call :rightpad "%py.misc.name%" 23
    <nul set /p ".= Age          : "
    call :rightpad "%py.misc.age%" 6
    call ui.cmd :statsAsString "!py.stats.used[%PlayerAttr.a_str%]!" stat_description
    echo    STR: !stat_description!
    <nul set /p ".= Race        : "
    call :rightpad "!character_races[%py.misc.race_id%].name!" 23
    <nul set /p ".= Height       : "
    call :rightpad "%py.misc.height%" 6
    call ui.cmd :statsAsString "!py.stats.used[%PlayerAttr.a_int%]!" stat_description
    echo    INT: !stat_description!
    <nul set /p ".= Sex         : "
    call player.cmd :playerGetGenderLabel gender_label
    call :rightpad "!gender_label!" 23
    <nul set /p ".= Weight       :"
    call :rightpad "%py.misc.weight%" 6
    call ui.cmd :statsAsString "!py.stats.used[%PlayerAttr.a_wis%]!" stat_description
    echo    WIS: !stat_description!
    <nul set /p ".= Class       : "
    call :rightpad "!classes[%py.misc.class_id%].title!" 23
    <nul set /p ".= Social Class :"
    call :rightpad "%py.misc.social_class%" 6
    call ui.cmd :statsAsString "!py.stats.used[%PlayerAttr.a_dex%]!" stat_description
    echo    DEX: !stat_description!
    <nul set /p ".= Title      : "
    call player.cmd :playerRankTitle player_title
    call :rightpad "!player_title!" 23
    call :rightpad " " 22
    call ui.cmd :statsAsString "!py.stats.used[%PlayerAttr.a_con%]!" stat_description
    echo    CON: !stat_description!
    echo                                                                CHR : 
    call ui.cmd :statsAsString "!py.stats.used[%PlayerAttr.a_chr%]!" stat_description
    echo    CHR: !stat_description!
    echo.

    <nul set /p ".= + To Hit    : "
    call :rightpad "%py.misc.display_to_hit%" 6
    <nul set /p ".=       Level      : "
    call :rightpad "%py.misc.level%" 7
    <nul set /p ".=    Max Hit Points : "
    call :rightpad "%py.misc.max_hp%" 6
    echo.
    <nul set /p ".= + To Damage : "
    call :rightpad "%py.misc.display_to_damage%" 6
    <nul set /p ".=       Experience : "
    call :rightpad "%py.misc.exp%" 7
    <nul set /p ".=    Cur Hit Points : "
    call :rightpad "%py.misc.current_hp%" 6
    echo.
    <nul set /p ".= + To AC     : "
    call :rightpad "%py.misc.display_to_ac%" 6
    <nul set /p ".=       Max Exp    : "
    call :rightpad "%py.misc.max_exp%" 7
    <nul set /p ".=    Max Mana       :"
    call :rightpad "%py.misc.mana" 6
    echo.
    <nul set /p ".=   Total AC  : "
    call :rightpad "%py.misc.display_ac%" 6
    if %py.misc.level% GEQ %player_max_level% (
        <nul set /p ".=       Exp to Adv : *******"
    ) else (
        set /a prev_level=%py.misc.level%-1
        for /f "delims=" %%A in ("!prev_level!") do (
            set /a exp_to_adv=!py.base_exp_levels[%%A]! * %py.misc.experience_factor% / 100
        )
        <nul set /p ".=       Exp to Adv : "
        call :rightpad "!exp_to_adv!" 7
    )
    <nul set /p ".=    Cur Mana       : "
    call :rightpad "%py.misc.current_mana%" 6
    <nul set /p ".=                            Gold       : "
    call :rightpad "%py.misc.au%" 7

    set /a "xbth=%py.misc.bth%+%py.misc.plusses_to_hit%*%bth_per_plus_to_hit_adjust%+(!class_level_adj[%py.misc.class_id%][%PlayerClassLevelAdj.BTH%]!*%py.misc.level%)"
    set /a "xbthb=%py.misc.bth_with_bows%+%py.misc.plusses_to_hit%*%bth_per_plus_to_hit_adjust%+(!class_level_adj[%py.misc.class_id%][%PlayerClassLevelAdj.BTHB%]!*%py.misc.level%)"

    set /a xfos=40-%py.misc.fos%
    if !xfos! LSS 0 set "xfos=0"

    call player_stats.cmd :playerStatAdjustmentWisdomIntelligence %PlayerAttr.a_int%
    set "int_adj=!errorlevel!"
    call player_stats.cmd :playerStatAdjustmentWisdomIntelligence %PlayerAttr.a_wis%
    set "wis_adj=!errorlevel!"
    set /a xstl=%py.misc.stealth_factor%+1
    call player_stats.cmd :playerDisarmAdjustment
    set /a "xdis=%py.misc.disarm%+2*!errorlevel!+!int_adj!+(!class_level_adj[%PlayerClassLevelAdj.disarm%]!*%py.misc.level%/3)"
    set /a "xsave=%py.misc.saving_throw%+!wis_adj!+(!class_level_adj[%PlayerClassLevelAdj.save%]!*%py.misc.level%/3)"
    set /a "xdev=%py.misc.saving_throw%+!int_adj!+(!class_level_adj[%PlayerClassLevelAdj.device%]!*%py.misc.level%/3)"
    set /a xinfra=%py.flags.see_infra%*10

    for %%A in ("bth 12" "stl 1" "fos 3" "bthb 12" "dis 8" "srh 6" "save 6" "dev 6") do (
        for /f "tokens=1,2" %%B in ("%%~A") do (
            call ui.cmd :statRating !x%%B! %%C stat_%%B
        )
    )
    echo ^(Miscellaneous Abilities^)
    echo.
    <nul set /p ".= Fighting    : "
    call :rightpad "!stat_bth!" 10
    <nul set /p ".=   Stealth     : "
    call :rightpad "!stat_stl!" 10
    echo   Perception  : !stat_fos!
    <nul set /p ".= Bows/Throw  : "
    call :rightpad "!stat_bthb!" 10
    <nul set /p ".=   Disarming   : "
    call :rightpad "!stat_dis!" 10
    echo    Searching   : !stat_srh!
    <nul set /p ".= Saving Throw: "
    call :rightpad "!stat_save!" 10
    <nul set /p ".=   Magic Device: "
    call :rightpad "!stat_dev!" 10
    echo    Infra-Vision: !xinfra!

    echo.
    echo Character Background
    for /L %%A in (0,1,3) do echo  !py.misc.history[%%A]!
) >"!char_file!"
exit /b

::------------------------------------------------------------------------------
:: Places spaces before a string and then crops the resulting string to a
:: specified length
::
:: Arguments: %1 - The string to pad
::            %2 - The number of characters to display
:: Returns:   None
::------------------------------------------------------------------------------
:rightpad
set "string=%~1"
set "length=%~2"
set "spaces=                                                                      "
set "str=%string%%spaces%"
<nul set /p ".=!str:~0,%length%!"
exit /b

::------------------------------------------------------------------------------
:: Displays the location of a piece of equipment
::
:: Arguments: %1 - The 22-indexed location of the item
::            %2 - The variable to store the string in
:: Returns:   None
::------------------------------------------------------------------------------
:equipmentPlacementDescription
set "%~2=*Unknown value*   "
if "%~1"=="%PlayerEquipment.Wield%"     set "%~2=You are wielding  "
if "%~1"=="%PlayerEquipment.Head%"      set "%~2=Worn on head      "
if "%~1"=="%PlayerEquipment.Neck%"      set "%~2=Worn around neck  "
if "%~1"=="%PlayerEquipment.Body%"      set "%~2=Worn on body      "
if "%~1"=="%PlayerEquipment.Arm%"       set "%~2=Worn on shield arm"
if "%~1"=="%PlayerEquipment.Hands%"     set "%~2=Worn on hands     "
if "%~1"=="%PlayerEquipment.Right%"     set "%~2=Right ring finger "
if "%~1"=="%PlayerEquipment.Left%"      set "%~2=Left  ring finger "
if "%~1"=="%PlayerEquipment.Outer%"     set "%~2=Worn about body   "
if "%~1"=="%PlayerEquipment.Auxiliary%" set "%~2=Secondary weapon  "
exit /b

::------------------------------------------------------------------------------
:: Writes out the player's equipment list to a file
::
:: Arguments: %1 - The name of the file to write to
:: Returns:   None
::------------------------------------------------------------------------------
:writeEquipmentListToFile
set "equip_file=%~1"

(
    echo.
    echo   [Character's Equipment List]
    echo.
    echo.

    if "%py.equipment_count%"=="0" (
        echo   Character has no equipment in use.
        exit /b
    )

    set "item_slot_id=0"
    for /L %%A in (22,1,33) do (
        if not "!py.inventory[%%A].category_id!"=="%tv_nothing%" (
            call identification.cmd :itemDescription description "py.inventory[%%A]" "true"

            set /a equip_letter=!item_slot_id!+97
            cmd /c exit /b !equip_letter!
            set "equip_letter=!=ExitCodeAscii!"
            call :equipmentPlacementDescription %%A equip_location

            echo   !equip_letter!^) !equip_location! : !description!
            set /a item_slot_id+=1
        )
    )
)>"%equip_file%"
exit /b

::------------------------------------------------------------------------------
:: Writes out the player's inventory to a file
::
:: Arguments: %1 - The name of the file to write to
:: Returns:   None
::------------------------------------------------------------------------------
:writeInventoryToFile
set "inv_file=%~1"

(
    echo   [General Inventory List]
    echo.
    echo.

    if "%py.pack.unique_items%"=="0" (
        echo   Character has no objects in inventory.
        exit /b
    )

    set /a unique_offset=%py.pack.unique_items%-1
    for /L %%A in (0,1,!unique_offset!) do (
        call identification.cmd :itemDescription description "py.inventory[%%A]" "true"
        set /a equip_letter=%%A+97
        cmd /c exit /b !equip_letter!
        set "equip_letter=!=ExitCodeAscii!"
        echo !equip_letter!^) !description!
    )
)>"%inv_file%"
exit /b

::------------------------------------------------------------------------------
:: Prints the character to a file
::
:: Arguments: %1 - The name of the file to write to
:: Returns:   None
::------------------------------------------------------------------------------
:outputPlayerCharacterToFile
set "file=%~1"
if exist "%file%" (
    call ui_io.cmd :getInputConfirmation "Replace existing file %file%?"
    if "!errorlevel!"=="1" exit /b
)

call :writeCharacterSheetToFile "%file%"
call :writeEquipmentListToFile "%file%"
call :writeInventoryToFile "%file%"
call ui_io.cmd :putStringClearToEOL "Completed." "0;0"
exit /b