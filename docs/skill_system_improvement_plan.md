# 技能系统功能补充计划

## 当前实现状态

### 已实现功能 ✅

1. **基础技能系统**
   - 技能数据解析（DamageData, HealData, LaunchBuff, LaunchSpell）
   - SkillExecutor统一执行器
   - 单体攻击和范围攻击(AOE)
   - 347个技能Lua文件
   - 154个法术Lua文件

2. **被动技能系统**
   - BattlePassiveSkill模块（完整实现）
   - 20种触发时机（战斗开始、回合开始、行动开始、HP变化等）
   - 已集成到战斗主循环

3. **Buff系统**
   - 240个Buff配置
   - Buff添加、移除、效果应用
   - 回合结束Buff持续时间减少

4. **伤害计算**
   - 使用原工程公式
   - 攻击力、防御力、暴击、格挡等

### 需要完善的功能 ⚠️

1. **技能冷却系统**
   - 框架已存在（BattleSkill.coolDowns）
   - 但战斗流程中未实际应用
   - 需要：回合结束时减少冷却、选择技能时检查冷却

2. **能量系统**
   - BattleEnergy模块已存在
   - 但技能释放时未检查能量消耗
   - 需要：释放技能时扣除能量、能量不足时不能使用大招

3. **被动技能效果执行**
   - 框架已存在
   - 但实际效果执行需要完善
   - 需要：根据配置执行伤害、治疗、Buff等效果

4. **技能连招系统**
   - 尚未实现
   - 需要：技能序列配置、连招触发条件

5. **技能打断机制**
   - 尚未实现
   - 需要：打断条件判断、打断后处理

## 实施计划

### 阶段1：冷却系统和能量系统完善（高优先级）

1. 在战斗回合结束时减少所有技能冷却
2. 选择技能时检查冷却时间
3. 释放技能时扣除能量
4. 能量不足时只能使用普通攻击

### 阶段2：被动技能效果执行（高优先级）

1. 解析被动技能配置
2. 根据触发时机执行效果
3. 支持伤害、治疗、Buff等效果

### 阶段3：技能连招系统（中优先级）

1. 设计连招配置格式
2. 实现连招触发检测
3. 连招技能自动释放

### 阶段4：技能打断机制（中优先级）

1. 设计打断条件
2. 实现打断检测
3. 打断后状态恢复

## 技术细节

### 冷却系统实现

```lua
-- 在回合结束时调用
BattleSkill.ReduceCooldown(hero, 1)

-- 选择技能时检查
if BattleSkill.GetCooldown(hero, skillId) > 0 then
    -- 技能在冷却中，不能使用
end

-- 释放技能后设置冷却
BattleSkill.SetCooldown(hero, skillId, skill.maxCoolDown)
```

### 能量系统实现

```lua
-- 释放技能前检查能量
if hero.curEnergy < skill.energyCost then
    -- 能量不足，使用普通攻击
end

-- 释放技能后扣除能量
hero.curEnergy = hero.curEnergy - skill.energyCost
```

### 被动技能效果执行

```lua
-- 在BattlePassiveSkill.Trigger中执行效果
for _, effect in ipairs(skill.effects) do
    if effect.type == "damage" then
        -- 执行伤害
    elseif effect.type == "heal" then
        -- 执行治疗
    elseif effect.type == "buff" then
        -- 添加Buff
    end
end
```

## 测试计划

1. 测试冷却系统：连续释放同一技能，检查冷却是否正常
2. 测试能量系统：能量不足时尝试释放大招
3. 测试被动技能：触发各种条件，验证被动效果
4. 测试完整战斗：62回合战斗，验证所有系统协同工作
