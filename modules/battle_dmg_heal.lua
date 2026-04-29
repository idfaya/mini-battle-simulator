---
--- Battle Damage and Heal Module
--- 战斗伤害与治疗模块
--- 处理伤害计算、应用、治疗以及特殊效果（如吸血）
---

local Logger = require("utils.logger")
local BattleFormula = require("core.battle_formula")
local BattleAttribute = require("modules.battle_attribute")
local BattleEvent = require("core.battle_event")
local BattleVisualEvents = require("ui.battle_visual_events")

---@class BattleDmgHeal
local BattleDmgHeal = {}

-- 模块配置
local config = {
    -- 吸血效果默认比例 (万分比)
    defaultBloodthirstyRate = 1000,  -- 10%
    -- 最小伤害值
    minDamage = 1,
    -- 最小治疗值
    minHeal = 1,
    -- 最大闪避率 (万分比)
    maxDodgeRate = 8000,  -- 80%
    -- 命中率基础值 (万分比)
    baseHitRate = 10000,  -- 100%
}

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

    -- 确保 BattleFormula 已初始化
    if BattleFormula and BattleFormula.Init then
        BattleFormula.Init(BattleFormula.FORMULA_TYPE.STANDARD)
    end
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

--- 检查攻击是否被闪避
---@param attacker table 攻击者
---@param defender table 防御者
---@return boolean 是否闪避
function BattleDmgHeal.IsDodged(attacker, defender)
    if not attacker or not defender then
        return false
    end

    -- 获取攻击者命中率
    local hitRate = attacker.hitRate or BattleAttribute.GetAttribute(attacker, BattleAttribute.ATTR_ID.HIT_RATE)
    hitRate = hitRate or config.baseHitRate

    -- 获取防御者闪避率
    local dodgeRate = defender.dodgeRate or BattleAttribute.GetAttribute(defender, BattleAttribute.ATTR_ID.DODGE_RATE)
    dodgeRate = dodgeRate or 0

    -- 限制闪避率上限
    dodgeRate = math.min(dodgeRate, config.maxDodgeRate)

    -- 计算实际闪避概率 (闪避率 - 未命中率)
    local actualDodgeRate = dodgeRate - (config.baseHitRate - hitRate)
    actualDodgeRate = math.max(0, actualDodgeRate)

    -- 使用 BattleMath 进行随机判定
    if BattleMath then
        return BattleMath.RandomCheck(actualDodgeRate, 10000)
    else
        -- 备用方案
        local randomValue = math.random(1, 10000)
        return randomValue <= actualDodgeRate
    end
end

--- 检查攻击是否暴击
---@param attacker table 攻击者
---@param defender table 防御者
---@return boolean 是否暴击
function BattleDmgHeal.IsCrit(attacker, defender)
    if not attacker then
        return false
    end

    -- 获取攻击者暴击率
    local critRate = attacker.critRate or BattleAttribute.GetAttribute(attacker, BattleAttribute.ATTR_ID.CRIT_RATE)
    critRate = critRate or 0

    -- 使用 BattleFormula 的暴击检查
    if BattleFormula and BattleFormula.CheckCrit then
        return BattleFormula.CheckCrit(critRate)
    else
        -- 备用方案
        local randomValue = math.random(1, 10000)
        return randomValue <= critRate
    end
end

--- 应用伤害
---@param attacker table 攻击者
---@param defender table 防御者
---@param atkType number 攻击类型 (E_ATTACK_TYPE)
---@param dmgParam table 伤害参数 { skillDamageRate = 10000, isCrit = nil, isForceHit = false }
---@param isShowDmg boolean 是否显示伤害数字
---@param hitType number 命中类型 (E_HIT_TYPE)
---@return table 伤害结果 { damage = number, isCrit = boolean, isBlock = boolean, isDodged = boolean }
function BattleDmgHeal.MakeDmg(attacker, defender, atkType, dmgParam, isShowDmg, hitType)
    dmgParam = dmgParam or {}
    local result = {
        damage = 0,
        isCrit = false,
        isBlock = false,
        isDodged = false,
    }

    -- 检查参数有效性
    if not attacker or not defender then
        Logger.LogWarning("[BattleDmgHeal.MakeDmg] 攻击者或防御者为空")
        return result
    end

    -- 检查防御者是否已死亡
    if defender.isDead or defender.hp <= 0 then
        Logger.Debug("[BattleDmgHeal.MakeDmg] 目标已死亡，无法造成伤害")
        return result
    end

    -- 检查是否闪避 (如果不是强制命中)
    if not dmgParam.isForceHit then
        result.isDodged = BattleDmgHeal.IsDodged(attacker, defender)
        if result.isDodged then
            Logger.Debug(string.format("[BattleDmgHeal.MakeDmg] %s 的攻击被 %s 闪避",
                attacker.name or "Unknown", defender.name or "Unknown"))
            BattleEvent.Publish(BattleVisualEvents.DODGE, BattleVisualEvents.BuildCombatEvent(
                BattleVisualEvents.DODGE,
                attacker,
                defender,
                {
                    skillId = dmgParam.skillId,
                    skillName = dmgParam.skillName,
                }))
            return result
        end
    end

    -- 准备 BattleFormula 需要的属性格式
    local attackerData = BattleDmgHeal.ConvertHeroToFormulaData(attacker)
    local defenderData = BattleDmgHeal.ConvertHeroToFormulaData(defender)

    -- 计算伤害
    local skillDamageRate = dmgParam.skillDamageRate or 10000
    local forceCrit = dmgParam.isCrit

    local damageResult = BattleFormula.CalcDamage(
        attackerData,
        defenderData,
        skillDamageRate,
        atkType or E_ATTACK_TYPE.Physical,
        forceCrit
    )

    result.damage = damageResult.damage
    result.isCrit = damageResult.isCrit
    result.isBlock = damageResult.isBlock

    -- 应用伤害到防御者
    if result.damage > 0 then
        BattleDmgHeal.ApplyDamage(defender, result.damage, attacker, {
            isCrit = result.isCrit,
            isBlocked = result.isBlock,
            isDodged = result.isDodged,
            damageType = atkType or E_ATTACK_TYPE.Physical,
            damageKind = "direct",
        })

        -- 更新统计
        damageStats.totalDamageDealt = damageStats.totalDamageDealt + result.damage
        damageStats.totalDamageTaken = damageStats.totalDamageTaken + result.damage

        -- 触发吸血效果
        if attacker.bloodthirstyRate and attacker.bloodthirstyRate > 0 then
            BattleDmgHeal.Bloodthirsty(attacker, result.damage)
        end

        -- 发布伤害事件（旧版兼容）
        BattleEvent.Publish("Damage", defender, result.damage, result.isCrit)
        
        -- 注意：可视化伤害事件在 ApplyDamage 中触发，避免重复

        Logger.Debug(string.format("[BattleDmgHeal.MakeDmg] %s 对 %s 造成 %d 点伤害 (暴击:%s, 格挡:%s)",
            attacker.name or "Unknown",
            defender.name or "Unknown",
            result.damage,
            tostring(result.isCrit),
            tostring(result.isBlock)))
    end

    return result
end

--- 应用额外伤害（无视防御或特殊计算）
---@param attacker table 攻击者
---@param defender table 防御者
---@param atkType number 攻击类型 (E_ATTACK_TYPE)
---@param dmgParam table 伤害参数 { damage = number, isTrueDamage = false, isCrit = false }
---@return table 伤害结果 { damage = number }
function BattleDmgHeal.MakeDmgPlus(attacker, defender, atkType, dmgParam)
    dmgParam = dmgParam or {}
    local result = {
        damage = 0,
        isCrit = false,
        isBlock = false,
        isDodged = false,
    }

    -- 检查参数有效性
    if not attacker or not defender then
        Logger.LogWarning("[BattleDmgHeal.MakeDmgPlus] 攻击者或防御者为空")
        return result
    end

    -- 检查防御者是否已死亡
    if defender.isDead or defender.hp <= 0 then
        Logger.Debug("[BattleDmgHeal.MakeDmgPlus] 目标已死亡，无法造成伤害")
        return result
    end

    local damage = dmgParam.damage or 0

    -- 如果是真实伤害，直接应用
    if dmgParam.isTrueDamage then
        result.damage = math.max(damage, config.minDamage)
    else
        -- 使用公式计算额外伤害
        local attackerData = BattleDmgHeal.ConvertHeroToFormulaData(attacker)
        local defenderData = BattleDmgHeal.ConvertHeroToFormulaData(defender)

        -- 计算最终伤害（基于基础伤害）
        result.damage = BattleFormula.CalcFinalDamage(damage, attackerData, defenderData, atkType)
    end

    -- 应用伤害
    if result.damage > 0 then
        BattleDmgHeal.ApplyDamage(defender, result.damage, attacker, {
            isCrit = result.isCrit,
            isBlocked = result.isBlock,
            isDodged = result.isDodged,
            damageType = atkType or E_ATTACK_TYPE.Physical,
            damageKind = dmgParam.damageKind or "direct",
        })

        -- 更新统计
        damageStats.totalDamageDealt = damageStats.totalDamageDealt + result.damage
        damageStats.totalDamageTaken = damageStats.totalDamageTaken + result.damage

        -- 触发吸血效果
        if attacker.bloodthirstyRate and attacker.bloodthirstyRate > 0 then
            BattleDmgHeal.Bloodthirsty(attacker, result.damage)
        end

        Logger.Debug(string.format("[BattleDmgHeal.MakeDmgPlus] %s 对 %s 造成 %d 点额外伤害",
            attacker.name or "Unknown",
            defender.name or "Unknown",
            result.damage))
    end

    return result
end

--- 应用治疗
---@param caster table 施法者
---@param target table 目标
---@param healVal number 治疗值
---@return number 实际治疗量
function BattleDmgHeal.MakeHeal(caster, target, healVal)
    -- 检查参数有效性
    if not caster or not target then
        Logger.LogWarning("[BattleDmgHeal.MakeHeal] 施法者或目标为空")
        return 0
    end

    -- 检查目标是否已死亡（通常不能治疗死亡目标，除非有复活效果）
    if target.isDead or target.hp <= 0 then
        Logger.Debug("[BattleDmgHeal.MakeHeal] 目标已死亡，无法治疗")
        return 0
    end

    -- 确保治疗值有效
    healVal = math.max(healVal or 0, config.minHeal)

    -- 应用治疗加成
    local healBonus = caster.healBonus or 0
    local finalHeal = healVal * (1 + healBonus / 10000)
    finalHeal = math.floor(finalHeal)

    -- 获取当前HP和最大HP
    local curHp = BattleAttribute.GetHeroCurHp(target)
    local maxHp = BattleAttribute.GetHeroMaxHp(target)

    -- 计算实际治疗量（不超过最大HP）
    local actualHeal = math.min(finalHeal, maxHp - curHp)

    if actualHeal > 0 then
        -- 使用 ApplyHeal 应用治疗（包含事件触发）
        BattleDmgHeal.ApplyHeal(target, actualHeal, caster)

        -- 更新统计
        damageStats.totalHealDone = damageStats.totalHealDone + actualHeal
        damageStats.totalHealReceived = damageStats.totalHealReceived + actualHeal

        -- 发布治疗事件（旧版兼容）
        BattleEvent.Publish("Heal", target, actualHeal)
        
        -- 注意：可视化治疗事件在 ApplyHeal 中触发，避免重复

        Logger.Debug(string.format("[BattleDmgHeal.MakeHeal] %s 治疗 %s %d 点生命值 (实际:%d)",
            caster.name or "Unknown",
            target.name or "Unknown",
            finalHeal,
            actualHeal))
    end

    return actualHeal
end

--- 应用恢复效果（与治疗的区别：恢复通常不受治疗加成/减益影响）
---@param caster table 施法者
---@param target table 目标
---@param healVal number 恢复值
---@return number 实际恢复量
function BattleDmgHeal.MakeRecovery(caster, target, healVal)
    -- 检查参数有效性
    if not caster or not target then
        Logger.LogWarning("[BattleDmgHeal.MakeRecovery] 施法者或目标为空")
        return 0
    end

    -- 检查目标是否已死亡
    if target.isDead or target.hp <= 0 then
        Logger.Debug("[BattleDmgHeal.MakeRecovery] 目标已死亡，无法恢复")
        return 0
    end

    -- 确保恢复值有效（恢复不受治疗加成影响）
    local finalHeal = math.max(healVal or 0, config.minHeal)
    finalHeal = math.floor(finalHeal)

    -- 获取当前HP和最大HP
    local curHp = BattleAttribute.GetHeroCurHp(target)
    local maxHp = BattleAttribute.GetHeroMaxHp(target)

    -- 计算实际恢复量
    local actualHeal = math.min(finalHeal, maxHp - curHp)

    if actualHeal > 0 then
        -- 应用恢复
        local newHp = curHp + actualHeal
        BattleAttribute.SetHpByVal(target, newHp)

        -- 更新统计
        damageStats.totalHealDone = damageStats.totalHealDone + actualHeal
        damageStats.totalHealReceived = damageStats.totalHealReceived + actualHeal

        Logger.Debug(string.format("[BattleDmgHeal.MakeRecovery] %s 恢复 %s %d 点生命值",
            caster.name or "Unknown",
            target.name or "Unknown",
            actualHeal))
    end

    return actualHeal
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
    local curHp = BattleAttribute.GetHeroCurHp(target)
    local newHp = math.max(0, curHp - damage)
    local actualDamage = math.max(0, curHp - newHp)

    -- region debug-point enemy-no-damage-apply
    Logger.Log(string.format("[DBG enemy-no-damage apply] attacker=%s attackerLeft=%s target=%s targetLeft=%s damage=%d hp=%d->%d",
        tostring(attacker and attacker.name),
        tostring(attacker and attacker.isLeft),
        tostring(target and target.name),
        tostring(target and target.isLeft),
        tonumber(damage) or 0,
        tonumber(curHp) or 0,
        tonumber(newHp) or 0))
    -- endregion debug-point enemy-no-damage-apply

    BattleAttribute.SetHpByVal(target, newHp)
    if attacker and attacker.__scriptDamageAccumulator ~= nil then
        attacker.__scriptDamageAccumulator = attacker.__scriptDamageAccumulator + damage
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
    
    -- 触发旧版伤害事件（用于 BattleDisplay 战斗日志）
    BattleEvent.Publish("Damage", target, damage, false)
    
    -- 触发可视化伤害事件
    local BattleVisualEvents = require("ui.battle_visual_events")
    BattleEvent.Publish(BattleVisualEvents.DAMAGE_DEALT, BattleVisualEvents.BuildDamageDealt(
        attacker, target, damage, {
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

--- 将英雄数据转换为 BattleFormula 需要的格式
---@param hero table 英雄对象
---@return table 公式数据
function BattleDmgHeal.ConvertHeroToFormulaData(hero)
    if not hero then
        return { attrs = {} }
    end

    -- 构建属性表
    local attrs = {}

    -- 基础属性
    attrs[BattleFormula.GetConfig().attrType.ATK] = hero.atk or BattleAttribute.GetAttribute(hero, BattleAttribute.ATTR_ID.ATK)
    attrs[BattleFormula.GetConfig().attrType.DEF] = hero.def or BattleAttribute.GetAttribute(hero, BattleAttribute.ATTR_ID.DEF)
    attrs[BattleFormula.GetConfig().attrType.HP] = hero.hp or BattleAttribute.GetHeroCurHp(hero)
    attrs[BattleFormula.GetConfig().attrType.CRIT] = hero.critRate or BattleAttribute.GetAttribute(hero, BattleAttribute.ATTR_ID.CRIT_RATE)
    attrs[BattleFormula.GetConfig().attrType.BLOCK] = hero.blockRate or 0

    return {
        attrs = attrs,
        damageBonus = hero.damageIncrease or 0,
        damageReduction = hero.damageReduce or 0,
    }
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

--- 设置模块配置
---@param newConfig table 新配置
function BattleDmgHeal.SetConfig(newConfig)
    if newConfig then
        for k, v in pairs(newConfig) do
            config[k] = v
        end
    end
end

--- 获取模块配置
---@return table 当前配置
function BattleDmgHeal.GetConfig()
    return config
end

return BattleDmgHeal
