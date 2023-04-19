:: Creates arrays for remembered monster descriptions

set "recall_counter=0"
for %%A in ("do something undefined" "attack" "weaken" "confuse" "terrify"
            "shoot flames" "shoot acid" "freeze" "shoot lightning" "corrode"
            "blind" "paralyse" "steal money" "steal things" "poison"
            "reduce dexterity" "reduce constitution" "drain intelligence"
            "drain wisdom" "lower experience" "call for help" "disenchant"
            "eat your food" "absorb light" "absorb charges") do (
    set "recall_description_attack_type[!recall_counter!]=%%~A"
    set /a recall_counter+=1
)

set "recall_counter=0"
for %%A in ("make an undefined advance" "hit" "bite" "claw" "sting" "touch"
            "kick" "gaze" "breathe" "spit" "wail" "embrace" "crawl on you"
            "release spores" "beg" "slime you" "crush" "trample" "drool"
            "insult") do (
    set "recall_description_attack_method[!recall_counter!]=%%~A"
    set /a recall_counter+=1
)

set "recall_counter=0"
for %%A in (" not at all", " a bit", "", " quite", " very", " most", " highly", " extremely",) do (
    set "recall_description_how_much[!recall_counter!]=%%~A"
    set /a recall_counter+=1
)

set "recall_counter=0"
for %%A in ("move invisibly" "open doors" "pass through walls"
            "kill weaker creatures" "pick up objects" "breed explosively") do (
    set "recall_description_move[!recall_counter!]=%%~A"
    set /a recall_counter+=1
)

set "recall_counter=0"
for %%A in ("teleport short distances" "teleport long distances"
            "teleport its prey" "cause light wounds" "cause serious wounds"
            "paralyse its prey" "induce blindness" "confuse" "terrify"
            "summon a monster" "summon the undead" "slow its prey"
            "drain mana" "unknown 1" "unknown 2") do (
    set "recall_description_spell[!recall_counter!]=%%~A"
    set /a recall_counter+=1
)

set "recall_counter=0"
for %%A in ("lightning" "poison gases" "acid" "frost" "fire") do (
    set "recall_description_breath[!recall_counter!]=%%~A"
    set /a recall_counter+=1
)

set "recall_counter=0"
for %%A in ("frost" "fire" "poison" "acid" "bright light" "rock remover") do (
    set "recall_description_weakness[!recall_counter!]=%%~A"
    set /a recall_counter+=1
)
set "recall_counter="