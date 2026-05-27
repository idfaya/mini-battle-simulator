# Roguelike Feat 树设计

## 1. 设计目标

把职业 feat 改成树形结构：等级只决定能走多少树点，build 走向由玩家在树上的选择决定。

- 与 [physical_class_core_skill_design.md](file:///c:/work/MiniBattleSimulator/design/physical_class_core_skill_design.md) 与 [caster_class_core_skill_design.md](file:///c:/work/MiniBattleSimulator/design/caster_class_core_skill_design.md) 中定义的 low / mid / high 核心能力对齐。
- 等级 1 自动获得根节点，对应职业 low 核心被动；Lv3 必须从主干 T1（mid 核心主动）选；Lv5 必须从主干 T2（high 核心主动）选；Lv10 必须从满足前置的 capstone 中选 1 个；其余等级提供 1 自由点。
- build 走向由玩家选择哪条分支决定，而不是「等级=1张固定卡」。

## 2. Feat 树通用结构

节点类型：

- **根节点 R**：每职业 1 个，对应 low 核心被动。等级 1 自动获得，作为 fixed feat，不消耗自由点。
- **主干节点 T1**：对应 Lv3 mid 核心主动。第一次点时 `grant_skill = mid_slot`。
- **主干节点 T2**：对应 Lv5 high 核心主动。第一次点时 `grant_skill = high_slot`。
- **分支节点 B**：每职业 8~12 个可选小卡，提供数值 / 触发器加深。
- **合流节点 J**：必须先点过两条分支才能解锁的强化节点，承担「构筑收尾」的语义。
- **Capstone C**：每职业 2 个，全 Run 只能选 1 个。

## 3. 走树规则

- 每个非根节点至少有 1 个父节点已被点过才能选。
- 单节点只能点 1 次。
- 分支可设互斥组（mutex），通过 §5 落表中的 `choiceGroup` 字段表达；当前 SSOT 中已废弃旧线性 `choiceGroup`，仅在 §5 树形节点之间使用。
- 主干 T1 / T2 第一次点时 `grant_skill` 对应核心主动，后续合流节点对该主动做 `modify_skill`。
- Capstone 全 Run 只能选 1 个；选定后其它 capstone 节点不再出现在候选池。

## 4. 等级与点数表

| 等级 | 是否给点 | 限制 |
| ---: | :---: | --- |
| Lv1 | 自动获得 R | 无（fixed） |
| Lv2 | 1 自由点 | 无 |
| Lv3 | 1 受限点 | 必须从 T1 候选选 |
| Lv4 | 1 自由点 | 无 |
| Lv5 | 1 受限点 | 必须从 T2 候选选 |
| Lv6 | 1 自由点 | 无 |
| Lv7 | 1 自由点 | 无 |
| Lv8 | 1 自由点 | 无 |
| Lv9 | 1 自由点 | 无 |
| Lv10 | 1 受限点 | 必须从满足前置的 capstone 选 |

自由点可以走任何已解锁的 B / J 节点，前提是父节点已点过。

## 5. 每职业 Feat 树

每个节点列出：节点名、父节点、类别（A/B/C/D）、效果描述、落点（grant/modify/replace）。

类别口径：

- **A 类** = 直接读 mod 即可（数值字段或现有 mod pipeline 已支持）。
- **B 类** = 需要在职业 passive 文件加 onHit / onCast / onTrigger 几行。
- **C 类** = 需要 runtime 字段扩展。
- **D 类** = 设计层修订（不再做 C 类扩展，改为更克制的方案）。

C 类（保留）：

- 游侠：双印记、箭雨溢出（4→5 次）、致命箭雨、猎神之眼、万箭
- 邪术师：雷链扩展（弹射 +1）、万雷奔流、残响、印记爆发 J
- 圣武士：双重庇护 J（per-unit）
- 牧师：独立庇护 J（同 `shelterPerUnit` 字段）
- 战士：护卫加深（架势承担远程）、守护连环 J（架势团队护盾）、二次反击 capstone
- 武僧：连环宗师 capstone

由 C 改 A/B（替换语义，已在表内体现）：

- 武僧 截脉宗师 J → 徒手打击对当前 STUN 目标 +1d6（B）
- 盗贼 出血 J → 伏击命中后，目标在你下次攻击它时额外 +1d4（B）
- 盗贼 影杀 capstone → 击杀触发伏击的目标后对当前最低血敌人发动 1 次基础攻击（B）
- 野蛮人 拼命 → 受击进入狂暴时立即获得 1d6 临时生命，1 场 1 次（B）
- 牧师 圣火联动 → 神圣火花命中后为最低血友军 +1d4 临时生命（B）
- 术士 灼烧叠层 J → 火焰技能命中已点燃目标时本次额外 +1d4（A）

D 类（设计层修订）：

- 战士 钢墙宗师 capstone → 改为：护卫架势 CD -1，持续时间 +1 回合。

落点缩写：

- `grant` = `grant_skill`
- `modify` = `modify_skill`
- `replace` = `replace_skill`

### 5.1 战士 Fighter

| 节点 | 父 | 类 | 效果 | 落点 |
| --- | --- | :---: | --- | --- |
| R 反击 | — | B | 敌方近战命中你后，登记一次基础武器反击，敌方动作结算后执行 | grant low 核心被动 |
| B 重斩 | R | A | 基础攻击伤害 +1d4 | modify 基础武器攻击 |
| B 钢铁姿态 | R | A | 常驻 AC +1 | modify 角色属性 |
| B 精准反击 | R | A | 反击 hit +1 | modify 反击 skill |
| B 武器精通 | R | A | 暴击阈值 -1 | modify 基础武器攻击 |
| B 战斗节奏 | R | A | 每回合首次基础攻击伤害 +1d4 | modify 基础武器攻击 |
| T1 护卫架势 | R | B | Lv3 主干：mid 核心主动；架势期 AC +2，替友军承担近战，结算后对攻击者反击 | grant mid_slot |
| B 护卫加深 | T1 | C | 护卫架势承担远程攻击 | modify T1（`guardExtendsToRanged`） |
| B 护卫反击+ | T1 | A | 护卫反击伤害 +1d6 | modify 护卫反击 |
| J 守护连环 | T1 + 护卫加深 | C | 架势期间每回合 tick 一次队伍护盾 | modify T1（`guardEmitsTeamShield`） |
| J 反击连锁 | R + T1 | B | 一回合内反击触发后，可破例追加 1 次基础攻击 | modify 反击（`counterExtraBasicOnce`） |
| T2 不屈之风 | R | B | Lv5 主干：high 核心主动；每场 1 次免死并回 50% HP，清状态 | grant high_slot |
| B 屹立不倒 | T2 | A | 不屈触发后 AC +2 持续到下回合开始 | modify T2 |
| B 不屈再起 | T2 | C | 不屈每场触发次数 +1 | modify T2（`secondWindCharges`） |
| C 二次反击 | R + 反击连锁 | C | 一回合内允许触发 2 次反击 | modify 反击（`counterExtraBasicOnce` + 次数扩展） |
| C 钢墙宗师 | T1 | D | 护卫架势 CD -1，持续 +1 回合 | modify T1（`cooldownDelta` / 持续 +1） |

### 5.2 武僧 Monk

| 节点 | 父 | 类 | 效果 | 落点 |
| --- | --- | :---: | --- | --- |
| R 连击 | — | B | 徒手打击命中后 50% 概率追加一次额外攻击；额外攻击不再触发连击 | grant low 核心被动 |
| B 拳力加深 | R | A | 徒手打击伤害 +1d4 | modify 徒手打击 |
| B 灵巧步法 | R | A | 每回合首次受击伤害 -2 | modify 受击管线 |
| B 连环之意 | R | A | 连击触发概率 +10 | modify R |
| B 影步连打 | R | A | 攻击命中后 AC +1 直到下回合 | modify 徒手打击 |
| T1 震劲掌 | R | B | Lv3 主干：mid 核心主动；造成 1d8 钝击，体豁失败 STUN 1 回合 | grant mid_slot |
| B 凝意 | T1 | A | 震劲掌 spell DC +1 | modify T1 |
| B 截脉延续 | T1 | A | 震劲掌 STUN 持续 +1 回合（封顶 2） | modify T1 |
| J 截脉宗师 | T1 + 截脉延续 | B | 徒手打击对当前处于 STUN 的目标 +1d6 | passive onHit |
| J 拳影回响 | R + T1 | B | 一回合内连击破例触发 1 次 | modify R（`comboReentryOnce`） |
| T2 明镜止水 | R | B | Lv5 主干：high 核心主动；自疗 2d8+3，清 Frozen/STUN/SILENT | grant high_slot |
| B 调息 | T2 | A | 明镜止水治疗 +1d4 | modify T2 |
| B 心流 | T2 | A | 明镜止水 CD -1 | modify T2 |
| C 连环宗师 | R + 影步连打 | C | 一回合内连击额外破例触发 1 次（与拳影回响叠加） | modify R（`comboReentryOnce`） |
| C 不动明王 | T2 | A | 明镜止水改为半场 1 次自动触发，每场 1 次 | modify T2 |

### 5.3 盗贼 Rogue

| 节点 | 父 | 类 | 效果 | 落点 |
| --- | --- | :---: | --- | --- |
| R 伏击 | — | B | 基础攻击命中后若目标受控或被夹击，额外 +1d6 | grant low 核心被动 |
| B 偷袭专精 | R | A | 伏击额外伤害改为 +1d8 | modify R |
| B 致命准头 | R | A | 暴击阈值 -1 | modify 基础武器攻击 |
| B 灵巧 | R | A | AC +1 | modify 角色属性 |
| B 夹击老手 | R | A | 伏击触发条件放宽：包含 SLOW 目标 | modify R |
| T1 影袭处决 | R | B | Lv3 主干：mid 核心主动；执行一次基础攻击且强制满足伏击；目标半血以下额外 +2d6 | grant mid_slot |
| B 处决重斩 | T1 | A | 影袭处决伤害 +1d6 | modify T1 |
| B 穿行突刺 | T1 | A | 影袭处决无视前排 | modify T1 |
| J 影袭再起 | R + T1 | A | 影袭处决 CD -1 | modify T1（`cooldownDelta`） |
| J 出血 | R + 偷袭专精 | B | 伏击命中后，目标在你下次攻击它时额外 +1d4 | passive onHit 登记 |
| T2 直觉闪避 | R | B | Lv5 主干：high 核心主动；每回合首次被命中伤害减半 | grant high_slot |
| B 闪避加深 | T2 | A | 直觉闪避也对 AOE 生效 | modify T2 |
| B 直觉反击 | T2 | B | 直觉闪避触发后下次基础攻击视为满足伏击 | passive onTrigger |
| C 影杀 | R + 出血 | B | 击杀触发过伏击的目标后，对当前最低血敌人发动 1 次基础攻击（每场 3 次） | passive onKill |
| C 影舞宗师 | T1 + 穿行突刺 | A | 影袭处决变为对相邻 2 个目标各发动一次半伤基础攻击 | modify T1 |

### 5.4 游侠 Ranger

| 节点 | 父 | 类 | 效果 | 落点 |
| --- | --- | :---: | --- | --- |
| R 猎人印记 | — | B | 远程基础攻击命中后施加唯一印记，本回合首次伤害 +1d4 | grant low 核心被动 |
| B 印记专精 | R | A | 印记额外伤害 +1d4（合计 +2d4） | modify R |
| B 精准射击 | R | A | 远程基础攻击 hit +1 | modify 远程基础攻击 |
| B 弓术训练 | R | A | 远程基础攻击伤害 +1d4 | modify 远程基础攻击 |
| B 双印记 | R + 印记专精 | C | 同时维持 2 个印记 | modify R（`markSlotMax`） |
| B 持久印记 | R | A | 印记持续时间 +1 回合 | modify R（`dotDurationDelta`） |
| T1 狩猎指引 | R | B | Lv3 主干：mid 核心主动；对目标远程一击，若已被你标记，额外 +2d6 | grant mid_slot |
| B 指引强化 | T1 | A | 狩猎指引伤害 +1d6 | modify T1 |
| B 缠绕箭 | T1 | B | 狩猎指引命中后目标 SLOW 1 回合 | passive onHit |
| J 印记爆发 | R + 双印记 | C | 印记每回合可兑现 2 次 | modify R（`markPayoutPerRound`） |
| T2 箭雨 | R | B | Lv5 主干：high 核心主动；连续发动 4 次远程基础攻击随机分配，重复目标减半 | grant high_slot |
| B 箭雨溢出 | T2 | C | 箭雨射击次数从 4 提升到 5 | modify T2（`chainCountDelta`） |
| B 致命箭雨 | T2 | C | 箭雨重复命中时不再减半 | modify T2 |
| J 风暴箭幕 | T2 + 箭雨溢出 | A | 箭雨 CD -1 | modify T2（`cooldownDelta`） |
| C 猎神之眼 | R + 印记爆发 | C | 对带印记目标 hit +1，伤害 +1d8 | modify 远程基础攻击（受 mark 触发） |
| C 万箭 | T2 + 致命箭雨 | C | 箭雨射击次数再 +2 | modify T2（`chainCountDelta`） |

### 5.5 圣武士 Paladin

| 节点 | 父 | 类 | 效果 | 落点 |
| --- | --- | :---: | --- | --- |
| R 神圣庇护 | — | B | 友军每回合首次受击 -1d6 伤害 | grant low 核心被动 |
| B 庇护加深 | R | A | 庇护减伤改为 -1d8 | modify R |
| B 战吼 | R | A | 战斗开始全队 AC +1 持续 1 回合 | modify 角色被动 |
| B 重甲祷法 | R | A | 自身 AC +1 | modify 角色属性 |
| B 守护灵光 | R | A | 友军每回合首次受到法术伤害 -2 | modify R |
| T1 破邪斩 | R | B | Lv3 主干：mid 核心主动；基础攻击命中后额外 +2d8 光耀，并驱散 1 个增益 | grant mid_slot |
| B 破邪重斩 | T1 | A | 破邪斩伤害 +1d8 | modify T1 |
| B 神圣印记 | T1 | B | 破邪斩命中后目标受到所有伤害 +1 持续 1 回合 | passive onHit |
| J 净化光耀 | T1 + 神圣印记 | A | 破邪斩 CD -1 | modify T1（`cooldownDelta`） |
| T2 圣手 | R | B | Lv5 主干：high 核心主动；为最低血友军回 2d8+4 并清控 | grant high_slot |
| B 圣手扩展 | T2 | A | 圣手治疗 +1d4 | modify T2 |
| B 圣域回响 | T2 | A | 圣手 CD -1 | modify T2 |
| J 双重庇护 | R + 庇护加深 | C | 庇护改为 per-unit（每个友军独立 1 次/回合） | modify R（`shelterPerUnit`） |
| C 神光主教 | T1 + 净化光耀 | A | 破邪斩转为对 2 个目标各 +1d8 光耀 | modify T1 |
| C 慈光圣骑 | T2 + 圣域回响 | A | 圣手改为治疗最低血友军 +1d8，并提供 4 点护盾 | modify T2 |

### 5.6 野蛮人 Barbarian

| 节点 | 父 | 类 | 效果 | 落点 |
| --- | --- | :---: | --- | --- |
| R 狂暴 | — | B | 攻击或受击触发狂暴：每场 1 次，期间物理减伤 -2 且伤害 +2 | grant low 核心被动 |
| B 怒火加深 | R | A | 狂暴期间伤害再 +1 | modify R |
| B 钢皮 | R | A | 狂暴期间额外 -1 物理伤害 | modify R |
| B 凶猛劈砍 | R | A | 基础攻击伤害 +1d4 | modify 基础武器攻击 |
| B 怒袭 | R | A | 狂暴期间暴击阈值 -1 | modify 基础武器攻击 |
| B 拼命 | R | B | 受击进入狂暴时立即获得 1d6 临时生命，1 场 1 次 | passive onTrigger |
| T1 重击 | R | B | Lv3 主干：mid 核心主动；强化近战，暴击范围翻倍、力量加值翻倍 | grant mid_slot |
| B 重击精通 | T1 | A | 重击伤害 +1d6 | modify T1 |
| B 重斩频率 | T1 | A | 重击 CD -1 | modify T1 |
| J 裂地 | T1 + 重击精通 | A | 重击命中后对相邻目标造成 1d6 溅射 | modify T1 |
| T2 不倦狂暴 | R | B | Lv5 主干：high 核心主动；取消狂暴每场 1 次限制 | grant high_slot |
| B 狂暴持续 | T2 | A | 狂暴持续时间 +1 回合 | modify R |
| B 鲜血勇气 | T2 | A | 狂暴期间击杀回 1d6 生命 | passive onKill |
| C 永恒狂怒 | T2 + 鲜血勇气 | A | 狂暴期间所有伤害再 -2 | modify R |
| C 战神之怒 | T1 + 裂地 | A | 重击改为对前排 2 个目标 | modify T1 |

### 5.7 法师（冰）Wizard

| 节点 | 父 | 类 | 效果 | 落点 |
| --- | --- | :---: | --- | --- |
| R 寒霜迟滞 | — | B | 寒霜法术命中后施加「霜冻」 | grant low 核心被动 |
| B 寒霜深锁 | R | A | 霜冻持续 +1 回合 | modify R（`dotDurationDelta`） |
| B 法术增幅 | R | A | 基础冰系法术伤害 +1d4 | modify 基础冰系法术 |
| B 冰甲 | R | A | 施法后获得 4 点护盾，1 场 3 次 | passive onCast |
| B 霜牢 | R + 寒霜深锁 | A | 对霜冻目标命中额外 +1d6 | modify 基础冰系法术 |
| T1 冻结新星 | R | B | Lv3 主干：mid 核心主动；十字范围；霜冻目标转 FROZEN 1 回合，未霜冻施加霜冻 | grant mid_slot |
| B 冻结增幅 | T1 | A | 冻结新星伤害 +1d8 | modify T1 |
| B 寒域扩张 | T1 | A | 冻结新星 AOE 半径 +1 | modify T1（`aoeRadiusDelta`） |
| J 霜咒 | T1 + 寒霜深锁 | A | 冻结新星 CD -1 | modify T1（`cooldownDelta`） |
| T2 暴风雪 | R | B | Lv5 主干：high 核心主动；全体冰系基础伤害；命中霜冻目标额外 +1d8 并刷新霜冻 | grant high_slot |
| B 极寒暴风 | T2 | A | 暴风雪伤害 +1d6 | modify T2 |
| B 风暴回返 | T2 | A | 暴风雪 CD -1 | modify T2 |
| J 冻结回响 | T1 + T2 | A | 冻结新星与暴风雪命中冻结目标时再 +1d4 | modify T1 + T2 |
| C 寒霜宗师 | R + 霜牢 | A | 对霜冻 / 冻结目标的所有冰系伤害再 +1d6 | modify 基础冰系法术 + T1 + T2 |
| C 冻土帝 | T2 + 风暴回返 | A | 暴风雪命中已 FROZEN 目标再延长 FROZEN 1 回合 | modify T2 |

### 5.8 术士（火）Sorcerer

| 节点 | 父 | 类 | 效果 | 落点 |
| --- | --- | :---: | --- | --- |
| R 余烬点燃 | — | B | 火焰法术命中附加燃烧；已燃烧只刷新持续 | grant low 核心被动 |
| B 烈焰塑形 | R | A | 基础火焰法术发射物 +1 | modify 基础火焰法术 |
| B 法术增幅 | R | A | 基础火焰法术伤害 +1d4 | modify 基础火焰法术 |
| B 余热 | R | A | 燃烧每跳 +1 | modify R |
| B 燃烧延续 | R | A | 燃烧持续 +1 回合 | modify R（`dotDurationDelta`） |
| T1 灰烬爆燃 | R | B | Lv3 主干：mid 核心主动；2d8 火焰；目标已点燃则 +1d8 | grant mid_slot |
| B 爆燃强化 | T1 | A | 灰烬爆燃伤害 +1d6 | modify T1 |
| B 火焰链接 | T1 | A | 灰烬爆燃命中后对相邻溅射 1d6 | modify T1 |
| J 烬火再燃 | R + 燃烧延续 | B | 燃烧目标死亡时引爆 1d6 火焰对相邻目标 | passive onKill |
| T2 烈焰风暴 | R | B | Lv5 主干：high 核心主动；全体火焰；已点燃 +1d8 并延燃 | grant high_slot |
| B 烈焰高潮 | T2 | A | 烈焰风暴伤害 +1d6 | modify T2 |
| B 风暴回响 | T2 | A | 烈焰风暴 CD -1 | modify T2 |
| J 灼烧叠层 | R + T2 | A | 火焰技能命中已点燃目标时本次 +1d4 | modify 全部火焰技能 |
| C 火潮宗师 | T2 + 风暴回响 | A | 烈焰风暴对所有目标的伤害再 +1d4 | modify T2 |
| C 余烬主教 | T1 + 烬火再燃 | A | 灰烬爆燃 CD -1，对点燃目标暴击阈值 -1 | modify T1 |

### 5.9 牧师 Cleric

| 节点 | 父 | 类 | 效果 | 落点 |
| --- | --- | :---: | --- | --- |
| R 神恩庇护 | — | B | 全队共享：每回合首次有友军被命中时该次 -1d6 | grant low 核心被动 |
| B 圣火加深 | R | A | 神圣火花伤害 +1d8 | modify 神圣火花 |
| B 圣职祷文 | R | A | 治愈之言治疗 +2 | modify 治愈之言 |
| B 庇护扩展 | R | A | 庇护减伤 +1d4（合计 -1d6-1d4） | modify R |
| B 圣火联动 | R | B | 神圣火花命中后，为最低血友军 +1d4 临时生命 | passive onHit |
| T1 治愈之言 | R | B | Lv3 主干：mid 核心主动；最低血友军 +2d8+施法修正，并解 1 个负面 | grant mid_slot |
| B 抚慰之言 | T1 | A | 治愈之言再额外 +1d4 | modify T1 |
| B 治疗加深 | T1 | A | 治愈之言 CD -1 | modify T1 |
| J 慈光 | T1 + 圣火联动 | A | 治愈之言额外为治疗目标提供 4 点护盾 | modify T1 |
| T2 圣域祷言 | R | B | Lv5 主干：high 核心主动；2 回合内全队 AC +1，每回合每友军首次受击 -1d6 | grant high_slot |
| B 圣域延续 | T2 | A | 圣域祷言持续 +1 回合 | modify T2 |
| B 圣域回响 | T2 | A | 圣域祷言 CD -1 | modify T2 |
| J 独立庇护 | R + 庇护扩展 | C | 神恩庇护改为 per-unit（每个友军独立 1 次/回合） | modify R（`shelterPerUnit`） |
| C 守望主教 | T2 + 独立庇护 | A | 圣域祷言期间附加：每回合最低血友军 +1d4 治疗 | modify T2 |
| C 慈恩主教 | T1 + 慈光 | A | 治愈之言改为治疗 2 名最低血友军 | modify T1 |

### 5.10 邪术师（雷）Warlock

| 节点 | 父 | 类 | 效果 | 落点 |
| --- | --- | :---: | --- | --- |
| R 静电印记 | — | B | 邪能冲击命中后附印记；本回合首次对带印记目标伤害 +1d6 | grant low 核心被动 |
| B 静电过载 | R | A | 印记额外伤害 +1d4（合计 +1d6+1d4） | modify R |
| B 法术增幅 | R | A | 邪能冲击伤害 +1d4 | modify 邪能冲击 |
| B 印记加深 | R | A | 每回合可对 2 个目标分别上印记 | modify R（`markRecastPerRound`） |
| B 印记延续 | R | A | 印记持续 +1 回合 | modify R（`dotDurationDelta`） |
| T1 雷链 | R | B | Lv3 主干：mid 核心主动；对目标雷电伤害并弹射 1 名敌人；带印记优先 | grant mid_slot |
| B 雷链扩展 | T1 | C | 雷链额外弹射 1 次 | modify T1（`chainCountDelta`） |
| B 残响 | T1 | C | 雷链最后一跳额外 +1d6 | modify T1（残响字段） |
| J 印记锚定 | R + 印记延续 | A | 雷链命中带印记目标后该印记持续 +1 回合 | modify T1 |
| T2 雷暴 | R | B | Lv5 主干：high 核心主动；全体雷电；带印记目标 +1d8 并清印记 | grant high_slot |
| B 雷暴增幅 | T2 | A | 雷暴伤害 +1d6 | modify T2 |
| B 雷暴回响 | T2 | A | 雷暴 CD -1 | modify T2 |
| J 印记爆发 | R + 印记加深 | C | 印记每回合可兑现 2 次 | modify R（`markPayoutPerRound`） |
| C 雷契宗师 | T1 + 雷链扩展 | C | 雷链改为最多 4 段弹射且首段 +1d8 | modify T1（`chainCountDelta` + 残响） |
| C 万雷奔流 | T2 + 雷暴回响 | C | 雷暴每命中带印记目标再随机弹射 1 次半伤雷击 | modify T2（弹射扩展） |

## 6. 基础设施 mod 字段清单

| 字段 | 用途 | 使用节点 | 读取位置 |
| --- | --- | --- | --- |
| `cooldownDelta` | CD ±N | 战 J 净化光耀、盗 J 影袭再起、武 心流、游 J 风暴箭幕、法 J 霜咒 + B 风暴回返、术 B 风暴回响、牧 B 治疗加深 + 圣域回响、邪 B 雷暴回响、战 C 钢墙宗师 | `modules/skill_runtime.lua`（CD 解析） |
| `bonusHit` | 命中加值 +1 | 游 C 猎神之眼、盗 B 致命准头（暴击侧）、武 B 灵巧步法附属 | `modules/skill_runtime.lua`（attack roll 装配） |
| `critThresholdDelta` | 暴击阈值 -1 | 战 B 武器精通、盗 B 致命准头、野 B 怒袭、邪 B 静电过载（带印记触发） | `modules/skill_runtime.lua`（crit 判定） |
| `dotDurationDelta` | 点燃 / 印记 / 霜冻持续 +N 回合 | 游 B 持久印记、法 B 寒霜深锁、术 B 燃烧延续、邪 B 印记延续 | 各职业 passive 文件（onApply 时计算） |
| `aoeRadiusDelta` | AOE 半径扩张 | 法 B 寒域扩张、术 B 火焰链接（语义级） | `skills/` 中各 AOE skill 的 target picker |
| `chainCountDelta` | 弹射 / 箭雨次数 +N | 游 B 箭雨溢出 + C 万箭、邪 B 雷链扩展 + C 雷契宗师 | `skills/` 中弹射 / multishot skill |
| `markPayoutPerRound` | 印记每回合可兑现次数 | 游 J 印记爆发 + C 猎神之眼、邪 J 印记爆发 | 游侠 / 邪术师 passive 文件 |
| `markSlotMax` | 印记同时维持上限 | 游 B 双印记 | 游侠 passive 文件 |
| `markRecastPerRound` | 印记每回合可施加次数 | 邪 B 印记加深 | 邪术师 passive 文件 |
| `guardExtendsToRanged` | 护卫架势承担远程攻击 | 战 B 护卫加深 | 战士 passive / 护卫架势 skill |
| `guardEmitsTeamShield` | 架势期间 tick 团队护盾 | 战 J 守护连环 | 战士 passive / 护卫架势 skill |
| `comboReentryOnce` | 一回合内连击 / 反击破例触发 1 次 | 武 J 拳影回响、武 C 连环宗师 | 武僧 passive 文件 |
| `counterExtraBasicOnce` | 反击破例追加 1 次基础攻击 | 战 J 反击连锁、战 C 二次反击 | 战士 passive 文件 |
| `secondWindCharges` | 不屈每场触发次数 | 战 B 不屈再起 | 战士 passive / 不屈 skill |
| `shelterPerUnit` | 庇护从 team-once 改为 per-unit | 圣 J 双重庇护、牧 J 独立庇护 | 圣武士 / 牧师 passive 文件 |

## 7. Schema 与 feats.lua 对接

`BuildFeatDef`（位于 `config/tables/feats.lua` 顶部 EmmyLua 注释）需要新增以下可选字段：

- `prerequisites: integer[]` —— 父节点 feat id 列表，用于实现「至少有一个父节点已点过」的解锁判定。
- `isRoot: boolean` —— 是否根节点 R，等级 1 自动获得，不消耗自由点。
- `trunk: "T1" | "T2" | nil` —— 主干位置；存在时 picker 在 Lv3 / Lv5 仅从该候选筛选。
- `isCapstone: boolean` —— 是否 capstone C；全 Run 只能选 1 个，picker 选定后清理同类候选。
- `treeSlot: "R" | "B" | "J" | "T1" | "T2" | "C" | nil` —— 树位语义，便于 UI / picker 排序与限制。

字段全部为可选，旧有 feat 数据不需要调整即可继续工作；新数据按节点类型逐个补上。

## 8. 落地顺序

1. 文档定稿（本任务完成后即定稿）。✅
2. 扩展 `BuildFeatDef` schema（仅扩注释，不改运行时函数）。✅（`treeSlot` / `trunk` / `isCapstone` / `prerequisites` 字段已在 `config/tables/feats.lua` 落地）
3. 实装基础设施 mod 字段（按第 6 节清单逐字段挂到对应 passive / skill）。✅（§6 字段已在 R / T1 / T2 + B / J / C 节点的 `effects.modify_skill.add` 中使用）
4. 按职业逐个把 R / T1 / T2 节点先补全，确保 Lv1 / Lv3 / Lv5 走完。✅（10 职业的 R = Lv1 fixed feat / T1 = Lv3 subclass / T2 = Lv5 capstone 已显式打 trunk 标记）
5. 再实装 B / J 节点，按类别 A → B → C 推进。✅（10 职业 × ~10 个 B/J 节点已写入，namespace 起 `2300000 + classId*1000 + idx`）
6. 最后实装 capstone（C / D），打通 Lv10 选择闭环。✅（每职业 2 个 Lv10 capstone，`isCapstone=true`，FeatPicker 限制 Run 内只能点一次）
