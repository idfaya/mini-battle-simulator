---
--- 反击系被动技能 - ClassID 8000011
--- 受击后概率进行反击
---

local Logger = require("utils.logger")
local BattleDmgHeal = require("modules.battle_dmg_heal")
local BattleFormula = require("core.battle_formula")
local BattleEvent = require("core.battle_event")

--- 创建技能实例的工厂函数
return function(context)
    local War_8000011 = {}
    War_8000011.context = context
    War_8000011.data = context and context.data or {}

    --- 受击后触发（反击）
    function War_8000011:OnDefAfterDmg(ctx)
        local data = ctx and ctx.data or self.data
        local extraParam = data.extraParam or {}

        -- 获取技能参数
        local skillParam = data.OwnerSkillCsv or {}
        local triggerProb = skillParam.param1 or 1500  -- 默认15%
        local damageRate = skillParam.param2 or 8000   -- 默认80%

        -- 获取英雄和攻击者
        local heroId = data.OwnerUnitID
        local attackerId = extraParam.attackerId

        -- 概率检查
        local roll = math.random(1, 10000)
        if roll > triggerProb then
            return  -- 未触发
        end

        Logger.Log(string.format("[War_8000011] 反击触发! 概率:%.1f%% 随机值:%d", triggerProb / 100, roll))

        -- 获取英雄和攻击者对象
        local BattleFormation = require("modules.battle_formation")
        local hero = BattleFormation.FindHeroByInstanceId(heroId)
        local attacker = attackerId and BattleFormation.FindHeroByInstanceId(attackerId)

        if not hero or not attacker or attacker.isDead then
            return
        end

        -- 执行反击伤害
        local damageResult = BattleFormula.CalcDamage(hero, attacker)
        local damage = math.floor(damageResult.damage * damageRate / 10000)
        BattleDmgHeal.ApplyDamage(attacker, damage, hero)

        Logger.Log(string.format("  -> 反击! %s 对 %s 造成 %d 伤害", hero.name or "Unknown", attacker.name or "Unknown", damage))

        -- 发送被动技能触发事件到Viewport
        BattleEvent.Publish("PassiveSkillTriggered", {
            eventType = "PassiveSkillTriggered",
            heroId = heroId,
            heroName = hero.name,
            skillName = "反击",
            triggerType = "反击攻击",
            extraInfo = string.format("造成%d伤害", damage),
        })
    end

    return War_8000011
end
