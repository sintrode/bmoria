@echo off
call %*
exit /b

::------------------------------------------------------------------------------
:: Calculates current boundaries
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:panelBounds
set /a dg.panel.top=%dg.panel.row% * (%screen_height% / 2)
set /a dg.panel.bottom=%dg.panel.top% + %screen_height% - 1
set /a dg.panel.row_prt=%dg.panel.top% - 1
set /a dg.panel.left=%dg.panel.col% * (%screen_width% / 2)
set /a dg.panel.right=%dg.panel.left% + %screen_width% - 1
set /a dg.panel.col_prt=%dg.panel.left% - 13
exit /b

:coordOutsidePanel
exit /b

:coordInsidePanel
exit /b

:drawDungeonPanel
exit /b

:drawCavePanel
exit /b

:dungeonResetView
exit /b

:statsAsString
exit /b

:displayCharacterStats
exit /b

:printCharacterInfoInField
exit /b

:printHeaderLongNumber
exit /b

:printHeaderLongNumber7Spaces
exit /b

:printHeaderNumber
exit /b

:printLongNumber
exit /b

:printNumber
exit /b

:printCharacterTitle
exit /b

:printCharacterLevel
exit /b

:printCharacterCurrentMana
exit /b

:printCharacterMaxHitPoints
exit /b

:printCharacterCurrentHitPoints
exit /b

:printCharacterCurrentArmorClass
exit /b

:printCharacterGoldValue
exit /b

:printCharacterCurrentDepth
exit /b

:printCharacterHungerStatus
exit /b

:printCharacterBlindStatus
exit /b

:printCharacterConfusedState
exit /b

:printCharacterFearState
exit /b

:printCharacterPoisonedState
exit /b

:printCharacterMovementState
exit /b

:printCharacterSpeed
exit /b

:printCharacterStudyInstruction
exit /b

:printCharacterWinner
exit /b

:printCharacterStatsBlock
exit /b

:printCharacterInformation
exit /b

:printCharacterStats
exit /b

:statRating
exit /b

:printCharacterVitalStatistics
exit /b

:printCharacterLevelExperience
exit /b

:printCharacterAbilities
exit /b

:printCharacter
exit /b

:getCharacterName
exit /b

:changeCharacterName
exit /b

:displaySpellsList
exit /b

:playerGainLevel
exit /b

:displayCharacterExperience
exit /b

