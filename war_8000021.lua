---
--- 闪避系被动技能 - ClassID 8000021
--- 受击时概率闪避攻击
---

local Logger = require("utils.logger")
local BattleEvent = require("core.battle_event")

--- 创建技能实例的工厂函数
return function(context)
    local War_8000021 = {}
    War_8000021.context = context
    War_8000021.data = context and context.data or {}

    --- 受击前触发（闪避）
    function War_8000021:OnDefBeforeDmg(ctx)
        local data = ctx and ctx.data or self.data
        local extraParam = data.extraParam or {}

        -- 获取技能参数
        local skillParam = data.OwnerSkillCsv or {}
        local triggerProb = skillParam.param1 or 1500  -- 默认15%

        -- 获取英雄
        local heroId = data.OwnerUnitID

        -- 概率检查
        local roll = math.random(1, 10000)
        if roll > triggerProb then
            return  -- 未触发
        end

        Logger.Log(string.format("[War_8000021] 闪避触发! 概率:%.1f%% 随机值:%d", triggerProb / 100, roll))

        -- 获取英雄对象
        local BattleFormation = require("modules.battle_formation")
        local hero = BattleFormation.FindHeroByInstanceId(heroId)

        if not hero then
            return
        end

        -- 设置闪避标记
        hero.isDodging = true

        Logger.Log(string.format("  -> 闪避! %s 闪避了攻击", hero.name or "Unknown"))

        -- 发送被动技能触发事件到Viewport
        BattleEvent.Publish("PassiveSkillTriggered", {
            eventType = "PassiveSkillTriggered",
            heroId = heroId,
            heroName = hero.name,
            skillName = "闪避",
            triggerType = "完全闪避",
            extraInfo = "闪避成功",
        })
    end

    return War_8000021
end
