# 5e 全量重做方案 v3（12 职业 / 12 英雄 / 数值+技能重设计）

本文件用于“先设计后落地”。你确认后我再改配置与脚本，并保证：
- `lua55 bin/test_roguelike_act1.lua` 通过
- `lua55 bin/test_roguelike_balance.lua --runs=1 --route=safe --seed=101` 通过
- `lua55 bin/test_browser_battle_runtime.lua` 通过

## 0. 总约束（你已确认）

- 12 个 5e 基础职业做满（新增 3 个英雄）。
- 大招仍可手动释放，但**不再有能量门槛**；大招受 `CD + 次数（篝火/营地长休恢复）` 约束。
- 优先复用现有技能脚本体系（`SkillTimelineCompiler` + `tags`），必要时最小新增脚本与 tag。
- 验收先以现有测试“全绿”为准。
- 进一步贴近 5e：技能按“命中/豁免、专注、吟唱、条件”来设计；但不引入完整法术位/动作经济系统（资源仍简化）。

## 1. 职业 ID / 英雄 ID / 技能 ID 规划

### 1.1 职业 ID（classId）

为减少改动面，先沿用既有 `classId` 风格并扩展到 12：

- 1 Rogue
- 2 Fighter
- 3 Monk
- 4 Paladin
- 5 Ranger
- 6 Cleric
- 7 Sorcerer
- 8 Wizard
- 9 Warlock
- 10 Bard（新增）
- 11 Druid（新增）
- 12 Barbarian（新增）

> 说明：现有 UI/逻辑大量依赖 `classId`，先扩展不替换旧值。

### 1.2 英雄 ID（AllyID）

保留原 9 个英雄（900001~900009）并新增 3 个（建议）：

- 900010 Bard
- 900011 Druid
- 900012 Barbarian

### 1.3 技能 ID / ClassID 规则

延续现有结构：

- 每职业一个 `ClassID`（7 位）：`8000CC00`（示意）
- 每职业 4 技能：`ID = ClassID * 10 + SkillLevel`
- 技能类型（res_skill.json: `Type`）：
  - 1 常驻
  - 2 CD 主动
  - 3 大招（次数制/篝火长休恢复）
  - 4 被动

新增 3 职业的 `ClassID` 建议：
- Bard: `8001000` -> skills `80010001..04`
- Druid: `8001100` -> skills `80011001..04`
- Barbarian: `8001200` -> skills `80012001..04`

## 2. 数值基线（v3 口径）

### 2.1 CD 与次数

每职业固定 4 技能位：

- L1 常驻：`Type=1`，`CoolDownR=0`
- L2 被动：`Type=4`
- L3 主动：`Type=2`，`CoolDownR=2~3`
- L4 大招：`Type=3`，`CoolDownR=5`，`ultimateChargesMax=1`（篝火/营地恢复；战后不恢复）

### 2.2 伤害/治疗的表达

本项目当前战斗核心仍以：
- `damageRate`（万分比）+ 统一伤害解算（命中/豁免/暴击）
为主。

因此 v3 先用：
- res_skill.json 的 `SkillParam[1]` 作为主要倍率（与现状一致）
- timeline `damageRate`（如 `13000`）作为技能输出主旋钮
- 治疗先沿用现有“治疗骰”机制（`BattleSkill.CalculateHealDice`）

### 2.3 更贴近 5e 的规则映射（本版新增）

当前引擎已经具备以下 5e 关键件（可以直接用/小改）：
- 豁免：`SkillTimelineCompiler` 的 `op=damage` 在 `meta.kind="spell"` 时会走 `RollSave`（基于 `spellDC` 和 `saveFort/saveRef/saveWill`）。
- 施法命中：`BattleFormula.RollHit` 支持命中检定，且 `meta.kind ~= "spell"` 会走命中判定。
- 吟唱=施法时间：`config/skill_5e_meta.lua` 的 `chantTurns` 通过 `__pendingCast` 落地，并应在施法者下次行动开始时自动释放。
- 专注：已有 `__concentrationSkillId` + 受伤触发 `RollConcentration` 打断。
- 控制：`Frozen/STUN/SILENT` 等 `CONTROL` 类 Buff 已接入“跳过行动”。

为“更像 5e”，v3 的重点是“技能行为像 5e”（改动小但收益大）：
- 统一“法术攻击 vs 豁免法术”口径：在 `skill_5e_meta.lua` 中用 `kind` 表达。
  - `kind="spell"`：豁免类法术（Fireball / Frost Nova / Hypnotic Pattern 等）。
  - `kind="auto"`：法术攻击类（Fire Bolt / Eldritch Blast / Ray of Frost 等，走命中检定但不拼接武器骰）。

> 说明：不引入“法术位/短休资源”全套系统；资源仍以 `CD + 大招次数（篝火/营地长休恢复）` 落地。

### 2.4 肉鸽短休/长休映射（本版确认）

- 战斗后自动短休：
  - 清除“小招 CD”（Type=2 的 CD 清零）。
  - 清除控制状态（Frozen/STUN/SILENT 等，不跨战斗）。
  - 不回血。
  - 不清大招 CD（Type=3 的 CD 保留跨战斗）。
  - 不恢复大招次数。
- 篝火/营地 = 长休：
  - 清除一切 CD（含大招）。
  - 恢复大招次数至上限。
  - 清除一切控制状态。
  - 血量恢复：当前血量 + 50% 最大血量（不超过满血）。

## 3. 12 职业技能包（v3 设计：按 5e 规则写清楚）

说明：
- “复用脚本”指优先复用现有 tag/Timeline 结构；若没有现成技能，则新建 `config/skill/skill_<id>.lua` 但仍按同一编译器写。
- 每个技能在 v3 都明确：`攻击检定/豁免`、`saveType`、`是否专注`、`是否吟唱`、`是否控制`。
- 具体 `damageDice/healDice/turns/stacks` 在落地时给出精确值并用测试回归校准（v3 文档先给“建议起点”）。

### 3.0 通用机制（v3 新增）

本章每个职业只列出 4 个技能（L1~L4）；职业特性不额外列槽位，而是在对应技能条目上标注“职业特性”。

#### A) 法术攻击 vs 豁免法术
- 法术攻击（如 Fire Bolt / Eldritch Blast / Ray of Frost）：走 `RollHit` 对 AC，使用 `kind="auto"`（不拼接武器骰）。
- 豁免法术（如 Fireball / Hypnotic Pattern / Entangle）：走 `RollSave` 对 `spellDC`，使用 `kind="spell"` + 指定 `saveType`，默认“成功半伤”。

#### B) 职业差异来源
v3 暂不引入优势/劣势（你已要求先不要）。职业差异优先用：
- 资源恢复（战后短休 / 篝火长休）
- 被动触发窗口（每回合/每战斗 N 次）
- 专注/吟唱/控制

#### C) 条件（轻量实现）
v3 只实现技能需要的最小集合，并都落成 Buff：
- `STUN`：跳过行动（现有控制体系已支持）。
- `Frightened`（恐惧，v3 近似）：命中（hit）降低 + 受到的伤害略提高（更易被击杀）。
- `Restrained`（束缚，v3 近似）：速度降低 + AC 降低（更容易被命中）。

#### D) 专注
v3 将“专注清理 buff”从硬编码改为可配置：专注技能在 meta 中声明需要维持/清理的 buffId 列表。

### 3.1 Rogue（现 Assassin 组）

- L1 Sneak Attack（职业特性）：单体物理命中；若目标被控制（Frozen/STUN/SILENT）或“夹击成立”（目标前排且我方前排存活单位>=2，含盗贼），则追加一次偷袭伤害（每回合最多 1 次）。
- L2 Flanking（职业特性，被动）：夹击判定器（用于解锁偷袭触发），不单独出手。
- L3 Cunning Strike：CD2 单体爆发/斩杀。
- L4 Blade Flurry：大招，AOE 清场（次数制；篝火/营地恢复）。

### 3.2 Fighter（现 Tank 组）

- L1 Shield Bash：单体+嘲讽。
- L2 Fighting Style（职业特性，被动）：格挡/反击（防御风格）。
- L3 顺劈斩：CD3，对前排相邻/一排目标造成物理伤害，体现战士的稳定清线能力；战后短休自动清 CD。
- L4 旋风斩（职业特性，大招）：对周围/全前排敌人进行一次大范围物理打击；次数制；篝火/营地恢复。

### 3.3 Monk（现 ComboWarrior 组）

- L1 Unarmed Strike：常驻近战输出。
- L2 Martial Arts（职业特性，被动）：每回合第一次命中后追加 1 次小额打击（连击风味）。
- L3 调息自愈：CD3，自身回复生命并清除部分负面状态，体现武僧气息调理；战后短休自动清 CD。
- L4 渗透劲（大招，职业特性）：以 force 伤害贯穿目标、无视前排保护；并附带强韧豁免，失败则 `STUN` 1 回合；次数制；篝火/营地恢复。

### 3.4 Paladin（现 BattleRage/战意组）

- L1 Warhammer Strike：常驻。
- L2 破邪斩（Divine Smite，职业特性）：单体武器命中后追加光辉伤害；并驱散目标身上 1 个 GOOD Buff（破邪近似）。
- L3 Blessed Charge：CD3 团队攻击增益（专注）。
- L4 Lay on Hands（职业特性，大招）：强力治疗/救急技能；次数制；篝火/营地恢复。

### 3.5 Ranger（现 Poison* 近战组）

定位：标准 5e 游侠（标记增伤 + 束缚箭/多重射击）。

- L1 Longbow Shot（常驻）：物理命中，对单体敌人造成武器伤害（偏远程/后排位）。
- L2 Hunter's Mark（职业特性，被动）：命中目标后施加“猎人印记”2 回合；攻击被标记者时，每回合第一次追加 1d6。
- L3 Ensnaring Strike（主动，CD3，专注）：对单体进行一次攻击；命中后目标进行 `saveType=ref`，失败获得 `Restrained`（v3 近似：AC-、Speed-）1~2 回合。
- L4 Volley / Conjure Barrage（大招）：对一排/全体敌人造成一次伤害（不做纯毒爆）。

### 3.6 Cleric（现 Healer 组）

- L1 Mace Strike：近战普攻，对单体敌人造成物理/神圣混合伤害，体现牧师也能近战参与。
- L2 Channel Divinity（职业特性，被动）：强化神圣技能；使神圣系控制/治疗效果提高（不单独占恢复资源）。
- L3 Healing Word（职业特性，CD3）：单体/双目标治疗小招，优先最低血友军；战后短休自动清 CD。
- L4 Revivify（职业特性，大招）：复活 1 名阵亡友军（次数制；篝火/营地恢复；战斗后不恢复）。

### 3.7 Sorcerer（现 FireMage 组）

- L1 Fire Bolt：常驻火系输出+燃烧。
- L2 Metamagic（职业特性，被动）：每回合第一次火系法术额外附加 1 层燃烧或额外小额火伤（不做优势/劣势）。
- L3 Scorching Ray：CD3 多段法术攻击（更贴 5e）。
- L4 Fireball（大招）：AOE+高燃烧。

### 3.8 Wizard（现 IceMage 组）

- L1 Ray of Frost：常驻+减速。
- L2 Arcane Recovery（职业特性，被动）：奥术掌控；使控制/冰系法术更稳定（例如延长控制或提高冰系伤害），不作为单独恢复资源。
- L3 Web：CD3 控制法术（专注），更贴 5e。
- L4 Blizzard（大招）：AOE+冻结概率。

### 3.9 Warlock（现 ThunderMage 组）

- L1 Eldritch Blast：常驻（带连锁/弹射）。
- L2 Eldritch Invocation（职业特性，被动）：强化 Eldritch Blast（命中后追加固定小额伤害）。
- L3 Hex（职业特性，CD3）：单体意志豁免失败则施加 `Hex` 2 回合；目标回合开始受到 1d6 并 hit-；战后短休自动清 CD。
- L4 Thunderstorm（大招）：AOE+额外弹射。

### 3.10 Bard（新增）

定位：辅助/软控/少量治疗。标志性应体现“鼓舞队友”和“用言语干扰敌人”。

- L1 Vicious Mockery（职业特性）：常驻，单体意志豁免失败则心灵伤害 + hit-（1 回合）。
- L2 Bardic Inspiration（职业特性，被动）：回合开始为生命最低友军附加“鼓舞”（hit+ / damageRate+，攻击后消耗）。
- L3 Healing Word：CD3 单体治疗（可复用 Cleric 的治疗脚本结构）。
- L4 Hypnotic Pattern（大招）：AOE 控制（意志豁免，失败 STUN 近似，专注维持）。

### 3.11 Druid（新增）

定位：控制/持续伤害/形态。

- L1 Produce Flame：常驻法术输出。
- L2 Wild Shape（职业特性，被动）：回合开始获得临时生命/护甲（用 buff 实现）。
- L3 Entangle（职业特性，CD3，专注）：AOE 反射豁免失败则 `Restrained`（v3 近似：AC-、Speed-）或 `STUN`（近似束缚）。
- L4 Moonbeam（大招）：AOE 持续伤害（一次性 AOE + 2 回合 DOT）。

### 3.12 Barbarian（新增）

定位：前排爆发/减伤窗口。

- L1 Greataxe Swing：常驻近战高基础伤。
- L2 Reckless Attack（职业特性，被动）：每回合第一次攻击获得 hit+；同时自身 AC-（更容易被命中），体现“莽攻”。
- L3 Brutal Strike：CD3 单体物理重击（命中），若目标处于控制（Frozen/STUN/SILENT）则额外伤害。
- L4 Rage（狂暴，职业特性，大招）：自 buff 2 回合：增伤 + 减伤（偏物理）；并降低控制持续（近似）；次数制；篝火/营地恢复。

## 4. 对测试的影响预案（v3）

为保证“改完测试全绿”，v3 落地时会遵循：

- 不改敌人/遭遇配置，先用职业技能与数值把现有 `act1/balance` 拉通。
- 避免在大招里放“纯功能（复活/大 buff）”导致测试策略误点。
  - `bin/test_roguelike_act1.lua` 目前已改为：每战最多点一次，只点“对敌/输出型”大招。
- 新增 3 英雄不会强制进入 starter 队；只进入招募池或商店招募，保证现有测试路径稳定。

## 5. 需要你确认的点（确认后我开始改代码）

1. 新增英雄 ID 是否接受：900010/900011/900012？
2. 新增职业先做哪三个英雄外观名：`Bard/Druid/Barbarian` 还是你想换成别的三职业？
3. 允许我做两处“适度重做”吗？（都很小，但能显著提升 5e 味道）
   - 专注改为“可扩展”：不仅仅绑定 80004003/04，也能让 Bard/Druid 的专注技能正确清理 Buff。
   - 新增 2~4 个小 Buff：`STUN(30001)`、`Frightened`、`Restrained`、`MoonbeamDot`（实现用现有 buff/custom 即可）。
