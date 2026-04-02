-- 开局增益系技能事件模板 - ClassID 8000030
-- 回合开始时触发增益效果

event_8000030 = {
    LuaFile = "war_8000030",
    eventid = 8000030,
    triggers = {
        {
            luaFuncName = "OnSelfTurnBegin",
            triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME.SelfTurnBegin,  -- 14: 自身回合开始
        },
    }
}
