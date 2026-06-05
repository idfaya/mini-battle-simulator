# MiniBattle 随机地牢系统设计

> **文档状态**：Run 地图与房间规则的**权威文档**。程序实现与回归见 [`docs/implementation_guidelines.md`](../docs/implementation_guidelines.md) §5 与 [`docs/README.md`](../docs/README.md)。

> 配套 [`character_progression_design.md`](./character_progression_design.md)（养成）。

---

## 1. 设计目标

1. **分层地牢下钻**：单次 Run = 一座多层随机地牢，每层都有通向下一层 / 上一层的楼梯，玩家自下而上「贪 / 退」决策；
2. **迷宫房间制**：每层由若干房间组合而成（无走廊，房间之间直接相邻 / 用门相连），重复进入已探索房间不再触发事件，配合 5e DM 抛骰开图的桌面感；
3. **怪物随层数线性强化**，部分层为 Boss 层，给出大量经验与装备奖励，作为路线节点诱因；
4. **精英战 / Boss = 装备 + bless**，对应 DD1 的 trinket 文化；
5. **不做地牢外系统**：无村镇 / 中转站 / 远征板 / 元进度，所有非战斗交互（商店 / 营地 / 复活）以"房间事件"形式直接出现在地牢内；
6. **Run 失败口径**：一场战斗内全队同时倒下 → Run 直接失败，地牢与所有进度丢弃。

---

## 2. 核心循环（Run Loop）

```text
┌─ Run 开始（4 名固定起手英雄 + 起手装备）
│
└─→ 进入第 1 层（迷宫房间图）
        │
        ├── 房间：战斗 / 装备 / 营地 / 商店 / 事件 / 楼梯
        │     已探索房间 = cleared，再次进入不触发（商店除外）
        │
        ├── 楼梯房：进入下一层 / 回上一层
        │
        ├── Boss 层：清空 Boss 房 → 进入下一章入口
        │
        └── Run 结束条件：
              - 通关最深层（Run 胜利）
              - 一场战斗内 4 人全部倒地（Run 失败 → 全部清空）
```

- 跨 Run **不保留任何进度**：等级 / 装备 / bless / feat / 金币 / 阵亡名册全部清空。
- 起手英雄阵容固定 4 人，Run 内不增不减（仅可通过复活通道恢复阵亡角色）。

---

## 3. 层级地牢结构

### 3.1 层级布局

- 默认 3 章 × 5 层 = **15 层**地牢；每章末尾为 **Boss 层**。
- 每层独立生成（同一 Run 内布局已确定，回头进入旧层不重新生成）。
- 楼梯：
  - **下楼梯**：通往下一层；每层至少 1 个。
  - **上楼梯**：返回上一层；第 1 层无上楼梯。
- 玩家可自由上下穿行（用于补给 / 回头清房 / 触发隐藏事件）。
- 进入下一章 = 通过 Boss 层之后的楼梯，章节切换不可逆。

### 3.2 难度按章节配置固定

- 章节难度由固定配置决定，不随当前队伍血线、减员或实时状态变化。
- 怪物模板仍遵循 `CR 为真，Level 为显`：
  - `CR` 决定真实预算与强度
  - `Level` 在 `enemies.json` 中按 `exp_5e.MONSTER_DISPLAY_LEVEL_BY_CR` 配置，运行时直接读取，不随楼层或队伍状态变化
- 遭遇压强由 `run_battle_profile.budget` 给定，再在敌人生成阶段从候选波次中挑选最接近目标预算的编组。
- 章节推进通过更高 `CR` 的怪物组合、精英/Boss 配置与 `budget` 形成节奏，而不是运行时按楼层或玩家状态自适应抬难度。
- 第一章普通战按楼层绑定不同 `run_enemy_pick_pool`：`F1` 以 CR 1/8 为主、`F2` CR 1/4、`F3–F4` 引入 CR 1/2、`F5` Boss 战含 CR 1 护卫（见 `bin/test_roguelike_act1_floor_cr.lua`）。

### 3.3 隐藏层（可选）

- 每章可通过事件房**检定大成功**解锁 1 次隐藏层（非每层固定刷新）。
- 隐藏层 = 极小型地牢（**3~5 房间**），固定隐藏 Boss；击杀后发放**双倍章节 trinket**（第二件从同章池再 roll，去重）。
- **入口**：解锁后在**当前主线楼层、当前房间的一格相邻房**改写为 `stair_down`（标题「隐藏层入口」）；玩家须走到该格并 `StairUse` 下楼（不可隔空触发）。
- **楼层**：运行时 `HIDDEN_FLOOR_DEPTH = 9`（`dungeon_generator.lua`）；模板 `config/data/floors.json` `id=10901`（`isHidden: true`）。
- **返回**：隐藏层 `stair_up` 回到解锁时记录的主线 `hiddenReturnDepth` / `hiddenReturnRoomId`；隐藏 Boss **不**触发章节 `chapter_result`（与章末 Boss 区分）。
- **清除语义**：隐藏 Boss 胜利后必须写回 `hiddenFloorCleared[chapterId] = true`，无论结算经过直接胜利链还是 `reward` 链；否则主线入口会被误当成可重复推进目标。
- **入口生命周期**：已清的隐藏层入口仍可作为地图节点存在，但只承担回访通路语义，不再承担“优先下楼”或“再次进入隐藏层”的推进语义。
- **示例事件**：`config/data/events.json` `101099`「远古裂隙」— 选项「离开」为零风险；「解读裂隙符文」为调查 DC14，大成功 `unlock_hidden_floor`。
- **实现**：[`roguelike/roguelike_run.lua`](../roguelike/roguelike_run.lua) `injectHiddenFloor` / `EventChoose`；[`roguelike/floor_state.lua`](../roguelike/floor_state.lua) `UseStair`；回归 [`bin/test_roguelike_hidden_floor.lua`](../bin/test_roguelike_hidden_floor.lua)。

---

## 4. 单层地牢生成

### 4.1 房间迷宫图（无走廊）

```text
Floor = Maze(Room ⇄ Room)
     Room      = 主奖励 / 主决策（必停）
     Connection= 房间之间的门（无走廊）
```

- 用迷宫算法（Recursive Backtracker / Prim）生成，房间之间通过门直接相连。
- 玩家在房间内移动 → 选择一扇门 → 进入相邻房间。
- **不存在"走廊小冲突"概念**；所有事件都在房间内触发。

### 4.2 房间一次性触发

- 进入未探索房间 → 触发事件 → 房间状态置为 `cleared`。
- 再次进入 `cleared` 房间：仅作通路，不再触发事件 / 战斗。
- **实现**：[`roguelike/roguelike_run.lua`](../roguelike/roguelike_run.lua) `enterNode` 检测 `FloorState.IsRoomCleared`；`battle_normal` / `battle_elite` / `boss` / `event` 重入保持 `phase=map`，不二次开战/弹事件（回归 [`bin/test_roguelike_room_one_shot.lua`](../bin/test_roguelike_room_one_shot.lua)）。
- **程序口径**：[`docs/implementation_guidelines.md`](../docs/implementation_guidelines.md) §5.2。
- **唯一例外**：商店房保留库存，可重复进入购物（详见 §4.6）；shop 离开时不写 cleared。

### 4.3 房间类型与权重

| 房间类型 | 内容 | 普通层默认权重 |
| --- | --- | --- |
| 普通战房 | 标准战斗 | 35% |
| 精英战房 | 精英战，必掉装备 + 概率 bless | 10% |
| 宝箱房 | 开启宝箱，随机获得金币或装备 | 10% |
| 事件房（Event） | 文字事件 + 多选项决策（含 5e 检定 / 调查物件） | 20% |
| 营地房（Camp） | 全队回满 + 清状态 + 复活 1 名 | 每章固定第 3 层 1 个 |
| 商店房（Shop） | 金币兑换装备 / bless / 复活卷轴 | 5% |
| 楼梯房 | 上 / 下楼梯 | 固定（每层 ≥1） |
| 空房 | 风味 / 仅作通路 | 余量 |

- Boss 层只有 Boss 房 + 楼梯房 + 少量空房。
- 隐藏层使用独立模板。

### 4.4 事件房（Event Room）

- 进入事件房 → 弹出文字事件 + 2~4 个选项。
- 选定选项后先展示一次结果面板，再继续进入地图、奖励或战斗。
- 章节事件池 = 共享事件 + 本章专属事件；支持按楼层配置事件权重，同一章内同一事件最多出现 1 次。
- 普通层事件房数量受楼层模板约束，当前上限为每层 `1~2` 个；Boss 层与隐藏层不生成事件房。
- 选项可能：
  - 直接结算（拿金币 / 受小伤）；
  - 触发 5e 检定（调查 / 感知 / 神秘 / 宗教 / 运动），玩家选 1 名英雄出面，`1d20 + 修正 vs DC`：

| 结果 | 典型反馈 |
| --- | --- |
| 大成功 | 双倍奖励 / 解锁隐藏房间 / 解锁隐藏层入口 |
| 成功 | 给装备 / bless / 金币 |
| 失败 | 无事 / 触发陷阱 |
| 大失败 | 触发战斗 / 受负面祝福 |

- 每个事件至少有 1 种"零风险使用方式"（`zeroRisk` 选项 / 直接离开），让玩家可主动规避。
- 共享事件 `余烬圣坛` 额外提供一次性“献上灰烬唤回亡者”：支付金币，复活 1 名阵亡队友并恢复 `50%` 生命。
- **配置 SSOT**：`config/data/events.json` → [`config/tables/events.lua`](../config/tables/events.lua)；结算 [`roguelike/event_resolver.lua`](../roguelike/event_resolver.lua)（`1d20 + 5e 修正 vs DC`，nat20/nat1 四档）。
- **回归**：[`bin/test_roguelike_event_skill_check.lua`](../bin/test_roguelike_event_skill_check.lua)、[`bin/test_events_json_loader.lua`](../bin/test_events_json_loader.lua)。

### 4.5 营地房（Camp）

- 进入营地房直接结算：
  - 全队回满 HP；
  - 清除全队所有负面状态 / 负面祝福；
  - 复活 1 名阵亡角色（满血）。
- 无营火点数、无 4 选 1 选项。
- 营地房每章只出现 1 次，固定在第 `3` 层。
- 营地结算后房间置为 `cleared`，重复进入仅作通路。
- **实现**：[`roguelike/roguelike_camp.lua`](../roguelike/roguelike_camp.lua) `ApplyReviveFullRest`；进入营地房即结算并回 map。回归 [`bin/test_roguelike_camp_full_rest.lua`](../bin/test_roguelike_camp_full_rest.lua)。

### 4.6 商店房（Shop）

| 货品 | 价格 | 备注 |
| --- | --- | --- |
| 装备（small / medium） | 视档位 | 章节越深货品档位越高 |
| Bless | 视档位 | 含正面 / 解负面 |
| 治疗药水 | 中等金币 | 单角色回 50% HP |
| 复活卷轴 | 高额金币 | 复活 1 名阵亡角色（50% HP） |

- 商店是**唯一可重复交互**的房间类型；每次回访保留库存（不刷新）。
- 复活卷轴是 Run 内复活的稳定金币入口（详见 [`character_progression_design.md`](./character_progression_design.md) §4）。
- **货品配置**：[`config/roguelike/run_shop_goods.lua`](../config/roguelike/run_shop_goods.lua)（无独立 `shops.json`）；复活卷轴动态价（常规章 ×3 / 章末 ×4 普通装备价）。回归 [`bin/test_roguelike_shop_revive_scroll.lua`](../bin/test_roguelike_shop_revive_scroll.lua)。

### 4.7 Boss 房

- 章节末尾 Boss 层固定 1 个 Boss 房。
- 击杀 Boss：
  - **章节级经验大额奖励**；
  - **章节级金币大额奖励**；
  - **章节装备 ×1~2 件**；
  - **章节 trinket 必掉**（特殊装备，作为下一章诱因；**不进** `equipmentIds`，独立 `state.trinketIds`）；
  - **章节 bless ×1**。
- **实现**：[`roguelike/trinket.lua`](../roguelike/trinket.lua) `GrantChapterBoss`；效果 SSOT 为 `config/data/trinkets.json` 的 `effectType` + `params`，由 [`roguelike/trinket_effects.lua`](../roguelike/trinket_effects.lua) 解释（战斗 / 事件检定 / 战后加金回满 / 隐藏 Boss 第三件）。回归 [`bin/test_roguelike_boss_trinket.lua`](../bin/test_roguelike_boss_trinket.lua)、[`bin/test_roguelike_trinket_effects.lua`](../bin/test_roguelike_trinket_effects.lua)。

---

## 5. 节点奖励矩阵

| 房间类型 | 经验 | 金币 | 装备 | Bless | 天赋卡触发 | 备注 |
| --- | --- | --- | --- | --- | --- | --- |
| 普通战 | 标准 | 基础 | 否 | 否 | 跟随升级 | 主要靠等级驱动 build |
| 精英战 | 高 | 高（×1.5~2） | **必掉 1 件** | **概率掉 1 个** | 跟随升级 | 核心吸引力 |
| 宝箱房 | 否 | **随机** | **随机** | 否 | 否 | 开箱后展示结果，只掉 1 档奖励 |
| 事件房 | 视检定 / 选项 | 视检定 / 选项 | 视检定 / 选项 | 视检定 / 选项 | 否 | 文字决策 + 5e 检定 |
| 营地房 | 否 | 否 | 否 | 否 | 否 | 回满 + 清状态 + 复活 1 名 |
| 商店房 | 否 | 消耗 | 可购买 | 可购买 | 否 | 唯一可重复交互（含复活卷轴） |
| Boss 房 | **章节大额** | **章节大额** | **章节装备 ×1~2** | **章节 bless** | 跟随升级 | **章节 trinket 必掉** |
| 隐藏层 Boss | 双倍 | 双倍 | trinket | trinket bless | 跟随升级 | 隐藏奖励 |

**精英战的"质变收益包" = 装备 + bless + 高经验**，对应 StS 必掉遗物 + DD1 必掉 trinket。

---

## 6. 数据 / 模块影响矩阵

| 类别 | 文件 | 状态 | 说明 |
| --- | --- | --- | --- |
| 配置 | `config/data/floors.json` | ✅ | 每层模板 + `10901` 隐藏层 |
| 配置 | `config/data/events.json` | ✅ | 事件房剧本 + 5e 检定 DC |
| 配置 | `config/data/trinkets.json` | ✅ | 章节 trinket 池 |
| 配置 | `config/roguelike/run_shop_goods.lua` | ✅ | 商店货品（含复活卷轴动态价） |
| 配置 | `config/roguelike/run_trinket_config.lua` | ✅ | 按章 trinket 池与 roll |
| Run | `roguelike/dungeon_generator.lua` | ✅ | 多层迷宫 + `GenerateHiddenFloor` |
| Run | `roguelike/floor_state.lua` | ✅ | cleared / 楼梯（含 depth=9 隐藏层） |
| Run | `roguelike/event_resolver.lua` | ✅ | 5e 四档检定 |
| Run | `roguelike/trinket.lua` | ✅ | `state.trinketIds` 发放 |
| Run | `roguelike/roguelike_shop.lua` / `roguelike_camp.lua` | ✅ | 商店 / 营地 |
| Run | `roguelike/roguelike_run.lua` | ✅ | 主状态机、事件 `unlock_hidden_floor`、Boss trinket |
| Web | `web/app/render/RunMapScene.ts`、`ui/runControls.ts` | ✅ | 楼层网格、检定 UI、trinket / 隐藏层提示 |
| Web | `web/tests/roguelike-act1.spec.ts`、`roguelike-dungeon.spec.ts` | ✅ | 章节 smoke + 地牢切片 E2E |
| 文档 | `design/README.md` / `docs/README.md` | 活跃 | 策划 / 程序导航 |

---

## 7. 落地路线（地牢相关）

> 角色养成相关阶段（1~3 / 7）见 [`character_progression_design.md`](./character_progression_design.md) §7。

### 7.1 阶段 4：层级地牢生成 — ✅

- `dungeon_generator.lua`：3 章 × 5 层 + 楼梯；`bin/test_roguelike_dungeon_generation.lua`。

### 7.2 阶段 5：房间事件全套 — ✅

- `events.json` + `event_resolver.lua` + `roguelike_event.lua`；营地 / 商店；Web 楼层网格与检定 UI。
- 回归：`test_roguelike_event_skill_check`、`test_roguelike_camp_full_rest`、`test_roguelike_shop_revive_scroll`、`web/tests/roguelike-dungeon.spec.ts`。

### 7.3 阶段 6：Boss 层 + 章节 Trinket + 隐藏层 — ✅

- `trinkets.json` + `roguelike/trinket.lua`；章末 Boss 必掉 trinket；事件 `101099` 大成功 → 相邻房隐藏入口 → depth=9 双倍 trinket。
- 回归：`test_roguelike_boss_trinket`、`test_roguelike_hidden_floor`。

---

## 8. 验收口径

- **房间多样性**：单层地牢内出现 ≥ 4 种房间类型。
- **回头探索率**：玩家平均每 Run 至少 1 次回到上一层（验证商店 / 营地的回头价值）。
- **Boss 触达率**：MVP 配置下 ≥ 60% 的 Run 能打到第 1 章 Boss。
- **测试覆盖**（已满足）：
  - `bin/`：生成 / 一次性 / 检定 / 营地 / 商店 / Boss trinket / 隐藏层；**101 章 Boss 触达** `test_roguelike_ch101_reach.lua`（seeds 1..30，`ch101_reach` 推图 + `autoWinBattles` 验迷宫可达，战斗数值见真战脚本）；改平衡必跑真战见 [`docs/implementation_guidelines.md`](../docs/implementation_guidelines.md) §8.4。
  - `web/tests/`：`roguelike-act1.spec.ts`（章节 smoke）、`roguelike-dungeon.spec.ts`（地图 + 商店 + 检定 UI）。
  - 全三章固定种子自动 `chapter_result` 仍不稳定；`test_roguelike_chapter_success` 使用 `ForceBossChapterResultForTest` 验契约。

---

## 9. 风险与对策

| 风险 | 表现 | 对策 |
| --- | --- | --- |
| 迷宫生成 bug | 楼梯不连通 / 死房间 | 强制连通性校验 + 单测覆盖 |
| 玩家回头刷商店 | 经济失衡 | 商店库存固定不刷新；金币只来自战斗 |
| 营地房过强 | 玩家把营地房压底 | 每层营地房权重 ≤ 5%，且营地一次性 |
| 事件房 RNG 灾难 | 大失败连续触发 | 每个事件至少有 1 种「零风险使用方式」 |
| Boss 层难度跳点 | Boss 比层间难度断层 | 用 Boss 专属 profile budget + 波次 / 护卫结构控制，不再叠统一运行时倍率 |
| 隐藏层入口回环 | 已清隐藏层后仍反复被路由当成推进目标 | 隐藏层入口与出口按一次性推进节点处理；`hiddenFloorCleared` 必须在所有胜利结算链上回写 |
| Web UI 复杂度 | 房间 / 楼梯 / 商店 / 事件 4 套面板 | 复用同一组卡牌组件，仅头部 / 边框颜色区分模式 |

---

## 10. 暂不纳入的范畴

以下内容本期**不设计、不实现**：

- 地牢外的村镇 / 中转站 / 远征板 / 任务板。
- 撤退 / 疲劳系统（撤退即视为放弃 Run，进度清空）。
- 元进度（账号成长 / 解锁 / 永久强化）。
- 跨 Run 永久死亡 / 遗志 / 怪癖。

> 本期的 Run 失败处理：一场战斗内全队同时倒下 → Run 直接结束，地牢与所有进度丢弃，下次重新开始新 Run。

---

## 11. 一页结论

```text
循环
  Run = 多层随机地牢（无地牢外系统）
  每层 = 迷宫房间图（无走廊）
  楼梯连接上 / 下层，可双向通行
  房间事件一次性触发，cleared 后安全（商店除外）
  Boss 层位于章节末尾，必掉章节 trinket
  一场战斗内全队同时倒下 → Run 直接失败，进度清空

地牢内服务
  营地房：直接结算（回满 + 清状态 + 复活 1 名，一次性）
  商店房：可重复交互，含复活卷轴 / 装备 / bless
  事件房：5e 检定剧本，含调查 / 感知 / 神秘 / 宗教 / 运动

落地（地牢相关阶段）
  阶段 4：层级地牢生成（3 章 × 5 层 + 楼梯）
  阶段 5：房间事件全套（事件 / 商店 / 营地）
  阶段 6：Boss 层 + 章节 trinket + 隐藏层
```
