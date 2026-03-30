# Mini Battle Simulator - Quick Reference

快速参考手册，供所有 Agent 查阅。

---

## 📁 项目结构

```
mini-battle-simulator/
├── core/                   # 核心层（改动前需Producer确认）
│   ├── battle_formula.lua  # 伤害/治疗公式
│   ├── battle_enum.lua     # 枚举定义
│   └── battle_event.lua    # 事件系统
├── modules/                # 模块层（主要工作区）
│   ├── battle_main.lua     # 战斗入口
│   ├── battle_skill.lua    # 技能执行
│   ├── battle_buff.lua     # Buff管理
│   ├── battle_ai.lua       # AI决策
│   ├── battle_formation.lua# 阵型计算
│   └── ...
├── config/                 # 配置层
│   ├── skill/              # 技能脚本
│   ├── buff/               # Buff脚本
│   ├── res_skill.json      # 技能基础数据
│   └── res_buff_template.json # Buff模板
├── design/                 # 设计文档
│   ├── skill.md            # 技能树设计
│   ├── 战斗系统机制.md      # 核心机制
│   ├── 技能配置指南.md      # 技能配置
│   ├── Buff配置指南.md      # Buff配置
│   └── 实体与阵型配置.md    # 实体配置
└── ui/                     # 表现层（通过事件通信）
    └── console_renderer.lua
```

---

## 🔢 常用枚举

### 技能类型 (`E_SKILL_TYPE`)
| 值 | 类型 | 说明 |
|----|------|------|
| 1 | NORMAL | 普攻（无CD无消耗）|
| 2 | ACTIVE | 主动技（受CD限制）|
| 3 | ULTIMATE | 大招（受能量限制）|
| 4 | PASSIVE | 被动技 |

### Buff触发时机 (`E_BUFF_TIMING`)
| 值 | 时机 | 典型用途 |
|----|------|----------|
| 1 | ON_ADD | 获得时一次性效果 |
| 2 | ON_REMOVE | 移除时触发 |
| 3 | ON_ROUND_BEGIN | 回合开始 | HOT/回能 |
| 4 | ON_ROUND_END | 回合结束 | DOT/毒伤 |
| 5 | ON_ATTACK | 攻击时 |
| 6 | ON_DEFEND | 受击时 |
| 7 | ON_DAMAGE | 造成伤害 | 吸血 |
| 8 | ON_RECEIVE_DAMAGE | 受到伤害 | 反伤 |
| 11 | ON_KILL | 击杀目标 |
| 12 | ON_DEATH | 自身死亡 |

### 属性ID (`E_ATTR`)
| ID | 属性 | ID | 属性 |
|----|------|----|------|
| 1 | HP | 2 | ATK |
| 3 | DEF | 4 | SPEED |
| 5 | CRIT_RATE | 6 | CRIT_DMG |
| 7 | HIT_RATE | 8 | DODGE_RATE |
| 9 | DMG_REDUCE | 10 | DMG_INCREASE |

### 目标阵营 (`castTarget`)
| 值 | 目标 |
|----|------|
| 0 | 自身 |
| 1 | 友方全体 |
| 2 | 敌方全体 |
| 3 | 除自己外的友方 |
| 4 | 全场所有人 |

---

## ⚡ API速查

### 伤害/治疗
```lua
-- 标准伤害
BattleFormula.CalcDamage(attacker, defender, rate, skill)
-- rate: 万分比 (15000 = 150%)

-- 真实伤害（无视防御）
BattleScriptExp.MakeDmgReal(attacker, target, value)

-- 治疗
BattleFormula.CalcHeal(caster, target, rate, skill)
```

### 目标查找
```lua
-- 获取存活敌人
BattleFormation.GetAliveEnemies(caster)

-- 按属性排序找目标
BattleScriptExp.GetFriendSortByAttrId(caster, attrId, ascending)
-- attrId: 1=HP, 2=ATK, 3=DEF, 4=SPEED

-- 获取当前回合
BattleMain.GetCurrentRound()
```

### 状态操作
```lua
-- 插入临时被动
BattleScriptExp.InsertPassiveSkill(caster, target, skillId, funcName, timing, once)

-- 自定义变量（跨回合）
BattleScriptExp.SetCustomValue(hero, key, value)
BattleScriptExp.GetCustomValue(hero, key)

-- 修改属性（万分比）
BattleScriptExp.ModifyAttribute(hero, attrId, value)
```

---

## 📝 配置模板

### 技能脚本 (`config/skill/skill_{ID}.lua`)
```lua
local skill_100001 = {
    targetsSelections = {
        castTarget = 2,  -- 敌方
        tSConditions = { Num = 3, wpType = 1 },  -- 前排3个
        tSFilter = { type = "HP_LOWEST" }        -- 血量最低
    },
    
    actData = {
        {
            atLeastTimeS = 2.0,
            keyFrameDatas = {
                { TriggerS = 0.5, datatype = "DWCommon.DamageData", data = "{ damageRate = 15000 }" },
                { TriggerS = 1.0, datatype = "DWCommon.LaunchBuff", data = "{ buffId = 9001 }" },
            }
        }
    }
}

-- 可选：完全接管
function skill_100001.Execute(hero, targets, skill)
    -- 自定义逻辑
    return true
end

return skill_100001
```

### Buff脚本 (`config/buff/buff_{ID}.lua`)
```lua
local buff_9001 = {
    stackRule = "refresh",  -- refresh/add/independent
    
    effects = {
        -- DOT：回合结束50%伤害
        { type = "damage", timing = 4, value = 5000, damageType = 2 },
        
        -- HOT：回合开始恢复10%生命
        { type = "heal", timing = 3, percent = 1000 },
        
        -- 自定义
        { type = "custom", timing = 12, func = function(buff, hero, effect)
            -- 死亡时触发
        end }
    }
}

return buff_9001
```

---

## ⚠️ 编码规范

| 规则 | 说明 |
|------|------|
| 函数长度 | ≤50行 |
| 变量 | 全`local`化，禁止全局变量 |
| 返回 | 显式`return`，不依赖隐式返回 |
| 注解 | 复杂函数加 EmmyLua 注解 |
| 校验 | 输入校验，快速失败 |

---

## 📊 数值公式

### 伤害公式
```
基础伤害 = (ATK - DEF) * rate / 10000
最终伤害 = 基础伤害 * (1 + 增伤/10000) * (1 - 减伤/10000)
```
保底伤害：1点

### 治疗公式
```
治疗量 = ATK * rate / 10000 * (1 + 治疗加成/10000)
```
随机浮动：±10%

### 能量机制
- 初始：15点
- 上限：100点
- 大招消耗：100点
- 获取：普攻/受击回能

---

## 🔗 相关文档

- [skill.md](design/skill.md) - 技能树设计
- [战斗系统机制.md](design/战斗系统机制.md) - 核心机制
- [技能配置指南.md](design/技能配置指南.md) - 技能配置
- [Buff配置指南.md](design/Buff配置指南.md) - Buff配置
- [实体与阵型配置.md](design/实体与阵型配置.md) - 实体配置

---

*Last updated: 2026-03-30*
