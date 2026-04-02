---
--- 吸血系被动技能 - ClassID 8000050
--- 造成伤害时恢复生命
---

local Logger = require("utils.logger")
local BattleDmgHeal = require("modules.battle_dmg_heal")
local BattleEvent = require("core.battle_event")

--- 创建技能实例的工厂函数
return function(context)
    local War_8000050 = {}
    War_8000050.context = context
    War_8000050.data = context and context.data or {}

    --- 普通攻击结束时触发（吸血）
    function War_8000050:OnNormalAtkFinish(ctx)
        local data = ctx and ctx.data or self.data
        local extraParam = data.extraParam or {}

        -- 获取技能参数
        local skillParam = data.OwnerSkillCsv or {}
        local vampRate = skillParam.param1 or 1500  -- 默认15%吸血

        -- 获取英雄
        local heroId = data.OwnerUnitID
        local damageDealt = extraParam.damageDealt or 0

        if damageDealt <= 0 then
            return
        end

        -- 获取英雄对象
        local BattleFormation = require("modules.battle_formation")
        local hero = BattleFormation.FindHeroByInstanceId(heroId)

        if not hero then
            return
        end

        -- 计算吸血量
        local healAmount = math.floor(damageDealt * vampRate / 10000)
        if healAmount > 0 then
            BattleDmgHeal.ApplyHeal(hero, healAmount, hero)
            Logger.Log(string.format("[War_8000050] %s 吸血恢复 %d HP (伤害:%d, 比例:%.1f%%)",
                hero.name or "Unknown", healAmount, damageDealt, vampRate / 100))

            -- 发送被动技能触发事件到Viewport
            BattleEvent.Publish("PassiveSkillTriggered", {
                eventType = "PassiveSkillTriggered",
                heroId = heroId,
                heroName = hero.name,
                skillName = "吸血",
                triggerType = "生命恢复",
                extraInfo = string.format("恢复%d HP", healAmount),
            })
        end
    end

    return War_8000050
end
