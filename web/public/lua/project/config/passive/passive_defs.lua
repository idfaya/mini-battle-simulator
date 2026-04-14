local PassiveDefs = {
    [8000020] = {
        triggers = {
            {
                luaFuncName = "OnDefBeforeDmg",
                triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME.DefBeforeDmg,
            },
        },
    },
    [8000100] = {
        triggers = {
            {
                luaFuncName = "OnDmgMakeKill",
                triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME.DmgMakeKill,
            },
        },
    },
    [8000200] = {
        triggers = {
            {
                luaFuncName = "OnDefBeforeDmg",
                triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME.DefBeforeDmg,
            },
            {
                luaFuncName = "OnSelfTurnBegin",
                triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME.SelfTurnBegin,
            },
        },
    },
    [8000300] = {
        triggers = {},
    },
    [8000400] = {
        triggers = {
            {
                luaFuncName = "OnDmgMakeKill",
                triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME.DmgMakeKill,
            },
        },
    },
    [8000500] = {
        triggers = {
            {
                luaFuncName = "OnSelfTurnBegin",
                triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME.SelfTurnBegin,
            },
        },
    },
    [8000600] = {
        triggers = {
            {
                luaFuncName = "OnSelfTurnBegin",
                triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME.SelfTurnBegin,
            },
        },
    },
    [8000700] = {
        triggers = {
            {
                luaFuncName = "OnSelfTurnBegin",
                triggerTime = E_PASSIVE_SKILL_TRIGGER_TIME.SelfTurnBegin,
            },
        },
    },
    [8000800] = {
        triggers = {},
    },
    [8000900] = {
        triggers = {},
    },
}

return PassiveDefs
