---
--- 法术增益系被动技能 - ClassID 8000100
--- 战斗开始时获得法术强度加成
---

local Logger = require("utils.logger")
local BattleEvent = require("core.battle_event")

--- 创建技能实例的工厂函数
return function(context)
    local War_8000100 = {}
    War_8000100.context = context
    War_8000100.data = context and context.data or {}

    --- 战斗开始时触发
    function War_8000100:OnBattleBegin(ctx)
        local data = ctx and ctx.data or self.data

        -- 获取技能参数
        local skillParam = data.OwnerSkillCsv or {}
        local magicBonus = skillParam.param1 or 100  -- 默认+100法术强度

        -- 获取英雄
        local heroId = data.OwnerUnitID

        -- 获取英雄对象
        local BattleFormation = require("modules.battle_formation")
        local hero = BattleFormation.FindHeroByInstanceId(heroId)

        if not hero then
            return
        end

        -- 应用法术强度加成
        hero.magicAtk = (hero.magicAtk or 0) + magicBonus
        Logger.Log(string.format("[War_8000100] %s 获得法术强度加成: +%d (当前:%d)", hero.name or "Unknown", magicBonus, hero.magicAtk))

        -- 发送被动技能触发事件到Viewport
        BattleEvent.Publish("PassiveSkillTriggered", {
            eventType = "PassiveSkillTriggered",
            heroId = heroId,
            heroName = hero.name,
            skillName = "法术强化",
            triggerType = "属性提升",
            extraInfo = string.format("法术强度+%d", magicBonus),
        })
    end

    return War_8000100
end
