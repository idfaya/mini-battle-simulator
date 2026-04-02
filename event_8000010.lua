-- 连击系技能事件模板 - ClassID 8000010
-- 攻击时概率触发额外攻击

event_8000010 = {
    LuaFile = "war_8000010",
    eventid = 8000010,
    triggers = {
        {
            luaFuncName = "OnNormalAtkStart",
            triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME.NormalAtkStart,  -- 16: 普通攻击开始时
        },
    }
}
