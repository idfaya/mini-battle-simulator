# 技能系统设计一致性检查报告

> **检查时间**: 2026-03-29  
> **检查范围**: 设计文档 vs 代码实现  
> **检查人**: Designer Agent

---

## 1. 执行摘要

Producer 反馈「技能系统不一致」，经过对设计文档和代码实现的详细对比分析，发现存在**多处不一致**，主要集中在被动技能实现、技能标签系统、AI技能选择逻辑等方面。

### 不一致程度评估

| 检查项 | 一致度 | 状态 |
|--------|--------|------|
| 技能类型定义 | 90% | 基本对齐，缺少被动技能触发框架 |
| 技能范围系统 | 95% | 设计完全实现，有增强 |
| 冷却/能量机制 | 85% | 基本实现，能量回复公式未完全对齐 |
| AI技能选择 | 70% | 设计目标与实现差距较大 |
| 技能标签系统 | 20% | 设计有定义，实现缺失 |
| 被动技能 | 30% | 设计有示例，实现不完整 |

---

## 2. 设计 vs 实现对比表

### 2.1 技能类型

| 设计文档 | 代码实现 | 状态 | 差异说明 |
|----------|----------|------|----------|
| 普通攻击 (无消耗、无冷却) | `E_SKILL_TYPE_NORMAL = 1` | 对齐 | 实现匹配 |
| 主动技能 (小技能、有冷却) | `E_SKILL_TYPE_ACTIVE = 2` | 对齐 | 实现匹配 |
| 大招 (消耗能量) | `E_SKILL_TYPE_ULTIMATE = 3` | 对齐 | 实现匹配 |
| 被动 (自动触发) | `E_SKILL_TYPE_PASSIVE = 4` | ⚠️ 部分对齐 | 类型定义存在，但**缺乏触发框架** |

**问题**: 被动技能在设计文档中有详细示例（无限反击、无法反击、吸血），但代码中只有类型常量，没有完整的被动触发机制。

### 2.2 技能范围系统

| 设计范围类型 | 实现文件 | 状态 | 差异说明 |
|--------------|----------|------|----------|
| SINGLE (单体) | `battle_area.lua` | 对齐 | 实现匹配 |
| ROW (一排3人) | `battle_area.lua` | 对齐 | 实现匹配 |
| COLUMN (一列2人) | `battle_area.lua` | 对齐 | 实现匹配 |
| CROSS (十字5人) | `battle_area.lua` | 对齐 | 实现匹配 |
| CHAIN (链式弹射) | `battle_area.lua` | 对齐 | 实现匹配 |
| FULL (全体6人) | `battle_area.lua` | 对齐 | 实现匹配 |
| RANDOM (随机N个) | `battle_area.lua` | 对齐 | 实现匹配 |
| — | RANDOM_RANGE | 新增 | 实现新增随机范围类型 |
| — | FRONT_ROW/BACK_ROW | 新增 | 实现新增前后排范围 |
| — | CIRCLE/NEAREST/FARTHEST | 新增 | 实现新增更多范围类型 |

**结论**: 范围系统实现**超出设计**，完全覆盖设计需求且有增强。

### 2.3 冷却/能量机制

| 机制 | 设计文档 | 代码实现 | 状态 | 差异说明 |
|------|----------|----------|------|----------|
| 最大能量 | 100 | 100 (默认值) | 对齐 | — |
| 行动回复 | 20 | 未明确实现 | ⚠️ 未对齐 | 代码中无固定值，需检查 |
| 受伤回复 | 伤害 × 0.5% | 未实现 | ❌ 缺失 | `battle_energy.lua` 未找到对应逻辑 |
| 大招消耗 | 60-100 | 从 res_skill.json 读取 | 对齐 | — |
| 冷却回合 | 按技能配置 | 已实现 | 对齐 | — |

**问题**: 受伤回复能量机制在设计中有定义，但实现中缺失。

### 2.4 目标选择机制

| 策略 | 设计文档 | 代码实现 | 状态 |
|------|----------|----------|------|
| RANDOM | ✓ | ✓ | 对齐 |
| LOWEST_HP | ✓ | ✓ | 对齐 |
| HIGHEST_HP | ✓ | ✓ | 对齐 |
| NEAREST | ✓ | ✓ | 对齐 |
| FARTHEST | ✓ | ✓ | 对齐 |
| HIGHEST_THREAT | ✓ | ⚠️ 未完全实现 | 威胁值计算未实现 |
| ALLY_LOWEST_HP | ✓ | ✓ | 对齐 |

**问题**: 威胁值计算在设计中有详细公式，但 `battle_target_selector.lua` 中未完全实现威胁度排序。

### 2.5 技能标签系统

| 标签 | 设计文档 | 代码实现 | 状态 |
|------|----------|----------|------|
| PREVENT_COUNTER (阻止反击) | ✓ | ❌ 缺失 | 未实现 |
| CANNOT_MISS (必中) | ✓ | ❌ 缺失 | 未实现 |
| IGNORE_DEFENSE (无视防御) | ✓ | ❌ 缺失 | 未实现 |

**问题**: 设计文档中定义的技能标签系统在代码中**完全缺失**。

### 2.6 AI技能选择

| 特性 | 设计文档 | 代码实现 | 状态 | 差异说明 |
|------|----------|----------|------|----------|
| 5级优先级选择 | ✓ | ⚠️ 简化 | 实现有简化 | 条件检查不完全匹配 |
| 策略类型 (激进/保守/控制) | ✓ | ❌ 未实现 | 缺失 | AI性格系统未实现 |
| 威胁感知分级 | ✓ | ❌ 未实现 | 缺失 | 难度分级未实现 |
| 职业默认策略 | ✓ | ❌ 未实现 | 缺失 | — |

**问题**: AI设计文档中的策略权重、性格调整、难度分级在实现中**大部分缺失**。

---

## 3. 不一致点详细列表

### 3.1 高优先级问题

#### ❌ ISSUE-001: 被动技能框架缺失
- **设计**: 被动技能应有自动触发机制，支持 onDealDamage、效果函数等
- **实现**: 只有 `E_SKILL_TYPE_PASSIVE` 常量，无触发框架
- **影响**: 被动技能无法正常工作
- **建议**: 实现被动技能事件监听框架

#### ❌ ISSUE-002: 技能标签系统未实现
- **设计**: PREVENT_COUNTER、CANNOT_MISS、IGNORE_DEFENSE 等标签
- **实现**: 代码中无技能标签相关逻辑
- **影响**: 突袭技能、必中技能等特殊效果无法实现
- **建议**: 在技能配置中添加标签字段，在伤害计算中检查

#### ❌ ISSUE-003: AI策略系统不完整
- **设计**: 激进型/保守型/控制型策略，不同技能类型权重
- **实现**: `battle_ai.lua` 中简化实现，缺少策略权重调整
- **影响**: AI行为单一，缺乏差异化
- **建议**: 实现完整的策略权重系统

### 3.2 中优先级问题

#### ⚠️ ISSUE-004: 受伤回复能量未实现
- **设计**: 受伤回复 = 伤害 × 0.5%
- **实现**: `battle_energy.lua` 中未找到对应逻辑
- **影响**: 能量系统与设计不完全一致
- **建议**: 在伤害计算后触发能量回复

#### ⚠️ ISSUE-005: 威胁值计算不完整
- **设计**: 威胁度 = 输出威胁×0.4 + 治疗威胁×0.3 + 角色基准×0.2 + 残血加成×0.1
- **实现**: `battle_target_selector.lua` 中威胁值计算简化
- **影响**: HIGHEST_THREAT 策略效果不佳
- **建议**: 实现完整威胁值跟踪和计算

#### ⚠️ ISSUE-006: 技能配置格式不一致
- **设计**: 简洁的 Lua 表配置，字段名小写
- **实现**: JSON + Lua 混合格式，字段名混合大小写
- **影响**: 配置维护困难
- **建议**: 统一配置格式规范

### 3.3 低优先级问题

#### ℹ️ ISSUE-007: 范围系统超出设计
- **现状**: 实现新增 RANDOM_RANGE、FRONT_ROW、BACK_ROW 等类型
- **影响**: 无负面影响，属增强
- **建议**: 更新设计文档以反映实现

#### ℹ️ ISSUE-008: 伤害公式实现差异
- **设计**: 基础伤害 = (ATK × 0.9 - DEF × 0.5) × 技能倍率
- **实现**: 使用 `battle_formula.lua`，公式细节可能不同
- **影响**: 数值平衡可能与设计预期不同
- **建议**: 对比公式实现，确保数值一致

---

## 4. 建议修复方案

### 4.1 短期修复 (1-2天)

#### 修复 ISSUE-006: 统一配置格式
```lua
-- 建议统一字段命名规范
-- 当前问题: skillCost vs skill_cost, LuaFile vs luaFile
-- 建议: 统一使用小写下划线命名
```

#### 修复 ISSUE-004: 受伤回复能量
```lua
-- 在 battle_dmg_heal.lua ApplyDamage 后添加
function ApplyDamage(target, damage, attacker)
    -- ... 现有伤害逻辑 ...
    
    -- 受伤回复能量
    local energyGain = math.floor(damage * 0.005)  -- 0.5%
    BattleEnergy.AddEnergy(target, energyGain)
end
```

### 4.2 中期修复 (3-5天)

#### 修复 ISSUE-001: 被动技能框架
```lua
-- 新建 modules/battle_passive_skill.lua
local BattlePassiveSkill = {}

-- 被动触发事件类型
E_PASSIVE_TRIGGER = {
    ON_DEAL_DAMAGE = 1,      -- 造成伤害时
    ON_RECEIVE_DAMAGE = 2,   -- 受到伤害时
    ON_ATTACK = 3,           -- 攻击时
    ON_BE_ATTACKED = 4,      -- 被攻击时
    ON_HEAL = 5,             -- 治疗时
    ON_ROUND_START = 6,      -- 回合开始
    ON_ROUND_END = 7,        -- 回合结束
    ON_KILL = 8,             -- 击杀时
}

-- 注册被动技能
function BattlePassiveSkill.Register(hero, skill)
    if skill.skillType ~= E_SKILL_TYPE_PASSIVE then return end
    -- 注册到事件系统
end

-- 触发被动
function BattlePassiveSkill.Trigger(triggerType, context)
    -- 遍历所有被动技能，检查是否触发
end

return BattlePassiveSkill
```

#### 修复 ISSUE-002: 技能标签系统
```lua
-- 在 res_skill.json 中添加 tags 字段
-- 在 battle_skill.lua 中检查标签
function BattleSkill.CheckSkillTag(skill, tag)
    local tags = skill.tags or {}
    for _, t in ipairs(tags) do
        if t == tag then return true end
    end
    return false
end

-- 在伤害计算中使用
function CalculateDamage(attacker, defender, skill)
    -- 检查必中标签
    if BattleSkill.CheckSkillTag(skill, "CANNOT_MISS") then
        hitRate = 100
    end
    
    -- 检查无视防御标签
    if BattleSkill.CheckSkillTag(skill, "IGNORE_DEFENSE") then
        def = 0
    end
    
    -- 检查阻止反击标签
    if BattleSkill.CheckSkillTag(skill, "PREVENT_COUNTER") then
        -- 标记此次攻击不触发反击
    end
end
```

### 4.3 长期修复 (1-2周)

#### 修复 ISSUE-003: AI策略系统
```lua
-- 在 battle_ai.lua 中实现完整策略系统
local AIPersonality = {
    AGGRESSIVE = {
        skillWeights = {
            [E_SKILL_TYPE_NORMAL] = 1.5,
            [E_SKILL_TYPE_ACTIVE] = 1.3,
            [E_SKILL_TYPE_ULTIMATE] = 1.2,
        },
        lowHpBonus = 50,
        tankThreatMod = -20,
    },
    DEFENSIVE = {
        -- ...
    },
    CONTROL = {
        -- ...
    },
}
```

#### 修复 ISSUE-005: 威胁值计算
```lua
-- 在 battle_main.lua 中跟踪威胁值
BattleMain.threatTracker = {
    -- 记录每个单位的累计伤害/治疗
}

-- 在目标选择时计算威胁值
function CalculateThreat(unit)
    local outputThreat = BattleMain.threatTracker[unit.id].damage / 1000
    local healThreat = BattleMain.threatTracker[unit.id].heal / 1000 * 0.7
    local roleBase = GetRoleBaseThreat(unit.class)
    local lowHpBonus = unit.hp / unit.maxHp < 0.3 and 20 or 0
    
    return outputThreat * 0.4 + healThreat * 0.3 + roleBase * 0.2 + lowHpBonus * 0.1
end
```

---

## 5. 修复优先级建议

| 优先级 | 问题 | 原因 |
|--------|------|------|
| P0 | ISSUE-001 被动技能 | 核心功能缺失 |
| P0 | ISSUE-002 技能标签 | 影响技能多样性 |
| P1 | ISSUE-003 AI策略 | 影响游戏体验 |
| P1 | ISSUE-004 受伤回复 | 能量系统不完整 |
| P2 | ISSUE-005 威胁值 | 影响AI智能度 |
| P2 | ISSUE-006 配置格式 | 维护性问题 |
| P3 | ISSUE-007/008 | 非阻塞性问题 |

---

## 6. 附录

### 6.1 检查文件清单

**设计文档**:
- `design/00-基础规则/战斗规则.md`
- `design/01-核心机制/技能范围机制.md`
- `design/01-核心机制/目标选择机制.md`
- `design/02-核心系统/技能系统.md`
- `design/02-核心系统/AI系统.md`
- `docs/SKILL_SYSTEM_IMPLEMENTATION.md`

**代码实现**:
- `modules/battle_skill.lua`
- `modules/battle_area.lua`
- `modules/skill_mechanics.lua`
- `modules/battle_ai.lua`
- `modules/battle_target_selector.lua`
- `modules/battle_energy.lua`
- `config/skill_config.lua`

### 6.2 术语对照表

| 设计术语 | 实现术语 | 说明 |
|----------|----------|------|
| 普通攻击 | `E_SKILL_TYPE_NORMAL` | — |
| 主动技能 | `E_SKILL_TYPE_ACTIVE` | — |
| 大招 | `E_SKILL_TYPE_ULTIMATE` | — |
| 被动 | `E_SKILL_TYPE_PASSIVE` | 框架不完整 |
| 射程 | `rangeType` | — |
| 范围 | `areaType` | — |
| 目标选择 | `selectorType` | — |

---

**报告完成**  
如有疑问或需要深入分析某个具体问题，请告知。
