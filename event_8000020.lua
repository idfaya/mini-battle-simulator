-- 格挡系技能事件模板 - ClassID 8000020
-- 受击时概率触发格挡减伤

event_8000020 = {
    LuaFile = "war_8000020",
    eventid = 8000020,
    triggers = {
        {
            luaFuncName = "OnDefBeforeDmg",
            triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME.DefBeforeDmg,  -- 5: 受击前
        },
    }
}
