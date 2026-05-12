local RunEnemyGroup = require("config.roguelike.run_enemy_group")
local RunFormationProfile = require("config.roguelike.run_formation_profile")
local RunEnemyPickPool = require("config.roguelike.run_enemy_pick_pool")
local RunWaveGroupPool = require("config.roguelike.run_wave_group_pool")

local RoguelikeEnemyGenerator = {}

local function makeRng(seed)
    local state = math.max(1, math.floor(tonumber(seed) or 1) % 2147483647)
    return {
        nextInt = function(self, minValue, maxValue)
            state = (state * 16807) % 2147483647
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

local function pickEnemyId(rng, poolId, counts, maxSameEnemy)
    local pool = RunEnemyPickPool.GetPool(poolId)
    local candidates = {}
    for _, entry in ipairs(pool and pool.entries or {}) do
        local count = counts[entry.enemyId] or 0
        if count < maxSameEnemy then
            candidates[#candidates + 1] = entry
        end
    end
    if #candidates <= 0 then
        candidates = pool and pool.entries or {}
    end
    local picked = rng:weightedPick(candidates)
    if not picked then
        return nil
    end
    counts[picked.enemyId] = (counts[picked.enemyId] or 0) + 1
    return picked.enemyId
end

local function buildWaveGroupFromTemplate(rng, template, waveIndex, waveCount)
    local profile = RunFormationProfile.GetProfile(template.formationProfileId)
    if not profile then
        return nil, "formation_profile_not_found"
    end

    local enemyCounts = {}
    local front = {}
    local back = {}
    local guards = {}
    local boss = nil

    for _ = 1, math.max(0, tonumber(profile.frontSlots) or 0) do
        local enemyId = pickEnemyId(rng, template.frontPoolId, enemyCounts, profile.maxSameEnemy or 2)
        if enemyId then
            front[#front + 1] = enemyId
        end
    end
    for _ = 1, math.max(0, tonumber(profile.backSlots) or 0) do
        local enemyId = pickEnemyId(rng, template.backPoolId, enemyCounts, profile.maxSameEnemy or 2)
        if enemyId then
            back[#back + 1] = enemyId
        end
    end

    local isLastWave = waveIndex >= waveCount
    if template.mustIncludeBoss and isLastWave then
        boss = pickEnemyId(rng, template.bossPoolId, enemyCounts, 1)
        local guardMin = math.max(0, tonumber(profile.guardCountMin) or 0)
        local guardMax = math.max(guardMin, tonumber(profile.guardCountMax) or guardMin)
        local guardCount = rng:nextInt(guardMin, guardMax)
        for _ = 1, guardCount do
            local enemyId = pickEnemyId(rng, template.guardPoolId, enemyCounts, profile.maxSameEnemy or 2)
            if enemyId then
                guards[#guards + 1] = enemyId
            end
        end
    elseif template.reinforcePoolId and isLastWave ~= true then
        local reinforceEnemyId = pickEnemyId(rng, template.reinforcePoolId, enemyCounts, profile.maxSameEnemy or 2)
        if reinforceEnemyId then
            back[#back + 1] = reinforceEnemyId
        end
    end

    local groupId = RunEnemyGroup.RegisterRuntimeGroup({
        code = string.format("%s_wave_%d", template.code or "runtime_wave", waveIndex),
        name = string.format("%s第%d波", template.name or "运行时波次", waveIndex),
        front = front,
        back = back,
        elite = {},
        boss = boss,
        guards = guards,
    })

    return {
        groupId = groupId,
        bossEnemyId = boss,
    }
end

function RoguelikeEnemyGenerator.Generate(templatePoolId, waveCount, seed)
    local pool = RunWaveGroupPool.GetPool(templatePoolId)
    if not pool then
        return nil, "wave_group_pool_not_found"
    end

    local rng = makeRng(seed)
    local waveGroupIds = {}
    local bossEnemyId = nil
    for waveIndex = 1, math.max(1, waveCount or 1) do
        local entry = rng:weightedPick(pool.entries or {})
        local template = RunWaveGroupPool.GetTemplate(entry and entry.templateId)
        if not template then
            return nil, "wave_group_template_not_found"
        end
        if template.mustBeLastWave and waveIndex < waveCount then
            local fallbackTemplate = nil
            for _, candidate in ipairs(pool.entries or {}) do
                local candidateTemplate = RunWaveGroupPool.GetTemplate(candidate.templateId)
                if candidateTemplate and candidateTemplate.mustBeLastWave ~= true then
                    fallbackTemplate = candidateTemplate
                    break
                end
            end
            template = fallbackTemplate or template
        elseif template.mustBeLastWave ~= true and waveIndex == waveCount then
            for _, candidate in ipairs(pool.entries or {}) do
                local candidateTemplate = RunWaveGroupPool.GetTemplate(candidate.templateId)
                if candidateTemplate and candidateTemplate.mustBeLastWave == true then
                    template = candidateTemplate
                    break
                end
            end
        end
        local built, reason = buildWaveGroupFromTemplate(rng, template, waveIndex, waveCount)
        if not built then
            return nil, reason
        end
        waveGroupIds[#waveGroupIds + 1] = built.groupId
        bossEnemyId = bossEnemyId or built.bossEnemyId
    end

    return {
        waveGroupIds = waveGroupIds,
        bossEnemyId = bossEnemyId,
    }
end

return RoguelikeEnemyGenerator
