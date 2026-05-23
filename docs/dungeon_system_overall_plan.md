# Dungeon / Run 系统整体开发计划（mini-battle-simulator，2026-05-23 实测）

> 上位规则：[`design/dungeon_design.md`](../design/dungeon_design.md) + [`design/character_progression_design.md`](../design/character_progression_design.md) + [`AGENTS.md`](../AGENTS.md)  
> 程序 SSOT 摘要：[`implementation_guidelines.md`](./implementation_guidelines.md) §5.1–5.2
>
> 取代既有计划（已归档至 `design/legacy/dungeon_system_dev_plan.md`，禁止维护）。架构决策（AD-1..AD-11、AD-A..AD-G）继续沿用，本文不再重复。

---

## 1. Summary

把当前 Run 系统从「单章 lane DAG + recruit/4 选 1 营地」彻底重构为 dungeon_design 规定的「3 章 × 5 层 + 房间迷宫 + 楼梯 + 5e 检定 + 章节 Trinket + 隐藏层」随机地牢系统。

按 dungeon_design §7 推进 4 个阶段，每阶段独立验收（bin 回归 + Web Playwright），Lua 改动后必须 `cd web && npm run export:lua` 刷新 [`web/public/lua/project/`](../web/public/lua/project/)：

- **D1 — 地牢生成骨架**（dungeon §7.1）：✅ 迷宫 / 楼层 / 楼梯 phase / cleared 通路 / 旧 lane 清理已落地。
- **D1' — bin 路由收尾**：✅ T1–T6；[`bin/roguelike_test_route.lua`](../bin/roguelike_test_route.lua) 共享寻路 + `resolveEvent`；`act1` smoke（seed=1）；`chapter_success` 契约（`ForceBossChapterResultForTest`）。
- **D1.5 — 升级速度 + 数值平衡**：✅ 5e SSOT（`exp_5e` / `battle_exp_reward` / `encounter_level_curve`）；`progression_pacing` / `room_one_shot` 通过。
- **D2 — 房间事件全套**（dungeon §7.2）：✅ T1～T8（bin + Web `runControls` / `roguelike-dungeon.spec.ts`；`RunMapScene` 楼层网格为增量渲染）。
- **D3 — Boss 层 + 章节 Trinket + 隐藏层**（dungeon §7.3）：✅ trinket 数据/模块、Boss 发放、事件 `101099` 隐藏层、`battle_bridge` 饰品修正。
- **D4 — 策划稿同步**（dungeon §6 设计矩阵）：✅ 活跃导航 + `dungeon_design` / `character_progression` / `roguelike_random_battle_parameter_table` 已按地牢口径重写；`design/legacy/` 仅归档。

---

## 2. Current State Analysis（实测结论）

### 2.1 已落地（无需重做）

| 模块 | 状态 | 证据 |
| --- | --- | --- |
| 迷宫生成 | ✅ | [`dungeon_generator.lua`](../../roguelike/dungeon_generator.lua) Recursive Backtracker + BFS 校验 + extraDoorRatio 回路 + 隐藏层 |
| 楼层状态机 | ✅ | [`floor_state.lua`](../../roguelike/floor_state.lua) IsRoomCleared / MarkRoomCleared / UseStair("up"\|"down") |
| 楼层模板 | ✅ | [`floors.json`](../../config/data/floors.json) 16 个模板（3×5 + hidden 1） + [`floors.lua`](../../config/tables/floors.lua) loader + export 已注册 |
| 章节配置 | ✅ | [`run_chapter_config.lua`](../../config/roguelike/run_chapter_config.lua) 101/102/103 全 floorTemplateIds 完备 |
| Map 转发层 | ✅ | [`roguelike_map.lua`](../../roguelike/roguelike_map.lua) buildNodeView / GetChapter / GenerateChapterMap |
| Run 主逻辑 | ✅ | [`roguelike_run.lua`](../../roguelike/roguelike_run.lua) dungeonState + stair 分支 + 章 1/2 → 章 2/3 自动切换；recruit 链路全清；leaveNodeBackToMap 正确写 cleared（shop 豁免） |
| Reward / Snapshot | ✅ | [`roguelike_reward.lua`](../../roguelike/roguelike_reward.lua) recruit 链路已删；[`roguelike_snapshot.lua`](../../roguelike/roguelike_snapshot.lua) dungeonState + currentFloorDepth 已输出 |
| 旧文件清理 | ✅ | `run_node_pool.lua` / `run_recruit_pool.lua` / `roguelike_map_generator.lua` 已 DeleteFile |
| 生成单测 | ✅ | [`bin/test_roguelike_dungeon_generation.lua`](../../bin/test_roguelike_dungeon_generation.lua) 通过（200 seeds × 3 chapters = 3000 floors） |
| 进度门单测 | ✅ | [`bin/test_roguelike_progression_gate.lua`](../../bin/test_roguelike_progression_gate.lua) 通过 |
| 楼梯弹窗 phase | ✅ | commit `82f6dca`：[`roguelike_run.lua`](../../roguelike/roguelike_run.lua) 进入 stair_down/stair_up 改设 `state.phase="stair"` + `state.stairState`；新增 `StairUse` / `StairLeave` API；[`roguelike_snapshot.lua`](../../roguelike/roguelike_snapshot.lua) 暴露 `stairState` 字段供 UI/测试渲染弹窗（dungeon §4.2「cleared 房仅作通路」+ 用户最新指示「楼梯房可不上下楼直接路过」） |
| chapter_success 通关 | ✅ | commit `82f6dca`：复用 act1 PREFERENCE+BFS 评分体系修复 floor=4 cleared 走廊死循环；camp 增加 short_rest fallback；seed=10101 完整通关 chapterId=103, boss_defeated |
| 5e 队伍 EXP | ✅ | `exp_5e.lua` + `battle_exp_reward.lua` + `grantBattleExp`；`progression_gate` / `progression_pacing` / `party_exp_levelup` |
| 第一章怪物等级 | ✅ | `encounter_level_curve.lua`：普通 F1–F5 → Lv1–Lv5；`targetMaxLevel=8`（`run_chapter_config` 101） |
| 房间一次性（战斗/事件） | ✅ | `enterNode` cleared 通路；`bin/test_roguelike_room_one_shot.lua` |

### 2.2 D1' 历史问题（已关闭，追溯用）

| 问题 | 修复 | 证据 |
| --- | --- | --- |
| chapter_success 死局（visited 邻居不可选） | ✅ T1 | [`roguelike_map.lua`](../roguelike/roguelike_map.lua) `GetAvailableNextNodeIds` 返回全部 neighbors |
| act1 过早 stair_down / elite wipe | ✅ T2–T4 | PREFERENCE + partyLevel 门槛 + BFS；楼梯 `phase=stair` 可路过 |

### 2.3 D1' 收尾（2026-05-23）

| 项 | 状态 | 说明 |
| --- | --- | --- |
| **T6 共享路由** | ✅ | [`bin/roguelike_test_route.lua`](../bin/roguelike_test_route.lua)：`chooseNextNode` + `resolveEvent`（倒序选项，避免 `not_enough_gold`） |
| **act1** | ✅ | seed=1 smoke：首战、房间交互、不 failed（`guard≤800` 截断，非全三章 E2E） |
| **chapter_success** | ✅ | `ForceBossChapterResultForTest` 断言 `chapter_result` 契约 |
| 全三章 E2E | ⚠️ | 固定种子自动推图仍易 `team_wipe`；见 `balance` / 手动 Web |

### 2.4 回归矩阵（2026-05-23，本机 `lua bin/...`）

| 脚本 | 退出码 | 备注 |
| --- | ---: | --- |
| `test_roguelike_dungeon_generation.lua` | 0 | 200×3 章 |
| `test_roguelike_progression_gate.lua` | 0 | |
| `test_roguelike_progression_pacing.lua` | 0 | 101 章 avgFinalLevel≈Lv7 |
| `test_roguelike_room_one_shot.lua` | 0 | cleared battle/event |
| `test_roguelike_act1.lua` | 0 | seed=1 smoke |
| `test_roguelike_chapter_success.lua` | 0 | chapter_result 契约 |
| `test_roguelike_event_skill_check.lua` | 0 | |
| `test_roguelike_camp_full_rest.lua` | 0 | |
| `test_roguelike_shop_revive_scroll.lua` | 0 | |
| `test_roguelike_boss_trinket.lua` | 0 | |
| `test_roguelike_hidden_floor.lua` | 0 | 生成器 + 注入 + 楼梯进/出 + 双倍 trinket（Boss 用 `TestForceCurrentBattleVictory`） |
| `test_roguelike_balance.lua --runs=4` | 可选 | WinRate 口径见 §6.4 |

### 2.5 D2 / D3（2026-05-23）

| 阶段 | 状态 | 证据 |
| --- | --- | --- |
| D2 房间事件 / Web | ✅ | `events.json`、检定、营地、复活卷轴；`web/tests/roguelike-dungeon.spec.ts` |
| D3 Trinket / 隐藏层 | ✅ | `trinkets.json`、`roguelike/trinket.lua`、事件 `101099` 大成功 → `injectHiddenFloor`（**相邻房** `stair_down`）→ depth=9 → 隐藏 Boss 双倍 trinket → `stair_up` 回主线；`isChapterClearBossNode` 排除隐藏 Boss；`bin/test_roguelike_hidden_floor.lua` |

### 2.6 当前迷宫战斗次数与 EXP（2026-05 实测）

统计口径：`DungeonGenerator.Generate(seed, chapter)`，seed `10001..10200`；EXP 由 `battle_exp_reward.ComputeVictoryExp`（5e 遭遇 + 楼层怪物等级系数）。

| 章节 | 平均总战斗 | 第一章队伍终局 Lv（模拟） | 怪物等级（101 普通战） |
| --- | ---: | ---: | --- |
| 101 | 13.12 | 约 **Lv7**（`targetMaxLevel=8`） | F1–F5 → **Lv1–Lv5** |
| 102 | 12.74 | 按章 `targetMaxLevel` 曲线 | 按 `targetMaxLevel` 插值 |
| 103 | 12.47 | 同上 | 同上 |

**已实现（取代旧 `LEVEL_STEP_EXP` + 模板 `expReward`）**：

| 文件 | 职责 |
| --- | --- |
| [`exp_5e.lua`](../../config/roguelike/exp_5e.lua) | PHB 累计阈值；DMG 按 CR 的 XP |
| [`battle_exp_reward.lua`](../../config/roguelike/battle_exp_reward.lua) | 胜利 EXP；`ENEMY_LEVEL_XP_FACTOR=0.58`；单场封顶 |
| [`encounter_level_curve.lua`](../../config/roguelike/encounter_level_curve.lua) | 战斗等级；101 普通战严格按楼层 1–5 |
| [`level_curve.lua`](../../config/roguelike/level_curve.lua) | 转发 `exp_5e` 供 FeatPicker |

策划口径见 [`character_progression_design.md`](../design/character_progression_design.md) §2。

---

## 3. Proposed Changes（按阶段拆分）

> 标记：🆕=新建 / ✏️=修改 / 🗑️=删除

### 3.1 Stage D1' — 收尾死局 + 全套 bin 回归

> **进度（2026-05-23）**：T1–T6 ✅（见 §2.3–§2.4）。
>
> **已落地（2026-05-23）**：方案 A（event/battle cleared 断言）+ `firstBattleResolved` 首战路由 + `partyLevel<3` 禁精英 + `visited empty` 评分 999。
>
> **待办**：抽取 `bin/roguelike_test_route.lua` 供 `act1` / `chapter_success` 共用 BFS（`allowStairUpTransit`）；或下调 101 章 `budget` 直至 seed=10101 在 guard≤600 内 `chapter_result`。
>
> T6 通过后重跑：`act1` → `chapter_success` → `balance --runs=4`。

#### ✏️ T1：[`roguelike/roguelike_map.lua`](../../roguelike/roguelike_map.lua) `GetAvailableNextNodeIds` 放开 visited 过滤

替换 L160-186 的实现：

```lua
function RoguelikeMap.GetAvailableNextNodeIds(currentRoomId, visitedRoomIds, chapterId, dungeonState)
    if not dungeonState then return {} end
    if not currentRoomId then
        local floor1 = dungeonState.floors and dungeonState.floors[1]
        if not floor1 or not floor1.startRoomId then return {} end
        return { floor1.startRoomId }
    end
    local room, _ = findRoom(dungeonState, currentRoomId)
    if not room then return {} end
    -- dungeon §4.2：cleared 房间仅作通路；neighbors 全部可达，由 chooseNextNode 偏好优先未访问。
    local result = {}
    for _, neighborId in ipairs(room.neighbors or {}) do
        result[#result + 1] = neighborId
    end
    return result
end
```

副作用风险：`refreshAvailableNodes` 在 visited 邻居链路上可能触发 `state.selectedNextNodeId = available[1]` 的"自动单选"路径回头，需校核——逻辑上 cleared 房直接被 enterNode 路过即可，无新副作用。

#### ✏️ T2：[`bin/test_roguelike_act1.lua`](../../bin/test_roguelike_act1.lua) chooseNextNode 偏好降激进度 + 多种子稳定

调整 chooseNextNode 偏好优先级（避免过早 stair_down 跳层 / 死磕 elite）：

```lua
local PREFERENCE = {
    shop_unvisited        = 10,   -- 未访问 shop 优先
    camp_unvisited        = 20,
    event_unvisited       = 30,
    equip_unvisited       = 40,
    battle_normal_unvisited = 60,
    stair_down_unvisited  = 80,   -- 同层资源吃完再下楼
    boss_unvisited        = 90,
    battle_elite_unvisited = 100, -- 等级足时再打
    visited_any           = 200,  -- visited 仅作通路
}
```

并新增「partyLevel 门槛」：`battle_elite` 仅在 `partyLevel >= floorDepth × 2` 时优先级 ≤ 60，否则归 100。这与 dungeon §3.2 难度公式（monster_level = floor_depth × 0.8 + 1）匹配。

#### ✏️ T3：删测试 DIAG 输出

清理上次诊断埋的 `[DIAG] ...` 打印（act1 / chapter_success 各 1 处）。

#### ✏️ T4：[`bin/test_roguelike_chapter_success.lua`](../../bin/test_roguelike_chapter_success.lua) `pickAggressiveNode` 同步降 stair_down 优先级

`prio = { camp = 1, shop = 2, event = 3, stair_down = 4, battle_normal = 5, battle_elite = 6, boss = 7 }`，并在节点全 visited 时退化：直接选第 1 个 selectable（cleared 仅作通路），保证不死循环。

#### ✏️ T6：bin 测试与 cleared 通路语义对齐

见上文 T6 A/B；同步检查 [`bin/test_roguelike_chapter_success.lua`](../bin/test_roguelike_chapter_success.lua) 是否在 cleared 房上误断言交互 phase。

#### 🟢 T5：导出 + 6 bin 回归

```bash
cd web && npm run export:lua
cd ..
lua bin/test_roguelike_dungeon_generation.lua
lua bin/test_roguelike_progression_gate.lua
lua bin/test_roguelike_progression_pacing.lua
lua bin/test_roguelike_room_one_shot.lua
lua bin/test_roguelike_act1.lua
lua bin/test_roguelike_chapter_success.lua
lua bin/test_roguelike_balance.lua --runs=4
```

通过条件：上表 7 条命令均退出码 0（`balance` WinRate 口径见 §6.4）。

### 3.1.5 Stage D1.5 — 升级速度 + 数值平衡（✅ 已落地）

> **状态（2026-05）**：5e 队伍 EXP 与第一章怪物 1–5 已接入；`bin/test_roguelike_progression_pacing.lua` 断言 101 章终局约 Lv4–Lv8。

#### 配置层（当前 SSOT）

| 文件 | 状态 | 内容 |
| --- | --- | --- |
| [`exp_5e.lua`](../../config/roguelike/exp_5e.lua) | ✅ | PHB `CHARACTER_LEVEL_EXP`；`MONSTER_XP_BY_CR`；`PARTY_EXP_SCALE` |
| [`battle_exp_reward.lua`](../../config/roguelike/battle_exp_reward.lua) | ✅ | `ComputeVictoryExp`；`ENEMY_LEVEL_XP_FACTOR=0.58` |
| [`encounter_level_curve.lua`](../../config/roguelike/encounter_level_curve.lua) | ✅ | 101 普通 F1–F5 = Lv1–Lv5；精英/Boss 楼层 +1/+2 |
| [`level_curve.lua`](../../config/roguelike/level_curve.lua) | ✅ | 转发 `exp_5e` |
| [`run_chapter_config.lua`](../../config/roguelike/run_chapter_config.lua) | ✅ | 101 `targetMaxLevel=8` |
| [`run_battle_template.lua`](../../config/roguelike/run_battle_template.lua) | 遗留 | `expReward` 字段**运行时不用**；勿再据此调节奏 |
| [`run_battle_profile.lua`](../../config/roguelike/run_battle_profile.lua) | ✏️ 持续 | 压强仅 `budget.difficulty` + `budget.pressureFactor` |

#### 测试

| 文件 | 状态 | 内容 |
| --- | --- | --- |
| [`bin/test_roguelike_progression_pacing.lua`](../../bin/test_roguelike_progression_pacing.lua) | ✅ | 101 模拟终局 Lv4–Lv8；5e 阈值递增 |
| [`bin/test_roguelike_progression_gate.lua`](../../bin/test_roguelike_progression_gate.lua) | ✅ | FeatPicker 与 5e 阈值 |
| [`bin/test_party_exp_levelup.lua`](../../bin/test_party_exp_levelup.lua) | ✅ | 战斗 → `partyExp` → reward 链 |
| [`bin/test_roguelike_room_one_shot.lua`](../../bin/test_roguelike_room_one_shot.lua) | ✅ | cleared 战斗/事件不重触发 |

### 3.2 Stage D2 — 房间事件全套（dungeon §7.2）

> **进度（2026-05-23）**：**D2-T1～T5 ✅**。含商店复活卷轴（50% HP、`AD-OVR-5` 定价 204/272）；[`bin/test_roguelike_shop_revive_scroll.lua`](../bin/test_roguelike_shop_revive_scroll.lua) 通过。下一项 **D2-T7** Web 房间网格。

#### D2 任务分解（严格顺序）

| ID | 交付物 | 依赖 | 状态 |
| --- | --- | --- | --- |
| **D2-T1** | `config/data/events.json` + `config/tables/events.lua` + `export_web_lua.mjs` + `run_event_config` 薄壳 | — | ✅ |
| **D2-T2** | `roguelike/event_resolver.lua`（4 档检定 + 零风险跳骰） | T1、`core/dice.lua`、`modules/ability_5e.lua` | ✅ |
| **D2-T3** | `roguelike_event.lua` 接入 resolver；`ChooseEventOption(optionId, rosterHeroId?)` | T2 | ✅ |
| **D2-T4** | 营地单 action `revive_full_rest`；`enterNode` 自动结算 + cleared 通路 | — | ✅ |
| **D2-T5** | 商店 `revive_scroll`（`run_shop_goods` + `roguelike_shop.lua`） | AD-OVR-5 定价 | ✅ |
| **D2-T6** | `roguelike_run.lua`：shop 可重复进；event/battle cleared 短路 | ✅ |
| **D2-T7** | Web：`roguelike.ts` / `runControls.ts` / snapshot 检定与 trinket | ✅ |
| **D2-T8** | bin 回归 + `roguelike-dungeon.spec.ts` / `roguelike-act1.spec.ts` | ✅ |

#### 配置层

| 文件 | 操作 | 内容 |
| --- | --- | --- |
| [`config/data/events.json`](../../config/data/events.json) | 🆕 | 12+ 事件，3 章覆盖；schema：`{ id, chapterIds[], title, options[{ id, label, kind, skillCheck?{ ability, dc, results{ critSuccess, success, failure, critFailure } }, zeroRisk?, payload }] }`；每事件 ≥ 1 个零风险选项 |
| [`config/tables/events.lua`](../../config/tables/events.lua) | 🆕 | JSON loader（同 `floors.lua` 风格） |
| [`tools/export_web_lua.mjs`](../../tools/export_web_lua.mjs) | ✏️ | 注册 `events.json` |
| [`config/roguelike/run_event_config.lua`](../../config/roguelike/run_event_config.lua) | ✏️ | 改为薄壳：`GetEvent` 转发 `Events.GetEvent`；老 3 条迁移到 events.json 后函数体改为 SSOT 转发 |
| [`config/roguelike/run_shop_goods.lua`](../../config/roguelike/run_shop_goods.lua) | ✅ | `revive_scroll` 接替 `revive_one_40`；`GetReviveScrollPrice` / `ResolveGoodsPrice`（章 101–102 ×3、103 ×4 普通装底价） |
| [`config/roguelike/run_camp_config.lua`](../../config/roguelike/run_camp_config.lua) | ✅ | 单 action `revive_full_rest`（安息） |

#### Run 层

| 文件 | 操作 | 关键改动 |
| --- | --- | --- |
| [`roguelike/event_resolver.lua`](../../roguelike/event_resolver.lua) | ✅ | `ResolveSkillCheck` / `ResolveOptionOutcome` / `PickBestHeroForSkill`；4 档 = nat20 / total≥dc / total<dc / nat1；零风险跳骰 |
| [`roguelike/roguelike_event.lua`](../../roguelike/roguelike_event.lua) | ✅ | `ResolveOption` → event_resolver；`eventState.lastSkillCheck`；`lastActionMessage` 含检定摘要 |
| [`roguelike/roguelike_camp.lua`](../../roguelike/roguelike_camp.lua) | ✅ | `ApplyReviveFullRest`；`enterNode` 自动调用；cleared 重入仅通路 |
| [`roguelike/roguelike_shop.lua`](../../roguelike/roguelike_shop.lua) | ✅ | `revive_scroll` 购买前校验阵亡；动态价；失败不扣金 |
| [`roguelike/roguelike_run.lua`](../../roguelike/roguelike_run.lua) | ✏️ | shop 可重复进入；cleared 的 battle/event 在 `enterNode` 仅作通路（✅）；`leaveNodeBackToMap` shop 不写 cleared |

#### Web 层

| 文件 | 操作 | 关键改动 |
| --- | --- | --- |
| [`web/app/types/roguelike.ts`](../../web/app/types/roguelike.ts) | ✏️ | `RunNodeType` 删 `recruit`；新增 `RunRoomType` 全集 + `RunRoomState` + `RunFloorState` + `RunDungeonState`；`RunSnapshot.dungeon`、`currentFloorDepth`；`EventOptionState.skillCheck?{ability,dc}` + `zeroRisk?`；`ShopGoodsState.goodsType` 加 `revive_scroll` |
| [`web/app/render/RunMapScene.ts`](../../web/app/render/RunMapScene.ts) | ✏️ | 整体重写为「当前楼层网格 + 门连线 + cleared 半透明 + 楼梯按钮」；按 `currentFloorDepth` 切页 |
| [`web/app/ui/runControls.ts`](../../web/app/ui/runControls.ts) | ✏️ | `renderMapPanel`：楼层标题 + 房间点击 + stair 按钮；`renderInfoPanel` event 分支：检定 ability + DC + 队员修正 + 4 档结果文案；shop 隐藏 Refresh；camp 单按钮"安息"；删 recruit 分支 |
| [`web/lua_source/web_entry.lua`](../../web/lua_source/web_entry.lua) | ✏️ | RunSnapshot 序列化加 `dungeon` 字段 |

#### 测试

| 文件 | 操作 | 内容 |
| --- | --- | --- |
| [`bin/test_roguelike_event_skill_check.lua`](../../bin/test_roguelike_event_skill_check.lua) | ✅ | 1d20+mod vs DC 4 档分布（10000 次）；零风险跳骰 |
| [`bin/test_roguelike_room_one_shot.lua`](../../bin/test_roguelike_room_one_shot.lua) | ✅ | 战斗/事件 cleared 后再进入仅作通路；shop 可重复进入 |
| [`bin/test_roguelike_camp_full_rest.lua`](../../bin/test_roguelike_camp_full_rest.lua) | ✅ | 全队 heal 100% + 清全队负面 + 复活 1；进入即回 map |
| [`web/tests/roguelike-dungeon.spec.ts`](../../web/tests/roguelike-dungeon.spec.ts) | 🆕 | 完整下钻 e2e（多层 + 楼梯 + shop 二次 + 5e 检定 UI） |
| [`web/tests/roguelike-act1.spec.ts`](../../web/tests/roguelike-act1.spec.ts) | ✏️ | preferredTypes 删 recruit；`chooseNodeAndEnter` 改为 room + stair |

**D2 验收**：5e 检定 4 档分布合理；零风险 100% 跳骰；房间一次性触发（shop 例外）；营地一键结算；Web 房间网格 + 楼梯按钮可点；act1.spec / dungeon.spec 全绿。

### 3.3 Stage D3 — Boss 层 + 章节 Trinket + 隐藏层（dungeon §7.3）

> **进度（2026-05-23）**：✅ 已落地（见 §2.5）。`events.json` 事件 `101099`（大成功 `unlock_hidden_floor`，已删零风险「留下界标」选项）；`floor_state` depth=9 隐藏层；`roguelike_battle_bridge` 应用 `ember_sigil` / `frost_shard` 战斗修正。

#### 配置层

| 文件 | 操作 | 内容 |
| --- | --- | --- |
| [`config/data/trinkets.json`](../../config/data/trinkets.json) | 🆕 | `{ id, name, chapterId, rarity, effects[], description }`；3 章各 4~6 件 |
| [`config/tables/trinkets.lua`](../../config/tables/trinkets.lua) | 🆕 | JSON loader |
| [`config/roguelike/run_trinket_config.lua`](../../config/roguelike/run_trinket_config.lua) | 🆕 | trinket pool（按章）+ Boss 必掉 + 隐藏 Boss 双倍 |
| [`config/roguelike/run_shop_goods.lua`](../../config/roguelike/run_shop_goods.lua) | ✏️ | 章末商店追加 `goodsType=trinket` |
| [`config/data/floors.json`](../../config/data/floors.json) | ✏️ | hidden 模板 roomCount 3~5 + 固定 boss + stair_down |

#### Run 层

| 文件 | 操作 | 关键改动 |
| --- | --- | --- |
| [`roguelike/trinket.lua`](../../roguelike/trinket.lua) | 🆕 | `grantTrinket(state, id)` + 互斥 + 序列化；接入 [`modules/battle_passive_skill.lua`](../../modules/battle_passive_skill.lua) |
| [`roguelike/roguelike_reward.lua`](../../roguelike/roguelike_reward.lua) | ✏️ | 新增 `RollChapterTrinket(chapterId, isHidden)`；章节奖励量级提升到 dungeon §4.7（章 trinket 必掉 + 章 bless ×1 + 装备 ×1~2） |
| [`roguelike/roguelike_run.lua`](../../roguelike/roguelike_run.lua) | ✏️ | Boss 胜利分支调 `Trinket.grant`；新增 `state.trinketIds`；处理事件 `unlock_hidden_floor` 结果（生成隐藏层 + 注入 stair） |
| [`roguelike/dungeon_generator.lua`](../../roguelike/dungeon_generator.lua) | ✏️ | 暴露 `GenerateHiddenFloor(chapterId, seed)`；主线 **当前房邻居** 改写为 `stair_down`（`payload.stairTarget=hidden`） |

#### Web 层

| 文件 | 操作 | 内容 |
| --- | --- | --- |
| [`web/app/types/roguelike.ts`](../../web/app/types/roguelike.ts) | ✏️ | `RunTrinketState` + `RunSnapshot.trinkets` |
| [`web/app/ui/runControls.ts`](../../web/app/ui/runControls.ts) | ✏️ | team / info 面板加 trinket 区域；隐藏层入口提示 |
| [`web/app/render/RunMapScene.ts`](../../web/app/render/RunMapScene.ts) | ✏️ | 隐藏层视觉差异（深色边框 / 紫色调） |

#### 测试

| 文件 | 操作 | 内容 |
| --- | --- | --- |
| [`bin/test_roguelike_boss_trinket.lua`](../../bin/test_roguelike_boss_trinket.lua) | 🆕 | 每章 Boss 必掉 1 件章节 trinket；金币/装备量级符合 §4.7 |
| [`bin/test_roguelike_hidden_floor.lua`](../../bin/test_roguelike_hidden_floor.lua) | 🆕 | 生成器 rooms∈[3,5]；`TestInjectHiddenFloor` + 楼梯闭环 + 双倍 trinket（Boss：`TestForceCurrentBattleVictory`） |
| [`web/tests/roguelike-dungeon.spec.ts`](../../web/tests/roguelike-dungeon.spec.ts) | ✏️ | 通关 3 章 + trinket UI |

**D3 验收**：每章 Boss 必掉 1 件章节 trinket；隐藏层入口存在并可触达；隐藏 Boss 双倍 trinket；Playwright 完整 3 章下钻通关。

### 3.4 Stage D4 — 策划稿维护（与 D2/D3 并行）

> **进度（2026-05-23）**：活跃 `design/` 已与地牢 / 5e EXP 对齐；**D3 落地后**再补 trinket / 隐藏层 / Boss 掉落表段落。

| 文件 | 状态 |
| --- | --- |
| `design/legacy/*` | ✅ 归档，禁止维护 |
| [`design/README.md`](../design/README.md) | ✅ |
| [`design/dungeon_design.md`](../design/dungeon_design.md) | ✅ §4.2 实现引用 + 回归链接 |
| [`design/character_progression_design.md`](../design/character_progression_design.md) | ✅ §2 5e partyExp |
| [`design/roguelike_random_battle_parameter_table.md`](../design/roguelike_random_battle_parameter_table.md) | ✅ 模板池 + budget（非 lane DAG） |
| trinket / 隐藏层专节 | ⏸️ 待 D3 代码落地后回写 |

---

## 4. Assumptions & Decisions

继承 `dungeon_system_dev_plan.md` 的 AD-1..AD-11、`stage_d1_finalize_plan.md` 的 AD-A..AD-G、`dungeon_system_master_plan.md` 的 AD-NEW-1..AD-NEW-4。本计划新增：

| # | 决策 | 理由 |
| --- | --- | --- |
| AD-OVR-1 | `GetAvailableNextNodeIds` 返回**所有 neighbors**（含 visited）作为 cleared 房间通路语义 | 严格对齐 dungeon §4.2「再次进入 cleared 房间仅作通路」；测试逻辑 chooseNextNode 自然偏好未访问 |
| AD-OVR-2 | bin 测试的 chooseNextNode 偏好降低 `stair_down` 优先级，先吃同层 shop/camp/event/battle_normal 再下楼 | 防止队伍跳层后等级断层；与 character_progression_design §3 partyExp 池协同 |
| AD-OVR-3 | `battle_elite` 在 `partyLevel < floorDepth × 2` 时降到末位 | 5e 难度模型 monster_level = floor_depth × 0.8 + 1，elite 额外加压；防止全队阵亡 |
| AD-OVR-4 | D2 的 `events.json` 沿用平铺三层架构（data/tables/skills 同模式），不复用现有 `run_event_config.lua` 的 Lua 内联表 | 用户偏好：静态配置强偏好 JSON / 单一事实来源 |
| AD-OVR-5 | D2 的复活卷轴定价规则：常规章 ×3 普通装备价格，章末 ×4；与 dungeon §4.6「高额金币」对齐 | 防止商店复活刷子；金币只来自战斗（dungeon §9 风险对策） |
| AD-OVR-6 | D3 trinket 不进 `equipmentIds`，独立 `state.trinketIds`；展示与装备系统隔离 | 与 DD1 trinket 文化对齐；UI 单独区域突出"质变"奖励 |
| AD-OVR-7 | ~~`LEVEL_STEP_EXP=20` + 模板 `expReward`~~ → **5e SSOT**（`exp_5e` + `battle_exp_reward` + 楼层等级系数） | 101 章约 13 战 → 队伍 Lv7；`targetMaxLevel=8` |
| AD-OVR-8 | 单场 EXP 封顶（`battle_exp_reward` 按 `GetExpToNextLevel` 与怪物等级放宽 cap） | 避免一场战斗 raw 掉落跨多档阈值 |
| AD-OVR-9 | 101 普通怪等级 = 楼层深度（1–5），不按 profile 抬高 | 保低难度；EXP 靠 `ENEMY_LEVEL_XP_FACTOR` 维持升级 |
| AD-OVR-10 | cleared `battle_*` / `event` 在 `enterNode` 短路为通路 | 对齐 dungeon §4.2；`room_one_shot` 回归 |

---

## 5. Execution Order（严格顺序）

### Stage D1' 收尾

1. ✅ **T1–T4**（见 §2.2）。
2. ✏️ **T6** bin 与 cleared 通路断言（§3.1）。
3. 🟢 **T5** `export:lua` + §2.4 全套 0 退出。

### Stage D1.5（✅ 已完成，后续仅微调系数）

1. ✅ `exp_5e.lua` / `battle_exp_reward.lua` / `encounter_level_curve.lua` / `grantBattleExp`。
2. ✅ `progression_pacing` / `progression_gate` / `party_exp_levelup` / `room_one_shot`。
3. ✏️ 持续：压强用 `run_battle_profile.budget`；节奏用 `ENEMY_LEVEL_XP_FACTOR` 与 `PARTY_EXP_SCALE`，勿改模板 `expReward`。

### Stage D2（当前 sprint）

严格按 §3.2 **D2-T1 → T8**；每完成 T2/T4/T5 可各提交一次；T8 前必须 `cd web && npm run export:lua`。

### Stage D3

D3-T1..T8：trinket data → trinket.lua → reward 改 → run boss 调用 → 隐藏层入口 → Web → 测试 → 导出。

### Stage D4

D3 合并后补 trinket/隐藏层策划段落；与代码 PR 同批。

> 建议：D1' 先单 PR（T6+T5）；D2 按 T1/T2–T3/T4–T5/T7–T8 拆 PR。

---

## 6. Verification

### 6.1 Lua 单测（按阶段）

```bash
# D1' + D1.5（日常）
lua bin/test_roguelike_dungeon_generation.lua
lua bin/test_roguelike_progression_gate.lua
lua bin/test_roguelike_progression_pacing.lua
lua bin/test_roguelike_room_one_shot.lua
lua bin/test_roguelike_act1.lua
lua bin/test_roguelike_chapter_success.lua
lua bin/test_roguelike_balance.lua --runs=4

# D2 新增（落地后）
lua bin/test_roguelike_event_skill_check.lua
lua bin/test_roguelike_camp_full_rest.lua
lua bin/test_roguelike_shop_revive_scroll.lua

# D3 新增（落地后）
lua bin/test_roguelike_boss_trinket.lua
lua bin/test_roguelike_hidden_floor.lua
```

Windows 可选 [`tools/run_balance_checks.ps1`](../tools/run_balance_checks.ps1)。

### 6.2 Web 镜像 + Playwright

```bash
cd web && npm run export:lua
cd web && npm run test:playwright
# 或单测：
cd web && npx playwright test tests/roguelike-act1.spec.ts
cd web && npx playwright test tests/roguelike-dungeon.spec.ts   # D2-T8 新增
```

### 6.3 静态完整性自检

```text
grep -r "mapState"             roguelike/    → 0
grep -r "recruit"              roguelike/ bin/  → 0
grep -r "RunNodePool"          bin/ roguelike/ config/ → 0
grep -r "RunRecruitPool"       bin/ roguelike/ config/ → 0
ls web/public/lua/project/roguelike/dungeon_generator.lua → 存在
ls web/public/lua/project/roguelike/floor_state.lua       → 存在
ls web/public/lua/project/config/tables/floors.lua        → 存在
ls web/public/lua/project/roguelike_map_generator.lua     → **不存在**
```

### 6.4 验收口径（dungeon §8）

- 单层 ≥ 4 种房间类型（roomCount≥6 时）— 已通过 `dungeon_generation` 验证。
- 平均每 Run ≥ 1 次回到上一层（验证商店/营地的回头价值）— D2 e2e 验。
- ≥ 60% 的 Run 能打到第 1 章 Boss（MVP 配置）— `balance.lua --runs=4` 多种子统计。
- bin ≥ 3 个回归（生成/一次性/Boss 奖励）— D1 + D2 + D3 累计满足。
- web/tests/ e2e 覆盖完整下钻 — D2 落地。
- D1.5：任意单战 `partyLevelDelta <= 1`；最终 3 章样本 Lv9~Lv10；seed=10102 不再因 floor=4 等级断层必 wipe。

---

## 7. Out of Scope

继承 dungeon_design §10：

- 地牢外的村镇 / 中转站 / 远征板 / 任务板。
- 撤退 / 疲劳系统。
- 元进度（账号成长 / 解锁 / 永久强化）。
- 跨 Run 永久死亡 / 遗志 / 怪癖。
- 4 缺口职业 Feat 补齐（独立 Stage D4 排期，与本计划解耦）。

---

## 8. 备注

- 所有 Lua 改动后**必须** `cd web && npm run export:lua`（[AGENTS.md](../AGENTS.md)）；新源目录需在 [`tools/export_web_lua.mjs`](../tools/export_web_lua.mjs) `sourceDirs` 注册。
- `config/data/*.json` SSOT 与 `config/tables/*.lua` loader 的对应关系沿用 [`skills.json` ↔ `skill_meta.lua`](../config/tables/skill_meta.lua) 模式。
- 5e 检定**复用** [`core/dice.lua`](../core/dice.lua) + [`modules/ability_5e.lua`](../modules/ability_5e.lua)，避免重新实现 1d20 / 修正逻辑（AGENTS.md 5e Non-Negotiable）。
- 本计划完成后 `design/legacy/` 内旧 Run 主计划不再维护；以本文为准。

---

## 9. 下一步（执行顺序）

1. **D1' T6**：修 `test_roguelike_act1` / `chapter_success` 与 cleared 通路（§3.1）→ **T5** 全绿。
2. ~~**D2-T1～T3**~~：events.json + `event_resolver` + `roguelike_event` 检定（✅）。
3. **D2-T6 → T8**：回归 + Web 网格 / 检定 UI → Playwright。
4. **D3**：trinket 数据与 Boss/隐藏层（§3.3）。
5. **D4**：D3 后补策划 trinket/隐藏层专节。
