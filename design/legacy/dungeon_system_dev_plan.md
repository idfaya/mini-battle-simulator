> **ARCHIVED — 禁止阅读与维护。** 见 [`README.md`](./README.md)。

# Dungeon 系统开发计划

> **已归档**：执行计划已废弃。当前实现见 [`dungeon_design.md`](../dungeon_design.md) 与 [`docs/implementation_guidelines.md`](../../docs/implementation_guidelines.md) §5。

> 上位规则源：[`design/dungeon_design.md`](../design/dungeon_design.md) + [`design/character_progression_design.md`](../design/character_progression_design.md) + [`AGENTS.md`](../AGENTS.md)
>
> 目标：把当前「单章 lane DAG（act_1，8 层）+ recruit/4 选 1 营地」的 Run 系统，重构为「3 章 × 5 层 + 房间迷宫 + 楼梯 + 5e 检定 + 章节 Trinket」的随机地牢系统。

---

## 1. 总体摘要 (Summary)

按 `dungeon_design.md` §7 的阶段 4 / 5 / 6 推进，单方向重构（不做 lane DAG ↔ Dungeon 双跑切换）：

- **阶段 D1 — 地牢生成骨架**（dungeon §7.1）：新增 `dungeon_generator.lua` + `floor_state.lua`，重写章节配置为 3 × 5。
- **阶段 D2 — 房间事件全套**（dungeon §7.2）：5e 检定、营地一键结算、商店扩展（治疗药水 + 复活卷轴 + 不刷新）、Web 房间网格视图。
- **阶段 D3 — Boss 层 + 章节 Trinket**（dungeon §7.3）：trinket 数据 + Boss 必掉 + 隐藏层入口。

每阶段独立验收（bin 回归 + Web Playwright）。所有 Lua 源码改动后必须 `npm run export:lua` 刷新 [`web/public/lua/project/`](../../web/public/lua/project/)。

### 1.1 当前进度快照（2026-05-22 重盘）

> 实际代码盘点结果，避免重复执行已落地的任务。Grep / Read 双重核对。

| 任务 | 状态 | 证据 |
| --- | --- | --- |
| D1-T1 抽 `roguelike/rng.lua` | ✅ 已落地 | [`rng.lua`](../../roguelike/rng.lua) 存在；`Rng.New(seed)` 暴露 `nextInt/pick/weightedPick`，LCG (48271/2147483647) |
| D1-T2 `roguelike/dungeon_generator.lua` | ✅ 已落地 | 文件存在；含 `Generate / GenerateFloor / GenerateHiddenFloor / Validate`；房间 id = `floorDepth*1000+cellIndex`；`HIDDEN_FLOOR_DEPTH=9` |
| D1-T3 `roguelike/floor_state.lua` | ✅ 已落地 | `IsRoomCleared / MarkRoomCleared / GetCurrentFloor / GetRoom / GetAvailableExits / UseStair("up"\|"down")` |
| D1-T4 `config/data/floors.json` + `config/tables/floors.lua` | ✅ 已落地 | 16 个模板（3×5 + 隐藏层）；JSON loader（`GetTemplate / AllTemplates / Init / Reload`）；`tools/export_web_lua.mjs` 已注册 |
| D1-T5 `run_chapter_config.lua` 扩 3 章 × 5 层 | ✅ 已落地 | [`run_chapter_config.lua`](../../config/roguelike/run_chapter_config.lua) 含 [101][102][103]，含 `floorTemplateIds` / `hiddenFloorTemplateId`；删了 `routeBlueprint` |
| D1-T5 `run_map_gen_profile.lua` 转薄壳 | ✅ 已落地 | [`run_map_gen_profile.lua`](../../config/roguelike/run_map_gen_profile.lua) 仅含 `{ id, chapterId }` 三条（101001/102001/103001） |
| D1-T5 `init.lua` 摘 Nodes 行 | ✅ 已落地 | [`init.lua`](../../config/roguelike/init.lua) 已无 `Nodes = require("config.roguelike.run_node_pool")` |
| D1-T6.1 `roguelike_map.lua` 转 dungeon 转发 | ✅ 已落地 | [`roguelike_map.lua`](../../roguelike/roguelike_map.lua) 200 行新版；依赖 `DungeonGenerator` + `RunChapterConfig`；提供 `GetChapter / GetNode / GetChapterNodes / BuildChapterMap / GetAvailableNextNodeIds / GenerateChapterMap`；`buildNodeView` 把 room → 兼容 lane DAG node 视图 |
| D1-T6.2 `roguelike_run.lua` 适配 dungeon | ✅ 已落地（含楼梯弹窗 commit `82f6dca`） | dungeonState + stair_up/stair_down/equip/empty 分支齐备；recruit 三处分支已删；enterChapterResult 章 1/2 → 下一章；进入楼梯房改设 `state.phase="stair"` + `state.stairState`，新增 `StairUse` / `StairLeave` API（用户指示「楼梯房可不上下楼直接路过」） |
| D1-T6.3 `roguelike_snapshot.lua` 字段切换 | ✅ 已落地 | runState.dungeonState + currentFloorDepth + stairState 已输出，UI/测试可读取 direction/nodeId/currentFloorDepth 渲染弹窗 |
| D1-T7.1 删 `roguelike_reward.lua` 的 recruit 链路 | ✅ 已落地 | `RunRecruitPool` import 与 recruit 三处分支已删 |
| D1-T7.2 删 3 个旧文件 | ✅ 已落地 | `roguelike_map_generator.lua` / `run_node_pool.lua` / `run_recruit_pool.lua` 已 DeleteFile |
| D1-T8.1 新增 `bin/test_roguelike_dungeon_generation.lua` | ✅ 已落地 | 通过（200 seeds × 3 chapters） |
| D1-T8.2 改 act1 / chapter_success / balance 三个 bin | ✅ 已落地（commit `82f6dca`） | 三个 bin 全部补 `stair` phase 分支：方向感知（down 推进；up 仅 partyLevel 不足时回补）；act1/chapter_success 引入 PREFERENCE 表 + BFS findPathNextHop 寻路修复 cleared 走廊死循环；camp short_rest fallback；act1 seed=10101 通过、chapter_success seed=10101 通过；act1 seed=10102 floor=4 真实战斗 wipe（独立难度议题） |
| D1-T9 `npm run export:lua` + 全套回归 | ✅ 已落地 | 镜像与源 Lua 一致；核心 bin 通过见上 |
| D2 / D3 | ⏸️ 未启动 | 见 §4 清单（房间事件 / 5e 检定 / Trinket / 隐藏层 / Web 重写） |

**剩余 D1 执行链**（commit `82f6dca` 后已全部完结）：

1. ~~T6.2~~ ✅ `roguelike_run.lua`：dungeonState + stair_up/stair_down 弹窗 phase + StairUse/StairLeave API；删 recruit 三处分支；enterChapterResult 章 1/2 自动切下一章。
2. ~~T6.3~~ ✅ `roguelike_snapshot.lua`：dungeonState + currentFloorDepth + stairState 输出，UI/测试可渲染楼梯弹窗。
3. ~~T7.1~~ ✅ `roguelike_reward.lua`：recruit 链路全清。
4. ~~T7.2~~ ✅ 物理删除 `roguelike_map_generator.lua` / `run_node_pool.lua` / `run_recruit_pool.lua`。
5. ~~T8.1~~ ✅ 新增 `bin/test_roguelike_dungeon_generation.lua`。
6. ~~T8.2~~ ✅ 改三个 bin：补 stair phase 分支 + PREFERENCE+BFS 路径选择 + camp fallback。
7. ~~T9~~ ✅ `npm run export:lua` + 核心 bin 通过。

**遗留议题**（纳入 D1.5 平衡收尾）：
- act1 seed=10102 在 floor=4 真实战斗 wipe：根因不是楼梯/路由，而是旧 EXP 曲线按 lane DAG 少战斗数设计，迁移到迷宫后单战 2~5 级、等级/数值节奏失真；按 §1.2 统一重设。

Stage D2 / D3 沿用本文 §4 的清单，无变更。

### 1.2 D1.5 升级速度与战斗数值再平衡（新增）

> 目标：按当前迷宫房间生成后的实际战斗次数重设 EXP 与难度，确保**单场战斗最多只跨 1 个 partyLevel**，同时让 10 级上限、Lv3 子职业、Lv5 峰值、Lv7/9 自动授予节奏成立。

#### 当前迷宫战斗次数基线

统计口径：`DungeonGenerator.Generate(seed, chapter)`，seed `10001..10200`，统计每章全部房间中的 `battle_normal / battle_elite / boss`。

| 章节 | 平均总战斗 | 最小 | 最大 | 平均普通 | 平均精英 | Boss | 楼层均值 `[F1,F2,F3,F4,F5]` |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| 101 | 13.12 | 6 | 19 | 9.96 | 2.15 | 1.00 | `[2.99,2.69,3.23,3.21,1.00]` |
| 102 | 12.74 | 7 | 19 | 9.70 | 2.04 | 1.00 | `[2.73,2.62,3.26,3.12,1.00]` |
| 103 | 12.47 | 5 | 19 | 9.31 | 2.16 | 1.00 | `[2.56,2.56,3.21,3.15,1.00]` |

设计结论：
- 当前每章约 13 场战斗，完整 3 章约 38~39 场；不能再沿用旧版 10 EXP/级 + 25~50 EXP/战的 lane DAG 节奏。
- 目标全 Run 从 Lv1 到 Lv10 只需要 9 次队伍等级提升，平均约每 4 场战斗提升 1 次。
- 单战 EXP 必须小于等于等级步长，才能从任意 `levelProgressExp` 状态最多只跨 1 个等级阈值。

#### 新 EXP 曲线

| 项 | 新值 | 说明 |
| --- | ---: | --- |
| `LEVEL_STEP_EXP` | 20 | 固定线性步长，保持 SSOT 在 `config/roguelike/level_curve.lua` |
| `CHAPTER_LEVEL_CAP` | 10 | 对齐 10 级上限；如运行时仍需欠抽缓冲，可保留内部 cap，但展示/成长规则以 10 为硬上限 |
| Lv2 | 20 | 约第 4~5 场战斗 |
| Lv3 | 40 | 约 Act1 F3/F4，触发子职业选择 |
| Lv5 | 80 | 约 Act2 前半，形成第一波主要强度峰值 |
| Lv7 | 120 | 约 Act2 Boss / Act3 开局，自动授予节点 |
| Lv9 | 160 | 约 Act3 中后段，自动授予节点 |
| Lv10 | 180 | 约 Act3 Boss / 隐藏层前后达到上限 |

#### 新战斗 EXP 奖励表

| 模板 | 当前 EXP | 新 EXP | 目的 |
| --- | ---: | ---: | --- |
| `201001 act1_normal_early` | 30 | 4 | 教学/早期普通战，约 5 场升 1 级 |
| `201002 act1_normal_mid` | 25 | 4 | 中期普通战，维持稳定进度 |
| `201003 act1_normal_late` | 30 | 5 | 后期普通战略高，但仍远低于 1 级 |
| `201101 act1_elite_mid` | 35 | 6 | 精英给明显奖励，不直接跳级 |
| `201102 act1_elite_late` | 40 | 7 | 后期精英奖励上限仍小于等级步长 |
| `201201 act1_boss` | 50 | 8 | Boss 有奖励感，但单场绝不超过 1 级 |
| `201301 act1_event_battle_skirmish` | 20 | 3 | 事件战略低于普通战 |
| `201302 act1_event_battle_ritual` | 25 | 4 | 事件战晚期等同普通中期 |

按当前平均战斗结构估算：单章约 `10×4 + 2×6~7 + 1×8 = 60~62 EXP`；完整 3 章约 `180~186 EXP`，正好覆盖 Lv1→Lv10。

#### 难度与奖励联动

| 项 | 调整方向 | 说明 |
| --- | --- | --- |
| 普通战 | `budget.difficulty="easy"`，`pressureFactor` 随章节缓升 | 不再用高 EXP 快速补强玩家；通过低压强保证连续迷宫战斗可承受 |
| 精英战 | 保持单波，`pressureFactor` 约普通战 +0.08~0.14 | 精英是资源消耗点，不是必杀点；seed=10102 floor=4 不应因首次精英必 wipe |
| Boss 战 | 章节 Boss 以机制/波次给压强，不靠 EXP 补偿 | Boss EXP=8 只提供一次可见推进，不改变整章平衡 |
| 章节差异 | 章 2/3 优先调 `battle profile level` 与 `budget.pressureFactor` | 遵守 AGENTS.md：不叠 ad-hoc 倍率 |

#### D1.5 执行任务

1. D1.5-T1：修改 `config/roguelike/level_curve.lua`：`LEVEL_STEP_EXP=20`，展示/成长上限按 10 级校准。
2. D1.5-T2：修改 `config/roguelike/run_battle_template.lua`：按上表下调所有 `expReward` 与注释。
3. D1.5-T3：补 `bin/test_roguelike_progression_pacing.lua`：断言任意单场 `expReward <= LevelCurve.GetExpToNextLevel(level)`，且完整 3 章平均到达 Lv9~Lv10。
4. D1.5-T4：扩 `bin/test_roguelike_balance.lua`：记录每 run 战斗次数、partyLevel 曲线、单战 level delta；出现 `delta > 1` 直接失败。
5. D1.5-T5：复测 seed `10101 / 10102` 与 `--runs=20`，验收标准见 §6.5。

---

## 2. 现状分析 (Current State Analysis)

### 2.1 关键模块（已有）

| 模块 | 现状要点 | 与目标差距 |
| --- | --- | --- |
| [`roguelike/roguelike_run.lua`](../../roguelike/roguelike_run.lua) | `state` 字段集中在 L251-288；`enterNode` (L307-368) 路由 7 类节点；`StartRun` L470 调用 `RoguelikeMap.GenerateChapterMap` | 节点类型、map state、章节切换均按 lane DAG 设计 |
| [`roguelike/roguelike_map.lua`](../../roguelike/roguelike_map.lua) + [`roguelike_map_generator.lua`](../../roguelike/roguelike_map_generator.lua) | 输出 `floor + lane` DAG，多 attempt 用 `battleRatioMin` 校验 | 必须替换为「房间迷宫 + 楼梯」 |
| [`config/roguelike/run_chapter_config.lua`](../../config/roguelike/run_chapter_config.lua) | 仅 1 章 `[101]`，`floorCount=8`，含 `routeBlueprint` 手写蓝图 | 需 3 章 × 5 层；删 `routeBlueprint` |
| [`config/roguelike/run_map_gen_profile.lua`](../../config/roguelike/run_map_gen_profile.lua) | lane DAG 参数（`nodeCountByFloor` / `typeWeightsByFloor` / `*FloorRange`） | 整体改为 floor template（迷宫尺寸 + 房间权重 + must-have） |
| [`config/roguelike/run_node_pool.lua`](../../config/roguelike/run_node_pool.lua) | 13 个手写节点 | 全部由生成器产出，文件可删（保留兼容 forwarder 直到测试切完） |
| [`roguelike/roguelike_event.lua`](../../roguelike/roguelike_event.lua) + [`run_event_config.lua`](../../config/roguelike/run_event_config.lua) | 5 类 resultType；3 条事件；**无 5e 检定** | 新增 `skillCheck`，4 档结果分发 |
| [`roguelike/roguelike_camp.lua`](../../roguelike/roguelike_camp.lua) | 4 选 1 菜单；`revive_full_rest` 只清复活者状态 | 改为一键结算：全队 heal 100% + 清全队负面 + 复活 1 |
| [`roguelike/roguelike_shop.lua`](../../roguelike/roguelike_shop.lua) + [`run_shop_goods.lua`](../../config/roguelike/run_shop_goods.lua) | 支持付费刷新；`revive_one_40` healPct=0.20；无治疗药水 / 复活卷轴独立 SKU | 关闭 Refresh；新增治疗药水 + 复活卷轴；healPct→0.5 |
| [`roguelike/roguelike_reward.lua`](../../roguelike/roguelike_reward.lua) | 装备 tier=common/rare/boss；精英 50% 祝福、Boss 必掉；含 recruit 链路 (L245-338) | **无 trinket 概念**；recruit 链路废弃 |
| [`web/app/render/RunMapScene.ts`](../../web/app/render/RunMapScene.ts) | 按 floor + lane 画 DAG；7 类节点颜色 | 重写为「房间网格 + 楼梯按钮 + cleared 半透明」 |
| [`web/app/types/roguelike.ts`](../../web/app/types/roguelike.ts) | `RunNodeType` 含 recruit；`RunMapState` 是 nodes+edges | 新增 `RunRoomState/Door/Stair`；去 recruit；加 `currentFloor / trinkets` |
| [`web/app/ui/runControls.ts`](../../web/app/ui/runControls.ts) | `renderMapPanel` (L562-609) 走 `selectable` 节点；`info` 面板 phase 分支 (L423-559) | 改为楼层视图 + 房间点击 + 楼梯按钮；事件面板加检定 DC 显示 |
| [`design/roguelike_random_battle_parameter_table.md`](../../design/roguelike_random_battle_parameter_table.md) | 8 层模板，无 dungeon 难度公式 | 补 `monster_level=floor*0.8+1`、`pressureFactor=1+0.06*floor`、Boss×1.3、章 2/3 模板、隐藏层 |
| [`design/roguelike_random_map_parameter_table.md`](../../design/roguelike_random_map_parameter_table.md) | lane DAG 参数全套 | 整体改写为「房间迷宫 + 楼梯」 |

### 2.2 已稳定可保留

- [`roguelike/feat_picker.lua`](../../roguelike/feat_picker.lua) + 升级三选一（progression §7 阶段 1-3 已完成）。
- [`roguelike/roguelike_battle_bridge.lua`](../../roguelike/roguelike_battle_bridge.lua) + [`roguelike_battle_resolver.lua`](../../roguelike/roguelike_battle_resolver.lua)。
- [`config/roguelike/level_curve.lua`](../../config/roguelike/level_curve.lua) 经验曲线。
- [`config/roguelike/run_blessing_config.lua`](../../config/roguelike/run_blessing_config.lua) 8 件祝福（章 2/3 仅做扩池）。
- [`config/roguelike/run_battle_*`](../../config/roguelike/) 战斗 / 编成 / 怪物池配置（按层数扩展即可）。

### 2.3 当前测试矩阵

| 测试 | 关键依赖 |
| --- | --- |
| [`bin/test_roguelike_act1.lua`](../../bin/test_roguelike_act1.lua) | lane DAG `nextNodeIds` + 4 类节点必经路线 + recruit 路径 |
| [`bin/test_roguelike_chapter_success.lua`](../../bin/test_roguelike_chapter_success.lua) | `selectable` lane 节点 + `boss_defeated` |
| [`bin/test_roguelike_balance.lua`](../../bin/test_roguelike_balance.lua) | `ROUTE_PRESETS[101]` 节点序列 |
| [`bin/test_roguelike_progression_gate.lua`](../../bin/test_roguelike_progression_gate.lua) | 仅依赖 partyExp / FeatPicker（**与地图无关，可保留**） |
| [`web/tests/roguelike-act1.spec.ts`](../../web/tests/roguelike-act1.spec.ts) | nodeType 枚举（含 recruit） + lane 选节点 |

---

## 3. 关键决策与假设 (Assumptions & Decisions)

| # | 决策 | 备选 / 风险 |
| --- | --- | --- |
| AD-1 | **单方向重构**：删除 lane DAG，不做兼容双跑。`roguelike_map_generator.lua` / `roguelike_map.lua` 直接重写为 dungeon 转发；旧 `run_node_pool.lua` 在 D1 验收后删除 | 备选「feature flag 双跑」会拖一倍维护成本；用户偏好彻底清理冗余层（user_profile） |
| AD-2 | 节点类型集合调整为：`battle_normal / battle_elite / event / camp / shop / boss / stair_up / stair_down / equip / empty`，**移除 `recruit`** | 与 dungeon §10 一致；recruit 链路全删 |
| AD-3 | 迷宫主算法选 **Recursive Backtracker**，`extraDoorRatio=0.10~0.20` 控制回路 | Prim 列为备选；Prim 倾向短分支，可选 profile 切换 |
| AD-4 | **房间网格 4×4 / Boss 层 3×3 / 隐藏层 3×3**，`roomCount.max ≤ floor(W*H*0.7)` | 防止"长链退化"；可在 floors 配置里覆写 |
| AD-5 | **章节配置物理结构保持 Lua**（`run_chapter_config.lua`），但**单层模板用 JSON**（`config/data/floors.json` + `config/tables/floors.lua`），与 `skills.json/passives.json/heroes.json` SSOT 对齐 | 用户偏好 JSON SSOT（user_profile） |
| AD-6 | **Trinket 是新独立数据**（`config/data/trinkets.json` + `run_trinket_config.lua`），不复用装备 / 祝福；`state.trinketIds` 独立数组 | 装备槽位与 5e 装备规则冲突，trinket 走"被动效果"路径 |
| AD-7 | **5e 检定接入 [`core/dice.lua`](../../core/dice.lua)** + [`modules/ability_5e.lua`](../../modules/ability_5e.lua)，统一公式 `1d20 + abilityMod vs DC`，4 档结果（DC ≤ -10 = 大成功 / 自然 1-自然 20 加权） | 与 AGENTS.md "5e 规则" 一致 |
| AD-8 | **商店关闭 Refresh**（dungeon §4.6）；UI 隐藏刷新按钮；服务端 `RoguelikeShop.Refresh` 保留但走配置 `enableRefresh=false` 拒绝 | 防 Web 旧调用 |
| AD-9 | **章节切换不可逆**：章末 Boss 击杀后跳到下一章 floor=1，章 3 才走 `chapter_result` 终局 | dungeon §3.1 |
| AD-10 | **难度模型对接 dungeon §3.2**：`monster_level = floor(floor_depth × 0.8) + 1`、`pressureFactor = 1.0 + 0.06 × floor_depth`，Boss 层 ×1.3；通过 `roguelike_random_battle_parameter_table.md` 的 budget 系统注入，不引入 ad-hoc 倍率（AGENTS.md 难度模型） | — |
| AD-11 | **阶段 7（4 缺口职业 Feat 补齐）独立排期**，与 D1/D2/D3 解耦 | 与地牢拓扑无强耦合 |

---

## 4. 提议变更 (Proposed Changes)

> 标记：🆕 新增 / ✏️ 修改 / 🗑️ 删除 / ✅ 保留

### 阶段 D1：层级地牢生成

#### 配置层

| 文件 | 操作 | 内容 |
| --- | --- | --- |
| [`config/data/floors.json`](../../config/data/floors.json) | 🆕 | floor template：`{ id, gridW, gridH, roomCount{min,max}, extraDoorRatio, typeWeights, mustHave, constraints, isBoss?, isHidden? }` |
| [`config/tables/floors.lua`](../../config/tables/floors.lua) | 🆕 | JSON loader（与 [`skill_meta.lua`](../../config/tables/skill_meta.lua) 风格一致），暴露 `Floors.GetTemplate(id)` |
| [`config/json_loader.lua`](../../config/json_loader.lua) | ✏️ | 注册 `floors.json` |
| [`config/roguelike/run_chapter_config.lua`](../../config/roguelike/run_chapter_config.lua) | ✏️ | 新增 `[102] [103]`；统一 `floorCount=5`；删 `routeBlueprint`、`startNodeId`、`bossNodeId`（改由生成器输出）；新增 `floorTemplateIds[1..5]`、`bossFloorTemplateId`、`hiddenFloorTemplateId?` |
| [`config/roguelike/run_map_gen_profile.lua`](../../config/roguelike/run_map_gen_profile.lua) | ✏️ | 改为薄壳：把 chapter+floor 转给 `Floors.GetTemplate`；删除 lane 时代字段（`nodeCountByFloor` / `typeWeightsByFloor` / `*FloorRange` / `recruitPoolId`） |
| [`config/roguelike/run_node_pool.lua`](../../config/roguelike/run_node_pool.lua) | 🗑️ | 在 D1 验收后删除（生成器接管） |
| [`config/roguelike/run_recruit_pool.lua`](../../config/roguelike/run_recruit_pool.lua) | 🗑️ | recruit 链路废弃 |
| [`config/roguelike/init.lua`](../../config/roguelike/init.lua) | ✏️ | 摘掉 `RunNodePool` / `RunRecruitPool` |

#### Run 层（Lua）

| 文件 | 操作 | 关键改动 |
| --- | --- | --- |
| [`roguelike/dungeon_generator.lua`](../../roguelike/dungeon_generator.lua) | 🆕 | Recursive Backtracker 主算法 + 强连通校验；输出 `DungeonState{ floors[1..15], currentFloorDepth, currentRoomId }` 与 `FloorState{ rooms[id]={gridX,gridY,roomType,neighbors[],payload}, doors[], startRoomId, downStairRoomId, upStairRoomId }`；楼梯放置：`upStair = max-distance from downStair`；Boss / 隐藏层走独立模板 |
| [`roguelike/floor_state.lua`](../../roguelike/floor_state.lua) | 🆕 | 房间状态机：`enterRoom / clearRoom / getAvailableExits / useStair`；shop 房豁免 cleared；提供 `IsRoomCleared / GetCurrentFloor` |
| [`roguelike/rng.lua`](../../roguelike/rng.lua) | 🆕 | 抽出 [`roguelike_map_generator.lua` L13-L54](../../roguelike/roguelike_map_generator.lua#L13-L54) 的 LCG（`makeRng / nextInt / pick / weightedPick`），复用给 dungeon_generator |
| [`roguelike/roguelike_map.lua`](../../roguelike/roguelike_map.lua) | ✏️ | `BuildChapterMap / GetAvailableNextNodeIds / GenerateChapterMap` 改为转发 dungeon_generator；`GetNode` 用 `floor.rooms[roomId]` |
| [`roguelike/roguelike_map_generator.lua`](../../roguelike/roguelike_map_generator.lua) | 🗑️ | D1 完成 + 测试通过后删除 |
| [`roguelike/roguelike_run.lua`](../../roguelike/roguelike_run.lua) | ✏️ | `state.mapState` → `state.dungeonState`（含 `currentFloorDepth`、`floorVisits`）；`enterNode` 加 `stair_up`/`stair_down` 分支（切层不消耗 cleared）；删 `recruit` 分支；`enterChapterResult`：章 1/2 → `chapterId += 1; currentFloorDepth = next chapter.floor1.startRoomId`，章 3 → 终局 |

#### 测试

| 文件 | 操作 | 内容 |
| --- | --- | --- |
| [`bin/test_roguelike_dungeon_generation.lua`](../../bin/test_roguelike_dungeon_generation.lua) | 🆕 | 1000 次种子：每层 BFS 全连通；第 1 层无 upStair；上下楼梯不撞房；roomType 多样性 ≥ 4；Boss 层模板符合；营地 ≤ 1 / 商店 ≤ 1 |
| [`bin/test_roguelike_act1.lua`](../../bin/test_roguelike_act1.lua) | ✏️ | 删 recruit 路径；`pathCanReachType` 改为相邻房间 BFS；`chooseNextNode` 改为「同层探索 + stair_down 优先」 |
| [`bin/test_roguelike_chapter_success.lua`](../../bin/test_roguelike_chapter_success.lua) | ✏️ | 把 act1 8 层断言改为 5 层 + 三章 boss_defeated 链 |
| [`bin/test_roguelike_balance.lua`](../../bin/test_roguelike_balance.lua) | ✏️ | `ROUTE_PRESETS` 改为 dungeon 房间序列 + 楼梯 token；接入新难度公式 |

### 阶段 D2：房间事件全套

#### 配置层

| 文件 | 操作 | 内容 |
| --- | --- | --- |
| [`config/data/events.json`](../../config/data/events.json) | 🆕 | 事件 schema：`{ id, chapterIds[], options[{ id, label, kind, skillCheck?{ ability, dc, results{ critSuccess, success, failure, critFailure } }, zeroRisk?, payload }] }`；至少 12 条覆盖 3 章 |
| [`config/tables/events.lua`](../../config/tables/events.lua) | 🆕 | JSON loader |
| [`config/roguelike/run_event_config.lua`](../../config/roguelike/run_event_config.lua) | ✏️ | 改为薄壳转发到 `Events`；保留旧 3 条事件迁出后删除 |
| [`config/roguelike/run_shop_goods.lua`](../../config/roguelike/run_shop_goods.lua) | ✏️ | 章 1/2/3 各 1 家商店；新增 `potion_heal_one_50`（单角色 50%）；`revive_scroll_50`（healPct=0.5，价格 dungeon §4.6 高额）；删 `remove_one_curse` 占位 |
| [`config/roguelike/run_camp_config.lua`](../../config/roguelike/run_camp_config.lua) | ✏️ | 改为 1 个 action `revive_full_rest`（dungeon §4.5：全队回满 + 清全队负面 + 复活 1） |

#### Run 层

| 文件 | 操作 | 关键改动 |
| --- | --- | --- |
| [`roguelike/event_resolver.lua`](../../roguelike/event_resolver.lua) | 🆕 | 5e 检定：`resolveSkillCheck(hero, ability, dc) → { roll, total, tier ∈ {critSuccess,success,failure,critFailure} }`；零风险路径走 `option.zeroRisk` 直接结算 |
| [`roguelike/roguelike_event.lua`](../../roguelike/roguelike_event.lua) | ✏️ | `ResolveOption` 调用 `event_resolver`；扩展 4 档结果到现有 5 类 resultType + 新增 `result_unlock_hidden_floor`（D3 用） |
| [`roguelike/roguelike_camp.lua`](../../roguelike/roguelike_camp.lua) | ✏️ | `revive_full_rest` 增加 `applyTeamHeal(state, 1.0)` + 全队 `clearAllStatuses`；删除 `grant_blessing` / `revive_one`；UI 一键结算无菜单 |
| [`roguelike/roguelike_shop.lua`](../../roguelike/roguelike_shop.lua) | ✏️ | `Refresh` 内部判 `enableRefresh==false` 直接 reject；新增 `applyPotionHealOne` / 修正 `applyReviveScroll`（healPct 来自 payload）；扩展 service 路由；shop 房进入豁免 visited（已支持，仅 UI 暴露） |
| [`roguelike/roguelike_run.lua`](../../roguelike/roguelike_run.lua) | ✏️ | `enterNode` shop 分支：cleared 房间也允许重新进入；`floorState.clearRoom` 在战斗 / 事件 / 营地结束时调用 |

#### Web 层

| 文件 | 操作 | 关键改动 |
| --- | --- | --- |
| [`web/app/types/roguelike.ts`](../../web/app/types/roguelike.ts) | ✏️ | `RunNodeType` 删 `recruit`；新增 `RunRoomType = battle_normal | battle_elite | event | camp | shop | boss | stair_up | stair_down | equip | empty`；新增 `RunRoomState{ id, gridX, gridY, roomType, cleared, doors:number[], payload? }` / `RunFloorState{ depth, rooms[], stairsUp?, stairsDown }` / `RunDungeonState{ floors[], currentFloorDepth, currentRoomId }`；`RunSnapshot` 新增 `dungeon`、`trinkets`（D3）；`EventOptionState` 新增 `skillCheck?{ability,dc}`、`zeroRisk?`；`ShopGoodsState.goodsType` 加 `potion`/`revive_scroll` |
| [`web/app/render/RunMapScene.ts`](../../web/app/render/RunMapScene.ts) | ✏️ | 整体重写：渲染当前楼层的房间网格（按 gridX/gridY），门用相邻线条，cleared 半透明，stair_up/down 用上下箭头图标；楼层切换不重渲（仍按 currentFloorDepth 显示一层） |
| [`web/app/ui/runControls.ts`](../../web/app/ui/runControls.ts) | ✏️ | `renderMapPanel` (L562-609) 改为：当前楼层标题 + 房间点击 + stair 按钮；`renderInfoPanel` event 分支 (L423-432) 显示「检定 ability + DC + 当前队员的修正」并在结算后显示 4 档结果文案；shop 面板隐藏 Refresh 按钮；camp 面板改为单按钮"安息"；删 recruit 分支 (L439, L454, L504) |
| [`web/app/render/RunMapScene.ts`](../../web/app/render/RunMapScene.ts) 颜色 | ✏️ | 节点颜色表加 `stair_up/stair_down/equip/empty` |
| [`web/lua_source/web_entry.lua`](../../web/lua_source/web_entry.lua) | ✏️ | `RunSnapshot` 序列化加 `dungeon` |

#### 测试

| 文件 | 操作 | 内容 |
| --- | --- | --- |
| [`bin/test_roguelike_event_skill_check.lua`](../../bin/test_roguelike_event_skill_check.lua) | 🆕 | 1d20 + mod vs DC 的 4 档结果分布（10000 次蒙特卡罗）；零风险选项 100% 跳骰 |
| [`bin/test_roguelike_room_one_shot.lua`](../../bin/test_roguelike_room_one_shot.lua) | 🆕 | 战斗 / 事件 / 营地房 cleared 后再进入仅作通路；shop 房可重复进入 |
| [`bin/test_roguelike_camp_full_rest.lua`](../../bin/test_roguelike_camp_full_rest.lua) | 🆕 | 全队 heal 100% + 清全队负面 + 复活 1；无菜单 |
| [`web/tests/roguelike-dungeon.spec.ts`](../../web/tests/roguelike-dungeon.spec.ts) | 🆕 | 完整下钻 e2e（多层 + 楼梯 + shop 二次进入 + 5e 检定 UI） |
| [`web/tests/roguelike-act1.spec.ts`](../../web/tests/roguelike-act1.spec.ts) | ✏️ | preferredTypes 移除 recruit；`chooseNodeAndEnter` 改为 room + stair |

### 阶段 D3：Boss 层 + 章节 Trinket + 隐藏层

#### 配置层

| 文件 | 操作 | 内容 |
| --- | --- | --- |
| [`config/data/trinkets.json`](../../config/data/trinkets.json) | 🆕 | trinket schema：`{ id, name, chapterId, rarity, effects[], description }`；3 章各 4~6 件 |
| [`config/tables/trinkets.lua`](../../config/tables/trinkets.lua) | 🆕 | JSON loader |
| [`config/roguelike/run_trinket_config.lua`](../../config/roguelike/run_trinket_config.lua) | 🆕 | trinket pool（按章）+ Boss 必掉 + 隐藏层 Boss 双倍规则 |
| [`config/roguelike/run_shop_goods.lua`](../../config/roguelike/run_shop_goods.lua) | ✏️ | 章末商店追加 `goodsType=trinket` 条目 |
| [`config/data/floors.json`](../../config/data/floors.json) | ✏️ | 新增 hidden 模板（roomCount 3~5、固定 boss + stair_down） |

#### Run 层

| 文件 | 操作 | 关键改动 |
| --- | --- | --- |
| [`roguelike/trinket.lua`](../../roguelike/trinket.lua) | 🆕 | `grantTrinket(state, id)` + 互斥 + 序列化；接入 [`modules/battle_passive_skill.lua`](../../modules/battle_passive_skill.lua) 注入战斗效果 |
| [`roguelike/roguelike_reward.lua`](../../roguelike/roguelike_reward.lua) | ✏️ | 新增 `RollChapterTrinket(chapterId, isHidden)`；删除 `AddRecruit / GenerateRecruitRewardState / createHeroRecord` (L245-338) 及相关 reward type |
| [`roguelike/roguelike_run.lua`](../../roguelike/roguelike_run.lua) | ✏️ | Boss 胜利分支 (L565-585) 调用 `Trinket.grant`；章节金币 / 经验 / 装备掉落量级提升到 dungeon §4.7；新增 `state.trinketIds`；`enterNode` 处理事件 `unlock_hidden_floor` 结果（生成隐藏层并把 stair 写入当前层） |
| [`roguelike/dungeon_generator.lua`](../../roguelike/dungeon_generator.lua) | ✏️ | 暴露 `GenerateHiddenFloor(chapterId, seed)`，由事件回调调用 |

#### Web 层

| 文件 | 操作 | 内容 |
| --- | --- | --- |
| [`web/app/types/roguelike.ts`](../../web/app/types/roguelike.ts) | ✏️ | 新增 `RunTrinketState`；`RunSnapshot.trinkets` 字段 |
| [`web/app/ui/runControls.ts`](../../web/app/ui/runControls.ts) | ✏️ | `team` / `info` 面板新增 trinket 区域；隐藏层入口提示 |
| [`web/app/render/RunMapScene.ts`](../../web/app/render/RunMapScene.ts) | ✏️ | 隐藏层视觉差异化（深色边框 / 紫色调） |

#### 测试

| 文件 | 操作 | 内容 |
| --- | --- | --- |
| [`bin/test_roguelike_boss_trinket.lua`](../../bin/test_roguelike_boss_trinket.lua) | 🆕 | 每章 Boss 必掉 1 件章节 trinket；章节金币 / 装备奖励量级符合 dungeon §4.7 |
| [`bin/test_roguelike_hidden_floor.lua`](../../bin/test_roguelike_hidden_floor.lua) | 🆕 | 事件大成功解锁隐藏层；房间数 ∈ [3,5]；Boss 必掉双倍 trinket |
| [`web/tests/roguelike-dungeon.spec.ts`](../../web/tests/roguelike-dungeon.spec.ts) | ✏️ | 通关 3 章并验证 trinket UI |

### 设计文档同步

| 文件 | 操作 |
| --- | --- |
| [`design/roguelike_run_system_design.md`](../../design/roguelike_run_system_design.md) | ✏️ 章节结构改为「Run = 多层地牢」 |
| [`design/roguelike_node_parameter_table.md`](../../design/roguelike_node_parameter_table.md) | ✏️ 节点 → 房间类型语义平移 |
| [`design/roguelike_random_map_parameter_table.md`](../../design/roguelike_random_map_parameter_table.md) | ✏️ 整体改写为「房间迷宫 + 楼梯」 |
| [`design/roguelike_random_battle_parameter_table.md`](../../design/roguelike_random_battle_parameter_table.md) | ✏️ 补难度公式 + 章 2/3 模板 + 隐藏层 |

---

## 5. 阶段任务清单（执行顺序）

### Stage D1 — 层级地牢生成（dungeon §7.1）

1. D1-T1：抽 `roguelike/rng.lua`，[`roguelike_map_generator.lua` L13-54](../../roguelike/roguelike_map_generator.lua#L13-L54) 改为转发。
2. D1-T2：实现 `roguelike/dungeon_generator.lua`（含 `Generate / GenerateHiddenFloor / Validate`）。
3. D1-T3：实现 `roguelike/floor_state.lua`。
4. D1-T4：新增 `config/data/floors.json` + `config/tables/floors.lua`。
5. D1-T5：扩 `run_chapter_config.lua` 至 3 章 × 5 层；`run_map_gen_profile.lua` 转发到 `Floors`。
6. D1-T6：`roguelike_map.lua` 转发到 dungeon_generator；`roguelike_run.lua` 状态字段切换 + stair 分支 + 章节切换；删除 `recruit` 分支与 `pendingRecruitHeroId`。
7. D1-T7：删除 `run_node_pool.lua` / `run_recruit_pool.lua` / `roguelike_map_generator.lua`；`init.lua` 同步。
8. D1-T8：新增 `bin/test_roguelike_dungeon_generation.lua`；改 `act1 / chapter_success / balance` 三个 bin 测试。
9. D1-T9：`npm run export:lua` 刷新；运行 `tools/run_balance_checks.ps1` + bin 全套。

**D1 验收**：
- `bin/test_roguelike_dungeon_generation.lua` 通过；
- `bin/test_roguelike_act1.lua` 已迁移到房间模型并通过；
- 单层 ≥ 4 种 roomType；Boss 层模板正确；3 章串联无回退。

### Stage D2 — 房间事件全套（dungeon §7.2）

1. D2-T1：`config/data/events.json` + `config/tables/events.lua`；迁移现有 3 条事件 + 新增 9 条。
2. D2-T2：`roguelike/event_resolver.lua` 实现 5e 检定；接入 `core/dice.lua` + `modules/ability_5e.lua`。
3. D2-T3：`roguelike_event.lua` 改派；`run_event_config.lua` 转发。
4. D2-T4：`roguelike_camp.lua` + `run_camp_config.lua` 改为一键结算（全队 heal + 清状态 + 复活 1）。
5. D2-T5：`roguelike_shop.lua` Refresh 禁用；`run_shop_goods.lua` 加 `potion_heal_one_50` + `revive_scroll_50`；healPct 校正。
6. D2-T6：Web 层重写 `RunMapScene.ts` 为房间网格 + 楼梯按钮；改 `runControls.ts` 的 map / info 面板；改 `roguelike.ts` 类型；同步 `web_entry.lua` 序列化。
7. D2-T7：新增 bin 测试 3 个 + Playwright `roguelike-dungeon.spec.ts`；改 `roguelike-act1.spec.ts`。
8. D2-T8：`npm run export:lua`；跑 `web/tests`。

**D2 验收**：
- 5e 检定 4 档结果分布合理；零风险选项 100% 跳骰；
- 房间一次性触发：cleared 后仅作通路；shop 重复进入；
- 营地一键结算：全队 heal 100% + 清全队负面 + 复活 1；
- Web 房间网格视图可点击门进入相邻房间，stair 按钮上下楼。

### Stage D3 — Boss 层 + 章节 Trinket + 隐藏层（dungeon §7.3）

1. D3-T1：`config/data/trinkets.json` + `config/tables/trinkets.lua` + `run_trinket_config.lua`；3 章各 4~6 件。
2. D3-T2：`roguelike/trinket.lua` 实现入库 / 互斥 / 战斗效果接入。
3. D3-T3：`roguelike_reward.lua` 新增 `RollChapterTrinket`；删除 recruit 残留代码（L245-338）。
4. D3-T4：`roguelike_run.lua` Boss 胜利分支调用 trinket grant；章节奖励量级提升到 dungeon §4.7。
5. D3-T5：事件 `unlock_hidden_floor` 结果挂上 `dungeon_generator.GenerateHiddenFloor`；隐藏层 stair 注入当前层。
6. D3-T6：Web 层 trinket UI（types + runControls）；隐藏层视觉差异。
7. D3-T7：新增 bin 测试 2 个；Playwright e2e 通关 3 章。
8. D3-T8：`npm run export:lua`；全量回归。

**D3 验收**：
- 每章 Boss 必掉 1 件章节 trinket；章节奖励金币 / 装备 / 祝福符合 dungeon §4.7；
- 隐藏层入口存在并可触达；隐藏 Boss 双倍 trinket 奖励；
- Playwright 完整 3 章下钻通关。

### Stage D4（独立排期，可与 D3 并行）— 4 缺口职业 Feat 补齐

按 `roguelike_feat_skill_fill_sheet.md` + `character_progression_design.md` §7 阶段 7，与本计划无强耦合，单独立项。

---

## 6. 验证步骤 (Verification)

### 6.1 Lua 单测（bin）

```powershell
lua bin/test_roguelike_dungeon_generation.lua
lua bin/test_roguelike_room_one_shot.lua
lua bin/test_roguelike_camp_full_rest.lua
lua bin/test_roguelike_event_skill_check.lua
lua bin/test_roguelike_boss_trinket.lua
lua bin/test_roguelike_hidden_floor.lua
lua bin/test_roguelike_act1.lua
lua bin/test_roguelike_chapter_success.lua
lua bin/test_roguelike_balance.lua
lua bin/test_roguelike_progression_gate.lua
```

或用 [`tools/run_balance_checks.ps1`](../../tools/run_balance_checks.ps1) 一键。

### 6.2 Web 镜像

```powershell
npm run export:lua
```

### 6.3 Web Playwright

```powershell
cd web; npx playwright test roguelike-dungeon.spec.ts; npx playwright test roguelike-act1.spec.ts
```

### 6.4 验收口径（dungeon §8）

- 单层 ≥ 4 种房间类型；
- 平均每 Run 至少 1 次回到上一层（验证商店 / 营地的回头价值）；
- ≥ 60% 的 Run 能打到第 1 章 Boss（MVP 配置）；
- bin 至少 3 个回归脚本（地牢生成 / 房间一次性 / Boss 奖励）已落地；
- web/tests/ e2e 覆盖完整下钻流程。

### 6.5 D1.5 升级/平衡验收

```powershell
lua bin/test_roguelike_progression_pacing.lua
lua bin/test_roguelike_act1.lua --seed=10101
lua bin/test_roguelike_act1.lua --seed=10102
lua bin/test_roguelike_balance.lua --runs=20
```

通过条件：
- 任意单场战斗 `partyLevelDelta <= 1`；
- `run_battle_template.lua` 任意 `expReward <= 20`；
- 3 章完整通关样本最终 `partyLevel` 落在 Lv9~Lv10；
- Lv3 出现在 Act1 中段附近，Lv5 出现在 Act2 前半附近，Lv7/Lv9 分别落在 Act2 末 / Act3 中后段；
- seed=10102 不再在 floor=4 因等级断层必然 wipe。

### 6.6 风险检查（dungeon §9）

| 风险 | 自检 |
| --- | --- |
| 楼梯不连通 / 死房间 | `dungeon_generator.Validate` 强制连通 + 单测覆盖 |
| 玩家回头刷商店 | shop 库存固定不刷新；金币只来自战斗 |
| 营地房过强 | 单层 camp 权重 ≤ 5%，且一次性 |
| 事件房 RNG 灾难 | 每事件 ≥ 1 个零风险选项 |
| Boss 层难度跳点 | Boss 层 `pressureFactor × 1.3` |
| Web UI 复杂度 | 复用同一组房间组件，仅头部 / 边框颜色区分模式 |

---

## 7. 不在范围内 (Out of Scope)

- 地牢外的村镇 / 中转站 / 远征板 / 任务板（dungeon §10）。
- 撤退 / 疲劳系统。
- 元进度（账号成长 / 解锁 / 永久强化）。
- 跨 Run 永久死亡 / 遗志 / 怪癖。
- 4 缺口职业 Feat 补齐（Stage D4 独立排期）。

---

## 8. 备注

- 所有 Lua 改动后**必须**`npm run export:lua` 同步 [`web/public/lua/project/`](../../web/public/lua/project/)（[AGENTS.md](../../AGENTS.md)）；新增 Lua 源目录需在 [`tools/export_web_lua.mjs`](../../tools/export_web_lua.mjs) `sourceDirs` 中注册。
- `config/data/*.json` SSOT 与 `config/tables/*.lua` loader 的对应关系沿用 [`skills.json` ↔ `skill_meta.lua`](../../config/tables/skill_meta.lua) 模式。
- 复用 [`core/dice.lua`](../../core/dice.lua) + [`modules/ability_5e.lua`](../../modules/ability_5e.lua)，避免在 `event_resolver.lua` 重新实现 1d20 / 修正逻辑（AGENTS.md 5e Non-Negotiable）。
- 删除冗余层时（`run_node_pool.lua` / `run_recruit_pool.lua` / `roguelike_map_generator.lua`）使用 forwarder 兼容期 ≤ 1 个 PR，避免长期双跑。
