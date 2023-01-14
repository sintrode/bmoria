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

:writeCharacterSheetToFile
exit /b

:equipmentPlacementDescription
exit /b

:writeEquipmentListToFile
exit /b

:writeInventoryToFile
exit /b

:outputPlayerCharacterToFile
exit /b