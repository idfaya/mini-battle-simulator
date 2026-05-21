# MiniBattle 角色成长与 Roguelike 融合优化设计

## 1. 文档范围

- 本文档面向当前 MiniBattle 中"等级 / 升阶 / Feat / Skill"成长链与 Roguelike Run 流程结合不紧密的问题，给出一份系统级优化设计。
- 上位规则源：
  - `roguelike_run_system_design.md`
  - `class_promotion_design.md`
  - `physical_class_core_skill_design.md`
  - `caster_class_core_skill_design.md`
  - `class_system_design.md`
- 本文档**不**直接修改既有规则源文档，仅定义优化目标、新增对象、新增流程，以及对既有字段的最小修订点。

---

## 2. 现状诊断

### 2.1 双轨成长冗余

- `level` 由战斗胜利自动结算，玩家不参与决策。
- `promotion_stage` 受重复职业卡 + 等级门槛双约束，玩家也只能"被动等待"。
- 结果：玩家既不真正"操控等级"，也常被门槛卡住"操控阶段"。

### 2.2 挂起进阶反馈延迟

- 重复职业卡先到、等级未达门槛 → 写入 `promotion_pending_target`，进阶被冻结到几场战斗之后。
- 玩家本应在"获得卡"瞬间获得多巴胺反馈，但反馈被推迟。

### 2.3 构筑选择稀薄

- 每个 `promotion_stage` 对应固定的 `mid_slot` / `high_slot` 能力包，玩家只有"要不要进阶"的决策。
- 同一职业的多次 Run 体验趋同，缺少"这次野蛮人是狂战流，上次是控场流"这种叙事。

### 2.4 节奏密度不均

- 只有精英 / Boss / 招募节点提供职业卡奖励。
- 普通战仅产出金币 + 经验，前期大量战斗"无成长反馈"，与 Slay the Spire / Hades 等流行 Roguelike 的"每场都有构筑选择"形成明显落差。

---

## 3. 设计目标

- 让**每一场战斗**都至少提供一次成长决策。
- 把**等级**与**进阶**解耦，避免重复卡冻结反馈。
- 引入**构筑分支**，使同一职业的多次 Run 形成不同 Build。
- 在**路线**与**节点**层面强化"流派引导"，让稳健 / 高压路线不仅影响节点比例，也影响构筑池倾向。
- 让**死亡**与**失败**也参与成长叙事，而不是单纯减员。

---

## 4. 参考流行游戏的核心机制

| 游戏 | 借鉴点 |
| --- | --- |
| Slay the Spire | 每战胜利后 3 选 1 / 跳过；任何节点都是构筑节点 |
| Hades | Boon 有专精方向，追求 Duo / Legendary 形成长线目标；不需要的资源可在 NPC 处兑换 |
| Monster Train | 单位升级 = 2 选 1 talent 树，单位本身参与构筑 |
| Darkest Dungeon | 升级解锁技能槽 + 随机怪癖；成长伴随取舍；死亡可遗留遗志 |
| Across the Obelisk | 升级时从 2–3 talent 选 1，与 5e Feat 文化天然契合 |
| D&D 5e 本身 | Subclass 在第 3 级岔路；Feat 与 ASI 在 4/8/12/16/19 级二选一 |

**共同规律**：每次升级都是一次*选择*；每次 Run 都形成*不同 Build*。

---

## 5. 新模型概览

```text
当前模型：
   Class Token (职业卡) = 加入阵容 + 阶段进阶 + 隐含能力包

新模型：
   Class Token  (职业卡)  → 仅管 "加入阵容 / 阶段进阶位置"
   Feat Card    (天赋卡)  → 每场战斗 N 选 1，承载 build 决策
   Stage Branch (阶段分支) → 进阶时 2~3 选 1 子流派
   Pending Voucher (挂起兑换券) → 重复卡先到时可立即兑换为其他资源
```

---

## 6. 天赋卡触发模型：等级驱动而非节点驱动

### 6.0 设计取舍

> 上一稿把档位绑定到节点类型（普通战 → small / 精英 → medium / Boss → awakening），玩家的"build 节奏"事实上被地图 RNG 决定，不可预期、不可规划。

**修订后的核心规则**：

```text
天赋卡的"是否触发"与"档位"
→ 完全由 "本场是否有单位升级" 与 "升到第几级" 决定
→ 节点类型只决定 "经验 / 金币 / 装备 / 职业卡" 等其它奖励
```

这样：

- 玩家盯着 EXP 条就能预判下一次 build 节点何时到来（与 D&D 5e 的 ASI/Feat 节点 4/8/12 级思路一致）。
- "我这把要补输出，先冲一张 medium 卡" 变成可规划目标。
- 节点选择回归到 *经济线（金币 / 装备 / 招募 / 营地）* 决策，与 *构筑线（feat 三选一）* 解耦。

### 6.1 等级 → 天赋卡档位映射

| 升到目标等级 | 触发档位 | 池来源（已就绪职业） |
| --- | --- | --- |
| Lv2 | `small` | `*_lv2_*` 既有三选一 |
| Lv3 | `mid_branch` | `*_lv3_*` 既有三选一（与 mid 阶段分支共用） |
| Lv4 | `medium` | `*_lv4_mastery` 既有三选一 |
| Lv5 | `awakening` | `*_lv5_capstone` 既有三选一（与 high 阶段分支共用） |

要点：

- **每次单位升级 = 一次 feat 三选一**，档位严格由 level 决定。
- Lv3 / Lv5 的三选一同时承担"阶段分支"职责（§8）：选了影袭处决就同时把 mid 分支定为"爆发流"。这样 *阶段分支* 与 *天赋卡* 在等级触发点上自然合一，不再需要额外的"分支卡面板"。
- 一场战斗可能同时触发多次三选一（多个单位同时升级），按行动顺序逐个结算。

### 6.2 节点奖励矩阵（修订后）

参考《杀戮尖塔》"普通战给卡 / 精英战必给遗物"的口径，但本作将"卡 = 等级触发的天赋卡"、"遗物 = 装备 + bless"。**职业卡（转职）是与精英战完全无关的独立通道**。

| 节点类型 | 经验 | 金币 | 装备 | Bless（祝福） | 职业卡 | 天赋卡 | 备注 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 普通战 | 标准 | 基础 | 低概率 | 否 | 否 | **跟随升级触发** | 主要靠等级驱动 build |
| 精英战 | 高 | 高 | **必掉 1 件** | **可能 1 个** | 否 | **跟随升级触发** | 核心吸引力 = 装备 + bless |
| Boss | 章节 | 章节 | 章节 | 章节 | 否 | **跟随升级触发** | 章节级装备 + bless |
| 招募 | 否 | 否 | 否 | 否 | **1 张** | 新单位起手 1 张 `small` | 转职 / 扩编**唯一稳定入口** |
| 商店 | 否 | 消耗 | 可购买 | 可购买 | 否 | 否 | 金币兑换装备 / bless |
| 事件 | 视配置 | 视配置 | 视配置 | 视配置 | **可能** | 视配置 | 极少数事件可掉职业卡 |
| 营地 | 否 | 否 | 否 | 否 | 否 | 否 | 恢复 / 复活 |

**职业卡（转职 / 进阶）独立化的关键原则**：

- 精英战 / Boss / 普通战**都不掉职业卡**。
- 职业卡的来源只有 *招募节点*（稳定）+ *少数指定事件*（点缀）。
- 这避免了"路线决定职业"的耦合：玩家不会因为选了高压路线就被迫多打精英拿转职卡，转职节奏与战斗节奏正交。
- 玩家想升阶 → 需要主动绕路去招募节点 / 触发对应事件，构成独立的"招募线"决策。

**精英战 vs 普通战的差异**（对标 StS 的"遗物诱因"）：

- 精英战**必掉 1 件装备**（对应 StS 必掉 1 件遗物）。
- 精英战**有概率掉 1 个 bless**（祝福，对应 StS 罕见/稀有卡概率上调）。
- 精英战金币区间 ≈ 1.5~2× 普通战，并提供更多经验。
- 普通战完全不掉装备 / bless，只给金币 + 经验。
- 这样精英战的"质变收益包" = **装备 + bless + 高经验**，足够诱使玩家承担 HP 风险。

要点：

- 节点类型不门控天赋卡档位；天赋卡仍由"升级"驱动，节点只调节经验产出。
- 精英战的高经验间接更易触发高档天赋卡，但**不是阶梯式门控**。
- 普通战仍可通过 1~2 场积累升级，触发 medium / awakening 档天赋卡。

### 6.3 升级节奏调节

为了让"等级驱动"的反馈密度仍然均匀：

- **EXP 曲线**：调整为"普通战 + 1~2 场即可让主力升一级"，保证大部分普通战都有升级反馈。
- **Run 内主力 EXP 上限**：单 Run 内 Lv5 是天花板（与 `promotion_stage = high` 配套），避免溢出。
- **多单位升级**：一场战斗多人升级时，依"上阵位 → 候补位"顺序逐个三选一；玩家可分别决策。
- **死亡单位的待发 EXP**：候补 / 死亡单位不获得 EXP，符合现行 §6.4 规则。

### 6.4 不允许跳过

- 天赋卡三选一**不可跳过**。候选池保证必有可用项（§7.3），强制玩家做出 build 决策。
- 升级触发的反馈不可被绕过；玩家也无法"攒卡稍后再选"。

---

## 7. 天赋卡（Feat Card）系统

### 7.1 字段定义

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | string | 天赋卡唯一编号 |
| `name` | string | 显示名称 |
| `tier` | enum | `small` / `medium` / `awakening` |
| `eligible_classes` | string[] | 可携带该卡的职业列表，留空表示全职业 |
| `required_stage` | enum? | 该卡是否要求 `low` / `mid` / `high` 才能拿，可空 |
| `tags` | string[] | `offense` / `defense` / `support` / `control` / `mobility` / ... |
| `effect_kind` | enum | `grant_skill` / `modify_skill` / `replace_skill` / `passive_buff` / `team_buff` |
| `effect_payload` | table | 具体效果数据 |
| `mutually_exclusive_group` | string? | 同组互斥，避免堆叠相同流派 |
| `summary_key` | string | 摘要文案键 |

### 7.2 强度分档

- `small`：单一被动微调或单段附加效果，普通战发放。
- `medium`：可观察的能力升级、协同触发，精英战发放。
- `awakening`：每章 1 次的高潮型构筑塑形，Boss 后发放。

### 7.3 候选池规则

- 三选一池由**当前职业 / 当前路线 / 当前已选标签**共同筛选。
- 必须满足：
  - 至少 1 张能立即影响"上阵单位"。
  - 不出现 3 张完全相同 `tags` 的"反常组合"（避免水池过窄）。
  - `mutually_exclusive_group` 已被选过的卡不再出现。

### 7.4 与现有 Feat / Skill 的关系

- 天赋卡是 Feat 的**Run 内载体**：本质仍走 `grant_skill` / `modify_skill` / `replace_skill`。
- 现有 `config/data/passives.json`、`skills.json`、`feats.lua` 中已有的"职业固定 Feat"按 §10 改造为阶段分支与天赋卡两类。
- Run 结束清空，不污染元进度。

---

## 7.5 既有 Feat 资源盘点（基于 `config/tables/feats.lua`）

> 目标：判断"既有 Feat 是否够用作天赋卡 / 阶段分支"。结论：**6 个职业已基本就绪，4 个职业严重不足，跨职业通用卡缺失**。

### 7.5.1 已就绪职业（已具备 lv2 / lv4 / lv5 三选一矩阵）

| 职业 | choiceGroup | 已有 Feat 数 | 用途映射 |
| --- | --- | --- | --- |
| 战士 | `fighter_lv3_active` | 2 | mid 分支（动作激增 / 护卫） |
| 战士 | `fighter_lv4_passive` | 2 | small 池 |
| 战士 | `fighter_lv5_capstone` | 2 | high 分支 |
| 武僧 | `monk_lv2_basic` | 3 | small 池 |
| 武僧 | `monk_lv3_subclass` | 3 | mid 分支 |
| 武僧 | `monk_lv4_mastery` | 3 | medium 池 |
| 武僧 | `monk_lv5_capstone` | 3 | high 分支 |
| 盗贼 | `rogue_lv2_basic` | 3 | small 池 |
| 盗贼 | `rogue_lv3_subclass` | 3 | mid 分支 |
| 盗贼 | `rogue_lv4_mastery` | 3 | medium 池 |
| 盗贼 | `rogue_lv5_capstone` | 3 | high 分支 |
| 游侠 | `ranger_lv2_basic` | 3 | small 池 |
| 游侠 | `ranger_lv3_subclass` | 3 | mid 分支 |
| 游侠 | `ranger_lv4_mastery` | 3 | medium 池 |
| 游侠 | `ranger_lv5_capstone` | 3 | high 分支 |
| 圣骑 | `paladin_lv2_prayer` | 3 | small 池（含核心被动） |
| 圣骑 | `paladin_lv3_oath` | 3 | mid 分支 |
| 圣骑 | `paladin_lv4_mastery` | 3 | medium 池 |
| 圣骑 | `paladin_lv5_capstone` | 3 | high 分支 |
| 牧师 | `cleric_lv2_prayer` | 3 | small 池（含核心被动） |
| 牧师 | `cleric_lv3_domain` | 2* | mid 分支（仅 2 项，建议补到 3） |
| 牧师 | `cleric_lv4_mastery` | 3 | medium 池 |
| 牧师 | `cleric_lv5_capstone` | 3 | high 分支 |

**结论**：6 职业（战士 / 武僧 / 盗贼 / 游侠 / 圣骑 / 牧师）只需轻微补全即可直接用作 *small / medium / awakening* 三档天赋卡的"职业专属池"。

### 7.5.2 严重不足职业（仅有训练 + 大招主线）

| 职业 | 现有 Feat | 缺口 |
| --- | --- | --- |
| 野蛮人 | `barbarian_training` / `barbarian_rage` / `barbarian_heavy_strike` / `barbarian_berserk` | 仅 4 项，**0 个 choiceGroup**。需要 lv2 small ×3、lv4 medium ×3、lv5 high 分支 ×2。 |
| 术士（火） | `sorcerer_training` / `ember_ignite` / `ash_burst` / `flame_storm` | 同野蛮人结构。需要 lv2 / lv4 / lv5 三组三选一。 |
| 法师（冰） | `wizard_training` / `frost_lag` / `freezing_nova` / `blizzard` | 同上。 |
| 邪术师（雷） | `warlock_training` / `static_mark` / `thunder_chain` / `thunderstorm` | 同上。 |

**结论**：野蛮人 + 三系法师**没有 Run 内构筑分化能力**，必须新增 Feat 才能进入天赋卡体系。这 4 职业是阶段 1 MVP 的最大阻塞点。

### 7.5.3 通用 / 跨职业天赋卡：完全缺失

现有 Feat 全部带 `classId`，**没有任何跨职业卡**。但天赋卡系统需要一批通用卡来填池：

- 普通战 small 池里至少要有"非职业绑定"的兜底卡，避免单职业枯水。
- 路线偏置（§10）需要按 `tags` 抽取，目前 Feat 没有 `tags` 字段。

**结论**：必须新增字段 `tags`、新增类别 `classId = 0`（通用）的 Feat，否则 §7.3 候选池保证（"至少 1 张能影响上阵单位"）无法稳定满足。

### 7.5.4 数量量化

| 类别 | 当前 Feat 数 | MVP 所需 | 缺口 |
| --- | --- | --- | --- |
| 战士 | 9 | 9 | 0 |
| 武僧 | 12 | 12 | 0 |
| 盗贼 | 12 | 12 | 0 |
| 游侠 | 12 | 12 | 0 |
| 圣骑 | 12 | 12 | 0 |
| 牧师 | 11 | 12 | 1（lv3 第三个 domain） |
| 野蛮人 | 4 | 12 | **8** |
| 术士 | 4 | 12 | **8** |
| 法师 | 4 | 12 | **8** |
| 邪术师 | 4 | 12 | **8** |
| 通用（classId=0） | 0 | 6~9 | **6~9** |
| **合计** | **84** | **123~126** | **39~42** |

> "MVP 所需"按照"每职业 lv2 小 ×3 + lv4 中 ×3 + lv5 高分支 ×2 + lv3 中分支 ×3 + 训练&核心 ×1"估算，约 12 项 / 职业。

### 7.5.5 字段补丁（已有 Feat 不够"做天赋卡"的最小修订）

现有 `BuildFeatDef` 缺以下字段，需要补：

| 字段 | 用途 | 默认值 |
| --- | --- | --- |
| `tier` | `small` / `medium` / `awakening` | 由 `level` 推断（lv2 → small，lv4 → medium，lv5 → awakening，lv3 用于 mid 分支） |
| `tags` | `offense` / `defense` / `support` / `control` / `mobility` / `economy` / `risk` | 必须人工补，不能默认 |
| `mutually_exclusive_group` | 替代 `choiceGroup` 的运行时阻断键 | 默认沿用 `choiceGroup` |
| `eligible_classes` | 多职业共用卡的白名单 | 默认 `{ classId }` |
| `required_stage` | mid / high 才能拿的卡 | 默认 `nil` |

**结论**：`feats.lua` 的 schema 需要做 1 次最小升级，补 `tier` / `tags` 两字段即可承载天赋卡。

---

## 7.6 既有 Feat 复用映射建议

### 7.6.1 阶段分支直接复用（零成本）

下列 `choiceGroup` 直接对应 §8.2 的 mid / high 分支，无需新写：

| 职业 | mid 分支映射 | high 分支映射 |
| --- | --- | --- |
| 战士 | `fighter_lv3_active`（动作激增 / 护卫） | `fighter_lv5_capstone`（横扫 / 续战） |
| 武僧 | `monk_lv3_subclass`（开放手 / 影行流 / 明镜止水） | `monk_lv5_capstone`（连拳 / 截脉 / 无垢） |
| 盗贼 | `rogue_lv3_subclass`（影袭 / 诡术 / 游斗） | `rogue_lv5_capstone`（直觉闪避 / 影舞者 / 生还者） |
| 游侠 | `ranger_lv3_subclass`（狩猎指引 / 暮影 / 缠绕箭） | `ranger_lv5_capstone`（箭雨 / 影袭宗师 / 缚林宗师） |
| 圣骑 | `paladin_lv3_oath`（圣手 / 破邪斩 / 古贤誓约） | `paladin_lv5_capstone`（裁决 / 慈光 / 圣域） |
| 牧师 | `cleric_lv3_domain`（生命 / 光明，需补守护域） | `cleric_lv5_capstone`（圣焰 / 慈恩 / 守望） |

### 7.6.2 small / medium 池直接复用

- `*_lv2_*` 三选一 → 普通战 *small* 卡池
- `*_lv4_mastery` 三选一 → 精英战 *medium* 卡池

> 这意味着即便不写一行新 Feat，6 个就绪职业的"普通战 + 精英战"天赋卡池都已经齐备，**MVP 可以立刻在这 6 职业上跑通**。

### 7.6.3 必须新增的 Feat 列表（按优先级）

**P0（阻塞 MVP）：**
- 野蛮人 / 术士 / 法师 / 邪术师 各补 lv2 small ×3 + lv4 medium ×3 = 6 张 / 职业 × 4 = **24 张**
- 牧师补 1 张守护域（`cleric_guardian_domain` 应进 lv3 三选一，目前是 lv5 单卡，需要拆分语义）

**P1（开放分支多样性）：**
- 野蛮人 / 术士 / 法师 / 邪术师 各补 lv5 capstone 分支 ×2 = 8 张

**P2（路线偏置 / 跨职业池）：**
- 通用 small 卡 6~9 张（治疗药水、临时 buff、AC 增益等，`classId = 0`）

**合计：32 张新 Feat（P0+P1）+ 6~9 张通用（P2）≈ 39~42 张**。

---

## 7.7 落地结论：MVP 不需要造 32 张新 Feat 才能开跑

可分两步走：

### 阶段 1A：6 就绪职业先 MVP

- 不补任何新 Feat，仅给 `BuildFeatDef` 补 `tier` / `tags` 字段。
- `feats.lua` 用 `level` 自动推断 `tier`；`tags` 人工补到 §7.5.1 涉及的 ~70 张 Feat 上（约 1~2 小时工作量）。
- Run 内只为 6 就绪职业开启天赋卡通道；4 缺口职业暂时维持原 promotion 体系不变。
- 立即获得"普通战即给天赋卡"的节奏感。

### 阶段 1B：4 缺口职业补齐

- 按 §7.5.3 P0 写 24 张 Feat。
- 跑 `bin/test_*_build_pipeline.lua` 全套回归。
- 4 职业进入天赋卡体系。

### 阶段 1C：通用池

- 按 §7.5.3 P2 写 6~9 张通用卡，开启路线偏置筛选。

---

## 8. 阶段分支（Stage Branch）

### 8.1 设计原则

- 把固定的 `mid_slot` / `high_slot` 改为 *2~3 选 1* 子流派。
- 每个分支对应一组 Feat（已存在或新增），以"流派标签"作为内部组织线索。
- 进阶决策点直接呈现 2~3 张"分支卡"，与天赋卡视觉一致但**不可跳过**（已经触发的进阶必须落地）。

### 8.2 分支命名建议（示例）

| 职业 | mid 分支 A | mid 分支 B | high 分支 A | high 分支 B |
| --- | --- | --- | --- | --- |
| 战士 | 护卫架势（守护） | 双手专精（爆发） | 不屈之风（坚韧） | 旋风斩（群体） |
| 武僧 | 震劲掌（控制） | 疾风步（机动） | 明镜止水（净化） | 千手观音（连击） |
| 盗贼 | 影袭处决（爆发） | 烟雾斗篷（隐遁） | 直觉闪避（生存） | 致命毒计（持续） |
| 游侠 | 狩猎指引（标记） | 钢爪兽伴（召唤） | 箭雨（AOE） | 必中之矢（精准） |
| 圣骑 | 破邪斩（输出） | 战誓领域（团辅） | 圣手（治疗） | 神罚降临（爆发） |
| 野蛮人 | 重击（爆发） | 嘲讽（控制） | 狂暴（持续） | 血怒（生存） |

> 法系职业按 `caster_class_core_skill_design.md` 同样原则补齐 2 套 mid + 2 套 high。

### 8.3 与 `promotion_stage` 的关系

- `promotion_stage` 仍为 `low / mid / high`（与现有数据兼容）。
- 进阶时新增 `stage_branch_id` 字段，决定该单位走哪条分支。
- 同一职业不同 Run 可走不同分支，构筑分化在此达成。

### 8.4 字段最小新增（Run 持有表）

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `mid_branch_id` | string? | mid 阶段所选分支，未进 mid 时为空 |
| `high_branch_id` | string? | high 阶段所选分支，未进 high 时为空 |
| `feat_card_ids` | string[] | 本 Run 已选的天赋卡列表 |

---

## 9. 等级与进阶的新分工

### 9.1 等级（level）

- **承担"feat 三选一"的触发器职责**：每次升级即触发一次按 §6.1 档位映射的天赋卡选择。
- 仍决定数值衍生（HP / 命中加值 / 豁免 / 法术 DC 系数）。
- 等级是**完全可预期**的成长线（盯着 EXP 条即可预测）。

### 9.2 进阶（promotion_stage）

- 仍由"职业卡"驱动，与等级解耦。
- 第 2 张同职业卡 → 立刻 `low → mid`，不再设等级门槛。
- 第 3 张同职业卡 → 立刻 `mid → high`。
- 进阶**不再触发天赋卡**（避免与升级三选一重复）；进阶的语义收敛为"获得阶段对应的属性 +N（§12.1 现有规则）+ 解锁该阶段允许的 Feat 等级范围"。

### 9.3 等级 ↔ 进阶的耦合点

- 阶段约束 feat 池的"等级上限"：例如 `low` 阶段只能在 Lv1 / Lv2 范围抽 feat；`mid` 阶段最高到 Lv4；`high` 阶段才解锁 Lv5 capstone。
- 这样：
  - 玩家拿到第 2 张职业卡 → `low → mid` → 该单位下一次升到 Lv3 时立即触发 mid 分支三选一。
  - 玩家始终知道"想吃 capstone 必须 Lv5 + high 阶段双满足"。
- 进阶 ≈ "解锁更高 feat 档"；等级 ≈ "兑现解锁的 feat 档"。两者职责清晰、各司其职。

### 9.4 重复卡溢出处理

- 已 `high` 阶段后再拿到同职业卡：转换为 1 张 `awakening` 档天赋卡（玩家立刻三选一）。
- 这取代了上一稿的"挂起兑换券"机制；规则更简单，反馈更直接。

---

## 10. 路线 × 构筑耦合

### 10.1 构筑标签

为天赋卡与阶段分支统一打 `tags`：

- `offense` / `defense` / `support` / `control` / `mobility` / `economy` / `risk`

### 10.2 路线偏置

- **稳健路线（safe）**：天赋池权重偏向 `defense` / `support` / `economy`。
- **高压路线（high_pressure）**：偏向 `offense` / `control` / `risk`。
- **Boss 路线（boss_path）**：偏向 `awakening` 档高强度卡。

### 10.3 玩家叙事

玩家在分支处选路线时，等同于先决定"本 Run 走什么流派"，路线选择即 Build 路径选择。

---

## 11. 死亡与失败的成长化

### 11.1 死亡单位的处理

- 营地节点：消耗 1 张职业卡复活 1 名死亡单位（保持机会成本）。
- 死亡单位的"遗志"：未复活的死亡单位每存在 1 个，全队获得 1 层"遗志"被动（小幅伤害提升或暴击率），Run 内可叠加。
- 参考 Darkest Dungeon 的死亡 -> 团队压力转化。

### 11.2 Run 失败时的反馈

- 即便 Run 失败，最后一场战斗胜利后已选的 Build 会进入"Run 摘要"，便于玩家复盘。
- 不引入元进度（保持 Roguelike 纯净度），但摘要可作为"上次 Run 的故事"。

---

## 12. 数据 / 模块影响矩阵

| 类别 | 文件 | 修改 | 说明 |
| --- | --- | --- | --- |
| 配置（新增） | `config/data/feat_cards.json` | 新增 | 天赋卡静态数据，每行一个对象 |
| 配置（新增） | `config/roguelike/run_feat_pool.lua` | 新增 | Run 内三档抽卡池 |
| 配置（新增） | `config/data/stage_branches.json` | 新增 | 阶段分支静态定义 |
| 配置（修改） | `config/data/passives.json` | 修改 | 部分阶段固定 Feat 改造为分支或天赋卡 |
| 配置（修改） | `config/tables/feats.lua` | 修改 | 暴露分支与天赋卡的运行时 API |
| Run 层 | `roguelike/roguelike_battle_resolver.lua` | 修改 | 战斗胜利后挂入天赋卡三选一 |
| Run 层 | `roguelike/roguelike_run.lua` | 修改 | Run 持有表新增 `mid_branch_id` / `high_branch_id` / `feat_card_ids` |
| Run 层 | `roguelike/roguelike_reward.lua` | 修改 | 跳过卡换金币 / 装备碎片的兑换逻辑 |
| Run 层（新增） | `roguelike/roguelike_feat_picker.lua` | 新增 | 天赋卡候选池筛选与三选一会话 |
| 战斗层 | `modules/hero_build.lua` | 修改 | 解析 `feat_card_ids` 与 `*_branch_id`，落到运行时被动 |
| 战斗层 | `modules/battle_passive_skill.lua` | 修改 | 兼容由天赋卡注入的被动 |
| Web | `web/app/lua/LuaBattleHost.ts` | 修改 | 暴露天赋卡选择事件 |
| Web | `web/app/ui/runControls.ts` | 修改 | 新增天赋卡三选一 UI |
| Web | `web/tests/*.spec.ts` | 修改 | 新增天赋卡选择回归用例 |
| 文档 | `class_promotion_design.md` | 修改 | §5.4 加入"挂起进阶兑换" |
| 文档 | `roguelike_run_system_design.md` | 修改 | §6.1 战斗胜利结算顺序加入天赋卡 |
| 文档 | `physical_class_core_skill_design.md` | 修改 | §三阶子职业结构加入分支 |

---

## 13. 战斗胜利结算的新顺序

```text
战斗胜利
→ 发放节点金币
→ 结算节点掉落
→ 发放战斗经验并自动升级
→ 固定恢复
→ 兑现 promotion_pending_target（若达成）
→ 若节点带职业卡奖励：进入职业卡三选一
   → 若进阶为 mid/high：插入阶段分支选择（不可跳过）
→ 若节点带天赋卡奖励：进入天赋卡三选一（可跳过）
→ 返回地图
```

---

## 14. 落地路线（建议顺序）

### 14.1 阶段 1：最小可行验证（MVP）

- 仅新增"天赋卡三选一 + 跳过"通道。
- 不动 `promotion_stage`、不动既有职业 Feat。
- 目标：验证"每场战斗都有构筑选择"对节奏密度的影响。
- 改动面：`feat_cards.json` + `run_feat_pool.lua` + `roguelike_battle_resolver.lua` + Web UI + Playwright 用例。
- 回归：`bin/test_roguelike_act1.lua` + Web smoke。

### 14.2 阶段 2：阶段分支（Stage Branch）

- 把至少 1 个物理职业（建议**战士**）的 mid + high 改造为分支二选一。
- 同步 `physical_class_core_skill_design.md` 与 `feats.lua`。
- 回归：`bin/test_fighter_build_pipeline.lua` + Web Fighter smoke。

### 14.3 阶段 3：挂起兑换券

- 在职业卡结算流程中，挂起进阶时弹出 *3 选 1* 兑换面板。
- 回归：`bin/test_roguelike_progression_gate.lua`（必要时新增分支用例）。

### 14.4 阶段 4：路线偏置 + 死亡遗志

- 在天赋池筛选中加入路线权重。
- 加入死亡单位"遗志"被动叠加。
- 回归：`bin/test_roguelike_balance.lua` + 新增遗志单元测试。

### 14.5 阶段 5：全职业分支铺开

- 按 §8.2 表逐职业落地，每职业一组 mid/high 分支。
- 同步设计文档与 web 测试。

---

## 15. 验收口径

- **节奏密度**：从普通战开始，每场战斗结束 1 秒内出现至少一次玩家决策（天赋卡三选一）。
- **构筑分化**：同职业不同 Run 的"已选 Feat 列表"重合度 ≤ 40%（自动统计）。
- **挂起反馈**：重复卡到达时玩家始终能选择立即奖励，不再出现"什么也没有，只能等下一关"的体验。
- **测试覆盖**：
  - `bin/` 下新增至少 2 个回归脚本，覆盖天赋卡抽取与分支选择。
  - `web/tests/` 下新增 1 个 e2e 用例覆盖 Run 全程的卡牌选择。

---

## 16. 风险与对策

| 风险 | 表现 | 对策 |
| --- | --- | --- |
| 池子过浅 | 早期天赋卡只有十几张，3 选 1 重复率高 | 阶段 1 不强求覆盖度，先按"普通战只用 small 池"小步快跑 |
| 单位 Build 过强 | 天赋卡叠加导致数值溢出 | 引入 `mutually_exclusive_group` 与每个 Run 的 cap（如同标签最多 3 张） |
| 分支文案膨胀 | mid/high 分支需要 2~3 套描述 | 分支与天赋卡共用同一份摘要键体系，避免重复维护 |
| Web UI 复杂度 | 三选一面板 + 分支面板 + 兑换面板叠加 | 复用同一组卡牌组件，仅以 `tier` / `mode` 区分头部样式 |
| 数值平衡难度 | 普通战即给 build 后期会脱缰 | 阶段 1 先压低 small 卡数值，配合 budget.pressureFactor 调整节点强度 |

---

## 17. 一页结论

```text
现状
→ 等级与进阶双轨冗余
→ 重复卡反馈被冻结
→ 同职业不同 Run 体验雷同
→ 普通战缺成长反馈

优化（最终版）
→ 拆分职业卡 / 天赋卡两类对象
→ 天赋卡触发 = "单位升级"，档位 = "目标等级"
→ 节点类型只决定经验产出，不再门控档位
→ Lv3 / Lv5 升级三选一同时承担 mid / high 分支
→ 进阶 = 解锁更高 feat 档；等级 = 兑现 feat 档
→ 已 high 后的重复卡 → 直接换 awakening 三选一

落地
→ 1A：6 就绪职业 + 等级触发 + 既有 choiceGroup 池
→ 1B：补 4 缺口职业 24 张 Feat
→ 1C：补通用池 + 路线偏置
→ 2：阶段 ↔ 等级解锁约束
→ 3：死亡遗志 / Run 摘要
```
