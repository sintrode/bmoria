:: Data for use in stores
@echo off

:: Buying and selling adjustments for character race vs store owner race
set "counter=0"
call :addListTo2dArray race_gold_adjustments "100 105 105 110 113 115 120 125"
call :addListTo2dArray race_gold_adjustments "110 100 100 105 110 120 125 130"
call :addListTo2dArray race_gold_adjustments "110 105 100 105 110 120 125 130"
call :addListTo2dArray race_gold_adjustments "115 110 105  95 105 110 115 130"
call :addListTo2dArray race_gold_adjustments "115 115 110 105  95 110 115 130"
call :addListTo2dArray race_gold_adjustments "115 120 120 110 110  95 125 135"
call :addListTo2dArray race_gold_adjustments "115 120 125 115 115 130 110 115"
call :addListTo2dArray race_gold_adjustments "110 115 115 110 110 130 110 110"

:: game_objects[] index of objects that may appear in the store
set "counter=0"
call :addListTo2dArray store_choices "366 365 364 84  84  365 123 366 365 350 349 348 347 346 346 345 345 345 344 344 344 344 344 344 344 344"
call :addListTo2dArray store_choices "94  95  96  109 103 104 105 106 110 111 112 114 116 124 125 126 127 129 103 104 124 125 91  92  95  96 "
call :addListTo2dArray store_choices "29  30  34  37  45  49  57  58  59  65  67  68  73  74  75  77  79  80  81  83  29  30  80  83  80  83 "
call :addListTo2dArray store_choices "322 323 324 325 180 180 233 237 240 241 361 362 57  58  59  260 358 359 265 237 237 240 240 241 323 359"
call :addListTo2dArray store_choices "173 174 175 351 351 352 353 354 355 356 357 206 227 230 236 252 253 352 353 354 355 356 359 363 359 359"
call :addListTo2dArray store_choices "318 141 142 153 164 167 168 140 319 320 320 321 269 270 282 286 287 292 293 294 295 308 269 290 319 282"
exit /b

::------------------------------------------------------------------------------
:: Adds a list of items to an array and then increments the first dimension
::
:: Arguments: %1 - The name of the array to add a list of elements to
::            %2 - The list of values to store in the 2D array
:: Returns:   None
::------------------------------------------------------------------------------
:addListTo2dArray
set "element=0"
for %%A in (%~2) do (
    set "%~1[!counter!][!element!]=%%~A"
    set /a element+=1
)
set /a counter+=1
exit /b