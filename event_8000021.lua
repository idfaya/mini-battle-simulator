-- 闪避系技能事件模板 - ClassID 8000021
-- 受击时概率闪避攻击

event_8000021 = {
    LuaFile = "war_8000021",
    eventid = 8000021,
    triggers = {
        {
            luaFuncName = "OnDefBeforeDmg",
            triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME.DefBeforeDmg,  -- 5: 受击前
        },
    }
}
