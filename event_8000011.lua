-- 反击系技能事件模板 - ClassID 8000011
-- 受击后概率进行反击

event_8000011 = {
    LuaFile = "war_8000011",
    eventid = 8000011,
    triggers = {
        {
            luaFuncName = "OnDefAfterDmg",
            triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME.DefAfterDmg,  -- 3: 受击后
        },
    }
}
