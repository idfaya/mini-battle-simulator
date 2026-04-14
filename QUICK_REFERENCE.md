# Mini Battle Simulator - Quick Reference

快速参考手册，供所有 Agent 查阅。

---

## 📁 项目结构

```
mini-battle-simulator/
├── core/                   # 核心层
│   ├── battle_formula.lua  # 伤害/治疗公式
│   ├── battle_enum.lua     # 枚举定义
│   ├── battle_event.lua    # 事件系统
│   └── skill_timeline.lua  # Timeline 执行引擎
├── modules/                # 模块层（主要工作区）
│   ├── battle_main.lua     # 战斗主流程
│   ├── battle_skill.lua    # 技能执行（CastSkillInSeq）
│   ├── battle_buff.lua     # Buff管理
│   ├── battle_dmg_heal.lua # 伤害/治疗结算
│   ├── battle_hero_factory.lua  # 英雄/敌人工厂
│   ├── battle_driver.lua   # 战斗驱动器
│   ├── skill_timeline.lua  # Timeline 执行（模块层封装）
│   └── battle_visual_events.lua # 视觉事件定义
├── config/                 # 配置层
│   ├── skill/              # 技能 Timeline 脚本（BuildTimeline）
│   ├── passive/            # 被动定义表（PassiveDefs）
│   ├── buff/               # Buff 定义脚本
│   ├── res_skill.json      # 技能静态数据
│   ├── res_hero.json       # 英雄基础数据
│   ├── skill_config.lua    # 技能配置加载器
│   ├── hero_data.lua       # 英雄属性与技能配置
│   └── enemy_data.lua      # 敌人属性与技能配置
├── design/                 # 设计文档
│   ├── skill.md            # 技能树设计（九流派4层）
│   ├── 战斗系统机制.md      # 核心机制与属性成长
│   └── web-visualization-plan.md  # Web 可视化方案
├── docs/                   # 实现文档
│   └── SKILL_SYSTEM_IMPLEMENTATION.md  # 技能系统实现（Timeline版）
└── ui/                     # 表现层（通过事件通信）
    └── viewport_renderer.lua
```

---

## 🔢 常用枚举

### 技能类型 (`E_SKILL_TYPE`)
| 值 | 类型 | 说明 |
|----|------|------|
| 1 | NORMAL | 普攻（无CD无消耗，回复20能量）|
| 2 | ACTIVE | 主动技（CD 2~3回合，不耗能量）|
| 3 | ULTIMATE | 大招（无CD，消耗100能量）|
| 4 | PASSIVE | 被动技（常驻生效）|

### Buff触发时机 (`E_BUFF_TIMING`)
| 值 | 时机 | 典型用途 |
|----|------|----------|
| 1 | ON_ADD | 获得时一次性效果 |
| 2 | ON_REMOVE | 移除时触发 |
| 3 | ON_ROUND_BEGIN | 回合开始 | DOT/HOT |
| 4 | ON_ROUND_END | 回合结束 |
| 5 | ON_ATTACK | 攻击时 |
| 6 | ON_DEFEND | 受击时 |
| 7 | ON_DAMAGE | 造成伤害 |
| 8 | ON_RECEIVE_DAMAGE | 受到伤害 |
| 11 | ON_KILL | 击杀目标 |
| 12 | ON_DEATH | 自身死亡 |

### 属性ID (`E_ATTR`)
| ID | 属性 | ID | 属性 |
|----|------|----|------|
| 1 | HP | 2 | ATK |
| 3 | DEF | 4 | SPEED |
| 5 | CRIT_RATE | 6 | CRIT_DMG |

---

## ⚡ API速查

### 伤害/治疗
```lua
-- 标准伤害计算（万分比）
local damage = BattleSkill.CalculateDamageWithRate(attacker, target, 10000)

-- 施加伤害
BattleDmgHeal.ApplyDamage(target, damage, attacker)

-- 治疗计算
local healAmount = BattleSkill.CalculateHeal(healer, target, 10000)

-- 施加治疗
BattleDmgHeal.ApplyHeal(target, amount, healer)
```

### Buff 操作
```lua
-- 施加 Buff
BattleSkill.ApplyBuff(target, buffId, duration, caster)

-- 施加冻结
BattleSkill.ApplyFreeze(target, duration, chance, caster)
```

### 技能释放
```lua
-- 释放技能（Timeline 路径）
BattleSkill.CastSkillInSeq(hero, target, skillId)

-- 选择可用技能（大招→主动→普攻）
local skillId = BattleSkill.SelectAvailableSkill(hero)

-- 加载技能 Lua 脚本
local script = BattleSkill.LoadSkillLua(skillId)
```

### 被动框架
```lua
-- 读取统一被动运行时状态
local minRate = BattlePassiveSkill.GetPassiveValue(hero, "comboMasterMinRate", 0)

-- 按被动态修正概率/倍率
local chance = BattleSkill.GetPassiveAdjustedChance(hero, 5000, "iceFreezeChanceBonus")
local rate = BattleSkill.GetPassiveAdjustedRate(hero, 10000, "iceDamageBonusPct")
```

### 被动目录
```lua
config/passive/passive_defs.lua     -- classId -> triggers
modules/passive_handlers.lua        -- 被动逻辑工厂
modules/battle_passive_skill.lua    -- 注册/分发/查询入口
```

---

## 📝 配置模板

### 技能脚本 (`config/skill/skill_{ID}.lua`)
```lua
local BattleSkill = require("modules.battle_skill")
local BattleDmgHeal = require("modules.battle_dmg_heal")
local BattleEvent = require("core.battle_event")
local BattleVisualEvents = require("modules.battle_visual_events")

local skill_80007003 = {}

function skill_80007003.BuildTimeline(hero, targets, skill)
    local timeline = {}
    table.insert(timeline, {
        frame = 0, op = "cast",
        execute = function(ctx, f)
            BattleEvent.Publish(BattleVisualEvents.SKILL_CAST_STARTED, {
                hero = ctx.hero, skillId = skill.id, targets = ctx.targets
            })
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

### Buff脚本 (`config/buff/buff_{ID}.lua`)
```lua
local buff_870001 = {
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
                local damage = math.max(1, math.floor((hero.maxHp or 0) * 0.05 * buff.stackCount))
                BattleDmgHeal.ApplyDamage(hero, damage, buff.caster or hero)
            end
        }
    }
}

return buff_870001
```

---

## 📊 数值公式

### 伤害公式
```
基础伤害 = (ATK - DEF) * damageRate / 10000
保底伤害 = 1
```

### 治疗公式
```
治疗量 = ATK * healRate / 10000
```

### 能量机制
- 初始：0点
- 上限：100点
- 大招消耗：100点
- 获取：每回合 +20

### 技能 ID 编码
```
actualSkillId = classId * 10 + level
```
禁止 `classId * 100 + level`（9位ID导致加载失败）

---

## 🔗 相关文档

- [skill.md](design/skill.md) - 技能树设计
- [战斗系统机制.md](design/战斗系统机制.md) - 核心机制
- [SKILL_SYSTEM_IMPLEMENTATION.md](docs/SKILL_SYSTEM_IMPLEMENTATION.md) - 技能系统实现

---

*Last updated: 2026-04-10*
