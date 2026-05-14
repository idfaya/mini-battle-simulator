# Roguelike Convergence Program Design

## Goal

Align the current roguelike runtime with the actual architecture already in use:

- Battle rewards only provide `feat` growth.
- Every battle win grants a fixed post-battle rest.
- Recruit becomes a dedicated node interaction.
- Relic is renamed to equipment at the gameplay/UI contract level.

## Core Loop

The chapter loop becomes:

1. Choose path
2. Enter node
3. Resolve battle/event/shop/camp/recruit
4. If battle won:
   - apply fixed post-battle rest
   - open `battle_levelup` feat 3-choice
5. Return to map

## Rules

### Battle Reward

- Normal / elite / boss battles no longer grant mixed reward pool choices.
- The only battle reward UI is `battle_levelup`.
- Each option remains a hero level-up card that grants one feat.

### Post-Battle Rest

- Trigger: immediately after a battle win, before opening feat choice.
- Default Act 1 policy:
  - heal alive heroes by 50% max HP
  - clear non-ultimate cooldowns
  - restore ultimate charges to max
  - clear persisted skill cooldown map
  - do not revive dead heroes
- The rest policy is chapter-config driven through `postBattleRest`.

### Recruit Node

- Recruit is removed from battle rewards and shop goods.
- Recruit is moved to a dedicated `recruit` node type.
- Entering a recruit node opens a 3-choice recruit panel and then returns to map.
- Recruit candidates are pool-driven by `run_recruit_pool.lua`.

### Equipment

- Player-facing term changes from relic to equipment.
- Phase 1 keeps the existing run-global passive implementation to avoid scope explosion.
- Equipment can come from:
  - shop
  - events
  - dedicated reward/event content
- Equipment is not dropped by normal battle reward flow.

### Camp

- Since battle win now auto-rests the team, camp no longer owns baseline healing value.
- Camp should focus on:
  - revive one hero to full
  - clear cooldowns / restore ultimate charges / clear statuses
  - blessing / empowerment

## Runtime Changes

### `roguelike_run.lua`

- Add `recruit` node handling in `enterNode`.
- Keep battle win flow as `postBattleRest -> battle_levelup -> map`.
- Remove battle reward dependency on old mixed reward groups.

### `roguelike_battle_bridge.lua`

- Replace the current "clear non-ultimate cooldown only" post-battle logic with chapter-driven post-battle rest.

### `roguelike_reward.lua`

- Keep feat level-up generation as the only battle reward.
- Reuse recruit option generation for recruit nodes.
- Rename reward type `relic` to `equipment`.

### `roguelike_snapshot.lua`

- Rename `relics` payload to `equipments`.
- Rename chapter result statistic `relicCount` to `equipmentCount`.

## Config Changes

### `run_chapter_config.lua`

- Add `postBattleRest`:
  - `healPct`
  - `clearCooldowns`
  - `restoreUltimateCharges`
  - `reviveDead`

### `run_node_pool.lua`

- Add node type `recruit`.
- Act 1 places one recruit node on the safe route.

### `run_recruit_pool.lua`

- New config for recruit node candidate pools.

### `run_shop_goods.lua`

- Rename goods type `relic` to `equipment`.
- Remove recruit goods.
- Keep revive/service goods.

### `run_event_config.lua`

- Replace `grant_relic` with `grant_equipment`.
- Remove direct recruit reward options.

## Web Contract

- Add `recruit` to `RunNodeType`.
- Rename `RelicState` to `EquipmentState`.
- Rename reward type `relic` to `equipment`.
- Keep `reward` panel protocol unchanged so existing `choose_reward(index)` API still works.

## Risks

- Post-battle recovery reduces attrition pressure and requires encounter retuning.
- Camp value drops if not repositioned.
- Equipment rename touches Lua runtime, TS types, UI text, and tests together.
- Full per-hero equipment slots are intentionally out of scope for this round.

## Act 1 Balance Targets

- `safe` route should remain stable and mostly act as a low-pressure clear path.
- `combat` route should be harder, but no longer hard-stop at `Dark Cabal`.
- Current tuning target:
  - `safe` route clear rate: 80%+
  - `combat` route clear rate: 40%~70%
- Priority tuning nodes:
  - `101102` (`Dark Cabal`): reduce enemy count / pressure first
  - `101201` (`Frozen Gate`): lightly reduce boss pressure after combat route is unblocked
  - `101104` (`Ember Ambush`): demote from pseudo-elite pressure back to a true safe-route teaching battle by reducing enemy count and opening tempo
