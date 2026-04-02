-- 法术增益系技能事件模板 - ClassID 8000100
-- 战斗开始时获得法术强度加成

event_8000100 = {
    LuaFile = "war_8000100",
    eventid = 8000100,
    triggers = {
        {
            luaFuncName = "OnBattleBegin",
            triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME.BattleBegin,  -- 1: 战斗开始
        },
    }
}
