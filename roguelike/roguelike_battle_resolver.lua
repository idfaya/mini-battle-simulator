local RunBattleConfig = require("config.roguelike.run_battle_config")
local RunEncounterGroup = require("config.roguelike.run_encounter_group")
local RunBattlePool = require("config.roguelike.run_battle_pool")
local RunBattleTemplate = require("config.roguelike.run_battle_template")
local RunEncounterPool = require("config.roguelike.run_encounter_pool")
local RunEnemyGroup = require("config.roguelike.run_enemy_group")
local RoguelikeEnemyGenerator = require("roguelike.roguelike_enemy_generator")

local RoguelikeBattleResolver = {}

local function cloneTable(value, visited)
    if type(value) ~= "table" then
        return value
    end
    visited = visited or {}
    if visited[value] then
        return visited[value]
    end
    local result = {}
    visited[value] = result
    for key, item in pairs(value) do
        result[cloneTable(key, visited)] = cloneTable(item, visited)
    end
    return result
end

local function makeRng(seed)
    local state = math.max(1, math.floor(tonumber(seed) or 1) % 2147483647)
    return {
        nextInt = function(self, minValue, maxValue)
            state = (state * 69621 + 12345) % 2147483647
            local minV = math.floor(tonumber(minValue) or 0)
            local maxV = math.floor(tonumber(maxValue) or minV)
            if maxV < minV then
                minV, maxV = maxV, minV
            end
            local span = maxV - minV + 1
            if span <= 1 then
                return minV
            end
            return minV + (state % span)
        end,
        weightedPick = function(self, entries)
            local total = 0
            for _, entry in ipairs(entries or {}) do
                total = total + math.max(0, tonumber(entry.weight) or 0)
            end
            if total <= 0 then
                return entries and entries[1] or nil
            end
            local roll = self:nextInt(1, total)
            local sum = 0
            for _, entry in ipairs(entries or {}) do
                sum = sum + math.max(0, tonumber(entry.weight) or 0)
                if roll <= sum then
                    return entry
                end
            end
            return entries and entries[#entries] or nil
        end,
    }
end

local function buildSeed(runState, node, salt)
    local baseSeed = tonumber(runState and runState.seed) or 1
    local nodeId = tonumber(node and node.id) or 0
    local chapterId = tonumber(runState and runState.chapterId) or 0
    return baseSeed * 1009 + chapterId * 9176 + nodeId * 131 + (salt or 0)
end

local function resolveEncounter(encounterPoolId, seed)
    local pool = RunEncounterPool.GetPool(encounterPoolId)
    if not pool then
        return nil, "encounter_pool_not_found"
    end
    local rng = makeRng(seed)
    local picked = rng:weightedPick(pool.entries or {})
    local encounter = RunEncounterGroup.GetEncounter(picked and picked.encounterId)
    if not encounter then
        return nil, "encounter_not_found"
    end
    return cloneTable(encounter)
end

function RoguelikeBattleResolver.ResolveNodeBattle(runState, node)
    if not node then
        return nil, nil, "node_not_found"
    end

    if tonumber(node.battleId) then
        local battle = RunBattleConfig.GetBattle(tonumber(node.battleId))
        local encounter = RunEncounterGroup.GetEncounter(tonumber(node.battleId))
        if not battle or not encounter then
            return nil, nil, "battle_not_found"
        end
        return cloneTable(battle), cloneTable(encounter)
    end

    local pool = RunBattlePool.GetPool(tonumber(node.battlePoolId))
    if not pool then
        return nil, nil, "battle_pool_not_found"
    end

    local rng = makeRng(buildSeed(runState, node, 1))
    local pickedEntry = rng:weightedPick(pool.entries or {})
    local template = RunBattleTemplate.GetTemplate(pickedEntry and pickedEntry.battleTemplateId)
    if not template then
        return nil, nil, "battle_template_not_found"
    end

    local encounter, encounterReason = resolveEncounter(template.encounterPoolId, buildSeed(runState, node, 2))
    if not encounter then
        return nil, nil, encounterReason
    end

    local waveCountRng = makeRng(buildSeed(runState, node, 3))
    local waveCount = waveCountRng:nextInt(template.waveCountMin or 1, template.waveCountMax or template.waveCountMin or 1)
    local generated, reason = RoguelikeEnemyGenerator.Generate(template.waveGroupPoolId, waveCount, buildSeed(runState, node, 4))
    if not generated then
        return nil, nil, reason
    end

    local battle = {
        id = template.id,
        code = template.code,
        name = template.name,
        kind = template.kind,
        expReward = template.expReward,
        refreshTurns = template.refreshTurns,
        refreshOnClear = template.refreshOnClear,
        spawnOrder = template.spawnOrder,
        winRule = template.winRule,
        loseRule = template.loseRule,
        waveGroupIds = generated.waveGroupIds,
        bossId = template.bossEnemyId or generated.bossEnemyId,
    }

    encounter.enemyIds = {}
    for _, groupId in ipairs(generated.waveGroupIds or {}) do
        local group = RunEnemyGroup.GetGroup(groupId)
        for _, enemyId in ipairs(group and group.front or {}) do
            encounter.enemyIds[#encounter.enemyIds + 1] = enemyId
        end
        for _, enemyId in ipairs(group and group.back or {}) do
            encounter.enemyIds[#encounter.enemyIds + 1] = enemyId
        end
        for _, enemyId in ipairs(group and group.elite or {}) do
            encounter.enemyIds[#encounter.enemyIds + 1] = enemyId
        end
        if group and group.boss then
            encounter.enemyIds[#encounter.enemyIds + 1] = group.boss
        end
        for _, enemyId in ipairs(group and group.guards or {}) do
            encounter.enemyIds[#encounter.enemyIds + 1] = enemyId
        end
    end

    return battle, encounter
end

return RoguelikeBattleResolver
