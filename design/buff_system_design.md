# Buff 系统设计文档

## 1. 文档范围

- 本文档从**技能 / Feat 落点**出发，定义 Buff 的策划语义；Buff 不是独立系统，而是技能链上的**状态载体**。
- 技能与 Feat 节点 SSOT：[`roguelike_feat_skill_fill_sheet.md`](./roguelike_feat_skill_fill_sheet.md) §2、§8。
- 上位规则：[`combat_system_design.md`](./combat_system_design.md)。
- 静态 ID 表：[`config/data/buffs.json`](../config/data/buffs.json)。
- 实现对照：[`docs/buff_shared_table.md`](../docs/buff_shared_table.md)。

**写作顺序**：先定技能何时挂什么 Buff → 再定该 Buff 的持续、叠层与回合结算 → 最后才改 `buffs.json` 与 Lua。

---

## 2. 技能如何挂 Buff

### 2.1 三条入口

| 入口 | 典型场景 | 落点 |
| --- | --- | --- |
| **Timeline 标签** | 主动技能伤害帧 `post` / `both` | `skills/skill_effect_registry.lua`：`apply_slow`、`sorcerer_burn_settlement` 等 |
| **被动 / 构筑钩子** | 普攻命中、回合开始、击杀 | `skills/*_build_passives.lua`、`modules/passive_handlers.lua` |
| **直接封装** | 复用叠层 / 刷新规则 | `skills/battle_skill_status.lua` → `BattleSkill.ApplyBuffFromSkill` |

技能读取 Buff 是否存在的入口集中在 `modules/battle_skill.lua` 的 `GetTargetConditionState`（`burning` / `slowed` / `frozen` / `hunterMarked`）及各类 `vs*` Feat mod。

### 2.2 同帧去重

法术类状态施加走 `ClaimSpellLikeStatusApplication`：**同一技能结算内**，对同一目标的同一 `buff:ID` 只处理一次（多段伤害不重复挂毒/燃烧）。

### 2.3 实例规则（技能侧观察）

- 同目标、同 `buffId` **仅保留一条** Buff 实例；再次施加 = **刷新 `duration`**，并**覆盖 `caster`**。
- **例外 — 猎人印记**：除 `890005` 外，游侠在目标 `runtime.rangerMarks[sourceId]` 维护**按来源**的到期表；联动技能用 `IsTargetMarkedBy(hero, target)` 判定，不用全局 `GetBuff`。
- 因此：燃烧 / 减速 / 静电印记在技能设计上按「**目标是否带该状态**」联动即可；**不假设**多施法者并行维持多条同 ID 实例。多人同职业时，后手刷新会改写 `caster`（归属随最后一次成功施加）。
- **禁用旧术语「来源隔离」**：策划统一表述为「同目标同 `buffId` 单实例 + 刷新覆盖 `caster`」；仅猎人印记另用 `runtime.rangerMarks` 做按来源判定。

### 2.4 策划状态符 ↔ Buff ID

Feat 填表与技能描述中的大写状态符，落点以 Buff ID 为准：

| 状态符 | Buff ID | 类型 | 备注 |
| --- | --- | --- | --- |
| `BURN` / 燃烧 | `870001` | DoT | 术士技能链 §3.1 |
| `SLOW` / 减速 | `880001` | 软减益 | **降先攻**；法师冰系铺垫；见 §4.2 |
| `FROZEN` / 冻结 | `880002` | 硬控 | `CONTROL`，跳过行动 |
| `STUN` / 眩晕 | `880003` | 硬控 | 武僧震慑拳、诡诈·眩晕 |
| `POISON` / 中毒 | `850001` | 层数 DoT | 诡诈涂毒、游侠感染 |
| `BLIND` / 盲目 | `880006` | 减益 | 诡诈·盲目；**命中 -2**（`value`） |
| `BLEED` / 流血 | `880007` | DoT | 诡诈打击体豁失败；§4.6 |
| `MARK`（游侠） | `890005` | 按来源减益 | 须 `IsTargetMarkedBy` |
| `MARK`（邪术师） | `890001` | 铺垫标记 | 雷暴引爆端 |
| `RAGE` / 狂暴 | `890002` | 强化态 | 野蛮人被动；次数限制在 runtime，非 `890003` |

> **`880005` 霜冻已废弃**，不再参与 Feat 单轨；法师冰系统一改挂 `880001` 减速。

---

## 3. 九职业技能 → Buff 映射

以下仅列**当前 Feat 单轨**中活跃的技能链；旧九流派毒爆流等见 `design/legacy/`，不参与本稿。

### 3.1 术士（母技能 `80007001` 火焰弹）

| 技能 ID | 名称 | 施加 Buff | 标签 / 钩子 | 技能侧联动 |
| --- | --- | --- | --- | --- |
| `80007001` | 火焰弹 | `870001` 燃烧 | `apply_burn_refresh_only`，2 回合 | 命中后点燃 |
| `80007002` | 余烬点燃 | `870002` 火焰亲和 | 被动 `OnSelfTurnBegin` 自检挂载 | 延长燃烧持续；火伤加成在被动 runtime |
| `80007003` | 灰烬爆燃 | `870001` | `sorcerer_burn_settlement` | 已燃烧 `+1d8` 并刷新；未燃烧则点燃 |
| `80007004` | 烈焰风暴 | `870001` | `sorcerer_burn_settlement`，3 回合 | 全体；已燃烧 `+1d8` 并延燃 |

**燃烧规则（由上述技能链导出）**：每回合开始敏捷豁免（对最近 `caster` 的 `spellDC`）；成功移除，失败 `1d4` 火伤并继续；不可叠层。

### 3.2 法师（母技能 `80008001` 寒霜射线）

| 技能 ID | 名称 | 施加 Buff | 标签 / 钩子 | 技能侧联动 |
| --- | --- | --- | --- | --- |
| `80008001` | 寒霜射线 | `880001` 减速 | `apply_slow`，2 回合 | 命中后铺减速 |
| `80008002` | 寒霜迟滞 | — | 被动：冰伤 / 冻结概率 runtime | `dotDurationDelta` 延长减速；施法临时生命等 |
| `80008003` | 冻结新星 | `880001` / `880002` | `wizard_freezing_nova` | 已减速 → `冻结` 1 回合；否则铺减速 |
| `80008004` | 暴风雪 | `880001` / `880002` | `wizard_blizzard_settlement` | 已减速 `+1d8` 并刷新减速；未减速只铺减速 |

**减速规则（冰系铺垫）**：`ON_ADD` / `ON_REMOVE` 调整战斗先攻（默认 `value=5`）；供 `vsFrost*`（实现仍读 `slowed`）加命中 / 加骰、新星转冻结、暴风雪兑现。重复施加只刷新持续，**不叠层**。

### 3.3 邪术师（母技能 `80009001` 邪能冲击）

| 技能 ID | 名称 | 施加 Buff | 标签 / 钩子 | 技能侧联动 |
| --- | --- | --- | --- | --- |
| `80009001` | 邪能冲击 | `890001` 静电印记 | `apply_static_mark`，2 回合 | 命中挂印记 |
| `80009003` | 雷链 | —（可延长印记） | 链式弹射；`extend_static_mark` | 命中已标记者追加雷伤；**不清印记** |
| `80009004` | 雷暴 | `890001` | `warlock_thunderstorm_settlement` | 已印记 `+1d8` 并**清除**；未印记则挂印记 |

印记兑现次数由 Feat `markRecastPerRound` / `markPayoutPerRound` 控制（见 feat 填表 §8.10）。

### 3.4 游侠（母技能远程基础攻击）

| 技能 / 被动 | 施加 Buff | 钩子 | 联动 |
| --- | --- | --- | --- |
| `80005001` 核心被动 猎人印记 | `890005` | 远程基础攻击**命中**后（伤害可为 0） | AC / 敏捷豁免各 `-value`；`IsTargetMarkedBy` |
| `80005002` 毒术精通 | `850001` 中毒 | 自身回合开始 `ProcessInfectEffect` | 已中毒目标层数 +1 |
| 二连射 / 箭雨 / 远程基础攻击等 | — | 读取印记 | `classMods.vsMarkBonusDice` 附加伤害 |

### 3.5 盗贼（母技能基础武器攻击）

| 技能 / Feat | 施加 Buff | 条件 | 用途 |
| --- | --- | --- | --- |
| `诡诈打击` + 涂毒 | `850001` 中毒 | 体豁失败 | 1 回合层数标记（兼 DoT 资源） |
| `诡诈打击` + 流血 | `880007` 流血 | 体豁失败 | 回合开始体豁 DoT；`偷袭放宽` 可读 |
| `诡诈·盲目` | `880006` 盲目 | 体豁失败 | 持续期间攻击命中 `-2` |
| `诡诈·眩晕` | `880003` 眩晕 | 感豁失败 | 硬控 |
| `偷袭放宽` | — | 读取 `850001` / `880007` / 印记 | 放宽偷袭条件 |

### 3.6 野蛮人（母技能 `狂斧劈砍`）

| 技能 / 被动 | 施加 Buff | 说明 |
| --- | --- | --- |
| `狂暴` 被动链（`R 狂暴基础`） | `890002` 狂暴 | 攻击 / 受击触发；默认每场 `1` 次；物伤 `-2`、伤害 `+2` 在被动侧 |
| `狂暴精通`（`T2` high_slot） | —（runtime） | 取消 `barbarianBerserkUsed` 每场一次限制；**不挂载** `890003` |
| `重击` | `890014` 重击破绽 | 自损；`subType=880004`，`value=2` → AC `-2` |

`890003` 不倦狂暴：历史预留 Buff ID；「不倦」语义由 Feat **`狂暴精通`** + `barbarian_build_passives` runtime 承载，**禁止**在新稿中把不倦等同于挂载 `890003`。

### 3.7 战士 / 圣骑 / 牧师 / 武僧（摘要）

| Buff | 技能 / 被动来源 |
| --- | --- |
| `820002` 反击姿态 / `820003` 盾墙 | 战士旧反击链 `passive_handlers`（非 Feat 主轴） |
| `890004` 护卫架势 | 战士护卫 `fighter_build_passives` |
| `890008` 守护灵光 / `890012` 神圣庇护 | 圣骑灵光链 |
| `890011` 神恩庇护 / `890006` 圣域祷言 | 牧师庇护 / 圣域 |
| `880003` 眩晕 | 武僧震慑拳 |
| `840001` 战意 | 战士被动叠层（伤害 / 治疗百分比） |

---

## 4. 核心 Buff 语义（§3 的归纳）

### 4.1 燃烧 `870001`

- **技能来源**：§3.1 术士火系 Timeline + `sorcerer_burn_settlement`。
- **5e 口径**：持续火焰伤害；每轮 **敏捷豁免** 对抗施法者 **法术 DC**；成功则状态结束，失败则 `1d4` 火焰伤害。
- **非 5e 简化**：豁免失败为全额伤害（非半伤）；不可叠层。

### 4.2 减速 `880001` 与冻结 `880002`

- **技能来源**：§3.2 法师冰系；游侠狩猎、`cleric` 驱散亡灵失败等亦可施加。
- **减速**：铺垫标记 + **先攻降低**（`value` 默认 `5`，`ON_ADD` 扣、`ON_REMOVE` 还）；重复施加刷新持续、不叠层；供 `vsFrost*` 与新星 / 暴风雪兑现。
- **冻结**：硬控 `CONTROL`，`ProcessTurnStartStatus` 跳过行动；偷袭等可读 `HasControlBuff`。

### 4.3 猎人印记 `890005`

- **技能来源**：§3.4；细则见 feat 填表 §8.4。
- **5e 口径**：等价于对 AC / 敏捷豁免的减益加值（`-N`）。
- **判定**：必须用 `IsTargetMarkedBy(施加者, 目标)`，不能只看 `GetBuff(890005)`。

### 4.4 静电印记 `890001`

- **技能来源**：§3.3。
- **规则**：冲击 / 雷链只追加伤害；**雷暴**为引爆端（额外伤害 + 清除）。

### 4.5 中毒 `850001`

- **技能来源**：盗贼诡诈涂毒、游侠感染加深；`apply_poison` 标签供扩展技能使用。
- **5e 口径**：层数 DoT；每回合开始 **体质豁免** 对抗施加者 **法术 DC**；成功则**整段中毒结束**（清空层数），失败则 `Xd4` 毒伤（`X=层数`）。
- **叠层**：仍可叠层加深失败时伤害；豁免成功一律移除整条中毒实例。
- **联动**：`poison_burst` 标签可引爆清空；圣疗精通等可净化。

### 4.6 流血 `880007`

- **技能来源**：§3.5 诡诈打击体豁失败。
- **规则**：每回合开始 **体质豁免** 对抗施加者法术 DC；成功移除，失败 `1d4` 物理伤害；不可叠层，重复施加只刷新持续。

### 4.7 盲目 `880006`

- **技能来源**：§3.5 诡诈·盲目。
- **规则**：携带者进行攻击检定时 **命中 -2**（`value`）；不参与 `HasControlBuff`。

---

## 5. 通用减益与控制（技能附带）

| Buff ID | 名称 | 典型技能来源 | 设计语义 |
| --- | --- | --- | --- |
| `880004` / `890014` | 破绽 / 重击破绽 | 重击自损等 | 共用 `subType=880004`；`GetDefenderAcBonus` 读取 `value` |
| `820001` | 挑衅 | 战士旧链 | 阵型嘲讽读取 |

---

## 6. 姿态 / 光环 / 资源类

收益**不在 Buff 配置内**，由技能 / 被动在命中、受击、回合钩子读取 Buff 存在或层数：

| 分类 | 代表 Buff | 读取方 |
| --- | --- | --- |
| 姿态 | `820002` 反击、`890004` 护卫 | `passive_handlers` / `fighter_build_passives` |
| 资源 | `840001` 战意 | `battle_skill` 伤害 / 治疗百分比 |
| 强化态 | `890002` 狂暴、`840002` 全军突击 | 野蛮人被动 / `battle_skill` |
| 团队防护 | `890011`–`890013` | `*_build_passives` 减伤 / AC / 豁免 |
| 被动态 | `870002` 火焰亲和 | 燃烧持续延长 |

---

## 7. 5e 风格对齐（技能链级别）

| 技能链 | 5e 对齐点 | 有意简化 |
| --- | --- | --- |
| 术士燃烧 | 敏捷豁免 vs 法术 DC；状态可结束 | 失败全额 `1d4`；无「持续火焰」半伤档 |
| 法师冰系 | 豁免法术 + 条件控制（冻结） | 减速用先攻表达，非完整 Restrained |
| 邪术师印记 | 印记后追加伤害 | 自定义引爆（雷暴） |
| 游侠印记 | AC / 豁免减益 | 槽位与 runtime 表为项目扩展 |
| 中毒 | 体质豁免 vs 法术 DC；层数 DoT | 成功整段移除；非 PHB Poisoned 状态名 |
| 流血 | 体质豁免结束 DoT | 固定 `1d4`、不叠层 |
| 盲目 | 攻击劣势近似 | 固定 `-2` 命中，非完整 Blinded 规则 |

---

## 8. 修改流程

1. 在 [`roguelike_feat_skill_fill_sheet.md`](./roguelike_feat_skill_fill_sheet.md) §8 或对应 `config/skill/skill_*.lua` 定**技能何时挂 Buff**。
2. 更新本文档 §3 / §4（技能 → Buff 映射与导出规则）。
3. 更新 `config/data/skills.json` 描述（以 Timeline 为准；`buffs` 数组字段可能与实际标签不一致，以 skill lua 为准）。
4. 更新 `config/data/buffs.json`。
5. 实现：`skill_effect_registry` / `battle_skill_status` / 职业 passive。
6. 同步 `docs/buff_shared_table.md`；补 `bin/test_buff_ticks.lua` 等回归。

---

## 9. 文档关系

```text
roguelike_feat_skill_fill_sheet.md §2/§8   ← 技能 / Feat SSOT
        ↓
buff_system_design.md（本文档）              ← 技能链 → Buff 语义
        ↓
config/data/buffs.json
docs/buff_shared_table.md
```

---

## 10. 一页结论

```text
Buff 由技能 Timeline 标签、被动钩子、battle_skill_status 封装挂载
同目标同 buffId 单实例；刷新覆盖 caster；猎人印记另用 runtime 表
术士：燃烧 — 敏捷豁免 DoT，技能 settlement 兑现
法师：减速铺垫（降先攻）+ 冻结硬控，暴风雪 / 新星条件结算
邪术师：印记 — 雷链追加、雷暴引爆
游侠：印记减 AC/豁免；毒术精通加深中毒
盗贼：诡诈多豁免分支；流血体豁 DoT；盲目降 hit
改 Buff 必先改技能落点，再改本文档与 buffs.json
```
