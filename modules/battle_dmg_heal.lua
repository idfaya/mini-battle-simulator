---
--- Battle Damage and Heal Module
--- 战斗伤害与治疗模块
--- 处理伤害计算、应用、治疗以及特殊效果（如吸血）
---

local Logger = require("utils.logger")
local BattleAttribute = require("modules.battle_attribute")
local BattleEvent = require("core.battle_event")
local BattleVisualEvents = require("ui.battle_visual_events")

---@class BattleDmgHeal
local BattleDmgHeal = {}

-- 伤害统计
local damageStats = {
    totalDamageDealt = 0,
    totalDamageTaken = 0,
    totalHealDone = 0,
    totalHealReceived = 0,
}

--- 初始化模块
function BattleDmgHeal.Init()
    Logger.Log("[BattleDmgHeal.Init] 伤害与治疗模块初始化")

    -- 重置统计
    damageStats = {
        totalDamageDealt = 0,
        totalDamageTaken = 0,
        totalHealDone = 0,
        totalHealReceived = 0,
    }

end

--- 清理模块
function BattleDmgHeal.OnFinal()
    Logger.Log("[BattleDmgHeal.OnFinal] 伤害与治疗模块清理")

    -- 重置统计
    damageStats = {
        totalDamageDealt = 0,
        totalDamageTaken = 0,
        totalHealDone = 0,
        totalHealReceived = 0,
    }
end

--- 处理吸血效果（生命偷取）
---@param attacker table 攻击者
---@param damage number 造成的伤害值
---@return number 实际吸血量
function BattleDmgHeal.Bloodthirsty(attacker, damage)
    -- 检查参数有效性
    if not attacker or not damage or damage <= 0 then
        return 0
    end

    -- 获取吸血比例
    local bloodthirstyRate = attacker.bloodthirstyRate or 0
    if bloodthirstyRate <= 0 then
        return 0
    end

    -- 计算吸血量
    local healAmount = damage * bloodthirstyRate / 10000
    healAmount = math.floor(healAmount)

    if healAmount > 0 then
        -- 对自己进行治疗
        local curHp = BattleAttribute.GetHeroCurHp(attacker)
        local maxHp = BattleAttribute.GetHeroMaxHp(attacker)
        local actualHeal = math.min(healAmount, maxHp - curHp)

        if actualHeal > 0 then
            local newHp = curHp + actualHeal
            BattleAttribute.SetHpByVal(attacker, newHp)

            Logger.Debug(string.format("[BattleDmgHeal.Bloodthirsty] %s 吸血恢复 %d 点生命值",
                attacker.name or "Unknown", actualHeal))
        end

        return actualHeal
    end

    return 0
end

--- 消耗HP（用于需要消耗生命值的技能）
---@param hero table 英雄
---@param percent number 消耗百分比 (0-100)
---@return number 实际消耗的HP值
function BattleDmgHeal.PayHP(hero, percent)
    -- 检查参数有效性
    if not hero then
        Logger.LogWarning("[BattleDmgHeal.PayHP] 英雄为空")
        return 0
    end

    -- 检查英雄是否已死亡
    if hero.isDead or hero.hp <= 0 then
        Logger.Debug("[BattleDmgHeal.PayHP] 英雄已死亡，无法消耗HP")
        return 0
    end

    -- 确保百分比有效
    percent = math.max(0, math.min(percent or 0, 100))

    -- 计算消耗量
    local maxHp = BattleAttribute.GetHeroMaxHp(hero)
    local payAmount = maxHp * percent / 100
    payAmount = math.floor(payAmount)

    -- 确保不会消耗致死（至少保留1点HP）
    local curHp = BattleAttribute.GetHeroCurHp(hero)
    payAmount = math.min(payAmount, curHp - 1)

    if payAmount > 0 then
        -- 应用消耗
        local newHp = curHp - payAmount
        BattleAttribute.SetHpByVal(hero, newHp)

        Logger.Debug(string.format("[BattleDmgHeal.PayHP] %s 消耗 %d 点HP (%.1f%%)",
            hero.name or "Unknown", payAmount, percent))

        return payAmount
    end

    return 0
end

--- 应用伤害到目标（内部函数）
---@param target table 目标
---@param damage number 伤害值
---@param attacker table 攻击者（可选）
---@param params table|nil 额外参数
function BattleDmgHeal.ApplyDamage(target, damage, attacker, params)
    if not target or damage <= 0 then
        return
    end

    params = params or {}
    local incomingDamage = math.max(0, math.floor(tonumber(damage) or 0))
    local reducedDamage = incomingDamage
    local flatReduce = math.max(0, math.floor(tonumber(target.damageReduce) or 0))
    if flatReduce > 0 then
        reducedDamage = math.max(0, reducedDamage - flatReduce)
    end
    local damageKind = tostring(params.damageKind or "direct")
    if damageKind == "spell" then
        local spellReduce = math.max(0, math.floor(tonumber(target.spellDamageReduce) or 0))
        if spellReduce > 0 then
            reducedDamage = math.max(0, reducedDamage - spellReduce)
        end
    end

    local tempHpBefore = math.max(0, math.floor(tonumber(target.tempHp) or 0))
    local absorbedByTempHp = math.min(tempHpBefore, reducedDamage)
    if absorbedByTempHp > 0 then
        target.tempHp = tempHpBefore - absorbedByTempHp
        reducedDamage = reducedDamage - absorbedByTempHp
    end

    local curHp = BattleAttribute.GetHeroCurHp(target)
    local newHp = math.max(0, curHp - reducedDamage)
    local actualDamage = math.max(0, curHp - newHp)

    -- region debug-point enemy-no-damage-apply
    Logger.Log(string.format("[DBG enemy-no-damage apply] attacker=%s attackerLeft=%s target=%s targetLeft=%s damage=%d hp=%d->%d",
        tostring(attacker and attacker.name),
        tostring(attacker and attacker.isLeft),
        tostring(target and target.name),
        tostring(target and target.isLeft),
        reducedDamage,
        tonumber(curHp) or 0,
        tonumber(newHp) or 0))
    -- endregion debug-point enemy-no-damage-apply

    BattleAttribute.SetHpByVal(target, newHp)
    if attacker and attacker.__scriptDamageAccumulator ~= nil then
        attacker.__scriptDamageAccumulator = attacker.__scriptDamageAccumulator + reducedDamage
    end
    if actualDamage > 0 and attacker then
        local ok, FighterBuildPassives = pcall(require, "skills.fighter_build_passives")
        if ok and FighterBuildPassives and FighterBuildPassives.RecordAttackVictim then
            FighterBuildPassives.RecordAttackVictim(attacker, target, actualDamage)
        end
    end
    if attacker and attacker.__energyCastStats and actualDamage > 0 then
        attacker.__energyCastStats.successfulHits = (attacker.__energyCastStats.successfulHits or 0) + 1
        if params.isCrit then
            attacker.__energyCastStats.didCrit = true
        end
        if target.isDead or target.hp <= 0 then
            attacker.__energyCastStats.killCount = (attacker.__energyCastStats.killCount or 0) + 1
        end
    end

    local BattleEnergy = require("modules.battle_energy")
    BattleEnergy.OnHeroDamaged(target, actualDamage, attacker, params)
    if params.isBlocked then
        BattleEnergy.OnBlock(target)
    end

    -- 5e-style: damage can break concentration / interrupt chanting.
    if actualDamage > 0 then
        local ok, BattleSkill = pcall(require, "modules.battle_skill")
        if ok and BattleSkill and BattleSkill.OnDamagedInterrupt then
            BattleSkill.OnDamagedInterrupt(target, actualDamage)
        end
    end

    -- 触发可视化伤害事件
    local BattleVisualEvents = require("ui.battle_visual_events")
    BattleEvent.Publish(BattleVisualEvents.DAMAGE_DEALT, BattleVisualEvents.BuildDamageDealt(
        attacker, target, reducedDamage, {
            damageType = params.damageType or 1,
            isCrit = params.isCrit or false,
            isDodged = params.isDodged or false,
            isBlocked = params.isBlocked or false,
            skillId = params.skillId,
            skillName = params.skillName,
            attackRoll = params.attackRoll,
            saveRoll = params.saveRoll,
            damageRoll = params.damageRoll,
        }))
    
    -- 触发目标状态变化事件
    BattleEvent.Publish(BattleVisualEvents.HERO_STATE_CHANGED, BattleVisualEvents.BuildHeroStateChanged(target))
end

--- 应用治疗到目标
---@param target table 目标
---@param heal number 治疗值
---@param caster table 施法者（可选）
function BattleDmgHeal.ApplyHeal(target, heal, caster)
    if not target or heal <= 0 then
        return
    end

    local curHp = BattleAttribute.GetHeroCurHp(target)
    local maxHp = target.maxHp or 100
    local newHp = math.min(maxHp, curHp + heal)

    BattleAttribute.SetHpByVal(target, newHp)
    
    -- 触发可视化治疗事件
    local BattleVisualEvents = require("ui.battle_visual_events")
    BattleEvent.Publish(BattleVisualEvents.HEAL_RECEIVED, BattleVisualEvents.BuildHealReceived(
        caster, target, heal, {}))
    
    -- 触发目标状态变化事件
    BattleEvent.Publish(BattleVisualEvents.HERO_STATE_CHANGED, BattleVisualEvents.BuildHeroStateChanged(target))
end

--- 获取伤害统计
---@return table 统计信息
function BattleDmgHeal.GetDamageStats()
    return {
        totalDamageDealt = damageStats.totalDamageDealt,
        totalDamageTaken = damageStats.totalDamageTaken,
        totalHealDone = damageStats.totalHealDone,
        totalHealReceived = damageStats.totalHealReceived,
    }
end

--- 重置伤害统计
function BattleDmgHeal.ResetDamageStats()
    damageStats = {
        totalDamageDealt = 0,
        totalDamageTaken = 0,
        totalHealDone = 0,
        totalHealReceived = 0,
    }
end

return BattleDmgHeal
