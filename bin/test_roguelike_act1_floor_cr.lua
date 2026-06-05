-- Act1 普通/精英/Boss 遭遇池应随 F1→F5 抬升 CR 上限，且低层不应刷出高层 CR 怪。
local script_source = debug.getinfo(1, "S").source
local script_dir = script_source:sub(2):match("(.*[/\\])") or "./"
local LuaBootstrap = dofile(script_dir .. "../core/lua_bootstrap.lua")
LuaBootstrap.SetupFromSource(script_source, { includeParent = true })

local EnemyData = require("config.enemy_data")
local EnemyGenerator = require("roguelike.roguelike_enemy_generator")
local RunEnemyGroup = require("config.roguelike.run_enemy_group")

local function crNum(cr)
    local a, b = tostring(cr):match("^(%d+)%/(%d+)$")
    if a then
        return tonumber(a) / tonumber(b)
    end
    return tonumber(cr) or 0
end

local function flattenGroup(groupId)
    local group = RunEnemyGroup.GetGroup(groupId)
    assert(group, "missing group " .. tostring(groupId))
    local ids = {}
    for _, enemyId in ipairs(group.front or {}) do
        ids[#ids + 1] = enemyId
    end
    for _, enemyId in ipairs(group.back or {}) do
        ids[#ids + 1] = enemyId
    end
    for _, enemyId in ipairs(group.guards or {}) do
        ids[#ids + 1] = enemyId
    end
    if tonumber(group.boss) then
        ids[#ids + 1] = tonumber(group.boss)
    end
    return ids
end

local function collectMaxCr(templatePoolId, waveCount, seedStart, seedEnd)
    local maxCr = 0
    for seed = seedStart, seedEnd do
        local generated, reason = EnemyGenerator.Generate(templatePoolId, waveCount, seed)
        assert(generated, "enemy generation failed: " .. tostring(reason))
        for _, groupId in ipairs(generated.waveGroupIds or {}) do
            for _, enemyId in ipairs(flattenGroup(groupId)) do
                local meta = EnemyData.GetChallengeMeta(enemyId)
                maxCr = math.max(maxCr, crNum(meta.cr))
            end
        end
    end
    return maxCr
end

local floorSpecs = {
    { label = "F1 normal", poolId = 401001, waves = 1, minMaxCr = 0.125, maxMaxCr = 0.25, seedStart = 9101, seedEnd = 9180 },
    { label = "F2 normal", poolId = 401002, waves = 2, minMaxCr = 0.25, maxMaxCr = 0.25, seedStart = 9201, seedEnd = 9280 },
    { label = "F3 normal", poolId = 401004, waves = 2, minMaxCr = 0.25, maxMaxCr = 0.5, seedStart = 9301, seedEnd = 9380 },
    { label = "F4 normal", poolId = 401003, waves = 2, minMaxCr = 0.5, maxMaxCr = 0.5, seedStart = 9401, seedEnd = 9480 },
    { label = "F5 boss", poolId = 401201, waves = 2, minMaxCr = 0.5, maxMaxCr = 1, seedStart = 9501, seedEnd = 9580 },
}

local previousMin = 0
for _, spec in ipairs(floorSpecs) do
    local observedMax = collectMaxCr(spec.poolId, spec.waves, spec.seedStart, spec.seedEnd)
    assert(observedMax >= spec.minMaxCr,
        string.format("%s max CR %.3f below min %.3f", spec.label, observedMax, spec.minMaxCr))
    assert(observedMax <= spec.maxMaxCr + 0.001,
        string.format("%s max CR %.3f above cap %.3f", spec.label, observedMax, spec.maxMaxCr))
    assert(spec.minMaxCr + 0.001 >= previousMin,
        string.format("%s min cap %.3f regressed below prior floor %.3f", spec.label, spec.minMaxCr, previousMin))
    previousMin = spec.minMaxCr
    print(string.format("[OK] %s observedMaxCr=%.3f", spec.label, observedMax))
end

print("[OK] act1 floor CR escalation")
