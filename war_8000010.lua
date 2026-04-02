---
--- 连击系被动技能 - ClassID 8000010
--- 攻击时概率触发连击
---

local Logger = require("utils.logger")
local BattleDmgHeal = require("modules.battle_dmg_heal")
local BattleFormula = require("core.battle_formula")
local BattleEvent = require("core.battle_event")

--- 创建技能实例的工厂函数
return function(context)
    local War_8000010 = {}
    War_8000010.context = context
    War_8000010.data = context and context.data or {}

    --- 普通攻击开始时触发（连击）
    function War_8000010:OnNormalAtkStart(ctx)
        local data = ctx and ctx.data or self.data
        local extraParam = data.extraParam or {}

        -- 获取技能参数
        local skillParam = data.OwnerSkillCsv or {}
        local triggerProb = skillParam.param1 or 2000  -- 默认20%
        local damageRate = skillParam.param2 or 10000  -- 默认100%

        -- 获取英雄和目标
        local heroId = data.OwnerUnitID
        local targetId = extraParam.targetId

        -- 概率检查
        local roll = math.random(1, 10000)
        if roll > triggerProb then
            return  -- 未触发
        end

        Logger.Log(string.format("[War_8000010] 连击触发! 概率:%.1f%% 随机值:%d", triggerProb / 100, roll))

        -- 获取英雄和目标对象
        local BattleFormation = require("modules.battle_formation")
        local hero = BattleFormation.FindHeroByInstanceId(heroId)
        local target = targetId and BattleFormation.FindHeroByInstanceId(targetId)

        if not hero or not target or target.isDead then
            return
        end

        -- 执行连击伤害
        local damageResult = BattleFormula.CalcDamage(hero, target)
        local damage = math.floor(damageResult.damage * damageRate / 10000)
        BattleDmgHeal.ApplyDamage(target, damage, hero)

        Logger.Log(string.format("  -> 连击! %s 对 %s 造成 %d 伤害", hero.name or "Unknown", target.name or "Unknown", damage))

        -- 发送被动技能触发事件到Viewport
        BattleEvent.Publish("PassiveSkillTriggered", {
            eventType = "PassiveSkillTriggered",
            heroId = heroId,
            heroName = hero.name,
            skillName = "连击",
            triggerType = "额外攻击",
            extraInfo = string.format("造成%d伤害", damage),
        })
    end

    return War_8000010
end
