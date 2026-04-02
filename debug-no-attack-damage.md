# Debug Session: no-attack-damage

## Status
[OPEN]

## Symptom
- **Expected**: Heroes should attack enemies and deal damage, HP should decrease
- **Actual**: No attack happening, no HP loss, battle runs but no damage dealt

## Hypotheses
1. **BattleFormula.CalcDamage returns 0** - The damage calculation formula might be returning 0 due to missing stats or incorrect formula
2. **Damage not being applied** - The damage calculation works but `target.hp` is not being updated correctly
3. **Attack logic not triggered** - The attack sequence in the test script is not being executed
4. **Hero/enemy stats missing** - Required stats (atk, def) are missing or nil
5. **BattlePassiveSkill trigger overrides attack** - Passive skill triggers might be interfering with normal attack flow

## Evidence Collected
*Pending*

## Fix Applied
*Pending*

## Verification
*Pending*
