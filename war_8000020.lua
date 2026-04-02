---
--- 格挡系被动技能 - ClassID 8000020
--- 受击时概率触发格挡减伤
---

local Logger = require("utils.logger")
local BattleEvent = require("core.battle_event")

--- 创建技能实例的工厂函数
return function(context)
    local War_8000020 = {}
    War_8000020.context = context
    War_8000020.data = context and context.data or {}

    --- 受击前触发（格挡）
    function War_8000020:OnDefBeforeDmg(ctx)
        local data = ctx and ctx.data or self.data
        local extraParam = data.extraParam or {}

        -- 获取技能参数
        local skillParam = data.OwnerSkillCsv or {}
        local triggerProb = skillParam.param1 or 2000  -- 默认20%
        local reduceRate = skillParam.param2 or 5000   -- 默认减伤50%

        -- 获取英雄
        local heroId = data.OwnerUnitID

        -- 概率检查
        local roll = math.random(1, 10000)
        if roll > triggerProb then
            return  -- 未触发
        end

        Logger.Log(string.format("[War_8000020] 格挡触发! 概率:%.1f%% 随机值:%d", triggerProb / 100, roll))

        -- 获取英雄对象
        local BattleFormation = require("modules.battle_formation")
        local hero = BattleFormation.FindHeroByInstanceId(heroId)

        if not hero then
            return
        end

        -- 设置格挡标记（实际减伤在伤害计算时处理）
        hero.isBlocking = true
        hero.blockReduceRate = reduceRate

        Logger.Log(string.format("  -> 格挡! %s 触发格挡，减伤%.1f%%", hero.name or "Unknown", reduceRate / 100))

        -- 发送被动技能触发事件到Viewport
        BattleEvent.Publish("PassiveSkillTriggered", {
            eventType = "PassiveSkillTriggered",
            heroId = heroId,
            heroName = hero.name,
            skillName = "格挡",
            triggerType = "伤害减免",
            extraInfo = string.format("减伤%.1f%%", reduceRate / 100),
        })
    end

    return War_8000020
end
