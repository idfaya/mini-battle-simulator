# MiniBattle 程序实现规范

> 本文档位于 **`docs/`**（程序开发文档）。策划规则见 [`design/README.md`](../design/README.md)。

## 1. 文档目的

- 本文档沉淀工程侧必须遵守的实现约束。
- 本文档不替代 `design/` 下的策划规则源：
  - `combat_system_design.md`
  - `class_system_design.md`
  - `roguelike_feat_skill_fill_sheet.md`
  - `auto_battle_targeting.md`
- 本文档只负责统一：
  - 能力建模约束
  - 职业实现边界
  - Roguelike 成长约束
  - Web 可观测性约束
  - 回归验证口径

## 2. 一页结论

- `Feat` 是唯一成长载体。
- `skill` 是唯一能力单元。
- 运行时只保留 `active` 与 `passive` 两类能力。
- 职业设计必须先定义母技能，再围绕母技能组织分支强化。
- `额外攻击` 与 `额外行动` 必须严格区分，禁止混写。
- 反击、护卫、拦截、报复类能力优先采用“先登记、后结算”。
- Web 表现必须和规则语义一一对应，不能只靠日志兜底。
- 文档、配置、运行时、Web、测试必须使用同一套语义。

## 3. 能力建模约束

### 3.1 Feat 是唯一成长来源

- 固定获得、三选一、阶段质变、Roguelike 战后成长，统一由 `Feat` 承载。
- `Feat` 不直接表达“加一点属性”或“升一级技能”，而是授予或修改 `skill`。
- 运行时不得再按 `classId` 反推职业应该拥有什么底盘能力。

### 3.2 skill 是唯一能力单元

- `skill` 不只表示按钮技能，而是角色持有的一个能力单元。
- 以下能力都统一视为 `skill`：
  - 主动技能
  - 自动触发被动
  - 反击
  - 额外攻击
  - 规则质变

### 3.3 设计层和运行时层的分类

- 设计层允许使用四类语义：
  - `active`
  - `passive`
  - `reaction`
  - `feature`
- 运行时只保留两类：
  - `active`
  - `passive`
- 映射规则如下：
  - `design.active -> runtime.active`
  - `design.passive -> runtime.passive`
  - `design.reaction -> runtime.passive`
  - `design.feature -> runtime.passive`

### 3.4 Feat 只保留三种核心操作

- `grant_skill`
- `modify_skill`
- `replace_skill`

以下旧式表达不再作为一等操作保留：

- `unlock_skill`
- `upgrade_skill`
- `unlock_feature`
- 独立的 `passive` effect

这些语义都应统一折叠进 `grant_skill / modify_skill / replace_skill`。

### 3.5 BuildState 是战前编译结果

- 角色进入战斗前，必须先由“职业成长状态 + 已选 Feat”编译出 `BuildState`。
- `BuildState` 至少应显式表达：
  - `activeSkills`
  - `passiveSkills`
  - `skillMods`
  - `replacedSkills`
  - `grantedTags`
- 战斗初始化应由 `BuildState` 驱动，而不是在运行时根据职业做隐式推断。

### 3.6 战斗属性 SSOT

战前战斗属性仅来自以下来源（不存在职业节奏模板表）：

| 来源 | 字段 |
| --- | --- |
| `Ability5e` + 英雄/怪物静态能力值模板 | HP、AC、命中、法术攻击/DC、豁免、六维及调整值 |
| `config/data/classes.json` → `weapon.weaponDice` | 物理武器骰 |
| `config/data/enemies.json`（敌人） | CR、基础 HP、AC bonus、能力值、静态 SkillIDs、role |
| `HeroBuild` / Feat `statMods`、Roguelike 祝福 | 命中、HP、`healingFlatBonus`、`damageReduce` 等 |
| `BattleAttribute` 活跃槽位 | HP、ATK（与 `hit` 镜像）、DMG_REDUCE、DMG_INCREASE |

**命中与伤害**：`core/battle_formula.lua` 提供 `RollD20` / `RollHit` / `RollSave` / `RollConcentration`；物理伤害为 d20+`hit` vs `ac`，重击为自然 20；伤害骰与属性调整由 `BattleSkill.ResolveScaledDamage` 结算。治疗固定加成走 `healingFlatBonus`；百分比治疗加成走 Buff / 职业节奏配置。

## 4. 职业实现边界

### 4.1 先定母技能

- 每个职业必须先定义一个清晰的母技能。
- 后续所有成长强化都应围绕这个母技能展开，而不是平铺堆多个并列主轴。
- 当前推荐口径：
  - 近战职业：近战基础武器攻击或徒手攻击
  - 远程职业：远程基础武器攻击
  - 法系职业：核心法术攻击或核心法术效果

### 4.2 额外攻击不是额外行动

- `额外攻击` 的标准语义是“同一次母技能行动中的第二击”。
- `额外攻击` 默认沿用同一目标。
- `额外攻击` 独立进行命中判定和伤害结算。
- `额外攻击` 不重新开启新的完整行动链。

### 4.3 新行动必须显式建模

- 若一个能力允许重新选择目标、重新触发整条攻击链或施法链，它就不是 `额外攻击`。
- 此类能力必须在文档与实现中显式建模为新的完整行动。
- 类似 `动作激增`、`战吼冲锋`、`迅捷施法` 这一类语义，应明确属于额外行动而不是追击。

### 4.4 反应技优先登记

- 反击、护卫、拦截、报复类能力，优先采用以下流程：
  - 条件满足时先登记
  - 当前敌方动作结束后再结算
- 该约束用于保证：
  - 未命中场景也能正确触发
  - 动画顺序稳定
  - 日志顺序可读
  - 多个反应冲突时更容易排序

### 4.5 守线职业必须同时具备防护与反打

- 守线 archetype 不能只做输出反制。
- 若一个职业被定义为前排守护线，必须同时提供：
  - 明确的团队防护收益
  - 明确的反打或惩罚收益
- 只提供弱化版 aura 或纯输出反击，不足以构成完整守线闭环。

## 5. Roguelike 成长约束

### 5.0 Run 模块索引

| 模块 | 路径 | 职责 |
| --- | --- | --- |
| 地牢生成 | `roguelike/dungeon_generator.lua` | Recursive Backtracker + BFS；隐藏层 `HIDDEN_FLOOR_DEPTH=9` |
| 楼层状态 | `roguelike/floor_state.lua` | `IsRoomCleared` / `MarkRoomCleared` / `UseStair` |
| Run 主循环 | `roguelike/roguelike_run.lua` | `dungeonState`、战斗/事件/shop/camp、`grantBattleExp`、隐藏层注入 |
| 地图视图 | `roguelike/roguelike_map.lua` | `buildNodeView`；cleared 房 neighbors 全作通路 |
| 楼层模板 | `config/data/floors.json` | `battlePoolIds`、`eventPoolIds`、constraints |
| 章节 | `config/roguelike/run_chapter_config.lua` | 101/102/103 `floorTemplateIds`、`targetMaxLevel` |
| 敌人生成 | `roguelike/roguelike_enemy_generator.lua` | 按 profile `budget` 从 pick pool 选编组 |
| 快照 | `roguelike/roguelike_snapshot.lua` | `dungeonState`、`currentFloorDepth`、`stairState` |

- 策划规则源：[`design/dungeon_design.md`](../design/dungeon_design.md)。
- `run_node_pool` / `run_recruit_pool` / `roguelike_map_generator` 已移除；勿再引用 lane DAG 或 recruit 链路。

- 战后成长统一发放职业树 `Feat`，不再并行维护第二套成长语义。
- Lv1 起始 feat 由 `ClassBuildProgression.GetLv1FeatIds(classId)` 自动授予（fixed），不进入升级候选。
- 升级候选池来自 `ClassBuildProgression.GetTreePool(classId)`，按 §5 树形规则（R/T1/T2/B/J/C）通过 `FeatPicker` 在每级筛出对应受限/自由层级的可选项。
- Lv3/Lv5/Lv10 的 T1/T2/Capstone 槽属于受限层级；其余层级为自由层（B/J）。所有候选必须满足 `prerequisites`（父节点已点过）。

### 5.1 队伍 EXP（5e SSOT，2026-05）

| 模块 | 路径 | 说明 |
| --- | --- | --- |
| PHB 阈值 / 怪物 CR XP | `config/roguelike/exp_5e.lua` | `partyExp` 升级阈值；`MONSTER_XP_BY_CR` |
| 胜利掉落 | `config/roguelike/battle_exp_reward.lua` | DMG 遭遇 XP × `PARTY_EXP_SCALE` × `chapterMultiplier` |
| 阈值转发 | `config/roguelike/level_curve.lua` | 转发 `exp_5e`，供 FeatPicker |
| 楼层难度分层 | `config/data/floors.json` → `run_battle_pool.lua` → `run_enemy_pick_pool.lua`；`encounter_level_curve.lua` 未接入运行时敌人生成 | 同章内随楼层换更高 CR 遭遇池 + `run_battle_profile.budget`；单怪强度不随楼层缩放 |
| 第一章压强 | `config/roguelike/run_battle_profile.lua` + `roguelike/roguelike_enemy_generator.lua` | 101 普通/精英/Boss 按固定 profile budget 在敌人生成阶段挑选最接近目标压强的编组 |
| Boss 触达回归 | `bin/test_roguelike_ch101_reach.lua` | `RoguelikeRunDriver` + `progressionMode=ch101_reach`；门禁测触达，战斗用 `TestForceCurrentBattleVictory` |
| 发放 | `roguelike/roguelike_run.lua` `grantBattleExp` | 只按当场敌人 `CR` 组合结算；**不读**模板 `expReward` |

- 第一章 `chapterMultiplier = 1.20`，让章末队伍节奏回到 Lv9-Lv10，避免平均角色等级过低。
- 改 EXP/节奏：优先动 `exp_5e.lua`、`battle_exp_reward.lua`、`run_battle_profile.lua` 与怪物池/波次组合，勿在 `run_battle_template.expReward` 手填。

### 5.2 房间一次性（dungeon §4.2）

- `leaveNodeBackToMap` 对非 shop 房写 `clearedRoomIds`。
- `enterNode` 对已 cleared 的 `battle_*` / `boss` / `event` 仅作通路（`phase=map`，不二次开战/弹事件）。
- 回归：`bin/test_roguelike_room_one_shot.lua`。

### 5.3 事件房 5e 检定（dungeon §4.4）

| 模块 | 路径 | 说明 |
| --- | --- | --- |
| 事件 SSOT | `config/data/events.json` | 选项 `skillCheck`（ability / dc / 四档 results）、`zeroRisk` |
| Loader | `config/tables/events.lua` | JSON → Lua |
| 检定 | `roguelike/event_resolver.lua` | `1d20` + `modules/ability_5e` 修正；nat20/nat1 覆盖 success/failure |
| 接入 | `roguelike/roguelike_event.lua` | `ResolveOption` → `resultType`（含 `unlock_hidden_floor`） |
| 回归 | `bin/test_roguelike_event_skill_check.lua`、`bin/test_events_json_loader.lua` | |

- 大成功 `unlock_hidden_floor`：[`roguelike_run.lua`](../roguelike/roguelike_run.lua) `EventChoose` → `injectHiddenFloor()`（见 §5.4）。
- 事件结果类型额外支持 `revive_one`；当前共享事件 `101002 余烬圣坛` 提供支付金币复活 `1` 名阵亡队友并恢复 `50%` 生命的分支。
- `floors.json` 的 `eventPoolIds` 支持 `eventId` 或 `{ id, weight }`；当前按章节拆池：共享事件低权、本章专属高权、`101099`「远古裂隙」低权稀有。
- 同一章地图生成期间，同一 `eventId` 只会出现一次；若事件池耗尽，后续房间不再强行塞重复事件。
- 单层事件数量受 `constraints.maxEvent` 控制；当前普通层按 `1,1,2,2` 限制事件房上限，Boss / 隐藏层不生成事件房。

### 5.4 章节 Trinket 与隐藏层（dungeon §3.3、§4.7）

| 模块 | 路径 | 说明 |
| --- | --- | --- |
| Trinket SSOT | `config/data/trinkets.json` | 按 `chapterId` 分池 |
| 发放 | `roguelike/trinket.lua` | `GrantChapterBoss(run, chapterId, isHidden)`；隐藏 Boss 双倍 roll |
| Run 状态 | `state.trinketIds` | **不**写入 `equipmentIds`；快照 `RoguelikeSnapshot` / Web `RunSnapshot.trinkets` |
| 隐藏层 | `dungeon_generator.HIDDEN_FLOOR_DEPTH`（9） | 模板 `floors.json` `10901`；主线**相邻房** `stair_down` + `payload.stairTarget=hidden` |
| 楼梯 | `roguelike/floor_state.lua` | 下楼进隐藏层；`stair_up` 回 `hiddenReturnDepth` / `hiddenReturnRoomId` |
| Boss 区分 | `isChapterClearBossNode` | 隐藏层 Boss 不进入 `chapter_result` |
| 效果解释 | `roguelike/trinket_effects.lua` | `effectType` + `params`（对齐 blessing 模式，非 Feat `effects[]`） |
| 战斗 | `team_save_delta` / `team_damage_resistance` | `ApplyBattleModifiers` → `heroData.resistances`（5e 伤害减半，非 flat 法术减伤） |
| 事件 | `event_skill_check_bonus` | `EventResolver.ResolveSkillCheck(..., trinketBonus)` |
| 战后 | `elite_victory_bonus_gold` / `boss_victory_full_heal` | `ApplyBattleVictory`（`ResolveBattle` 内） |
| 隐藏 | `hidden_boss_extra_trinket_roll` | `GrantChapterBoss(..., isHidden)` 第三件 roll |
| 回归 | `bin/test_roguelike_trinket_effects.lua` + boss/hidden 脚本 | 隐藏 Boss 战斗用 `TestForceCurrentBattleVictory`（bin only） |

- 隐藏 Boss 胜利后，`hiddenFloorCleared[chapterId]` 必须在所有胜利出口统一回写，包括直接战斗胜利和 `reward` 结算返回主地图两条链路。
- 运行时或测试路由在主线地图看到“已清的隐藏层入口”时，只能把它当作已访问通路，不能继续把它当成下楼或推进目标。
- 对 Act1 难度分析，`bin/test_real_combat_winrate.lua` 与 `bin/test_roguelike_real_combat_balance.lua` 出现 `unknown` 时，必须先修流程问题，再解读 wipe/clear 比例；`unknown=0` 是平衡结论可用的前置条件。

### 5.5 Run 运行时决策

| 决策 | 口径 |
| --- | --- |
| cleared 通路 | `battle_*` / `event` / `boss` 在 `enterNode` 短路为 map 通路；shop 可重复进入 |
| 邻居可达 | `GetAvailableNextNodeIds` 返回全部 neighbors（含 visited）；路由由 `chooseNextNode` 偏好未访问房 |
| Trinket 存储 | `state.trinketIds` 独立，**不**写入 `equipmentIds` |
| EXP 结算 | 5e SSOT：`exp_5e` + `battle_exp_reward` + `grantBattleExp`；**不读** `run_battle_template.expReward` |
| 楼层难度 | `floors.json` → 战斗池 → `run_enemy_pick_pool` 更高 CR 组合 + `run_battle_profile.budget`；单怪不随楼层缩放 Level/面板 |
| 隐藏层 | 事件大成功 → 主线相邻房 `stair_down`；Boss 胜利须写回 `hiddenFloorCleared`；已清入口仅作通路 |
| 复活卷轴定价 | 常规章 ×3 普通装底价、章末 ×4（`run_shop_goods`） |

## 6. Web 可观测性约束

### 6.1 表现必须对齐规则语义

- 同一行动第二击：
  - 表现为一次前冲中的二次碰撞，再回位
- 波及副目标：
  - 表现为单次动作中的双目标命中
- 命中修正：
  - 表现为短促特效或日志，不应伪装成完整位移
- 反应技：
  - 登记日志先出现，真正出手在敌方动作后出现

### 6.2 当前 Web 事件链路

- 可视化事件由 `ui/battle_visual_events.lua` 产出。
- Web 侧通过 `web/app/lua/eventBridge.ts` 归一化事件类型。
- 表现层根据事件语义在 `web/app/render/` 中消费并渲染。
- 新增技能、被动、反应或特殊伤害表现时，必须同时检查事件字段、日志顺序和动画语义是否一致。

### 6.3 验证要求

- 不能只验证“日志里有这句话”。
- 必须同时验证：
  - 触发时机是否正确
  - 表现节奏是否正确
  - 目标数和目标顺序是否正确
  - 是否错误伪装成新的完整行动

## 7. 文档编写约束

- Feat 和 skill 文案必须写离散规则，不写模糊描述。
- 每个关键能力至少要写清：
  - 何时触发
  - 作用于谁
  - 命中前还是命中后
  - 是否重选目标
  - 是同一行动第二击，还是新的完整行动
  - 是否需要每回合限次
- 避免使用以下模糊表达：
  - “强化连击”
  - “提升压制力”
  - “额外展开一轮攻势”
  - “增强保护能力”

## 8. 测试与回归口径

### 8.1 通用检查项

- 是否存在一个清晰的母技能
- 是否把 `额外攻击` 和 `额外行动` 写混
- 是否把守线能力误写成纯输出能力
- 是否有反应技但没有登记语义
- 是否缺少 Web 日志或 Web 表现
- Roguelike 是否会漏掉固定成长节点
- 文档、实现、测试三者是否一致

### 8.2 Web 验证模板

- 优先提供可直接复现的单战 URL 或脚本入口。
- 若一个职业支持按槽位注入不同 Build，必须同时提供公共配置与按英雄槽位配置两种验证方式。
- 对涉及反应技的用例，必须写清日志期望顺序。
- 对涉及额外攻击、横扫、副目标、命中修正的用例，必须写清表现期望而不是只写日志期望。

### 8.3 回归命令要求

- 新职业或新分支落地后，应至少保留一组 Lua 侧回归验证。
- 若存在 Web 表现差异，还应保留一组浏览器侧验证。
- 文档中的验证入口必须能被直接复制使用，不能只写“自行测试”。

### 8.4 数值 / 遭遇平衡：必须真战

改动怪物 CR/HP/技能、`run_enemy_pick_pool`、`run_battle_profile.budget` 或遭遇编组时，**必须**跑真战 bin，不能只靠静态对齐或 `test_roguelike_ch101_reach`（`autoWinBattles=true`，只验触达）。

最小门禁：

```bash
lua bin/test_roguelike_balance.lua --runs=4
lua bin/test_roguelike_real_combat_balance.lua
lua bin/test_real_combat_winrate.lua
```

配套静态（改池/CR 时同跑）：`test_enemy_cr_alignment.lua`、`test_roguelike_act1_floor_cr.lua`。

- `test_roguelike_progression_pacing.lua` 只验 EXP 节奏，**不跑战斗**，不能替代真战。
- 真战脚本出现 `unknown` / `Other Fail` 时，先修 Run 流程再解读 wipe/clear；`unknown=0` 是平衡结论可用前置（见 §5.1 旁注、`design/roguelike_monster_system_design.md` §9.7）。
- Playwright 不能替代真战统计；大改平衡时两者都要。

## 9. 关联文档

- 程序导航：[`docs/README.md`](./README.md)
- 策划导航：[`design/README.md`](../design/README.md)
- 策划规则源：`design/combat_system_design.md`、`design/class_system_design.md`、职业核心技稿、`design/dungeon_design.md`、`design/character_progression_design.md`
- 模块实现：`skill_system_implementation.md`、`buff_system_implementation.md`
