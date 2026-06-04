# Buff 系统实现文档

> **项目**: Mini Battle Simulator
> **更新时间**: 2026-05-18
> **说明**: 本文档描述当前工程中 Buff 系统的实际实现方式、调用链路、生命周期、配置格式与现有状态表，内容以源码现状为准。

---

## 1. 系统概述

当前工程中，几乎所有状态效果都统一走 `Buff` 框架实现。

- 正面状态走 `E_BUFF_MAIN_TYPE.GOOD`
- 负面状态走 `E_BUFF_MAIN_TYPE.BAD`
- 硬控制走 `E_BUFF_MAIN_TYPE.CONTROL`

这意味着：

- 规则层可以继续区分增益、减益、DoT、控制
- 实现层统一都落在 `BattleBuff` 里管理
- 技能脚本、Timeline 标签、前端显示、日志事件都围绕同一套 Buff 生命周期工作

Buff 系统在工程中的职责主要有四块：

- 管理角色身上的 Buff 实例与叠层
- 在指定时机触发 Buff 效果
- 提供统一的查询、移除、统计接口
- 向表现层派发 Buff 变更事件

---

## 2. 核心文件

| 模块 | 文件 | 职责 |
|------|------|------|
| Buff 核心 | `modules/battle_buff.lua` | Buff 存储、添加、移除、叠层、时机触发、控制判定 |
| 技能入口 | `modules/battle_skill.lua` | 从技能加载 Buff 配置，并通过统一入口施加 Buff |
| 状态封装 | `skills/battle_skill_status.lua` | 对中毒、燃烧、冻结、霜冻、静电印记等常见状态做封装 |
| 时间线标签 | `skills/skill_effect_registry.lua` | 把 `apply_burn`、`apply_poison`、`apply_freeze` 等标签绑定到实际逻辑 |
| 回合钩子 | `skills/battle_skill_turn_hooks.lua` | 在回合开始处理 Buff 触发、控制跳过、复活虚弱、吟唱继续 |
| 战斗主循环 | `modules/battle_main.lua` | 在回合结束调用 Buff 结算与持续时间递减 |
| 枚举定义 | `core/battle_enum.lua` | 定义 Buff 主类型、控制子类型等枚举 |
| 视觉事件 | `ui/battle_visual_events.lua` | 构建 BUFF_ADDED、BUFF_REMOVED、HERO_STATE_CHANGED 等事件数据 |
| Buff 配置源 | `config/data/buffs.json` | Buff 静态总表配置，按数组维护当前 28 个状态 |
| Buff 运行时适配 | `config/tables/buffs.lua` | 读取 `data/buffs.json`，按 `buffId` 建索引并回绑 Lua handler |
| Buff 效果注册 | `skills/buff_effect_registry.lua` | 为 DoT、减速等少数带自定义逻辑的 Buff 提供 handler |

---

## 3. 架构分层

### 3.1 实现分层

当前 Buff 系统可以按四层理解：

1. `config/data/buffs.json`
   - 定义 Buff 静态总表配置
   - 包括名称、主类型、持续时间、叠层规则、触发效果等
2. `config/tables/buffs.lua`
   - 运行时适配层
   - 负责读取 JSON，并按 `handlerId` 回绑 Lua 自定义效果
3. `BattleSkill.ApplyBuffFromSkill`
   - 技能侧统一施加入口
   - 负责加载配置，并允许调用方覆盖持续时间、层数、数值
4. `BattleBuff`
   - 运行时核心
   - 管理 Buff 实例、叠层、移除、时机触发、控制判定
5. `BattleVisualEvents`
   - 面向前端和日志的事件层
   - 把 Buff 变化包装成统一事件

### 3.2 运行时存储

`BattleBuff` 内部用一个全局表保存所有角色身上的 Buff：

```lua
local heroBuffs = {}
```

键使用角色的 `id` 或 `instanceId`，值是该角色当前持有的 Buff 实例数组。

每个 Buff 实例至少包含以下运行时字段：

- `id`: 运行时唯一 Buff 实例 ID
- `buffId`: 配置 ID
- `mainType`: 主类型，GOOD/BAD/CONTROL/MIDDLE
- `subType`: 子类型
- `name`: 名称
- `stackCount`: 当前层数
- `maxStack`: 最大层数
- `value` / `maxValue`: 数值参数
- `displayMode`: 前端展示模式
- `duration` / `maxDuration`: 持续时间
- `caster`: 施加者
- `target`: 持有者
- `effects`: 触发效果列表
- `isPermanent`: 是否永久
- `canStack`: 是否可叠层
- `stackRule`: 叠层规则
- `icon` / `desc`: 展示文本

---

## 4. Buff 配置格式

### 4.1 基础结构

Buff 静态配置统一放在 `config/data/buffs.json`，运行时由 `config/tables/buffs.lua` 读取后按 `buffId` 建立索引，并按 `handlerId` 回绑 Lua 效果函数。

典型配置如下：

```lua
local BuffConfig = {
    [870001] = {
        buffId = 870001,
        mainType = E_BUFF_MAIN_TYPE.BAD,
        subType = 870001,
        name = "燃烧",
        initialStack = 1,
        maxStack = 99,
        duration = 2,
        canStack = true,
        stackRule = "add",
        effects = {
            {
                timing = 3,
                type = "custom",
                func = function(buff, hero, effect)
                    -- 自定义逻辑
                end
            }
        }
    },
}
```

### 4.2 常用字段

| 字段 | 说明 |
|------|------|
| `buffId` | Buff 唯一 ID |
| `mainType` | 主类型，决定增益/减益/控制分类 |
| `subType` | 子类型，用于规则判定、查询、移除 |
| `name` | Buff 名称 |
| `initialStack` | 初始层数 |
| `maxStack` | 最大层数 |
| `duration` | 持续回合 |
| `isPermanent` | 是否永久 Buff |
| `canStack` | 是否允许叠层 |
| `stackRule` | 叠层规则：`refresh` / `add` / `independent` |
| `value` / `maxValue` | 附加数值参数 |
| `displayMode` | 前端展示模式，如 `pct` |
| `effects` | 触发效果列表 |
| `icon` | 图标路径 |
| `desc` | 描述文本 |

### 4.3 叠层规则

`stackRule` 是当前系统里非常关键的字段：

- `refresh`
  - 刷新持续时间
  - 常见于不可叠层的单体状态
- `add`
  - 增加层数
  - 常见于中毒、燃烧、战意、狂怒
- `independent`
  - 创建独立实例
  - 当前工程里较少使用，但底层支持

---

## 5. 触发时机与效果系统

### 5.1 触发时机

`BattleBuff` 内部定义了一套统一时机枚举：

| timing | 名称 | 含义 |
|--------|------|------|
| 1 | `ON_ADD` | Buff 添加时 |
| 2 | `ON_REMOVE` | Buff 移除时 |
| 3 | `ON_ROUND_BEGIN` | 回合开始时 |
| 4 | `ON_ROUND_END` | 回合结束时 |
| 5 | `ON_ATTACK` | 攻击时 |
| 6 | `ON_DEFEND` | 受击时 |
| 7 | `ON_DAMAGE` | 造成伤害时 |
| 8 | `ON_RECEIVE_DAMAGE` | 受到伤害时 |
| 9 | `ON_HEAL` | 治疗时 |
| 10 | `ON_RECEIVE_HEAL` | 受到治疗时 |
| 11 | `ON_KILL` | 击杀时 |
| 12 | `ON_DEATH` | 死亡时 |

### 5.2 效果类型

`effects` 里的每个效果项通过 `type` 决定处理方式：

| type | 含义 |
|------|------|
| `damage` | 造成伤害 |
| `heal` | 恢复生命 |
| `attr_change` | 修改属性 |
| `dispel` | 驱散 |
| `energy` | 改变能量 |
| `custom` | 走 Lua 自定义函数 |

当前工程里，大多数复杂状态都使用 `custom`，因为它能复用现有伤害结算、豁免、日志、附加逻辑。

### 5.3 当前常见模式

- DoT 类 Buff
  - 通过 `ON_ROUND_BEGIN + custom` 在回合开始结算
- 属性挂载类 Buff
  - 通过 `ON_ADD` 修改属性
  - 通过 `ON_REMOVE` 还原属性
- 控制类 Buff
  - 主要依赖 `mainType = CONTROL` 或控制子类型，不一定需要 `effects`

---

## 6. 从技能到 Buff 的完整调用链

### 6.1 通用入口

技能侧统一通过：

```lua
BattleSkill.ApplyBuffFromSkill(caster, target, buffId, skill, override)
```

这个入口会做三件事：

1. 调用 `BattleSkill.LoadBuffConfig(buffId)` 加载配置
2. 如果传入 `override`，把覆盖字段合并到配置里
3. 调用 `BattleBuff.Add(caster, target, buffConfig)` 真正挂载

### 6.2 时间线标签

Timeline 技能通常不会直接手写大量 Buff 逻辑，而是通过 `SkillEffectRegistry` 注册的标签复用已有逻辑。

当前已经内置的 Buff 相关标签包括：

- `apply_burn`
- `apply_burn_refresh_only`
- `apply_poison`
- `apply_freeze`
- `apply_frost`
- `apply_static_mark`
- `battle_intent_buff`
- `poison_burst`
- `wizard_freezing_nova`
- `wizard_blizzard_settlement`
- `warlock_thunderstorm_settlement`

这些标签大致分三类：

- 直接施加状态
- 结算旧状态并刷新
- 检查已有状态后执行引爆或转化

### 6.3 状态封装层

`skills/battle_skill_status.lua` 是当前常用状态的统一封装层，主要负责：

- `ApplyPoison`
- `ProcessInfectEffect`
- `ApplyBurn`
- `ApplyBurnRefreshOnly`
- `ApplyFreeze`
- `ApplyFrost`
- `ApplyStaticMark`
- `HasSlow`
- `HasFrost`
- `HasStaticMark`

它的作用不是替代 `BattleBuff`，而是把业务规则固定下来：

- 防止每个技能都各写一套叠层逻辑
- 保留旧的 monkey-patch 转发契约
- 方便 Timeline 标签复用

---

## 7. BattleBuff 生命周期

### 7.1 初始化

战斗开始时会调用：

- `BattleBuff.Init()`

它会：

- 清空所有角色 Buff
- 重置运行时 Buff ID 计数器
- 初始化控制子类型表

### 7.2 添加

Buff 添加统一经过：

```lua
BattleBuff.Add(caster, target, buffConfig)
```

处理逻辑如下：

1. 检查目标与配置是否合法
2. 查找目标身上是否已有同 `buffId` Buff
3. 按 `canStack + stackRule` 处理刷新、叠层或创建独立实例
4. 新增时立即触发 `ON_ADD`
5. 发布 `BUFF_ADDED`
6. 发布 `HERO_STATE_CHANGED`

一个当前实现里的特殊规则：

- 如果新 Buff 的 `mainType == CONTROL`
- 且目标正在吟唱 `__pendingCast`
- 则会立即打断吟唱

### 7.3 回合开始

回合开始时由 `BattleSkillTurnHooks.ProcessTurnStartStatus(hero)` 驱动：

1. 调用 `BattleBuff.OnRoundBegin(hero)`
2. 逐个触发该角色所有 Buff 的 `ON_ROUND_BEGIN`
3. 处理复活虚弱、吟唱继续等额外状态
4. 如果角色仍处于控制状态，则跳过本次行动

这一步是：

- 中毒
- 燃烧
- 回合开始类恢复
- 控制状态行动阻断

的统一入口。

### 7.4 回合结束

回合结束时由 `BattleMain.FinalizeHeroTurn(hero)` 调用：

- `BattleBuff.OnRoundEnd(hero)`

它会：

1. 触发 `ON_ROUND_END`
2. 对非永久 Buff 递减 `duration`
3. 收集到期 Buff
4. 触发到期 Buff 的 `ON_REMOVE`
5. 发布 `BUFF_EXPIRED`
6. 从角色身上移除 Buff

如果这个 Buff 与专注系统绑定，到期后还会进一步清掉施法者身上的专注状态。

### 7.5 移除

当前提供多种移除方式：

- `DelBuffByMainType`
- `DelBuffBySubType`
- `DelBuffByBuffIdAndCaster`
- `ClearAllBuffs`
- `RemoveAllDebuffs`

其中 `RemoveAllDebuffs(hero)` 会移除：

- `BAD`
- `CONTROL`

因此它既能净化减益，也能净化硬控。

---

## 8. 控制判定

### 8.1 控制来源

控制判定有两条路径：

1. `buff.mainType == E_BUFF_MAIN_TYPE.CONTROL`
2. `buff.subType` 属于控制子类型集合

控制子类型集合当前包含：

- `STUN`
- `Frozen`
- `SILENT`
- `Charm`
- `Charm2`

### 8.2 控制影响

当前控制的统一行为是：

- 回合开始时检测
- 若命中控制，则当前回合不能继续行动

这套逻辑集中在：

- `BattleBuff.IsHeroUnderControl`
- `BattleBuff.GetControlBuffs`
- `BattleSkillTurnHooks.ProcessTurnStartStatus`

注意：

- `霜冻 880005` 不是 `CONTROL`
- `减速 880001` 不是 `CONTROL`
- 它们属于负面状态，不会直接触发“跳过行动”

---

## 9. 当前 Buff 与属性系统的耦合

### 9.1 GetBuffValue / GetBuffStack 的使用方式

属性模块并不是逐个读取 Buff 配置，而是通过通用查询接口计算结果，例如：

- `GetBuffValueBySubType(hero, subType)`
- `GetBuffStackNumBySubType(hero, subType)`
- `GetBuffBySubType(hero, subType)`

这意味着：

- Buff 本身负责声明状态
- 属性模块负责解释这个状态对面板或公式的影响

### 9.2 典型例子

#### 战意 840001

在 `BattleAttribute.GetSpeed(hero)` 中：

- `战意` 每层额外提供速度百分比加成

#### 战神降临 840003

在 `BattleAttribute.GetSpeed(hero)` 中：

- 若存在该 Buff，则额外提供速度百分比增益

#### 减速 880001

当前有两部分效果：

1. 在 Buff 的 `ON_ADD/ON_REMOVE` 中直接影响：
   - `hero.ac`
   - `hero.saveRef`
2. 在 `BattleAttribute.GetSpeed(hero)` 中通过 `value = 3000` 参与速度百分比扣减

需要特别注意：

- 当前战斗行动条系统采用“等速推进”
- `speed` 不决定战斗中的行动频率
- 所以减速虽然会进入 `GetSpeed` 计算，但当前不会改变战斗中的出手次数

这不是文档约定，而是当前代码现状。

---

## 10. 前端与事件系统

### 10.1 事件类型

Buff 系统会向表现层发布以下核心事件：

- `BUFF_ADDED`
- `BUFF_REMOVED`
- `BUFF_EXPIRED`
- `HERO_STATE_CHANGED`

### 10.2 Buff 事件数据

`BattleVisualEvents.BuildBuffEvent` 当前会给前端提供：

- `buffId`
- `buffName`
- `buffIcon`
- `buffType`
- `stackCount`
- `value`
- `displayMode`
- `duration`

这意味着前端显示 Buff 图标、层数、持续时间和数值，不需要再去重复解析底层 Buff 表。

### 10.3 Timeline 帧事件

技能时间线帧事件里也可能带 Buff 信息，例如：

- `buffId`
- `effectValue`
- `statusEffect`
- `savedTargets`

这部分主要服务于：

- 日志展示
- 特效播放
- Web 端时间线调试

---

## 11. 关键 API 清单

### 11.1 添加与移除

- `BattleBuff.Add(caster, target, buffConfig)`
- `BattleBuff.DelBuffByMainType(target, mainType)`
- `BattleBuff.DelBuffBySubType(target, subType, count)`
- `BattleBuff.DelBuffByBuffIdAndCaster(target, buffId, caster, count)`
- `BattleBuff.ClearAllBuffs(hero)`
- `BattleBuff.RemoveAllDebuffs(hero)`

### 11.2 查询与修改

- `BattleBuff.GetAllBuffs(hero)`
- `BattleBuff.GetBuff(hero, buffId)`
- `BattleBuff.GetBuffBySubType(hero, subType)`
- `BattleBuff.GetBuffStackNumByMainType(hero, mainType)`
- `BattleBuff.GetBuffStackNumBySubType(hero, subType)`
- `BattleBuff.GetBuffValueBySubType(hero, subType)`
- `BattleBuff.ModifyBuffStack(hero, buffId, delta)`
- `BattleBuff.GetStats()`

### 11.3 生命周期与控制

- `BattleBuff.Init()`
- `BattleBuff.OnFinal()`
- `BattleBuff.OnRoundBegin(hero)`
- `BattleBuff.OnRoundEnd(hero)`
- `BattleBuff.ProcessBuffEffect(buff, hero, timing)`
- `BattleBuff.HasControlBuff(target)`
- `BattleBuff.IsHeroUnderControl(target)`
- `BattleBuff.GetControlBuffs(target)`

### 11.4 技能侧入口

- `BattleSkill.ApplyBuffFromSkill(caster, target, buffId, skill, override)`
- `BattleSkill.LoadBuffConfig(buffId)`

---

## 12. 当前 Buff 配置总表

截至当前版本，`config/data/buffs.json` 中共维护 28 个 Buff 条目；运行时通过 `config/tables/buffs.lua` 适配加载。

### 12.1 820xxx：旧战斗通用姿态/仇恨状态

| Buff ID | 名称 | 主类型 | 说明 |
|---------|------|--------|------|
| 820001 | 挑衅 | BAD | 短时目标约束状态 |
| 820002 | 反击姿态 | GOOD | 反击窗口状态 |
| 820003 | 盾墙 | GOOD | 短时防护姿态 |

### 12.2 840xxx：团队增益与战意体系

| Buff ID | 名称 | 主类型 | 说明 |
|---------|------|--------|------|
| 840001 | 战意 | GOOD | 可叠层的团队/个人成长状态 |
| 840002 | 全军突击 | GOOD | 团队增益 |
| 840003 | 战神降临 | GOOD | 强化型团队增益 |

### 12.3 850xxx：毒系

| Buff ID | 名称 | 主类型 | 说明 |
|---------|------|--------|------|
| 850001 | 中毒 | BAD | 回合开始按层数结算毒伤 |

### 12.4 860xxx：神恩系

| Buff ID | 名称 | 主类型 | 说明 |
|---------|------|--------|------|
| 860001 | 神恩 | GOOD | 持续型正面状态 |

### 12.5 870xxx：火系

| Buff ID | 名称 | 主类型 | 说明 |
|---------|------|--------|------|
| 870001 | 燃烧 | BAD | 首个回合开始仅延迟；下一次回合开始进行反射豁免，失败则受到火焰伤害并结束 |
| 870002 | 火焰亲和 | GOOD | 常驻正面状态，用于延长燃烧等联动 |

### 12.6 880xxx：冰系与弱点

| Buff ID | 名称 | 主类型 | 说明 |
|---------|------|--------|------|
| 880001 | 减速 | BAD | 当前同时影响 AC、敏捷豁免与速度计算 |
| 880002 | 冻结 | CONTROL | 硬控 |
| 880003 | 眩晕 | CONTROL | 硬控 |
| 880004 | 破绽 | BAD | AC -1 的短时破甲状态 |
| 880005 | 霜冻 | BAD | 无法移动，但不直接算硬控 |

### 12.7 890xxx：职业被动与标记体系

| Buff ID | 名称 | 主类型 | 说明 |
|---------|------|--------|------|
| 890001 | 静电印记 | BAD | 雷系标记；邪能冲击 / 雷链兑现时只追加雷伤，`雷暴` 命中已标记目标时移除 |
| 890002 | 狂怒 | GOOD | 野蛮人叠层资源 |
| 890003 | 狂暴 | GOOD | 野蛮人强化状态 |
| 890004 | 护卫架势 | GOOD | 护卫窗口、AC 加成、准备反击 |
| 890005 | 猎人印记 | BAD | 游侠锁定目标 |
| 890006 | 圣域祷言 | GOOD | 团队防护状态 |
| 890007 | 守望主教 | GOOD | 前排强化窗口 |
| 890008 | 守护灵光 | GOOD | 圣骑守护灵光窗口；范围内友军获得 AC 加成 |
| 890009 | 圣域圣骑 | GOOD | 防护强化状态 |
| 890010 | 野外坚忍 | GOOD | 首次受击减伤机会标记 |
| 890011 | 神恩庇护 | GOOD | 牧师团队减伤庇护 |
| 890012 | 神圣庇护 | GOOD | 圣骑神圣灵光常驻标记，供 AC / 豁免 / 范围逻辑读取 |
| 890013 | 重甲祷法 | GOOD | 圣骑重甲祷法常驻标记，供额外 AC / 豁免加成读取 |

---

## 13. 当前工程中的典型状态实现

### 13.1 中毒

实现特点：

- `BAD`
- 可叠层
- `isPermanent = true`
- `ON_ROUND_BEGIN` 时按层数结算 `Xd4` 毒伤

适合作为：

- 主体系 DoT
- 可引爆资源
- 可感染加深的堆叠状态

### 13.2 燃烧

实现特点：

- `BAD`
- 不叠层，重复施加只刷新持续时间
- 首个 `ON_ROUND_BEGIN` 仅消耗延迟标记，不立即造成伤害
- 下一次 `ON_ROUND_BEGIN` 进行一次 `反射` 豁免，失败时受到 `1d4` 火焰伤害并立刻结束
- 若施法者有 `火焰亲和 870002`，可延长持续时间

### 13.3 冻结 / 眩晕

实现特点：

- `CONTROL`
- 不依赖复杂 `effects`
- 主要通过统一控制检测阻断行动

### 13.4 霜冻

实现特点：

- `BAD`
- 当前语义是“无法移动，但仍可远程攻击和释放技能”
- 用于冰系链路中的铺垫状态，不直接跳过行动

### 13.5 静电印记

实现特点：

- `BAD`
- 不叠层，只刷新
- 主要用于后续技能检测与引爆，不是 DoT 也不是硬控

---

## 14. 当前实现注意事项

### 14.1 文档应以源码为准

本章描述以当前源码与配置为准。例如，DoT 结算已统一为基于骰子表达的 5e 风格语义。

后续核对 Buff 行为时应优先参考：

- `modules/battle_buff.lua`
- `skills/battle_skill_status.lua`
- `skills/skill_effect_registry.lua`
- `config/tables/buffs.lua`
- `skills/buff_effect_registry.lua`

### 14.2 减速的现状较特殊

`880001 减速` 目前不是单一语义：

- Buff 本体会直接扣 AC 和 `saveRef`
- 属性模块里又会把它当速度百分比减益
- 但当前行动条系统不按 speed 决定出手频率

所以它是“已接属性层、未完全接行动频率层”的状态。

### 14.3 控制与负面状态是两套语义

并不是所有负面状态都会阻断行动。

当前要触发“无法行动”，必须满足：

- `mainType = CONTROL`
  或
- `subType` 被纳入控制子类型集合

像 `霜冻`、`减速`、`破绽`、`猎人印记` 都不会自动跳过行动。

### 14.4 业务规则大量依赖封装函数

虽然底层是统一 Buff 系统，但很多业务规则不在配置里，而在封装逻辑里，例如：

- 燃烧刷新不叠层
- 毒爆后清中毒
- 寒霜新星对已霜冻目标转冻结
- 雷暴对已标记者改为引爆并清标记

因此新增状态时要明确：

- 只是新增一个配置
- 还是要同步补技能标签或状态封装逻辑

---

## 15. 推荐阅读顺序

如果后续要继续改 Buff 系统，建议按这个顺序读代码：

1. `modules/battle_buff.lua`
2. `modules/battle_skill.lua`
3. `skills/battle_skill_status.lua`
4. `skills/skill_effect_registry.lua`
5. `skills/battle_skill_turn_hooks.lua`
6. `config/tables/buffs.lua` 与 `skills/buff_effect_registry.lua`
7. `ui/battle_visual_events.lua`

这样能最快看清：

- Buff 如何挂上去
- 什么时候触发
- 什么时候过期
- 前端拿到哪些数据
- 业务规则到底落在配置里还是脚本里
