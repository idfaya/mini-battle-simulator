---
--- 开局增益系被动技能 - ClassID 8000030
--- 回合开始时触发增益效果
---

local Logger = require("utils.logger")
local BattleBuff = require("modules.battle_buff")
local BattleEvent = require("core.battle_event")

--- 创建技能实例的工厂函数
return function(context)
    local War_8000030 = {}
    War_8000030.context = context
    War_8000030.data = context and context.data or {}

    --- 自身回合开始时触发
    function War_8000030:OnSelfTurnBegin(ctx)
        local data = ctx and ctx.data or self.data

        -- 获取技能参数
        local skillParam = data.OwnerSkillCsv or {}
        local buffId = skillParam.param1 or 810001  -- 默认添加攻击提升Buff
        local triggerProb = skillParam.param2 or 10000  -- 默认100%触发

        -- 获取英雄
        local heroId = data.OwnerUnitID

        -- 概率检查
        local roll = math.random(1, 10000)
        if roll > triggerProb then
            return  -- 未触发
        end

        Logger.Log(string.format("[War_8000030] 增益触发! BuffID:%d", buffId))

        -- 获取英雄对象
        local BattleFormation = require("modules.battle_formation")
        local hero = BattleFormation.FindHeroByInstanceId(heroId)

        if not hero then
            return
        end

        -- 添加Buff
        local BuffRglConfig = require("config.buff_rgl_config")
        local buffConfig = BuffRglConfig.GetBuffConfig(buffId)
        if buffConfig then
            BattleBuff.AddBuff(hero, buffId, hero, buffConfig.Duration or 3, 1)
            Logger.Log(string.format("  -> 增益! %s 获得 [%s]", hero.name or "Unknown", buffConfig.Name or "Unknown"))

            -- 发送被动技能触发事件到Viewport
            BattleEvent.Publish("PassiveSkillTriggered", {
                eventType = "PassiveSkillTriggered",
                heroId = heroId,
                heroName = hero.name,
                skillName = "开局增益",
                triggerType = "获得Buff",
                extraInfo = buffConfig.Name or "Unknown",
            })
        end
    end

    return War_8000030
end
