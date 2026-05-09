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
            { templateId = 501002, weight = 45 },
            { templateId = 501003, weight = 20 },
        },
    },
    [401003] = {
        id = 401003,
        entries = {
            { templateId = 501005, weight = 100 },
        },
    },
    [401101] = {
        id = 401101,
        entries = {
            { templateId = 501101, weight = 100 },
        },
    },
    [401102] = {
        id = 401102,
        entries = {
            { templateId = 501102, weight = 100 },
        },
    },
    [401201] = {
        id = 401201,
        entries = {
            { templateId = 501201, weight = 100 },
        },
    },
}

---@type table<integer, RunWaveGroupTemplate>
RunWaveGroupPool.TEMPLATES = {
    [501001] = {
        id = 501001,
        code = "normal_wave_light",
        name = "Normal Wave Light",
        formationProfileId = 601001,
        frontPoolId = 701001,
        backPoolId = 701002,
        reinforcePoolId = nil,
    },
    [501002] = {
        id = 501002,
        code = "normal_wave_mixed",
        name = "Normal Wave Mixed",
        formationProfileId = 601002,
        frontPoolId = 701001,
        backPoolId = 701002,
        reinforcePoolId = nil,
    },
    [501003] = {
        id = 501003,
        code = "normal_wave_pressure",
        name = "Normal Wave Pressure",
        formationProfileId = 601003,
        frontPoolId = 701004,
        backPoolId = 701002,
        reinforcePoolId = nil,
    },
    [501004] = {
        id = 501004,
        code = "normal_wave_caster",
        name = "Normal Wave Caster",
        formationProfileId = 601002,
        frontPoolId = 701004,
        backPoolId = 701005,
        reinforcePoolId = nil,
    },
    [501005] = {
        id = 501005,
        code = "normal_wave_soft_late",
        name = "Normal Wave Soft Late",
        formationProfileId = 601002,
        frontPoolId = 701007,
        backPoolId = 701008,
        reinforcePoolId = nil,
    },
    [501101] = {
        id = 501101,
        code = "elite_wave_brute",
        name = "Elite Wave Brute",
        formationProfileId = 601101,
        frontPoolId = 701004,
        backPoolId = 701006,
        reinforcePoolId = nil,
    },
    [501102] = {
        id = 501102,
        code = "elite_wave_cabal",
        name = "Elite Wave Cabal",
        formationProfileId = 601102,
        frontPoolId = 701004,
        backPoolId = 701006,
        reinforcePoolId = nil,
    },
    [501201] = {
        id = 501201,
        code = "boss_wave_guard",
        name = "Boss Wave Guard",
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
        name = "Boss Wave Heavy Guard",
        formationProfileId = 601202,
        frontPoolId = 701203,
        backPoolId = 701204,
        reinforcePoolId = 701204,
        bossPoolId = 701201,
        guardPoolId = 701202,
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
