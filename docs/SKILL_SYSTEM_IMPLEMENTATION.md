# 技能系统实现文档 (Timeline 版)

> **项目**: Mini Battle Simulator  
> **版本**: 2.0 (Timeline 架构)  
> **更新时间**: 2026-04-14  
> **说明**: 本文档描述技能系统迁移至 Timeline 执行体系后的实际实现

---

## 目录

1. [系统概述](#1-系统概述)
2. [Timeline 执行体系](#2-timeline-执行体系)
3. [技能配置三层架构](#3-技能配置三层架构)
4. [技能 ID 编码规则](#4-技能-id-编码规则)
5. [技能释放完整流程](#5-技能释放完整流程)
6. [技能脚本开发规范](#6-技能脚本开发规范)
7. [Buff 系统实现](#7-buff-系统实现)
8. [敌人技能体系](#8-敌人技能体系)
9. [视觉事件系统](#9-视觉事件系统)
10. [核心 API 清单](#10-核心-api-清单)

---

## 1. 系统概述

### 1.1 架构变迁

技能系统已从旧版 `actData` 关键帧 + `Execute` 分支模式，完全迁移至 **Timeline 执行体系**：

| 维度 | 旧版 | 新版 (Timeline) |
|------|------|-----------------|
| 执行入口 | `Execute` 函数 或 `actData` 关键帧 | `BuildTimeline` 函数 |
| 时序控制 | `TriggerS` 秒级时间戳 | `frame` 逻辑帧序号 |
| 伤害结算 | `DWCommon.DamageData` 字符串解析 | `CalculateDamageWithRate` 直接调用 |
| Buff 施加 | `DWCommon.LaunchBuff` 字符串解析 | `ApplyBuff` / `ApplyFreeze` / `ApplyFrost` 直接调用 |
| 表现解耦 | 逻辑与表现混合 | 逻辑帧结算 + 事件派发，表现层异步订阅 |

### 1.2 核心模块

| 模块 | 文件路径 | 职责 |
|------|----------|------|
| SkillTimeline | `core/skill_timeline.lua` | Timeline 执行引擎，排序帧序列、逐帧执行、派发事件 |
| BattleSkill | `modules/battle_skill.lua` | 技能系统主入口，管理技能实例、冷却、释放流程 |
| BattleVisualEvents | `ui/battle_visual_events.lua` | 视觉事件定义与数据构建器 |
| BattlePassiveSkill | `modules/battle_passive_skill.lua` | 被动技能注册、触发分发与运行时状态查询 |
| PassiveDefs | `config/tables/passives.lua` | 被动触发定义加载器，从 `config/data/passives.json` 读取触发表 |
| PassiveHandlers | `modules/passive_handlers.lua` | 被动处理器工厂，承载脚本型被动逻辑 |
| SkillConfig | `config/skill_config.lua` | 技能配置薄封装，转发到 `config/tables/skills.lua` |
| BattleHeroFactory | `modules/battle_hero_factory.lua` | 英雄/敌人工厂，含技能类型转换 |
| HeroData | `config/hero_data.lua` | 英雄属性与技能配置 |
| EnemyData | `config/enemy_data.lua` | 敌人属性与技能配置 |

---

## 2. Timeline 执行体系

### 2.1 核心概念

Timeline 体系将技能执行抽象为**逻辑帧序列**，每帧包含：
- `frame`: 帧序号（整数，按升序执行）
- `op`: 操作类型（cast/hit/damage/heal/buff/effect）
- `execute`: 帧执行函数，接收 `context` 和 `frameCopy` 两个参数

### 2.2 SkillTimeline.Execute 流程

```lua
function SkillTimeline.Execute(hero, targets, skill, timeline)
    -- 1. 克隆帧序列（避免污染原始定义）
    -- 2. 按 frame 升序排序
    -- 3. 派发 SKILL_TIMELINE_STARTED 事件
    -- 4. 逐帧执行 frame.execute(context, frameCopy)
    --    - pcall 保护执行
    --    - 累计 totalDamage / totalHeal
    --    - 派发 SKILL_TIMELINE_FRAME 事件
    -- 5. 派发 SKILL_TIMELINE_COMPLETED 事件
    -- 6. 返回 succeeded, result
end
```

### 2.3 帧事件类型

| op | 说明 | 典型操作 |
|----|------|----------|
| cast | 技能释放 | 派发 SKILL_CAST_STARTED，设置动画状态 |
| hit | 命中判定 | 判定闪避/格挡 |
| damage | 伤害结算 | 调用 CalculateDamageWithRate，派发 DAMAGE_DEALT |
| heal | 治疗结算 | 调用 CalculateHeal，派发 HEAL_RECEIVED |
| buff | Buff 施加 | 调用 ApplyBuff / ApplyFreeze / ApplyFrost，派发 BUFF_ADDED |
| effect | 特效触发 | 纯表现层事件，逻辑层无操作 |

### 2.4 Context 结构

```lua
context = {
    hero = hero,           -- 施法者
    targets = targets,     -- 目标列表
    skill = skill,         -- 技能实例
    timeline = frames,     -- 排序后的帧序列
    totalDamage = 0,       -- 累计伤害
    totalHeal = 0,         -- 累计治疗
}
```

---

## 3. 技能配置三层架构

每个技能由三层配置共同定义，必须保持一致：

### 3.1 JSON 静态配置 (`config/data/skills.json`)

```json
{
    "ID": 80007003,
    "Name": "爆炸火球",
    "Type": 2,
    "CoolDownR": 3,
    "Cost": 0,
    "SkillParam": [10000, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    "Buff1": [10000, 0, 2, 870001, 1]
}
```

| 字段 | 说明 |
|------|------|
| ID | 技能 ID，8位：`classId * 10 + level` |
| Type | 1=普攻, 2=主动, 3=大招, 4=被动 |
| CoolDownR | 冷却回合数 |
| Cost | 能量消耗（大招=100，其他=0） |
| SkillParam[1] | 伤害倍率（万分比，10000=100%） |
| Buff1-5 | [概率, 目标类型, 持续回合, BuffID, 叠加层数] |

### 3.2 Lua 技能脚本 (`config/skill/skill_{ID}.lua`)

```lua
local BattleSkill = require("modules.battle_skill")

local skill_80007003 = {}

function skill_80007003.BuildTimeline(hero, targets, skill)
    local timeline = {}
    table.insert(timeline, {
        frame = 0, op = "cast",
        execute = function(ctx, f)
            BattleEvent.Publish(BattleVisualEvents.SKILL_CAST_STARTED, ...)
        end
    })
    table.insert(timeline, {
        frame = 10, op = "damage",
        execute = function(ctx, f)
            for _, target in ipairs(ctx.targets) do
                local damage = BattleSkill.CalculateDamageWithRate(ctx.hero, target, 10000)
                BattleDmgHeal.ApplyDamage(target, damage, ctx.hero)
            end
        end
    })
    table.insert(timeline, {
        frame = 20, op = "buff",
        execute = function(ctx, f)
            for _, target in ipairs(ctx.targets) do
                BattleSkill.ApplyBuff(target, 870001, 2, ctx.hero)
            end
        end
    })
    return timeline
end

return skill_80007003
```

### 3.3 Buff 定义 (`config/data/buffs.json` + `skills/buff_effect_registry.lua`)

```json
[
  {"buffId":870001,"name":"燃烧","mainType":2,"subType":870001,"initialStack":1,"maxStack":1,"duration":2,"canStack":false,"stackRule":"refresh","effects":[{"type":"custom","handlerId":"burn_tick","timing":3}]}
]
```

```lua
local BuffEffectRegistry = {
    burn_tick = function(buff, hero)
        local stacks = math.max(1, tonumber(buff.stackCount) or 1)
        local diceExpr = string.format("%dd6", stacks)
        -- 当前工程实际用骰子表达持续伤害
                end
            }
        }
    },
}
```

### 3.4 三层一致性要求

| 参数 | JSON | Lua 脚本 | Buff 定义 |
|------|------|----------|-----------|
| 伤害倍率 | SkillParam[1] | CalculateDamageWithRate 参数 | - |
| Buff 持续 | Buff[3] | ApplyBuff 参数 | duration |
| Buff 叠加 | Buff[5] | ApplyBuff 参数 | canStack/maxStack |
| 冻结持续 | Buff[3] | ApplyFreeze 参数 | duration |
| 霜冻持续 | Buff[3] | ApplyFrost 参数 | duration |

**修改技能参数时，三层必须同步更新。**

---

## 4. 技能 ID 编码规则

```
actualSkillId = classId * 10 + level

classId 范围: 8000100 ~ 8000900 (九流派)
level 范围: 1~4 (普攻/被动/主动/大招)

示例:
  8000101 = 8000100 * 10 + 1  → 刺客 L1 普攻
  8000103 = 8000100 * 10 + 3  → 刺客 L3 主动
  8000704 = 8000700 * 10 + 4  → 火法 L4 大招
```

**禁止使用** `classId * 100 + level`（产生9位ID导致加载失败回退默认普攻）。

---

## 5. 技能释放完整流程

```
BattleMain.ExecuteHeroAction
  └─ SelectAvailableSkill(hero)
       ├─ 优先选择大招 (ULTIMATE, 能量≥100)
       ├─ 其次选择主动技能 (ACTIVE, CD=0)
       └─ 最后选择普攻 (NORMAL)
  └─ BattleSkill.CastSkillInSeq(hero, target, skillId)
       ├─ 检查技能条件 (CD, 能量, 沉默等)
       ├─ BattleSkill.SelectTarget(hero, skill)
       ├─ BattleSkill.LoadSkillLua(skillId)
       │    └─ require("config.skill.skill_{ID}")
       ├─ skillScript.BuildTimeline(hero, targets, skill)
       ├─ SkillTimeline.Execute(hero, targets, skill, timeline)
       │    ├─ 排序帧序列
       │    ├─ 逐帧执行
       │    └─ 派发视觉事件
       ├─ 扣除能量 / 设置冷却
       └─ 返回执行结果
```

---

## 6. 技能脚本开发规范

### 6.1 必须实现 BuildTimeline

所有技能脚本必须实现 `BuildTimeline(hero, targets, skill)` 函数，返回帧数组。

### 6.2 禁止使用 Execute

旧版 `Execute` 分支已移除，`CastSkillInSeq` 仅处理 `BuildTimeline` 结果。

### 6.3 帧序号约定

| 帧范围 | 用途 |
|--------|------|
| 0 | cast 释放 |
| 5-10 | hit 命中判定 |
| 10-20 | damage 伤害结算 |
| 20-30 | buff 施加 |
| 30+ | effect 特效 / 后续效果 |

### 6.4 伤害计算 API

```lua
-- 标准伤害计算
local damage = BattleSkill.CalculateDamageWithRate(attacker, target, damageRate)
-- damageRate: 万分比，10000 = 100%

-- 治疗计算
local healAmount = BattleSkill.CalculateHeal(healer, target, healRate)

-- 施加 Buff
BattleSkill.ApplyBuff(target, buffId, duration, caster)

-- 施加冻结
BattleSkill.ApplyFreeze(target, duration, chance, caster)

-- 施加霜冻
BattleSkillStatus.ApplyFrost(target, duration, caster)
```

---

## 6.5 被动技能统一框架

### 6.5.1 架构说明

被动技能已从旧版 `event_*.lua + war_*.lua` 双文件模式，整合为统一框架：

| 层级 | 文件 | 职责 |
|------|------|------|
| 被动定义 | `config/tables/passives.lua` | 被动定义加载器，负责把 `config/data/passives.json` 转成运行时触发表 |
| 被动逻辑 | `modules/passive_handlers.lua` | 实现被动处理器工厂，返回具名回调对象 |
| 调度入口 | `modules/battle_passive_skill.lua` | 注册触发器、派发回调、维护 `hero.passiveRuntime` |

### 6.5.2 被动定义格式

```lua
local PassiveDefs = {
    [8000300] = {
        triggers = {
            {
                luaFuncName = "OnBattleBegin",
                triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME.BattleBegin,
            },
        },
    },
}
```

### 6.5.3 处理器格式

```lua
local function CreateComboMasterPassive(context)
    local self = BuildContextState(context)

    function self:OnBattleBegin(ctx)
        local hero = self.context and self.context.src or nil
        if not hero or hero.isDead then
            return
        end
        hero.passiveRuntime = hero.passiveRuntime or {}
        hero.passiveRuntime.comboMasterMinRate = 5000
    end

    return self
end
```

### 6.5.4 运行时状态

统一框架允许被动将数值状态写入 `hero.passiveRuntime`，供主动技能和通用结算逻辑读取：

| key | 说明 | 来源 |
|-----|------|------|
| `comboMasterMinRate` | 连击精通的最低连击概率 | `8000300` |
| `iceDamageBonusPct` | 冰系伤害加成 | `8000800` |
| `iceFreezeChanceBonus` | 冰系冻结概率加成 | `8000800` |
| `thunderChainChanceBonus` | 雷系连锁概率加成 | `8000900` |
| `thunderChainDecayReductionPct` | 雷系弹射衰减减免预留值 | `8000900` |

读取统一通过：

```lua
local minRate = BattlePassiveSkill.GetPassiveValue(hero, "comboMasterMinRate", 0)
local chance = BattleSkill.GetPassiveAdjustedChance(hero, 5000, "iceFreezeChanceBonus")
```

### 6.5.5 当前被动分类

| ClassID | 名称 | 类型 | 框架状态 |
|---------|------|------|----------|
| 8000020 | 格挡 | 脚本型 | 已接入统一 handler |
| 8000100 | 追击 | 脚本型 | 已接入统一 handler |
| 8000200 | 格挡/反击 | 脚本型 | 已接入统一 handler |
| 8000300 | 连击精通 | 运行时状态型 | 已接入统一 handler |
| 8000400 | 战意 | 脚本型 | 已接入统一 handler |
| 8000500 | 感染 | 脚本型 | 已接入统一 handler |
| 8000600 | 亲和 | 脚本型 | 已接入统一 handler |
| 8000700 | 火焰亲和 | 脚本型 | 已接入统一 handler |
| 8000800 | 寒冰亲和 | 运行时状态型 | 已接入统一 handler |
| 8000900 | 雷电亲和 | 运行时状态型 | 已接入统一 handler |

---

## 7. Buff 系统实现

### 7.1 文档归档说明

本章不再维护 Buff 系统的完整实现细节。

原因：

- Buff 系统已经独立演进，状态配置、生命周期、控制判定、前端事件与旧版技能文档存在分叉风险
- 旧版这里的部分表格与描述已经不是当前源码现状，例如历史上的百分比 DoT、旧持续时间与旧姿态效果

当前请统一以新文档为准：

- [BUFF_SYSTEM_IMPLEMENTATION.md](file:///c:/work/MiniBattleSimulator/docs/BUFF_SYSTEM_IMPLEMENTATION.md)

### 7.2 技能系统视角下的 Buff 要点

从技能系统角度，只需要掌握以下几点：

- Buff 统一通过 `BattleSkill.ApplyBuffFromSkill(caster, target, buffId, skill, override)` 施加
- Buff 静态配置统一放在 `config/data/buffs.json`，运行时通过 `config/tables/buffs.lua` 加载并按 `buffId` 索引
- Timeline 技能优先通过 `skills/skill_effect_registry.lua` 中的标签复用已有状态逻辑
- 中毒、燃烧、冻结、霜冻、静电印记等常见状态封装在 `skills/battle_skill_status.lua`
- 回合开始由 `BattleSkillTurnHooks.ProcessTurnStartStatus()` 触发 `OnRoundBegin` 与控制判定
- 回合结束由 `BattleMain.FinalizeHeroTurn()` 触发 `OnRoundEnd`、持续时间递减与过期移除

### 7.3 当前开发约定

涉及技能与 Buff 联动时，优先遵守以下约定：

- 不要在技能文档中重复维护完整 Buff 清单，避免与独立 Buff 文档冲突
- 修改状态行为时，应同时检查：
  - `config/tables/buffs.lua` 与 `skills/buff_effect_registry.lua`
  - `skills/battle_skill_status.lua` 中的封装逻辑
  - `skills/skill_effect_registry.lua` 中的 Timeline 标签行为
  - `ui/battle_visual_events.lua` 中的前端事件数据
- 控制类状态是否阻断行动，不以名称判断，而以 `mainType == CONTROL` 或控制子类型集合为准
- 当前 `speed` 虽然会读取部分 Buff 数值，但战斗中行动条仍按等速推进；不要把减速直接理解为“减少出手次数”

### 7.4 常用交叉引用

| 主题 | 参考文档 |
|------|----------|
| Buff 核心结构与生命周期 | [BUFF_SYSTEM_IMPLEMENTATION.md](file:///c:/work/MiniBattleSimulator/docs/BUFF_SYSTEM_IMPLEMENTATION.md) |
| 技能 Timeline 架构 | 当前文档第 2 节至第 6 节 |
| 视觉事件系统 | 当前文档第 9 节 |

---

## 8. 敌人技能体系

### 8.1 敌人技能来源

敌人使用与英雄相同的九流派技能脚本，通过 `EnemyData.ConvertToHeroData` 分配技能。

### 8.2 敌人技能类型映射

`BattleHeroFactory.CreateEnemy` 中的类型转换规则：

| 原始 skillType | 条件 | 映射结果 |
|----------------|------|----------|
| PASSIVE (4) | - | 保持 PASSIVE |
| ACTIVE (2) | - | 保持 ACTIVE |
| 3 或 skillCost>0 | - | ULTIMATE (3) |
| 其他 | - | NORMAL (1) |

### 8.3 敌人属性成长

```lua
-- 成长率（比英雄高约2倍）
hpGrowthRate  = 0.12 + quality * 0.015
atkGrowthRate = 0.095 + quality * 0.012
defGrowthRate = 0.075 + quality * 0.010

-- 乘法叠加
qualityMultipliers = {1.0, 1.06, 1.12, 1.18, 1.26, 1.34}
typeMultipliers = {[0]=1.0, [1]=1.15, [2]=1.35}  -- 普通/Elite/BOSS
starMultiplier = 1.0 + (star-1) * 0.15

totalMultiplier = qualityMultiplier * typeMultiplier * starMultiplier
atkMultiplier = 1.0 + (totalMultiplier - 1.0) * 0.45  -- ATK 衰减系数

hp  = (baseHp + hpGrowth) * totalMultiplier
atk = (baseAtk + atkGrowth) * atkMultiplier
def = (baseDef + defGrowth) * totalMultiplier
```

---

## 9. 视觉事件系统

### 9.1 事件类型

| 事件常量 | 说明 |
|----------|------|
| SKILL_TIMELINE_STARTED | Timeline 开始执行 |
| SKILL_TIMELINE_FRAME | 帧执行完成 |
| SKILL_TIMELINE_COMPLETED | Timeline 执行完成 |
| SKILL_CAST_STARTED | 技能释放开始 |
| SKILL_CAST_COMPLETED | 技能释放完成 |
| DAMAGE_DEALT | 伤害事件 |
| HEAL_RECEIVED | 治疗事件 |
| BUFF_ADDED | Buff 添加 |
| BUFF_REMOVED | Buff 移除 |
| HERO_STATE_CHANGED | 英雄状态变化 |
| TURN_STARTED | 回合开始 |
| TURN_ENDED | 回合结束 |
| HERO_DIED | 英雄阵亡 |
| ENERGY_CHANGED | 能量变化 |

### 9.2 渲染后端订阅

不同渲染后端（Console/Web/Unity）订阅 `BattleVisualEvents` 事件，用自己的方式呈现战斗画面。逻辑层与表现层完全解耦。

---

## 10. 核心 API 清单

### 10.1 BattleSkill

| 函数 | 说明 |
|------|------|
| `Init(hero, skillsConfig)` | 初始化英雄技能 |
| `CastSkillInSeq(hero, target, skillId)` | 释放技能（Timeline 路径） |
| `SelectAvailableSkill(hero)` | 选择可用技能（大招→主动→普攻） |
| `SelectTarget(hero, skill)` | 选择技能目标 |
| `LoadSkillLua(skillId)` | 加载技能 Lua 脚本 |
| `CalculateDamageWithRate(attacker, target, rate)` | 计算伤害 |
| `CalculateHeal(healer, target, rate)` | 计算治疗量 |
| `GetPassiveAdjustedRate(hero, baseRate, passiveKey)` | 读取统一被动状态并调整倍率 |
| `GetPassiveAdjustedChance(hero, baseChance, passiveKey)` | 读取统一被动状态并调整概率 |
| `ApplyBuff(target, buffId, duration, caster)` | 施加 Buff |
| `ApplyFreeze(target, duration, chance, caster)` | 施加冻结 |
| `BattleSkillStatus.ApplyFrost(target, duration, caster)` | 施加霜冻 |
| `GetSkillCurCoolDown(hero, skillId)` | 获取技能冷却 |
| `SetSkillCurCoolDown(hero, skillId, cd)` | 设置技能冷却 |
| `GetHeroSkills(hero)` | 获取英雄所有技能 |
| `GetSkillsByType(hero, skillType)` | 按类型获取技能 |

### 10.2 SkillTimeline

| 函数 | 说明 |
|------|------|
| `Execute(hero, targets, skill, timeline)` | 执行 Timeline 帧序列 |

### 10.3 BattlePassiveSkill

| 函数 | 说明 |
|------|------|
| `RegisterHeroSkills(hero)` | 注册英雄被动触发器 |
| `RunSkillOnBattleBegin()` | 触发战斗开始类被动 |
| `RunSkillOnSelfTurnBegin(hero)` | 触发自身回合开始被动 |
| `RunSkillOnSelfTurnEnd(hero)` | 触发自身回合结束被动 |
| `GetPassiveValue(hero, key, defaultValue)` | 读取统一被动运行时状态 |

### 10.4 BattleDmgHeal

| 函数 | 说明 |
|------|------|
| `ApplyDamage(target, damage, attacker)` | 施加伤害 |
| `ApplyHeal(target, amount, healer)` | 施加治疗 |

---

*文档结束*



