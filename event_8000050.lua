-- 吸血系技能事件模板 - ClassID 8000050
-- 造成伤害时恢复生命

event_8000050 = {
    LuaFile = "war_8000050",
    eventid = 8000050,
    triggers = {
        {
            luaFuncName = "OnNormalAtkFinish",
            triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME.NormalAtkFinish,  -- 17: 普通攻击结束
        },
    }
}
