---
--- Battle Skill Target Helper Module
--- 集中管理 BattleSkill 常用的「辅助目标选择」逻辑：
---   * SelectLowestHpEnemy / SelectLowestHpAlly —— 取最残血目标
---   * SelectRandomAliveEnemies —— 随机存活敌人（用于连击风暴、连锁闪电）
---   * SelectAllAliveTargets —— 全场存活敌人
---   * IsAlly —— 阵营判定
---
--- 从 modules/battle_skill.lua [10] 区拆出（2026-04-27），后迁移到 skills/ 目录。
--- 更高阶的 SelectTarget / SelectEnemyTargets / SelectMultiTargets 仍留在 battle_skill.lua，
--- 因为它们依赖技能配置解析上下文（SkillConfig、skillParam、castTarget 等）。
---
--- 外部契约：battle_skill.lua 仍保留 BattleSkill.SelectLowestHpEnemy 等同名接口作为转发，
--- 保持 bin/test_timeline_passive.lua 的 monkey-patch 能力。
---

local BattleSkillTargetHelper = {}

--- 随机打乱一个数组（Fisher-Yates），返回新表。
--- 与 battle_skill.lua 内部的 ShuffleTargets 等价。
local function Shuffle(targets)
    local shuffled = {}
    for i, target in ipairs(targets) do
        shuffled[i] = target
    end
    for i = #shuffled, 2, -1 do
        local j = math.random(i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end
    return shuffled
end

--- 判断两个单位是否属于同一阵营。
---@param hero table
---@param target table
---@return boolean
function BattleSkillTargetHelper.IsAlly(hero, target)
    if not hero or not target then return false end
    return hero.isLeft == target.isLeft
end

--- 选 HP 比例最低的敌人（优先走 GetSelectableEnemyHeroes 过滤，兜底 GetEnemyTeam）。
---@param hero table
---@return table|nil
function BattleSkillTargetHelper.SelectLowestHpEnemy(hero)
    local BattleFormation = require("modules.battle_formation")
    local enemies = nil
    if BattleFormation.GetSelectableEnemyHeroes then
        enemies = BattleFormation.GetSelectableEnemyHeroes(hero, false)
    end
    if not enemies or #enemies == 0 then
        enemies = BattleFormation.GetEnemyTeam(hero)
    end

    if not enemies or #enemies == 0 then return nil end

    local lowestHpTarget = nil
    local lowestHpRatio = math.huge

    for _, enemy in ipairs(enemies) do
        if enemy and not enemy.isDead and enemy.hp and enemy.maxHp and enemy.maxHp > 0 then
            local hpRatio = enemy.hp / enemy.maxHp
            if hpRatio < lowestHpRatio then
                lowestHpRatio = hpRatio
                lowestHpTarget = enemy
            end
        end
    end

    return lowestHpTarget
end

--- 选 HP 比例最低且未满血的友方（含自身）。
---@param hero table
---@return table|nil
function BattleSkillTargetHelper.SelectLowestHpAlly(hero)
    local BattleFormation = require("modules.battle_formation")
    local allies = BattleFormation.GetFriendTeam(hero)
    local lowestHpTarget = nil
    local lowestHpRatio = 1.0

    for _, ally in ipairs(allies or {}) do
        if ally and ally.isAlive and not ally.isDead and ally.maxHp and ally.maxHp > 0 and ally.hp < ally.maxHp then
            local hpRatio = ally.hp / ally.maxHp
            if hpRatio < lowestHpRatio then
                lowestHpRatio = hpRatio
                lowestHpTarget = ally
            end
        end
    end

    return lowestHpTarget
end

--- 随机选存活敌人 N 个（打乱后取前 count）。
---@param hero table
---@param count number
---@return table 目标列表
function BattleSkillTargetHelper.SelectRandomAliveEnemies(hero, count)
    local BattleFormation = require("modules.battle_formation")
    local enemies = nil
    if BattleFormation.GetSelectableEnemyHeroes then
        enemies = BattleFormation.GetSelectableEnemyHeroes(hero, false)
    end
    if not enemies or #enemies == 0 then
        enemies = BattleFormation.GetEnemyTeam(hero)
    end

    if not enemies or #enemies == 0 then return {} end

    local aliveEnemies = {}
    for _, enemy in ipairs(enemies) do
        if enemy and not enemy.isDead then
            table.insert(aliveEnemies, enemy)
        end
    end

    local selected = {}
    local shuffled = Shuffle(aliveEnemies)
    for i = 1, math.min(count or 0, #shuffled) do
        table.insert(selected, shuffled[i])
    end
    return selected
end

--- 全场存活敌人（不过滤 taunt/可选性，用于 AoE）。
---@param hero table
---@return table
function BattleSkillTargetHelper.SelectAllAliveTargets(hero)
    local BattleFormation = require("modules.battle_formation")
    local enemies = BattleFormation.GetEnemyTeam(hero)
    if not enemies then return {} end

    local aliveTargets = {}
    for _, enemy in ipairs(enemies) do
        if enemy and not enemy.isDead then
            table.insert(aliveTargets, enemy)
        end
    end
    return aliveTargets
end

return BattleSkillTargetHelper
