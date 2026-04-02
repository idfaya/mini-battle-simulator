-- 速度系技能事件模板 - ClassID 8000032
-- 战斗开始时获得速度加成

event_8000032 = {
    LuaFile = "war_8000032",
    eventid = 8000032,
    triggers = {
        {
            luaFuncName = "OnBattleBegin",
            triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME.BattleBegin,  -- 1: 战斗开始
        },
    }
}
