# [RESOLVED-PARTIAL] debug-roguelike-balance

## Goal
- Make Act1 real-combat balance results trustworthy, then continue lowering actual wipe pressure without reducing enemy count.

## What Was Fixed
- Fixed `bin/test_roguelike_real_combat_balance.lua` camp handling to use the real available camp action instead of a hard-coded invalid action id.
- Fixed hidden-floor progression closure:
  - hidden boss reward path now writes `hiddenFloorCleared`
  - runtime stair handling distinguishes hidden-floor exit from cleared hidden entrance
  - route logic no longer treats a cleared hidden-floor entrance as a preferred downstairs target
- Trimmed `910006` skill package to remove out-of-band high-tier AOE/control skills while keeping the Act1 ice-caster identity.
- Synced `bin/test_enemy_skill_alignment.lua` to the current enemy baselines so static assertions match the current balance truth.

## Key Findings
- `unknown` outcomes were not balance noise; they were real flow bugs caused by hidden-floor state not closing correctly.
- Once hidden-floor flow was repaired, real-combat metrics became interpretable again.
- The biggest Act1 boss pressure improvement came from reducing boss skill density, not from further shaving HP/AC.
- Route conservatism and correct camp execution helped validate the test harness, but were not the main reason `101201` was wiping.

## Evidence
- Before hidden-floor closure fix:
  - `bin/test_roguelike_real_combat_balance.lua`: `15/30` boss clear, `other=1`
  - `bin/test_real_combat_winrate.lua`: `5/10` cleared, `Other Fail: 1`
- After hidden-floor closure fix:
  - `bin/test_roguelike_real_combat_balance.lua`: `16/30` boss clear, `other=0`
  - `bin/test_real_combat_winrate.lua`: `6/10` cleared, `Other Fail: 0`
- After trimming `910006` skill package:
  - boss clear improved from the earlier `10/30` range to `15/30`, proving the main gain came from boss skill-pressure reduction.

## Remaining Pressure
- The main unresolved difficulty is still `101201` on floor 5.
- Current remaining losses are mostly true wipes, not flow corruption.
- Existing web failures are still the fighter counter timing cases and are outside this balance track.

## Lessons
- Clear `unknown` first, then read wipe/clear rates.
- Separate flow bugs from balance bugs before tuning monsters.
- For Act1 boss tuning, remove out-of-band skills before continuing to sand down boss stats.
- Keep static enemy-alignment tests synced with the live balance baseline.

## Next Focus
- Continue reducing `101201` support/escort quality without reducing enemy count.
- Keep using `bin/test_real_combat_winrate.lua` and `bin/test_roguelike_real_combat_balance.lua` as the acceptance gate.
