---
--- 速度系被动技能 - ClassID 8000032
--- 战斗开始时获得速度加成
---

local Logger = require("utils.logger")
local BattleEvent = require("core.battle_event")

--- 创建技能实例的工厂函数
return function(context)
    local War_8000032 = {}
    War_8000032.context = context
    War_8000032.data = context and context.data or {}

    --- 战斗开始时触发
    function War_8000032:OnBattleBegin(ctx)
        local data = ctx and ctx.data or self.data

        -- 获取技能参数
        local skillParam = data.OwnerSkillCsv or {}
        local speedBonus = skillParam.param1 or 50  -- 默认+50速度

        -- 获取英雄
        local heroId = data.OwnerUnitID

        -- 获取英雄对象
        local BattleFormation = require("modules.battle_formation")
        local hero = BattleFormation.FindHeroByInstanceId(heroId)

        if not hero then
            return
        end

        -- 应用速度加成
        hero.spd = (hero.spd or 0) + speedBonus
        Logger.Log(string.format("[War_8000032] %s 获得速度加成: +%d (当前:%d)", hero.name or "Unknown", speedBonus, hero.spd))

        -- 发送被动技能触发事件到Viewport
        BattleEvent.Publish("PassiveSkillTriggered", {
            eventType = "PassiveSkillTriggered",
            heroId = heroId,
            heroName = hero.name,
            skillName = "速度加成",
            triggerType = "属性提升",
            extraInfo = string.format("速度+%d", speedBonus),
        })
    end

    return War_8000032
end
