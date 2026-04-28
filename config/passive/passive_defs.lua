---@class PassiveTriggerDef
---@field luaFuncName string
---@field triggerTime integer

---@class PassiveDefEntry
---@field triggers PassiveTriggerDef[]

---@type table<integer, PassiveDefEntry>
local PassiveDefs = {
    [8000020] = {
        triggers = {
            {
                luaFuncName = "OnDefBeforeDmg",
                triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME.DefBeforeDmg,
            },
        },
    },
    [80001002] = {
        triggers = {
            {
                luaFuncName = "OnDmgMakeKill",
                triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME.DmgMakeKill,
            },
            {
                luaFuncName = "OnDefBeforeDmg",
                triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME.DefBeforeDmg,
            },
            {
                luaFuncName = "OnBattleBegin",
                triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME.BattleBegin,
            },
        },
    },
    [80002002] = {
        triggers = {
            {
                luaFuncName = "OnDefBeforeDmg",
                triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME.DefBeforeDmg,
            },
            {
                luaFuncName = "OnSelfTurnBegin",
                triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME.SelfTurnBegin,
            },
            {
                luaFuncName = "OnNormalAtkFinish",
                triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME.NormalAtkFinish,
            },
        },
    },
    [80003002] = {
        triggers = {
            {
                luaFuncName = "OnBattleBegin",
                triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME.BattleBegin,
            },
        },
    },
    [80004002] = {
        triggers = {
            {
                luaFuncName = "OnDmgMakeKill",
                triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME.DmgMakeKill,
            },
        },
    },
    [80005002] = {
        triggers = {
            {
                luaFuncName = "OnSelfTurnBegin",
                triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME.SelfTurnBegin,
            },
        },
    },
    [80006002] = {
        triggers = {
            {
                luaFuncName = "OnSelfTurnBegin",
                triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME.SelfTurnBegin,
            },
            {
                luaFuncName = "OnBattleBegin",
                triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME.BattleBegin,
            },
        },
    },
    [80007002] = {
        triggers = {
            {
                luaFuncName = "OnSelfTurnBegin",
                triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME.SelfTurnBegin,
            },
        },
    },
    [80008002] = {
        triggers = {
            {
                luaFuncName = "OnBattleBegin",
                triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME.BattleBegin,
            },
        },
    },
    [80009002] = {
        triggers = {
            {
                luaFuncName = "OnBattleBegin",
                triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME.BattleBegin,
            },
        },
    },
}

return PassiveDefs
