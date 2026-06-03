---@class RunWaveGroupPoolEntry
---@field templateId integer
---@field weight integer

---@class RunWaveGroupPoolConfig
---@field id integer
---@field entries RunWaveGroupPoolEntry[]

---@class RunWaveGroupTemplate
---@field id integer
---@field code string
---@field name string
---@field formationProfileId integer
---@field frontPoolId integer|nil
---@field backPoolId integer|nil
---@field reinforcePoolId integer|nil
---@field bossPoolId integer|nil
---@field guardPoolId integer|nil
---@field mustIncludeBoss boolean|nil
---@field mustBeLastWave boolean|nil

---@class RunWaveGroupPoolModule
---@field POOLS table<integer, RunWaveGroupPoolConfig>
---@field TEMPLATES table<integer, RunWaveGroupTemplate>
---@field GetPool fun(poolId: integer): RunWaveGroupPoolConfig|nil
---@field GetTemplate fun(templateId: integer): RunWaveGroupTemplate|nil

---@type RunWaveGroupPoolModule
local RunWaveGroupPool = {}

---@type table<integer, RunWaveGroupPoolConfig>
RunWaveGroupPool.POOLS = {
    [401001] = {
        id = 401001,
        entries = {
            { templateId = 501001, weight = 100 },
        },
    },
    [401002] = {
        id = 401002,
        entries = {
            { templateId = 501001, weight = 35 },
            { templateId = 501002, weight = 35 },
            { templateId = 501003, weight = 15 },
            { templateId = 501004, weight = 15 },
        },
    },
    [401003] = {
        id = 401003,
        entries = {
            { templateId = 501003, weight = 25 },
            { templateId = 501004, weight = 30 },
            { templateId = 501005, weight = 45 },
        },
    },
    [401101] = {
        id = 401101,
        entries = {
            { templateId = 501101, weight = 55 },
            { templateId = 501103, weight = 45 },
        },
    },
    [401102] = {
        id = 401102,
        entries = {
            { templateId = 501102, weight = 60 },
            { templateId = 501103, weight = 40 },
        },
    },
    [401201] = {
        id = 401201,
        entries = {
            { templateId = 501201, weight = 55 },
            { templateId = 501202, weight = 45 },
        },
    },
    [402001] = {
        id = 402001,
        entries = {
            { templateId = 502001, weight = 100 },
        },
    },
    [402002] = {
        id = 402002,
        entries = {
            { templateId = 502001, weight = 25 },
            { templateId = 502002, weight = 45 },
            { templateId = 502003, weight = 30 },
        },
    },
    [402003] = {
        id = 402003,
        entries = {
            { templateId = 502003, weight = 45 },
            { templateId = 502004, weight = 55 },
        },
    },
    [402101] = {
        id = 402101,
        entries = {
            { templateId = 502101, weight = 55 },
            { templateId = 502102, weight = 45 },
        },
    },
    [402102] = {
        id = 402102,
        entries = {
            { templateId = 502101, weight = 25 },
            { templateId = 502102, weight = 75 },
        },
    },
    [402201] = {
        id = 402201,
        entries = {
            { templateId = 502201, weight = 100 },
        },
    },
    [403001] = {
        id = 403001,
        entries = {
            { templateId = 503001, weight = 100 },
        },
    },
    [403002] = {
        id = 403002,
        entries = {
            { templateId = 503001, weight = 20 },
            { templateId = 503002, weight = 40 },
            { templateId = 503003, weight = 40 },
        },
    },
    [403003] = {
        id = 403003,
        entries = {
            { templateId = 503003, weight = 40 },
            { templateId = 503004, weight = 60 },
        },
    },
    [403101] = {
        id = 403101,
        entries = {
            { templateId = 503101, weight = 45 },
            { templateId = 503102, weight = 55 },
        },
    },
    [403102] = {
        id = 403102,
        entries = {
            { templateId = 503101, weight = 20 },
            { templateId = 503102, weight = 80 },
        },
    },
    [403201] = {
        id = 403201,
        entries = {
            { templateId = 503201, weight = 100 },
        },
    },
}

---@type table<integer, RunWaveGroupTemplate>
RunWaveGroupPool.TEMPLATES = {
    [501001] = {
        id = 501001,
        code = "normal_wave_light",
        name = "普通轻压波次",
        formationProfileId = 601001,
        frontPoolId = 701001,
        backPoolId = 701002,
        reinforcePoolId = nil,
    },
    [501002] = {
        id = 501002,
        code = "normal_wave_mixed",
        name = "普通混编波次",
        formationProfileId = 601002,
        frontPoolId = 701001,
        backPoolId = 701002,
        reinforcePoolId = nil,
    },
    [501003] = {
        id = 501003,
        code = "normal_wave_pressure",
        name = "普通高压波次",
        formationProfileId = 601003,
        frontPoolId = 701004,
        backPoolId = 701002,
        reinforcePoolId = nil,
    },
    [501004] = {
        id = 501004,
        code = "normal_wave_caster",
        name = "普通施法波次",
        formationProfileId = 601002,
        frontPoolId = 701004,
        backPoolId = 701005,
        reinforcePoolId = nil,
    },
    [501005] = {
        id = 501005,
        code = "normal_wave_soft_late",
        name = "普通后程波次",
        formationProfileId = 601002,
        frontPoolId = 701007,
        backPoolId = 701008,
        reinforcePoolId = nil,
    },
    [501101] = {
        id = 501101,
        code = "elite_wave_brute",
        name = "精英强攻波次",
        formationProfileId = 601101,
        frontPoolId = 701004,
        backPoolId = 701006,
        reinforcePoolId = nil,
    },
    [501102] = {
        id = 501102,
        code = "elite_wave_cabal",
        name = "精英秘团波次",
        formationProfileId = 601102,
        frontPoolId = 701004,
        backPoolId = 701006,
        reinforcePoolId = nil,
    },
    [501103] = {
        id = 501103,
        code = "elite_wave_guarded",
        name = "精英护卫波次",
        formationProfileId = 601101,
        frontPoolId = 701202,
        backPoolId = 701006,
        reinforcePoolId = nil,
    },
    [501201] = {
        id = 501201,
        code = "boss_wave_guard",
        name = "Boss 守卫波次",
        formationProfileId = 601201,
        frontPoolId = 701203,
        backPoolId = 701204,
        reinforcePoolId = 701204,
        bossPoolId = 701201,
        guardPoolId = 701202,
        mustIncludeBoss = true,
        mustBeLastWave = true,
    },
    [501202] = {
        id = 501202,
        code = "boss_wave_heavy_guard",
        name = "Boss 重卫波次",
        formationProfileId = 601202,
        frontPoolId = 701203,
        backPoolId = 701204,
        reinforcePoolId = 701204,
        bossPoolId = 701201,
        guardPoolId = 701202,
        mustIncludeBoss = true,
        mustBeLastWave = true,
    },
    [502001] = {
        id = 502001,
        code = "act2_normal_wave_early",
        name = "Act2 普通早期波次",
        formationProfileId = 601002,
        frontPoolId = 702001,
        backPoolId = 702002,
        reinforcePoolId = nil,
    },
    [502002] = {
        id = 502002,
        code = "act2_normal_wave_mixed",
        name = "Act2 普通混编波次",
        formationProfileId = 601002,
        frontPoolId = 702001,
        backPoolId = 702002,
        reinforcePoolId = 702002,
    },
    [502003] = {
        id = 502003,
        code = "act2_normal_wave_pressure",
        name = "Act2 普通高压波次",
        formationProfileId = 601003,
        frontPoolId = 702003,
        backPoolId = 702002,
        reinforcePoolId = nil,
    },
    [502004] = {
        id = 502004,
        code = "act2_normal_wave_cabal",
        name = "Act2 秘团波次",
        formationProfileId = 601002,
        frontPoolId = 702003,
        backPoolId = 702004,
        reinforcePoolId = nil,
    },
    [502101] = {
        id = 502101,
        code = "act2_elite_wave_guarded",
        name = "Act2 精英护卫波次",
        formationProfileId = 601101,
        frontPoolId = 702202,
        backPoolId = 702004,
        reinforcePoolId = nil,
    },
    [502102] = {
        id = 502102,
        code = "act2_elite_wave_ritual",
        name = "Act2 精英仪式波次",
        formationProfileId = 601102,
        frontPoolId = 702003,
        backPoolId = 702004,
        reinforcePoolId = nil,
    },
    [502201] = {
        id = 502201,
        code = "act2_boss_wave",
        name = "Act2 Boss 波次",
        formationProfileId = 601201,
        frontPoolId = 702202,
        backPoolId = 702203,
        reinforcePoolId = 702203,
        bossPoolId = 702201,
        guardPoolId = 702202,
        mustIncludeBoss = true,
        mustBeLastWave = true,
    },
    [503001] = {
        id = 503001,
        code = "act3_normal_wave_early",
        name = "Act3 普通早期波次",
        formationProfileId = 601002,
        frontPoolId = 703001,
        backPoolId = 703002,
        reinforcePoolId = nil,
    },
    [503002] = {
        id = 503002,
        code = "act3_normal_wave_mixed",
        name = "Act3 普通混编波次",
        formationProfileId = 601002,
        frontPoolId = 703001,
        backPoolId = 703002,
        reinforcePoolId = 703002,
    },
    [503003] = {
        id = 503003,
        code = "act3_normal_wave_pressure",
        name = "Act3 普通高压波次",
        formationProfileId = 601003,
        frontPoolId = 703003,
        backPoolId = 703002,
        reinforcePoolId = nil,
    },
    [503004] = {
        id = 503004,
        code = "act3_normal_wave_cabal",
        name = "Act3 深渊波次",
        formationProfileId = 601002,
        frontPoolId = 703003,
        backPoolId = 703004,
        reinforcePoolId = nil,
    },
    [503101] = {
        id = 503101,
        code = "act3_elite_wave_guarded",
        name = "Act3 精英护卫波次",
        formationProfileId = 601101,
        frontPoolId = 703202,
        backPoolId = 703004,
        reinforcePoolId = nil,
    },
    [503102] = {
        id = 503102,
        code = "act3_elite_wave_ritual",
        name = "Act3 精英深渊波次",
        formationProfileId = 601102,
        frontPoolId = 703003,
        backPoolId = 703004,
        reinforcePoolId = nil,
    },
    [503201] = {
        id = 503201,
        code = "act3_boss_wave",
        name = "Act3 Boss 波次",
        formationProfileId = 601202,
        frontPoolId = 703202,
        backPoolId = 703203,
        reinforcePoolId = 703203,
        bossPoolId = 703201,
        guardPoolId = 703202,
        mustIncludeBoss = true,
        mustBeLastWave = true,
    },
}

function RunWaveGroupPool.GetPool(poolId)
    return RunWaveGroupPool.POOLS[poolId]
end

function RunWaveGroupPool.GetTemplate(templateId)
    return RunWaveGroupPool.TEMPLATES[templateId]
end

return RunWaveGroupPool
