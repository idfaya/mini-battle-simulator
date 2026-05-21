local RunRewardPool = require("config.roguelike.run_reward_pool")
local RunEquipmentConfig = require("config.roguelike.run_equipment_config")
local RunBlessingConfig = require("config.roguelike.run_blessing_config")
local RunRecruitPool = require("config.roguelike.run_recruit_pool")
local HeroData = require("config.hero_data")
local HeroBuild = require("modules.hero_build")
local BattleEvent = require("core.battle_event")
local RoguelikeRoster = require("roguelike.roguelike_roster")
local BuildConstraints = require("roguelike.build_constraints")

local RoguelikeReward = {}
local RECRUIT_LEVEL = 1
local RECRUIT_STAR = 1
local EQUIPMENT_RARITY_TIER = {
    common = 1,
    rare = 2,
    boss = 3,
}

local function allocateRosterId(runState)
    runState.nextRosterId = (runState.nextRosterId or 1)
    local rosterId = runState.nextRosterId
    runState.nextRosterId = rosterId + 1
    return rosterId
end

local function contains(list, value)
    for _, item in ipairs(list or {}) do
        if item == value then
            return true
        end
    end
    return false
end

local function containsHeroId(roster, heroId)
    for _, hero in ipairs(roster or {}) do
        if tonumber(hero.heroId) == tonumber(heroId) then
            return true
        end
    end
    return false
end

local function collectAllUnits(runState)
    return RoguelikeRoster.GetOwnedUnits(runState)
end

local function getClassIdFromHeroId(heroId)
    local heroInfo = HeroData.GetHeroInfo(heroId)
    return tonumber(heroInfo and heroInfo.Class) or 0
end

local function containsClassId(roster, classId)
    for _, hero in ipairs(roster or {}) do
        if tonumber(hero.classId) == tonumber(classId) then
            return true
        end
    end
    return false
end

local function findClassUnit(runState, classId)
    for _, hero in ipairs(collectAllUnits(runState)) do
        if tonumber(hero.classId) == tonumber(classId) then
            return hero
        end
    end
    return nil
end

local function getActiveUnitCount(runState)
    return RoguelikeRoster.GetTeamUnitCount(runState)
end

local function hasFreeActiveSlot(runState)
    return getActiveUnitCount(runState) < (runState.maxHeroCount or 5)
end

local function collectEquipmentPoolByTier(targetTier)
    local pool = {}
    for equipmentId, equipment in pairs(RunEquipmentConfig.EQUIPMENTS or {}) do
        local rarityTier = EQUIPMENT_RARITY_TIER[tostring(equipment and equipment.rarity or "common")] or 1
        if rarityTier == targetTier then
            pool[#pool + 1] = tonumber(equipmentId)
        end
    end
    table.sort(pool)
    return pool
end

local function chooseEquipmentIdByTier(targetTier)
    local pool = collectEquipmentPoolByTier(targetTier)
    if #pool <= 0 then
        return nil
    end
    return pool[math.random(1, #pool)]
end

local function rollBattleEquipmentId(nodeType, battleProfile)
    local resolvedNodeType = tostring(nodeType or "")
    -- 设计 §2.2 新规则：
    --   battle_normal: 不再掉装备（一律 nil）。普通战只产 gold + EXP。
    --   battle_elite : 必掉 1 件装备（rare/boss tier 加权）。
    --   boss         : 必掉 boss tier 装备。
    if resolvedNodeType == "battle_normal" then
        return nil
    end
    if resolvedNodeType == "battle_elite" then
        local rarityBonus = math.max(0, tonumber(battleProfile and battleProfile.eliteBonus and battleProfile.eliteBonus.rewardRarityBonus) or 0)
        local roll = math.random()
        local rareThreshold = math.min(0.75, 0.30 + rarityBonus * 0.10)
        local bossThreshold = math.min(0.35, math.max(0, (rarityBonus - 1) * 0.10))
        if roll <= bossThreshold then
            return chooseEquipmentIdByTier(3) or chooseEquipmentIdByTier(2) or chooseEquipmentIdByTier(1)
        end
        if roll <= (bossThreshold + rareThreshold) then
            return chooseEquipmentIdByTier(2) or chooseEquipmentIdByTier(1)
        end
        return chooseEquipmentIdByTier(1)
    end
    if resolvedNodeType == "boss" then
        return chooseEquipmentIdByTier(3) or chooseEquipmentIdByTier(2) or chooseEquipmentIdByTier(1)
    end
    return nil
end

local BLESSING_RARITY_TIER = { common = 1, rare = 2, boss = 3 }

local function collectBlessingPoolByTier(targetTier)
    local pool = {}
    for blessingId, blessing in pairs(RunBlessingConfig.BLESSINGS or {}) do
        local rarityTier = BLESSING_RARITY_TIER[tostring(blessing and blessing.rarity or "common")] or 1
        if rarityTier == targetTier then
            pool[#pool + 1] = tonumber(blessingId)
        end
    end
    table.sort(pool)
    return pool
end

local function chooseBlessingIdByTier(targetTier)
    local pool = collectBlessingPoolByTier(targetTier)
    if #pool <= 0 then
        return nil
    end
    return pool[math.random(1, #pool)]
end

-- 设计 §2.2 新规则：
--   battle_normal: 不掉祝福。
--   battle_elite : 50% 概率掉祝福（rare 或 common）。
--   boss         : 必掉 1 个 boss tier 祝福（fallback rare）。
local function rollBattleBlessingId(nodeType, battleProfile)
    local resolvedNodeType = tostring(nodeType or "")
    if resolvedNodeType == "battle_elite" then
        if math.random() > 0.5 then
            return nil
        end
        local rareChance = 0.40
        if math.random() <= rareChance then
            return chooseBlessingIdByTier(2) or chooseBlessingIdByTier(1)
        end
        return chooseBlessingIdByTier(1)
    end
    if resolvedNodeType == "boss" then
        return chooseBlessingIdByTier(3) or chooseBlessingIdByTier(2) or chooseBlessingIdByTier(1)
    end
    return nil
end

local function weightedPick(entries, taken)
    local total = 0
    for index, entry in ipairs(entries or {}) do
        if not taken[index] then
            total = total + math.max(0, tonumber(entry.weight) or 0)
        end
    end
    if total <= 0 then
        return nil
    end

    local roll = math.random() * total
    local cursor = 0
    for index, entry in ipairs(entries or {}) do
        if not taken[index] then
            cursor = cursor + math.max(0, tonumber(entry.weight) or 0)
            if roll <= cursor then
                return index, entry
            end
        end
    end

    return nil
end

local function buildLabel(entry)
    if entry.rewardType == "gold" then
        return string.format("金币 +%d", entry.value or 0)
    end
    if entry.rewardType == "equipment" then
        local equipment = RunEquipmentConfig.GetEquipment(entry.refId)
        return equipment and equipment.name or ("装备 " .. tostring(entry.refId))
    end
    if entry.rewardType == "blessing" then
        local blessing = RunBlessingConfig.GetBlessing(entry.refId)
        return blessing and blessing.name or ("祝福 " .. tostring(entry.refId))
    end
    if entry.rewardType == "recruit" then
        return "招募 " .. HeroData.GetHeroName(entry.refId)
    end
    return tostring(entry.rewardType or "reward")
end

local function buildDescription(entry)
    if entry.rewardType == "equipment" then
        local equipment = RunEquipmentConfig.GetEquipment(entry.refId)
        return equipment and equipment.code or ""
    end
    if entry.rewardType == "blessing" then
        local blessing = RunBlessingConfig.GetBlessing(entry.refId)
        return blessing and blessing.description or ""
    end
    if entry.rewardType == "recruit" then
        return HeroData.GetClassName((HeroData.GetHeroInfo(entry.refId) or {}).Class or 0)
    end
    return ""
end

local function createHeroRecord(runState, heroId)
    local classId = getClassIdFromHeroId(heroId)
    if classId <= 0 then
        return nil
    end
    local rosterId = allocateRosterId(runState)
    return HeroData.CreateClassUnit(classId, {
        rosterId = rosterId,
        unitId = string.format("class_unit_%d_%d", classId, rosterId),
        level = math.max(RECRUIT_LEVEL, tonumber(runState.partyLevel) or RECRUIT_LEVEL),
        teamState = hasFreeActiveSlot(runState) and "active" or "bench",
        source = "reward",
    })
end

function RoguelikeReward.AddRecruit(runState, heroId, options)
    local recruitOptions = options or {}
    local classId = getClassIdFromHeroId(heroId)
    if classId <= 0 then
        return false, "invalid_recruit"
    end

    local existingUnit = findClassUnit(runState, classId)
    if existingUnit then
        -- 阶段 3.1：废弃职业卡进阶；同职业重复招募直接拒绝。
        return false, "class_already_owned"
    end

    local heroRecord = createHeroRecord(runState, heroId)
    if not heroRecord then
        return false, "invalid_recruit"
    end
    heroRecord.ultimateChargesMax = heroRecord.ultimateChargesMax or 1
    heroRecord.ultimateCharges = heroRecord.ultimateCharges or heroRecord.ultimateChargesMax

    if recruitOptions.forceBench then
        RoguelikeRoster.AddOwnedUnit(runState, heroRecord, "bench")
        runState.lastActionMessage = "新职业卡已加入候补"
        return true, heroRecord
    end

    if hasFreeActiveSlot(runState) then
        RoguelikeRoster.AddOwnedUnit(runState, heroRecord, "active")
        runState.lastActionMessage = "新职业卡已直接加入上阵队伍"
    else
        RoguelikeRoster.AddOwnedUnit(runState, heroRecord, "bench")
        runState.lastActionMessage = "新职业卡已加入候补"
    end

    return true, heroRecord
end

function RoguelikeReward.GenerateRecruitRewardState(runState, recruitPoolId, optionCount)
    local count = math.max(1, tonumber(optionCount) or 3)
    local poolConfig = recruitPoolId and RunRecruitPool.GetPool(recruitPoolId) or nil
    if poolConfig then
        count = math.max(1, tonumber(optionCount) or tonumber(poolConfig.optionCount) or 3)
    end
    local pool = (poolConfig and poolConfig.heroIds) or HeroData.GetAllHeroIds() or {}
    local classPool = {}
    local classSeen = {}
    for _, heroId in ipairs(pool) do
        local classId = getClassIdFromHeroId(heroId)
        if classId > 0 and not classSeen[classId] then
            classSeen[classId] = true
            classPool[#classPool + 1] = classId
        end
    end
    local candidates = {}
    for _, classId in ipairs(classPool) do
        local unit = findClassUnit(runState, classId)
        if not unit then
            -- 阶段 3.1：废弃 promotion_pending_target / promotionStage，仅按是否已拥有该职业过滤。
            candidates[#candidates + 1] = classId
        end
    end
    if #candidates == 0 then
        candidates = classPool
    end

    local options = {}
    local picked = {}
    local pickedCount = 0
    while #options < count and pickedCount < #candidates do
        local idx = math.random(1, #candidates)
        local classId = candidates[idx]
        if not picked[classId] then
            local heroId = HeroData.GetRepresentativeHeroId(classId)
            local className = HeroData.GetClassName(classId)
            picked[classId] = true
            pickedCount = pickedCount + 1
            options[#options + 1] = {
                rewardType = "recruit",
                refId = heroId,
                heroName = className,
                classId = classId,
                teamState = hasFreeActiveSlot(runState) and "active" or "bench",
                label = "职业卡 " .. className,
                description = "招募 " .. className,
            }
        end
    end

    return {
        groupId = tonumber(recruitPoolId) or 0,
        kind = "node_recruit",
        options = options,
    }
end

-- ==========================================================================
-- 阶段 3.1：职业卡 / 进阶 / promotion_pending_target 全部废弃。
-- 战斗胜利的升级三选一改由 roguelike/feat_picker.lua 驱动。
-- ==========================================================================

function RoguelikeReward.RollBattleEquipmentDrop(nodeType, battleProfile)
    return rollBattleEquipmentId(nodeType, battleProfile)
end

-- 战斗祝福掉落 API（精英战 50% 概率，boss 必掉 boss tier）
function RoguelikeReward.RollBattleBlessingDrop(nodeType, battleProfile)
    return rollBattleBlessingId(nodeType, battleProfile)
end

function RoguelikeReward.GenerateRewardState(groupId)
    local group = RunRewardPool.GetGroup(groupId)
    if not group then
        return nil
    end

    local options = {}
    local taken = {}
    local required = ((group.constraints or {}).requireAtLeastOne) or {}

    for _, rewardType in ipairs(required) do
        for index, entry in ipairs(group.options or {}) do
            if entry.rewardType == rewardType and not taken[index] then
                taken[index] = true
                options[#options + 1] = {
                    rewardType = entry.rewardType,
                    refId = entry.refId,
                    value = entry.value,
                    label = buildLabel(entry),
                    description = buildDescription(entry),
                }
                break
            end
        end
    end

    while #options < (group.optionCount or 1) do
        local pickedIndex, entry = weightedPick(group.options, taken)
        if not pickedIndex or not entry then
            break
        end
        taken[pickedIndex] = true
        options[#options + 1] = {
            rewardType = entry.rewardType,
            refId = entry.refId,
            value = entry.value,
            label = buildLabel(entry),
            description = buildDescription(entry),
        }
    end

    return {
        groupId = groupId,
        kind = group.kind,
        options = options,
    }
end

function RoguelikeReward.ApplyReward(runState, rewardState, index)
    local option = rewardState and rewardState.options and rewardState.options[index] or nil
    if not option then
        return false, "invalid_reward"
    end

    if option.rewardType == "gold" then
        runState.gold = (runState.gold or 0) + (option.value or 0)
        runState.lastActionMessage = option.label
    elseif option.rewardType == "equipment" then
        BuildConstraints.AddEquipment(runState, option.refId)
        runState.lastActionMessage = option.label
    elseif option.rewardType == "blessing" then
        BuildConstraints.AddBlessing(runState, option.refId)
        runState.lastActionMessage = option.label
    elseif option.rewardType == "recruit" then
        local added, reason = RoguelikeReward.AddRecruit(runState, option.refId)
        if not added then
            return false, reason
        end
        if not runState.lastActionMessage or runState.lastActionMessage == "" then
            runState.lastActionMessage = option.label
        end
    else
        return false, "unsupported_reward"
    end

    return true
end

return RoguelikeReward

